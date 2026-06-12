extends Node2D

const _STAR_COUNT : int = 210
const _MAP_TRANSITION_TIME : float = 4.8
var _stars : Array = []
var _time : float = 0.0
var _mapa_visivel_id : String = ""
var _mapa_desenhado_info : Dictionary = {}
var _mapa_anterior_info : Dictionary = {}
var _mapa_destino_info : Dictionary = {}
var _transicao_timer : float = 0.0
var _mapa_texture_cache : Dictionary = {}
var _bau_evento_tex : Texture2D = null
var _bau_evento_tex_carregado : bool = false


func _ready() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 42
	for i in range(_STAR_COUNT):
		_stars.append({
			"pos": Vector2(rng.randf_range(-900.0, 2180.0), rng.randf_range(-560.0, 1280.0)),
			"size": rng.randf_range(0.45, 2.2),
			"alpha_base": rng.randf_range(0.08, 0.50),
			"phase": rng.randf_range(0.0, TAU),
			"speed": rng.randf_range(0.22, 1.05),
			"layer": rng.randi_range(0, 2),
		})


func _process(delta: float) -> void:
	_time += delta
	var atual := _mapa_atual()
	var id := str(atual.get("id", "setor_inicial"))
	if _mapa_visivel_id == "":
		_mapa_visivel_id = id
		_mapa_desenhado_info = atual
	elif id != _mapa_visivel_id:
		_mapa_anterior_info = _mapa_desenhado_info.duplicate(true) if not _mapa_desenhado_info.is_empty() else atual.duplicate(true)
		_mapa_destino_info = atual.duplicate(true)
		_mapa_desenhado_info = atual.duplicate(true)
		_mapa_visivel_id = id
		_transicao_timer = _MAP_TRANSITION_TIME
	_transicao_timer = maxf(0.0, _transicao_timer - delta)
	queue_redraw()


func _mapa_atual() -> Dictionary:
	var mapa : Dictionary = Salvar.mapa_teste_info()
	var main := get_parent()
	if main and main.get("mapa_atual_info") is Dictionary:
		var mi := main.get("mapa_atual_info") as Dictionary
		if not mi.is_empty():
			mapa = mi
	return mapa


func _wave_atual() -> int:
	var main := get_parent()
	if main:
		var w = main.get("wave")
		if w is int:
			return w
		if w is float:
			return floori(w)
	return 1


func _draw() -> void:
	var mapa := _mapa_atual()
	var id := str(mapa.get("id", "setor_inicial"))
	var cor : Color = mapa.get("cor", Color(0.0, 0.72, 1.0)) as Color

	var zoom : float = 1.0
	var vp := get_viewport()
	if vp:
		var cam := vp.get_camera_2d()
		if cam:
			zoom = cam.zoom.x
	var vp_size := vp.get_visible_rect().size if vp else Vector2(1280, 720)
	var margin : float = 180.0
	var half_w : float = (vp_size.x * 0.5) / zoom + margin
	var half_h : float = (vp_size.y * 0.5) / zoom + margin
	var rect := Rect2(640.0 - half_w, 360.0 - half_h, half_w * 2.0, half_h * 2.0)

	if _transicao_timer > 0.0 and not _mapa_anterior_info.is_empty() and not _mapa_destino_info.is_empty():
		_draw_mapa_em_viagem(_mapa_anterior_info, _mapa_destino_info, rect)
	else:
		_draw_mapa(mapa, rect)


func _draw_mapa(mapa: Dictionary, rect: Rect2) -> void:
	var id := str(mapa.get("id", "setor_inicial"))
	var cor : Color = mapa.get("cor", Color(0.0, 0.72, 1.0)) as Color
	var final_mapa : bool = Salvar.mapa_final_ativo(_wave_atual())
	var tex := _mapa_texture(mapa)
	if tex != null:
		draw_rect(rect, Color(0.0, 0.0, 0.0, 1.0))
		_draw_texture_cover(tex, rect, 1.0)
	else:
		if id == "setor_inicial":
			_draw_setor_inicial(rect)
		else:
			_draw_espaco_profundo(rect, cor)
			_draw_nevoa_distante(cor)
			_draw_planeta_do_mapa(id)
			if final_mapa:
				_draw_perspectiva_invasao(cor)

	_draw_estrelas(id, cor)
	var main := get_parent()
	var boss_ativo : bool = main and is_instance_valid(main) and main.get("_dante_boss") != null and is_instance_valid(main.get("_dante_boss") as Node)
	var boss_encerrado : bool = main and is_instance_valid(main) and main.get("_dante_boss_encerrado") == true
	if final_mapa and not boss_ativo and not boss_encerrado:
		_draw_fonte_invasao(id, cor)
	# ── Overlay de gameplay: baú de evento + cone de focus ────────────────────
	_draw_overlay_gameplay(main)


func _mapa_texture(mapa: Dictionary) -> Texture2D:
	var path := str(mapa.get("bg", ""))
	if path == "":
		return null
	if _mapa_texture_cache.has(path):
		return _mapa_texture_cache[path] as Texture2D
	var tex := _load_texture_file(path)
	_mapa_texture_cache[path] = tex
	return tex


func _load_texture_file(path: String) -> Texture2D:
	if ResourceLoader.exists(path):
		var imported_tex := load(path) as Texture2D
		if imported_tex != null:
			return imported_tex
	if not FileAccess.file_exists(path):
		return null
	var img := Image.load_from_file(path)
	if img == null:
		var abs_path := ProjectSettings.globalize_path(path)
		if abs_path != path:
			img = Image.load_from_file(abs_path)
	if img == null or img.get_width() <= 0 or img.get_height() <= 0:
		return null
	return ImageTexture.create_from_image(img)


func _draw_texture_cover(tex: Texture2D, rect: Rect2, alpha: float = 1.0) -> void:
	if tex == null:
		return
	var tw := float(tex.get_width())
	var th := float(tex.get_height())
	if tw <= 0.0 or th <= 0.0 or rect.size.x <= 0.0 or rect.size.y <= 0.0:
		return
	var target_ratio := rect.size.x / rect.size.y
	var src_ratio := tw / th
	var src := Rect2(0.0, 0.0, tw, th)
	if src_ratio > target_ratio:
		var new_w := th * target_ratio
		src.position.x = (tw - new_w) * 0.5
		src.size.x = new_w
	else:
		var new_h := tw / target_ratio
		src.position.y = (th - new_h) * 0.5
		src.size.y = new_h
	draw_texture_rect_region(tex, rect, src, Color(1.0, 1.0, 1.0, alpha))


func _draw_mapa_em_viagem(anterior: Dictionary, destino: Dictionary, rect: Rect2) -> void:
	var cor_destino : Color = destino.get("cor", Color(0.0, 0.72, 1.0)) as Color
	var rest : float = clampf(_transicao_timer / _MAP_TRANSITION_TIME, 0.0, 1.0)
	var prog : float = 1.0 - rest
	var eased : float = prog * prog * (3.0 - 2.0 * prog)
	var old_offset : Vector2 = Vector2(lerpf(0.0, -760.0, eased), lerpf(0.0, 70.0, eased))
	var new_offset : Vector2 = Vector2(lerpf(920.0, 0.0, eased), lerpf(-95.0, 0.0, eased))

	draw_set_transform(old_offset, 0.0, Vector2.ONE)
	_draw_mapa(anterior, rect)
	draw_set_transform(new_offset, 0.0, Vector2.ONE)
	_draw_mapa(destino, rect)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

	_draw_rastro_viagem(cor_destino, rest, eased)


func _draw_setor_inicial(rect: Rect2) -> void:
	draw_rect(rect, Color(0.008, 0.008, 0.025))


func _draw_espaco_profundo(rect: Rect2, cor: Color) -> void:
	var base := Color(0.004 + cor.r * 0.012, 0.005 + cor.g * 0.010, 0.014 + cor.b * 0.026)
	draw_rect(rect, base)
	var centro : Vector2 = rect.get_center()
	for i in range(7, 0, -1):
		var t : float = float(i) / 7.0
		draw_circle(centro + Vector2(260.0, -130.0), 520.0 * t,
			Color(cor.r, cor.g, cor.b, 0.010 * t))
		draw_circle(centro + Vector2(-360.0, 210.0), 440.0 * t,
			Color(cor.r * 0.55, cor.g * 0.45, cor.b, 0.006 * t))


func _draw_estrelas(id: String, cor: Color) -> void:
	var tint := Color(0.75, 0.85, 1.0)
	if id != "setor_inicial":
		tint = Color(0.68 + cor.r * 0.25, 0.78 + cor.g * 0.18, 1.0)
	for raw in _stars:
		var s := raw as Dictionary
		var p : Vector2 = s["pos"] as Vector2
		var layer : int = int(s.get("layer", 0))
		if id != "setor_inicial":
			p.x += sin(_time * (0.015 + float(layer) * 0.012)) * (12.0 + float(layer) * 8.0)
			p.y += cos(_time * (0.010 + float(layer) * 0.010)) * (5.0 + float(layer) * 4.0)
		var twinkle : float = sin(_time * float(s["speed"]) + float(s["phase"])) * (0.045 if id == "setor_inicial" else 0.07)
		var a : float = clampf(float(s["alpha_base"]) + twinkle, 0.04, 0.62)
		var sz : float = float(s["size"])
		var c := Color(tint.r, tint.g, tint.b, a)
		if sz <= 1.0:
			draw_rect(Rect2(p.x, p.y, 1.0, 1.0), c)
		else:
			draw_circle(p, sz * 0.5, c)


func _draw_nevoa_distante(cor: Color) -> void:
	var centers := [
		Vector2(820, 150),
		Vector2(960, 470),
		Vector2(300, 560),
	]
	for i in range(centers.size()):
		var base := centers[i] as Vector2
		for r in range(5, 0, -1):
			var t := float(r) / 5.0
			var drift := Vector2(sin(_time * 0.06 + float(i)) * 18.0, cos(_time * 0.04 + float(i)) * 10.0)
			draw_circle(base + drift, 180.0 * t, Color(cor.r, cor.g, cor.b, 0.018 * t))


func _draw_planeta_do_mapa(id: String) -> void:
	match id:
		"nebulosa_fraturada":
			_draw_planeta_3d(Vector2(1030, 145), 120.0, Color(0.16, 0.03, 0.25), Color(0.80, 0.18, 1.0), false)
			_draw_planeta_3d(Vector2(210, 585), 42.0, Color(0.02, 0.12, 0.16), Color(0.0, 0.85, 1.0), false)
		"orbita_glacial":
			_draw_planeta_3d(Vector2(1010, 535), 145.0, Color(0.04, 0.16, 0.24), Color(0.58, 0.92, 1.0), true)
		"nucleo_abissal":
			_draw_planeta_3d(Vector2(175, 135), 105.0, Color(0.14, 0.02, 0.05), Color(1.0, 0.10, 0.30), false)
			_draw_planeta_3d(Vector2(1120, 240), 58.0, Color(0.10, 0.02, 0.18), Color(0.75, 0.08, 1.0), false)
		"coroa_void":
			_draw_planeta_3d(Vector2(965, 150), 155.0, Color(0.18, 0.12, 0.02), Color(1.0, 0.78, 0.14), true)


func _draw_planeta_3d(pos: Vector2, raio: float, sombra: Color, luz: Color, anel: bool) -> void:
	for i in range(10, 0, -1):
		var t : float = float(i) / 10.0
		var p : Vector2 = pos + Vector2(-raio * 0.20 * (1.0 - t), -raio * 0.16 * (1.0 - t))
		var c : Color = sombra.lerp(luz, (1.0 - t) * 0.38)
		draw_circle(p, raio * t, Color(c.r, c.g, c.b, 0.18 + t * 0.50))
	draw_circle(pos + Vector2(-raio * 0.32, -raio * 0.28), raio * 0.42, Color(luz.r, luz.g, luz.b, 0.20))
	draw_circle(pos + Vector2(raio * 0.34, raio * 0.20), raio * 0.72, Color(0.0, 0.0, 0.0, 0.20))
	draw_arc(pos, raio + 1.5, 0.0, TAU, 80, Color(luz.r, luz.g, luz.b, 0.38), 1.3)
	if anel:
		draw_arc(pos, raio * 1.38, -0.35, PI + 0.35, 100, Color(luz.r, luz.g, luz.b, 0.30), 2.0)
		draw_arc(pos, raio * 1.12, -0.30, PI + 0.30, 100, Color(luz.r, luz.g, luz.b, 0.16), 1.2)


func _draw_perspectiva_invasao(cor: Color) -> void:
	var origem : Vector2 = Vector2(1160, 360)
	for y in [245.0, 360.0, 475.0]:
		draw_line(Vector2(720, y), origem, Color(cor.r, cor.g, cor.b, 0.055), 1.2)
	for i in range(3):
		var p : Vector2 = Vector2(770.0 + float(i) * 105.0, 360.0 + sin(_time * 0.7 + float(i)) * 18.0)
		draw_circle(p, 4.0, Color(cor.r, cor.g, cor.b, 0.16))


func _draw_fonte_invasao(id: String, cor: Color) -> void:
	_draw_rotas_spawn_inimigo(cor)
	match id:
		"setor_inicial":
			_draw_nave_inimiga_destrocos(Vector2(1135, 360), cor, "INICIAL")
		"nebulosa_fraturada":
			_draw_nave_inimiga_destrocos(Vector2(1135, 360), cor, "NEBULOSA")
		"orbita_glacial":
			_draw_nave_inimiga_destrocos(Vector2(1140, 360), cor, "GLACIAL")
		"nucleo_abissal":
			_draw_nave_inimiga_destrocos(Vector2(1145, 360), cor, "ABISSAL")
		"coroa_void":
			_draw_nave_inimiga_destrocos(Vector2(1150, 360), cor, "VOID")
		_:
			_draw_nave_inimiga_destrocos(Vector2(1135, 360), cor, "INICIAL")


func _draw_rotas_spawn_inimigo(cor: Color) -> void:
	var saidas : Array = [
		Vector2(978.0, 302.0),
		Vector2(978.0, 360.0),
		Vector2(978.0, 418.0),
	]
	for i in range(saidas.size()):
		var p : Vector2 = saidas[i] as Vector2
		var pulse : float = 0.45 + 0.25 * sin(_time * 2.4 + float(i))
		draw_line(p + Vector2(-10.0, 0.0), p + Vector2(-210.0, 0.0), Color(cor.r, cor.g, cor.b, 0.11), 3.0)
		draw_line(p + Vector2(-28.0, -7.0), p + Vector2(-178.0, -24.0), Color(cor.r, cor.g, cor.b, 0.08), 1.4)
		draw_line(p + Vector2(-28.0, 7.0), p + Vector2(-178.0, 24.0), Color(cor.r, cor.g, cor.b, 0.08), 1.4)
		draw_circle(p, 18.0, Color(1.0, 0.20, 0.08, 0.08 + 0.05 * pulse))
		draw_arc(p, 18.0, _time * 0.9 + float(i), _time * 0.9 + float(i) + PI * 1.55, 34, Color(1.0, 0.30, 0.12, 0.54), 2.2)
		draw_circle(p + Vector2(-6.0, 0.0), 5.0, Color(1.0, 0.32, 0.16, 0.60 + 0.25 * pulse))
		for j in range(3):
			var fase : float = fmod(_time * 0.58 + float(j) * 0.34 + float(i) * 0.17, 1.0)
			var x : float = lerpf(p.x - 8.0, p.x - 210.0, fase)
			var y : float = p.y + sin(fase * PI * 2.0 + float(i)) * 7.0
			var a : float = sin(fase * PI) * 0.36
			draw_circle(Vector2(x, y), 4.0 + 3.0 * fase, Color(1.0, 0.35, 0.12, a))
			draw_line(Vector2(x + 18.0, y), Vector2(x - 24.0, y), Color(cor.r, cor.g, cor.b, a * 0.55), 2.0)


func _draw_nave_inimiga_destrocos(pos: Vector2, cor: Color, variante: String) -> void:
	var bob : Vector2 = Vector2(sin(_time * 0.45) * 3.0, cos(_time * 0.38) * 4.0)
	pos += bob
	var sombra : Color = Color(0.020, 0.014, 0.028, 0.94)
	var casco : Color = Color(0.075 + cor.r * 0.035, 0.045 + cor.g * 0.025, 0.085 + cor.b * 0.030, 0.92)
	var asa_sup := PackedVector2Array([
		pos + Vector2(-180, -112),
		pos + Vector2(-44, -76),
		pos + Vector2(76, -116),
		pos + Vector2(152, -52),
		pos + Vector2(26, -30),
		pos + Vector2(-150, -52),
	])
	var asa_inf := PackedVector2Array([
		pos + Vector2(-180, 112),
		pos + Vector2(-44, 76),
		pos + Vector2(76, 116),
		pos + Vector2(152, 52),
		pos + Vector2(26, 30),
		pos + Vector2(-150, 52),
	])
	var corpo := PackedVector2Array([
		pos + Vector2(-176, -54),
		pos + Vector2(-38, -96),
		pos + Vector2(124, -58),
		pos + Vector2(188, 0),
		pos + Vector2(124, 58),
		pos + Vector2(-38, 96),
		pos + Vector2(-176, 54),
		pos + Vector2(-128, 0),
	])
	draw_polygon(asa_sup, _fill(asa_sup.size(), Color(sombra.r, sombra.g, sombra.b, 0.70)))
	draw_polygon(asa_inf, _fill(asa_inf.size(), Color(sombra.r, sombra.g, sombra.b, 0.70)))
	draw_polygon(corpo, _fill(corpo.size(), casco))
	draw_polyline(corpo + PackedVector2Array([corpo[0]]), Color(cor.r, cor.g, cor.b, 0.62), 2.4)
	draw_polyline(asa_sup + PackedVector2Array([asa_sup[0]]), Color(cor.r, cor.g, cor.b, 0.34), 1.6)
	draw_polyline(asa_inf + PackedVector2Array([asa_inf[0]]), Color(cor.r, cor.g, cor.b, 0.34), 1.6)
	for k in range(5):
		var px : float = pos.x - 86.0 + float(k) * 42.0
		var py : float = pos.y - 42.0 + sin(_time * 1.6 + float(k)) * 4.0
		var blink : float = 0.22 + 0.18 * sin(_time * 2.8 + float(k) * 1.7)
		draw_line(Vector2(px, py), Vector2(px + 24.0, py + 8.0), Color(cor.r, cor.g, cor.b, blink), 1.5)

	var hangar : Vector2 = pos + Vector2(-158.0, 0.0)
	draw_rect(Rect2(hangar.x - 22.0, hangar.y - 74.0, 34.0, 148.0), Color(0.0, 0.0, 0.0, 0.55))
	var porta_alpha : float = 0.62 + 0.20 * sin(_time * 2.2)
	draw_line(hangar + Vector2(-22, -74), hangar + Vector2(-22, 74), Color(1.0, 0.25, 0.10, porta_alpha), 3.0)
	for idx in range(3):
		var sy : float = [-58.0, 0.0, 58.0][idx]
		var porta : Vector2 = hangar + Vector2(0.0, sy)
		var carga : float = 0.5 + 0.5 * sin(_time * 3.2 + float(idx) * 1.4)
		draw_circle(porta, 16.0 + carga * 7.0, Color(1.0, 0.20, 0.08, 0.08 + 0.08 * carga))
		draw_arc(porta, 15.0 + carga * 4.0, _time * 1.5 + float(idx), _time * 1.5 + float(idx) + TAU * 0.72, 30, Color(1.0, 0.30, 0.12, 0.48 + 0.22 * carga), 1.8)
		draw_line(porta + Vector2(-8.0, 0.0), porta + Vector2(-88.0 - carga * 30.0, 0.0), Color(1.0, 0.22, 0.08, 0.14 + 0.12 * carga), 2.0)

	_draw_nucleo_vilao(pos + Vector2(55.0, 0.0), cor, variante)
	_draw_destrocos_nave(pos, cor)


func _draw_nucleo_vilao(pos: Vector2, cor: Color, variante: String) -> void:
	var pulso : float = 0.5 + 0.5 * sin(_time * 1.35)
	draw_circle(pos, 48.0 + pulso * 10.0, Color(cor.r, cor.g, cor.b, 0.06 + 0.06 * pulso))
	draw_arc(pos, 52.0 + pulso * 5.0, _time * 0.35, _time * 0.35 + TAU, 64, Color(cor.r, cor.g, cor.b, 0.28 + 0.16 * pulso), 2.0)
	draw_arc(pos, 66.0 + pulso * 8.0, -_time * 0.24, -_time * 0.24 + PI * 1.35, 64, Color(cor.r, cor.g, cor.b, 0.20), 1.4)
	var olho_cor : Color = Color(1.0, 0.22, 0.08, 0.82)
	if variante == "GLACIAL":
		olho_cor = Color(0.55, 0.95, 1.0, 0.82)
	elif variante == "VOID":
		olho_cor = Color(1.0, 0.78, 0.16, 0.82)
	draw_polygon(PackedVector2Array([
		pos + Vector2(-38, 0),
		pos + Vector2(-8, -18),
		pos + Vector2(42, 0),
		pos + Vector2(-8, 18),
	]), _fill(4, Color(olho_cor.r, olho_cor.g, olho_cor.b, 0.26)))
	draw_circle(pos + Vector2(2.0, 0.0), 8.0 + pulso * 3.0, olho_cor)


func _draw_destrocos_nave(pos: Vector2, cor: Color) -> void:
	var pecas : Array = [
		Vector2(-224.0, -92.0),
		Vector2(-238.0, 74.0),
		Vector2(-92.0, -128.0),
		Vector2(22.0, 126.0),
		Vector2(166.0, -92.0),
	]
	for i in range(pecas.size()):
		var p : Vector2 = pos + (pecas[i] as Vector2) + Vector2(sin(_time * 0.7 + float(i)) * 4.0, cos(_time * 0.5 + float(i)) * 3.0)
		var tam : float = 12.0 + float(i % 3) * 5.0
		var frag := PackedVector2Array([
			p + Vector2(-tam, -tam * 0.35),
			p + Vector2(tam * 0.65, -tam * 0.70),
			p + Vector2(tam, tam * 0.40),
			p + Vector2(-tam * 0.45, tam * 0.75),
		])
		draw_polygon(frag, _fill(4, Color(0.025, 0.025, 0.038, 0.78)))
		draw_polyline(frag + PackedVector2Array([frag[0]]), Color(cor.r, cor.g, cor.b, 0.25), 1.1)


func _draw_portal(pos: Vector2, cor: Color) -> void:
	for i in range(5):
		var r : float = 34.0 + float(i) * 16.0 + sin(_time * 1.1 + float(i)) * 3.0
		draw_arc(pos, r, _time * 0.25 + float(i), _time * 0.25 + float(i) + PI * 1.35, 60, Color(cor.r, cor.g, cor.b, 0.32 - float(i) * 0.04), 1.8)
	draw_circle(pos, 28.0, Color(cor.r, cor.g, cor.b, 0.08))


func _draw_entidade(pos: Vector2, cor: Color) -> void:
	draw_circle(pos, 64.0, Color(cor.r * 0.10, cor.g * 0.06, cor.b * 0.08, 0.72))
	draw_arc(pos, 64.0, 0.0, TAU, 64, Color(cor.r, cor.g, cor.b, 0.42), 2.0)
	draw_arc(pos, 92.0, _time * 0.23, _time * 0.23 + PI * 1.22, 72, Color(cor.r, cor.g, cor.b, 0.26), 1.6)
	var eye : Vector2 = pos + Vector2(-12.0, -5.0)
	draw_circle(eye, 12.0, Color(cor.r, cor.g, cor.b, 0.62))
	draw_circle(eye, 4.0, Color(1.0, 1.0, 1.0, 0.72))


func _draw_guias_centrais(id: String, cor: Color) -> void:
	var centro : Vector2 = Vector2(640, 360)
	var guia : Color = Color(0.06, 0.14, 0.30, 0.12) if id == "setor_inicial" else Color(cor.r, cor.g, cor.b, 0.10)
	for r in [140, 310, 550]:
		draw_arc(centro, float(r), 0.0, TAU, 90, guia, 1.0)
	draw_line(Vector2(centro.x, centro.y - 12), Vector2(centro.x, centro.y + 12), Color(guia.r, guia.g, guia.b, 0.26), 1.5)
	draw_line(Vector2(centro.x - 12, centro.y), Vector2(centro.x + 12, centro.y), Color(guia.r, guia.g, guia.b, 0.26), 1.5)


func _draw_rastro_viagem(cor: Color, rest: float, eased: float) -> void:
	var intensidade : float = sin(eased * PI)
	draw_rect(Rect2(-220, -120, 1680, 960), Color(0.0, 0.0, 0.0, 0.10 * intensidade))

	for i in range(38):
		var fi : float = float(i)
		var y : float = -60.0 + fi * 24.0 + sin(_time * 2.5 + fi) * 5.0
		var inicio_x : float = lerpf(1220.0, 160.0, eased) + sin(fi * 8.31) * 90.0
		var tamanho : float = lerpf(120.0, 420.0, intensidade)
		var alpha : float = (0.04 + 0.12 * intensidade) * rest
		draw_line(
			Vector2(inicio_x + tamanho, y - 20.0),
			Vector2(inicio_x - tamanho * 0.25, y + 35.0),
			Color(cor.r, cor.g, cor.b, alpha),
			1.2 + 2.2 * intensidade
		)

	var brilho_x : float = lerpf(1030.0, 365.0, eased)
	draw_circle(Vector2(brilho_x, 360.0), 52.0 + 20.0 * intensidade, Color(cor.r, cor.g, cor.b, 0.08 * intensidade))
	draw_arc(Vector2(brilho_x, 360.0), 72.0 + 25.0 * intensidade, -0.8, 0.8, 36, Color(cor.r, cor.g, cor.b, 0.22 * intensidade), 2.0)


func _fill(count: int, color: Color) -> PackedColorArray:
	var arr := PackedColorArray()
	arr.resize(count)
	arr.fill(color)
	return arr


# ── Overlay gameplay: baú de evento + cone de focus ──────────────────────────

func _draw_overlay_gameplay(main: Node) -> void:
	if not main or not is_instance_valid(main):
		return

	# ── Focus de Ataque ───────────────────────────────────────────────────────
	var torre = main.get("torre")
	if torre and is_instance_valid(torre) and (torre.get("focus_ativo") == true):
		var fdir  : Vector2 = torre.get("focus_dir")  as Vector2
		var ftmr  : float   = torre.get("focus_timer") as float
		var alpha : float   = clampf(ftmr / 6.0, 0.0, 1.0)
		var c     : Vector2 = (torre as Node2D).global_position
		var rang  : float   = torre.get("range_r") as float
		var ang_c : float   = atan2(fdir.y, fdir.x)
		var half  : float   = PI / 3.0
		var steps : int     = 28
		var pts   : PackedVector2Array = PackedVector2Array()
		pts.append(c)
		for i in range(steps + 1):
			var a : float = ang_c - half + float(i) / float(steps) * half * 2.0
			pts.append(c + Vector2(cos(a), sin(a)) * rang)
		draw_polygon(pts, _fill(pts.size(), Color(1.0, 0.85, 0.1, alpha * 0.28)))
		draw_arc(c, rang, ang_c - half, ang_c + half, 32, Color(1.0, 0.95, 0.2, alpha * 0.90), 3.5)
		draw_line(c, c + fdir * rang, Color(1.0, 0.95, 0.3, alpha * 0.55), 2.0)
		# Anel de calor: mostra nível de spin (cadência+projéteis)
		var mspin : float = maxf(float(torre.get("_manual_spin")), 0.0)
		if mspin > 0.02:
			draw_arc(c, 24.0, -PI * 0.5, -PI * 0.5 + TAU * mspin, 36, Color(1.0, 0.85 - mspin * 0.65, 0.05, mspin * 0.90), 5.5)

	# ── Baú de evento no mapa ─────────────────────────────────────────────────
	var ev_ativo : Dictionary = main.get("_evento_ativo") as Dictionary
	var ev_pos   : Vector2    = main.get("_evento_pos")   as Vector2
	var ev_timer : float      = main.get("_evento_timer") as float
	if ev_ativo.is_empty() or ev_pos == Vector2.ZERO:
		return

	var ev_cor  : Color = ev_ativo.get("cor",  Color(1.0, 0.82, 0.1)) as Color
	var ev_dur  : float = maxf(float(ev_ativo.get("dur", 8.0)), 0.01)
	var frac    : float = clampf(ev_timer / ev_dur, 0.0, 1.0)
	var pulse   : float = 0.5 + 0.5 * sin(float(Time.get_ticks_msec()) * 0.006)
	var ep      : Vector2 = ev_pos
	# Glow externo (sombra do baú)
	draw_circle(ep, 44.0 + pulse * 8.0, Color(ev_cor.r, ev_cor.g, ev_cor.b, 0.12 + pulse * 0.08))
	# Anel de countdown
	draw_arc(ep, 38.0, -PI * 0.5, -PI * 0.5 + TAU * frac, 48,
			Color(ev_cor.r, ev_cor.g, ev_cor.b, 0.95), 5.0)
	# Sprite do baú caindo
	var bau_tex : Texture2D = _obter_bau_evento_tex()
	if bau_tex != null:
		var bob   : float = pulse * 4.0
		var size  : Vector2 = Vector2(48.0, 48.0)
		var rect  := Rect2(ep - size * 0.5 - Vector2(0, bob), size)
		draw_texture_rect(bau_tex, rect, false)
	else:
		draw_circle(ep, 28.0, Color(0.06, 0.06, 0.12, 0.92))
		draw_circle(ep, 24.0, Color(ev_cor.r * 0.25, ev_cor.g * 0.25, ev_cor.b * 0.25, 0.90))
		draw_circle(ep, 12.0 + pulse * 4.0, Color(ev_cor.r, ev_cor.g, ev_cor.b, 0.75 + pulse * 0.20))


func _obter_bau_evento_tex() -> Texture2D:
	if not _bau_evento_tex_carregado:
		_bau_evento_tex_carregado = true
		_bau_evento_tex = _load_texture_file("res://assets/sprites/baus/bau_comum.png")
	return _bau_evento_tex
