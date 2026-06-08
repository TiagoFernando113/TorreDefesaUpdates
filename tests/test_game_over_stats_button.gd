extends Node

var _falhas: Array[String] = []

const UI_SCRIPT := preload("res://scripts/ui.gd")


func _ready() -> void:
	call_deferred("_run")


func _run() -> void:
	var ui: CanvasLayer = UI_SCRIPT.new()
	add_child(ui)
	ui.mostrar_game_over(1200, 12, 450, 0, Callable(), false, Callable(), func() -> void:
		pass
	)

	var stats_btn: Button = _find_stats_button(ui)
	_esperar(stats_btn != null, "Botao de estatisticas da derrota deve existir.")
	if stats_btn != null:
		var sprite: Control = _find_stats_sprite(stats_btn)
		_esperar(sprite != null, "Botao de estatisticas deve usar imagem/sprite visual.")
		var start_pos: Vector2 = stats_btn.position
		var start_scale: Vector2 = stats_btn.scale
		stats_btn.mouse_entered.emit()
		stats_btn.button_down.emit()
		stats_btn.button_up.emit()
		stats_btn.mouse_exited.emit()
		_esperar(stats_btn.position == start_pos, "Botao de estatisticas nao pode se mover no hover/clique.")
		_esperar(stats_btn.scale == start_scale, "Botao de estatisticas nao pode escalar no hover/clique.")
		if sprite != null:
			_esperar(int(sprite.get_meta("frame", 0)) == 0, "Botao de estatisticas deve ficar em imagem fixa, sem animar frames.")

	ui.queue_free()
	_finalizar()


func _find_stats_button(node: Node) -> Button:
	if node is Button:
		var btn := node as Button
		if _find_stats_sprite(btn) != null:
			return btn
	for child in node.get_children():
		var found: Button = _find_stats_button(child)
		if found != null:
			return found
	return null


func _find_stats_sprite(node: Node) -> Control:
	for child in node.get_children():
		if child is Control and (child as Control).has_meta("frame"):
			return child as Control
		var nested: Control = _find_stats_sprite(child)
		if nested != null:
			return nested
	return null


func _esperar(condicao: bool, msg: String) -> void:
	if not condicao:
		_falhas.append(msg)


func _finalizar() -> void:
	if _falhas.is_empty():
		print("OK game over stats button")
		get_tree().quit(0)
	else:
		for falha in _falhas:
			push_error(falha)
		get_tree().quit(1)
