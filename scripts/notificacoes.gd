extends Node
## Ponte de notificacoes do jogo.
## No Android, conversa com o plugin nativo "CyronPush" quando instalado.
## No PC/editor, fica em modo seguro sem quebrar cenas.

signal token_recebido(token: String)
signal notificacao_recebida(id: String, tipo: String, titulo: String, corpo: String)
signal notices_carregados   # avisos do GitHub prontos (pro popup in-game)

const URL_NOTICES: String = "https://raw.githubusercontent.com/TiagoFernando113/TorreDefesaUpdates/refs/heads/main/notices.json"
const SETTINGS_PATH: String = "user://notificacoes_settings.json"

var _plugin: Object = null
var _http: HTTPRequest = null
var _settings: Dictionary = {
	"enabled": false,
	"last_seen": {},
	"token": ""
}
var notices_cache: Array[Dictionary] = []
var _notices_carregando: bool = false


func _ready() -> void:
	_carregar_settings()
	_conectar_plugin()
	if BuildConfig.is_mobile() and plugin_disponivel() and notificacoes_ativas() and _plugin.has_method("requestToken"):
		_plugin.call("requestToken")
	# Entrega pushes recebidos enquanto o app estava fechado (vira aviso in-game).
	if _plugin and _plugin.has_method("flushPendingNotifications"):
		_plugin.call("flushPendingNotifications")
	_iniciar_fetch_notices()


func ativar_automatica_pos_login() -> void:
	# Primeira ativação (dispara o popup de permissão do Android) só DEPOIS do
	# login — senão o popup aparece por cima da tela de login no boot do app.
	if BuildConfig.is_mobile() and plugin_disponivel() and not notificacoes_ativas():
		ativar_notificacoes()


func plugin_disponivel() -> bool:
	return _plugin != null


func status_texto() -> String:
	if plugin_disponivel():
		return "Notificacoes Android prontas."
	if BuildConfig.is_mobile():
		return "Plugin CyronPush ausente no build Android."
	return "Notificacoes push disponiveis apenas no Android."


func notificacoes_ativas() -> bool:
	return bool(_settings.get("enabled", false))


func ativar_notificacoes() -> void:
	_settings["enabled"] = true
	_salvar_settings()
	if BuildConfig.is_mobile():
		_solicitar_permissao_android()
	if _plugin and _plugin.has_method("setEnabled"):
		_plugin.call("setEnabled", true)
	if _plugin and _plugin.has_method("requestToken"):
		_plugin.call("requestToken")


func desativar_notificacoes() -> void:
	_settings["enabled"] = false
	_salvar_settings()
	if _plugin and _plugin.has_method("setEnabled"):
		_plugin.call("setEnabled", false)


func abrir_acao_notice(notice: Dictionary) -> void:
	var url := str(notice.get("url", ""))
	if url.begins_with("https://") or url.begins_with("http://"):
		OS.shell_open(url)


func marcar_vista(id: String) -> void:
	if id == "":
		return
	var vistos: Dictionary = _settings.get("last_seen", {}) as Dictionary
	vistos[id] = Time.get_unix_time_from_system()
	_settings["last_seen"] = vistos
	_salvar_settings()


func notices_nao_vistas() -> Array[Dictionary]:
	var vistos: Dictionary = _settings.get("last_seen", {}) as Dictionary
	var out: Array[Dictionary] = []
	for notice in notices_cache:
		var id := str(notice.get("id", ""))
		if id != "" and not vistos.has(id):
			out.append(notice)
	return out


func _conectar_plugin() -> void:
	if not Engine.has_singleton("CyronPush"):
		return
	_plugin = Engine.get_singleton("CyronPush")
	if _plugin.has_signal("token_received"):
		_plugin.connect("token_received", _on_token_received)
	if _plugin.has_signal("notification_received"):
		_plugin.connect("notification_received", _on_notification_received)
	if _plugin.has_method("setEnabled"):
		_plugin.call("setEnabled", notificacoes_ativas())


func _solicitar_permissao_android() -> void:
	if OS.has_method("request_permission"):
		OS.request_permission("android.permission.POST_NOTIFICATIONS")
	elif OS.has_method("request_permissions"):
		OS.request_permissions()


func esta_carregando_notices() -> bool:
	return _notices_carregando


func _iniciar_fetch_notices() -> void:
	# Reusa um único HTTPRequest; cancela o anterior se estiver travado e re-busca.
	if _http == null or not is_instance_valid(_http):
		_http = HTTPRequest.new()
		_http.use_threads = true
		_http.timeout = 8.0
		add_child(_http)
		_http.request_completed.connect(_on_notices_resp)
	if _http.get_http_client_status() != HTTPClient.STATUS_DISCONNECTED:
		_http.cancel_request()
	_notices_carregando = true
	if _http.request(URL_NOTICES) != OK:
		_notices_carregando = false
		notices_carregados.emit()   # falhou ao iniciar → para de "Carregando"


func recarregar_notices() -> void:
	_iniciar_fetch_notices()   # reusa: cancela o anterior e re-busca


func _on_notices_resp(result: int, code: int, _h: PackedStringArray, body: PackedByteArray) -> void:
	_notices_carregando = false
	if result != HTTPRequest.RESULT_SUCCESS or code != 200:
		notices_carregados.emit()   # avisa a UI mesmo na falha (para de "Carregando")
		return
	notices_cache = _parse_notices_manifest(body.get_string_from_utf8())
	if notificacoes_ativas() and _plugin and _plugin.has_method("syncNotices"):
		_plugin.call("syncNotices", JSON.stringify({"notices": notices_cache}))
	_disparar_notices_locais()
	notices_carregados.emit()   # avisa a UI in-game (popup no PC e Android)


func _parse_notices_manifest(txt: String) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	var json := JSON.new()
	if json.parse(txt) != OK:
		return out
	var data: Variant = json.get_data()
	if not data is Dictionary:
		return out
	var notices: Variant = (data as Dictionary).get("notices", [])
	if not notices is Array:
		return out
	for item in notices as Array:
		if not item is Dictionary:
			continue
		var d: Dictionary = item as Dictionary
		var id := str(d.get("id", "")).strip_edges()
		var title := str(d.get("title", "")).strip_edges()
		var body := str(d.get("body", "")).strip_edges()
		if id == "" or title == "" or body == "":
			continue
		out.append({
			"id": id,
			"title": title,
			"body": body,
			"type": str(d.get("type", "info")),
			"url": str(d.get("url", "")),
			"button": str(d.get("button", "ABRIR"))
		})
	return out


func _on_token_received(token: String) -> void:
	_settings["token"] = token
	_salvar_settings()
	emit_signal("token_recebido", token)


func _on_notification_received(id: String, tipo: String, titulo: String, corpo: String) -> void:
	emit_signal("notificacao_recebida", id, tipo, titulo, corpo)
	# Push do FCM também entra na central in-game (popup + sininho) — serve de
	# prova de que o push chegou no aparelho.
	var ja := false
	for c in notices_cache:
		if str((c as Dictionary).get("id", "")) == id:
			ja = true
			break
	if not ja:
		notices_cache.insert(0, {
			"id": id, "title": titulo, "body": corpo,
			"type": (tipo if tipo != "" else "push"), "url": "", "button": "ABRIR"
		})
	var vistos: Dictionary = _settings.get("last_seen", {}) as Dictionary
	vistos.erase(id)                 # marca como NÃO-visto → popup + badge
	_settings["last_seen"] = vistos
	_salvar_settings()
	notices_carregados.emit()        # avisa a UI in-game


func _disparar_notices_locais() -> void:
	if not notificacoes_ativas() or not _plugin or not _plugin.has_method("showLocalNotification"):
		return
	var novas := notices_nao_vistas()
	var limite: int = min(novas.size(), 3)
	for i in range(limite):
		var notice: Dictionary = novas[i]
		var id := str(notice.get("id", ""))
		_plugin.call(
			"showLocalNotification",
			id,
			str(notice.get("title", "Cyron Defense")),
			str(notice.get("body", "Novo comunicado disponivel.")),
			str(notice.get("type", "info"))
		)
		marcar_vista(id)


func _carregar_settings() -> void:
	if not FileAccess.file_exists(SETTINGS_PATH):
		return
	var f := FileAccess.open(SETTINGS_PATH, FileAccess.READ)
	if f == null:
		return
	var txt := f.get_as_text()
	f.close()
	var json := JSON.new()
	if json.parse(txt) == OK and json.get_data() is Dictionary:
		var data: Dictionary = json.get_data() as Dictionary
		for key in data.keys():
			_settings[key] = data[key]


func _salvar_settings() -> void:
	var f := FileAccess.open(SETTINGS_PATH, FileAccess.WRITE)
	if f == null:
		return
	f.store_string(JSON.stringify(_settings, "\t"))
	f.close()
