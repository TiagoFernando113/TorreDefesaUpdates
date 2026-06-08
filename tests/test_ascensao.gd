extends SceneTree

var _falhas: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var salvar = root.get_node_or_null("Salvar")
	if salvar == null:
		_falhas.append("Autoload Salvar nao foi encontrado.")
		quit(1)
		return
	var snapshot := {
		"talentos": salvar.talentos.duplicate(true),
		"ascensoes": salvar.ascensoes,
		"ouro_banco": salvar.ouro_banco,
		"cristais": salvar.cristais,
		"pontos_atributo": salvar.pontos_atributo,
	}
	salvar.talentos.clear()
	salvar.ascensoes = 0
	salvar.ouro_banco = 0
	salvar.cristais = 0

	var ids: Array[String] = []
	for tid in salvar.TALENTOS_INFO.keys():
		var ts := str(tid)
		if ts != "raiz":
			ids.append(ts)

	for i in range(mini(20, ids.size())):
		salvar.talentos[ids[i]] = true
	_esperar(not salvar.pode_ascender(), "Ascensao deve exigir todos os talentos, nao apenas 20.")

	for tid in ids:
		salvar.talentos[tid] = true
	_esperar(salvar.has_method("ascensao_custo_moedas"), "Salvar deve expor ascensao_custo_moedas().")
	var custo := 1
	if salvar.has_method("ascensao_custo_moedas"):
		custo = int(salvar.ascensao_custo_moedas())
	_esperar(custo == 1, "Primeira Ascensao deve custar 1 Moeda Cytron.")
	_esperar(not salvar.pode_ascender(), "Ascensao deve exigir Moeda Cytron suficiente.")

	salvar.ouro_banco = custo
	_esperar(salvar.pode_ascender(), "Com arvore completa e moeda suficiente, deve poder ascender.")

	_esperar(salvar.has_method("bonus_ascensao_stats"), "Salvar deve expor bonus_ascensao_stats().")
	if salvar.has_method("bonus_ascensao_stats"):
		var bonus: Dictionary = salvar.bonus_ascensao_stats(1)
		_esperar(is_equal_approx(float(bonus.get("dano_mult", 0.0)), 1.01), "Uma Ascensao deve dar +1% dano.")
		_esperar(is_equal_approx(float(bonus.get("vida_mult", 0.0)), 1.01), "Uma Ascensao deve dar +1% vida.")
		_esperar(is_equal_approx(float(bonus.get("cadencia_mult", 0.0)), 1.005), "Uma Ascensao deve dar +0.5% cadencia.")
		_esperar(is_equal_approx(float(bonus.get("ouro_mult", -1.0)), 0.02), "Uma Ascensao deve dar +2% ouro.")
		_esperar(is_equal_approx(float(bonus.get("cristais_mult", 0.0)), 1.02), "Uma Ascensao deve dar +2% cristais.")
		_esperar(is_equal_approx(float(bonus.get("talento_desconto", -1.0)), 0.02), "Uma Ascensao deve dar -2% custo de talentos.")

	var ouro_antes: int = int(salvar.ouro_banco)
	salvar.ascender()
	_esperar(salvar.ascensoes == 1, "Ascender deve aumentar o nivel de Ascensao.")
	_esperar(salvar.talentos.is_empty(), "Ascender deve resetar os talentos.")
	_esperar(salvar.ouro_banco == ouro_antes - custo, "Ascender deve cobrar a Moeda Cytron.")

	salvar.talentos = (snapshot["talentos"] as Dictionary).duplicate(true)
	salvar.ascensoes = int(snapshot["ascensoes"])
	salvar.ouro_banco = int(snapshot["ouro_banco"])
	salvar.cristais = int(snapshot["cristais"])
	salvar.pontos_atributo = int(snapshot["pontos_atributo"])
	salvar._cloud_pendente = false
	salvar.salvar(false)

	if _falhas.is_empty():
		print("OK ascensao")
		quit(0)
	else:
		for falha in _falhas:
			push_error(falha)
		quit(1)


func _esperar(condicao: bool, msg: String) -> void:
	if not condicao:
		_falhas.append(msg)
