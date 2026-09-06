extends Node2D
## Projétil ISOLADO: Raio Orbital (arma Bombardeio Orbital, manual).
## Um feixe desce do céu no ponto clicado e explode em ÁREA. Carregado com
## guarda; se falhar, a torre só não bombardeia (não trava a partida).

var alvo_pos   : Vector2 = Vector2.ZERO
var dano       : float = 0.0
var raio       : float = 110.0
var mobs_group : String = "mobs"
var cor        : Color = Color(0.5, 0.85, 1.0)

const T_DESCIDA  : float = 0.16   # feixe desce
const T_EXPLOSAO : float = 0.34   # explosão + fade
const ALTURA     : float = 680.0  # de onde o feixe "vem" (acima do ponto)

var _t        : float = 0.0
var _fase     : String = "descida"   # descida → explosao
var _aplicou  : bool = false
var _mini     : bool = false
var _crit     : bool = false

func set_crit(c: bool) -> void:
	_crit = c

func set_mini(m: bool) -> void:
	_mini = m
	if m:
		cor = Color(0.6, 0.72, 0.85)   # mais apagado = mini raio (dano reduzido)

func iniciar(ate: Vector2, dano_v: float, raio_v: float, grupo: String) -> void:
	alvo_pos        = ate
	dano            = dano_v
	raio            = raio_v
	mobs_group      = grupo
	global_position = ate   # nó no ponto; desenha em coords locais

func _process(delta: float) -> void:
	_t += delta
	queue_redraw()
	if _fase == "descida":
		if _t >= T_DESCIDA:
			_explodir()
	else:
		if _t >= T_DESCIDA + T_EXPLOSAO:
			queue_free()

func _explodir() -> void:
	_fase = "explosao"
	if not _aplicou:
		_aplicou = true
		for mob in get_tree().get_nodes_in_group(mobs_group):
			if not is_instance_valid(mob): continue
			if mob.get("imune_aoe") == true: continue
			if alvo_pos.distance_to((mob as Node2D).global_position) <= raio:
				if mob.has_method("receber_dano"):
					mob.receber_dano(dano, true, _crit)
		if typeof(Som) != TYPE_NIL and Som.has_method("impacto"):
			Som.impacto()

func _draw() -> void:
	if _fase == "descida":
		var p : float = clampf(_t / T_DESCIDA, 0.0, 1.0)
		var ytip : float = -ALTURA * (1.0 - p)    # ponta do feixe descendo até 0
		draw_line(Vector2(0.0, -ALTURA), Vector2(0.0, ytip), Color(cor.r, cor.g, cor.b, 0.45), 6.0)
		draw_line(Vector2(0.0, -ALTURA), Vector2(0.0, ytip), Color(1.0, 1.0, 1.0, 0.7), 2.0)
		# Marcador de mira no chão
		draw_arc(Vector2.ZERO, raio, 0.0, TAU, 32, Color(cor.r, cor.g, cor.b, 0.40), 2.0)
	else:
		var p : float = clampf((_t - T_DESCIDA) / T_EXPLOSAO, 0.0, 1.0)
		var a : float = 1.0 - p
		# Coluna cheia brilhando + explosão expandindo
		draw_line(Vector2(0.0, -ALTURA), Vector2.ZERO, Color(cor.r, cor.g, cor.b, 0.45 * a), 12.0)
		draw_line(Vector2(0.0, -ALTURA), Vector2.ZERO, Color(1.0, 1.0, 1.0, 0.65 * a), 3.0)
		var r : float = raio * (0.5 + 0.5 * p)
		draw_circle(Vector2.ZERO, r,        Color(cor.r, cor.g, cor.b, 0.30 * a))
		draw_circle(Vector2.ZERO, r * 0.6,  Color(0.80, 0.95, 1.0, 0.50 * a))
		draw_circle(Vector2.ZERO, r * 0.3,  Color(1.0, 1.0, 1.0, 0.80 * a))
