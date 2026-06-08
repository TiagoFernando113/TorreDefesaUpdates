extends Node2D

signal boss_derrotado

# ── Posição / layout ─────────────────────────────────────────────────────────
const POS       := Vector2(1135.0, 360.0)
const HANGAR_Y  := [-58.0, 0.0, 58.0]
const MORTE_DUR := 3.0
const FUGA_DUR  := 4.4
const FUGA_FRAMES := 44
const SPRITE_BASE := "res://assets/sprites/boss_dante/"
const ATAQUES_DANTE := {
	"rajada_tripla": {"nome": "01. Rajada Tripla", "dano": 30.0},
	"misseis_teleguiados": {"nome": "02. Misseis Teleguiados", "dano": 42.0},
	"anel_quebrado": {"nome": "03. Anel Quebrado", "dano": 44.0},
	"chuva_lateral": {"nome": "04. Chuva Lateral", "dano": 48.0},
}
const FASE_NORMAL_LIMITE    : float = 0.66
const FASE_CRITICA_LIMITE   : float = 0.33
const FASE_NORMAL           : String = "normal"
const FASE_ENFURECIDO       : String = "enfurecido"
const FASE_CRITICO          : String = "critico"
const ATAQUES_FASE_NORMAL := [
	"rajada_tripla", "misseis_teleguiados",
]
const ATAQUES_FASE_ENFURECIDO := [
	"rajada_tripla", "misseis_teleguiados", "anel_quebrado", "chuva_lateral",
]
const ATAQUES_FASE_CRITICO := [
	"chuva_lateral", "chuva_lateral", "anel_quebrado", "anel_quebrado",
	"misseis_teleguiados", "rajada_tripla",
]

# ── Estado ───────────────────────────────────────────────────────────────────
var boss_hp     : float = 0.0
var boss_max_hp : float = 0.0
var hp          : float = 0.0
var max_hp      : float = 0.0
var gelo_slow   : float = 0.0
var veneno_dps   : float = 0.0
var veneno_timer : float = 0.0
var imune_aoe   : bool = false
var fase2       : bool  = false
var fase3       : bool  = false
var morto       : bool  = false
var fugindo     : bool  = false
var t           : float = 0.0
var wave_num    : int   = 1
var jogo        : Node  = null

# ── Combate ──────────────────────────────────────────────────────────────────
var atk_timer   : float = 2.5
var atk_cd      : float = 4.5
var spawn_timer : float = 5.0
var spawn_cd    : float = 9.0
var misseis     : Array = []
var laser_timer : float = 0.0
var laser_fase  : String = ""
var laser_alvo  : Vector2 = Vector2.ZERO
var laser_dano  : float = 40.0
var laser_raio  : float = 34.0
var ataque_atual_id   : String = ""
var ataque_atual_nome : String = ""

# ── Visual ───────────────────────────────────────────────────────────────────
var _shake      : float   = 0.0
var _shake_off  : Vector2 = Vector2.ZERO
var _hit_flash  : float   = 0.0
var _morte_t    : float   = 0.0
var _fuga_t     : float   = 0.0
var _fuga_tilt  : float   = 0.0
var _look_tilt  : float   = 0.0
var _explosoes  : Array   = []
var _efeitos_ataque : Array = []

static var _tex_cache : Dictionary = {}


static func _get_tex(nome: String) -> Texture2D:
	if nome in _tex_cache:
		return _tex_cache[nome]
	var tex : Texture2D = null
	var path := SPRITE_BASE + nome + ".png"
	if ResourceLoader.exists(path):
		tex = load(path) as Texture2D
	if tex != null:
		_tex_cache[nome] = tex
	return tex


func setup(p_hp: float, wave: int) -> void:
	boss_max_hp = p_hp
	boss_hp     = p_hp
	max_hp      = p_hp
	hp          = p_hp
	wave_num    = wave
	atk_cd      = maxf(2.8, 5.8 - float(wave) * 0.018)
	spawn_cd    = maxf(4.5, 9.5 - float(wave) * 0.05)


func _ready() -> void:
	add_to_group("boss_dante")
	set_process(true)


func _process(delta: float) -> void:
	t          += delta
	_shake      = maxf(0.0, _shake - delta * 7.0)
	_hit_flash  = maxf(0.0, _hit_flash - delta * 4.0)
	_shake_off  = Vector2(randf_range(-1, 1), randf_range(-1, 1)) * _shake * 5.0 if _shake > 0.01 else Vector2.ZERO
	if not morto and not fugindo:
		var tilt_alvo := clampf((POS.y - _get_torre_pos().y) / 420.0, -0.32, 0.32)
		_look_tilt = lerpf(_look_tilt, tilt_alvo, clampf(delta * 1.15, 0.0, 1.0))
	for i in range(_efeitos_ataque.size() - 1, -1, -1):
		_efeitos_ataque[i]["t"] += delta
		var hit_at : float = float(_efeitos_ataque[i].get("hit_at", -1.0))
		if hit_at >= 0.0 and not (_efeitos_ataque[i].get("hit_done", false) == true) and float(_efeitos_ataque[i]["t"]) >= hit_at:
			_efeitos_ataque[i]["hit_done"] = true
			var fx_hit := _efeitos_ataque[i] as Dictionary
			var fx_id : String = str(fx_hit.get("id", ""))
			if fx_id == "laser_avisado":
				_dano_torre_laser_avisado(fx_hit)
			elif fx_id == "anel_quebrado":
				_dano_torre_anel_quebrado(fx_hit)
			elif fx_id == "chuva_lateral":
				_dano_torre_chuva_lateral(fx_hit)
			else:
				_dano_torre_area(
					fx_hit["pos"] as Vector2,
					float(fx_hit.get("raio", 0.0)),
					float(fx_hit.get("dano", 0.0))
				)
		if float(_efeitos_ataque[i]["t"]) >= float(_efeitos_ataque[i]["dur"]):
			_efeitos_ataque.remove_at(i)

	if morto:
		_morte_t += delta
		if fmod(_morte_t, 0.22) < delta:
			_explosoes.append({
				"pos": POS + Vector2(randf_range(-185, 185), randf_range(-105, 105)),
				"t": 0.0,
				"r": randf_range(16.0, 48.0),
			})
		for i in range(_explosoes.size() - 1, -1, -1):
			_explosoes[i]["t"] += delta
			if float(_explosoes[i]["t"]) > 0.55:
				_explosoes.remove_at(i)
		if _morte_t >= MORTE_DUR:
			queue_free()
		queue_redraw()
		return

	if fugindo:
		_fuga_t += delta
		_shake = maxf(_shake, 0.28 * (1.0 - clampf(_fuga_t / FUGA_DUR, 0.0, 1.0)))
		if _fuga_t >= FUGA_DUR:
			emit_signal("boss_derrotado")
			queue_free()
		queue_redraw()
		return

	if veneno_timer > 0.0:
		veneno_timer = maxf(0.0, veneno_timer - delta)
		if veneno_dps > 0.0:
			receber_dano(veneno_dps * delta, true)
		if veneno_timer <= 0.0:
			veneno_dps = 0.0
		if morto:
			queue_redraw()
			return

	# Fase 2 a 50% HP
	var fase_agora := _fase_atual()
	if not fase2 and fase_agora == FASE_ENFURECIDO:
		fase2     = true
		_shake    = 2.5
		atk_cd   *= 0.58
		spawn_cd *= 0.52
	if not fase3 and fase_agora == FASE_CRITICO:
		fase3 = true
		fase2 = true
		_shake = 3.4
		atk_cd *= 0.72

	# Ataques
	atk_timer += delta
	if atk_timer >= atk_cd:
		atk_timer = randf_range(-0.2, 0.2)
		_spawnar_ataque()

	# Laser (fase 2)
	if laser_fase != "":
		laser_timer += delta
		if laser_fase == "warn" and laser_timer >= 1.3:
			laser_fase  = "fire"
			laser_timer = 0.0
			_dano_torre_linha(POS + Vector2(-160.0, 0.0), laser_alvo, laser_raio, laser_dano)
		elif laser_fase == "fire" and laser_timer >= 0.35:
			laser_fase  = ""
			laser_timer = 0.0

	# Spawn mobs pelos hangares
	spawn_timer += delta
	if spawn_timer >= spawn_cd:
		spawn_timer = 0.0
		_spawnar_mobs_hangar()

	# Processar mísseis
	for i in range(misseis.size() - 1, -1, -1):
		var m : Dictionary = misseis[i]
		m["t"] += delta
		var delay : float = float(m.get("delay", 0.0))
		if delay > 0.0:
			m["delay"] = maxf(0.0, delay - delta)
			misseis[i] = m
			continue
		var life : float = float(m.get("life", 6.0))
		if float(m["t"]) > life:
			misseis.remove_at(i)
			continue
		if m.get("homing", false) == true and float(m["t"]) <= float(m.get("steer_time", 1.2)):
			var vel_atual := m["vel"] as Vector2
			var alvo_dir := (_get_torre_pos() - (m["pos"] as Vector2)).normalized()
			var speed : float = float(m.get("speed", vel_atual.length()))
			m["vel"] = vel_atual.lerp(alvo_dir * speed, clampf(delta * float(m.get("turn", 2.6)), 0.0, 1.0))
		m["pos"] = (m["pos"] as Vector2) + (m["vel"] as Vector2) * delta
		if jogo:
			var torre = jogo.get("torre")
			if torre and is_instance_valid(torre):
				if (m["pos"] as Vector2).distance_to((torre as Node2D).global_position) < float(m.get("raio", 34.0)):
					jogo.call("dano_boss_na_torre", float(m["dano"]))
					misseis.remove_at(i)
					continue
		var p_m := m["pos"] as Vector2
		if p_m.x < -120.0 or p_m.x > 1400.0 or p_m.y < -160.0 or p_m.y > 880.0:
			misseis.remove_at(i)
			continue
		misseis[i] = m

	queue_redraw()


func _spawnar_ataque() -> void:
	var lista : Array = ATAQUES_FASE_NORMAL
	var fase := _fase_atual()
	if fase == FASE_ENFURECIDO:
		lista = ATAQUES_FASE_ENFURECIDO
	elif fase == FASE_CRITICO:
		lista = ATAQUES_FASE_CRITICO
	_executar_combo_ataque(fase, lista)


func _executar_combo_ataque(fase: String, lista: Array) -> void:
	if fase == FASE_NORMAL:
		var abertura : String = lista[randi() % lista.size()]
		_executar_ataque(abertura)
		var follow : String = "rajada_tripla" if abertura == "misseis_teleguiados" else "misseis_teleguiados"
		_agendar_ataque(follow, 0.72)
	elif fase == FASE_ENFURECIDO:
		var combos := [
			["rajada_tripla", "anel_quebrado", "misseis_teleguiados"],
			["misseis_teleguiados", "chuva_lateral", "rajada_tripla"],
			["anel_quebrado", "rajada_tripla", "chuva_lateral"],
		]
		var combo : Array = combos[randi() % combos.size()]
		for i in range(combo.size()):
			_agendar_ataque(str(combo[i]), float(i) * 0.58)
	else:
		var combos_crit := [
			["chuva_lateral", "anel_quebrado", "misseis_teleguiados", "rajada_tripla"],
			["anel_quebrado", "chuva_lateral", "rajada_tripla", "misseis_teleguiados"],
			["misseis_teleguiados", "rajada_tripla", "chuva_lateral", "anel_quebrado"],
		]
		var combo_c : Array = combos_crit[randi() % combos_crit.size()]
		for i in range(combo_c.size()):
			_agendar_ataque(str(combo_c[i]), float(i) * 0.46)


func _agendar_ataque(id: String, delay: float) -> void:
	if delay <= 0.0:
		_executar_ataque(id)
		return
	get_tree().create_timer(delay, false).timeout.connect(func() -> void:
		if is_inside_tree() and not morto and not fugindo:
			_executar_ataque(id)
	)


func _fase_atual() -> String:
	var hp_r : float = boss_hp / maxf(boss_max_hp, 1.0)
	if hp_r <= FASE_CRITICA_LIMITE:
		return FASE_CRITICO
	if hp_r <= FASE_NORMAL_LIMITE:
		return FASE_ENFURECIDO
	return FASE_NORMAL


func get_target_position() -> Vector2:
	return _ponto_alvo_torre()


func _ponto_alvo_torre() -> Vector2:
	return POS + Vector2(-130.0, 6.0)


func _executar_ataque(id: String) -> void:
	ataque_atual_id = id
	ataque_atual_nome = (ATAQUES_DANTE.get(id, {}) as Dictionary).get("nome", id) as String
	var dano_base : float = float((ATAQUES_DANTE.get(id, {}) as Dictionary).get("dano", 24.0))
	match id:
		"rajada_tripla":
			_ataque_rajada_tripla(dano_base)
		"misseis_teleguiados":
			_ataque_misseis_teleguiados(dano_base)
		"anel_quebrado":
			_ataque_anel_quebrado(dano_base)
		"chuva_lateral":
			_ataque_chuva_lateral(dano_base)
		_:
			_ataque_rajada_tripla(dano_base)


func _registrar_efeito_ataque(id: String, duracao: float, dano: float = 0.0, raio: float = 0.0, hit_at: float = -1.0) -> void:
	_efeitos_ataque.append({
		"id": id,
		"nome": (ATAQUES_DANTE.get(id, {}) as Dictionary).get("nome", id),
		"t": 0.0,
		"dur": duracao,
		"pos": _get_torre_pos(),
		"dano": dano,
		"raio": raio,
		"hit_at": hit_at,
		"hit_done": false,
		"seed": randf() * 999.0,
	})


func _spawn_proj_dante(pos: Vector2, vel: Vector2, dano: float, kind: String, raio: float = 34.0, delay: float = 0.0, life: float = 6.0, homing: bool = false) -> void:
	misseis.append({
		"pos": pos,
		"vel": vel,
		"speed": vel.length(),
		"t": 0.0,
		"delay": delay,
		"life": life,
		"dano": dano,
		"kind": kind,
		"raio": raio,
		"homing": homing,
		"steer_time": 1.35,
		"turn": 2.5,
	})


func _ataque_rajada_tripla(dano: float) -> void:
	var alvo := _get_torre_pos()
	for wave_i in range(2):
		for i in range(3):
			var hy : float = HANGAR_Y[i]
			var origem := POS + Vector2(-160.0, hy)
			var dir := (alvo + Vector2(0.0, hy * 0.16) - origem).normalized().rotated(randf_range(-0.055, 0.055))
			_spawn_proj_dante(origem, dir * 340.0, dano * 0.60, "rajada", 52.0, float(wave_i) * 0.18, 4.6)


func _ataque_misseis_teleguiados(dano: float) -> void:
	var alvo := _get_torre_pos()
	for i in range(4):
		var hy : float = HANGAR_Y[i % 3] + randf_range(-18.0, 18.0)
		var origem := POS + Vector2(-160.0, hy)
		var dir := (alvo - origem).normalized().rotated(randf_range(-0.38, 0.38))
		_spawn_proj_dante(origem, dir * 220.0, dano * 0.78, "missil", 62.0, float(i) * 0.16, 6.2, true)


func _ataque_anel_quebrado(dano: float) -> void:
	var alvo := _get_torre_pos()
	var origem := POS + Vector2(-160.0, 0.0)
	var base_ang := (alvo - origem).angle()
	var gap := randi_range(3, 8)
	for i in range(12):
		if abs(i - gap) <= 1:
			continue
		var off : float = (float(i) - 5.5) * 0.15
		var dir := Vector2.RIGHT.rotated(base_ang + off)
		var lane := Vector2(0.0, (float(i) - 5.5) * 16.0).rotated(base_ang)
		_spawn_proj_dante(origem + lane, dir * 265.0, dano * 0.66, "anel", 54.0, 0.12 + absf(off) * 0.28, 5.6)


func _ataque_chuva_lateral(dano: float) -> void:
	var alvo := _get_torre_pos()
	var lanes := [-180.0, -108.0, -36.0, 36.0, 108.0, 180.0]
	for wave_i in range(3):
		for i in range(lanes.size()):
			if (i + wave_i) % 3 == 1:
				continue
			var x : float = clampf(alvo.x + float(lanes[i]), 110.0, 690.0)
			var origem := Vector2(x, 92.0)
			var dir := Vector2(0.0, 1.0).rotated(randf_range(-0.05, 0.05))
			_spawn_proj_dante(origem, dir * (255.0 + float(wave_i) * 20.0), dano * 0.58, "chuva", 58.0, 0.22 + float(wave_i) * 0.36 + float(i) * 0.025, 4.4)


func _atacar_misseis(cnt: int) -> void:
	var alvo := _get_torre_pos()
	for i in range(cnt):
		var hy : float = HANGAR_Y[i % 3]
		var origem := POS + Vector2(-160.0, hy)
		var dir    := (alvo - origem).normalized().rotated(randf_range(-0.28, 0.28))
		_spawn_proj_dante(origem, dir * (195.0 + float(i) * 20.0), 20.0 + (13.0 if fase2 else 0.0), "missil", 34.0, 0.0, 5.0)


func _iniciar_laser(dano: float = 40.0, raio: float = 34.0) -> void:
	if laser_fase != "": return
	laser_fase  = "warn"
	laser_timer = 0.0
	laser_alvo  = _get_torre_pos()
	laser_dano  = dano
	laser_raio  = raio


func _spawnar_mobs_hangar() -> void:
	if not jogo: return
	var cnt   := 2 if fase2 else 1
	var tipos := ["normal", "fast"] if not fase2 else ["normal", "fast", "tank"]
	for i in range(cnt):
		var hy  : float  = HANGAR_Y[i % 3]
		var pos : Vector2 = POS + Vector2(-160.0, hy) + Vector2(randf_range(-8, 8), randf_range(-8, 8))
		var tipo : String = tipos[randi() % tipos.size()]
		if jogo.has_method("_spawnar_mob_em"):
			jogo.call("_spawnar_mob_em", tipo, pos)


func _get_torre_pos() -> Vector2:
	if jogo:
		var torre = jogo.get("torre")
		if torre and is_instance_valid(torre):
			return (torre as Node2D).global_position
	return Vector2(260.0, 360.0)


func _dano_torre_area(centro: Vector2, raio: float, dano: float) -> void:
	if dano <= 0.0 or raio <= 0.0 or not jogo:
		return
	var torre = jogo.get("torre")
	if torre and is_instance_valid(torre):
		if (torre as Node2D).global_position.distance_to(centro) <= raio:
			jogo.call("dano_boss_na_torre", dano)


func _dano_torre_linha(origem: Vector2, fim: Vector2, raio: float, dano: float) -> void:
	if dano <= 0.0 or not jogo:
		return
	var torre = jogo.get("torre")
	if torre and is_instance_valid(torre):
		var dist := _dist_ponto_segmento((torre as Node2D).global_position, origem, fim)
		if dist <= raio:
			jogo.call("dano_boss_na_torre", dano)


func _dano_torre_laser_avisado(fx: Dictionary) -> void:
	if not jogo:
		return
	var torre = jogo.get("torre")
	if not (torre and is_instance_valid(torre)):
		return
	var alvo := fx["pos"] as Vector2
	var dano : float = float(fx.get("dano", 0.0))
	var raio : float = float(fx.get("raio", 30.0))
	var torre_pos := (torre as Node2D).global_position
	for off in [-76.0, 0.0, 76.0]:
		var x : float = alvo.x + off
		if _dist_ponto_segmento(torre_pos, Vector2(x, 94.0), Vector2(x, 642.0)) <= raio:
			jogo.call("dano_boss_na_torre", dano)
			return


func _dano_torre_anel_quebrado(fx: Dictionary) -> void:
	if not jogo:
		return
	var torre = jogo.get("torre")
	if not (torre and is_instance_valid(torre)):
		return
	var centro := fx["pos"] as Vector2
	var torre_pos := (torre as Node2D).global_position
	var dist := torre_pos.distance_to(centro)
	if dist < 82.0 or dist > 178.0:
		return
	var ang := (torre_pos - centro).angle()
	var gap := -PI * 0.5 + sin(float(fx.get("seed", 0.0))) * 0.55
	var diff := absf(wrapf(ang - gap, -PI, PI))
	if diff > 0.46:
		jogo.call("dano_boss_na_torre", float(fx.get("dano", 0.0)))


func _dano_torre_chuva_lateral(fx: Dictionary) -> void:
	if not jogo:
		return
	var torre = jogo.get("torre")
	if not (torre and is_instance_valid(torre)):
		return
	var alvo := fx["pos"] as Vector2
	var torre_pos := (torre as Node2D).global_position
	var lanes := [-152.0, -76.0, 0.0, 76.0, 152.0]
	for i in range(lanes.size()):
		var x : float = alvo.x + float(lanes[i])
		var gap_shift : float = sin(float(fx.get("seed", 0.0)) + float(i) * 1.7) * 18.0
		if absf(torre_pos.x - x - gap_shift) <= 42.0 and absf(torre_pos.y - alvo.y) <= 228.0:
			jogo.call("dano_boss_na_torre", float(fx.get("dano", 0.0)))
			return


func _dist_ponto_segmento(p: Vector2, a: Vector2, b: Vector2) -> float:
	var ab := b - a
	var denom := ab.length_squared()
	if denom <= 0.001:
		return p.distance_to(a)
	var u := clampf((p - a).dot(ab) / denom, 0.0, 1.0)
	return p.distance_to(a + ab * u)


func receber_dano(dano: float, _explosivo: bool = false, _critico: bool = false) -> void:
	if morto or fugindo: return
	boss_hp    = maxf(0.0, boss_hp - dano)
	hp         = boss_hp
	_hit_flash = 0.85
	_shake     = maxf(_shake, 0.38)
	if jogo and jogo.has_method("atualizar_boss_hp"):
		jogo.call("atualizar_boss_hp", boss_hp, boss_max_hp)
	if boss_hp <= 0.0:
		if _deve_fugir():
			_iniciar_fuga()
			return
		morto    = true
		_shake   = 3.5
		_morte_t = 0.0
		misseis.clear()
		emit_signal("boss_derrotado")


func _deve_fugir() -> bool:
	if not jogo:
		return wave_num < 25
	var info = jogo.get("mapa_atual_info")
	if info is Dictionary:
		var id : String = str((info as Dictionary).get("id", ""))
		return id != "coroa_void"
	return wave_num < 25


func _iniciar_fuga() -> void:
	fugindo = true
	_fuga_t = 0.0
	_fuga_tilt = _boss_look_tilt()
	_shake = 2.8
	_hit_flash = 0.0
	laser_fase = ""
	ataque_atual_nome = "DANTE - FUGA"
	misseis.clear()
	_efeitos_ataque.clear()
	_explosoes.clear()
	if jogo and jogo.has_method("atualizar_boss_hp"):
		jogo.call("atualizar_boss_hp", 0.0, boss_max_hp)


# ── Desenho ──────────────────────────────────────────────────────────────────
func _draw() -> void:
	if fugindo:
		_draw_fuga()
		return
	if morto:
		_draw_morte()
		return
	var pulse : float = 0.5 + 0.5 * sin(t * 1.35)
	var cor   : Color = Color(0.0, 0.72, 1.0)
	if _fase_atual() == FASE_ENFURECIDO:
		cor = Color(1.0, 0.28, 0.08)
	elif _fase_atual() == FASE_CRITICO:
		cor = Color(1.0, 0.05, 0.02)
	var pos   : Vector2 = POS + _shake_off

	_draw_nave(pos, pulse, cor)
	_draw_laser_visual(pos)
	_draw_misseis_visual()
	_draw_efeitos_ataque()
	_draw_hp_bar()

	if _hit_flash > 0.01:
		_draw_flash(pos, _hit_flash)


func _boss_sprite_nome() -> String:
	if morto:
		var frame : int = clampi(int(floor((_morte_t / MORTE_DUR) * 4.0)), 0, 3)
		return "dante_die_%d" % frame
	var fase := _fase_atual()
	if fase == FASE_CRITICO:
		return "dante_phase_3"
	if fase == FASE_ENFURECIDO:
		return "dante_phase_2"
	return "dante_phase_1"


func _boss_look_tilt() -> float:
	return _look_tilt


func _draw_nave(pos: Vector2, pulse: float, cor: Color) -> void:
	var bob  : Vector2 = Vector2(sin(t * 0.45) * 3.0, cos(t * 0.38) * 4.0)
	pos += bob
	var tex := _get_tex(_boss_sprite_nome())
	if tex != null:
		var sz : float = 385.0
		if _fase_atual() == FASE_CRITICO:
			sz = 415.0
		var sprite_alpha : float = clampf(1.0 - _morte_t / MORTE_DUR, 0.0, 1.0) if morto else 0.96
		var tilt := _boss_look_tilt()
		draw_set_transform(pos, -PI * 0.5 + tilt, Vector2.ONE)
		draw_texture_rect(tex, Rect2(-sz * 0.5, -sz * 0.5, sz, sz), false, Color(1.0, 1.0, 1.0, sprite_alpha))
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		var core := pos + Vector2(8.0, 0.0).rotated(tilt)
		draw_circle(core, 38.0 + pulse * 11.0, Color(1.0, 0.10, 0.02, 0.08 + pulse * 0.06))
		draw_arc(core, 46.0 + pulse * 5.0, t * 0.8, t * 0.8 + TAU, 48, Color(1.0, 0.28, 0.08, 0.45), 2.2)
		draw_circle(core, 7.0 + pulse * 3.5, Color(1.0, 0.25, 0.08, 0.95))
		for idx in range(3):
			var porta := pos + Vector2(-165.0, HANGAR_Y[idx]).rotated(tilt)
			var carga : float = 0.5 + 0.5 * sin(t * 3.2 + float(idx) * 1.4)
			draw_arc(porta, 16.0 + carga * 5.0, t * 1.5, t * 1.5 + TAU * 0.76, 24, Color(1.0, 0.20, 0.06, 0.48 + carga * 0.22), 1.7)
		_draw_propulsores_nave(pos, tilt, pulse)
		if fase2:
			for i in range(3):
				draw_circle(pos, 210.0 - float(i) * 45.0, Color(1.0, 0.12, 0.02, 0.018 + float(i) * 0.008))
		return

	var sombra : Color = Color(0.020, 0.014, 0.028, 0.94)
	var casco  : Color = Color(0.075 + cor.r * 0.035, 0.045 + cor.g * 0.025, 0.085 + cor.b * 0.030, 0.92)

	# Glow de fase 2
	if fase2:
		for i in range(4):
			draw_circle(pos + Vector2(10, 0), 280.0 - float(i) * 42.0,
				Color(cor.r, cor.g, cor.b, 0.013 * float(i + 1)))

	var asa_sup := PackedVector2Array([
		pos + Vector2(-180, -112), pos + Vector2(-44, -76),
		pos + Vector2(76, -116),   pos + Vector2(152, -52),
		pos + Vector2(26, -30),    pos + Vector2(-150, -52),
	])
	var asa_inf := PackedVector2Array([
		pos + Vector2(-180, 112), pos + Vector2(-44, 76),
		pos + Vector2(76, 116),   pos + Vector2(152, 52),
		pos + Vector2(26, 30),    pos + Vector2(-150, 52),
	])
	var corpo := PackedVector2Array([
		pos + Vector2(-176, -54), pos + Vector2(-38, -96),
		pos + Vector2(124, -58),  pos + Vector2(188, 0),
		pos + Vector2(124, 58),   pos + Vector2(-38, 96),
		pos + Vector2(-176, 54),  pos + Vector2(-128, 0),
	])

	draw_polygon(asa_sup, _fill(asa_sup.size(), Color(sombra.r, sombra.g, sombra.b, 0.70)))
	draw_polygon(asa_inf, _fill(asa_inf.size(), Color(sombra.r, sombra.g, sombra.b, 0.70)))
	draw_polygon(corpo,   _fill(corpo.size(), casco))
	draw_polyline(corpo   + PackedVector2Array([corpo[0]]),   Color(cor.r, cor.g, cor.b, 0.62), 2.4)
	draw_polyline(asa_sup + PackedVector2Array([asa_sup[0]]), Color(cor.r, cor.g, cor.b, 0.34), 1.6)
	draw_polyline(asa_inf + PackedVector2Array([asa_inf[0]]), Color(cor.r, cor.g, cor.b, 0.34), 1.6)

	# Detalhes internos
	for k in range(5):
		var blink : float = 0.22 + 0.18 * sin(t * 2.8 + float(k) * 1.7)
		var lx    : float = pos.x - 86.0 + float(k) * 42.0
		var ly    : float = pos.y - 42.0 + sin(t * 1.6 + float(k)) * 4.0
		draw_line(Vector2(lx, ly), Vector2(lx + 24.0, ly + 8.0), Color(cor.r, cor.g, cor.b, blink), 1.5)

	# Hangar (3 portas com mobs saindo)
	var hangar : Vector2 = pos + Vector2(-158.0, 0.0)
	draw_rect(Rect2(hangar.x - 22.0, hangar.y - 74.0, 34.0, 148.0), Color(0.0, 0.0, 0.0, 0.55))
	draw_line(hangar + Vector2(-22, -74), hangar + Vector2(-22, 74),
		Color(1.0, 0.25, 0.10, 0.62 + 0.20 * sin(t * 2.2)), 3.0)
	for idx in range(3):
		var sy    : float  = HANGAR_Y[idx]
		var porta : Vector2 = hangar + Vector2(0.0, sy)
		var carga : float  = 0.5 + 0.5 * sin(t * 3.2 + float(idx) * 1.4)
		draw_circle(porta, 16.0 + carga * 7.0, Color(1.0, 0.20, 0.08, 0.08 + 0.08 * carga))
		draw_arc(porta, 15.0 + carga * 4.0,
			t * 1.5 + float(idx), t * 1.5 + float(idx) + TAU * 0.72,
			30, Color(1.0, 0.30, 0.12, 0.48 + 0.22 * carga), 1.8)

	# Núcleo central (olho do vilão)
	var np    : Vector2 = pos + Vector2(55.0, 0.0)
	var olho  : Color   = Color(1.0, 0.22, 0.08, 0.82) if not fase2 else Color(1.0, 0.06, 0.04, 0.95)
	draw_circle(np, 48.0 + pulse * 10.0, Color(cor.r, cor.g, cor.b, 0.06 + 0.06 * pulse))
	draw_arc(np, 52.0 + pulse * 5.0,  t * 0.35, t * 0.35 + TAU,       64, Color(cor.r, cor.g, cor.b, 0.28 + 0.16 * pulse), 2.0)
	draw_arc(np, 66.0 + pulse * 8.0, -t * 0.24, -t * 0.24 + PI * 1.35, 64, Color(cor.r, cor.g, cor.b, 0.20), 1.4)
	draw_polygon(PackedVector2Array([
		np + Vector2(-38, 0), np + Vector2(-8, -18),
		np + Vector2(42, 0),  np + Vector2(-8, 18),
	]), _fill(4, Color(olho.r, olho.g, olho.b, 0.26)))
	draw_circle(np + Vector2(2.0, 0.0), 8.0 + pulse * 3.0, olho)

	# Destroços ao redor
	var pecas : Array = [
		Vector2(-224, -92), Vector2(-238, 74), Vector2(-92, -128),
		Vector2(22, 126),   Vector2(166, -92),
	]
	for i in range(pecas.size()):
		var fp : Vector2 = pos + (pecas[i] as Vector2) + Vector2(sin(t * 0.7 + float(i)) * 4.0, cos(t * 0.5 + float(i)) * 3.0)
		var tam : float = 12.0 + float(i % 3) * 5.0
		var frag := PackedVector2Array([
			fp + Vector2(-tam, -tam * 0.35), fp + Vector2(tam * 0.65, -tam * 0.70),
			fp + Vector2(tam, tam * 0.40),   fp + Vector2(-tam * 0.45, tam * 0.75),
		])
		draw_polygon(frag, _fill(4, Color(0.025, 0.025, 0.038, 0.78)))
		draw_polyline(frag + PackedVector2Array([frag[0]]), Color(cor.r, cor.g, cor.b, 0.25), 1.1)


func _draw_propulsores_nave(pos: Vector2, tilt: float, pulse: float) -> void:
	var phase : float = t * 14.0
	var base_alpha : float = 0.46 + pulse * 0.18
	var motores : Array = [
		Vector2(174.0, -82.0),
		Vector2(188.0, -25.0),
		Vector2(192.0, 38.0),
		Vector2(176.0, 92.0),
	]
	for i in range(motores.size()):
		var local : Vector2 = motores[i] as Vector2
		var p : Vector2 = pos + local.rotated(tilt)
		var dir : Vector2 = Vector2.RIGHT.rotated(tilt)
		var lat : Vector2 = dir.rotated(PI * 0.5)
		var flicker : float = 0.5 + 0.5 * sin(phase + float(i) * 1.7)
		var len : float = 13.0 + flicker * 11.0 + (4.0 if _fase_atual() == FASE_CRITICO else 0.0)
		var w : float = 4.2 + flicker * 2.0
		draw_circle(p - dir * 2.0, 6.5, Color(0.04, 0.01, 0.0, 0.68))
		draw_arc(p, 8.0, -0.7 + tilt, 0.7 + tilt, 16, Color(1.0, 0.20, 0.04, base_alpha * 0.62), 1.4)
		var flame := PackedVector2Array([
			p - lat * w,
			p + lat * w,
			p + dir * (len + 4.0) + lat * w * 0.24,
			p + dir * (len + 10.0 * flicker),
			p + dir * (len + 4.0) - lat * w * 0.24,
		])
		draw_polygon(flame, _fill(flame.size(), Color(1.0, 0.12, 0.02, base_alpha * 0.30)))
		draw_polyline(flame + PackedVector2Array([flame[0]]), Color(1.0, 0.25, 0.05, base_alpha * 0.78), 1.1)
		draw_line(p + dir * 2.5, p + dir * (len + 2.0), Color(1.0, 0.78, 0.32, base_alpha * 0.74), 1.6)
		draw_circle(p + dir * (len * 0.62), 2.3 + flicker * 0.9, Color(1.0, 0.78, 0.34, base_alpha * 0.58))


func _draw_laser_visual(pos: Vector2) -> void:
	if laser_fase == "": return
	var alvo   := laser_alvo
	var origem := pos + Vector2(-160.0, 0.0)
	var alpha  : float
	var width  : float
	var dir    := alvo - origem
	if laser_fase == "warn":
		var prog := clampf(laser_timer / 1.3, 0.0, 1.0)
		alpha = 0.22 + prog * 0.48 + sin(t * 28.0) * 0.08
		width = 2.0
		if dir.length_squared() > 1.0:
			for i in range(9):
				var a : float = float(i) / 9.0
				var b : float = minf(a + 0.055 + prog * 0.035, 1.0)
				draw_line(origem.lerp(alvo, a), origem.lerp(alvo, b),
					Color(1.0, 0.18, 0.05, alpha * (0.45 + prog * 0.45)), 2.0 + prog * 2.0)
		draw_circle(alvo, laser_raio + 10.0 + sin(t * 10.0) * 4.0, Color(1.0, 0.08, 0.02, 0.08 + prog * 0.12))
		draw_arc(alvo, laser_raio + 14.0, -t * 2.5, -t * 2.5 + TAU * 0.82, 42, Color(1.0, 0.42, 0.12, 0.58), 2.3)
		draw_arc(alvo, laser_raio + 24.0 * prog, t * 3.0, t * 3.0 + TAU * 0.36, 24, Color(1.0, 0.95, 0.70, 0.38), 1.5)
	else:
		alpha = 1.0 - laser_timer / 0.35
		width = laser_raio * 0.56
		for i in range(7):
			var off := Vector2(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0)) * 2.4
			draw_line(origem + off, alvo + off, Color(1.0, 0.08, 0.02, alpha * 0.16), width * (1.8 - float(i) * 0.15))
		draw_circle(alvo, laser_raio * (1.1 + alpha * 0.7), Color(1.0, 0.30, 0.08, alpha * 0.38))
	draw_line(origem, alvo, Color(1.0, 0.22, 0.08, alpha * 0.32), width * 2.5)
	draw_line(origem, alvo, Color(1.0, 0.58, 0.22, alpha * 0.85), width)
	draw_line(origem, alvo, Color(1.0, 1.0,  0.85, alpha * 0.95), width * 0.3)


func _draw_misseis_visual() -> void:
	var tex_missil := _get_tex("boss_atk_missil_teleguiado")
	var tex_rajada := _get_tex("boss_atk_rajada_tripla")
	for m in misseis:
		var mp    : Vector2 = m["pos"]
		var vel := m["vel"] as Vector2
		var vel_n : Vector2 = vel.normalized() if vel.length_squared() > 0.01 else Vector2.LEFT
		var delay : float = float(m.get("delay", 0.0))
		var kind : String = str(m.get("kind", "missil"))
		if delay > 0.0:
			var warn_alpha : float = 0.18 + 0.18 * sin(t * 14.0)
			draw_circle(mp, float(m.get("raio", 32.0)) * 1.25, Color(1.0, 0.16, 0.04, warn_alpha))
			draw_arc(mp, float(m.get("raio", 32.0)) * 1.6, t * 2.4, t * 2.4 + TAU * 0.65, 24, Color(1.0, 0.42, 0.12, warn_alpha + 0.12), 1.6)
			continue
		var tex : Texture2D = tex_missil if kind == "missil" else tex_rajada
		if tex != null:
			var cols := _atlas_cols(tex)
			var frame : int = clampi(int(floor(float(m["t"]) * (18.0 if kind == "missil" else 22.0))), 0, cols - 1)
			var size := Vector2(148.0, 148.0)
			var rot := vel_n.angle() - PI * 0.25
			if kind == "rajada":
				size = Vector2(112.0, 174.0)
				rot = vel_n.angle() - PI * 0.5
			elif kind == "anel":
				size = Vector2(98.0, 150.0)
				rot = vel_n.angle() - PI * 0.5
			elif kind == "chuva":
				size = Vector2(106.0, 180.0)
				rot = vel_n.angle() - PI * 0.5
			_draw_tex_region_fx(tex, mp, size, _atlas_region(tex, frame), 0.96, rot)
		else:
			for i in range(5):
				var trail := mp - vel_n * float(i) * 7.0
				draw_circle(trail, 7.0 * (1.0 - float(i) * 0.18), Color(1.0, 0.38, 0.12, 0.75 - float(i) * 0.14))
			draw_circle(mp, 7.0, Color(1.0, 0.72, 0.22, 0.95))
			draw_circle(mp, 3.5, Color(1.0, 1.0,  0.85, 1.00))


func _draw_tex_fx(tex: Texture2D, centro: Vector2, size: Vector2, alpha: float, rot: float = 0.0) -> void:
	if tex == null or alpha <= 0.01:
		return
	draw_set_transform(centro, rot, Vector2.ONE)
	draw_texture_rect(tex, Rect2(-size.x * 0.5, -size.y * 0.5, size.x, size.y), false, Color(1.0, 1.0, 1.0, clampf(alpha, 0.0, 1.0)))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _draw_tex_region_fx(tex: Texture2D, centro: Vector2, size: Vector2, region: Rect2, alpha: float, rot: float = 0.0) -> void:
	if tex == null or alpha <= 0.01:
		return
	draw_set_transform(centro, rot, Vector2.ONE)
	draw_texture_rect_region(tex, Rect2(-size.x * 0.5, -size.y * 0.5, size.x, size.y), region, Color(1.0, 1.0, 1.0, clampf(alpha, 0.0, 1.0)))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _region_col(tex: Texture2D, idx: int, cols: int) -> Rect2:
	var tw := float(tex.get_width())
	var th := float(tex.get_height())
	var w := tw / float(cols)
	return Rect2(w * float(idx % cols), 0.0, w, th)


func _atlas_cols(tex: Texture2D) -> int:
	if tex == null or tex.get_height() <= 0:
		return 1
	return maxi(1, int(round(float(tex.get_width()) / float(tex.get_height()))))


func _atlas_region(tex: Texture2D, idx: int) -> Rect2:
	return _region_col(tex, idx, _atlas_cols(tex))


func _draw_atlas_frame(nome: String, centro: Vector2, size: Vector2, prog: float, alpha: float, rot: float = 0.0, fps: float = 18.0) -> void:
	var tex := _get_tex(nome)
	if tex == null:
		return
	var cols := _atlas_cols(tex)
	var frame : int = clampi(int(floor(prog * float(cols - 1) + t * fps * 0.04)), 0, cols - 1)
	_draw_tex_region_fx(tex, centro, size, _atlas_region(tex, frame), alpha, rot)


func _draw_ataque_dante_sprite(id: String, fx: Dictionary, prog: float, alpha: float) -> void:
	var alvo := fx["pos"] as Vector2
	var origem := POS + Vector2(-160.0, 0.0)
	var dir := alvo - origem
	var ang := dir.angle() if dir.length_squared() > 1.0 else 0.0
	match id:
		"rajada_tripla":
			var tex := _get_tex("boss_atk_rajada_tripla")
			if tex == null:
				return
			var cols := _atlas_cols(tex)
			for i in range(3):
				var lane := Vector2(0.0, -26.0 + float(i) * 26.0).rotated(ang)
				var travel : float = clampf(prog * 1.25 - float(i) * 0.10, 0.0, 1.0)
				var p := origem.lerp(alvo, travel) + lane
				var frame : int = clampi(int(floor(travel * float(cols - 1))), 0, cols - 1)
				_draw_tex_region_fx(tex, p, Vector2(74.0, 112.0), _atlas_region(tex, frame), alpha, ang - PI * 0.5)
		"misseis_teleguiados":
			var tex_m := _get_tex("boss_atk_missil_teleguiado")
			if tex_m == null:
				return
			var cols_m := _atlas_cols(tex_m)
			for i in range(4):
				var travel_m : float = clampf(prog * 1.10 - float(i) * 0.08, 0.0, 1.0)
				var curve := Vector2(0.0, sin(travel_m * PI + float(i)) * 76.0).rotated(ang)
				var p_m := origem.lerp(alvo, travel_m) + curve
				var frame_m : int = clampi(int(floor(travel_m * float(cols_m - 1))), 0, cols_m - 1)
				_draw_tex_region_fx(tex_m, p_m, Vector2(96.0, 96.0), _atlas_region(tex_m, frame_m), alpha, ang - PI * 0.25)
		"anel_quebrado":
			var scale : float = 0.62 + prog * 1.10
			_draw_atlas_frame("boss_atk_anel_quebrado", alvo, Vector2(176.0, 176.0) * scale, prog, alpha, t * 0.10, 16.0)
		"laser_avisado":
			var size := Vector2(370.0, 286.0)
			_draw_atlas_frame("boss_atk_laser_avisado", alvo + Vector2(0.0, -22.0), size, prog, alpha, 0.0, 20.0)
		"chuva_lateral":
			_draw_atlas_frame("boss_atk_chuva_lateral", alvo + Vector2(0.0, -4.0), Vector2(430.0, 320.0), prog, alpha, 0.0, 18.0)


func _draw_sprite_ataque(id: String, tex: Texture2D, alvo: Vector2, prog: float, alpha: float) -> void:
	var origem := POS + Vector2(-160.0, 0.0)
	var dir := alvo - origem
	var ang := dir.angle() if dir.length_squared() > 1.0 else 0.0
	var frame : int = int(floor(t * 14.0 + prog * 6.0))
	match id:
		"laser_continuo", "raio_energia", "lanca_energia":
			var mid := origem.lerp(alvo, 0.52)
			var len := maxf(180.0, dir.length())
			var beam_w : float = 92.0
			if id == "laser_continuo":
				beam_w = 76.0
			elif id == "lanca_energia":
				beam_w = 68.0
			for i in range(3):
				var strip := _region_col(tex, frame + i, 3)
				var jitter := Vector2(0.0, sin(t * 18.0 + float(i) * 2.1) * 5.0).rotated(ang)
				_draw_tex_region_fx(tex, mid + jitter, Vector2(beam_w * (1.0 + float(i) * 0.10), len), strip, (0.62 - float(i) * 0.13) * alpha, ang - PI * 0.5)
		"chuva_meteoros":
			for i in range(7):
				var fall := clampf(prog * 1.28 - float(i % 3) * 0.10, 0.0, 1.0)
				var col := (frame + i) % 5
				var strip := _region_col(tex, col, 5)
				var xoff := -130.0 + float(i) * 43.0 + sin(t * 4.0 + float(i)) * 10.0
				var pos := alvo + Vector2(xoff, -210.0 + 250.0 * fall)
				_draw_tex_region_fx(tex, pos, Vector2(72.0, 190.0), strip, 0.90 * alpha, -0.08)
		"onda_choque":
			var sz := 150.0 + prog * 300.0
			for i in range(3):
				_draw_tex_fx(tex, alvo, Vector2(sz + float(i) * 54.0, sz + float(i) * 54.0), (0.64 - float(i) * 0.15) * alpha, sin(t * 2.0 + float(i)) * 0.04)
		"orbe_explosivo", "explosao_plasma", "campo_gravitacional":
			var charge := 0.72 + 0.30 * sin(prog * PI)
			for i in range(3):
				var rcol := _region_col(tex, frame + i, 3)
				_draw_tex_region_fx(tex, alvo, Vector2(180.0 + float(i) * 34.0, 180.0 + float(i) * 34.0) * charge, rcol, (0.72 - float(i) * 0.13) * alpha, t * (0.45 + float(i) * 0.18))
		"satelites_orbitais", "barragem_espiral", "disco_cortante":
			var sz := 210.0 + 46.0 * sin(prog * PI)
			for i in range(3):
				var rcol2 := _region_col(tex, frame + i, 3)
				var orbit := Vector2(cos(t * 2.0 + float(i) * TAU / 3.0), sin(t * 2.0 + float(i) * TAU / 3.0)) * (10.0 + float(i) * 12.0)
				_draw_tex_region_fx(tex, alvo + orbit, Vector2(sz, sz), rcol2, (0.68 - float(i) * 0.10) * alpha, t * (0.8 + float(i) * 0.25))
		"foguete_grande_porte":
			var pos := origem.lerp(alvo, clampf(prog * 1.12, 0.0, 1.0))
			var rocket_frame := _region_col(tex, frame, 3)
			_draw_tex_region_fx(tex, pos, Vector2(118.0, 176.0), rocket_frame, 0.95 * alpha, ang - PI * 0.5)
		"disparo_basico", "rajada_tripla", "misseis_teleguiados":
			var shots : int = 1
			if id == "rajada_tripla":
				shots = 3
			elif id == "misseis_teleguiados":
				shots = 4
			for i in range(shots):
				var lane := Vector2(0.0, -26.0 + float(i) * (52.0 / maxf(float(shots - 1), 1.0))).rotated(ang)
				var p := origem.lerp(alvo, clampf(prog * 1.15 - float(i) * 0.05, 0.0, 1.0)) + lane
				var proj_frame := _region_col(tex, frame + i, 3)
				_draw_tex_region_fx(tex, p, Vector2(72.0, 118.0), proj_frame, 0.92 * alpha, ang - PI * 0.5)
		_:
			_draw_tex_fx(tex, alvo, Vector2(210.0, 210.0), 0.86 * alpha, t * 0.25)


func _draw_efeitos_ataque() -> void:
	for fx in _efeitos_ataque:
		var id : String = fx["id"] as String
		var alvo : Vector2 = fx["pos"] as Vector2
		var dur : float = maxf(float(fx["dur"]), 0.01)
		var prog : float = clampf(float(fx["t"]) / dur, 0.0, 1.0)
		var alpha : float = sin(prog * PI)
		var seed : float = float(fx.get("seed", 0.0))
		var raio : float = float(fx.get("raio", 0.0))
		var hit_at : float = float(fx.get("hit_at", -1.0))
		var tex := _get_tex("atk_" + id)
		if id in ["rajada_tripla", "misseis_teleguiados", "anel_quebrado", "laser_avisado", "chuva_lateral"]:
			if raio > 0.0 and hit_at > 0.0 and float(fx["t"]) < hit_at:
				var arm_n : float = clampf(float(fx["t"]) / hit_at, 0.0, 1.0)
				if id == "laser_avisado":
					for off in [-76.0, 0.0, 76.0]:
						var x : float = alvo.x + off
						draw_line(Vector2(x, 94.0), Vector2(x, 642.0), Color(1.0, 0.12, 0.02, 0.16 + arm_n * 0.34), 1.4 + arm_n * 1.6)
				elif id == "anel_quebrado":
					draw_arc(alvo, 88.0 + arm_n * 72.0, -PI * 0.10, PI * 1.56, 72, Color(1.0, 0.24, 0.05, 0.24 + arm_n * 0.44), 2.0)
					draw_arc(alvo, 88.0 + arm_n * 72.0, PI * 1.78, TAU - PI * 0.22, 36, Color(1.0, 0.24, 0.05, 0.24 + arm_n * 0.44), 2.0)
				elif id == "chuva_lateral":
					for off in [-152.0, -76.0, 0.0, 76.0, 152.0]:
						draw_line(alvo + Vector2(off, -228.0), alvo + Vector2(off, 228.0), Color(1.0, 0.13, 0.02, 0.11 + arm_n * 0.24), 1.6)
				else:
					draw_circle(alvo, raio + arm_n * 18.0, Color(1.0, 0.12, 0.02, 0.035 + arm_n * 0.055))
			_draw_ataque_dante_sprite(id, fx as Dictionary, prog, maxf(alpha, 0.22))
			continue
		if raio > 0.0 and hit_at > 0.0 and float(fx["t"]) < hit_at:
			var arm : float = clampf(float(fx["t"]) / hit_at, 0.0, 1.0)
			draw_circle(alvo, raio, Color(1.0, 0.10, 0.02, 0.035 + arm * 0.055))
			draw_arc(alvo, raio + 4.0, t * 2.0, t * 2.0 + TAU * arm, 58, Color(1.0, 0.25, 0.06, 0.38 + arm * 0.30), 2.0)
			draw_arc(alvo, raio * (0.35 + arm * 0.65), -t * 3.0, -t * 3.0 + TAU * 0.42, 32, Color(1.0, 0.86, 0.42, 0.28 + arm * 0.34), 1.6)
		if tex != null:
			_draw_sprite_ataque(id, tex, alvo, prog, maxf(alpha, 0.18))
		match id:
			"disparo_basico", "rajada_tripla", "misseis_teleguiados":
				var origem := POS + Vector2(-160.0, 0.0)
				for i in range(4):
					var fase : float = fmod(prog + float(i) * 0.18, 1.0)
					var p : Vector2 = origem.lerp(alvo, fase)
					var dir : Vector2 = (alvo - origem).normalized()
					draw_line(p - dir * 24.0, p + dir * 12.0, Color(1.0, 0.42, 0.08, alpha * 0.48), 2.0)
					draw_circle(p, 4.0 + alpha * 3.0, Color(1.0, 0.88, 0.38, alpha * 0.78))
			"laser_continuo", "raio_energia", "lanca_energia":
				var charge : float = 1.0 - absf(prog - 0.5) * 2.0
				for i in range(5):
					var a : float = t * 4.0 + float(i) * TAU / 5.0
					var p : Vector2 = alvo + Vector2(cos(a), sin(a)) * (22.0 + 34.0 * charge)
					draw_line(p, alvo, Color(1.0, 0.18, 0.04, alpha * 0.28), 1.5)
				draw_circle(alvo, 10.0 + 36.0 * charge, Color(1.0, 0.20, 0.03, alpha * 0.20))
				draw_circle(alvo, 4.0 + 9.0 * charge, Color(1.0, 0.90, 0.55, alpha * 0.85))
			"onda_choque":
				for r_i in range(4):
					var rr : float = 24.0 + prog * 260.0 + float(r_i) * 34.0
					draw_arc(alvo, rr, PI * 0.92, PI * 2.08, 64, Color(1.0, 0.20, 0.05, alpha * (0.52 - float(r_i) * 0.08)), 2.2)
				for i in range(8):
					var a : float = PI + (float(i) / 7.0 - 0.5) * PI * 0.9
					draw_line(alvo, alvo + Vector2(cos(a), sin(a)) * (50.0 + prog * 150.0), Color(1.0, 0.55, 0.20, alpha * 0.22), 1.2)
			"campo_gravitacional":
				for r_i in range(6):
					var rr : float = 28.0 + float(r_i) * 19.0 + sin(t * 2.0 + float(r_i)) * 7.0
					draw_arc(alvo, rr, t * (1.0 + float(r_i) * 0.1), t * (1.0 + float(r_i) * 0.1) + TAU * 0.74, 48,
						Color(0.82, 0.18, 1.0, alpha * (0.44 - float(r_i) * 0.045)), 2.0)
				draw_circle(alvo, 18.0 + 14.0 * alpha, Color(0.72, 0.08, 1.0, alpha * 0.28))
			"chuva_meteoros":
				for i in range(9):
					var ox : float = sin(seed + float(i) * 4.7) * 132.0
					var fall : float = clampf(prog * 1.32 - float(i % 3) * 0.08, 0.0, 1.0)
					var head : Vector2 = alvo + Vector2(ox, -210.0 + fall * 245.0)
					var tail : Vector2 = head + Vector2(-26.0, -64.0)
					draw_line(tail, head, Color(1.0, 0.22, 0.04, alpha * 0.75), 3.0)
					draw_circle(head, 5.0 + 6.0 * fall, Color(1.0, 0.78, 0.30, alpha * 0.82))
				if prog > 0.62:
					var boom : float = clampf((prog - 0.62) / 0.38, 0.0, 1.0)
					draw_circle(alvo, 30.0 + boom * 78.0, Color(1.0, 0.22, 0.02, (1.0 - boom) * 0.35))
					draw_circle(alvo, 14.0 + boom * 35.0, Color(1.0, 0.90, 0.32, (1.0 - boom) * 0.45))
			"barragem_espiral", "disco_cortante", "explosao_plasma":
				for i in range(8):
					var a : float = t * 4.8 + float(i) * TAU / 8.0 + prog * TAU
					var r : float = 24.0 + prog * 112.0 + sin(seed + float(i)) * 10.0
					var p : Vector2 = alvo + Vector2(cos(a), sin(a)) * r
					draw_line(alvo, p, Color(0.85, 0.10, 1.0, alpha * 0.14), 1.2)
					draw_circle(p, 5.0 + 9.0 * alpha, Color(0.92, 0.18, 1.0, alpha * 0.58))
				if id == "explosao_plasma":
					draw_circle(alvo, 32.0 + prog * 72.0, Color(0.82, 0.15, 1.0, alpha * 0.22))
			"orbe_explosivo":
				var orb_y : float = -120.0 + prog * 120.0
				var orb : Vector2 = alvo + Vector2(sin(t * 3.0) * 12.0, orb_y)
				draw_line(orb, alvo, Color(1.0, 0.22, 0.04, alpha * 0.25), 1.5)
				draw_circle(orb, 17.0 + 10.0 * alpha, Color(1.0, 0.24, 0.04, alpha * 0.50))
				draw_circle(orb, 6.0 + 5.0 * alpha, Color(1.0, 0.92, 0.50, alpha * 0.92))
			"satelites_orbitais":
				for i in range(5):
					var a : float = -t * 3.2 + float(i) * TAU / 5.0
					var p : Vector2 = alvo + Vector2(cos(a), sin(a)) * (40.0 + 45.0 * prog)
					draw_arc(p, 13.0, a, a + TAU * 0.78, 22, Color(0.78, 0.22, 1.0, alpha * 0.60), 1.7)
					draw_circle(p, 4.0, Color(1.0, 0.75, 1.0, alpha * 0.80))
			"foguete_grande_porte":
				var y : float = -170.0 + prog * 190.0
				var rocket : Vector2 = alvo + Vector2(0.0, y)
				draw_line(rocket + Vector2(0, -70), rocket, Color(1.0, 0.25, 0.02, alpha * 0.68), 6.0)
				draw_circle(rocket, 11.0 + 10.0 * alpha, Color(1.0, 0.88, 0.38, alpha * 0.78))
				if prog > 0.68:
					var boom2 : float = clampf((prog - 0.68) / 0.32, 0.0, 1.0)
					draw_circle(alvo, 40.0 + boom2 * 92.0, Color(1.0, 0.18, 0.02, (1.0 - boom2) * 0.36))
			_:
				draw_arc(alvo, 36.0 + prog * 80.0, 0.0, TAU, 42, Color(1.0, 0.24, 0.08, alpha * 0.42), 2.0)
	if ataque_atual_nome != "":
		draw_string(ThemeDB.fallback_font, POS + Vector2(-160.0, -176.0),
			ataque_atual_nome, HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color(1.0, 0.34, 0.20, 0.92))


func _draw_flash(pos: Vector2, intensity: float) -> void:
	var corpo := PackedVector2Array([
		pos + Vector2(-176, -54), pos + Vector2(-38, -96),
		pos + Vector2(124, -58),  pos + Vector2(188, 0),
		pos + Vector2(124, 58),   pos + Vector2(-38, 96),
		pos + Vector2(-176, 54),  pos + Vector2(-128, 0),
	])
	draw_polygon(corpo, _fill(corpo.size(), Color(1.0, 1.0, 1.0, intensity * 0.48)))


func _draw_hp_bar() -> void:
	var hp_r : float = boss_hp / maxf(boss_max_hp, 1.0)
	var bw   : float = 320.0
	var bx   : float = _ponto_alvo_torre().x - bw * 0.5
	var by   : float = POS.y - 148.0
	var bh   : float = 12.0
	draw_rect(Rect2(bx - 2, by - 2, bw + 4, bh + 4), Color(0, 0, 0, 0.78))
	draw_rect(Rect2(bx, by, bw, bh), Color(0.06, 0.03, 0.04, 0.90))
	if not morto:
		var fc : Color = Color(0.0, 0.72, 1.0)
		if _fase_atual() == FASE_ENFURECIDO:
			fc = Color(1.0, 0.42, 0.04)
		elif _fase_atual() == FASE_CRITICO:
			fc = Color(1.0, 0.06, 0.02)
		draw_rect(Rect2(bx, by, bw * hp_r, bh), fc)
	draw_string(ThemeDB.fallback_font, Vector2(bx, by - 16.0),
		"DANTE [%s] %.0f%%" % [_fase_atual().to_upper(), hp_r * 100.0],
		HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color(1.0, 0.75, 0.75, 0.92))


func _draw_morte() -> void:
	var alpha : float = clampf(1.0 - _morte_t / MORTE_DUR, 0.0, 1.0)
	var die_tex := _get_tex(_boss_sprite_nome())
	if die_tex != null:
		var sz : float = 430.0 * (1.0 + _morte_t / MORTE_DUR * 0.22)
		draw_set_transform(POS, -PI * 0.5, Vector2.ONE)
		draw_texture_rect(die_tex, Rect2(-sz * 0.5, -sz * 0.5, sz, sz), false, Color(1.0, 1.0, 1.0, alpha))
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	if _morte_t < 0.5:
		draw_rect(Rect2(0, 0, 1280, 720), Color(1.0, 0.6, 0.1, (0.5 - _morte_t) * 0.65))
	for exp in _explosoes:
		var et : float = float(exp["t"]) / 0.55
		var er : float = float(exp["r"]) * (1.0 + et * 0.9)
		var ea : float = (1.0 - et) * 0.88
		draw_circle(exp["pos"] as Vector2, er, Color(1.0, 0.52, 0.08, ea))
		draw_circle(exp["pos"] as Vector2, er * 0.45, Color(1.0, 0.92, 0.38, ea * 0.75))


func _draw_fuga() -> void:
	var prog : float = clampf(_fuga_t / FUGA_DUR, 0.0, 1.0)
	var frame : int = clampi(int(floor(prog * float(FUGA_FRAMES))), 0, FUGA_FRAMES - 1)
	var tex := _get_tex("dante_escape_%02d" % frame)
	var tilt := _fuga_tilt
	var rot := -PI * 0.5 + tilt
	var frente := Vector2.LEFT.rotated(tilt)
	var tras := -frente
	var pos : Vector2 = POS + tras * lerpf(-18.0, 48.0, prog) + _shake_off
	var portal : Vector2 = POS + tras * 122.0
	var portal_open : float = sin(clampf(prog * 1.12, 0.0, 1.0) * PI)
	draw_circle(portal, 72.0 * portal_open, Color(1.0, 0.10, 0.02, 0.10 + portal_open * 0.12))
	for i in range(4):
		var rr : float = 36.0 + float(i) * 16.0 + sin(t * 4.0 + float(i)) * 4.0
		draw_arc(portal, rr * portal_open, t * (1.2 + float(i) * 0.2), t * (1.2 + float(i) * 0.2) + TAU * 0.84,
			54, Color(1.0, 0.28, 0.06, (0.55 - float(i) * 0.08) * portal_open), 2.0)
	for i in range(18):
		var a : float = float(i) * TAU / 18.0 + t * 1.8
		var r : float = 42.0 + float((i * 17) % 38)
		var p : Vector2 = portal + Vector2(cos(a), sin(a) * 0.34).rotated(tilt) * r * portal_open
		draw_circle(p, 2.0 + float(i % 3), Color(1.0, 0.24, 0.04, 0.42 * portal_open))
	if tex != null:
		var scale : float = 1.32 - prog * 0.34
		var alpha : float = clampf(1.0 - maxf(0.0, prog - 0.84) / 0.16, 0.0, 1.0)
		draw_set_transform(pos, rot, Vector2.ONE)
		draw_texture_rect(tex, Rect2(-170.0 * scale, -170.0 * scale, 340.0 * scale, 340.0 * scale),
			false, Color(1.0, 1.0, 1.0, alpha))
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	else:
		draw_circle(pos, 80.0 * (1.0 - prog), Color(1.0, 0.18, 0.04, 0.45))
	for i in range(7):
		var xoff : float = -64.0 + float(i) * 21.0
		var lateral := frente.rotated(PI * 0.5)
		var top : Vector2 = pos + tras * 28.0 + lateral * xoff
		var bot : Vector2 = portal + lateral * xoff * 0.35 + frente * (8.0 + sin(t * 3.0 + float(i)) * 8.0)
		draw_line(top, bot, Color(1.0, 0.20, 0.03, (0.34 + 0.22 * sin(t * 5.0 + float(i))) * portal_open), 2.0)
	draw_string(ThemeDB.fallback_font, POS + Vector2(-175.0, -176.0),
		"DANTE FUGIU PARA O PROXIMO SETOR", HORIZONTAL_ALIGNMENT_LEFT, -1, 13,
		Color(1.0, 0.34, 0.20, 0.92))


func _fill(count: int, color: Color) -> PackedColorArray:
	var arr := PackedColorArray()
	arr.resize(count)
	arr.fill(color)
	return arr
