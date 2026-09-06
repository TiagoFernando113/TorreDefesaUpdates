extends Node2D
## Efeito visual ISOLADO: arco elétrico (raio em ziguezague) entre dois pontos.
## Usado pela Corrente Elétrica para mostrar o salto do dano (antes invisível =
## "dano fantasma"). Carregado com guarda; se falhar, o dano do chain continua.

var _ate : Vector2 = Vector2.ZERO
var _t   : float = 0.0
var _dur : float = 0.22
var _cor : Color = Color(0.45, 0.85, 1.0)
var _segs : PackedVector2Array = PackedVector2Array()

func iniciar(de: Vector2, ate: Vector2, cor: Color = Color(0.45, 0.85, 1.0)) -> void:
	global_position = de
	_ate = ate - de
	_cor = cor
	_gerar()

func _gerar() -> void:
	_segs = PackedVector2Array()
	var n : int = 6
	var dir : Vector2 = _ate
	var perp : Vector2 = (dir.orthogonal().normalized() if dir.length() > 0.01 else Vector2.UP)
	for i in range(n + 1):
		var tt : float = float(i) / float(n)
		var base : Vector2 = Vector2.ZERO.lerp(_ate, tt)
		var jitter : float = 0.0
		if i != 0 and i != n:
			jitter = randf_range(-11.0, 11.0)
		_segs.append(base + perp * jitter)

func _process(delta: float) -> void:
	_t += delta
	if _t >= _dur:
		queue_free()
		return
	queue_redraw()

func _draw() -> void:
	if _segs.size() < 2:
		return
	var a : float = 1.0 - (_t / _dur)
	# Glow + núcleo + brilho branco
	draw_polyline(_segs, Color(_cor.r, _cor.g, _cor.b, 0.25 * a), 5.0)
	draw_polyline(_segs, Color(_cor.r, _cor.g, _cor.b, 0.85 * a), 2.5)
	draw_polyline(_segs, Color(1.0, 1.0, 1.0, 0.55 * a), 1.0)
