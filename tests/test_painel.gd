extends Node
## Valida o MÓDULO isolado scripts/partida/painel_comando.gd:
## upar gasta Energia ⚡, aplica % do base no torre, escala custo, respeita cap
## por trilha, nega sem energia, serializa/restaura. + baralho só especialidade.

var torre = null      # o módulo lê jogo.torre
var ui_node = null    # o módulo lê jogo.ui_node (null = sem UI, só lógica)

func _falha(msg: String) -> void:
	push_error("FALHA: " + msg)
	get_tree().quit(1)

func _ready() -> void:
	var mod_scr = load("res://scripts/partida/painel_comando.gd")
	if mod_scr == null:
		_falha("painel_comando.gd nao compilou"); return
	var torre_scr = load("res://scripts/torre.gd")
	var t = torre_scr.new()
	add_child(t)
	torre = t
	var p = mod_scr.new(self)   # self = fake jogo (torre + ui_node)
	# ganhar_energia acumula sobre a energia inicial
	var e0 : int = p.energia()
	p.ganhar_energia(1000)
	if p.energia() != e0 + 1000:
		_falha("ganhar_energia nao acumulou"); return
	# Energia alta p/ testar os upgrades
	p._energia = 500000

	var dano0 : float = t.damage
	var custo1 : int = p.custo("dano")
	if custo1 <= 0:
		_falha("custo inicial deveria ser > 0"); return

	# 1) Upar Dano: nível sobe, energia cai, dano sobe, % = 1
	if not p.upar("dano"):
		_falha("upar(dano) deveria suceder"); return
	if p.nivel("dano") != 1:
		_falha("nível dano deveria ser 1, veio %d" % p.nivel("dano")); return
	if p.energia() != 500000 - custo1:
		_falha("energia não debitou (esperado %d, veio %d)" % [500000 - custo1, p.energia()]); return
	if t.damage <= dano0:
		_falha("torre.damage não subiu"); return
	if int(p.pct_total("dano")) != 5:
		_falha("pct_total(dano) deveria ser 5%% (nv1 x 5%%), veio %d" % int(p.pct_total("dano"))); return

	# 2) Custo escala (linear)
	if p.custo("dano") <= custo1:
		_falha("custo não escalou"); return

	# 3) Vida e Regen são SEPARADOS: Vida sobe max_hp e NÃO mexe no regen
	var maxhp0 : float = float(t.get("max_hp"))
	var regen0 : float = float(t.get("regen_rate"))
	if not p.upar("vida"):
		_falha("upar(vida) falhou"); return
	if float(t.get("max_hp")) <= maxhp0:
		_falha("upar vida deveria aumentar max_hp"); return
	if not is_equal_approx(float(t.get("regen_rate")), regen0):
		_falha("upar vida NÃO deveria mexer no regen (trilhas distintas)"); return
	# Regen (trilha própria) sobe regen_rate
	if not p.upar("regen"):
		_falha("upar(regen) falhou"); return
	if float(t.get("regen_rate")) <= regen0:
		_falha("upar regen deveria aumentar regen_rate"); return

	# 3b) Crit: chance e multiplicador aplicam no torre
	var cc0 : float = float(t.get("crit_chance"))
	var cm0 : float = float(t.get("crit_mult"))
	if not p.upar("crit"):
		_falha("upar(crit) falhou"); return
	if float(t.get("crit_chance")) <= cc0:
		_falha("upar crit não aumentou crit_chance"); return
	if not p.upar("critdano"):
		_falha("upar(critdano) falhou"); return
	if float(t.get("crit_mult")) <= cm0:
		_falha("upar critdano não aumentou crit_mult"); return

	# 4) Serializa/restaura mantém níveis e energia
	var snap : Dictionary = p.serializar()
	var p2 = mod_scr.new(self)
	p2.restaurar(snap)
	if p2.nivel("dano") != 1 or p2.energia() != p.energia():
		_falha("serializar/restaurar perdeu estado"); return

	# 5) Cap por trilha (dano = 200): leva ao cap, além disso nega
	var cap_dano : int = p.cap("dano")
	if cap_dano != 120:
		_falha("cap dano deveria ser 120, veio %d" % cap_dano); return
	while p.nivel("dano") < cap_dano:
		if not p.upar("dano"):
			_falha("upar dano falhou antes do cap (nível %d)" % p.nivel("dano")); return
	if p.upar("dano"):
		_falha("upar além do cap deveria negar"); return

	# 6) Sem energia: nega
	var p3 = mod_scr.new(self)
	p3._energia = 0
	if p3.upar("cadencia"):
		_falha("upar sem energia deveria negar"); return

	# 6b) Trilha "energia": aumenta o GANHO de energia
	var pe = mod_scr.new(self)
	pe._energia = 0
	pe.ganhar_energia(1000)
	var ganho0 : int = pe.energia()          # nível 0 = ganho cheio (1000)
	pe._energia = 100000
	for _k in range(5): pe.upar("energia")    # +5 níveis
	pe._energia = 0
	pe.ganhar_energia(1000)
	if pe.energia() <= ganho0:
		_falha("trilha energia deveria aumentar o ganho de energia"); return

	# 7) Baralho do main: sem cartas de stat puro
	var main_scr = load("res://scripts/main.gd")
	var m = main_scr.new()
	var stat_efeitos := ["dano", "cadencia", "vida", "alcance", "speed", "regen"]
	var tem_wave1 := false
	for carta in m.CARTAS:
		var ef : String = str((carta as Dictionary).get("efeito", ""))
		if ef in stat_efeitos:
			_falha("carta de stat no baralho: %s" % [(carta as Dictionary).get("id")]); return
		if int((carta as Dictionary).get("min_wave", 99)) <= 1:
			tem_wave1 = true
	if not tem_wave1:
		_falha("nenhuma carta na wave 1"); return

	print("TESTE painel: OK (módulo isolado: energia/%/escala/regen/serial/cap/sem-energia + baralho)")
	get_tree().quit(0)
