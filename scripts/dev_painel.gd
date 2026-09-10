extends CanvasLayer
## Painel de manutencao, so' no app de desenvolvedor.
##
## POR QUE PRECISA ESTAR NO APK
##
## Duas coisas ficavam impossiveis a distancia:
##
## 1. VER O QUE DEU ERRADO. Erro no celular nao aparece em lugar nenhum -- "foi
##    mas esta sem audio" era tudo que dava para saber. Agora o motor grava tudo
##    em user://logs/godot.log (ajuste `debug/file_logging`, lido no arranque:
##    tinha que ser ligado ANTES, no APK) e este painel mostra na tela.
##
## 2. DESFAZER UM PACOTE RUIM. O Carregador so' descarta pacote quando a
##    abertura anterior TRAVOU. Um pacote que apenas deixa o jogo errado --
##    tela torta, sistema mudo, botao que nao responde -- nao trava nada, e
##    ficaria grudado ate' reinstalar o APK. Aqui tem o botao.
##
## Nada disso pode nascer de um pacote: painel e captura de log precisam existir
## antes do pacote chegar. Por isso vem de fabrica.
##
## COMO ABRIR, SEM TECLADO
##
## Cinco toques no canto superior esquerdo, dentro de tres segundos. Escolhido
## por ser impossivel de acertar sem querer e nao gastar botao na tela.
##
## No app publico este autoload se apaga no _ready e nao custa nada.

const CANTO := Vector2(0.16, 0.11)  ## fracao da tela que conta como "canto"
const TOQUES := 5
const JANELA_S := 3.0
const ARQ_LOG := "user://logs/godot.log"
const LINHAS_LOG := 40

var _toques: Array[float] = []
var _corpo: RichTextLabel
var _raiz: Control


## Os outros autoloads sao alcancados por /root/<nome>, e nao pelo nome global,
## DE PROPOSITO.
##
## Um script que cita autoload inexistente nao compila -- nem ele, nem nada que
## dependa dele. Este painel e' a ferramenta de recuperacao: se ele deixar de
## compilar porque outro autoload foi renomeado ou removido, some junto a unica
## saida para um pacote ruim, e ai' so' reinstalando. Conferido de proposito:
## com o autoload Modulos fora do project.godot, a versao anterior deste arquivo
## parava de compilar.
##
## Com get_node_or_null o painel abre mesmo faltando peca, e diz o que faltou.
func _autoload(nome: String) -> Node:
	return get_node_or_null("/root/" + nome)


func _ready() -> void:
	var cfg := _autoload("BuildConfig")
	# Sem BuildConfig, o seguro e' NAO existir: melhor ficar sem painel do que
	# arriscar um painel de manutencao dentro do app publico.
	if cfg == null or not cfg.is_dev_build():
		# App publico: nao existe. Sem painel, sem custo, sem risco.
		queue_free()
		return
	layer = 128
	_montar()
	_raiz.visible = false


func _input(evento: InputEvent) -> void:
	if _raiz == null:
		return
	var pos := Vector2.ZERO
	if evento is InputEventScreenTouch and (evento as InputEventScreenTouch).pressed:
		pos = (evento as InputEventScreenTouch).position
	elif evento is InputEventMouseButton and (evento as InputEventMouseButton).pressed:
		pos = (evento as InputEventMouseButton).position
	else:
		return
	var tela := get_viewport().get_visible_rect().size
	if pos.x > tela.x * CANTO.x or pos.y > tela.y * CANTO.y:
		return
	# NAO marca o evento como tratado: o jogo continua recebendo o toque, senao
	# o canto viraria uma zona morta para quem esta jogando.
	var agora := Time.get_ticks_msec() / 1000.0
	_toques.append(agora)
	while not _toques.is_empty() and agora - _toques[0] > JANELA_S:
		_toques.pop_front()
	if _toques.size() >= TOQUES:
		_toques.clear()
		_alternar()


func _alternar() -> void:
	_raiz.visible = not _raiz.visible
	if _raiz.visible:
		_atualizar()


func _montar() -> void:
	_raiz = Control.new()
	_raiz.set_anchors_preset(Control.PRESET_FULL_RECT)
	_raiz.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_raiz)

	var fundo := ColorRect.new()
	fundo.color = Color(0, 0, 0, 0.92)
	fundo.set_anchors_preset(Control.PRESET_FULL_RECT)
	_raiz.add_child(fundo)

	var col := VBoxContainer.new()
	col.set_anchors_preset(Control.PRESET_FULL_RECT)
	col.add_theme_constant_override("separation", 10)
	col.offset_left = 18
	col.offset_top = 18
	col.offset_right = -18
	col.offset_bottom = -18
	_raiz.add_child(col)

	var titulo := Label.new()
	titulo.text = "MANUTENÇÃO — app de desenvolvedor"
	titulo.add_theme_font_size_override("font_size", 26)
	col.add_child(titulo)

	_corpo = RichTextLabel.new()
	_corpo.bbcode_enabled = true
	_corpo.scroll_following = false
	_corpo.selection_enabled = true
	_corpo.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_corpo.add_theme_font_size_override("normal_font_size", 17)
	col.add_child(_corpo)

	var linha := HBoxContainer.new()
	linha.add_theme_constant_override("separation", 10)
	col.add_child(linha)
	_botao(linha, "Atualizar", _atualizar)
	_botao(linha, "Copiar tudo", _copiar)
	_botao(linha, "Descartar pacotes", _descartar)
	_botao(linha, "Fechar", _alternar)


func _botao(pai: Node, texto: String, alvo: Callable) -> void:
	var b := Button.new()
	b.text = texto
	b.custom_minimum_size = Vector2(0, 56)
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b.add_theme_font_size_override("font_size", 18)
	b.pressed.connect(alvo)
	pai.add_child(b)


func _atualizar() -> void:
	_corpo.text = _relatorio()


## Tudo que eu perguntaria por mensagem, numa tela so'.
func _relatorio() -> String:
	var p: Array[String] = []
	var cfg := _autoload("BuildConfig")
	# codigo_versao()/nome_versao(), nao as constantes: elas ficaram paradas em
	# 12 enquanto o APK era 19, e esta tela mostrava "code 12" em qualquer
	# aparelho -- a ferramenta de diagnostico mentindo sobre o diagnostico.
	p.append("[b]Versão[/b]  %s (code %s)  ·  Godot %s" % [
		cfg.nome_versao() if cfg else "?", str(cfg.codigo_versao()) if cfg else "?",
		Engine.get_version_info().get("string", "?")])
	p.append("[b]Aparelho[/b]  %s  ·  tela %s" % [
		OS.get_name(), str(get_viewport().get_visible_rect().size)])

	p.append("\n[b]Pacotes aplicados[/b]")
	var carr := _autoload("Carregador")
	if carr == null:
		p.append("  [color=orange]sem Carregador — nenhum pacote é aplicado nesta build[/color]")
	elif carr.pulou_por_seguranca:
		p.append("  [color=orange]descartados: a abertura anterior não terminou[/color]")
	elif carr.aplicados.is_empty():
		p.append("  nenhum — rodando o que veio no APK")
	else:
		for a in carr.aplicados:
			p.append("  • %s" % a)

	# "Aplicados: nenhum" queria dizer tres coisas ao mesmo tempo, e nenhuma
	# delas dava para agir: nao procurou / nao achou / achou e vale na proxima
	# abertura. Esta linha separa a terceira das outras duas.
	var atu := _autoload("Atualizador")
	if atu != null and atu.has_method("pacotes_baixados"):
		var baixados: Dictionary = atu.pacotes_baixados()
		if baixados.is_empty():
			p.append("  [color=#8899aa]nada baixado ainda — se acabou de instalar, abra o app mais uma vez[/color]")
		else:
			for id in baixados.keys():
				var v := int(baixados[id])
				var ja := carr != null and carr.aplicados.any(func(a): return a.begins_with(str(id)))
				if not ja:
					p.append("  [color=#7fe08a]baixado: %s v%d — vale na próxima abertura[/color]" % [str(id), v])

	p.append("\n[b]Módulos[/b]")
	var mods := _autoload("Modulos")
	if mods == null:
		p.append("  [color=orange]sem Modulos — esta build não instala sistema novo por pacote[/color]")
	else:
		var vivos: Array = mods.lista()
		p.append("  ativos: %s" % ("nenhum" if vivos.is_empty() else ", ".join(vivos)))
		for r in mods.recusados:
			p.append("  [color=orange]recusado: %s[/color]" % r)

	p.append("\n[b]Últimos erros do log[/b]")
	var linhas := _erros_do_log()
	if linhas.is_empty():
		p.append("  nada — nenhum erro registrado nesta abertura")
	else:
		for l in linhas:
			p.append("  [color=#ff8a80]%s[/color]" % l)
	return "\n".join(p)


## Le' o log que o motor grava sozinho. Depende de
## debug/file_logging/enable_file_logging estar ligado no project.godot -- se
## alguem desligar, isto aqui fica mudo e o painel perde metade da serventia.
func _erros_do_log() -> Array[String]:
	var f := FileAccess.open(ARQ_LOG, FileAccess.READ)
	if f == null:
		return ["(sem arquivo de log — file_logging está desligado?)"]
	var todas := f.get_as_text().split("\n")
	f.close()
	var r: Array[String] = []
	for i in range(todas.size()):
		var l := str(todas[i]).strip_edges()
		if l.is_empty():
			continue
		var baixa := l.to_lower()
		if baixa.contains("error") or baixa.contains("erro") or baixa.contains("warning") \
				or baixa.contains("failed") or baixa.begins_with("at:"):
			r.append(l.left(200))
	if r.size() > LINHAS_LOG:
		r = r.slice(r.size() - LINHAS_LOG)
	return r


func _copiar() -> void:
	DisplayServer.clipboard_set(_relatorio().replace("[b]", "").replace("[/b]", ""))


## A saida para um pacote que nao trava, so' estraga. Sem isto so' reinstalando.
func _descartar() -> void:
	var carr := _autoload("Carregador")
	if carr == null:
		_corpo.text = "[b]Sem Carregador nesta build[/b] — não há pacote para descartar."
		return
	carr.descartar_pacotes()
	_corpo.text = "[b]Pacotes descartados.[/b]\n\nFeche o app por completo e abra de novo: " \
		+ "ele volta ao que veio no APK.\n\n(No Android o app não consegue se reiniciar " \
		+ "sozinho — tem que ser na mão mesmo.)"
