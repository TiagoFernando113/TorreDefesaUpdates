extends Node
## Valida a arma Bombardeio Orbital + o módulo raio_orbital: lancar spawna o
## raio e respeita cooldown, a explosão aplica dano em ÁREA (acerta dentro do
## raio, erra fora), e a MIRA AUTOMÁTICA cobre o jogador que não está tocando
## na tela — sem roubar o tiro de quem está.

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

	# 5) MIRA AUTOMÁTICA. A arma era 100% manual: sem toque, a torre não atirava.
	#    Quem escolhia sem perceber ficava sem torre a wave inteira.
	t.mobs_group = "mobs"
	# Entre a zona morta (150) e o alcance da torre (220): é a faixa onde a mira
	# automática pode trabalhar.
	var longe := Vector2(180.0, 0.0)
	for i in range(3):
		var m = fm_scr.new(); add_child(m)
		m.global_position = longe + Vector2(float(i) * 15.0, 0.0)

	# 5a) Logo após um toque, a torre NÃO assume — o tiro é de quem está mirando.
	t.bombardeio_cd = 0.0
	t.lancar_bombardeio(Vector2(400.0, 400.0))   # abre a janela manual
	t.bombardeio_cd = 0.0
	var antes_auto : int = parent.get_child_count()
	t._bombardeio_automatico()
	if parent.get_child_count() != antes_auto:
		_falha("a torre roubou o tiro de quem estava mirando"); return

	# 5b) Passada a janela sem toque, a torre assume sozinha.
	t._bombardeio_manual = 0.0
	t.bombardeio_cd = 0.0
	t._bombardeio_automatico()
	if parent.get_child_count() <= antes_auto:
		_falha("sem toque do jogador, a torre continuou sem atirar"); return
	var ro_auto = parent.get_child(parent.get_child_count() - 1)

	# 5c) Mirar você mesmo continua valendo mais que deixar a torre mirar.
	t._bombardeio_manual = 0.0
	t.bombardeio_cd = 0.0
	t.lancar_bombardeio(longe)
	var ro_mirado = parent.get_child(parent.get_child_count() - 1)
	if float(ro_auto.dano) >= float(ro_mirado.dano):
		_falha("o tiro automático deveria ser mais fraco que o mirado"); return

	# 5d) O ponto escolhido cai onde estão os mobs, não em cima da torre.
	var alvo : Vector2 = t._melhor_ponto_bombardeio()
	if not alvo.is_finite():
		_falha("com mobs alcançáveis, deveria achar um ponto"); return
	if alvo.distance_to(t.global_position) < t.BOMBARDEIO_MIN_DIST:
		_falha("mirou dentro da zona morta, onde o raio sai fraco"); return

	# 5e) A mira automática está LIGADA no _atirar(). Sem isto, a função acima
	#     pode estar perfeita e nunca ser chamada — que é como a arma ficou
	#     100% manual em primeiro lugar.
	t._bombardeio_manual = 0.0
	t.bombardeio_cd = 0.0
	t.target = get_tree().get_nodes_in_group("mobs")[0]
	var antes_atirar : int = parent.get_child_count()
	t._atirar()
	if parent.get_child_count() <= antes_atirar:
		_falha("_atirar() com bombardeio nao lancou nada -- a mira automatica esta' desligada"); return

	# 5f) Sem ninguém alcançável, não gasta o cooldown à toa.
	for m2 in get_tree().get_nodes_in_group("mobs"):
		m2.queue_free()
	await get_tree().process_frame
	if t._melhor_ponto_bombardeio().is_finite():
		_falha("sem mobs, não deveria haver ponto para bombardear"); return

	print("TESTE bombardeio: OK (spawn + cooldown + AoE + mira automática)")
	get_tree().quit(0)
