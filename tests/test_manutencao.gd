extends Node
## Guarda a lista de coisas que SO' existem se estiverem no APK.
##
## POR QUE UM TESTE PARA ISTO
##
## Um pacote troca quase tudo, mas nao alcanca o que o motor le' no arranque:
## a lista de autoloads e alguns ajustes de projeto. Cada item desses que falta
## no APK nao da' erro nenhum -- simplesmente nao existe a possibilidade, e a
## conta so' aparece meses depois, na forma de "preciso de um APK novo por
## causa disso".
##
## Foi exatamente a reclamacao que originou esta lista: "chato de toda hora ter
## que baixar um novo porque esqueceu de algo e nao consegue editar agora".
##
## Entao a lista vira teste. Tirar um item daqui passa a exigir tirar tambem do
## teste -- que e' uma decisao consciente, e nao um esquecimento.

const PROJETO := "res://project.godot"

var _falhas: Array[String] = []
var _projeto: String = ""


func _ready() -> void:
	var f := FileAccess.open(PROJETO, FileAccess.READ)
	if f == null:
		push_error("nao consegui ler o project.godot")
		get_tree().quit(1)
		return
	_projeto = f.get_as_text()
	f.close()

	_carregador_e_o_primeiro()
	_os_autoloads_de_manutencao()
	_log_em_arquivo()
	_a_lista_de_modulos_existe()
	_finalizar()


## Ordem nao e' detalhe: o Carregador aplica os pacotes no _init(), e todo
## autoload declarado ANTES dele leria a versao do APK, nunca a do pacote. Ja'
## foi assim -- Som, Salvar e Auth ficavam fora de alcance de qualquer
## atualizacao. Se alguem inserir uma linha acima dele, volta tudo.
func _carregador_e_o_primeiro() -> void:
	var i := _projeto.find("[autoload]")
	if i < 0:
		_falhas.append("nao achei a secao [autoload]")
		return
	var bloco := _projeto.substr(i)
	for linha in bloco.split("\n"):
		var l := linha.strip_edges()
		if l.is_empty() or l.begins_with("[") or l.begins_with(";"):
			continue
		_esperar(l.begins_with("Carregador="),
			"o primeiro autoload tem que ser o Carregador, e e' '%s'" % l.split("=")[0])
		return
	_falhas.append("a secao [autoload] esta vazia")


func _os_autoloads_de_manutencao() -> void:
	# Cada nome aqui e' uma porta que so' abre de dentro do APK.
	var obrigatorios := {
		"Modulos": "sem ele, sistema novo por pacote e' impossivel (pacote nao cria autoload)",
		"DevPainel": "sem ele, nao ha' como ver erro nem descartar pacote ruim no celular",
		"Reserva1": "vaga guardada para nome global novo",
		"Reserva2": "vaga guardada para nome global novo",
		"Reserva3": "vaga guardada para nome global novo",
	}
	for nome in obrigatorios:
		_esperar(_projeto.contains("\n%s=" % nome),
			"o autoload %s sumiu do project.godot -- %s" % [nome, obrigatorios[nome]])


## No Android o log em arquivo vem DESLIGADO de fabrica, e o ajuste e' lido no
## arranque. Sem ele o DevPainel nao tem o que mostrar e um defeito no aparelho
## de outra pessoa volta a ser invisivel.
func _log_em_arquivo() -> void:
	var ligado := _projeto.contains("file_logging/enable_file_logging=true")
	_esperar(ligado, "file_logging/enable_file_logging precisa estar true no project.godot")
	if ligado:
		# Confere que o motor concorda com o arquivo -- ajuste com nome errado
		# nao da' erro, so' fica sem efeito, que e' o pior dos mundos.
		_esperar(bool(ProjectSettings.get_setting("debug/file_logging/enable_file_logging", false)),
			"o motor nao esta enxergando o ajuste de file_logging (nome da chave mudou?)")


## O pacote substitui ESTE arquivo para instalar modulos. Se ele nao for junto
## no APK, nao ha' o que substituir.
##
## O caminho vai escrito aqui, e nao como `Modulos.ARQ_LISTA`, de proposito:
## citar o autoload faria ESTE arquivo deixar de compilar quando o autoload
## sumisse, e o teste morreria com "Identifier not declared" em vez da mensagem
## que explica o que fazer. Guarda que so' funciona enquanto o vigiado existe
## nao e' guarda.
func _a_lista_de_modulos_existe() -> void:
	const CAMINHO := "res://modulos/lista.json"
	var f := FileAccess.open(CAMINHO, FileAccess.READ)
	if f == null:
		_falhas.append("%s nao existe -- o pacote nao teria o que substituir" % CAMINHO)
		return
	var txt := f.get_as_text()
	f.close()
	var d: Variant = JSON.parse_string(txt)
	_esperar(d is Dictionary and (d as Dictionary).has("modulos"),
		"a lista de modulos precisa ser um objeto JSON com a chave 'modulos'")


func _esperar(condicao: bool, msg: String) -> void:
	if not condicao:
		_falhas.append(msg)


func _finalizar() -> void:
	if _falhas.is_empty():
		print("OK manutencao")
		get_tree().quit(0)
	else:
		for falha in _falhas:
			push_error(falha)
		get_tree().quit(1)
