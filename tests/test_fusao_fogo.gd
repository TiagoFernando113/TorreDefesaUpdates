extends Node
## Valida a FUSÃO Bolas de Fogo: 5x Brasa + Ricochete ativa fogo_fusao na torre.

func _ready() -> void:
	var torre_scr = load("res://scripts/torre.gd")
	if torre_scr == null:
		push_error("FALHA: torre.gd nao compilou")
		get_tree().quit(1)
		return
	var t = torre_scr.new()
	add_child(t)

	# Aplica 4 Brasa: ainda sem fusão
	for i in 4:
		t.aplicar_carta("brasa", 1.0)
	if t.fogo_fusao:
		push_error("FALHA: fusao ligou cedo demais (4 brasa, sem ricochete)")
		get_tree().quit(1)
		return

	# 5a Brasa, ainda sem arma Ricochete: sem fusão
	t.aplicar_carta("brasa", 1.0)
	if t.fogo_fusao:
		push_error("FALHA: fusao ligou sem a arma Ricochete")
		get_tree().quit(1)
		return

	# Adiciona Ricochete: agora fundem
	t.aplicar_carta("ricochete", 1.0)
	if not t.fogo_fusao:
		push_error("FALHA: 5 brasa + ricochete NAO ativou fogo_fusao")
		get_tree().quit(1)
		return

	# Sanidade: brasa_count cap em 5, ricochete cap em 4
	if t.brasa_count != 5:
		push_error("FALHA: brasa_count = %d (esperado 5)" % t.brasa_count)
		get_tree().quit(1)
		return

	# main.gd compila com a identidade da fusao
	if load("res://scripts/main.gd") == null or load("res://scripts/projetil.gd") == null:
		push_error("FALHA: main.gd/projetil.gd nao compilaram")
		get_tree().quit(1)
		return

	# ── Armas ────────────────────────────────────────────────────────────────
	var t2 = torre_scr.new()
	add_child(t2)
	if t2.arma_ativa != "padrao":
		push_error("FALHA: arma inicial deveria ser padrao")
		get_tree().quit(1)
		return
	# Sniper: cadência baixa, dano alto, alcance longo
	t2.definir_arma("sniper")
	if t2.arma_ativa != "sniper" or t2._arma_mult("dano") < 2.0 or t2._arma_mult("cad") > 0.5:
		push_error("FALHA: multiplicadores da sniper errados")
		get_tree().quit(1)
		return
	# Saltitante define ricochete embutido → checa fusão com brasa
	t2.definir_arma("saltitante")
	for i in 5:
		t2.aplicar_carta("brasa", 1.0)
	if not t2.fogo_fusao:
		push_error("FALHA: 5 brasa + arma saltitante NAO fundiu")
		get_tree().quit(1)
		return
	# Arma inválida não muda nada
	t2.definir_arma("inexistente")
	if t2.arma_ativa != "saltitante":
		push_error("FALHA: arma invalida nao deveria trocar")
		get_tree().quit(1)
		return

	print("TESTE fusao-fogo: OK (fusão + armas)")
	get_tree().quit(0)
