extends Node
## Guarda o novo caminho de volta do login.
##
## O caminho antigo (servidor local em 127.0.0.1) foi testado no aparelho e nao
## funciona no Android: o navegador conecta e fica girando para sempre, porque o
## app congela em segundo plano. Repetido com o app acordado e o login ativo --
## a conexao nao chega. Voltar para aquele desenho seria repetir dias de
## tentativa e erro, entao aqui tem uma trava explicita contra isso.
##
## O que este teste protege:
##   1. o pendente sobrevive ao app ser morto (senao o codigo na ponte vira lixo)
##   2. um pendente velho e' descartado (a ponte ja' apagou o codigo la')
##   3. ninguem ressuscita o servidor local sem apagar esta trava

var _falhas: Array[String] = []


func _ready() -> void:
	_o_pendente_sobrevive()
	_pendente_velho_e_descartado()
	_o_loopback_nao_voltou()
	_finalizar()


## O caso que motiva o arquivo em disco: a pessoa toca em entrar, vai para o
## navegador, e o Android mata o jogo para liberar memoria. O codigo ja' esta na
## ponte. Sem o verifier salvo, ele seria impossivel de trocar por sessao.
func _o_pendente_sobrevive() -> void:
	Auth._estado = "estado-de-teste-com-tamanho-suficiente"
	Auth._verifier = "verifier-de-teste"
	Auth._salvar_pendente()

	# simula o app reabrindo do zero
	Auth._estado = ""
	Auth._verifier = ""
	Auth._ativo = false
	Auth._retomar_pendente()

	_esperar(Auth._estado == "estado-de-teste-com-tamanho-suficiente",
		"o estado tinha que voltar do disco (veio '%s')" % Auth._estado)
	_esperar(Auth._verifier == "verifier-de-teste",
		"o verifier tinha que voltar do disco")
	_esperar(Auth._ativo, "retomar tem que religar a busca na ponte")

	# Nao deixar a busca rodando de verdade depois do teste.
	Auth._ativo = false
	Auth._esquecer_pendente()


## Passado o prazo, a ponte ja' apagou o codigo. Continuar perguntando seria
## bater num servidor a toa e deixar o jogador olhando uma espera que nunca
## termina.
func _pendente_velho_e_descartado() -> void:
	var f := FileAccess.open_encrypted_with_pass(
		Auth._ARQ_PENDENTE, FileAccess.WRITE, Auth._CHAVE_SESSAO)
	if f == null:
		_falhas.append("nao consegui escrever o pendente de teste")
		return
	f.store_string(JSON.stringify({
		"estado": "estado-velho-mas-com-tamanho-ok",
		"verifier": "verifier-velho",
		"em": Time.get_unix_time_from_system() - (Auth._TIMEOUT_S + 60.0),
	}))
	f.close()

	Auth._estado = ""
	Auth._ativo = false
	Auth._retomar_pendente()

	_esperar(not Auth._ativo, "pendente vencido nao pode religar a busca")
	_esperar(Auth._estado.is_empty(), "pendente vencido nao pode restaurar o estado")
	_esperar(not FileAccess.file_exists(Auth._ARQ_PENDENTE),
		"pendente vencido tem que ser apagado do disco")


## Trava contra a volta do desenho que nao funciona.
func _o_loopback_nao_voltou() -> void:
	var f := FileAccess.open("res://scripts/auth_supabase.gd", FileAccess.READ)
	if f == null:
		_falhas.append("nao consegui ler o auth_supabase.gd")
		return
	var fonte := f.get_as_text()
	f.close()

	# Fora os comentarios: o cabecalho EXPLICA o loopback antigo e citaria as
	# palavras de proposito. Ja' deu alarme falso assim no test_auth_falhas.
	var codigo := ""
	for linha in fonte.split("\n"):
		var l := linha.strip_edges()
		if l.begins_with("#"):
			continue
		codigo += linha + "\n"

	_esperar(not codigo.contains("TCPServer"),
		"o servidor local voltou ao auth_supabase.gd — ele nao funciona no Android")
	_esperar(codigo.contains("_PAGINA_RETORNO"),
		"o retorno pela pagina do portal sumiu")
	_esperar(codigo.contains("_RPC_PEGAR"),
		"a busca na ponte sumiu")
	# O identificador precisa ir junto no endereco, senao a pagina nao sabe de
	# quem e' o codigo que recebeu.
	_esperar(codigo.contains("?s=%s") or codigo.contains("?s=") ,
		"o endereco de retorno precisa levar o identificador do login")
	_esperar(Auth._TIMEOUT_S >= 300.0,
		"prazo curto demais (%.0fs): login de celular passa disso com facilidade"
			% Auth._TIMEOUT_S)


func _esperar(condicao: bool, msg: String) -> void:
	if not condicao:
		_falhas.append(msg)


func _finalizar() -> void:
	if _falhas.is_empty():
		print("OK login-ponte")
		get_tree().quit(0)
	else:
		for falha in _falhas:
			push_error(falha)
		get_tree().quit(1)
