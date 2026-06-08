extends Node

var _falhas: Array[String] = []


func _ready() -> void:
	call_deferred("_run")


func _run() -> void:
	_testar_mapas_usam_ceu_mundo_aberto()
	_testar_textura_nao_corta_estrelas()
	_finalizar()


func _testar_mapas_usam_ceu_mundo_aberto() -> void:
	for idx in range(1, Salvar.MAPAS_TORRE.size()):
		var mapa: Dictionary = Salvar.MAPAS_TORRE[idx] as Dictionary
		var bg := str(mapa.get("bg", ""))
		_esperar(
			bg.begins_with("res://assets/mapas/open_world_sky/"),
			"Mapa %s deve usar fundo de ceu aberto em assets/mapas/open_world_sky." % str(mapa.get("nome", idx + 1))
		)
		_esperar(ResourceLoader.exists(bg) or FileAccess.file_exists(bg), "Fundo do mapa deve existir: %s" % bg)


func _testar_textura_nao_corta_estrelas() -> void:
	var src := _ler_arquivo("res://scripts/background.gd")
	var tex_pos := src.find("if tex != null:")
	var stars_pos := src.find("_draw_estrelas(id, cor)")
	_esperar(tex_pos >= 0, "background.gd deve ter ramo de textura.")
	_esperar(stars_pos > tex_pos, "Estrelas devem ser desenhadas depois do fundo com textura.")
	if tex_pos >= 0 and stars_pos > tex_pos:
		var trecho := src.substr(tex_pos, stars_pos - tex_pos)
		_esperar(not trecho.contains("\n\t\treturn"), "Fundo com textura nao pode retornar antes de desenhar estrelas.")


func _ler_arquivo(path: String) -> String:
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		return ""
	var txt := f.get_as_text()
	f.close()
	return txt


func _esperar(condicao: bool, msg: String) -> void:
	if not condicao:
		_falhas.append(msg)


func _finalizar() -> void:
	if _falhas.is_empty():
		print("OK open world sky background")
		get_tree().quit(0)
	else:
		for falha in _falhas:
			push_error(falha)
		get_tree().quit(1)
