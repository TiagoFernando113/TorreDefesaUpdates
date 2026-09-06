extends Node

var _falhas: Array[String] = []

const MAIN_SCRIPT := preload("res://scripts/main.gd")
const MOB_SCRIPT := preload("res://scripts/mob.gd")
const CONTROLE_HORDA := [
	"atirador", "curandeiro", "invocador", "bruxo", "suporte",
	"escudeiro", "ancora", "regenerador", "necromante"
]
const MOB_KEYS := [
	"normal", "fast", "tank", "elite", "berserker", "colossus",
	"atirador", "curandeiro", "invocador", "bruxo", "suporte",
	"escudeiro", "fantasma", "vampiro", "espelho", "ladrao", "ancora",
	"regenerador", "divididor", "kamikaze", "blindado", "necromante"
]


func _ready() -> void:
	call_deferred("_run")


func _run() -> void:
	var salvar = get_node_or_null("/root/Salvar")
	if salvar == null:
		_falhas.append("Autoload Salvar nao foi encontrado.")
		_finalizar()
		return

	_test_wave_config_tem_mais_horda_e_menos_controle()
	_test_spawn_sustenta_20_mobs_na_tela()
	_test_mapas_priorizam_quantidade_antes_de_hp(salvar)
	await _test_hp_da_wave_escala_com_freio()
	_finalizar()


func _test_wave_config_tem_mais_horda_e_menos_controle() -> void:
	var game = MAIN_SCRIPT.new()
	var cfg: Dictionary = game.call("_get_wave_config", 50)
	var total := _total_mobs(cfg)
	var controle := _total_chaves(cfg, CONTROLE_HORDA)
	_esperar(total >= 220, "Wave 50 deve focar em horda: esperado pelo menos 220 mobs base.")
	_esperar(float(controle) / maxf(1.0, float(total)) <= 0.16, "Mobs de cura/escudo/debuff devem ficar abaixo de 16% da wave base.")
	game.free()


func _test_spawn_sustenta_20_mobs_na_tela() -> void:
	var game = MAIN_SCRIPT.new()
	game.wave = 50
	game.spawn_intervalo = 0.24
	_esperar(game.has_method("_horda_alvo_tela"), "Main deve expor meta de mobs ativos da horda.")
	_esperar(game.has_method("_horda_lote_spawn"), "Main deve calcular lote de spawn para preencher a tela.")
	_esperar(game.has_method("_horda_spawn_intervalo_atual"), "Main deve acelerar spawn quando a tela esta vazia.")
	if game.has_method("_horda_alvo_tela") and game.has_method("_horda_lote_spawn") and game.has_method("_horda_spawn_intervalo_atual"):
		_esperar(int(game.call("_horda_alvo_tela")) >= 22, "Wave 50 deve mirar 20+ mobs simultaneos.")
		_esperar(int(game.call("_horda_lote_spawn", 0, 120, 185)) >= 5, "Tela vazia deve receber lote grande de mobs.")
		_esperar(int(game.call("_horda_lote_spawn", 19, 120, 185)) >= 3, "Abaixo de 20 mobs ainda deve preencher em lote.")
		_esperar(float(game.call("_horda_spawn_intervalo_atual", 0)) <= 0.14, "Spawn deve acelerar quando houver poucos mobs na tela.")
	game.free()


func _test_mapas_priorizam_quantidade_antes_de_hp(salvar) -> void:
	var mapa_4: Dictionary = salvar.mapa_por_wave(180)
	var mapa_6: Dictionary = salvar.mapa_por_wave(300)
	_esperar(float(mapa_4.get("mob_mult", 0.0)) >= 1.80, "Mapa 4 deve subir mais quantidade de mobs.")
	_esperar(float(mapa_4.get("hp_mult", 99.0)) <= 1.32, "Mapa 4 deve frear multiplicador de HP.")
	_esperar(float(mapa_6.get("mob_mult", 0.0)) >= 2.10, "Mapa 6 deve sustentar hordas grandes.")
	_esperar(float(mapa_6.get("hp_mult", 99.0)) <= 1.50, "Mapa 6 deve manter HP controlado mesmo em late game.")


func _test_hp_da_wave_escala_com_freio() -> void:
	var mob = MOB_SCRIPT.new()
	mob.tipo = "normal"
	mob.wave_num = 50
	add_child(mob)
	await get_tree().process_frame
	# O teto era 240, escrito no commit inicial (08/06). Quatro dias depois, o
	# commit cd01f64 -- "balance: curva facil ate w15, pesada 15-100" -- trocou
	# a escala de proposito, e o comentario dentro do mob.gd diz por que:
	# "builds full precisam sentir pressao". O teste ficou para tras e passou a
	# reprovar uma decisao tomada de olho aberto.
	#
	# A faixa agora guarda ESSA decisao em vez de opinar contra ela. E' uma
	# faixa, e nao o valor exato de hoje (288), porque teste preso no numero
	# exato quebra em qualquer ajuste fino e vira barulho. Larga o bastante para
	# afinar, apertada o bastante para pegar escala disparada.
	#
	# A curva medida com este mob.gd:
	#   wave 1 = 12   wave 10 = 54   wave 25 = 119   wave 50 = 288   wave 100 = 780
	_esperar(mob.max_hp >= 130.0, "Wave 50 ainda deve subir HP acima do mob inicial.")
	_esperar(mob.max_hp <= 350.0,
		"Wave 50 passou de 350 de HP: a rampa de 15-100 disparou (era ~288 quando foi calibrada).")
	mob.queue_free()

	var escudeiro = MOB_SCRIPT.new()
	escudeiro.tipo = "escudeiro"
	escudeiro.wave_num = 100
	add_child(escudeiro)
	await get_tree().process_frame
	_esperar(float(escudeiro.escudo_arm_max) <= 430.0, "Escudeiro nao deve escalar escudo demais em ondas grandes.")
	escudeiro.queue_free()


func _total_mobs(cfg: Dictionary) -> int:
	return _total_chaves(cfg, MOB_KEYS)


func _total_chaves(cfg: Dictionary, keys: Array) -> int:
	var total := 0
	for key in keys:
		total += int(cfg.get(key, 0))
	return total


func _esperar(condicao: bool, msg: String) -> void:
	if not condicao:
		_falhas.append(msg)


func _finalizar() -> void:
	if _falhas.is_empty():
		print("OK hordas balance")
		get_tree().quit(0)
	else:
		for falha in _falhas:
			push_error(falha)
		get_tree().quit(1)
