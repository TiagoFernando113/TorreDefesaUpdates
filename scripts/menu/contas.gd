extends RefCounted
## Modulo do menu - tela "QUEM ESTA JOGANDO?" (login pratico de 1 clique).
## Visual minimalista dark (referencia Grok/xAI): titulo central + cards
## arredondados das contas conhecidas do aparelho. Clicou -> re-login com a
## credencial hasheada salva + download do save da nuvem. Sem digitar nada.

var m  # menu principal (menu.gd)

var _overlay: ColorRect = null
var _status: Label = null
var _entrando: bool = false

func _init(menu) -> void:
	m = menu


func limpar_refs() -> void:
	_overlay = null
	_status = null
	_entrando = false


func deve_abrir_no_boot() -> bool:
	# Deslogado: a tela é a porta de entrada (Google / contas do aparelho / offline)
	return Salvar.nome_jogador.strip_edges() == ""


func abrir(ui: CanvasLayer) -> void:
	if _overlay and is_instance_valid(_overlay):
		return
	if m._menu_contents:
		m._menu_contents.hide()
	var vp: Vector2 = m.get_viewport().get_visible_rect().size
	_entrando = false

	_overlay = ColorRect.new()
	_overlay.color = Color(0.01, 0.01, 0.015, 1.0)
	_overlay.position = Vector2.ZERO
	_overlay.size = vp
	_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	_overlay.z_index = 220
	ui.add_child(_overlay)

	var tit := Label.new()
	tit.text = "Quem está jogando?"
	tit.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tit.position = Vector2(0, vp.y * 0.16)
	tit.size = Vector2(vp.x, 52)
	tit.add_theme_font_size_override("font_size", 38)
	tit.add_theme_color_override("font_color", Color(0.96, 0.97, 1.0))
	_overlay.add_child(tit)

	_status = Label.new()
	_status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_status.position = Vector2(0, vp.y * 0.16 + 56)
	_status.size = Vector2(vp.x, 26)
	_status.add_theme_font_size_override("font_size", 15)
	_status.add_theme_color_override("font_color", Color(0.55, 0.62, 0.75))
	_overlay.add_child(_status)

	var cw: float = minf(430.0, vp.x - 60.0)
	var cx: float = (vp.x - cw) * 0.5
	var y: float = vp.y * 0.16 + 110.0

	# Botão principal: Google (branco, como na referência)
	_botao_google(Rect2(cx, y, cw, 54))
	y += 78.0

	var contas := Salvar.contas_conhecidas()
	for i in range(mini(3, contas.size())):
		var c: Dictionary = contas[i] as Dictionary
		var nome: String = str(c.get("nome", "?"))
		_card_conta(nome, str(c.get("senha", "")), int(c.get("avatar_idx", 0)), Rect2(cx, y, cw, 58), false)
		y += 70.0

	y += 14.0
	_botao_menor("Entrar com outra conta", Rect2(cx, y, cw, 46), func():
		_fechar()
		m._abrir_perfil(m._ui_main))
	y += 56.0
	_botao_menor("Jogar sem conta", Rect2(cx, y, cw, 46), func():
		_fechar())


func _botao_google(r: Rect2) -> void:
	var btn := Button.new()
	btn.position = r.position
	btn.size = r.size
	btn.focus_mode = Control.FOCUS_NONE
	var sty := StyleBoxFlat.new()
	sty.bg_color = Color(0.94, 0.95, 0.97, 1.0)
	sty.set_corner_radius_all(int(r.size.y * 0.5))
	btn.add_theme_stylebox_override("normal", sty)
	var sty_h: StyleBoxFlat = sty.duplicate()
	sty_h.bg_color = Color(1, 1, 1, 1)
	btn.add_theme_stylebox_override("hover", sty_h)
	btn.text = "G   Entrar com Google"
	btn.add_theme_font_size_override("font_size", 19)
	btn.add_theme_color_override("font_color", Color(0.10, 0.11, 0.13))
	btn.pressed.connect(_login_google)
	_overlay.add_child(btn)


func _card_conta(nome: String, senha_hash: String, av_idx: int, r: Rect2, destaque: bool) -> void:
	var btn := Button.new()
	btn.position = r.position
	btn.size = r.size
	btn.focus_mode = Control.FOCUS_NONE
	var sty := StyleBoxFlat.new()
	if destaque:
		sty.bg_color = Color(0.94, 0.95, 0.97, 1.0)
	else:
		sty.bg_color = Color(0.07, 0.08, 0.10, 1.0)
		sty.border_color = Color(0.28, 0.30, 0.36, 1.0)
		sty.set_border_width_all(1)
	sty.set_corner_radius_all(int(r.size.y * 0.5))
	btn.add_theme_stylebox_override("normal", sty)
	var sty_h: StyleBoxFlat = sty.duplicate()
	sty_h.bg_color = Color(1, 1, 1, 1) if destaque else Color(0.12, 0.13, 0.17, 1.0)
	btn.add_theme_stylebox_override("hover", sty_h)
	btn.text = nome
	btn.add_theme_font_size_override("font_size", 19)
	btn.add_theme_color_override("font_color", Color(0.08, 0.09, 0.11) if destaque else Color(0.92, 0.94, 0.98))
	_overlay.add_child(btn)

	# Avatar: circulo colorido com inicial
	var av := Control.new()
	av.position = r.position + Vector2(14, (r.size.y - 34.0) * 0.5)
	av.size = Vector2(34, 34)
	av.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var cores: Array = m._AVATAR_CORES
	var cor_av: Color = (cores[av_idx] as Color) if av_idx >= 0 and av_idx < cores.size() else Color(0.45, 0.6, 0.9)
	var inicial: String = nome.substr(0, 1).to_upper()
	av.draw.connect(func():
		av.draw_circle(Vector2(17, 17), 17.0, cor_av * Color(1, 1, 1, 0.9))
		var f := ThemeDB.fallback_font
		if f:
			var w := f.get_string_size(inicial, HORIZONTAL_ALIGNMENT_LEFT, -1, 18).x
			av.draw_string(f, Vector2(17.0 - w * 0.5, 23.5), inicial, HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color(0.02, 0.03, 0.05, 0.92)))
	_overlay.add_child(av)

	# X discreto pra esquecer a conta deste aparelho
	var btn_x := Button.new()
	btn_x.text = "×"
	btn_x.position = r.position + Vector2(r.size.x - 40, (r.size.y - 30.0) * 0.5)
	btn_x.size = Vector2(30, 30)
	btn_x.flat = true
	btn_x.focus_mode = Control.FOCUS_NONE
	btn_x.add_theme_font_size_override("font_size", 18)
	btn_x.add_theme_color_override("font_color", Color(0.45, 0.30, 0.30) if destaque else Color(0.55, 0.45, 0.45))
	btn_x.pressed.connect(func():
		Salvar.esquecer_conta(nome)
		var ui_ref = m._ui_ref
		_fechar_sem_menu()
		abrir(ui_ref))
	_overlay.add_child(btn_x)

	btn.pressed.connect(func(): _entrar(nome, senha_hash))


func _botao_menor(txt: String, r: Rect2, acao: Callable) -> void:
	var btn := Button.new()
	btn.position = r.position
	btn.size = r.size
	btn.focus_mode = Control.FOCUS_NONE
	var sty := StyleBoxFlat.new()
	sty.bg_color = Color(0.05, 0.055, 0.07, 1.0)
	sty.border_color = Color(0.22, 0.24, 0.29, 1.0)
	sty.set_border_width_all(1)
	sty.set_corner_radius_all(int(r.size.y * 0.5))
	btn.add_theme_stylebox_override("normal", sty)
	var sty_h: StyleBoxFlat = sty.duplicate()
	sty_h.bg_color = Color(0.10, 0.11, 0.14, 1.0)
	btn.add_theme_stylebox_override("hover", sty_h)
	btn.text = txt
	btn.add_theme_font_size_override("font_size", 16)
	btn.add_theme_color_override("font_color", Color(0.78, 0.82, 0.90))
	btn.pressed.connect(acao)
	_overlay.add_child(btn)


func _entrar(nome: String, senha_hash: String) -> void:
	if _entrando:
		return
	_entrando = true
	if _status and is_instance_valid(_status):
		_status.text = "Entrando como %s…" % nome
	var conta_anterior: String = Salvar.nome_jogador
	var conn := func(ok: bool, nome_ret: String, email_ret: String) -> void:
		if not _overlay or not is_instance_valid(_overlay):
			return
		if ok:
			Salvar.nome_jogador = nome_ret
			Salvar.email_jogador = email_ret
			Salvar.senha_jogador = senha_hash
			Salvar.credenciais_versao = 1
			Salvar.salvar()
			Salvar.lembrar_conta(nome_ret, email_ret, senha_hash)
			RankingOnline.download_save(nome_ret, func(s_ok: bool, dados: Dictionary, force: bool = false) -> void:
				if s_ok:
					if force or conta_anterior != nome_ret:
						Salvar.importar_cloud_forcado(dados)
						if force: RankingOnline._limpar_force_sync(nome_ret)
					else:
						Salvar.importar_cloud(dados)
					RankingOnline.buscar_premios_pendentes()
				m.get_tree().change_scene_to_file("res://scenes/Menu.tscn"))
		else:
			_entrando = false
			if _status and is_instance_valid(_status):
				_status.text = "Não foi possível entrar — a senha pode ter mudado. Use 'Entrar com outra conta'."
				_status.add_theme_color_override("font_color", Color(1.0, 0.5, 0.45))
	_conectar_login_unico(conn)
	RankingOnline.verificar_login_hash(nome, senha_hash, Callable())


var _conn_atual: Callable = Callable()

func _conectar_login_unico(conn: Callable) -> void:
	if _conn_atual.is_valid() and RankingOnline.login_verificado.is_connected(_conn_atual):
		RankingOnline.login_verificado.disconnect(_conn_atual)
	_conn_atual = conn
	RankingOnline.login_verificado.connect(_conn_atual)


func _fechar() -> void:
	_fechar_sem_menu()
	if m._menu_contents and is_instance_valid(m._menu_contents):
		m._menu_contents.show()


func _fechar_sem_menu() -> void:
	if _conn_atual.is_valid() and RankingOnline.login_verificado.is_connected(_conn_atual):
		RankingOnline.login_verificado.disconnect(_conn_atual)
	_conn_atual = Callable()
	if _overlay and is_instance_valid(_overlay):
		_overlay.queue_free()
	_overlay = null
	_status = null
	_entrando = false


# ── Entrar com Google ────────────────────────────────────────────────────────

const GOOGLE_AUTH = preload("res://scripts/google_auth.gd")

func _login_google() -> void:
	if _entrando:
		return
	_entrando = true
	_set_status("Abrindo o Google no navegador…", false)
	var ga := GOOGLE_AUTH.new()
	m.add_child(ga)
	ga.concluido.connect(func(ok: bool, email: String, _nome_g: String, erro: String):
		if not _overlay or not is_instance_valid(_overlay):
			return
		if not ok:
			_entrando = false
			_set_status(erro, true)
			return
		_set_status("Conectando à conta do jogo…", false)
		_resolver_conta_google(email))
	ga.iniciar()


func _resolver_conta_google(email: String) -> void:
	var res := await _rest("GET",
		RankingOnline._URL_USUARIOS + "?email=eq.%s&select=nome" % email.uri_encode(), "")
	if int(res[0]) != 200:
		_entrando = false
		_set_status("Servidor indisponível (%d). Tente de novo." % int(res[0]), true)
		return
	var lista = res[1]
	if lista is Array and not (lista as Array).is_empty():
		# Conta existe: renova a credencial e entra (sem digitar nada)
		var nome_conta := str(((lista as Array)[0] as Dictionary).get("nome", ""))
		var novo_hash := RankingOnline._hash(GOOGLE_AUTH._b64url(Crypto.new().generate_random_bytes(32)))
		var up := await _rest("PATCH",
			RankingOnline._URL_USUARIOS + "?email=eq.%s" % email.uri_encode(),
			JSON.stringify({"senha": novo_hash}))
		if int(up[0]) != 200 and int(up[0]) != 204:
			_entrando = false
			_set_status("Não consegui renovar a credencial (%d)." % int(up[0]), true)
			return
		_finalizar_login(nome_conta, email, novo_hash)
	else:
		_entrando = false
		_tela_escolher_nome(email)


func _tela_escolher_nome(email: String) -> void:
	# Conta Google nova: só falta o nome de jogador
	for ch in _overlay.get_children():
		ch.queue_free()
	var vp: Vector2 = _overlay.size
	var tit := Label.new()
	tit.text = "Escolha seu nome de jogador"
	tit.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tit.position = Vector2(0, vp.y * 0.22)
	tit.size = Vector2(vp.x, 50)
	tit.add_theme_font_size_override("font_size", 32)
	tit.add_theme_color_override("font_color", Color(0.96, 0.97, 1.0))
	_overlay.add_child(tit)

	var sub := Label.new()
	sub.text = email + "  ·  esse será seu nome no ranking"
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.position = Vector2(0, vp.y * 0.22 + 52)
	sub.size = Vector2(vp.x, 24)
	sub.add_theme_font_size_override("font_size", 14)
	sub.add_theme_color_override("font_color", Color(0.55, 0.62, 0.75))
	_overlay.add_child(sub)

	_status = Label.new()
	_status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_status.position = Vector2(0, vp.y * 0.22 + 80)
	_status.size = Vector2(vp.x, 24)
	_status.add_theme_font_size_override("font_size", 14)
	_overlay.add_child(_status)

	var cw: float = minf(430.0, vp.x - 60.0)
	var cx: float = (vp.x - cw) * 0.5
	var campo := LineEdit.new()
	campo.position = Vector2(cx, vp.y * 0.22 + 120)
	campo.size = Vector2(cw, 52)
	campo.max_length = 18
	campo.placeholder_text = "Nome de jogador"
	campo.alignment = HORIZONTAL_ALIGNMENT_CENTER
	campo.add_theme_font_size_override("font_size", 20)
	_overlay.add_child(campo)
	campo.grab_focus()

	var confirmar := func():
		var nome := campo.text.strip_edges()
		if nome.length() < 3:
			_set_status("Nome precisa de pelo menos 3 letras.", true)
			return
		if _entrando:
			return
		_entrando = true
		_set_status("Verificando nome…", false)
		var chk := await _rest("GET",
			RankingOnline._URL_USUARIOS + "?nome=ilike.%s&select=nome" % nome.uri_encode(), "")
		if int(chk[0]) == 200 and chk[1] is Array and not (chk[1] as Array).is_empty():
			_entrando = false
			_set_status("Esse nome já existe — tente outro.", true)
			return
		var novo_hash := RankingOnline._hash(GOOGLE_AUTH._b64url(Crypto.new().generate_random_bytes(32)))
		var ins := await _rest("POST", RankingOnline._URL_USUARIOS,
			JSON.stringify({"nome": nome, "email": email, "senha": novo_hash}))
		if int(ins[0]) != 201:
			_entrando = false
			_set_status("Não consegui criar a conta (%d)." % int(ins[0]), true)
			return
		_finalizar_login(nome, email, novo_hash, true)

	var btn := Button.new()
	btn.text = "COMEÇAR"
	btn.position = Vector2(cx, vp.y * 0.22 + 188)
	btn.size = Vector2(cw, 50)
	btn.focus_mode = Control.FOCUS_NONE
	var sty := StyleBoxFlat.new()
	sty.bg_color = Color(0.94, 0.95, 0.97, 1.0)
	sty.set_corner_radius_all(25)
	btn.add_theme_stylebox_override("normal", sty)
	btn.add_theme_font_size_override("font_size", 19)
	btn.add_theme_color_override("font_color", Color(0.10, 0.11, 0.13))
	btn.pressed.connect(confirmar)
	campo.text_submitted.connect(func(_t): confirmar.call())
	_overlay.add_child(btn)


func _finalizar_login(nome: String, email: String, senha_hash: String, eh_nova: bool = false) -> void:
	if eh_nova:
		# Conta nova começa zerada — não herda recursos do estado em memória
		Salvar.limpar_dados()
	Salvar.nome_jogador = nome
	Salvar.email_jogador = email
	Salvar.senha_jogador = senha_hash
	Salvar.credenciais_versao = 1
	Salvar.salvar()
	Salvar.lembrar_conta(nome, email, senha_hash)
	if _status and is_instance_valid(_status):
		_set_status("Bem-vindo, %s!" % nome, false)
	RankingOnline.download_save(nome, func(s_ok: bool, dados: Dictionary, force: bool = false) -> void:
		if s_ok:
			Salvar.importar_cloud_forcado(dados)
			if force: RankingOnline._limpar_force_sync(nome)
			RankingOnline.buscar_premios_pendentes()
		else:
			RankingOnline.envio_inicial()
		m.get_tree().change_scene_to_file("res://scenes/Menu.tscn"))


func _set_status(txt: String, erro: bool) -> void:
	if _status and is_instance_valid(_status):
		_status.text = txt
		_status.add_theme_color_override("font_color",
			Color(1.0, 0.5, 0.45) if erro else Color(0.55, 0.75, 0.95))


func _rest(metodo: String, url: String, body: String) -> Array:
	# Request REST simples com await: retorna [status, dados_json]
	var http := HTTPRequest.new()
	m.add_child(http)
	var headers := PackedStringArray([
		"apikey: " + RankingOnline._ANON,
		"Authorization: Bearer " + RankingOnline._ANON,
		"Content-Type: application/json",
		"Prefer: return=minimal",
	])
	var met := HTTPClient.METHOD_GET
	match metodo:
		"POST":  met = HTTPClient.METHOD_POST
		"PATCH": met = HTTPClient.METHOD_PATCH
	http.request(url, headers, met, body)
	var res = await http.request_completed
	http.queue_free()
	var status := int(res[1])
	var dados = JSON.parse_string((res[3] as PackedByteArray).get_string_from_utf8())
	return [status, dados]
