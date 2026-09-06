extends Node
## Distinguir "nao chegou resposta" de "o servidor disse nao".
##
## Existe por causa de um defeito que custava a CONTA do jogador: o refresh do
## token apagava a sessao guardada em QUALQUER falha. Sem sinal chega ali igual
## a token invalido -- entao metro, aviao, wi-fi ruim ou servidor fora do ar
## deslogavam de vez, e a pessoa so' descobria depois.
##
## O primeiro parametro do request_completed diz qual dos dois aconteceu, e
## estava sendo ignorado nos cinco pontos do auth_supabase.gd.

const AUTH := preload("res://scripts/auth_supabase.gd")

var _falhas: Array[String] = []


func _ready() -> void:
	_sem_resposta()
	_mensagens()
	_o_codigo_ainda_usa_o_resultado()
	_finalizar()


func _sem_resposta() -> void:
	# Transporte falhou: nao houve resposta, ponto.
	_esperar(AUTH.sem_resposta(HTTPRequest.RESULT_CANT_CONNECT, 0),
		"nao conectou = sem resposta")
	_esperar(AUTH.sem_resposta(HTTPRequest.RESULT_CANT_RESOLVE, 0),
		"DNS falhou = sem resposta")
	_esperar(AUTH.sem_resposta(HTTPRequest.RESULT_TIMEOUT, 0),
		"tempo esgotado = sem resposta")
	# Servidor pausado responde assim: o Godot conclui, mas sem status HTTP.
	_esperar(AUTH.sem_resposta(HTTPRequest.RESULT_SUCCESS, 0),
		"status 0 = sem resposta, mesmo com resultado SUCCESS")

	# Aqui o servidor RESPONDEU. Mesmo dizendo nao, respondeu.
	_esperar(not AUTH.sem_resposta(HTTPRequest.RESULT_SUCCESS, 401),
		"401 e' resposta: o servidor recusou")
	_esperar(not AUTH.sem_resposta(HTTPRequest.RESULT_SUCCESS, 500),
		"500 e' resposta: o servidor quebrou")
	_esperar(not AUTH.sem_resposta(HTTPRequest.RESULT_SUCCESS, 200),
		"200 e' resposta")


func _mensagens() -> void:
	# O caso que motivou tudo: com o servidor fora do ar, o jogo dizia
	# "O servidor recusou o login (0)" e mandava procurar no lugar errado.
	var fora := AUTH.msg_de_falha(HTTPRequest.RESULT_CANT_CONNECT, 0)
	_esperar(not fora.contains("recusou"),
		"servidor fora do ar NAO pode dizer que recusou (veio: %s)" % fora)
	_esperar(fora.to_lower().contains("internet") or fora.to_lower().contains("servidor"),
		"a mensagem de rede deve falar de conexao (veio: %s)" % fora)

	_esperar(AUTH.msg_de_falha(HTTPRequest.RESULT_SUCCESS, 401).contains("não aceitou"),
		"401 deve dizer que o login nao foi aceito")
	_esperar(AUTH.msg_de_falha(HTTPRequest.RESULT_SUCCESS, 503).contains("problema"),
		"5xx deve dizer que o problema e' do servidor")

	# Nenhuma mensagem pode sair vazia: recado vazio na tela e' pior que erro.
	for par in [[HTTPRequest.RESULT_SUCCESS, 200], [HTTPRequest.RESULT_SUCCESS, 418],
			[HTTPRequest.RESULT_CANT_CONNECT, 0], [HTTPRequest.RESULT_SUCCESS, 500]]:
		_esperar(AUTH.msg_de_falha(par[0], par[1]).length() > 10,
			"mensagem curta demais para resultado=%d status=%d" % [par[0], par[1]])


## O conserto do refresh nao tem como ser chamado de fora (esta dentro de uma
## lambda), entao o teste olha o CODIGO. Sem isto, alguem reescreve o bloco,
## volta a apagar a sessao em qualquer falha, e nenhum teste reclama.
func _o_codigo_ainda_usa_o_resultado() -> void:
	var f := FileAccess.open("res://scripts/auth_supabase.gd", FileAccess.READ)
	if f == null:
		_falhas.append("nao consegui ler o auth_supabase.gd")
		return
	var fonte := f.get_as_text()
	f.close()

	# Fora os comentarios. O comentario que EXPLICA o defeito cita
	# `func(_r, status, ...)` de proposito, e a primeira versao deste teste
	# acusava a propria documentacao -- alarme falso que ensina a ignorar o
	# teste. Guarda tem que olhar codigo, nao prosa.
	var codigo := ""
	for linha in fonte.split("\n"):
		if linha.strip_edges().begins_with("#"):
			continue
		codigo += linha + "\n"

	_esperar(not codigo.contains("func(_r, status"),
		"algum ponto voltou a ignorar o resultado do HTTPRequest (func(_r, status)")

	var i := fonte.find("grant_type=refresh_token")
	var bloco := fonte.substr(maxi(0, i - 1400), 1400) if i > 0 else ""
	_esperar(bloco.contains("sem_resposta("),
		"o refresh precisa conferir sem_resposta antes de apagar a sessao")
	_esperar(bloco.contains("_limpar_local()"),
		"o refresh ainda deve encerrar a sessao quando o servidor RECUSA")


func _esperar(condicao: bool, msg: String) -> void:
	if not condicao:
		_falhas.append(msg)


func _finalizar() -> void:
	if _falhas.is_empty():
		print("OK auth-falhas")
		get_tree().quit(0)
	else:
		for falha in _falhas:
			push_error(falha)
		get_tree().quit(1)
