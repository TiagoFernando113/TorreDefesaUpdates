extends Node
## Busca a chave da API Google Cloud TTS do Supabase.
## Fallback: chave salva localmente pelo jogador em Salvar.tts_api_key.

const _URL : String = "https://mslzcjqkfeivuavfxwli.supabase.co/rest/v1/config?key=eq.tts_key&select=value"
const _ANON : String = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1zbHpjanFrZmVpdnVhdmZ4d2xpIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzY1MjA1NDksImV4cCI6MjA5MjA5NjU0OX0.Op30JOIg4RcJgYtaNMiHWvVWvMguEt-j2Ccoax_-ncQ"

var _chave_nuvem : String = ""
var _http_cfg    : HTTPRequest = null


func _ready() -> void:
	_http_cfg         = HTTPRequest.new()
	_http_cfg.timeout = 8.0
	add_child(_http_cfg)
	_http_cfg.request_completed.connect(_on_cfg_resposta)
	var headers := PackedStringArray([
		"apikey: " + _ANON,
		"Authorization: Bearer " + _ANON,
	])
	_http_cfg.request(_URL, headers)


func _on_cfg_resposta(result: int, code: int, _hdrs: PackedStringArray, body: PackedByteArray) -> void:
	if result != HTTPRequest.RESULT_SUCCESS or code != 200:
		print("[ChaveTTS] Supabase indisponível (result=%d code=%d) — usando chave local." % [result, code])
		return
	var json := JSON.new()
	if json.parse(body.get_string_from_utf8()) != OK:
		return
	var data = json.get_data()
	if data is Array and (data as Array).size() > 0:
		var row = (data as Array)[0]
		if row is Dictionary and (row as Dictionary).has("value"):
			_chave_nuvem = (row as Dictionary)["value"] as String
			print("[ChaveTTS] Chave carregada da nuvem. len=%d" % _chave_nuvem.length())


func get_tts_key() -> String:
	if _chave_nuvem != "":
		return _chave_nuvem
	return Salvar.tts_api_key
