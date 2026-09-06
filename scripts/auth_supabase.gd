extends Node
## Supabase Auth (GoTrue) — "Entrar com Google" via PKCE.
##
## Diferente do google_auth.gd antigo: o OAuth passa PELO Supabase (provider
## google configurado no painel), então o CLIENT_SECRET do Google NÃO fica no
## binário. O jogo só abre o navegador, recebe um `code` no redirect e troca por
## uma sessão (access + refresh token). Os tokens ficam salvos CRIPTOGRAFADOS.
##
## Autoload sugerido: "Auth".
## API:
##   Auth.entrar_google()                 # inicia o login
##   Auth.sessao_valida() -> bool
##   Auth.bearer() -> String              # access token (use "Authorization: Bearer "+...)
##   Auth.uid() -> String                 # id do usuário no Supabase
##   Auth.sair()
##   sinais: login_ok(uid), login_falhou(erro), logout_feito
##
## PC: redirect via loopback 127.0.0.1:porta fixa (allowlist estável).
## Android: HOJE usa o mesmo loopback do PC, e o jogador precisa voltar ao app
## na mao -- o navegador nao traz de volta sozinho. O deep link `cyron://auth`
## esta declarado em _SCHEME_AND e NAO esta ligado a nada: nao ha intent-filter
## declarado no Android nem quem trate o retorno. Fica escrito aqui porque o
## comentario antigo dizia que o deep link era o caminho, e quem lesse iria
## procurar um bug onde nao ha' codigo.

signal login_ok(uid: String)
signal login_falhou(erro: String)
signal perfil_pronto(apelido: String)   # login concluído E perfil carregado/criado
signal precisa_apelido(sugestao: String) # 1º login: jogador deve escolher o apelido
signal logout_feito

const _BASE        : String = "https://npbqezpfjrjvsqwvgtfy.supabase.co"
const _AUTHORIZE   : String = _BASE + "/auth/v1/authorize"
const _TOKEN       : String = _BASE + "/auth/v1/token"
const _LOGOUT      : String = _BASE + "/auth/v1/logout"
const _URL_PROFILES: String = _BASE + "/rest/v1/profiles"
const _PORTA_PC    : int    = 49190                      # fixa → allowlist estável
const _SCHEME_AND  : String = "cyron://auth"             # deep link Android
const _TIMEOUT_S   : float  = 180.0
const _ARQ_SESSAO  : String = "user://sessao.dat"
const _CHAVE_SESSAO: String = "cyron_sessao_v1"          # ofuscação local do token

var _access     : String = ""
var _refresh    : String = ""
var _uid        : String = ""
var _expira_em  : int    = 0                             # unix time
var _nome_google: String = ""                            # nome vindo do Google (default do apelido)
var _apelido    : String = ""                            # apelido do perfil (nome no ranking)

# Estado do fluxo OAuth em andamento
var _server   : TCPServer = null
var _verifier : String    = ""
var _restante : float     = 0.0
var _ativo    : bool      = false


func _ready() -> void:
	_carregar_sessao()


# ── API pública ──────────────────────────────────────────────────────────────

func sessao_valida() -> bool:
	return _uid != "" and (_access != "" or _refresh != "")


func bearer() -> String:
	# Devolve um access token válido (renova se faltar pouco). Pode estar vazio
	# se a sessão caiu — o chamador deve tratar.
	return _access


func uid() -> String:
	return _uid


func entrar_google() -> void:
	if _ativo:
		return
	_verifier = _b64url(Crypto.new().generate_random_bytes(48))
	var ctx := HashingContext.new()
	ctx.start(HashingContext.HASH_SHA256)
	ctx.update(_verifier.to_utf8_buffer())
	var challenge := _b64url(ctx.finish())

	var redirect := _redirect_uri()
	if redirect == "":
		login_falhou.emit("Não consegui preparar o retorno do login neste aparelho.")
		return

	var url := _AUTHORIZE + "?" + "&".join(PackedStringArray([
		"provider=google",
		"redirect_to=" + redirect.uri_encode(),
		"code_challenge=" + challenge,
		"code_challenge_method=s256",
	]))
	_ativo = true
	_restante = _TIMEOUT_S
	OS.shell_open(url)


func sair() -> void:
	# Revoga no servidor (best-effort) e limpa local.
	if _access != "":
		var http := HTTPRequest.new()
		add_child(http)
		http.request_completed.connect(func(_r, _s, _h, _b): http.queue_free())
		http.request(_LOGOUT, _headers(true), HTTPClient.METHOD_POST, "")
	_limpar_local()
	logout_feito.emit()


# ── Fluxo OAuth (PC loopback) ────────────────────────────────────────────────

func _redirect_uri() -> String:
	# Loopback funciona em PC e (geralmente) Android: o navegador redireciona pra
	# 127.0.0.1:porta e o app captura. No Android o jogador volta pro app na mão
	# (o navegador não traz de volta sozinho). Se falhar no device, fallback é
	# deep link via plugin nativo.
	_server = TCPServer.new()
	if _server.listen(_PORTA_PC, "127.0.0.1") != OK:
		_server = null
		return ""
	return "http://127.0.0.1:%d" % _PORTA_PC


func _process(delta: float) -> void:
	if not _ativo or _server == null:
		return
	_restante -= delta
	if _restante <= 0.0:
		_cancelar("Tempo esgotado — tente de novo.")
		return
	if not _server.is_connection_available():
		return
	var conn := _server.take_connection()
	if conn == null:
		return
	var espera := 0
	while conn.get_available_bytes() <= 0 and espera < 100:
		OS.delay_msec(10)
		espera += 1
	var raw := conn.get_utf8_string(conn.get_available_bytes())
	var code := ""
	var m := RegEx.create_from_string("[?&]code=([^&\\s]+)").search(raw)
	if m:
		code = m.get_string(1).uri_decode()
	var ok_html : String = "Login confirmado ✔" if code != "" else "Login cancelado"
	var corpo := "<html><body style='background:#0a0a12;color:#dde;font-family:sans-serif;text-align:center;padding-top:120px'><h2>%s</h2><p>Pronto! O jogo já voltou pra frente. Pode fechar esta aba.</p></body></html>" % ok_html
	conn.put_data(("HTTP/1.1 200 OK\r\nContent-Type: text/html; charset=utf-8\r\nConnection: close\r\nContent-Length: %d\r\n\r\n%s" % [corpo.to_utf8_buffer().size(), corpo]).to_utf8_buffer())
	conn.disconnect_from_host()
	_fechar_server()
	_ativo = false
	if code == "":
		_cancelar("Login cancelado no navegador.")
		return
	# Traz o jogo de volta pra frente automaticamente (sem alt-tab manual).
	DisplayServer.window_move_to_foreground()
	DisplayServer.window_request_attention()
	_trocar_codigo(code)


## Nao chegou resposta nenhuma? (ao contrario de "o servidor respondeu, e disse
## nao")
##
## O primeiro parametro do request_completed e' o RESULTADO do transporte, e
## estava sendo ignorado nos cinco pontos deste arquivo -- todos escritos
## `func(_r, status, ...)`. Sem ele, "sem sinal" e "credencial recusada" viram
## a mesma coisa, porque os dois chegam aqui com status 0 ou != 200.
##
## Isso nao e' preciosismo: quando o servidor esta fora do ar, o jogo dizia "O
## servidor recusou o login (0)". O servidor nao recusou nada -- ele nao
## respondeu. Quem le' isso vai conferir a conta do Google, e o problema esta
## noutro lugar.
static func sem_resposta(resultado: int, status: int) -> bool:
	return resultado != HTTPRequest.RESULT_SUCCESS or status <= 0


## O recado honesto para cada caso.
static func msg_de_falha(resultado: int, status: int) -> String:
	if sem_resposta(resultado, status):
		return "Não consegui falar com o servidor. Verifique a internet e tente de novo."
	if status in [401, 403]:
		return "O servidor não aceitou este login."
	if status >= 500:
		return "O servidor está com problema (%d). Tente mais tarde." % status
	return "O servidor recusou o login (%d)." % status


func _trocar_codigo(code: String) -> void:
	var http := HTTPRequest.new()
	add_child(http)
	var body := JSON.stringify({"auth_code": code, "code_verifier": _verifier})
	http.request_completed.connect(func(r, status, _h, resp: PackedByteArray):
		http.queue_free()
		var dados = JSON.parse_string(resp.get_string_from_utf8())
		if status != 200 or not (dados is Dictionary):
			print("AUTH: troca PKCE falhou resultado=", r, " status=", status,
				" body=", resp.get_string_from_utf8())
			login_falhou.emit(msg_de_falha(r, status))
			return
		_aplicar_sessao(dados as Dictionary, true))
	http.request(_TOKEN + "?grant_type=pkce", _headers(false), HTTPClient.METHOD_POST, body)


# ── Sessão / token ───────────────────────────────────────────────────────────

func _aplicar_sessao(d: Dictionary, emitir: bool) -> void:
	_access  = str(d.get("access_token", ""))
	_refresh = str(d.get("refresh_token", _refresh))
	var expira_in : int = int(d.get("expires_in", 3600))
	_expira_em = int(Time.get_unix_time_from_system()) + expira_in
	var user = d.get("user", null)
	if user is Dictionary:
		_uid = str((user as Dictionary).get("id", _uid))
		_nome_google = _extrair_nome_google(user as Dictionary)
	if _access == "" or _uid == "":
		if emitir:
			login_falhou.emit("Resposta de login incompleta.")
		return
	_guardar_sessao()
	if emitir:
		login_ok.emit(_uid)
		_garantir_perfil()


func _extrair_nome_google(u: Dictionary) -> String:
	var meta = u.get("user_metadata", {})
	if meta is Dictionary:
		for k in ["full_name", "name", "nome"]:
			var v = (meta as Dictionary).get(k, "")
			if v is String and (v as String).strip_edges() != "":
				return (v as String).strip_edges()
	var email := str(u.get("email", ""))
	if email.contains("@"):
		return email.split("@")[0]
	return "Jogador"


func apelido() -> String:
	return _apelido


func _garantir_perfil() -> void:
	# Busca o perfil do jogador (apelido). Se não existir, cria com o nome do Google.
	var http := HTTPRequest.new()
	add_child(http)
	http.request_completed.connect(func(r, status, _h, resp: PackedByteArray):
		http.queue_free()
		if status == 200:
			var arr = JSON.parse_string(resp.get_string_from_utf8())
			if arr is Array and (arr as Array).size() > 0 and (arr as Array)[0] is Dictionary:
				_apelido = str(((arr as Array)[0] as Dictionary).get("apelido", _nome_google))
				perfil_pronto.emit(_apelido)
				return
			_criar_perfil_inicial()
			return
		print("AUTH: GET perfil falhou resultado=", r, " status=", status,
			" body=", resp.get_string_from_utf8())
		_apelido = _nome_google      # fallback: não bloqueia o login
		perfil_pronto.emit(_apelido))
	http.request(_URL_PROFILES + "?id=eq.%s&select=apelido,avatar_idx" % _uid.uri_encode(), _headers(true))


func _criar_perfil_inicial() -> void:
	# Sem perfil ainda → pede pro jogador ESCOLHER o apelido (sugere o do Google).
	precisa_apelido.emit(_nome_google)


func definir_apelido(nome_escolhido: String) -> void:
	# Cria/atualiza o perfil com o apelido escolhido pelo jogador (upsert por id).
	var nome : String = nome_escolhido.strip_edges().substr(0, 20)
	if nome == "":
		nome = (_nome_google if _nome_google != "" else "Jogador").substr(0, 20)
	var http := HTTPRequest.new()
	add_child(http)
	var body := JSON.stringify({"id": _uid, "apelido": nome})
	http.request_completed.connect(func(r, status, _h, resp: PackedByteArray):
		http.queue_free()
		if not (status in [200, 201, 204]):
			print("AUTH: salvar apelido falhou resultado=", r, " status=", status,
				" body=", resp.get_string_from_utf8())
		_apelido = nome
		perfil_pronto.emit(_apelido))
	var h := _headers(true)
	h.append("Prefer: return=minimal,resolution=merge-duplicates")
	http.request(_URL_PROFILES + "?on_conflict=id", h, HTTPClient.METHOD_POST, body)


func _carregar_sessao() -> void:
	if not FileAccess.file_exists(_ARQ_SESSAO):
		return
	var f := FileAccess.open_encrypted_with_pass(_ARQ_SESSAO, FileAccess.READ, _CHAVE_SESSAO)
	if f == null:
		return
	var txt := f.get_as_text()
	f.close()
	var d = JSON.parse_string(txt)
	if not (d is Dictionary):
		return
	var dd := d as Dictionary
	_access   = str(dd.get("access", ""))
	_refresh  = str(dd.get("refresh", ""))
	_uid      = str(dd.get("uid", ""))
	_expira_em = int(dd.get("expira", 0))
	# Access perto de expirar → renova já
	if _refresh != "" and int(Time.get_unix_time_from_system()) > _expira_em - 120:
		_renovar()


func _renovar() -> void:
	if _refresh == "":
		return
	var http := HTTPRequest.new()
	add_child(http)
	var body := JSON.stringify({"refresh_token": _refresh})
	http.request_completed.connect(func(r, status, _h, resp: PackedByteArray):
		http.queue_free()
		var dados = JSON.parse_string(resp.get_string_from_utf8())
		if status != 200 or not (dados is Dictionary):
			# Sessao SO' cai quando o servidor recusa o token. Antes, qualquer
			# falha apagava o login guardado -- e "sem sinal" chega aqui igual a
			# "token invalido". Na pratica: metro, aviao, wi-fi ruim ou servidor
			# fora do ar deslogavam o jogador de vez, e ele so' descobria depois.
			# Guardar a sessao nao custa nada: se o token estiver mesmo morto, a
			# proxima tentativa recebe 401 e ai' sim ela e' apagada.
			if sem_resposta(r, status) or status >= 500:
				print("AUTH: refresh sem resposta (resultado=", r, " status=", status,
					"); mantendo a sessao para tentar de novo")
				return
			print("AUTH: refresh recusado status=", status, "; encerrando a sessao")
			_limpar_local()
			return
		_aplicar_sessao(dados as Dictionary, false))
	http.request(_TOKEN + "?grant_type=refresh_token", _headers(false), HTTPClient.METHOD_POST, body)


func _guardar_sessao() -> void:
	var f := FileAccess.open_encrypted_with_pass(_ARQ_SESSAO, FileAccess.WRITE, _CHAVE_SESSAO)
	if f == null:
		return
	f.store_string(JSON.stringify({
		"access": _access, "refresh": _refresh,
		"uid": _uid, "expira": _expira_em,
	}))
	f.close()


func _limpar_local() -> void:
	_access = ""; _refresh = ""; _uid = ""; _expira_em = 0
	if FileAccess.file_exists(_ARQ_SESSAO):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(_ARQ_SESSAO))


# ── Helpers ──────────────────────────────────────────────────────────────────

func _headers(com_bearer: bool) -> PackedStringArray:
	var h := PackedStringArray([
		"apikey: " + RankingOnline._ANON,
		"Content-Type: application/json",
	])
	if com_bearer and _access != "":
		h.append("Authorization: Bearer " + _access)
	return h


func _cancelar(msg: String) -> void:
	_fechar_server()
	_ativo = false
	login_falhou.emit(msg)


func _fechar_server() -> void:
	if _server:
		_server.stop()
		_server = null


static func _b64url(bytes: PackedByteArray) -> String:
	return Marshalls.raw_to_base64(bytes).replace("+", "-").replace("/", "_").replace("=", "")
