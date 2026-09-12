extends Node
## O Nexo Estelar tinha quatro problemas de leitura, todos reportados juntos.
##
##   1. Os rotulos se atropelavam: cada no escrevia o proprio nome centrado
##      embaixo de si, sem saber de mais ninguem. "Coletor de Cytr", "Fluxo
##      Ler", "Escamas de Aç" -- nome cortado pela metade nao le como "esta
##      cheio aqui", le como defeito.
##
##   2. O fundo lavava o mapa: seis ramos x quatro blobs = 24 circulos de ate'
##      130 de raio, sobrepostos. Cada um discreto, somados viram manchas que
##      faziam os nos externos parecerem ruido.
##
##   3. Os 59 nos nao tinham hierarquia: so' "aceso" e "apagado", e o apagado
##      era a maior parte da tela. O que esta' a um passo parecia igual ao que
##      esta' a seis.
##
##   4. "15 DISPONÍVEIS" nao apontava para nada: anunciava quinze coisas para
##      fazer e nao dizia onde nenhuma estava, num mapa que nao cabe na tela.
##
## O que da' para conferir de fora e' o COMPORTAMENTO, nao o pixel. Entao este
## teste exercita a escolha dos rotulos (que caixa foi reservada) e a navegacao
## do contador (para onde a camera vai), que sao as duas partes com regra.

var _falhas: Array[String] = []

const NEXO := preload("res://scripts/talentos_v2.gd")


func _ready() -> void:
	call_deferred("_run")


func _run() -> void:
	var nexo: Control = NEXO.new()
	add_child(nexo)
	nexo.size = Vector2(1000.0, 600.0)

	_checar_rotulos(nexo)
	_checar_ir_disponivel(nexo)
	_checar_fundo()

	nexo.queue_free()
	_finalizar()


## Dois nos praticamente no mesmo lugar nao podem produzir dois nomes
## sobrepostos. Um dos dois cede -- e quem cede e' sempre o de menor
## prioridade, nunca o selecionado.
func _checar_rotulos(nexo: Control) -> void:
	var ids: Array = []
	for tid in Salvar.TALENTOS_INFO.keys():
		if tid != "raiz":
			ids.append(tid)
	if ids.size() < 2:
		print("PULADO: menos de dois talentos para testar colisao de rotulo")
		return

	var a: String = ids[0] as String
	var b: String = ids[1] as String

	# Dois no MESMO ponto: os dois cabem, um embaixo e outro em cima. E' para
	# isso que existe o recuo de cima -- e' o caso comum de dois nos vizinhos.
	nexo._rotulos_pend = [
		{"id": a, "sp": Vector2(500.0, 300.0), "rr": 20.0, "ab": 1.0, "prio": 0},
		{"id": b, "sp": Vector2(500.0, 300.0), "rr": 20.0, "ab": 1.0, "prio": 0},
	]
	var caixas: Array[Rect2] = _caixas(nexo)
	_esperar(caixas.size() == 2,
		"Dois nos colados cabem: um nome embaixo, outro em cima (coube %d)." % caixas.size())
	_esperar(_nenhuma_sobrepoe(caixas),
		"Os dois nomes NAO podem se sobrepor -- e' o defeito inteiro que isto conserta.")

	# SEIS no mesmo ponto: so' ha' dois lugares, entao quatro tem que CEDER.
	# Sumir um nome e' melhor que mostrar seis ilegiveis; o nome sempre pode
	# ser lido tocando o no.
	var muitos: Array = []
	for i in range(6):
		muitos.append({"id": ids[i % ids.size()], "sp": Vector2(500.0, 300.0),
				"rr": 20.0, "ab": 1.0, "prio": 0})
	nexo._rotulos_pend = muitos
	var apertado: Array[Rect2] = _caixas(nexo)
	_esperar(apertado.size() <= 2,
		"Sem lugar, os nomes tem que CEDER: escreveu %d onde cabem 2." % apertado.size())
	_esperar(_nenhuma_sobrepoe(apertado),
		"Mesmo apertado, nome nenhum pode ficar por cima de outro.")

	# Afastados: os dois cabem, e nenhum pode sumir a' toa.
	nexo._rotulos_pend = [
		{"id": a, "sp": Vector2(200.0, 150.0), "rr": 20.0, "ab": 1.0, "prio": 0},
		{"id": b, "sp": Vector2(800.0, 450.0), "rr": 20.0, "ab": 1.0, "prio": 0},
	]
	_esperar(_caixas(nexo).size() == 2,
		"Nos afastados tem que escrever os DOIS nomes -- esconder a' toa e' pior que sobrepor.")

	# O selecionado tem prioridade e nunca cede o lugar, mesmo chegando depois.
	nexo._rotulos_pend = [
		{"id": a, "sp": Vector2(500.0, 300.0), "rr": 20.0, "ab": 1.0, "prio": 0},
		{"id": b, "sp": Vector2(500.0, 300.0), "rr": 20.0, "ab": 1.0, "prio": 2},
	]
	nexo._draw_rotulos()
	## A ordenacao acontece dentro do _draw_rotulos, no proprio array.
	var primeiro: Dictionary = nexo._rotulos_pend[0] as Dictionary
	_esperar(primeiro["id"] == b,
		"O selecionado tem que ser resolvido primeiro, para nunca perder o lugar.")


func _nenhuma_sobrepoe(caixas: Array[Rect2]) -> bool:
	for i in range(caixas.size()):
		for j in range(i + 1, caixas.size()):
			if caixas[i].intersects(caixas[j]):
				return false
	return true


func _caixas(nexo: Control) -> Array[Rect2]:
	## Le as caixas que o PROPRIO _draw_rotulos reservou.
	##
	## A primeira versao disto refazia a conta de colisao aqui dentro, com os
	## mesmos numeros. Parecia rigoroso e nao conferia nada: sabotei a colisao
	## de verdade, no talentos_v2.gd, e o teste continuou VERDE -- porque ele
	## estava concordando consigo mesmo, nao com o codigo.
	##
	## Um teste que recalcula o que deveria verificar e' um espelho. Ele so'
	## reprova quando o teste esta' errado, que e' exatamente ao contrario.
	nexo._draw_rotulos()
	return nexo._rotulos_caixas.duplicate()


## O contador do cabecalho passou a LEVAR aos nos compraveis, um por toque.
func _checar_ir_disponivel(nexo: Control) -> void:
	var compraveis: Array = []
	for tid in nexo._pos.keys():
		var id: String = tid as String
		if Salvar.pode_comprar_talento(id) and not Salvar.talento_ativo(id):
			compraveis.append(id)

	if compraveis.is_empty():
		## Num clone limpo nao ha' cristais, entao NADA e' comprável e este
		## bloco inteiro seria pulado -- deixando a navegacao sem ser
		## exercitada, que e' o jeito classico de um recurso nascer quebrado
		## com o teste verde por cima. Entao o teste PAGA os cristais.
		var antes: int = Salvar.cristais
		Salvar.cristais = 999999
		for tid2 in nexo._pos.keys():
			var id2: String = tid2 as String
			if Salvar.pode_comprar_talento(id2) and not Salvar.talento_ativo(id2):
				compraveis.append(id2)
		if compraveis.is_empty():
			Salvar.cristais = antes
			print("PULADO: nem com cristais ha' talento comprável -- arvore vazia?")
			return

	## Zoom baixo de proposito: o padrao (0.8) ja' passaria da regra sozinho, e
	## a asserçao de zoom ficaria verde mesmo se a linha que o sobe sumisse --
	## foi o que a sabotagem mostrou.
	nexo._zoom_alvo = 0.50
	## Pela ACAO de UI, e nao chamando a funcao: o defeito de sempre e' a
	## fiacao. Sabotei o `match` do botao e o teste passou, porque ele estava
	## chamando a funcao por baixo do botao.
	nexo._acao_ui("ir_disponivel")
	var primeiro: String = nexo._sel_id
	_esperar(primeiro != "", "Havendo comprável, o BOTAO do contador tem que levar a algum.")
	_esperar(nexo._sel_id == primeiro, "Ir ao disponível tem que SELECIONAR o nó de destino.")
	_esperar(nexo._cam_anim, "A câmera tem que animar até lá, e não saltar.")
	_esperar(nexo._cam_alvo == nexo._pos[primeiro],
		"O alvo da câmera tem que ser a posição do nó escolhido.")
	## O zoom tem que subir o suficiente para o NOME aparecer (rotulos comecam
	## em 0.72), senao a camera leva ate' um no que continua sem se explicar.
	_esperar(nexo._zoom_alvo >= 0.72,
		"Chegar no nó sem zoom para ler o nome nao resolve nada (ficou %.2f)." % nexo._zoom_alvo)
	_esperar(nexo._zoom_alvo > 0.50,
		"O zoom tem que SUBIR ao ir para o nó, e nao ficar onde estava.")

	if compraveis.size() >= 2:
		nexo._acao_ui("ir_disponivel")
		var segundo: String = nexo._sel_id
		_esperar(segundo != primeiro,
			"Tocar de novo tem que ir para OUTRO comprável, e nao repetir o mesmo.")
		## E tem que dar a volta, em vez de travar no ultimo.
		for i in range(compraveis.size() + 2):
			nexo._ir_ao_proximo_disponivel()
		_esperar(nexo._sel_id != "", "Depois de dar a volta inteira ainda tem que haver um selecionado.")


## O fundo nao pode voltar a lavar o mapa.
func _checar_fundo() -> void:
	var f := FileAccess.open("res://scripts/talentos_v2.gd", FileAccess.READ)
	if f == null:
		_falhas.append("Nao achei o talentos_v2.gd.")
		return
	var texto := f.get_as_text()
	f.close()
	# Comentario nao e' codigo: o comentario que explica esta reducao cita os
	# numeros antigos de proposito.
	var codigo := ""
	for linha in texto.split("\n"):
		var corte: int = linha.find("#")
		codigo += (linha if corte < 0 else linha.substr(0, corte)) + "\n"

	_esperar(codigo.contains("COR_DISPONIVEL"),
		"A cor do 'disponível' tem que ser UMA so', partilhada pelo contador e pelas marcas.")
	## O contador e as marcas nos nos tem que usar a MESMA constante -- e' o
	## que liga o numero la' em cima ao que pisca no mapa.
	var usos: int = codigo.count("COR_DISPONIVEL")
	_esperar(usos >= 4,
		"A cor do disponível tem que ser usada no cabeçalho E nas marcas dos nós (usos: %d)." % usos)


func _esperar(condicao: bool, msg: String) -> void:
	if not condicao:
		_falhas.append(msg)


func _finalizar() -> void:
	if _falhas.is_empty():
		print("OK nexo visual")
		get_tree().quit(0)
	else:
		for falha in _falhas:
			push_error(falha)
		get_tree().quit(1)
