extends Node
## Deixa um pacote criar SISTEMAS NOVOS sem precisar de APK novo.
##
## O BLOQUEIO QUE ISTO RESOLVE
##
## Um pacote troca arquivo, mas nao cria autoload: a lista de autoloads mora no
## project.binary, que o motor le' no arranque, antes de qualquer pacote. Pior:
## todo script que MENCIONA um autoload inexistente nem chega a carregar. Foi
## assim que um pacote com o codigo de setembro quebrou a build de junho, com
##
##   Parse Error: Identifier "Auth" not declared in the current scope.
##
## Entao, ate' aqui, "sistema novo" era sinonimo de "APK novo".
##
## COMO ESCAPA DISSO
##
## Este autoload ja' vem no APK. Ele le' uma LISTA (res://modulos/lista.json) e
## instancia o que estiver nela como filho seu. A lista e' arquivo comum: um
## pacote a substitui, e junto manda os .gd novos. Ninguem precisou de autoload
## novo -- o Modulos ja' estava la'.
##
## Quem usa nao escreve `Loja.abrir()` (isso exigiria o autoload `Loja` existir
## no arranque). Escreve:
##
##   var loja := Modulos.pegar("loja")
##   if loja: loja.abrir()
##
## Chamada resolvida em tempo de execucao: nao trava o carregamento de quem
## chama, mesmo que o modulo nao esteja instalado.
##
## POR QUE `can_instantiate()` E NAO `load() != null`
##
## Conferido rodando, com tres modulos de proposito: um bom, um com erro de
## sintaxe e um citando um autoload que nao existe.
##
##   load() devolveu NAO-NULO para o quebrado -- essa checagem nao serve.
##   can_instantiate() devolveu false para os dois defeituosos e true para o bom.
##
## E mais: chamar `.new()` num script invalido ABORTA a funcao que chamou. Numa
## unica funcao com um laco, o modulo ruim levava junto todos os seguintes --
## o terceiro modulo nem chegava a ser tentado. Por isso cada modulo passa por
## _carregar_um(): o erro derruba so' aquela chamada, e o laco continua.
##
## Com o guard, os dois defeituosos sao PULADOS em silencio e o bom sobe.

const ARQ_LISTA := "res://modulos/lista.json"

## nome -> Node. Vazio num APK sem pacote, e isso e' o normal.
var _vivos: Dictionary = {}
## Modulos que a lista pedia e nao subiram. O painel de dev mostra isto.
var recusados: Array[String] = []


func _ready() -> void:
	# _ready, e nao _init: o Carregador ja' aplicou os pacotes bem antes daqui,
	# e em _ready a arvore existe -- da' para os modulos usarem os outros
	# autoloads sem depender de ordem de criacao.
	for entrada in _ler_lista():
		if not (entrada is Dictionary):
			continue
		var nome := str((entrada as Dictionary).get("nome", "")).strip_edges()
		var caminho := str((entrada as Dictionary).get("script", "")).strip_edges()
		if nome.is_empty() or caminho.is_empty():
			continue
		if _vivos.has(nome):
			push_warning("modulos: '%s' repetido na lista; ficou o primeiro" % nome)
			continue
		_carregar_um(nome, caminho)


## Uma funcao por modulo DE PROPOSITO. Ver o cabecalho: instanciar script
## invalido aborta a funcao chamadora, e num laco unico isso engoliria todos os
## modulos seguintes.
func _carregar_um(nome: String, caminho: String) -> void:
	if not caminho.begins_with("res://"):
		recusados.append("%s (caminho fora de res://)" % nome)
		return
	if not ResourceLoader.exists(caminho):
		recusados.append("%s (arquivo ausente)" % nome)
		return
	var recurso: Variant = load(caminho)
	if recurso == null or not (recurso is Script):
		recusados.append("%s (nao e' script)" % nome)
		return
	var script := recurso as Script
	# O guard. Vale para erro de sintaxe E para script que cita autoload
	# inexistente -- os dois dao can_instantiate() == false.
	if not script.can_instantiate():
		recusados.append("%s (script nao compila nesta build)" % nome)
		return
	var obj: Variant = script.new()
	if not (obj is Node):
		recusados.append("%s (nao e' Node)" % nome)
		return
	var no := obj as Node
	no.name = nome
	_vivos[nome] = no
	add_child(no)


func _ler_lista() -> Array:
	var f := FileAccess.open(ARQ_LISTA, FileAccess.READ)
	if f == null:
		return []
	var txt := f.get_as_text()
	f.close()
	var d: Variant = JSON.parse_string(txt)
	if not (d is Dictionary):
		return []
	var lista: Variant = (d as Dictionary).get("modulos", [])
	return lista as Array if lista is Array else []


## O jeito de usar. Devolve null quando o modulo nao esta instalado -- quem
## chama confere, e o codigo continua valido em build sem o pacote.
func pegar(nome: String) -> Node:
	return _vivos.get(nome)


func tem(nome: String) -> bool:
	return _vivos.has(nome)


func lista() -> Array[String]:
	var r: Array[String] = []
	for k in _vivos.keys():
		r.append(str(k))
	r.sort()
	return r
