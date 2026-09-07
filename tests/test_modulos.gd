extends Node
## Confere o registro de modulos -- o caminho pelo qual um pacote cria sistema
## novo sem APK novo.
##
## O que este teste protege, em uma frase: um modulo ruim nao pode levar junto
## os modulos bons. Isso ja' aconteceu no laboratorio -- com um unico laco, o
## modulo quebrado abortava a funcao e o terceiro modulo nem chegava a ser
## tentado. A defesa sao duas coisas (guard `can_instantiate` + uma funcao por
## modulo), e as duas sao invisiveis: quem reescrever o arquivo desfaz sem
## perceber, e nenhum teste reclamaria. Por isso alguns testes aqui leem o
## CODIGO, nao so' o comportamento.

const FONTE_MODULOS := "res://scripts/modulos.gd"

var _falhas: Array[String] = []


func _ready() -> void:
	_o_guard_distingue()
	_a_api_nao_explode()
	_caminhos_recusados()
	_o_codigo_mantem_as_duas_defesas()
	_finalizar()


## `can_instantiate()` e' o guard. Ele precisa dizer NAO para os dois defeitos
## que um pacote pode trazer, e SIM para codigo bom.
func _o_guard_distingue() -> void:
	var bom := _script_de("extends Node\nfunc oi() -> int:\n\treturn 1\n")
	_esperar(bom.can_instantiate(), "script bom tem que poder instanciar")

	var quebrado := _script_de("extends Node\nfunc _ready() -> void\n\tisto (((nao compila\n")
	_esperar(not quebrado.can_instantiate(),
		"erro de sintaxe tem que reprovar no can_instantiate")

	# O caso que quebrou a build de junho: script citando autoload inexistente.
	var fantasma := _script_de("extends Node\nfunc _ready() -> void:\n\tprint(NaoExisteEsteAutoload.x)\n")
	_esperar(not fantasma.can_instantiate(),
		"script que cita autoload inexistente tem que reprovar no can_instantiate")


## A API tem que ser segura de chamar quando NAO ha' modulo nenhum -- que e' o
## estado de todo APK recem-instalado. Se `pegar` de um nome ausente explodisse,
## todo codigo que consulta modulo opcional quebraria no app publico.
func _a_api_nao_explode() -> void:
	_esperar(Modulos != null, "o autoload Modulos precisa existir")
	_esperar(not Modulos.tem("nao_instalado"), "tem() de modulo ausente e' false")
	_esperar(Modulos.pegar("nao_instalado") == null, "pegar() de modulo ausente e' null")
	_esperar(Modulos.lista() is Array, "lista() devolve Array")


## Um pacote nao pode apontar para fora de res:// nem para arquivo que nao veio.
## Nos dois casos o modulo e' recusado E registrado -- recusa silenciosa faria
## o modulo "sumir" sem ninguem saber por que.
func _caminhos_recusados() -> void:
	var antes := Modulos.recusados.size()
	Modulos._carregar_um("fora", "user://algum.gd")
	Modulos._carregar_um("ausente", "res://modulos/nao_existe_mesmo.gd")
	_esperar(Modulos.recusados.size() == antes + 2,
		"caminho invalido e arquivo ausente tem que virar recusa registrada")
	_esperar(not Modulos.tem("fora") and not Modulos.tem("ausente"),
		"modulo recusado nao pode entrar como vivo")


## As duas defesas moram no codigo e nao dao para observar de fora.
func _o_codigo_mantem_as_duas_defesas() -> void:
	var f := FileAccess.open(FONTE_MODULOS, FileAccess.READ)
	if f == null:
		_falhas.append("nao consegui ler o modulos.gd")
		return
	var fonte := f.get_as_text()
	f.close()

	# Fora os comentarios: o cabecalho EXPLICA as defesas citando os nomes, e um
	# teste que confere prosa da' alarme falso. Ja' aconteceu no test_auth_falhas.
	var codigo := ""
	for linha in fonte.split("\n"):
		if linha.strip_edges().begins_with("#"):
			continue
		codigo += linha + "\n"

	_esperar(codigo.contains("can_instantiate()"),
		"o guard can_instantiate() sumiu do modulos.gd")
	_esperar(codigo.contains("func _carregar_um("),
		"a funcao por modulo sumiu -- sem ela, um modulo ruim aborta os seguintes")
	# A chamada tem que estar no laco, nao inline: e' a chamada que isola o erro.
	_esperar(codigo.contains("_carregar_um(nome, caminho)"),
		"o laco precisa chamar _carregar_um; instanciar direto no laco perde o isolamento")


func _script_de(fonte: String) -> GDScript:
	var s := GDScript.new()
	s.source_code = fonte
	# reload() reclama alto no log quando a fonte e' invalida, e e' esperado:
	# duas das tres fontes aqui sao invalidas de proposito.
	s.reload()
	return s


func _esperar(condicao: bool, msg: String) -> void:
	if not condicao:
		_falhas.append(msg)


func _finalizar() -> void:
	if _falhas.is_empty():
		print("OK modulos")
		get_tree().quit(0)
	else:
		for falha in _falhas:
			push_error(falha)
		get_tree().quit(1)
