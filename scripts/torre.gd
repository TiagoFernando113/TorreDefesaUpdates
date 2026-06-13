extends Node2D

const PROJETIL_SCENE = preload("res://scenes/Projetil.tscn")

var jogo = null

# Stats
var hp          := 150.0
var max_hp      := 150.0
var damage      := 25.0
var range_r     := 220.0
var fire_rate   := 1.2     # tiros/s

# Nível dos upgrades
var dmg_lvl    := 0
var rng_lvl    := 0
var rate_lvl   := 0
var pierce_lvl := 0
var multi_lvl  := 0
var speed_lvl  := 0
var regen_lvl  := 0

# Stats dos upgrades avançados
var pierce_count          := 0
var pierce_splash_radius  := 0.0
var pierce_splash_dmg_mult := 0.0
var multi_shot            := false   # mantido para compatibilidade
var proj_speed_bonus      := 0.0
var regen_rate            := 0.0

# Canhões orbitais (Canhão Duplo — um por carta selecionada)
var _canhao_angs : Array  = []   # ângulo de mira de cada canhão extra
var _orbit_rot   := 0.0          # rotação lenta das posições orbitais

# Stats dos talentos permanentes
var damage_reduction := 0.0   # 0.25 = reduz 25% dano
var block_chance     := 0.0
var boss_damage_mult := 1.0
var low_hp_barrier_ready := false
var low_hp_barrier_threshold := 0.30
var imortal_ativo    := false  # Fênix: sobrevive 1x com 1 HP
var imortal_flash    := 0.0
var r5_ativo         := false  # R5 — Imortal: protege nas waves 1-5

# IA Assistente — boost de cadência (Cyron/Hacker)
var ia_boost_ativo : bool  = false
var ia_boost_timer : float = 0.0
const IA_BOOST_MULT : float = 2.0
const IA_BOOST_DUR  : float = 6.0

# IA Assistente — boost de dano (Nexus/Sobrecarga)
var ia_dano_boost_ativo : bool  = false
var ia_dano_boost_timer : float = 0.0
const IA_DANO_BOOST_MULT : float = 1.6

# Debuffs temporários
var maldicao_timer        := 0.0
var maldicao_flash        := 0.0
var punicao_pierce_timer  := 0.0  # Punição da Perfuração: anula pierce
var ancora_suprimida      := false  # Âncora: reduz cadência a 30%

# ── Cartas avançadas ──────────────────────────────────────────────────────────
var raio_nivel     := 0
var raio_dano      := 0.0
var raio_timer     := 0.0
var raio_intervalo := 3.0
var _raio_flash_timer  := 0.0
var _raio_flash_pts    : PackedVector2Array = PackedVector2Array()
var _raio_flash_timer2 := 0.0
var _raio_flash_pts2   : PackedVector2Array = PackedVector2Array()

var tempestade_ativa     := false   # Tempestade Arcana: raio acerta TODOS no alcance
var fissura_ativa        := false   # Fissura Venenosa: projéteis envenenam em 70px
var corrente_ativa       := false   # Corrente Elétrica: projéteis saltam +2 alvos
var ricochete_count      := 0      # Ricochete: projétil quica para N inimigos após acertar
var brasa_count          := 0      # Brasa: cartas de fogo empilhadas (fusão em 5)
var fogo_fusao           := false   # FUSÃO: 5 Brasa + Ricochete = Bolas de Fogo
var veneno_dps           := 0.0    # Veneno Arcano: DoT nos acertados
var crit_chance          := 0.0    # Golpe Crítico: chance de 3× dano
var explosao_ativa       := false   # Explosão Mortal: explode ao matar
var chama_bonus_por_kill := 0.0    # Chama Perpétua: +dano por kill
var overdrive_ativa      := false   # Overdrive: cadência ×2 após boss
var overdrive_timer      := 0.0
var overdrive_bonus      := 0.0
var rajada_ativa         := false   # Rajada: 3 projéteis em leque ±15°
var carga_ativa          := false   # Tiro Carregado: sem alvo 3.5s = tiro 6×
var carga_timer          := 0.0
var carga_carregada      := false
var gelo_ativo           := false   # Campo de Gelo: slow 80% nos mobs no alcance
var _gelo_tick           := 0.0
const CARGA_MAX          : float = 3.5
var armadura_inv         := false   # Armadura Invertida: +60% dano em alvo <30% HP
var bencao_ativa         := false   # Bênção de Energia: a cada 15 kills → 8× próximo tiro
var bencao_kills         := 0
var bencao_proximo       := false
var recuperacao_ativa    := false   # Recuperação Rápida: cura após boss
var recuperacao_timer    := 0.0

var target      = null
var shoot_timer := 0.0
var angle       := -PI / 2.0

# B2 — Trance Berserker
var _b2_ativo     := false
var _b2_timer     := 0.0   # duração restante (8s)
var _b2_cd        := 0.0   # cooldown (60s)
var _b2_fr_before := 0.0   # fire_rate antes da ativação

# B4 — Fúria Final
var _b4_usado_wave := false   # resetado a cada wave

# Visual
var pulse    := 0.0
var hit_flash:= 0.0

var mobs_group : String = "mobs"
var _alvos_cache : Array = []
var _alvos_cache_frame : int = -1

# ── Arma ativa (formato do tiro) ─────────────────────────────────────────────
# cad/dano/alcance = multiplicadores; modo = padrão de disparo
const ARMAS : Dictionary = {
	"padrao":       {"nome": "Padrão",      "cad": 1.0,  "dano": 1.0,  "alcance": 1.0, "modo": "single"},
	"saltitante":   {"nome": "Saltitante",  "cad": 1.0,  "dano": 0.9,  "alcance": 1.0, "modo": "ricochete"},
	"escopeta":     {"nome": "Escopeta",    "cad": 0.85, "dano": 0.55, "alcance": 0.6, "modo": "escopeta"},
	"sniper":       {"nome": "Sniper",      "cad": 0.35, "dano": 4.5,  "alcance": 1.6, "modo": "sniper"},
	"metralhadora": {"nome": "Metralhadora","cad": 2.2,  "dano": 0.45, "alcance": 0.9, "modo": "single"},
}
var arma_ativa : String = "padrao"

func definir_arma(id: String) -> void:
	if ARMAS.has(id):
		arma_ativa = id
		# Saltitante = arma com ricochete embutido; re-checa fusão de fogo
		ricochete_count = 2 if id == "saltitante" else ricochete_count
		_checar_fusao_fogo()

func _arma_mult(campo: String) -> float:
	return float((ARMAS.get(arma_ativa, ARMAS["padrao"]) as Dictionary).get(campo, 1.0))

func _arma_modo() -> String:
	return str((ARMAS.get(arma_ativa, ARMAS["padrao"]) as Dictionary).get("modo", "single"))

# ── Focus de Ataque ──────────────────────────────────────────────────────────
var focus_dir   : Vector2 = Vector2.ZERO   # direção clicada pelo jogador
var focus_ativo : bool    = false
var focus_timer : float   = 0.0
const FOCUS_DUR : float   = 6.0            # duração em segundos
var _manual_spin : float = 0.0   # 0→1: aquece enquanto segura mira manual (bônus cadência+projéteis)


func _alvos_validos() -> Array:
	var frame : int = Engine.get_process_frames()
	if _alvos_cache_frame == frame:
		return _alvos_cache
	var alvos: Array = []
	for mob in get_tree().get_nodes_in_group(mobs_group):
		if is_instance_valid(mob):
			alvos.append(mob)
	if jogo and is_instance_valid(jogo):
		var boss = jogo.get("_dante_boss")
		if boss != null and is_instance_valid(boss) and not (boss.get("morto") == true):
			alvos.append(boss)
	_alvos_cache = alvos
	_alvos_cache_frame = frame
	return alvos


func _target_pos(alvo: Node) -> Vector2:
	if alvo and is_instance_valid(alvo) and alvo.has_method("get_target_position"):
		return alvo.call("get_target_position") as Vector2
	return (alvo as Node2D).global_position


func _get_float_prop(obj: Object, prop: String, fallback: float = 0.0) -> float:
	if not is_instance_valid(obj):
		return fallback
	var v = obj.get(prop)
	if v == null:
		return fallback
	var t: int = typeof(v)
	if t == TYPE_FLOAT or t == TYPE_INT:
		return float(v)
	if t == TYPE_STRING:
		var s: String = v as String
		return float(s) if s.is_valid_float() else fallback
	return fallback


func _ready() -> void:
	add_to_group("torre")


func _process(delta: float) -> void:
	pulse         += delta * 2.5
	hit_flash      = max(0.0, hit_flash     - delta * 4.0)
	imortal_flash  = max(0.0, imortal_flash - delta * 2.0)
	if ia_boost_timer > 0.0:
		ia_boost_timer = max(0.0, ia_boost_timer - delta)
		if ia_boost_timer <= 0.0:
			ia_boost_ativo = false
	if ia_dano_boost_timer > 0.0:
		ia_dano_boost_timer = max(0.0, ia_dano_boost_timer - delta)
		if ia_dano_boost_timer <= 0.0:
			ia_dano_boost_ativo = false
	maldicao_timer       = max(0.0, maldicao_timer       - delta)
	maldicao_flash       = max(0.0, maldicao_flash       - delta * 1.5)
	punicao_pierce_timer = max(0.0, punicao_pierce_timer - delta)
	_raio_flash_timer  = max(0.0, _raio_flash_timer  - delta)
	_raio_flash_timer2 = max(0.0, _raio_flash_timer2 - delta)
	shoot_timer      += delta

	# Focus de Ataque: expira após FOCUS_DUR
	if focus_ativo:
		focus_timer -= delta
		if focus_timer <= 0.0:
			focus_ativo = false
			focus_dir   = Vector2.ZERO

	# Raio Arcano
	if raio_nivel > 0:
		raio_timer += delta
		if raio_timer >= raio_intervalo:
			raio_timer = 0.0
			_disparar_raio_em_alvo()

	# Overdrive (cadência temporária após boss)
	if overdrive_timer > 0.0:
		overdrive_timer -= delta
		if overdrive_timer <= 0.0:
			fire_rate      -= overdrive_bonus
			overdrive_bonus = 0.0

	# Recuperação Rápida (regen temporária após boss)
	if recuperacao_timer > 0.0:
		recuperacao_timer -= delta
		hp = min(hp + 15.0 * delta, max_hp)

	# Regeneração
	if regen_rate > 0.0:
		hp = min(hp + regen_rate * delta, max_hp)

	# B2 — Trance Berserker: cooldown e duração
	if Salvar.talento_ativo("b2"):
		if _b2_cd > 0.0:
			_b2_cd = maxf(0.0, _b2_cd - delta)
		if _b2_ativo:
			_b2_timer = maxf(0.0, _b2_timer - delta)
			if _b2_timer <= 0.0:
				fire_rate  = _b2_fr_before   # restaura o valor original
				_b2_ativo  = false
				_b2_cd     = 60.0
		elif max_hp > 0.0 and hp / max_hp < 0.50 and _b2_cd <= 0.0:
			# Ativa: salva cadência atual e dobra
			_b2_fr_before = fire_rate
			fire_rate    *= 2.0
			_b2_ativo     = true
			_b2_timer     = 8.0

	# Tiro carregado: acumula quando não há alvo
	if carga_ativa:
		if _achar_alvos_multiplos(1).is_empty():
			carga_timer += delta
			if carga_timer >= CARGA_MAX:
				carga_carregada = true
		else:
			if not carga_carregada:
				carga_timer = maxf(0.0, carga_timer - delta * 0.5)  # decai devagar com alvo

	# Campo de gelo: aplica slow nos mobs no alcance a cada frame
	if gelo_ativo:
		_gelo_tick -= delta
		if _gelo_tick <= 0.0:
			_gelo_tick = 0.12
			for _gmob in _alvos_validos():
				if is_instance_valid(_gmob) and not (_gmob.get("morto") as bool):
					if global_position.distance_to(_target_pos(_gmob)) <= range_r:
						_gmob.set("gelo_slow", 0.80)
	else:
		_gelo_tick = 0.0

	_orbit_rot += delta * 0.38

	# Âncora: verifica se há mob âncora no alcance + 80px
	ancora_suprimida = false
	for m in _alvos_validos():
		if is_instance_valid(m) and m.get("tipo") == "ancora" and not (m.get("morto") as bool):
			if global_position.distance_to((m as Node2D).global_position) <= range_r + 80.0:
				ancora_suprimida = true
				break

	# Modo manual: jogador segura o dedo/mouse (focus_timer > 90 = ativo)
	if focus_ativo and focus_timer > 90.0:
		# Aquece o spin enquanto segura (0→1 em ~0.6s)
		_manual_spin = minf(_manual_spin + delta / 0.6, 1.0)
		angle = lerp_angle(angle, atan2(focus_dir.y, focus_dir.x), delta * 12.0)
		# Cadência sobe até 2× conforme spin (incentivo ao uso manual)
		var fr_m : float = fire_rate * (1.0 + _manual_spin * 1.0)
		if ia_boost_ativo:    fr_m *= IA_BOOST_MULT
		if ancora_suprimida:  fr_m *= 0.30
		elif maldicao_timer > 0.0: fr_m *= 0.55
		if shoot_timer >= 1.0 / maxf(fr_m, 0.01):
			shoot_timer = 0.0
			_disparar_direcao(focus_dir)
			# Projéteis extras em leque conforme calor do spin
			var ang_b : float = atan2(focus_dir.y, focus_dir.x)
			var off   : float = 0.28   # ~16° de abertura
			if _manual_spin > 0.35:
				_disparar_direcao(Vector2(cos(ang_b + off), sin(ang_b + off)))
			if _manual_spin > 0.70:
				_disparar_direcao(Vector2(cos(ang_b - off), sin(ang_b - off)))
	else:
		# Resfria o spin ao soltar (1→0 em ~1.2s)
		_manual_spin = maxf(_manual_spin - delta / 1.2, 0.0)
		target = _achar_alvo()
		if target and is_instance_valid(target):
			var dir: Vector2 = (_target_pos(target) - global_position).normalized()
			angle    = lerp_angle(angle, atan2(dir.y, dir.x), delta * 10.0)
			var fr_efetiva : float = fire_rate * _arma_mult("cad")
			if ia_boost_ativo:
				fr_efetiva *= IA_BOOST_MULT
			if ancora_suprimida:
				fr_efetiva *= 0.30
			elif maldicao_timer > 0.0:
				fr_efetiva *= 0.55
			if shoot_timer >= 1.0 / fr_efetiva:
				shoot_timer = 0.0
				_atirar()

	# Sincroniza tamanho do array de ângulos com multi_lvl
	while _canhao_angs.size() < multi_lvl:
		_canhao_angs.append(angle)

	# Atualiza mira de cada canhão orbital em direção a um alvo único
	if multi_lvl > 0:
		var todos := _achar_alvos_multiplos(1 + multi_lvl)
		for i in range(multi_lvl):
			var alvo_idx : int = i + 1
			if alvo_idx < todos.size() and is_instance_valid(todos[alvo_idx]):
				var de : Vector2 = (_target_pos(todos[alvo_idx]) - global_position).normalized()
				_canhao_angs[i] = lerp_angle(_canhao_angs[i] as float, atan2(de.y, de.x), delta * 9.0)
			elif target and is_instance_valid(target):
				var de : Vector2 = (_target_pos(target) - global_position).normalized()
				_canhao_angs[i] = lerp_angle(_canhao_angs[i] as float, atan2(de.y, de.x), delta * 5.0)

	queue_redraw()


func _achar_alvo() -> Node:
	var alvo  = null
	var min_d = range_r
	# Focus de Ataque: prioriza mobs no setor indicado (cone de ~120°)
	if focus_ativo and focus_dir.length_squared() > 0.01:
		for mob in _alvos_validos():
			if not is_instance_valid(mob): continue
			var d : float = global_position.distance_to(_target_pos(mob))
			if d <= _range_para_alvo(mob):
				var mob_dir : Vector2 = (_target_pos(mob) - global_position).normalized()
				if focus_dir.dot(mob_dir) >= 0.5:   # dentro de ~60° de cada lado
					if alvo == null or d < min_d:
						alvo  = mob
						min_d = d
		if alvo != null:
			return alvo
		# fallback: sem mob no setor → usa mais próximo normal
		min_d = range_r
	for mob in _alvos_validos():
		if not is_instance_valid(mob):
			continue
		var d = global_position.distance_to(_target_pos(mob))
		var limite : float = _range_para_alvo(mob)
		if d <= limite and (alvo == null or d < min_d):
			alvo  = mob
			min_d = d
	return alvo


func _atirar() -> void:
	if not is_instance_valid(target):
		return
	# Escopeta: leque de pelotas em direções espalhadas (alcance curto)
	if _arma_modo() == "escopeta":
		_atirar_escopeta()
		return
	# Canhão principal sempre atira no alvo primário
	# (sniper/metralhadora/padrão/saltitante usam o disparo único; a diferença
	#  vem dos multiplicadores de cad/dano/alcance e da perfuração da sniper)
	_disparar_em(target)
	# Rajada: 2 tiros adicionais em ±15°
	if rajada_ativa:
		for ang_off in [-0.26, 0.26]:
			var dir_r : Vector2 = (_target_pos(target) - global_position).normalized()
			var ang_r : float = atan2(dir_r.y, dir_r.x) + float(ang_off)
			var alvo_r : Node = _achar_alvo_em_direcao(Vector2(cos(ang_r), sin(ang_r)))
			if alvo_r and is_instance_valid(alvo_r):
				_disparar_de(alvo_r, global_position, 0.70)
			else:
				_disparar_de(target, global_position, 0.70)
	# Cada canhão orbital atira em seu próprio alvo (fallback: alvo principal)
	if multi_lvl > 0:
		var todos := _achar_alvos_multiplos(1 + multi_lvl)
		for i in range(multi_lvl):
			var alvo_idx    : int  = i + 1
			var alvo_orbital : Node = target
			if alvo_idx < todos.size() and is_instance_valid(todos[alvo_idx]):
				alvo_orbital = todos[alvo_idx]
			if not is_instance_valid(alvo_orbital):
				continue
			var orbit_a   := float(i) * TAU / float(multi_lvl) + _orbit_rot
			var cannon_gp := global_position + Vector2(cos(orbit_a), sin(orbit_a)) * 54.0
			_disparar_de(alvo_orbital, cannon_gp, 0.05)


func _achar_alvos_multiplos(n: int) -> Array:
	var pares : Array = []
	for mob in _alvos_validos():
		if not is_instance_valid(mob): continue
		var d : float = global_position.distance_to(_target_pos(mob))
		if d <= _range_para_alvo(mob):
			pares.append([d, mob])
	pares.sort_custom(func(a, b): return (a[0] as float) < (b[0] as float))
	var result : Array = []
	for par in pares:
		if result.size() >= n: break
		result.append(par[1])
	return result


func _disparar_em(alvo: Node) -> void:
	_disparar_de(alvo, global_position)


func _disparar_de(alvo: Node, spawn_gp: Vector2, dmg_mult: float = 1.0) -> void:
	# X1 — Dados do Caos: 20% chance de falhar (não cria projétil)
	var x1_mult : float = 1.0
	if Salvar.talento_ativo("x1"):
		if randf() < 0.20:
			return
		x1_mult = 1.25

	var dir_alvo : Vector2 = (_target_pos(alvo) - spawn_gp).normalized()
	var ang_alvo := atan2(dir_alvo.y, dir_alvo.x)
	var proj = PROJETIL_SCENE.instantiate()
	get_parent().add_child(proj)
	proj.global_position = spawn_gp + Vector2(cos(ang_alvo), sin(ang_alvo)) * 20.0

	var dano_final : float = damage * _arma_mult("dano") * dmg_mult * x1_mult
	if is_instance_valid(alvo) and alvo.is_in_group("boss_dante"):
		dano_final *= boss_damage_mult
	if ia_dano_boost_ativo:
		dano_final *= IA_DANO_BOOST_MULT

	# B1 — Fúria de Sangue: +5% dano por 10% HP faltante (máx +50%)
	if Salvar.talento_ativo("b1") and max_hp > 0.0:
		var hp_faltante_pct : float = clampf(1.0 - (hp / max_hp), 0.0, 1.0)
		var bonus_b1 : float = clampf(floorf(hp_faltante_pct * 10.0) * 0.05, 0.0, 0.50)
		dano_final *= (1.0 + bonus_b1)

	var eh_bencao  : bool  = false

	# Bênção de Energia — só aplica no canhão principal
	if bencao_proximo and dmg_mult >= 1.0:
		dano_final    *= 8.0
		eh_bencao      = true
		bencao_proximo = false

	# Tiro carregado
	var eh_carga : bool = false
	if carga_ativa and carga_carregada and dmg_mult >= 1.0:
		dano_final    *= 6.0
		eh_carga       = true
		carga_carregada = false
		carga_timer     = 0.0

	# Golpe Crítico
	var eh_critico : bool = false
	if crit_chance > 0.0 and randf() < crit_chance:
		dano_final  *= 3.0
		eh_critico   = true

	# Punição da Perfuração: anula pierce enquanto debuff ativo
	var pierce_efetivo : int  = 0 if punicao_pierce_timer > 0.0 else pierce_count
	# Sniper: o tiro perfura naturalmente (atravessa a fileira)
	if arma_ativa == "sniper" and punicao_pierce_timer <= 0.0:
		pierce_efetivo += 3
	var splash_r       : float = pierce_splash_radius if pierce_efetivo > 0 else 0.0
	var splash_d       : float = dano_final * pierce_splash_dmg_mult

	var extras : Dictionary = {}
	extras["mobs_group"] = mobs_group
	extras["low_fx"] = _efeitos_leves_ativos()
	if corrente_ativa:                  extras["chain"]        = 2
	if ricochete_count > 0:             extras["ricochete"]    = ricochete_count
	if brasa_count > 0:                 extras["queimadura"]   = true   # Brasa: tiros queimam
	if fogo_fusao:                      extras["fogo_fusao"]   = true   # Bolas de Fogo
	if veneno_dps > 0.0:               extras["veneno_dps"]   = veneno_dps;  extras["veneno_dur"] = 4.0
	if armadura_inv:                    extras["armadura_inv"]  = true
	if eh_bencao:                       extras["is_bencao"]     = true
	if fissura_ativa:                   extras["fissura"]       = true
	if eh_critico:                      extras["is_critico"]    = true
	if eh_carga:                        extras["is_carga"]      = true
	if Salvar.talento_ativo("p5"):      extras["queimadura"]    = true
	if Salvar.talento_ativo("canhao_g") and randf() < 0.20:
		extras["canhao_g_gelo"] = true
	extras["max_travel"] = _range_para_alvo(alvo) + 26.0

	proj.setup(alvo, dano_final, pierce_efetivo, proj_speed_bonus, splash_r, splash_d, extras)
	Som.tiro()


func _disparar_direcao(dir: Vector2) -> void:
	var x1_mult : float = 1.0
	if Salvar.talento_ativo("x1"):
		if randf() < 0.20: return
		x1_mult = 1.25
	var ang : float = atan2(dir.y, dir.x)
	var proj = PROJETIL_SCENE.instantiate()
	get_parent().add_child(proj)
	proj.global_position = global_position + Vector2(cos(ang), sin(ang)) * 20.0
	var dano_final : float = damage * x1_mult
	if ia_dano_boost_ativo: dano_final *= IA_DANO_BOOST_MULT
	if Salvar.talento_ativo("b1") and max_hp > 0.0:
		var hp_f : float = clampf(1.0 - (hp / max_hp), 0.0, 1.0)
		dano_final *= 1.0 + clampf(floorf(hp_f * 10.0) * 0.05, 0.0, 0.50)
	var eh_crit : bool = crit_chance > 0.0 and randf() < crit_chance
	if eh_crit: dano_final *= 3.0
	var pierce_ef : int   = 0 if punicao_pierce_timer > 0.0 else pierce_count
	var splash_r  : float = pierce_splash_radius if pierce_ef > 0 else 0.0
	var splash_d  : float = dano_final * pierce_splash_dmg_mult if pierce_ef > 0 else 0.0
	var extras : Dictionary = {}
	extras["mobs_group"] = mobs_group
	extras["low_fx"]     = _efeitos_leves_ativos()
	if veneno_dps > 0.0:  extras["veneno_dps"] = veneno_dps; extras["veneno_dur"] = 4.0
	if armadura_inv:      extras["armadura_inv"] = true
	if fissura_ativa:     extras["fissura"]      = true
	if eh_crit:           extras["is_critico"]   = true
	if Salvar.talento_ativo("p5"):      extras["queimadura"]   = true
	if Salvar.talento_ativo("canhao_g") and randf() < 0.20: extras["canhao_g_gelo"] = true
	extras["max_travel"] = range_r + 26.0
	proj.setup_dir(dir, dano_final, pierce_ef, proj_speed_bonus, splash_r, splash_d, extras)
	Som.tiro()


func _efeitos_leves_ativos() -> bool:
	return fire_rate >= 7.0 or multi_lvl >= 2 or _alvos_validos().size() >= 34


func _achar_alvo_em_direcao(dir: Vector2) -> Node:
	var melhor   : Node  = null
	var mel_dot  : float = 0.5   # coseno mínimo (~±60°)
	for mob in _alvos_validos():
		if not is_instance_valid(mob) or (mob.get("morto") as bool): continue
		if global_position.distance_to(_target_pos(mob)) > _range_para_alvo(mob): continue
		var mob_dir : Vector2 = (_target_pos(mob) - global_position).normalized()
		var dot     : float   = dir.dot(mob_dir)
		if dot > mel_dot:
			mel_dot = dot
			melhor  = mob
	return melhor


func _range_para_alvo(alvo: Node) -> float:
	return range_r * _arma_mult("alcance")


func _atirar_escopeta() -> void:
	# Leque de 6 pelotas em ±40° em torno da direção do alvo. Alcance curto
	# (já refletido em _range_para_alvo), dano por pelota baixo (mult da arma).
	var dir_base : Vector2 = (_target_pos(target) - global_position).normalized()
	var ang_base : float = atan2(dir_base.y, dir_base.x)
	const N : int = 6
	for i in range(N):
		var frac : float = (float(i) / float(N - 1)) - 0.5   # -0.5..0.5
		var ang  : float = ang_base + frac * deg_to_rad(80.0)
		var alvo_p : Node = _achar_alvo_em_direcao(Vector2(cos(ang), sin(ang)))
		if alvo_p and is_instance_valid(alvo_p):
			_disparar_de(alvo_p, global_position)
		else:
			# Sem mob naquele ângulo: dispara direcional reto (free_dir)
			_disparar_direcao(Vector2(cos(ang), sin(ang)))


func receber_dano(dano: float) -> void:
	if block_chance > 0.0 and randf() < block_chance:
		hit_flash = 1.0
		return
	var dano_efetivo : float = dano * (1.0 - damage_reduction)
	hp       -= dano_efetivo
	hit_flash = 1.0
	Som.dano_torre()
	if low_hp_barrier_ready and max_hp > 0.0 and hp <= max_hp * low_hp_barrier_threshold:
		low_hp_barrier_ready = false
		hp = maxf(hp, max_hp * low_hp_barrier_threshold)
		imortal_flash = 1.0
		if jogo and is_instance_valid(jogo) and jogo.get("ui_node"):
			(jogo.get("ui_node") as Node).call("mostrar_notificacao_consumivel",
				"Barreira da armadura ativada!", Color(1.0, 0.62, 0.18))
	# B4 — Fúria Final: explosão de 300 dano em 200px ao atingir 5% HP (1×/wave)
	if Salvar.talento_ativo("b4") and not _b4_usado_wave and max_hp > 0.0 and hp / max_hp <= 0.05 and hp > 0.0:
		_b4_usado_wave = true
		for mob in _alvos_validos():
			if is_instance_valid(mob) and not (mob.get("imune_aoe") as bool):
				if global_position.distance_to(_target_pos(mob)) <= 200.0:
					(mob as Node).receber_dano(300.0, true)
	if hp <= 0.0:
		if imortal_ativo:
			hp            = 1.0
			imortal_ativo = false
			imortal_flash = 1.0
		elif r5_ativo:
			hp            = 1.0
			r5_ativo      = false
			imortal_flash = 1.0
		elif jogo and is_instance_valid(jogo) and jogo.get("_cristal_barreira_ativo") as bool:
			jogo.set("_cristal_barreira_ativo", false)
			hp            = 1.0
			imortal_flash = 1.0
			if jogo.get("ui_node"):
				(jogo.get("ui_node") as Node).call("mostrar_notificacao_consumivel",
					"Cristal de Barreira absorveu o golpe!", Color(0.3, 0.55, 1.0))
		else:
			hp = 0.0
			if jogo:
				jogo.game_over()


func aplicar_maldicao(duracao: float) -> void:
	maldicao_timer = max(maldicao_timer, duracao)
	maldicao_flash = 1.0


func aplicar_punicao_perfuracao(duracao: float) -> void:
	punicao_pierce_timer = max(punicao_pierce_timer, duracao)


func aplicar_carta(efeito: String, val: float) -> void:
	match efeito:
		"dano":
			damage  = max(1.0, damage + val)
		"cadencia":
			fire_rate = max(0.15, fire_rate + val)
		"alcance":
			# Cap 450: limite que a câmera consegue enquadrar (main._RANGE_MAX)
			range_r = clampf(range_r + val, 60.0, 450.0)
		"vida":
			if val >= 0.0:
				max_hp += val
				hp      = min(hp + val * 1.5, max_hp)
			else:
				# Penalidade: só reduz o máximo, não mata
				max_hp = max(30.0, max_hp + val)
				hp     = min(hp, max_hp)
		"pierce":     pierce_count = min(pierce_count + int(val), 3)
		"fragmento":
			pierce_splash_radius   = max(pierce_splash_radius, 60.0)
			pierce_splash_dmg_mult = minf(pierce_splash_dmg_mult + 0.25, 1.5)
		"multi":
			if multi_lvl < 5:
				multi_shot = true
				multi_lvl += 1
		"raio":
			raio_nivel += int(val)
			raio_dano   = float(raio_nivel) * 45.0 + (20.0 if Salvar.talento_ativo("e1") else 0.0)
			var base_inv : float = max(1.2, 4.0 - float(raio_nivel - 1) * 0.35)
			var cd_mult  : float = 1.0
			if Salvar.talento_ativo("e3"): cd_mult *= 0.60  # Tempestade Interior
			if Salvar.talento_ativo("e5"): cd_mult *= 0.40  # Fúria Elétrica
			raio_intervalo = base_inv * cd_mult
		"tempestade": tempestade_ativa = true
		"fissura":    fissura_ativa   = true
		"corrente":   corrente_ativa  = true
		"ricochete":  ricochete_count = mini(ricochete_count + int(val), 4); _checar_fusao_fogo()
		"brasa":      brasa_count     = mini(brasa_count + int(val), 5);     _checar_fusao_fogo()
		"veneno":     veneno_dps     = max(0.0, veneno_dps + val)
		"critico":    crit_chance    = clampf(crit_chance + val, 0.0, 0.75)
		"explosao":   explosao_ativa = true
		"chama":      chama_bonus_por_kill += val
		"overdrive":  overdrive_ativa = true
		"rajada":     rajada_ativa   = true
		"carga":      carga_ativa    = true
		"gelo":       gelo_ativo     = true
		"armadura_i": armadura_inv   = true
		"bencao":     bencao_ativa   = true
		"recuperacao":recuperacao_ativa = true
		"speed":    proj_speed_bonus = max(0.0, proj_speed_bonus + val)
		"regen":    regen_rate  = max(0.0, regen_rate + val)
		"reducao":  damage_reduction = clampf(damage_reduction + val, 0.0, 0.75)


func _checar_fusao_fogo() -> void:
	# FUSÃO Bolas de Fogo: 5 cartas de Brasa + arma Ricochete
	fogo_fusao = brasa_count >= 5 and ricochete_count > 0


func aplicar_upgrade(tipo: String) -> void:
	match tipo:
		"dano":
			damage    += [12.0, 18.0, 25.0, 35.0][min(dmg_lvl,  3)]
			dmg_lvl   += 1
		"alcance":
			range_r   = minf(range_r + [30.0, 40.0, 55.0, 70.0][min(rng_lvl,  3)], 450.0)
			rng_lvl   += 1
		"cadencia":
			fire_rate += [0.35, 0.5, 0.7,  1.0 ][min(rate_lvl, 3)]
			rate_lvl  += 1
		"vida":
			max_hp += 30.0
			hp      = min(hp + 50.0, max_hp)
		"perfurante":
			pierce_count = min(pierce_count + 1, 3)
			pierce_lvl  += 1
		"multitiro":
			if multi_lvl < 5:
				multi_shot = true
				multi_lvl += 1
		"velocidade":
			proj_speed_bonus += [120.0, 160.0, 200.0, 240.0][min(speed_lvl, 3)]
			speed_lvl        += 1
		"regeneracao":
			regen_rate += 2.0
			regen_lvl  += 1


func boss_morreu() -> void:
	if overdrive_ativa:
		var bonus : float = fire_rate
		fire_rate       += bonus
		overdrive_bonus  = bonus
		overdrive_timer  = 6.0
	if recuperacao_ativa:
		recuperacao_timer = 8.0


const _CHAMA_CAP : float = 200.0   # limite total de bônus acumulado pela Chama Perpétua
var _chama_acumulado : float = 0.0

func on_mob_morreu() -> void:
	if chama_bonus_por_kill > 0.0 and _chama_acumulado < _CHAMA_CAP:
		var ganho : float = minf(chama_bonus_por_kill, _CHAMA_CAP - _chama_acumulado)
		damage            += ganho
		_chama_acumulado  += ganho
	if bencao_ativa:
		bencao_kills += 1
		if bencao_kills >= 15:
			bencao_kills   = 0
			bencao_proximo = true


func explosao_em(pos: Vector2) -> void:
	for mob in _alvos_validos():
		if not is_instance_valid(mob) or (mob.get("morto") as bool): continue
		if (mob.get("imune_aoe") as bool): continue   # Fantasma imune à explosão
		if pos.distance_to(_target_pos(mob)) <= 80.0:
			mob.receber_dano(damage * 0.40, true)


func _disparar_raio_em_alvo() -> void:
	var validos : Array = []
	for mob in _alvos_validos():
		if is_instance_valid(mob) and not (mob.get("morto") as bool):
			validos.append(mob)
	if validos.is_empty(): return

	# Tempestade Arcana: raio acerta todos os mobs no alcance (dano 65%)
	# e2 — Sobrecarga: raio acerta 2 alvos
	var num_alvos : int
	var dano_raio : float = raio_dano
	if tempestade_ativa:
		num_alvos  = validos.size()
		dano_raio  = raio_dano * 0.65
	elif Salvar.talento_ativo("e2"):
		num_alvos  = 2
	else:
		num_alvos  = 1
	var atingidos : Array = []
	for i_alvo in range(num_alvos):
		# Fantasma: imune ao raio encadeado (2º alvo em diante), mas pode ser alvo direto (1º)
		var candidatos : Array = validos.filter(func(m):
			if m in atingidos: return false
			if i_alvo > 0 and (m.get("imune_aoe") as bool): return false
			return true
		)
		if candidatos.is_empty(): break
		var alvo : Node = candidatos[randi() % candidatos.size()]
		(alvo as Node).receber_dano(dano_raio, true)
		# Relâmpago Sombrio: raio aplica veneno ao alvo
		if Salvar.talento_ativo("relamp"):
			(alvo as Node).set("veneno_dps",   maxf(_get_float_prop(alvo, "veneno_dps"), 20.0))
			(alvo as Node).set("veneno_timer", 4.0)
		atingidos.append(alvo)
	Som.impacto()

	# Visual: traça raio até o primeiro alvo
	if not atingidos.is_empty():
		var dest : Vector2         = to_local(_target_pos(atingidos[0]))
		var pts  : PackedVector2Array = PackedVector2Array()
		pts.append(Vector2.ZERO)
		for i in range(1, 8):
			var t    : float   = float(i) / 8.0
			var base : Vector2 = Vector2.ZERO.lerp(dest, t)
			var perp : Vector2 = dest.rotated(PI / 2.0).normalized()
			base += perp * randf_range(-22.0, 22.0)
			pts.append(base)
		pts.append(dest)
		_raio_flash_pts   = pts
		_raio_flash_timer = 0.30

	# Visual: raio encadeado do primeiro para o segundo alvo (e2 — Sobrecarga)
	if atingidos.size() >= 2:
		var origem2 : Vector2 = to_local(_target_pos(atingidos[0]))
		var dest2   : Vector2 = to_local(_target_pos(atingidos[1]))
		var pts2 : PackedVector2Array = PackedVector2Array()
		pts2.append(origem2)
		for i in range(1, 6):
			var t2   : float   = float(i) / 6.0
			var base2: Vector2 = origem2.lerp(dest2, t2)
			var perp2: Vector2 = (dest2 - origem2).rotated(PI / 2.0).normalized()
			base2 += perp2 * randf_range(-16.0, 16.0)
			pts2.append(base2)
		pts2.append(dest2)
		_raio_flash_pts2   = pts2
		_raio_flash_timer2 = 0.25

	queue_redraw()


# ── Desenho ───────────────────────────────────────────────────────────────────

func _skin_cor() -> Color:
	if Salvar.SKINS_INFO.has(Salvar.skin_ativa):
		return (Salvar.SKINS_INFO[Salvar.skin_ativa] as Dictionary)["cor"] as Color
	return Color(0.0, 0.72, 1.0)


func _draw() -> void:
	var p   := sin(pulse) * 0.25 + 0.75
	var cor := _skin_cor() if hit_flash < 0.05 else Color(1.0, 0.35, 0.1)

	# Campo de gelo: anel azul-claro ao redor do alcance
	if gelo_ativo:
		var gelo_r : float = range_r
		var gf : float = sin(pulse * 1.5) * 0.15 + 0.85
		draw_arc(Vector2.ZERO, gelo_r, 0.0, TAU, 90,
				Color(0.45, 0.82, 1.0, 0.22 * gf), 2.5)
		draw_circle(Vector2.ZERO, gelo_r, Color(0.45, 0.82, 1.0, 0.04 * gf))
		# Flocos de gelo orbitando
		for gi in range(6):
			var ga : float = float(gi) * TAU / 6.0 + pulse * 0.4
			draw_circle(Vector2(cos(ga), sin(ga)) * range_r * 0.88, 4.0,
					Color(0.75, 0.92, 1.0, 0.55 * gf))

	# Tiro carregado: glow laranja-intenso pulsante ao carregar
	if carga_ativa and (carga_timer > 0.5 or carga_carregada):
		var cp : float = carga_timer / CARGA_MAX if not carga_carregada else 1.0
		var cf : float = sin(pulse * (3.0 + cp * 8.0)) * 0.35 + 0.65
		var cc : Color = Color(1.0, 0.55 - cp * 0.30, 0.05, cp * cf * 0.80)
		for ci in range(5, 0, -1):
			draw_circle(Vector2.ZERO, 24.0 + float(ci) * (5.0 + cp * 8.0), Color(cc.r, cc.g, cc.b, 0.06 * cp / float(ci)))
		if carga_carregada:
			draw_arc(Vector2.ZERO, 36.0, 0.0, TAU, 48,
					Color(1.0, 0.75, 0.05, cf * 0.90), 4.5)

	# Anel de âncora (supressão de cadência)
	if ancora_suprimida:
		var af : float = sin(pulse * 2.0) * 0.20 + 0.80
		draw_arc(Vector2.ZERO, 42.0, 0.0, TAU, 32,
				Color(0.28, 0.38, 0.65, 0.70 * af), 4.0)
		draw_arc(Vector2.ZERO, 48.0, 0.0, TAU, 24,
				Color(0.28, 0.38, 0.65, 0.28 * af), 2.5)
		# Ícone âncora (linhas simples no centro)
		draw_line(Vector2(0, -10), Vector2(0,  10), Color(0.5, 0.65, 1.0, 0.55 * af), 2.0)
		draw_line(Vector2(-8, -4), Vector2(8, -4), Color(0.5, 0.65, 1.0, 0.55 * af), 2.0)
		draw_arc(Vector2.ZERO, 6.0, -PI, 0.0, 16,  Color(0.5, 0.65, 1.0, 0.55 * af), 2.0)

	# Anel de maldição (bruxo)
	if maldicao_timer > 0.0:
		var mf : float = sin(pulse * 3.0) * 0.25 + 0.75
		draw_arc(Vector2.ZERO, 38.0, 0.0, TAU, 32,
				Color(0.6, 0.0, 0.85, 0.55 * mf), 3.5)
		draw_arc(Vector2.ZERO, 44.0, 0.0, TAU, 24,
				Color(0.4, 0.0, 0.60, 0.22 * mf), 2.0)
	elif maldicao_flash > 0.01:
		draw_arc(Vector2.ZERO, 38.0, 0.0, TAU, 32,
				Color(0.6, 0.0, 0.85, maldicao_flash * 0.7), 4.0)

	var is_saberpunk : bool = Salvar.skin_ativa == "saberpunk"

	# Círculo de alcance
	var _vis_range : float = range_r
	if target and is_instance_valid(target) and _vis_range > 10.0:
		if is_saberpunk:
			# Anel de alcance cyberpunk: dual-neon rotativo com segmentos
			var seg_a   : float = pulse * 0.6         # rotação lenta
			var seg_a2  : float = -pulse * 0.45        # contra-rotação
			var pf      : float = sin(pulse * 2.0) * 0.12 + 0.88
			# Fundo fill suave cyan
			draw_circle(Vector2.ZERO, _vis_range, Color(0.0, 1.0, 0.88, 0.025 * pf))
			# Anel base cyan sólido fino
			draw_arc(Vector2.ZERO, _vis_range, 0.0, TAU, 128,
					Color(0.0, 1.0, 0.88, 0.30 * pf), 1.2)
			# Segmentos magenta girando em sentido oposto (arco 3/4)
			draw_arc(Vector2.ZERO, _vis_range, seg_a, seg_a + TAU * 0.72, 96,
					Color(0.88, 0.0, 1.0, 0.50 * pf), 2.2)
			# Segundo arco magenta menor (1/3 do círculo) na frente
			draw_arc(Vector2.ZERO, _vis_range, seg_a2, seg_a2 + TAU * 0.33, 48,
					Color(1.0, 0.55, 1.0, 0.65 * pf), 3.0)
			# Nó de vértice: 6 pontos brilhantes distribuídos no anel
			for vi in range(6):
				var va  : float = float(vi) * TAU / 6.0 + pulse * 0.9
				var vpos : Vector2 = Vector2(cos(va), sin(va)) * _vis_range
				draw_circle(vpos, 4.5, Color(0.0, 1.0, 0.88, 0.80 * pf))
				draw_circle(vpos, 2.0, Color(1.0, 1.0, 1.0, 0.90 * pf))
			# Glow externo suave magenta
			for gi2 in range(3, 0, -1):
				draw_arc(Vector2.ZERO, _vis_range + float(gi2) * 3.5, 0.0, TAU, 64,
						Color(0.88, 0.0, 1.0, 0.06 / float(gi2)), 2.0)
		else:
			draw_arc(Vector2.ZERO, _vis_range, 0.0, TAU, 90,
					Color(cor.r, cor.g, cor.b, 0.18), 1.0)
			draw_circle(Vector2.ZERO, _vis_range, Color(cor.r, cor.g, cor.b, 0.03))

	# ── Efeitos exclusivos SaberPunk ──────────────────────────────────────────
	if is_saberpunk:
		var cor2 := Color(0.88, 0.0, 1.0)   # magenta neon
		# Anel giratório de partículas neon
		for pi2 in range(8):
			var pa  : float = pulse * 1.8 + float(pi2) * TAU / 8.0
			var pr  : float = 36.0 + sin(pulse * 2.5 + float(pi2)) * 5.0
			var pcor : Color = cor if pi2 % 2 == 0 else cor2
			draw_circle(Vector2(cos(pa) * pr, sin(pa) * pr), 3.0,
				Color(pcor.r, pcor.g, pcor.b, 0.75 * p))
		# Anel duplo pulsante alternado cyan/magenta
		var ring_r1 : float = 30.0 + sin(pulse * 3.0) * 4.0
		var ring_r2 : float = 44.0 + cos(pulse * 2.2) * 5.0
		draw_arc(Vector2.ZERO, ring_r1, 0.0, TAU, 48, Color(cor.r, cor.g, cor.b, 0.55 * p), 1.5)
		draw_arc(Vector2.ZERO, ring_r2, pulse, pulse + TAU * 0.75, 48,
			Color(cor2.r, cor2.g, cor2.b, 0.40 * p), 1.2)
		# Scanlines glitch horizontais (2 linhas rápidas)
		for sl in range(2):
			var sy : float = sin(pulse * 4.0 + float(sl) * PI) * 18.0
			draw_line(Vector2(-28.0, sy), Vector2(28.0, sy),
				Color(0.0, 1.0, 0.88, 0.18 * p), 1.0)

	# Glow externo (camadas)
	for i in range(5, 0, -1):
		var a := (0.10 / float(i)) * p
		var gc : Color = Color(cor.r, cor.g, cor.b, a)
		if is_saberpunk and i % 2 == 0:
			gc = Color(0.88, 0.0, 1.0, a * 0.7)   # alterna magenta no glow
		draw_circle(Vector2.ZERO, 26.0 + float(i) * 5.0, gc)

	# Hexágono
	var pts := _hex_pts(24.0)
	draw_polygon(pts, _cores(pts.size(), Color(0.02, 0.08, 0.20, 0.92)))
	var borda := PackedVector2Array(pts)
	borda.append(pts[0])
	if is_saberpunk:
		# Bordas dual-neon: magenta por baixo, cyan por cima
		for i in range(3, 0, -1):
			draw_polyline(borda, Color(0.88, 0.0, 1.0, 0.35 / float(i) * p), float(i) * 3.0)
		draw_polyline(borda, Color(0.0, 1.0, 0.88, 1.0), 1.8)
	else:
		for i in range(3, 0, -1):
			draw_polyline(borda, Color(cor.r, cor.g, cor.b, 0.25 / float(i) * p), float(i) * 2.2)
		draw_polyline(borda, Color(cor.r + 0.25, cor.g + 0.2, cor.b, 1.0), 2.0)

	# Núcleo
	if is_saberpunk:
		draw_circle(Vector2.ZERO, 9.0, Color(0.88, 0.0, 1.0, 0.6 * p))
		draw_circle(Vector2.ZERO, 6.0, Color(0.0, 1.0, 0.88, p))
	else:
		draw_circle(Vector2.ZERO, 8.0, Color(cor.r + 0.2, cor.g + 0.2, cor.b, p))

	# Canhão
	var dir  := Vector2(cos(angle), sin(angle))
	var lat  := dir.rotated(PI / 2.0) * 4.5
	var tip  := dir * 32.0
	var gun  := PackedVector2Array([-lat * 0.4, lat * 0.4, tip + lat * 0.15, tip - lat * 0.15])
	draw_polygon(gun, _cores(gun.size(), Color(cor.r, cor.g, cor.b, 0.9)))
	if is_saberpunk:
		# Trilha neon no canhão
		draw_polyline(PackedVector2Array([Vector2.ZERO, tip]),
			Color(0.88, 0.0, 1.0, 0.35 * p), 2.5)
		draw_circle(tip, 6.0, Color(0.0, 1.0, 0.88, p))
	else:
		draw_circle(tip, 5.0, Color(1.0, 1.0, 1.0, p))

	# Flash do Raio Arcano (torre → alvo 1)
	if _raio_flash_timer > 0.01 and _raio_flash_pts.size() > 1:
		var ra : float = _raio_flash_timer / 0.30
		for i in range(_raio_flash_pts.size() - 1):
			draw_line(_raio_flash_pts[i], _raio_flash_pts[i + 1],
					Color(0.45, 0.80, 1.0, ra * 0.90), 3.5)
			draw_line(_raio_flash_pts[i], _raio_flash_pts[i + 1],
					Color(1.0,  1.0,  1.0, ra * 0.55), 1.8)

	# Flash do raio encadeado (alvo 1 → alvo 2, e2 — Sobrecarga)
	if _raio_flash_timer2 > 0.01 and _raio_flash_pts2.size() > 1:
		var ra2 : float = _raio_flash_timer2 / 0.25
		for i in range(_raio_flash_pts2.size() - 1):
			draw_line(_raio_flash_pts2[i], _raio_flash_pts2[i + 1],
					Color(0.20, 0.90, 1.0, ra2 * 0.70), 2.5)
			draw_line(_raio_flash_pts2[i], _raio_flash_pts2[i + 1],
					Color(0.80, 1.0,  1.0, ra2 * 0.40), 1.2)

	# Anel dourado pulsante quando bênção está carregada (próximo tiro 8×)
	if bencao_proximo:
		var bp : float = sin(pulse * 4.5) * 0.35 + 0.65
		draw_arc(Vector2.ZERO, 44.0, 0.0, TAU, 48,
				Color(1.0, 0.92, 0.1, bp * 0.85), 4.5)
		for i in range(6):
			var ba := float(i) * TAU / 6.0 + pulse * 1.8
			draw_circle(Vector2(cos(ba), sin(ba)) * 44.0, 5.0,
					Color(1.0, 0.88, 0.12, bp))

	# Anel Fênix (imortalidade ativa)
	if imortal_ativo:
		var pi2 := sin(pulse * 1.5) * 0.25 + 0.75
		draw_arc(Vector2.ZERO, 34.0, 0.0, TAU, 48,
				Color(1.0, 0.85, 0.15, 0.55 * pi2), 3.0)
		draw_arc(Vector2.ZERO, 38.0, 0.0, TAU, 48,
				Color(1.0, 0.65, 0.05, 0.25 * pi2), 2.0)
	elif imortal_flash > 0.01:
		draw_arc(Vector2.ZERO, 34.0, 0.0, TAU, 48,
				Color(1.0, 0.85, 0.15, imortal_flash * 0.9), 4.0)

	# Canhões orbitais (Canhão Duplo)
	if multi_lvl > 0:
		var orbit_r := 54.0
		# Anel orbital sutil
		draw_arc(Vector2.ZERO, orbit_r, 0.0, TAU, 64,
				Color(cor.r, cor.g, cor.b, 0.12 * p), 1.0)
		for i in range(multi_lvl):
			var orbit_a : float = float(i) * TAU / float(multi_lvl) + _orbit_rot
			var cpos    : Vector2 = Vector2(cos(orbit_a), sin(orbit_a)) * orbit_r
			var cang    : float   = _canhao_angs[i] as float if i < _canhao_angs.size() else angle

			# Glow do mini-canhão
			for gi in range(3, 0, -1):
				draw_circle(cpos, 16.0 + float(gi) * 4.0,
						Color(cor.r, cor.g, cor.b, 0.06 * p / float(gi)))

			# Mini hexágono
			var hex_pts := PackedVector2Array()
			for j in range(6):
				var ha := float(j) * TAU / 6.0 + PI / 6.0
				hex_pts.append(cpos + Vector2(cos(ha), sin(ha)) * 11.0)
			draw_polygon(hex_pts, _cores(hex_pts.size(), Color(0.02, 0.08, 0.20, 0.92)))
			var hex_brd := PackedVector2Array(hex_pts); hex_brd.append(hex_pts[0])
			draw_polyline(hex_brd, Color(cor.r, cor.g, cor.b, 0.88 * p), 1.8)

			# Núcleo do mini-canhão
			draw_circle(cpos, 4.0, Color(cor.r + 0.2, cor.g + 0.2, cor.b, p))

			# Cano do mini-canhão apontando para o alvo
			var cdir : Vector2 = Vector2(cos(cang), sin(cang))
			var clat : Vector2 = cdir.rotated(PI / 2.0) * 2.8
			var ctip : Vector2 = cpos + cdir * 20.0
			var cgun := PackedVector2Array([
				cpos - clat * 0.35, cpos + clat * 0.35,
				ctip + clat * 0.12, ctip - clat * 0.12,
			])
			draw_polygon(cgun, _cores(cgun.size(), Color(cor.r, cor.g, cor.b, 0.90)))
			draw_circle(ctip, 3.5, Color(1.0, 1.0, 1.0, p))

	# Barra de HP
	_draw_hp()


func _draw_hp() -> void:
	var w  := 64.0
	var h  := 7.0
	var y  := 38.0
	var pc := hp / max_hp
	draw_rect(Rect2(-w / 2.0, y, w, h), Color(0.08, 0.08, 0.08, 0.85))
	var c  := Color(0.1, 0.9, 0.3) if pc > 0.5 else (Color(0.9, 0.7, 0.1) if pc > 0.25 else Color(0.9, 0.1, 0.1))
	draw_rect(Rect2(-w / 2.0, y, w * pc, h), Color(c.r, c.g, c.b, 0.9))
	draw_rect(Rect2(-w / 2.0, y, w, h), Color(0.5, 0.5, 0.5, 0.5), false, 1.0)


func _hex_pts(r: float) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in range(6):
		var a := float(i) * TAU / 6.0 + PI / 6.0
		pts.append(Vector2(cos(a), sin(a)) * r)
	return pts


func _cores(n: int, c: Color) -> PackedColorArray:
	var arr := PackedColorArray()
	arr.resize(n)
	arr.fill(c)
	return arr
