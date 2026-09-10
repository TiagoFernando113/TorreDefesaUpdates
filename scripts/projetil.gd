extends Node2D

var target      = null
var damage      := 0.0
var speed       := 440.0
var pulse       := 0.0
var trail       : Array[Vector2] = []
var morto       := false
var origin_pos  : Vector2 = Vector2.ZERO
var max_travel  : float = 0.0

var pierce_left  := 0
var pierce_hit   := 0
var hit_targets  : Array = []
var splash_radius := 0.0
var splash_damage := 0.0

# Extras
var chain_count  := 0     # Corrente Elétrica: salta para N inimigos extras
var ricochete_left := 0   # Ricochete: projétil quica para N alvos após o impacto
var veneno_dps   := 0.0   # Veneno Arcano: dano por segundo aplicado ao alvo
var veneno_dur   := 0.0
var armadura_inv := false  # Armadura Invertida: +60% dano em alvo abaixo de 30% HP
var is_bencao    := false  # Bênção de Energia: visual especial
var fissura_ativa:= false  # Fissura Venenosa: envenena mobs em 70px ao acertar
var is_critico   := false  # Golpe Crítico: trilha laranja
var queimadura   := false  # P5 Lenda do Canhão / Brasa: aplica queimadura no alvo
var fogo_fusao   := false  # FUSÃO Bolas de Fogo: explode em área flamejante
var is_missil    := false  # Lança-Mísseis: desenha como foguete com rastro
var canhao_g_gelo := false  # Canhão Glacial: congela o alvo ao acertar
# Qual ARMA disparou. So' muda o desenho -- nenhuma regra de dano le' este campo.
# Antes o projetil nao sabia disso, e 7 das 12 armas cuspiam a mesma bolinha
# amarela: a torre tinha silhueta propria (luneta, tambor, leque) e o TIRO nao.
var arma         := "padrao"
var mobs_group   := "mobs"
var low_fx       := false
var free_dir     : Vector2 = Vector2.ZERO  # disparo manual / perfuração: viaja nesta direção
var _ultima_dir  : Vector2 = Vector2.ZERO  # direção do último movimento teleguiado

# Multiplicadores de dano por ordem de impacto (100%, 30%, 20%, 10%)
const PIERCE_MULT : Array = [1.0, 0.3, 0.2, 0.1]


func _get_float_prop(obj: Object, prop: String, fallback: float = 0.0) -> float:
	if not is_instance_valid(obj):
		return fallback
	var v = obj.get(prop)
	if v == null:
		return fallback
	return float(v)


func _target_pos(alvo: Node) -> Vector2:
	if alvo and is_instance_valid(alvo) and alvo.has_method("get_target_position"):
		return alvo.call("get_target_position") as Vector2
	return (alvo as Node2D).global_position


func setup(alvo: Node, dano: float, pierce: int = 0, speed_bonus: float = 0.0,
		splash_r: float = 0.0, splash_dmg: float = 0.0, extras: Dictionary = {}) -> void:
	target        = alvo
	damage        = dano
	pierce_left   = pierce
	speed        += speed_bonus
	splash_radius = splash_r
	splash_damage = splash_dmg
	chain_count   = extras.get("chain",          0)     as int
	ricochete_left = extras.get("ricochete",     0)     as int
	veneno_dps    = extras.get("veneno_dps",     0.0)   as float
	veneno_dur    = extras.get("veneno_dur",     0.0)   as float
	armadura_inv  = extras.get("armadura_inv",   false) as bool
	is_bencao     = extras.get("is_bencao",      false) as bool
	fissura_ativa = extras.get("fissura",        false) as bool
	is_critico    = extras.get("is_critico",     false) as bool
	queimadura    = extras.get("queimadura",     false) as bool
	fogo_fusao    = extras.get("fogo_fusao",     false) as bool
	canhao_g_gelo = extras.get("canhao_g_gelo", false) as bool
	is_missil     = extras.get("is_missil",      false) as bool
	arma          = extras.get("arma",       "padrao") as String
	mobs_group    = extras.get("mobs_group",    "mobs") as String
	low_fx        = extras.get("low_fx",        false) as bool
	origin_pos    = global_position
	max_travel    = extras.get("max_travel", 0.0) as float


func setup_dir(dir: Vector2, dano: float, pierce: int = 0, speed_bonus: float = 0.0,
		splash_r: float = 0.0, splash_dmg: float = 0.0, extras: Dictionary = {}) -> void:
	free_dir      = dir.normalized()
	damage        = dano
	pierce_left   = pierce
	speed        += speed_bonus
	splash_radius = splash_r
	splash_damage = splash_dmg
	veneno_dps    = extras.get("veneno_dps",    0.0)   as float
	veneno_dur    = extras.get("veneno_dur",    0.0)   as float
	armadura_inv  = extras.get("armadura_inv",  false) as bool
	fissura_ativa = extras.get("fissura",       false) as bool
	is_critico    = extras.get("is_critico",    false) as bool
	queimadura    = extras.get("queimadura",    false) as bool
	canhao_g_gelo = extras.get("canhao_g_gelo", false) as bool
	arma          = extras.get("arma",      "padrao") as String
	mobs_group    = extras.get("mobs_group",   "mobs") as String
	low_fx        = extras.get("low_fx",        false) as bool
	origin_pos    = global_position
	max_travel    = extras.get("max_travel",    0.0)   as float


func _process(delta: float) -> void:
	if morto:
		queue_free()
		return

	pulse += delta * 12.0
	if max_travel > 0.0 and global_position.distance_to(origin_pos) > max_travel:
		queue_free()
		return

	trail.append(global_position)
	var trail_max : int = 4 if low_fx else 9
	if trail.size() > trail_max:
		trail.pop_front()

	# ── Modo de disparo direcional livre (mira manual) ────────────────────────
	if free_dir != Vector2.ZERO:
		global_position += free_dir * speed * delta
		for mob in get_tree().get_nodes_in_group(mobs_group):
			if not is_instance_valid(mob) or (mob.get("morto") as bool): continue
			if mob in hit_targets: continue
			if global_position.distance_to((mob as Node2D).global_position) < 22.0:
				var mult   : float = PIERCE_MULT[mini(pierce_hit, PIERCE_MULT.size() - 1)]
				var dano_h : float = damage * mult
				if armadura_inv:
					var mhp : float = _get_float_prop(mob, "max_hp")
					var chp : float = _get_float_prop(mob, "hp")
					if mhp > 0.0 and chp / mhp < 0.30: dano_h *= 1.60
				if Salvar.talento_ativo("g1") and _get_float_prop(mob, "gelo_slow") > 0.0:
					dano_h *= 1.15
				mob.receber_dano(dano_h, false, is_critico)
				if queimadura:
					mob.set("queima_dps",   maxf(_get_float_prop(mob, "queima_dps"),   10.0))
					mob.set("queima_timer", maxf(_get_float_prop(mob, "queima_timer"), 2.0))
				if canhao_g_gelo: mob.set("gelo_slow", 1.0)
				hit_targets.append(mob)
				pierce_hit += 1
				if pierce_left <= 0:
					morto = true
					return
				pierce_left -= 1
		return

	if not is_instance_valid(target):
		# Alvo morreu antes do impacto: se já tinha direção, segue reto
		# (perfuração não vira atrás de outro alvo).
		if pierce_left > 0 and _ultima_dir != Vector2.ZERO:
			free_dir = _ultima_dir
			target = null
			return
		queue_free()
		return

	var alvo_pos := _target_pos(target)
	if max_travel > 0.0 and target.is_in_group("boss_dante") and origin_pos.distance_to(alvo_pos) > max_travel + 8.0:
		queue_free()
		return
	var dir: Vector2 = (alvo_pos - global_position).normalized()
	_ultima_dir = dir
	global_position += dir * speed * delta

	if global_position.distance_to(alvo_pos) < 14.0:
		if is_instance_valid(target) and target.has_method("receber_dano") and not (target in hit_targets):
			var mult      : float = PIERCE_MULT[min(pierce_hit, PIERCE_MULT.size() - 1)]
			var dano_hit  : float = damage * mult
			# Armadura Invertida: +60% em alvos com <30% HP
			if armadura_inv:
				var mhp : float = _get_float_prop(target, "max_hp")
				var chp : float = _get_float_prop(target, "hp")
				if mhp > 0.0 and chp / mhp < 0.30:
					dano_hit *= 1.60
			# G1 — Vantagem Glacial: +15% dano em mobs com gelo
			if Salvar.talento_ativo("g1") and _get_float_prop(target, "gelo_slow") > 0.0:
				dano_hit *= 1.15
			target.receber_dano(dano_hit, false, is_critico)
			# P5 — Lenda do Canhão: queimadura 10/s por 2s
			if queimadura:
				target.set("queima_dps",   maxf(_get_float_prop(target, "queima_dps"), 10.0))
				target.set("queima_timer", maxf(_get_float_prop(target, "queima_timer"), 2.0))
			# Canhão Glacial: gelo total (paralisia ~0.5s)
			if canhao_g_gelo:
				target.set("gelo_slow", 1.0)
			hit_targets.append(target)
			pierce_hit += 1
			if is_critico:
				Som.critico()
			elif veneno_dps > 0.0:
				Som.veneno_impacto()
			else:
				Som.impacto()
			# Veneno Arcano
			if veneno_dps > 0.0 and veneno_dur > 0.0:
				target.set("veneno_dps",   maxf(_get_float_prop(target, "veneno_dps"), veneno_dps))
				target.set("veneno_timer", veneno_dur)
			# Corrente Elétrica
			if chain_count > 0:
				_chain_hit(alvo_pos, chain_count)
			if splash_radius > 0.0:
				_splash_at(alvo_pos)
			# Fissura Venenosa: envenena mobs em 70px ao redor do impacto
			if fissura_ativa:
				_fissura_at(alvo_pos)
			# FUSÃO Bolas de Fogo: explode em área flamejante
			if fogo_fusao:
				_explosao_fogo_at(alvo_pos)

		if pierce_left > 0:
			pierce_left -= 1
			# Perfuração REAL: atravessa em linha reta na direção atual e fura
			# quem cruzar o caminho (o modo free_dir cuida dos próximos hits).
			# (antes: virava pro mob mais próximo = ricochete teleguiado)
			free_dir = _ultima_dir if _ultima_dir != Vector2.ZERO else (alvo_pos - origin_pos).normalized()
			target = null
		elif ricochete_left > 0:
			# Ricochete: quica para o mob mais próximo (não atingido).
			# Decaimento próprio suave (70%/quique); reseta pierce_hit para
			# não sofrer o multiplicador agressivo de perfuração.
			var proximo = _achar_proximo_alvo()
			if proximo:
				ricochete_left -= 1
				damage *= 0.70
				pierce_hit = 0
				target = proximo
			else:
				morto = true
		else:
			morto = true

	if not low_fx or Engine.get_process_frames() % 2 == 0:
		queue_redraw()


func _chain_hit(origin: Vector2, count: int) -> void:
	var mobs   : Array = get_tree().get_nodes_in_group(mobs_group)
	var nearby : Array = []
	for mob in mobs:
		if not is_instance_valid(mob) or mob in hit_targets: continue
		if (mob.get("imune_aoe") as bool): continue   # Fantasma imune
		var d : float = origin.distance_to((mob as Node2D).global_position)
		if d <= 220.0:
			nearby.append([d, mob])
	nearby.sort_custom(func(a, b): return (a[0] as float) < (b[0] as float))
	var hits := 0
	for pair in nearby:
		if hits >= count: break
		var mob = pair[1]
		if is_instance_valid(mob) and mob.has_method("receber_dano"):
			mob.receber_dano(damage, true)
			_spawn_arco_eletrico(origin, (mob as Node2D).global_position)
			hit_targets.append(mob)
			hits += 1


func _spawn_arco_eletrico(de: Vector2, ate: Vector2) -> void:
	# Visual do salto da Corrente Elétrica (antes invisível = "dano fantasma").
	# Carga com guarda + respeita low_fx; se falhar, o dano do chain segue normal.
	if low_fx:
		return
	var scr = load("res://scripts/partida/arco_eletrico.gd")
	if scr == null:
		return
	var parent = get_parent()
	if parent == null or not is_instance_valid(parent):
		return
	var arc = scr.new()
	parent.add_child(arc)
	arc.iniciar(de, ate)


func _splash_at(pos: Vector2) -> void:
	var mobs = get_tree().get_nodes_in_group(mobs_group)
	for mob in mobs:
		if not is_instance_valid(mob) or mob in hit_targets:
			continue
		if (mob.get("imune_aoe") as bool): continue   # Fantasma imune
		if pos.distance_to((mob as Node2D).global_position) <= splash_radius:
			mob.receber_dano(splash_damage, true)


func _fissura_at(pos: Vector2) -> void:
	var mobs = get_tree().get_nodes_in_group(mobs_group)
	for mob in mobs:
		if not is_instance_valid(mob): continue
		if (mob.get("imune_aoe") as bool): continue   # Fantasma imune
		if pos.distance_to((mob as Node2D).global_position) <= 70.0:
			mob.set("veneno_dps",   maxf(mob.get("veneno_dps")   as float, 15.0))
			mob.set("veneno_timer", maxf(mob.get("veneno_timer")  as float, 3.0))


func _explosao_fogo_at(pos: Vector2) -> void:
	# Bolas de Fogo: dano de área + queimadura forte em todos no raio
	const RAIO_FOGO : float = 72.0
	var dano_area : float = damage * 0.55
	for mob in get_tree().get_nodes_in_group(mobs_group):
		if not is_instance_valid(mob): continue
		if (mob.get("imune_aoe") as bool): continue   # Fantasma imune
		if pos.distance_to((mob as Node2D).global_position) <= RAIO_FOGO:
			if mob not in hit_targets:
				mob.receber_dano(dano_area, true)
			mob.set("queima_dps",   maxf(_get_float_prop(mob, "queima_dps"),   15.0))
			mob.set("queima_timer", maxf(_get_float_prop(mob, "queima_timer"), 3.0))


func _achar_proximo_alvo() -> Node:
	# Ricochete só quica para mob PRÓXIMO (raio limitado). Se o mais próximo
	# está além de RICOCHETE_RAIO, retorna null — a bola não atravessa o mapa.
	const RICOCHETE_RAIO : float = 190.0
	var mobs    = get_tree().get_nodes_in_group(mobs_group)
	var melhor  = null
	var min_d   = RICOCHETE_RAIO
	for mob in mobs:
		if not is_instance_valid(mob) or mob in hit_targets:
			continue
		var d = global_position.distance_to(mob.global_position)
		if d < min_d:
			melhor = mob
			min_d  = d
	return melhor


func _draw() -> void:
	var p := sin(pulse) * 0.3 + 0.7
	# Cor/raio da arma UMA vez: o laço do rastro roda até 9x por projétil por
	# quadro, e com a tela cheia de tiros isso vira busca em dicionário à toa.
	var cor_arma : Color = _COR_ARMA.get(arma, _COR_PADRAO) as Color
	var raio_rastro : float = _RAIO_RASTRO.get(arma, 3.5) as float
	# Trail
	for i in range(trail.size()):
		var tp : Vector2 = to_local(trail[i])
		var t  : float   = float(i) / float(trail.size())
		if fogo_fusao:
			# Bola de fogo: rastro flamejante laranja/vermelho
			draw_circle(tp, 7.0 * t, Color(1.0, 0.30, 0.02, t * 0.45))
			draw_circle(tp, 4.5 * t, Color(1.0, 0.62, 0.10, t * 0.60))
		elif is_bencao:
			draw_circle(tp, 5.0 * t, Color(1.0, 0.92, 0.2,  t * 0.55))
		elif veneno_dps > 0.0:
			draw_circle(tp, 3.5 * t, Color(0.12, 0.95, 0.22, t * 0.50))
		elif is_critico:
			draw_circle(tp, 4.0 * t, Color(1.0, 0.45, 0.05,  t * 0.55))
		else:
			# Sem efeito de carta: o rastro toma a cor da ARMA. Os ramos acima
			# vem primeiro de proposito -- veneno/critico/fogo sao informacao de
			# jogo, e ler a arma nao pode custar a leitura do efeito.
			draw_circle(tp, raio_rastro * t,
					Color(cor_arma.r, cor_arma.g, cor_arma.b, t * 0.45))

	# Núcleo
	if is_missil:
		# Foguete: corpo + nariz vermelho + chama atrás, orientado pelo movimento
		var mdir : Vector2 = _ultima_dir
		if mdir == Vector2.ZERO: mdir = free_dir
		if mdir == Vector2.ZERO: mdir = Vector2.RIGHT
		var fwd  : Vector2 = mdir.normalized()
		var perp : Vector2 = Vector2(-fwd.y, fwd.x)
		var fl   : float   = 0.6 + 0.4 * sin(pulse * 5.0)
		# Chama do propulsor (atrás)
		draw_circle(-fwd * 8.0, 4.5 * fl, Color(1.0, 0.5, 0.08, 0.9))
		draw_circle(-fwd * 12.0 * fl, 2.6 * fl, Color(1.0, 0.85, 0.3, 0.85))
		# Corpo
		var corpo := PackedVector2Array([
			fwd * 9.0, fwd * 3.0 + perp * 3.6, -fwd * 7.0 + perp * 3.6,
			-fwd * 7.0 - perp * 3.6, fwd * 3.0 - perp * 3.6,
		])
		var fill := PackedColorArray(); fill.resize(corpo.size()); fill.fill(Color(0.82, 0.84, 0.90))
		draw_polygon(corpo, fill)
		# Nariz vermelho
		var nariz := PackedVector2Array([fwd * 9.0, fwd * 3.0 + perp * 3.6, fwd * 3.0 - perp * 3.6])
		var fn := PackedColorArray(); fn.resize(3); fn.fill(Color(0.9, 0.22, 0.18))
		draw_polygon(nariz, fn)
	elif fogo_fusao:
		var fp : float = sin(pulse * 1.4) * 0.25 + 0.85
		draw_circle(Vector2.ZERO, 12.0, Color(1.0, 0.30, 0.0, 0.30 * fp))
		draw_circle(Vector2.ZERO,  8.0, Color(1.0, 0.55, 0.05, 0.85 * fp))
		draw_circle(Vector2.ZERO,  4.5, Color(1.0, 0.92, 0.55, 1.0))
	elif is_bencao:
		draw_circle(Vector2.ZERO, 11.0, Color(1.0, 0.90, 0.1, 0.35 * p))
		draw_circle(Vector2.ZERO,  7.0, Color(1.0, 1.0,  0.5, 0.85 * p))
		draw_circle(Vector2.ZERO,  3.5, Color(1.0, 1.0,  1.0, 1.0))
	else:
		_desenhar_por_arma(p, cor_arma)


# ── Desenho por arma ─────────────────────────────────────────────────────────
# So' vale quando NENHUM efeito de carta pintou o projetil (missil, bola de
# fogo e bencao mandam mais, porque sao informacao de jogo). Cada arma ganha uma
# silhueta de tiro que combina com a silhueta que a torre ja' tinha.
const _COR_PADRAO : Color = Color(1.0, 0.95, 0.40)
const _COR_ARMA : Dictionary = {
	"sniper":       Color(0.60, 0.85, 1.00),   # bala fria e rapida
	"escopeta":     Color(1.00, 0.60, 0.18),   # chumbo quente
	"metralhadora": Color(1.00, 0.88, 0.30),   # tracante
	"ricochete":    Color(0.35, 1.00, 0.80),   # verde-agua: quica
	"gemea":        Color(0.45, 0.95, 0.85),
	"vortice":      Color(0.80, 0.45, 1.00),
}
const _RAIO_RASTRO : Dictionary = {
	"sniper":       2.2,   # risco fino: le-se velocidade
	"escopeta":     2.0,   # sao 6 de uma vez -- rastro gordo virava borrao
	"metralhadora": 2.4,
	"ricochete":    3.2,
	"gemea":        3.0,
	"vortice":      3.0,
}


func _dir_visual() -> Vector2:
	# Direcao de viagem, para as formas alongadas. Teleguiado usa a ultima
	# direcao real; tiro reto usa a direcao fixa; sem nenhuma das duas, aponta
	# para a direita (nunca deixa a forma colapsar num ponto).
	var d : Vector2 = _ultima_dir
	if d == Vector2.ZERO: d = free_dir
	if d == Vector2.ZERO: return Vector2.RIGHT
	return d.normalized()


func _capsula(fwd: Vector2, perp: Vector2, comp: float, larg: float, cor: Color) -> void:
	var forma := PackedVector2Array([
		fwd * comp, fwd * (comp * 0.35) + perp * larg,
		-fwd * (comp * 0.6) + perp * larg,
		-fwd * (comp * 0.6) - perp * larg, fwd * (comp * 0.35) - perp * larg,
	])
	var fill := PackedColorArray(); fill.resize(forma.size()); fill.fill(cor)
	draw_polygon(forma, fill)


func _desenhar_por_arma(p: float, cor: Color) -> void:
	var fwd : Vector2 = _dir_visual()
	var perp : Vector2 = Vector2(-fwd.y, fwd.x)
	match arma:
		"sniper":
			# Dardo longo e fino: a arma de tiro unico e caro tem que PARECER
			# cara. Brilho na ponta pra ler o sentido da viagem.
			draw_line(-fwd * 9.0, fwd * 11.0, Color(cor.r, cor.g, cor.b, 0.35 * p), 5.0)
			_capsula(fwd, perp, 11.0, 1.9, cor)
			draw_circle(fwd * 9.0, 2.0, Color(1.0, 1.0, 1.0, 1.0))
		"escopeta":
			# Pelota pequena. Sao 6 por disparo: qualquer coisa maior vira massa.
			draw_circle(Vector2.ZERO, 4.0, Color(cor.r, cor.g, cor.b, 0.30 * p))
			draw_circle(Vector2.ZERO, 2.3, Color(1.0, 0.88, 0.62, 1.0))
		"metralhadora":
			# Tracante curto: muitos tiros, cada um discreto.
			draw_line(-fwd * 5.0, fwd * 4.0, Color(cor.r, cor.g, cor.b, 0.55 * p), 3.4)
			draw_circle(fwd * 3.0, 2.1, Color(1.0, 1.0, 0.85, 1.0))
		"ricochete":
			# Anel ao redor da bola = "isto quica". A unica arma comum cuja
			# regra e' invisivel sem um sinal desses.
			draw_circle(Vector2.ZERO, 6.0, Color(cor.r, cor.g, cor.b, 0.25 * p))
			draw_arc(Vector2.ZERO, 5.4, pulse * 3.0, pulse * 3.0 + TAU * 0.72, 14,
					Color(cor.r, cor.g, cor.b, 0.95), 1.6)
			draw_circle(Vector2.ZERO, 3.0, Color(0.90, 1.0, 0.97, 1.0))
		"gemea":
			_capsula(fwd, perp, 8.0, 2.7, cor)
			draw_circle(fwd * 5.0, 1.8, Color(1.0, 1.0, 1.0, 0.95))
		"vortice":
			# Losango girando: combina com o hub de 6 portas radiais da torre.
			var g : float = pulse * 4.0
			var gd : Vector2 = Vector2(cos(g), sin(g))
			var gp : Vector2 = Vector2(-gd.y, gd.x)
			var losango := PackedVector2Array([gd * 5.4, gp * 3.2, -gd * 5.4, -gp * 3.2])
			var fl := PackedColorArray(); fl.resize(4); fl.fill(cor)
			draw_circle(Vector2.ZERO, 6.0, Color(cor.r, cor.g, cor.b, 0.22 * p))
			draw_polygon(losango, fl)
		_:
			# Padrao (e qualquer arma sem desenho proprio): a bolinha de sempre.
			draw_circle(Vector2.ZERO, 5.5, Color(1.0, 0.95, 0.4, 0.3 * p))
			draw_circle(Vector2.ZERO, 3.5, Color(1.0, 1.0,  0.9, 1.0))
