extends Node

## ATENCAO: estes dois sao a RESERVA, nao a verdade.
##
## Eles ficaram parados em 12 enquanto o APK ja' estava no 19, e o painel de
## manutencao -- cuja unica funcao e' dizer o que esta rodando -- mostrava
## "code 12" em qualquer aparelho. A ferramenta de diagnostico mentia.
##
## Pior: e' este numero que decide se o app publico mostra "atualizacao
## disponivel". Preso em 12, o banner ficaria escondido para sempre.
##
## A verdade agora vem de res://versao_build.json, carimbado pela esteira na
## hora de montar o APK (ver tools/exportar_apk_dev.sh). Use codigo_versao() e
## nome_versao(); estas constantes so' valem no editor e nos testes, onde
## arquivo nenhum foi carimbado.
const APP_VERSION_CODE: int = 12
const APP_VERSION_NAME: String = "0.12.0"

const ARQ_VERSAO: String = "res://versao_build.json"

var _codigo_do_build: int = 0
var _nome_do_build: String = ""


## O numero que o Android instalou. Cai na constante quando o arquivo nao
## existe -- editor, testes, ou um APK montado antes deste carimbo existir.
func codigo_versao() -> int:
	_ler_versao_do_build()
	return _codigo_do_build if _codigo_do_build > 0 else APP_VERSION_CODE


func nome_versao() -> String:
	_ler_versao_do_build()
	return _nome_do_build if not _nome_do_build.is_empty() else APP_VERSION_NAME


func _ler_versao_do_build() -> void:
	if _codigo_do_build > 0 or not _nome_do_build.is_empty():
		return
	var f := FileAccess.open(ARQ_VERSAO, FileAccess.READ)
	if f == null:
		return
	var txt := f.get_as_text()
	f.close()
	var d: Variant = JSON.parse_string(txt)
	if not d is Dictionary:
		return
	_codigo_do_build = int((d as Dictionary).get("code", 0))
	_nome_do_build = str((d as Dictionary).get("name", ""))
const STORE_BUILD_FEATURE: String = "store_build"
const DEV_BUILD_FEATURE: String = "dev_build"
const FORCE_RELEASE_MODE: bool = false
const ALLOW_SIDELOAD_ANDROID_UPDATES: bool = true

# Debug: força o layout mobile rodando no PC, pra testar a cara do celular sem
# exportar APK. Liga/desliga com F10 (só em build de debug). Reabra a tela.
var forcar_mobile_pc: bool = false
var _modo_janela_anterior: int = -1
var _f10_anterior: bool = false


func is_mobile() -> bool:
	return OS.has_feature("android") or OS.has_feature("ios") or (forcar_mobile_pc and OS.is_debug_build())


func _process(_dt: float) -> void:
	# Polling do F10 (em vez de _unhandled_input, que telas em foco podem comer).
	if not OS.is_debug_build():
		return
	var agora := Input.is_key_pressed(KEY_F10)
	if agora and not _f10_anterior:
		forcar_mobile_pc = not forcar_mobile_pc
		_aplicar_janela_mobile(forcar_mobile_pc)
		print("[BuildConfig] forcar_mobile_pc = ", forcar_mobile_pc, "  (reabra a tela pra ver o layout)")
	_f10_anterior = agora


# No PC, força uma janela com ASPECTO de celular (landscape ~19.5:9). Fullscreen
# usaria o aspecto do monitor (16:9) e espremeria o layout mobile.
func _aplicar_janela_mobile(ligar: bool) -> void:
	if OS.has_feature("android") or OS.has_feature("ios"):
		return
	if ligar:
		_modo_janela_anterior = DisplayServer.window_get_mode()
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		var tam := Vector2i(1300, 600)   # janela 1300x600 -> viewport vira 1560x720 (celular)
		DisplayServer.window_set_size(tam)
		var scr := DisplayServer.screen_get_size()
		DisplayServer.window_set_position((scr - tam) / 2)
	else:
		var modo := _modo_janela_anterior if _modo_janela_anterior >= 0 else DisplayServer.WINDOW_MODE_WINDOWED
		DisplayServer.window_set_mode(modo)


func is_store_build() -> bool:
	return OS.has_feature(STORE_BUILD_FEATURE)


## Build de desenvolvedor: um APK separado, com outro nome de pacote, que
## instala AO LADO do jogo de verdade.
##
## Ele existe por um motivo unico e concreto. O canal de pacotes consegue
## trocar codigo no aparelho (provado: uma build compilada com a barra ciano
## passou a desenhar a barra dourada so' recebendo um pacote). Mas um pacote
## publicado vai para TODO MUNDO que tem o jogo, fica salvo no aparelho e
## carrega em toda abertura -- se quebrar um autoload, o jogo nao abre mais e
## nao se conserta sozinho.
##
## Entao nao existe "pacote so' para testar" no app publico. A saida e' um app
## separado: aqui os pacotes de codigo sao aceitos e vem de um canal proprio,
## e quem tem o jogo de verdade nunca ve nada disso.
##
## A marca vem de `custom_features` no preset de exportacao, o mesmo mecanismo
## que o projeto ja usa para `store_build`.
func is_dev_build() -> bool:
	return OS.has_feature(DEV_BUILD_FEATURE)


func is_release_mode() -> bool:
	return FORCE_RELEASE_MODE or is_store_build() or OS.has_feature("release")


func debug_logs_enabled() -> bool:
	return not is_release_mode()


func allow_external_apk_update() -> bool:
	return _should_allow_external_apk_update(is_mobile(), is_store_build())


func _should_allow_external_apk_update(mobile: bool, store_build: bool) -> bool:
	if store_build:
		return false
	if mobile:
		return ALLOW_SIDELOAD_ANDROID_UPDATES
	return true
