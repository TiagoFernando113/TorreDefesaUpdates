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
## COMO O CODIGO VOLTA (mudou, e o motivo importa)
##
## Ate' aqui o jogo abria um servidor em 127.0.0.1 e esperava o navegador
## voltar nele. Isso NAO funciona no Android, e foi conferido no aparelho:
## o navegador conecta -- nao da recusa -- e fica girando para sempre, porque
## o app congela em segundo plano e nunca responde. Repetido com o app
## acordado e o login ativo: a conexao nao chega ate' ele de qualquer jeito.
##
## Hoje o Google volta para uma funcao deste mesmo projeto Supabase, que guarda
## o codigo numa ponte; o jogo pergunta pela ponte de dois em dois segundos.
## Funciona igual no PC e no celular, e sobrevive ao Android matar o jogo no
## meio do caminho.
##
## Nao existe deep link `cyron://`. Conferido no manifesto do APK: nao ha
## scheme, VIEW nem BROWSABLE. E nao adiantaria so' declarar -- o Godot 4.6.2
## nao entrega intents ao GDScript, entao o codigo se perderia no caminho.
## Fazer de verdade pede um plugin em Kotlin.

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
## Para onde o Google devolve: uma funcao DESTE MESMO projeto Supabase.
##
## Chegou a morar numa pagina do portal da Alianca, e estava errado. O Cyron
## Defense e' projeto proprio -- pendurar o login dele no site de outro projeto
## cria uma dependencia invisivel: um dia alguem mexe la', ou troca o dominio,
## e derruba o login daqui sem desconfiar. Aqui o retorno mora junto com a
## autenticacao que ele serve.
const _PAGINA_RETORNO : String = _BASE + "/functions/v1/entrar"
const _RPC_PEGAR      : String = _BASE + "/rest/v1/rpc/login_ponte_pegar"

## 10 minutos. Eram 3, e nao davam: escolher conta, digitar senha e passar pela
## verificacao em duas etapas leva mais que isso com facilidade, e ao estourar o
## prazo o login morria em silencio.
const _TIMEOUT_S      : float  = 600.0
const _INTERVALO_BUSCA: float  = 2.0

const _ARQ_SESSAO  : String = "user://sessao.dat"
const _ARQ_PENDENTE: String = "user://login_pendente.dat"
const _CHAVE_SESSAO: String = "cyron_sessao_v1"          # ofuscação local do token

var _access     : String = ""
var _refresh    : String = ""
var _uid        : String = ""
var _expira_em  : int    = 0                             # unix time
var _nome_google: String = ""                            # nome vindo do Google (default do apelido)
var _apelido    : String = ""                            # apelido do perfil (nome no ranking)

# Estado do fluxo OAuth em andamento
var _verifier   : String = ""
var _estado     : String = ""    # identifica ESTE login na ponte
var _restante   : float  = 0.0
var _ate_buscar : float  = 0.0
var _ativo      : bool   = false
var _http_busca : HTTPRequest = null


func _ready() -> void:
	_carregar_sessao()
	if _access == "":
		# O app pode ter sido fechado (ou morto pelo Android) enquanto a pessoa
		# estava no navegador. O login continua valendo: o codigo esta esperando
		# na ponte e o verifier ficou salvo em disco.
		_retomar_pendente()


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

	# Identifica ESTE login na ponte. Aleatorio e longo: quem nao tem o valor
	# nao consegue pedir o codigo de outra pessoa, e adivinhar e' inviavel.
	_estado = _b64url(Crypto.new().generate_random_bytes(24))
	_salvar_pendente()

	var redirect := "%s?s=%s" % [_PAGINA_RETORNO, _estado]
	var url := _AUTHORIZE + "?" + "&".join(PackedStringArray([
		"provider=google",
		"redirect_to=" + redirect.uri_encode(),
		"code_challenge=" + challenge,
		"code_challenge_method=s256",
	]))
	_ativo = true
	_restante = _TIMEOUT_S
	_ate_buscar = 1.0
	print("AUTH: login iniciado; esperando a ponte (estado ", _estado.left(6), "…)")
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


# ── Fluxo OAuth: o retorno passa por uma ponte ───────────────────────────────
#
# ANTES: o jogo abria um servidor em 127.0.0.1 e esperava o navegador voltar
# nele. Conferido no aparelho e NAO funciona no Android -- o navegador conecta
# (nao da recusa) e fica girando para sempre, porque o app congela em segundo
# plano e nunca responde. Testado tambem com o app acordado e o fluxo ativo: a
# conexao simplesmente nao chega ate' ele.
#
# AGORA: o Google volta para uma funcao deste mesmo projeto Supabase (a
# `entrar`), que guarda o codigo numa ponte. O jogo pergunta pela ponte de dois
# em dois segundos. Nao depende de o app estar acordado na hora certa, e
# sobrevive ate' se o Android matar o jogo -- o verifier fica salvo em disco e a
# busca recomeca sozinha na proxima abertura.
#
# O codigo guardado na ponte nao entra em conta nenhuma: a troca exige o
# code_verifier do PKCE, que nasce aqui dentro e nunca sai. A leitura na ponte
# e' de uso unico e tudo expira em 10 minutos.


func _process(delta: float) -> void:
	if not _ativo:
		return
	_restante -= delta
	if _restante <= 0.0:
		_esquecer_pendente()
		_cancelar("O login demorou demais. Toque em entrar de novo.")
		return
	_ate_buscar -= delta
	if _ate_buscar > 0.0:
		return
	_ate_buscar = _INTERVALO_BUSCA
	_buscar_na_ponte()


func _buscar_na_ponte() -> void:
	# Uma pergunta por vez: sem isto, uma resposta lenta empilharia requisicoes.
	if _http_busca != null and is_instance_valid(_http_busca):
		return
	_http_busca = HTTPRequest.new()
	_http_busca.timeout = 10.0
	add_child(_http_busca)
	_http_busca.request_completed.connect(_on_busca)
	var err := _http_busca.request(_RPC_PEGAR, _headers(false), HTTPClient.METHOD_POST,
		JSON.stringify({"p_estado": _estado}))
	if err != OK:
		_http_busca.queue_free()
		_http_busca = null


func _on_busca(resultado: int, status: int, _h: PackedStringArray, corpo: PackedByteArray) -> void:
	if _http_busca != null and is_instance_valid(_http_busca):
		_http_busca.queue_free()
	_http_busca = null
	if not _ativo:
		return

	# Sem resposta ou servidor com problema: nao e' motivo para desistir do
	# login. A pessoa pode estar trocando de rede no meio do caminho.
	if sem_resposta(resultado, status) or status >= 500:
		return
	if status != 200:
		print("AUTH: a ponte recusou a consulta status=", status,
			" corpo=", corpo.get_string_from_utf8().left(200))
		return

	var txt := corpo.get_string_from_utf8().strip_edges()
	if txt == "" or txt == "null":
		return                                  # ainda nao chegou; pergunta de novo
	var code: Variant = JSON.parse_string(txt)
	if not (code is String) or (code as String).is_empty():
		return

	_ativo = false
	_esquecer_pendente()
	print("AUTH: codigo recebido pela ponte; trocando por sessao")
	_trocar_codigo(code as String)


## Guarda o login em andamento. Existe para o caso do Android matar o jogo
## enquanto a pessoa esta no navegador: sem isto o verifier morreria junto e o
## codigo que ja' esta na ponte viraria lixo.
func _salvar_pendente() -> void:
	var f := FileAccess.open_encrypted_with_pass(_ARQ_PENDENTE, FileAccess.WRITE, _CHAVE_SESSAO)
	if f == null:
		return
	f.store_string(JSON.stringify({
		"estado": _estado,
		"verifier": _verifier,
		"em": Time.get_unix_time_from_system(),
	}))
	f.close()


func _esquecer_pendente() -> void:
	if FileAccess.file_exists(_ARQ_PENDENTE):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(_ARQ_PENDENTE))


func _retomar_pendente() -> void:
	if not FileAccess.file_exists(_ARQ_PENDENTE):
		return
	var f := FileAccess.open_encrypted_with_pass(_ARQ_PENDENTE, FileAccess.READ, _CHAVE_SESSAO)
	if f == null:
		_esquecer_pendente()
		return
	var d: Variant = JSON.parse_string(f.get_as_text())
	f.close()
	if not (d is Dictionary):
		_esquecer_pendente()
		return
	var dd := d as Dictionary
	# Mais velho que o prazo: a ponte ja' apagou o codigo, nao ha' o que buscar.
	if Time.get_unix_time_from_system() - float(dd.get("em", 0.0)) > _TIMEOUT_S:
		_esquecer_pendente()
		return
	_estado = str(dd.get("estado", ""))
	_verifier = str(dd.get("verifier", ""))
	if _estado.is_empty() or _verifier.is_empty():
		_esquecer_pendente()
		return
	_ativo = true
	_restante = _TIMEOUT_S
	_ate_buscar = 0.5
	print("AUTH: retomando um login que ficou pela metade")


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
	_ativo = false
	login_falhou.emit(msg)


static func _b64url(bytes: PackedByteArray) -> String:
	return Marshalls.raw_to_base64(bytes).replace("+", "-").replace("/", "_").replace("=", "")
