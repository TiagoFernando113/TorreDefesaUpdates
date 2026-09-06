extends Node2D

var _t         : float = 0.0
var _fase      : int   = 0
var _alpha     : float = 0.0
var _progresso : float = 0.0
var _img       : Texture2D = null
var _particulas : Array = []
## Relogio que NAO zera na troca de fase, ao contrario do _t. O brilho pulsa
## com ele; com o _t, a pulsacao dava um salto toda vez que a fase virava.
var _relogio   : float = 0.0

const DUR_IN   : float = 0.4
const DUR_HOLD : float = 3.2
const DUR_OUT  : float = 1.0


func _ready() -> void:
	_img = load("res://scenes/logo_cyron.png")
	if OS.get_name() in ["Android", "iOS"]:
		Engine.max_fps = 30
	Som.tocar_intro_synth()

	# Captura toque para pular
	var vp   := get_viewport().get_visible_rect().size
	var skip := ColorRect.new()
	skip.color        = Color(0, 0, 0, 0)
	skip.position     = Vector2.ZERO
	skip.size         = vp
	skip.z_index      = 10
	skip.mouse_filter = Control.MOUSE_FILTER_STOP
	skip.gui_input.connect(func(e: InputEvent):
		if e is InputEventMouseButton and (e as InputEventMouseButton).pressed:
			_ir_menu())
	add_child(skip)


func _process(delta: float) -> void:
	_t += delta
	_relogio += delta
	match _fase:
		0:
			_alpha     = clampf(_t / DUR_IN, 0.0, 1.0)
			_progresso = clampf(_t / DUR_IN * 0.4, 0.0, 0.4)
			if _t >= DUR_IN:
				_fase = 1; _t = 0.0
		1:
			_alpha     = 1.0
			_progresso = clampf(0.4 + (_t / DUR_HOLD) * 0.6, 0.0, 1.0)
			if _t >= DUR_HOLD:
				_fase = 2; _t = 0.0
		2:
			_alpha     = clampf(1.0 - _t / DUR_OUT, 0.0, 1.0)
			_progresso = 1.0
			if _t >= DUR_OUT:
				_ir_menu(); return

	# Partículas na frente do mob
	if _progresso < 0.98 and randf() < 0.35:
		var g := _geometria()
		var mob_x : float = g.x0 + g.w * _progresso
		_particulas.append({
			"x": mob_x + randf_range(-6.0, 6.0),
			"y": g.y + g.h * 0.5 + randf_range(-8.0, 8.0),
			"vx": randf_range(8.0, 28.0),
			"vy": randf_range(-28.0, -8.0),
			"life": 1.0,
		})

	for p in _particulas:
		p["life"] -= delta * 2.0
		p["x"]    += (p["vx"] as float) * delta
		p["y"]    += (p["vy"] as float) * delta
	_particulas = _particulas.filter(func(p): return (p["life"] as float) > 0.0)

	queue_redraw()


## Onde a pista fica. UM dono para a medida.
##
## Estas contas estavam escritas duas vezes: uma no _draw e outra no _process,
## que solta as particulas na frente do mob. Ao mudar a barra de lugar eu
## atualizei so' uma delas, e as particulas passaram a nascer no ponto onde a
## barra ficava ANTES -- pontinhos soltos no vazio, do lado errado da tela.
## Aparecia na captura de tela e nao apareceria em teste nenhum.
##
## Medidas em FRACAO da tela, e nao em pixels: o jogo roda de celular estreito a
## monitor, e uma margem que respira num monitor engole a tela de um telefone.
## A pista para em 80% da largura de proposito -- o resto e' a area da torre.
func _geometria() -> Dictionary:
	var vp := get_viewport().get_visible_rect().size
	return {
		"x0": vp.x * 0.060,
		"w":  vp.x * 0.800,
		"y":  vp.y - vp.y * 0.108,
		"h":  maxf(16.0, vp.y * 0.030),
	}


func _draw() -> void:
	var vp    := get_viewport().get_visible_rect().size
	var W     : float = vp.x
	var H     : float = vp.y

	# ── Fundo preto ───────────────────────────────────────────────────────────
	draw_rect(Rect2(Vector2.ZERO, vp), Color(0.0, 0.0, 0.0, 1.0))

	# ── Logo tela cheia ──────────────────────────────────────────────────────
	if _img:
		draw_texture_rect(_img, Rect2(0.0, 0.0, W, H), false,
			Color(1.0, 1.0, 1.0, _alpha))

	# ── A pista ──────────────────────────────────────────────────────────────
	#
	# A barra e' uma PISTA de tower defense: o mob corre por ela ate a torre.
	# A ideia ja' estava aqui; o que faltava era desenha-la como o resto do
	# jogo. A logo acima e' toda brilho e profundidade, e a barra era uma tira
	# chapada de 14px com canto reto, colada na borda de baixo -- duas
	# linguagens visuais diferentes na mesma tela.
	#
	# O que mudou: canto arredondado, halo por tras (o "glow controlado" da
	# identidade do jogo), degrade continuo em vez de 24 tirinhas, marcas de
	# pista a cada 10%, e a barra subiu da borda para respirar.
	var g      := _geometria()
	var bar_h  : float = g.h
	var bar_y  : float = g.y
	var bar_x0 : float = g.x0
	var bar_w  : float = g.w
	var filled : float = bar_w * _progresso
	var pulso  : float = 0.5 + 0.5 * sin(_relogio * 3.2)

	# Halo: tres camadas abertas para fora. E' bloom de pobre, e e' o que casa
	# a barra com o brilho da logo sem custar shader nenhum.
	for gi in range(3, 0, -1):
		var camada : float = float(gi)
		_pista(bar_x0 - camada * 3.0, bar_y - camada * 3.0,
			bar_w + camada * 6.0, bar_h + camada * 6.0,
			Color(0.15, 0.65, 1.0, 0.05 * _alpha / camada))

	# Leito: quase preto, para o preenchido brilhar por contraste.
	_pista(bar_x0, bar_y, bar_w, bar_h, Color(0.02, 0.04, 0.09, 0.94 * _alpha))

	# Marcas de pista a cada 10%: sem elas a barra e' so' uma barra; com elas
	# se le' distancia, que e' o que faz a corrida do mob ter sentido.
	for mi in range(1, 10):
		var mx0 : float = bar_x0 + bar_w * float(mi) / 10.0
		draw_rect(Rect2(mx0 - 0.5, bar_y + bar_h * 0.30, 1.0, bar_h * 0.40),
			Color(0.35, 0.6, 0.9, 0.16 * _alpha))

	# Preenchido: degrade continuo, azul profundo -> ciano. Sao 48 fatias em vez
	# de 24 tirinhas com salto visivel entre elas.
	if filled > 1.0:
		var fatias : int = 48
		for fi in range(fatias):
			var t  : float = float(fi) / float(fatias - 1)
			var fx : float = bar_x0 + filled * float(fi) / float(fatias)
			var fw : float = filled / float(fatias) + 1.2
			draw_rect(Rect2(fx, bar_y + 1.5, fw, bar_h - 3.0),
				Color(lerp(0.01, 0.10, t), lerp(0.16, 0.72, t), lerp(0.42, 1.0, t),
					_alpha * 0.95))
		# Cabeca da energia: a ponta e' o ponto mais quente da barra.
		var hx : float = bar_x0 + filled
		draw_circle(Vector2(hx, bar_y + bar_h * 0.5), bar_h * (0.62 + 0.10 * pulso),
			Color(0.5, 0.95, 1.0, 0.16 * _alpha))
		draw_rect(Rect2(hx - 2.5, bar_y + 1.0, 3.0, bar_h - 2.0),
			Color(0.85, 1.0, 1.0, (0.55 + 0.35 * pulso) * _alpha))
		# Brilho no topo: da' volume, como se a pista fosse um tubo.
		draw_rect(Rect2(bar_x0 + 2.0, bar_y + 2.0, maxf(0.0, filled - 4.0), bar_h * 0.26),
			Color(1.0, 1.0, 1.0, 0.085 * _alpha))

	# Borda por ultimo, para fechar o desenho por cima do preenchido.
	_pista_borda(bar_x0, bar_y, bar_w, bar_h,
		Color(0.35, 0.78, 1.0, 0.55 * _alpha), 1.6)

	# ── Partículas ────────────────────────────────────────────────────────────
	for p in _particulas:
		var life : float = p["life"] as float
		draw_circle(Vector2(p["x"] as float, p["y"] as float),
			2.2 * life, Color(0.4, 0.75, 1.0, life * _alpha))

	# ── A torre, no fim da pista ──────────────────────────────────────────────
	# Era um hexagono de raio 14 que sumia contra a logo. Agora tem halo,
	# duas faces (topo claro / base escura, que e' o que da' volume sem
	# gradiente), canhao apontado para a esquerda e um nucleo que acende
	# conforme o mob se aproxima -- a torre esta CARREGANDO junto.
	var ty : float = bar_y + bar_h * 0.5
	var tx : float = bar_x0 + bar_w + W * 0.045
	var tr : float = maxf(16.0, H * 0.031)

	for gi in range(3, 0, -1):
		draw_circle(Vector2(tx, ty), tr + float(gi) * 5.0,
			Color(0.2, 0.7, 1.0, 0.06 * _alpha / float(gi)))

	var tpts := PackedVector2Array()
	for i in range(6):
		var a := float(i) * TAU / 6.0 + PI / 6.0
		tpts.append(Vector2(tx + cos(a) * tr, ty + sin(a) * tr))
	draw_polygon(tpts, _fill(tpts.size(), Color(0.03, 0.14, 0.34, _alpha)))
	# Meia-face de cima mais clara: volume sem custar gradiente.
	var topo := PackedVector2Array([tpts[4], tpts[5], tpts[0], tpts[1]])
	draw_polygon(topo, _fill(topo.size(), Color(0.07, 0.26, 0.55, _alpha * 0.9)))
	var tborda := PackedVector2Array(tpts); tborda.append(tpts[0])
	draw_polyline(tborda, Color(0.45, 0.85, 1.0, _alpha), 2.2)

	# Nucleo: acende conforme a pista enche.
	draw_circle(Vector2(tx, ty), tr * (0.26 + 0.10 * pulso),
		Color(0.6, 0.95, 1.0, (0.35 + 0.55 * _progresso) * _alpha))

	# Canhao apontado para a esquerda, de onde o mob vem.
	var ctip := Vector2(tx - tr * 1.55, ty)
	draw_line(Vector2(tx - tr * 0.55, ty), ctip,
		Color(0.10, 0.32, 0.62, _alpha), tr * 0.42)
	draw_line(Vector2(tx - tr * 0.55, ty), ctip,
		Color(0.50, 0.88, 1.0, _alpha), tr * 0.20)
	draw_circle(ctip, tr * 0.20, Color(0.85, 1.0, 1.0, (0.5 + 0.5 * pulso) * _alpha))

	# ── O mob, correndo pela pista ────────────────────────────────────────────
	# Era um circulo vermelho com dois pontinhos brancos -- lia como emoji, nao
	# como ameaca. Agora tem rastro, silhueta espinhada e olho aceso.
	if _progresso < 0.98:
		var mx : float = bar_x0 + bar_w * _progresso
		var mr : float = maxf(10.0, H * 0.019)

		# Rastro: cinco marcas que somem para tras. E' o que da' VELOCIDADE.
		for ri in range(5, 0, -1):
			var rt : float = float(ri) / 5.0
			draw_circle(Vector2(mx - rt * 34.0, ty), mr * (1.0 - rt * 0.55),
				Color(1.0, 0.35, 0.15, 0.13 * (1.0 - rt) * _alpha))

		for gi in range(3, 0, -1):
			draw_circle(Vector2(mx, ty), mr + float(gi) * 4.0,
				Color(1.0, 0.25, 0.1, 0.07 * _alpha / float(gi)))

		# Silhueta espinhada: oito pontas alternando raio.
		var mpts := PackedVector2Array()
		for i in range(16):
			var a  : float = float(i) * TAU / 16.0 + _relogio * 1.1
			var rr : float = mr * (1.0 if i % 2 == 0 else 0.66)
			mpts.append(Vector2(mx + cos(a) * rr, ty + sin(a) * rr))
		draw_polygon(mpts, _fill(mpts.size(), Color(0.62, 0.06, 0.06, 0.95 * _alpha)))
		var mborda := PackedVector2Array(mpts); mborda.append(mpts[0])
		draw_polyline(mborda, Color(1.0, 0.45, 0.25, _alpha), 1.6)

		# Um olho so', aceso: le' melhor em 13px do que dois pontinhos.
		draw_circle(Vector2(mx, ty), mr * 0.34,
			Color(1.0, 0.85, 0.4, (0.7 + 0.3 * pulso) * _alpha))

	# ── Percentual ────────────────────────────────────────────────────────────
	# Era 16px na fonte de sistema, cinza-azulado, perdido embaixo da barra.
	var font : Font = ThemeDB.fallback_font
	if font:
		var pct : String = "%d%%" % int(_progresso * 100.0)
		var fsz : int    = 26
		var tw  : float  = font.get_string_size(pct, HORIZONTAL_ALIGNMENT_LEFT, -1, fsz).x
		var px  : float  = bar_x0 + bar_w * 0.5 - tw * 0.5
		var py  : float  = bar_y + bar_h + 34.0
		# Sombra antes do texto: sem ela o numero some sobre o brilho da logo.
		draw_string(font, Vector2(px + 1.5, py + 1.5), pct,
			HORIZONTAL_ALIGNMENT_LEFT, -1, fsz, Color(0.0, 0.0, 0.0, 0.55 * _alpha))
		draw_string(font, Vector2(px, py), pct,
			HORIZONTAL_ALIGNMENT_LEFT, -1, fsz, Color(0.72, 0.94, 1.0, _alpha))


## Retangulo de canto redondo, feito de um retangulo e dois circulos nas pontas.
##
## O Godot nao tem draw_rect arredondado, e canto reto era metade do que fazia a
## barra parecer de outro jogo: a logo inteira e' curva e brilho, e a barra
## terminava em quina. Dois circulos resolvem, e custam duas chamadas.
func _pista(x: float, y: float, w: float, h: float, cor: Color) -> void:
	var r : float = h * 0.5
	if w <= h:
		draw_circle(Vector2(x + w * 0.5, y + r), maxf(w, h) * 0.5, cor)
		return
	draw_rect(Rect2(x + r, y, w - h, h), cor)
	draw_circle(Vector2(x + r, y + r), r, cor)
	draw_circle(Vector2(x + w - r, y + r), r, cor)


## O contorno da mesma forma. Arco nas pontas, reta em cima e embaixo -- se
## fosse um circulo inteiro, a linha cortaria o meio da barra.
func _pista_borda(x: float, y: float, w: float, h: float, cor: Color, grossura: float) -> void:
	var r : float = h * 0.5
	if w <= h:
		return
	draw_line(Vector2(x + r, y), Vector2(x + w - r, y), cor, grossura)
	draw_line(Vector2(x + r, y + h), Vector2(x + w - r, y + h), cor, grossura)
	draw_arc(Vector2(x + r, y + r), r, PI * 0.5, PI * 1.5, 14, cor, grossura)
	draw_arc(Vector2(x + w - r, y + r), r, -PI * 0.5, PI * 0.5, 14, cor, grossura)


func _fill(n: int, c: Color) -> PackedColorArray:
	var a := PackedColorArray()
	for i in range(n): a.append(c)
	return a


func _ir_menu() -> void:
	if _fase == 3:
		return
	_fase = 3
	get_tree().change_scene_to_file("res://scenes/Menu.tscn")
