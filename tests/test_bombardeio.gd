extends Node
## Valida a arma Bombardeio Orbital (manual) + o módulo raio_orbital:
## arma existe e é manual (sem auto-fire), lancar spawna o raio + respeita
## cooldown, e a explosão aplica dano em ÁREA (acerta dentro do raio, erra fora).

func _falha(msg: String) -> void:
	push_error("FALHA: " + msg)
	get_tree().quit(1)

func _ready() -> void:
	var torre_scr = load("res://scripts/torre.gd")
	var ro_scr    = load("res://scripts/partida/raio_orbital.gd")
	var fm_scr    = load("res://tests/fake_mob.gd")
	if torre_scr == null:
		_falha("torre.gd nao compilou"); return
	if ro_scr == null:
		_falha("raio_orbital.gd nao compilou"); return

	var parent := Node2D.new()
	add_child(parent)
	var t = torre_scr.new()
	parent.add_child(t)

	# 1) Arma existe e é lendária
	if not t.ARMAS.has("bombardeio"):
		_falha("arma bombardeio ausente"); return
	t.definir_arma("bombardeio")
	if t._arma_modo() != "bombardeio":
		_falha("modo deveria ser bombardeio"); return

	# 2) lancar_bombardeio spawna o raio + seta cooldown
	var antes : int = parent.get_child_count()
	if not t.lancar_bombardeio(Vector2(200, 200)):
		_falha("lancar_bombardeio falhou"); return
	if parent.get_child_count() <= antes:
		_falha("raio orbital não spawnou"); return
	if t.bombardeio_cd <= 0.0:
		_falha("cooldown não setou"); return

	# 3) Segundo disparo no cooldown é bloqueado
	if t.lancar_bombardeio(Vector2(0, 0)):
		_falha("deveria bloquear no cooldown"); return

	# 3b) Perto da torre = MINI RAIO (dispara, mas dano reduzido — não bloqueia)
	t.bombardeio_cd = 0.0
	if not t.lancar_bombardeio(Vector2(40, 40)):
		_falha("mini raio (perto) deveria disparar"); return
	var ro_mini = parent.get_child(parent.get_child_count() - 1)
	t.bombardeio_cd = 0.0
	if not t.lancar_bombardeio(Vector2(400, 400)):
		_falha("disparo longe deveria suceder"); return
	var ro_full = parent.get_child(parent.get_child_count() - 1)
	if float(ro_mini.dano) >= float(ro_full.dano):
		_falha("mini raio deveria ter dano MENOR que o normal"); return
	if not ro_mini._mini:
		_falha("disparo perto deveria ser marcado como mini"); return

	# 4) Explosão AoE: acerta mob dentro do raio, erra fora
	var ponto := Vector2(500.0, 500.0)
	var dentro = fm_scr.new(); add_child(dentro); dentro.global_position = ponto + Vector2(60, 0)
	var fora   = fm_scr.new(); add_child(fora);   fora.global_position   = ponto + Vector2(400, 0)
	var ro = ro_scr.new(); add_child(ro)
	ro.iniciar(ponto, 100.0, 110.0, "mobs")
	ro._explodir()
	if dentro.recebeu <= 0.0:
		_falha("mob dentro do raio não tomou dano"); return
	if fora.recebeu != 0.0:
		_falha("mob fora do raio tomou dano (AoE vazou)"); return

	print("TESTE bombardeio: OK (arma manual + spawn + cooldown + AoE)")
	get_tree().quit(0)
