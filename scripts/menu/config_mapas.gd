extends RefCounted
## Modulo do menu - CONFIG + MAPAS (Fase 4 da modularizacao).
## Extraido de menu.gd em 2026-06-12 (tools/extrair_fase4.ps1).

var m  # menu principal (menu.gd)

func _init(menu) -> void:
	m = menu


func limpar_refs() -> void:
	_mapas_overlay = null
	_config_overlay = null
	_config_panel = null
	_config_confirm = false

var _mapas_overlay: ColorRect = null
var _config_overlay = null
var _config_panel = null
var _config_confirm:= false


func _abrir_mapas(ui: CanvasLayer) -> void:
	if m._menu_contents:
		m._menu_contents.hide()
	if _mapas_overlay and is_instance_valid(_mapas_overlay):
		_mapas_overlay.queue_free()
	var vp: Vector2 = m.get_viewport().get_visible_rect().size
	var ov := ColorRect.new()
	ov.color = Color(0.0, 0.0, 0.0, 0.90)
	ov.size = vp
	ov.mouse_filter = Control.MOUSE_FILTER_STOP
	ui.add_child(ov)
	_mapas_overlay = ov

	var mapa_bg_info : Dictionary = Salvar.mapa_teste_info()
	var mapa_fundo := Control.new()
	mapa_fundo.name = "MapasFundo"
	mapa_fundo.position = Vector2.ZERO
	mapa_fundo.size = vp
	mapa_fundo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	mapa_fundo.set_meta("mapa_bg_path", str(mapa_bg_info.get("bg", "")))
	mapa_fundo.draw.connect(func():
		m._draw_menu_mapa_fundo(mapa_fundo, Rect2(Vector2.ZERO, mapa_fundo.size), mapa_bg_info)
		mapa_fundo.draw_rect(Rect2(Vector2.ZERO, mapa_fundo.size), Color(0.0, 0.0, 0.0, 0.34), true)
		var cor_bg : Color = mapa_bg_info.get("cor", Color(0.0, 0.72, 1.0)) as Color
		mapa_fundo.draw_rect(Rect2(Vector2.ZERO, mapa_fundo.size), Color(cor_bg.r, cor_bg.g, cor_bg.b, 0.08), true)
	)
	ov.add_child(mapa_fundo)

	var pw : float = minf(1040.0, vp.x - 36.0)
	var ph : float = minf(860.0, vp.y - 20.0)
	var px : float = (vp.x - pw) * 0.5
	var py : float = (vp.y - ph) * 0.5
	var pnl: Panel = m._inv_painel(ov, px, py, pw, ph, Color(0.025, 0.035, 0.06, 0.98), Color(0.0, 0.95, 0.85, 0.62), 2)
	m._inv_lbl(pnl, "MAPAS DA TORRE", 0, 18, pw, 36, 28, Color(0.55, 1.0, 0.92), HORIZONTAL_ALIGNMENT_CENTER)
	m._inv_lbl(pnl, "Todos liberados para teste enquanto os modelos estao em criacao.", 36, 56, pw - 72, 24, 15, Color(0.62, 0.76, 0.82), HORIZONTAL_ALIGNMENT_CENTER)

	var cols : int = 2 if pw < 760.0 else 3
	var gap : float = 14.0
	var card_w : float = (pw - 56.0 - gap * float(cols - 1)) / float(cols)
	var card_h : float = 132.0
	var start_y : float = 98.0
	for i in range(Salvar.MAPAS_TORRE.size()):
		var mapa : Dictionary = Salvar.MAPAS_TORRE[i] as Dictionary
		var col : int = i % cols
		var row : int = i / cols
		var pos := Vector2(28.0 + float(col) * (card_w + gap), start_y + float(row) * (card_h + gap))
		var cor : Color = mapa.get("cor", Color(0.0, 0.72, 1.0)) as Color
		var ativo : bool = str(mapa.get("id", "")) == Salvar.mapa_teste_id
		var card := Button.new()
		card.position = pos
		card.size = Vector2(card_w, card_h)
		card.focus_mode = Control.FOCUS_NONE
		card.text = ""
		var sty := StyleBoxFlat.new()
		sty.bg_color = Color(cor.r * 0.10, cor.g * 0.10, cor.b * 0.12, 0.94)
		sty.border_color = Color(cor.r, cor.g, cor.b, 1.0 if ativo else 0.48)
		for side in ["left", "right", "top", "bottom"]:
			sty.set("border_width_" + side, 3 if ativo else 1)
		for corner in ["top_left", "top_right", "bottom_left", "bottom_right"]:
			sty.set("corner_radius_" + corner, 8)
		card.add_theme_stylebox_override("normal", sty)
		card.add_theme_stylebox_override("hover", sty)
		pnl.add_child(card)

		m._inv_lbl(card, str(mapa.get("nome", "Mapa")), 12, 10, card_w - 24, 24, 18, Color(cor.r + 0.18, cor.g + 0.18, cor.b + 0.18), HORIZONTAL_ALIGNMENT_LEFT)
		m._inv_lbl(card, str(mapa.get("faixa", "")), card_w - 126, 12, 112, 22, 13, Color(1.0, 0.86, 0.25), HORIZONTAL_ALIGNMENT_RIGHT)
		m._inv_lbl(card, str(mapa.get("tema", "")), 12, 38, card_w - 24, 20, 13, Color(0.74, 0.86, 0.92), HORIZONTAL_ALIGNMENT_LEFT)
		var desc: Label = m._inv_lbl(card, str(mapa.get("desc", "")), 12, 63, card_w - 24, 38, 12, Color(0.58, 0.66, 0.74), HORIZONTAL_ALIGNMENT_LEFT)
		desc.autowrap_mode = TextServer.AUTOWRAP_WORD
		var mult_txt := "Mobs %.2fx  HP %.2fx  Vel %.2fx" % [float(mapa.get("mob_mult", 1.0)), float(mapa.get("hp_mult", 1.0)), float(mapa.get("speed_mult", 1.0))]
		m._inv_lbl(card, mult_txt, 12, 105, card_w - 24, 18, 11, Color(0.88, 0.78, 0.55), HORIZONTAL_ALIGNMENT_LEFT)
		if ativo:
			m._inv_lbl(card, "SELECIONADO", card_w - 118, 105, 104, 18, 11, Color(0.35, 1.0, 0.55), HORIZONTAL_ALIGNMENT_RIGHT)
		var mid : String = str(mapa.get("id", "setor_inicial"))
		card.pressed.connect(func():
			Salvar.mapa_teste_id = mid
			Salvar.salvar()
			ov.queue_free()
			if _mapas_overlay == ov:
				_mapas_overlay = null
			if m._menu_contents:
				m._menu_contents.show()
			_abrir_mapas(ui)
		)

	# ── Comparação de métodos de sprite ──────────────────────────────────────
	var rows_used  : int   = (Salvar.MAPAS_TORRE.size() + cols - 1) / cols
	var amostras_y : float = start_y + float(rows_used) * (card_h + gap) + 14.0

	m._inv_lbl(pnl, "COMPARAÇÃO DE MÉTODOS DE GERAÇÃO DE SPRITE", 0, amostras_y, pw, 22, 14,
		Color(0.55, 1.0, 0.92), HORIZONTAL_ALIGNMENT_CENTER)

	# Colunas: cada método. Linhas: nave tipo.
	# Métodos: ChatGPT | Python Skia | Node.js Canvas | Python aggdraw
	var metodos := ["ChatGPT\n(IA)", "Python\nSkia", "Node.js\nCanvas", "Python\naggdraw"]
	var cores_metodo := [Color(1.0,0.85,0.2), Color(0.2,0.9,0.4), Color(0.3,0.7,1.0), Color(0.8,0.5,1.0)]

	var naves_rows := [
		["Nave/Interceptador",
			"res://assets/sprites/amostras/chatgpt_nave.png",
			"res://assets/sprites/amostras/skia_interceptador.png",
			"res://assets/sprites/amostras/canvas_interceptador.png",
			"res://assets/sprites/amostras/amostra_interceptador.png"],
		["Kamikaze",
			"res://assets/sprites/amostras/chatgpt_kamikaze.png",
			"res://assets/sprites/amostras/skia_kamikaze.png",
			"res://assets/sprites/amostras/canvas_kamikaze.png",
			"res://assets/sprites/amostras/amostra_kamikaze.png"],
		["Boss",
			"res://assets/sprites/amostras/chatgpt_boss.png",
			"res://assets/sprites/amostras/skia_boss.png",
			"res://assets/sprites/amostras/canvas_boss.png",
			"res://assets/sprites/amostras/amostra_boss.png"],
	]

	var sz_s   : float = 72.0
	var gap_s  : float = 8.0
	var col_w  : float = sz_s + gap_s
	var row_h  : float = sz_s + 24.0
	# Calcular x de inicio centrado
	var label_w : float = 88.0
	var total_cols_w : float = label_w + float(metodos.size()) * col_w
	var sx0 : float = (pw - total_cols_w) * 0.5
	var sy0 : float = amostras_y + 30.0

	# Cabeçalhos de método
	for mi in range(metodos.size()):
		var hx : float = sx0 + label_w + float(mi) * col_w
		var header := Panel.new()
		header.position = Vector2(hx, sy0)
		header.size     = Vector2(sz_s, 32)
		var hs := StyleBoxFlat.new()
		hs.bg_color     = Color(cores_metodo[mi].r*0.15, cores_metodo[mi].g*0.15, cores_metodo[mi].b*0.15, 0.85)
		hs.border_color = Color(cores_metodo[mi].r, cores_metodo[mi].g, cores_metodo[mi].b, 0.6)
		for side in ["left","right","top","bottom"]: hs.set("border_width_"+side, 1)
		for corner in ["top_left","top_right","bottom_left","bottom_right"]: hs.set("corner_radius_"+corner, 4)
		header.add_theme_stylebox_override("panel", hs)
		pnl.add_child(header)
		m._inv_lbl(header, metodos[mi], 0, 2, sz_s, 28, 9, cores_metodo[mi], HORIZONTAL_ALIGNMENT_CENTER)

	# Linhas por tipo de nave
	for ri in range(naves_rows.size()):
		var row_data : Array = naves_rows[ri]
		var nave_nome : String = row_data[0]
		var ry : float = sy0 + 38.0 + float(ri) * row_h

		# Label da nave
		m._inv_lbl(pnl, nave_nome, sx0, ry + sz_s * 0.5 - 8, label_w - 4, 18, 11,
			Color(0.78, 0.88, 0.96), HORIZONTAL_ALIGNMENT_RIGHT)

		# Cards de sprite por método
		for mi in range(metodos.size()):
			var sx : float = sx0 + label_w + float(mi) * col_w
			var scard := Panel.new()
			scard.position = Vector2(sx, ry)
			scard.size     = Vector2(sz_s, sz_s + 16)
			var sty_s := StyleBoxFlat.new()
			sty_s.bg_color     = Color(0.03, 0.05, 0.08, 0.9)
			sty_s.border_color = Color(cores_metodo[mi].r, cores_metodo[mi].g, cores_metodo[mi].b, 0.3)
			for side in ["left","right","top","bottom"]: sty_s.set("border_width_"+side, 1)
			for corner in ["top_left","top_right","bottom_left","bottom_right"]: sty_s.set("corner_radius_"+corner, 4)
			scard.add_theme_stylebox_override("panel", sty_s)
			pnl.add_child(scard)

			var arq : String = row_data[mi + 1]
			if ResourceLoader.exists(arq):
				var tex := load(arq) as Texture2D
				var tr := TextureRect.new()
				tr.texture      = tex
				tr.position     = Vector2(3, 2)
				tr.size         = Vector2(sz_s - 6, sz_s - 4)
				tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
				tr.expand_mode  = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
				scard.add_child(tr)
			else:
				m._inv_lbl(scard, "N/A", 0, sz_s*0.4, sz_s, 18, 10, Color(0.5,0.5,0.5), HORIZONTAL_ALIGNMENT_CENTER)

	# ─────────────────────────────────────────────────────────────────────────
	var fechar := Button.new()
	fechar.text = "FECHAR"
	fechar.position = Vector2((pw - 240.0) * 0.5, ph - 66.0)
	fechar.size = Vector2(240, 44)
	fechar.focus_mode = Control.FOCUS_NONE
	fechar.add_theme_font_size_override("font_size", 18)
	fechar.pressed.connect(func():
		ov.queue_free()
		if _mapas_overlay == ov:
			_mapas_overlay = null
		if m._menu_contents:
			m._menu_contents.show()
	)
	pnl.add_child(fechar)




func _abrir_config(ui: CanvasLayer) -> void :
	if _config_overlay:
		return
	if m._menu_contents:
		m._menu_contents.hide()
	m._ui_ref = ui
	_config_confirm = false

	var _vp_cfg: Vector2 = m.get_viewport().get_visible_rect().size
	_config_overlay = ColorRect.new()
	_config_overlay.color = Color(0.0, 0.0, 0.02, 0.88)
	_config_overlay.position = Vector2.ZERO
	_config_overlay.size = _vp_cfg
	ui.add_child(_config_overlay)

	_config_panel = Control.new()
	_config_panel.position = Vector2((_vp_cfg.x - 1100.0) * 0.5, 10)
	_config_panel.size = Vector2(1100, 770)
	ui.add_child(_config_panel)


	var bg:= Panel.new()
	bg.position = Vector2.ZERO
	bg.size = Vector2(1100, 760)
	var bg_sty:= StyleBoxFlat.new()
	bg_sty.bg_color = Color(0.04, 0.05, 0.09, 0.97)
	bg_sty.border_color = Color(0.35, 0.45, 0.6, 0.7)
	for side in ["left", "right", "top", "bottom"]:
		bg_sty.set("border_width_" + side, 2)
	for corner in ["top_left", "top_right", "bottom_left", "bottom_right"]:
		bg_sty.set("corner_radius_" + corner, 14)
	bg.add_theme_stylebox_override("panel", bg_sty)
	_config_panel.add_child(bg)


	var tit:= Label.new()
	tit.text = "CONFIGURAÇÕES"
	tit.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tit.position = Vector2(0, 16)
	tit.size = Vector2(1100, 50)
	tit.add_theme_font_size_override("font_size", 34)
	tit.add_theme_color_override("font_color", Color(0.72, 0.82, 1.0))
	m._ui_title_label(tit, 4.0)
	_config_panel.add_child(tit)


	var sep:= ColorRect.new()
	sep.color = Color(0.3, 0.4, 0.6, 0.35)
	sep.position = Vector2(40, 68)
	sep.size = Vector2(1020, 2)
	_config_panel.add_child(sep)


	var stats_txt:= "High Score: %s     Ouro no banco: %s     Cristais: %s" % [
		m._format_num(Salvar.high_score), m._format_num(Salvar.ouro_banco), m._format_num(Salvar.cristais)]
	var lstats:= Label.new()
	lstats.text = stats_txt
	lstats.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lstats.autowrap_mode = TextServer.AUTOWRAP_WORD
	lstats.position = Vector2(40, 73)
	lstats.size = Vector2(1020, 32)
	lstats.add_theme_font_size_override("font_size", 17)
	lstats.add_theme_color_override("font_color", Color(0.55, 0.62, 0.72))
	_config_panel.add_child(lstats)

	var sep2:= ColorRect.new()
	sep2.color = Color(0.3, 0.4, 0.6, 0.2)
	sep2.position = Vector2(40, 108)
	sep2.size = Vector2(1020, 2)
	_config_panel.add_child(sep2)


	var lvol:= Label.new()
	lvol.text = "Volume SFX:"
	lvol.position = Vector2(40, 115)
	lvol.size = Vector2(220, 34)
	lvol.add_theme_font_size_override("font_size", 20)
	lvol.add_theme_color_override("font_color", Color(0.72, 0.82, 1.0))
	_config_panel.add_child(lvol)

	var slider:= HSlider.new()
	slider.min_value = 0.0
	slider.max_value = 1.0
	slider.step = 0.05
	slider.value = Som.volume_sfx
	slider.position = Vector2(270, 118)
	slider.size = Vector2(780, 28)
	slider.focus_mode = Control.FOCUS_NONE
	slider.value_changed.connect( func(val: float):
		Som.volume_sfx = val
		Salvar.volume_sfx = val
		Salvar.salvar()
	)
	_config_panel.add_child(slider)


	var lmus:= Label.new()
	lmus.text = "Volume Música:"
	lmus.position = Vector2(40, 153)
	lmus.size = Vector2(220, 34)
	lmus.add_theme_font_size_override("font_size", 20)
	lmus.add_theme_color_override("font_color", Color(0.72, 0.82, 1.0))
	_config_panel.add_child(lmus)

	var slider_mus:= HSlider.new()
	slider_mus.min_value = 0.0
	slider_mus.max_value = 1.0
	slider_mus.step = 0.05
	slider_mus.value = Som.volume_musica
	slider_mus.position = Vector2(270, 156)
	slider_mus.size = Vector2(780, 28)
	slider_mus.focus_mode = Control.FOCUS_NONE
	slider_mus.value_changed.connect( func(val: float):
		Som.set_volume_musica(val)
		Salvar.salvar()
	)
	_config_panel.add_child(slider_mus)


	var lpausa:= Label.new()
	lpausa.text = "Pausa automática entre waves:"
	lpausa.position = Vector2(40, 194)
	lpausa.size = Vector2(500, 34)
	lpausa.add_theme_font_size_override("font_size", 20)
	lpausa.add_theme_color_override("font_color", Color(0.72, 0.82, 1.0))
	_config_panel.add_child(lpausa)

	var chk:= CheckButton.new()
	chk.button_pressed = Salvar.pausa_auto_wave
	chk.position = Vector2(700, 191)
	chk.size = Vector2(200, 42)
	chk.focus_mode = Control.FOCUS_NONE
	chk.add_theme_font_size_override("font_size", 24)
	chk.toggled.connect( func(val: bool):
		Salvar.pausa_auto_wave = val
		Salvar.salvar()
	)
	_config_panel.add_child(chk)


	var ltela:= Label.new()
	ltela.text = "Tela cheia  (F11):"
	ltela.position = Vector2(40, 238)
	ltela.size = Vector2(500, 34)
	ltela.add_theme_font_size_override("font_size", 20)
	ltela.add_theme_color_override("font_color", Color(0.72, 0.82, 1.0))
	_config_panel.add_child(ltela)

	var chk_fs:= CheckButton.new()
	var _is_mobile : bool = OS.has_feature("android") or OS.has_feature("ios")
	chk_fs.button_pressed = _is_mobile or DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN
	chk_fs.disabled = _is_mobile
	chk_fs.position = Vector2(700, 235)
	chk_fs.size = Vector2(200, 42)
	chk_fs.focus_mode = Control.FOCUS_NONE
	chk_fs.add_theme_font_size_override("font_size", 24)
	if not _is_mobile:
		chk_fs.toggled.connect( func(val: bool):
			if val:
				DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
			else:
				DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		)
	_config_panel.add_child(chk_fs)


	var lacess:= Label.new()
	lacess.text = "Acessibilidade (glaucoma):"
	lacess.position = Vector2(40, 282)
	lacess.size = Vector2(500, 34)
	lacess.add_theme_font_size_override("font_size", 20)
	lacess.add_theme_color_override("font_color", Color(0.72, 0.82, 1.0))
	_config_panel.add_child(lacess)

	var lacess2:= Label.new()
	lacess2.text = "(3 cliques para confirmar + leitura de tela)"
	lacess2.position = Vector2(40, 314)
	lacess2.size = Vector2(500, 24)
	lacess2.add_theme_font_size_override("font_size", 15)
	lacess2.add_theme_color_override("font_color", Color(0.5, 0.6, 0.78))
	_config_panel.add_child(lacess2)

	var chk_ac:= CheckButton.new()
	chk_ac.button_pressed = Salvar.acessibilidade_ativo
	chk_ac.position = Vector2(700, 279)
	chk_ac.size = Vector2(200, 42)
	chk_ac.focus_mode = Control.FOCUS_NONE
	chk_ac.add_theme_font_size_override("font_size", 24)
	chk_ac.toggled.connect( func(val: bool):
		Acessibilidade.set_ativo(val)
	)
	_config_panel.add_child(chk_ac)


	var lnome:= Label.new()
	lnome.text = "Nome no Ranking Online:"
	lnome.position = Vector2(40, 344)
	lnome.size = Vector2(420, 34)
	lnome.add_theme_font_size_override("font_size", 19)
	lnome.add_theme_color_override("font_color", Color(1.0, 0.88, 0.3))
	_config_panel.add_child(lnome)

	m._cfg_nome_antigo = Salvar.nome_jogador
	var nome_edit:= LineEdit.new()
	nome_edit.text = Salvar.nome_jogador
	nome_edit.placeholder_text = "Seu nome no ranking (máx 20)"
	nome_edit.position = Vector2(470, 342)
	nome_edit.size = Vector2(590, 38)
	nome_edit.focus_mode = Control.FOCUS_CLICK
	nome_edit.max_length = 20
	nome_edit.add_theme_font_size_override("font_size", 22)
	var sty_nome:= StyleBoxFlat.new()
	sty_nome.bg_color = Color(0.1, 0.09, 0.03, 0.95)
	sty_nome.border_color = Color(1.0, 0.78, 0.1, 0.7)
	for side in ["left", "right", "top", "bottom"]: sty_nome.set("border_width_" + side, 1)
	for corner in ["top_left", "top_right", "bottom_left", "bottom_right"]: sty_nome.set("corner_radius_" + corner, 6)
	nome_edit.add_theme_stylebox_override("normal", sty_nome)
	nome_edit.add_theme_color_override("font_color", Color(1.0, 0.95, 0.6))
	nome_edit.text_changed.connect( func(val: String):
		Salvar.nome_jogador = val.strip_edges()
		Salvar.salvar()
	)
	nome_edit.focus_exited.connect( func():
		var novo:= Salvar.nome_jogador.strip_edges()
		if novo != m._cfg_nome_antigo and m._cfg_nome_antigo != "" and novo != "":
			RankingOnline.renomear(m._cfg_nome_antigo, novo, Salvar.senha_jogador)
			m._cfg_nome_antigo = novo
	)
	_config_panel.add_child(nome_edit)

	var lnome_hint:= Label.new()
	lnome_hint.text = "Seu apelido aparece no ranking global · Deixe vazio para não participar"
	lnome_hint.position = Vector2(40, 383)
	lnome_hint.size = Vector2(1020, 22)
	lnome_hint.add_theme_font_size_override("font_size", 14)
	lnome_hint.add_theme_color_override("font_color", Color(0.55, 0.5, 0.28))
	_config_panel.add_child(lnome_hint)


	var sep4:= ColorRect.new()
	sep4.color = Color(0.3, 0.4, 0.6, 0.2)
	sep4.position = Vector2(40, 409)
	sep4.size = Vector2(1020, 2)
	_config_panel.add_child(sep4)


	var laviso:= Label.new()
	laviso.text = "RESETAR JOGO apaga todo o progresso: ouro, cristais, talentos e melhorias."
	laviso.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	laviso.autowrap_mode = TextServer.AUTOWRAP_WORD
	laviso.position = Vector2(40, 414)
	laviso.size = Vector2(1020, 40)
	laviso.add_theme_font_size_override("font_size", 17)
	laviso.add_theme_color_override("font_color", Color(0.85, 0.6, 0.35))
	_config_panel.add_child(laviso)


	var btn_reset:= Button.new()
	btn_reset.text = "RESETAR JOGO"
	btn_reset.position = Vector2(200, 458)
	btn_reset.size = Vector2(700, 50)
	btn_reset.focus_mode = Control.FOCUS_NONE
	btn_reset.add_theme_font_size_override("font_size", 22)
	var sty_r:= StyleBoxFlat.new()
	sty_r.bg_color = Color(0.22, 0.05, 0.05, 0.92)
	sty_r.border_color = Color(0.85, 0.18, 0.18, 0.85)
	for side in ["left", "right", "top", "bottom"]:
		sty_r.set("border_width_" + side, 2)
	for corner in ["top_left", "top_right", "bottom_left", "bottom_right"]:
		sty_r.set("corner_radius_" + corner, 10)
	btn_reset.add_theme_stylebox_override("normal", sty_r)
	var sty_rh: StyleBoxFlat = sty_r.duplicate()
	sty_rh.bg_color = Color(0.42, 0.08, 0.08, 0.96)
	sty_rh.border_color = Color(1.0, 0.28, 0.28, 1.0)
	btn_reset.add_theme_stylebox_override("hover", sty_rh)
	btn_reset.add_theme_color_override("font_color", Color(1.0, 0.55, 0.55))
	btn_reset.pressed.connect(_on_reset_press.bind(btn_reset))
	_config_panel.add_child(btn_reset)


	var lconfirm:= Label.new()
	lconfirm.name = "LConfirm"
	lconfirm.text = "Clique novamente para confirmar o reset!"
	lconfirm.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lconfirm.position = Vector2(40, 512)
	lconfirm.size = Vector2(1020, 28)
	lconfirm.add_theme_font_size_override("font_size", 17)
	lconfirm.add_theme_color_override("font_color", Color(1.0, 0.35, 0.35))
	lconfirm.visible = false
	_config_panel.add_child(lconfirm)


	if Salvar.nome_jogador != "":
		var btn_logout:= Button.new()
		btn_logout.text = "SAIR DA CONTA  (" + Salvar.nome_jogador + ")"
		btn_logout.position = Vector2(200, 548)
		btn_logout.size = Vector2(700, 50)
		btn_logout.focus_mode = Control.FOCUS_NONE
		btn_logout.add_theme_font_size_override("font_size", 18)
		var sty_lo:= StyleBoxFlat.new()
		sty_lo.bg_color = Color(0.12, 0.06, 0.18, 0.92)
		sty_lo.border_color = Color(0.65, 0.25, 0.9, 0.75)
		for side in ["left", "right", "top", "bottom"]:
			sty_lo.set("border_width_" + side, 1)
		for corner in ["top_left", "top_right", "bottom_left", "bottom_right"]:
			sty_lo.set("corner_radius_" + corner, 8)
		btn_logout.add_theme_stylebox_override("normal", sty_lo)
		var sty_loh: StyleBoxFlat = sty_lo.duplicate()
		sty_loh.bg_color = Color(0.22, 0.08, 0.32, 0.96)
		sty_loh.border_color = Color(0.85, 0.35, 1.0, 0.9)
		btn_logout.add_theme_stylebox_override("hover", sty_loh)
		btn_logout.add_theme_color_override("font_color", Color(0.82, 0.55, 1.0))
		btn_logout.pressed.connect(func():
			var _acc_path := Salvar._save_path()
			Salvar.limpar_dados()
			Salvar.nome_jogador       = ""
			Salvar.email_jogador      = ""
			Salvar.senha_jogador      = ""
			Salvar.player_id          = ""
			Salvar.id_sequencial      = 0
			Salvar.nome_ja_renomeado  = false
			Salvar.credenciais_versao = 0
			var _dir := DirAccess.open("user://")
			if _dir:
				if FileAccess.file_exists(_acc_path): _dir.remove(_acc_path.get_file())
				if FileAccess.file_exists("user://save.json"): _dir.remove("save.json")
			m.get_tree().change_scene_to_file("res://scenes/Menu.tscn"))
		_config_panel.add_child(btn_logout)

	var btn_f:= Button.new()
	btn_f.text = "FECHAR"
	btn_f.position = Vector2(200, 608)
	btn_f.size = Vector2(700, 50)
	btn_f.focus_mode = Control.FOCUS_NONE
	btn_f.add_theme_font_size_override("font_size", 21)
	var sty_f:= StyleBoxFlat.new()
	sty_f.bg_color = Color(0.08, 0.08, 0.1, 0.9)
	sty_f.border_color = Color(0.38, 0.4, 0.48, 0.7)
	for side in ["left", "right", "top", "bottom"]:
		sty_f.set("border_width_" + side, 1)
	for corner in ["top_left", "top_right", "bottom_left", "bottom_right"]:
		sty_f.set("corner_radius_" + corner, 8)
	btn_f.add_theme_stylebox_override("normal", sty_f)
	btn_f.add_theme_color_override("font_color", Color(0.6, 0.62, 0.68))
	btn_f.pressed.connect( func():
		Acessibilidade.processar("config_fechar", "Fechar configurações.", _fechar_config))
	_config_panel.add_child(btn_f)
	m._corrigir_textos_ui(_config_panel)




func _on_reset_press(btn: Button) -> void :
	if not _config_confirm:
		_config_confirm = true
		btn.text = "CONFIRMAR RESET?"
		var sty_c:= StyleBoxFlat.new()
		sty_c.bg_color = Color(0.55, 0.06, 0.06, 0.95)
		sty_c.border_color = Color(1.0, 0.2, 0.2, 1.0)
		for side in ["left", "right", "top", "bottom"]:
			sty_c.set("border_width_" + side, 2)
		for corner in ["top_left", "top_right", "bottom_left", "bottom_right"]:
			sty_c.set("corner_radius_" + corner, 10)
		btn.add_theme_stylebox_override("normal", sty_c)
		var lc = _config_panel.find_child("LConfirm")
		if lc: lc.visible = true
	else:
		RankingOnline.remover_do_ranking(Salvar.nome_jogador)
		RankingOnline.apagar_save_nuvem(Salvar.nome_jogador, Salvar.player_id)
		Salvar.resetar()
		Salvar.nome_jogador       = ""
		Salvar.email_jogador      = ""
		Salvar.senha_jogador      = ""
		Salvar.player_id          = ""
		Salvar.id_sequencial      = 0
		Salvar.nome_ja_renomeado  = false
		Salvar.credenciais_versao = 0
		if FileAccess.file_exists("user://save.json"):
			DirAccess.open("user://").remove("save.json")
		Som.upgrade()
		m.get_tree().change_scene_to_file("res://scenes/Menu.tscn")




func _fechar_config() -> void :
	Acessibilidade.cancelar_foco()
	if _config_overlay and is_instance_valid(_config_overlay):
		_config_overlay.queue_free()
	if _config_panel and is_instance_valid(_config_panel):
		_config_panel.queue_free()
	_config_overlay = null
	_config_panel = null
	_config_confirm = false
	m._ui_ref = null
	if m._menu_contents:
		m._menu_contents.show()




