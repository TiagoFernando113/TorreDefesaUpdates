extends Node

const APP_VERSION_CODE: int = 12
const APP_VERSION_NAME: String = "0.12.0"
const STORE_BUILD_FEATURE: String = "store_build"
const FORCE_RELEASE_MODE: bool = false
const ALLOW_SIDELOAD_ANDROID_UPDATES: bool = true


func is_mobile() -> bool:
	return OS.has_feature("android") or OS.has_feature("ios")


func is_store_build() -> bool:
	return OS.has_feature(STORE_BUILD_FEATURE)


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
