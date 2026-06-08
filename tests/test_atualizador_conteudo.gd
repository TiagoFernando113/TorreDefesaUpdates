extends Node

var _falhas: Array[String] = []


func _ready() -> void:
	var build_config: Node = preload("res://scripts/build_config.gd").new()
	_testar_build_avulsa_android_permite_update_externo(build_config)
	var atualizador: Node = preload("res://scripts/atualizador.gd").new()
	_testar_manifest_apk_compatibilidade(atualizador)
	_testar_manifest_valido(atualizador)
	_testar_pacote_novo_e_seguro(atualizador)
	_testar_pacote_antigo_ou_inseguro(atualizador)
	_finalizar()


func _testar_build_avulsa_android_permite_update_externo(build_config: Node) -> void:
	var metodo := "_should_allow_external_apk_update"
	_esperar(build_config.has_method(metodo), "BuildConfig deve expor regra testavel de update externo.")
	if not build_config.has_method(metodo):
		return
	_esperar(build_config.call(metodo, false, false), "PC avulso deve permitir update externo.")
	_esperar(build_config.call(metodo, true, false), "Android avulso/GitHub deve permitir update externo.")
	_esperar(not build_config.call(metodo, true, true), "Build de loja deve bloquear update externo de APK.")


func _testar_manifest_apk_compatibilidade(atualizador: Node) -> void:
	var antigo: Dictionary = _call_required(atualizador, "_normalizar_manifest_apk", [{
		"versao": 11,
		"url": "https://example.com/cyrondefense.apk",
		"notas": "V11 pronta."
	}]) as Dictionary
	_esperar(int(antigo.get("version", 0)) == 11, "Manifest APK antigo deve mapear versao para version.")
	_esperar(str(antigo.get("apk_url", "")) == "https://example.com/cyrondefense.apk", "Manifest APK antigo deve mapear url para apk_url.")

	var novo: Dictionary = _call_required(atualizador, "_normalizar_manifest_apk", [{
		"version": 12,
		"apk_url": "https://example.com/cyrondefense_v12.apk",
		"notes": "V12 pronta."
	}]) as Dictionary
	_esperar(int(novo.get("version", 0)) == 12, "Manifest APK novo deve preservar version.")
	_esperar(str(novo.get("apk_url", "")) == "https://example.com/cyrondefense_v12.apk", "Manifest APK novo deve preservar apk_url.")


func _testar_manifest_valido(atualizador: Node) -> void:
	var manifest: Variant = _call_required(atualizador, "_parse_content_manifest", [JSON.stringify({
		"version": 3,
		"packs": [
			{
				"id": "mapas",
				"version": 2,
				"url": "https://example.com/mapas_v2.pck",
				"sha256": "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa",
				"kind": "assets"
			}
		],
		"configs": [
			{
				"id": "balance",
				"version": 4,
				"url": "https://example.com/balance_v4.json",
				"sha256": "bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb"
			}
		]
	})])
	_esperar(manifest is Dictionary, "Manifest valido deve virar Dictionary.")
	_esperar(int(manifest.get("version", 0)) == 3, "Manifest deve preservar versao.")
	_esperar((manifest.get("packs", []) as Array).size() == 1, "Manifest deve preservar packs.")
	_esperar((manifest.get("configs", []) as Array).size() == 1, "Manifest deve preservar configs.")


func _testar_pacote_novo_e_seguro(atualizador: Node) -> void:
	var pack: Dictionary = {
		"id": "mapas",
		"version": 5,
		"url": "https://github.com/usuario/repo/releases/download/v5/mapas_v5.pck",
		"sha256": "0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef",
		"kind": "assets"
	}
	_esperar(_call_required(atualizador, "_should_download_content_pack", [pack, {"mapas": 4}]), "Pack assets mais novo deve baixar.")
	_esperar(_call_required(atualizador, "_content_local_path", [pack]) == "user://content_packs/mapas_v5.pck", "Caminho local deve ser deterministico.")


func _testar_pacote_antigo_ou_inseguro(atualizador: Node) -> void:
	var base: Dictionary = {
		"id": "mapas",
		"version": 5,
		"url": "https://example.com/mapas_v5.pck",
		"sha256": "0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef",
		"kind": "assets"
	}
	_esperar(not _call_required(atualizador, "_should_download_content_pack", [base, {"mapas": 5}]), "Pack da mesma versao nao deve baixar.")
	var script_pack: Dictionary = base.duplicate()
	script_pack["kind"] = "scripts"
	script_pack["version"] = 6
	_esperar(not _call_required(atualizador, "_should_download_content_pack", [script_pack, {"mapas": 5}]), "Pack de scripts deve ser bloqueado.")
	var sem_hash: Dictionary = base.duplicate()
	sem_hash["version"] = 6
	sem_hash["sha256"] = ""
	_esperar(not _call_required(atualizador, "_should_download_content_pack", [sem_hash, {"mapas": 5}]), "Pack sem SHA256 deve ser bloqueado.")
	var url_ruim: Dictionary = base.duplicate()
	url_ruim["version"] = 6
	url_ruim["url"] = "ftp://example.com/mapas_v6.pck"
	_esperar(not _call_required(atualizador, "_should_download_content_pack", [url_ruim, {"mapas": 5}]), "Pack sem HTTPS deve ser bloqueado.")


func _call_required(obj: Object, metodo: String, args: Array) -> Variant:
	if not obj.has_method(metodo):
		_falhas.append("Metodo ausente: %s" % metodo)
		return null
	return obj.callv(metodo, args)


func _esperar(condicao: bool, msg: String) -> void:
	if not condicao:
		_falhas.append(msg)


func _finalizar() -> void:
	if _falhas.is_empty():
		print("OK atualizador conteudo")
		get_tree().quit(0)
	else:
		for falha in _falhas:
			push_error(falha)
		get_tree().quit(1)
