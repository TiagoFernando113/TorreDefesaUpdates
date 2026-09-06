extends Node
## Confirma que a vida do mini-chefe ficou numa faixa matável após o fix do
## multiplicador adaptativo (tank_soft). Imprime HP de cada tipo/wave.

func _ready() -> void:
	var mob_scr = load("res://scripts/mob.gd")
	if mob_scr == null:
		push_error("FALHA: mob.gd nao compilou"); get_tree().quit(1); return

	var casos := [
		["normal", 10], ["elite", 10], ["colossus", 10],
		["normal", 20], ["elite", 20], ["colossus", 20],
		["colossus", 30],
	]
	for caso in casos:
		var m = mob_scr.new()
		m.tipo     = caso[0]
		m.wave_num = caso[1]
		m.is_chefe = true
		add_child(m)
		print("CHEFE %-9s wave %2d -> HP %6d" % [str(caso[0]), int(caso[1]), int(m.max_hp)])
		m.queue_free()

	# Sanidade: colossus-chefe na wave 10 nao pode mais beirar 30k.
	var c10 = mob_scr.new()
	c10.tipo = "colossus"; c10.wave_num = 10; c10.is_chefe = true
	add_child(c10)
	if c10.max_hp > 8000.0:
		push_error("FALHA: colossus-chefe wave 10 ainda tanky demais: %d" % int(c10.max_hp))
		get_tree().quit(1); return
	c10.queue_free()

	print("TESTE mob-chefe: OK")
	get_tree().quit(0)
