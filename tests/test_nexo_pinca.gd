extends Node
## A pinça de dois dedos no Nexo Estelar.
##
## O Nexo só ouvia roda de mouse e movimento de mouse. No celular, arrastar
## funcionava por acidente -- o Godot emula mouse a partir do PRIMEIRO dedo --
## e a pinça não fazia absolutamente nada, porque o segundo dedo não vira
## mouse nenhum. Num mapa de 59 nós que não cabe na tela, o zoom é justamente
## onde a pessoa mais precisa, e os botões - e + no topo eram a única saída.
##
## Este teste manda EVENTOS DE DEDO de verdade (InputEventScreenTouch e
## InputEventScreenDrag) pelo _gui_input, em vez de chamar a função da pinça
## direto. Chamar a função direto provaria que a matemática fecha e não
## provaria nada sobre o defeito, que era de FIAÇÃO: ninguém escutava o toque.

var _falhas: Array[String] = []

const NEXO := preload("res://scripts/talentos_v2.gd")


func _ready() -> void:
	call_deferred("_run")


func _dedo(indice: int, pos: Vector2, pressionado: bool) -> InputEventScreenTouch:
	var e := InputEventScreenTouch.new()
	e.index = indice
	e.position = pos
	e.pressed = pressionado
	return e


func _arrasta(indice: int, pos: Vector2) -> InputEventScreenDrag:
	var e := InputEventScreenDrag.new()
	e.index = indice
	e.position = pos
	return e


func _run() -> void:
	var nexo: Control = NEXO.new()
	add_child(nexo)
	nexo.size = Vector2(1000.0, 600.0)

	var zoom0: float = nexo._zoom

	# ── Afastar os dedos tem que APROXIMAR ────────────────────────────────
	nexo._gui_input(_dedo(0, Vector2(400.0, 300.0), true))
	nexo._gui_input(_dedo(1, Vector2(500.0, 300.0), true))
	_esperar(nexo._pinca, "Dois dedos na tela têm que iniciar a pinça.")

	nexo._gui_input(_arrasta(0, Vector2(350.0, 300.0)))
	nexo._gui_input(_arrasta(1, Vector2(550.0, 300.0)))
	_esperar(nexo._zoom > zoom0,
		"Afastar os dedos tem que aumentar o zoom (era %.3f, ficou %.3f)." % [zoom0, nexo._zoom])

	# O alvo acompanha o zoom: senão a suavização do _process desfaz a pinça no
	# quadro seguinte e o zoom "volta sozinho" com o dedo ainda na tela.
	_esperar(is_equal_approx(nexo._zoom_alvo, nexo._zoom),
		"O zoom-alvo tem que acompanhar a pinça, senão ela é desfeita no quadro seguinte.")

	# ── Juntar os dedos tem que AFASTAR ──────────────────────────────────
	var zoom1: float = nexo._zoom
	nexo._gui_input(_arrasta(0, Vector2(440.0, 300.0)))
	nexo._gui_input(_arrasta(1, Vector2(460.0, 300.0)))
	_esperar(nexo._zoom < zoom1,
		"Juntar os dedos tem que diminuir o zoom (era %.3f, ficou %.3f)." % [zoom1, nexo._zoom])

	# ── Os limites valem ─────────────────────────────────────────────────
	for i in 30:
		nexo._gui_input(_arrasta(0, Vector2(100.0, 300.0)))
		nexo._gui_input(_arrasta(1, Vector2(900.0, 300.0)))
	_esperar(nexo._zoom <= NEXO.ZOOM_MAX + 0.001,
		"A pinça não pode passar do ZOOM_MAX (chegou a %.3f)." % nexo._zoom)
	for i in 30:
		nexo._gui_input(_arrasta(0, Vector2(499.0, 300.0)))
		nexo._gui_input(_arrasta(1, Vector2(501.0, 300.0)))
	_esperar(nexo._zoom >= NEXO.ZOOM_MIN - 0.001,
		"A pinça não pode passar do ZOOM_MIN (chegou a %.3f)." % nexo._zoom)

	# ── Soltar um dedo encerra a pinça ───────────────────────────────────
	nexo._gui_input(_dedo(1, Vector2(501.0, 300.0), false))
	_esperar(not nexo._pinca, "Soltar um dedo tem que encerrar a pinça.")

	# E o dedo que sai NÃO pode comprar talento. O clique emulado chega depois
	# do toque terminar; sem trava, terminar um zoom em cima de um nó compra
	# aquele talento -- e talento comprado não volta.
	_esperar(nexo._trava_clique > 0.0,
		"Ao sair da pinça, o clique tem que ficar travado por um instante.")

	nexo._gui_input(_dedo(0, Vector2(499.0, 300.0), false))
	_esperar(nexo._dedos.is_empty(), "Sem dedos na tela, a lista tem que ficar vazia.")

	# ── O arrasto de um dedo morre quando o segundo encosta ──────────────
	# Sem isso, o mouse emulado do primeiro dedo segue arrastando o mapa no
	# meio do zoom e a câmera foge enquanto a pessoa só queria aproximar.
	nexo._mouse_down = true
	nexo._dragging = true
	nexo._drag_vel = Vector2(40.0, 0.0)
	nexo._gui_input(_dedo(0, Vector2(400.0, 300.0), true))
	nexo._gui_input(_dedo(1, Vector2(500.0, 300.0), true))
	_esperar(not nexo._dragging, "O arrasto de um dedo tem que morrer quando o segundo encosta.")
	_esperar(nexo._drag_vel == Vector2.ZERO,
		"A inércia do arrasto tem que zerar na pinça, senão o mapa desliza durante o zoom.")

	# ── Fiação: o evento de toque não pode vazar para o resto ────────────
	_esperar(nexo._tratar_dedos(_dedo(2, Vector2(10.0, 10.0), true)),
		"Evento de toque tem que ser tratado e consumido pelo tratador de dedos.")

	nexo.queue_free()
	_finalizar()


func _esperar(condicao: bool, msg: String) -> void:
	if not condicao:
		_falhas.append(msg)


func _finalizar() -> void:
	if _falhas.is_empty():
		print("OK nexo pinca")
		get_tree().quit(0)
	else:
		for falha in _falhas:
			push_error(falha)
		get_tree().quit(1)
