extends Control

signal closed

const SciFiPanel = preload("res://ui/components/SciFiPanel.gd")
const AttributeCard = preload("res://ui/components/AttributeCard.gd")
const NeonButton = preload("res://ui/components/NeonButton.gd")
const CYRON_THEME = preload("res://ui/theme/cyron_theme.tres")
const TITLE_FONT : FontFile = preload("res://assets/fonts/ethnocentric_rg.otf")
const TECH_FONT : FontFile = preload("res://assets/fonts/bahnschrift.ttf")

var _panel: Control = null
var _pulse: float = 0.0


func _ready() -> void:
	theme = CYRON_THEME
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	_build()
	modulate.a = 0.0
	scale = Vector2(0.985, 0.985)
	pivot_offset = get_viewport_rect().size * 0.5
	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(self, "modulate:a", 1.0, 0.22).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(self, "scale", Vector2.ONE, 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _process(delta: float) -> void:
	_pulse += delta
	queue_redraw()
	if _panel:
		_panel.queue_redraw()


func _build() -> void:
	for ch in get_children():
		ch.queue_free()
	var vp := get_viewport_rect().size
	var root_margin := MarginContainer.new()
	root_margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	root_margin.add_theme_constant_override("margin_left", 22)
	root_margin.add_theme_constant_override("margin_top", 22)
	root_margin.add_theme_constant_override("margin_right", 22)
	root_margin.add_theme_constant_override("margin_bottom", 22)
	add_child(root_margin)

	_panel = SciFiPanel.new()
	_panel.configure(Color(0.64, 0.26, 1.0), Color(0.006, 0.008, 0.018, 0.96), 22, true)
	_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root_margin.add_child(_panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 22)
	margin.add_theme_constant_override("margin_top", 18)
	margin.add_theme_constant_override("margin_right", 22)
	margin.add_theme_constant_override("margin_bottom", 14)
	_panel.add_child(margin)

	var main := VBoxContainer.new()
	main.add_theme_constant_override("separation", 9)
	margin.add_child(main)

	_build_header(main)
	_build_title_band(main)
	_build_content(main)
	_build_footer(main)


func _draw() -> void:
	var s := size
	draw_rect(Rect2(Vector2.ZERO, s), Color(0, 0, 0, 0.88))
	var planet := Vector2(s.x * 0.62, s.y * 0.35)
	for r in [360.0, 260.0, 180.0]:
		draw_circle(planet, r, Color(0.34, 0.12, 0.72, 0.030 + r / 20000.0))
	draw_arc(planet, 260.0, -PI * 0.88, -PI * 0.05, 160, Color(0.82, 0.42, 1.0, 0.22), 3.0, true)
	for i in range(80):
		var x := fmod(float(i * 97), maxf(s.x, 1.0))
		var y := fmod(float(i * 53), maxf(s.y, 1.0))
		var a := 0.10 + float(i % 5) * 0.025
		draw_circle(Vector2(x, y), 0.8 + float(i % 3) * 0.35, Color(0.55, 0.78, 1.0, a))
	for i in range(12):
		var x2 := 40.0 + float(i) * 118.0
		draw_line(Vector2(x2, 26), Vector2(x2 - 100.0, s.y - 42.0), Color(0.30, 0.15, 0.85, 0.025), 1.0)


func _build_header(parent: VBoxContainer) -> void:
	var header := SciFiPanel.new()
	header.configure(Color(0.56, 0.22, 1.0), Color(0.012, 0.016, 0.036, 0.76), 18, true)
	header.custom_minimum_size = Vector2(0, 154)
	header.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	parent.add_child(header)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 38)
	margin.add_theme_constant_override("margin_top", 16)
	margin.add_theme_constant_override("margin_right", 38)
	margin.add_theme_constant_override("margin_bottom", 14)
	header.add_child(margin)

	var info := VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info.add_theme_constant_override("separation", 1)
	margin.add_child(info)

	var patent_title := _label("PATENTE ESPACIAL", 24, Color(0.78, 0.38, 1.0), TITLE_FONT)
	patent_title.custom_minimum_size = Vector2(0, 30)
	info.add_child(patent_title)

	var rank_label := _label("%s  /  NIVEL %d" % [Salvar.patente_conta().to_upper(), Salvar.nivel_conta], 22, Color(0.78, 0.34, 1.0), TECH_FONT)
	rank_label.custom_minimum_size = Vector2(0, 26)
	info.add_child(rank_label)

	var xp_need := Salvar.xp_para_proximo_nivel()
	var xp_lbl := _label("XP: %d / %d" % [Salvar.xp_conta, xp_need], 14, Color(0.78, 0.84, 0.95), TECH_FONT)
	xp_lbl.custom_minimum_size = Vector2(0, 16)
	info.add_child(xp_lbl)

	var xp := ProgressBar.new()
	xp.min_value = 0
	xp.max_value = xp_need
	xp.value = Salvar.xp_conta
	xp.show_percentage = false
	xp.custom_minimum_size = Vector2(0, 10)
	info.add_child(xp)

	var prox := Salvar.proxima_patente_conta()
	var prox_txt := "PATENTE MAXIMA ALCANCADA" if prox.is_empty() else "PROXIMA PATENTE: %s (NV. %d)" % [str(prox.get("nome", "")).to_upper(), int(prox.get("nivel", 0))]
	var next_label := _label(prox_txt, 13, Color(0.58, 0.66, 0.86), TECH_FONT)
	next_label.custom_minimum_size = Vector2(0, 16)
	info.add_child(next_label)


func _emblem_block() -> Control:
	var c := Control.new()
	c.custom_minimum_size = Vector2(126, 126)
	c.draw.connect(func():
		var mid := c.size * 0.5
		for r in [57.0, 44.0, 31.0]:
			c.draw_arc(mid, r, _pulse * 0.45, TAU + _pulse * 0.45, 94, Color(0.70, 0.25, 1.0, 0.18 + r / 280.0), 2.0, true)
		var badge := PackedVector2Array([
			mid + Vector2(0, -40), mid + Vector2(34, -18), mid + Vector2(27, 27),
			mid + Vector2(0, 48), mid + Vector2(-27, 27), mid + Vector2(-34, -18), mid + Vector2(0, -40)
		])
		c.draw_colored_polygon(badge, Color(0.045, 0.020, 0.095, 0.95))
		c.draw_polyline(badge, Color(0.78, 0.42, 1.0, 0.96), 2.5)
		c.draw_line(mid + Vector2(0, -22), mid + Vector2(0, 26), Color(0.92, 0.72, 1.0, 0.82), 2.2)
		c.draw_line(mid + Vector2(-18, -4), mid + Vector2(18, -4), Color(0.92, 0.72, 1.0, 0.82), 2.2)
		c.draw_line(mid + Vector2(-18, 18), mid + Vector2(18, 18), Color(0.70, 0.25, 1.0, 0.74), 2.0)
	)
	return c


func _rank_medal() -> Control:
	var c := Control.new()
	c.custom_minimum_size = Vector2(170, 142)
	c.draw.connect(func():
		var mid := c.size * 0.5
		for r in [66.0, 50.0]:
			c.draw_arc(mid, r, -PI * 0.85 - _pulse * 0.18, PI * 1.18 - _pulse * 0.18, 110, Color(1.0, 0.72, 0.16, 0.24), 2.0, true)
		var medal := PackedVector2Array([
			mid + Vector2(0, -48), mid + Vector2(43, -22), mid + Vector2(34, 36),
			mid + Vector2(0, 64), mid + Vector2(-34, 36), mid + Vector2(-43, -22), mid + Vector2(0, -48)
		])
		c.draw_colored_polygon(medal, Color(0.12, 0.055, 0.005, 0.96))
		c.draw_polyline(medal, Color(1.0, 0.82, 0.22, 0.95), 3.0)
		var star := PackedVector2Array()
		for i in range(11):
			var rr := 26.0 if i % 2 == 0 else 11.0
			var a := -PI * 0.5 + float(i) * TAU / 10.0
			star.append(mid + Vector2(cos(a), sin(a)) * rr)
		c.draw_colored_polygon(star, Color(1.0, 0.72, 0.12, 0.96))
	)
	return c


func _build_title_band(parent: VBoxContainer) -> void:
	var band := VBoxContainer.new()
	band.add_theme_constant_override("separation", 0)
	parent.add_child(band)
	var title := _label("ATRIBUTOS DA CONTA", 27, Color(0.92, 0.92, 1.0), TITLE_FONT)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	band.add_child(title)
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 14)
	band.add_child(row)
	row.add_child(_label("PONTOS DISPONIVEIS", 14, Color(0.78, 0.34, 1.0), TECH_FONT))
	row.add_child(_label("%d" % Salvar.pontos_atributo, 24, Color(0.86, 0.45, 1.0), TITLE_FONT))
	var hint := _label("Cada nivel concede +1 ponto para melhorar seus atributos permanentes.", 10, Color(0.58, 0.64, 0.82), TECH_FONT)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	band.add_child(hint)


func _build_content(parent: VBoxContainer) -> void:
	var content := HBoxContainer.new()
	content.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.add_theme_constant_override("separation", 18)
	parent.add_child(content)

	var grid := GridContainer.new()
	grid.columns = 4
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.size_flags_vertical = Control.SIZE_EXPAND_FILL
	grid.add_theme_constant_override("h_separation", 10)
	grid.add_theme_constant_override("v_separation", 10)
	content.add_child(grid)
	for id in ["vida", "defesa", "dano", "agilidade", "alcance", "fortuna", "critico", "tecnologia"]:
		var card := AttributeCard.new()
		card.custom_minimum_size = Vector2(190, 138)
		card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		card.size_flags_vertical = Control.SIZE_EXPAND_FILL
		card.setup(_attribute_data(id))
		card.upgrade_pressed.connect(_on_upgrade_pressed)
		grid.add_child(card)

	var side := SciFiPanel.new()
	side.configure(Color(0.36, 0.58, 1.0), Color(0.010, 0.014, 0.030, 0.94), 14, true)
	side.custom_minimum_size = Vector2(226, 0)
	side.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.add_child(side)
	var side_margin := MarginContainer.new()
	side_margin.add_theme_constant_override("margin_left", 14)
	side_margin.add_theme_constant_override("margin_top", 14)
	side_margin.add_theme_constant_override("margin_right", 14)
	side_margin.add_theme_constant_override("margin_bottom", 14)
	side.add_child(side_margin)
	var side_box := VBoxContainer.new()
	side_box.add_theme_constant_override("separation", 7)
	side_margin.add_child(side_box)
	var rs := _label("RESUMO DE BONUS", 13, Color(0.78, 0.84, 1.0), TECH_FONT)
	rs.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	side_box.add_child(rs)
	for id in ["vida", "defesa", "dano", "agilidade", "alcance", "fortuna", "critico", "tecnologia"]:
		side_box.add_child(_summary_row(id))
	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	side_box.add_child(spacer)
	var how := _label("COMO FUNCIONA", 12, Color(0.86, 0.86, 1.0), TECH_FONT)
	how.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	side_box.add_child(how)
	var desc := _label("Ganhe XP nas partidas.\nCada nivel concede 1 ponto.\nOs bonus sao permanentes.", 10, Color(0.62, 0.68, 0.86), TECH_FONT)
	desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	side_box.add_child(desc)


func _build_footer(parent: VBoxContainer) -> void:
	var footer := HBoxContainer.new()
	footer.alignment = BoxContainer.ALIGNMENT_CENTER
	parent.add_child(footer)
	var back := NeonButton.new()
	back.configure("VOLTAR", Color(0.10, 0.82, 1.0), false, 14)
	back.custom_minimum_size = Vector2(210, 34)
	back.pressed.connect(func(): closed.emit())
	footer.add_child(back)


func _attribute_data(id: String) -> Dictionary:
	var info : Dictionary = Salvar.ATRIBUTOS_CONTA_INFO[id] as Dictionary
	var lvl := int(Salvar.atributos_conta.get(id, 0))
	return {
		"id": id,
		"name": str(info.get("nome", id)),
		"description": str(info.get("desc", "")),
		"level": lvl,
		"max_level": int(info.get("max", 1)),
		"bonus": _bonus_text(id, lvl),
		"color": _attr_color(id),
		"can_upgrade": Salvar.pontos_atributo > 0 and lvl < int(info.get("max", 1)),
		"font": TECH_FONT,
	}


func _summary_row(id: String) -> Control:
	var row := Control.new()
	row.custom_minimum_size = Vector2(0, 22)
	var lvl := int(Salvar.atributos_conta.get(id, 0))
	var c := _attr_color(id)
	row.draw.connect(func():
		row.draw_line(Vector2(0, 21), Vector2(row.size.x, 21), Color(0.25, 0.32, 0.55, 0.28), 1.0)
		row.draw_circle(Vector2(10, 10), 8.0, Color(c.r, c.g, c.b, 0.18))
		row.draw_arc(Vector2(10, 10), 8.0, 0.0, TAU, 22, Color(c.r, c.g, c.b, 0.88), 1.2, true)
		row.draw_string(TECH_FONT, Vector2(26, 15), _bonus_text(id, lvl), HORIZONTAL_ALIGNMENT_LEFT, row.size.x - 26, 12, Color(c.r + 0.10, c.g + 0.10, c.b + 0.10, 0.95))
	)
	return row


func _on_upgrade_pressed(id: String) -> void:
	if Salvar.gastar_ponto_atributo(id):
		_build()


func _label(txt: String, fs: int, color: Color, font: Font) -> Label:
	var l := Label.new()
	l.text = txt
	l.add_theme_font_override("font", font)
	l.add_theme_font_size_override("font_size", fs)
	l.add_theme_color_override("font_color", color)
	l.clip_text = true
	l.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	return l


func _bonus_text(id: String, lvl: int) -> String:
	match id:
		"vida": return "+%d HP" % (lvl * 8)
		"dano": return "+%d%% DANO" % lvl
		"defesa": return "-%.1f%% DANO" % (float(lvl) * 0.3)
		"agilidade": return "+%.1f%% CADENCIA" % (float(lvl) * 0.6)
		"alcance": return "+%d ALCANCE" % (lvl * 3)
		"fortuna": return "+%d%% OURO" % lvl
		"critico": return "+%.1f%% CRITICO" % (float(lvl) * 0.25)
		"tecnologia": return "-%.1f%% COOLDOWN" % (float(lvl) * 0.4)
	return ""


func _attr_color(id: String) -> Color:
	match id:
		"vida": return Color(0.24, 1.0, 0.50)
		"dano": return Color(1.0, 0.35, 0.16)
		"defesa": return Color(0.35, 0.70, 1.0)
		"agilidade": return Color(0.78, 0.35, 1.0)
		"alcance": return Color(0.16, 0.85, 1.0)
		"fortuna": return Color(1.0, 0.78, 0.16)
		"critico": return Color(1.0, 0.50, 0.08)
		"tecnologia": return Color(0.30, 1.0, 0.86)
	return Color(0.85, 0.9, 1.0)
