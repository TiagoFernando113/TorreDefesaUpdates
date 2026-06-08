extends Node2D

const W: float = 1280.0
const H: float = 720.0
const MID_X: float = 640.0

var _t: float = 0.0


func _process(delta: float) -> void:
	_t += delta
	queue_redraw()


func _draw() -> void:
	_fundo()
	_lados()
	_divisor()
	_zonas_torre()


func _fundo() -> void:
	draw_rect(Rect2(0, 0, W, H), Color(0.018, 0.014, 0.035))
	var rng := RandomNumberGenerator.new()
	rng.seed = 77
	for _i in range(80):
		var pos := Vector2(rng.randf_range(0.0, W), rng.randf_range(36.0, H - 28.0))
		var a := 0.22 + 0.35 * absf(sin(_t * rng.randf_range(0.25, 1.1) + rng.randf() * TAU))
		draw_circle(pos, rng.randf_range(0.5, 1.3), Color(0.75, 0.86, 1.0, a))


func _lados() -> void:
	draw_rect(Rect2(0, 0, MID_X, H), Color(0.0, 0.14, 0.20, 0.18), true)
	draw_rect(Rect2(MID_X, 0, MID_X, H), Color(0.22, 0.02, 0.16, 0.18), true)
func _divisor() -> void:
	var pulse := 0.55 + sin(_t * 2.2) * 0.20
	draw_line(Vector2(MID_X, 70.0), Vector2(MID_X, H - 30.0), Color(0.70, 0.82, 1.0, 0.44 * pulse), 2.0)
	draw_line(Vector2(MID_X, 70.0), Vector2(MID_X, H - 30.0), Color(0.40, 0.60, 1.0, 0.08 * pulse), 10.0)


func _zonas_torre() -> void:
	_zona(Vector2(260.0, 375.0), Color(0.0, 0.85, 1.0))
	_zona(Vector2(1020.0, 375.0), Color(1.0, 0.22, 0.65))


func _zona(pos: Vector2, cor: Color) -> void:
	draw_arc(pos, 90.0, 0.0, TAU, 64, Color(cor.r, cor.g, cor.b, 0.16), 2.0)
	draw_arc(pos, 145.0, 0.0, TAU, 72, Color(cor.r, cor.g, cor.b, 0.07), 1.3)
