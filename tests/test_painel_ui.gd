extends Node
## Constrói o Painel de Comando contra um HUD DE VERDADE e confere que os oito
## botões aparecem, legíveis e dentro da tela.
##
## Existe porque o painel sumiu inteiro de um APK publicado e nenhum teste viu.
## O test_painel.gd passa ui_node = null — ele valida a lógica (energia, custo,
## cap) e nunca chega a criar um botão. Então uma chamada inválida na montagem
## da UI passava batido pela esteira e só aparecia no celular.
##
## O HUD do jogo é um CanvasLayer (scenes/Main.tscn). CanvasLayer estende Node,
## NÃO CanvasItem — logo não tem get_viewport_rect(). Chamar esse método aqui
## derrubava criar_ui() na primeira linha e o jogador ficava sem painel. É por
## isso que este teste usa CanvasLayer, e não Control: com Control ele passaria
## enquanto o jogo continuava quebrado.

var torre = null      # o módulo lê jogo.torre
var ui_node = null    # o módulo lê jogo.ui_node

func _falha(msg: String) -> void:
	push_error("FALHA: " + msg)
	get_tree().quit(1)

func _ready() -> void:
	var mod_scr = load("res://scripts/partida/painel_comando.gd")
	if mod_scr == null:
		_falha("painel_comando.gd nao compilou"); return
	var torre_scr = load("res://scripts/torre.gd")
	if torre_scr == null:
		_falha("torre.gd nao compilou"); return
	var t = torre_scr.new()
	add_child(t)
	torre = t

	# O MESMO tipo de nó que o jogo usa como HUD.
	var hud := CanvasLayer.new()
	add_child(hud)
	ui_node = hud

	var p = mod_scr.new(self)
	p.criar_ui()

	# 1) Os oito botões existem e são filhos do HUD.
	var trilhas : Array = p.TRILHAS
	if trilhas.is_empty():
		_falha("nenhuma trilha configurada"); return
	var botoes : Array = []
	for filho in hud.get_children():
		if filho is Button:
			botoes.append(filho)
	if botoes.size() != trilhas.size():
		_falha("o painel montou %d botoes para %d trilhas -- criar_ui() nao completou" % [botoes.size(), trilhas.size()])
		return

	# 2) Nenhum botão degenerado: com escala perto de zero eles viram um borrão
	#    de 4 px empilhado no canto, que é como o painel "sumiu" na tela.
	var tela : Vector2 = hud.get_viewport().get_visible_rect().size
	for b in botoes:
		var bt := b as Button
		if bt.size.x < 40.0 or bt.size.y < 16.0:
			_falha("botao de %.0fx%.0f -- pequeno demais para o dedo" % [bt.size.x, bt.size.y]); return
		if bt.position.x < 0.0 or bt.position.y < 0.0:
			_falha("botao fora da tela em %s" % str(bt.position)); return

	# 3) Eles estão EMPILHADOS, não amontoados no mesmo ponto.
	var ys : Array = []
	for b2 in botoes:
		ys.append((b2 as Button).position.y)
	ys.sort()
	for i in range(1, ys.size()):
		if absf(float(ys[i]) - float(ys[i - 1])) < 8.0:
			_falha("dois botoes praticamente no mesmo y -- a coluna colapsou"); return

	# 4) A última trilha cabe na tela. Perder a última é perder um upgrade
	#    inteiro sem o jogador saber que ele existe.
	var ultimo : float = float(ys[ys.size() - 1]) + (botoes[0] as Button).size.y
	if ultimo > tela.y:
		_falha("a ultima trilha termina em %.0f, abaixo da tela (%.0f)" % [ultimo, tela.y]); return

	# 5) Reconstruir não duplica: criar_ui() chama limpar_ui() antes.
	p.criar_ui()
	var botoes2 : int = 0
	for filho2 in hud.get_children():
		if filho2 is Button:
			botoes2 += 1
	# Os antigos saem por queue_free(), que só efetiva no fim do quadro.
	await get_tree().process_frame
	await get_tree().process_frame
	botoes2 = 0
	for filho3 in hud.get_children():
		if filho3 is Button:
			botoes2 += 1
	if botoes2 != trilhas.size():
		_falha("depois de recriar sobraram %d botoes (esperado %d)" % [botoes2, trilhas.size()]); return

	print("TESTE painel UI: OK (%d botoes montados num CanvasLayer, tela %.0fx%.0f)" % [trilhas.size(), tela.x, tela.y])
	get_tree().quit(0)
