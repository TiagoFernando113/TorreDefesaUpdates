extends Node
## Valida Tier 1 anti-cheat: save gravado encriptado + migração de JSON legado.

func _ready() -> void:
	var tmp := "user://_test_cripto.tmp"
	var conteudo := JSON.stringify({"ouro_banco": 12345, "cristais": 678, "nome": "teste"})

	# 1) Escrita segura: o arquivo cru NÃO deve ser JSON legível (está encriptado)
	if not Salvar._escrever_seguro(tmp, conteudo):
		push_error("FALHA: _escrever_seguro retornou false")
		get_tree().quit(1)
		return
	var bruto := FileAccess.open(tmp, FileAccess.READ)
	var texto_cru := bruto.get_as_text() if bruto != null else ""
	if bruto != null: bruto.close()
	if JSON.parse_string(texto_cru) != null:
		push_error("FALHA: arquivo salvo em texto puro (encriptacao nao aplicou)")
		get_tree().quit(1)
		return

	# 2) Leitura segura recupera o conteúdo original
	var lido := Salvar._ler_seguro(tmp)
	if lido != conteudo:
		push_error("FALHA: roundtrip encriptado divergiu.\nesperado=%s\nveio=%s" % [conteudo, lido])
		get_tree().quit(1)
		return

	# 3) Migração: arquivo antigo em texto puro ainda é lido (fallback legado)
	var legado := "user://_test_legado.tmp"
	var pf := FileAccess.open(legado, FileAccess.WRITE)
	pf.store_string(conteudo)
	pf.close()
	var lido_legado := Salvar._ler_seguro(legado)
	if JSON.parse_string(lido_legado) == null or lido_legado != conteudo:
		push_error("FALHA: JSON legado em texto puro nao migrou.\nveio=%s" % lido_legado)
		get_tree().quit(1)
		return

	# Limpa temporários
	DirAccess.remove_absolute(ProjectSettings.globalize_path(tmp))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(legado))
	if FileAccess.file_exists(tmp): DirAccess.remove_absolute(tmp)
	if FileAccess.file_exists(legado): DirAccess.remove_absolute(legado)

	print("TESTE save-cripto: OK (encriptado + migracao legado)")
	get_tree().quit(0)
