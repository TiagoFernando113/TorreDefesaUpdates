extends Node
## Fotografa uma cena do jogo sem ninguem olhando, para conferir ARTE.
##
##   xvfb-run -a godot --path . --rendering-driver opengl3 --resolution 1280x720 \
##       res://tools/foto_de_cena.tscn -- res://scenes/Intro.tscn 0.3 1.6 3.3
##
## Existe porque desenhar sem ver o resultado e' chutar. Ao refazer a barra de
## carregamento, foi a captura -- e nao a leitura do codigo -- que mostrou que
## as particulas estavam nascendo no lugar onde a barra ficava ANTES: pontinhos
## soltos do lado errado da tela, que teste nenhum pegaria.
##
## Precisa de framebuffer (xvfb no Linux sem tela). Com `--headless` o Godot nao
## desenha nada e as fotos saem pretas.

const DESTINO := "/tmp/tiros"


func _ready() -> void:
	# Adiar: no _ready a raiz ainda esta montando os filhos e o add_child falha
	# com "Parent node is busy setting up children" -- a cena nao entra, e as
	# fotos saem de um viewport vazio, sem erro nenhum que explique.
	call_deferred("_rodar")


func _rodar() -> void:
	var args := OS.get_cmdline_user_args()
	var caminho := args[0] if args.size() > 0 else "res://scenes/Intro.tscn"
	var marcas: Array[float] = []
	for i in range(1, args.size()):
		marcas.append(float(args[i]))
	if marcas.is_empty():
		marcas = [0.3, 1.6, 3.3]

	var cena := load(caminho)
	if cena == null:
		printerr("nao consegui carregar ", caminho)
		get_tree().quit(1)
		return
	get_tree().root.add_child(cena.instantiate())
	await get_tree().process_frame
	DirAccess.make_dir_recursive_absolute(DESTINO)

	var nome := caminho.get_file().get_basename().to_lower()
	var agora := 0.0
	for marca in marcas:
		if marca > agora:
			await get_tree().create_timer(marca - agora).timeout
			agora = marca
		# Esperar o quadro TERMINAR de ser desenhado. Sem isto a imagem sai do
		# quadro anterior, e uma foto atrasada engana mais que foto nenhuma.
		await RenderingServer.frame_post_draw
		var img := get_viewport().get_texture().get_image()
		var arquivo := "%s/%s_%.2f.png" % [DESTINO, nome, marca]
		img.save_png(arquivo)
		print("foto: ", arquivo, "  (", img.get_width(), "x", img.get_height(), ")")
	get_tree().quit(0)
