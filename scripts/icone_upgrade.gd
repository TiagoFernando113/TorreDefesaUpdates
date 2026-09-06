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
		# Efeitos de carta (ícone único por efeito)
		"brasa":      _icone_brasa(mid, r, c, p)
		"chama":      _icone_chama(mid, r, c, p)
		"explosao":   _icone_explosao(mid, r, c, p)
		"fragmento":  _icone_fragmento(mid, r, c, p)
		"raio":       _icone_raio(mid, r, c, p)
		"tempestade": _icone_tempestade(mid, r, c, p)
		"corrente":   _icone_corrente(mid, r, c, p)
		"critico":    _icone_critico(mid, r, c, p)
		"veneno":     _icone_veneno(mid, r, c, p)
		"fissura":    _icone_fissura(mid, r, c, p)
		"gelo":       _icone_gelo(mid, r, c, p)
		"carga":      _icone_carga(mid, r, c, p)
		"rajada":     _icone_rajada(mid, r, c, p)
		"overdrive":  _icone_overdrive(mid, r, c, p)
		"armadura_i": _icone_armadura_i(mid, r, c, p)
		"bencao":     _icone_bencao(mid, r, c, p)
		"saque":      _icone_saque(mid, r, c, p)
		"recuperacao":_icone_recuperacao(mid, r, c, p)
		"cacador":    _icone_cacador(mid, r, c, p)
		# Armas (formato do tiro)
		"arma_padrao":       _arma_padrao(mid, r, c, p)
		"arma_ricochete":    _arma_ricochete(mid, r, c, p)
		"arma_escopeta":     _arma_escopeta(mid, r, c, p)
		"arma_sniper":       _arma_sniper(mid, r, c, p)
		"arma_metralhadora": _arma_metralhadora(mid, r, c, p)
		"arma_orbital":      _arma_orbital(mid, r, c, p)
		"arma_missil":       _arma_missil(mid, r, c, p)
		"arma_gemea":        _arma_gemea(mid, r, c, p)
		"arma_vortice":      _arma_vortice(mid, r, c, p)
		"arma_aniquilador":  _arma_aniquilador(mid, r, c, p)
		"arma_bombardeio":   _arma_bombardeio(mid, r, c, p)
		"arma_lanca_chamas": _arma_lanca_chamas(mid, r, c, p)


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


# ── Ícones de ARMA (formato do tiro) ─────────────────────────────────────────

func _arma_padrao(mid: Vector2, r: float, c: Color, p: float) -> void:
	# Canhão simples: 1 projétil viajando reto + cano
	draw_line(mid + Vector2(-r * 0.9, 0), mid + Vector2(r * 0.3, 0), Color(c.r, c.g, c.b, 0.5 * p), 3.0)
	var bx : float = mid.x - r * 0.3 + fmod(_p * 30.0, r * 1.4)
	draw_circle(Vector2(bx, mid.y), r * 0.22, Color(c.r, c.g, c.b, p))
	draw_circle(Vector2(bx, mid.y), r * 0.34, Color(c.r, c.g, c.b, 0.25 * p))


func _arma_ricochete(mid: Vector2, r: float, c: Color, p: float) -> void:
	# Trajetória em zigue-zague (quica) com bola na ponta
	var pts := PackedVector2Array([
		mid + Vector2(-r, r * 0.5), mid + Vector2(-r * 0.3, -r * 0.6),
		mid + Vector2(r * 0.3, r * 0.5), mid + Vector2(r, -r * 0.5),
	])
	draw_polyline(pts, Color(c.r, c.g, c.b, p), 2.6)
	var t : float = fmod(_p * 0.5, 1.0) * 3.0
	var seg : int = int(t)
	var f : float = t - float(seg)
	var bp : Vector2 = (pts[seg] as Vector2).lerp(pts[mini(seg + 1, 3)] as Vector2, f)
	draw_circle(bp, r * 0.20, Color(1.0, 1.0, 1.0, p))


func _arma_escopeta(mid: Vector2, r: float, c: Color, p: float) -> void:
	# Leque de 5 pelotas espalhando
	var origem := mid + Vector2(-r * 0.8, 0)
	for i in range(5):
		var ang : float = (float(i) - 2.0) * 0.32
		var fase : float = fmod(_p * 0.7 + float(i) * 0.1, 1.0)
		var pos : Vector2 = origem + Vector2(cos(ang), sin(ang)) * (r * 0.3 + fase * r * 1.4)
		draw_circle(pos, r * 0.13 * (1.0 - fase * 0.4), Color(c.r, c.g, c.b, (1.0 - fase) * p))
	draw_circle(origem, r * 0.18, Color(c.r, c.g, c.b, 0.6 * p))


func _arma_sniper(mid: Vector2, r: float, c: Color, p: float) -> void:
	# Mira (cruz + círculo) com linha longa
	draw_arc(mid, r * 0.7, 0.0, TAU, 40, Color(c.r, c.g, c.b, 0.8 * p), 2.2)
	draw_line(mid + Vector2(-r, 0), mid + Vector2(-r * 0.4, 0), Color(c.r, c.g, c.b, p), 2.0)
	draw_line(mid + Vector2(r * 0.4, 0), mid + Vector2(r, 0), Color(c.r, c.g, c.b, p), 2.0)
	draw_line(mid + Vector2(0, -r), mid + Vector2(0, -r * 0.4), Color(c.r, c.g, c.b, p), 2.0)
	draw_line(mid + Vector2(0, r * 0.4), mid + Vector2(0, r), Color(c.r, c.g, c.b, p), 2.0)
	draw_circle(mid, r * 0.12, Color(1.0, 1.0, 1.0, p))


func _arma_metralhadora(mid: Vector2, r: float, c: Color, p: float) -> void:
	# Sequência rápida de muitas balas
	for i in range(6):
		var fase : float = fmod(_p * 1.6 + float(i) * 0.16, 1.0)
		var x : float = mid.x - r + fase * r * 2.0
		draw_circle(Vector2(x, mid.y), r * 0.12, Color(c.r, c.g, c.b, sin(fase * PI) * p))
	draw_line(mid + Vector2(-r, 0), mid + Vector2(r, 0), Color(c.r, c.g, c.b, 0.15), 1.2)


func _arma_orbital(mid: Vector2, r: float, c: Color, p: float) -> void:
	# Núcleo + 3 orbes girando ao redor
	draw_arc(mid, r * 0.62, 0.0, TAU, 40, Color(c.r, c.g, c.b, 0.2 * p), 1.5)
	draw_circle(mid, r * 0.22, Color(c.r, c.g, c.b, p))
	for i in range(3):
		var a : float = _p * 0.9 + float(i) * TAU / 3.0
		var op : Vector2 = mid + Vector2(cos(a), sin(a)) * r * 0.62
		draw_circle(op, r * 0.15, Color(c.r, c.g, c.b, p))


func _arma_missil(mid: Vector2, r: float, c: Color, p: float) -> void:
	# Foguete (corpo + ponta + chama) subindo na diagonal
	var d : Vector2 = Vector2(0.7, -0.7)
	var body := mid - d * r * 0.2
	var tip := body + d * r * 0.7
	draw_line(body - d * r * 0.6, tip, Color(c.r, c.g, c.b, p), 4.0)
	# Ponta
	var perp := Vector2(-d.y, d.x)
	draw_line(tip, tip - d * r * 0.3 + perp * r * 0.2, Color(c.r, c.g, c.b, p), 2.5)
	draw_line(tip, tip - d * r * 0.3 - perp * r * 0.2, Color(c.r, c.g, c.b, p), 2.5)
	# Chama
	var ch : float = 0.5 + 0.5 * sin(_p * 4.0)
	draw_circle(body - d * r * (0.7 + ch * 0.3), r * 0.18 * ch, Color(1.0, 0.55, 0.1, p))


func _arma_gemea(mid: Vector2, r: float, c: Color, p: float) -> void:
	# Dois canos paralelos, cada um com sua bala
	for s in [-1.0, 1.0]:
		var y : float = mid.y + s * r * 0.35
		draw_line(Vector2(mid.x - r * 0.8, y), Vector2(mid.x + r * 0.2, y), Color(c.r, c.g, c.b, 0.5 * p), 2.5)
		var bx : float = mid.x - r * 0.2 + fmod(_p * 26.0 + (s + 1.0) * 8.0, r * 1.2)
		draw_circle(Vector2(bx, y), r * 0.16, Color(c.r, c.g, c.b, p))


func _arma_vortice(mid: Vector2, r: float, c: Color, p: float) -> void:
	# Raios saindo em todas as direções (360°), girando
	for i in range(10):
		var a : float = _p * 0.5 + float(i) * TAU / 10.0
		var p1 : Vector2 = mid + Vector2(cos(a), sin(a)) * r * 0.3
		var p2 : Vector2 = mid + Vector2(cos(a), sin(a)) * r
		draw_line(p1, p2, Color(c.r, c.g, c.b, p), 2.0)
		draw_circle(p2, r * 0.07, Color(c.r, c.g, c.b, 0.8 * p))
	draw_circle(mid, r * 0.18, Color(1.0, 1.0, 1.0, 0.5 * p))


func _arma_aniquilador(mid: Vector2, r: float, c: Color, p: float) -> void:
	# Feixe grosso horizontal atravessando, com brilho pulsante
	var glow : float = 0.6 + 0.4 * sin(_p * 3.0)
	draw_line(mid + Vector2(-r, 0), mid + Vector2(r, 0), Color(c.r, c.g, c.b, 0.25 * glow), 10.0)
	draw_line(mid + Vector2(-r, 0), mid + Vector2(r, 0), Color(c.r, c.g, c.b, 0.6 * glow), 5.0)
	draw_line(mid + Vector2(-r, 0), mid + Vector2(r, 0), Color(1.0, 1.0, 1.0, glow), 2.0)
	# Núcleo emissor
	draw_circle(mid + Vector2(-r, 0), r * 0.22, Color(1.0, 1.0, 1.0, glow))


func _arma_lanca_chamas(mid: Vector2, r: float, c: Color, p: float) -> void:
	# Cone de chamas saindo de um bocal à esquerda
	var origem := mid + Vector2(-r * 0.85, 0.0)
	for i in range(5):
		var f : float = (float(i) / 4.0) - 0.5            # -0.5..0.5
		var ang : float = f * 0.9
		var ph : float = fmod(_p * 0.9 + float(i) * 0.12, 1.0)
		var comp : float = r * (0.5 + ph * 1.3)
		var d : Vector2 = Vector2(cos(ang), sin(ang))
		draw_line(origem + d * r * 0.2, origem + d * comp, Color(1.0, 0.45, 0.08, (1.0 - ph) * p), 3.0)
		draw_circle(origem + d * comp, r * 0.14 * (1.0 - ph), Color(1.0, 0.78, 0.2, (1.0 - ph) * p))
	# Bocal
	draw_circle(origem, r * 0.16, Color(c.r, c.g, c.b, 0.7 * p))


func _arma_bombardeio(mid: Vector2, r: float, c: Color, p: float) -> void:
	# Feixe vertical descendo num alvo no chão (raio orbital manual)
	var queda : float = fmod(_p * 0.8, 1.0)
	var ytip  : float = -r + queda * r * 1.4
	draw_line(Vector2(mid.x, mid.y - r), Vector2(mid.x, mid.y + ytip), Color(c.r, c.g, c.b, 0.5 * p), 4.0)
	draw_line(Vector2(mid.x, mid.y - r), Vector2(mid.x, mid.y + ytip), Color(1.0, 1.0, 1.0, p), 1.5)
	# Alvo / cratera no chão
	draw_arc(Vector2(mid.x, mid.y + r * 0.5), r * 0.55, 0.0, TAU, 28, Color(c.r, c.g, c.b, 0.8 * p), 2.0)
	draw_arc(Vector2(mid.x, mid.y + r * 0.5), r * 0.28, 0.0, TAU, 20, Color(c.r, c.g, c.b, 0.5 * p), 1.5)
	draw_circle(Vector2(mid.x, mid.y + r * 0.5), r * 0.10, Color(1.0, 1.0, 1.0, p))


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


# ── Ícones de EFEITO de carta (um por efeito) ────────────────────────────────

func _icone_brasa(mid: Vector2, r: float, c: Color, p: float) -> void:
	# Chama em gota com núcleo brilhante
	var pts := PackedVector2Array([
		mid + Vector2(0.0, -r),          mid + Vector2(r * 0.55, r * 0.1),
		mid + Vector2(r * 0.30, r * 0.7), mid + Vector2(-r * 0.30, r * 0.7),
		mid + Vector2(-r * 0.55, r * 0.1),
	])
	var fill := PackedColorArray(); fill.resize(pts.size())
	fill.fill(Color(c.r, c.g * 0.65, c.b * 0.30, 0.55 * p))
	draw_polygon(pts, fill)
	draw_circle(mid + Vector2(0.0, r * 0.28), r * 0.30, Color(1.0, 0.92, 0.55, p))


func _icone_chama(mid: Vector2, r: float, c: Color, p: float) -> void:
	# Fogo contínuo: chama alta + faíscas subindo (permanente)
	var pts := PackedVector2Array([
		mid + Vector2(0.0, -r * 1.05), mid + Vector2(r * 0.5, r * 0.2), mid + Vector2(-r * 0.5, r * 0.2),
	])
	var fill := PackedColorArray(); fill.resize(pts.size())
	fill.fill(Color(c.r, c.g * 0.6, c.b * 0.2, 0.6 * p))
	draw_polygon(pts, fill)
	draw_circle(mid + Vector2(0.0, r * 0.40), r * 0.34, Color(c.r, c.g, c.b, 0.5 * p))
	for i in range(3):
		var ph := fmod(_p * 0.7 + float(i) * 0.33, 1.0)
		var sx := mid.x + (float(i) - 1.0) * r * 0.4
		draw_circle(Vector2(sx, mid.y - r * 0.4 - ph * r), r * 0.10 * (1.0 - ph),
				Color(1.0, 0.85, 0.4, (1.0 - ph) * p))


func _icone_explosao(mid: Vector2, r: float, c: Color, p: float) -> void:
	# Estouro: espinhos grossos radiais + miolo brilhante
	for i in range(12):
		var a    := float(i) * TAU / 12.0
		var comp : float = r * (1.0 if i % 2 == 0 else 0.6)
		draw_line(mid + Vector2(cos(a), sin(a)) * r * 0.3,
				mid + Vector2(cos(a), sin(a)) * comp, Color(c.r, c.g, c.b, 0.7 * p), 3.0)
	draw_circle(mid, r * 0.5,  Color(c.r, c.g, c.b, 0.2 * p))
	draw_circle(mid, r * 0.32, Color(1.0, 0.85, 0.4, p))


func _icone_fragmento(mid: Vector2, r: float, c: Color, p: float) -> void:
	# Estilhaços voando para fora de um ponto
	draw_circle(mid, r * 0.18, Color(1.0, 0.9, 0.5, p))
	for i in range(6):
		var a    := float(i) * TAU / 6.0 + _p * 0.2
		var d    := fmod(_p * 0.5 + float(i) * 0.15, 1.0)
		var dir  := Vector2(cos(a), sin(a))
		var pos  := mid + dir * (r * 0.3 + d * r * 0.7)
		var perp := Vector2(-dir.y, dir.x)
		var tri := PackedVector2Array([
			pos + dir * r * 0.18, pos - dir * r * 0.1 + perp * r * 0.1, pos - dir * r * 0.1 - perp * r * 0.1])
		var fill := PackedColorArray(); fill.resize(3); fill.fill(Color(c.r, c.g, c.b, (1.0 - d) * p))
		draw_polygon(tri, fill)


func _icone_raio(mid: Vector2, r: float, c: Color, p: float) -> void:
	# Relâmpago único em ziguezague
	var pts := PackedVector2Array([
		mid + Vector2(r * 0.15, -r),  mid + Vector2(-r * 0.25, -r * 0.1),
		mid + Vector2(r * 0.1, -r * 0.1), mid + Vector2(-r * 0.2, r),
	])
	draw_polyline(pts, Color(c.r, c.g, c.b, p), 3.0)
	draw_polyline(pts, Color(1.0, 1.0, 1.0, 0.5 * p), 1.2)


func _icone_tempestade(mid: Vector2, r: float, c: Color, p: float) -> void:
	# Nuvem + 3 raios piscando
	draw_circle(mid + Vector2(-r * 0.3, -r * 0.4), r * 0.32, Color(c.r, c.g, c.b, 0.4 * p))
	draw_circle(mid + Vector2(r * 0.3, -r * 0.4),  r * 0.32, Color(c.r, c.g, c.b, 0.4 * p))
	draw_circle(mid + Vector2(0.0, -r * 0.25),     r * 0.40, Color(c.r, c.g, c.b, 0.4 * p))
	for i in range(3):
		var bx := mid.x + (float(i) - 1.0) * r * 0.5
		var fl : float = 0.4 + 0.6 * absf(sin(_p * 3.0 + float(i)))
		draw_polyline(PackedVector2Array([
			Vector2(bx + r * 0.1, mid.y), Vector2(bx - r * 0.12, mid.y + r * 0.45),
			Vector2(bx + r * 0.05, mid.y + r * 0.45), Vector2(bx - r * 0.1, mid.y + r)]),
			Color(1.0, 1.0, 0.7, fl * p), 2.0)


func _icone_corrente(mid: Vector2, r: float, c: Color, p: float) -> void:
	# Raio saltando entre nós
	var nodes := [mid + Vector2(-r * 0.8, r * 0.5), mid + Vector2(0.0, -r * 0.55), mid + Vector2(r * 0.8, r * 0.4)]
	for i in range(nodes.size() - 1):
		var a : Vector2 = nodes[i]
		var b : Vector2 = nodes[i + 1]
		var mp : Vector2 = (a + b) * 0.5 + Vector2(0.0, -r * 0.2)
		draw_polyline(PackedVector2Array([a, mp, b]), Color(c.r, c.g, c.b, p), 2.2)
	for nd in nodes:
		draw_circle(nd, r * 0.15, Color(1.0, 1.0, 1.0, p))


func _icone_critico(mid: Vector2, r: float, c: Color, p: float) -> void:
	# Alvo com X + faísca pulsante (acerto crítico)
	draw_arc(mid, r * 0.7, 0.0, TAU, 32, Color(c.r, c.g, c.b, 0.5 * p), 2.0)
	draw_line(mid + Vector2(-r * 0.5, -r * 0.5), mid + Vector2(r * 0.5, r * 0.5), Color(c.r, c.g, c.b, p), 2.2)
	draw_line(mid + Vector2(-r * 0.5, r * 0.5), mid + Vector2(r * 0.5, -r * 0.5), Color(c.r, c.g, c.b, p), 2.2)
	var s : float = 0.6 + 0.4 * sin(_p * 4.0)
	draw_circle(mid, r * 0.22 * s, Color(1.0, 1.0, 0.85, p))


func _icone_veneno(mid: Vector2, r: float, c: Color, p: float) -> void:
	# Gota de veneno + bolhas subindo
	var pts := PackedVector2Array([
		mid + Vector2(0.0, -r * 0.9), mid + Vector2(r * 0.45, r * 0.2),
		mid + Vector2(0.0, r * 0.6),  mid + Vector2(-r * 0.45, r * 0.2),
	])
	var fill := PackedColorArray(); fill.resize(pts.size()); fill.fill(Color(c.r, c.g, c.b, 0.55 * p))
	draw_polygon(pts, fill)
	draw_circle(mid + Vector2(-r * 0.12, r * 0.05), r * 0.13, Color(1.0, 1.0, 1.0, 0.7 * p))
	for i in range(2):
		var ph := fmod(_p * 0.6 + float(i) * 0.5, 1.0)
		draw_circle(mid + Vector2(r * 0.5, r * 0.5 - ph * r), r * 0.08 * (1.0 - ph),
				Color(c.r, c.g, c.b, (1.0 - ph) * p))


func _icone_fissura(mid: Vector2, r: float, c: Color, p: float) -> void:
	# Rachaduras espalhando do centro
	for i in range(5):
		var a  := float(i) * TAU / 5.0 + 0.3
		var p2 := mid + Vector2(cos(a), sin(a)) * r * 0.6
		var p3 := p2 + Vector2(cos(a + 0.4), sin(a + 0.4)) * r * 0.4
		draw_polyline(PackedVector2Array([mid, p2, p3]), Color(c.r, c.g, c.b, p), 2.2)
	draw_circle(mid, r * 0.15, Color(c.r, c.g, c.b, 0.5 * p))


func _icone_gelo(mid: Vector2, r: float, c: Color, p: float) -> void:
	# Floco de neve de 6 braços
	for i in range(6):
		var a   := float(i) * TAU / 6.0 + _p * 0.1
		var dir := Vector2(cos(a), sin(a))
		draw_line(mid, mid + dir * r, Color(c.r, c.g, c.b, p), 2.0)
		var perp := Vector2(-dir.y, dir.x)
		var b    := mid + dir * r * 0.6
		draw_line(b, b + (perp - dir) * r * 0.2, Color(c.r, c.g, c.b, 0.8 * p), 1.5)
		draw_line(b, b + (-perp - dir) * r * 0.2, Color(c.r, c.g, c.b, 0.8 * p), 1.5)
	draw_circle(mid, r * 0.13, Color(1.0, 1.0, 1.0, 0.7 * p))


func _icone_carga(mid: Vector2, r: float, c: Color, p: float) -> void:
	# Anéis colapsando para um núcleo carregado
	for i in range(3):
		var ph   := fmod(_p * 0.7 + float(i) * 0.33, 1.0)
		var raio := r * (1.0 - ph)
		draw_arc(mid, raio, 0.0, TAU, 32, Color(c.r, c.g, c.b, ph * p), 2.0)
	var s : float = 0.6 + 0.4 * sin(_p * 5.0)
	draw_circle(mid, r * 0.30 * s, Color(1.0, 0.9, 0.7, p))


func _icone_rajada(mid: Vector2, r: float, c: Color, p: float) -> void:
	# Três balas saindo em leque (com rastro)
	var origem := mid + Vector2(-r * 0.7, 0.0)
	for ang in [-0.4, 0.0, 0.4]:
		var dir := Vector2(cos(ang), sin(ang))
		var ph  := fmod(_p * 0.8, 1.0)
		var pos := origem + dir * (r * 0.3 + ph * r * 1.5)
		draw_line(pos - dir * r * 0.3, pos, Color(c.r, c.g, c.b, 0.5 * p), 2.0)
		draw_circle(pos, r * 0.13, Color(c.r, c.g, c.b, p))
	draw_circle(origem, r * 0.16, Color(c.r, c.g, c.b, 0.6 * p))


func _icone_overdrive(mid: Vector2, r: float, c: Color, p: float) -> void:
	# Velocímetro: arco + marcas + ponteiro oscilando
	draw_arc(mid, r * 0.8, PI * 0.8, PI * 2.2, 32, Color(c.r, c.g, c.b, 0.6 * p), 2.5)
	for i in range(5):
		var a := lerpf(PI * 0.8, PI * 2.2, float(i) / 4.0)
		draw_line(mid + Vector2(cos(a), sin(a)) * r * 0.65, mid + Vector2(cos(a), sin(a)) * r * 0.8,
				Color(c.r, c.g, c.b, 0.5 * p), 1.5)
	var t  : float = 0.5 + 0.5 * sin(_p * 2.0)
	var na : float = lerpf(PI * 0.9, PI * 2.1, t)
	draw_line(mid, mid + Vector2(cos(na), sin(na)) * r * 0.7, Color(1.0, 0.85, 0.3, p), 2.5)
	draw_circle(mid, r * 0.12, Color(1.0, 1.0, 1.0, p))


func _icone_armadura_i(mid: Vector2, r: float, c: Color, p: float) -> void:
	# Escudo rachado (vulnerabilidade)
	var pts := PackedVector2Array([
		mid + Vector2(-r * 0.6, -r * 0.6), mid + Vector2(r * 0.6, -r * 0.6),
		mid + Vector2(r * 0.6, r * 0.1),   mid + Vector2(0.0, r * 0.75), mid + Vector2(-r * 0.6, r * 0.1),
	])
	var borda := PackedVector2Array(pts); borda.append(pts[0])
	draw_polyline(borda, Color(c.r, c.g, c.b, p), 2.5)
	draw_polyline(PackedVector2Array([
		mid + Vector2(0.0, -r * 0.5), mid + Vector2(r * 0.18, -r * 0.1),
		mid + Vector2(-r * 0.15, r * 0.1), mid + Vector2(r * 0.1, r * 0.55)]),
		Color(1.0, 0.45, 0.45, p), 2.2)


func _icone_bencao(mid: Vector2, r: float, c: Color, p: float) -> void:
	# Halo radiante (golpe abençoado)
	for i in range(8):
		var a := float(i) * TAU / 8.0 + _p * 0.2
		draw_line(mid + Vector2(cos(a), sin(a)) * r * 0.45, mid + Vector2(cos(a), sin(a)) * r,
				Color(c.r, c.g, c.b, (0.35 + 0.4 * sin(_p * 2.0 + float(i))) * p), 2.0)
	draw_circle(mid, r * 0.4,  Color(c.r, c.g, c.b, 0.3 * p))
	draw_circle(mid, r * 0.26, Color(1.0, 1.0, 0.85, p))


func _icone_saque(mid: Vector2, r: float, c: Color, p: float) -> void:
	# Pilha de moedas/lingotes (distinto do ouro losango)
	for i in range(3):
		var y    := mid.y + r * 0.55 - float(i) * r * 0.45
		var rect := Rect2(mid.x - r * 0.6, y - r * 0.16, r * 1.2, r * 0.32)
		draw_rect(rect, Color(c.r * 0.5, c.g * 0.4, 0.05, 0.9 * p))
		draw_rect(rect, Color(c.r, c.g, c.b, p), false, 2.0)
	draw_circle(Vector2(mid.x, mid.y - r * 0.35), r * 0.16, Color(1.0, 0.95, 0.6, p))


func _icone_recuperacao(mid: Vector2, r: float, c: Color, p: float) -> void:
	# Coração pulsante + cruzinhas subindo (cura sustentada)
	var s  : float = 0.9 + 0.1 * sin(_p * 3.0)
	var rr : float = r * 0.4 * s
	draw_circle(mid + Vector2(-rr * 0.6, -rr * 0.3), rr, Color(c.r, c.g, c.b, 0.85 * p))
	draw_circle(mid + Vector2(rr * 0.6, -rr * 0.3),  rr, Color(c.r, c.g, c.b, 0.85 * p))
	var tri := PackedVector2Array([
		mid + Vector2(-rr * 1.25, rr * 0.1), mid + Vector2(rr * 1.25, rr * 0.1), mid + Vector2(0.0, rr * 1.5)])
	var fill := PackedColorArray(); fill.resize(3); fill.fill(Color(c.r, c.g, c.b, 0.85 * p))
	draw_polygon(tri, fill)
	for i in range(2):
		var ph := fmod(_p * 0.6 + float(i) * 0.5, 1.0)
		var pp := mid + Vector2(r * 0.7, r * 0.3 - ph * r)
		var sz : float = r * 0.12 * (1.0 - ph)
		draw_line(pp + Vector2(-sz, 0.0), pp + Vector2(sz, 0.0), Color(1.0, 1.0, 1.0, (1.0 - ph) * p), 1.5)
		draw_line(pp + Vector2(0.0, -sz), pp + Vector2(0.0, sz), Color(1.0, 1.0, 1.0, (1.0 - ph) * p), 1.5)


func _icone_cacador(mid: Vector2, r: float, c: Color, p: float) -> void:
	# Fantasma com olhos (revela invisíveis)
	var ctr := mid + Vector2(0.0, -r * 0.05)
	var body := PackedVector2Array()
	for i in range(13):
		var a := PI + float(i) / 12.0 * PI   # semicírculo superior
		body.append(ctr + Vector2(cos(a), sin(a)) * r * 0.62)
	body.append(ctr + Vector2(r * 0.62, r * 0.55))
	body.append(ctr + Vector2(r * 0.31, r * 0.35))
	body.append(ctr + Vector2(0.0, r * 0.55))
	body.append(ctr + Vector2(-r * 0.31, r * 0.35))
	body.append(ctr + Vector2(-r * 0.62, r * 0.55))
	var fill := PackedColorArray(); fill.resize(body.size()); fill.fill(Color(c.r, c.g, c.b, 0.5 * p))
	draw_polygon(body, fill)
	draw_circle(ctr + Vector2(-r * 0.22, -r * 0.05), r * 0.11, Color(0.12, 0.05, 0.18, p))
	draw_circle(ctr + Vector2(r * 0.22, -r * 0.05),  r * 0.11, Color(0.12, 0.05, 0.18, p))
