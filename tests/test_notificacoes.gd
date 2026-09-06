extends Node

var _falhas: Array[String] = []
## O que nao pode ser conferido AQUI, e por que. Pular calado seria pior que
## falhar: quem le "OK" acharia que tudo foi verificado.
var _pulados: Array[String] = []


func _ready() -> void:
	var notificacoes: Node = preload("res://scripts/notificacoes.gd").new()
	_testar_parse_notices(notificacoes)
	_testar_estado_sem_plugin_android(notificacoes)
	_testar_export_android_pede_permissao()
	_testar_android_build_fcm()
	_finalizar()


func _testar_parse_notices(notificacoes: Node) -> void:
	var data := {
		"version": 2,
		"notices": [
			{
				"id": "update_v11",
				"title": "Atualizacao disponivel",
				"body": "Baixe a nova versao.",
				"type": "update",
				"url": "https://github.com/TiagoFernando113/TorreDefesaUpdates/releases/latest"
			},
			{
				"id": "",
				"title": "Sem id",
				"body": "Deve ser ignorado."
			}
		]
	}
	var notices: Array = notificacoes.call("_parse_notices_manifest", JSON.stringify(data))
	_esperar(notices.size() == 1, "Parser deve ignorar notice sem id.")
	if notices.size() == 1:
		var notice: Dictionary = notices[0] as Dictionary
		_esperar(notice.get("id", "") == "update_v11", "Notice valida deve manter id.")
		_esperar(notice.get("type", "") == "update", "Notice valida deve manter tipo.")


func _testar_estado_sem_plugin_android(notificacoes: Node) -> void:
	_esperar(not notificacoes.call("plugin_disponivel"), "No PC/headless o plugin Android nao deve existir.")
	_esperar(str(notificacoes.call("status_texto")) != "", "Status textual deve existir mesmo sem plugin.")


## O export_presets.cfg NAO esta no repositorio -- ele guarda a senha da
## keystore de assinatura em texto puro, entao versiona-lo vazaria a chave que
## assina o APK. Consequencia: num clone novo, ou no CI, este arquivo nao
## existe.
##
## Antes, `_ler_arquivo` devolvia "" e os dois `contains` davam falso, entao o
## teste FALHAVA por causa de um arquivo que nunca poderia estar ali. Um teste
## que nao tem como passar num clone limpo ensina a ignorar a bateria inteira.
##
## Agora ele PULA e diz que pulou. Na maquina de quem exporta -- que e' a unica
## onde a conferencia significa alguma coisa -- ele continua conferindo igual.
func _testar_export_android_pede_permissao() -> void:
	if not FileAccess.file_exists("res://export_presets.cfg"):
		_pulados.append("export_presets.cfg nao existe neste clone (nao e' versionado: guarda a senha da keystore)")
		return
	var txt := _ler_arquivo("res://export_presets.cfg")
	_esperar(txt.contains("permissions/post_notifications=true"), "Export Android deve pedir POST_NOTIFICATIONS.")
	_esperar(txt.contains("gradle_build/use_gradle_build=true"), "Export Android deve usar Gradle custom build para FCM.")


## Mesma historia do export_presets, e vale um aviso: a pasta `android/build/`
## NAO esta no repositorio -- so' o `.build_version`. Ela nasce do "Instalar
## modelo de build Android" do editor, mas o que este teste confere ali dentro
## nao e' gerado: o google-services.json, as linhas de Firebase no gradle e o
## CyronPushPlugin.kt foram escritos a mao. Hoje eles existem apenas na maquina
## de quem exporta, e um clone limpo nao tem como reconstrui-los.
##
## Enquanto isso nao for versionado, o teste pula em vez de falhar -- mas o
## risco continua de pe, e e' de perder trabalho, nao de teste vermelho.
func _testar_android_build_fcm() -> void:
	if not DirAccess.dir_exists_absolute("res://android/build"):
		_pulados.append("android/build/ nao existe neste clone (nao e' versionado -- ver o comentario acima)")
		return
	_esperar(FileAccess.file_exists("res://android/build/google-services.json"), "google-services.json deve estar no Android build.")
	var gradle := _ler_arquivo("res://android/build/build.gradle")
	_esperar(gradle.contains("com.google.gms.google-services"), "Gradle deve aplicar Google Services.")
	_esperar(gradle.contains("com.google.firebase:firebase-messaging"), "Gradle deve depender de Firebase Messaging.")
	var settings := _ler_arquivo("res://android/build/settings.gradle")
	_esperar(settings.contains("com.google.gms.google-services"), "settings.gradle deve registrar Google Services plugin.")
	var manifest := _ler_arquivo("res://android/build/src/main/AndroidManifest.xml")
	_esperar(manifest.contains("org.godotengine.plugin.v2.CyronPush"), "Manifest deve registrar singleton CyronPush.")
	_esperar(manifest.contains("CyronFirebaseMessagingService"), "Manifest deve registrar FirebaseMessagingService.")
	var plugin := _ler_arquivo("res://android/build/src/main/java/com/tiago/cyronpush/CyronPushPlugin.kt")
	_esperar(plugin.contains("showLocalNotification"), "Plugin Android deve expor notificacao local.")
	_esperar(plugin.contains("subscribeToTopic(TOPIC_ALL)"), "Plugin Android deve assinar topico global do Firebase.")


func _ler_arquivo(path: String) -> String:
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		return ""
	var txt := f.get_as_text()
	f.close()
	return txt


func _esperar(condicao: bool, msg: String) -> void:
	if not condicao:
		_falhas.append(msg)


func _finalizar() -> void:
	for pulado in _pulados:
		print("PULADO: ", pulado)
	if _falhas.is_empty():
		if _pulados.is_empty():
			print("OK notificacoes")
		else:
			print("OK notificacoes (%d conferencia(s) pulada(s))" % _pulados.size())
		get_tree().quit(0)
	else:
		for falha in _falhas:
			push_error(falha)
		get_tree().quit(1)
