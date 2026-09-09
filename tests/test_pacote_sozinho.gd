extends Node
## Guarda o canal que faz o app se atualizar sozinho.
##
## O jogo instalado busca content_manifest_dev.json a cada abertura, baixa o
## pacote novo e o aplica na abertura seguinte. Isso substitui baixar e instalar
## um APK de 208 MB por cima, toda vez que uma linha de codigo muda.
##
## O canal so' pode rodar sozinho porque existe uma trava: o pacote declara de
## quais autoloads ele precisa, e quem nao os tem NAO baixa. Sem ela, o dia em
## que alguem acrescentasse um autoload, todo aparelho com APK antigo baixaria
## um pacote que nao compila -- e o jogo pararia de abrir, sem conserto pelo
## proprio canal, porque o canal e' o que parou de rodar. Ja' aconteceu uma vez,
## com o `Auth`, quando publicar pacote ainda era ato manual.
##
## Este teste existe para essa trava nao ser removida sem querer.

const MANIFESTO := "res://content_manifest_dev.json"

var _falhas: Array[String] = []


func _ready() -> void:
	var atualizador: Node = preload("res://scripts/atualizador.gd").new()
	_a_trava_responde(atualizador)
	_manifesto_velho_continua_valendo(atualizador)
	_pacote_que_pede_autoload_ausente_e_recusado(atualizador)
	_o_manifesto_publicado_declara_os_autoloads()
	_quem_aplica_pacote_e_so_o_carregador()
	_a_esteira_existe()
	_finalizar()


## Meia atualizacao e' pior que nenhuma.
##
## Se o Atualizador aplicar o pacote na mesma abertura em que baixou, os
## autoloads continuam sendo os do APK (ja' subiram) e so' as telas passam a vir
## do pacote. O jogo roda metade novo, metade velho -- e uma tela nova chamando
## um metodo que so' existe no autoload novo da' erro em tempo de execucao, com
## o agravante de que o descarte automatico do Carregador nao dispara: ele so'
## age quando a abertura nao chega ao primeiro quadro, e essa chegou.
##
## Enquanto pacote era raro e manual, a janela quase nunca abria. Publicando um
## a cada mudanca, ela abriria toda vez.
func _quem_aplica_pacote_e_so_o_carregador() -> void:
	var f := FileAccess.open("res://scripts/atualizador.gd", FileAccess.READ)
	if f == null:
		_falhas.append("nao consegui ler o atualizador.gd")
		return
	var fonte := f.get_as_text()
	f.close()

	# Sem os comentarios: o texto acima EXPLICA por que nao se aplica aqui, e
	# cita o nome da funcao de proposito.
	var codigo := ""
	for linha in fonte.split("\n"):
		if linha.strip_edges().begins_with("#"):
			continue
		codigo += linha + "\n"

	_esperar(not codigo.contains("load_resource_pack"),
		"o atualizador voltou a aplicar pacote — isso mistura versao nova com "
		+ "autoload velho na mesma abertura; quem aplica e' o Carregador")

	var g := FileAccess.open("res://scripts/carregador.gd", FileAccess.READ)
	if g == null:
		_falhas.append("nao consegui ler o carregador.gd")
		return
	var fonte_c := g.get_as_text()
	g.close()
	_esperar(fonte_c.contains("load_resource_pack"),
		"o Carregador parou de aplicar pacote — ninguem mais aplica, e o app "
		+ "ficaria preso na versao do APK para sempre")


## Os autoloads citados aqui sao os que o proprio projeto tem. Se algum for
## renomeado sem cuidado, este teste avisa antes de o pacote sair.
func _a_trava_responde(atualizador: Node) -> void:
	_esperar(_chamar(atualizador, "_tem_todos_autoloads", [[]]) == true,
		"lista vazia nao exige nada e tem que passar")
	_esperar(_chamar(atualizador, "_tem_todos_autoloads",
			[["Carregador", "BuildConfig", "Modulos", "DevPainel"]]) == true,
		"autoloads que existem neste projeto foram dados como ausentes")
	_esperar(_chamar(atualizador, "_tem_todos_autoloads",
			[["Carregador", "AutoloadQueNuncaExistiu"]]) == false,
		"autoload inexistente tinha que reprovar o pacote")


## O campo nasceu depois de haver APK instalado por ai'. Um manifesto sem ele
## nao pode virar pacote recusado, senao os aparelhos que ja' existem ficariam
## sem receber nada -- exatamente o problema que o canal veio resolver.
func _manifesto_velho_continua_valendo(atualizador: Node) -> void:
	var antigo := {
		"id": "mapas",
		"version": 9,
		"url": "https://example.com/mapas_v9.pck",
		"sha256": "0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef",
		"kind": "assets",
	}
	_esperar(_chamar(atualizador, "_should_download_content_pack", [antigo, {}]) == true,
		"manifesto sem requer_autoloads tem que continuar sendo aceito")


func _pacote_que_pede_autoload_ausente_e_recusado(atualizador: Node) -> void:
	var impossivel := {
		"id": "mapas",
		"version": 9,
		"url": "https://example.com/mapas_v9.pck",
		"sha256": "0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef",
		"kind": "assets",
		"requer_autoloads": ["Carregador", "AutoloadDoFuturo"],
	}
	_esperar(_chamar(atualizador, "_should_download_content_pack", [impossivel, {}]) == false,
		"pacote que pede autoload ausente tem que ser recusado ANTES de baixar")


## A trava so' vale se o manifesto realmente trouxer o campo. Um manifesto
## escrito na mao, sem ele, passa direto -- e volta o risco de brick.
func _o_manifesto_publicado_declara_os_autoloads() -> void:
	var f := FileAccess.open(MANIFESTO, FileAccess.READ)
	if f == null:
		_falhas.append("nao consegui ler o %s" % MANIFESTO)
		return
	var txt := f.get_as_text()
	f.close()

	var dados: Variant = JSON.parse_string(txt)
	if not dados is Dictionary:
		_falhas.append("%s nao e' um JSON de objeto" % MANIFESTO)
		return

	var pacotes: Variant = (dados as Dictionary).get("packs", [])
	if not pacotes is Array:
		_falhas.append("o campo packs do manifesto nao e' uma lista")
		return

	for item in (pacotes as Array):
		if not item is Dictionary:
			_falhas.append("entrada do manifesto que nao e' objeto")
			continue
		var d := item as Dictionary
		var nome := str(d.get("id", "?"))
		var exige: Variant = d.get("requer_autoloads", null)
		if not exige is Array or (exige as Array).is_empty():
			_falhas.append("o pacote '%s' foi publicado sem requer_autoloads" % nome)
			continue
		_esperar((exige as Array).has("Carregador"),
			"o pacote '%s' nao exige o Carregador, que e' quem aplica pacote" % nome)


## A esteira e' a parte que faz isto acontecer sozinho. Sem ela, sobra de novo
## alguem lembrando de montar pacote na mao -- que e' onde tudo parou antes.
func _a_esteira_existe() -> void:
	for caminho in [
		"res://tools/exportar_pacote_dev.sh",
		"res://.github/workflows/pacote-dev.yml",
	]:
		_esperar(FileAccess.file_exists(caminho),
			"sumiu o %s -- sem ele o pacote volta a ser trabalho manual" % caminho)


func _chamar(obj: Object, metodo: String, args: Array) -> Variant:
	if not obj.has_method(metodo):
		_falhas.append("metodo ausente no atualizador: %s" % metodo)
		return null
	return obj.callv(metodo, args)


func _esperar(condicao: bool, msg: String) -> void:
	if not condicao:
		_falhas.append(msg)


func _finalizar() -> void:
	if _falhas.is_empty():
		print("OK pacote-sozinho")
		get_tree().quit(0)
	else:
		for falha in _falhas:
			push_error(falha)
		get_tree().quit(1)
