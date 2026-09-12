extends Node
## Por que o ranking "nao funciona".
##
## A tabela do servidor tem DUAS linhas, as duas de junho, temporada 1 -- tres
## temporadas inteiras sem uma entrada. A conta da temporada esta certa (junho
## e' mesmo a 1, hoje e' a 4). O que nao estava certo era o silencio:
##
##   1. `verificar_e_enviar` desistia por TRES motivos diferentes -- wave 0,
##      sem nome, sem login -- e os tres davam em `return`, sem sinal nenhum.
##      Para quem joga, os tres tem a mesma cara: o quadro vazio.
##
##   2. A tela do ranking, com a lista vazia, mostrava a mensagem "Nenhum
##      recorde registrado" e SAIA antes de escrever o rotulo de posicao, que
##      ficava com o texto da vez anterior. As duas frases apareciam juntas:
##      "Nenhum recorde por wave registrado ainda" e "Sua posição: 1º lugar".
##      Ser primeiro de nada nao quer dizer nada.
##
## Um recurso que falha calado nao e' um recurso quebrado, e' um recurso
## invisivel: ninguem reporta, ninguem conserta, e o jogador conclui que o jogo
## foi abandonado.

var _falhas: Array[String] = []


func _ready() -> void:
	call_deferred("_run")


func _run() -> void:
	var nome_antes: String = Salvar.nome_jogador
	var wave_antes: int = Salvar.melhor_wave
	var senha_antes: String = Salvar.senha_jogador

	# ── Sem nome: tem que dizer que falta o nome ─────────────────────────
	Salvar.nome_jogador = ""
	Salvar.senha_jogador = "hash-de-mentira"
	Salvar.melhor_wave = 0
	RankingOnline.verificar_e_enviar("", 100, 5)
	_esperar(RankingOnline.motivo_nao_enviei() != "",
		"Sem nome, o envio tem que dizer POR QUE nao foi -- nao pode sair calado.")
	_esperar(RankingOnline.motivo_nao_enviei().to_lower().contains("nome"),
		"O motivo tem que falar do nome, e nao de outra coisa (veio: %s)."
			% RankingOnline.motivo_nao_enviei())

	# ── Sem login: o motivo mais provavel na pratica ─────────────────────
	Salvar.nome_jogador = "Testador"
	Salvar.senha_jogador = ""
	RankingOnline.verificar_e_enviar("Testador", 100, 5)
	var sem_login: String = RankingOnline.motivo_nao_enviei()
	_esperar(sem_login != "", "Sem login, o envio tem que dizer por que nao foi.")
	_esperar(sem_login.to_lower().contains("conta") or sem_login.to_lower().contains("entre"),
		"O motivo tem que mandar entrar na conta (veio: %s)." % sem_login)

	# ── Wave 0: nao ha' o que registrar, e isso tambem se diz ────────────
	Salvar.senha_jogador = "hash-de-mentira"
	RankingOnline.verificar_e_enviar("Testador", 0, 0)
	_esperar(RankingOnline.motivo_nao_enviei() != "",
		"Wave 0 tem que dizer que nao ha' o que registrar.")

	# ── Partida pior que o recorde: tambem e' um motivo, nao um sumico ───
	Salvar.melhor_wave = 30
	RankingOnline.verificar_e_enviar("Testador", 100, 5)
	var pior: String = RankingOnline.motivo_nao_enviei()
	_esperar(pior != "", "Partida abaixo do recorde tem que dizer que so' o melhor conta.")
	_esperar(pior.contains("30"),
		"O motivo tem que citar a wave que precisa ser batida (veio: %s)." % pior)

	# ── E quando DA' certo, o motivo tem que ficar vazio ─────────────────
	# Sem isto, um motivo antigo ficaria grudado na tela para sempre, dizendo
	# que nao deu certo depois de ter dado.
	Salvar.melhor_wave = 5
	RankingOnline.verificar_e_enviar("Testador", 100, 9)
	_esperar(RankingOnline.motivo_nao_enviei() == "",
		"Quando o envio segue em frente, o motivo tem que ser LIMPO (ficou: %s)."
			% RankingOnline.motivo_nao_enviei())

	Salvar.nome_jogador = nome_antes
	Salvar.melhor_wave = wave_antes
	Salvar.senha_jogador = senha_antes

	_checar_tela_vazia()
	_checar_campeoes_vazios()
	_finalizar()


## "CAMPEOES TEMP. 4" e "Nenhuma temporada encerrada ainda" apareciam na MESMA
## linha. A temporada 4 encerrou; o que nao houve foi gente nela. A condicao
## juntava dois estados diferentes e dava a ambos a frase errada, escondendo a
## noticia de verdade.
func _checar_campeoes_vazios() -> void:
	var codigo := _codigo("res://scripts/menu/ranking.gd")

	var i: int = codigo.find("Nenhuma temporada encerrada ainda")
	_esperar(i >= 0, "A frase de 'nenhuma temporada encerrada' sumiu do ranking.gd.")
	_esperar(codigo.contains("fechou sem ninguém no quadro"),
		"Temporada que ENCERROU sem ninguem precisa de frase propria -- dizer que "
		+ "nenhuma encerrou, ao lado do titulo 'CAMPEOES TEMP. N', se contradiz.")
	## E os tres casos tem que continuar separados: carregando, nunca encerrou,
	## e encerrou vazia.
	_esperar(codigo.contains("Carregando..."), "O estado 'carregando' tem que continuar existindo.")

	## O degrau vago do podio nao pode voltar a ser uma caixa apagada com um
	## risco: com o quadro vazio isso le como tela que nao carregou.
	_esperar(codigo.contains("em aberto"),
		"O degrau sem dono tem que se explicar ('em aberto'), e nao ser um travessao.")
	_esperar(not codigo.contains('"—"'),
		"O travessao no degrau vazio tem que sair: ele parece tela quebrada.")


func _codigo(caminho: String) -> String:
	var f := FileAccess.open(caminho, FileAccess.READ)
	if f == null:
		_falhas.append("Nao achei o %s." % caminho)
		return ""
	var texto := f.get_as_text()
	f.close()
	# Comentario nao e' codigo: os comentarios destes consertos CITAM as frases
	# antigas de proposito.
	var limpo := ""
	for linha in texto.split("\n"):
		var corte: int = linha.find("#")
		limpo += (linha if corte < 0 else linha.substr(0, corte)) + "\n"
	return limpo


## A tela nao pode mais deixar "Sua posição: 1º lugar" sobrando sobre uma
## lista vazia. Confere no texto-fonte, porque montar a tela inteira aqui
## exigiria o menu completo -- mas confere a ORDEM, que e' onde estava o
## defeito: o `return` vinha antes de escrever o rotulo.
func _checar_tela_vazia() -> void:
	var f := FileAccess.open("res://scripts/menu/ranking.gd", FileAccess.READ)
	if f == null:
		_falhas.append("Nao achei o scripts/menu/ranking.gd.")
		return
	var texto := f.get_as_text()
	f.close()

	# Comentario NAO e' codigo: o comentario que explica este conserto CITA a
	# frase "Sua posição: 1º lugar" de proposito. Sem tirar os comentarios,
	# este teste casaria com a propria prosa que o justifica.
	var codigo := ""
	for linha in texto.split("\n"):
		var corte: int = linha.find("#")
		codigo += (linha if corte < 0 else linha.substr(0, corte)) + "\n"

	var i_vazio: int = codigo.find("Nenhum recorde por wave registrado ainda")
	_esperar(i_vazio >= 0, "A mensagem de lista vazia sumiu do ranking.gd.")
	if i_vazio < 0:
		return
	var depois: String = codigo.substr(i_vazio)
	var i_return: int = depois.find("return")
	var i_motivo: int = depois.find("motivo_nao_enviei")
	_esperar(i_motivo >= 0,
		"Com a lista vazia, a tela tem que dizer o motivo de nada ter sido enviado.")
	_esperar(i_motivo >= 0 and i_return >= 0 and i_motivo < i_return,
		"O rotulo de posicao tem que ser escrito ANTES do return -- era o return "
		+ "cedo demais que deixava 'Sua posição: 1º lugar' sobrando sobre a lista vazia.")


func _esperar(condicao: bool, msg: String) -> void:
	if not condicao:
		_falhas.append(msg)


func _finalizar() -> void:
	if _falhas.is_empty():
		print("OK ranking motivo")
		get_tree().quit(0)
	else:
		for falha in _falhas:
			push_error(falha)
		get_tree().quit(1)
