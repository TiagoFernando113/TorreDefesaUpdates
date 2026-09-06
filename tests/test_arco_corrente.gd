extends Node
## Valida o visual da Corrente Elétrica: o chain spawna um arco elétrico
## (antes invisível = "dano fantasma"). Respeita low_fx e gera a geometria.

func _falha(msg: String) -> void:
	push_error("FALHA: " + msg)
	get_tree().quit(1)

func _ready() -> void:
	var proj_scr = load("res://scripts/projetil.gd")
	var arc_scr  = load("res://scripts/partida/arco_eletrico.gd")
	if proj_scr == null:
		_falha("projetil.gd nao compilou"); return
	if arc_scr == null:
		_falha("arco_eletrico.gd nao compilou"); return

	var parent := Node2D.new()
	add_child(parent)
	var proj = proj_scr.new()
	parent.add_child(proj)
	proj.low_fx = false

	# 1) _spawn_arco_eletrico adiciona um nó visual ao pai
	var antes : int = parent.get_child_count()
	proj._spawn_arco_eletrico(Vector2(0, 0), Vector2(120, 40))
	if parent.get_child_count() <= antes:
		_falha("chain não spawnou o arco visual"); return

	# 2) low_fx pula o arco (performance)
	proj.low_fx = true
	var antes2 : int = parent.get_child_count()
	proj._spawn_arco_eletrico(Vector2(0, 0), Vector2(120, 40))
	if parent.get_child_count() != antes2:
		_falha("low_fx deveria pular o arco"); return

	# 3) o arco gera a geometria do raio (>= 2 pontos)
	var arc = arc_scr.new()
	add_child(arc)
	arc.iniciar(Vector2(0, 0), Vector2(80, 30))
	if arc._segs.size() < 2:
		_falha("arco não gerou segmentos do raio"); return

	print("TESTE arco-corrente: OK (chain visível + low_fx + geometria)")
	get_tree().quit(0)
