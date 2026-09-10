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
	_o_endereco_proprio_do_jogo()
	_o_app_sabe_qual_apk_e()
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


## O ENDERECO PROPRIO DO JOGO, cyron://voltar.
##
## Sem ele, o botao "VOLTAR AO JOGO" da pagina de login nao abre o app -- e nao
## avisa: o navegador so' vai para o endereco de reserva. Esta medido no
## aparelho, com as Configuracoes do Android como controle: nenhum app abre
## pelo navegador sem um intent-filter proprio, porque o Chrome acrescenta
## CATEGORY_BROWSABLE e a tela de abertura nao declara essa categoria.
##
## Isso so' cabe no manifesto com COMPILACAO GRADLE. As duas pontas ficam aqui
## porque a esteira do APK so' roda quando muda assets/, addons/ ou o
## project.godot -- uma mudanca que desligue o Gradle passaria meses sem
## aparecer. A bateria de testes roda em todo PR.
func _o_endereco_proprio_do_jogo() -> void:
	var f := FileAccess.open("res://tools/exportar_apk_dev.sh", FileAccess.READ)
	if f == null:
		_falhas.append("sumiu o tools/exportar_apk_dev.sh")
		return
	var script := f.get_as_text()
	f.close()

	_esperar(script.contains("gradle_build/use_gradle_build=true"),
		"a compilacao Gradle foi desligada — sem ela o manifesto nao aceita o "
		+ "endereco proprio, e o botao de voltar para de abrir o jogo")
	_esperar(script.contains("endereco_proprio_android.py"),
		"o remendo do manifesto saiu do exportar_apk_dev.sh")
	_esperar(script.contains("android_source.zip"),
		"sumiu a instalacao do modelo de compilacao — o Gradle nao teria o que compilar")
	_esperar(FileAccess.file_exists("res://tools/endereco_proprio_android.py"),
		"sumiu o tools/endereco_proprio_android.py")

	# A pagina e o manifesto tem que falar do MESMO endereco. Se um mudar
	# sozinho, o botao vira um link para lugar nenhum -- e em silencio.
	var g := FileAccess.open("res://site/voltar-dev.html", FileAccess.READ)
	if g == null:
		_falhas.append("sumiu o site/voltar-dev.html")
		return
	var pagina := g.get_as_text()
	g.close()
	_esperar(pagina.contains("scheme=cyron"),
		"a pagina de voltar nao aponta mais para cyron:// — o botao nao abre o app")


## O APP TEM QUE SABER QUAL APK ELE E'.
##
## BuildConfig.APP_VERSION_CODE era uma constante fixa em 12 enquanto o APK ja'
## estava no 19. O painel de manutencao -- cuja unica funcao e' dizer o que esta
## rodando -- mostrava "code 12" em qualquer aparelho, e ninguem percebeu por
## semanas, porque um numero errado nao parece errado.
##
## Pior: e' esse numero que decide se o app publico mostra "atualizacao
## disponivel". Preso, o banner some para sempre.
##
## A verdade vem de res://versao_build.json, carimbado pela esteira. Quem voltar
## a ler a constante direto reintroduz o defeito -- daí estas travas.
func _o_app_sabe_qual_apk_e() -> void:
	var cfg := get_node_or_null("/root/BuildConfig")
	if cfg == null:
		_falhas.append("sem BuildConfig — nada a conferir")
		return
	_esperar(cfg.has_method("codigo_versao"),
		"BuildConfig perdeu codigo_versao() — o app volta a não saber qual APK é")
	_esperar(cfg.has_method("nome_versao"), "BuildConfig perdeu nome_versao()")
	if cfg.has_method("codigo_versao"):
		# Sem carimbo (editor/teste) tem que cair na constante, não em zero.
		_esperar(int(cfg.codigo_versao()) > 0,
			"codigo_versao() devolveu %d sem o carimbo — a reserva não funcionou"
				% int(cfg.codigo_versao()))

	for caminho in ["res://scripts/atualizador.gd", "res://scripts/dev_painel.gd"]:
		var f := FileAccess.open(caminho, FileAccess.READ)
		if f == null:
			_falhas.append("não consegui ler o %s" % caminho)
			continue
		var fonte := f.get_as_text()
		f.close()
		var codigo := ""
		for linha in fonte.split("\n"):
			if linha.strip_edges().begins_with("#"):
				continue
			codigo += linha + "\n"
		_esperar(not codigo.contains("APP_VERSION_CODE"),
			"%s voltou a ler a constante em vez do carimbo — o número volta a mentir"
				% caminho)

	var g := FileAccess.open("res://tools/exportar_apk_dev.sh", FileAccess.READ)
	if g == null:
		_falhas.append("sumiu o exportar_apk_dev.sh")
		return
	var script := g.get_as_text()
	g.close()
	_esperar(script.contains("versao_build.json"),
		"a esteira parou de carimbar a versão — o app volta a não saber qual APK é")
