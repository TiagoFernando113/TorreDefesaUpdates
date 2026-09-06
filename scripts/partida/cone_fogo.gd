extends Node2D
## Efeito ISOLADO: cone de fogo do Lança-Chamas (línguas de chama em leque).
## Re-spawnado a cada tiro (cadência alta) → parece jato contínuo. Carga com
## guarda; se falhar, o dano/queimadura ainda é aplicado pela torre.

var _ang      : float = 0.0
var _alc      : float = 200.0
var _meia_ang : float = 0.5
var _t        : float = 0.0
var _dur      : float = 0.13

func iniciar(de: Vector2, ang: float, alcance: float, meia_ang: float) -> void:
	global_position = de
	_ang = ang
	_alc = alcance
	_meia_ang = meia_ang

func _process(delta: float) -> void:
	_t += delta
	queue_redraw()
	if _t >= _dur:
		queue_free()

func _draw() -> void:
	var a : float = 1.0 - (_t / _dur)
	var n : int = 9
	for i in range(n):
		var f : float = (float(i) / float(n - 1)) - 0.5   # -0.5..0.5
		var ang : float = _ang + f * 2.0 * _meia_ang
		var comp : float = _alc * (0.7 + randf() * 0.35)
		var d : Vector2 = Vector2(cos(ang), sin(ang))
		# Língua de chama: base larga laranja → ponta amarela
		draw_line(d * (_alc * 0.18), d * comp, Color(1.0, 0.42, 0.06, 0.42 * a), 7.0)
		draw_circle(d * comp, 9.0 * a + 2.0, Color(1.0, 0.30, 0.04, 0.40 * a))
		draw_circle(d * (comp * 0.62), 6.0, Color(1.0, 0.72, 0.18, 0.55 * a))
	# Brilho na boca do cano
	draw_circle(Vector2.ZERO, 15.0, Color(1.0, 0.8, 0.3, 0.30 * a))
