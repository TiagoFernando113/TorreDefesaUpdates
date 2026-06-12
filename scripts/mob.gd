extends Node2D

var jogo     = null
var tipo     := "normal"
var wave_num := 1

# Stats (preenchidos em _ready por tipo)
var hp      := 0.0
var max_hp  := 0.0
var speed   := 0.0
var damage  := 0.0
var gold_v  := 0
var score_v := 0
var tamanho := 0.0
var cor     := Color.WHITE
var forma   := ""

var is_chefe   := false
var nome_chefe := ""


var habil_stun_timer : float = 0.0   # Atordoamento por habilidade ativa (elétrico)
var morto      := false
var morte_prog := 0.0
var hit_flash  := 0.0
var heal_flash := 0.0   # Flash verde ao ser curado
var pulse      := 0.0

var habil_timer := 0.0   # Timer genérico para habilidades especiais
var aim_angle   := 0.0   # Ângulo para atirador
var veneno_timer := 0.0
var veneno_dps   := 0.0

var escudo_hits       := 0      # Suporte: absorve N ataques básicos
var escudo_armadura   := 0.0   # Escudeiro: pontos de armadura que absorvem dano antes do HP
var escudo_arm_max    := 0.0
var imune_aoe         := false  # Fantasma: imune a dano de área/corrente/splash
var escudo_explosivo  := false  # Blindada: escudo que bloqueia dano explosivo/AoE

# Regenerador
var regen_sem_dano_timer : float = 0.0
# Divididor
var _dividiu  : bool = false
# Kamikaze
var _kamikaze_explodiu : bool = false
# Necromante
var _necro_timer : float = 0.0
# Campo de gelo (torre)
var gelo_slow   : float = 0.0
# P5 — Lenda do Canhão: queimadura
var queima_dps   : float = 0.0
var queima_timer : float = 0.0
var _habil_cd         := 0.0   # Cooldown dinâmico da habilidade especial

# Fantasma: invisibilidade progressiva
var _invis_timer    : float = 0.0    # >0 = ainda a revelar; 0 = visível
var _invis_revelado : bool  = true   # true = visível por padrão

# Chefe: habilidades especiais exclusivas
var _chefe_habil_timer      : float = 0.0
var _chefe_shield_cd        : float = 0.0   # Colossus: escudo regenerativo
var _chefe_shield_ativo     : bool  = false
var _chefe_berserk_triggered: bool  = false # Berserker: fúria a 50% HP
var _bruxo_buff_timer := 0.0   # Duração do buff do bruxo sobre curandeiro/invocador
var _cura_raio        := 165.0 # Curandeiro: raio de detecção de aliados a curar

var modo_abismo := false

# ── Cache de sprites ──────────────────────────────────────────────────────────
static var _tex_cache : Dictionary = {}

static func _get_tex(t: String) -> Texture2D:
	if t in _tex_cache:
		return _tex_cache[t]
	const BASE := "res://assets/sprites/mobs/"
	const PATHS := {
		"normal":        BASE + "mob_normal.png",
		"fast":          BASE + "mob_fast.png",
		"tank":          BASE + "mob_tank.png",
		"elite":         BASE + "mob_elite.png",
		"berserker":     BASE + "mob_berserker.png",
		"colossus":      BASE + "mob_colossus.png",
		"atirador":      BASE + "mob_atirador.png",
		"curandeiro":    BASE + "mob_curandeiro.png",
		"invocador":     BASE + "mob_invocador.png",
		"bruxo":         BASE + "mob_bruxo.png",
		"suporte":       BASE + "mob_suporte.png",
		"escudeiro":     BASE + "mob_escudeiro.png",
		"fantasma":      BASE + "mob_fantasma.png",
		"vampiro":       BASE + "mob_vampiro.png",
		"espelho":       BASE + "mob_espelho.png",
		"ladrao":        BASE + "mob_ladrao.png",
		"ancora":        BASE + "mob_ancora.png",
		"regenerador":   BASE + "mob_regenerador.png",
		"divididor":     BASE + "mob_divididor.png",
		"divididor_mini":BASE + "mob_divididor_mini.png",
		"kamikaze":      BASE + "mob_kamikaze.png",
		"blindado":      BASE + "mob_blindado.png",
		"necromante":    BASE + "mob_necromante.png",
	}
	var path : String = PATHS.get(t, "")
	var tex  : Texture2D = null
	if path != "" and ResourceLoader.exists(path):
		tex = load(path) as Texture2D
	_tex_cache[t] = tex
	return tex


static func _get_tex_estado(t: String, estado: String) -> Texture2D:
	if estado == "":
		return _get_tex(t)
	var key := t + "::" + estado
	if key in _tex_cache:
		return _tex_cache[key]
	var path := "res://assets/sprites/mobs/mob_%s_%s.png" % [t, estado]
	var tex : Texture2D = null
	if ResourceLoader.exists(path):
		tex = load(path) as Texture2D
	_tex_cache[key] = tex
	return tex


func _get_die_tex() -> Texture2D:
	var frame : int = clampi(int(floor(morte_prog * 5.0)), 0, 4)
	for i in range(frame, -1, -1):
		var tex := _get_tex_estado(tipo, "die_%d" % i)
		if tex != null:
			return tex
	return null

const TIPOS := {
	"normal":    {"hp": 60.0,   "speed": 125.0, "damage": 8.0,  "gold": 1,  "score": 10,  "size": 14.0, "cor": Color(0.0,  0.82, 1.0),  "forma": "circulo"},
	"fast":      {"hp": 30.0,   "speed": 240.0, "damage": 5.0,  "gold": 1,  "score": 15,  "size": 10.0, "cor": Color(0.75, 1.0,  0.1),  "forma": "triangulo"},
	"tank":      {"hp": 230.0,  "speed": 62.0,  "damage": 22.0, "gold": 4,  "score": 35,  "size": 20.0, "cor": Color(1.0,  0.35, 0.1),  "forma": "diamante"},
	"elite":     {"hp": 420.0,  "speed": 88.0,  "damage": 18.0, "gold": 7,  "score": 60,  "size": 17.0, "cor": Color(0.72, 0.18, 1.0),  "forma": "pentagono"},
	"berserker": {"hp": 55.0,   "speed": 300.0, "damage": 12.0, "gold": 4,  "score": 25,  "size": 11.0, "cor": Color(1.0,  0.08, 0.55), "forma": "estrela"},
	"colossus":  {"hp": 2000.0, "speed": 38.0,  "damage": 48.0, "gold": 14, "score": 100, "size": 28.0, "cor": Color(0.65, 0.18, 0.05), "forma": "hexagono"},
	# ── Novos inimigos estratégicos ──────────────────────────────────────────
	"atirador":  {"hp": 130.0,  "speed": 100.0, "damage": 14.0, "gold": 8,  "score": 48,  "size": 17.0, "cor": Color(1.0,  0.30, 0.08), "forma": "seta"},
	"curandeiro":{"hp": 200.0,  "speed": 72.0,  "damage": 7.0,  "gold": 6,  "score": 42,  "size": 19.0, "cor": Color(0.1,  0.95, 0.55), "forma": "cruz"},
	"invocador": {"hp": 340.0,  "speed": 52.0,  "damage": 10.0, "gold": 11, "score": 60,  "size": 22.0, "cor": Color(0.62, 0.12, 0.88), "forma": "espiral"},
	"bruxo":     {"hp": 160.0,  "speed": 62.0,  "damage": 5.0,  "gold": 8,  "score": 52,  "size": 18.0, "cor": Color(0.55, 0.0,  0.72), "forma": "olho"},
	"suporte":   {"hp": 260.0,  "speed": 70.0,  "damage": 8.0,  "gold": 7,  "score": 48,  "size": 20.0, "cor": Color(0.2,  0.55, 1.0),  "forma": "anel_s"},
	# ── Novos inimigos ──────────────────────────────────────────────────────────
	"escudeiro": {"hp": 160.0,  "speed": 68.0,  "damage": 18.0, "gold": 8,  "score": 55,  "size": 18.0, "cor": Color(0.55, 0.82, 1.0),  "forma": "escudo_mob"},
	"fantasma":  {"hp": 40.0,   "speed": 230.0, "damage": 10.0, "gold": 6,  "score": 40,  "size": 13.0, "cor": Color(0.72, 0.0,  1.0),   "forma": "fantasma"},
	# ── Inimigos especiais ───────────────────────────────────────────────────────
	"vampiro":        {"hp": 95.0,  "speed": 155.0, "damage": 14.0, "gold": 7,  "score": 48,  "size": 13.0, "cor": Color(0.72, 0.0,  0.18),  "forma": "vampiro"},
	"espelho":        {"hp": 180.0, "speed": 90.0,  "damage": 15.0, "gold": 12, "score": 70,  "size": 16.0, "cor": Color(0.5,  0.9,  1.0),   "forma": "espelho"},
	"ladrao":         {"hp": 28.0,  "speed": 290.0, "damage": 0.0,  "gold": 4,  "score": 32,  "size": 11.0, "cor": Color(0.95, 0.72, 0.08),  "forma": "ladrao"},
	"ancora":         {"hp": 310.0, "speed": 44.0,  "damage": 22.0, "gold": 11, "score": 60,  "size": 22.0, "cor": Color(0.28, 0.38, 0.65),  "forma": "ancora"},
	# ── Novos inimigos ───────────────────────────────────────────────────────────
	"regenerador":    {"hp": 130.0, "speed": 84.0,  "damage": 13.0, "gold": 8,  "score": 52,  "size": 16.0, "cor": Color(0.12, 0.95, 0.45),  "forma": "regenerador"},
	"divididor":      {"hp": 85.0,  "speed": 148.0, "damage": 10.0, "gold": 6,  "score": 38,  "size": 15.0, "cor": Color(0.88, 0.55, 0.12),  "forma": "divididor"},
	"divididor_mini": {"hp": 36.0,  "speed": 205.0, "damage": 6.0,  "gold": 2,  "score": 18,  "size": 9.0,  "cor": Color(0.88, 0.55, 0.12),  "forma": "divididor"},
	"kamikaze":       {"hp": 48.0,  "speed": 335.0, "damage": 0.0,  "gold": 5,  "score": 30,  "size": 11.0, "cor": Color(1.0,  0.12, 0.05),  "forma": "kamikaze"},
	"blindado":       {"hp": 200.0, "speed": 78.0,  "damage": 25.0, "gold": 10, "score": 58,  "size": 19.0, "cor": Color(0.62, 0.68, 0.72),  "forma": "blindado"},
	"necromante":     {"hp": 215.0, "speed": 54.0,  "damage": 14.0, "gold": 12, "score": 65,  "size": 20.0, "cor": Color(0.42, 0.05, 0.55),  "forma": "necromante"},
}


func _ready() -> void:
	add_to_group("mobs")
	var cfg : Dictionary = TIPOS.get(tipo, TIPOS["normal"]) as Dictionary
	hp      = cfg["hp"]     as float
	max_hp  = cfg["hp"]     as float
	speed   = cfg["speed"]  as float
	damage  = cfg["damage"] as float
	gold_v  = cfg["gold"]   as int
	score_v = cfg["score"]  as int
	tamanho = cfg["size"]   as float
	cor     = cfg["cor"]    as Color
	forma   = cfg["forma"]  as String

	# O mapa define a resistencia/quantidade. Velocidade nao escala por mapa.
	var mapa_info : Dictionary = Salvar.mapa_por_wave(wave_num)
	var hp_mult  : float = float(mapa_info.get("hp_mult", 1.0))
	hp *= hp_mult
	max_hp *= hp_mult

	# Curva em 2 fases: aquecimento suave ate a wave 15, rampa pesada da 15 a 100
	# (builds full precisam sentir pressao). Velocidade fica fixa p/ leitura.
	if wave_num > 8:
		var w_step   : float = float(wave_num - 8)
		var rampa    : float = maxf(0.0, float(wave_num - 15))
		var escala_hp  : float = minf(40.0, 1.0 + w_step * 0.028 + pow(rampa, 1.32) * 0.024)
		var escala_dmg : float = minf(7.0,  1.0 + w_step * 0.010 + pow(rampa, 1.12) * 0.009)
		var loot_esc   : float = 1.0 + w_step * 0.06
		hp     = hp     * escala_hp
		max_hp = max_hp * escala_hp
		damage = damage * escala_dmg
		gold_v  = int(float(gold_v)  * loot_esc)
		score_v = int(float(score_v) * (1.0 + w_step * 0.12))

	# Mini-chefe: versao gigante do tipo com habilidades de chefe ativas
	if is_chefe:
		var chefe_hp_mult : float = 14.0 + float(wave_num) * 0.40
		hp     *= chefe_hp_mult
		max_hp *= chefe_hp_mult
		damage *= 2.2
		tamanho *= 1.75
		speed  *= 0.80
		gold_v  = int(float(gold_v)  * 12.0)
		score_v = int(float(score_v) * 15.0)

	# Purificador: curandeiro e invocador com -25% HP
	if tipo in ["curandeiro", "invocador"] and Salvar.talento_ativo("purif"):
		hp    *= 0.75;  max_hp *= 0.75

	match tipo:
		"curandeiro": _habil_cd = 2.8
		"invocador":  _habil_cd = 4.5
		"bruxo":      _habil_cd = 5.5
	# Suporte carrega escudos → velocidade 90% da base
	if tipo == "suporte":
		speed *= 0.90
	# Escudeiro: armadura escalada pela wave
	if tipo == "escudeiro":
		var arm_scale : float = minf(5.0, 1.0 + float(max(0, wave_num - 1)) * 0.035)
		escudo_armadura = 80.0 * arm_scale
		escudo_arm_max  = escudo_armadura
	# Fantasma: imune a AoE/corrente/splash; começa invisível por 3s
	elif tipo == "fantasma":
		imune_aoe       = true
		_invis_revelado = false
		_invis_timer    = 3.0

		gold_v   = int(float(gold_v)  * 3.5)
		score_v  = int(float(score_v) * 4.0)


func _process(delta: float) -> void:
	if morto:
		morte_prog += delta * 3.0
		if morte_prog >= 1.0:
			queue_free()
		queue_redraw()
		return
	pulse      += delta * 3.0
	hit_flash   = max(0.0, hit_flash  - delta * 6.0)
	heal_flash  = max(0.0, heal_flash - delta * 2.5)

	# Fantasma: conta regressiva da invisibilidade
	if not _invis_revelado:
		_invis_timer = maxf(0.0, _invis_timer - delta)
		if _invis_timer <= 0.0:
			_invis_revelado = true

	# Buff do bruxo: ao expirar, restaura CDs e raio originais
	if _bruxo_buff_timer > 0.0:
		_bruxo_buff_timer -= delta
		if _bruxo_buff_timer <= 0.0:
			match tipo:
				"curandeiro": _habil_cd = 2.8; _cura_raio = 165.0
				"invocador":  _habil_cd = 4.5

	# Veneno (DoT)
	if veneno_dps > 0.0:
		if not Salvar.talento_ativo("s4"):
			# s4 — Veneno Eterno: timer não decai
			veneno_timer = max(0.0, veneno_timer - delta)
			if veneno_timer <= 0.0:
				veneno_dps = 0.0
		if veneno_dps > 0.0:
			hp -= veneno_dps * delta
			if hp <= 0.0:
				_morrer(true)
				return

	# Queimadura (P5 — Lenda do Canhão)
	if queima_dps > 0.0:
		queima_timer = max(0.0, queima_timer - delta)
		if queima_timer <= 0.0:
			queima_dps = 0.0
		else:
			hp -= queima_dps * delta
			if hp <= 0.0:
				_morrer(true)
				return

	# Gelo: decai naturalmente ao sair do alcance da torre (G2 = metade da velocidade)
	if gelo_slow > 0.0:
		var decay_rate : float = 1.0 if Salvar.talento_ativo("g2") else 2.0
		gelo_slow = maxf(0.0, gelo_slow - delta * decay_rate)

	# Blindado: imune a veneno e gelo
	if tipo == "blindado":
		veneno_dps = 0.0
		gelo_slow  = 0.0

	# Regenerador: recupera HP quando não recebe dano por 2s
	if tipo == "regenerador":
		regen_sem_dano_timer += delta
		if regen_sem_dano_timer >= 2.0 and hp < max_hp:
			# G4 — Criotranse: gelo suprime 80% da regen
			var regen_mult : float = 0.20 if (gelo_slow > 0.0 and Salvar.talento_ativo("g4")) else 1.0
			hp = minf(hp + 22.0 * regen_mult * delta, max_hp)
			heal_flash = 0.4

	# Necromante: invoca mob fraco a cada 10s
	if tipo == "necromante":
		_necro_timer += delta
		if _necro_timer >= 10.0:
			_necro_timer = 0.0
			if jogo:
				var noff := Vector2(randf_range(-55.0, 55.0), randf_range(-55.0, 55.0))
				jogo.spawnar_mob_proximo(global_position + noff, "normal")

	var torres = get_tree().get_nodes_in_group("torre")
	if torres.is_empty():
		return

	var torre_node  = torres[0]
	var torre_pos   : Vector2 = (torre_node as Node2D).global_position
	var dir         : Vector2 = (torre_pos - global_position).normalized()
	var dist_torre  : float   = global_position.distance_to(torre_pos)
	if dir.length_squared() > 0.001:
		aim_angle = atan2(dir.y, dir.x)

	# ── Atirador: avança até a borda do alcance da torre e atira de lá ─────
	if tipo == "atirador":
		# Detecta o alcance real da torre a partir do nó já obtido
		var t_range : float = 175.0
		var r_ati = torre_node.get("range_r")
		if r_ati != null and float(r_ati) > 50.0:
			t_range = float(r_ati)
		var parar_em : float = t_range - 15.0
		if dist_torre > parar_em:
			# Ainda fora do alcance — avança
			position += dir * speed * delta
		else:
			# Dentro do alcance — para e atira
			habil_timer += delta
			if habil_timer >= 2.0:
				habil_timer = 0.0
				if jogo: jogo.dano_na_torre(damage * (2.0 if is_chefe else 1.0))
				Som.tiro()
		if dist_torre < 28.0:
			if jogo: jogo.dano_na_torre(damage)
			_morrer(false)
		queue_redraw()
		return

	# ── Atordoamento por habilidade ativa ───────────────────────────────────
	if habil_stun_timer > 0.0:
		habil_stun_timer = maxf(0.0, habil_stun_timer - delta)
		queue_redraw()
		return

	# ── Velocidade com bônus de suporte próximo ─────────────────────────────
	var move_speed := speed
	if tipo != "suporte":
		for smob in get_tree().get_nodes_in_group("mobs"):
			if not is_instance_valid(smob): continue
			if smob.get("tipo") == "suporte" and not smob.get("morto"):
				if global_position.distance_to((smob as Node2D).global_position) < 135.0:
					move_speed *= 1.90
					break
	else:
		# Suporte aplica escudo de 5 hits a aliados próximos sem escudo
		for smob in get_tree().get_nodes_in_group("mobs"):
			if not is_instance_valid(smob) or smob == self: continue
			if smob.get("morto"): continue
			if global_position.distance_to((smob as Node2D).global_position) < 135.0:
				if (smob.get("escudo_hits") as int) == 0:
					smob.set("escudo_hits", 10 if is_chefe else 5)

	# ── Habilidades especiais ────────────────────────────────────────────────
	habil_timer += delta
	match tipo:
		"curandeiro":
			if habil_timer >= _habil_cd:
				habil_timer = 0.0
				_curar_aliado_proximo()
		"invocador":
			if habil_timer >= _habil_cd:
				habil_timer = 0.0
				_invocar_mobs()
		"bruxo":
			if habil_timer >= _habil_cd:
				habil_timer = 0.0
				if jogo:
					jogo.aplicar_maldicao_torre(6.0 if is_chefe else 3.5)
					jogo.aplicar_punicao_perfuracao(4.0)
				_impulsionar_aliados_proximos()

	# Chefe: habilidades especiais por tipo
	if is_chefe:
		_processar_habil_chefe(delta)

	if gelo_slow > 0.0:
		move_speed *= (1.0 - gelo_slow)

	position += dir * move_speed * delta

	if dist_torre < 30.0:
		match tipo:
			"ladrao":
				# Ladrão: rouba ouro, não causa dano
				if jogo: jogo.call("roubar_ouro", randi_range(8, 18))
			"vampiro":
				# Vampiro: causa dano E cura a si mesmo
				if jogo: jogo.dano_na_torre(damage)
				hp = minf(hp + damage * 0.85, max_hp)
				heal_flash = 1.0
				_morrer(false)
				return
			"kamikaze":
				# Kamikaze: explode em área ao chegar na torre
				if not _kamikaze_explodiu:
					_kamikaze_explodiu = true
					var dano_exp : float = 55.0 + max_hp * 0.45
					if jogo:
						jogo.dano_na_torre(dano_exp)
						jogo.mob_explodiu(global_position)
					Som.explosao_forte()
					# AoE: onda de choque empurra/danifica mobs próximos
					for m in get_tree().get_nodes_in_group("mobs"):
						if is_instance_valid(m) and m != self and not (m.get("morto") as bool):
							if global_position.distance_to((m as Node2D).global_position) <= 90.0:
								m.receber_dano(dano_exp * 0.30)
			_:
				if jogo: jogo.dano_na_torre(damage)
		_morrer(false)

	queue_redraw()


func _curar_aliado_proximo() -> void:
	var mobs = get_tree().get_nodes_in_group("mobs")
	var alvo  = null
	var menor_ratio : float = 1.0
	for mob in mobs:
		if not is_instance_valid(mob) or mob == self: continue
		if mob.get("morto"): continue
		var mhp : float = mob.get("max_hp") as float
		if mhp <= 0.0: continue
		var ratio : float = (mob.get("hp") as float) / mhp
		if ratio < menor_ratio and global_position.distance_to((mob as Node2D).global_position) < _cura_raio:
			menor_ratio = ratio
			alvo = mob
	if alvo:
		alvo.set("hp", min((alvo.get("hp") as float) + 45.0, alvo.get("max_hp") as float))
		alvo.set("heal_flash", 1.0)


func _invocar_mobs() -> void:
	if jogo:
		for i in range(4):
			var off := Vector2(randf_range(-70.0, 70.0), randf_range(-70.0, 70.0))
			jogo.spawnar_mob_proximo(global_position + off, "normal")


func _impulsionar_aliados_proximos() -> void:
	for mob in get_tree().get_nodes_in_group("mobs"):
		if not is_instance_valid(mob) or mob == self: continue
		if mob.get("morto"): continue
		if global_position.distance_to((mob as Node2D).global_position) > 180.0: continue
		match mob.get("tipo") as String:
			"invocador":
				# Força a próxima invocação imediatamente
				mob.set("habil_timer", mob.get("_habil_cd"))
				mob.set("_habil_cd", 1.5)
				mob.set("_bruxo_buff_timer", 6.0)
			"curandeiro":
				# Força cura imediata, reduz CD e aumenta raio
				mob.set("habil_timer", mob.get("_habil_cd"))
				mob.set("_habil_cd",   1.0)
				mob.set("_cura_raio",  260.0)
				mob.set("_bruxo_buff_timer", 6.0)


func _invocar_para_boss(qtd: int) -> void:
	if not jogo: return
	var pool := ["normal", "fast", "elite", "berserker"]
	for _i in range(qtd):
		var t : String = pool[randi() % pool.size()]
		var off := Vector2(randf_range(-140.0, 140.0), randf_range(-140.0, 140.0))
		jogo.spawnar_mob_proximo(global_position + off, t)


func _grito_de_guerra() -> void:
	Som.impacto()
	for mob in get_tree().get_nodes_in_group("mobs"):
		if not is_instance_valid(mob) or mob == self: continue
		if mob.get("morto"): continue
		mob.call("_aplicar_grito_guerra")




func _processar_habil_chefe(delta: float) -> void:
	_chefe_shield_cd    = maxf(0.0, _chefe_shield_cd - delta)
	_chefe_habil_timer += delta

	match tipo:
		"curandeiro":
			# Auto-cura agressiva: 10% HP a cada 4s
			if _chefe_habil_timer >= 4.0:
				_chefe_habil_timer = 0.0
				hp         = minf(hp + max_hp * 0.10, max_hp)
				heal_flash = 1.0
		"invocador":
			# Invoca 8 mobs normais a cada 3s
			if _chefe_habil_timer >= 3.0 and jogo:
				_chefe_habil_timer = 0.0
				for _ci in range(8):
					var coff := Vector2(randf_range(-120.0, 120.0), randf_range(-120.0, 120.0))
					jogo.spawnar_mob_proximo(global_position + coff, "normal")
		"berserker":
			# Ao atingir 50% HP, velocidade ×2 permanente (fúria de chefe)
			if not _chefe_berserk_triggered and max_hp > 0.0 and hp / max_hp <= 0.50:
				_chefe_berserk_triggered = true
				speed     *= 2.0
				hit_flash  = 1.0
				heal_flash = 1.0
		"colossus":
			# Regenera o escudo a cada 8s
			if _chefe_shield_cd <= 0.0:
				_chefe_shield_cd    = 8.0
				_chefe_shield_ativo = true
				heal_flash          = 0.5
		"fantasma":
			# Invoca 2 fantasmas a cada 8s
			if _chefe_habil_timer >= 8.0 and jogo:
				_chefe_habil_timer = 0.0
				for _fi in range(2):
					var foff := Vector2(randf_range(-90.0, 90.0), randf_range(-90.0, 90.0))
					jogo.spawnar_mob_proximo(global_position + foff, "fantasma")
		"escudeiro":
			# Regenera 15 pontos de armadura por segundo quando acima de 50% HP
			if escudo_arm_max > 0.0 and escudo_armadura < escudo_arm_max:
				if max_hp > 0.0 and hp / max_hp > 0.50:
					escudo_armadura = minf(escudo_armadura + 15.0 * delta, escudo_arm_max)


func receber_dano(dano: float, explosivo: bool = false, critico: bool = false) -> void:
	if morto:
		return
	# Escudo blindada: bloqueia dano explosivo/AoE
	if escudo_explosivo and explosivo:
		hit_flash = 1.0
		if jogo: jogo.mostrar_dano(global_position, 0.0, Color(1.0, 0.65, 0.10))
		return
	# Escudo do suporte: absorve ataques básicos sem dano
	if escudo_hits > 0:
		escudo_hits -= 1
		hit_flash    = 1.0
		if jogo: jogo.mostrar_dano(global_position, dano, Color(0.55, 0.72, 0.88))
		return
	var dano_efetivo : float = dano
	# Escudeiro: armadura absorve dano antes do HP
	if escudo_armadura > 0.0:
		escudo_armadura -= dano_efetivo
		hit_flash = 1.0
		if escudo_armadura >= 0.0:
			if jogo: jogo.mostrar_dano(global_position, dano_efetivo, Color(0.55, 0.88, 1.0))
			return
		else:
			dano_efetivo    = -escudo_armadura   # overflow entra no HP
			escudo_armadura = 0.0
	var dano_real : float = dano_efetivo
	# s2 — Corrosão Arcana / Predador: mobs envenenados recebem dano extra
	if veneno_dps > 0.0:
		if gelo_slow > 0.0 and Salvar.talento_ativo("predador"):
			dano_real *= 1.35   # Predador (veneno+gelo): +35%
		elif Salvar.talento_ativo("s2"):
			dano_real *= 1.20   # Corrosão Arcana: +20%
	# Anti-Tanque: +30% dano em mobs com HP atual > 300
	if hp > 300.0 and Salvar.talento_ativo("anti_t"):
		dano_real *= 1.30
	# Cazador de Bosses: +40% dano em chefes
	if is_chefe and Salvar.talento_ativo("cazador"):
		dano_real *= 1.40
	# Armadura de chefe: absorve parte do dano
	if is_chefe:
		dano_real *= 0.72
	# Colossus chefe: escudo absorve 1 hit a cada 8s
	if is_chefe and tipo == "colossus" and _chefe_shield_ativo:
		_chefe_shield_ativo = false
		hit_flash = 1.0
		if jogo: jogo.mostrar_dano(global_position, 0.0, Color(0.55, 0.88, 1.0))
		return
	# Tank chefe: 30% de chance de refletir dano na torre
	if is_chefe and tipo == "tank" and randf() < 0.30 and jogo:
		jogo.dano_na_torre(dano_real * 0.35)
	hp       -= dano_real
	hit_flash = 1.0
	regen_sem_dano_timer = 0.0  # Interrompe regeneração
	if jogo:
		var cor_dano := Color(1.0, 0.46, 0.08) if critico else Color(1.0, 0.88, 0.30)
		var off_dano := Vector2(0.0, -8.0) if critico else Vector2.ZERO
		jogo.mostrar_dano(global_position + off_dano, dano_real, cor_dano)
	if jogo and (dano_real >= 60.0 or is_chefe) and jogo.has_method("registrar_impacto_combate"):
		jogo.call("registrar_impacto_combate", global_position, cor, dano_real >= 140.0 or is_chefe)
	if jogo: jogo.call("registrar_dano_causado", dano_real)
	if hp <= 0.0:
		_morrer(true)


func _morrer(por_tiro: bool) -> void:
	if morto:
		return
	morto = true
	remove_from_group("mobs")
	Som.morte_mob()
	if por_tiro and jogo:
		jogo.mob_morreu(gold_v, score_v)
		if is_chefe:
			jogo.boss_morreu()
		if jogo.has_method("registrar_impacto_combate"):
			jogo.call("registrar_impacto_combate", global_position, cor, is_chefe)
		jogo.mob_explodiu(global_position)
	# s3 — Praga Sombria: morte de mob envenenado espalha veneno para vizinhos
	if por_tiro and veneno_dps > 0.0 and Salvar.talento_ativo("s3"):
		for vizinho in get_tree().get_nodes_in_group("mobs"):
			if not is_instance_valid(vizinho) or vizinho == self: continue
			if global_position.distance_to((vizinho as Node2D).global_position) <= 100.0:
				vizinho.set("veneno_dps",   maxf(vizinho.get("veneno_dps") as float, 12.0))
				vizinho.set("veneno_timer", 5.0)
	# S5 — Metamorfose: conta mortes de mobs envenenados
	if por_tiro and veneno_dps > 0.0 and jogo:
		jogo.call("registrar_morte_envenenado")
	# G3 — Avalanche: morte com gelo ativo espalha gelo nos vizinhos em 60px
	if por_tiro and gelo_slow > 0.15 and Salvar.talento_ativo("g3"):
		for vizinho in get_tree().get_nodes_in_group("mobs"):
			if not is_instance_valid(vizinho) or vizinho == self: continue
			if global_position.distance_to((vizinho as Node2D).global_position) <= 60.0:
				vizinho.set("gelo_slow", maxf(vizinho.get("gelo_slow") as float, 0.80))
	# Divididor: ao morrer divide-se em 2 minis
	if por_tiro and tipo == "divididor" and not _dividiu:
		_dividiu = true
		if jogo:
			for _di in range(2):
				var doff := Vector2(randf_range(-45.0, 45.0), randf_range(-45.0, 45.0))
				jogo.spawnar_mob_proximo(global_position + doff, "divididor_mini")

	# Berserker: explode ao ser abatido por projétil
	if por_tiro and tipo == "berserker":
		var torres = get_tree().get_nodes_in_group("torre")
		for t in torres:
			if is_instance_valid(t):
				var dist : float = global_position.distance_to(t.global_position)
				if dist <= 120.0:
					var dano_exp : float = 20.0 * (1.0 - dist / 120.0)
					if jogo:
						jogo.dano_na_torre(dano_exp)


# ── Desenho ───────────────────────────────────────────────────────────────────

func _draw() -> void:
	var p : float = sin(pulse) * 0.2 + 0.8
	var c : Color = cor if hit_flash < 0.05 else Color(1.0, 1.0, 1.0)

	if morto:
		var am : float = 1.0 - morte_prog
		var die_tex := _get_die_tex()
		if die_tex != null:
			var die_sz : float = tamanho * 3.8 * (1.0 + morte_prog * 0.25)
			draw_set_transform(Vector2.ZERO, aim_angle + PI * 0.5, Vector2.ONE)
			draw_texture_rect(die_tex, Rect2(-die_sz * 0.5, -die_sz * 0.5, die_sz, die_sz), false, Color(1.0, 1.0, 1.0, am))
			draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
			return
		if tipo == "berserker":
			# Berserker: faíscas explodindo para fora
			var rm_b : float = tamanho * (1.0 + morte_prog * 2.5)
			draw_circle(Vector2.ZERO, rm_b * 0.5, Color(1.0, 0.45, 0.05, am * 0.9))
			for i in range(12):
				var sa : float = float(i) * TAU / 12.0
				var dist_s : float = tamanho * morte_prog * 5.5
				var sp := Vector2(cos(sa), sin(sa)) * dist_s
				draw_circle(sp, maxf(3.5 * (1.0 - morte_prog), 0.5), Color(1.0, 0.5, 0.05, am * 0.9))
				if morte_prog < 0.6:
					draw_circle(sp + Vector2(cos(sa), sin(sa)) * 7.0, maxf(2.0 * (1.0 - morte_prog), 0.2), Color(1.0, 0.9, 0.3, am * 0.7))
		else:
			# Morte genérica: expansão suave
			var rm : float = tamanho * (1.0 + morte_prog * 3.5)
			for i in range(4, 0, -1):
				draw_circle(Vector2.ZERO, rm + float(i) * 5.0,
						Color(c.r, c.g, c.b, am * 0.12 / float(i)))
			draw_circle(Vector2.ZERO, rm * 0.35, Color(1.0, 1.0, 0.85, am))
		return

	# Glow de cura (curandeiro recebeu cura)
	if heal_flash > 0.01:
		draw_arc(Vector2.ZERO, tamanho + 10.0, 0.0, TAU, 24,
				Color(0.1, 1.0, 0.45, heal_flash * 0.85), 3.0)

	# Gelo: anel azul gélido sobre mob lento
	if gelo_slow > 0.15:
		draw_arc(Vector2.ZERO, tamanho + 6.0, 0.0, TAU, 24,
				Color(0.45, 0.82, 1.0, gelo_slow * 0.75), 3.0)
		draw_arc(Vector2.ZERO, tamanho + 2.0, 0.0, TAU, 16,
				Color(0.75, 0.92, 1.0, gelo_slow * 0.40), 1.5)
	if hit_flash > 0.05:
		var hf : float = clampf(hit_flash, 0.0, 1.0)
		draw_arc(Vector2.ZERO, tamanho + 7.0 + (1.0 - hf) * 12.0, 0.0, TAU, 32,
				Color(1.0, 1.0, 1.0, hf * 0.85), 2.8)
		draw_circle(Vector2.ZERO, tamanho * 0.45, Color(1.0, 0.95, 0.65, hf * 0.18))

	var _tex := _get_tex(tipo)
	var _sprite_desenhado := false
	if _tex != null:
		var _sz    : float = tamanho * 3.2
		var _alpha : float = p
		if not _invis_revelado and tipo == "fantasma":
			_alpha *= 0.15
		var _tint := Color(1.0, 1.0, 1.0, _alpha) if hit_flash < 0.05 else Color(1.0, 1.0, 1.0, 0.95)
		draw_set_transform(Vector2.ZERO, aim_angle + PI * 0.5, Vector2.ONE)
		draw_texture_rect(_tex, Rect2(-_sz * 0.5, -_sz * 0.5, _sz, _sz), false, _tint)
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		_sprite_desenhado = true

	match (forma if not _sprite_desenhado else ""):
		"circulo":
			draw_circle(Vector2.ZERO, tamanho,
					Color(c.r * 0.25, c.g * 0.25, c.b * 0.25, 0.9))
			draw_arc(Vector2.ZERO, tamanho, 0.0, TAU, 48,
					Color(c.r, c.g, c.b, p), 2.5)
			draw_circle(Vector2.ZERO, tamanho * 0.38,
					Color(c.r, c.g, c.b, 0.75 * p))

		"triangulo":
			var pts_t := PackedVector2Array()
			for i in range(3):
				var a := float(i) * TAU / 3.0 - PI / 2.0
				pts_t.append(Vector2(cos(a), sin(a)) * tamanho)
			draw_polygon(pts_t, _cores(pts_t.size(), Color(c.r * 0.2, c.g * 0.2, 0.0, 0.9)))
			var borda_t := PackedVector2Array(pts_t)
			borda_t.append(pts_t[0])
			draw_polyline(borda_t, Color(c.r, c.g, c.b, p), 2.5)

		"diamante":
			var pts_d := PackedVector2Array([
				Vector2(0.0, -tamanho * 1.4),
				Vector2(tamanho, 0.0),
				Vector2(0.0,  tamanho * 1.4),
				Vector2(-tamanho, 0.0),
			])
			draw_polygon(pts_d, _cores(pts_d.size(), Color(c.r * 0.22, c.g * 0.08, 0.0, 0.9)))
			var borda_d := PackedVector2Array(pts_d)
			borda_d.append(pts_d[0])
			draw_polyline(borda_d, Color(c.r, c.g, c.b, p), 2.5)

		"pentagono":
			var pts_p := PackedVector2Array()
			for i in range(5):
				var a := float(i) * TAU / 5.0 - PI / 2.0
				pts_p.append(Vector2(cos(a), sin(a)) * tamanho)
			draw_polygon(pts_p, _cores(pts_p.size(), Color(c.r * 0.18, c.g * 0.06, c.b * 0.25, 0.92)))
			var borda_p := PackedVector2Array(pts_p)
			borda_p.append(pts_p[0])
			for i in range(2, 0, -1):
				draw_polyline(borda_p, Color(c.r, c.g, c.b, p * 0.4 / float(i)), float(i) * 2.0)
			draw_polyline(borda_p, Color(c.r, c.g, c.b, p), 2.0)
			draw_circle(Vector2.ZERO, tamanho * 0.30, Color(c.r, c.g, c.b, 0.55 * p))

		"estrela":
			var pts_s := PackedVector2Array()
			for i in range(8):
				var a   := float(i) * TAU / 8.0 - PI / 2.0
				var rad : float = tamanho if i % 2 == 0 else tamanho * 0.42
				pts_s.append(Vector2(cos(a), sin(a)) * rad)
			draw_polygon(pts_s, _cores(pts_s.size(), Color(c.r * 0.22, 0.02, c.b * 0.1, 0.92)))
			var borda_s := PackedVector2Array(pts_s)
			borda_s.append(pts_s[0])
			draw_polyline(borda_s, Color(c.r, c.g, c.b, p), 2.0)
			draw_circle(Vector2.ZERO, tamanho * 0.22, Color(1.0, 0.3, 0.6, p))

		"hexagono":
			# Hexágono duplo — imponente
			for pass_i in range(2):
				var r_hex : float = tamanho * (1.0 if pass_i == 0 else 0.52)
				var pts_h := PackedVector2Array()
				for i in range(6):
					var a := float(i) * TAU / 6.0 + PI / 6.0
					pts_h.append(Vector2(cos(a), sin(a)) * r_hex)
				if pass_i == 0:
					draw_polygon(pts_h, _cores(pts_h.size(), Color(c.r * 0.20, c.g * 0.06, 0.02, 0.95)))
				var borda_h := PackedVector2Array(pts_h)
				borda_h.append(pts_h[0])
				var lw_h : float = 3.0 if pass_i == 0 else 1.5
				var alp_h : float = p * 0.55 if pass_i == 0 else p
				draw_polyline(borda_h, Color(c.r, c.g, c.b, alp_h), lw_h)
			draw_circle(Vector2.ZERO, tamanho * 0.25, Color(c.r + 0.2, c.g, c.b, p * 0.8))

		# ── Novos inimigos — visuais elaborados ─────────────────────────────

		"seta":
			# Atirador — flecha de precisão com retículo de mira
			var fwd := Vector2(cos(aim_angle), sin(aim_angle))
			var lat := Vector2(-sin(aim_angle), cos(aim_angle))
			# Retículo quando parado e mirando
			if habil_timer > 0.3:
				var mp : float = min(habil_timer / 2.0, 1.0)
				draw_arc(Vector2.ZERO, tamanho * 2.6, 0.0, TAU, 32,
						Color(c.r, c.g, c.b, mp * 0.55 * p), 1.8)
				for i in range(4):
					var ma := float(i) * TAU / 4.0 + PI / 4.0
					var mv := Vector2(cos(ma + aim_angle), sin(ma + aim_angle))
					draw_line(mv * tamanho * 1.7, mv * tamanho * 3.0,
							Color(c.r, c.g, c.b, mp * 0.80), 1.5)
			# Corpo da flecha (forma de seta com haste)
			var pts_a := PackedVector2Array([
				fwd  * tamanho * 1.30,
				fwd  * tamanho * 0.12 + lat * tamanho * 0.68,
				fwd  * tamanho * 0.12 + lat * tamanho * 0.26,
				fwd  * (-tamanho * 1.0) + lat * tamanho * 0.42,
				fwd  * (-tamanho * 1.0) - lat * tamanho * 0.42,
				fwd  * tamanho * 0.12 - lat * tamanho * 0.26,
				fwd  * tamanho * 0.12 - lat * tamanho * 0.68,
			])
			draw_polygon(pts_a, _cores(pts_a.size(), Color(c.r * 0.20, c.g * 0.06, 0.0, 0.92)))
			var brd_a := PackedVector2Array(pts_a); brd_a.append(pts_a[0])
			draw_polyline(brd_a, Color(c.r, c.g, c.b, p), 2.8)
			# Linha de highlight na haste
			draw_line(fwd * (-tamanho * 0.85), fwd * tamanho * 1.05,
					Color(1.0, 1.0, 0.70, 0.55 * p), 1.8)
			# Ponta brilhante
			draw_circle(fwd * tamanho * 1.25, tamanho * 0.13, Color(1.0, 0.85, 0.3, p))

		"cruz":
			# Curandeiro — cruz médica com orbes de cura orbitando
			var cw : float = tamanho * 0.40
			var cl : float = tamanho * 1.05
			# Preenchimento dos braços
			draw_rect(Rect2(-cw, -cl, cw * 2.0, cl * 2.0),
					Color(c.r * 0.10, c.g * 0.16, c.b * 0.10, 0.92))
			draw_rect(Rect2(-cl, -cw, cl * 2.0, cw * 2.0),
					Color(c.r * 0.10, c.g * 0.16, c.b * 0.10, 0.92))
			# Borda brilhante
			draw_rect(Rect2(-cw, -cl, cw * 2.0, cl * 2.0),
					Color(c.r, c.g, c.b, p), false, 2.5)
			draw_rect(Rect2(-cl, -cw, cl * 2.0, cw * 2.0),
					Color(c.r, c.g, c.b, p), false, 2.5)
			# Centro branco luminoso
			draw_circle(Vector2.ZERO, cw * 0.80, Color(c.r, c.g, c.b, 0.75 * p))
			draw_circle(Vector2.ZERO, cw * 0.36, Color(1.0, 1.0, 1.0, 0.90 * p))
			# 4 orbes de cura orbitando
			for i in range(4):
				var oa := float(i) * TAU / 4.0 + pulse * 0.65
				var op := Vector2(cos(oa), sin(oa)) * tamanho * 1.65
				draw_circle(op, tamanho * 0.22, Color(c.r, c.g, c.b, 0.85 * p))
				draw_circle(op, tamanho * 0.11, Color(1.0, 1.0, 1.0, 0.75 * p))
			# Aura de cura pulsante
			var ar : float = tamanho * 1.9 + sin(pulse * 1.8) * tamanho * 0.22
			draw_arc(Vector2.ZERO, ar, 0.0, TAU, 32,
					Color(c.r, c.g, c.b, 0.25 * p), 1.8)

		"espiral":
			# Invocador — portal dimensional com runas orbitais
			var r1 := pulse * 0.28
			var r2 := -(pulse * 0.55)
			var r3 := pulse * 0.88
			# Anel externo de 8 runas
			for i in range(8):
				var ra := float(i) * TAU / 8.0 + r1
				draw_circle(Vector2(cos(ra), sin(ra)) * tamanho * 1.45,
						tamanho * 0.13, Color(c.r, c.g, c.b, 0.72 * p))
			draw_arc(Vector2.ZERO, tamanho * 1.45, r1, r1 + TAU * 0.65, 32,
					Color(c.r, c.g, c.b, 0.28 * p), 1.5)
			# Anel médio girando ao contrário
			draw_arc(Vector2.ZERO, tamanho * 0.95, r2, r2 + TAU * 0.82, 32,
					Color(c.r, c.g, c.b, 0.78 * p), 2.8)
			draw_arc(Vector2.ZERO, tamanho * 0.95, r2 + PI, r2 + PI + TAU * 0.12, 10,
					Color(c.r + 0.25, c.g, c.b, 0.65 * p), 2.8)
			# 3 braços espirais internos
			for i in range(3):
				var base_a : float = float(i) * TAU / 3.0 + r3
				var pts_e := PackedVector2Array()
				for j in range(9):
					var frac : float = float(j) / 8.0
					var ea   : float = base_a + frac * TAU * 0.32
					var er   : float = tamanho * (0.14 + frac * 0.60)
					pts_e.append(Vector2(cos(ea), sin(ea)) * er)
				draw_polyline(pts_e, Color(c.r, c.g, c.b, 0.68 * p), 2.2)
			# Core do portal
			draw_circle(Vector2.ZERO, tamanho * 0.32, Color(c.r * 0.12, c.g * 0.04, c.b * 0.20, 0.95))
			draw_arc(Vector2.ZERO, tamanho * 0.32, 0.0, TAU, 32,
					Color(c.r, c.g, c.b, 0.55 * p), 2.5)
			draw_circle(Vector2.ZERO, tamanho * 0.15, Color(c.r + 0.30, c.g + 0.10, c.b, p))
			draw_circle(Vector2.ZERO, tamanho * 0.07, Color(1.0, 1.0, 1.0, 1.0))

		"olho":
			# Bruxo — olho arcano com sigilo hexagonal e pupila rasgada
			# Sigilo externo girando
			var rot_h := pulse * 0.20
			for i in range(6):
				var ha := float(i) * TAU / 6.0 + rot_h
				draw_circle(Vector2(cos(ha), sin(ha)) * tamanho * 1.65,
						tamanho * 0.12, Color(c.r, c.g, c.b, 0.62 * p))
			draw_arc(Vector2.ZERO, tamanho * 1.65, rot_h, rot_h + TAU * 0.60, 24,
					Color(c.r, c.g, c.b, 0.28 * p), 1.5)
			# Esclera (fundo do olho)
			var pts_o := PackedVector2Array()
			for i in range(32):
				var oa := float(i) * TAU / 32.0
				pts_o.append(Vector2(cos(oa) * tamanho * 1.12, sin(oa) * tamanho * 0.58))
			draw_polygon(pts_o, _cores(pts_o.size(), Color(0.06, 0.02, 0.10, 0.95)))
			var brd_o := PackedVector2Array(pts_o); brd_o.append(pts_o[0])
			draw_polyline(brd_o, Color(c.r, c.g, c.b, p), 2.8)
			# Íris colorida
			draw_circle(Vector2.ZERO, tamanho * 0.38, Color(c.r * 0.50, 0.0, c.b * 0.85, 0.92))
			# Pupila rasgada (vertical)
			var pup := PackedVector2Array([
				Vector2( 0.0,            -tamanho * 0.30),
				Vector2( tamanho * 0.11, -tamanho * 0.05),
				Vector2( tamanho * 0.11,  tamanho * 0.05),
				Vector2( 0.0,             tamanho * 0.30),
				Vector2(-tamanho * 0.11,  tamanho * 0.05),
				Vector2(-tamanho * 0.11, -tamanho * 0.05),
			])
			draw_polygon(pup, _cores(pup.size(), Color(0.0, 0.0, 0.0, 1.0)))
			# Reflexo de luz
			draw_circle(Vector2(-tamanho * 0.14, -tamanho * 0.14),
					tamanho * 0.08, Color(1.0, 1.0, 1.0, 0.80))
			# Aura de maldição intensifica quando habilidade pronta
			if habil_timer > 3.5:
				var cp : float = (habil_timer - 3.5) / 2.0
				for ci in range(3):
					draw_arc(Vector2.ZERO, tamanho * (1.20 + float(ci) * 0.28),
							rot_h + float(ci) * 0.8, rot_h + float(ci) * 0.8 + TAU * 0.72, 24,
							Color(0.85, 0.0, 1.0, cp * (0.65 - float(ci) * 0.18) * p), 2.5)

		"anel_s":
			# Suporte — escudo de aura com dois anéis pulsantes e 6 orbes
			# Dois anéis de aura expandindo (offset de fase)
			for wave_i in range(2):
				var wf : float = fmod(pulse * 0.38 + float(wave_i) * 0.5, 1.0)
				var wr : float = tamanho * (1.3 + wf * 1.1)
				draw_arc(Vector2.ZERO, wr, 0.0, TAU, 32,
						Color(c.r, c.g, c.b, (1.0 - wf) * 0.38 * p), 2.2)
			# Corpo principal
			draw_circle(Vector2.ZERO, tamanho, Color(c.r * 0.09, c.g * 0.09, c.b * 0.18, 0.90))
			draw_arc(Vector2.ZERO, tamanho, 0.0, TAU, 32, Color(c.r, c.g, c.b, p), 3.0)
			# Anel interno
			draw_arc(Vector2.ZERO, tamanho * 0.55, 0.0, TAU, 24,
					Color(c.r, c.g, c.b, 0.55 * p), 2.0)
			# 6 orbes alternando dois raios
			for i in range(6):
				var oa  := float(i) * TAU / 6.0 + pulse * 0.50
				var or2 : float = tamanho if i % 2 == 0 else tamanho * 0.55
				var os  : float = tamanho * (0.19 if i % 2 == 0 else 0.13)
				draw_circle(Vector2(cos(oa), sin(oa)) * or2, os,
						Color(c.r, c.g, c.b, 0.90 * p))
				draw_circle(Vector2(cos(oa), sin(oa)) * or2, os * 0.50,
						Color(1.0, 1.0, 1.0, 0.70 * p))
			# Hub central
			draw_circle(Vector2.ZERO, tamanho * 0.28, Color(c.r, c.g, c.b, 0.80 * p))
			draw_circle(Vector2.ZERO, tamanho * 0.13, Color(1.0, 1.0, 1.0, 0.90 * p))

		"escudo_mob":
			# Escudeiro — escudo kite com anel de armadura
			var pts_sh := PackedVector2Array([
				Vector2(0.0,              -tamanho * 1.30),
				Vector2( tamanho * 0.88,  -tamanho * 0.45),
				Vector2( tamanho * 0.88,   tamanho * 0.45),
				Vector2(0.0,               tamanho * 1.30),
				Vector2(-tamanho * 0.88,   tamanho * 0.45),
				Vector2(-tamanho * 0.88,  -tamanho * 0.45),
			])
			draw_polygon(pts_sh, _cores(pts_sh.size(), Color(c.r * 0.12, c.g * 0.15, c.b * 0.22, 0.94)))
			var brd_sh := PackedVector2Array(pts_sh); brd_sh.append(pts_sh[0])
			draw_polyline(brd_sh, Color(c.r, c.g, c.b, p), 2.8)
			# Runa em cruz no centro
			draw_line(Vector2(0, -tamanho * 0.55), Vector2(0,  tamanho * 0.55), Color(c.r, c.g, c.b, 0.55 * p), 1.5)
			draw_line(Vector2(-tamanho * 0.55, 0), Vector2(tamanho * 0.55, 0),  Color(c.r, c.g, c.b, 0.55 * p), 1.5)
			draw_circle(Vector2.ZERO, tamanho * 0.20, Color(c.r, c.g, c.b, 0.50 * p))
			# Anel de armadura (arco proporcional à armadura restante)
			if escudo_arm_max > 0.0:
				var arm_r : float = clampf(escudo_armadura / escudo_arm_max, 0.0, 1.0)
				draw_arc(Vector2.ZERO, tamanho * 1.6, 0.0, TAU, 32,
						Color(0.4, 0.55, 0.65, 0.22), 3.0)
				if arm_r > 0.01:
					draw_arc(Vector2.ZERO, tamanho * 1.6, -PI / 2.0,
							-PI / 2.0 + TAU * arm_r, int(32.0 * arm_r + 4),
							Color(0.7, 0.92, 1.0, 0.90 * p), 3.5)

		"fantasma":
			# Fantasma — forma etérea semi-transparente, imune a AoE
			# Invisibilidade progressiva: alpha baixo enquanto _invis_timer > 0
			var reveal_t : float = 3.0   # duração total do reveal
			var reveal_p : float = 1.0   # 0=invisível, 1=visível
			if not _invis_revelado:
				reveal_p = clampf(1.0 - _invis_timer / reveal_t, 0.0, 1.0)
			var alpha_f : float = (0.38 + sin(pulse) * 0.14) * reveal_p
			# Quando ainda invisível, mostra apenas um contorno tênue
			if reveal_p < 0.12:
				# Quase invisível — apenas ondulação sutil
				draw_arc(Vector2.ZERO, tamanho * 1.05, 0.0, TAU, 24,
						Color(c.r, c.g, c.b, reveal_p * 0.25), 1.2)
			else:
				# Corpo central translúcido
				draw_circle(Vector2.ZERO, tamanho,
						Color(c.r * 0.08, c.g * 0.02, c.b * 0.18, alpha_f * 0.82))
				draw_arc(Vector2.ZERO, tamanho, 0.0, TAU, 32,
						Color(c.r, c.g, c.b, alpha_f), 2.0)
				# 3 wisps orbitando
				for i in range(3):
					var wa : float = float(i) * TAU / 3.0 + pulse * 0.85
					var wp := Vector2(cos(wa), sin(wa)) * tamanho * 1.25
					draw_circle(wp, tamanho * 0.22, Color(c.r, c.g, c.b, alpha_f * 0.60))
					draw_circle(wp, tamanho * 0.10, Color(1.0, 0.8, 1.0, alpha_f * 0.80))
				# Olhos brilhantes
				for i in range(2):
					var ex : float = (float(i) - 0.5) * tamanho * 0.55
					draw_circle(Vector2(ex, -tamanho * 0.18), tamanho * 0.15, Color(1.0, 0.65, 1.0, alpha_f * 0.90))
					draw_circle(Vector2(ex, -tamanho * 0.18), tamanho * 0.07, Color(1.0, 1.0, 1.0, alpha_f * 1.10))
				# Anel tracejado indicando imunidade a AoE (só quando visível)
				for i in range(6):
					var arc_a : float = float(i) * TAU / 6.0 + pulse * 0.30
					draw_arc(Vector2.ZERO, tamanho * 1.70, arc_a, arc_a + TAU / 12.0, 6,
							Color(c.r, c.g, c.b, 0.30 * p * reveal_p), 1.5)

		"vampiro":
			# Vampiro — forma de morcego com asas e presas
			var vp : float = sin(pulse * 2.2) * 0.25 + 0.75
			# Corpo central
			draw_circle(Vector2.ZERO, tamanho * 0.65,
					Color(c.r * 0.15, c.g * 0.05, c.b * 0.12, 0.92))
			draw_arc(Vector2.ZERO, tamanho * 0.65, 0.0, TAU, 24,
					Color(c.r, c.g, c.b, vp), 2.0)
			# Asas (dois arcos curvos batendo)
			var wing_flap : float = sin(pulse * 4.5) * 0.25
			for side in [-1.0, 1.0]:
				var wx : float = tamanho * 1.55 * side
				var pts_w := PackedVector2Array([
					Vector2(0.0, 0.0),
					Vector2(side * tamanho * 0.55, -tamanho * (0.85 + wing_flap)),
					Vector2(wx, -tamanho * (0.35 + wing_flap * 0.5)),
					Vector2(wx, tamanho * 0.50),
					Vector2(side * tamanho * 0.55, tamanho * 0.70),
				])
				draw_polygon(pts_w, _cores(pts_w.size(), Color(c.r * 0.18, 0.0, c.b * 0.12, 0.82)))
				var bw := PackedVector2Array(pts_w); bw.append(pts_w[0])
				draw_polyline(bw, Color(c.r, c.g, c.b, vp * 0.75), 1.8)
			# Presas
			draw_line(Vector2(-tamanho * 0.22, tamanho * 0.5),
					Vector2(-tamanho * 0.22, tamanho * 0.82), Color(1.0, 0.88, 0.88, vp), 2.0)
			draw_line(Vector2( tamanho * 0.22, tamanho * 0.5),
					Vector2( tamanho * 0.22, tamanho * 0.82), Color(1.0, 0.88, 0.88, vp), 2.0)
			# Olhos vermelhos
			for side_e in [-1.0, 1.0]:
				draw_circle(Vector2(side_e * tamanho * 0.28, -tamanho * 0.12),
						tamanho * 0.13, Color(1.0, 0.08, 0.08, vp * 0.95))
				draw_circle(Vector2(side_e * tamanho * 0.28, -tamanho * 0.12),
						tamanho * 0.06, Color(1.0, 0.7, 0.7, 1.0))

		"espelho":
			# Espelho — hexágono prateado com reflexo interno pulsante
			var ep : float = sin(pulse * 1.8) * 0.20 + 0.80
			var pts_e := PackedVector2Array()
			for i in range(6):
				var ae := float(i) * TAU / 6.0 + PI / 6.0
				pts_e.append(Vector2(cos(ae), sin(ae)) * tamanho)
			draw_polygon(pts_e, _cores(pts_e.size(), Color(c.r * 0.08, c.g * 0.12, c.b * 0.14, 0.94)))
			var brd_e := PackedVector2Array(pts_e); brd_e.append(pts_e[0])
			for i in range(3, 0, -1):
				draw_polyline(brd_e, Color(c.r, c.g, c.b, ep * 0.35 / float(i)), float(i) * 2.2)
			draw_polyline(brd_e, Color(c.r + 0.1, c.g + 0.05, 1.0, ep), 2.0)
			# Reflexo: hexágono interno menor a girar devagar
			var pts_ei := PackedVector2Array()
			for i in range(6):
				var ae2 := float(i) * TAU / 6.0 + PI / 6.0 + pulse * 0.22
				pts_ei.append(Vector2(cos(ae2), sin(ae2)) * tamanho * 0.48)
			var brd_ei := PackedVector2Array(pts_ei); brd_ei.append(pts_ei[0])
			draw_polyline(brd_ei, Color(c.r, c.g, c.b, ep * 0.65), 1.5)
			# Brilho central
			draw_circle(Vector2.ZERO, tamanho * 0.20, Color(0.85, 0.95, 1.0, ep * 0.80))
			draw_circle(Vector2.ZERO, tamanho * 0.08, Color(1.0, 1.0, 1.0, ep))

		"ladrao":
			# Ladrão — forma pequena e ágil com moeda orbitando
			var lp : float = sin(pulse * 3.0) * 0.25 + 0.75
			# Corpo
			draw_circle(Vector2.ZERO, tamanho,
					Color(c.r * 0.18, c.g * 0.14, c.b * 0.02, 0.90))
			draw_arc(Vector2.ZERO, tamanho, 0.0, TAU, 24,
					Color(c.r, c.g, c.b, lp), 2.5)
			draw_circle(Vector2.ZERO, tamanho * 0.38, Color(c.r, c.g, c.b, lp * 0.55))
			# Moeda dourada orbitando
			var coin_a : float = pulse * 2.0
			var coin_p := Vector2(cos(coin_a), sin(coin_a)) * tamanho * 1.6
			draw_circle(coin_p, tamanho * 0.38, Color(1.0, 0.85, 0.10, lp * 0.90))
			draw_arc(coin_p, tamanho * 0.38, 0.0, TAU, 12,
					Color(0.9, 0.65, 0.05, lp), 1.5)
			draw_circle(coin_p, tamanho * 0.15, Color(1.0, 0.95, 0.40, lp))
			# Sinal "R$" no corpo
			draw_line(Vector2(-tamanho * 0.20, -tamanho * 0.30),
					Vector2(-tamanho * 0.20,  tamanho * 0.30), Color(c.r, c.g, c.b, lp * 0.80), 1.8)
			draw_arc(Vector2(-tamanho * 0.08, -tamanho * 0.08), tamanho * 0.22, -PI / 2.0, PI / 2.0, 8,
					Color(c.r, c.g, c.b, lp * 0.70), 1.8)

		"ancora":
			# Âncora — forma de âncora pesada com corrente
			var anc_p : float = sin(pulse * 1.2) * 0.15 + 0.85
			# Haste vertical
			draw_line(Vector2(0.0, -tamanho * 1.20), Vector2(0.0, tamanho * 1.20),
					Color(c.r, c.g, c.b, anc_p), 5.0)
			# Travessão horizontal
			draw_line(Vector2(-tamanho * 0.80, -tamanho * 0.88),
					Vector2( tamanho * 0.80, -tamanho * 0.88),
					Color(c.r, c.g, c.b, anc_p), 4.0)
			# Meia-lua inferior (curva da âncora)
			draw_arc(Vector2(0.0, tamanho * 0.30), tamanho * 0.88,
					PI * 0.08, PI * 0.92, 20,
					Color(c.r, c.g, c.b, anc_p), 4.5)
			# Pontas inferiores
			for side_a in [-1.0, 1.0]:
				draw_circle(Vector2(side_a * tamanho * 0.88, tamanho * 0.30 + tamanho * 0.88 * sin(PI * 0.5)),
						tamanho * 0.22, Color(c.r, c.g, c.b, anc_p * 0.80))
			# Anel no topo
			draw_circle(Vector2(0.0, -tamanho * 1.22), tamanho * 0.28,
					Color(c.r * 0.12, c.g * 0.15, c.b * 0.22, 0.90))
			draw_arc(Vector2(0.0, -tamanho * 1.22), tamanho * 0.28, 0.0, TAU, 16,
					Color(c.r, c.g, c.b, anc_p), 2.5)
			# Anel de supressão pulsante (aura da âncora)
			var aura_r : float = 55.0 + sin(pulse * 2.0) * 8.0
			for i in range(3):
				draw_arc(Vector2.ZERO, aura_r + float(i) * 12.0, 0.0, TAU, 24,
						Color(c.r, c.g, c.b, (0.22 - float(i) * 0.06) * anc_p), 1.5)

		"regenerador":
			# Regenerador — círculo com anel verde pulsante, escudo de cura
			draw_circle(Vector2.ZERO, tamanho, Color(c.r * 0.12, c.g * 0.18, c.b * 0.14, 0.92))
			draw_arc(Vector2.ZERO, tamanho, 0.0, TAU, 32, Color(c.r, c.g, c.b, p), 3.0)
			# Cruz de cura interna
			var hrw : float = tamanho * 0.28; var hrl : float = tamanho * 0.72
			draw_rect(Rect2(-hrw, -hrl, hrw * 2.0, hrl * 2.0), Color(c.r, c.g, c.b, 0.65 * p))
			draw_rect(Rect2(-hrl, -hrw, hrl * 2.0, hrw * 2.0), Color(c.r, c.g, c.b, 0.65 * p))
			# Anel de regen pulsante (visível ao regenerar)
			if regen_sem_dano_timer >= 1.5:
				var rp2 : float = (regen_sem_dano_timer - 1.5) / 0.5
				draw_arc(Vector2.ZERO, tamanho + 8.0, 0.0, TAU, 32,
						Color(c.r, c.g, c.b, minf(rp2, 1.0) * 0.80), 4.0)

		"divididor":
			# Divididor — círculo com linha de divisão e flechas simétricas
			var div_r : float = tamanho
			draw_circle(Vector2.ZERO, div_r, Color(c.r * 0.14, c.g * 0.08, 0.0, 0.92))
			draw_arc(Vector2.ZERO, div_r, 0.0, TAU, 32, Color(c.r, c.g, c.b, p), 3.0)
			# Linha de divisão vertical com "tensão"
			var div_off : float = sin(pulse * 3.5) * 2.0
			draw_line(Vector2(div_off, -div_r), Vector2(div_off, div_r),
					Color(1.0, 1.0, 0.5, p * 0.85), 2.5)
			# Flechas divergindo
			for side_d in [-1.0, 1.0]:
				var fa : float = 0.0 if side_d < 0 else PI
				var fp := Vector2(cos(fa), 0.0) * div_r * 0.55
				draw_line(fp, fp + Vector2(cos(fa), 0.0) * div_r * 0.40,
						Color(c.r, c.g, c.b, p), 2.0)

		"kamikaze":
			# Kamikaze — corpo triangular pontiagudo com rastro de chamas
			var kp : float = sin(pulse * 6.0) * 0.25 + 0.75
			# Quão próximo da torre (mais próximo = mais intenso)
			var danger_p : float = kp
			# Triângulo apontando para frente
			var kt := PackedVector2Array([
				Vector2(0.0,              -tamanho * 1.35),
				Vector2(-tamanho * 0.85,   tamanho * 0.80),
				Vector2( tamanho * 0.85,   tamanho * 0.80),
			])
			draw_polygon(kt, _cores(kt.size(), Color(c.r * 0.22, 0.02, 0.0, 0.94)))
			var kt_brd := PackedVector2Array(kt); kt_brd.append(kt[0])
			draw_polyline(kt_brd, Color(c.r, c.g * danger_p, 0.05, p), 3.0)
			# Núcleo incandescente
			draw_circle(Vector2(0.0, tamanho * 0.10), tamanho * 0.38, Color(1.0, 0.55, 0.05, p))
			draw_circle(Vector2(0.0, tamanho * 0.10), tamanho * 0.18, Color(1.0, 0.92, 0.5, 1.0))
			# Chamas saindo (partículas ascendentes)
			for ki in range(3):
				var kt_p : float = fmod(pulse * 1.2 + float(ki) * 0.66, 1.0)
				var ky   : float = tamanho * 0.8 + kt_p * tamanho * 1.8
				var kx   : float = sin(pulse * 2.0 + float(ki) * 2.1) * tamanho * 0.4
				var ka   : float = (1.0 - kt_p) * 0.7
				draw_circle(Vector2(kx, ky), tamanho * 0.25 * (1.0 - kt_p * 0.8),
						Color(1.0, 0.45 + 0.45 * (1.0 - kt_p), 0.05, ka))

		"blindado":
			# Blindado — hexágono metálico com facetas de aço
			var bp2 : float = sin(pulse * 1.5) * 0.12 + 0.88
			var pts_bl := PackedVector2Array()
			for i in range(6):
				var ba : float = float(i) * TAU / 6.0 + PI / 6.0
				pts_bl.append(Vector2(cos(ba), sin(ba)) * tamanho)
			draw_polygon(pts_bl, _cores(pts_bl.size(), Color(0.12, 0.15, 0.16, 0.95)))
			var brd_bl := PackedVector2Array(pts_bl); brd_bl.append(pts_bl[0])
			draw_polyline(brd_bl, Color(c.r, c.g, c.b, bp2), 4.0)
			draw_polyline(brd_bl, Color(0.85, 0.92, 0.95, bp2 * 0.35), 1.5)
			# Brilho metálico (linha diagonal)
			draw_line(Vector2(-tamanho * 0.60, -tamanho * 0.55),
					Vector2( tamanho * 0.30,  tamanho * 0.40),
					Color(0.90, 0.94, 0.96, bp2 * 0.40), 2.5)
			# Símbolo imune (X) no centro
			var bx : float = tamanho * 0.35
			draw_line(Vector2(-bx, -bx), Vector2(bx, bx), Color(c.r, c.g, c.b, bp2 * 0.60), 2.0)
			draw_line(Vector2( bx, -bx), Vector2(-bx, bx), Color(c.r, c.g, c.b, bp2 * 0.60), 2.0)

		"necromante":
			# Necromante — círculo sombrio com crânio estilizado e aura de morte
			var np : float = sin(pulse * 1.8) * 0.20 + 0.80
			draw_circle(Vector2.ZERO, tamanho, Color(c.r * 0.08, 0.0, c.b * 0.10, 0.94))
			draw_arc(Vector2.ZERO, tamanho, 0.0, TAU, 32, Color(c.r, c.g, c.b, np), 3.5)
			# Anel de invocação girando
			var nr : float = tamanho * 1.45
			for ni in range(5):
				var na : float = float(ni) * TAU / 5.0 + pulse * 0.8
				draw_circle(Vector2(cos(na), sin(na)) * nr, tamanho * 0.14,
						Color(0.75, 0.12, 0.88, np * 0.70))
			# Olhos (dois pontos brilhantes)
			draw_circle(Vector2(-tamanho * 0.30, -tamanho * 0.18), tamanho * 0.20,
					Color(0.85, 0.12, 0.95, np))
			draw_circle(Vector2( tamanho * 0.30, -tamanho * 0.18), tamanho * 0.20,
					Color(0.85, 0.12, 0.95, np))
			# Sorriso (arco)
			draw_arc(Vector2(0.0, tamanho * 0.12), tamanho * 0.40,
					PI * 0.15, PI * 0.85, 12, Color(c.r, c.g, c.b, np * 0.80), 2.0)
			# Aura de invocação (timer)
			if _necro_timer >= 7.0:
				var necrp : float = (_necro_timer - 7.0) / 3.0
				draw_arc(Vector2.ZERO, tamanho + 12.0 + necrp * 10.0, 0.0, TAU, 32,
						Color(0.75, 0.12, 0.88, necrp * 0.75), 3.5)

	_draw_identidade_espacial(c, p)

	# ── Identidade de mini-chefe: aura dourada dupla + orbes orbitais ─────────
	if is_chefe:
		var rc    : float = tamanho * 1.30
		var ang_c : float = pulse * 0.8
		# Glow de presença (atrás de tudo que vier por cima)
		draw_circle(Vector2.ZERO, rc * 1.7, Color(c.r, c.g, c.b, 0.05 + 0.03 * sin(pulse * 2.0)))
		# Anel dourado principal girando + anel da cor do tipo contra-girando
		draw_arc(Vector2.ZERO, rc, ang_c, ang_c + TAU * 0.78, 40, Color(1.0, 0.82, 0.20, 0.85), 3.0)
		draw_arc(Vector2.ZERO, rc + 7.0, -ang_c * 0.7, -ang_c * 0.7 + TAU * 0.55, 32, Color(c.r, c.g, c.b, 0.55), 2.0)
		# 4 orbes de coroa orbitando
		for oi in range(4):
			var pa : float = ang_c * 1.3 + float(oi) * TAU / 4.0
			var pp : Vector2 = Vector2(cos(pa), sin(pa)) * (rc + 4.0)
			draw_circle(pp, 3.2, Color(1.0, 0.85, 0.30, 0.9))


	# Barra de armadura do Escudeiro (acima da HP)
	if escudo_arm_max > 0.0:
		var aw : float = tamanho * 2.4
		var ay : float = -tamanho - 17.0
		var arm_r : float = clampf(escudo_armadura / escudo_arm_max, 0.0, 1.0)
		draw_rect(Rect2(-aw / 2.0, ay, aw, 4.0), Color(0.06, 0.08, 0.10, 0.85))
		draw_rect(Rect2(-aw / 2.0, ay, aw * arm_r, 4.0), Color(0.55, 0.88, 1.0, 0.90))

	# ── Atordoamento elétrico: anéis pulsantes brancos/ciano ────────────────────
	if habil_stun_timer > 0.0 and not morto:
		var sp : float = sin(pulse * 12.0) * 0.30 + 0.70
		for si in range(3, 0, -1):
			draw_arc(Vector2.ZERO, tamanho + float(si) * 7.0, 0.0, TAU, 24,
					Color(0.65, 1.0, 1.0, sp * 0.55 / float(si)), float(si) * 2.2)
		draw_arc(Vector2.ZERO, tamanho * 1.05, 0.0, TAU, 32,
				Color(1.0, 1.0, 1.0, sp * 0.80), 2.5)
		# Faísca em 4 pontos
		for ei in range(4):
			var ea : float = float(ei) * TAU / 4.0 + pulse * 8.0
			var ep := Vector2(cos(ea), sin(ea)) * (tamanho + 12.0)
			draw_circle(ep, 2.5, Color(0.8, 1.0, 1.0, sp))

	# ── Partículas de veneno ─────────────────────────────────────────────────────
	if veneno_dps > 0.0 and not morto:
		for vi in range(4):
			var t_par : float = fmod(pulse * 0.75 + float(vi) * 0.62, 1.0)
			var py_par : float = -t_par * (tamanho * 2.0 + 8.0)
			var px_par : float = sin(pulse * 1.4 + float(vi) * 1.57) * tamanho * 0.55
			var a_par  : float = minf(t_par * 3.5, 1.0) * (1.0 - t_par) * 1.3
			if a_par > 0.04:
				draw_circle(Vector2(px_par, py_par), 2.8, Color(0.12, 0.95, 0.22, a_par))

	# Barra de HP (só quando levou dano)
	if hp < max_hp:
		var w : float = tamanho * 2.4
		var h : float = 4.0
		var y : float = -tamanho - 10.0
		draw_rect(Rect2(-w / 2.0, y, w, h), Color(0.1, 0.1, 0.1, 0.85))
		var bar_cor : Color = Color(c.r, c.g, c.b, 0.9)
		draw_rect(Rect2(-w / 2.0, y, w * (hp / max_hp), h), bar_cor)
	# Indicador de escudo explosivo (blindada) — segmento laranja acima da barra
	if escudo_explosivo and not morto:
		var sw : float = tamanho * 2.4
		var sy : float = -tamanho - 16.0
		var sp : float = sin(pulse * 3.0) * 0.25 + 0.75
		draw_rect(Rect2(-sw / 2.0, sy, sw, 3.0), Color(0.08, 0.04, 0.02, 0.80))
		draw_rect(Rect2(-sw / 2.0, sy, sw, 3.0), Color(1.0, 0.55, 0.05, 0.85 * sp))


func _cores(n: int, c: Color) -> PackedColorArray:
	var arr := PackedColorArray()
	arr.resize(n)
	arr.fill(c)
	return arr


func _draw_identidade_espacial(c: Color, p: float) -> void:
	var dir := Vector2.RIGHT.rotated(aim_angle)
	if dir.length_squared() < 0.01:
		dir = Vector2.RIGHT
	var lat := dir.rotated(PI * 0.5)
	var alpha : float = 0.55 * p
	var rear := -dir * tamanho * 0.88
	var nose := dir * tamanho * 0.92
	var cockpit := nose - dir * tamanho * 0.38
	draw_line(rear, nose, Color(c.r, c.g, c.b, alpha * 0.45), 1.2)
	draw_circle(cockpit, maxf(2.2, tamanho * 0.15), Color(0.82, 0.96, 1.0, alpha))
	draw_circle(cockpit, maxf(1.0, tamanho * 0.07), Color(1.0, 1.0, 1.0, alpha * 0.9))
	for side in [-1.0, 1.0]:
		var wing_a : Vector2 = rear + lat * side * tamanho * 0.58
		var wing_b : Vector2 = rear + lat * side * tamanho * 0.28 + dir * tamanho * 0.34
		draw_line(wing_a, wing_b, Color(c.r, c.g, c.b, alpha * 0.72), 2.0)
		draw_circle(wing_a, maxf(1.4, tamanho * 0.08), Color(c.r, c.g, c.b, alpha))
	var engine_alpha : float = (0.32 + 0.22 * sin(pulse * 2.6)) * p
	draw_circle(rear - dir * tamanho * 0.20, maxf(2.4, tamanho * 0.16), Color(c.r, c.g, c.b, engine_alpha))
	draw_circle(rear - dir * tamanho * 0.36, maxf(1.4, tamanho * 0.09), Color(0.95, 1.0, 1.0, engine_alpha * 0.75))
	if tipo in ["fast", "berserker", "kamikaze", "ladrao"]:
		draw_line(rear - dir * tamanho * 0.25, rear - dir * tamanho * 0.95, Color(c.r, c.g, c.b, engine_alpha * 1.4), 2.4)
	elif tipo in ["curandeiro", "suporte", "regenerador"]:
		draw_arc(Vector2.ZERO, tamanho + 4.0, pulse * 0.6, pulse * 0.6 + TAU * 0.72, 32,
				Color(c.r, c.g, c.b, alpha * 0.55), 1.8)
	elif tipo in ["tank", "colossus", "blindado", "ancora"]:
		draw_arc(Vector2.ZERO, tamanho + 5.0, 0.0, TAU, 36,
				Color(0.75, 0.9, 1.0, alpha * 0.36), 1.8)
