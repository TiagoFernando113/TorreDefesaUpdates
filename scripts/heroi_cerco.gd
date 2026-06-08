extends Node2D

var jogo = null
var hero_id: String = "tanque"
var alvo_torre: Node2D = null
var do_jogador: bool = true

var hp: float = 300.0
var max_hp: float = 300.0
var speed: float = 70.0
var damage: float = 45.0
var tamanho: float = 24.0
var cor: Color = Color(1.0, 0.55, 0.12)
var estrelas: int = 1
var morto: bool = false
var hit_flash: float = 0.0
var pulse: float = 0.0
var gelo_slow: float = 0.0
var veneno_dps: float = 0.0
var veneno_timer: float = 0.0
var queima_dps: float = 0.0
var queima_timer: float = 0.0
var _duelo_alvo = null
var _duelo_timer: float = 0.0
var _last_position: Vector2 = Vector2.ZERO
var _visual_angle: float = 0.0
var _trail: Array[Vector2] = []

const FIGHT_RANGE: float = 6.0


func configurar(id: String, player_side: bool, alvo: Node2D, wave_num: int, estrelas_nivel: int = 1) -> void:
	estrelas = clampi(estrelas_nivel, 1, 3)
	hero_id = id
	do_jogador = player_side
	alvo_torre = alvo
	var escala: float = 1.0 + float(maxi(wave_num - 1, 0)) * 0.08
	match hero_id:
		"assassino":
			max_hp = 170.0 * escala
			speed = 145.0
			damage = 34.0 + float(wave_num) * 2.0
			tamanho = 18.0
			cor = Color(1.0, 0.18, 0.55)
		"invocador":
			max_hp = 240.0 * escala
			speed = 78.0
			damage = 22.0 + float(wave_num)
			tamanho = 22.0
			cor = Color(0.75, 0.25, 1.0)
		"arqueiro":
			max_hp = 120.0 * escala
			speed = 110.0
			damage = 18.0 + float(wave_num) * 1.5
			tamanho = 14.0
			cor = Color(0.2, 0.9, 0.45)
		"guardiao":
			max_hp = 650.0 * escala
			speed = 38.0
			damage = 40.0 + float(wave_num) * 1.5
			tamanho = 32.0
			cor = Color(0.4, 0.65, 1.0)
		"berserker":
			max_hp = 200.0 * escala
			speed = 100.0
			damage = 28.0 + float(wave_num) * 2.5
			tamanho = 20.0
			cor = Color(0.9, 0.1, 0.1)
		_:
			max_hp = 420.0 * escala
			speed = 54.0
			damage = 72.0 + float(wave_num) * 3.0
			tamanho = 28.0
			cor = Color(1.0, 0.55, 0.12)

	match estrelas:
		2:
			max_hp *= 1.75
			damage *= 1.45
			tamanho *= 1.20
		3:
			max_hp *= 3.20
			damage *= 2.10
			tamanho *= 1.45
	hp = max_hp


func _ready() -> void:
	add_to_group("herois_cerco")
	_last_position = global_position
	_visual_angle = 0.0 if do_jogador else PI


func _process(delta: float) -> void:
	if morto:
		return
	pulse = fmod(pulse + delta * 4.0, TAU)
	hit_flash = maxf(0.0, hit_flash - delta * 5.0)
	gelo_slow = maxf(0.0, gelo_slow - delta)
	if veneno_timer > 0.0:
		veneno_timer = maxf(0.0, veneno_timer - delta)
		receber_dano(veneno_dps * delta, true)
	if queima_timer > 0.0:
		queima_timer = maxf(0.0, queima_timer - delta)
		receber_dano(queima_dps * delta, true)
	if not (alvo_torre and is_instance_valid(alvo_torre)):
		queue_free()
		return

	var inimigo: Node = _heroi_inimigo_mais_proximo()
	if inimigo:
		_duelar(inimigo, delta)
		_atualizar_animacao(delta)
		queue_redraw()
		return
	_duelo_alvo = null

	var dir := alvo_torre.global_position - global_position
	var dist := dir.length()
	if dist <= tamanho + 24.0:
		if alvo_torre.has_method("receber_dano"):
			alvo_torre.call("receber_dano", damage)
		_morrer(false)
		return
	var slow := 0.35 if gelo_slow > 0.0 else 1.0
	global_position += dir.normalized() * speed * slow * delta
	_atualizar_animacao(delta)
	queue_redraw()


func _atualizar_animacao(delta: float) -> void:
	var vel := global_position - _last_position
	if vel.length() > 0.4:
		_visual_angle = lerp_angle(_visual_angle, atan2(vel.y, vel.x), minf(delta * 10.0, 1.0))
		_trail.append(to_local(_last_position))
		if _trail.size() > 8:
			_trail.pop_front()
	else:
		if not _trail.is_empty():
			_trail.pop_front()
	_last_position = global_position


func _heroi_inimigo_mais_proximo():
	var melhor: Node = null
	var melhor_dist: float = INF
	for h in get_tree().get_nodes_in_group("herois_cerco"):
		if h == self or not is_instance_valid(h):
			continue
		if h.get("morto") == true:
			continue
		if (h.get("do_jogador") == true) == do_jogador:
			continue
		var d := global_position.distance_to((h as Node2D).global_position)
		if d < melhor_dist:
			melhor_dist = d
			melhor = h
	return melhor


func _duelar(inimigo: Node, delta: float) -> void:
	_duelo_alvo = inimigo
	var inimigo_pos := (inimigo as Node2D).global_position
	var dir := inimigo_pos - global_position
	var dist := dir.length()
	var fight_dist: float = tamanho + float(inimigo.get("tamanho")) + FIGHT_RANGE
	var slow := 0.35 if gelo_slow > 0.0 else 1.0
	if dist > fight_dist:
		var move_dir := inimigo_pos - global_position
		if move_dir.length() > 2.0:
			global_position += move_dir.normalized() * speed * slow * delta
		return

	_duelo_timer -= delta
	if _duelo_timer <= 0.0:
		_duelo_timer = 0.45
		var vantagem: float = _vantagem_contra(str(inimigo.get("hero_id")))
		if hero_id == "berserker" and max_hp > 0.0 and hp / max_hp < 0.40:
			vantagem *= 1.50
		if inimigo.has_method("receber_dano"):
			inimigo.call("receber_dano", damage * vantagem)
		hit_flash = 1.0


func _vantagem_contra(outro_id: String) -> float:
	if hero_id == "assassino" and outro_id == "invocador":
		return 1.30
	if hero_id == "invocador" and outro_id == "tanque":
		return 1.30
	if hero_id == "tanque" and outro_id == "assassino":
		return 1.30
	if hero_id == "arqueiro" and outro_id == "assassino":
		return 1.40
	if hero_id == "guardiao" and outro_id == "arqueiro":
		return 1.40
	return 1.0


func receber_dano(dano: float, _aoe: bool = false) -> void:
	if morto:
		return
	hp -= dano
	hit_flash = 1.0
	if hp <= 0.0:
		_morrer(true)
	queue_redraw()


func _morrer(derrotado: bool) -> void:
	if morto:
		return
	morto = true
	remove_from_group("herois_cerco")
	queue_free()


func _draw() -> void:
	var c := Color.WHITE if hit_flash > 0.05 else cor
	var a := 0.72 + sin(pulse) * 0.18
	var dark := Color(c.r * 0.13, c.g * 0.13, c.b * 0.13, 0.96)
	var mid := Color(c.r * 0.36, c.g * 0.36, c.b * 0.36, 0.92)
	var light := Color(c.r, c.g, c.b, a)

	_draw_trail(c)
	draw_set_transform(Vector2.ZERO, _visual_angle, Vector2.ONE)
	_draw_thruster(c)
	match hero_id:
		"assassino":
			_draw_interceptor(dark, light)
		"invocador":
			_draw_orbital(dark, light, mid)
		"arqueiro":
			_draw_rail_drone(dark, light)
		"guardiao":
			_draw_shield_frigate(dark, light, mid)
		"berserker":
			_draw_volatile_ship(dark, light)
		_:
			_draw_battleship(dark, light, mid)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

	var w := tamanho * 2.0
	var y := -tamanho - 12.0
	if _duelo_alvo and is_instance_valid(_duelo_alvo):
		draw_arc(Vector2.ZERO, tamanho + 12.0, 0.0, TAU, 32, Color(1.0, 0.85, 0.25, 0.5), 2.0)
	if estrelas >= 2:
		var anel_cor := Color(1.0, 0.85, 0.1, 0.75) if estrelas == 3 else Color(0.78, 0.85, 1.0, 0.65)
		var anel_r := tamanho + (4.0 + sin(pulse * 2.0) * 2.0 if estrelas == 3 else 3.0)
		draw_arc(Vector2.ZERO, anel_r, 0.0, TAU, 48, anel_cor, 2.5 if estrelas == 3 else 1.8)

	draw_rect(Rect2(-w / 2.0, y, w, 4.0), Color(0, 0, 0, 0.55))
	draw_rect(Rect2(-w / 2.0, y, w * clampf(hp / maxf(max_hp, 1.0), 0.0, 1.0), 4.0), Color(c.r, c.g, c.b, 0.9))
	if estrelas > 1:
		var star_cor := Color(1.0, 0.88, 0.1) if estrelas == 3 else Color(0.78, 0.85, 1.0)
		var sx := -float(estrelas - 1) * 5.0
		for si in range(estrelas):
			draw_circle(Vector2(sx + float(si) * 10.0, y + 9.0), 3.0, star_cor)


func _draw_trail(c: Color) -> void:
	for i in range(_trail.size()):
		var t := float(i + 1) / float(maxi(_trail.size(), 1))
		draw_circle(_trail[i], tamanho * 0.18 * t, Color(c.r, c.g, c.b, 0.20 * t))


func _draw_thruster(c: Color) -> void:
	var flicker := 0.75 + sin(pulse * 3.2) * 0.25
	var flame := PackedVector2Array([
		Vector2(-tamanho * 0.72, -tamanho * 0.22),
		Vector2(-tamanho * (1.18 + 0.18 * flicker), 0.0),
		Vector2(-tamanho * 0.72, tamanho * 0.22),
	])
	draw_polygon(flame, _fill(flame.size(), Color(c.r, c.g, c.b, 0.28 + 0.28 * flicker)))
	draw_polyline(flame + PackedVector2Array([flame[0]]), Color(0.8, 0.95, 1.0, 0.40), 1.2)


func _draw_interceptor(dark: Color, light: Color) -> void:
	var r := tamanho
	var hull := PackedVector2Array([
		Vector2(r * 1.45, 0.0),
		Vector2(r * 0.25, -r * 0.24),
		Vector2(-r * 0.28, -r * 0.55),
		Vector2(-r * 1.05, -r * 1.05),
		Vector2(-r * 0.62, -r * 0.18),
		Vector2(-r * 1.16, 0.0),
		Vector2(-r * 0.62, r * 0.18),
		Vector2(-r * 1.05, r * 1.05),
		Vector2(-r * 0.28, r * 0.55),
		Vector2(r * 0.25, r * 0.24),
	])
	draw_polygon(hull, _fill(hull.size(), dark))
	draw_polyline(hull + PackedVector2Array([hull[0]]), light, 2.4)
	draw_line(Vector2(-r * 0.20, -r * 0.44), Vector2(r * 1.10, -r * 0.08), Color(1, 1, 1, 0.34), 1.3)
	draw_line(Vector2(-r * 0.20, r * 0.44), Vector2(r * 1.10, r * 0.08), Color(1, 1, 1, 0.34), 1.3)
	draw_line(Vector2(r * 0.15, 0.0), Vector2(r * 1.28, 0.0), Color(1, 1, 1, 0.62), 1.5)
	draw_circle(Vector2(r * 0.15, 0.0), r * 0.16, light)


func _draw_orbital(dark: Color, light: Color, mid: Color) -> void:
	var r := tamanho
	var core := PackedVector2Array([
		Vector2(r * 0.58, 0.0),
		Vector2(r * 0.18, -r * 0.48),
		Vector2(-r * 0.42, -r * 0.34),
		Vector2(-r * 0.58, 0.0),
		Vector2(-r * 0.16, r * 0.50),
		Vector2(r * 0.44, r * 0.30),
	])
	draw_polygon(core, _fill(core.size(), dark))
	draw_polyline(core + PackedVector2Array([core[0]]), light, 2.4)
	draw_arc(Vector2.ZERO, r * 1.12, pulse, pulse + PI * 1.35, 36, light, 2.2)
	draw_arc(Vector2.ZERO, r * 0.78, -pulse * 0.7, -pulse * 0.7 + PI * 1.60, 28, Color(1, 1, 1, 0.45), 1.4)
	draw_circle(Vector2.ZERO, r * 0.20, Color(1, 1, 1, 0.55))
	for i in range(4):
		var ang := pulse + float(i) * TAU / 4.0
		var p := Vector2(cos(ang), sin(ang)) * r * (0.92 + 0.12 * float(i % 2))
		draw_rect(Rect2(p - Vector2(r * 0.10, r * 0.10), Vector2(r * 0.20, r * 0.20)), mid)


func _draw_rail_drone(dark: Color, light: Color) -> void:
	var r := tamanho
	var body := PackedVector2Array([
		Vector2(r * 0.58, 0.0),
		Vector2(r * 0.10, -r * 0.34),
		Vector2(-r * 0.58, -r * 0.28),
		Vector2(-r * 0.76, 0.0),
		Vector2(-r * 0.58, r * 0.28),
		Vector2(r * 0.10, r * 0.34),
	])
	draw_polygon(body, _fill(body.size(), dark))
	draw_polyline(body + PackedVector2Array([body[0]]), light, 2.1)
	draw_line(Vector2(-r * 0.34, -r * 0.74), Vector2(r * 0.12, -r * 0.32), light, 2.2)
	draw_line(Vector2(-r * 0.34, r * 0.74), Vector2(r * 0.12, r * 0.32), light, 2.2)
	draw_line(Vector2(r * 0.10, 0.0), Vector2(r * 1.72, 0.0), Color(0.85, 1.0, 0.86, 0.92), 2.4)
	draw_circle(Vector2(r * 1.76, 0.0), r * 0.08, Color(1, 1, 1, 0.85))


func _draw_shield_frigate(dark: Color, light: Color, mid: Color) -> void:
	var r := tamanho
	var shell := PackedVector2Array([
		Vector2(r * 0.92, 0.0),
		Vector2(r * 0.42, -r * 0.72),
		Vector2(-r * 0.58, -r * 0.82),
		Vector2(-r * 1.02, -r * 0.36),
		Vector2(-r * 1.02, r * 0.36),
		Vector2(-r * 0.58, r * 0.82),
		Vector2(r * 0.42, r * 0.72),
	])
	draw_polygon(shell, _fill(shell.size(), dark))
	draw_polyline(shell + PackedVector2Array([shell[0]]), light, 2.7)
	draw_rect(Rect2(Vector2(-r * 0.42, -r * 0.30), Vector2(r * 0.62, r * 0.60)), mid)
	draw_arc(Vector2(r * 0.42, 0.0), r * 1.05, -PI * 0.58, PI * 0.58, 30, Color(light.r, light.g, light.b, 0.78), 3.4)
	draw_arc(Vector2(r * 0.42, 0.0), r * 0.72, -PI * 0.48, PI * 0.48, 24, Color(1, 1, 1, 0.34), 1.8)


func _draw_volatile_ship(dark: Color, light: Color) -> void:
	var r := tamanho
	var shake := sin(pulse * 6.0) * r * 0.06
	var hull := PackedVector2Array([
		Vector2(r * 1.10, shake),
		Vector2(r * 0.28, -r * 0.35),
		Vector2(r * 0.04, -r * 1.02),
		Vector2(-r * 0.34, -r * 0.42),
		Vector2(-r * 1.02, -r * 0.70),
		Vector2(-r * 0.54, 0.0),
		Vector2(-r * 1.02, r * 0.70),
		Vector2(-r * 0.34, r * 0.42),
		Vector2(r * 0.04, r * 1.02),
		Vector2(r * 0.28, r * 0.35),
	])
	draw_polygon(hull, _fill(hull.size(), dark))
	draw_polyline(hull + PackedVector2Array([hull[0]]), light, 2.8)
	draw_line(Vector2(-r * 0.28, -r * 0.60), Vector2(r * 0.82, -r * 0.12), Color(1, 1, 1, 0.34), 1.4)
	draw_line(Vector2(-r * 0.28, r * 0.60), Vector2(r * 0.82, r * 0.12), Color(1, 1, 1, 0.34), 1.4)
	draw_arc(Vector2.ZERO, r * 1.05, 0.0, TAU, 36, Color(1.0, 0.12, 0.05, 0.18 + 0.12 * absf(sin(pulse * 4.0))), 2.0)


func _draw_battleship(dark: Color, light: Color, mid: Color) -> void:
	var r := tamanho
	var hull := PackedVector2Array([
		Vector2(r * 1.08, 0.0),
		Vector2(r * 0.54, -r * 0.54),
		Vector2(r * 0.20, -r * 0.88),
		Vector2(-r * 0.68, -r * 0.76),
		Vector2(-r * 1.12, -r * 0.32),
		Vector2(-r * 1.12, r * 0.32),
		Vector2(-r * 0.68, r * 0.76),
		Vector2(r * 0.20, r * 0.88),
		Vector2(r * 0.54, r * 0.54),
	])
	draw_polygon(hull, _fill(hull.size(), dark))
	draw_polyline(hull + PackedVector2Array([hull[0]]), light, 2.6)
	draw_rect(Rect2(Vector2(-r * 0.62, -r * 0.36), Vector2(r * 0.36, r * 0.72)), mid)
	draw_rect(Rect2(Vector2(-r * 0.18, -r * 0.24), Vector2(r * 0.58, r * 0.48)), mid)
	draw_circle(Vector2(r * 0.48, 0.0), r * 0.17, Color(1, 1, 1, 0.72))
	draw_line(Vector2(-r * 0.82, -r * 0.52), Vector2(-r * 0.34, -r * 0.32), light, 2.0)
	draw_line(Vector2(-r * 0.82, r * 0.52), Vector2(-r * 0.34, r * 0.32), light, 2.0)


func _fill(count: int, color: Color) -> PackedColorArray:
	var arr := PackedColorArray()
	arr.resize(count)
	arr.fill(color)
	return arr
