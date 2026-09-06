extends Node2D
## Mob falso p/ testes: registra dano recebido, entra no grupo "mobs".
var recebeu : float = 0.0
var ultimo_crit : bool = false
var morto : bool = false
var max_hp : float = 100.0
var hp : float = 100.0
var veneno_dps : float = 0.0
var veneno_timer : float = 0.0
var queima_dps : float = 0.0
var queima_timer : float = 0.0
func _ready() -> void:
	add_to_group("mobs")
func receber_dano(d: float, _explosivo: bool = false, critico: bool = false) -> void:
	recebeu += d
	ultimo_crit = critico
	hp -= d
