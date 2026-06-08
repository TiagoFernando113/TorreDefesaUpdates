extends Control

var accent: Color = Color(1.0, 0.72, 0.16)
var rank_level: int = 1
var _pulse: float = 0.0


func setup(level: int, color: Color = Color(1.0, 0.72, 0.16)) -> void:
	rank_level = maxi(1, level)
	accent = color
	queue_redraw()


func _process(delta: float) -> void:
	_pulse += delta
	queue_redraw()


func _draw() -> void:
	var mid := size * 0.5
	var radius := minf(size.x, size.y) * 0.44
	for i in range(4, 0, -1):
		draw_circle(mid, radius * (0.62 + float(i) * 0.13), Color(accent.r, accent.g, accent.b, 0.020 * float(i)))
	draw_arc(mid, radius * 0.88, -PI * 0.85 - _pulse * 0.18, PI * 1.18 - _pulse * 0.18, 110, Color(accent.r, accent.g, accent.b, 0.36), 2.4, true)
	draw_arc(mid, radius * 0.68, PI * 0.12 + _pulse * 0.25, PI * 1.75 + _pulse * 0.25, 80, Color(0.72, 0.28, 1.0, 0.28), 1.8, true)
	var medal := PackedVector2Array([
		mid + Vector2(0, -radius * 0.70),
		mid + Vector2(radius * 0.58, -radius * 0.32),
		mid + Vector2(radius * 0.46, radius * 0.52),
		mid + Vector2(0, radius * 0.86),
		mid + Vector2(-radius * 0.46, radius * 0.52),
		mid + Vector2(-radius * 0.58, -radius * 0.32),
		mid + Vector2(0, -radius * 0.70)
	])
	draw_colored_polygon(medal, Color(0.12, 0.055, 0.005, 0.96))
	draw_polyline(medal, Color(accent.r, accent.g, accent.b, 0.95), 3.0)
	var star := PackedVector2Array()
	for i in range(11):
		var rr := radius * (0.34 if i % 2 == 0 else 0.14)
		var a := -PI * 0.5 + float(i) * TAU / 10.0
		star.append(mid + Vector2(cos(a), sin(a)) * rr)
	draw_colored_polygon(star, Color(1.0, 0.72, 0.12, 0.96))
