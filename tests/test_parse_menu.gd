extends Node
## Parse-check rápido dos scripts tocados (load() == null se houver erro de parse).

func _ready() -> void:
	for caminho in [
		"res://scripts/menu.gd",
		"res://scripts/build_config.gd",
		"res://scripts/ui.gd",
		"res://scripts/main.gd",
		"res://scripts/mob.gd",
		"res://scripts/torre.gd",
		"res://scripts/projetil.gd",
		"res://scripts/partida/painel_comando.gd",
		"res://scripts/partida/arco_eletrico.gd",
		"res://scripts/ranking_online.gd",
		"res://scripts/menu/contas.gd",
		"res://scripts/menu/ranking.gd",
		"res://scripts/menu/config_mapas.gd",
		"res://scripts/menu/loja.gd",
		"res://scripts/menu/inventario.gd",
		"res://scripts/talentos_v2.gd",
		"res://scripts/auth_supabase.gd",
		"res://scripts/notificacoes.gd",
	]:
		if load(caminho) == null:
			push_error("FALHA: %s nao compilou" % caminho)
			get_tree().quit(1)
			return
	print("TESTE parse-menu: OK (todos os scripts tocados compilam)")
	get_tree().quit(0)
