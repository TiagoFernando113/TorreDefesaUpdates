extends Node
## Ranking online com cache local + posição estimada + autenticação por nome/senha.

const _URL_BASE      : String = "https://npbqezpfjrjvsqwvgtfy.supabase.co/rest/v1/ranking"
const _URL_USUARIOS  : String = "https://npbqezpfjrjvsqwvgtfy.supabase.co/rest/v1/usuarios"
const _URL_SAVES     : String = "https://npbqezpfjrjvsqwvgtfy.supabase.co/rest/v1/saves"
const _URL_BETA_SKIN : String = "https://npbqezpfjrjvsqwvgtfy.supabase.co/rest/v1/beta_skin"
const _URL_AVALIACOES: String = "https://npbqezpfjrjvsqwvgtfy.supabase.co/rest/v1/avaliacoes"
const _URL_DISCORD_LINK   : String = "https://npbqezpfjrjvsqwvgtfy.supabase.co/rest/v1/rpc/confirm_discord_link"
const _URL_CLAIM_REWARDS  : String = "https://npbqezpfjrjvsqwvgtfy.supabase.co/rest/v1/rpc/claim_pending_rewards"
const _URL_DISCORD_INVITE_REQUEST : String = "https://npbqezpfjrjvsqwvgtfy.supabase.co/rest/v1/rpc/request_discord_join_invite"
const _URL_DISCORD_INVITE_STATUS  : String = "https://npbqezpfjrjvsqwvgtfy.supabase.co/rest/v1/rpc/get_discord_join_invite_status"
const _URL_DISCORD_INVITE_CONFIRM : String = "https://npbqezpfjrjvsqwvgtfy.supabase.co/rest/v1/rpc/claim_discord_join_reward_by_request"
const _URL_SUBMIT_RANKING : String = "https://npbqezpfjrjvsqwvgtfy.supabase.co/rest/v1/rpc/submit_ranking"
const _URL_REMOVE_RANKING : String = "https://npbqezpfjrjvsqwvgtfy.supabase.co/rest/v1/rpc/remove_ranking_entry"
const _BETA_MAX          : int    = 10
const _ANON              : String = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im5wYnFlenBmanJqdnNxd3ZndGZ5Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzY1MzEwODAsImV4cCI6MjA5MjEwNzA4MH0.-eJ1DWs3ujkSEgR7YYj98AzMlOBRu9v1Uj-oy-8zT88"
# Temporadas: época de início (2026-05-10 00:00 UTC) + duração em segundos
const _TEMPORADA_EPOCH   : int    = 1778371200
const _TEMPORADA_DURACAO : int    = 30 * 24 * 3600   # 30 dias

signal ranking_carregado(entradas: Array)
signal envio_concluido(ok: bool)
signal registro_concluido(ok: bool, erro: String)
signal login_verificado(ok: bool, nome: String, email: String)
signal save_enviado(ok: bool)
signal save_recebido(ok: bool, dados: Dictionary)
signal email_atualizado(ok: bool)
signal beta_info_recebida(restantes: int, donos: Array)
signal beta_resgatado(ok: bool, erro: String)
signal sincronizacao_concluida   # emitido após sincronizar_nome terminar (ok ou não)
signal discord_vinculo_concluido(ok: bool, erro: String)
signal discord_invite_pronto(ok: bool, url: String, erro: String)
signal premios_bot_aplicados(qtd: int)
signal premio_temporada_aplicado(posicao: int, temporada: int, baus_lendarios: int, cristais: int)
signal campeoes_temporada_anterior_carregados(temporada: int, entradas: Array)

# Cache único (ranking universal)
var _cache           : Array = []
var _cache_timestamp : int   = -1

var _http_envio   : HTTPRequest = null
var _http_busca   : HTTPRequest = null
var _http_qualif  : HTTPRequest = null
var _http_usuario : HTTPRequest = null
var _http_delete  : HTTPRequest = null
var _http_save    : HTTPRequest = null
var _http_beta    : HTTPRequest = null
var _http_aval    : HTTPRequest = null
var _http_avatar  : HTTPRequest = null
var _http_rename  : HTTPRequest = null
var _http_discord : HTTPRequest = null
var _http_discord_invite : HTTPRequest = null
var _http_rewards : HTTPRequest = null
var _http_temporada_premio : HTTPRequest = null
var _http_campeoes_temporada_anterior : HTTPRequest = null

signal rename_concluido(ok: bool)
var _rename_etapa  : String = ""
var _rename_antigo : String = ""
var _rename_novo   : String = ""
var _beta_modo    : String      = ""   # "buscar" ou "resgatar"
var _beta_nome    : String      = ""
var _save_modo          : String   = ""   # "upload" ou "download"
var _cb_save            : Callable = Callable()
var _save_nome_fallback : String   = ""   # fallback para busca por nome quando player_id não retorna nada
var _pending_insert : Dictionary = {}   # dados aguardando após o DELETE
var _discord_invite_modo : String = ""
var _discord_invite_request_id : String = ""
var _discord_invite_tentativas : int = 0

# Fila de envios pendentes — evita dropar scores quando _http_qualif está ocupado
var _fila_qualif : Array = []   # Array de {nome, score, wave}

# Callback de login (chamado após verificar_login)
var _cb_login : Callable = Callable()
# Flag para saber se o http_usuario está em modo registro (true) ou login (false)
var _usuario_modo_registro : bool = false
var _usuario_modo_email    : bool = false
var _usuario_modo_sync     : bool = false


func _ready() -> void:
	for slot in ["_http_envio", "_http_busca", "_http_qualif", "_http_usuario", "_http_delete", "_http_save", "_http_beta", "_http_aval", "_http_avatar", "_http_rename", "_http_discord", "_http_discord_invite", "_http_rewards", "_http_temporada_premio", "_http_campeoes_temporada_anterior"]:
		var h := HTTPRequest.new()
		h.timeout = 15.0
		h.use_threads = false
		add_child(h)
		set(slot, h)
	_http_envio.request_completed.connect(_on_envio_resposta)
	_http_busca.request_completed.connect(_on_busca_resposta)
	_http_qualif.request_completed.connect(_on_qualif_resposta)
	_http_usuario.request_completed.connect(_on_usuario_resposta)
	_http_delete.request_completed.connect(_on_delete_resposta)
	_http_save.request_completed.connect(_on_save_resposta)
	_http_beta.request_completed.connect(_on_beta_resposta)
	_http_aval.request_completed.connect(_on_aval_resposta)
	_http_rename.request_completed.connect(_on_rename_resposta)
	_http_discord.request_completed.connect(_on_discord_link_resposta)
	_http_discord_invite.request_completed.connect(_on_discord_invite_resposta)
	_http_rewards.request_completed.connect(_on_claim_rewards_resposta)
	_http_temporada_premio.request_completed.connect(_on_temporada_premio_resposta)
	_http_campeoes_temporada_anterior.request_completed.connect(_on_campeoes_temporada_anterior_resposta)


# ── Utilitários de header ──────────────────────────────────────────────────────

func _headers_json() -> PackedStringArray:
	return PackedStringArray([
		"apikey: " + _ANON, "Authorization: Bearer " + _ANON,
		"Content-Type: application/json", "Prefer: return=minimal",
	])


func _headers_json_repr() -> PackedStringArray:
	return PackedStringArray([
		"apikey: " + _ANON, "Authorization: Bearer " + _ANON,
		"Content-Type: application/json", "Prefer: return=representation",
	])


func _headers_get() -> PackedStringArray:
	return PackedStringArray(["apikey: " + _ANON, "Authorization: Bearer " + _ANON])


func _hash(s: String) -> String:
	var ctx := HashingContext.new()
	ctx.start(HashingContext.HASH_SHA256)
	ctx.update(s.to_utf8_buffer())
	return ctx.finish().hex_encode()


# ── API pública — ranking ──────────────────────────────────────────────────────

func get_lista_estimada() -> Array:
	var base : Array = _cache.duplicate(true)
	var nome  : String = Salvar.nome_jogador.strip_edges()
	if nome == "":
		return base
	var wave_local : int = Salvar.melhor_wave
	if wave_local <= 0:
		return base
	base = base.filter(func(e): return (e as Dictionary).get("nome","") != nome)
	base.append({
		"nome": nome, "score": Salvar.high_score,
		"wave": wave_local, "temporada": _temporada_atual(),
		"local": true, "avatar_idx": Salvar.avatar_idx,
		"ascensoes": Salvar.ascensoes,
	})
	base.sort_custom(func(a, b):
		var wa: int = int((a as Dictionary).get("wave", 0))
		var wb: int = int((b as Dictionary).get("wave", 0))
		if wa == wb:
			return int((a as Dictionary).get("score", 0)) > int((b as Dictionary).get("score", 0))
		return wa > wb
	)
	if base.size() > 50:
		base.resize(50)
	return base


func segundos_desde_atualizacao() -> int:
	if _cache_timestamp < 0:
		return -1
	return int(Time.get_unix_time_from_system()) - _cache_timestamp


func buscar_ranking() -> void:
	if _http_busca.get_http_client_status() != HTTPClient.STATUS_DISCONNECTED:
		_http_busca.cancel_request()
	var url := _ranking_temporada_url(_temporada_atual(), 50)
	_http_busca.request(url, _headers_get())


func _ranking_temporada_url(temporada: int, limite: int) -> String:
	return _URL_BASE + "?order=wave.desc,score.desc&limit=%d&select=nome,score,wave,temporada,criado_em,avatar_idx,ascensoes&temporada=eq.%d" % [limite, temporada]


func _parse_ranking_entries(body: PackedByteArray) -> Array:
	var json := JSON.new()
	if json.parse(body.get_string_from_utf8()) != OK:
		return []
	var data = json.get_data()
	return data if data is Array else []


func temporada_atual() -> int:
	return _temporada_atual()


func temporada_anterior() -> int:
	return _temporada_atual() - 1


func temporada_display_numero() -> int:
	return _temporada_atual() + 1


func segundos_para_fim_temporada() -> int:
	var atual: int = _temporada_atual()
	var fim: int = _TEMPORADA_EPOCH + (atual + 1) * _TEMPORADA_DURACAO
	return maxi(0, fim - int(Time.get_unix_time_from_system()))


func temporada_duracao_dias() -> int:
	return maxi(1, _TEMPORADA_DURACAO / (24 * 3600))


func premio_temporada_info(posicao: int) -> Dictionary:
	match posicao:
		1:
			return {"baus_lendarios": 3, "cristais": 300}
		2:
			return {"baus_lendarios": 2, "cristais": 180}
		3:
			return {"baus_lendarios": 1, "cristais": 100}
	return {"baus_lendarios": 0, "cristais": 0}


func buscar_campeoes_temporada_anterior() -> void:
	var temporada_fechada: int = temporada_anterior()
	if temporada_fechada < 0:
		emit_signal("campeoes_temporada_anterior_carregados", temporada_fechada, [])
		return
	if _http_campeoes_temporada_anterior.get_http_client_status() != HTTPClient.STATUS_DISCONNECTED:
		return
	_http_campeoes_temporada_anterior.request(_ranking_temporada_url(temporada_fechada, 3), _headers_get())


func _on_campeoes_temporada_anterior_resposta(result: int, code: int, _h: PackedStringArray, body: PackedByteArray) -> void:
	var temporada_fechada: int = temporada_anterior()
	var entradas: Array = []
	if result == HTTPRequest.RESULT_SUCCESS and code == 200:
		var parsed = JSON.parse_string(body.get_string_from_utf8())
		if parsed is Array:
			for row in (parsed as Array):
				if row is Dictionary:
					entradas.append(row)
	emit_signal("campeoes_temporada_anterior_carregados", temporada_fechada, entradas)


func checar_premio_temporada() -> void:
	var temporada_fechada: int = _temporada_atual() - 1
	if temporada_fechada < 0:
		return
	if Salvar.ranking_temporada_premiada >= temporada_fechada:
		return
	if Salvar.nome_jogador.strip_edges() == "":
		return
	if _http_temporada_premio.get_http_client_status() != HTTPClient.STATUS_DISCONNECTED:
		return
	var url := _ranking_temporada_url(temporada_fechada, 3)
	_http_temporada_premio.request(url, _headers_get())


## Envia score para o ranking. Usa fila para não perder envios simultâneos.
func atualizar_avatar(nome: String, avatar_idx: int) -> void:
	if nome.strip_edges() == "":
		return
	if _http_avatar.get_http_client_status() != HTTPClient.STATUS_DISCONNECTED:
		return
	var url  := _URL_BASE + "?nome=eq." + nome.strip_edges().uri_encode()
	var body := JSON.stringify({
		"avatar_idx": avatar_idx,
		"ascensoes":  Salvar.ascensoes,
	})
	_http_avatar.request(url, _headers_json(), HTTPClient.METHOD_PATCH, body)


func verificar_e_enviar(nome: String, score: int, wave: int) -> void:
	if wave <= 0 or nome.strip_edges() == "" or Salvar.senha_jogador == "":
		return
	if wave < Salvar.melhor_wave:
		return
	_fila_qualif.append({"nome": nome.strip_edges(), "score": score, "wave": wave, "avatar_idx": Salvar.avatar_idx, "ascensoes": Salvar.ascensoes})
	_processar_fila()


func _processar_fila() -> void:
	if _fila_qualif.is_empty():
		return
	if _http_qualif.get_http_client_status() != HTTPClient.STATUS_DISCONNECTED:
		return
	var p    : Dictionary = _fila_qualif[0] as Dictionary
	var body : String     = JSON.stringify({
		"p_nome":       p["nome"],
		"p_senha_hash": Salvar.senha_jogador,
		"p_wave":       p["wave"],
		"p_score":      p["score"],
		"p_avatar_idx": int(p.get("avatar_idx", 0)),
		"p_temporada":  _temporada_atual(),
		"p_ascensoes":  int(p.get("ascensoes", 0)),
	})
	_http_qualif.request(_URL_SUBMIT_RANKING, _headers_json_repr(), HTTPClient.METHOD_POST, body)


func checar_diario() -> void:
	if Salvar.nome_jogador.strip_edges() == "":
		return
	var hoje : int = _dia_atual()
	if Salvar.ultimo_check_ranking == hoje:
		return
	Salvar.ultimo_check_ranking = hoje
	Salvar.salvar()
	_enviar_todos_recordes()
	atualizar_avatar(Salvar.nome_jogador, Salvar.avatar_idx)
	checar_premio_temporada()


func envio_inicial() -> void:
	if Salvar.nome_jogador.strip_edges() == "":
		return
	Salvar.ultimo_check_ranking = _dia_atual()
	Salvar.salvar()
	_enviar_todos_recordes()
	atualizar_avatar(Salvar.nome_jogador, Salvar.avatar_idx)
	checar_premio_temporada()


func _enviar_todos_recordes() -> void:
	if Salvar.melhor_wave > 0:
		verificar_e_enviar(Salvar.nome_jogador, Salvar.high_score, Salvar.melhor_wave)


# ── API pública — autenticação ─────────────────────────────────────────────────

## Registra nome+email+senha. Emite registro_concluido(true,"") ou (false, erro).
func registrar_nome(nome: String, email: String, senha: String) -> void:
	if _http_usuario.get_http_client_status() != HTTPClient.STATUS_DISCONNECTED:
		_http_usuario.cancel_request()
	_usuario_modo_registro = true
	var body := JSON.stringify({
		"nome": nome.strip_edges().left(20),
		"email": email.strip_edges().left(100),
		"senha": _hash(senha),
	})
	# return=representation para receber a linha criada (inclui player_id gerado pelo servidor)
	var err := _http_usuario.request(_URL_USUARIOS, _headers_json_repr(), HTTPClient.METHOD_POST, body)
	if err != OK:
		emit_signal("registro_concluido", false, "Falha ao iniciar requisição (err %d)." % err)


## Adiciona email a conta existente (usuários antigos sem email).
func adicionar_email(nome: String, senha: String, email: String) -> void:
	if _http_usuario.get_http_client_status() != HTTPClient.STATUS_DISCONNECTED:
		_http_usuario.cancel_request()
	_usuario_modo_registro = false
	_usuario_modo_email    = true
	var url  := _URL_USUARIOS + "?nome=eq.%s&senha=eq.%s" % [
		nome.strip_edges().uri_encode(), _hash(senha).uri_encode()
	]
	var body := JSON.stringify({"email": email.strip_edges().left(100)})
	var h    := PackedStringArray([
		"apikey: " + _ANON, "Authorization: Bearer " + _ANON,
		"Content-Type: application/json", "Prefer: return=minimal",
	])
	_http_usuario.request(url, h, HTTPClient.METHOD_PATCH, body)


## Busca o nome atual e player_id no servidor pela senha — corrige divergência multi-dispositivo.
func sincronizar_nome() -> void:
	if Salvar.senha_jogador == "" or Salvar.nome_jogador == "":
		return
	if _http_usuario.get_http_client_status() != HTTPClient.STATUS_DISCONNECTED:
		return
	_usuario_modo_registro = false
	_usuario_modo_email    = false
	_usuario_modo_sync     = true
	var url : String
	if Salvar.player_id != "":
		url = _URL_USUARIOS + "?player_id=eq.%s&select=nome,player_id,id_sequencial" % Salvar.player_id.uri_encode()
	else:
		url = _URL_USUARIOS + "?senha=eq.%s&select=nome,player_id,id_sequencial" % Salvar.senha_jogador.uri_encode()
	_http_usuario.request(url, _headers_get())


## Login por nome OU email + senha. Emite login_verificado(ok, nome, email).
func verificar_login(identificador: String, senha: String, cb: Callable) -> void:
	if _http_usuario.get_http_client_status() != HTTPClient.STATUS_DISCONNECTED:
		_http_usuario.cancel_request()
	_usuario_modo_registro = false
	_cb_login = cb
	var id := identificador.strip_edges().uri_encode()
	var url := _URL_USUARIOS + "?or=(nome.eq.%s,email.eq.%s)&senha=eq.%s&select=nome,email,player_id,id_sequencial" % [
		id, id, _hash(senha).uri_encode()
	]
	_http_usuario.request(url, _headers_get())


func confirmar_discord_link(code: String) -> void:
	var clean_code := code.strip_edges().to_upper()
	if clean_code == "":
		emit_signal("discord_vinculo_concluido", false, "Codigo de vinculo ausente.")
		return
	if Salvar.nome_jogador == "" or Salvar.senha_jogador == "":
		emit_signal("discord_vinculo_concluido", false, "Entre na sua conta do jogo antes de vincular o Discord.")
		return
	if _http_discord.get_http_client_status() != HTTPClient.STATUS_DISCONNECTED:
		_http_discord.cancel_request()
	var body := JSON.stringify({
		"p_code": clean_code,
		"p_player_id": Salvar.player_id,
		"p_nome": Salvar.nome_jogador,
		"p_senha_hash": Salvar.senha_jogador,
	})
	_http_discord.request(_URL_DISCORD_LINK, _headers_json_repr(), HTTPClient.METHOD_POST, body)


func solicitar_discord_invite() -> void:
	if Salvar.nome_jogador == "" or Salvar.senha_jogador == "":
		emit_signal("discord_invite_pronto", false, "", "Entre na sua conta para receber o premio do Discord.")
		return
	if _http_discord_invite.get_http_client_status() != HTTPClient.STATUS_DISCONNECTED:
		emit_signal("discord_invite_pronto", false, "", "Aguarde o convite anterior terminar.")
		return
	_discord_invite_modo = "request"
	_discord_invite_request_id = ""
	_discord_invite_tentativas = 0
	var body := JSON.stringify({
		"p_player_id": Salvar.player_id,
		"p_nome": Salvar.nome_jogador,
		"p_senha_hash": Salvar.senha_jogador,
	})
	_http_discord_invite.request(_URL_DISCORD_INVITE_REQUEST, _headers_json_repr(), HTTPClient.METHOD_POST, body)


func _consultar_discord_invite_status() -> void:
	if _discord_invite_request_id == "":
		emit_signal("discord_invite_pronto", false, "", "Pedido de convite ausente.")
		return
	if _http_discord_invite.get_http_client_status() != HTTPClient.STATUS_DISCONNECTED:
		return
	_discord_invite_modo = "status"
	_discord_invite_tentativas += 1
	var body := JSON.stringify({"p_request_id": _discord_invite_request_id})
	_http_discord_invite.request(_URL_DISCORD_INVITE_STATUS, _headers_json_repr(), HTTPClient.METHOD_POST, body)


func confirmar_discord_invite_aberto() -> void:
	if _discord_invite_request_id == "":
		return
	if Salvar.nome_jogador == "" or Salvar.senha_jogador == "":
		return
	if _http_discord_invite.get_http_client_status() != HTTPClient.STATUS_DISCONNECTED:
		return
	_discord_invite_modo = "confirm_opened"
	var body := JSON.stringify({
		"p_request_id": _discord_invite_request_id,
		"p_player_id": Salvar.player_id,
		"p_nome": Salvar.nome_jogador,
		"p_senha_hash": Salvar.senha_jogador,
	})
	_http_discord_invite.request(_URL_DISCORD_INVITE_CONFIRM, _headers_json_repr(), HTTPClient.METHOD_POST, body)


func buscar_premios_pendentes() -> void:
	if Salvar.nome_jogador == "" or Salvar.senha_jogador == "":
		return
	if _http_rewards.get_http_client_status() != HTTPClient.STATUS_DISCONNECTED:
		return
	var body := JSON.stringify({
		"p_player_id": Salvar.player_id,
		"p_nome": Salvar.nome_jogador,
		"p_senha_hash": Salvar.senha_jogador,
	})
	_http_rewards.request(_URL_CLAIM_REWARDS, _headers_json_repr(), HTTPClient.METHOD_POST, body)


## Envia save completo para a nuvem (UPSERT). Usa player_id como chave quando disponível.
func upload_save(nome: String, dados: Dictionary) -> void:
	if _http_save.get_http_client_status() != HTTPClient.STATUS_DISCONNECTED:
		_http_save.cancel_request()
	_save_modo = "upload"
	var pid : String = Salvar.player_id
	var payload : Dictionary = {"nome": nome.left(20), "data": dados}
	var conflict_key : String
	if pid != "":
		payload["player_id"] = pid
		conflict_key = "player_id"
	else:
		conflict_key = "nome"
	var body := JSON.stringify(payload)
	var url := _URL_SAVES + "?on_conflict=" + conflict_key
	var h := PackedStringArray([
		"apikey: " + _ANON, "Authorization: Bearer " + _ANON,
		"Content-Type: application/json",
		"Prefer: return=minimal,resolution=merge-duplicates",
	])
	_http_save.request(url, h, HTTPClient.METHOD_POST, body)


## Baixa save da nuvem. Chama cb(ok, dados, force_sync). Usa player_id quando disponível.
func download_save(nome: String, cb: Callable) -> void:
	if _http_save.get_http_client_status() != HTTPClient.STATUS_DISCONNECTED:
		_http_save.cancel_request()
	_save_modo = "download"
	_cb_save   = cb
	_save_nome_fallback = nome.left(20)   # guardado para fallback se player_id não achar nada
	var pid : String = Salvar.player_id
	var url : String
	if pid != "":
		url = _URL_SAVES + "?player_id=eq.%s&select=data,force_sync" % pid.uri_encode()
	else:
		url = _URL_SAVES + "?nome=eq.%s&select=data,force_sync" % nome.left(20).uri_encode()
	_http_save.request(url, _headers_get())


## Apaga completamente o save da nuvem (reset total da conta).
func apagar_save_nuvem(nome: String, player_id_val: String) -> void:
	if _http_save.get_http_client_status() != HTTPClient.STATUS_DISCONNECTED:
		_http_save.cancel_request()
	_save_modo = "delete"
	var url : String
	if player_id_val != "":
		url = _URL_SAVES + "?player_id=eq.%s" % player_id_val.uri_encode()
	else:
		url = _URL_SAVES + "?nome=eq.%s" % nome.left(20).uri_encode()
	var h := PackedStringArray([
		"apikey: " + _ANON, "Authorization: Bearer " + _ANON,
		"Content-Type: application/json", "Prefer: return=minimal",
	])
	_http_save.request(url, h, HTTPClient.METHOD_DELETE)


## Apaga saves com nomes antigos do mesmo player_id (evita acúmulo após renames).
func limpar_saves_orfaos(nome_atual: String) -> void:
	var pid : String = Salvar.player_id
	if pid == "" or nome_atual.strip_edges() == "":
		return
	# DELETE saves onde player_id bate mas nome é diferente do atual
	var url := _URL_SAVES + "?player_id=eq.%s&nome=neq.%s" % [
		pid.uri_encode(), nome_atual.left(20).uri_encode()
	]
	var h := PackedStringArray([
		"apikey: " + _ANON, "Authorization: Bearer " + _ANON,
		"Content-Type: application/json", "Prefer: return=minimal",
	])
	_http_save.request(url, h, HTTPClient.METHOD_DELETE)


## Desativa o force_sync no Supabase após aplicar.
func _limpar_force_sync(nome: String) -> void:
	var url  := _URL_SAVES + "?nome=eq.%s" % nome.left(20).uri_encode()
	var body := JSON.stringify({"force_sync": false})
	var h := PackedStringArray([
		"apikey: " + _ANON, "Authorization: Bearer " + _ANON,
		"Content-Type: application/json", "Prefer: return=minimal",
	])
	_http_save.request(url, h, HTTPClient.METHOD_PATCH, body)


# ── Callbacks HTTP ────────────────────────────────────────────────────────────

func _on_qualif_resposta(result: int, code: int, _h: PackedStringArray, body: PackedByteArray) -> void:
	if not _fila_qualif.is_empty():
		_fila_qualif.pop_front()
	var ok : bool = result == HTTPRequest.RESULT_SUCCESS and code == 200
	emit_signal("envio_concluido", ok)
	_processar_fila()


func remover_do_ranking(nome: String) -> void:
	if nome == "" or Salvar.senha_jogador == "": return
	_pending_insert = {}
	if _http_delete.get_http_client_status() != HTTPClient.STATUS_DISCONNECTED:
		_http_delete.cancel_request()
	var body := JSON.stringify({
		"p_nome": nome.left(20),
		"p_senha_hash": Salvar.senha_jogador,
		"p_temporada": _temporada_atual(),
	})
	_http_delete.request(_URL_REMOVE_RANKING, _headers_json_repr(), HTTPClient.METHOD_POST, body)
	_cache           = []
	_cache_timestamp = -1


func _enviar(_nome: String, _score: int, _wave: int, _avatar_idx: int = 0) -> void:
	# Substituído pela RPC submit_ranking via _processar_fila.
	# Mantido apenas para compatibilidade com fluxo de rename interno.
	var url := _URL_BASE + "?nome=eq.%s&temporada=eq.%d" % [_nome.left(20).uri_encode(), _temporada_atual()]
	var h := PackedStringArray([
		"apikey: " + _ANON, "Authorization: Bearer " + _ANON,
		"Content-Type: application/json", "Prefer: return=minimal",
	])
	_http_delete.request(url, h, HTTPClient.METHOD_DELETE)


func _on_delete_resposta(_result: int, _code: int, _h: PackedStringArray, _body: PackedByteArray) -> void:
	# DELETE concluído (ok ou não) — faz o INSERT limpo agora
	if _pending_insert.is_empty():
		return
	var p : Dictionary = _pending_insert
	_pending_insert = {}
	if _http_envio.get_http_client_status() != HTTPClient.STATUS_DISCONNECTED:
		await get_tree().create_timer(1.2).timeout
	var body := JSON.stringify(p)
	var h := PackedStringArray([
		"apikey: " + _ANON, "Authorization: Bearer " + _ANON,
		"Content-Type: application/json", "Prefer: return=minimal",
	])
	_http_envio.request(_URL_BASE, h, HTTPClient.METHOD_POST, body)


func _on_envio_resposta(result: int, code: int, _h: PackedStringArray, _body: PackedByteArray) -> void:
	var ok : bool = result == HTTPRequest.RESULT_SUCCESS and code in [200, 201]
	emit_signal("envio_concluido", ok)


func _on_busca_resposta(result: int, code: int, _h: PackedStringArray, body: PackedByteArray) -> void:
	if result != HTTPRequest.RESULT_SUCCESS or code != 200:
		emit_signal("ranking_carregado", [])
		return
	var data: Array = _parse_ranking_entries(body)
	_cache = data
	_cache_timestamp = int(Time.get_unix_time_from_system())
	emit_signal("ranking_carregado", data)


func _on_usuario_resposta(result: int, code: int, _h: PackedStringArray, body: PackedByteArray) -> void:
	if _usuario_modo_sync:
		_usuario_modo_sync = false
		if result == HTTPRequest.RESULT_SUCCESS and code == 200:
			var parsed = JSON.parse_string(body.get_string_from_utf8())
			if parsed is Array and (parsed as Array).size() > 0:
				var row = (parsed as Array)[0]
				if row is Dictionary:
					var nome_sv : String = (row as Dictionary).get("nome", "") as String
					if nome_sv != "" and nome_sv != Salvar.nome_jogador:
						Salvar.nome_jogador = nome_sv
					var pid_sv = (row as Dictionary).get("player_id", null)
					if pid_sv is String and (pid_sv as String) != "":
						Salvar.player_id = pid_sv as String
					var ids_sv = (row as Dictionary).get("id_sequencial", null)
					if ids_sv != null:
						Salvar.id_sequencial = int(ids_sv)
					Salvar.salvar()
		emit_signal("sincronizacao_concluida")
		return
	if _usuario_modo_email:
		_usuario_modo_email = false
		var ok := result == HTTPRequest.RESULT_SUCCESS and code in [200, 204]
		emit_signal("email_atualizado", ok)
		return
	if _usuario_modo_registro:
		var ok   : bool   = result == HTTPRequest.RESULT_SUCCESS and code == 201
		var erro : String = ""
		if ok:
			# return=representation → recebe a linha criada, extrai player_id
			var parsed = JSON.parse_string(body.get_string_from_utf8())
			var row = null
			if parsed is Array and (parsed as Array).size() > 0:
				row = (parsed as Array)[0]
			elif parsed is Dictionary:
				row = parsed
			if row is Dictionary:
				var pid_sv = (row as Dictionary).get("player_id", null)
				if pid_sv is String and (pid_sv as String) != "":
					Salvar.player_id = pid_sv as String
				var ids_sv = (row as Dictionary).get("id_sequencial", null)
				if ids_sv != null:
					Salvar.id_sequencial = int(ids_sv)
				Salvar.salvar()
		else:
			if result != HTTPRequest.RESULT_SUCCESS:
				erro = "Sem conexão com o servidor (err %d)." % result
			elif code == 409:
				erro = "Nome ou e-mail já está em uso."
			else:
				erro = "Erro ao registrar (HTTP %d). Tente novamente." % code
		emit_signal("registro_concluido", ok, erro)
	else:
		var ok        : bool   = false
		var nome_ret  : String = ""
		var email_ret : String = ""
		if result == HTTPRequest.RESULT_SUCCESS and code == 200:
			var json := JSON.new()
			if json.parse(body.get_string_from_utf8()) == OK:
				var data = json.get_data()
				if data is Array and (data as Array).size() > 0:
					ok = true
					var row = (data as Array)[0]
					if row is Dictionary:
						var nv = (row as Dictionary).get("nome",  "")
						var ev = (row as Dictionary).get("email", "")
						nome_ret  = nv as String if nv is String else ""
						email_ret = ev as String if ev is String else ""
						var pid_sv = (row as Dictionary).get("player_id", null)
						if pid_sv is String and (pid_sv as String) != "":
							Salvar.player_id = pid_sv as String
						var ids_sv2 = (row as Dictionary).get("id_sequencial", null)
						if ids_sv2 != null:
							Salvar.id_sequencial = int(ids_sv2)
						Salvar.salvar()
						# Limpa saves de nomes antigos do mesmo player_id
						if Salvar.player_id != "":
							limpar_saves_orfaos(nome_ret)
		emit_signal("login_verificado", ok, nome_ret, email_ret)
		if _cb_login.is_valid():
			_cb_login.call(ok)
			_cb_login = Callable()


func _on_save_resposta(result: int, code: int, _h: PackedStringArray, body: PackedByteArray) -> void:
	if _save_modo == "delete":
		return
	if _save_modo == "upload":
		var ok := result == HTTPRequest.RESULT_SUCCESS and code in [200, 201]
		emit_signal("save_enviado", ok)
	else:
		var ok         : bool       = false
		var dados      : Dictionary = {}
		var force_sync : bool       = false
		if result == HTTPRequest.RESULT_SUCCESS and code == 200:
			var json := JSON.new()
			if json.parse(body.get_string_from_utf8()) == OK:
				var data = json.get_data()
				# player_id retornou vazio → tenta fallback por nome
				if data is Array and (data as Array).size() == 0 and _save_nome_fallback != "" and Salvar.player_id != "":
					var url := _URL_SAVES + "?nome=eq.%s&select=data,force_sync" % _save_nome_fallback.uri_encode()
					_save_nome_fallback = ""
					_http_save.request(url, _headers_get())
					return
				if data is Array and (data as Array).size() > 0:
					var row = (data as Array)[0]
					if row is Dictionary:
						force_sync = (row as Dictionary).get("force_sync", false) == true
						var d = (row as Dictionary).get("data")
						if d is Dictionary:
							dados = d as Dictionary
							ok    = true
		_save_nome_fallback = ""
		emit_signal("save_recebido", ok, dados)
		if _cb_save.is_valid():
			_cb_save.call(ok, dados, force_sync)
			_cb_save = Callable()


func _on_discord_link_resposta(result: int, code: int, _h: PackedStringArray, body: PackedByteArray) -> void:
	if result != HTTPRequest.RESULT_SUCCESS:
		emit_signal("discord_vinculo_concluido", false, "Sem conexao com o Supabase.")
		return
	if code in [200, 201]:
		var parsed = JSON.parse_string(body.get_string_from_utf8())
		if parsed is Dictionary:
			var ok : bool = (parsed as Dictionary).get("ok", false) == true
			var erro := (parsed as Dictionary).get("erro", "") as String
			emit_signal("discord_vinculo_concluido", ok, erro)
			return
	emit_signal("discord_vinculo_concluido", false, "Erro ao confirmar vinculo (HTTP %d)." % code)


func _on_discord_invite_resposta(result: int, code: int, _h: PackedStringArray, body: PackedByteArray) -> void:
	if result != HTTPRequest.RESULT_SUCCESS:
		if _discord_invite_modo == "confirm_opened":
			return
		emit_signal("discord_invite_pronto", false, "", "Sem conexao com o Supabase.")
		return
	if not (code in [200, 201]):
		if _discord_invite_modo == "confirm_opened":
			return
		emit_signal("discord_invite_pronto", false, "", "Erro ao preparar convite (HTTP %d)." % code)
		return
	var parsed = JSON.parse_string(body.get_string_from_utf8())
	if not (parsed is Dictionary):
		if _discord_invite_modo == "confirm_opened":
			return
		emit_signal("discord_invite_pronto", false, "", "Resposta invalida do servidor.")
		return
	var data : Dictionary = parsed as Dictionary
	if not (data.get("ok", false) == true):
		if _discord_invite_modo == "confirm_opened":
			return
		emit_signal("discord_invite_pronto", false, "", String(data.get("erro", "Nao foi possivel gerar convite.")))
		return
	if _discord_invite_modo == "confirm_opened":
		buscar_premios_pendentes()
		return
	var status := String(data.get("status", ""))
	var invite_url := String(data.get("invite_url", ""))
	if data.has("request_id"):
		_discord_invite_request_id = String(data.get("request_id", ""))
	if invite_url != "":
		emit_signal("discord_invite_pronto", true, invite_url, "")
		return
	if _discord_invite_modo == "request":
		status = String(data.get("status", "pending"))
	if status in ["pending", "ready"] and _discord_invite_tentativas < 12:
		await get_tree().create_timer(1.0).timeout
		_consultar_discord_invite_status()
		return
	emit_signal("discord_invite_pronto", false, "", "Convite ainda nao ficou pronto. Tente novamente.")


func _on_claim_rewards_resposta(result: int, code: int, _h: PackedStringArray, body: PackedByteArray) -> void:
	if result != HTTPRequest.RESULT_SUCCESS or code != 200:
		return
	var parsed = JSON.parse_string(body.get_string_from_utf8())
	if not (parsed is Dictionary):
		return
	if not ((parsed as Dictionary).get("ok", false) == true):
		return
	var rewards = (parsed as Dictionary).get("rewards", [])
	if not (rewards is Array):
		return
	var applied := 0
	for reward in (rewards as Array):
		if reward is Dictionary:
			var tipo := (reward as Dictionary).get("reward_type", "") as String
			var qtd := int((reward as Dictionary).get("amount", 0))
			if Salvar.aplicar_premio_bot(tipo, qtd):
				applied += 1
	if applied > 0:
		Salvar.discord_reward_claimed = true
		Salvar.salvar(false)
		upload_save(Salvar.nome_jogador, Salvar.exportar_cloud())
		emit_signal("premios_bot_aplicados", applied)


func _on_temporada_premio_resposta(result: int, code: int, _h: PackedStringArray, body: PackedByteArray) -> void:
	var temporada_fechada: int = _temporada_atual() - 1
	if temporada_fechada < 0:
		return
	if result != HTTPRequest.RESULT_SUCCESS or code != 200:
		return
	var parsed = JSON.parse_string(body.get_string_from_utf8())
	if not (parsed is Array):
		return
	var nome_local: String = Salvar.nome_jogador.strip_edges()
	var posicao: int = -1
	for i in range(mini(3, (parsed as Array).size())):
		var row = (parsed as Array)[i]
		if row is Dictionary:
			var nome_rank: String = str((row as Dictionary).get("nome", "")).strip_edges()
			if nome_rank == nome_local:
				posicao = i + 1
				break
	if posicao > 0:
		var premio: Dictionary = premio_temporada_info(posicao)
		var baus_l: int = int(premio.get("baus_lendarios", 0))
		var cristais_p: int = int(premio.get("cristais", 0))
		if Salvar.aplicar_premio_temporada(posicao, temporada_fechada, baus_l, cristais_p):
			upload_save(Salvar.nome_jogador, Salvar.exportar_cloud())
			emit_signal("premio_temporada_aplicado", posicao, temporada_fechada, baus_l, cristais_p)
	else:
		Salvar.ranking_temporada_premiada = temporada_fechada
		Salvar.salvar()


# ── Rename ────────────────────────────────────────────────────────────────────

## Renomeia usuário no servidor.
## Com player_id: PATCH usuarios → DELETE ranking → PATCH save.nome (sem DELETE/reupload).
## Sem player_id (retrocompat): PATCH usuarios → DELETE ranking → DELETE save → re-upload.
## senha_hash deve ser Salvar.senha_jogador (já é SHA-256, não passar senha raw).
func _on_campeoes_temporada_anterior_resposta(result: int, code: int, _h: PackedStringArray, body: PackedByteArray) -> void:
	var temporada_fechada: int = temporada_anterior()
	if temporada_fechada < 0:
		emit_signal("campeoes_temporada_anterior_carregados", temporada_fechada, [])
		return
	if result != HTTPRequest.RESULT_SUCCESS or code != 200:
		emit_signal("campeoes_temporada_anterior_carregados", temporada_fechada, [])
		return
	var entradas: Array = _parse_ranking_entries(body)
	var top3: Array = []
	for i in range(mini(3, entradas.size())):
		if entradas[i] is Dictionary:
			top3.append(entradas[i])
	emit_signal("campeoes_temporada_anterior_carregados", temporada_fechada, top3)


func renomear(nome_antigo: String, nome_novo: String, senha_hash: String) -> void:
	var ant := nome_antigo.strip_edges().left(20)
	var nov := nome_novo.strip_edges().left(20)
	if ant == "" or nov == "" or ant == nov:
		emit_signal("rename_concluido", ant == nov)
		return
	if _http_rename.get_http_client_status() != HTTPClient.STATUS_DISCONNECTED:
		_http_rename.cancel_request()
	# Bloqueia uploads durante toda a sequência do rename
	Salvar._rename_em_curso = true
	Salvar._cloud_pendente  = false
	Salvar._cloud_timer     = 0.0
	_rename_antigo = ant
	_rename_novo   = nov
	if senha_hash != "":
		_rename_etapa = "patch_usuario"
		var pid : String = Salvar.player_id
		var url : String
		if pid != "":
			url = _URL_USUARIOS + "?player_id=eq.%s" % pid.uri_encode()
		else:
			url = _URL_USUARIOS + "?nome=eq.%s&senha=eq.%s" % [ant.uri_encode(), senha_hash.uri_encode()]
		var body := JSON.stringify({"nome": nov})
		_http_rename.request(url, _headers_json(), HTTPClient.METHOD_PATCH, body)
	else:
		_rename_etapa = "delete_ranking"
		var url := _URL_BASE + "?nome=eq." + ant.uri_encode()
		_http_rename.request(url, _headers_json(), HTTPClient.METHOD_DELETE)


func _on_rename_resposta(result: int, code: int, _h: PackedStringArray, _body: PackedByteArray) -> void:
	var ok := result == HTTPRequest.RESULT_SUCCESS and code in [200, 204]
	match _rename_etapa:
		"patch_usuario":
			if not ok:
				_rename_etapa = ""
				Salvar._rename_em_curso = false
				emit_signal("rename_concluido", false)
				return
			_rename_etapa = "delete_ranking"
			var url := _URL_BASE + "?nome=eq." + _rename_antigo.uri_encode()
			_http_rename.request(url, _headers_json(), HTTPClient.METHOD_DELETE)
		"delete_ranking":
			# Com player_id: PATCH saves.nome em vez de DELETE+reupload
			if Salvar.player_id != "":
				_rename_etapa = "patch_save_nome"
				var url := _URL_SAVES + "?player_id=eq.%s" % Salvar.player_id.uri_encode()
				var body := JSON.stringify({"nome": _rename_novo})
				_http_rename.request(url, _headers_json(), HTTPClient.METHOD_PATCH, body)
			else:
				_rename_etapa = "delete_save"
				var url := _URL_SAVES + "?nome=eq." + _rename_antigo.uri_encode()
				_http_rename.request(url, _headers_json(), HTTPClient.METHOD_DELETE)
		"patch_save_nome":
			_rename_etapa = ""
			Salvar.nome_jogador      = _rename_novo
			Salvar.nome_ja_renomeado = true
			Salvar._rename_em_curso  = false
			Salvar.salvar()
			limpar_saves_orfaos(_rename_novo)
			envio_inicial()
			emit_signal("rename_concluido", true)
		"delete_save":
			_rename_etapa = ""
			Salvar.nome_jogador      = _rename_novo
			Salvar.nome_ja_renomeado = true
			Salvar._rename_em_curso  = false
			Salvar.salvar()
			envio_inicial()
			upload_save(_rename_novo, Salvar.exportar_cloud())
			emit_signal("rename_concluido", true)


# ── Utilitários internos ──────────────────────────────────────────────────────

func _temporada_atual() -> int:
	var now := int(Time.get_unix_time_from_system())
	return maxi(0, (now - _TEMPORADA_EPOCH) / _TEMPORADA_DURACAO)


func _dia_atual() -> int:
	var t := Time.get_date_dict_from_system()
	return (t["year"] as int) * 10000 + (t["month"] as int) * 100 + (t["day"] as int)


# ── Beta Skin ─────────────────────────────────────────────────────────────────

func buscar_info_beta() -> void:
	# Cancela requisição travada antes de iniciar nova
	if _http_beta.get_http_client_status() != HTTPClient.STATUS_DISCONNECTED:
		_http_beta.cancel_request()
	_beta_modo = "buscar"
	_http_beta.request(_URL_BETA_SKIN + "?select=nome,resgatado_em&order=resgatado_em.asc",
		_headers_json(), HTTPClient.METHOD_GET)


func deletar_beta(nome: String) -> void:
	if nome.strip_edges() == "": return
	if _http_beta.get_http_client_status() != HTTPClient.STATUS_DISCONNECTED:
		_http_beta.cancel_request()
	_beta_modo = "deletar"
	_beta_nome = nome.strip_edges()
	_http_beta.request(
		_URL_BETA_SKIN + "?nome=eq." + _beta_nome.uri_encode(),
		_headers_json(), HTTPClient.METHOD_DELETE)


func resgatar_beta(nome: String) -> void:
	if nome.strip_edges() == "": return
	if _http_beta.get_http_client_status() != HTTPClient.STATUS_DISCONNECTED:
		return
	_beta_modo = "resgatar"
	_beta_nome = nome.strip_edges()
	var body : String = JSON.stringify({"nome": _beta_nome})
	_http_beta.request(_URL_BETA_SKIN, _headers_json(), HTTPClient.METHOD_POST, body)


func _on_beta_resposta(result: int, code: int, _h: PackedStringArray, body: PackedByteArray) -> void:
	if result != HTTPRequest.RESULT_SUCCESS:
		if _beta_modo == "buscar":
			emit_signal("beta_info_recebida", _BETA_MAX, [])
		else:
			emit_signal("beta_resgatado", false, "Sem conexão")
		return

	if _beta_modo == "buscar":
		var donos : Array = []
		if code == 200:
			var parsed = JSON.parse_string(body.get_string_from_utf8())
			if parsed is Array:
				for entry in (parsed as Array):
					if entry is Dictionary:
						donos.append((entry as Dictionary).get("nome", "") as String)
		var restantes : int = maxi(0, _BETA_MAX - donos.size())
		emit_signal("beta_info_recebida", restantes, donos)

	elif _beta_modo == "resgatar":
		if code == 201:
			# Sucesso: desbloqueia a skin localmente
			if not ("saberpunk" in Salvar.skins_desbloqueadas):
				Salvar.skins_desbloqueadas.append("saberpunk")
				Salvar.skin_ativa = "saberpunk"
				Salvar.salvar()
			emit_signal("beta_resgatado", true, "")
		elif code == 409:
			# Servidor confirma que o usuário já possui — garante desbloqueio local
			if not ("saberpunk" in Salvar.skins_desbloqueadas):
				Salvar.skins_desbloqueadas.append("saberpunk")
				Salvar.skin_ativa = "saberpunk"
				Salvar.salvar()
			emit_signal("beta_resgatado", true, "")
		else:
			var msg : String = "Erro %d" % code
			var parsed = JSON.parse_string(body.get_string_from_utf8())
			if parsed is Dictionary:
				msg = (parsed as Dictionary).get("message", msg) as String
			emit_signal("beta_resgatado", false, msg)

	elif _beta_modo == "deletar":
		if code in [200, 204]:
			# Remove skin localmente
			Salvar.skins_desbloqueadas.erase("saberpunk")
			if Salvar.skin_ativa == "saberpunk":
				Salvar.skin_ativa = "padrao"
			Salvar.salvar()
			emit_signal("beta_resgatado", true, "deletado")
		else:
			emit_signal("beta_resgatado", false, "Erro ao resetar (%d)" % code)


signal avaliacao_enviada(ok: bool)
signal avaliacoes_recebidas(ok: bool, lista: Array)

var _aval_modo : String = ""   # "enviar" ou "buscar"
var _cb_aval   : Callable = Callable()

func enviar_avaliacao(dados: Dictionary) -> void:
	_aval_modo = "enviar"
	var body := JSON.stringify(dados)
	var h := PackedStringArray([
		"apikey: " + _ANON, "Authorization: Bearer " + _ANON,
		"Content-Type: application/json", "Prefer: return=minimal",
	])
	_http_aval.request(_URL_AVALIACOES, h, HTTPClient.METHOD_POST, body)

func buscar_avaliacoes(cb: Callable) -> void:
	_aval_modo = "buscar"
	_cb_aval   = cb
	var url := _URL_AVALIACOES + "?order=criado_em.desc&limit=100&select=nome,criado_em,loja_nota,loja_texto,cartas_nota,cartas_texto,talentos_nota,talentos_texto,config_nota,config_texto,dificuldades_nota,dificuldades_texto,geral_nota,geral_texto"
	_http_aval.request(url, _headers_get())

func _on_aval_resposta(result: int, code: int, _h: PackedStringArray, body: PackedByteArray) -> void:
	if _aval_modo == "enviar":
		emit_signal("avaliacao_enviada", result == HTTPRequest.RESULT_SUCCESS and code in [200, 201])
	elif _aval_modo == "buscar":
		var lista : Array = []
		var ok : bool = false
		if result == HTTPRequest.RESULT_SUCCESS and code == 200:
			var parsed = JSON.parse_string(body.get_string_from_utf8())
			if parsed is Array:
				lista = parsed as Array
				ok    = true
		if _cb_aval.is_valid():
			_cb_aval.call(ok, lista)
			_cb_aval = Callable()
