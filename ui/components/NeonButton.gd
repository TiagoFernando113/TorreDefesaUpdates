extends Button

var accent: Color = Color(0.25, 0.85, 1.0)
var active: bool = false


func _ready() -> void:
	focus_mode = Control.FOCUS_NONE
	flat = true
	mouse_entered.connect(_on_hovered)
	mouse_exited.connect(_on_unhovered)
	button_down.connect(func(): queue_redraw())
	button_up.connect(func(): queue_redraw())
	add_theme_stylebox_override("normal", StyleBoxEmpty.new())
	add_theme_stylebox_override("hover", StyleBoxEmpty.new())
	add_theme_stylebox_override("pressed", StyleBoxEmpty.new())
	add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	add_theme_stylebox_override("hover_pressed", StyleBoxEmpty.new())
	add_theme_color_override("font_color", Color(0.82, 0.94, 1.0))
	pivot_offset = size * 0.5


func configure(p_text: String, p_accent: Color, p_active: bool = false, font_size: int = 14) -> void:
	text = p_text
	accent = p_accent
	active = p_active
	add_theme_font_size_override("font_size", font_size)
	queue_redraw()


func _on_hovered() -> void:
	pivot_offset = size * 0.5
	var tw := create_tween()
	tw.tween_property(self, "scale", Vector2(1.035, 1.035), 0.10).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	queue_redraw()


func _on_unhovered() -> void:
	var tw := create_tween()
	tw.tween_property(self, "scale", Vector2.ONE, 0.12).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	queue_redraw()


func _draw() -> void:
	var hover := is_hovered()
	var down := button_pressed
	var bg_alpha := 0.22 if active else 0.10
	if hover:
		bg_alpha += 0.10
	if down:
		bg_alpha += 0.08
	var rect := Rect2(Vector2.ZERO, size)
	draw_rect(rect, Color(accent.r * 0.22, accent.g * 0.22, accent.b * 0.28, bg_alpha))
	for i in range(3, 0, -1):
		draw_rect(rect.grow(float(i) * 1.4), Color(accent.r, accent.g, accent.b, 0.035 * float(i)), false, float(i))
	draw_rect(rect, Color(accent.r, accent.g, accent.b, 0.80 if active or hover else 0.48), false, 1.4)
	var cut := minf(10.0, size.y * 0.35)
	draw_line(Vector2(0, cut), Vector2(cut, 0), Color(accent.r, accent.g, accent.b, 0.75), 1.0)
	draw_line(Vector2(size.x - cut, size.y), Vector2(size.x, size.y - cut), Color(accent.r, accent.g, accent.b, 0.75), 1.0)
