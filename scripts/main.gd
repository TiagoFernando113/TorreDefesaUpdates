extends Node2D

const TORRE_SCENE = preload("res://scenes/Torre.tscn")
const MOB_SCENE   = preload("res://scenes/Mob.tscn")

# Configuração das waves: [qtd_normal, qtd_fast, qtd_tank, intervalo_spawn]

var pet_assistente = null   # referência ao IA Assistente (null se não comprado)
var wave   := 0
var score  := 0
var gold   : int = 0
var estado := "jogando"   # jogando | cartas | game_over

var gold_mult_carta  : float = 1.0
var score_mult_skin  : float = 1.0   # bônus de score da skin equipada
var token_disponivel : bool  = false
var saque_bonus      : float = 0.0   # Saque em Massa: % do score da wave como ouro
var wave_score       : int   = 0     # Score acumulado na wave atual
var mobs_mortos      : int   = 0     # Total de mobs eliminados na partida
var mobs_na_wave     : int   = 0     # Total de mobs spawnados na wave atual
var mobs_mortos_wave : int   = 0     # Kills nesta wave (para o contador do HUD)
var cacador_fantasma : bool  = false # Caçador de Fantasmas: revela fantasmas rapidamente
var dano_causado_total  : float = 0.0  # Dano total causado pela torre nesta partida
var dano_recebido_total : float = 0.0  # Dano total recebido pela torre nesta partida
# S5 — Metamorfose
var _s5_kills_veneno : int  = 0
var _s5_carta_bonus  : bool = false

# T4 — Retrocesso Temporal
var _t4_usado        : bool  = false
var _t4_hp_inicio    : float = 0.0

# B3 — Pilhagem Bárbara: ouro duplo com <30% HP
# (verificado em mob_morreu)

# Exter — Exterminador: 3 kills em 1s = próximos 3 kills valem 2×
var _exter_kills_rapidos : int   = 0
var _exter_kills_timer   : float = 0.0
var _exter_bonus_left    : int   = 0

# Teto de velocidade — reduz de 3.0→1.5 entre waves 35-45 (imperceptível)
var _vel_cap : float = 3.0

# X4 — Carta do Acaso
var _x4_carta_pendente : bool = false
var _x4_usado_wave     : bool = false
var _x4_total_partida  : int  = 0   # máx 4 ativações por partida

# Wave modifier
var wave_mod_atual   : String = ""   # "", "furia", "densa", "elite", "blindada"
var mapa_atual_info  : Dictionary = {}
var _mapa_texture_cache : Dictionary = {}

# Screen shake
var _shake_timer     : float = 0.0
var _shake_intensity : float = 0.0
var _impactos_combate : Array = []
var _dano_visual_last_ms : int = -1000000
var _impacto_visual_last_ms : int = -1000000


# ── Boss Dante ────────────────────────────────────────────────────────────────
var _dante_boss : Node = null
var _dante_boss_encerrado : bool = false
const BOSS_TORRE_START := Vector2(300.0, 360.0)
const BOSS_TORRE_LIMIT := Rect2(10.0, 44.0, 760.0, 638.0)
const BOSS_TORRE_SPEED : float = 285.0
const BOSS_JOY_BASE    := Vector2(112.0, 608.0)
const BOSS_JOY_RADIUS  : float = 62.0
var _boss_joy_active : bool = false
var _boss_joy_index  : int = -1
var _boss_joy_vec    : Vector2 = Vector2.ZERO

# ── Sistema de Alma ───────────────────────────────────────────────────────────
var _alma_usado            : bool = false
var _revive_loja_usado     : bool = false
var _game_over_confirmado  : bool = false

# ── Consumíveis ───────────────────────────────────────────────────────────────
var _cristal_barreira_ativo : bool  = false  # escudo passivo
var _runa_furia_ativo       : bool  = false
var _runa_furia_waves       : int   = 0      # waves restantes com bônus
var _runa_furia_usado       : bool  = false  # 1 uso por partida

# ── Habilidade Ativa ─────────────────────────────────────────────────────────
const HABIL_CD_MAX : float = 45.0
var _habil_cds     : Dictionary = {}       # id → cooldown restante (individual)
var _habil_visual  : Dictionary = {}       # {"cor":Color, "raio":float, "alpha":float, "timer":float}
var habil_effect_mult : float = 1.0
var _arsenal_boss_escudo : bool = false

# ── Modo Abismo ───────────────────────────────────────────────────────────────
var modo_abismo    : bool  = false
var _abismo_multi  : float = 1.0  # multiplicador de stats dos mobs
var arena_ouro_inicio : int = 0
var _cartas_escolhidas_jogador : Array = []

# ── Identidade de Build ───────────────────────────────────────────────────────
var _build_nome : String = ""

# ── Mini-eventos durante wave ─────────────────────────────────────────────────
const EVENTOS_WAVE : Array = [
	{"id":"suprimento", "texto":"SUPRIMENTO CAINDO!", "sub":"Colete ouro extra",    "cor":Color(1.0, 0.82, 0.10), "dur":9.0},
	{"id":"artilharia", "texto":"ARTILHARIA PRONTA!", "sub":"Dispare na horda",     "cor":Color(1.0, 0.40, 0.10), "dur":8.0},
	{"id":"reforco",    "texto":"REFORÇO DISPONÍVEL!","sub":"Ative +40% ataque 10s","cor":Color(0.25, 1.0, 0.50), "dur":8.0},
	{"id":"espiao",     "texto":"ESPIÃO DETECTADO!",  "sub":"Neutralize a tempo",   "cor":Color(1.0, 0.30, 0.70), "dur":7.0},
]
var _evento_ativo   : Dictionary = {}
var _evento_timer   : float      = 0.0
var _evento_delay   : float      = 999.0  # tempo até primeiro evento da wave
var _eventos_wave_n : int        = 0      # eventos disparados nesta wave
var _evento_pos     : Vector2    = Vector2.ZERO  # posição do baú no mapa

# ── Focus de Ataque (hold contínuo) ──────────────────────────────────────────
var _focus_mouse_hold : bool = false   # botão esquerdo seguro
var _focus_touch_idx  : int  = -1     # índice do dedo fazendo mira

# Contagem de cartas para o sistema de fusão (futuro)
# Quando pierce_cartas >= 5 e dano_cartas >= 5 → fusão "Raio"
var _cartas_colhidas : Dictionary = {}   # {"pierce": 2, "dano": 3, ...}

# raridade: "comum"(8) | "incomum"(4) | "raro"(2) | "epico"(1)
# peso: probabilidade relativa no pool
# min_wave: wave mínima para aparecer
# max_picks: máximo de vezes escolhível por partida (talentos podem +1)
const CARTAS := [
	{"id":"dano_m", "nome":"Força Bruta",        "desc":"+25 de dano\nnesta partida",           "cor":Color(1.0, 0.42, 0.1),  "efeito":"dano",    "val":25.0,  "raridade":"comum",   "peso":8, "min_wave":1,  "max_picks":6},
	{"id":"dano_g", "nome":"Canhão de Obsidiana","desc":"+50 de dano\nnesta partida",           "cor":Color(1.0, 0.58, 0.0),  "efeito":"dano",    "val":50.0,  "raridade":"incomum", "peso":4, "min_wave":4,  "max_picks":4},
	{"id":"cad_m",  "nome":"Ritmo Acelerado",    "desc":"+0.5 tiros/s\nnesta partida",          "cor":Color(0.75,0.2,  1.0),  "efeito":"cadencia","val":0.5,   "raridade":"comum",   "peso":8, "min_wave":1,  "max_picks":6},
	{"id":"cad_g",  "nome":"Metralhadora",       "desc":"+1.0 tiro/s\nnesta partida",           "cor":Color(0.9, 0.3,  1.0),  "efeito":"cadencia","val":1.0,   "raridade":"raro",    "peso":2, "min_wave":7,  "max_picks":3},
	{"id":"range_m","nome":"Visão Ampla",        "desc":"+60 de alcance\nnesta partida",        "cor":Color(0.12,0.62, 1.0),  "efeito":"alcance", "val":60.0,  "raridade":"comum",   "peso":8, "min_wave":1,  "max_picks":4},
	{"id":"range_g","nome":"Olho de Deus",       "desc":"+120 de alcance\nnesta partida",       "cor":Color(0.2, 0.80, 1.0),  "efeito":"alcance", "val":120.0, "raridade":"raro",    "peso":2, "min_wave":6,  "max_picks":3},
	{"id":"vida_m", "nome":"Couraça",            "desc":"Cura 60 HP\ne +40 vida máxima",        "cor":Color(0.12,1.0,  0.45), "efeito":"vida",    "val":40.0,  "raridade":"comum",   "peso":8, "min_wave":1,  "max_picks":5},
	{"id":"vida_g", "nome":"Fortaleza",          "desc":"Cura 120 HP\ne +80 vida máxima",       "cor":Color(0.1, 0.9,  0.4),  "efeito":"vida",    "val":80.0,  "raridade":"incomum", "peso":4, "min_wave":5,  "max_picks":3},
	{"id":"pierce", "nome":"Bala Perfurante",    "desc":"Projéteis perfuram\n+1 inimigo",       "cor":Color(1.0, 0.88, 0.12), "efeito":"pierce",  "val":1.0,   "raridade":"raro",    "peso":2, "min_wave":7,  "max_picks":3},
	{"id":"multi",  "nome":"Canhão Duplo",       "desc":"Cria um canhão orbital\nque atira em paralelo","cor":Color(0.12,1.0,0.88),"efeito":"multi","val":1.0,  "raridade":"epico",   "peso":1, "min_wave":12, "max_picks":2},
	{"id":"vel",    "nome":"Projétil Sônico",    "desc":"+260 velocidade\nde projétil",         "cor":Color(0.95,0.95,0.12),  "efeito":"speed",   "val":260.0, "raridade":"incomum", "peso":3, "min_wave":4,  "max_picks":2},
	{"id":"regen",  "nome":"Regeneração",        "desc":"+4 HP/s de\nregeneração",             "cor":Color(0.4, 1.0,  0.55), "efeito":"regen",   "val":4.0,   "raridade":"incomum", "peso":5, "min_wave":3,  "max_picks":4},
	{"id":"escudo", "nome":"Escudo Arcano",      "desc":"-20% dano\nrecebido",                 "cor":Color(0.2, 0.6,  1.0),  "efeito":"reducao", "val":0.20,  "raridade":"raro",    "peso":2, "min_wave":9,  "max_picks":1},
	{"id":"ouro",      "nome":"Toque de Midas",     "desc":"+40% de ouro\nem cada kill",                  "cor":Color(1.0, 0.82, 0.1),  "efeito":"ouro",       "val":0.40,  "raridade":"raro",    "peso":2, "min_wave":7,  "max_picks":3},
	{"id":"fragmento",  "nome":"Fragmento Arcano",    "desc":"Pierce explode em 60px\n(+25% dano de área)",             "cor":Color(1.0, 0.65, 0.0),  "efeito":"fragmento",  "val":0.25, "raridade":"epico",   "peso":1, "min_wave":10, "max_picks":3},
	# ── Novas cartas ────────────────────────────────────────────────────────────
	{"id":"raio",       "nome":"Raio Arcano",         "desc":"Golpeia inimigo aleatório\na cada ~4s (+45 dano/nv)",    "cor":Color(0.40, 0.72, 1.0), "efeito":"raio",       "val":1.0,  "raridade":"epico",   "peso":1, "min_wave":15, "max_picks":5},
	{"id":"corrente",   "nome":"Corrente Elétrica",   "desc":"Projéteis saltam para\n2 inimigos extras (sem redução)","cor":Color(0.25, 0.95, 1.0), "efeito":"corrente",   "val":1.0,  "raridade":"epico",   "peso":1, "min_wave":15, "max_picks":1},
	{"id":"veneno",     "nome":"Veneno Arcano",        "desc":"+8 dano/s por 4s\nem inimigos acertados",             "cor":Color(0.25, 1.0,  0.2),  "efeito":"veneno",     "val":8.0,  "raridade":"incomum", "peso":5, "min_wave":4,  "max_picks":4},
	{"id":"critico",    "nome":"Golpe Crítico",        "desc":"+12% chance de\n3× dano por tiro",                    "cor":Color(1.0,  0.50, 0.05), "efeito":"critico",    "val":0.12, "raridade":"raro",    "peso":2, "min_wave":6,  "max_picks":3},
	{"id":"explosao",   "nome":"Explosão Mortal",      "desc":"Ao matar: explode\n40% dano em 80px",                 "cor":Color(1.0,  0.38, 0.05), "efeito":"explosao",   "val":1.0,  "raridade":"epico",   "peso":2, "min_wave":10, "max_picks":2},
	{"id":"chama",      "nome":"Chama Perpétua",       "desc":"+0.2 dano permanente\npor kill (máx +200 total)",    "cor":Color(1.0,  0.58, 0.08), "efeito":"chama",      "val":0.2,  "raridade":"incomum", "peso":5, "min_wave":5,  "max_picks":3},
	{"id":"overdrive",  "nome":"Overdrive",            "desc":"Após boss: cadência\n×2 por 6s",                      "cor":Color(1.0,  0.80, 0.0),  "efeito":"overdrive",  "val":1.0,  "raridade":"epico",   "peso":2, "min_wave":15, "max_picks":2},
	{"id":"armadura_i", "nome":"Armadura Invertida",   "desc":"Inimigos <30% HP\nrecebem +60% dano",                "cor":Color(0.85, 0.25, 0.95), "efeito":"armadura_i", "val":0.60, "raridade":"raro",    "peso":3, "min_wave":8,  "max_picks":2},
	{"id":"bencao",     "nome":"Bênção de Energia",    "desc":"A cada 15 kills\npróximo tiro: 8× dano",             "cor":Color(1.0,  0.95, 0.25), "efeito":"bencao",     "val":1.0,  "raridade":"epico",   "peso":2, "min_wave":12, "max_picks":2},
	{"id":"saque",      "nome":"Saque em Massa",       "desc":"+5% do score da wave\ncomo ouro extra",              "cor":Color(1.0,  0.82, 0.08), "efeito":"saque",      "val":0.05, "raridade":"incomum", "peso":4, "min_wave":5,  "max_picks":4},
	{"id":"recuperacao","nome":"Recuperação Rápida",   "desc":"Após boss: cura\n15 HP/s por 8s",                    "cor":Color(0.25, 1.0,  0.50), "efeito":"recuperacao","val":1.0,  "raridade":"raro",    "peso":3, "min_wave":10, "max_picks":3},
	# ── Novas cartas épicas ──────────────────────────────────────────────────────
	{"id":"tempestade", "nome":"Tempestade Arcana",    "desc":"Raio acerta TODOS\nos inimigos no alcance",           "cor":Color(0.55, 0.80, 1.0),  "efeito":"tempestade", "val":1.0,  "raridade":"epico",   "peso":1, "min_wave":12, "max_picks":1},
	{"id":"fissura",    "nome":"Fissura Venenosa",     "desc":"Projéteis envenenam\ntodos em 70px ao acertar",       "cor":Color(0.38, 1.0,  0.30),  "efeito":"fissura",    "val":1.0,  "raridade":"epico",   "peso":1, "min_wave":10, "max_picks":1},
	{"id":"cacador",    "nome":"Caçador de Fantasmas", "desc":"Fantasmas revelam-se\ninstantaneamente ao surgir",    "cor":Color(0.88, 0.55, 1.0),  "efeito":"cacador",    "val":1.0,  "raridade":"raro",    "peso":2, "min_wave":12, "max_picks":1},
	{"id":"rajada",     "nome":"Rajada de Tiros",      "desc":"3 projéteis em leque (±15°)\ncada um com 70% do dano",     "cor":Color(1.0,  0.72, 0.15), "efeito":"rajada",     "val":1.0,  "raridade":"epico",   "peso":1, "min_wave":10, "max_picks":1},
	{"id":"carga",      "nome":"Tiro Carregado",       "desc":"Sem alvo por 3.5s →\npróximo tiro causa 6× dano",         "cor":Color(0.88, 0.30, 0.05), "efeito":"carga",      "val":1.0,  "raridade":"raro",    "peso":2, "min_wave":6,  "max_picks":1},
	{"id":"gelo",       "nome":"Campo de Gelo",        "desc":"Mobs no alcance ficam\n45% mais lentos (imune: blindado)", "cor":Color(0.45, 0.82, 1.0),  "efeito":"gelo",       "val":1.0,  "raridade":"epico",   "peso":2, "min_wave":10, "max_picks":1},
]

const CHEFE_TIPOS : Array = [
	"normal","fast","tank","elite","berserker","colossus",
	"atirador","curandeiro","invocador","bruxo","suporte","escudeiro","fantasma"
]

var fila_spawn   : Array = []
var spawn_timer          := 0.0
var spawn_intervalo      := 1.0
const MAX_MOBS_ATIVOS_NORMAL : int = 185
const MAX_MOBS_ATIVOS_ABISMO : int = 240
const HORDA_ALVO_MIN_TELA : int = 22
const HORDA_ALVO_MAX_NORMAL : int = 44
const HORDA_ALVO_MAX_ABISMO : int = 58
const HORDA_BURST_MAX_NORMAL : int = 5
const HORDA_BURST_MAX_ABISMO : int = 7
const HORDA_INTERVALO_PRESSAO : float = 0.12

var torre   : Node2D
var ui_node : Node

# Camera e visão do mapa
var _camera        : Camera2D = null
const _ZOOM_BASE   : float    = 1.0    # zoom quando alcance = 220
const _ZOOM_MIN    : float    = 0.72   # zoom máximo afastamento (alcance = 450)
const _RANGE_BASE  : float    = 220.0  # alcance inicial sem melhorias
const _RANGE_MAX   : float    = 450.0  # cap de alcance (igual ao do main)

# ── Tutorial in-game ─────────────────────────────────────────────────────────
var _tut_ativo      : bool = false
var _tut_step       : int  = 0   # 0=wave1, 1=cartas, 2=wave2done
var _tut_dica_node  : CanvasLayer = null


func _ready() -> void:
	Engine.time_scale = 1.0
	Engine.max_fps    = 60
	gold = Salvar.ouro_banco   # começa com o saldo total do banco
	arena_ouro_inicio = gold
	# Modo Abismo: lê a flag do Salvar e reseta para não persistir
	modo_abismo              = Salvar.abismo_modo_ativo
	Salvar.abismo_modo_ativo = false
	mapa_atual_info = _mapa_partida_info(1)
	_criar_camera()
	_criar_torre()
	ui_node = $UI
	ui_node.jogo = self
	ui_node.atualizar_hud(score, gold, wave)
	if modo_abismo:
		ui_node.mostrar_banner_abismo()
	Som.tocar_musica_jogo()
	Salvar.normalizar_pet_ativo()
	var tem_pet : bool = Salvar.pet_ativo_jogavel()
	if tem_pet:
		var scr = load("res://scripts/pet.gd")
		if scr:
			pet_assistente = scr.new()
			pet_assistente.jogo = self
			add_child(pet_assistente)
	# Consumíveis: cria slots no HUD (ativação manual pelo jogador)
	if ui_node:
		ui_node.criar_consumivel_hud()
	if not Salvar.tutorial_jogo_visto:
		_tut_ativo = true
	# Restaurar checkpoint de run se existir
	if Salvar.tem_checkpoint():
		_restaurar_run_do_checkpoint(Salvar.run_checkpoint)
		Salvar.limpar_checkpoint()
	_iniciar_wave()


func _mapa_teste_override_ativo() -> bool:
	# A partida normal deve progredir pelos mapas por wave; a tela de mapas saiu do menu.
	return false


func _mapa_partida_info(w: int) -> Dictionary:
	if _mapa_teste_override_ativo():
		return Salvar.mapa_teste_info()
	return Salvar.mapa_por_wave(w)


func _mapa_final_ativo_partida(w: int) -> bool:
	if _mapa_teste_override_ativo():
		return w > 0 and w % 50 == 0
	return Salvar.mapa_final_ativo(w)


func _proximo_mapa_partida(w: int) -> Dictionary:
	if _mapa_teste_override_ativo():
		return Salvar.mapa_teste_info()
	return Salvar.mapa_por_wave(w)


func _criar_camera() -> void:
	_camera            = Camera2D.new()
	_camera.position   = Vector2(640, 360)
	_camera.zoom       = Vector2(_ZOOM_BASE, _ZOOM_BASE)
	_camera.enabled    = true
	add_child(_camera)


func _criar_torre() -> void:
	torre = TORRE_SCENE.instantiate()
	torre.position = Vector2(640, 360)
	torre.jogo     = self
	add_child(torre)

	# Melhorias da loja
	var m := Salvar.melhorias
	torre.damage    += (m["forca"]       as int) * 8.0
	torre.max_hp    += (m["resistencia"] as int) * 40.0
	torre.hp         = torre.max_hp
	torre.range_r   += (m["visao"]       as int) * 25.0
	torre.fire_rate += (m["cadencia"]    as int) * 0.2

	# Raiz — bônus base (sempre ativo)
	torre.damage += 10.0
	torre.max_hp += 20.0
	torre.hp      = torre.max_hp

	# Talentos permanentes — Ramo P (Poder)
	if Salvar.talento_ativo("p1"): torre.damage   += 30.0
	if Salvar.talento_ativo("p2"): torre.fire_rate += 0.5
	if Salvar.talento_ativo("p3"): torre.multi_shot = true; torre.multi_lvl += 1
	if Salvar.talento_ativo("p4"): torre.damage   += 80.0
	# Ramo R (Resiliência)
	if Salvar.talento_ativo("r1"): torre.damage_reduction = 0.25
	if Salvar.talento_ativo("r2"): torre.regen_rate      += 4.0
	if Salvar.talento_ativo("r3"): torre.imortal_ativo    = true
	if Salvar.talento_ativo("r4"): torre.max_hp          += 100.0; torre.hp = torre.max_hp
	# Recompensas: credito de campo escala com o banco para nao virar irrelevante no late game.
	if Salvar.talento_ativo("f2"):
		gold += maxi(500, int(float(Salvar.ouro_banco) * 0.02))
	# Ramo E (Energia)
	if Salvar.talento_ativo("e1"): torre.raio_dano += 30.0
	# Ramo S (Sombra)
	if Salvar.talento_ativo("s1"): torre.veneno_dps += 5.0
	# Colosso (cross-ramo)
	if Salvar.talento_ativo("colosso"):
		torre.damage    += 50.0
		torre.max_hp    += 50.0
		torre.hp         = torre.max_hp
		torre.fire_rate += 0.3
	# Tita — Fusão P4+R4
	if Salvar.talento_ativo("tita"):
		torre.damage  += 150.0
		torre.max_hp  += 200.0
		torre.hp       = torre.max_hp
	# Sobrevivente — +1 HP/s regen
	if Salvar.talento_ativo("sobrev"):
		torre.regen_rate += 1.0
	# Genocida — +2 dano por 1k kills acima de 10k
	if Salvar.talento_ativo("genoci"):
		var kills_acima : int = max(0, Salvar.total_mobs_mortos - 10000) / 1000
		torre.damage += float(kills_acima) * 2.0
	# Skin: aplica bônus de atributo da skin equipada
	var skin_id : String = Salvar.skin_ativa
	if Salvar.SKINS_INFO.has(skin_id):
		var sk : Dictionary = Salvar.SKINS_INFO[skin_id] as Dictionary
		var btype : String = sk["bonus_tipo"] as String
		var bval  : float  = sk["bonus_val"]  as float
		if bval > 0.0:
			match btype:
				"dano":     torre.damage    *= (1.0 + bval)
				"alcance":  torre.range_r   *= (1.0 + bval)
				"cadencia": torre.fire_rate *= (1.0 + bval)
				"ouro":     gold_mult_carta += bval
				"premium_dano_alc":
					torre.damage  *= (1.0 + bval)
					torre.range_r *= (1.0 + bval)
				"premium_cad_score":
					torre.fire_rate *= (1.0 + bval)
					score_mult_skin  = maxf(score_mult_skin, 1.0 + bval)
				"beta":
					torre.damage    *= (1.0 + bval)
					torre.range_r   *= (1.0 + bval)
					torre.fire_rate *= (1.0 + bval)
					torre.regen_rate += 1.0    # +1 HP/s regeneração
					score_mult_skin  = 1.01    # +1% score por kill
	_aplicar_equipamentos_bonus_torre()
	_aplicar_bonus_conta_torre()
	_aplicar_bonus_ascensao_torre()


func _aplicar_bonus_conta_torre() -> void:
	if torre == null or not is_instance_valid(torre):
		return
	var bonus : Dictionary = Salvar.bonus_atributos_conta()
	torre.max_hp += float(bonus.get("vida_flat", 0.0))
	torre.hp = torre.max_hp
	torre.damage *= float(bonus.get("dano_mult", 1.0))
	torre.fire_rate *= float(bonus.get("cadencia_mult", 1.0))
	torre.range_r += float(bonus.get("alcance_flat", 0.0))
	torre.damage_reduction = clampf(float(torre.damage_reduction) + float(bonus.get("reducao_dano", 0.0)), 0.0, 0.75)
	torre.crit_chance = clampf(float(torre.crit_chance) + float(bonus.get("crit_chance", 0.0)), 0.0, 0.75)
	gold_mult_carta += float(bonus.get("ouro_mult", 0.0))
	habil_effect_mult *= 1.0 + maxf(0.0, -float(bonus.get("cooldown_mult", 0.0)) * 0.5)


func _aplicar_bonus_ascensao_torre() -> void:
	if torre == null or not is_instance_valid(torre):
		return
	var bonus : Dictionary = Salvar.bonus_ascensao_stats()
	torre.damage *= float(bonus.get("dano_mult", 1.0))
	torre.fire_rate *= float(bonus.get("cadencia_mult", 1.0))
	var vida_mult : float = float(bonus.get("vida_mult", 1.0))
	if vida_mult != 1.0:
		torre.max_hp *= vida_mult
		torre.hp = torre.max_hp
	gold_mult_carta += float(bonus.get("ouro_mult", 0.0))


func _aplicar_equipamentos_bonus_torre() -> void:
	if torre == null or not is_instance_valid(torre):
		return
	var bonus : Dictionary = Salvar.equipamentos_bonus_stats()
	torre.damage    *= float(bonus.get("dano_mult", 1.0))
	torre.fire_rate *= float(bonus.get("cadencia_mult", 1.0))
	torre.range_r   *= float(bonus.get("alcance_mult", 1.0))
	var vida_mult : float = float(bonus.get("vida_mult", 1.0))
	if vida_mult != 1.0:
		torre.max_hp *= vida_mult
		torre.hp = torre.max_hp
	torre.regen_rate += float(bonus.get("regen_flat", 0.0))
	torre.damage_reduction = clampf(float(torre.damage_reduction) + float(bonus.get("reducao_dano", 0.0)), 0.0, 0.75)
	torre.boss_damage_mult *= 1.0 + float(bonus.get("boss_dano_mult", 0.0))
	torre.block_chance = clampf(float(torre.block_chance) + float(bonus.get("bloqueio_chance", 0.0)), 0.0, 0.75)
	if bonus.get("barreira_hp_baixo", false) == true:
		torre.low_hp_barrier_ready = true
	habil_effect_mult *= 1.0 + float(bonus.get("efeito_mult", 0.0))
	_arsenal_boss_escudo = bonus.get("boss_escudo", false) == true
	gold_mult_carta += float(bonus.get("ouro_mult", 0.0))


func _habil_cd_max_atual() -> float:
	var bonus : Dictionary = Salvar.equipamentos_bonus_stats()
	var conta : Dictionary = Salvar.bonus_atributos_conta()
	return maxf(5.0, HABIL_CD_MAX * (1.0 + float(bonus.get("cooldown_mult", 0.0)) + float(conta.get("cooldown_mult", 0.0))))


func _nome_chefe(tipo: String) -> String:
	match tipo:
		"normal":     return "GUARDIÃO SOMBRIO"
		"fast":       return "ESPECTRO VELOZ"
		"tank":       return "TITÃ DE FERRO"
		"elite":      return "CORRUPTOR ELITE"
		"berserker":  return "MATADOR BERSERK"
		"colossus":   return "COLOSSO ABISSAL"
		"atirador":   return "FRANCO-ATIRADOR"
		"curandeiro": return "SACERDOTE SOMBRIO"
		"invocador":  return "INVOCADOR SUPREMO"
		"bruxo":      return "ARQUIBRUXO"
		"suporte":    return "ANCIÃO DO ESCUDO"
		"escudeiro":  return "PALADINO DE AÇO"
		"fantasma":   return "ESPECTRO ETERNO"
	return "CHEFE"


func _get_wave_config(w: int) -> Dictionary:
	# Pos-wave 15 a horda cresce mais rapido (curva facil->15, pesada 15->100)
	var n        : int   = min(6 + int(roundf(float(w) * 1.25 + maxf(0.0, float(w - 15)) * 0.55)), 105)
	var fast     : int   = min(max(0, int(roundf(float(w - 1) * 1.15))), 36)
	var tank     : int   = min(max(0, int(roundf(float(w - 2) * 0.78))), 28)
	var elite    : int   = min(max(0, (w - 8) / 2), 18) if w >= 9 else 0
	var berserk  : int   = min(max(0, (w - 16) / 3), 14) if w >= 17 else 0
	var coloss   : int   = min(max(0, (w - 24) / 5), 6) if w >= 25 else 0
	var atirad   : int   = min(max(0, (w - 10) / 5), 4) if w >= 11 else 0
	var curand   : int   = min(max(0, (w - 18) / 8), 3) if w >= 19 else 0
	var invoc    : int   = min(max(0, (w - 24) / 9), 2) if w >= 25 else 0
	var bruxo_n  : int   = min(max(0, (w - 18) / 8), 3) if w >= 19 else 0
	var suporte  : int   = min(max(0, (w - 28) / 10), 2) if w >= 29 else 0
	var escudei  : int   = min(max(0, (w - 18) / 8), 3) if w >= 19 else 0
	var fantasma : int   = min(max(0, (w - 14) / 4), 5) if w >= 15 else 0
	var vampiro     : int   = min(max(0, (w - 8) / 4), 7) if w >= 9 else 0
	var espelho     : int   = min(max(0, (w - 14) / 6), 3) if w >= 15 else 0
	var ladrao      : int   = min(max(0, (w - 4) / 4), 6) if w >= 5 else 0
	var ancora      : int   = min(max(0, (w - 24) / 10), 2) if w >= 25 else 0
	var regenerador : int   = min(max(0, (w - 18) / 8), 3) if w >= 19 else 0
	var divididor   : int   = min(max(0, (w - 7) / 4), 7) if w >= 8 else 0
	var kamikaze    : int   = min(max(0, (w - 3) / 3), 12) if w >= 4 else 0
	var blindado    : int   = min(max(0, (w - 12) / 5), 5) if w >= 13 else 0
	var necromante  : int   = min(max(0, (w - 28) / 10), 2) if w >= 29 else 0
	var interv      : float = max(0.20, 1.35 - float(w) * 0.029)
	return {
		"normal": n,   "fast": fast,    "tank": tank,
		"elite": elite, "berserker": berserk, "colossus": coloss,
		"atirador": atirad, "curandeiro": curand, "invocador": invoc,
		"bruxo": bruxo_n,   "suporte": suporte,
		"escudeiro": escudei, "fantasma": fantasma,
		"vampiro": vampiro, "espelho": espelho, "ladrao": ladrao, "ancora": ancora,
		"regenerador": regenerador, "divididor": divididor, "kamikaze": kamikaze,
		"blindado": blindado, "necromante": necromante, "intervalo": interv,
	}


func get_next_wave_config() -> Dictionary:
	return _get_wave_config(wave + 1)


func _horda_alvo_tela() -> int:
	if wave <= 0:
		return 0
	var max_alvo : int = HORDA_ALVO_MAX_ABISMO if modo_abismo else HORDA_ALVO_MAX_NORMAL
	var alvo : int = 8 + int(roundf(float(wave) * 0.48))
	if wave >= 12:
		alvo = maxi(alvo, HORDA_ALVO_MIN_TELA)
	return clampi(alvo, 8, max_alvo)


func _horda_lote_spawn(ativos: int, fila_total: int, mob_cap: int) -> int:
	if fila_total <= 0 or ativos >= mob_cap:
		return 0
	var alvo : int = mini(_horda_alvo_tela(), mob_cap)
	var espaco : int = maxi(0, mob_cap - ativos)
	var burst_max : int = HORDA_BURST_MAX_ABISMO if modo_abismo else HORDA_BURST_MAX_NORMAL
	if ativos < alvo:
		var deficit : int = alvo - ativos
		return mini(fila_total, mini(espaco, mini(burst_max, deficit)))
	return mini(fila_total, mini(espaco, 1))


func _horda_spawn_intervalo_atual(ativos: int) -> float:
	var alvo : int = _horda_alvo_tela()
	if alvo > 0 and ativos < alvo:
		return minf(spawn_intervalo, HORDA_INTERVALO_PRESSAO)
	return spawn_intervalo


func _ativar_runa_furia() -> void:
	if _runa_furia_usado or Salvar.runa_furia_estoque <= 0: return
	Salvar.usar_runa_furia()
	_runa_furia_usado = true
	_runa_furia_ativo = true
	_runa_furia_waves = 3
	if torre and is_instance_valid(torre):
		torre.damage *= 1.8
	if ui_node:
		ui_node.mostrar_notificacao_consumivel("Runa de Fúria ativa! +80%% dano por 3 waves", Color(1.0, 0.45, 0.1))


func _usar_consumivel(id: String) -> void:
	match id:
		"orbe":
			if Salvar.orbe_cura_estoque <= 0: return
			Salvar.usar_orbe_cura()
			if torre and is_instance_valid(torre):
				torre.hp = minf(torre.hp + torre.max_hp * 0.5, torre.max_hp)
			if ui_node:
				ui_node.mostrar_flash_cura()
				ui_node.mostrar_notificacao_consumivel("Orbe de Cura: +50% HP restaurado!", Color(0.25, 1.0, 0.45))
				ui_node.atualizar_consumivel_slot("orbe")
		"cristal":
			if Salvar.cristal_barreira_estoque <= 0 or _cristal_barreira_ativo: return
			Salvar.usar_cristal_barreira()
			_cristal_barreira_ativo = true
			if ui_node:
				ui_node.mostrar_notificacao_consumivel("Cristal de Barreira ativo! Próximo golpe fatal absorvido.", Color(0.35, 0.55, 1.0))
				ui_node.atualizar_consumivel_slot("cristal")
		"runa":
			_ativar_runa_furia()
			if ui_node and _runa_furia_usado:
				ui_node.atualizar_consumivel_slot("runa")


func _iniciar_wave() -> void:
	wave             += 1
	mapa_atual_info = _mapa_partida_info(wave)
	wave_score        = 0
	mobs_mortos_wave  = 0
	estado            = "jogando"
	# Limpar boss anterior se existir
	if _dante_boss and is_instance_valid(_dante_boss):
		_dante_boss.queue_free()
	_dante_boss = null
	# Spawnar boss Dante nas waves finais de mapa
	if _mapa_final_ativo_partida(wave):
		_spawnar_boss_dante()
		if _arsenal_boss_escudo:
			_cristal_barreira_ativo = true
			if ui_node:
				ui_node.mostrar_notificacao_consumivel("Escudo estelar ativado para o boss!", Color(1.0, 0.78, 0.22))
	if _tut_ativo and wave == 1:
		_tut_mostrar_dica("Sua torre atira AUTOMATICAMENTE!\nSobreviva à 1ª wave para ganhar cartas de poder.", 5.0)
	elif _tut_ativo and wave == 2:
		_tut_mostrar_dica("Ótimo! As cartas melhoram sua torre.\nSobreviva mais waves para ficar mais forte!", 4.0)
	# Abismo: multiplicador de HP cresce agressivamente por wave
	if modo_abismo:
		_abismo_multi = 1.60 + float(wave - 1) * 0.12   # wave 1=1.60× wave 10=2.68× wave 20=3.88× wave 30=5.08×
	_x4_carta_pendente = false
	_x4_usado_wave     = false
	# Mini-eventos: reset a cada wave
	_evento_ativo   = {}
	_evento_timer   = 0.0
	_eventos_wave_n = 0
	# Eventos em qualquer wave, não em boss waves, delay aleatório 4-8s
	if not _mapa_final_ativo_partida(wave):
		_evento_delay = randf_range(4.0, 8.0)
	else:
		_evento_delay = 999.0
	# R5 — Imortal: protege nas waves 1-5
	if is_instance_valid(torre) and Salvar.talento_ativo("r5"):
		torre.r5_ativo = wave <= 5

	# T4 — Retrocesso Temporal: salva HP no início de cada wave
	if torre and is_instance_valid(torre):
		_t4_hp_inicio = torre.hp
		# B4 — Fúria Final: reset a cada wave
		torre.set("_b4_usado_wave", false)

	# X2 — Bênção Aleatória: bônus aleatório no início de cada wave
	if Salvar.talento_ativo("x2") and torre and is_instance_valid(torre):
		match randi() % 3:
			0: gold += 8
			1: torre.fire_rate += 0.15
			2: torre.damage    += 12.0

	# Sortear modificador de wave (não em boss waves, chance 35%, a partir da wave 3)
	if wave > 2 and not _mapa_final_ativo_partida(wave) and randf() < 0.35:
		var mods : Array = ["furia", "densa", "elite", "blindada"]
		wave_mod_atual = mods[randi() % mods.size()]
	else:
		wave_mod_atual = ""

	var cfg : Dictionary = _get_wave_config(wave)
	var mapa_mob_mult : float = float(mapa_atual_info.get("mob_mult", 1.0))

	# Progressao normal: mapas aumentam quantidade; velocidade fica controlada.
	var _mob_count_keys := [
		"normal","fast","tank","elite","berserker","colossus",
		"atirador","curandeiro","invocador","bruxo","suporte",
		"escudeiro","fantasma","vampiro","espelho","ladrao","ancora",
		"regenerador","divididor","kamikaze","blindado","necromante"
	]
	# Mobs de controle, cura ou escudo aparecem como ameaça rara dentro da horda.
	var _controle_horda_keys := ["atirador", "curandeiro", "invocador", "bruxo", "suporte", "escudeiro", "ancora", "regenerador", "necromante"]

	if not modo_abismo:
		for _k in _mob_count_keys:
			if cfg.has(_k):
				cfg[_k] = max(0, int(roundf(float(cfg[_k]) * mapa_mob_mult)))
		for _k in _controle_horda_keys:
			if cfg.has(_k) and int(cfg[_k]) > 0:
				cfg[_k] = max(1, int(floorf(float(cfg[_k]) * 0.70)))
		cfg["intervalo"] = maxf(0.24, cfg["intervalo"])
	else:
		var abismo_count : float = minf(1.85 + float(wave - 1) * 0.018, 3.35)
		for _k in _mob_count_keys:
			if cfg.has(_k):
				cfg[_k] = max(0, int(roundf(float(cfg[_k]) * abismo_count)))
		# Abismo mantem pressao por quantidade, mas sem empilhar cura/escudo/debuff demais.
		for _k in _controle_horda_keys:
			if cfg.has(_k) and int(cfg[_k]) > 0:
				cfg[_k] = max(1, int(floorf(float(cfg[_k]) * 0.45)))
		cfg["intervalo"] = maxf(0.16, cfg["intervalo"] * 0.72)

	fila_spawn = []
	for _i in cfg["normal"]     as int: fila_spawn.append("normal")
	for _i in cfg["fast"]       as int: fila_spawn.append("fast")
	for _i in cfg["tank"]       as int: fila_spawn.append("tank")
	for _i in cfg["elite"]      as int: fila_spawn.append("elite")
	for _i in cfg["berserker"]  as int: fila_spawn.append("berserker")
	for _i in cfg["colossus"]   as int: fila_spawn.append("colossus")
	for _i in cfg["atirador"]   as int: fila_spawn.append("atirador")
	for _i in cfg["curandeiro"] as int: fila_spawn.append("curandeiro")
	for _i in cfg["invocador"]  as int: fila_spawn.append("invocador")
	for _i in cfg["bruxo"]      as int: fila_spawn.append("bruxo")
	for _i in cfg["suporte"]    as int: fila_spawn.append("suporte")
	for _i in cfg["escudeiro"]  as int: fila_spawn.append("escudeiro")
	for _i in cfg["fantasma"]   as int: fila_spawn.append("fantasma")
	for _i in cfg.get("vampiro", 0) as int: fila_spawn.append("vampiro")
	for _i in cfg.get("espelho", 0) as int: fila_spawn.append("espelho")
	for _i in cfg.get("ladrao",  0) as int: fila_spawn.append("ladrao")
	for _i in cfg.get("ancora",      0) as int: fila_spawn.append("ancora")
	for _i in cfg.get("regenerador", 0) as int: fila_spawn.append("regenerador")
	for _i in cfg.get("divididor",   0) as int: fila_spawn.append("divididor")
	for _i in cfg.get("kamikaze",    0) as int: fila_spawn.append("kamikaze")
	for _i in cfg.get("blindado",    0) as int: fila_spawn.append("blindado")
	for _i in cfg.get("necromante",  0) as int: fila_spawn.append("necromante")

	# Aplicar modificador "densa": +40% de mobs extras
	if wave_mod_atual == "densa":
		var extra : int  = int(float(fila_spawn.size()) * 0.40)
		var pool  : Array = fila_spawn.duplicate()
		for _i in range(extra):
			fila_spawn.append(pool[randi() % pool.size()])

	# Aplicar modificador "elite": normais viram elite
	if wave_mod_atual == "elite":
		for i in range(fila_spawn.size()):
			if fila_spawn[i] == "normal":
				fila_spawn[i] = "elite"

	fila_spawn.shuffle()

	# Mini-chefe a cada 10 waves (fora das waves de boss de mapa): entra cedo
	# na fila com escolta. CHEFE_TIPOS + is_chefe ativam as habilidades de
	# chefe do mob.gd e a entrada cinematica.
	if wave >= 10 and wave % 10 == 0 and not _mapa_final_ativo_partida(wave):
		var tipo_chefe : String = CHEFE_TIPOS[randi() % CHEFE_TIPOS.size()]
		fila_spawn.insert(mini(fila_spawn.size(), 6), "CHEFE:" + tipo_chefe)

	mobs_na_wave = fila_spawn.size()

	spawn_intervalo = cfg["intervalo"] as float
	# T1 — Fluxo Lento: +15% de intervalo entre spawns
	if Salvar.talento_ativo("t1"):
		spawn_intervalo *= 1.15
	spawn_timer = spawn_intervalo

	if ui_node:
		Som.wave_inicio()
		ui_node.mostrar_wave(wave, wave_mod_atual)
		ui_node.atualizar_hud(score, gold, wave)
		ui_node.atualizar_kills(0, mobs_na_wave)


func _process(delta: float) -> void:
	queue_redraw()
	# Screen shake
	if _shake_timer > 0.0:
		_shake_timer -= delta
		if _camera:
			var s : float = _shake_intensity * clampf(_shake_timer / 0.22, 0.0, 1.0)
			_camera.offset = Vector2(randf_range(-s, s), randf_range(-s, s))
		if _shake_timer <= 0.0:
			_shake_intensity = 0.0
			if _camera: _camera.offset = Vector2.ZERO

	# Wave 35→45: reduz o teto de velocidade de 3.0→1.5 sutilmente (imperceptível ao jogador)
	if wave >= 35 and _vel_cap > 1.5 and estado == "jogando":
		var real_delta : float = delta / maxf(Engine.time_scale, 0.01)
		_vel_cap = maxf(1.5, _vel_cap - real_delta * 0.005)
		if Engine.time_scale > _vel_cap:
			Engine.time_scale = _vel_cap

	# Atualiza zoom da câmera conforme o alcance real da torre — garante que o círculo nunca sai da tela
	if _camera and torre and is_instance_valid(torre):
		var alvo_torre : Vector2 = Vector2(360, 360) if _mapa_final_ativo_partida(wave) else Vector2(640, 360)
		if _boss_dante_vivo():
			_processar_movimento_torre_boss(delta)
		else:
			torre.position = torre.position.lerp(alvo_torre, minf(delta * 1.4, 1.0))
		var t_range : float = torre.range_r as float
		# 330 = margem interna (tela tem 360px do centro à borda vertical)
		var zoom_alvo : float = clamp(330.0 / maxf(t_range, 1.0), _ZOOM_MIN, _ZOOM_BASE)
		var zoom_atual : float = _camera.zoom.x
		var zoom_novo  : float = lerp(zoom_atual, zoom_alvo, delta * 1.5)
		_camera.zoom = Vector2(zoom_novo, zoom_novo)

	# Exter — timer de 1s para detectar kills rápidos
	if _exter_kills_timer > 0.0:
		_exter_kills_timer -= delta
		if _exter_kills_timer <= 0.0:
			_exter_kills_rapidos = 0

	# Cooldown individual por habilidade (toca mesmo durante seleção de cartas)
	for _cd_id in _habil_cds.keys():
		var _cd_prev : float = _habil_cds[_cd_id] as float
		if _cd_prev > 0.0:
			var _cd_novo : float = maxf(0.0, _cd_prev - delta)
			_habil_cds[_cd_id] = _cd_novo
			if ui_node and is_instance_valid(ui_node):
				ui_node.call("atualizar_habil_cd", _cd_id, _cd_novo)
	if not _impactos_combate.is_empty():
		for i in range(_impactos_combate.size() - 1, -1, -1):
			var imp : Dictionary = _impactos_combate[i] as Dictionary
			imp["timer"] = float(imp.get("timer", 0.0)) - delta
			if float(imp["timer"]) <= 0.0:
				_impactos_combate.remove_at(i)
			else:
				_impactos_combate[i] = imp
		queue_redraw()

	if estado != "jogando":
		return

	# ── Mini-eventos ─────────────────────────────────────────────────────────
	if _evento_delay > 0.0 and _eventos_wave_n < 2:
		_evento_delay -= delta
		if _evento_delay <= 0.0:
			_sortear_evento()
	if not _evento_ativo.is_empty():
		_evento_timer -= delta
		if _evento_timer <= 0.0:
			_resolver_evento(false)

	if _mapa_final_ativo_partida(wave):
		if Engine.time_scale > 1.0:
			Engine.time_scale = 1.0

	# Visual expansivo da habilidade
	if not _habil_visual.is_empty():
		var dur : float = 1.1   # deve bater com o timer inicial
		var t_v : float = (_habil_visual["timer"] as float) - delta
		if t_v <= 0.0:
			_habil_visual = {}
		else:
			var prog : float = 1.0 - t_v / dur
			_habil_visual["timer"] = t_v
			_habil_visual["prog"]  = prog
			_habil_visual["raio"]  = prog * 760.0
			_habil_visual["alpha"] = (t_v / dur) * 0.88
			_habil_visual["burst"] = clampf((t_v - (dur - 0.22)) / 0.22, 0.0, 1.0)
		queue_redraw()

	if fila_spawn.size() > 0:
		var mob_cap : int = MAX_MOBS_ATIVOS_ABISMO if modo_abismo else MAX_MOBS_ATIVOS_NORMAL
		var mobs_ativos : int = get_tree().get_nodes_in_group("mobs").size()
		if mobs_ativos < mob_cap:
			spawn_timer += delta
			if spawn_timer >= _horda_spawn_intervalo_atual(mobs_ativos):
				spawn_timer = 0.0
				var lote_spawn : int = _horda_lote_spawn(mobs_ativos, fila_spawn.size(), mob_cap)
				for _i in range(lote_spawn):
					if fila_spawn.is_empty():
						break
					_spawnar_mob(fila_spawn.pop_front())

	var boss_vivo : bool = _dante_boss != null and is_instance_valid(_dante_boss) and not (_dante_boss.get("morto") == true)
	if fila_spawn.is_empty() and get_tree().get_nodes_in_group("mobs").is_empty() and not boss_vivo:
		_fim_wave()


func _screen_to_world(sp: Vector2) -> Vector2:
	var vp_size  : Vector2 = get_viewport().get_visible_rect().size
	var cam_zoom : float   = _camera.zoom.x if _camera else 1.0
	var cam_pos  : Vector2 = _camera.global_position if _camera else Vector2(640, 360)
	return cam_pos + (sp - vp_size * 0.5) / cam_zoom


func _aplicar_focus(world_pos: Vector2) -> void:
	if not torre or not is_instance_valid(torre): return
	var torre_pos : Vector2 = (torre as Node2D).global_position
	if world_pos.distance_to(torre_pos) > 60.0:
		var era_inativo : bool = not (torre.get("focus_ativo") as bool)
		torre.set("focus_dir",   (world_pos - torre_pos).normalized())
		torre.set("focus_ativo", true)
		torre.set("focus_timer", 99.0)   # infinito enquanto segura
		queue_redraw()
		if era_inativo and ui_node:
			ui_node.mostrar_notificacao_consumivel("⚡ Foco ativo!", Color(1.0, 0.88, 0.2))


func _input(event: InputEvent) -> void:
	# ── Focus de Ataque contínuo + coleta de baú (fora do boss) ──────────────
	if estado == "jogando" and not _boss_dante_vivo() and torre and is_instance_valid(torre):

		if event is InputEventScreenTouch:
			var ev := event as InputEventScreenTouch
			if ev.pressed:
				var wp : Vector2 = _screen_to_world(ev.position)
				# Tap no baú → coleta; caso contrário inicia mira hold
				if not _evento_ativo.is_empty() and wp.distance_to(_evento_pos) < 55.0:
					coletar_evento()
				else:
					_focus_touch_idx = ev.index
					_aplicar_focus(wp)
			elif ev.index == _focus_touch_idx:
				# Soltou o dedo: mantém mira por 4s e some
				_focus_touch_idx = -1
				if torre and is_instance_valid(torre) and (torre.get("focus_ativo") as bool):
					torre.set("focus_timer", 4.0)

		elif event is InputEventScreenDrag:
			var drag := event as InputEventScreenDrag
			if drag.index == _focus_touch_idx:
				_aplicar_focus(_screen_to_world(drag.position))

		elif event is InputEventMouseButton:
			var mb := event as InputEventMouseButton
			if mb.button_index == MOUSE_BUTTON_LEFT:
				if mb.pressed:
					var wp : Vector2 = _screen_to_world(mb.position)
					if not _evento_ativo.is_empty() and wp.distance_to(_evento_pos) < 55.0:
						coletar_evento()
					else:
						_focus_mouse_hold = true
						_aplicar_focus(wp)
				else:
					_focus_mouse_hold = false
					if torre and is_instance_valid(torre) and (torre.get("focus_ativo") as bool):
						torre.set("focus_timer", 4.0)

		elif event is InputEventMouseMotion and _focus_mouse_hold:
			_aplicar_focus(_screen_to_world((event as InputEventMouseMotion).position))

	if not _boss_dante_vivo():
		_boss_joy_active = false
		_boss_joy_index = -1
		_boss_joy_vec = Vector2.ZERO
		return
	if event is InputEventScreenTouch:
		var ev := event as InputEventScreenTouch
		if ev.pressed:
			if _boss_joy_index == -1 and ev.position.distance_to(BOSS_JOY_BASE) <= BOSS_JOY_RADIUS * 2.2:
				_boss_joy_index = ev.index
				_boss_joy_active = true
				_boss_joy_vec = _boss_joy_from_pos(ev.position)
		elif ev.index == _boss_joy_index:
			_boss_joy_active = false
			_boss_joy_index = -1
			_boss_joy_vec = Vector2.ZERO
	elif event is InputEventScreenDrag:
		var drag := event as InputEventScreenDrag
		if drag.index == _boss_joy_index:
			_boss_joy_active = true
			_boss_joy_vec = _boss_joy_from_pos(drag.position)
	elif event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_LEFT:
			if mb.pressed and mb.position.distance_to(BOSS_JOY_BASE) <= BOSS_JOY_RADIUS * 2.2:
				_boss_joy_active = true
				_boss_joy_vec = _boss_joy_from_pos(mb.position)
			elif not mb.pressed:
				_boss_joy_active = false
				_boss_joy_vec = Vector2.ZERO
	elif event is InputEventMouseMotion and _boss_joy_active:
		var mm := event as InputEventMouseMotion
		_boss_joy_vec = _boss_joy_from_pos(mm.position)


func _boss_dante_vivo() -> bool:
	return _dante_boss != null and is_instance_valid(_dante_boss) and not (_dante_boss.get("morto") == true)


func _boss_joy_from_pos(pos: Vector2) -> Vector2:
	var v := pos - BOSS_JOY_BASE
	if v.length() > BOSS_JOY_RADIUS:
		v = v.normalized() * BOSS_JOY_RADIUS
	return v / BOSS_JOY_RADIUS


func _processar_movimento_torre_boss(delta: float) -> void:
	if not torre or not is_instance_valid(torre):
		return
	var dir := Vector2.ZERO
	if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT):
		dir.x -= 1.0
	if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT):
		dir.x += 1.0
	if Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP):
		dir.y -= 1.0
	if Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN):
		dir.y += 1.0
	if _boss_joy_vec.length_squared() > 0.02:
		dir += _boss_joy_vec
	if dir.length_squared() > 1.0:
		dir = dir.normalized()
	var nova_pos : Vector2 = torre.position + dir * BOSS_TORRE_SPEED * delta
	nova_pos.x = clampf(nova_pos.x, BOSS_TORRE_LIMIT.position.x, BOSS_TORRE_LIMIT.position.x + BOSS_TORRE_LIMIT.size.x)
	nova_pos.y = clampf(nova_pos.y, BOSS_TORRE_LIMIT.position.y, BOSS_TORRE_LIMIT.position.y + BOSS_TORRE_LIMIT.size.y)
	torre.position = nova_pos









func _spawnar_boss_dante() -> void:
	_dante_boss_encerrado = false
	if torre and is_instance_valid(torre):
		torre.position = BOSS_TORRE_START
	_boss_joy_active = false
	_boss_joy_index = -1
	_boss_joy_vec = Vector2.ZERO
	var boss : Node2D = load("res://scripts/boss_dante.gd").new()
	boss.name = "BossDante"
	boss.jogo = self
	# HP escala linear + rampa pós-w30 (builds full chegam fortes demais p/ linear puro)
	var hp_boss : float = (16000.0 + float(wave) * 950.0) * (1.0 + maxf(0.0, float(wave - 30)) * 0.022)
	if Salvar.talento_ativo("t3"):
		hp_boss *= 1.20
	boss.setup(hp_boss, wave)
	boss.boss_derrotado.connect(func():
		_trigger_shake(18.0, 0.55)
		score += 300 + wave * 15
		if Salvar.talento_ativo("t3"):
			var bonus_boss_cytron : int = int(float(500 + wave * 35) * (1.0 if modo_abismo else 0.45))
			gold += bonus_boss_cytron
			if ui_node:
				ui_node.mostrar_notificacao_consumivel(
					"Protocolo de boss: +%d Cytron." % bonus_boss_cytron,
					Color(1.0, 0.72, 0.18)
				)
		if Salvar.talento_ativo("token") and not token_disponivel and randf() < 0.35:
			token_disponivel = true
			if ui_node:
				ui_node.ganhar_token()
		if ui_node: ui_node.atualizar_hud(score, gold, wave)
		_dante_boss_encerrado = true
		_dante_boss = null)
	add_child(boss)
	_dante_boss = boss


func _spawnar_mob_em(tipo: String, pos: Vector2) -> void:
	var mob = MOB_SCENE.instantiate()
	mob.tipo     = tipo
	mob.wave_num = wave
	mob.jogo     = self
	mob.modo_abismo = modo_abismo
	mob.position = pos
	add_child(mob)
	mobs_na_wave += 1


func _spawnar_mob(tipo: String) -> void:
	var mob      = MOB_SCENE.instantiate()
	if tipo.begins_with("CHEFE:"):
		tipo = tipo.trim_prefix("CHEFE:")
		mob.is_chefe   = true
		mob.nome_chefe = _nome_chefe(tipo)
	mob.tipo = tipo
	mob.wave_num    = wave
	mob.jogo        = self
	mob.modo_abismo = modo_abismo
	# Mobs de suporte surgem perto de aliados com bastante HP (sem caminho fixo)
	var spawn_perto : bool = mob.tipo in ["curandeiro", "bruxo", "suporte"]
	if spawn_perto:
		mob.position = _posicao_spawn_proximo()
	else:
		mob.position = _posicao_spawn()
	add_child(mob)
	# Dificuldade por mapa ja vem do mob/mapa; velocidade nao escala.
	if modo_abismo:
		var am : float = _abismo_multi
		mob.hp     *= am
		mob.max_hp *= am
		mob.damage *= (1.0 + (am - 1.0) * 0.55)
	# Espelho: copia stats da torre (HP, dano, velocidade)
	if mob.tipo == "espelho" and torre and is_instance_valid(torre):
		var m_hp : float = clampf(torre.max_hp * 0.32, 80.0, 550.0)
		mob.hp     = m_hp;  mob.max_hp = m_hp
		mob.damage = clampf(torre.damage * 0.38, 10.0, 75.0)
		mob.speed  = clampf(55.0 + torre.fire_rate * 20.0, 65.0, 195.0)
	if torre and is_instance_valid(torre) and mob.tipo != "espelho":
		var hp_floor : float = 0.0
		if modo_abismo and wave >= 15:
			hp_floor = torre.damage * 0.85
		if hp_floor > 0.0 and mob.hp < hp_floor:
			mob.max_hp = maxf(mob.max_hp, hp_floor)
			mob.hp     = hp_floor

	# Caçador de Fantasmas: reduz tempo de revelação a 0.4s
	if mob.tipo == "fantasma" and cacador_fantasma:
		mob.set("_invis_timer", 0.4)
	# Aplicar modificador de wave
	if true:
		match wave_mod_atual:
			"furia":
				mob.damage *= 1.35
			"blindada":
				mob.escudo_explosivo = true
	# Efeito de entrada: câmera lenta + overlay com nome (apenas mini-chefes)
	if mob.is_chefe:
		var nome_b : String = mob.nome_chefe if mob.nome_chefe != "" else "CHEFE"
		var vel_antes : float = Engine.time_scale   # guarda para restaurar depois
		Engine.time_scale = 0.20
		if ui_node:
			ui_node.mostrar_entrada_boss(nome_b, mob.cor)
		var ui_ref := ui_node   # cópia local — evita capturar self no lambda
		get_tree().create_timer(3.0, true, false, true).timeout.connect(
			func() -> void:
				if absf(Engine.time_scale - 0.20) < 0.05:
					if is_instance_valid(ui_ref):
						ui_ref.call("_definir_velocidade", vel_antes)
					else:
						Engine.time_scale = vel_antes
		)


# ── Habilidade Ativa ─────────────────────────────────────────────────────────

func _draw() -> void:
	_draw_fundo_mapa()
	# Focus cone + baú de evento desenhados em background.gd (renderiza depois, fica visível)
	# Arena do boss é desenhada pelo próprio nó (CanvasLayer)
	if not _impactos_combate.is_empty():
		for raw in _impactos_combate:
			var imp : Dictionary = raw as Dictionary
			var dur : float = maxf(float(imp.get("dur", 0.35)), 0.01)
			var t : float = clampf(float(imp.get("timer", 0.0)) / dur, 0.0, 1.0)
			var prog_i : float = 1.0 - t
			var pos : Vector2 = imp.get("pos", Vector2.ZERO) as Vector2
			var imp_cor : Color = imp.get("cor", Color(1.0, 0.82, 0.20)) as Color
			var forte : bool = imp.get("forte", false) == true
			var base_r : float = 22.0 if forte else 13.0
			var r : float = base_r + prog_i * (44.0 if forte else 24.0)
			draw_circle(pos, r * 0.28, Color(1.0, 1.0, 0.86, t * (0.28 if forte else 0.18)))
			draw_arc(pos, r, 0.0, TAU, 32, Color(imp_cor.r, imp_cor.g, imp_cor.b, t * 0.75), 3.5 if forte else 2.2)
			draw_arc(pos, r * 0.62, 0.0, TAU, 24, Color(1.0, 1.0, 1.0, t * 0.30), 1.5)
			if forte:
				for si in range(6):
					var a : float = float(si) * TAU / 6.0 + prog_i * 0.8
					var p0 := pos + Vector2(cos(a), sin(a)) * (r * 0.35)
					var p1 := pos + Vector2(cos(a), sin(a)) * (r * 0.78)
					draw_line(p0, p1, Color(imp_cor.r, imp_cor.g, imp_cor.b, t * 0.55), 2.0)
	if _boss_dante_vivo():
		_draw_boss_joystick()
	if _habil_visual.is_empty(): return
	var cor   : Color  = _habil_visual["cor"]
	var raio  : float  = _habil_visual["raio"]
	var alpha : float  = _habil_visual["alpha"]
	var prog  : float  = _habil_visual.get("prog", 0.0)     # 0→1 ao longo do efeito
	var burst : float  = _habil_visual.get("burst", 0.0)    # flash inicial 1→0
	var hid   : String = _habil_visual.get("id", "")
	var c : Vector2 = Vector2(640.0, 360.0)

	# ── Flash inicial no centro ────────────────────────────────────────────────
	if burst > 0.01:
		draw_circle(c, 180.0 * burst, Color(cor.r, cor.g, cor.b, burst * 0.35))
		draw_circle(c, 60.0  * burst, Color(1.0, 1.0, 1.0, burst * 0.55))

	# ── Anéis expansivos comuns ────────────────────────────────────────────────
	draw_arc(c, raio,        0.0, TAU, 96, Color(cor.r, cor.g, cor.b, alpha * 0.88), 10.0)
	draw_arc(c, raio * 0.72, 0.0, TAU, 80, Color(cor.r, cor.g, cor.b, alpha * 0.50),  6.0)
	draw_arc(c, raio * 0.44, 0.0, TAU, 64, Color(cor.r, cor.g, cor.b, alpha * 0.28),  3.5)

	# ── Efeito específico por habilidade ──────────────────────────────────────
	match hid:
		"eletrico":
			# Raios em zigzag saindo do centro até a frente de onda
			var n_raios : int = 12
			for i in range(n_raios):
				var ang  : float = float(i) / float(n_raios) * TAU + prog * 1.8
				var flick: float = 0.5 + 0.5 * sin(prog * 38.0 + float(i) * 1.9)
				var p0   := c
				var segmentos : int = 5
				for seg in range(segmentos):
					var t0 : float = float(seg)     / float(segmentos)
					var t1 : float = float(seg + 1) / float(segmentos)
					var desvio : float = randf_range(-22.0, 22.0) * (1.0 - t0)
					var ang_perp : float = ang + TAU * 0.25
					var rp0 := c + Vector2(cos(ang), sin(ang)) * raio * t0 + Vector2(cos(ang_perp), sin(ang_perp)) * desvio
					var rp1 := c + Vector2(cos(ang), sin(ang)) * raio * t1
					draw_line(rp0, rp1, Color(0.7, 1.0, 1.0, alpha * flick * 0.85), 1.8)
			# Arco elétrico pulsante na frente de onda
			draw_arc(c, raio + 8.0, 0.0, TAU, 48,
				Color(1.0, 1.0, 1.0, alpha * (0.5 + 0.5 * sin(prog * 40.0))), 3.0)

		"gelo":
			# 6 braços de cristal de gelo saindo do centro
			var n_bracos : int = 6
			for i in range(n_bracos):
				var ang : float = float(i) / float(n_bracos) * TAU
				var ponta := c + Vector2(cos(ang), sin(ang)) * raio * 0.95
				draw_line(c, ponta, Color(0.75, 0.95, 1.0, alpha * 0.70), 2.5)
				# Ramificações perpendiculares em 3 pontos do braço
				for r_idx in range(3):
					var t : float = 0.30 + float(r_idx) * 0.22
					var pb := c + Vector2(cos(ang), sin(ang)) * raio * t
					var ramo_len : float = raio * 0.12
					var perp_ang : float = ang + TAU * 0.25
					var pb1 := pb + Vector2(cos(perp_ang), sin(perp_ang)) * ramo_len
					var pb2 := pb - Vector2(cos(perp_ang), sin(perp_ang)) * ramo_len
					draw_line(pb, pb1, Color(0.85, 0.97, 1.0, alpha * 0.55), 1.5)
					draw_line(pb, pb2, Color(0.85, 0.97, 1.0, alpha * 0.55), 1.5)
			# Anel de gelo externo com facetas
			draw_arc(c, raio, 0.0, TAU, 6, Color(0.6, 0.9, 1.0, alpha * 0.60), 4.0)

		"devastador":
			# 3 anéis de choque deslocados — efeito de explosão em camadas
			for ri in range(3):
				var offset : float = float(ri) * 0.18
				var r_anel : float = raio * clampf(prog - offset, 0.0, 1.0) * (0.9 + float(ri) * 0.08) * 760.0 / 760.0
				if r_anel > 5.0:
					var a_anel : float = alpha * (1.0 - float(ri) * 0.28) * clampf(1.0 - (prog - offset) * 1.5, 0.0, 1.0)
					draw_arc(c, r_anel, 0.0, TAU, 64,
						Color(cor.r, cor.g * (0.5 - float(ri)*0.1), 0.0, a_anel * 0.95),
						12.0 - float(ri) * 3.0)
			# Faíscas saindo do centro
			var n_faisca : int = 16
			for fi in range(n_faisca):
				var fa : float = float(fi) / float(n_faisca) * TAU + prog * 0.5
				var fd : float = raio * prog * (0.6 + float(fi % 3) * 0.15)
				var fp := c + Vector2(cos(fa), sin(fa)) * fd
				draw_circle(fp, 3.5, Color(1.0, 0.8, 0.2, alpha * 0.75))


func _draw_boss_joystick() -> void:
	var base := BOSS_JOY_BASE
	var knob := base + _boss_joy_vec * BOSS_JOY_RADIUS
	var a : float = 0.62 if _boss_joy_active else 0.36
	draw_circle(base, BOSS_JOY_RADIUS + 12.0, Color(0.0, 0.05, 0.08, 0.34))
	draw_arc(base, BOSS_JOY_RADIUS, 0.0, TAU, 64, Color(0.0, 0.72, 1.0, a), 3.5)
	draw_arc(base, BOSS_JOY_RADIUS * 0.56, 0.0, TAU, 48, Color(0.55, 0.88, 1.0, a * 0.38), 1.6)
	draw_line(base + Vector2(-BOSS_JOY_RADIUS * 0.48, 0.0), base + Vector2(BOSS_JOY_RADIUS * 0.48, 0.0), Color(0.55, 0.88, 1.0, a * 0.34), 1.4)
	draw_line(base + Vector2(0.0, -BOSS_JOY_RADIUS * 0.48), base + Vector2(0.0, BOSS_JOY_RADIUS * 0.48), Color(0.55, 0.88, 1.0, a * 0.34), 1.4)
	draw_circle(knob, 20.0, Color(0.0, 0.72, 1.0, 0.26 + a * 0.18))
	draw_arc(knob, 20.0, 0.0, TAU, 32, Color(0.75, 0.95, 1.0, 0.72), 2.2)
	draw_circle(knob, 6.0, Color(0.75, 0.95, 1.0, 0.80))


func _draw_fundo_mapa() -> void:
	var info : Dictionary = mapa_atual_info if not mapa_atual_info.is_empty() else Salvar.mapa_teste_info()
	var id : String = str(info.get("id", "setor_inicial"))
	var cor : Color = info.get("cor", Color(0.0, 0.72, 1.0)) as Color
	var rect := _mapa_rect_visivel()
	var tex := _mapa_texture(info)
	if tex != null:
		draw_rect(rect, Color(0.0, 0.0, 0.0, 1.0))
		_draw_texture_cover(tex, rect, 1.0)
		return
	if id == "setor_inicial":
		draw_rect(rect, Color(0.008, 0.008, 0.025, 1.0))
		_draw_estrelas_setor_inicial(rect)
		return
	var bg_top := Color(0.010 + cor.r * 0.050, 0.012 + cor.g * 0.040, 0.030 + cor.b * 0.080, 1.0)
	var bg_bot := Color(0.004 + cor.r * 0.025, 0.004 + cor.g * 0.020, 0.012 + cor.b * 0.045, 1.0)
	draw_rect(rect, bg_bot)
	for i in range(9):
		var y : float = rect.position.y + float(i) * rect.size.y / 9.0
		var t : float = float(i) / 8.0
		var c := bg_top.lerp(bg_bot, t)
		draw_rect(Rect2(rect.position.x, y, rect.size.x, rect.size.y / 9.0 + 2.0), c)

	_draw_estrelas_distantes(cor, id)
	match id:
		"nebulosa_fraturada":
			_draw_nebulosa(Vector2(850, 185), 620.0, Color(0.75, 0.18, 1.0, 0.24), Color(0.0, 0.85, 1.0, 0.12))
			_draw_planeta(Vector2(1030, 170), 155.0, Color(0.32, 0.05, 0.48), Color(0.95, 0.22, 1.0), 0.78)
			_draw_planeta(Vector2(180, 590), 62.0, Color(0.03, 0.18, 0.24), Color(0.0, 0.95, 1.0), 0.48)
		"orbita_glacial":
			_draw_nebulosa(Vector2(350, 175), 560.0, Color(0.25, 0.80, 1.0, 0.22), Color(0.8, 1.0, 1.0, 0.11))
			_draw_planeta(Vector2(1015, 540), 180.0, Color(0.07, 0.22, 0.34), Color(0.55, 0.90, 1.0), 0.82)
			_draw_anel_planeta(Vector2(1015, 540), 240.0, Color(0.72, 0.95, 1.0, 0.38))
		"nucleo_abissal":
			_draw_nebulosa(Vector2(640, 360), 720.0, Color(0.78, 0.04, 0.22, 0.22), Color(0.45, 0.0, 0.75, 0.16))
			_draw_planeta(Vector2(180, 135), 128.0, Color(0.18, 0.02, 0.06), Color(1.0, 0.12, 0.35), 0.78)
			_draw_planeta(Vector2(1120, 260), 82.0, Color(0.14, 0.02, 0.20), Color(0.8, 0.1, 1.0), 0.52)
		"coroa_void":
			_draw_nebulosa(Vector2(680, 230), 740.0, Color(1.0, 0.66, 0.08, 0.20), Color(0.45, 0.15, 1.0, 0.16))
			_draw_planeta(Vector2(970, 150), 190.0, Color(0.26, 0.18, 0.03), Color(1.0, 0.80, 0.16), 0.86)
			_draw_anel_planeta(Vector2(970, 150), 270.0, Color(1.0, 0.78, 0.22, 0.42))
		_:
			_draw_nebulosa(Vector2(760, 170), 540.0, Color(0.0, 0.55, 1.0, 0.18), Color(0.0, 1.0, 0.78, 0.10))
			_draw_planeta(Vector2(1080, 155), 142.0, Color(0.04, 0.13, 0.25), Color(0.0, 0.75, 1.0), 0.70)
			_draw_planeta(Vector2(180, 520), 72.0, Color(0.04, 0.18, 0.12), Color(0.0, 1.0, 0.72), 0.42)


func _mapa_rect_visivel() -> Rect2:
	if _camera == null or not is_instance_valid(_camera):
		return Rect2(0.0, 0.0, 1280.0, 720.0)
	var vp := get_viewport_rect().size
	if vp.x <= 0.0 or vp.y <= 0.0:
		vp = Vector2(1280.0, 720.0)
	var zx : float = maxf(_camera.zoom.x, 0.01)
	var zy : float = maxf(_camera.zoom.y, 0.01)
	var visible_size := Vector2(vp.x / zx, vp.y / zy)
	var center := _camera.get_screen_center_position()
	return Rect2(center - visible_size * 0.5, visible_size)


func _mapa_texture(info: Dictionary) -> Texture2D:
	var path := str(info.get("bg", ""))
	if path == "":
		return null
	if _mapa_texture_cache.has(path):
		return _mapa_texture_cache[path] as Texture2D
	var tex := _load_texture_file(path)
	_mapa_texture_cache[path] = tex
	return tex


func _load_texture_file(path: String) -> Texture2D:
	if ResourceLoader.exists(path):
		var imported_tex := load(path) as Texture2D
		if imported_tex != null:
			return imported_tex
	if not FileAccess.file_exists(path):
		return null
	var img := Image.load_from_file(path)
	if img == null:
		var abs_path := ProjectSettings.globalize_path(path)
		if abs_path != path:
			img = Image.load_from_file(abs_path)
	if img == null or img.get_width() <= 0 or img.get_height() <= 0:
		return null
	return ImageTexture.create_from_image(img)


func _draw_texture_cover(tex: Texture2D, rect: Rect2, alpha: float = 1.0) -> void:
	if tex == null:
		return
	var tw := float(tex.get_width())
	var th := float(tex.get_height())
	if tw <= 0.0 or th <= 0.0 or rect.size.x <= 0.0 or rect.size.y <= 0.0:
		return
	var target_ratio := rect.size.x / rect.size.y
	var src_ratio := tw / th
	var src := Rect2(0.0, 0.0, tw, th)
	if src_ratio > target_ratio:
		var new_w := th * target_ratio
		src.position.x = (tw - new_w) * 0.5
		src.size.x = new_w
	else:
		var new_h := tw / target_ratio
		src.position.y = (th - new_h) * 0.5
		src.size.y = new_h
	draw_texture_rect_region(tex, rect, src, Color(1.0, 1.0, 1.0, alpha))


func _draw_estrelas_distantes(cor: Color, seed_id: String) -> void:
	var base : int = abs(hash(seed_id))
	for i in range(95):
		var x : float = float((base + i * 173) % 1280)
		var y : float = float((base / 7 + i * 97) % 720)
		var s : float = 0.7 + float((base + i * 19) % 9) * 0.12
		var a : float = 0.16 + float((base + i * 31) % 10) * 0.025
		draw_circle(Vector2(x, y), s, Color(0.75 + cor.r * 0.25, 0.82 + cor.g * 0.18, 1.0, a))


func _draw_estrelas_setor_inicial(rect: Rect2) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 42
	for i in range(210):
		var p := Vector2(
			rng.randf_range(rect.position.x, rect.position.x + rect.size.x),
			rng.randf_range(rect.position.y, rect.position.y + rect.size.y)
		)
		var s : float = rng.randf_range(0.45, 1.35)
		var a : float = rng.randf_range(0.08, 0.50)
		if i % 13 == 0:
			s = rng.randf_range(1.1, 2.0)
			a = rng.randf_range(0.24, 0.62)
		draw_circle(p, s * 0.5, Color(0.75, 0.86, 1.0, a))


func _draw_nebulosa(pos: Vector2, raio: float, c1: Color, c2: Color) -> void:
	for i in range(8, 0, -1):
		var t : float = float(i) / 8.0
		draw_circle(pos + Vector2(sin(float(i)) * 38.0, cos(float(i) * 1.7) * 24.0), raio * t, Color(c1.r, c1.g, c1.b, c1.a * t * 0.85))
	for i in range(5, 0, -1):
		var t : float = float(i) / 5.0
		draw_circle(pos + Vector2(-90.0 + float(i) * 36.0, 46.0 - float(i) * 18.0), raio * 0.42 * t, Color(c2.r, c2.g, c2.b, c2.a * t * 1.25))


func _draw_planeta(pos: Vector2, raio: float, base: Color, luz: Color, alpha: float) -> void:
	for i in range(7, 0, -1):
		var t : float = float(i) / 7.0
		draw_circle(pos, raio * t, Color(base.r + luz.r * 0.10 * (1.0 - t), base.g + luz.g * 0.10 * (1.0 - t), base.b + luz.b * 0.10 * (1.0 - t), alpha * t))
	draw_circle(pos + Vector2(-raio * 0.28, -raio * 0.22), raio * 0.48, Color(luz.r, luz.g, luz.b, alpha * 0.22))
	draw_arc(pos, raio + 2.0, 0.0, TAU, 64, Color(luz.r, luz.g, luz.b, alpha * 0.55), 1.6)


func _draw_anel_planeta(pos: Vector2, raio: float, cor: Color) -> void:
	draw_arc(pos, raio, -0.25, PI + 0.25, 96, cor, 2.4)
	draw_arc(pos, raio * 0.76, -0.20, PI + 0.20, 96, Color(cor.r, cor.g, cor.b, cor.a * 0.55), 1.4)


func ativar_habilidade(id: String) -> void:
	if (_habil_cds.get(id, 0.0) as float) > 0.0: return
	if estado != "jogando": return
	if not Salvar.usar_habil(id): return
	var cd_max : float = _habil_cd_max_atual()
	_habil_cds[id] = cd_max
	var info : Dictionary = Salvar.HABIL_INFO[id] as Dictionary
	_habil_visual = {
		"id":    id,
		"cor":   info["cor"] as Color,
		"raio":  0.0,
		"alpha": 0.0,
		"prog":  0.0,
		"burst": 1.0,
		"timer": 1.1,    # era 0.65 — mais tempo para o efeito
	}
	match id:
		"eletrico":   _habil_eletrico()
		"gelo":       _habil_gelo()
		"devastador": _habil_devastador()
	Som.upgrade()
	if ui_node and is_instance_valid(ui_node):
		ui_node.call("mostrar_efeito_habil", id, info["cor"] as Color)
		ui_node.call("atualizar_habil_cargas")
		ui_node.call("atualizar_habil_cd", id, cd_max)
	# Camera shake leve ao usar habilidade
	_shake_timer     = 0.28
	_shake_intensity = 5.5


func _habil_eletrico() -> void:
	for mob in get_tree().get_nodes_in_group("mobs"):
		if not is_instance_valid(mob): continue
		if mob.get("morto"): continue
		mob.set("habil_stun_timer", 1.8 * habil_effect_mult)


func _habil_gelo() -> void:
	for mob in get_tree().get_nodes_in_group("mobs"):
		if not is_instance_valid(mob): continue
		if mob.get("morto"): continue
		var atual : float = mob.get("gelo_slow") as float
		var novo  : float = clampf(0.80 * habil_effect_mult, 0.0, 0.95)
		mob.set("gelo_slow", maxf(atual, novo))


func _habil_devastador() -> void:
	for mob in get_tree().get_nodes_in_group("mobs"):
		if not is_instance_valid(mob): continue
		if mob.get("morto"): continue
		var hp_atual : float = mob.get("hp") as float
		var pct      : float = clampf(0.35 * habil_effect_mult, 0.0, 0.70)
		mob.call("receber_dano", hp_atual * pct)


func _posicao_spawn_proximo() -> Vector2:
	var mapa_id : String = str(mapa_atual_info.get("id", Salvar.mapa_teste_info().get("id", "setor_inicial")))
	if _mapa_final_ativo_partida(wave):
		return _posicao_spawn()
	var mobs := get_tree().get_nodes_in_group("mobs")
	var candidatos : Array = []
	for mob in mobs:
		if not is_instance_valid(mob) or (mob.get("morto") as bool):
			continue
		var mhp : float = mob.get("max_hp") as float
		if mhp > 0.0 and (mob.get("hp") as float) / mhp > 0.35:
			candidatos.append(mob)
	if candidatos.is_empty() and not mobs.is_empty():
		candidatos = mobs
	if not candidatos.is_empty():
		var alvo : Node2D = candidatos[randi() % candidatos.size()] as Node2D
		return alvo.position + Vector2(randf_range(-90.0, 90.0), randf_range(-90.0, 90.0))
	return _posicao_spawn()


func _posicao_spawn() -> Vector2:
	var mapa_id : String = str(mapa_atual_info.get("id", Salvar.mapa_teste_info().get("id", "setor_inicial")))
	if _mapa_final_ativo_partida(wave):
		var fontes := [
			Vector2(978.0, 302.0),
			Vector2(978.0, 360.0),
			Vector2(978.0, 418.0),
		]
		var base : Vector2 = fontes[randi() % fontes.size()]
		return base + Vector2(randf_range(-8.0, 10.0), randf_range(-10.0, 10.0))
	# Considera o zoom da câmera para que mobs sempre spawnem fora da tela visível
	var zoom   : float = _camera.zoom.x if _camera else 1.0
	var half_w : float = 640.0 / zoom + 30.0
	var half_h : float = 360.0 / zoom + 30.0
	var cy     : float = 360.0
	var cx : float = 640.0
	match randi() % 4:
		0: return Vector2(randf_range(cx - half_w, cx + half_w), cy - half_h)
		1: return Vector2(randf_range(cx - half_w, cx + half_w), cy + half_h)
		2: return Vector2(cx - half_w, randf_range(cy - half_h, cy + half_h))
		_: return Vector2(cx + half_w, randf_range(cy - half_h, cy + half_h))


func _posicao_borda_aleatoria() -> Vector2:
	# Retorna posição na BORDA da tela visível (para a sombra do boss)
	var zoom   : float = _camera.zoom.x if _camera else 1.0
	var half_w : float = 640.0 / zoom
	var half_h : float = 360.0 / zoom
	var cx     : float = 640.0
	var cy     : float = 360.0
	match randi() % 4:
		0: return Vector2(randf_range(cx - half_w * 0.6, cx + half_w * 0.6), cy - half_h + 60.0)
		1: return Vector2(randf_range(cx - half_w * 0.6, cx + half_w * 0.6), cy + half_h - 60.0)
		2: return Vector2(cx - half_w + 60.0, randf_range(cy - half_h * 0.6, cy + half_h * 0.6))
		_: return Vector2(cx + half_w - 60.0, randf_range(cy - half_h * 0.6, cy + half_h * 0.6))


func _carta_max_picks(carta: Dictionary) -> int:
	var base : int = carta["max_picks"] as int
	match carta["id"] as String:
		"multi":  if Salvar.talento_ativo("p3"): return base + 2
		"escudo": if Salvar.talento_ativo("r1"): return base + 1
		"ouro":   if Salvar.talento_ativo("f1"): return base + 1
	return base


func _carta_bloqueada_arena(_carta: Dictionary) -> bool:
	return false


func _fim_wave() -> void:
	var fim_mapa : bool = _mapa_final_ativo_partida(wave)
	var mapa_concluido_info : Dictionary = mapa_atual_info.duplicate()
	var gold_antes : int = gold
	var baus_ganhos : Dictionary = {}
	if _runa_furia_ativo:
		_runa_furia_waves -= 1
		if _runa_furia_waves <= 0:
			_runa_furia_ativo = false
			if torre and is_instance_valid(torre):
				torre.damage /= 1.8
			if ui_node:
				ui_node.mostrar_notificacao_consumivel("Runa de Fúria expirou.", Color(0.6, 0.4, 0.2))
	if _tut_ativo and wave == 2:
		_tut_ativo = false
		Salvar.tutorial_concluido = true
		Salvar.tutorial_jogo_visto = true
		Salvar.salvar()
		_tut_fechar_dica()
	estado = "cartas"
	var wave_gold_mult : float = 1.0 if modo_abismo else 0.45
	gold += int(float(5 + wave * 2) * wave_gold_mult)
	if saque_bonus > 0.0:
		gold += int(float(wave_score) * saque_bonus * wave_gold_mult)

	var cristais_ganhos : int = max(1, wave / 10)
	if Salvar.talento_ativo("f5"):
		cristais_ganhos = int(float(cristais_ganhos) * 1.5)
	if modo_abismo:
		cristais_ganhos += 2  # Abismo: dificuldade própria, bônus fixo
	else:
		var asc_cristais_mult : float = float(Salvar.bonus_ascensao_stats().get("cristais_mult", 1.0))
		if asc_cristais_mult > 1.0:
			cristais_ganhos = maxi(1, int(round(float(cristais_ganhos) * asc_cristais_mult)))
	Salvar.depositar_cristais(cristais_ganhos)
	if wave > 0:
		var bau_nivel : String = ""
		if fim_mapa:
			bau_nivel = str(mapa_concluido_info.get("bau_bonus", Salvar.bau_por_wave(wave)))
		elif wave % 10 == 0:
			bau_nivel = Salvar.bau_por_wave(wave)
		if bau_nivel != "":
			Salvar.ganhar_bau(1, bau_nivel)
			baus_ganhos[bau_nivel] = int(baus_ganhos.get(bau_nivel, 0)) + 1
			if ui_node:
				ui_node.mostrar_notificacao_consumivel("Bau %s conquistado! Abra no inventario." % bau_nivel.capitalize(), Color(1.0, 0.72, 0.18))

	if ui_node:
		ui_node.atualizar_hud(score, gold, wave)
	if fim_mapa:
		var proximo_mapa : Dictionary = _proximo_mapa_partida(wave + 1)
		mapa_atual_info = proximo_mapa
		estado = "resumo_mapa"
		var resumo := {
			"mapa": str(mapa_concluido_info.get("nome", "Setor")),
			"proximo_mapa": str(proximo_mapa.get("nome", "Proximo Setor")),
			"gold": maxi(0, gold - gold_antes),
			"score": wave_score,
			"score_total": score,
			"cristais": cristais_ganhos,
			"baus": baus_ganhos,
		}
		if ui_node and ui_node.has_method("mostrar_resumo_mapa"):
			ui_node.call("mostrar_resumo_mapa", resumo, Callable(self, "_prosseguir_pos_resumo_mapa"))
		else:
			_prosseguir_pos_resumo_mapa()
		return
	_prosseguir_pos_resumo_mapa()
	return


func _prosseguir_pos_resumo_mapa() -> void:
	# Cartas aparecem na wave 1 (tutorial) e a cada 5 waves depois (5, 10, 15...).
	# Waves intermediárias vão direto para a próxima wave.
	var wave_com_carta : bool = (wave == 1) or (wave % 5 == 0)
	if not wave_com_carta:
		if Salvar.pausa_auto_wave and ui_node:
			ui_node.mostrar_btn_iniciar_wave()
		else:
			_iniciar_wave()
		return
	estado = "cartas"
	_sortear_e_mostrar_cartas()


# ── Mini-eventos ─────────────────────────────────────────────────────────────

func _sortear_evento() -> void:
	var ev : Dictionary = (EVENTOS_WAVE[randi() % EVENTOS_WAVE.size()] as Dictionary).duplicate()
	_evento_ativo   = ev
	_evento_timer   = float(ev.get("dur", 8.0))
	_eventos_wave_n += 1
	# Posição aleatória no mapa: anel entre 160-270px do centro da arena
	var centro  : Vector2 = Vector2(640.0, 360.0)
	var ang     : float   = randf() * TAU
	var dist    : float   = randf_range(160.0, 270.0)
	_evento_pos = centro + Vector2(cos(ang), sin(ang)) * dist
	queue_redraw()
	# Avisa o jogador que algo apareceu no mapa
	if ui_node:
		var cor_ev : Color = ev.get("cor", Color(1.0, 0.82, 0.1)) as Color
		ui_node.mostrar_notificacao_consumivel("⚠ %s" % str(ev.get("texto", "")), cor_ev)


func coletar_evento() -> void:
	if _evento_ativo.is_empty(): return
	_resolver_evento(true)


func _resolver_evento(coletado: bool) -> void:
	var ev_id : String = str(_evento_ativo.get("id", ""))
	if coletado:
		match ev_id:
			"suprimento":
				var bonus : int = 30 + wave * 2
				gold += bonus
				if ui_node:
					ui_node.atualizar_hud(score, gold, wave)
					ui_node.mostrar_notificacao_consumivel("+%d ouro coletado!" % bonus, Color(1.0, 0.85, 0.1))
			"artilharia":
				if torre and is_instance_valid(torre):
					var dmg : float = torre.damage * 0.60
					for mob in get_tree().get_nodes_in_group("mobs"):
						if is_instance_valid(mob) and not (mob.get("morto") as bool):
							mob.receber_dano(dmg, true)
				if ui_node:
					ui_node.mostrar_notificacao_consumivel("Artilharia disparada!", Color(1.0, 0.5, 0.1))
			"reforco":
				if torre and is_instance_valid(torre):
					torre.damage *= 1.4
					get_tree().create_timer(10.0).timeout.connect(func():
						if torre and is_instance_valid(torre):
							torre.damage /= 1.4
					)
				if ui_node:
					ui_node.mostrar_notificacao_consumivel("+40% ataque por 10s!", Color(0.25, 1.0, 0.5))
			"espiao":
				var bonus_s : int = 150 + wave * 5
				score += bonus_s
				if ui_node:
					ui_node.atualizar_hud(score, gold, wave)
					ui_node.mostrar_notificacao_consumivel("+%d score! Espião neutralizado." % bonus_s, Color(1.0, 0.3, 0.7))
	else:
		# Evento ignorado: penalidade leve
		match ev_id:
			"espiao":
				if torre and is_instance_valid(torre):
					var pen : float = (torre.get("max_hp") as float) * 0.08
					torre.receber_dano(pen)
				if ui_node:
					ui_node.mostrar_notificacao_consumivel("Espião escapou! Torre danificada.", Color(1.0, 0.3, 0.3))
			"suprimento":
				if ui_node:
					ui_node.mostrar_notificacao_consumivel("Suprimento perdido...", Color(0.6, 0.6, 0.6))
	_evento_ativo = {}
	_evento_timer = 0.0
	_evento_pos   = Vector2.ZERO
	queue_redraw()
	# Agendar próximo evento se ainda abaixo do limite
	if _eventos_wave_n < 2 and estado == "jogando":
		_evento_delay = randf_range(6.0, 12.0)


# ── Callbacks chamados por Torre / Mob ────────────────────────────────────────

func mob_morreu(val_gold: int, val_score: int) -> void:
	var mult : float = 1.0 + (Salvar.melhorias["fortuna"] as int) * 0.15
	if Salvar.talento_ativo("f1"):
		mult += 0.30
	if Salvar.talento_ativo("f3") and randf() < 0.10:
		mult *= 4.0
	mult *= gold_mult_carta
	# B3 — Pilhagem Bárbara: kills com <30% HP valem 2× ouro
	if Salvar.talento_ativo("b3") and torre and is_instance_valid(torre):
		if (torre.hp / torre.max_hp) < 0.30:
			mult *= 2.0
	# Exter — Exterminador: próximos 3 kills valem 2×
	if Salvar.talento_ativo("exter"):
		if _exter_bonus_left > 0:
			mult  *= 2.0
			_exter_bonus_left -= 1
		_exter_kills_rapidos += 1
		if _exter_kills_timer <= 0.0:
			_exter_kills_timer = 1.0
		if _exter_kills_rapidos >= 3:
			_exter_bonus_left    = 3
			_exter_kills_rapidos = 0
	# Progressao normal agora e por mapa/wave. Abismo segue como modo proprio.
	var score_mult : float = 2.0 if modo_abismo else 1.0
	var gold_diff_mult : float = 1.0 if modo_abismo else 0.45
	gold += int(float(val_gold) * mult * gold_diff_mult)
	score       += int(float(val_score) * score_mult * score_mult_skin)
	wave_score  += int(float(val_score) * score_mult * score_mult_skin)
	mobs_mortos      += 1
	mobs_mortos_wave += 1
	if torre and is_instance_valid(torre):
		torre.on_mob_morreu()
	if ui_node:
		ui_node.atualizar_hud(score, gold, wave)
		ui_node.atualizar_kills(mobs_mortos_wave, mobs_na_wave)
	# T2 — Pulso Congelante: 8% de chance de congelar todos os mobs por 0.5s
	if Salvar.talento_ativo("t2") and randf() < 0.08:
		for mob in get_tree().get_nodes_in_group("mobs"):
			if is_instance_valid(mob):
				mob.set("gelo_slow", 1.0)
	# X4 — Carta do Acaso: 1.5% de chance de abrir seleção de carta (1× por wave, máx 4× por partida, só até wave 99)
	if Salvar.talento_ativo("x4") and not _x4_carta_pendente and not _x4_usado_wave and _x4_total_partida < 4 and wave < 100 and randf() < 0.015:
		_x4_carta_pendente = true
		_x4_total_partida += 1
		estado = "cartas"
		if ui_node:
			_sortear_e_mostrar_cartas(true)


func atualizar_boss_hp(hp: float, max_hp: float) -> void:
	if ui_node and is_instance_valid(ui_node):
		ui_node.call("atualizar_boss_hp", hp, max_hp)




func boss_morreu() -> void:
	# Mini-chefe abatido: dispara os efeitos "após boss" das cartas
	# (Overdrive, Recuperação Rápida) e celebra com shake
	_trigger_shake(10.0, 0.35)
	if torre and is_instance_valid(torre):
		torre.boss_morreu()


func mob_explodiu(pos: Vector2) -> void:
	if torre and is_instance_valid(torre) and torre.explosao_ativa:
		torre.explosao_em(pos)


func dano_boss_na_torre(dano: float) -> void:
	if token_disponivel:
		token_disponivel = false
		if ui_node: ui_node.usar_token()
		return
	_trigger_shake(14.0, 0.50)
	dano_na_torre(dano)


func aplicar_maldicao_torre(duracao: float) -> void:
	if torre and is_instance_valid(torre):
		torre.aplicar_maldicao(duracao)


func aplicar_punicao_perfuracao(duracao: float) -> void:
	if torre and is_instance_valid(torre):
		torre.aplicar_punicao_perfuracao(duracao)


func spawnar_mob_proximo(pos: Vector2, tipo_mob: String) -> void:
	var mob      = MOB_SCENE.instantiate()
	mob.tipo     = tipo_mob
	mob.wave_num = wave
	mob.jogo     = self
	mob.position = pos
	add_child(mob)
	mobs_na_wave += 1
	if ui_node:
		ui_node.atualizar_kills(mobs_mortos_wave, mobs_na_wave)


func aplicar_carta(efeito: String, val: float, id: String = "") -> void:
	var chave : String = id if id != "" else efeito
	_cartas_colhidas[chave] = (_cartas_colhidas.get(chave, 0) as int) + 1

	if efeito == "ouro":
		gold_mult_carta += val
	elif efeito == "saque":
		saque_bonus += val
	elif efeito == "cacador":
		cacador_fantasma = true
		# Revela imediatamente qualquer fantasma já em campo
		for mob in get_tree().get_nodes_in_group("mobs"):
			if is_instance_valid(mob) and mob.get("tipo") == "fantasma":
				mob.set("_invis_timer",    0.0)
				mob.set("_invis_revelado", true)
	elif torre and is_instance_valid(torre):
		torre.aplicar_carta(efeito, val)

	# Alquimista — 25% de chance de ganhar 1 cristal ao escolher carta
	if Salvar.talento_ativo("alquim") and randf() < 0.25:
		Salvar.depositar_cristais(1)

	_atualizar_build()

	# X4 — foi acionado no meio da wave: retoma o combate sem iniciar nova wave
	if _x4_carta_pendente:
		_x4_carta_pendente = false
		_x4_usado_wave     = true   # bloqueia até a próxima wave
		estado = "jogando"
		return
	_x4_carta_pendente = false

	if Salvar.pausa_auto_wave and ui_node:
		ui_node.mostrar_btn_iniciar_wave()
	else:
		_iniciar_wave()


func registrar_dano_causado(amount: float) -> void:
	dano_causado_total += amount


func registrar_morte_envenenado() -> void:
	if not Salvar.talento_ativo("s5"):
		return
	_s5_kills_veneno += 1
	if _s5_kills_veneno >= 50 and not _s5_carta_bonus:
		_s5_carta_bonus = true


func aplicar_carta_m4(efeito: String, val: float, id: String = "") -> void:
	# Aplica o efeito da carta SEM iniciar a wave — usado pelo M4 para dar 2 picks
	var chave : String = id if id != "" else efeito
	_cartas_colhidas[chave] = (_cartas_colhidas.get(chave, 0) as int) + 1
	if efeito == "ouro":
		gold_mult_carta += val
	elif efeito == "saque":
		saque_bonus += val
	elif efeito == "cacador":
		cacador_fantasma = true
		for mob in get_tree().get_nodes_in_group("mobs"):
			if is_instance_valid(mob) and mob.get("tipo") == "fantasma":
				mob.set("_invis_timer",    0.0)
				mob.set("_invis_revelado", true)
	elif torre and is_instance_valid(torre):
		torre.aplicar_carta(efeito, val)
	# Mostra a segunda seleção de carta (pick bônus)
	_sortear_e_mostrar_cartas()


func roubar_ouro(amount: int) -> void:
	var roubado : int = min(amount, gold)
	gold -= roubado
	if ui_node:
		ui_node.atualizar_hud(score, gold, wave)
		# Floater vermelho mostrando ouro perdido
		var pos_torre : Vector2 = Vector2(640, 360)
		if torre and is_instance_valid(torre):
			pos_torre = torre.global_position
		mostrar_dano(pos_torre + Vector2(randf_range(-20.0, 20.0), -30.0),
				float(roubado), Color(1.0, 0.82, 0.08))


func dano_na_torre(dano: float) -> void:
	_trigger_shake(5.0, 0.22)
	dano_recebido_total += dano
	if torre and is_instance_valid(torre):
		torre.receber_dano(dano)
		# T4 — Retrocesso Temporal: 1× por partida, restaura HP ao início da wave ao cair a 20%
		if Salvar.talento_ativo("t4") and not _t4_usado:
			if torre.hp / torre.max_hp <= 0.20 and _t4_hp_inicio > torre.hp:
				_t4_usado = true
				torre.hp  = _t4_hp_inicio


func _trigger_shake(intensity: float, duration: float) -> void:
	_shake_intensity = maxf(_shake_intensity, intensity)
	_shake_timer     = maxf(_shake_timer, duration)


func mostrar_dano(pos: Vector2, dano: float, cor: Color = Color(1.0, 0.88, 0.3)) -> void:
	if dano < 1.0:
		return   # ignora danos mínimos (evita spam)
	var now : int = Time.get_ticks_msec()
	var min_gap : int = 0
	if wave >= 220:
		min_gap = 70
	elif wave >= 120:
		min_gap = 42
	elif wave >= 60:
		min_gap = 18
	if min_gap > 0 and now - _dano_visual_last_ms < min_gap:
		return
	_dano_visual_last_ms = now
	var nodo = load("res://scripts/dano_flutuante.gd").new()
	nodo.position = pos + Vector2(randf_range(-10.0, 10.0), randf_range(-8.0, 0.0))
	add_child(nodo)
	var tamanho_px : int = 20 if dano >= 100.0 else 16
	nodo.call("iniciar", "-%d" % int(dano), cor, tamanho_px)


func registrar_impacto_combate(pos: Vector2, cor: Color, forte: bool = false) -> void:
	var now : int = Time.get_ticks_msec()
	var min_gap : int = 40 if wave >= 160 else 16
	if not forte and now - _impacto_visual_last_ms < min_gap:
		return
	_impacto_visual_last_ms = now
	_impactos_combate.append({
		"pos": pos,
		"cor": cor,
		"forte": forte,
		"dur": 0.42 if forte else 0.28,
		"timer": 0.42 if forte else 0.28,
	})
	if _impactos_combate.size() > 28:
		_impactos_combate.pop_front()
	_trigger_shake(4.5 if forte else 1.6, 0.12 if forte else 0.06)
	queue_redraw()


func game_over() -> void:
	if _game_over_confirmado:
		return
	if ui_node:
		ui_node.fechar_cartas()
		ui_node.fechar_overlay_boss()
	estado = "game_over"
	var custo_alma : int    = (max(3, 3 + wave / 5) if not _alma_usado else 0)
	var cb_alma    : Callable = (func(): reviver_com_alma(custo_alma)) if not _alma_usado else Callable()
	var tem_vela   : bool   = not _revive_loja_usado and Salvar.revive_loja_estoque > 0
	var cb_vela    : Callable = (func(): reviver_com_loja()) if tem_vela else Callable()
	if ui_node:
		ui_node.mostrar_game_over(score, wave, gold,
			custo_alma, cb_alma, tem_vela, cb_vela,
			func(): _finalizar_game_over())
	get_tree().paused = true


func _verificar_revive_loja() -> void:
	_finalizar_game_over()


func reviver_com_loja() -> void:
	if not Salvar.usar_revive_loja(): return
	gold = Salvar.ouro_banco
	_revive_loja_usado = true
	estado             = "jogando"
	get_tree().paused  = false
	Engine.time_scale  = 1.0
	if torre and is_instance_valid(torre):
		torre.hp        = torre.max_hp * 0.50
		torre.hit_flash = 0.0
		var push_dist : float = maxf((torre.range_r as float) * 2.0, 650.0)
		for mob in get_tree().get_nodes_in_group("mobs"):
			if not is_instance_valid(mob): continue
			var dir : Vector2 = (mob as Node2D).position - torre.position
			if dir.length() < push_dist:
				if dir.length() < 1.0:
					dir = Vector2(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0)).normalized()
				(mob as Node2D).position = torre.position + dir.normalized() * push_dist
	if ui_node:
		ui_node.fechar_tela_alma()
		ui_node.atualizar_hud(score, gold, wave)
		ui_node.mostrar_reviver_flash()


func _finalizar_game_over() -> void:
	if _game_over_confirmado: return
	_game_over_confirmado = true
	Salvar.limpar_checkpoint()  # morreu — sem retorno
	get_tree().paused = false
	Engine.time_scale = 1.0
	if ui_node and is_instance_valid(ui_node):
		ui_node.fechar_overlay_boss()
	# Soft-cap de renda: ganho da partida sofre diminishing returns se o banco ja esta alto.
	var _ganho_partida : int = gold - arena_ouro_inicio
	Salvar.ouro_banco = arena_ouro_inicio + Salvar.ajustar_ganho_ouro(arena_ouro_inicio, _ganho_partida)
	Salvar.atualizar_high_score(score)
	if modo_abismo:
		Salvar.atualizar_high_score_abismo(score)
	if Salvar.talento_ativo("f4"):
		Salvar.depositar_cristais(5)
	if Salvar.talento_ativo("veteran"):
		Salvar.depositar_cristais(5)
	Salvar.registrar_fim_partida(wave, score, gold, mobs_mortos, 0, _cartas_colhidas, modo_abismo)
	RankingOnline.verificar_e_enviar(Salvar.nome_jogador, score, wave)
	if Salvar.nome_jogador != "" and Salvar.senha_jogador != "" and not Salvar.save_bloqueado:
		RankingOnline.upload_save(Salvar.nome_jogador, Salvar.exportar_cloud())


func _confirmar_game_over() -> void:
	_finalizar_game_over()


func reviver_com_alma(custo: int) -> void:
	if Salvar.cristais < custo:
		return
	Salvar.cristais -= custo
	Salvar.salvar()
	_alma_usado = true
	estado      = "jogando"
	get_tree().paused = false
	Engine.time_scale = 1.0
	if torre and is_instance_valid(torre):
		torre.hp        = torre.max_hp * 0.35
		torre.hit_flash = 0.0
	if ui_node:
		ui_node.fechar_tela_alma()
		ui_node.atualizar_hud(score, gold, wave)
		ui_node.mostrar_reviver_flash()


func sair_da_partida() -> void:
	get_tree().paused = false
	Engine.time_scale = 1.0
	if ui_node:
		ui_node.fechar_cartas()
	var _ganho_partida : int = gold - arena_ouro_inicio
	Salvar.ouro_banco = arena_ouro_inicio + Salvar.ajustar_ganho_ouro(arena_ouro_inicio, _ganho_partida)
	Salvar.atualizar_high_score(score)
	if modo_abismo:
		Salvar.atualizar_high_score_abismo(score)
	if Salvar.talento_ativo("f4"):
		Salvar.depositar_cristais(5)
	if Salvar.talento_ativo("veteran"):
		Salvar.depositar_cristais(5)
	Salvar.registrar_fim_partida(wave, score, gold, mobs_mortos, 0, _cartas_colhidas, modo_abismo)
	Salvar.limpar_checkpoint()
	Som.parar_musica()
	get_tree().change_scene_to_file("res://scenes/Menu.tscn")


# ── Run checkpoint: pausar e retomar partida ─────────────────────────────────

func _capturar_estado_run() -> Dictionary:
	if not torre or not is_instance_valid(torre): return {}
	# Se em mid-wave, regride para repetir a mesma; se entre waves, continua da proxima
	var wave_save : int = maxi(0, wave - 1 if estado == "jogando" else wave)
	return {
		"wave": wave_save,
		"score": score,
		"gold": gold,
		"arena_ouro_inicio": arena_ouro_inicio,
		"gold_mult_carta": gold_mult_carta,
		"saque_bonus": saque_bonus,
		"cartas_colhidas": _cartas_colhidas.duplicate(true),
		"cartas_escolhidas": _cartas_escolhidas_jogador.duplicate(true),
		"ascensoes": Salvar.ascensoes,
		"modo_abismo": modo_abismo,
		"torre": {
			"hp": torre.hp, "max_hp": torre.max_hp,
			"damage": torre.damage, "fire_rate": torre.fire_rate,
			"range_r": torre.range_r,
			"damage_reduction": float(torre.get("damage_reduction") if torre.get("damage_reduction") != null else 0.0),
			"crit_chance": float(torre.get("crit_chance") if torre.get("crit_chance") != null else 0.0),
			"regen_rate": float(torre.get("regen_rate") if torre.get("regen_rate") != null else 0.0),
			"veneno_dps": float(torre.get("veneno_dps") if torre.get("veneno_dps") != null else 0.0),
			"raio_dano": float(torre.get("raio_dano") if torre.get("raio_dano") != null else 0.0),
			"pierce_count": int(torre.get("pierce_count") if torre.get("pierce_count") != null else 0),
			"multi_shot": bool(torre.get("multi_shot") if torre.get("multi_shot") != null else false),
			"multi_lvl": int(torre.get("multi_lvl") if torre.get("multi_lvl") != null else 0),
			"chama_bonus_por_kill": float(torre.get("chama_bonus_por_kill") if torre.get("chama_bonus_por_kill") != null else 0.0),
			"corrente_ativa": bool(torre.get("corrente_ativa") if torre.get("corrente_ativa") != null else false),
			"explosao_ativa": bool(torre.get("explosao_ativa") if torre.get("explosao_ativa") != null else false),
			"overdrive_ativa": bool(torre.get("overdrive_ativa") if torre.get("overdrive_ativa") != null else false),
			"armadura_inv": bool(torre.get("armadura_inv") if torre.get("armadura_inv") != null else false),
			"bencao_ativa": bool(torre.get("bencao_ativa") if torre.get("bencao_ativa") != null else false),
			"bencao_kills": int(torre.get("bencao_kills") if torre.get("bencao_kills") != null else 0),
			"fragmento_ativa": bool(torre.get("fragmento_ativa") if torre.get("fragmento_ativa") != null else false),
		}
	}


func _restaurar_run_do_checkpoint(dados: Dictionary) -> void:
	wave               = int(dados.get("wave", 0))
	score              = int(dados.get("score", 0))
	gold               = int(dados.get("gold", 0))
	arena_ouro_inicio  = int(dados.get("arena_ouro_inicio", gold))
	gold_mult_carta    = float(dados.get("gold_mult_carta", 1.0))
	saque_bonus        = float(dados.get("saque_bonus", 0.0))
	_cartas_colhidas   = (dados.get("cartas_colhidas", {}) as Dictionary).duplicate(true)
	_cartas_escolhidas_jogador = (dados.get("cartas_escolhidas", []) as Array).duplicate(true)
	var td : Dictionary = dados.get("torre", {}) as Dictionary
	if td.is_empty() or not torre or not is_instance_valid(torre): return
	torre.max_hp               = float(td.get("max_hp", torre.max_hp))
	torre.hp                   = float(td.get("hp", torre.max_hp))
	torre.damage               = float(td.get("damage", torre.damage))
	torre.fire_rate            = float(td.get("fire_rate", torre.fire_rate))
	torre.range_r              = float(td.get("range_r", torre.range_r))
	torre.set("damage_reduction", float(td.get("damage_reduction", 0.0)))
	torre.set("crit_chance",      float(td.get("crit_chance", 0.0)))
	torre.set("regen_rate",       float(td.get("regen_rate", 0.0)))
	torre.set("veneno_dps",       float(td.get("veneno_dps", 0.0)))
	torre.set("raio_dano",        float(td.get("raio_dano", 0.0)))
	torre.set("pierce_count",     int(td.get("pierce_count", 0)))
	torre.set("multi_shot",       bool(td.get("multi_shot", false)))
	torre.set("multi_lvl",        int(td.get("multi_lvl", 0)))
	torre.set("chama_bonus_por_kill", float(td.get("chama_bonus_por_kill", 0.0)))
	torre.set("corrente_ativa",   bool(td.get("corrente_ativa", false)))
	torre.set("explosao_ativa",   bool(td.get("explosao_ativa", false)))
	torre.set("overdrive_ativa",  bool(td.get("overdrive_ativa", false)))
	torre.set("armadura_inv",     bool(td.get("armadura_inv", false)))
	torre.set("bencao_ativa",     bool(td.get("bencao_ativa", false)))
	torre.set("bencao_kills",     int(td.get("bencao_kills", 0)))
	torre.set("fragmento_ativa",  bool(td.get("fragmento_ativa", false)))


func pausar_e_sair_da_partida() -> void:
	var dados := _capturar_estado_run()
	if dados.is_empty(): return
	Salvar.salvar_checkpoint(dados)
	get_tree().paused = false
	Engine.time_scale = 1.0
	Som.parar_musica()
	get_tree().change_scene_to_file("res://scenes/Menu.tscn")


func _sortear_e_mostrar_cartas(is_x4: bool = false) -> void:
	if not ui_node:
		return
	if _tut_ativo and wave == 1:
		_tut_mostrar_dica("Escolha uma carta para melhorar sua torre!\nCada carta tem efeitos únicos.", 5.0)
	# Pool ponderada: filtra por min_wave e limite de picks, repete pelo peso
	var pool : Array = []
	for carta in CARTAS:
		# e1: Raio Arcano disponível desde wave 1
		if _carta_bloqueada_arena(carta):
			continue
		var min_w : int = carta["min_wave"] as int
		if (carta["id"] as String) == "raio" and Salvar.talento_ativo("e1"):
			min_w = 1
		if wave < min_w:
			continue
		var picks : int = (_cartas_colhidas.get(carta["id"] as String, 0) as int)
		if picks >= _carta_max_picks(carta):
			continue
		# "fragmento" só aparece após 3 picks de "pierce"
		if (carta["id"] as String) == "fragmento" and (_cartas_colhidas.get("pierce", 0) as int) < 3:
			continue
		# "corrente": fusão pierce nv3 + raio nv3 (ou talento e4 remove requisito)
		if (carta["id"] as String) == "corrente" and not Salvar.talento_ativo("e4"):
			if (_cartas_colhidas.get("pierce", 0) as int) < 3: continue
			if (_cartas_colhidas.get("raio",   0) as int) < 3: continue
		# "tempestade" depende do Raio Arcano — sem raio a carta não faz nada
		if (carta["id"] as String) == "tempestade" and (_cartas_colhidas.get("raio", 0) as int) < 1:
			continue
		# cartas de alcance somem depois que a torre atinge o alcance máximo
		if (carta["efeito"] as String) == "alcance" and torre and is_instance_valid(torre) and torre.range_r >= 450.0:
			continue
		var peso : int = carta["peso"] as int
		for _w in range(peso):
			pool.append(carta)
	pool.shuffle()

	# Quantidade de cartas: base 3, +1 com m1, +1 com s5 bônus
	var max_cartas : int = 3
	if Salvar.talento_ativo("m1"): max_cartas += 1
	if _s5_carta_bonus:            max_cartas += 1; _s5_carta_bonus = false

	# Coleta até max_cartas únicas (por id)
	var vistas : Dictionary = {}
	var escolha : Array = []
	for c in pool:
		var cid : String = c["id"] as String
		if not vistas.has(cid):
			vistas[cid] = true
			escolha.append(c)
			if escolha.size() >= max_cartas:
				break

	# Pool vazio: fallback com dano / cadência / vida (comuns) sem limite de picks.
	if escolha.is_empty():
		for carta in CARTAS:
			var ef : String = carta["efeito"] as String
			if ef in ["dano", "cadencia", "vida"] and (carta["raridade"] as String) == "comum":
				var c : Dictionary = (carta as Dictionary).duplicate()
				c["max_picks"] = 99
				escolha.append(c)
				if escolha.size() >= max_cartas:
					break

	# M2 — Alquimia de Cartas: cartas comuns têm 30% chance de virar incomum
	if Salvar.talento_ativo("m2"):
		for i in range(escolha.size()):
			var c := (escolha[i] as Dictionary).duplicate()
			if (c["raridade"] as String) == "comum" and randf() < 0.30:
				c = _promover_carta(c)
				escolha[i] = c

	ui_node.mostrar_cartas(escolha, is_x4)


# Escala val e desc de uma carta ao promovê-la para raridade superior.
func _promover_carta(c: Dictionary) -> Dictionary:
	c["raridade"] = "incomum"
	var ef  : String = c["efeito"] as String
	var val : float  = c["val"]    as float
	# raio: promove para nível 2 de imediato (torre.gd usa int(val))
	if ef == "raio":
		c["val"]  = 2.0
		c["desc"] = "Raio Nv2 imediato\n(+90 dano, intervalo ~3.65s)"
		return c
	# Efeitos com val numérico diretamente escalável
	const ESCALAVEIS := ["dano", "cadencia", "alcance", "vida", "regen",
		"veneno", "speed", "ouro", "critico", "chama", "reducao", "armadura_i", "saque"]
	if ef not in ESCALAVEIS:
		return c
	val *= 1.5
	c["val"] = val
	match ef:
		"dano":
			c["desc"] = "+%d de dano\nnesta partida" % int(val)
		"cadencia":
			c["desc"] = "+%.1f tiros/s\nnesta partida" % val
		"alcance":
			c["desc"] = "+%d de alcance\nnesta partida" % int(val)
		"vida":
			c["desc"] = "Cura %d HP\ne +%d vida máxima" % [int(val * 1.5), int(val)]
		"regen":
			c["desc"] = "+%d HP/s de\nregeneração" % int(val)
		"veneno":
			c["desc"] = "+%d dano/s por 4s\nem inimigos acertados" % int(val)
		"speed":
			c["desc"] = "+%d velocidade\nde projétil" % int(val)
		"ouro":
			c["desc"] = "+%d%% de ouro\nem cada kill" % int(val * 100.0)
		"critico":
			c["desc"] = "+%d%% chance de\n3× dano por tiro" % int(val * 100.0)
		"chama":
			c["desc"] = "+%.1f dano permanente\npor kill (máx +200 total)" % val
		"reducao":
			c["desc"] = "-%d%% dano\nrecebido" % int(val * 100.0)
		"armadura_i":
			c["desc"] = "Inimigos <30%% HP\nrecebem +%d%% dano" % int(val * 100.0)
		"saque":
			c["desc"] = "+%d%% do score da wave\ncomo ouro extra" % int(val * 100.0)
	return c


func _checar_identidade_build() -> String:
	if not torre or not is_instance_valid(torre): return ""
	var t := torre
	var s  := Salvar

	# Builds específicas (verificadas primeiro — ordem de raridade/especificidade)
	if t.gelo_ativo and t.veneno_dps >= 8.0 and s.talento_ativo("predador"):
		return "PREDADOR GLACIAL"
	if t.tempestade_ativa and t.raio_nivel >= 3 and t.fissura_ativa:
		return "TEMPESTADE PERFEITA"
	if t.corrente_ativa and t.pierce_count >= 2 and t.raio_nivel >= 2:
		return "ARCO ELÉTRICO"
	if t.bencao_ativa and t.carga_ativa and t.crit_chance >= 0.30:
		return "GOLPE DO DESTINO"
	if t.corrente_ativa and t.pierce_count >= 3:
		return "PERFURADOR CAÓTICO"
	if t.veneno_dps >= 20.0 and s.talento_ativo("s4") and t.crit_chance >= 0.15:
		return "CACADOR DE SOMBRAS"
	if t.explosao_ativa and t.pierce_splash_radius > 0.0 and t.pierce_count >= 2:
		return "EXPLOSAO EM CADEIA"
	if t.multi_lvl >= 3 and t.overdrive_ativa:
		return "ARTILHARIA PESADA"
	if t.tempestade_ativa and t.raio_nivel >= 4:
		return "LENDA DO RELAMPAGO"
	if t.veneno_dps >= 24.0 and s.talento_ativo("s3") and s.talento_ativo("s4"):
		return "SENHOR DO VENENO"
	if s.talento_ativo("b2") and s.talento_ativo("b4") and t.regen_rate >= 6.0:
		return "FENIX BERSERKER"
	if t.gelo_ativo and t.multi_lvl >= 2 and t.rajada_ativa:
		return "TORRENTE GELADA"
	if t.raio_nivel >= 3 and s.talento_ativo("e3"):
		return "MAGO DO RELAMPAGO"
	if t.damage >= 280.0 and t.crit_chance >= 0.15:
		return "CANHAO SOLAR"
	if t.fire_rate >= 4.0 and t.multi_lvl >= 2:
		return "METRALHADORA INFERNAL"
	# Genéricas
	if t.raio_nivel >= 2:   return "CONDUTOR ARCANO"
	if t.gelo_ativo:        return "CAMPO GLACIAL"
	if t.veneno_dps >= 8.0: return "VENOMANTE"
	if t.multi_lvl >= 2:    return "ARTILHEIRO"
	if t.damage >= 200.0:   return "DESTRUIDOR"
	if t.fire_rate >= 3.5:  return "TORRENTE"
	return ""


func _atualizar_build() -> void:
	var novo : String = _checar_identidade_build()
	if novo != _build_nome:
		_build_nome = novo
		if ui_node and is_instance_valid(ui_node):
			ui_node.atualizar_build_nome(_build_nome)


func reroll_cartas(custo: int) -> void:
	# X3 — Reroll Gratuito: 15% de chance de não custar ouro
	var custo_real : int = custo
	if Salvar.talento_ativo("x3") and randf() < 0.15:
		custo_real = 0
	if gold < custo_real:
		return
	gold -= custo_real
	if ui_node:
		ui_node.atualizar_hud(score, gold, wave)
	_sortear_e_mostrar_cartas()


func aplicar_upgrade(tipo: String) -> void:
	if is_instance_valid(torre):
		torre.aplicar_upgrade(tipo)
	_iniciar_wave()


func get_status_data() -> Dictionary:
	var d := {
		"wave":        wave,
		"score":       score,
		"gold":        gold,
		"mobs_mortos": mobs_mortos,
		"boss_mortos": 0,
		"cartas":      _cartas_colhidas.duplicate(),
		"melhorias":   Salvar.melhorias.duplicate(),
		# stats da torre (zerados se torre inválida)
		"hp": 0.0, "max_hp": 0.0, "damage": 0.0, "range_r": 0.0,
		"fire_rate": 0.0, "regen_rate": 0.0, "damage_reduction": 0.0,
		"pierce_count": 0, "multi_lvl": 0, "chama_bonus_por_kill": 0.0,
		"raio_nivel": 0, "raio_dano": 0.0,
		"corrente_ativa": false, "veneno_dps": 0.0, "crit_chance": 0.0,
		"explosao_ativa": false, "overdrive_ativa": false,
		"armadura_inv": false, "bencao_ativa": false, "bencao_kills": 0,
		"recuperacao_ativa": false, "imortal_ativo": false,
		"rajada_ativa": false, "carga_ativa": false, "gelo_ativo": false,
		"dano_causado": dano_causado_total,
		"dano_recebido": dano_recebido_total,
		"atributos_bonus": {},
		"atributos_niveis": {},
		"habil_cd_max": 0.0,
		"gold_mult_total": gold_mult_carta,
		"score_mult_total": score_mult_skin,
	}
	if torre and is_instance_valid(torre):
		d["hp"]                   = torre.hp
		d["max_hp"]               = torre.max_hp
		d["damage"]               = torre.damage
		d["range_r"]              = torre.range_r
		d["fire_rate"]            = torre.fire_rate
		d["regen_rate"]           = torre.regen_rate
		d["damage_reduction"]     = torre.damage_reduction
		d["pierce_count"]         = torre.pierce_count
		d["multi_lvl"]            = torre.multi_lvl
		d["chama_bonus_por_kill"] = torre.chama_bonus_por_kill
		d["raio_nivel"]           = torre.raio_nivel
		d["raio_dano"]            = torre.raio_dano
		d["corrente_ativa"]       = torre.corrente_ativa
		d["veneno_dps"]           = torre.veneno_dps
		d["crit_chance"]          = torre.crit_chance
		d["explosao_ativa"]       = torre.explosao_ativa
		d["overdrive_ativa"]      = torre.overdrive_ativa
		d["armadura_inv"]         = torre.armadura_inv
		d["bencao_ativa"]         = torre.bencao_ativa
		d["bencao_kills"]         = torre.bencao_kills
		d["recuperacao_ativa"]    = torre.recuperacao_ativa
		d["imortal_ativo"]        = torre.imortal_ativo
		d["rajada_ativa"]         = torre.rajada_ativa
		d["carga_ativa"]          = torre.carga_ativa
		d["gelo_ativo"]           = torre.gelo_ativo
	d["atributos_bonus"] = Salvar.bonus_atributos_conta()
	d["atributos_niveis"] = Salvar.atributos_conta.duplicate()
	d["habil_cd_max"] = _habil_cd_max_atual()
	d["gold_mult_total"] = gold_mult_carta
	d["score_mult_total"] = score_mult_skin
	return d


# ── Tutorial helpers ──────────────────────────────────────────────────────────
func _tut_mostrar_dica(texto: String, duracao: float) -> void:
	_tut_fechar_dica()
	var cl := CanvasLayer.new()
	cl.layer = 12
	_tut_dica_node = cl
	add_child(cl)

	var vp := get_viewport().get_visible_rect().size
	var pw : float = minf(vp.x * 0.72, 480.0)
	var px : float = (vp.x - pw) * 0.5
	var py : float = vp.y * 0.12

	var panel := Panel.new()
	panel.position = Vector2(px, py)
	panel.size     = Vector2(pw, 0)
	var ss := StyleBoxFlat.new()
	ss.bg_color          = Color(0.04, 0.06, 0.12, 0.88)
	ss.border_color      = Color(0.3, 0.6, 1.0, 0.9)
	ss.set_border_width_all(2)
	ss.set_corner_radius_all(10)
	ss.set_content_margin_all(12)
	panel.add_theme_stylebox_override("panel", ss)
	cl.add_child(panel)

	var lbl := Label.new()
	lbl.text                                       = texto
	lbl.autowrap_mode                              = TextServer.AUTOWRAP_WORD_SMART
	lbl.horizontal_alignment                       = HORIZONTAL_ALIGNMENT_CENTER
	lbl.add_theme_font_size_override("font_size", 16)
	lbl.add_theme_color_override("font_color", Color(0.9, 0.95, 1.0))
	lbl.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.7))
	lbl.add_theme_constant_override("shadow_offset_x", 1)
	lbl.add_theme_constant_override("shadow_offset_y", 1)
	lbl.size = Vector2(pw - 24, 0)
	lbl.position = Vector2(12, 12)
	panel.add_child(lbl)
	await get_tree().process_frame
	panel.size.y = lbl.size.y + 24

	var tw := create_tween()
	tw.tween_interval(duracao)
	tw.tween_callback(_tut_fechar_dica)


func _tut_fechar_dica() -> void:
	if is_instance_valid(_tut_dica_node):
		_tut_dica_node.queue_free()
	_tut_dica_node = null
