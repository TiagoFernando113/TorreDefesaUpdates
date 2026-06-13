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
	# Compra de verdade via eventos de mouse (press+release), com backup do save
	var tal_bak: Dictionary = Salvar.talentos.duplicate(true)
	var cri_bak: int = Salvar.cristais
	var alvo_c: String = ""
	for tid in Salvar.TALENTOS_INFO.keys():
		if Salvar.pode_comprar_talento(tid as String):
			alvo_c = tid as String
			break
	var compra_ok: bool = true
	if alvo_c != "":
		inst.set("_zoom", 0.8)
		inst.set("_cam", Vector2.ZERO)
		var spc: Vector2 = inst.call("_w2s", posicoes[alvo_c] as Vector2) as Vector2
		var press := InputEventMouseButton.new()
		press.button_index = MOUSE_BUTTON_LEFT
		press.pressed = true
		press.position = spc
		inst.call("_gui_input", press)
		var rel := InputEventMouseButton.new()
		rel.button_index = MOUSE_BUTTON_LEFT
		rel.pressed = false
		rel.position = spc
		inst.call("_gui_input", rel)
		compra_ok = Salvar.talento_ativo(alvo_c)
	# Restaura o save do jogador SEMPRE
	Salvar.talentos = tal_bak
	Salvar.cristais = cri_bak
	Salvar.salvar()
	if alvo_c == "":
		print("TESTE compra-click: pulado (nada compravel no save)")
	elif compra_ok:
		print("TESTE compra-click: OK (%s comprado via press+release)" % alvo_c)
	else:
		push_error("FALHA: press+release em %s nao comprou" % alvo_c)
		get_tree().quit(1)
		return
	inst.queue_free()
	await get_tree().process_frame
	for sp in ["res://scripts/menu.gd", "res://scripts/menu/ranking.gd", "res://scripts/menu/loja.gd", "res://scripts/menu/inventario.gd", "res://scripts/menu/config_mapas.gd", "res://scripts/menu/contas.gd", "res://scripts/ranking_online.gd", "res://scripts/google_auth.gd",
			"res://scripts/main.gd", "res://scripts/ui.gd", "res://scripts/salvar.gd", "res://scripts/mob.gd",
			"res://scripts/torre.gd", "res://scripts/boss_dante.gd"]:
		var s = load(sp)
		if s == null or not (s as Script).can_instantiate():
			push_error("FALHA: %s nao compilou" % sp)
			get_tree().quit(1)
			return
	print("TESTE talentos_v2: OK")
	get_tree().quit(0)
