extends Node
## Smoke test: talentos_v2.gd compila, monta layout e fecha sem erro.
## Rodar: godot --headless --path . res://tests/test_talentos_v2_parse.tscn

func _ready() -> void:
	var v2_script = load("res://scripts/talentos_v2.gd")
	if v2_script == null:
		push_error("FALHA: talentos_v2.gd nao compilou")
		get_tree().quit(1)
		return
	var inst: Control = v2_script.new()
	inst.size = Vector2(1280, 720)
	add_child(inst)
	await get_tree().process_frame
	await get_tree().process_frame
	var total_nos: int = (inst.get("_pos") as Dictionary).size()
	var esperado: int = Salvar.TALENTOS_INFO.size()
	print("TESTE talentos_v2: nos posicionados=%d / talentos=%d" % [total_nos, esperado])
	if total_nos != esperado:
		push_error("FALHA: layout incompleto (%d != %d)" % [total_nos, esperado])
		get_tree().quit(1)
		return
	inst.queue_free()
	await get_tree().process_frame
	var menu_script = load("res://scripts/menu.gd")
	if menu_script == null:
		push_error("FALHA: menu.gd nao compilou (hook do Nexo)")
		get_tree().quit(1)
		return
	print("TESTE talentos_v2: OK")
	get_tree().quit(0)
