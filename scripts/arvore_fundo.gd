extends Control
## Fundo do mapa estelar: linhas de constelacao, estrelas e orbita suave.

var linhas: Array = [] # [Vector2_a, Vector2_b, Color, bool_ativo_a, bool_ativo_b] ou [Array[Vector2], Color, bool_ativo_a, bool_ativo_b]
var estrelas: Array = []
var pulse := 0.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_gerar_estrelas()


func _gerar_estrelas() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 99137
	estrelas.clear()
	for i in range(240):
		estrelas.append({
			"pos": Vector2(rng.randf_range(0.0, 1536.0), rng.randf_range(0.0, 864.0)),
			"r": rng.randf_range(0.6, 2.0),
			"phase": rng.randf_range(0.0, TAU),
			"alpha": rng.randf_range(0.08, 0.30),
		})


var _redraw_acc: float = 0.0
const REDRAW_INTERVAL: float = 0.05  # 20 fps

func _process(delta: float) -> void:
	pulse += delta * 1.15
	_redraw_acc += delta
	if _redraw_acc >= REDRAW_INTERVAL:
		_redraw_acc -= REDRAW_INTERVAL
		queue_redraw()


func _draw() -> void:
	var p: float = sin(pulse) * 0.25 + 0.75
	var vp: Vector2 = size
	var center: Vector2 = vp * 0.5
	draw_rect(Rect2(Vector2.ZERO, vp), Color(0.0, 0.0, 0.0, 1.0), true)
	for i in range(5):
		var rr: float = minf(vp.x, vp.y) * (0.20 + float(i) * 0.115)
		draw_arc(center, rr, -0.08, TAU - 0.08, 128, Color(0.20, 0.38, 0.95, 0.032), 1.0)

	for s in estrelas:
		var sd: Dictionary = s as Dictionary
		var sp: float = sin(pulse * 0.62 + (sd["phase"] as float)) * 0.35 + 0.65
		var pos: Vector2 = sd["pos"] as Vector2
		var draw_pos := Vector2(pos.x * vp.x / 1536.0, pos.y * vp.y / 864.0)
		draw_circle(draw_pos, sd["r"] as float, Color(0.55, 0.70, 1.0, (sd["alpha"] as float) * sp))

	for ln in linhas:
		var la: Array = ln as Array
		var pontos: Array = []
		var c: Color
		var aa: bool
		var ab: bool
		if la[0] is Array:
			pontos = la[0] as Array
			c = la[1] as Color
			aa = la[2] as bool
			ab = la[3] as bool
		else:
			pontos = [la[0] as Vector2, la[1] as Vector2]
			c = la[2] as Color
			aa = la[3] as bool
			ab = la[4] as bool
		if pontos.size() < 2:
			continue
		var pa: Vector2 = pontos[0] as Vector2
		var pb: Vector2 = pontos[pontos.size() - 1] as Vector2
		if aa and ab:
			for i in range(4, 0, -1):
				_draw_segmentos(pontos, Color(c.r, c.g, c.b, 0.065 * p / float(i)), float(i) * 4.0)
			_draw_segmentos(pontos, Color(c.r * 0.75 + 0.25, c.g * 0.75 + 0.18, c.b * 0.75 + 0.12, 0.92 * p), 2.2)
			_draw_estrelas_finais(pa, pb, c, p)
		elif aa:
			_draw_segmentos(pontos, Color(c.r * 0.70, c.g * 0.70, c.b * 0.70, 0.38), 1.8)
			draw_circle(pa, 3.3, Color(c.r, c.g, c.b, 0.58))
		else:
			_draw_segmentos(pontos, Color(0.24, 0.27, 0.36, 0.20), 1.4)


func _draw_segmentos(pontos: Array, cor: Color, largura: float) -> void:
	for i in range(pontos.size() - 1):
		draw_line(pontos[i] as Vector2, pontos[i + 1] as Vector2, cor, largura)


func _draw_estrelas_finais(pa: Vector2, pb: Vector2, cor: Color, p: float) -> void:
	for q in [pa, pb]:
		var pos: Vector2 = q as Vector2
		draw_circle(pos, 5.2, Color(cor.r, cor.g, cor.b, 0.42 * p))
		draw_circle(pos, 2.4, Color(1.0, 0.96, 0.82, 0.82 * p))
