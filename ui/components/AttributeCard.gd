extends PanelContainer

signal upgrade_pressed(attribute_id: String)

const NeonButton = preload("res://ui/components/NeonButton.gd")

var attribute_id: String = ""
var display_name: String = ""
var description: String = ""
var level: int = 0
var max_level: int = 1
var bonus_text: String = ""
var accent: Color = Color(0.2, 0.9, 1.0)
var can_upgrade: bool = false
var _plus: Button = null
var _font: Font = ThemeDB.fallback_font


func setup(data: Dictionary) -> void:
	attribute_id = str(data.get("id", ""))
	display_name = str(data.get("name", attribute_id)).to_upper()
	description = str(data.get("description", ""))
	level = int(data.get("level", 0))
	max_level = maxi(1, int(data.get("max_level", 1)))
	bonus_text = str(data.get("bonus", ""))
	accent = data.get("color", accent) as Color
	can_upgrade = bool(data.get("can_upgrade", false))
	if data.get("font", null) is Font:
		_font = data.get("font") as Font
	_build()
	queue_redraw()


func _ready() -> void:
	add_theme_stylebox_override("panel", StyleBoxEmpty.new())
	mouse_filter = Control.MOUSE_FILTER_PASS


func _build() -> void:
	for ch in get_children():
		ch.queue_free()
	_plus = null
	var root := MarginContainer.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_theme_constant_override("margin_left", 18)
	root.add_theme_constant_override("margin_top", 14)
	root.add_theme_constant_override("margin_right", 18)
	root.add_theme_constant_override("margin_bottom", 12)
	add_child(root)
	var stack := VBoxContainer.new()
	stack.add_theme_constant_override("separation", 0)
	root.add_child(stack)
	var top := HBoxContainer.new()
	top.add_theme_constant_override("separation", 12)
	stack.add_child(top)
	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(82, 1)
	top.add_child(spacer)
	var name_box := VBoxContainer.new()
	name_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_box.add_theme_constant_override("separation", 0)
	top.add_child(name_box)
	var name_lbl := _label(display_name, 15, accent)
	name_box.add_child(name_lbl)
	var lvl_lbl := _label("%d / %d" % [level, max_level], 14, Color(0.82, 0.88, 0.98))
	name_box.add_child(lvl_lbl)
	var pad := Control.new()
	pad.size_flags_vertical = Control.SIZE_EXPAND_FILL
	pad.custom_minimum_size = Vector2(1, 14)
	stack.add_child(pad)
	var bonus_lbl := _label(bonus_text, 16, Color(minf(accent.r + 0.22, 1.0), minf(accent.g + 0.22, 1.0), minf(accent.b + 0.22, 1.0)))
	bonus_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	bonus_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	bonus_lbl.custom_minimum_size = Vector2(0, 28)
	stack.add_child(bonus_lbl)
	var bottom_pad := Control.new()
	bottom_pad.custom_minimum_size = Vector2(1, 26)
	stack.add_child(bottom_pad)
	_plus = NeonButton.new()
	_plus.configure("+", accent, can_upgrade, 21)
	_plus.disabled = not can_upgrade
	_plus.position = Vector2(size.x - 46, size.y - 48)
	_plus.size = Vector2(36, 36)
	_plus.pressed.connect(func(): upgrade_pressed.emit(attribute_id))
	add_child(_plus)


func _label(txt: String, fs: int, color: Color) -> Label:
	var l := Label.new()
	l.text = txt
	l.clip_text = true
	l.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	l.add_theme_font_override("font", _font)
	l.add_theme_font_size_override("font_size", fs)
	l.add_theme_color_override("font_color", color)
	return l


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED and _plus:
		_plus.position = Vector2(maxf(0.0, size.x - 46.0), maxf(0.0, size.y - 48.0))
		_plus.size = Vector2(36, 36)


func _draw() -> void:
	var w := size.x
	var h := size.y
	if w <= 2.0 or h <= 2.0:
		return
	var cut := 18.0
	var poly := PackedVector2Array([
		Vector2(cut, 0), Vector2(w - cut, 0), Vector2(w, cut),
		Vector2(w, h - cut), Vector2(w - cut, h), Vector2(cut, h),
		Vector2(0, h - cut), Vector2(0, cut), Vector2(cut, 0)
	])
	draw_colored_polygon(poly, Color(accent.r * 0.050, accent.g * 0.050, accent.b * 0.065, 0.96))
	draw_rect(Rect2(8, 8, w - 16, h - 16), Color(accent.r, accent.g, accent.b, 0.025))
	for i in range(3, 0, -1):
		draw_polyline(poly, Color(accent.r, accent.g, accent.b, 0.035 * float(i)), float(i) * 2.0)
	draw_polyline(poly, Color(accent.r, accent.g, accent.b, 0.88), 1.6)
	var icon_c := Vector2(48, 47)
	draw_circle(icon_c, 33, Color(accent.r, accent.g, accent.b, 0.11))
	draw_arc(icon_c, 33, -PI * 0.80, PI * 1.20, 70, Color(accent.r, accent.g, accent.b, 0.95), 3.0, true)
	_draw_icon(icon_c)
	var segs := 12
	var filled := int(round(float(level) / maxf(float(max_level), 1.0) * float(segs)))
	var sx := 18.0
	var sy := h - 28.0
	var sw := (w - 36.0 - float(segs - 1) * 4.0) / float(segs)
	for i in range(segs):
		var r := Rect2(sx + float(i) * (sw + 4.0), sy, sw, 7.0)
		draw_rect(r, Color(accent.r, accent.g, accent.b, 0.92 if i < filled else 0.16))
		draw_rect(r, Color(accent.r, accent.g, accent.b, 0.34), false, 0.8)
	draw_circle(Vector2(w - 24, h - 24), 28, Color(accent.r, accent.g, accent.b, 0.055))


func _draw_icon(center: Vector2) -> void:
	match attribute_id:
		"vida":
			var pts := PackedVector2Array([center + Vector2(0, 15), center + Vector2(-17, -2), center + Vector2(-8, -15), center, center + Vector2(8, -15), center + Vector2(17, -2), center + Vector2(0, 15)])
			draw_colored_polygon(pts, Color(accent.r, accent.g, accent.b, 0.94))
		"defesa":
			var sh := PackedVector2Array([center + Vector2(0, -19), center + Vector2(17, -8), center + Vector2(13, 13), center + Vector2(0, 20), center + Vector2(-13, 13), center + Vector2(-17, -8), center + Vector2(0, -19)])
			draw_polyline(sh, Color(accent.r, accent.g, accent.b, 0.95), 2.2)
		"dano":
			draw_arc(center, 18, 0, TAU, 48, Color(accent.r, accent.g, accent.b, 0.95), 2.0, true)
			draw_line(center + Vector2(-18, 0), center + Vector2(18, 0), accent, 2.0)
			draw_line(center + Vector2(0, -18), center + Vector2(0, 18), accent, 2.0)
		"agilidade":
			draw_line(center + Vector2(-15, 16), center + Vector2(18, -17), accent, 3.2)
			draw_line(center + Vector2(-4, 18), center + Vector2(22, -8), Color(accent.r, accent.g, accent.b, 0.62), 2.0)
		"alcance":
			for r in [8.0, 14.0, 21.0]:
				draw_arc(center, r, -PI * 0.85, -PI * 0.15, 24, Color(accent.r, accent.g, accent.b, 0.80), 1.7, true)
			draw_line(center, center + Vector2(0, 20), accent, 2.0)
		"fortuna":
			draw_circle(center + Vector2(-6, 3), 10.0, Color(accent.r, accent.g, accent.b, 0.88))
			draw_circle(center + Vector2(8, -6), 10.0, Color(accent.r, accent.g, accent.b, 0.62))
		"critico":
			var star := PackedVector2Array()
			for i in range(11):
				var rr := 22.0 if i % 2 == 0 else 8.0
				var a := -PI * 0.5 + float(i) * TAU / 10.0
				star.append(center + Vector2(cos(a), sin(a)) * rr)
			draw_colored_polygon(star, Color(accent.r, accent.g, accent.b, 0.92))
		"tecnologia":
			draw_rect(Rect2(center - Vector2(16, 16), Vector2(32, 32)), Color(accent.r, accent.g, accent.b, 0.28), false, 2.0)
			draw_rect(Rect2(center - Vector2(8, 8), Vector2(16, 16)), Color(accent.r, accent.g, accent.b, 0.86), false, 1.6)
		_:
			draw_string(_font, center + Vector2(-18, 8), "++", HORIZONTAL_ALIGNMENT_CENTER, 36, 18, accent)
