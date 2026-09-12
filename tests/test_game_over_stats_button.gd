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
		_checar_rotulo(ui, stats_btn)

	ui.queue_free()
	_finalizar()


## O rotulo tem que CABER, e nao ser cortado.
##
## `draw_string` com largura corta o texto que nao cabe: nao encolhe, nao
## quebra linha e nao avisa. Um corpo de fonte tirado da largura do botao
## daria "ESTATÍSTIC" so' na tela estreita -- exatamente onde ninguem testa,
## porque o aparelho de quem desenvolve costuma ser o grande.
##
## O botao tem duas medidas de verdade no jogo (compacta e larga), e o teste
## desce bem abaixo das duas: se um dia alguem apertar o layout, isto reprova
## antes de chegar no aparelho de alguem.
func _checar_rotulo(ui: Node, stats_btn: Button) -> void:
	var fonte: Font = ThemeDB.fallback_font
	if fonte == null:
		return
	var alvo: Variant = ui
	var rotulo: String = UI_SCRIPT.ROTULO_STATS
	var minimo: int = UI_SCRIPT.CORPO_STATS_MIN
	for largura in [124.0, 158.0, stats_btn.size.x, 96.0, 64.0]:
		var preferido: int = int(clamp(largura * 0.125, 10.0, 18.0))
		var corpo: int = alvo.corpo_que_cabe(fonte, rotulo, largura - 6.0, preferido)
		var medido: float = fonte.get_string_size(rotulo, HORIZONTAL_ALIGNMENT_LEFT, -1.0, corpo).x
		_esperar(corpo >= minimo,
			"Corpo de fonte do rotulo nao pode cair abaixo do minimo legivel (largura %.0f)." % largura)
		## O piso de legibilidade vence o "cabe": abaixo dele o texto vira
		## sujeira, e e' melhor transbordar do que fingir que da' para ler.
		if corpo > minimo:
			_esperar(medido <= largura - 6.0,
				"Rotulo ESTATISTICAS seria CORTADO com largura %.0f (mede %.0f em corpo %d)."
					% [largura, medido, corpo])
		_esperar(corpo <= preferido,
			"O ajuste so' pode DIMINUIR a fonte, nunca aumentar (largura %.0f)." % largura)

	## E o botao nao pode voltar a depender do spritesheet, que traz a moldura
	## quadrada desenhada na propria arte.
	##
	## Comentario NAO e' codigo, e este teste precisa saber disso: o comentario
	## que explica a troca, la' no ui.gd, CITA o nome do arquivo de proposito.
	## Sem tirar os comentarios antes, este teste reprovaria por causa da prosa
	## que o justifica -- que ja' aconteceu vezes demais neste projeto.
	_esperar(not _codigo_do_ui().contains("stats_button_sheet"),
		"O botao voltou a depender do spritesheet, que traz a moldura quadrada desenhada.")


func _codigo_do_ui() -> String:
	var f := FileAccess.open("res://scripts/ui.gd", FileAccess.READ)
	if f == null:
		return ""
	var texto := f.get_as_text()
	f.close()
	var limpo := ""
	for linha in texto.split("\n"):
		var corte: int = linha.find("#")
		limpo += (linha if corte < 0 else linha.substr(0, corte)) + "\n"
	return limpo


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
