extends Node
## Valida duas coisas que faziam as 12 armas parecerem menos do que são:
##
## 1) O PROJÉTIL SABE QUAL ARMA O DISPAROU. Antes não sabia, e 7 das 12 armas
##    cuspiam a mesma bolinha amarela — a torre tinha silhueta própria (luneta,
##    tambor, leque) e o tiro não. O campo é SÓ desenho: nenhuma regra de dano
##    pode passar a depender dele.
##
## 2) O PORTÃO DAS LENDÁRIAS ABRE ANTES DA WAVE 100. A escolha de arma acontece
##    nas waves 1, 20, 40, 60, 80, 100 — com o portão em 100, metade do arsenal
##    existia no código e não na partida.

func _falha(msg: String) -> void:
	push_error("FALHA: " + msg)
	get_tree().quit(1)

func _ready() -> void:
	var torre_scr = load("res://scripts/torre.gd")
	var proj_scr  = load("res://scripts/projetil.gd")
	var fm_scr    = load("res://tests/fake_mob.gd")
	if torre_scr == null:
		_falha("torre.gd nao compilou"); return
	if proj_scr == null:
		_falha("projetil.gd nao compilou"); return

	var parent := Node2D.new()
	add_child(parent)
	var t = torre_scr.new()
	parent.add_child(t)
	t.mobs_group = "mobs"

	var mob = fm_scr.new()
	parent.add_child(mob)
	mob.global_position = Vector2(120.0, 0.0)

	# ── 1) A arma chega ao projétil ──────────────────────────────────────────
	# Armas de projétil teleguiado (_disparar_em) e de tiro reto (_disparar_direcao).
	for id in ["padrao", "sniper", "escopeta", "metralhadora", "ricochete"]:
		t.definir_arma(id as String)
		var antes : int = parent.get_child_count()
		t._disparar_em(mob)
		if parent.get_child_count() <= antes:
			_falha("arma '%s' nao disparou nada" % id); return
		var pj = parent.get_child(parent.get_child_count() - 1)
		if str(pj.get("arma")) != str(id):
			_falha("o projetil da '%s' se identificou como '%s' -- o desenho por arma nao chega" % [id, str(pj.get("arma"))])
			return

	t.definir_arma("vortice")
	var antes_dir : int = parent.get_child_count()
	t._disparar_direcao(Vector2.RIGHT)
	if parent.get_child_count() <= antes_dir:
		_falha("tiro reto nao spawnou projetil"); return
	var pj_dir = parent.get_child(parent.get_child_count() - 1)
	if str(pj_dir.get("arma")) != "vortice":
		_falha("no tiro reto a arma nao chega ao projetil"); return

	# ── 2) Nenhuma arma desenhada tem a cor de outra ─────────────────────────
	# Se duas coincidirem, elas voltam a parecer a mesma arma na tela — que é
	# exatamente o problema que este arquivo existe para impedir.
	var p = proj_scr.new()
	var cores : Dictionary = p._COR_ARMA
	if cores.size() < 5:
		_falha("quase nenhuma arma tem desenho proprio (%d)" % cores.size()); return
	var vistas : Array = []
	for id2 in cores.keys():
		var c : Color = cores[id2] as Color
		for outra in vistas:
			if (outra as Color).is_equal_approx(c):
				_falha("duas armas com a mesma cor de tiro (%s)" % str(id2)); return
		vistas.append(c)
		if c.is_equal_approx(p._COR_PADRAO):
			_falha("a arma '%s' ficou com a cor do tiro padrao" % str(id2)); return
	p.free()

	# ── 3) O portão das lendárias ────────────────────────────────────────────
	var portao : int = int(t.LENDARIA_WAVE)
	if portao >= 100:
		_falha("lendarias so' a partir da wave %d: a escolha da wave 100 e' a unica que as mostra" % portao)
		return
	if portao <= 20:
		_falha("portao em %d: as lendarias deixam de ser lendarias" % portao); return
	# A escolha de arma acontece de 20 em 20 — um portão fora dessa grade
	# adiaria as lendárias até a próxima escolha, sem ninguém perceber.
	if portao % 20 != 0:
		_falha("portao em %d nao cai numa wave de escolha (multiplo de 20)" % portao); return

	# E as comuns continuam desde o começo: sem isso a wave 1 ficaria sem arma.
	var tem_comum : bool = false
	for aid in t.ARMAS.keys():
		if str((t.ARMAS[aid] as Dictionary).get("tier", "comum")) == "comum":
			tem_comum = true
			break
	if not tem_comum:
		_falha("nenhuma arma comum: a escolha da wave 1 ficaria vazia"); return

	print("TESTE armas visual: OK (arma chega ao projetil + cores distintas + portao em %d)" % portao)
	get_tree().quit(0)
