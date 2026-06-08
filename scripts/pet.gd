extends Node2D

## Comandante - controlador invisivel com stats e habilidade dinamicos por piloto ativo

const PROJETIL_SCENE = preload("res://scenes/Projetil.tscn")
const COMANDANTE_SEM_SPRITE_CAMPO : bool = true

const VEL_RETORNO  : float  = 180.0
const BASE_POS     : Vector2 = Vector2(640, 360)
const _LIMITES     := Rect2(80, 80, 1120, 560)
const ASSIST_SPRITE_BASE : String = "res://assets/sprites/assistentes/"

var jogo = null

# Stats dinâmicos (carregados em _init_stats)
var _dano       : float = 22.0
var _cd_ataque_max : float = 1.8
var _alcance    : float = 130.0
var _vel        : float = 72.0
var _hab_cd_max : float = 35.0
var _hab_dur    : float = 15.0
var _hab_tipo   : String = "hacker"
var _cor        : Color  = Color(0.25, 0.75, 1.0)
var _pid        : String = "cyron"
var _aurora_heal_frac : float = 0.18
var _eclipse_slow_forca : float = 0.65
var _repetir_chance : float = 0.0

var _estado       : String  = "vagando"
var _alvo                   = null
var _cd_ataque    : float   = 0.0
var _hab_cd       : float   = 0.0
var _destino      : Vector2 = Vector2.ZERO
var _cd_destino   : float   = 0.0
var _hit_flash    : float   = 0.0
var _angulo       : float   = 0.0
var _pulso        : float   = 0.0
var _boost_timer  : float   = 0.0
var _orbit_angulo : float   = 0.0
var _sprite_visual_id : String = ""
var _sprite_frames : Dictionary = {}
var _sprite_special : Dictionary = {}


func _init_stats() -> bool:
	_pid = Salvar.pet_ativo
	var info : Dictionary = Salvar.PETS_INFO.get(_pid, {}) as Dictionary
	if info.is_empty() or not Salvar.pet_desbloqueado(_pid):
		return false
	var stats : Dictionary = Salvar.pet_stats(_pid)
	_dano          = float(stats.get("dano",       22.0))
	_cd_ataque_max = float(stats.get("cd_ataque",  1.8))
	_alcance       = float(stats.get("alcance",    130.0))
	_vel           = float(stats.get("vel",         72.0))
	_hab_cd_max    = float(stats.get("hab_cd",      35.0))
	_hab_dur       = float(stats.get("hab_dur",     15.0))
	_aurora_heal_frac = float(stats.get("aurora_heal", 0.18))
	_eclipse_slow_forca = float(stats.get("eclipse_slow", 0.65))
	var equip_bonus : Dictionary = Salvar.equipamentos_bonus_stats()
	_repetir_chance = clampf(float(equip_bonus.get("repetir_assistente", 0.0)), 0.0, 0.75)
	_hab_tipo      = str(info.get("hab_tipo",      "hacker"))
	_cor           = info.get("cor",               Color(0.25, 0.75, 1.0)) as Color
	if not COMANDANTE_SEM_SPRITE_CAMPO:
		_carregar_sprites_assistente()
	return true


func _visual_assistente_id() -> String:
	match _pid:
		"nexus":
			return "dante"
		"aurora":
			return "cyron"
		"eclipse":
			return "phantom"
		_:
			return _pid


func _load_assistente_tex(file_name: String) -> Texture2D:
	if _sprite_visual_id == "":
		return null
	var path : String = ASSIST_SPRITE_BASE + _sprite_visual_id + "/" + file_name
	if ResourceLoader.exists(path):
		return load(path) as Texture2D
	return null


func _carregar_sprites_assistente() -> void:
	_sprite_visual_id = _visual_assistente_id()
	_sprite_frames.clear()
	_sprite_special.clear()
	for dir_key in ["front", "back", "up", "down", "left", "right"]:
		var frames : Array = []
		for i in range(3):
			var tex := _load_assistente_tex("%s_%d.png" % [dir_key, i])
			if tex != null:
				frames.append(tex)
		if not frames.is_empty():
			_sprite_frames[dir_key] = frames
	for special_key in [
		"idle", "alert", "aggressive", "attack", "dash", "charging",
		"happy", "support", "orb", "shield",
		"invisible", "teleport_start", "teleport_end", "explosion", "drain"
	]:
		var stex := _load_assistente_tex("%s.png" % special_key)
		if stex != null:
			_sprite_special[special_key] = stex


func _sprite_dir_key() -> String:
	var dir := Vector2(cos(_angulo), sin(_angulo))
	if dir.length() < 0.01:
		return "front"
	if absf(dir.x) > absf(dir.y):
		return "right" if dir.x > 0.0 else "left"
	return "down" if dir.y > 0.0 else "up"


func _sprite_special_key() -> String:
	if _estado == "hackeando":
		match _sprite_visual_id:
			"dante":
				return "charging"
			"cyron":
				return "support"
			"phantom":
				return "teleport_end"
	return ""


func _draw_assistente_sprite(flash: bool) -> bool:
	var tex : Texture2D = null
	var special := _sprite_special_key()
	if special != "" and _sprite_special.has(special):
		tex = _sprite_special[special] as Texture2D
	if tex == null:
		var dir_key := _sprite_dir_key()
		var frames : Array = _sprite_frames.get(dir_key, []) as Array
		if frames.is_empty():
			frames = _sprite_frames.get("front", []) as Array
		if not frames.is_empty():
			tex = frames[0] as Texture2D
	if tex == null:
		return false

	var sz : float = 52.0
	match _sprite_visual_id:
		"cyron":
			sz = 46.0
		"dante":
			sz = 54.0
		"phantom":
			sz = 54.0
	var pulse_alpha : float = 0.20 + sin(_pulso * 2.0) * 0.08
	draw_circle(Vector2.ZERO, sz * 0.34, Color(_cor.r, _cor.g, _cor.b, pulse_alpha))
	draw_texture_rect(tex, Rect2(-sz * 0.5, -sz * 0.5, sz, sz), false, Color(1.0, 1.0, 1.0, 1.0))
	if flash:
		draw_circle(Vector2.ZERO, sz * 0.38, Color(1.0, 1.0, 1.0, 0.22))
	return true


func _ready() -> void:
	if not _init_stats():
		queue_free()
		return
	if COMANDANTE_SEM_SPRITE_CAMPO:
		visible = false
		position = _base_pos()
		return
	var ang := randf_range(0.0, TAU)
	var base := _base_pos()
	position = base + Vector2(cos(ang), sin(ang)) * randf_range(40.0, 100.0)
	_novo_destino()


func _process(delta: float) -> void:
	if COMANDANTE_SEM_SPRITE_CAMPO:
		_process_comandante(delta)
		return
	_cd_ataque  = maxf(0.0, _cd_ataque  - delta)
	_cd_destino = maxf(0.0, _cd_destino - delta)
	_hit_flash  = maxf(0.0, _hit_flash  - delta * 3.0)
	_pulso      = fmod(_pulso + delta * 2.5, TAU)
	if _hab_cd > 0.0:
		_hab_cd = maxf(0.0, _hab_cd - delta)

	match _estado:
		"vagando":
			var mob = _mob_mais_proximo(INF)
			if mob:
				_alvo = mob; _estado = "perseguindo"; return
			_mover_para(_destino, delta)
			if _destino.distance_to(position) < 12.0 or _cd_destino <= 0.0:
				_novo_destino()
		"perseguindo":
			var melhor = _mob_mais_proximo(INF)
			if melhor: _alvo = melhor
			if not _alvo_valido(): _estado = "vagando"; return
			var alvo_pos := _target_pos(_alvo)
			_mover_para(alvo_pos, delta)
			if position.distance_to(alvo_pos) <= _alcance_para_alvo(_alvo):
				_estado = "atacando"
		"atacando":
			var melhor = _mob_mais_proximo(INF)
			if melhor: _alvo = melhor
			if not _alvo_valido(): _estado = "vagando"; return
			var alvo_pos := _target_pos(_alvo)
			if position.distance_to(alvo_pos) > _alcance_para_alvo(_alvo) + 10.0:
				_estado = "perseguindo"; return
			if _cd_ataque <= 0.0:
				_atacar()
		"retornando":
			var base_ret := _base_pos()
			_mover_para(base_ret, delta * (VEL_RETORNO / _vel))
			if position.distance_to(base_ret) < 18.0:
				_estado       = "hackeando"
				_boost_timer  = _hab_dur
				_orbit_angulo = 0.0
				_aplicar_boost()
		"hackeando":
			_boost_timer  = maxf(0.0, _boost_timer - delta)
			_orbit_angulo = fmod(_orbit_angulo + delta * 3.8, TAU)
			position = _base_pos() + Vector2(cos(_orbit_angulo), sin(_orbit_angulo)) * 22.0
			if _boost_timer <= 0.0:
				_hab_cd = 0.0 if _rolar_repetir_habilidade() else _hab_cd_max
				_estado = "saindo"
		"saindo":
			_novo_destino()
			_estado = "vagando"

	_limitar_posicao_arena()
	queue_redraw()


func _process_comandante(delta: float) -> void:
	position = _base_pos()
	_cd_ataque = maxf(0.0, _cd_ataque - delta)
	_hit_flash = maxf(0.0, _hit_flash - delta * 3.0)
	_pulso = fmod(_pulso + delta * 2.5, TAU)
	if _hab_cd > 0.0:
		_hab_cd = maxf(0.0, _hab_cd - delta)

	match _estado:
		"retornando":
			_estado = "hackeando"
			_boost_timer = _hab_dur
			_aplicar_boost()
		"hackeando":
			_boost_timer = maxf(0.0, _boost_timer - delta)
			if _boost_timer <= 0.0:
				_hab_cd = 0.0 if _rolar_repetir_habilidade() else _hab_cd_max
				_estado = "vagando"
		"saindo":
			_estado = "vagando"

	if _estado in ["vagando", "perseguindo", "atacando"]:
		var melhor = _mob_mais_proximo(INF)
		if melhor:
			_alvo = melhor
			_estado = "atacando"
			if _cd_ataque <= 0.0:
				_atacar()
		else:
			_alvo = null
			_estado = "vagando"


func ativar_habilidade() -> bool:
	if _estado in ["retornando", "hackeando", "saindo"]: return false
	if _hab_cd > 0.0: return false
	_estado = "retornando"
	_alvo   = null
	return true


# Legacy alias kept for compatibility
func ativar_hacker() -> bool:
	return ativar_habilidade()


func get_hacker_cd() -> float:
	return _hab_cd


func get_em_analise() -> bool:
	return _estado in ["retornando", "hackeando"]


func get_boost_prog() -> float:
	if _estado != "hackeando" or _hab_dur <= 0.0: return 0.0
	return _boost_timer / _hab_dur


func _rolar_repetir_habilidade() -> bool:
	return _repetir_chance > 0.0 and randf() < _repetir_chance


func _aplicar_boost() -> void:
	if not (jogo and is_instance_valid(jogo)): return
	var t = jogo.torre
	if not (t and is_instance_valid(t)): return
	match _hab_tipo:
		"hacker":
			t.ia_boost_ativo = true
			t.ia_boost_timer = _hab_dur
		"sobrecarga":
			t.ia_dano_boost_ativo = true
			t.ia_dano_boost_timer = _hab_dur
		"interferencia":
			for m in get_tree().get_nodes_in_group("mobs"):
				if is_instance_valid(m) and not m.get("morto"):
					m.set("habil_stun_timer", _hab_dur)
		"aurora":
			t.hp = minf(t.max_hp, t.hp + t.max_hp * _aurora_heal_frac)
			t.ia_boost_ativo = true
			t.ia_boost_timer = _hab_dur
		"eclipse":
			for m in get_tree().get_nodes_in_group("mobs"):
				if is_instance_valid(m) and not m.get("morto"):
					m.set("gelo_slow", maxf(float(m.get("gelo_slow")), _eclipse_slow_forca))
					m.set("veneno_timer", maxf(float(m.get("veneno_timer")), _hab_dur))


func _mob_mais_proximo(raio: float):
	var melhor = null; var md : float = raio
	var base := _base_pos()
	for m in _alvos_combate():
		if not is_instance_valid(m) or m.get("morto") == true: continue
		var pos_alvo := _target_pos(m)
		var d : float = base.distance_to(pos_alvo)
		if d < md: md = d; melhor = m
	return melhor


func _alvo_valido() -> bool:
	return _alvo != null and is_instance_valid(_alvo) and not (_alvo.get("morto") == true) and not (_alvo.get("fugindo") == true)


func _alvos_combate() -> Array:
	var alvos : Array = []
	for m in get_tree().get_nodes_in_group("mobs"):
		if is_instance_valid(m):
			alvos.append(m)
	if jogo and is_instance_valid(jogo):
		var boss = jogo.get("_dante_boss")
		if boss != null and is_instance_valid(boss) and not (boss.get("morto") == true) and not (boss.get("fugindo") == true):
			alvos.append(boss)
	return alvos


func _target_pos(alvo) -> Vector2:
	if alvo != null and is_instance_valid(alvo) and alvo.has_method("get_target_position"):
		return alvo.call("get_target_position") as Vector2
	if alvo is Node2D:
		return (alvo as Node2D).global_position
	return global_position


func _alcance_para_alvo(alvo) -> float:
	if alvo != null and is_instance_valid(alvo) and alvo.is_in_group("boss_dante"):
		return maxf(_alcance, 520.0)
	return _alcance


func _atacar() -> void:
	_cd_ataque = _cd_ataque_max
	if not _alvo_valido(): return
	_hit_flash = 1.0
	var proj = PROJETIL_SCENE.instantiate()
	get_parent().add_child(proj)
	proj.global_position = _base_pos() if COMANDANTE_SEM_SPRITE_CAMPO else global_position
	proj.setup(_alvo, _dano)


func _mover_para(dest: Vector2, delta: float) -> void:
	var dir := dest - global_position
	if dir.length() < 2.0: return
	dir = dir.normalized()
	_angulo = dir.angle()
	global_position += dir * _vel * delta


func _get_torre_range() -> float:
	if jogo and is_instance_valid(jogo) and jogo.torre and is_instance_valid(jogo.torre):
		return float(jogo.torre.range_r) * 0.82
	return 200.0


func _base_pos() -> Vector2:
	if jogo and is_instance_valid(jogo) and jogo.torre and is_instance_valid(jogo.torre):
		return (jogo.torre as Node2D).global_position
	return BASE_POS


func _limites_movimento() -> Rect2:
	return _LIMITES


func _limitar_posicao_arena() -> void:
	pass


func _novo_destino() -> void:
	var raio : float = _get_torre_range()
	var ang  : float = randf_range(0.0, TAU)
	var dist : float = randf_range(30.0, raio)
	var dest : Vector2 = _base_pos() + Vector2(cos(ang), sin(ang)) * dist
	var lim := _limites_movimento()
	_destino    = dest.clamp(lim.position, lim.position + lim.size)
	_cd_destino = randf_range(2.5, 5.5)


func _draw() -> void:
	var pulso_a : float = 0.5 + sin(_pulso) * 0.18
	var flash   : bool  = _hit_flash > 0.05

	# ── HACKEANDO — órbita na torre ────────────────────────────────────────────
	if _estado == "hackeando":
		var prog : float = get_boost_prog()
		draw_arc(Vector2.ZERO, 12.0, 0.0, TAU * prog, 48, Color(_cor.r, _cor.g, _cor.b, 0.85), 2.5)
		draw_arc(Vector2.ZERO, 12.0, 0.0, TAU,        48, Color(_cor.r, _cor.g, _cor.b, 0.18), 1.0)
		if _draw_assistente_sprite(flash):
			draw_string(ThemeDB.fallback_font, Vector2(-10, 24),
				"%.1fs" % _boost_timer, HORIZONTAL_ALIGNMENT_LEFT, -1, 9,
				Color(_cor.r, _cor.g, _cor.b, 0.85))
			return
		draw_circle(Vector2.ZERO, 7.0,  Color(_cor.r * 0.2, _cor.g * 0.2, _cor.b * 0.2, 0.95))
		draw_circle(Vector2.ZERO, 5.0,  Color(_cor.r, _cor.g, _cor.b, 0.7 + sin(_pulso) * 0.2))
		draw_circle(Vector2.ZERO, 2.5,  Color(1.0, 1.0, 1.0, 0.9))
		draw_string(ThemeDB.fallback_font, Vector2(-10, 20),
			"%.1fs" % _boost_timer, HORIZONTAL_ALIGNMENT_LEFT, -1, 9,
			Color(_cor.r, _cor.g, _cor.b, 0.85))
		return

	# ── RETORNANDO — seta direcional ────────────────────────────────────────────
	if _estado == "retornando":
		if _draw_assistente_sprite(flash):
			return
		var fwd := Vector2(cos(_angulo), sin(_angulo))
		var lft := Vector2(-fwd.y, fwd.x)
		var pts  := PackedVector2Array([fwd * 12.0, lft * 5.0 - fwd * 4.0, -lft * 5.0 - fwd * 4.0])
		draw_colored_polygon(pts, Color(_cor.r, _cor.g, _cor.b, 0.75))
		draw_polyline(pts + PackedVector2Array([pts[0]]), Color(_cor.r + 0.2, _cor.g + 0.2, _cor.b + 0.2, 0.9), 1.5)
		for i in 3:
			var back : Vector2 = -fwd * float(i + 1) * 7.0
			draw_circle(back, 2.0 - float(i) * 0.5, Color(_cor.r, _cor.g, _cor.b, 0.4 - float(i) * 0.12))
		return

	var atk_cor : Color = Color(1.0, 0.35, 0.1) if _estado == "atacando" else _cor
	if _draw_assistente_sprite(flash):
		return

	match _pid:
		"nexus":
			_draw_nexus(atk_cor, pulso_a, flash)
		"phantom":
			_draw_phantom(atk_cor, pulso_a, flash)
		_:
			_draw_cyron(atk_cor, pulso_a, flash)


func _draw_cyron(atk_cor: Color, pulso_a: float, flash: bool) -> void:
	# Robô retangular clássico
	draw_rect(Rect2(-7, -4, 14, 13), Color(0.0, 0.0, 0.0, 0.22))
	var c_cor := Color(1.0, 1.0, 1.0, 0.85) if flash else Color(0.06, 0.12, 0.24, 0.96)
	draw_rect(Rect2(-8, -7, 16, 14), c_cor)
	var b := Color(atk_cor.r, atk_cor.g, atk_cor.b, pulso_a)
	draw_line(Vector2(-8,-7), Vector2( 8,-7), b, 1.5)
	draw_line(Vector2( 8,-7), Vector2( 8, 7), b, 1.5)
	draw_line(Vector2( 8, 7), Vector2(-8, 7), b, 1.5)
	draw_line(Vector2(-8, 7), Vector2(-8,-7), b, 1.5)
	for pt in [Vector2(-8,-7), Vector2(8,-7), Vector2(8,7), Vector2(-8,7)]:
		draw_circle(pt, 1.2, Color(atk_cor.r, atk_cor.g, atk_cor.b, pulso_a * 0.8))
	draw_line(Vector2(0,-7), Vector2(0,-14), Color(0.45, 0.85, 1.0, 0.8), 1.5)
	draw_circle(Vector2(0,-15), 2.2, atk_cor)
	draw_circle(Vector2(0,-15), 1.0 + sin(_pulso) * 0.6, Color(1.0,1.0,1.0, pulso_a))
	draw_rect(Rect2(-5,-5, 10, 7), Color(0.0, 0.06, 0.16, 0.96))
	var scan_y : float = -5.0 + fmod(_pulso / TAU * 7.0, 7.0)
	draw_line(Vector2(-5, scan_y), Vector2(5, scan_y), Color(0.15, 1.0, 0.45, 0.35), 1.0)
	var eye := Vector2(cos(_angulo), sin(_angulo)) * 2.5
	draw_circle(eye, 2.3, Color(0.0,0.0,0.0))
	draw_circle(eye, 1.5, atk_cor)
	draw_line(Vector2(-8, -2), Vector2(-10, -2), b, 1.0)
	draw_line(Vector2(-8,  2), Vector2(-10,  2), b, 1.0)
	draw_line(Vector2( 8, -2), Vector2( 10, -2), b, 1.0)
	draw_line(Vector2( 8,  2), Vector2( 10,  2), b, 1.0)
	draw_line(Vector2(-4, 7), Vector2(-5, 12), Color(0.45, 0.85, 1.0, 0.7), 2.0)
	draw_line(Vector2( 4, 7), Vector2( 5, 12), Color(0.45, 0.85, 1.0, 0.7), 2.0)
	draw_string(ThemeDB.fallback_font, Vector2(-8,-20), "CYRON",
		HORIZONTAL_ALIGNMENT_LEFT, -1, 7, Color(_cor.r, _cor.g, _cor.b, 0.55))


func _draw_nexus(atk_cor: Color, pulso_a: float, flash: bool) -> void:
	# Drone robusto octogonal laranja
	var c_cor := Color(1.0, 0.8, 0.5, 0.9) if flash else Color(0.18, 0.09, 0.03, 0.95)
	var pts := PackedVector2Array()
	for i in 8:
		var a := float(i) * TAU / 8.0 + PI / 8.0
		pts.append(Vector2(cos(a), sin(a)) * 12.0)
	var fills := PackedColorArray()
	for _f in 8: fills.append(c_cor)
	draw_polygon(pts, fills)
	var brd := PackedVector2Array(pts); brd.append(pts[0])
	draw_polyline(brd, Color(atk_cor.r, atk_cor.g, atk_cor.b, pulso_a), 2.0)
	# Núcleo pulsante
	draw_circle(Vector2.ZERO, 5.0 + sin(_pulso) * 1.5,
		Color(atk_cor.r, atk_cor.g, atk_cor.b, 0.85))
	draw_circle(Vector2.ZERO, 2.5, Color(1.0, 0.9, 0.7, 0.95))
	# 4 thruster dots
	for i in 4:
		var ta := float(i) * TAU / 4.0
		draw_circle(Vector2(cos(ta), sin(ta)) * 11.0, 2.0,
			Color(atk_cor.r, atk_cor.g, atk_cor.b, 0.7))
	draw_string(ThemeDB.fallback_font, Vector2(-12,-20), "NEXUS",
		HORIZONTAL_ALIGNMENT_LEFT, -1, 7, Color(_cor.r, _cor.g, _cor.b, 0.55))


func _draw_phantom(atk_cor: Color, pulso_a: float, flash: bool) -> void:
	# Drone furtivo losangular roxo com rastro fantasma
	var alpha : float = 0.55 + sin(_pulso) * 0.2
	var c_cor := Color(0.8, 0.6, 1.0, 0.9) if flash else Color(0.12, 0.04, 0.2, alpha)
	var pts := PackedVector2Array([
		Vector2(0, -14), Vector2(10, 0), Vector2(0, 10), Vector2(-10, 0)
	])
	var fills := PackedColorArray()
	for _f in 4: fills.append(c_cor)
	draw_polygon(pts, fills)
	var brd := PackedVector2Array(pts); brd.append(pts[0])
	draw_polyline(brd, Color(atk_cor.r, atk_cor.g, atk_cor.b, pulso_a), 1.8)
	# Olho central
	draw_circle(Vector2.ZERO, 4.0, Color(0.0, 0.0, 0.0, 0.9))
	draw_circle(Vector2.ZERO, 2.5, Color(atk_cor.r, atk_cor.g, atk_cor.b, 0.95))
	draw_circle(Vector2.ZERO, 1.0, Color(1.0, 1.0, 1.0, 0.9))
	# Aura semi-transparente de interferência
	draw_arc(Vector2.ZERO, 18.0, 0.0, TAU, 32,
		Color(atk_cor.r, atk_cor.g, atk_cor.b, 0.12 + sin(_pulso) * 0.06), 1.2)
	draw_string(ThemeDB.fallback_font, Vector2(-14,-22), "PHANTOM",
		HORIZONTAL_ALIGNMENT_LEFT, -1, 7, Color(_cor.r, _cor.g, _cor.b, 0.55))
