extends Node2D
## Efeito ISOLADO: feixe de laser (linha reta brilhante que pisca e some).
## Usado pelo Aniquilador — é um RAIO instantâneo, não projétil. Carga com
## guarda; se falhar, o dano do feixe ainda é aplicado pela torre.

var _ate  : Vector2 = Vector2.ZERO
var _t    : float = 0.0
var _dur  : float = 0.18
var _cor  : Color = Color(1.0, 0.35, 0.55)
var _larg : float = 8.0

func iniciar(de: Vector2, ate: Vector2, cor: Color = Color(1.0, 0.35, 0.55), larg: float = 8.0) -> void:
	global_position = de
	_ate  = ate - de
	_cor  = cor
	_larg = larg

func _process(delta: float) -> void:
	_t += delta
	queue_redraw()
	if _t >= _dur:
		queue_free()

func _draw() -> void:
	var a : float = 1.0 - (_t / _dur)
	draw_line(Vector2.ZERO, _ate, Color(_cor.r, _cor.g, _cor.b, 0.28 * a), _larg * 2.3)
	draw_line(Vector2.ZERO, _ate, Color(_cor.r, _cor.g, _cor.b, 0.70 * a), _larg)
	draw_line(Vector2.ZERO, _ate, Color(1.0, 1.0, 1.0, a), _larg * 0.4)
