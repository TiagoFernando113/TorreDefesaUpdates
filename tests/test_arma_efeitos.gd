extends Node
## Valida que o PIPELINE de dano compartilhado (_calc_dano_arma + _ferir_mob),
## usado pelas armas de AoE/feixe novas, herda: crítico, veneno (DoT), Armadura
## Invertida e queimadura. Antes essas armas ignoravam cartas/talentos.

func _falha(msg: String) -> void:
	push_error("FALHA: " + msg)
	get_tree().quit(1)

func _ready() -> void:
	var torre_scr = load("res://scripts/torre.gd")
	var fm_scr    = load("res://tests/fake_mob.gd")
	if torre_scr == null:
		_falha("torre.gd nao compilou"); return
	var t = torre_scr.new()
	add_child(t)

	# 1) _calc_dano_arma aplica crítico (chance 100%)
	t.crit_chance = 1.0
	t.crit_mult   = 3.0
	var res : Array = t._calc_dano_arma(null)
	if not bool(res[1]):
		_falha("crit_chance 1.0 deveria sempre critar no pipeline"); return
	if float(res[0]) <= t.damage:
		_falha("crit deveria multiplicar o dano (>%.1f)" % t.damage); return

	# 2) _ferir_mob aplica dano + crit + veneno (DoT herdado)
	t.veneno_dps = 8.0
	var mob = fm_scr.new(); add_child(mob)
	t._ferir_mob(mob, 50.0, true, false)
	if mob.recebeu <= 0.0:
		_falha("_ferir_mob não aplicou dano"); return
	if not mob.ultimo_crit:
		_falha("_ferir_mob não propagou o crit"); return
	if float(mob.veneno_dps) <= 0.0:
		_falha("veneno (DoT) não foi aplicado pelas armas novas"); return

	# 3) Armadura Invertida: +60% em alvo com <30% HP
	t.armadura_inv = true
	var mob2 = fm_scr.new(); add_child(mob2)
	mob2.max_hp = 100.0; mob2.hp = 20.0   # 20% HP → bônus
	var antes : float = mob2.recebeu
	t._ferir_mob(mob2, 100.0, false, false)
	if mob2.recebeu <= antes + 100.0:   # deve ser 160, não 100
		_falha("Armadura Invertida não aplicou +60%% em alvo <30%% HP"); return

	print("TESTE arma-efeitos: OK (crit/veneno/armadura herdados pelas armas novas)")
	get_tree().quit(0)
