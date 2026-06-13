extends Node
## "Entrar com Google" — OAuth 2.0 para apps desktop (loopback + PKCE).
## Abre o navegador no seletor de contas do Google; o jogador escolhe a conta
## e volta pro jogo com o e-mail verificado. Nenhuma senha digitada.
##
## Uso:
##   var ga := GOOGLE_AUTH.new()
##   add_child(ga)
##   ga.concluido.connect(func(ok, email, nome, erro): ...)
##   ga.iniciar()
## O node se autodestroi ao concluir.

signal concluido(ok: bool, email: String, nome: String, erro: String)

const CLIENT_ID     := "551167063541-2pmptkmr3v0ll3a54mc89k5lvrrvnveu.apps.googleusercontent.com"
# Para apps tipo "Desktop" o Google exige o client_secret na troca do código,
# mas NAO o trata como segredo (doc oficial: "not treated as a secret").
const CLIENT_SECRET := "COLE_AQUI_O_GOCSPX"

const _AUTH_URL  := "https://accounts.google.com/o/oauth2/v2/auth"
const _TOKEN_URL := "https://oauth2.googleapis.com/token"
const _USERINFO  := "https://openidconnect.googleapis.com/v1/userinfo"
const _TIMEOUT_S := 180.0

var _server: TCPServer = null
var _porta: int = 0
var _verifier: String = ""
var _restante: float = _TIMEOUT_S
var _ativo: bool = false


func iniciar() -> void:
	if CLIENT_SECRET.begins_with("COLE_AQUI"):
		_terminar(false, "", "", "Login Google ainda não configurado (client secret).")
		return
	_verifier = _b64url(Crypto.new().generate_random_bytes(48))
	var ctx := HashingContext.new()
	ctx.start(HashingContext.HASH_SHA256)
	ctx.update(_verifier.to_utf8_buffer())
	var challenge := _b64url(ctx.finish())

	_server = TCPServer.new()
	for p in range(49170, 49190):
		if _server.listen(p, "127.0.0.1") == OK:
			_porta = p
			break
	if _porta == 0:
		_terminar(false, "", "", "Não consegui abrir a porta local pro retorno do Google.")
		return

	var redirect := "http://127.0.0.1:%d" % _porta
	var url := _AUTH_URL + "?" + "&".join(PackedStringArray([
		"client_id=" + CLIENT_ID.uri_encode(),
		"redirect_uri=" + redirect.uri_encode(),
		"response_type=code",
		"scope=" + "openid email profile".uri_encode(),
		"code_challenge=" + challenge,
		"code_challenge_method=S256",
		"prompt=select_account",
	]))
	_ativo = true
	_restante = _TIMEOUT_S
	OS.shell_open(url)


func _process(delta: float) -> void:
	if not _ativo:
		return
	_restante -= delta
	if _restante <= 0.0:
		_terminar(false, "", "", "Tempo esgotado — tente de novo.")
		return
	if _server == null or not _server.is_connection_available():
		return
	var conn := _server.take_connection()
	if conn == null:
		return
	# Lê a primeira linha do request: GET /?code=...&scope=... HTTP/1.1
	var espera := 0
	while conn.get_available_bytes() <= 0 and espera < 100:
		OS.delay_msec(10)
		espera += 1
	var raw := conn.get_utf8_string(conn.get_available_bytes())
	var code := ""
	var m := RegEx.create_from_string("[?&]code=([^&\\s]+)").search(raw)
	if m:
		code = m.get_string(1).uri_decode()
	var corpo := "<html><body style='background:#0a0a12;color:#dde;font-family:sans-serif;text-align:center;padding-top:120px'><h2>%s</h2><p>Pode fechar esta aba e voltar ao jogo.</p></body></html>" % ("Login confirmado ✔" if code != "" else "Login cancelado")
	conn.put_data(("HTTP/1.1 200 OK\r\nContent-Type: text/html; charset=utf-8\r\nConnection: close\r\nContent-Length: %d\r\n\r\n%s" % [corpo.to_utf8_buffer().size(), corpo]).to_utf8_buffer())
	conn.disconnect_from_host()
	_ativo = false
	if code == "":
		_terminar(false, "", "", "Login cancelado no navegador.")
		return
	_trocar_codigo(code)


func _trocar_codigo(code: String) -> void:
	var http := HTTPRequest.new()
	add_child(http)
	var body := "&".join(PackedStringArray([
		"client_id=" + CLIENT_ID.uri_encode(),
		"client_secret=" + CLIENT_SECRET.uri_encode(),
		"code=" + code.uri_encode(),
		"code_verifier=" + _verifier,
		"grant_type=authorization_code",
		"redirect_uri=" + ("http://127.0.0.1:%d" % _porta).uri_encode(),
	]))
	http.request_completed.connect(func(_r, status, _h, resposta: PackedByteArray):
		http.queue_free()
		var dados = JSON.parse_string(resposta.get_string_from_utf8())
		if status != 200 or not (dados is Dictionary) or not (dados as Dictionary).has("access_token"):
			_terminar(false, "", "", "Google recusou a troca do código (%d)." % status)
			return
		_buscar_userinfo(str((dados as Dictionary)["access_token"])))
	http.request(_TOKEN_URL, PackedStringArray(["Content-Type: application/x-www-form-urlencoded"]), HTTPClient.METHOD_POST, body)


func _buscar_userinfo(token: String) -> void:
	var http := HTTPRequest.new()
	add_child(http)
	http.request_completed.connect(func(_r, status, _h, resposta: PackedByteArray):
		http.queue_free()
		var dados = JSON.parse_string(resposta.get_string_from_utf8())
		if status != 200 or not (dados is Dictionary):
			_terminar(false, "", "", "Não consegui ler teu perfil do Google (%d)." % status)
			return
		var d := dados as Dictionary
		var email := str(d.get("email", ""))
		if email == "" or not bool(d.get("email_verified", true)):
			_terminar(false, "", "", "Conta Google sem e-mail verificado.")
			return
		_terminar(true, email, str(d.get("name", "")), ""))
	http.request(_USERINFO, PackedStringArray(["Authorization: Bearer " + token]))


func _terminar(ok: bool, email: String, nome: String, erro: String) -> void:
	_ativo = false
	if _server:
		_server.stop()
		_server = null
	concluido.emit(ok, email, nome, erro)
	queue_free()


static func _b64url(bytes: PackedByteArray) -> String:
	return Marshalls.raw_to_base64(bytes).replace("+", "-").replace("/", "_").replace("=", "")
