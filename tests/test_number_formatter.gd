extends SceneTree

var _falhas: Array[String] = []

const NumberFormatter := preload("res://scripts/number_formatter.gd")


func _init() -> void:
	_esperar(NumberFormatter.compact_int(0) == "0", "Zero deve ficar sem sufixo.")
	_esperar(NumberFormatter.compact_int(999) == "999", "999 deve ficar completo.")
	_esperar(NumberFormatter.compact_int(1000) == "1.00K", "1000 deve virar 1.00K.")
	_esperar(NumberFormatter.compact_int(12500) == "12.5K", "12500 deve virar 12.5K.")
	_esperar(NumberFormatter.compact_int(760176) == "760K", "760176 deve virar 760K.")
	_esperar(NumberFormatter.compact_int(1000000) == "1.00M", "1M deve usar M.")
	_esperar(NumberFormatter.compact_int(1534000000) == "1.53B", "1.534B deve virar 1.53B.")
	_esperar(NumberFormatter.compact_int(1000000000000) == "1.00T", "1T deve usar T.")
	_esperar(NumberFormatter.compact_int(-1534) == "-1.53K", "Valores negativos devem manter sinal.")
	_finalizar()


func _esperar(condicao: bool, msg: String) -> void:
	if not condicao:
		_falhas.append(msg)


func _finalizar() -> void:
	if _falhas.is_empty():
		print("OK number formatter")
		quit(0)
	else:
		for falha in _falhas:
			push_error(falha)
		quit(1)
