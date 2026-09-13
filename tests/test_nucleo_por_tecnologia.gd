extends Node
## Cada tecnologia comprada tem que MOVER o número.
##
## O defeito foi medido, não suposto. Um bot que joga o jogo (tools/
## bot_progressao.gd) mostrou sete horas seguidas assim:
##
##   partida | wave | talentos | dano inicial
##         8 |   39 |   19/59  |      89
##        14 |   39 |   31/59  |      89
##        20 |   40 |   39/59  |      89
##
## Vinte e um talentos comprados, zero ponto de dano. Todo o poder da árvore
## morava em TRÊS nós -- p4, tita e colosso -- e os outros 56 não tocavam em
## `damage`. Sete horas em que o jogador progride e não vê nada acontecer: é
## onde se desinstala um jogo.
##
## O conserto tem uma regra só: cada tecnologia reforça o núcleo, e os três
## gigantes encolheram para o topo não explodir.
##
## Este teste trava as duas metades. Só a primeira faria a curva do fim
## explodir; só a segunda deixaria o jogador mais fraco do que antes.

var _falhas: Array[String] = []

const MAIN := preload("res://scripts/main.gd")


func _ready() -> void:
	call_deferred("_run")


func _run() -> void:
	_checar_constantes()
	_checar_curva()
	_checar_descricoes()
	_finalizar()


func _checar_constantes() -> void:
	## O reforço tem que existir e ser pequeno: é ele que move cada compra,
	## mas 59 tecnologias multiplicam qualquer número.
	_esperar(MAIN.NUCLEO_POR_TECNOLOGIA > 0.0,
		"Sem reforço por tecnologia, a maior parte da árvore volta a não fazer nada.")
	_esperar(MAIN.NUCLEO_POR_TECNOLOGIA <= 0.02,
		"Acima de 2%% por tecnologia o bot mediu o jogo quebrando cedo demais (era %.3f)."
			% MAIN.NUCLEO_POR_TECNOLOGIA)

	## E os gigantes tinham que encolher junto. Sem isso o total dispara.
	_esperar(MAIN.P4_DANO < 80.0, "p4 tinha que encolher de 80 (está %.0f)." % MAIN.P4_DANO)
	_esperar(MAIN.TITA_DANO < 150.0, "tita tinha que encolher de 150 (está %.0f)." % MAIN.TITA_DANO)
	_esperar(MAIN.COLOSSO_DANO < 50.0, "colosso tinha que encolher de 50 (está %.0f)." % MAIN.COLOSSO_DANO)

	## Mas não podem sumir: continuam sendo os marcos da árvore.
	_esperar(MAIN.P4_DANO >= 40.0 and MAIN.TITA_DANO >= 75.0 and MAIN.COLOSSO_DANO >= 25.0,
		"Os três marcos não podem virar migalha -- eles são o motivo de ir até o fim de um ramo.")


## A prova que interessa: com a árvore pela metade, a torre TEM que estar mais
## forte do que estaria pelo desenho antigo -- porque é exatamente ali, no
## meio, que estavam as sete horas paradas.
func _checar_curva() -> void:
	var d0 : float = 25.0 + 10.0     # torre base + raiz
	## Antigo: no meio da árvore, sem p4/tita/colosso, o dano era só p1 (+30).
	var antigo_meio : float = d0 + 30.0
	## Novo: o mesmo p1, mais o reforço de 30 tecnologias.
	var novo_meio : float = (d0 + 30.0) * (1.0 + MAIN.NUCLEO_POR_TECNOLOGIA * 30.0)
	_esperar(novo_meio > antigo_meio * 1.20,
		"Com metade da árvore o jogador tem que estar visivelmente mais forte "
		+ "que no desenho antigo (era %.0f, ficou %.0f)." % [antigo_meio, novo_meio])

	## E no fim a curva não pode ter explodido: o jogo já é infinito para quem
	## completa, e deixá-lo MAIS fácil tiraria o pouco de teto que resta.
	var antigo_fim : float = d0 + 30.0 + 80.0 + 150.0 + 50.0
	var novo_fim : float = (d0 + 30.0 + MAIN.P4_DANO + MAIN.TITA_DANO + MAIN.COLOSSO_DANO) \
			* (1.0 + MAIN.NUCLEO_POR_TECNOLOGIA * 59.0)
	_esperar(novo_fim <= antigo_fim * 1.15,
		"Com a árvore cheia o dano não pode disparar: antes %.0f, agora %.0f."
			% [antigo_fim, novo_fim])
	_esperar(novo_fim >= antigo_fim * 0.85,
		"E nem despencar: quem completou a árvore antes não pode ficar mais fraco "
		+ "(antes %.0f, agora %.0f)." % [antigo_fim, novo_fim])


## Texto que promete o que não entrega é pior que texto nenhum: a árvore custa
## cristais e o jogador escolhe lendo essas frases.
func _checar_descricoes() -> void:
	var velhos : Array = ["+80 de dano", "+150 dano", "+50 dano, +50 HP"]
	for tid in Salvar.TALENTOS_INFO.keys():
		var info : Dictionary = Salvar.TALENTOS_INFO[tid] as Dictionary
		var texto : String = str(info.get("desc", "")) + " " + str(info.get("efeito", ""))
		for v in velhos:
			_esperar(not texto.contains(str(v)),
				"O talento '%s' ainda promete '%s', que deixou de ser verdade." % [str(tid), str(v)])


func _esperar(condicao: bool, msg: String) -> void:
	if not condicao:
		_falhas.append(msg)


func _finalizar() -> void:
	if _falhas.is_empty():
		print("OK nucleo por tecnologia")
		get_tree().quit(0)
	else:
		for falha in _falhas:
			push_error(falha)
		get_tree().quit(1)
