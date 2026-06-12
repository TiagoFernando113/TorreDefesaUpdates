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
	# Hit test em grade: todo no deve ser clicavel em qualquer zoom/camera
	# (quando visivel na tela e fora da barra do header)
	var falhas: int = 0
	var testados: int = 0
	var posicoes: Dictionary = inst.get("_pos") as Dictionary
	for zoom_any in [0.42, 0.62, 0.85, 1.2, 1.65]:
		var z: float = zoom_any as float
		inst.set("_zoom", z)
		inst.set("_zoom_alvo", z)
		for tid in posicoes.keys():
			var alvo_pos: Vector2 = posicoes[tid] as Vector2
			for off_any in [Vector2.ZERO, Vector2(220, 130), Vector2(-300, 80), Vector2(90, -260)]:
				inst.set("_cam", alvo_pos + (off_any as Vector2))
				var sp: Vector2 = inst.call("_w2s", alvo_pos) as Vector2
				if sp.x < 30.0 or sp.y < 80.0 or sp.x > 1250.0 or sp.y > 690.0:
					continue  # fora da area util da tela — nao clicavel mesmo
				testados += 1
				var hit: String = inst.call("_hit_no", sp) as String
				if hit != str(tid):
					falhas += 1
					if falhas <= 5:
						push_error("HIT ERRADO: alvo=%s hit=%s zoom=%.2f off=%s" % [tid, hit, z, off_any])
	print("TESTE hit-grade: %d cliques simulados, %d falhas" % [testados, falhas])
	if falhas > 0:
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
