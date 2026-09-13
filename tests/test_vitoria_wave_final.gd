extends Node
## O jogo passa a TER FIM: limpar a wave final é vencer.
##
## Antes daqui não havia vitória possível. A dificuldade congelava na wave 250
## -- HP dos mobs em 40×, horda no teto de 105, intervalo no piso de 0.20s -- e
## dali em diante nada mudava. Quem vencia a 250 vencia a 1000: a run só
## terminava quando a pessoa fechava o app.
##
## Um jogo que não pode ser vencido não tem o que comemorar, e um placar de
## "maior wave" num jogo infinito mede paciência, não habilidade.
##
## Este teste trava as três coisas que fazem o fim EXISTIR de verdade:
## a wave final ser alcançável e única, a vitória sair pelo caminho de fim de
## partida (para o ouro e o recorde não se perderem), e a tela dizer "venceu"
## em vez de "perdeu".

var _falhas: Array[String] = []

const MAIN := preload("res://scripts/main.gd")
const UI   := preload("res://scripts/ui.gd")


func _ready() -> void:
	call_deferred("_run")


func _run() -> void:
	_checar_constantes()
	_checar_gatilho()
	_checar_registro()
	_checar_tela()
	_finalizar()


func _checar_constantes() -> void:
	_esperar(MAIN.WAVE_FINAL == 300,
		"A wave final tem que ser 300 (está %d)." % MAIN.WAVE_FINAL)
	_esperar(MAIN.CRISTAIS_VITORIA > 0,
		"Vencer sem prêmio nenhum é um anticlímax -- e quem chega lá gastou horas numa run só.")


## O gatilho tem que estar no instante em que a wave é LIMPA, e antes de
## qualquer coisa que prepare a próxima.
##
## Se a vitória fosse conferida no começo da wave seguinte, a 301 chegaria a
## existir por um quadro: o jogador veria o jogo continuar antes de receber o
## aviso de que tinha acabado.
func _checar_gatilho() -> void:
	var codigo : String = _codigo("res://scripts/main.gd")
	var i_gatilho : int = codigo.find("if wave >= WAVE_FINAL:")
	_esperar(i_gatilho >= 0, "Não existe gatilho de wave final no main.gd.")
	if i_gatilho < 0:
		return

	var i_cartas : int = codigo.find('estado = "cartas"', i_gatilho)
	_esperar(i_cartas > i_gatilho,
		"O gatilho da vitória tem que vir ANTES de preparar a próxima wave -- "
		+ "senão a 301 existe por um quadro antes de o jogador saber que acabou.")

	var corpo : String = codigo.substr(i_gatilho, 200)
	_esperar(corpo.contains("_vencer()"), "O gatilho tem que chamar _vencer().")
	_esperar(corpo.contains("return"),
		"Depois de vencer a função tem que SAIR: seguir em frente prepararia a wave 301.")


## Vitória é um fim de partida como qualquer outro: ouro, recorde, ranking e
## save na nuvem valem igual. Esquecer um deles puniria justamente quem foi
## mais longe.
func _checar_registro() -> void:
	var codigo : String = _codigo("res://scripts/main.gd")
	var i : int = codigo.find("func _vencer()")
	_esperar(i >= 0, "Não existe a função _vencer no main.gd.")
	if i < 0:
		return
	var corpo : String = codigo.substr(i, 1400)
	_esperar(corpo.contains("registrar_vitoria"), "A vitória tem que ser carimbada no save.")
	_esperar(corpo.contains("depositar_cristais"), "O prêmio tem que ser pago.")
	## Na chamada da TELA DE VITÓRIA, e não em qualquer lugar da função: o ramo
	## de reserva (quando a tela nova não existe) também cita o mesmo nome, e a
	## sabotagem que tirou o callback da chamada de verdade passou batido por
	## causa disso.
	var i_tela : int = corpo.find("mostrar_vitoria(")
	_esperar(i_tela >= 0, "A vitória tem que abrir a tela de vitória.")
	if i_tela >= 0:
		_esperar(corpo.substr(i_tela, 160).contains("_finalizar_game_over"),
			"A tela de vitória tem que receber o fim de partida -- é ele que deposita "
			+ "o ouro, grava o recorde e manda o score ao ranking. Sem ele a run "
			+ "mais longa do jogador não rende NADA.")

	_esperar(Salvar.has_method("registrar_vitoria"),
		"Falta o registrar_vitoria no Salvar.")
	if Salvar.has_method("registrar_vitoria"):
		var antes : int = int(Salvar.get("vitorias"))
		Salvar.registrar_vitoria(300, 12345)
		_esperar(int(Salvar.get("vitorias")) == antes + 1,
			"registrar_vitoria tem que contar a vitória.")
		_esperar(str(Salvar.get("vitoria_primeira_em")) != "",
			"A data da primeira vitória tem que ficar registrada.")


## A tela tem que dizer VITÓRIA, e não DERROTA. Quem venceu não pode ler que
## perdeu.
func _checar_tela() -> void:
	_esperar(UI.new().has_method("mostrar_vitoria"),
		"Falta a tela de vitória (mostrar_vitoria) no ui.gd.")
	var codigo : String = _codigo("res://scripts/ui.gd")
	_esperar(codigo.contains('"VITÓRIA" if _venceu else "DERROTA"'),
		"O título tem que alternar entre VITÓRIA e DERROTA.")
	## Uma tela só, dois finais: a de vitória REAPROVEITA a montagem da
	## derrota. Uma segunda tela escrita à mão envelheceria separado -- o
	## conserto que a derrota recebesse não chegaria na vitória.
	var corpo_vit : String = _corpo(codigo, "func mostrar_vitoria")
	_esperar(corpo_vit != "", "Não achei o corpo do mostrar_vitoria.")
	_esperar(corpo_vit.contains("mostrar_game_over(score"),
		"A tela de vitória tem que CHAMAR a montagem da derrota (com os argumentos), "
		+ "senão ela não desenha nada -- ou as duas telas envelhecem separado.")
	_esperar(corpo_vit.contains("_vitoria_em_curso = true"),
		"A tela precisa marcar que é vitória antes de montar, senão sai DERROTA.")


## O corpo de uma função, até a PRÓXIMA função.
##
## Uma janela de N caracteres não serve: ela atravessa a fronteira e casa com a
## função seguinte. Foi o que a sabotagem mostrou -- apaguei a chamada dentro
## do mostrar_vitoria e o teste continuou verde, porque o NOME `mostrar_game_over`
## aparecia logo abaixo, na declaração da função de baixo.
func _corpo(codigo: String, assinatura: String) -> String:
	var i : int = codigo.find(assinatura)
	if i < 0:
		return ""
	var fim : int = codigo.find("\nfunc ", i + assinatura.length())
	if fim < 0:
		fim = codigo.length()
	return codigo.substr(i, fim - i)


func _codigo(caminho: String) -> String:
	var f := FileAccess.open(caminho, FileAccess.READ)
	if f == null:
		_falhas.append("Nao achei o %s." % caminho)
		return ""
	var texto := f.get_as_text()
	f.close()
	# Comentário não é código: os comentários destes consertos citam as frases
	# e os números de propósito.
	var limpo := ""
	for linha in texto.split("\n"):
		var corte: int = linha.find("#")
		limpo += (linha if corte < 0 else linha.substr(0, corte)) + "\n"
	return limpo


func _esperar(condicao: bool, msg: String) -> void:
	if not condicao:
		_falhas.append(msg)


func _finalizar() -> void:
	if _falhas.is_empty():
		print("OK vitoria wave final")
		get_tree().quit(0)
	else:
		for falha in _falhas:
			push_error(falha)
		get_tree().quit(1)
