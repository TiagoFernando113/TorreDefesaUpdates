extends Control
## Nó visual individual da árvore de talentos — círculo com ícone desenhado

var id    := ""
var cor   := Color.WHITE
var ativo := false
var pode  := false
var pulse := 0.0

signal hover_in(id: String)
signal hover_out
signal pressionado(id: String)


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_PASS
	mouse_entered.connect(func(): hover_in.emit(id))
	mouse_exited.connect(func(): hover_out.emit())


var _redraw_acc: float = 0.0
const REDRAW_INTERVAL: float = 0.05  # 20 fps

func _process(delta: float) -> void:
	pulse += delta * 2.2
	_redraw_acc += delta
	if _redraw_acc >= REDRAW_INTERVAL:
		_redraw_acc -= REDRAW_INTERVAL
		queue_redraw()


func _gui_input(event: InputEvent) -> void:
	var pressed := false
	if event is InputEventMouseButton:
		var mb : InputEventMouseButton = event as InputEventMouseButton
		pressed = mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT
		if mb.button_index == MOUSE_BUTTON_LEFT:
			if mb.pressed:
				hover_in.emit(id)
			else:
				hover_out.emit()
	elif event is InputEventScreenTouch:
		var touch := event as InputEventScreenTouch
		pressed = touch.pressed
		if touch.pressed:
			hover_in.emit(id)
		else:
			hover_out.emit()
	elif event is InputEventScreenDrag:
		hover_in.emit(id)
	if pressed and not ativo and pode:
		pressionado.emit(id)
		accept_event()


func _draw() -> void:
	var p   : float   = sin(pulse) * 0.25 + 0.75
	var cx  : Vector2 = size * 0.5
	var r   : float   = min(size.x, size.y) * 0.5 - 2.0

	# ── Glow externo ──────────────────────────────────────────────────────
	if ativo:
		for i in range(7, 0, -1):
			draw_circle(cx, r + float(i) * 5.0,
					Color(cor.r, cor.g, cor.b, 0.058 * p / float(i)))
	elif pode:
		for i in range(4, 0, -1):
			draw_circle(cx, r + float(i) * 3.5,
					Color(cor.r, cor.g, cor.b, 0.024 / float(i)))

	# ── Moldura metálica estilo Tibia (bronze/dourado em camadas) ─────────
	# O multiplicador de brilho separa nós ativos/disponíveis dos bloqueados
	var brt : float = 1.0 if (ativo or pode) else 0.45

	# Borda externa: realce dourado (simula rim brilhante)
	var rim := Color(
			(0.60 + cor.r * 0.30) * brt,
			(0.42 + cor.g * 0.16) * brt,
			(0.10 + cor.b * 0.04) * brt, 0.96)
	if not ativo and not pode:
		rim = Color(0.30 * brt, 0.22 * brt, 0.10 * brt, 0.92)

	# Corpo do anel: bronze médio-escuro
	var mid := Color(rim.r * 0.50 + 0.04, rim.g * 0.48 + 0.02,
			rim.b * 0.36 + 0.01, 0.97)

	draw_circle(cx, r,        rim)   # rim dourado externo
	draw_circle(cx, r - 2.8,  mid)   # corpo bronze
	# Reflexo especular sutil (parte superior — dá sensação de curvatura 3D)
	draw_arc(cx, r - 1.8, -2.20, -0.94, 12,
			Color(1.0, 0.92, 0.70, 0.28 * brt), 1.5)
	# Interior escuro profundo
	draw_circle(cx, r - 5.8, Color(0.05, 0.04, 0.09, 0.98))
	# Segundo anel fino colorido (acento interno — "joia" da classe)
	var acc_a : float = 0.90 * p if ativo else (0.40 if pode else 0.13)
	draw_arc(cx, r - 6.4, 0.0, TAU, 48,
			Color(cor.r, cor.g, cor.b, acc_a), 1.8)

	# ── Ícone ──────────────────────────────────────────────────────────────
	var ir   : float = (r - 7.0) * 0.84
	var ic_c : Color
	var fl_c : Color
	if ativo:
		ic_c = Color(minf(cor.r + 0.14, 1.0), minf(cor.g + 0.08, 1.0), cor.b, 1.0)
		fl_c = Color(cor.r * 0.46, cor.g * 0.46, cor.b * 0.46, 0.80)
	elif pode:
		ic_c = Color(cor.r * 0.78, cor.g * 0.78, cor.b * 0.78, 0.92)
		fl_c = Color(cor.r * 0.26, cor.g * 0.26, cor.b * 0.26, 0.55)
	else:
		ic_c = Color(cor.r * 0.28, cor.g * 0.28, cor.b * 0.28, 0.50)
		fl_c = Color(0.06, 0.05, 0.09, 0.42)

	_draw_icon(cx, ir, ic_c, fl_c, p)

	# ── Indicador: check verde (ativo) ou cadeado (bloqueado) ─────────────
	if ativo:
		var bp : Vector2 = cx + Vector2(r * 0.60, r * 0.60)
		draw_circle(bp, 7.0,  mid)
		draw_circle(bp, 5.5,  Color(0.12, 0.88, 0.35, 0.96))
		draw_arc(bp, 5.5, 0.0, TAU, 12, Color(1.0, 1.0, 1.0, 0.40), 1.0)
	elif not pode and id != "raiz":
		# Cadeado no canto inferior direito
		var lk  := Color(ic_c.r, ic_c.g, ic_c.b, 0.50)
		var lkc : Vector2 = cx + Vector2(r * 0.58, r * 0.58)
		var lbw : float = r * 0.22   # meia-largura do corpo
		var lbh : float = r * 0.22   # altura do corpo
		var lar : float = r * 0.16   # raio do gancho
		# Corpo do cadeado (retângulo)
		draw_rect(Rect2(lkc.x - lbw, lkc.y, lbw * 2.0, lbh), lk, true)
		draw_rect(Rect2(lkc.x - lbw, lkc.y, lbw * 2.0, lbh), lk, false, 1.5)
		# Gancho em U acima do corpo (arco de 0 a PI = semicírculo SUPERIOR)
		draw_arc(lkc + Vector2(0, 0), lar, PI, TAU, 10, lk, 2.0)
		# Pino central do buraco da fechadura
		draw_circle(lkc + Vector2(0, lbh * 0.45), r * 0.07, lk)


# ── Ícones por talento ────────────────────────────────────────────────────────

func _draw_icon(cx: Vector2, r: float, ic: Color, fl: Color, p: float) -> void:
	match id:
		"raiz":  _icon_hex(cx, r, ic, fl)
		# ── Ramo P — Poder ────────────────────────────────────────────────────
		"p1":    _icon_chama(cx, r, ic, fl, p)
		"p2":    _icon_raio(cx, r, ic, fl)
		"p3":    _icon_duplo(cx, r, ic, fl)
		"p4":    _icon_arsenal(cx, r, ic, fl)
		"p5":    _icon_canhao(cx, r, ic, fl, p)
		# ── Ramo R — Resiliência ──────────────────────────────────────────────
		"r1":    _icon_escudo(cx, r, ic, fl)
		"r2":    _icon_coracao(cx, r, ic, fl, p)
		"r3":    _icon_fenix(cx, r, ic, fl, p)
		"r4":    _icon_muralha(cx, r, ic, fl)
		"token": _icon_token(cx, r, ic, fl, p)
		"r5":    _icon_imortal(cx, r, ic, fl, p)
		# ── Ramo F — Fortuna ──────────────────────────────────────────────────
		"f1":    _icon_moeda(cx, r, ic, fl, p)
		"f2":    _icon_gema(cx, r, ic, fl)
		"f3":    _icon_estrela(cx, r, ic, fl, p)
		"f4":    _icon_mercador(cx, r, ic, fl, p)
		"f5":    _icon_banco(cx, r, ic, fl, p)
		# ── Ramo E — Energia ──────────────────────────────────────────────────
		"e1":    _icon_condutor(cx, r, ic, fl)
		"e2":    _icon_sobrecarga(cx, r, ic, fl, p)
		"e3":    _icon_tempestade(cx, r, ic, fl, p)
		"e4":    _icon_olho(cx, r, ic, fl, p)
		"e5":    _icon_furia_elet(cx, r, ic, fl, p)
		# ── Ramo S — Sombra ───────────────────────────────────────────────────
		"s1":    _icon_sombra(cx, r, ic, fl, p)
		"s2":    _icon_corrosao(cx, r, ic, fl, p)
		"s3":    _icon_praga(cx, r, ic, fl, p)
		"s4":    _icon_eterno(cx, r, ic, fl, p)
		"s5":    _icon_metamorf(cx, r, ic, fl, p)
		# ── Ramo M — Maestria ─────────────────────────────────────────────────
		"m1":    _icon_leque(cx, r, ic, fl)
		"m2":    _icon_frasco(cx, r, ic, fl, p)
		"m3":    _icon_saco(cx, r, ic, fl)
		"m4":    _icon_dupla_carta(cx, r, ic, fl)
		# ── Ramo G — Glacial ──────────────────────────────────────────────────
		"g1":    _icon_floco(cx, r, ic, fl)
		"g2":    _icon_tundra(cx, r, ic, fl, p)
		"g3":    _icon_avalanche(cx, r, ic, fl)
		"g4":    _icon_criotrance(cx, r, ic, fl, p)
		# ── Ramo B — Berserker ────────────────────────────────────────────────
		"b1":    _icon_sangue(cx, r, ic, fl, p)
		"b2":    _icon_trance(cx, r, ic, fl, p)
		"b3":    _icon_pillagem(cx, r, ic, fl)
		"b4":    _icon_explosao(cx, r, ic, fl, p)
		# ── Ramo T — Temporal ─────────────────────────────────────────────────
		"t1":    _icon_ampulheta(cx, r, ic, fl, p)
		"t2":    _icon_pulso(cx, r, ic, fl, p)
		"t3":    _icon_coroa(cx, r, ic, fl)
		"t4":    _icon_relogio(cx, r, ic, fl, p)
		# ── Ramo X — Caos ────────────────────────────────────────────────────
		"x1":    _icon_dado(cx, r, ic, fl)
		"x2":    _icon_bencao(cx, r, ic, fl, p)
		"x3":    _icon_reroll(cx, r, ic, fl, p)
		"x4":    _icon_carta_caos(cx, r, ic, fl, p)
		# ── Fusões ────────────────────────────────────────────────────────────
		"colosso":  _icon_colosso(cx, r, ic, fl, p)
		"predador": _icon_predador(cx, r, ic, fl)
		"alquim":   _icon_alquim(cx, r, ic, fl, p)
		"tita":     _icon_tita(cx, r, ic, fl)
		"relamp":   _icon_relamp(cx, r, ic, fl, p)
		"canhao_g": _icon_canhao_g(cx, r, ic, fl)
		# ── Especiais ─────────────────────────────────────────────────────────
		"cazador":  _icon_cazador(cx, r, ic, fl)
		"exter":    _icon_exter(cx, r, ic, fl, p)
		"anti_t":   _icon_anti_t(cx, r, ic, fl)
		"purif":    _icon_purif(cx, r, ic, fl, p)
		# ── Legado ───────────────────────────────────────────────────────────
		"veteran":  _icon_veteran(cx, r, ic, fl, p)
		"genoci":   _icon_genoci(cx, r, ic, fl)
		"sobrev":   _icon_sobrev(cx, r, ic, fl, p)


func _icon_token(cx: Vector2, r: float, ic: Color, fl: Color, p: float) -> void:
	# Moeda dourada com estrela de 5 pontas e brilho pulsante
	draw_circle(cx, r * 0.80, fl)
	draw_arc(cx, r * 0.80, 0.0, TAU, 40, ic, 2.5)
	# Anel interno brilhante
	draw_arc(cx, r * 0.60, 0.0, TAU, 32,
			Color(ic.r, ic.g, ic.b, 0.45 * (sin(p * 2.5) * 0.25 + 0.75)), 1.5)
	# Estrela de 5 pontas
	var pts := PackedVector2Array()
	for i in range(10):
		var a   : float = float(i) * TAU / 10.0 - PI / 2.0
		var rad : float = r * 0.50 if i % 2 == 0 else r * 0.22
		pts.append(cx + Vector2(cos(a), sin(a)) * rad)
	draw_polygon(pts, _c(pts.size(), Color(ic.r * 0.55, ic.g * 0.55, ic.b * 0.10, 0.90)))
	var b := PackedVector2Array(pts); b.append(pts[0])
	draw_polyline(b, Color(ic.r, ic.g, ic.b, 0.90 + sin(p * 3.0) * 0.10), 1.8)
	# Brilho central pulsante
	draw_circle(cx, r * 0.10 * (sin(p * 3.5) * 0.15 + 0.85),
			Color(1.0, 0.98, 0.70, 0.88))


func _c(n: int, c: Color) -> PackedColorArray:
	var a := PackedColorArray(); a.resize(n); a.fill(c); return a


func _icon_hex(cx: Vector2, r: float, ic: Color, fl: Color) -> void:
	var pts := PackedVector2Array()
	for i in range(6):
		var a := float(i) * TAU / 6.0 + PI / 6.0
		pts.append(cx + Vector2(cos(a), sin(a)) * r)
	draw_polygon(pts, _c(pts.size(), fl))
	var b := PackedVector2Array(pts); b.append(pts[0])
	draw_polyline(b, ic, 2.0)
	draw_circle(cx, r * 0.28, ic)


func _icon_chama(cx: Vector2, r: float, ic: Color, fl: Color, p: float) -> void:
	var pts := PackedVector2Array([
		cx + Vector2(0,       -r * 0.95),
		cx + Vector2(r*0.50,  r * 0.18),
		cx + Vector2(r*0.20,  r * 0.05),
		cx + Vector2(r*0.12,  r * 0.78),
		cx + Vector2(-r*0.12, r * 0.78),
		cx + Vector2(-r*0.20, r * 0.05),
		cx + Vector2(-r*0.50, r * 0.18),
	])
	draw_polygon(pts, _c(pts.size(), fl))
	var b := PackedVector2Array(pts); b.append(pts[0])
	draw_polyline(b, ic, 1.8)
	draw_circle(cx + Vector2(0, r * 0.18), r * 0.18 * (sin(p * 2.0) * 0.1 + 0.9),
			Color(ic.r, ic.g, ic.b, 0.85))


func _icon_raio(cx: Vector2, r: float, ic: Color, fl: Color) -> void:
	var pts := PackedVector2Array([
		cx + Vector2( r*0.20, -r*0.92),
		cx + Vector2(-r*0.08, -r*0.06),
		cx + Vector2( r*0.26, -r*0.06),
		cx + Vector2(-r*0.20,  r*0.92),
		cx + Vector2( r*0.08,  r*0.06),
		cx + Vector2(-r*0.26,  r*0.06),
	])
	draw_polygon(pts, _c(pts.size(), fl))
	var b := PackedVector2Array(pts); b.append(pts[0])
	draw_polyline(b, ic, 2.0)


func _icon_duplo(cx: Vector2, r: float, ic: Color, fl: Color) -> void:
	for s in [-1.0, 1.0]:
		var cv : Vector2 = cx + Vector2(s * r * 0.32, 0.0)
		draw_circle(cv, r * 0.28, fl)
		draw_arc(cv, r * 0.28, 0.0, TAU, 20, ic, 1.8)
		draw_line(cv, cv + Vector2(s * r * 0.55, 0.0), ic, 3.0)
		draw_circle(cv + Vector2(s * r * 0.55, 0.0), r * 0.10, ic)


func _icon_escudo(cx: Vector2, r: float, ic: Color, fl: Color) -> void:
	var pts := PackedVector2Array([
		cx + Vector2(0,       -r * 0.95),
		cx + Vector2( r*0.72, -r * 0.40),
		cx + Vector2( r*0.54,  r * 0.48),
		cx + Vector2(0,        r * 0.88),
		cx + Vector2(-r*0.54,  r * 0.48),
		cx + Vector2(-r*0.72, -r * 0.40),
	])
	draw_polygon(pts, _c(pts.size(), fl))
	var b := PackedVector2Array(pts); b.append(pts[0])
	draw_polyline(b, ic, 2.0)
	draw_line(cx + Vector2(0, -r*0.38), cx + Vector2(0,  r*0.32), ic, 2.0)
	draw_line(cx + Vector2(-r*0.30, 0), cx + Vector2(r*0.30, 0),  ic, 2.0)


func _icon_coracao(cx: Vector2, r: float, ic: Color, fl: Color, p: float) -> void:
	var off : float = r * 0.28
	draw_arc(cx + Vector2(-off, -r*0.10), r*0.30, PI, 2.0*PI, 14, ic, 2.0)
	draw_arc(cx + Vector2( off, -r*0.10), r*0.30, PI, 2.0*PI, 14, ic, 2.0)
	var bot : Vector2 = cx + Vector2(0.0, r * 0.72)
	draw_line(cx + Vector2(-off - r*0.30, -r*0.10), bot, ic, 2.0)
	draw_line(cx + Vector2( off + r*0.30, -r*0.10), bot, ic, 2.0)
	draw_circle(bot, r * 0.12 * p, Color(ic.r, ic.g, ic.b, 0.8 * p))


func _icon_fenix(cx: Vector2, r: float, ic: Color, fl: Color, p: float) -> void:
	var wl := PackedVector2Array([
		cx,
		cx + Vector2(-r*0.85, -r*0.30),
		cx + Vector2(-r*0.95,  r*0.18),
		cx + Vector2(-r*0.40,  r*0.05),
	])
	draw_polygon(wl, _c(wl.size(), fl))
	var bl := PackedVector2Array(wl); bl.append(wl[0]); draw_polyline(bl, ic, 1.8)
	var wr := PackedVector2Array([
		cx,
		cx + Vector2( r*0.85, -r*0.30),
		cx + Vector2( r*0.95,  r*0.18),
		cx + Vector2( r*0.40,  r*0.05),
	])
	draw_polygon(wr, _c(wr.size(), fl))
	var br := PackedVector2Array(wr); br.append(wr[0]); draw_polyline(br, ic, 1.8)
	draw_circle(cx + Vector2(0.0, -r*0.18), r * 0.22,
			Color(fl.r * 1.5, fl.g * 1.5, fl.b * 1.5, 0.9))
	var ta : float = -PI * 0.5 + sin(p * 1.5) * 0.22
	draw_arc(cx + Vector2(0.0, r * 0.35), r * 0.32, ta - 0.5, ta + 0.5, 10, ic, 2.5)


func _icon_moeda(cx: Vector2, r: float, ic: Color, fl: Color, p: float) -> void:
	draw_circle(cx, r * 0.80, fl)
	draw_arc(cx, r * 0.80, 0.0, TAU, 32, ic, 2.2)
	var pts := PackedVector2Array([
		cx + Vector2(0,       -r * 0.46),
		cx + Vector2( r*0.34,  0.0),
		cx + Vector2(0,        r * 0.46),
		cx + Vector2(-r*0.34,  0.0),
	])
	draw_polygon(pts, _c(pts.size(), Color(ic.r, ic.g, ic.b, 0.55 * p)))
	var b := PackedVector2Array(pts); b.append(pts[0]); draw_polyline(b, ic, 1.8)


func _icon_gema(cx: Vector2, r: float, ic: Color, fl: Color) -> void:
	var top := PackedVector2Array([
		cx + Vector2(0,       -r * 0.90),
		cx + Vector2(-r*0.55, -r * 0.18),
		cx + Vector2( r*0.55, -r * 0.18),
	])
	draw_polygon(top, _c(top.size(), Color(fl.r * 1.5, fl.g * 1.5, fl.b * 1.5, 0.72)))
	var btm := PackedVector2Array([
		cx + Vector2(-r*0.55, -r * 0.18),
		cx + Vector2(0,        r * 0.88),
		cx + Vector2( r*0.55, -r * 0.18),
	])
	draw_polygon(btm, _c(btm.size(), fl))
	var outline := PackedVector2Array([
		cx + Vector2(0,       -r * 0.90),
		cx + Vector2(-r*0.55, -r * 0.18),
		cx + Vector2(0,        r * 0.88),
		cx + Vector2( r*0.55, -r * 0.18),
	])
	var b := PackedVector2Array(outline); b.append(outline[0])
	draw_polyline(b, ic, 2.0)
	draw_line(cx + Vector2(-r*0.55, -r*0.18), cx + Vector2(r*0.55, -r*0.18), ic, 1.5)


func _icon_estrela(cx: Vector2, r: float, ic: Color, fl: Color, p: float) -> void:
	var pts := PackedVector2Array()
	for i in range(8):
		var a   : float = float(i) * TAU / 8.0 - PI / 2.0
		var rad : float = r * 0.88 if i % 2 == 0 else r * 0.38
		pts.append(cx + Vector2(cos(a), sin(a)) * rad)
	draw_polygon(pts, _c(pts.size(), fl))
	var b := PackedVector2Array(pts); b.append(pts[0])
	draw_polyline(b, ic, 2.0)
	draw_circle(cx, r * 0.18 * (sin(p * 3.0) * 0.12 + 0.88),
			Color(ic.r, ic.g, ic.b, p * 0.92))


# ── Tier-4 icons ─────────────────────────────────────────────────────────────

func _icon_arsenal(cx: Vector2, r: float, ic: Color, fl: Color) -> void:
	# p4 — Arsenal Pesado: dois canos de canhão sobrepostos
	for s in [-1.0, 1.0]:
		var yc : float = cx.y + s * r * 0.34
		draw_rect(Rect2(cx.x - r*0.72, yc - r*0.18, r*1.44, r*0.36), fl, true)
		draw_rect(Rect2(cx.x - r*0.72, yc - r*0.18, r*1.44, r*0.36), ic, false, 1.8)
		# Boca do cano (círculo na ponta)
		draw_circle(Vector2(cx.x + r*0.72, yc), r*0.18, ic)
		# Culatra (círculo largo na base)
		draw_circle(Vector2(cx.x - r*0.72, yc), r*0.24, fl)
		draw_arc(Vector2(cx.x - r*0.72, yc), r*0.24, 0.0, TAU, 12, ic, 1.8)


func _icon_muralha(cx: Vector2, r: float, ic: Color, fl: Color) -> void:
	# r4 — Muralha Viva: parede de tijolos 3×3 escalonada
	var bw : float = r * 0.44
	var bh : float = r * 0.27
	for row in range(3):
		var ry : float = cx.y - r*0.62 + float(row) * bh * 2.25
		var off : float = float(row % 2) * bw
		for col in range(-1, 2):
			var rx : float = cx.x + float(col) * bw * 2.0 + off - bw
			draw_rect(Rect2(rx + 1.5, ry + 1.5, bw*2.0 - 3.0, bh*2.0 - 3.0), fl, true)
			draw_rect(Rect2(rx + 1.5, ry + 1.5, bw*2.0 - 3.0, bh*2.0 - 3.0), ic, false, 1.5)


func _icon_mercador(cx: Vector2, r: float, ic: Color, fl: Color, p: float) -> void:
	# f4 — Mercador das Almas: caveira + moeda brilhante
	draw_circle(cx + Vector2(0.0, -r*0.12), r*0.54, fl)
	draw_arc(cx + Vector2(0.0, -r*0.12), r*0.54, 0.0, TAU, 28, ic, 2.0)
	var jaw := PackedVector2Array([
		cx + Vector2(-r*0.34, r*0.26),
		cx + Vector2(-r*0.34, r*0.72),
		cx + Vector2( r*0.34, r*0.72),
		cx + Vector2( r*0.34, r*0.26),
	])
	draw_polygon(jaw, _c(jaw.size(), fl))
	var jb := PackedVector2Array(jaw); jb.append(jaw[0]); draw_polyline(jb, ic, 1.8)
	# Dentes (lacunas verticais na mandíbula)
	for t in [-1, 0, 1]:
		draw_line(cx + Vector2(float(t)*r*0.22, r*0.50),
				  cx + Vector2(float(t)*r*0.22, r*0.72),
				  Color(0.04, 0.04, 0.07, 1.0), 3.5)
	# Olhos vazios
	draw_circle(cx + Vector2(-r*0.20, -r*0.20), r*0.12, Color(0.04, 0.04, 0.08, 0.95))
	draw_circle(cx + Vector2( r*0.20, -r*0.20), r*0.12, Color(0.04, 0.04, 0.08, 0.95))
	# Moedinha cintilante no canto superior
	draw_circle(cx + Vector2(r*0.58, -r*0.72),
			r*0.17 * (sin(p*3.2)*0.08 + 0.92),
			Color(ic.r + 0.10, ic.g + 0.05, ic.b * 0.60, 0.90*p))
	draw_arc(cx + Vector2(r*0.58, -r*0.72), r*0.17, 0.0, TAU, 12,
			Color(1.0, 0.92, 0.4, 0.70*p), 1.5)


# ── Ramo E — Energia ─────────────────────────────────────────────────────────

func _icon_condutor(cx: Vector2, r: float, ic: Color, fl: Color) -> void:
	# e1 — Condutor Arcano: barra horizontal + três postes verticais com nós
	draw_line(cx + Vector2(-r*0.80, r*0.12), cx + Vector2(r*0.80, r*0.12), ic, 2.5)
	for i in range(3):
		var px : float = cx.x + float(i - 1) * r * 0.60
		draw_line(Vector2(px, cx.y - r*0.65), Vector2(px, cx.y + r*0.12), fl, 3.5)
		draw_line(Vector2(px, cx.y - r*0.65), Vector2(px, cx.y + r*0.12), ic, 1.8)
		draw_circle(Vector2(px, cx.y + r*0.12), r*0.11, ic)
		draw_circle(Vector2(px, cx.y - r*0.65), r*0.09,
				Color(ic.r + 0.20, ic.g + 0.15, ic.b, 0.88))


func _icon_sobrecarga(cx: Vector2, r: float, ic: Color, fl: Color, p: float) -> void:
	# e2 — Sobrecarga: dois raios lado a lado
	for s in [-1.0, 1.0]:
		var ox : float = s * r * 0.29
		var pts := PackedVector2Array([
			cx + Vector2(ox + r*0.10, -r*0.86),
			cx + Vector2(ox - r*0.05, -r*0.06),
			cx + Vector2(ox + r*0.14, -r*0.06),
			cx + Vector2(ox - r*0.10,  r*0.86),
			cx + Vector2(ox + r*0.05,  r*0.06),
			cx + Vector2(ox - r*0.14,  r*0.06),
		])
		draw_polygon(pts, _c(pts.size(), Color(fl.r, fl.g, fl.b, 0.72)))
		var b := PackedVector2Array(pts); b.append(pts[0])
		draw_polyline(b, Color(ic.r, ic.g, ic.b, 0.80 + sin(p + s)*0.20), 1.8)


func _icon_tempestade(cx: Vector2, r: float, ic: Color, fl: Color, p: float) -> void:
	# e3 — Tempestade Interior: espiral animada
	var pts := PackedVector2Array()
	var steps := 80
	for i in range(steps):
		var t     : float = float(i) / float(steps - 1)
		var angle : float = t * TAU * 2.4 + p * 0.38
		var rad   : float = r * 0.84 * (1.0 - t * 0.82)
		pts.append(cx + Vector2(cos(angle), sin(angle)) * rad)
	draw_polyline(pts, Color(fl.r*1.5, fl.g*1.5, fl.b*1.5, 0.38), 4.5)
	draw_polyline(pts, ic, 1.8)
	draw_circle(cx, r * 0.12, Color(ic.r + 0.10, ic.g + 0.05, ic.b, 0.92))


func _icon_olho(cx: Vector2, r: float, ic: Color, fl: Color, p: float) -> void:
	# e4 — Olho da Tormenta: olho amêndoa com pupila pulsante
	var pts := PackedVector2Array()
	for i in range(17):
		var t : float = float(i) / 16.0 * PI
		pts.append(cx + Vector2(cos(t) * r*0.84, -sin(t) * r*0.40))
	for i in range(17):
		var t : float = float(i) / 16.0 * PI
		pts.append(cx + Vector2(-cos(t) * r*0.84, sin(t) * r*0.40))
	draw_polygon(pts, _c(pts.size(), fl))
	var b := PackedVector2Array(pts); b.append(pts[0])
	draw_polyline(b, ic, 2.0)
	# Iris
	draw_circle(cx, r * 0.25, Color(ic.r*0.28, ic.g*0.28, ic.b*0.28, 0.94))
	draw_arc(cx, r * 0.25, 0.0, TAU, 16, ic, 1.8)
	# Pupila pulsante
	draw_circle(cx, r * 0.10 * (sin(p * 2.5) * 0.12 + 0.88),
			Color(1.0, 1.0, 1.0, 0.88))


# ── Ramo S — Sombra ──────────────────────────────────────────────────────────

func _icon_sombra(cx: Vector2, r: float, ic: Color, fl: Color, p: float) -> void:
	# s1 — Toque das Sombras: quatro garras rasgando
	for i in range(4):
		var ox : float = (float(i) - 1.5) * r * 0.40
		var pts := PackedVector2Array([
			cx + Vector2(ox - r*0.09, -r*0.82),
			cx + Vector2(ox + r*0.04, -r*0.08),
			cx + Vector2(ox + r*0.12,  r*0.82),
		])
		draw_polyline(pts, Color(fl.r*1.6, fl.g*1.6, fl.b*1.6, 0.42), 5.0)
		draw_polyline(pts,
				Color(ic.r, ic.g, ic.b, 0.78 + sin(p + float(i) * 0.9) * 0.22), 1.8)


func _icon_corrosao(cx: Vector2, r: float, ic: Color, fl: Color, p: float) -> void:
	# s2 — Corrosão Arcana: gotas de ácido caindo
	var drops := [
		Vector2(-r*0.38, -r*0.30), Vector2(r*0.14, -r*0.52),
		Vector2(r*0.42,   r*0.06), Vector2(-r*0.10,  r*0.40),
	]
	for drop in drops:
		var dp : Vector2 = drop
		draw_circle(cx + dp, r*0.15, fl)
		draw_arc(cx + dp, r*0.15, 0.0, TAU, 10, ic, 1.5)
		var a_phase : float = p + dp.x * 0.04 + dp.y * 0.04
		draw_line(cx + dp + Vector2(0.0, r*0.15),
				  cx + dp + Vector2(0.0, r*0.32),
				  Color(ic.r, ic.g, ic.b, 0.62 * (sin(a_phase)*0.2 + 0.8)), 2.0)
	draw_circle(cx + Vector2(0.0, r*0.62), r*0.10, Color(ic.r, ic.g, ic.b, 0.55*p))


func _icon_praga(cx: Vector2, r: float, ic: Color, fl: Color, p: float) -> void:
	# s3 — Praga Sombria: nuvem de veneno com gotículas animadas
	var puffs := [
		Vector2( 0.0,   -r*0.30),
		Vector2(-r*0.36, -r*0.06),
		Vector2( r*0.36, -r*0.06),
	]
	for puff in puffs:
		draw_circle(cx + (puff as Vector2), r*0.30, fl)
	draw_rect(Rect2(cx.x - r*0.62, cx.y + r*0.16, r*1.24, r*0.26), fl, true)
	for puff in puffs:
		draw_arc(cx + (puff as Vector2), r*0.30, PI, 2.0*PI, 12, ic, 1.8)
	draw_line(cx + Vector2(-r*0.62, r*0.22), cx + Vector2(r*0.62, r*0.22), ic, 1.8)
	# Gotículas animadas descendo
	for i in range(3):
		var fi  : float = float(i)
		var dx  : float = (fi - 1.0) * r * 0.32
		var dy  : float = fmod(fi * 0.35 + p * 0.20, 1.0) * r * 0.52
		draw_circle(cx + Vector2(dx, r*0.36 + dy), r*0.07,
				Color(ic.r, ic.g, ic.b, 0.82))


func _icon_eterno(cx: Vector2, r: float, ic: Color, fl: Color, p: float) -> void:
	# s4 — Veneno Eterno: serpente enrolada com língua bífida
	for i in range(3):
		var ci      : float = float(i)
		var arc_r   : float = r * (0.76 - ci * 0.20)
		var a_start : float = ci * TAU / 3.0 + p * 0.12
		var a_end   : float = a_start + PI * 1.55
		draw_arc(cx, arc_r, a_start, a_end, 28,
				Color(fl.r*1.4, fl.g*1.4, fl.b*1.4, 0.42), arc_r * 0.32)
		draw_arc(cx, arc_r, a_start, a_end, 28, ic, 2.0)
	# Cabeça da serpente
	var ha : float = p * 0.12 + PI * 1.05
	var hp : Vector2 = cx + Vector2(cos(ha), sin(ha)) * r * 0.36
	draw_circle(hp, r * 0.13, ic)
	# Língua bífida
	var ta  : float = ha + PI
	var tb  : Vector2 = hp + Vector2(cos(ta), sin(ta)) * r * 0.20
	draw_line(hp, tb, ic, 1.5)
	draw_line(tb, tb + Vector2(cos(ta + 0.45), sin(ta + 0.45)) * r*0.18, ic, 1.2)
	draw_line(tb, tb + Vector2(cos(ta - 0.45), sin(ta - 0.45)) * r*0.18, ic, 1.2)


# ── Ramo P — tier 5 ──────────────────────────────────────────────────────────

func _icon_canhao(cx: Vector2, r: float, ic: Color, fl: Color, p: float) -> void:
	# p5 — Lenda do Canhão: cano longo com chama na boca
	draw_rect(Rect2(cx.x - r*0.80, cx.y - r*0.22, r*1.30, r*0.44), fl, true)
	draw_rect(Rect2(cx.x - r*0.80, cx.y - r*0.22, r*1.30, r*0.44), ic, false, 1.8)
	draw_circle(cx + Vector2(-r*0.80, 0.0), r*0.26, fl)
	draw_arc(cx + Vector2(-r*0.80, 0.0), r*0.26, 0.0, TAU, 14, ic, 1.8)
	# Rodas
	draw_circle(cx + Vector2(-r*0.35, r*0.50), r*0.20, fl)
	draw_arc(cx + Vector2(-r*0.35, r*0.50), r*0.20, 0.0, TAU, 12, ic, 1.5)
	draw_circle(cx + Vector2( r*0.25, r*0.50), r*0.20, fl)
	draw_arc(cx + Vector2( r*0.25, r*0.50), r*0.20, 0.0, TAU, 12, ic, 1.5)
	# Chama pulsante na boca
	var fp : float = sin(p * 3.5) * 0.12 + 0.88
	for fi in range(3):
		var fa : float = float(fi) * TAU / 3.0 + p * 1.2
		draw_line(cx + Vector2(r*0.50, 0.0),
			cx + Vector2(r*0.50 + cos(fa)*r*0.22*fp, sin(fa)*r*0.22*fp),
			Color(ic.r + 0.10, ic.g - 0.10, 0.0, 0.85), 2.5)


# ── Ramo R — tier 5 e 6 ──────────────────────────────────────────────────────

func _icon_imortal(cx: Vector2, r: float, ic: Color, fl: Color, p: float) -> void:
	# r5 — Imortal: escudo brilhante com cruz de luz
	var pts := PackedVector2Array([
		cx + Vector2(0,       -r*0.95),
		cx + Vector2( r*0.70, -r*0.38),
		cx + Vector2( r*0.52,  r*0.46),
		cx + Vector2(0,        r*0.86),
		cx + Vector2(-r*0.52,  r*0.46),
		cx + Vector2(-r*0.70, -r*0.38),
	])
	draw_polygon(pts, _c(pts.size(), fl))
	var b := PackedVector2Array(pts); b.append(pts[0])
	for gi in range(3, 0, -1):
		draw_polyline(b, Color(ic.r, ic.g, ic.b, 0.15*p/float(gi)), float(gi)*3.0)
	draw_polyline(b, ic, 2.0)
	# Cruz de luz pulsante
	var glo : float = sin(p * 2.0) * 0.20 + 0.80
	draw_line(cx + Vector2(0, -r*0.50), cx + Vector2(0, r*0.42),
			Color(1.0, 1.0, 1.0, 0.85*glo), 3.0)
	draw_line(cx + Vector2(-r*0.36, -r*0.10), cx + Vector2(r*0.36, -r*0.10),
			Color(1.0, 1.0, 1.0, 0.85*glo), 3.0)
	draw_circle(cx + Vector2(0, -r*0.10), r*0.10*glo,
			Color(1.0, 1.0, 1.0, 0.92))


# ── Ramo F — tier 5 ──────────────────────────────────────────────────────────

func _icon_banco(cx: Vector2, r: float, ic: Color, fl: Color, p: float) -> void:
	# f5 — Banco das Almas: torre de moedas empilhadas
	var ys : Array = [-r*0.66, -r*0.33, 0.0, r*0.33, r*0.66]
	for yi in range(ys.size()):
		var yv : float = ys[yi] as float
		var rw : float = r * (0.38 + float(yi) * 0.08)
		draw_ellipse_helper(cx + Vector2(0, yv), rw, r*0.14, fl, ic, 1.5, p * 0.0 + 0.0)
	# Brilho pulsante no topo
	var gp : float = sin(p * 2.8) * 0.15 + 0.85
	draw_circle(cx + Vector2(0, -r*0.66), r*0.10*gp,
			Color(ic.r + 0.10, ic.g + 0.05, 0.20, 0.90))


func draw_ellipse_helper(c: Vector2, rx: float, ry: float,
		fill: Color, outline: Color, lw: float, _unused: float) -> void:
	var steps := 20
	var pts   := PackedVector2Array()
	pts.resize(steps)
	for i in range(steps):
		var t : float = float(i) / float(steps) * TAU
		pts[i] = c + Vector2(cos(t)*rx, sin(t)*ry)
	draw_polygon(pts, _c(pts.size(), fill))
	var b := PackedVector2Array(pts); b.append(pts[0])
	draw_polyline(b, outline, lw)


# ── Ramo E — tier 5 ──────────────────────────────────────────────────────────

func _icon_furia_elet(cx: Vector2, r: float, ic: Color, fl: Color, p: float) -> void:
	# e5 — Fúria Elétrica: três raios em leque animado
	for i in range(3):
		var fi    : float = float(i) - 1.0
		var angle : float = fi * 0.40 + sin(p * 1.8 + fi) * 0.08
		var rot   := Vector2(sin(angle), -cos(angle))
		var perp  := Vector2(cos(angle),  sin(angle))
		var pts   := PackedVector2Array([
			cx + rot * r*0.90,
			cx + rot * r*0.40 + perp * r*0.08,
			cx + rot * r*0.10 + perp * r*0.10,
			cx - rot * r*0.60 + perp * r*0.08,
			cx - rot * r*0.60 - perp * r*0.08,
			cx + rot * r*0.10 - perp * r*0.10,
			cx + rot * r*0.40 - perp * r*0.08,
		])
		draw_polygon(pts, _c(pts.size(), Color(fl.r, fl.g, fl.b, 0.60)))
		var b := PackedVector2Array(pts); b.append(pts[0])
		draw_polyline(b, Color(ic.r, ic.g, ic.b, 0.70 + float(i==1)*0.30), 1.8)
	draw_circle(cx, r*0.12, Color(ic.r + 0.15, ic.g + 0.10, ic.b, 0.95))


# ── Ramo S — tier 5 ──────────────────────────────────────────────────────────

func _icon_metamorf(cx: Vector2, r: float, ic: Color, fl: Color, p: float) -> void:
	# s5 — Metamorfose: borboleta simétrica
	for s in [-1.0, 1.0]:
		var wpts := PackedVector2Array([
			cx,
			cx + Vector2(s*r*0.88, -r*0.55),
			cx + Vector2(s*r*0.95,  r*0.12),
			cx + Vector2(s*r*0.55,  r*0.70),
			cx + Vector2(s*r*0.18,  r*0.25),
		])
		draw_polygon(wpts, _c(wpts.size(), Color(fl.r, fl.g, fl.b, 0.72)))
		var bw := PackedVector2Array(wpts); bw.append(wpts[0])
		draw_polyline(bw, ic, 1.8)
	# Corpo central
	draw_line(cx + Vector2(0, -r*0.80), cx + Vector2(0, r*0.80), ic, 2.5)
	# Antenas animadas
	var aa : float = sin(p * 1.6) * 0.12
	draw_line(cx + Vector2(0, -r*0.80),
			cx + Vector2(-r*0.30 + aa*r, -r*0.98), ic, 1.5)
	draw_line(cx + Vector2(0, -r*0.80),
			cx + Vector2( r*0.30 - aa*r, -r*0.98), ic, 1.5)
	draw_circle(cx + Vector2(-r*0.30 + aa*r, -r*0.98), r*0.07, ic)
	draw_circle(cx + Vector2( r*0.30 - aa*r, -r*0.98), r*0.07, ic)


# ── Ramo M — Maestria ────────────────────────────────────────────────────────

func _icon_leque(cx: Vector2, r: float, ic: Color, fl: Color) -> void:
	# m1 — Leque de Opções: cartas em leque
	for i in range(4):
		var a : float = float(i) * 0.38 - 0.57
		var cv : Vector2 = cx + Vector2(sin(a), -cos(a)) * r * 0.30
		var hw : float = r * 0.22
		var hh : float = r * 0.62
		var rot_pts := PackedVector2Array([
			cv + _rot2(Vector2(-hw, -hh), a),
			cv + _rot2(Vector2( hw, -hh), a),
			cv + _rot2(Vector2( hw,  hh), a),
			cv + _rot2(Vector2(-hw,  hh), a),
		])
		draw_polygon(rot_pts, _c(rot_pts.size(), fl))
		var b := PackedVector2Array(rot_pts); b.append(rot_pts[0])
		draw_polyline(b, ic, 1.5)
	draw_circle(cx, r*0.12, ic)


func _rot2(v: Vector2, angle: float) -> Vector2:
	return Vector2(v.x*cos(angle) - v.y*sin(angle),
				   v.x*sin(angle) + v.y*cos(angle))


func _icon_frasco(cx: Vector2, r: float, ic: Color, fl: Color, p: float) -> void:
	# m2 — Alquimia de Cartas: frasco com líquido borbulhando
	var body := PackedVector2Array([
		cx + Vector2(-r*0.42, -r*0.20),
		cx + Vector2(-r*0.58,  r*0.25),
		cx + Vector2(-r*0.52,  r*0.80),
		cx + Vector2( r*0.52,  r*0.80),
		cx + Vector2( r*0.58,  r*0.25),
		cx + Vector2( r*0.42, -r*0.20),
	])
	draw_polygon(body, _c(body.size(), fl))
	var bb := PackedVector2Array(body); bb.append(body[0]); draw_polyline(bb, ic, 2.0)
	# Gargalo
	draw_rect(Rect2(cx.x - r*0.20, cx.y - r*0.82, r*0.40, r*0.64), fl, true)
	draw_rect(Rect2(cx.x - r*0.20, cx.y - r*0.82, r*0.40, r*0.64), ic, false, 1.8)
	# Líquido pulsante
	var lv : float = sin(p * 2.0) * 0.08 + 0.60
	draw_rect(Rect2(cx.x - r*0.46, cx.y + lv*r*0.35, r*0.92, r*(0.80 - lv*0.35)),
			Color(ic.r, ic.g, ic.b, 0.42), true)
	# Bolha
	var by : float = cx.y + r*0.30 - fmod(p * r*0.18, r*0.60)
	draw_circle(Vector2(cx.x + r*0.15, by), r*0.07,
			Color(ic.r + 0.10, ic.g + 0.10, ic.b, 0.70))


func _icon_saco(cx: Vector2, r: float, ic: Color, fl: Color) -> void:
	# m3 — Mercado Negro: saco cheio de moedas
	draw_circle(cx + Vector2(0, r*0.20), r*0.70, fl)
	draw_arc(cx + Vector2(0, r*0.20), r*0.70, 0.0, TAU, 28, ic, 2.0)
	# Laço no topo
	draw_rect(Rect2(cx.x - r*0.18, cx.y - r*0.56, r*0.36, r*0.22), fl, true)
	draw_rect(Rect2(cx.x - r*0.18, cx.y - r*0.56, r*0.36, r*0.22), ic, false, 1.5)
	draw_line(cx + Vector2(-r*0.22, -r*0.56), cx + Vector2(r*0.22, -r*0.56), ic, 2.0)
	# Símbolo no saco
	draw_line(cx + Vector2(-r*0.22, r*0.14), cx + Vector2(r*0.22, r*0.14), ic, 2.0)
	draw_line(cx + Vector2(0, -r*0.12), cx + Vector2(0,  r*0.40), ic, 2.0)


func _icon_dupla_carta(cx: Vector2, r: float, ic: Color, fl: Color) -> void:
	# m4 — Dupla Escolha: duas cartas sobrepostas com estrela
	for s in [-1.0, 1.0]:
		var ox : float = s * r * 0.22
		var oy : float = s * r * 0.18
		var hw : float = r * 0.34
		var hh : float = r * 0.56
		var pts := PackedVector2Array([
			cx + Vector2(ox - hw, oy - hh),
			cx + Vector2(ox + hw, oy - hh),
			cx + Vector2(ox + hw, oy + hh),
			cx + Vector2(ox - hw, oy + hh),
		])
		draw_polygon(pts, _c(pts.size(), Color(fl.r, fl.g, fl.b, 0.75)))
		var b := PackedVector2Array(pts); b.append(pts[0])
		draw_polyline(b, ic, 1.8)
	draw_circle(cx, r*0.14, ic)


# ── Ramo G — Glacial ─────────────────────────────────────────────────────────

func _icon_floco(cx: Vector2, r: float, ic: Color, fl: Color) -> void:
	# g1 — Vantagem Glacial: cristal de neve de 6 pontas
	for i in range(6):
		var a : float = float(i) * TAU / 6.0
		var tip : Vector2 = cx + Vector2(cos(a), sin(a)) * r * 0.86
		draw_line(cx, tip, ic, 2.0)
		# Raminhos laterais
		for s in [-1.0, 1.0]:
			var ma : float = a + s * PI / 3.0
			var mp : Vector2 = cx + Vector2(cos(a), sin(a)) * r * 0.50
			draw_line(mp, mp + Vector2(cos(ma), sin(ma)) * r * 0.28, ic, 1.5)
	draw_circle(cx, r*0.12, fl)
	draw_arc(cx, r*0.12, 0.0, TAU, 8, ic, 1.5)


func _icon_tundra(cx: Vector2, r: float, ic: Color, fl: Color, p: float) -> void:
	# g2 — Tundra Prolongada: ampulheta com cristais de gelo
	var hw : float = r * 0.38
	var body := PackedVector2Array([
		cx + Vector2(-hw, -r*0.88),
		cx + Vector2( hw, -r*0.88),
		cx + Vector2( r*0.06, 0.0),
		cx + Vector2( hw,  r*0.88),
		cx + Vector2(-hw,  r*0.88),
		cx + Vector2(-r*0.06, 0.0),
	])
	draw_polygon(body, _c(body.size(), Color(fl.r, fl.g, fl.b, 0.55)))
	var b := PackedVector2Array(body); b.append(body[0]); draw_polyline(b, ic, 2.0)
	# Floco pequeno animado caindo
	var fy : float = fmod(p * r * 0.14, r * 0.55)
	draw_arc(cx + Vector2(0, -r*0.44 + fy), r*0.10, 0.0, TAU, 6, ic, 1.5)


func _icon_avalanche(cx: Vector2, r: float, ic: Color, fl: Color) -> void:
	# g3 — Avalanche: triângulo de neve descendo com seta
	var pts := PackedVector2Array([
		cx + Vector2(0,       -r*0.90),
		cx + Vector2( r*0.82,  r*0.55),
		cx + Vector2(-r*0.82,  r*0.55),
	])
	draw_polygon(pts, _c(pts.size(), fl))
	var b := PackedVector2Array(pts); b.append(pts[0]); draw_polyline(b, ic, 2.0)
	# Ondas de neve internas
	for wi in range(3):
		var wy : float = -r*0.20 + float(wi) * r*0.32
		var wx : float = float(wi + 1) * r * 0.24
		draw_arc(cx + Vector2(0, wy), wx, 0.0, PI, 10, ic, 1.5)
	# Seta para baixo
	draw_line(cx + Vector2(0, r*0.60), cx + Vector2(0, r*0.90), ic, 2.2)
	draw_line(cx + Vector2(-r*0.14, r*0.75), cx + Vector2(0, r*0.90), ic, 2.2)
	draw_line(cx + Vector2( r*0.14, r*0.75), cx + Vector2(0, r*0.90), ic, 2.2)


func _icon_criotrance(cx: Vector2, r: float, ic: Color, fl: Color, p: float) -> void:
	# g4 — Criotranse: espiral angular de gelo
	var pts := PackedVector2Array()
	var steps := 60
	for i in range(steps):
		var t     : float = float(i) / float(steps - 1)
		var angle : float = t * TAU * 2.0 + p * 0.20
		var rad   : float = r * 0.85 * (1.0 - t * 0.78)
		pts.append(cx + Vector2(cos(angle), sin(angle)) * rad)
	draw_polyline(pts, Color(fl.r*1.6, fl.g*1.6, fl.b*1.6, 0.32), 5.0)
	draw_polyline(pts, ic, 1.8)
	# Cristal central
	var cpts := PackedVector2Array()
	for i in range(6):
		var a : float = float(i) * TAU / 6.0
		cpts.append(cx + Vector2(cos(a), sin(a)) * r * 0.15)
	draw_polygon(cpts, _c(cpts.size(), ic))


# ── Ramo B — Berserker ───────────────────────────────────────────────────────

func _icon_sangue(cx: Vector2, r: float, ic: Color, fl: Color, p: float) -> void:
	# b1 — Fúria de Sangue: gota de sangue com racha
	var drop := PackedVector2Array([
		cx + Vector2(0, -r*0.90),
		cx + Vector2( r*0.48, -r*0.12),
		cx + Vector2( r*0.55,  r*0.30),
		cx + Vector2( r*0.30,  r*0.68),
		cx + Vector2(0,        r*0.85),
		cx + Vector2(-r*0.30,  r*0.68),
		cx + Vector2(-r*0.55,  r*0.30),
		cx + Vector2(-r*0.48, -r*0.12),
	])
	draw_polygon(drop, _c(drop.size(), fl))
	var bd := PackedVector2Array(drop); bd.append(drop[0])
	draw_polyline(bd, ic, 2.0)
	# Racha no meio (ira)
	draw_line(cx + Vector2(-r*0.18, -r*0.28), cx + Vector2(r*0.04, r*0.10), ic, 2.2)
	draw_line(cx + Vector2(r*0.04, r*0.10),  cx + Vector2(r*0.20, r*0.52),  ic, 2.2)
	# Brilho pulsante
	draw_circle(cx + Vector2(0, -r*0.28),
			r*0.08*(sin(p*3.0)*0.10 + 0.90), Color(1.0, 0.80, 0.80, 0.70))


func _icon_trance(cx: Vector2, r: float, ic: Color, fl: Color, p: float) -> void:
	# b2 — Trance Berserker: linhas de velocidade em espiral
	for i in range(8):
		var a    : float = float(i) * TAU / 8.0 + p * 0.60
		var r1   : float = r * 0.28
		var r2   : float = r * 0.88
		var pa   : Vector2 = cx + Vector2(cos(a), sin(a)) * r1
		var pb   : Vector2 = cx + Vector2(cos(a + 0.55), sin(a + 0.55)) * r2
		var alph : float = (1.0 - float(i) / 8.0) * 0.80
		draw_line(pa, pb, Color(ic.r, ic.g, ic.b, alph), 2.5)
	draw_circle(cx, r*0.22, fl)
	draw_arc(cx, r*0.22, 0.0, TAU, 16, ic, 2.0)
	draw_circle(cx, r*0.10, Color(ic.r + 0.10, ic.g, ic.b, 0.92))


func _icon_pillagem(cx: Vector2, r: float, ic: Color, fl: Color) -> void:
	# b3 — Pilhagem Bárbara: machado + moeda
	# Machado
	var axe := PackedVector2Array([
		cx + Vector2(-r*0.15, -r*0.88),
		cx + Vector2(-r*0.58, -r*0.40),
		cx + Vector2(-r*0.58,  r*0.08),
		cx + Vector2(-r*0.10, -r*0.12),
		cx + Vector2( r*0.10,  r*0.80),
		cx + Vector2( r*0.22,  r*0.80),
		cx + Vector2(-r*0.02, -r*0.12),
	])
	draw_polygon(axe, _c(axe.size(), fl))
	var ba := PackedVector2Array(axe); ba.append(axe[0]); draw_polyline(ba, ic, 1.8)
	# Moeda pequena
	draw_circle(cx + Vector2(r*0.60, -r*0.55), r*0.22, Color(fl.r*1.3, fl.g*1.3, fl.b*0.8, 0.90))
	draw_arc(cx + Vector2(r*0.60, -r*0.55), r*0.22, 0.0, TAU, 12, ic, 1.8)


func _icon_explosao(cx: Vector2, r: float, ic: Color, fl: Color, p: float) -> void:
	# b4 — Fúria Final: explosão em raios irregulares
	var n := 12
	for i in range(n):
		var a  : float = float(i) * TAU / float(n)
		var ra : float = r * (0.52 + sin(float(i)*2.14 + p*0.5) * 0.32)
		var rb : float = r * (0.20 + sin(float(i)*1.77) * 0.08)
		draw_line(cx + Vector2(cos(a), sin(a)) * rb,
				  cx + Vector2(cos(a), sin(a)) * ra,
				  Color(ic.r, ic.g, ic.b, 0.65 + float(i % 2)*0.25), 2.5)
	draw_circle(cx, r*0.22, fl)
	draw_circle(cx, r*0.12, Color(1.0, 0.90, 0.50, 0.90 * (sin(p*3.0)*0.15 + 0.85)))


# ── Ramo T — Temporal ────────────────────────────────────────────────────────

func _icon_ampulheta(cx: Vector2, r: float, ic: Color, fl: Color, p: float) -> void:
	# t1 — Fluxo Lento: ampulheta com areia caindo devagar
	var hw : float = r * 0.42
	var body := PackedVector2Array([
		cx + Vector2(-hw, -r*0.88),
		cx + Vector2( hw, -r*0.88),
		cx + Vector2( r*0.07,  0.0),
		cx + Vector2( hw,  r*0.88),
		cx + Vector2(-hw,  r*0.88),
		cx + Vector2(-r*0.07, 0.0),
	])
	draw_polygon(body, _c(body.size(), fl))
	var b := PackedVector2Array(body); b.append(body[0]); draw_polyline(b, ic, 2.0)
	# Areia acumulada embaixo
	var apts := PackedVector2Array([
		cx + Vector2(-hw + r*0.04, r*0.88),
		cx + Vector2( hw - r*0.04, r*0.88),
		cx + Vector2( r*0.28, r*0.38),
		cx + Vector2(-r*0.28, r*0.38),
	])
	draw_polygon(apts, _c(apts.size(), Color(ic.r, ic.g, ic.b, 0.50)))
	# Grão caindo animado
	var gy : float = cx.y - r*0.60 + fmod(p * r*0.22, r*0.55)
	draw_circle(Vector2(cx.x, gy), r*0.06, Color(ic.r, ic.g, ic.b, 0.80))


func _icon_pulso(cx: Vector2, r: float, ic: Color, fl: Color, p: float) -> void:
	# t2 — Pulso Congelante: ondas concêntricas pulsando
	for i in range(4):
		var fi   : float = float(i)
		var pr   : float = r * (0.22 + fi * 0.20) * (1.0 + sin(p * 1.4 - fi*0.7)*0.06)
		var alph : float = (0.80 - fi * 0.16) * (sin(p * 1.4 - fi*0.7)*0.15 + 0.85)
		draw_arc(cx, pr, 0.0, TAU, 24 + i*8, Color(ic.r, ic.g, ic.b, alph), 2.0 - fi*0.30)
	draw_circle(cx, r*0.12, fl)
	draw_circle(cx, r*0.07, ic)


func _icon_coroa(cx: Vector2, r: float, ic: Color, fl: Color) -> void:
	# t3 — Boss Pesado: coroa com 3 pontos
	var base := PackedVector2Array([
		cx + Vector2(-r*0.70,  r*0.55),
		cx + Vector2(-r*0.70, -r*0.20),
		cx + Vector2(-r*0.38, -r*0.70),
		cx + Vector2(0,       -r*0.45),
		cx + Vector2( r*0.38, -r*0.70),
		cx + Vector2( r*0.70, -r*0.20),
		cx + Vector2( r*0.70,  r*0.55),
	])
	draw_polygon(base, _c(base.size(), fl))
	var bb := PackedVector2Array(base); bb.append(base[0]); draw_polyline(bb, ic, 2.0)
	# Joias nos pontos
	for jx in [-r*0.38, 0.0, r*0.38]:
		var jy : float = -r*0.72 if jx != 0.0 else -r*0.47
		draw_circle(cx + Vector2(jx, jy), r*0.10, ic)
	# Base inferior
	draw_line(cx + Vector2(-r*0.70, r*0.55), cx + Vector2(r*0.70, r*0.55), ic, 2.5)


func _icon_relogio(cx: Vector2, r: float, ic: Color, fl: Color, p: float) -> void:
	# t4 — Retrocesso Temporal: relógio com seta anti-horária
	draw_circle(cx, r*0.88, fl)
	draw_arc(cx, r*0.88, 0.0, TAU, 32, ic, 2.0)
	# Marcadores de hora
	for i in range(12):
		var a   : float = float(i) * TAU / 12.0
		var pa2 : Vector2 = cx + Vector2(cos(a), sin(a)) * r * 0.72
		var pb2 : Vector2 = cx + Vector2(cos(a), sin(a)) * r * 0.84
		draw_line(pa2, pb2, ic, 1.5 if i % 3 == 0 else 0.8)
	# Ponteiros (indo para trás — hora 10, min 8)
	var ha : float = -p * 0.30          # hora vai no sentido anti-horário
	var ma : float = -p * 1.80
	draw_line(cx, cx + Vector2(sin(ha), -cos(ha)) * r*0.48, ic, 2.5)
	draw_line(cx, cx + Vector2(sin(ma), -cos(ma)) * r*0.70, ic, 1.8)
	draw_circle(cx, r*0.08, ic)
	# Seta curva indicando retrocesso
	draw_arc(cx, r*0.62, -PI*0.5, PI*0.1, 10,
			Color(ic.r, ic.g, ic.b, 0.55), 3.0)


# ── Ramo X — Caos ────────────────────────────────────────────────────────────

func _icon_dado(cx: Vector2, r: float, ic: Color, fl: Color) -> void:
	# x1 — Dados do Caos: face de dado em perspectiva isométrica
	var hw : float = r * 0.65
	# Face frontal
	draw_rect(Rect2(cx.x - hw, cx.y - hw*0.60, hw*2.0, hw*1.35), fl, true)
	draw_rect(Rect2(cx.x - hw, cx.y - hw*0.60, hw*2.0, hw*1.35), ic, false, 2.0)
	# Face superior (paralelogramo)
	var top := PackedVector2Array([
		cx + Vector2(-hw, -hw*0.60),
		cx + Vector2(0,   -hw),
		cx + Vector2(hw,  -hw*0.60),
		cx + Vector2(0,   -hw*0.20),
	])
	draw_polygon(top, _c(top.size(), Color(fl.r*1.5, fl.g*1.5, fl.b*1.5, 0.80)))
	var bt := PackedVector2Array(top); bt.append(top[0]); draw_polyline(bt, ic, 1.8)
	# Pontos (face frontal: 3 pontos em diagonal)
	var dot_pos : Array = [
		Vector2(-hw*0.48, -hw*0.18),
		Vector2(0.0,       hw*0.15),
		Vector2( hw*0.48,  hw*0.48),
	]
	for dp in dot_pos:
		draw_circle(cx + (dp as Vector2), r*0.09, ic)


func _icon_bencao(cx: Vector2, r: float, ic: Color, fl: Color, p: float) -> void:
	# x2 — Bênção Aleatória: estrela de 4 pontas com raios aleatórios
	var pts := PackedVector2Array()
	for i in range(8):
		var a   : float = float(i) * TAU / 8.0
		var rad : float = r * 0.88 if i % 2 == 0 else r * 0.36
		pts.append(cx + Vector2(cos(a), sin(a)) * rad)
	draw_polygon(pts, _c(pts.size(), fl))
	var b := PackedVector2Array(pts); b.append(pts[0]); draw_polyline(b, ic, 2.0)
	draw_circle(cx, r*0.16, Color(ic.r + 0.10, ic.g + 0.05, ic.b, 0.90*(sin(p*3.0)*0.15+0.85)))
	# Partículas aleatórias girando
	for i in range(6):
		var a2 : float = float(i) * TAU / 6.0 + p * 0.80
		var pr : float = r * 0.55 + float(i % 3) * r * 0.10
		draw_circle(cx + Vector2(cos(a2), sin(a2)) * pr,
				r*0.06, Color(ic.r, ic.g, ic.b, 0.55))


func _icon_reroll(cx: Vector2, r: float, ic: Color, fl: Color, p: float) -> void:
	# x3 — Reroll Gratuito: seta circular (refresh)
	# Arco principal (270°)
	draw_arc(cx, r*0.68, -PI*0.30, PI*1.70, 28, ic, 3.0)
	# Ponta da seta
	var tip_a : float = PI * 1.70
	var tip   : Vector2 = cx + Vector2(cos(tip_a), sin(tip_a)) * r * 0.68
	var tp    : float   = tip_a + PI*0.5
	draw_line(tip, tip + Vector2(cos(tp - 0.6), sin(tp - 0.6)) * r*0.28, ic, 2.5)
	draw_line(tip, tip + Vector2(cos(tp + 0.6), sin(tp + 0.6)) * r*0.28, ic, 2.5)
	# Símbolo de moeda / grátis no centro
	draw_circle(cx, r*0.26, fl)
	draw_arc(cx, r*0.26, 0.0, TAU, 14, ic, 1.8)
	draw_line(cx + Vector2(0, -r*0.15), cx + Vector2(0, r*0.15),
			Color(ic.r, ic.g, ic.b, 0.80 + sin(p*2.5)*0.20), 2.0)


func _icon_carta_caos(cx: Vector2, r: float, ic: Color, fl: Color, p: float) -> void:
	# x4 — Carta do Acaso: carta com ponto de interrogação animado
	var hw : float = r * 0.48
	var hh : float = r * 0.72
	draw_rect(Rect2(cx.x - hw, cx.y - hh, hw*2.0, hh*2.0), fl, true)
	draw_rect(Rect2(cx.x - hw, cx.y - hh, hw*2.0, hh*2.0), ic, false, 2.0)
	# Interrogação
	var qs  : float = r * 0.40
	draw_arc(cx + Vector2(0, -qs*0.24), qs*0.46, PI*0.15, PI*1.15, 12,
			Color(ic.r, ic.g, ic.b, 0.85 + sin(p*2.0)*0.15), 2.5)
	draw_line(cx + Vector2(r*0.06, r*0.20), cx + Vector2(r*0.06, r*0.40),
			Color(ic.r, ic.g, ic.b, 0.85), 2.5)
	draw_circle(cx + Vector2(r*0.06, r*0.52), r*0.07,
			Color(ic.r, ic.g, ic.b, 0.90))


# ── Fusões ────────────────────────────────────────────────────────────────────

func _icon_colosso(cx: Vector2, r: float, ic: Color, fl: Color, p: float) -> void:
	# colosso — 3 círculos sobrepostos em triângulo
	var offs : Array = [
		Vector2(-r*0.40, r*0.28),
		Vector2( r*0.40, r*0.28),
		Vector2( 0.0,   -r*0.44),
	]
	for off in offs:
		var ov : Vector2 = off as Vector2
		draw_circle(cx + ov, r*0.42, Color(fl.r, fl.g, fl.b, 0.65))
		draw_arc(cx + ov, r*0.42, 0.0, TAU, 20, ic, 2.0)
	# Núcleo central brilhante
	draw_circle(cx, r*0.16, Color(ic.r + 0.10, ic.g + 0.10, ic.b,
			0.90 * (sin(p * 2.2) * 0.15 + 0.85)))


func _icon_predador(cx: Vector2, r: float, ic: Color, fl: Color) -> void:
	# predador — duas presas cruzadas
	for s in [-1.0, 1.0]:
		var pts := PackedVector2Array([
			cx + Vector2(s*r*0.12,  -r*0.90),
			cx + Vector2(s*r*0.50,   r*0.70),
			cx + Vector2(s*r*0.10,   r*0.42),
			cx + Vector2(-s*r*0.14, -r*0.90),
		])
		draw_polygon(pts, _c(pts.size(), fl))
		var b := PackedVector2Array(pts); b.append(pts[0]); draw_polyline(b, ic, 1.8)
	# Gotas de veneno nos pontos
	for s2 in [-1.0, 1.0]:
		draw_circle(cx + Vector2(s2*r*0.40, r*0.72), r*0.10, ic)


func _icon_alquim(cx: Vector2, r: float, ic: Color, fl: Color, p: float) -> void:
	# alquimista — cristal facetado com brilho
	var pts := PackedVector2Array([
		cx + Vector2( 0,       -r*0.90),
		cx + Vector2( r*0.55,  -r*0.22),
		cx + Vector2( r*0.42,   r*0.72),
		cx + Vector2(-r*0.42,   r*0.72),
		cx + Vector2(-r*0.55,  -r*0.22),
	])
	draw_polygon(pts, _c(pts.size(), fl))
	var b := PackedVector2Array(pts); b.append(pts[0])
	for gi in range(3, 0, -1):
		draw_polyline(b, Color(ic.r, ic.g, ic.b, 0.12*p/float(gi)), float(gi)*3.0)
	draw_polyline(b, ic, 2.0)
	# Reflexo interno
	draw_line(pts[0], pts[2], Color(ic.r, ic.g, ic.b, 0.28), 1.5)
	draw_line(pts[0], pts[3], Color(ic.r, ic.g, ic.b, 0.28), 1.5)
	draw_circle(cx + Vector2(-r*0.18, -r*0.38),
			r*0.10 * (sin(p*3.0)*0.08 + 0.92), Color(1.0, 1.0, 1.0, 0.70))


func _icon_tita(cx: Vector2, r: float, ic: Color, fl: Color) -> void:
	# tita — punho fechado
	# Dedos (4 retângulos)
	for i in range(4):
		var fx : float = cx.x + float(i - 1.5) * r * 0.38
		draw_rect(Rect2(fx - r*0.15, cx.y - r*0.86, r*0.30, r*0.60), fl, true)
		draw_rect(Rect2(fx - r*0.15, cx.y - r*0.86, r*0.30, r*0.60), ic, false, 1.5)
	# Palma
	draw_rect(Rect2(cx.x - r*0.72, cx.y - r*0.28, r*1.44, r*0.62), fl, true)
	draw_rect(Rect2(cx.x - r*0.72, cx.y - r*0.28, r*1.44, r*0.62), ic, false, 2.0)
	# Polegar
	draw_rect(Rect2(cx.x + r*0.56, cx.y - r*0.62, r*0.30, r*0.40), fl, true)
	draw_rect(Rect2(cx.x + r*0.56, cx.y - r*0.62, r*0.30, r*0.40), ic, false, 1.5)
	# Base do punho
	draw_rect(Rect2(cx.x - r*0.72, cx.y + r*0.34, r*1.44, r*0.50), fl, true)
	draw_rect(Rect2(cx.x - r*0.72, cx.y + r*0.34, r*1.44, r*0.50), ic, false, 1.8)


func _icon_relamp(cx: Vector2, r: float, ic: Color, fl: Color, p: float) -> void:
	# relâmpago sombrio — raio + gota de veneno
	var pts := PackedVector2Array([
		cx + Vector2( r*0.18, -r*0.90),
		cx + Vector2(-r*0.06, -r*0.08),
		cx + Vector2( r*0.24, -r*0.08),
		cx + Vector2(-r*0.18,  r*0.90),
		cx + Vector2( r*0.06,  r*0.08),
		cx + Vector2(-r*0.24,  r*0.08),
	])
	draw_polygon(pts, _c(pts.size(), fl))
	var b := PackedVector2Array(pts); b.append(pts[0]); draw_polyline(b, ic, 2.0)
	# Gota de veneno pulsante no canto
	var gp : float = sin(p*2.8)*0.12 + 0.88
	draw_circle(cx + Vector2(r*0.58, -r*0.58), r*0.18*gp,
			Color(0.30, 0.90, 0.30, 0.85))
	draw_arc(cx + Vector2(r*0.58, -r*0.58), r*0.18, 0.0, TAU, 10,
			Color(0.12, 0.98, 0.35, 0.70*p), 1.5)


func _icon_canhao_g(cx: Vector2, r: float, ic: Color, fl: Color) -> void:
	# canhão glacial — cano + floco de neve
	draw_rect(Rect2(cx.x - r*0.78, cx.y - r*0.20, r*1.20, r*0.40), fl, true)
	draw_rect(Rect2(cx.x - r*0.78, cx.y - r*0.20, r*1.20, r*0.40), ic, false, 1.8)
	draw_circle(cx + Vector2(-r*0.78, 0.0), r*0.24, fl)
	draw_arc(cx + Vector2(-r*0.78, 0.0), r*0.24, 0.0, TAU, 12, ic, 1.8)
	# Floco de gelo na boca do cano
	var fc : Vector2 = cx + Vector2(r*0.50, 0.0)
	for i in range(6):
		var a : float = float(i) * TAU / 6.0
		draw_line(fc, fc + Vector2(cos(a), sin(a)) * r*0.28, ic, 1.8)
		var mp : Vector2 = fc + Vector2(cos(a), sin(a)) * r*0.18
		draw_line(mp, mp + Vector2(cos(a + PI*0.5), sin(a + PI*0.5)) * r*0.10, ic, 1.2)
		draw_line(mp, mp + Vector2(cos(a - PI*0.5), sin(a - PI*0.5)) * r*0.10, ic, 1.2)


# ── Especiais ─────────────────────────────────────────────────────────────────

func _icon_cazador(cx: Vector2, r: float, ic: Color, fl: Color) -> void:
	# cazador — mira telescópica (crosshair)
	draw_arc(cx, r*0.62, 0.0, TAU, 32, ic, 2.2)
	draw_arc(cx, r*0.30, 0.0, TAU, 18, ic, 1.5)
	# Linhas da mira
	for a in [0.0, PI*0.5, PI, PI*1.5]:
		var inner : Vector2 = cx + Vector2(cos(a), sin(a)) * r*0.38
		var outer : Vector2 = cx + Vector2(cos(a), sin(a)) * r*0.85
		draw_line(inner, outer, ic, 2.0)
	# Ponto central
	draw_circle(cx, r*0.08, ic)
	# Linhas finas diagonais
	for a in [PI*0.25, PI*0.75, PI*1.25, PI*1.75]:
		var va : Vector2 = cx + Vector2(cos(a), sin(a)) * r*0.62
		var vb : Vector2 = cx + Vector2(cos(a), sin(a)) * r*0.80
		draw_line(va, vb, Color(ic.r, ic.g, ic.b, 0.45), 1.2)


func _icon_exter(cx: Vector2, r: float, ic: Color, fl: Color, p: float) -> void:
	# exterminador — caveira com × nos olhos
	draw_circle(cx + Vector2(0, -r*0.10), r*0.55, fl)
	draw_arc(cx + Vector2(0, -r*0.10), r*0.55, 0.0, TAU, 26, ic, 2.0)
	var jaw2 := PackedVector2Array([
		cx + Vector2(-r*0.34, r*0.30),
		cx + Vector2(-r*0.34, r*0.76),
		cx + Vector2( r*0.34, r*0.76),
		cx + Vector2( r*0.34, r*0.30),
	])
	draw_polygon(jaw2, _c(jaw2.size(), fl))
	var jb2 := PackedVector2Array(jaw2); jb2.append(jaw2[0]); draw_polyline(jb2, ic, 1.8)
	for t in [-1, 0, 1]:
		draw_line(cx + Vector2(float(t)*r*0.22, r*0.50),
				  cx + Vector2(float(t)*r*0.22, r*0.76),
				  Color(0.04, 0.04, 0.07, 1.0), 3.5)
	# × nos olhos (em vez de buraco redondo)
	for sx in [-1.0, 1.0]:
		var ec : Vector2 = cx + Vector2(sx*r*0.22, -r*0.20)
		var es : float = r * 0.12
		draw_line(ec + Vector2(-es, -es), ec + Vector2(es, es), ic, 2.0)
		draw_line(ec + Vector2( es, -es), ec + Vector2(-es, es), ic, 2.0)
	# Brilho pulsante
	draw_circle(cx + Vector2(r*0.52, -r*0.68),
			r*0.10 * (sin(p*2.5)*0.12 + 0.88), Color(ic.r, ic.g, ic.b, 0.75))


func _icon_anti_t(cx: Vector2, r: float, ic: Color, fl: Color) -> void:
	# anti-tanque — escudo com racha diagonal
	var pts := PackedVector2Array([
		cx + Vector2(0,       -r*0.95),
		cx + Vector2( r*0.70, -r*0.38),
		cx + Vector2( r*0.52,  r*0.46),
		cx + Vector2(0,        r*0.86),
		cx + Vector2(-r*0.52,  r*0.46),
		cx + Vector2(-r*0.70, -r*0.38),
	])
	draw_polygon(pts, _c(pts.size(), fl))
	var b := PackedVector2Array(pts); b.append(pts[0]); draw_polyline(b, ic, 2.2)
	# Racha diagonal (dano penetrando)
	draw_line(cx + Vector2(-r*0.28, -r*0.55), cx + Vector2(r*0.22, r*0.48),
			Color(1.0, 0.30, 0.10, 0.90), 3.5)
	draw_line(cx + Vector2(-r*0.20, -r*0.50), cx + Vector2(r*0.14, r*0.44),
			Color(1.0, 0.70, 0.40, 0.55), 1.5)


func _icon_purif(cx: Vector2, r: float, ic: Color, fl: Color, p: float) -> void:
	# purificador — cruz radiante de luz sagrada
	var arm : float = r * 0.80
	var thick : float = r * 0.22
	# Corpo da cruz
	draw_rect(Rect2(cx.x - thick, cx.y - arm, thick*2.0, arm*2.0), fl, true)
	draw_rect(Rect2(cx.x - arm,   cx.y - thick, arm*2.0, thick*2.0), fl, true)
	draw_rect(Rect2(cx.x - thick, cx.y - arm, thick*2.0, arm*2.0), ic, false, 2.0)
	draw_rect(Rect2(cx.x - arm,   cx.y - thick, arm*2.0, thick*2.0), ic, false, 2.0)
	# Raios de luz pulsantes nos 4 ângulos diagonais
	var gp2 : float = sin(p*2.0)*0.20 + 0.80
	for i in range(4):
		var a : float = float(i) * TAU / 4.0 + PI / 4.0
		draw_line(cx + Vector2(cos(a), sin(a)) * arm*0.54,
				  cx + Vector2(cos(a), sin(a)) * arm*0.90,
				  Color(ic.r + 0.10, ic.g + 0.10, ic.b, 0.60*gp2), 2.5)
	draw_circle(cx, r*0.14, Color(1.0, 1.0, 1.0, 0.88*(sin(p*2.5)*0.12+0.88)))


# ── Legado ────────────────────────────────────────────────────────────────────

func _icon_veteran(cx: Vector2, r: float, ic: Color, fl: Color, p: float) -> void:
	# veterano — medalha com estrela e fita
	# Fita (duas tiras diagonais)
	for s in [-1.0, 1.0]:
		var rx : float = s * r * 0.26
		draw_rect(Rect2(cx.x + rx - r*0.10, cx.y - r*0.90,
				r*0.20, r*0.48), fl, true)
		draw_rect(Rect2(cx.x + rx - r*0.10, cx.y - r*0.90,
				r*0.20, r*0.48), ic, false, 1.5)
	# Medalha (círculo)
	draw_circle(cx + Vector2(0, r*0.26), r*0.56, fl)
	draw_arc(cx + Vector2(0, r*0.26), r*0.56, 0.0, TAU, 28, ic, 2.2)
	# Estrela de 5 pontas na medalha
	var mc : Vector2 = cx + Vector2(0, r*0.26)
	var sp := PackedVector2Array()
	for i in range(10):
		var a   : float = float(i) * TAU / 10.0 - PI/2.0
		var rad : float = r*0.36 if i % 2 == 0 else r*0.16
		sp.append(mc + Vector2(cos(a), sin(a)) * rad)
	draw_polygon(sp, _c(sp.size(), Color(ic.r, ic.g, ic.b, 0.80*(sin(p*1.8)*0.10+0.90))))
	var sb := PackedVector2Array(sp); sb.append(sp[0])
	draw_polyline(sb, Color(1.0, 1.0, 0.70, 0.70), 1.5)


func _icon_genoci(cx: Vector2, r: float, ic: Color, fl: Color) -> void:
	# genocida — pilha de 3 caveiras
	var skull_positions : Array = [
		Vector2(0, r*0.42),
		Vector2(-r*0.38, -r*0.10),
		Vector2( r*0.38, -r*0.10),
	]
	for sp2 in skull_positions:
		var sc : Vector2 = cx + (sp2 as Vector2)
		var sr : float = r * 0.30
		draw_circle(sc + Vector2(0, -sr*0.10), sr, fl)
		draw_arc(sc + Vector2(0, -sr*0.10), sr, 0.0, TAU, 18, ic, 1.5)
		# Olho esquerdo
		draw_circle(sc + Vector2(-sr*0.32, -sr*0.10), sr*0.14,
				Color(0.04, 0.04, 0.07, 1.0))
		# Olho direito
		draw_circle(sc + Vector2( sr*0.32, -sr*0.10), sr*0.14,
				Color(0.04, 0.04, 0.07, 1.0))
		# Boca
		draw_line(sc + Vector2(-sr*0.35, sr*0.38), sc + Vector2(sr*0.35, sr*0.38),
				ic, 1.5)


func _icon_sobrev(cx: Vector2, r: float, ic: Color, fl: Color, p: float) -> void:
	# sobrevivente — onda estilizada com escudo no centro
	# Onda de fundo
	var wave := PackedVector2Array()
	var wsteps := 24
	for i in range(wsteps):
		var t : float = float(i) / float(wsteps - 1)
		var wx : float = cx.x - r*0.88 + t * r*1.76
		var wy : float = cx.y + r*0.30 + sin(t * TAU + p * 0.60) * r * 0.26
		wave.append(Vector2(wx, wy))
	draw_polyline(wave, Color(ic.r, ic.g, ic.b, 0.55), 2.5)
	# Segunda onda (ligeiramente offset)
	var wave2 := PackedVector2Array()
	for i in range(wsteps):
		var t : float = float(i) / float(wsteps - 1)
		var wx : float = cx.x - r*0.88 + t * r*1.76
		var wy : float = cx.y + r*0.54 + sin(t * TAU + p * 0.60 + PI*0.4) * r * 0.18
		wave2.append(Vector2(wx, wy))
	draw_polyline(wave2, Color(ic.r, ic.g, ic.b, 0.32), 1.8)
	# Escudo central pequeno
	var spts := PackedVector2Array([
		cx + Vector2(0,       -r*0.76),
		cx + Vector2( r*0.44, -r*0.30),
		cx + Vector2( r*0.32,  r*0.16),
		cx + Vector2(0,        r*0.36),
		cx + Vector2(-r*0.32,  r*0.16),
		cx + Vector2(-r*0.44, -r*0.30),
	])
	draw_polygon(spts, _c(spts.size(), fl))
	var sb2 := PackedVector2Array(spts); sb2.append(spts[0])
	draw_polyline(sb2, ic, 2.0)
	draw_line(cx + Vector2(0, -r*0.42), cx + Vector2(0, r*0.16), ic, 1.8)
	draw_line(cx + Vector2(-r*0.22, -r*0.08), cx + Vector2(r*0.22, -r*0.08), ic, 1.8)
