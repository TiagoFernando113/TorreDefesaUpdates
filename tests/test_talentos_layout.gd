extends Node

var _falhas: Array[String] = []

const MENU_SCRIPT := preload("res://scripts/menu.gd")
const BRANCHES := {
	"p": ["p1", "p2", "p3", "p4", "p5"],
	"b": ["b1", "b2", "b3", "b4"],
	"r": ["r1", "r2", "r3", "r4", "token", "r5"],
	"t": ["t1", "t2", "t3", "t4"],
	"e": ["e1", "e2", "e3", "e4", "e5"],
	"g": ["g1", "g2", "g3", "g4"],
	"s": ["s1", "s2", "s3", "s4", "s5"],
	"m": ["m1", "m2", "m3", "m4"],
	"f": ["f1", "f2", "f3", "f4", "f5"],
	"x": ["x1", "x2", "x3", "x4"],
}


func _ready() -> void:
	call_deferred("_run")


func _run() -> void:
	var menu = MENU_SCRIPT.new()
	add_child(menu)
	await get_tree().process_frame

	menu._tab_talentos = "ramos"
	var root: Vector2 = menu.call("_tech_tree_pos", "raiz") as Vector2
	var vp: Vector2 = get_viewport().get_visible_rect().size
	var detail_rect: Rect2 = menu.call("_talent_text_rect_screen") as Rect2
	var map_rect: Rect2 = menu.call("_talent_map_rect") as Rect2
	var visible_ids: Array[String] = ["raiz"]

	_esperar(map_rect.position.x >= detail_rect.end.x + 16.0, "Mapa de talentos deve comecar depois do painel lateral.")
	_esperar(map_rect.position.y >= 126.0, "Mapa de talentos deve respeitar cabecalho e abas.")
	_esperar(map_rect.end.y <= vp.y - 70.0, "Mapa de talentos deve deixar rodape livre para o botao Voltar.")
	_esperar(root.x >= map_rect.position.x + 42.0 and root.x <= map_rect.end.x - 42.0, "Nucleo deve ficar dentro da area util do mapa.")
	_esperar(not detail_rect.has_point(root), "Painel de detalhe nao pode cobrir o nucleo.")

	for branch_key in BRANCHES.keys():
		var ids: Array = BRANCHES[branch_key] as Array
		var prev_x: float = root.x
		for id_any in ids:
			var id: String = id_any as String
			var pos: Vector2 = menu.call("_tech_tree_pos", id) as Vector2
			_esperar(map_rect.grow(8.0).has_point(pos), "Emblema %s deve ficar dentro da area util do mapa." % id)
			_esperar(pos.x > prev_x + 18.0, "Ramo %s deve avancar em trilha legivel para a direita em %s." % [branch_key, id])
			prev_x = pos.x

	for group_any in menu._TECH_CONSTELLATIONS:
		var group: Dictionary = group_any as Dictionary
		for id_any in (group.get("points", []) as Array):
			var id: String = id_any as String
			_esperar(not menu._TECH_FUSION_IDS.has(id), "A aba Tecnologias nao deve misturar fusoes no miolo da arvore: %s." % id)
			if not visible_ids.has(id):
				visible_ids.append(id)

	for i in range(visible_ids.size()):
		for j in range(i + 1, visible_ids.size()):
			var a_id: String = visible_ids[i]
			var b_id: String = visible_ids[j]
			var a: Vector2 = menu.call("_tech_tree_pos", a_id) as Vector2
			var b: Vector2 = menu.call("_tech_tree_pos", b_id) as Vector2
			_esperar(a.distance_to(b) >= 46.0, "Emblemas da arvore principal nao podem ficar sobrepostos: %s perto de %s." % [a_id, b_id])

	var recipes: Array = menu.call("_fusion_recipes") as Array
	_esperar(recipes.size() >= 6, "Mapa de tecnologia precisa exibir portoes de fusao suficientes.")
	for rec_any in recipes:
		var rec: Dictionary = rec_any as Dictionary
		var fusion_id: String = rec.get("id", "") as String
		var reqs: Array = rec.get("reqs", []) as Array
		_esperar(menu._TECH_FUSION_IDS.has(fusion_id), "Receita de fusao deve apontar para um talento de fusao conhecido: %s." % fusion_id)
		_esperar(reqs.size() >= 2, "Fusao %s precisa mostrar pelo menos dois emblemas convergindo." % fusion_id)
		var gate_pos: Vector2 = menu.call("_tech_tree_pos", fusion_id) as Vector2
		_esperar(map_rect.grow(8.0).has_point(gate_pos), "Portao de fusao %s deve ficar dentro da area util do mapa." % fusion_id)
		_esperar(not detail_rect.has_point(gate_pos), "Portao de fusao nao pode ficar escondido pelo painel lateral: %s." % fusion_id)
		_esperar(root.distance_to(gate_pos) >= 70.0, "Portao de fusao deve ficar em anel proprio, nao colado no nucleo: %s." % fusion_id)
		for visible_id in visible_ids:
			var normal_pos: Vector2 = menu.call("_tech_tree_pos", visible_id) as Vector2
			_esperar(gate_pos.distance_to(normal_pos) >= 48.0, "Portao de fusao nao deve encostar em emblema normal: %s perto de %s." % [fusion_id, visible_id])
		for req_any in reqs:
			var req_id: String = req_any as String
			_esperar(Salvar.TALENTOS_INFO.has(req_id), "Fusao %s usa requisito inexistente: %s." % [fusion_id, req_id])

	var constellation_source := FileAccess.get_file_as_string("res://scripts/talent_constellation_fundo.gd")
	_esperar(not constellation_source.contains("\n\t_draw_fusion_beams()"), "A aba Tecnologias nao deve desenhar feixes longos de fusao por cima da arvore.")

	var ui := CanvasLayer.new()
	add_child(ui)
	menu.call("_abrir_talentos", ui)
	await get_tree().process_frame
	_esperar(menu._talentos_panel != null and is_instance_valid(menu._talentos_panel), "Tela de talentos deve montar o painel principal sem erro.")
	_esperar(menu._talent_constellation_layer != null and is_instance_valid(menu._talent_constellation_layer), "Tela de talentos deve montar a camada visual dos ramos.")
	menu._tab_talentos = "fusoes"
	menu.call("_rebuild_talentos")
	await get_tree().process_frame
	_esperar(menu._talentos_panel != null and is_instance_valid(menu._talentos_panel), "Aba Fusoes deve montar cartas de combinacao sem erro.")

	menu.queue_free()
	_finalizar()


func _esperar(condicao: bool, msg: String) -> void:
	if not condicao:
		_falhas.append(msg)


func _finalizar() -> void:
	if _falhas.is_empty():
		print("OK talentos layout")
		get_tree().quit(0)
	else:
		for falha in _falhas:
			push_error(falha)
		get_tree().quit(1)
