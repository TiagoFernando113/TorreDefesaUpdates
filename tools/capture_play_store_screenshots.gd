extends SceneTree

const OUT_DIR: String = "res://play_store/screenshots"
const VIEW_SIZE: Vector2i = Vector2i(1280, 720)

var _current_scene: Node = null


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT_DIR))
	root.size = VIEW_SIZE
	_prepare_demo_state()

	await _capture_menu("01_menu.png")
	await _capture_menu_overlay("02_inventario.png", "_abrir_inventario")
	await _capture_menu_overlay("03_talentos.png", "_abrir_talentos")
	await _capture_menu_overlay("04_mapas.png", "_abrir_mapas")
	await _capture_main("05_partida.png")
	_clear_current_scene()
	quit()


func _prepare_demo_state() -> void:
	Engine.time_scale = 1.0
	var s: Node = root.get_node("/root/Salvar")
	s.set("tutorial_menu_visto", true)
	s.set("tutorial_jogo_visto", true)
	s.set("nome_jogador", "CYRON")
	s.set("email_jogador", "")
	s.set("senha_jogador", "")
	s.set("player_id", "")
	s.set("ouro_banco", 13856256)
	s.set("cristais", 1208)
	s.set("dificuldade", 1)
	s.set("mapa_teste_id", "fronteira_cosmica")
	s.set("melhorias", {"forca": 3, "resistencia": 3, "visao": 3, "cadencia": 3, "fortuna": 3})
	s.set("high_score", 13117)
	s.set("melhor_wave", 14)
	s.set("total_partidas", 2)
	s.set("total_mobs_mortos", 414)
	s.set("total_bosses_mortos", 0)
	s.set("skins_desbloqueadas", ["padrao", "chama", "glacial", "abissal", "dourado", "saberpunk"])
	s.set("skin_ativa", "saberpunk")
	s.set("habil_cargas", {"eletrico": 3, "gelo": 3, "devastador": 3})
	s.set("orbe_cura_estoque", 5)
	s.set("cristal_barreira_estoque", 3)
	s.set("runa_furia_estoque", 3)
	s.set("revive_loja_estoque", 2)
	s.set("cons_equipados", ["cristal", "orbe", "runa"])
	s.set("baus_estoque", {"comum": 2, "raro": 1, "epico": 1, "lendario": 1})
	s.set("pets_desbloqueados", ["cyron", "nexus", "phantom"])
	s.set("pet_ativo", "cyron")
	s.set("pet_cartas", {"cyron": 42, "nexus": 12, "phantom": 8})
	s.set("pet_niveis", {"cyron": 5, "nexus": 1, "phantom": 3})
	s.set("pet_ia_comprado", true)
	s.set("arsenal_itens_desbloqueados", [
		"canhao_plasma", "disparador_ionico", "lente_orbital", "devastador_eclipse",
		"nucleo_vital", "reator_lunar", "bateria_cristal", "coracao_estelar",
		"placa_lunar", "casco_meteoro", "campo_defletor", "armadura_imperial",
		"fragmento_lunar", "orbe_abissal", "selo_dante", "reliquia_cyron",
	])
	s.set("arsenal_equipado", {
		"canhao": "devastador_eclipse",
		"nucleo": "coracao_estelar",
		"blindagem": "armadura_imperial",
		"reliquia": "reliquia_cyron",
	})
	s.set("talentos", {"raiz": true, "p1": true, "p2": true, "r1": true, "f1": true})
	s.set("acessibilidade_ativo", false)


func _capture_menu(filename: String) -> void:
	var menu := _load_scene("res://scenes/Menu.tscn")
	await _settle(24)
	await _save_png(filename)
	_clear_current_scene()
	await _settle(8)


func _capture_menu_overlay(filename: String, method_name: String) -> void:
	var menu := _load_scene("res://scenes/Menu.tscn")
	await _settle(24)
	var ui = menu.get("_ui_main")
	if ui != null and menu.has_method(method_name):
		menu.call(method_name, ui)
	await _settle(30)
	await _save_png(filename)
	_clear_current_scene()
	await _settle(8)


func _capture_main(filename: String) -> void:
	var main := _load_scene("res://scenes/Main.tscn")
	await _settle(90)
	await _save_png(filename)
	_clear_current_scene()
	await _settle(8)


func _load_scene(path: String) -> Node:
	_clear_current_scene()
	var packed := load(path) as PackedScene
	var node := packed.instantiate()
	root.add_child(node)
	_current_scene = node
	return node


func _clear_current_scene() -> void:
	if _current_scene != null and is_instance_valid(_current_scene):
		_current_scene.queue_free()
	_current_scene = null


func _settle(frames: int) -> void:
	for _i in range(frames):
		await process_frame


func _save_png(filename: String) -> void:
	await process_frame
	var img := root.get_texture().get_image()
	img.save_png("%s/%s" % [OUT_DIR, filename])
