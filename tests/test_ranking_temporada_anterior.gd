extends Node

var _falhas: Array[String] = []

const RankingOnlineScript := preload("res://scripts/ranking_online.gd")
const MenuScript := preload("res://scripts/menu.gd")


func _ready() -> void:
	var ranking = RankingOnlineScript.new()
	_test_url_top3_temporada(ranking)
	_test_parse_ranking_entries(ranking)
	ranking.free()
	_test_render_campeoes_faixa()
	_finalizar()


func _test_url_top3_temporada(ranking: Node) -> void:
	_esperar(ranking.has_method("_ranking_temporada_url"), "RankingOnline deve expor _ranking_temporada_url().")
	if not ranking.has_method("_ranking_temporada_url"):
		return
	var url: String = ranking.call("_ranking_temporada_url", 4, 3)
	_esperar(url.contains("order=wave.desc,score.desc"), "URL deve ordenar por wave e score.")
	_esperar(url.contains("limit=3"), "URL dos campeoes deve limitar top 3.")
	_esperar(url.contains("temporada=eq.4"), "URL deve filtrar a temporada solicitada.")
	_esperar(url.contains("select=nome,score,wave,temporada,criado_em,avatar_idx,ascensoes"), "URL deve selecionar os campos usados no ranking.")


func _test_parse_ranking_entries(ranking: Node) -> void:
	_esperar(ranking.has_method("_parse_ranking_entries"), "RankingOnline deve expor _parse_ranking_entries().")
	if not ranking.has_method("_parse_ranking_entries"):
		return
	var body := JSON.stringify([
		{"nome": "Cyron", "score": 1000, "wave": 50},
		{"nome": "Dante", "score": 900, "wave": 44}
	]).to_utf8_buffer()
	var entradas: Array = ranking.call("_parse_ranking_entries", body)
	_esperar(entradas.size() == 2, "Parser deve devolver as entradas do JSON.")
	if entradas.size() >= 2:
		_esperar(str((entradas[0] as Dictionary).get("nome", "")) == "Cyron", "Parser deve preservar o primeiro nome.")
		_esperar(int((entradas[1] as Dictionary).get("wave", 0)) == 44, "Parser deve preservar wave.")


func _test_render_campeoes_faixa() -> void:
	var menu = MenuScript.new()
	var cont := Control.new()
	cont.size = Vector2(900, 26)
	menu.set("_ranking_campeoes_cont", cont)
	menu.call("_render_campeoes_temporada_anterior", 0, [
		{"nome": "Boss Yakushi", "score": 760176, "wave": 151},
		{"nome": "Lamen", "score": 232660, "wave": 49},
		{"nome": "Yuji", "score": 191909, "wave": 46}
	])
	_esperar(cont.get_child_count() >= 4, "Faixa deve renderizar titulo e campeoes.")
	if cont.get_child_count() >= 2 and cont.get_child(1) is Label:
		var txt := (cont.get_child(1) as Label).text
		_esperar(txt.contains("TOP 1"), "Faixa deve mostrar TOP 1.")
		_esperar(txt.contains("760K"), "Faixa deve usar score compacto.")
	cont.free()
	menu.free()


func _esperar(condicao: bool, msg: String) -> void:
	if not condicao:
		_falhas.append(msg)


func _finalizar() -> void:
	if _falhas.is_empty():
		print("OK ranking temporada anterior")
		get_tree().quit(0)
	else:
		for falha in _falhas:
			push_error(falha)
		get_tree().quit(1)
