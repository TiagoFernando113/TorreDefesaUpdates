extends Control
## Ícone geométrico animado para cada tipo de upgrade.

var tipo : String = ""
var cor  : Color  = Color.WHITE
var _p   := 0.0   # pulse


func _process(delta: float) -> void:
	_p += delta * 2.4
	queue_redraw()


func _draw() -> void:
	var p   : float   = sin(_p) * 0.22 + 0.78
	var mid : Vector2 = size / 2.0
	var r   : float   = min(size.x, size.y) * 0.36
	var c   : Color   = cor

	match tipo:
		"dano":       _icone_dano(mid, r, c, p)
		"alcance":    _icone_alcance(mid, r, c, p)
		"cadencia":   _icone_cadencia(mid, r, c, p)
		"vida":       _icone_vida(mid, r, c, p)
		"perfurante": _icone_perfurante(mid, r, c, p)
		"multitiro":  _icone_multitiro(mid, r, c, p)
		"velocidade": _icone_velocidade(mid, r, c, p)
		"regeneracao":_icone_regeneracao(mid, r, c, p)
		"escudo":     _icone_escudo(mid, r, c, p)
		"ouro":       _icone_ouro(mid, r, c, p)


# ── Ícones ────────────────────────────────────────────────────────────────────

func _icone_dano(mid: Vector2, r: float, c: Color, p: float) -> void:
	# Estrela de 8 pontas (explosão)
	for i in range(8):
		var a  := float(i) * TAU / 8.0 + _p * 0.15
		var p1 := mid + Vector2(cos(a), sin(a)) * r
		var p2 := mid + Vector2(cos(a + TAU/16.0), sin(a + TAU/16.0)) * r * 0.45
		draw_line(mid, p1, Color(c.r, c.g, c.b, 0.6 * p), 2.0)
		draw_line(mid, p2, Color(c.r, c.g, c.b, 0.3 * p), 1.5)
	draw_circle(mid, r * 0.22, Color(c.r, c.g, c.b, p))
	draw_circle(mid, r * 0.35, Color(c.r, c.g, c.b, 0.18 * p))


func _icone_alcance(mid: Vector2, r: float, c: Color, p: float) -> void:
	# Anéis concêntricos expandindo
	for i in range(3):
		var fase := fmod(_p * 0.6 + float(i) * 0.6, 1.0)
		var raio := r * 0.25 + fase * r * 0.85
		var alfa := (1.0 - fase) * 0.8 * p
		draw_arc(mid, raio, 0.0, TAU, 48, Color(c.r, c.g, c.b, alfa), 2.0)
	draw_circle(mid, r * 0.18, Color(c.r, c.g, c.b, p))


func _icone_cadencia(mid: Vector2, r: float, c: Color, p: float) -> void:
	# Três projéteis em sequência
	for i in range(3):
		var fase  := fmod(_p * 0.8 + float(i) * 0.33, 1.0)
		var x     := mid.x - r + fase * r * 2.0
		var alfa  := sin(fase * PI) * p
		draw_circle(Vector2(x, mid.y), r * 0.18, Color(c.r, c.g, c.b, alfa))
	# Linha de trajetória
	draw_line(Vector2(mid.x - r, mid.y), Vector2(mid.x + r, mid.y),
			Color(c.r, c.g, c.b, 0.2), 1.5)


func _icone_vida(mid: Vector2, r: float, c: Color, p: float) -> void:
	# Cruz + pulsação
	var pw := r * 0.28
	var ph := r * 0.8
	draw_rect(Rect2(mid.x - pw, mid.y - ph, pw * 2.0, ph * 2.0),
			Color(c.r, c.g, c.b, 0.75 * p))
	draw_rect(Rect2(mid.x - ph, mid.y - pw, ph * 2.0, pw * 2.0),
			Color(c.r, c.g, c.b, 0.75 * p))
	draw_circle(mid, r * 0.22, Color(1.0, 1.0, 1.0, 0.4 * p))


func _icone_perfurante(mid: Vector2, r: float, c: Color, p: float) -> void:
	# Seta horizontal + 2 círculos que ela atravessa
	for i in range(2):
		var x := mid.x - r * 0.3 + float(i) * r * 0.6
		draw_arc(Vector2(x, mid.y), r * 0.28, 0.0, TAU, 32,
				Color(c.r, c.g, c.b, 0.55 * p), 2.0)
	# Seta
	var tip   := Vector2(mid.x + r, mid.y)
	var tail  := Vector2(mid.x - r, mid.y)
	draw_line(tail, tip, Color(c.r, c.g, c.b, p), 2.5)
	var pts := PackedVector2Array([
		tip,
		tip + Vector2(-r * 0.3,  r * 0.22),
		tip + Vector2(-r * 0.3, -r * 0.22),
	])
	var fill := PackedColorArray()
	fill.resize(pts.size())
	fill.fill(Color(c.r, c.g, c.b, p))
	draw_polygon(pts, fill)


func _icone_multitiro(mid: Vector2, r: float, c: Color, p: float) -> void:
	# Três setas em leque
	var angulos := [-0.45, 0.0, 0.45]
	for ang in angulos:
		var dir := Vector2(cos(ang), sin(ang)) * r
		draw_line(mid - dir * 0.3, mid + dir, Color(c.r, c.g, c.b, p), 2.2)
	draw_circle(mid, r * 0.16, Color(c.r, c.g, c.b, p))


func _icone_velocidade(mid: Vector2, r: float, c: Color, p: float) -> void:
	# Rastro de velocidade (linhas horizontais escalonadas)
	var offset := fmod(_p * 40.0, r * 2.0) - r
	for i in range(3):
		var y    := mid.y + (float(i) - 1.0) * r * 0.4
		var larg : float = r * ([1.0, 0.65, 0.4][i] as float)
		var xa   : float = mid.x - larg + offset * ([0.6, 0.8, 1.0][i] as float)
		draw_line(Vector2(xa, y), Vector2(xa + larg, y),
				Color(c.r, c.g, c.b, p * ([0.9, 0.6, 0.4][i] as float)), 2.2)
	# Ponta da bala
	draw_circle(Vector2(mid.x + r * 0.7, mid.y), r * 0.18, Color(1.0, 1.0, 0.8, p))


func _icone_regeneracao(mid: Vector2, r: float, c: Color, p: float) -> void:
	# Arco circular girando (ícone de recarga)
	var a0 := _p * 1.2
	draw_arc(mid, r * 0.72, a0, a0 + TAU * 0.75, 48,
			Color(c.r, c.g, c.b, p), 3.0)
	# Pontinha da seta
	var tip  := mid + Vector2(cos(a0 + TAU * 0.75), sin(a0 + TAU * 0.75)) * r * 0.72
	var perp := Vector2(-sin(a0 + TAU * 0.75), cos(a0 + TAU * 0.75))
	draw_line(tip, tip - perp * r * 0.25 + Vector2(cos(a0 + TAU * 0.75), sin(a0 + TAU * 0.75)) * r * 0.22,
			Color(c.r, c.g, c.b, p), 2.5)
	draw_circle(mid, r * 0.15, Color(c.r, c.g, c.b, 0.5 * p))


func _icone_escudo(mid: Vector2, r: float, c: Color, p: float) -> void:
	# Escudo clássico (pentágono com ponta baixo) + cruz interna
	var pts := PackedVector2Array([
		mid + Vector2(-r * 0.70, -r * 0.60),
		mid + Vector2( r * 0.70, -r * 0.60),
		mid + Vector2( r * 0.70,  r * 0.15),
		mid + Vector2( 0.0,       r * 0.82),
		mid + Vector2(-r * 0.70,  r * 0.15),
	])
	var fill := PackedColorArray()
	fill.resize(pts.size())
	fill.fill(Color(c.r * 0.15, c.g * 0.15, c.b * 0.18, 0.80 * p))
	draw_polygon(pts, fill)
	var borda := PackedVector2Array(pts)
	borda.append(pts[0])
	draw_polyline(borda, Color(c.r, c.g, c.b, p), 2.8)
	# Cruz interna (símbolo de proteção)
	var cx  := mid + Vector2(0.0, -r * 0.10)
	var pw2 := r * 0.11
	var ph2 := r * 0.38
	draw_rect(Rect2(cx.x - pw2, cx.y - ph2, pw2 * 2.0, ph2 * 2.0),
			Color(c.r, c.g, c.b, 0.65 * p))
	draw_rect(Rect2(cx.x - ph2, cx.y - pw2, ph2 * 2.0, pw2 * 2.0),
			Color(c.r, c.g, c.b, 0.65 * p))
	# Brilho de pulso
	draw_circle(cx, r * 0.14, Color(1.0, 1.0, 1.0, 0.28 * p))


func _icone_ouro(mid: Vector2, r: float, c: Color, p: float) -> void:
	# Losango girando com cintilações (moeda/ouro)
	var rot := _p * 0.32
	var pts := PackedVector2Array()
	for i in range(4):
		var a  := float(i) * TAU / 4.0 + rot + PI / 4.0
		var rr := r * (0.88 if i % 2 == 0 else 0.52)
		pts.append(mid + Vector2(cos(a), sin(a)) * rr)
	var fill := PackedColorArray()
	fill.resize(pts.size())
	fill.fill(Color(c.r * 0.28, c.g * 0.22, 0.0, 0.88 * p))
	draw_polygon(pts, fill)
	var borda := PackedVector2Array(pts)
	borda.append(pts[0])
	draw_polyline(borda, Color(c.r, c.g, c.b, p), 2.8)
	# Brilho central
	draw_circle(mid, r * 0.20, Color(1.0, 0.96, 0.55, 0.70 * p))
	# 4 cintilações orbitando
	for i in range(4):
		var sa := _p * 1.6 + float(i) * TAU / 4.0
		var sp := mid + Vector2(cos(sa), sin(sa)) * r * 0.50
		draw_circle(sp, r * 0.07, Color(1.0, 1.0, 0.60, 0.60 * p))
