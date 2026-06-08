extends Node2D

var _t         : float = 0.0
var _fase      : int   = 0
var _alpha     : float = 0.0
var _progresso : float = 0.0
var _img       : Texture2D = null
var _particulas : Array = []

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
		var vp2   := get_viewport().get_visible_rect().size
		var bar_y : float = vp2.y - 52.0
		var bar_x0: float = 60.0
		var bar_w : float = vp2.x - 120.0
		var mob_x : float = bar_x0 + bar_w * _progresso
		_particulas.append({
			"x": mob_x + randf_range(-6.0, 6.0),
			"y": bar_y + randf_range(-8.0, 8.0),
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

	# ── Barra de loading ─────────────────────────────────────────────────────
	var bar_h  : float = 14.0
	var bar_y  : float = H - 52.0
	var bar_x0 : float = 60.0
	var bar_w  : float = W - 120.0
	var filled : float = bar_w * _progresso

	draw_rect(Rect2(bar_x0, bar_y, bar_w, bar_h),
		Color(0.06, 0.08, 0.16, 0.88 * _alpha))
	draw_rect(Rect2(bar_x0, bar_y, bar_w, bar_h),
		Color(0.2, 0.4, 0.7, 0.55 * _alpha), false, 1.5)

	var faixas : int = 24
	for fi in range(faixas):
		var fx : float = bar_x0 + filled * float(fi) / float(faixas)
		var fw : float = filled / float(faixas) + 1.0
		var t  : float = float(fi) / float(faixas - 1)
		draw_rect(Rect2(fx, bar_y, fw, bar_h),
			Color(lerp(0.1, 0.4, t), lerp(0.4, 0.85, t), 1.0, _alpha * 0.92))

	draw_rect(Rect2(bar_x0, bar_y, filled, bar_h * 0.4),
		Color(1.0, 1.0, 1.0, 0.18 * _alpha))

	# ── Partículas ────────────────────────────────────────────────────────────
	for p in _particulas:
		var life : float = p["life"] as float
		draw_circle(Vector2(p["x"] as float, p["y"] as float),
			2.2 * life, Color(0.4, 0.75, 1.0, life * _alpha))

	# ── Torre (direita) ───────────────────────────────────────────────────────
	var ty : float = bar_y + bar_h * 0.5
	var tx : float = bar_x0 + bar_w + 26.0
	var tr : float = 14.0
	var tpts := PackedVector2Array()
	for i in range(6):
		var a := float(i) * TAU / 6.0 + PI / 6.0
		tpts.append(Vector2(tx + cos(a) * tr, ty + sin(a) * tr))
	draw_polygon(tpts, _fill(tpts.size(), Color(0.0, 0.25, 0.75, _alpha)))
	var tborda := PackedVector2Array(tpts); tborda.append(tpts[0])
	draw_polyline(tborda, Color(0.35, 0.72, 1.0, _alpha), 1.8)
	var cdir := Vector2(-1.0, 0.0)
	var clat := cdir.rotated(PI * 0.5) * tr * 0.20
	var ctip := Vector2(tx, ty) + cdir * tr * 1.15
	var gun  := PackedVector2Array([
		Vector2(tx, ty) - clat, Vector2(tx, ty) + clat,
		ctip + clat * 0.5, ctip - clat * 0.5])
	draw_polygon(gun, _fill(gun.size(), Color(0.45, 0.82, 1.0, _alpha)))

	# ── Mob (esquerda → direita) ──────────────────────────────────────────────
	if _progresso < 0.98:
		var mx : float = bar_x0 + bar_w * _progresso
		var mr : float = 11.0
		for gi in range(3, 0, -1):
			draw_circle(Vector2(mx, ty), mr + float(gi) * 3.0,
				Color(1.0, 0.2, 0.1, 0.07 * _alpha / float(gi)))
		draw_circle(Vector2(mx, ty), mr, Color(0.85, 0.12, 0.12, 0.92 * _alpha))
		draw_circle(Vector2(mx - mr*0.28, ty - mr*0.15), mr*0.22,
			Color(1.0, 1.0, 1.0, _alpha))
		draw_circle(Vector2(mx + mr*0.28, ty - mr*0.15), mr*0.22,
			Color(1.0, 1.0, 1.0, _alpha))
		draw_arc(Vector2(mx, ty), mr, 0.0, TAU, 24,
			Color(1.0, 0.5, 0.5, _alpha), 1.5)

	# ── Percentual ────────────────────────────────────────────────────────────
	var font : Font = ThemeDB.fallback_font
	if font:
		var pct : String = "%d%%" % int(_progresso * 100.0)
		var fsz : int    = 16
		var tw  : float  = font.get_string_size(pct, HORIZONTAL_ALIGNMENT_LEFT, -1, fsz).x
		draw_string(font, Vector2(bar_x0 + bar_w * 0.5 - tw * 0.5, bar_y + bar_h + 20.0),
			pct, HORIZONTAL_ALIGNMENT_LEFT, -1, fsz, Color(0.6, 0.85, 1.0, _alpha * 0.85))


func _fill(n: int, c: Color) -> PackedColorArray:
	var a := PackedColorArray()
	for i in range(n): a.append(c)
	return a


func _ir_menu() -> void:
	if _fase == 3:
		return
	_fase = 3
	get_tree().change_scene_to_file("res://scenes/Menu.tscn")
