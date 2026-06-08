extends PanelContainer

var accent: Color = Color(0.55, 0.22, 1.0)
var fill: Color = Color(0.015, 0.018, 0.040, 0.88)
var border_alpha: float = 0.78
var cut: float = 18.0
var glow: bool = true


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_PASS
	add_theme_stylebox_override("panel", StyleBoxEmpty.new())


func configure(p_accent: Color, p_fill: Color = Color(0.015, 0.018, 0.040, 0.88), p_cut: float = 18.0, p_glow: bool = true) -> void:
	accent = p_accent
	fill = p_fill
	cut = p_cut
	glow = p_glow
	queue_redraw()


func _draw() -> void:
	var w := size.x
	var h := size.y
	if w <= 2.0 or h <= 2.0:
		return
	var c := minf(cut, minf(w, h) * 0.22)
	var poly := PackedVector2Array([
		Vector2(c, 0), Vector2(w - c, 0), Vector2(w, c),
		Vector2(w, h - c), Vector2(w - c, h), Vector2(c, h),
		Vector2(0, h - c), Vector2(0, c), Vector2(c, 0)
	])
	draw_colored_polygon(poly, fill)
	if glow:
		for i in range(4, 0, -1):
			draw_polyline(poly, Color(accent.r, accent.g, accent.b, 0.045 * float(i)), float(i) * 2.2)
	draw_polyline(poly, Color(accent.r, accent.g, accent.b, border_alpha), 1.6)
	draw_line(Vector2(c + 10, 10), Vector2(w * 0.38, 10), Color(accent.r, accent.g, accent.b, 0.20), 1.0)
	draw_line(Vector2(w - c - 10, h - 10), Vector2(w * 0.62, h - 10), Color(accent.r, accent.g, accent.b, 0.18), 1.0)
	draw_circle(Vector2(c * 0.65, c * 0.65), 2.0, Color(accent.r, accent.g, accent.b, 0.95))
	draw_circle(Vector2(w - c * 0.65, c * 0.65), 2.0, Color(accent.r, accent.g, accent.b, 0.95))
	draw_circle(Vector2(c * 0.65, h - c * 0.65), 2.0, Color(accent.r, accent.g, accent.b, 0.95))
	draw_circle(Vector2(w - c * 0.65, h - c * 0.65), 2.0, Color(accent.r, accent.g, accent.b, 0.95))
