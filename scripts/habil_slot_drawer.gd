extends Node2D

const R : float = 40.0   # raio do slot

# Dados dos slots de habilidade (um por habilidade)
var slot_cors    : Array = []   # Color
var slot_nomes   : Array = []   # String
var slot_cargas  : Array = []   # int
var slot_cd_prog : Array = []   # float 0.0 = recargando, 1.0 = pronto
var slot_cd_secs : Array = []   # float segundos restantes (para exibição)
var slot_centers : Array = []   # Vector2

# Slot do Hacker
var hk_ativo   : bool    = false
var hk_center  : Vector2 = Vector2.ZERO
var hk_prog    : float   = 1.0
var hk_analise : bool    = false
var hk_boost   : float   = 0.0
var hk_cd_secs : float   = 0.0
var hk_cor     : Color   = Color(0.2, 1.0, 0.5)
var hk_nome    : String  = "HACK"
var hk_dur     : float   = 15.0
var hk_tex     : Texture2D = null


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	var font := ThemeDB.fallback_font
	for i in slot_centers.size():
		_slot(slot_centers[i], slot_cors[i], slot_nomes[i],
			slot_cargas[i], slot_cd_prog[i], slot_cd_secs[i], font)
	if hk_ativo:
		_hacker(hk_center, hk_prog, hk_analise, hk_boost, hk_cd_secs, font, hk_cor, hk_nome, hk_dur)


func _slot(c: Vector2, cor: Color, nome: String, cargas: int,
		prog: float, cd_sec: float, font: Font) -> void:
	var active : bool  = cargas > 0 and prog >= 1.0
	var dim    : float = lerpf(0.45, 1.0, prog)

	# Sombra
	draw_circle(c, R + 3.0, Color(0.0, 0.0, 0.0, 0.50))

	# Fundo
	draw_circle(c, R, Color(cor.r * 0.12 * dim, cor.g * 0.12 * dim, cor.b * 0.12 * dim, 0.95))

	# Setor escuro do cooldown (relógio)
	if prog < 0.998:
		var sweep := TAU * (1.0 - prog)
		_setor(c, R, -PI * 0.5, -PI * 0.5 + sweep, Color(0.0, 0.0, 0.0, 0.72))

	# Anel externo
	draw_arc(c, R,       0.0, TAU, 80, Color(cor.r, cor.g, cor.b, 0.90 * dim), 4.0, true)
	# Anel interno sutil
	draw_arc(c, R - 6.0, 0.0, TAU, 80, Color(cor.r, cor.g, cor.b, 0.18 * dim), 1.5, true)

	# Pips de cargas (3 pontos na parte inferior do círculo)
	for j in 3:
		var a  := PI * 0.5 + (float(j) - 1.0) * 0.44
		var dp := c + Vector2(cos(a), sin(a)) * (R - 9.0)
		if j < cargas:
			draw_circle(dp, 4.5, Color(cor.r, cor.g, cor.b, 0.95))
			draw_circle(dp, 2.2, Color(1.0, 1.0, 1.0, 0.50))
		else:
			draw_circle(dp, 4.5, Color(0.15, 0.15, 0.18, 0.90))

	# Texto central: segundos quando em recarga, nome quando pronto
	var tw := R * 1.6
	if prog < 0.998 and cd_sec > 0.0:
		var sec_str : String = "%.0f" % cd_sec if cd_sec >= 1.0 else "%.1f" % cd_sec
		draw_string(font, c + Vector2(-tw * 0.5, 6.0), sec_str,
			HORIZONTAL_ALIGNMENT_CENTER, tw, 18,
			Color(0.85, 0.85, 0.90, 0.90))
	else:
		draw_string(font, c + Vector2(-tw * 0.5, 6.0), nome,
			HORIZONTAL_ALIGNMENT_CENTER, tw, 14,
			Color(cor.r + 0.3, cor.g + 0.3, cor.b + 0.3, dim) if active
			else Color(0.45, 0.45, 0.50, 0.65))


func _hacker(c: Vector2, prog: float, em_analise: bool, boost_prog: float,
		cd_sec: float, font: Font, cor: Color = Color(0.2,1.0,0.5), nome: String = "HACK", dur: float = 15.0) -> void:
	var dim   := lerpf(0.45, 1.0, prog)
	var tw    := R * 1.6

	# Sombra
	draw_circle(c, R + 3.0, Color(0.0, 0.0, 0.0, 0.50))

	# Fundo
	draw_circle(c, R, Color(cor.r * 0.08 * dim, cor.g * 0.08 * dim, cor.b * 0.08 * dim, 0.95))

	if em_analise and boost_prog > 0.0:
		var end_a := -PI * 0.5 + TAU * boost_prog
		draw_arc(c, R - 3.0, -PI * 0.5, end_a, 80,
			Color(cor.r, cor.g, cor.b, 0.90), 5.0, true)
	elif prog < 0.998:
		_setor(c, R, -PI * 0.5, -PI * 0.5 + TAU * (1.0 - prog), Color(0.0, 0.0, 0.0, 0.72))

	# Anel externo
	draw_arc(c, R,       0.0, TAU, 80, Color(cor.r, cor.g, cor.b, 0.90 * dim), 4.0, true)
	draw_arc(c, R - 6.0, 0.0, TAU, 80, Color(cor.r, cor.g, cor.b, 0.18 * dim), 1.5, true)

	# Texto central
	var lbl : String
	if em_analise:
		lbl = "%.0fs" % (boost_prog * dur) if boost_prog > 0.0 else "..."
	elif prog < 0.998 and cd_sec > 0.0:
		lbl = "%.0f" % cd_sec if cd_sec >= 1.0 else "%.1f" % cd_sec
	else:
		lbl = nome
	if hk_tex != null and not em_analise and cd_sec <= 0.0:
		draw_texture_rect(hk_tex, Rect2(c.x - 23.0, c.y - 25.0, 46.0, 46.0), false, Color(1.0, 1.0, 1.0, 0.94 * dim))
		draw_string(font, c + Vector2(-tw * 0.5, 22.0), "CMD",
			HORIZONTAL_ALIGNMENT_CENTER, tw, 9,
			Color(cor.r + 0.15, cor.g + 0.15, cor.b + 0.15, 0.72 * dim))
	else:
		draw_string(font, c + Vector2(-tw * 0.5, 6.0), lbl,
			HORIZONTAL_ALIGNMENT_CENTER, tw, 14,
			Color(cor.r + 0.1, cor.g + 0.1, cor.b + 0.1, dim))

	# Label "IA" pequeno acima
	draw_string(font, c + Vector2(-tw * 0.5, -R + 6.0), "CMD",
		HORIZONTAL_ALIGNMENT_CENTER, tw, 10,
		Color(cor.r, cor.g, cor.b, 0.55 * dim))


func _setor(c: Vector2, r: float, a_ini: float, a_fim: float, cor: Color) -> void:
	if abs(a_fim - a_ini) < 0.005: return
	var pts  := PackedVector2Array()
	pts.append(c)
	var steps : int = maxi(4, int(abs(a_fim - a_ini) / TAU * 72) + 1)
	for i in range(steps + 1):
		var a : float = lerpf(a_ini, a_fim, float(i) / float(steps))
		pts.append(c + Vector2(cos(a), sin(a)) * r)
	draw_colored_polygon(pts, cor)
