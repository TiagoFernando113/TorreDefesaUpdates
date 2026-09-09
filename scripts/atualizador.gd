extends Node
## Verificador de atualizacao: compara versao local com server.
## Em builds de loja/Android, nao baixa APK por fora da loja.
## Packs de conteudo sao permitidos para assets/configs e nunca devem carregar codigo.

const VERSAO_ATUAL : int    = 12
const URL_VERSAO   : String = "https://raw.githubusercontent.com/TiagoFernando113/TorreDefesaUpdates/refs/heads/main/version.json"
const URL_CONTEUDO  : String = "https://raw.githubusercontent.com/TiagoFernando113/TorreDefesaUpdates/refs/heads/main/content_manifest.json"
## O app de desenvolvedor le' um manifesto SO' DELE. Nao e' capricho de
## organizacao: e' o que garante que um pacote de teste nunca chegue no aparelho
## de quem tem o jogo de verdade. Dois arquivos, dois publicos, sem engano
## possivel -- errar o campo `kind` no manifesto publico nao alcanca ninguem.
const URL_CONTEUDO_DEV : String = "https://raw.githubusercontent.com/TiagoFernando113/TorreDefesaUpdates/refs/heads/main/content_manifest_dev.json"
const CONTENT_STATE_PATH : String = "user://content_updates_state.json"
const CONTENT_PACK_DIR   : String = "user://content_packs"

## Tempo maximo de um download de pacote. Ver o comentario em
## _baixar_proximo_pack: o app publico recebe ajuste pequeno, o de
## desenvolvedor recebe coisa grande (audio), e o numero nao da' para mudar
## depois sem APK novo.
const TEMPO_DOWNLOAD     : float = 45.0
const TEMPO_DOWNLOAD_DEV : float = 600.0

var _http     : HTTPRequest = null
var _http_conteudo : HTTPRequest = null
var _http_download : HTTPRequest = null
var _camada   : CanvasLayer = null
var _url_apk  : String      = ""
var _content_state : Dictionary = {}
var _content_queue : Array[Dictionary] = []
var _content_current : Dictionary = {}


func _ready() -> void:
	_carregar_content_state()
	# Nao ha' _carregar_packs_salvos aqui: quem aplica pacote e' o Carregador, no
	# _init(), antes de todos os autoloads. Aplicar de novo neste ponto seria
	# tarde demais para servir de alguma coisa (os autoloads ja' subiram) e so'
	# criaria a mistura de versoes descrita em _on_content_pack_resp.
	_iniciar_check_conteudo()
	if not BuildConfig.allow_external_apk_update():
		return
	_iniciar_check_apk()


func _iniciar_check_apk() -> void:
	_http             = HTTPRequest.new()
	_http.use_threads = true
	_http.timeout     = 12.0
	add_child(_http)
	_http.request_completed.connect(_on_versao_resp)
	_http.request(URL_VERSAO)


func _iniciar_check_conteudo() -> void:
	_http_conteudo             = HTTPRequest.new()
	_http_conteudo.use_threads = true
	_http_conteudo.timeout     = 12.0
	add_child(_http_conteudo)
	_http_conteudo.request_completed.connect(_on_content_manifest_resp)
	_http_conteudo.request(URL_CONTEUDO_DEV if BuildConfig.is_dev_build() else URL_CONTEUDO)


## Versao atual usada pelo menu para exibir no canto.
func versao_efetiva() -> int:
	return BuildConfig.APP_VERSION_CODE


func _on_versao_resp(result: int, code: int, _h: PackedStringArray, body: PackedByteArray) -> void:
	if not BuildConfig.allow_external_apk_update():
		return
	if result != HTTPRequest.RESULT_SUCCESS or code != 200:
		return
	var json := JSON.new()
	if json.parse(body.get_string_from_utf8()) != OK:
		return
	var data = json.get_data()
	if not data is Dictionary:
		return
	var d         : Dictionary = _normalizar_manifest_apk(data as Dictionary)
	var versao_sv : int        = int(d.get("version", 0))
	var url_apk   : String     = str(d.get("apk_url", ""))
	var notas     : String     = str(d.get("notes", ""))

	if versao_sv <= BuildConfig.APP_VERSION_CODE or url_apk == "":
		return

	_url_apk = url_apk
	_mostrar_banner(versao_sv, notas)


func _normalizar_manifest_apk(d: Dictionary) -> Dictionary:
	return {
		"version": int(d.get("version", d.get("versao", 0))),
		"apk_url": str(d.get("apk_url", d.get("url", ""))),
		"notes": str(d.get("notes", d.get("notas", "")))
	}


func _mostrar_banner(versao_sv: int, notas: String) -> void:
	_camada       = CanvasLayer.new()
	_camada.layer = 128
	get_tree().root.add_child(_camada)

	var vp_w : float = get_viewport().get_visible_rect().size.x
	var vp_h : float = get_viewport().get_visible_rect().size.y

	# Escurecimento de fundo
	var escuro := ColorRect.new()
	escuro.color = Color(0.0, 0.0, 0.0, 0.75)
	escuro.set_anchors_preset(Control.PRESET_FULL_RECT)
	_camada.add_child(escuro)

	# Dimensões do painel
	var pw : float = min(500.0, vp_w - 60)
	var ph : float = 270.0
	var px : float = (vp_w - pw) * 0.5
	var py : float = (vp_h - ph) * 0.5

	# Fundo do painel (igual ao fundo do jogo)
	var painel := ColorRect.new()
	painel.color    = Color(0.03, 0.04, 0.08, 0.98)
	painel.position = Vector2(px, py)
	painel.size     = Vector2(pw, ph)
	_camada.add_child(painel)

	# Linhas de grid (decorativas)
	for i in range(1, 5):
		var linha := ColorRect.new()
		linha.color    = Color(0.0, 0.8, 1.0, 0.04)
		linha.position = Vector2(px, py + (ph / 5.0) * i)
		linha.size     = Vector2(pw, 1)
		_camada.add_child(linha)
	for i in range(1, 6):
		var col := ColorRect.new()
		col.color    = Color(0.0, 0.8, 1.0, 0.04)
		col.position = Vector2(px + (pw / 6.0) * i, py)
		col.size     = Vector2(1, ph)
		_camada.add_child(col)

	# Bordas ciano (igual aos botões do jogo)
	for borda_data in [
		[Vector2(px,           py),           Vector2(pw, 2)],   # topo
		[Vector2(px,           py + ph - 2),  Vector2(pw, 2)],   # base
		[Vector2(px,           py),           Vector2(2, ph)],   # esquerda
		[Vector2(px + pw - 2,  py),           Vector2(2, ph)],   # direita
	]:
		var b := ColorRect.new()
		b.color    = Color(0.0, 0.85, 1.0)
		b.position = borda_data[0]
		b.size     = borda_data[1]
		_camada.add_child(b)

	# Título estilo do jogo
	var titulo := Label.new()
	titulo.text                 = "ATUALIZACAO DISPONIVEL"
	titulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	titulo.position             = Vector2(px, py + 22)
	titulo.size                 = Vector2(pw, 36)
	titulo.add_theme_font_size_override("font_size", 24)
	titulo.add_theme_color_override("font_color", Color(0.0, 0.9, 1.0))
	_camada.add_child(titulo)

	# Separador
	var sep := ColorRect.new()
	sep.color    = Color(0.0, 0.85, 1.0, 0.3)
	sep.position = Vector2(px + 30, py + 64)
	sep.size     = Vector2(pw - 60, 1)
	_camada.add_child(sep)

	# Versão
	var ver_lbl := Label.new()
	ver_lbl.text                 = "Versao %d" % versao_sv
	ver_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ver_lbl.position             = Vector2(px, py + 74)
	ver_lbl.size                 = Vector2(pw, 24)
	ver_lbl.add_theme_font_size_override("font_size", 14)
	ver_lbl.add_theme_color_override("font_color", Color(0.5, 0.75, 1.0))
	_camada.add_child(ver_lbl)

	# Notas
	var notas_lbl := Label.new()
	notas_lbl.text                 = notas
	notas_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	notas_lbl.autowrap_mode        = TextServer.AUTOWRAP_WORD
	notas_lbl.position             = Vector2(px + 20, py + 104)
	notas_lbl.size                 = Vector2(pw - 40, 72)
	notas_lbl.add_theme_font_size_override("font_size", 14)
	notas_lbl.add_theme_color_override("font_color", Color(0.75, 0.88, 1.0))
	_camada.add_child(notas_lbl)

	# Borda do botão principal (ciano, estilo do jogo)
	var btn_bw : float = pw * 0.62
	var btn_bx : float = px + (pw - btn_bw) * 0.5
	var btn_by : float = py + ph - 72
	var btn_border := ColorRect.new()
	btn_border.color    = Color(0.0, 0.85, 1.0)
	btn_border.position = Vector2(btn_bx, btn_by)
	btn_border.size     = Vector2(btn_bw, 44)
	_camada.add_child(btn_border)

	var btn := Button.new()
	btn.text     = "ATUALIZAR"
	btn.position = Vector2(btn_bx + 2, btn_by + 2)
	btn.size     = Vector2(btn_bw - 4, 40)
	btn.add_theme_font_size_override("font_size", 17)
	btn.add_theme_color_override("font_color", Color(0.0, 0.9, 1.0))
	btn.add_theme_stylebox_override("normal", _estilo_btn(Color(0.03, 0.04, 0.08)))
	btn.add_theme_stylebox_override("hover",  _estilo_btn(Color(0.0, 0.15, 0.22)))
	btn.add_theme_stylebox_override("pressed",_estilo_btn(Color(0.0, 0.08, 0.14)))
	btn.pressed.connect(_abrir_download)
	_camada.add_child(btn)

	# Botão fechar
	var fechar := Button.new()
	fechar.text     = "agora nao"
	fechar.position = Vector2(px + (pw - 120) * 0.5, py + ph - 24)
	fechar.size     = Vector2(120, 20)
	fechar.add_theme_font_size_override("font_size", 12)
	fechar.add_theme_color_override("font_color", Color(0.35, 0.45, 0.55))
	fechar.add_theme_stylebox_override("normal",  _estilo_btn(Color(0.0, 0.0, 0.0, 0.0)))
	fechar.add_theme_stylebox_override("hover",   _estilo_btn(Color(0.0, 0.0, 0.0, 0.0)))
	fechar.add_theme_stylebox_override("pressed", _estilo_btn(Color(0.0, 0.0, 0.0, 0.0)))
	fechar.pressed.connect(_fechar_banner)
	_camada.add_child(fechar)


func _estilo_btn(cor: Color) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = cor
	return s


func _abrir_download() -> void:
	if not BuildConfig.allow_external_apk_update():
		_fechar_banner()
		return
	OS.shell_open(_url_apk)
	_fechar_banner()


func _fechar_banner() -> void:
	if _camada and is_instance_valid(_camada):
		_camada.queue_free()
		_camada = null


func _on_content_manifest_resp(result: int, code: int, _h: PackedStringArray, body: PackedByteArray) -> void:
	if result != HTTPRequest.RESULT_SUCCESS or code != 200:
		return
	var manifest := _parse_content_manifest(body.get_string_from_utf8())
	if manifest.is_empty():
		return
	var local_versions: Dictionary = _content_state.get("packs", {}) as Dictionary
	_content_queue.clear()
	for item in manifest.get("packs", []):
		if item is Dictionary and _should_download_content_pack(item as Dictionary, local_versions):
			_content_queue.append(item as Dictionary)
	_baixar_proximo_pack()


func _baixar_proximo_pack() -> void:
	if _content_queue.is_empty():
		return
	_content_current = _content_queue.pop_front()
	var url := str(_content_current.get("url", ""))
	var destino := _content_local_path(_content_current)
	_garantir_dir_conteudo()
	_http_download = HTTPRequest.new()
	_http_download.use_threads = true
	# 45s da' conta de um pacote de codigo (kilobytes), mas nao de audio: os
	# ~96 MB da trilha estouram isso em qualquer 4G e o download morre pela
	# metade, sempre. E o numero mora num autoload -- ou seja, aumentar depois
	# custaria APK novo. Fica largo aqui, no app de desenvolvedor, onde pacote
	# grande e' o caso normal; no app publico segue apertado de proposito,
	# porque la' pacote e' ajuste pequeno.
	_http_download.timeout = TEMPO_DOWNLOAD_DEV if BuildConfig.is_dev_build() else TEMPO_DOWNLOAD
	add_child(_http_download)
	_http_download.request_completed.connect(_on_content_pack_resp.bind(destino))
	var err := _http_download.request(url)
	if err != OK:
		_http_download.queue_free()
		_http_download = null
		_baixar_proximo_pack()


func _on_content_pack_resp(result: int, code: int, _h: PackedStringArray, body: PackedByteArray, destino: String) -> void:
	if _http_download and is_instance_valid(_http_download):
		_http_download.queue_free()
		_http_download = null
	if result != HTTPRequest.RESULT_SUCCESS or code != 200:
		_baixar_proximo_pack()
		return
	var f := FileAccess.open(destino, FileAccess.WRITE)
	if f == null:
		_baixar_proximo_pack()
		return
	f.store_buffer(body)
	f.close()
	var sha := str(_content_current.get("sha256", "")).to_lower()
	if not _verificar_sha256(destino, sha):
		if FileAccess.file_exists(destino):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(destino))
		_baixar_proximo_pack()
		return
	# O PACOTE NAO E' APLICADO NESTA ABERTURA. De proposito.
	#
	# Aplicar aqui parece adiantar a atualizacao, mas nao adianta: os autoloads
	# ja' subiram com o codigo do APK e continuam com ele ate' o app fechar. O
	# que muda e' so' o que for carregado DEPOIS -- as telas. Ou seja, o jogo
	# passaria a rodar metade novo e metade velho.
	#
	# Isso quebra de um jeito especifico: uma tela do pacote chama um metodo que
	# so' existe no autoload novo, e o autoload em memoria e' o antigo. Erro em
	# tempo de execucao, tela torta -- e o descarte automatico do Carregador NAO
	# salva, porque ele so' dispara quando a abertura nao chega ao primeiro
	# quadro, e essa chegou.
	#
	# Enquanto pacote era coisa rara e manual, a janela quase nunca abria. Agora
	# que sai um a cada mudanca, ela abriria toda vez. Entao o pacote fica
	# guardado e quem aplica e' o Carregador, no _init() da proxima abertura, com
	# tudo da mesma versao e com a rede de seguranca ligada.
	#
	# O sha256 acima ja' garantiu que o arquivo esta inteiro; se ainda assim ele
	# nao abrir, o Carregador descarta e o app volta ao que veio no APK.
	var packs: Dictionary = _content_state.get("packs", {}) as Dictionary
	packs[str(_content_current.get("id", ""))] = int(_content_current.get("version", 0))
	_content_state["packs"] = packs
	_salvar_content_state()
	_baixar_proximo_pack()


func _parse_content_manifest(txt: String) -> Dictionary:
	var json := JSON.new()
	if json.parse(txt) != OK:
		return {}
	var data: Variant = json.get_data()
	if not data is Dictionary:
		return {}
	var manifest: Dictionary = data as Dictionary
	if not manifest.has("packs"):
		manifest["packs"] = []
	if not manifest.get("packs", []) is Array:
		return {}
	if manifest.has("configs") and not manifest.get("configs") is Array:
		return {}
	return manifest


func _should_download_content_pack(pack: Dictionary, local_versions: Dictionary) -> bool:
	var id := _safe_content_id(str(pack.get("id", "")))
	var version := int(pack.get("version", 0))
	var local_version := int(local_versions.get(id, 0))
	var url := str(pack.get("url", ""))
	var sha := str(pack.get("sha256", "")).to_lower()
	var kind := str(pack.get("kind", "assets")).to_lower()
	if id == "" or version <= local_version:
		return false
	if not url.begins_with("https://"):
		return false
	if not _is_valid_sha256(sha):
		return false
	# Pacote com codigo dentro so' passa no app de desenvolvedor.
	#
	# A regra "packs nunca devem carregar codigo" continua valendo para quem tem
	# o jogo publicado, e vale por um motivo pratico: pacote publicado vai para
	# todo mundo, fica salvo no aparelho e carrega em toda abertura. Um pacote
	# que quebre um autoload deixa o jogo sem abrir, e sem conserto pelo proprio
	# canal -- porque o canal e' justamente o que parou de rodar.
	#
	# No app de desenvolvedor o estrago maximo e' o proprio app de teste, que se
	# reinstala. Por isso a excecao mora aqui, e nao no campo `kind`.
	if kind in ["script", "scripts", "code", "codigo"] and not BuildConfig.is_dev_build():
		return false
	# Executavel e APK nunca, em build nenhuma: o canal entrega conteudo para o
	# jogo, e nao um programa novo para instalar.
	if kind in ["executable", "exe", "apk"]:
		return false
	# A UNICA armadilha que quebra o app de verdade: autoload que nao existe.
	#
	# A lista de autoloads mora no project.binary, lido pelo motor ANTES de
	# qualquer pacote. Pacote nao cria autoload -- e todo script do pacote que
	# mencione um autoload que a build instalada nao tem morre na leitura com
	# "Identifier X not declared in the current scope". Como o pacote e' aplicado
	# no arranque, isso deixa o jogo sem abrir.
	#
	# Ja' aconteceu, com o `Auth` numa build de junho. Enquanto publicar pacote
	# era ato manual, dava para lembrar. Agora que sai sozinho a cada mudanca,
	# lembrar nao e' plano: o pacote diz de quais autoloads ele precisa, e quem
	# nao os tem simplesmente NAO baixa. Fica na versao do APK, funcionando, ate'
	# instalar um APK novo -- que e' o desfecho certo.
	if not _tem_todos_autoloads(pack.get("requer_autoloads", [])):
		return false
	var ext := _content_ext_from_url(url)
	return ext == "pck" or ext == "zip"


## Manifesto antigo (sem o campo) continua valendo: lista vazia = nada exigido.
## Isso importa porque o campo nasceu depois de haver APK instalado por ai'.
func _tem_todos_autoloads(nomes: Variant) -> bool:
	if not nomes is Array:
		return true
	for n in (nomes as Array):
		var nome := str(n).strip_edges()
		if nome.is_empty():
			continue
		if not _tem_autoload(nome):
			return false
	return true


## Duas perguntas para o mesmo fato, porque cada uma tem um ponto cego.
##
## ProjectSettings enxerga a lista inteira, inclusive os autoloads que ainda nao
## subiram -- mas depende de como o project.binary foi gravado na exportacao. A
## arvore e' o fato observavel, sem intermediario, e aqui ela ja' esta completa:
## esta funcao so' roda quando a resposta do manifesto chega, dezenas de quadros
## depois do arranque. Bastar UMA dizer que sim evita recusar pacote bom.
func _tem_autoload(nome: String) -> bool:
	if ProjectSettings.has_setting("autoload/" + nome):
		return true
	var arvore := get_tree()
	if arvore == null or arvore.root == null:
		return false
	return arvore.root.get_node_or_null(NodePath(nome)) != null


func _content_local_path(pack: Dictionary) -> String:
	var id := _safe_content_id(str(pack.get("id", "")))
	var version := int(pack.get("version", 0))
	var ext := _content_ext_from_url(str(pack.get("url", "")))
	if ext == "":
		ext = "pck"
	return "%s/%s_v%d.%s" % [CONTENT_PACK_DIR, id, version, ext]


func _safe_content_id(id: String) -> String:
	var src := id.to_lower()
	var out := ""
	for i in range(src.length()):
		var c := src.substr(i, 1)
		if (c >= "a" and c <= "z") or (c >= "0" and c <= "9") or c == "_" or c == "-":
			out += c
		elif c == " ":
			out += "_"
	return out.strip_edges()


func _content_ext_from_url(url: String) -> String:
	var clean := url
	var q := clean.find("?")
	if q >= 0:
		clean = clean.substr(0, q)
	var slash := clean.rfind("/")
	if slash >= 0:
		clean = clean.substr(slash + 1)
	var dot := clean.rfind(".")
	if dot < 0:
		return ""
	return clean.substr(dot + 1).to_lower()


func _is_valid_sha256(sha: String) -> bool:
	if sha.length() != 64:
		return false
	for i in range(sha.length()):
		var c := sha.substr(i, 1)
		if not ((c >= "a" and c <= "f") or (c >= "0" and c <= "9")):
			return false
	return true


func _verificar_sha256(path: String, esperado: String) -> bool:
	if not _is_valid_sha256(esperado):
		return false
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		return false
	var ctx := HashingContext.new()
	ctx.start(HashingContext.HASH_SHA256)
	while not f.eof_reached():
		ctx.update(f.get_buffer(1024 * 64))
	f.close()
	return ctx.finish().hex_encode().to_lower() == esperado


func _carregar_content_state() -> void:
	_content_state = {"packs": {}}
	if not FileAccess.file_exists(CONTENT_STATE_PATH):
		return
	var f := FileAccess.open(CONTENT_STATE_PATH, FileAccess.READ)
	if f == null:
		return
	var txt := f.get_as_text()
	f.close()
	var parsed := _parse_content_manifest(txt)
	if parsed.has("packs") and parsed.get("packs") is Dictionary:
		_content_state = parsed
	else:
		var json := JSON.new()
		if json.parse(txt) == OK and json.get_data() is Dictionary:
			_content_state = json.get_data() as Dictionary
	if not _content_state.has("packs") or not _content_state.get("packs") is Dictionary:
		_content_state["packs"] = {}


func _salvar_content_state() -> void:
	var f := FileAccess.open(CONTENT_STATE_PATH, FileAccess.WRITE)
	if f == null:
		return
	f.store_string(JSON.stringify(_content_state, "\t"))
	f.close()


func _garantir_dir_conteudo() -> void:
	if not DirAccess.dir_exists_absolute(ProjectSettings.globalize_path(CONTENT_PACK_DIR)):
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(CONTENT_PACK_DIR))
