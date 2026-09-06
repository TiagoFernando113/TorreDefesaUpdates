extends Node
## Aplica os pacotes baixados ANTES de qualquer outro autoload.
##
## POR QUE ELE EXISTE
##
## O Atualizador tambem carrega pacotes, mas ele e' o oitavo autoload: quando
## chega a vez dele, BuildConfig, Som, Salvar, ChaveTTS, Acessibilidade,
## RankingOnline e Auth ja' rodaram, e a versao deles no pacote nunca vale.
## Na pratica isso trancava o motor de som, a logica de salvar e o login fora
## de qualquer atualizacao sem APK novo.
##
## Este e' o PRIMEIRO autoload, e trabalha no _init() -- que roda antes ate' do
## _ready(). Dai' em diante, todo autoload seguinte le' a versao do pacote.
## Conferido rodando: um pacote trocou o APP_VERSION_NAME de dentro do
## BuildConfig, que antes era impossivel.
##
## O PREÇO, E A REDE
##
## Carregar cedo aumenta o alcance e o estrago na mesma medida: um pacote ruim
## agora derruba tudo, inclusive o proprio caminho que traria o conserto. Sem
## rede, um pacote quebrado deixaria o app morto ate' reinstalar.
##
## A rede e' uma marca no disco. Antes de aplicar qualquer pacote grava-se
## "estou tentando"; quando o jogo chega de pe' na primeira tela, a marca sai.
## Se numa abertura a marca ainda estiver la', quer dizer que a anterior nao
## chegou ao fim -- entao os pacotes sao IGNORADOS e apagados, e o app volta
## sozinho ao que veio no APK.
##
## Uma abertura ruim, e o proximo toque ja' abre. Nao ha' reinstalar.

const DIR_PACOTES := "user://content_packs"
const ARQ_ESTADO  := "user://content_updates_state.json"
const ARQ_TENTANDO := "user://carregando_pacote.flag"

## Preenchido no _init: quem quiser mostrar na tela o que foi aplicado le' daqui.
var aplicados: Array[String] = []
var pulou_por_seguranca: bool = false


func _init() -> void:
	if FileAccess.file_exists(ARQ_TENTANDO):
		# A abertura passada nao chegou ao fim. Culpa provavel: o pacote.
		pulou_por_seguranca = true
		_descartar_pacotes()
		return

	var estado := _ler_estado()
	if estado.is_empty():
		return

	# A marca entra ANTES de aplicar. Se o processo morrer no meio, ela fica --
	# e e' isso que a proxima abertura le'.
	var f := FileAccess.open(ARQ_TENTANDO, FileAccess.WRITE)
	if f != null:
		f.store_string("1")
		f.close()

	for id in estado.keys():
		var versao := int(estado[id])
		if versao <= 0:
			continue
		var caminho := "%s/%s_v%d.pck" % [DIR_PACOTES, str(id), versao]
		if not FileAccess.file_exists(caminho):
			continue
		if ProjectSettings.load_resource_pack(caminho, true):
			aplicados.append("%s v%d" % [str(id), versao])
		else:
			# Pacote que nao abre e' pacote corrompido. Nao adianta insistir na
			# proxima abertura: descarta agora e segue com o que veio no APK.
			push_warning("carregador: pacote %s nao abriu; descartando" % caminho)
			_descartar_pacotes()
			return


func _ready() -> void:
	# A marca so' sai quando o jogo chega de pe'. Um quadro desenhado ja' prova
	# que os autoloads subiram e a primeira cena montou -- que e' exatamente o
	# que um pacote ruim impediria.
	# Dois quadros: o primeiro ainda pode estar no meio da montagem.
	await get_tree().process_frame
	await get_tree().process_frame
	if FileAccess.file_exists(ARQ_TENTANDO):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(ARQ_TENTANDO))


func _ler_estado() -> Dictionary:
	var f := FileAccess.open(ARQ_ESTADO, FileAccess.READ)
	if f == null:
		return {}
	var txt := f.get_as_text()
	f.close()
	var d: Variant = JSON.parse_string(txt)
	if not d is Dictionary:
		return {}
	var pacotes: Variant = (d as Dictionary).get("packs", {})
	return pacotes as Dictionary if pacotes is Dictionary else {}


## Apaga os pacotes E o estado. Apagar so' os arquivos deixaria o Atualizador
## achando que a versao ja' esta instalada, e ele nunca baixaria de novo -- o
## app ficaria preso na versao do APK sem ninguem entender por que.
func _descartar_pacotes() -> void:
	var dir := DirAccess.open(DIR_PACOTES)
	if dir != null:
		dir.list_dir_begin()
		var nome := dir.get_next()
		while nome != "":
			if not dir.current_is_dir():
				dir.remove(nome)
			nome = dir.get_next()
		dir.list_dir_end()
	for arq in [ARQ_ESTADO, ARQ_TENTANDO]:
		if FileAccess.file_exists(arq):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(arq))
