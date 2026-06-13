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
	return Salvar.nome_jogador.strip_edges() == "" and not Salvar.contas_conhecidas().is_empty()


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

	var contas := Salvar.contas_conhecidas()
	for i in range(mini(4, contas.size())):
		var c: Dictionary = contas[i] as Dictionary
		var nome: String = str(c.get("nome", "?"))
		var destaque: bool = (i == 0)
		_card_conta(nome, str(c.get("senha", "")), int(c.get("avatar_idx", 0)), Rect2(cx, y, cw, 58), destaque)
		y += 70.0

	y += 14.0
	_botao_menor("Entrar com outra conta", Rect2(cx, y, cw, 46), func():
		_fechar()
		m._abrir_perfil(m._ui_main))
	y += 56.0
	_botao_menor("Jogar sem conta", Rect2(cx, y, cw, 46), func():
		_fechar())


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
