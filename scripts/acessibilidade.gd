extends Node
## Modo Acessibilidade — Glaucoma
## Voz: Google TTS neural pt-BR via HTTP (fallback: sistema)
## 1º clique → lê descrição | 2º clique → confirmar | 3º clique → executa

var ativo : bool = false

# ── Estado triplo-clique ──────────────────────────────────────────────────────
var _foco_id   : String   = ""
var _foco_cont : int      = 0
var _foco_acao : Callable

# ── TTS sistema (fallback) ────────────────────────────────────────────────────
var _voz_sistema : String = ""

# ── TTS Google (principal) ────────────────────────────────────────────────────
var _http        : HTTPRequest        = null
var _player      : AudioStreamPlayer  = null
var _cache       : Dictionary         = {}   # texto → PackedByteArray (MP3)
var _pendente    : String             = ""   # texto aguardando resposta

# ── UI de feedback ────────────────────────────────────────────────────────────
var _camada   : CanvasLayer = null
var _painel   : Panel       = null
var _lbl_nome : Label       = null
var _lbl_cont : Label       = null


func _ready() -> void:
	_detectar_voz_sistema()
	_criar_ui_feedback()
	_criar_tts_http()
	call_deferred("_carregar_estado")


func _carregar_estado() -> void:
	ativo = Salvar.acessibilidade_ativo
	# Aquece motor TTS com a voz pt-BR já detectada (volume 0, sem texto audível)
	if ativo and OS.get_name() == "Android" and _voz_sistema != "":
		DisplayServer.tts_speak(" ", _voz_sistema, 0, 1.0, 1.0, 0, false)


# ── Setup ─────────────────────────────────────────────────────────────────────

func _detectar_voz_sistema() -> void:
	var voices := DisplayServer.tts_get_voices()
	if voices.is_empty():
		print("[Acessibilidade] Nenhuma voz SAPI encontrada no sistema.")
		return

	# Imprime todas as vozes disponíveis para diagnóstico
	print("[Acessibilidade] Vozes disponíveis no sistema:")
	for v in voices:
		var vd : Dictionary = v as Dictionary
		print("  nome='%s'  lang='%s'  id='%s'" % [
			vd.get("name", ""), vd.get("language", ""), vd.get("id", "")])

	# ── Prioridade 1: voz "Leda" (Nuance/Loquendo pt-BR) ──────────────────────
	for v in voices:
		var vd   : Dictionary = v as Dictionary
		var nome : String     = vd.get("name", "") as String
		if "leda" in nome.to_lower():
			_voz_sistema = vd.get("id", "") as String
			print("[Acessibilidade] Voz selecionada: Leda  (%s)" % _voz_sistema)
			return

	# ── Prioridade 2: voz neural/natural pt-BR ────────────────────────────────
	for v in voices:
		var vd   : Dictionary = v as Dictionary
		var lang : String     = vd.get("language", "") as String
		var nome : String     = vd.get("name",     "") as String
		if "pt" in lang.to_lower():
			if "natural" in nome.to_lower() or "online" in nome.to_lower() or "neural" in nome.to_lower():
				_voz_sistema = vd.get("id", "") as String
				print("[Acessibilidade] Voz selecionada (neural pt-BR): %s" % nome)
				return

	# ── Prioridade 3: pt-BR exato ────────────────────────────────────────────
	for v in voices:
		var vd   : Dictionary = v as Dictionary
		var lang : String     = vd.get("language", "") as String
		var nome : String     = vd.get("name",     "") as String
		if lang.to_lower() in ["pt-br", "pt_br", "por-bra", "pt"]:
			_voz_sistema = vd.get("id", "") as String
			print("[Acessibilidade] Voz selecionada (pt-BR): %s" % nome)
			return

	# ── Prioridade 4: qualquer voz com "pt" na língua ─────────────────────────
	for v in voices:
		var vd   : Dictionary = v as Dictionary
		var lang : String     = vd.get("language", "") as String
		var nome : String     = vd.get("name",     "") as String
		if "pt" in lang.to_lower():
			_voz_sistema = vd.get("id", "") as String
			print("[Acessibilidade] Voz selecionada (pt genérico): %s" % nome)
			return

	# ── Fallback: primeira voz disponível ─────────────────────────────────────
	var vd_fb : Dictionary = voices[0] as Dictionary
	_voz_sistema = vd_fb.get("id", "") as String
	print("[Acessibilidade] Voz selecionada (fallback): %s" % vd_fb.get("name", ""))


func _criar_tts_http() -> void:
	_player            = AudioStreamPlayer.new()
	_player.bus        = "Master"
	_player.volume_db  = 2.0   # ligeiramente mais alto
	add_child(_player)

	_http = HTTPRequest.new()
	_http.timeout = 5.0   # desiste após 5 s e usa fallback
	add_child(_http)
	_http.request_completed.connect(_on_tts_resposta)


func _criar_ui_feedback() -> void:
	_camada       = CanvasLayer.new()
	_camada.layer = 99
	add_child(_camada)

	_painel          = Panel.new()
	_painel.position = Vector2(20, 610)
	_painel.size     = Vector2(700, 72)
	var sty          := StyleBoxFlat.new()
	sty.bg_color     = Color(0.03, 0.07, 0.16, 0.96)
	sty.border_color = Color(0.28, 0.62, 1.0, 0.92)
	for s in ["left","right","top","bottom"]: sty.set("border_width_" + s, 2)
	for c in ["top_left","top_right","bottom_left","bottom_right"]: sty.set("corner_radius_" + c, 8)
	_painel.add_theme_stylebox_override("panel", sty)
	_painel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_camada.add_child(_painel)

	_lbl_nome          = Label.new()
	_lbl_nome.position = Vector2(12, 7)
	_lbl_nome.size     = Vector2(676, 28)
	_lbl_nome.add_theme_font_size_override("font_size", 14)
	_lbl_nome.add_theme_color_override("font_color", Color(0.80, 0.92, 1.0))
	_lbl_nome.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_painel.add_child(_lbl_nome)

	_lbl_cont          = Label.new()
	_lbl_cont.position = Vector2(12, 38)
	_lbl_cont.size     = Vector2(676, 26)
	_lbl_cont.add_theme_font_size_override("font_size", 13)
	_lbl_cont.add_theme_color_override("font_color", Color(0.38, 0.78, 1.0))
	_lbl_cont.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_painel.add_child(_lbl_cont)

	_painel.visible = false


# ── API pública ───────────────────────────────────────────────────────────────

func set_ativo(v: bool) -> void:
	ativo = v
	Salvar.acessibilidade_ativo = v
	Salvar.salvar()
	cancelar_foco()
	if v:
		# Aquece motor TTS ao ativar para 1ª fala sair sem delay
		if OS.get_name() == "Android" and _voz_sistema != "":
			DisplayServer.tts_speak(" ", _voz_sistema, 0, 1.0, 1.0, 0, false)
		_falar("Modo acessibilidade ativado. Clique 3 vezes para confirmar ações.")


func falar(texto: String) -> void:
	if not ativo: return
	_falar(texto)


func processar(elem_id: String, desc: String, acao: Callable) -> void:
	if not ativo:
		acao.call()
		return

	if _foco_id != elem_id:
		_foco_id   = elem_id
		_foco_cont = 1
		_foco_acao = acao
		_falar(desc)
		_mostrar_feedback(desc, 1)
	else:
		_foco_cont += 1
		if _foco_cont == 2:
			_falar("Clique mais uma vez para confirmar")
			_mostrar_feedback(_foco_id, 2)
		elif _foco_cont >= 3:
			var exec := _foco_acao
			cancelar_foco()
			exec.call()


func cancelar_foco() -> void:
	_foco_id   = ""
	_foco_cont = 0
	if is_instance_valid(_painel):
		_painel.visible = false
	_parar_audio()


# ── Núcleo TTS ────────────────────────────────────────────────────────────────

var _modo_tts : String = "auto"   # "gcl" | "gtranslate" | "sistema"

func _falar(texto: String) -> void:
	_parar_audio()

	# Cache hit → reproduz sem requisição
	if _cache.has(texto):
		_tocar_mp3(_cache[texto] as PackedByteArray)
		return

	if _http.get_http_client_status() != HTTPClient.STATUS_DISCONNECTED:
		_http.cancel_request()

	_pendente = texto

	# ── Prioridade 1: Google Cloud TTS Neural2 (precisa de chave) ────────────
	if ChaveTTS.get_tts_key() != "":
		_modo_tts = "gcl"
		_pedir_gcl(texto)
		return

	# ── Prioridade 2: Android → TTS nativo (Google TTS engine soa bem) ───────
	if OS.get_name() == "Android":
		_pendente = ""
		_falar_sistema(texto)
		return

	# ── Prioridade 3: Google Translate TTS (sem chave, qualidade média) ──────
	_modo_tts = "gtranslate"
	_pedir_gtranslate(texto)


func _pedir_gcl(texto: String) -> void:
	# Google Cloud TTS — Neural2 pt-BR, retorna JSON com audioContent em base64
	var voz : String = Salvar.tts_voz if Salvar.tts_voz != "" else "pt-BR-Neural2-A"
	var url  : String = "https://texttospeech.googleapis.com/v1/text:synthesize?key=" + ChaveTTS.get_tts_key()
	var body_json : String = JSON.stringify({
		"input":       {"text": texto},
		"voice":       {"languageCode": "pt-BR", "name": voz},
		"audioConfig": {"audioEncoding": "MP3", "speakingRate": 0.95, "pitch": 0.0}
	})
	var headers := PackedStringArray(["Content-Type: application/json"])
	var err := _http.request(url, headers, HTTPClient.METHOD_POST, body_json)
	if err != OK:
		_pendente = ""
		_falar_sistema(texto)


func _pedir_gtranslate(texto: String) -> void:
	var encoded : String = texto.uri_encode()
	var url : String = (
		"https://translate.google.com/translate_tts"
		+ "?ie=UTF-8&q=" + encoded
		+ "&tl=pt-BR&client=tw-ob&ttsspeed=0.9"
	)
	var headers := PackedStringArray([
		"User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36",
		"Referer: https://translate.google.com/",
	])
	var err := _http.request(url, headers)
	if err != OK:
		_pendente = ""
		_falar_sistema(texto)


func _tem_leda() -> bool:
	var voices := DisplayServer.tts_get_voices()
	for v in voices:
		var nome : String = (v as Dictionary).get("name", "") as String
		if "leda" in nome.to_lower():
			return true
	return false


func _on_tts_resposta(result: int, code: int, _hdrs: PackedStringArray, body: PackedByteArray) -> void:
	var texto := _pendente
	_pendente = ""
	if result != HTTPRequest.RESULT_SUCCESS or code != 200:
		_falar_sistema(texto)
		return

	# ── Google Cloud TTS → JSON com base64 ───────────────────────────────────
	if _modo_tts == "gcl":
		var json := JSON.new()
		var parse_ok := json.parse(body.get_string_from_utf8()) == OK
		print("[GCL] parse_ok=%s  body_str_len=%d" % [parse_ok, body.size()])
		if parse_ok:
			var data = json.get_data()
			var has_audio := data is Dictionary and (data as Dictionary).has("audioContent")
			print("[GCL] has_audioContent=%s" % has_audio)
			if has_audio:
				var b64 : String = (data as Dictionary)["audioContent"] as String
				var mp3 : PackedByteArray = Marshalls.base64_to_raw(b64)
				print("[GCL] mp3 size=%d" % mp3.size())
				if mp3.size() > 500:
					_cache[texto] = mp3
					_tocar_mp3(mp3)
					return
		print("[GCL] falhou → fallback. body inicio: " + body.get_string_from_utf8().substr(0, 120))
		_falar_sistema(texto)
		return

	# ── Google Translate TTS → MP3 direto ────────────────────────────────────
	if body.size() > 1000:
		_cache[texto] = body
		_tocar_mp3(body)
	else:
		_falar_sistema(texto)


func _tocar_mp3(data: PackedByteArray) -> void:
	if data.is_empty(): return
	var stream      := AudioStreamMP3.new()
	stream.data      = data
	_player.stream   = stream
	_player.play()


func _falar_sistema(texto: String) -> void:
	if DisplayServer.tts_is_speaking():
		DisplayServer.tts_stop()
	if _voz_sistema != "":
		DisplayServer.tts_speak(texto, _voz_sistema, 92, 1.0, 0.92, 0, true)
	else:
		# Último recurso: sem voz_id definido
		var voices := DisplayServer.tts_get_voices()
		if not voices.is_empty():
			var vid : String = (voices[0] as Dictionary).get("id", "") as String
			DisplayServer.tts_speak(texto, vid, 92, 1.0, 0.92, 0, true)


func _parar_audio() -> void:
	if is_instance_valid(_player) and _player.playing:
		_player.stop()
	if DisplayServer.tts_is_speaking():
		DisplayServer.tts_stop()


# ── UI de feedback ────────────────────────────────────────────────────────────

func _mostrar_feedback(desc: String, cont: int) -> void:
	if not is_instance_valid(_painel): return
	var desc_curta : String = desc if desc.length() <= 70 else desc.substr(0, 68) + "…"
	_lbl_nome.text = "ACESSO  " + desc_curta
	match cont:
		1: _lbl_cont.text = "[ 1 / 3 ]  Clique mais 2 vezes para confirmar"
		2: _lbl_cont.text = "[ 2 / 3 ]  Clique mais 1 vez para confirmar"
		_: _lbl_cont.text = "[ 3 / 3 ]  Confirmando…"
	_painel.visible = true
