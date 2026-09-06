extends Node
## Testa se o Godot consegue baixar o notices.json do GitHub (TLS/rede).

const URL := "https://raw.githubusercontent.com/TiagoFernando113/TorreDefesaUpdates/refs/heads/main/notices.json"

func _ready() -> void:
	var http := HTTPRequest.new()
	http.use_threads = true
	http.timeout = 12.0
	add_child(http)
	http.request_completed.connect(_resp)
	var err := http.request(URL)
	print("REQUEST err=", err)
	if err != OK:
		get_tree().quit(1)

func _resp(result: int, code: int, _h: PackedStringArray, body: PackedByteArray) -> void:
	print("RESULT=", result, " (SUCCESS=", HTTPRequest.RESULT_SUCCESS, ")  CODE=", code, "  BYTES=", body.size())
	var txt := body.get_string_from_utf8()
	print("PRIMEIROS 80 CHARS: ", txt.substr(0, 80))
	var d = JSON.parse_string(txt)
	if d is Dictionary and (d as Dictionary).has("notices"):
		print("PARSE OK — notices=", ((d as Dictionary)["notices"] as Array).size())
	else:
		print("PARSE FALHOU ou sem 'notices'")
	get_tree().quit(0)
