extends Node
## Matchmaking online para o Modo Arena usando Supabase REST API.
## Fluxo: cria sessão → poll a cada 2s até achar oponente ou timeout (15s) → fallback bot.

const _URL   : String = "https://npbqezpfjrjvsqwvgtfy.supabase.co/rest/v1/arena_sessoes"
const _ANON  : String = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im5wYnFlenBmanJqdnNxd3ZndGZ5Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzY1MzEwODAsImV4cCI6MjA5MjEwNzA4MH0.-eJ1DWs3ujkSEgR7YYj98AzMlOBRu9v1Uj-oy-8zT88"

const BUSCA_TIMEOUT : float = 30.0
const POLL_INTERVAL : float = 1.0
const SYNC_INTERVAL : float = 0.75

signal oponente_encontrado(nome: String)
signal timeout_sem_oponente
signal score_oponente_atualizado(score: int, wave: int, hp: int, nome: String)
signal oponente_finalizou

var _estado        : String = ""   # "" | "criando" | "buscando" | "em_partida"
var _minha_id      : String = ""   # UUID da minha sessão no Supabase
var _op_player_id  : String = ""   # player_id do oponente
var _op_nome       : String = ""
var _meu_player_id : String = ""
var _meu_nome      : String = ""

var _busca_timer   : float = 0.0
var _poll_timer    : float = 0.0
var _sync_timer    : float = 0.0

# Score local para sync
var _score_local : int = 0
var _wave_local  : int = 1
var _hp_local    : int = 100

# Candidato sendo claimado (para usar no callback)
var _claim_candidato : Dictionary = {}

# Modo do http_poll: "busca" ou "score"
var _poll_modo : String = ""

var _http_cleanup : HTTPRequest = null  # DELETE cleanup — sem callback
var _http_criar   : HTTPRequest = null  # POST nova sessão
var _http_poll    : HTTPRequest = null  # GET busca / GET score oponente
var _http_status  : HTTPRequest = null
var _http_claim   : HTTPRequest = null  # PATCH claim oponente
var _http_patch   : HTTPRequest = null  # PATCH minha sessão (status, sync)


func _ready() -> void:
	# Cleanup — sem callback conectado (fire-and-forget)
	_http_cleanup = HTTPRequest.new()
	_http_cleanup.timeout = 8.0
	add_child(_http_cleanup)

	for arr in [["_http_criar", "_on_criar_resposta"], ["_http_poll", "_on_poll_resposta"], ["_http_claim", "_on_claim_resposta"]]:
		var h := HTTPRequest.new()
		h.timeout = 10.0
		add_child(h)
		set(arr[0], h)
		h.request_completed.connect(Callable(self, arr[1]))

	_http_patch = HTTPRequest.new()
	_http_patch.timeout = 8.0
	add_child(_http_patch)

	_http_status = HTTPRequest.new()
	_http_status.timeout = 8.0
	add_child(_http_status)
	_http_status.request_completed.connect(_on_status_resposta)
	# patch é fire-and-forget, sem callback


func _headers_json() -> PackedStringArray:
	return PackedStringArray([
		"apikey: " + _ANON, "Authorization: Bearer " + _ANON,
		"Content-Type: application/json", "Prefer: return=representation",
	])


func _headers_min() -> PackedStringArray:
	return PackedStringArray([
		"apikey: " + _ANON, "Authorization: Bearer " + _ANON,
		"Content-Type: application/json", "Prefer: return=minimal",
	])


func _headers_get() -> PackedStringArray:
	return PackedStringArray(["apikey: " + _ANON, "Authorization: Bearer " + _ANON])


# ── API pública ────────────────────────────────────────────────────────────────

func iniciar_matchmaking(nome: String, player_id: String) -> void:
	var pid : String = player_id if player_id != "" else nome
	if pid == "":
		emit_signal("timeout_sem_oponente")
		return

	_meu_nome      = nome.left(20) if nome != "" else "Jogador"
	_meu_player_id = pid
	_estado        = "criando"
	_busca_timer   = 0.0
	_poll_timer    = POLL_INTERVAL
	_minha_id      = ""
	_op_player_id  = ""
	_op_nome       = ""
	_poll_modo     = ""
	_claim_candidato = {}

	# Remove sessões antigas deste jogador
	if _http_cleanup.get_http_client_status() == HTTPClient.STATUS_DISCONNECTED:
		_http_cleanup.request(
			_URL + "?player_id=eq." + _meu_player_id.uri_encode(),
			_headers_min(), HTTPClient.METHOD_DELETE
		)

	# Cria nova sessão após 0.5s (dá tempo para o DELETE terminar)
	get_tree().create_timer(0.5).timeout.connect(_criar_sessao)


func sincronizar_score(score: int, wave: int, hp: int) -> void:
	_score_local = score
	_wave_local  = wave
	_hp_local    = hp


func finalizar_partida() -> void:
	if _estado == "":
		return
	_estado = ""
	if _minha_id == "":
		return
	if _http_patch.get_http_client_status() == HTTPClient.STATUS_DISCONNECTED:
		var url := _URL + "?id=eq." + _minha_id.uri_encode()
		_http_patch.request(url, _headers_min(), HTTPClient.METHOD_PATCH,
			JSON.stringify({"status": "finalizada"}))


# ── Criação de sessão ─────────────────────────────────────────────────────────

func _criar_sessao() -> void:
	if _http_criar.get_http_client_status() != HTTPClient.STATUS_DISCONNECTED:
		get_tree().create_timer(0.3).timeout.connect(_criar_sessao)
		return
	var body := JSON.stringify({
		"player_id": _meu_player_id,
		"nome": _meu_nome,
		"status": "buscando",
		"matched_with": "",
		"score": 0, "wave": 1, "hp": 100,
	})
	_http_criar.request(_URL, _headers_json(), HTTPClient.METHOD_POST, body)


func _on_criar_resposta(result: int, code: int, _h: PackedStringArray, body: PackedByteArray) -> void:
	if result != HTTPRequest.RESULT_SUCCESS or code != 201:
		emit_signal("timeout_sem_oponente")
		return
	var parsed = JSON.parse_string(body.get_string_from_utf8())
	var row = null
	if parsed is Array and (parsed as Array).size() > 0:
		row = (parsed as Array)[0]
	if row is Dictionary:
		_minha_id = (row as Dictionary).get("id", "") as String
	if _minha_id == "":
		emit_signal("timeout_sem_oponente")
		return
	_estado = "buscando"


# ── Loop principal ────────────────────────────────────────────────────────────

func _process(delta: float) -> void:
	match _estado:
		"buscando":
			_busca_timer += delta
			if _busca_timer >= BUSCA_TIMEOUT:
				_timeout()
				return
			_poll_timer -= delta
			if _poll_timer <= 0.0:
				_poll_timer = POLL_INTERVAL
				_poll_minha_sessao()
				_poll_busca()

		"em_partida":
			_sync_timer -= delta
			if _sync_timer <= 0.0:
				_sync_timer = SYNC_INTERVAL
				_sync_partida()


# ── Busca de oponente ─────────────────────────────────────────────────────────

func _poll_busca() -> void:
	if _http_poll.get_http_client_status() != HTTPClient.STATUS_DISCONNECTED:
		return
	_poll_modo = "busca"
	var url := (
		_URL + "?status=eq.buscando&player_id=neq.%s&order=criado_em.asc&limit=1&select=id,nome,player_id"
	) % _meu_player_id.uri_encode()
	_http_poll.request(url, _headers_get())


func _poll_minha_sessao() -> void:
	if _minha_id == "" or _http_status.get_http_client_status() != HTTPClient.STATUS_DISCONNECTED:
		return
	var url := _URL + "?id=eq.%s&select=status,matched_with&limit=1" % _minha_id.uri_encode()
	_http_status.request(url, _headers_get())


func _on_status_resposta(result: int, code: int, _h: PackedStringArray, body: PackedByteArray) -> void:
	if _estado != "buscando":
		return
	if result != HTTPRequest.RESULT_SUCCESS or code != 200:
		return
	var parsed = JSON.parse_string(body.get_string_from_utf8())
	if not (parsed is Array) or (parsed as Array).is_empty():
		return
	var row = (parsed as Array)[0]
	if not (row is Dictionary):
		return
	var status : String = (row as Dictionary).get("status", "") as String
	var matched : String = (row as Dictionary).get("matched_with", "") as String
	if status == "em_partida" and matched != "":
		_entrar_em_partida(matched, "Oponente")


func _on_poll_resposta(result: int, code: int, _h: PackedStringArray, body: PackedByteArray) -> void:
	if result != HTTPRequest.RESULT_SUCCESS or code != 200:
		return
	var parsed = JSON.parse_string(body.get_string_from_utf8())
	if not (parsed is Array):
		return

	if _poll_modo == "busca":
		if _estado != "buscando":
			return
		if (parsed as Array).is_empty():
			return
		var candidato = (parsed as Array)[0]
		if candidato is Dictionary:
			_claim_candidato = candidato as Dictionary
			_tentar_clamar(_claim_candidato.get("id", "") as String)

	elif _poll_modo == "score":
		if _estado != "em_partida":
			return
		if (parsed as Array).is_empty():
			return
		var row = (parsed as Array)[0]
		if row is Dictionary:
			if ((row as Dictionary).get("status", "") as String) == "finalizada":
				emit_signal("oponente_finalizou")
				return
			emit_signal("score_oponente_atualizado",
				int((row as Dictionary).get("score", 0)),
				int((row as Dictionary).get("wave",  1)),
				int((row as Dictionary).get("hp",  100)),
				(row as Dictionary).get("nome", "Oponente") as String
			)


# ── Claim atômico ─────────────────────────────────────────────────────────────
# Usa filtro &status=eq.buscando para que apenas um jogador consiga clamar o oponente

func _tentar_clamar(oponente_id: String) -> void:
	if oponente_id == "" or _http_claim.get_http_client_status() != HTTPClient.STATUS_DISCONNECTED:
		return
	var url := _URL + "?id=eq.%s&status=eq.buscando" % oponente_id.uri_encode()
	var body := JSON.stringify({"status": "em_partida", "matched_with": _meu_player_id})
	_http_claim.request(url, _headers_json(), HTTPClient.METHOD_PATCH, body)


func _on_claim_resposta(result: int, code: int, _h: PackedStringArray, body: PackedByteArray) -> void:
	if _estado != "buscando":
		return
	if result != HTTPRequest.RESULT_SUCCESS or code != 200:
		return
	var parsed = JSON.parse_string(body.get_string_from_utf8())
	# Array vazio = oponente já foi claimado por outro — continue buscando
	if not (parsed is Array) or (parsed as Array).is_empty():
		_claim_candidato = {}
		return

	# Claim bem-sucedido — atualiza minha sessão e entra em partida
	_op_player_id = _claim_candidato.get("player_id", "") as String
	_op_nome      = _claim_candidato.get("nome", "Oponente") as String
	_claim_candidato = {}

	if _minha_id != "" and _http_patch.get_http_client_status() == HTTPClient.STATUS_DISCONNECTED:
		var url := _URL + "?id=eq." + _minha_id.uri_encode()
		_http_patch.request(url, _headers_min(), HTTPClient.METHOD_PATCH,
			JSON.stringify({"status": "em_partida", "matched_with": _op_player_id}))

	_entrar_em_partida(_op_player_id, _op_nome)


func _entrar_em_partida(op_player_id: String, op_nome: String) -> void:
	if _estado == "em_partida":
		return
	_op_player_id = op_player_id
	_op_nome = op_nome if op_nome != "" else "Oponente"
	_estado = "em_partida"
	_sync_timer = SYNC_INTERVAL
	emit_signal("oponente_encontrado", _op_nome)


# ── Sync de score durante partida ─────────────────────────────────────────────

func _sync_partida() -> void:
	# PATCH meu score
	if _minha_id != "" and _http_patch.get_http_client_status() == HTTPClient.STATUS_DISCONNECTED:
		var url := _URL + "?id=eq." + _minha_id.uri_encode()
		_http_patch.request(url, _headers_min(), HTTPClient.METHOD_PATCH,
			JSON.stringify({"score": _score_local, "wave": _wave_local, "hp": _hp_local}))

	# GET score do oponente
	if _op_player_id != "" and _http_poll.get_http_client_status() == HTTPClient.STATUS_DISCONNECTED:
		_poll_modo = "score"
		var url := _URL + "?player_id=eq.%s&select=score,wave,hp,nome,status&limit=1" % _op_player_id.uri_encode()
		_http_poll.request(url, _headers_get())


# ── Timeout ───────────────────────────────────────────────────────────────────

func _timeout() -> void:
	_estado = ""
	if _minha_id != "" and _http_patch.get_http_client_status() == HTTPClient.STATUS_DISCONNECTED:
		var url := _URL + "?id=eq." + _minha_id.uri_encode()
		_http_patch.request(url, _headers_min(), HTTPClient.METHOD_PATCH,
			JSON.stringify({"status": "finalizada"}))
	emit_signal("timeout_sem_oponente")
