extends Node
## Guarda o version.json, que decide o aviso de atualizacao de QUEM TEM O JOGO.
##
## POR QUE EXISTE
##
## O arquivo tem duas chaves para cada coisa -- versao/version, url/apk_url,
## notas/notes -- e o _normalizar_manifest_apk faz a INGLESA GANHAR:
##
##   "version": int(d.get("version", d.get("versao", 0)))
##
## A portuguesa so' vale como reserva. Entao editar `versao` e esquecer
## `version` nao muda nada, nao da' erro e nao avisa -- some em silencio. Num
## projeto escrito em portugues, mexer justamente na chave em portugues e' o
## erro mais natural que existe aqui.
##
## O segundo perigo e' o numero nao bater com o APK do link. O version.json ja'
## anunciou a versao 12 apontando para o APK da v11. Ficou inerte por sorte
## (12 <= APP_VERSION_CODE, entao nenhum banner aparecia), mas no dia em que o
## numero subisse, o aviso mandaria todo mundo baixar o APK errado.
##
## Nao ha' teste possivel de "o link existe" sem rede, e teste que depende de
## rede reprova por wi-fi ruim. Entao a conferencia e' de COERENCIA: o numero
## anunciado tem que ser o mesmo que aparece no endereco.

const ARQ := "res://version.json"

var _falhas: Array[String] = []
var _d: Dictionary = {}


func _ready() -> void:
	var f := FileAccess.open(ARQ, FileAccess.READ)
	if f == null:
		push_error("nao consegui ler o version.json")
		get_tree().quit(1)
		return
	var txt := f.get_as_text()
	f.close()
	var d: Variant = JSON.parse_string(txt)
	if not (d is Dictionary):
		push_error("version.json nao e' um objeto JSON valido")
		get_tree().quit(1)
		return
	_d = d as Dictionary

	_os_pares_concordam()
	_o_numero_bate_com_o_link()
	_finalizar()


## O par tem que dizer a mesma coisa. Divergiu, a inglesa ganha em silencio.
func _os_pares_concordam() -> void:
	for par in [["versao", "version"], ["url", "apk_url"], ["notas", "notes"]]:
		var pt: String = par[0]
		var en: String = par[1]
		if not _d.has(pt) or not _d.has(en):
			continue  # ter so' uma das duas e' legitimo: a normalizacao cobre
		_esperar(_texto(_d[pt]) == _texto(_d[en]),
			"'%s' e '%s' discordam ('%s' vs '%s'). A inglesa ganha, entao a %s seria ignorada."
				% [pt, en, _texto(_d[pt]), _texto(_d[en]), pt])


## O JSON do Godot devolve todo numero como float, e str() disso vira "13.0".
## Numa mensagem que existe para orientar alguem no meio de um problema, um
## numero que nao e' o que esta escrito no arquivo custa tempo a' toa.
func _texto(v: Variant) -> String:
	if v is float and is_equal_approx(v, floorf(v)):
		return str(int(v))
	return str(v)


## O numero anunciado tem que ser o mesmo do APK apontado.
func _o_numero_bate_com_o_link() -> void:
	var versao := int(_d.get("version", _d.get("versao", 0)))
	var url := str(_d.get("apk_url", _d.get("url", "")))

	_esperar(versao > 0, "o version.json precisa anunciar uma versao maior que zero")
	_esperar(not url.is_empty(), "o version.json precisa apontar para um APK")
	if url.is_empty() or versao <= 0:
		return

	# .../releases/download/v11/cyrondefense.apk  ->  11
	var re := RegEx.new()
	re.compile("/releases/download/v(\\d+)/")
	var m := re.search(url)
	if m == null:
		_falhas.append("nao reconheci a versao no endereco do APK: %s" % url)
		return
	var versao_do_link := int(m.get_string(1))
	_esperar(versao_do_link == versao,
		"o version.json anuncia a versao %d mas o link baixa o APK da v%d -- "
			% [versao, versao_do_link]
		+ "quem atualizasse receberia a versao errada")


func _esperar(condicao: bool, msg: String) -> void:
	if not condicao:
		_falhas.append(msg)


func _finalizar() -> void:
	if _falhas.is_empty():
		print("OK version-json")
		get_tree().quit(0)
	else:
		for falha in _falhas:
			push_error(falha)
		get_tree().quit(1)
