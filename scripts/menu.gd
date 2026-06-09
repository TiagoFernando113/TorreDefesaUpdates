extends Node2D

const TALENTO_NO = preload("res://scripts/talento_no.gd")
const ARVORE_FUNDO = preload("res://scripts/arvore_fundo.gd")
const CONSTELLATION_FUNDO = preload("res://scripts/talent_constellation_fundo.gd")
const NumberFormatter = preload("res://scripts/number_formatter.gd")
const MENU_RANKING_TEXTURE = preload("res://assets/menu/menu_ranking_transparent.png")
const MENU_ACCESSIBILITY_TEXTURE = preload("res://assets/menu/menu_acessibilidade_transparent.png")
const MENU_DISCORD_TEXTURE = preload("res://assets/menu/menu_discord_transparent.png")
const ATTRIBUTES_SCREEN = preload("res://ui/screens/AttributesScreen.tscn")
const TITLE_FONT_RESOURCE : FontFile = preload("res://assets/fonts/ethnocentric_rg.otf")
const TECH_FONT_RESOURCE : FontFile = preload("res://assets/fonts/bahnschrift.ttf")
const DEBUG_MENU_WHITE_BACKGROUND : bool = false
const DEBUG_MENU_MAP_PREVIEW : bool = false
const DEBUG_MOCHILA_MOSTRAR_TODOS_ITENS : bool = false
const SHOW_PREMIUM_PURCHASES : bool = false
const DEBUG_PREMIUM_TEST_PURCHASES : bool = false
const DISCORD_CANAL_URL : String = "https://discord.gg/qDvVaTvDeb"
const BAU_SPRITE_BASE : String = "res://assets/sprites/baus/"
const ITEM_SPRITE_BASE : String = "res://assets/sprites/itens/"
const REWARD_CARD_BASE_PATH : String = "res://assets/sprites/ui_hud/reward_card_base.png"
const UI_COIN_TEXTURE_PATH : String = "res://assets/sprites/ui_hud/cytron_coin_icon.png"
const UI_CRYSTAL_TEXTURE_PATH : String = "res://assets/sprites/ui_hud/cyron_crystal_icon.png"
const TALENT_MAP_TEXTURE_PATH : String = "res://assets/talents/talent_constellation_map.png"
const TALENT_MAP_SOURCE_SIZE : Vector2 = Vector2(1774.0, 887.0)
const TALENT_MAP_WORLD_MIN_WIDTH : float = 1900.0
const TALENT_MAP_WORLD_WIDTH_FACTOR : float = 1.72
const TALENT_STAR_STATES_TEXTURE_PATH : String = "res://assets/talents/talent_star_states_sheet.png"
const TALENT_CALIBRATION_EXPORT_PATH : String = "res://data/talent_calibration_map.json"
const TALENT_USE_CALIBRATION_POSITIONS : bool = false
const REWARD_CARD_TEXTURE_PATHS : Dictionary = {
	"comum": "res://assets/sprites/ui_hud/reward_card_common.png",
	"raro": "res://assets/sprites/ui_hud/reward_card_rare.png",
	"epico": "res://assets/sprites/ui_hud/reward_card_epic.png",
	"lendario": "res://assets/sprites/ui_hud/reward_card_legendary.png",
}
const ITEM_SPRITES_MOCHILA_ATIVOS : Dictionary = {
	"vela_da_alma": true,
	"orbe_de_cura": true,
	"cristal_barreira": true,
	"runa_de_furia": true,
	"pulso_eletrico": true,
	"bomba_de_gelo": true,
	"pulso_final": true,
	"canhao_plasma": true,
	"disparador_ionico": true,
	"lente_orbital": true,
	"devastador_eclipse": true,
	"nucleo_vital": true,
	"reator_lunar": true,
	"campo_defletor": true,
	"placa_lunar": true,
	"casco_meteoro": true,
	"armadura_imperial": true,
	"bateria_cristal": true,
	"fragmento_lunar": true,
	"coracao_estelar": true,
	"orbe_abissal": true,
	"selo_dante": true,
	"reliquia_cyron": true,
}
const COMANDANTE_SPRITE_BASE : String = "res://assets/sprites/comandantes/"
const COMANDANTE_MENU_BG_BASE : String = "res://assets/sprites/comandantes/menu_bg/"
const TITLE_FONT_PATH : String = "res://assets/fonts/ethnocentric_rg.otf"

var pulse:= 0.0
var hex_angle:= 0.0
var _bau_sprite_cache : Dictionary = {}
var _item_sprite_cache : Dictionary = {}
var _currency_texture_cache : Dictionary = {}
var _skin_sprite_cache : Dictionary = {}
var _reward_card_texture_cache : Dictionary = {}
var _comandante_sprite_cache : Dictionary = {}
var _comandante_bg_cache : Dictionary = {}
var _mapa_bg_cache : Dictionary = {}
var _font_tech : Font = TECH_FONT_RESOURCE
var _font_title : Font = TITLE_FONT_RESOURCE


var _deco_mobs: Array = []
var _inventario_reselect_item: Dictionary = {}
var _inventario_arsenal_aberto: bool = false
var _inventario_filtro_atual: String = "tudo"
var _inventario_scroll_bar: VScrollBar = null
var _inventario_scroll_content: Control = null
var _inventario_scroll_area: Rect2 = Rect2()
var _inventario_scroll_view_h: float = 0.0
var _inventario_scroll_enabled: bool = false
var _inventario_scroll_target: float = 0.0
var _inventario_scroll_tween: Tween = null
var _inventario_touch_active: bool = false
var _inventario_touch_scrolling: bool = false
var _inventario_touch_last_pos: Vector2 = Vector2.ZERO
var _inventario_touch_suppress_tap_until: int = 0

const CENTRO:= Vector2(640, 360)

var _loja_overlay = null
var _loja_panel = null
var _loja_scroll_cont: Control = null
var _loja_scroll_node: ScrollContainer = null
var _loja_cont_w: float = 1244.0
var _inventario_overlay: ColorRect = null
var _bau_abertura_overlay: ColorRect = null
var _mapas_overlay: ColorRect = null
var _talentos_overlay = null
var _talentos_panel = null
var _talentos_scroll: ScrollContainer = null
var _talentos_content_y_off: float = 0.0
var _config_overlay = null
var _config_panel = null
var _config_confirm:= false
var _cfg_nome_antigo: String = ""
var _hist_overlay = null
var _hist_panel = null
var _perfil_overlay = null
var _perfil_panel = null
var _perfil_btn: Control = null
var _patente_overlay = null
var _patente_panel = null
var _attributes_screen: Control = null
var _aval_overlay = null
var _aval_aba: int = 0
var _aval_notas: Array = [0, 0, 0, 0, 0, 0]
var _aval_textos: Array = ["", "", "", "", "", ""]
var _aval_conteudo: Control = null

var _ranking_overlay = null
var _ranking_panel = null
var _ranking_lista: Control = null
var _ranking_ts_lbl: Label = null
var _ranking_pos_lbl: Label = null
var _ranking_campeoes_cont: Control = null
var _ranking_carregando: bool = false
var _ui_ref = null
var _ui_main: CanvasLayer = null
var _tree_tweens: Array = []
var _menu_contents: Control = null
var _menu_comandante_atual: String = ""
var _discord_premio_poll_ativo: bool = false
var _discord_reward_badge: Control = null
var _discord_reward_badge_visivel: bool = true
var _cyron_popup_overlay: CanvasLayer = null
var _menu_hint_popup: Control = null
var _menu_hint_seq: int = 0

var _tab_talentos: String = "ramos"
var _talento_pendente: String = ""
var _talento_pendente_toques: int = 0
var _talento_detalhe_nome: Label = null
var _talento_detalhe_sub: Label = null
var _talento_detalhe_desc: Label = null
var _talento_detalhe_estado: Label = null
var _talento_detalhe_pontos: Label = null
var _talento_detalhe_cover: Control = null
var _talento_reset_btn: Button = null
var _talento_reset_confirmar: bool = false
var _talent_map_bg_rect: TextureRect = null
var _talent_constellation_layer: Control = null
var _talent_map_hitboxes: Dictionary = {}
var _talent_map_pan: Vector2 = Vector2.ZERO
var _talent_map_zoom: float = 0.0
var _talent_map_dragging: bool = false
var _talent_map_drag_last: Vector2 = Vector2.ZERO
var _talent_calibration_active: bool = false
var _talent_calibration_area_mode: bool = false
var _talent_calibration_index: int = 0
var _talent_calibration_group_index: int = 0
var _talent_calibration_positions: Dictionary = {}
var _talent_calibration_groups_by_id: Dictionary = {}
var _talent_calibration_notes_by_id: Dictionary = {}
var _talent_calibration_text_rect_norm: Rect2 = Rect2(0.022, 0.330, 0.190, 0.575)
var _talent_calibration_layer: Control = null
var _talent_calibration_desc_edit: LineEdit = null
var _talent_calibration_dragging: bool = false
var _talent_calibration_drag_start: Vector2 = Vector2.ZERO
var _talent_calibration_drag_current: Vector2 = Vector2.ZERO

var _tut_overlay  : CanvasLayer = null
var _tut_jogar_rect  : Rect2 = Rect2()
var _tut_loja_rect   : Rect2 = Rect2()
var _tut_inv_rect    : Rect2 = Rect2()
var _tut_tal_rect    : Rect2 = Rect2()
var _tut_hist_rect   : Rect2 = Rect2()
var _tut_diff_rect   : Rect2 = Rect2()
var _last_viewport_size: Vector2 = Vector2.ZERO
var _resize_rebuild_delay: float = -1.0
var _resize_rebuilding: bool = false


func _ready() -> void :
	Engine.time_scale = 1.0
	_carregar_fonte_titulo()
	_deco_mobs.clear()
	_desativar_fundo_antigo_menu()
	_load_talent_calibration()
	_last_viewport_size = get_viewport().get_visible_rect().size
	_construir_ui()
	_configurar_discord_link()
	if not RankingOnline.premio_temporada_aplicado.is_connected(_on_premio_temporada_aplicado):
		RankingOnline.premio_temporada_aplicado.connect(_on_premio_temporada_aplicado)
	RankingOnline.buscar_premios_pendentes()
	if not Salvar.tutorial_menu_visto:
		_abrir_tutorial()
	Som.tocar_musica_menu(true)
	_garantir_musica_menu_depois_de_voltar()
	RankingOnline.checar_diario()
	RankingOnline.checar_premio_temporada()


func _garantir_musica_menu_depois_de_voltar() -> void:
	call_deferred("_garantir_musica_menu_agora")
	var timer := get_tree().create_timer(1.5)
	timer.timeout.connect(func() -> void:
		if is_inside_tree():
			_garantir_musica_menu_agora()
	)


func _garantir_musica_menu_agora() -> void:
	Som.garantir_musica_menu()


func _carregar_fonte_titulo() -> void:
	_font_tech = TECH_FONT_RESOURCE
	_font_title = TITLE_FONT_RESOURCE if TITLE_FONT_RESOURCE != null else _font_tech
	if _font_title == null:
		push_warning("Nao foi possivel carregar a fonte de titulo: %s" % TITLE_FONT_PATH)


func _desativar_fundo_antigo_menu() -> void:
	var bg := get_node_or_null("Background")
	if bg == null:
		return
	bg.set_process(false)
	bg.set_physics_process(false)
	if bg is CanvasItem:
		var canvas_bg := bg as CanvasItem
		canvas_bg.visible = false
	bg.queue_free()


func _on_premio_temporada_aplicado(posicao: int, temporada: int, baus_lendarios: int, cristais_bonus: int) -> void:
	if not _ui_main or not is_instance_valid(_ui_main):
		return
	var vp:= get_viewport().get_visible_rect().size
	var ov:= ColorRect.new()
	ov.color = Color(0.0, 0.0, 0.0, 0.72)
	ov.position = Vector2.ZERO
	ov.size = vp
	ov.mouse_filter = Control.MOUSE_FILTER_STOP
	_ui_main.add_child(ov)

	var pw: float = minf(620.0, vp.x - 34.0)
	var ph: float = 300.0
	var pnl:= Panel.new()
	pnl.position = Vector2((vp.x - pw) * 0.5, (vp.y - ph) * 0.5)
	pnl.size = Vector2(pw, ph)
	var sty:= StyleBoxFlat.new()
	sty.bg_color = Color(0.035, 0.025, 0.01, 0.98)
	sty.border_color = Color(1.0, 0.78, 0.12, 0.95)
	for s in ["left", "right", "top", "bottom"]:
		sty.set("border_width_" + s, 2)
	for c in ["top_left", "top_right", "bottom_left", "bottom_right"]:
		sty.set("corner_radius_" + c, 12)
	pnl.add_theme_stylebox_override("panel", sty)
	ov.add_child(pnl)

	var tit:= Label.new()
	tit.text = "PREMIO DA TEMPORADA"
	tit.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tit.position = Vector2(20, 24)
	tit.size = Vector2(pw - 40, 40)
	tit.add_theme_font_size_override("font_size", 30)
	tit.add_theme_color_override("font_color", Color(1.0, 0.86, 0.18))
	pnl.add_child(tit)

	var msg:= Label.new()
	msg.text = "Você terminou a temporada %d em %dº lugar." % [temporada, posicao]
	msg.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	msg.position = Vector2(30, 76)
	msg.size = Vector2(pw - 60, 30)
	msg.add_theme_font_size_override("font_size", 20)
	msg.add_theme_color_override("font_color", Color(0.82, 0.9, 1.0))
	pnl.add_child(msg)

	var rec:= Label.new()
	rec.text = "+%d Bau%s Estelar%s    +%d cristais" % [
		baus_lendarios,
		"" if baus_lendarios == 1 else "s",
		"" if baus_lendarios == 1 else "es",
		cristais_bonus
	]
	rec.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	rec.position = Vector2(28, 122)
	rec.size = Vector2(pw - 56, 44)
	rec.add_theme_font_size_override("font_size", 25)
	rec.add_theme_color_override("font_color", Color(1.0, 0.92, 0.36))
	pnl.add_child(rec)

	var sub:= Label.new()
	sub.text = "Recompensa enviada para sua mochila."
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.position = Vector2(36, 172)
	sub.size = Vector2(pw - 72, 28)
	sub.add_theme_font_size_override("font_size", 17)
	sub.add_theme_color_override("font_color", Color(0.58, 0.72, 0.86))
	pnl.add_child(sub)

	var btn:= Button.new()
	btn.text = "CONTINUAR"
	btn.position = Vector2((pw - 230.0) * 0.5, ph - 72.0)
	btn.size = Vector2(230, 48)
	btn.focus_mode = Control.FOCUS_NONE
	btn.add_theme_font_size_override("font_size", 22)
	var bsty:= StyleBoxFlat.new()
	bsty.bg_color = Color(0.12, 0.1, 0.02, 0.95)
	bsty.border_color = Color(1.0, 0.82, 0.12, 0.95)
	for s2 in ["left", "right", "top", "bottom"]:
		bsty.set("border_width_" + s2, 2)
	for c2 in ["top_left", "top_right", "bottom_left", "bottom_right"]:
		bsty.set("corner_radius_" + c2, 8)
	btn.add_theme_stylebox_override("normal", bsty)
	btn.add_theme_color_override("font_color", Color(1.0, 0.88, 0.26))
	btn.pressed.connect(func(): ov.queue_free())
	pnl.add_child(btn)



func _gerar_mobs_deco() -> void :
	return

	var formas = ["circulo", "triangulo", "diamante"]
	var cores = [Color(0.0, 0.82, 1.0), Color(0.75, 1.0, 0.1), Color(1.0, 0.35, 0.1)]
	for i in range(12):
		var angulo:= float(i) / 12.0 * TAU
		var raio:= randf_range(260.0, 520.0)
		_deco_mobs.append({
			"angulo": angulo, 
			"raio": raio, 
			"speed": randf_range(0.15, 0.35) * (1.0 if randf() > 0.5 else -1.0), 
			"tamanho": randf_range(8.0, 18.0), 
			"forma": formas[i % 3], 
			"cor": cores[i % 3], 
			"pulse": randf_range(0.0, TAU), 
		})


func _unhandled_input(event: InputEvent) -> void :
	if OS.has_feature("android") or OS.has_feature("ios"): return
	if not (event is InputEventKey): return
	if not (event as InputEventKey).pressed: return
	if (event as InputEventKey).keycode == KEY_F11:
		var modo:= DisplayServer.window_get_mode()
		if modo == DisplayServer.WINDOW_MODE_FULLSCREEN:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		else:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)


func _input(event: InputEvent) -> void:
	if _handle_talent_calibration_input(event):
		return
	if _handle_talent_map_navigation_input(event):
		return
	_handle_inventario_wheel(event)


func _handle_inventario_wheel(event: InputEvent) -> void:
	if not _inventario_scroll_enabled:
		return
	if event is InputEventScreenTouch:
		var touch := event as InputEventScreenTouch
		if touch.pressed:
			_inventario_touch_active = _inventario_scroll_area.has_point(touch.position)
			_inventario_touch_scrolling = false
			_inventario_touch_last_pos = touch.position
		else:
			if _inventario_touch_active and _inventario_touch_scrolling:
				_inventario_touch_suppress_tap_until = Time.get_ticks_msec() + 180
				get_viewport().set_input_as_handled()
			_inventario_touch_active = false
			_inventario_touch_scrolling = false
		return
	if event is InputEventScreenDrag:
		if not _inventario_touch_active:
			return
		var drag := event as InputEventScreenDrag
		var delta_drag := -drag.relative.y
		if absf(delta_drag) < 0.1:
			return
		_inventario_touch_scrolling = true
		_inventario_touch_last_pos = drag.position
		_aplicar_scroll_mochila(delta_drag, false)
		get_viewport().set_input_as_handled()
		return
	if not (event is InputEventMouseButton):
		return
	var mb := event as InputEventMouseButton
	if not mb.pressed:
		return
	var delta := 0.0
	if mb.button_index == MOUSE_BUTTON_WHEEL_DOWN:
		delta = 46.0
	elif mb.button_index == MOUSE_BUTTON_WHEEL_UP:
		delta = -46.0
	else:
		return
	if not _inventario_scroll_area.has_point(get_viewport().get_mouse_position()):
		return
	_aplicar_scroll_mochila(delta)
	get_viewport().set_input_as_handled()


func _aplicar_scroll_mochila(delta: float, smooth: bool = true) -> void:
	if _inventario_scroll_bar == null or _inventario_scroll_content == null:
		return
	if not is_instance_valid(_inventario_scroll_bar) or not is_instance_valid(_inventario_scroll_content):
		return
	var max_scroll : float = maxf(0.0, _inventario_scroll_content.size.y - _inventario_scroll_view_h)
	_inventario_scroll_target = clampf(_inventario_scroll_target + delta, 0.0, max_scroll)
	if not smooth:
		if _inventario_scroll_tween and _inventario_scroll_tween.is_valid():
			_inventario_scroll_tween.kill()
		_inventario_scroll_bar.value = _inventario_scroll_target
		_inventario_scroll_content.position.y = -_inventario_scroll_target
		return
	if _inventario_scroll_tween and _inventario_scroll_tween.is_valid():
		_inventario_scroll_tween.kill()
	_inventario_scroll_tween = create_tween()
	_inventario_scroll_tween.set_parallel(true)
	_inventario_scroll_tween.tween_property(_inventario_scroll_bar, "value", _inventario_scroll_target, 0.16).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	_inventario_scroll_tween.tween_property(_inventario_scroll_content, "position:y", -_inventario_scroll_target, 0.16).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)


func _limpar_scroll_mochila() -> void:
	_inventario_scroll_enabled = false
	_inventario_scroll_bar = null
	_inventario_scroll_content = null
	_inventario_scroll_area = Rect2()
	_inventario_scroll_view_h = 0.0
	_inventario_scroll_target = 0.0
	_inventario_touch_active = false
	_inventario_touch_scrolling = false
	_inventario_touch_last_pos = Vector2.ZERO
	_inventario_touch_suppress_tap_until = 0
	if _inventario_scroll_tween and _inventario_scroll_tween.is_valid():
		_inventario_scroll_tween.kill()
	_inventario_scroll_tween = null


func _is_primary_press(event: InputEvent) -> bool:
	if event is InputEventMouseButton:
		if OS.get_name() == "Android":
			return false
		var mbe := event as InputEventMouseButton
		return mbe.pressed and mbe.button_index == MOUSE_BUTTON_LEFT
	if event is InputEventScreenTouch:
		return (event as InputEventScreenTouch).pressed
	return false


func _texto_ui_suspeito_count(txt: String) -> int:
	var total := 0
	for marca in ["Ã", "â", "Â·", "Â ", "Â\n", "Â-", "Â)", "Â("]:
		if txt.find(marca) != -1:
			total += 1
	return total


func _bytes_utf8_validos(bytes: PackedByteArray) -> bool:
	var i := 0
	while i < bytes.size():
		var b := int(bytes[i])
		if b <= 0x7F:
			i += 1
		elif b >= 0xC2 and b <= 0xDF:
			if i + 1 >= bytes.size() or int(bytes[i + 1]) < 0x80 or int(bytes[i + 1]) > 0xBF:
				return false
			i += 2
		elif b >= 0xE0 and b <= 0xEF:
			if i + 2 >= bytes.size():
				return false
			var b1 := int(bytes[i + 1])
			var b2 := int(bytes[i + 2])
			if b1 < 0x80 or b1 > 0xBF or b2 < 0x80 or b2 > 0xBF:
				return false
			i += 3
		elif b >= 0xF0 and b <= 0xF4:
			if i + 3 >= bytes.size():
				return false
			var c1 := int(bytes[i + 1])
			var c2 := int(bytes[i + 2])
			var c3 := int(bytes[i + 3])
			if c1 < 0x80 or c1 > 0xBF or c2 < 0x80 or c2 > 0xBF or c3 < 0x80 or c3 > 0xBF:
				return false
			i += 4
		else:
			return false
	return true


func _texto_ui_limpador_manual(txt: String) -> String:
	var s := txt
	s = s.replace("âš ", "[!]")
	s = s.replace("âš”", "ATK")
	s = s.replace("â˜…", "*")
	s = s.replace("â˜ ", "KO")
	s = s.replace("â€”", "—")
	s = s.replace("â€“", "–")
	s = s.replace("â†’", "→")
	s = s.replace("âœŽ", "EDIT")
	s = s.replace("âœ“", "OK")
	s = s.replace("âœ”", "OK")
	s = s.replace("âœ—", "X")
	s = s.replace("âœ•", "X")
	s = s.replace("âˆ’", "−")
	s = s.replace("â—†", "◆")
	s = s.replace("â—", "●")
	s = s.replace("â—‹", "○")
	s = s.replace("â€¢", "•")
	s = s.replace("â€¦", "...")
	s = s.replace("â€™", "'")
	s = s.replace("â€˜", "'")
	s = s.replace("â€œ", "\"")
	s = s.replace("â€�", "\"")
	s = s.replace("Ã—", "×")
	s = s.replace("Â·", "·")
	s = s.replace("Â ", " ")
	s = s.replace("⚠", "[!]")
	s = s.replace("⚔", "ATK")
	s = s.replace("★", "*")
	s = s.replace("☠", "KO")
	s = s.replace("✎", "EDIT")
	s = s.replace("✓", "OK")
	s = s.replace("✗", "X")
	s = s.replace("✕", "X")
	return s


func _texto_ui_decodificar_uma_vez(txt: String) -> String:
	var cp1252_extra := {
		0x20AC: 0x80, 0x201A: 0x82, 0x0192: 0x83, 0x201E: 0x84,
		0x2026: 0x85, 0x2020: 0x86, 0x2021: 0x87, 0x02C6: 0x88,
		0x2030: 0x89, 0x0160: 0x8A, 0x2039: 0x8B, 0x0152: 0x8C,
		0x017D: 0x8E, 0x2018: 0x91, 0x2019: 0x92, 0x201C: 0x93,
		0x201D: 0x94, 0x2022: 0x95, 0x2013: 0x96, 0x2014: 0x97,
		0x02DC: 0x98, 0x2122: 0x99, 0x0161: 0x9A, 0x203A: 0x9B,
		0x0153: 0x9C, 0x017E: 0x9E, 0x0178: 0x9F,
	}
	var bytes := PackedByteArray()
	for i in range(txt.length()):
		var cp := txt.unicode_at(i)
		if cp <= 0xFF:
			bytes.append(cp)
		elif cp1252_extra.has(cp):
			bytes.append(int(cp1252_extra[cp]))
		else:
			return _texto_ui_limpador_manual(txt)

	if not _bytes_utf8_validos(bytes):
		return _texto_ui_limpador_manual(txt)
	var limpo := bytes.get_string_from_utf8()
	if limpo.is_empty() or limpo.find("\uFFFD") != -1:
		return _texto_ui_limpador_manual(txt)
	return _texto_ui_limpador_manual(limpo)


func _texto_ui_limpo(txt: String) -> String:
	if txt.is_empty():
		return txt

	var melhor := _texto_ui_limpador_manual(txt)
	var melhor_score := _texto_ui_suspeito_count(melhor)
	var atual := melhor
	for _i in range(4):
		var score_atual := _texto_ui_suspeito_count(atual)
		if score_atual <= 0:
			break
		var prox := _texto_ui_decodificar_uma_vez(atual)
		prox = _texto_ui_limpador_manual(prox)
		if prox == atual:
			break
		var prox_score := _texto_ui_suspeito_count(prox)
		if prox_score <= melhor_score:
			melhor = prox
			melhor_score = prox_score
		atual = prox
	return melhor


func _corrigir_textos_ui(root: Node) -> void:
	if root == null or not is_instance_valid(root):
		return
	if root is Label:
		var lbl := root as Label
		lbl.text = _texto_ui_limpo(lbl.text)
	elif root is BaseButton:
		var btn := root as BaseButton
		btn.text = _texto_ui_limpo(btn.text)
	elif root is LineEdit:
		var le := root as LineEdit
		le.text = _texto_ui_limpo(le.text)
		le.placeholder_text = _texto_ui_limpo(le.placeholder_text)
	elif root is TextEdit:
		var te := root as TextEdit
		te.text = _texto_ui_limpo(te.text)
		te.placeholder_text = _texto_ui_limpo(te.placeholder_text)
	for child in root.get_children():
		if child is Node:
			_corrigir_textos_ui(child as Node)


func _process(delta: float) -> void :
	pulse += delta * 1.8
	hex_angle += delta * 0.4
	_monitorar_resize_viewport(delta)

	for m in _deco_mobs:
		m["angulo"] += m["speed"] * delta
		m["pulse"] += delta * 2.5

	queue_redraw()
	if _perfil_btn and is_instance_valid(_perfil_btn):
		_perfil_btn.queue_redraw()
	if _discord_reward_badge and is_instance_valid(_discord_reward_badge):
		_discord_reward_badge.queue_redraw()


func _monitorar_resize_viewport(delta: float) -> void:
	var vp_now := get_viewport().get_visible_rect().size
	if _bau_abertura_overlay and is_instance_valid(_bau_abertura_overlay):
		_bau_abertura_overlay.size = vp_now
		_last_viewport_size = vp_now
		_resize_rebuild_delay = -1.0
		return
	if _last_viewport_size == Vector2.ZERO:
		_last_viewport_size = vp_now
		return
	if absf(vp_now.x - _last_viewport_size.x) > 0.5 or absf(vp_now.y - _last_viewport_size.y) > 0.5:
		_last_viewport_size = vp_now
		_resize_rebuild_delay = 0.14
		return
	if _resize_rebuild_delay < 0.0:
		return
	_resize_rebuild_delay -= delta
	if _resize_rebuild_delay <= 0.0:
		_resize_rebuild_delay = -1.0
		_reconstruir_ui_por_resize()


func _tela_aberta_por_resize() -> String:
	if _inventario_overlay and is_instance_valid(_inventario_overlay):
		return "inventario"
	if _loja_overlay and is_instance_valid(_loja_overlay):
		return "loja"
	if _talentos_overlay and is_instance_valid(_talentos_overlay):
		return "talentos"
	if _ranking_overlay and is_instance_valid(_ranking_overlay):
		return "ranking"
	if _config_overlay and is_instance_valid(_config_overlay):
		return "config"
	if _hist_overlay and is_instance_valid(_hist_overlay):
		return "historico"
	if _perfil_overlay and is_instance_valid(_perfil_overlay):
		return "perfil"
	if _aval_overlay and is_instance_valid(_aval_overlay):
		return "avaliacao"
	if _mapas_overlay and is_instance_valid(_mapas_overlay):
		return "mapas"
	return ""


func _limpar_referencias_ui_por_resize() -> void:
	_limpar_scroll_mochila()
	for tw in _tree_tweens:
		if is_instance_valid(tw):
			(tw as Tween).kill()
	_tree_tweens.clear()
	if _ui_main and is_instance_valid(_ui_main):
		_ui_main.hide()
		_ui_main.queue_free()
	if _tut_overlay and is_instance_valid(_tut_overlay):
		_tut_overlay.queue_free()
	_tut_overlay = null
	_ui_main = null
	_ui_ref = null
	_menu_contents = null
	_perfil_btn = null
	_inventario_overlay = null
	_mapas_overlay = null
	_loja_overlay = null
	_loja_panel = null
	_loja_scroll_cont = null
	_loja_scroll_node = null
	_talentos_overlay = null
	_talentos_panel = null
	_talentos_scroll = null
	_talent_map_bg_rect = null
	_talent_map_hitboxes.clear()
	_talento_detalhe_cover = null
	_talento_reset_btn = null
	_config_overlay = null
	_config_panel = null
	_hist_overlay = null
	_hist_panel = null
	_perfil_overlay = null
	_perfil_panel = null
	_aval_overlay = null
	_aval_conteudo = null
	_ranking_overlay = null
	_ranking_panel = null
	_ranking_lista = null
	_ranking_ts_lbl = null
	_ranking_pos_lbl = null
	_ranking_campeoes_cont = null
	_bau_abertura_overlay = null


func _reconstruir_ui_por_resize() -> void:
	if _resize_rebuilding:
		return
	_resize_rebuilding = true
	var tela_aberta := _tela_aberta_por_resize()
	_limpar_referencias_ui_por_resize()
	_construir_ui()
	match tela_aberta:
		"inventario":
			_abrir_inventario(_ui_main)
		"loja":
			_abrir_loja(_ui_main)
		"talentos":
			_abrir_talentos(_ui_main)
		"ranking":
			_abrir_ranking(_ui_main)
		"config":
			_abrir_config(_ui_main)
		"historico":
			_abrir_hist(_ui_main)
		"perfil":
			_abrir_perfil(_ui_main)
		"avaliacao":
			_abrir_avaliacao(_ui_main)
		"mapas":
			_abrir_mapas(_ui_main)
	_last_viewport_size = get_viewport().get_visible_rect().size
	_resize_rebuilding = false


func _draw() -> void :
	pass



func _draw_torre_deco() -> void :
	var p:= sin(pulse) * 0.3 + 0.7
	var cor:= Color(0.0, 0.72, 1.0)
	var pos:= CENTRO


	for r in [90.0, 160.0, 240.0]:
		var rf: float = r as float
		var rp: float = rf + sin(pulse * 0.7 + rf * 0.01) * 6.0
		draw_arc(pos, rp, 0.0, TAU, 80, Color(cor.r, cor.g, cor.b, 0.12), 1.2)


	for i in range(6, 0, -1):
		draw_circle(pos, 32.0 + float(i) * 7.0, Color(cor.r, cor.g, cor.b, 0.07 * p / float(i)))


	var pts:= PackedVector2Array()
	for i in range(6):
		var a:= float(i) * TAU / 6.0 + PI / 6.0 + hex_angle
		pts.append(pos + Vector2(cos(a), sin(a)) * 32.0)
	draw_polygon(pts, _cores(pts.size(), Color(0.02, 0.08, 0.22, 0.92)))
	var borda:= PackedVector2Array(pts);borda.append(pts[0])
	for i in range(3, 0, -1):
		draw_polyline(borda, Color(cor.r, cor.g, cor.b, 0.22 / float(i) * p), float(i) * 2.5)
	draw_polyline(borda, Color(cor.r + 0.2, cor.g + 0.15, 1.0, 1.0), 2.2)


	draw_circle(pos, 10.0, Color(cor.r + 0.2, cor.g + 0.2, 1.0, p))
	draw_circle(pos, 5.0, Color(1.0, 1.0, 1.0, p))


func _draw_titulo() -> void :

	var p:= sin(pulse * 1.2) * 0.3 + 0.7
	var lw:= 280.0 + sin(pulse) * 20.0
	draw_line(Vector2(640 - lw, 115), Vector2(640 + lw, 115), 
			Color(0.2, 0.6, 1.0, 0.5 * p), 1.5)
	draw_line(Vector2(640 - lw * 0.6, 180), Vector2(640 + lw * 0.6, 180), 
			Color(0.2, 0.6, 1.0, 0.3 * p), 1.0)


func _construir_ui() -> void :
	var ui:= CanvasLayer.new()
	ui.layer = 10
	add_child(ui)
	_ui_main = ui

	var vp_size := get_viewport().get_visible_rect().size
	var vp_w: float = vp_size.x
	var vp_h: float = maxf(720.0, vp_size.y)
	var safe_left := _menu_safe_margin_x()
	var mc:= Control.new()
	mc.position = Vector2.ZERO
	mc.size = Vector2(vp_w, vp_h)
	mc.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui.add_child(mc)
	_menu_contents = mc

	var _home_pid := _comandante_home_visual_pid()
	_menu_comandante_atual = _home_pid
	var _home_meta := _comandante_meta(_home_pid if _home_pid != "" else "cyron")
	var _mapa_home : Dictionary = Salvar.mapa_info("setor_inicial")
	var _home_cor : Color = (_home_meta.get("cor", Color(0.25,0.75,1.0)) as Color) if _home_pid != "" else (_mapa_home.get("cor", Color(0.0,0.72,1.0)) as Color)
	var _home_dark : Color = _home_meta.get("escura", Color(0.02,0.06,0.10)) as Color
	var _home_bg: Texture2D = null
	var home_rect := Rect2(0.0, 0.0, vp_w, vp_h)
	var fundo := Control.new()
	fundo.position = Vector2.ZERO
	fundo.size = Vector2(vp_w, vp_h)
	fundo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fundo.draw.connect(func():
		if DEBUG_MENU_WHITE_BACKGROUND:
			fundo.draw_rect(home_rect, Color.WHITE, true)
			return
		if DEBUG_MENU_MAP_PREVIEW:
			var mapas_count := Salvar.MAPAS_TORRE.size()
			var mapa_idx := int(Time.get_ticks_msec() / 1800) % maxi(1, mapas_count)
			var mapa_preview : Dictionary = Salvar.MAPAS_TORRE[mapa_idx] as Dictionary
			_draw_menu_mapa_fundo(fundo, home_rect, mapa_preview)
			var cor_preview : Color = mapa_preview.get("cor", Color(0.0, 0.72, 1.0)) as Color
			fundo.draw_rect(home_rect, Color(cor_preview.r, cor_preview.g, cor_preview.b, 0.08), true)
			fundo.draw_rect(home_rect, Color(0.0, 0.0, 0.0, 0.10), true)
			return
		fundo.draw_rect(home_rect, Color(0.0, 0.0, 0.0, 1.0), true)
		if _home_bg != null:
			_draw_texture_cover(fundo, _home_bg, home_rect, 1.0)
			fundo.draw_rect(home_rect, Color(_home_cor.r, _home_cor.g, _home_cor.b, 0.055), true)
		else:
			_draw_menu_mapa_fundo(fundo, home_rect, _mapa_home)
		fundo.draw_rect(home_rect, Color(0.0, 0.0, 0.0, 0.16), true)
	)
	mc.add_child(fundo)
	if DEBUG_MENU_MAP_PREVIEW:
		var preview_timer := Timer.new()
		preview_timer.wait_time = 0.2
		preview_timer.autostart = true
		preview_timer.timeout.connect(func():
			if is_instance_valid(fundo):
				fundo.queue_redraw()
		)
		mc.add_child(preview_timer)
	_ui_panel_frame(mc, Rect2(8.0, 8.0, vp_w - 16.0, vp_h - 16.0), _home_cor, 0.58)


	var lver:= Label.new()
	lver.text = "v%d" % Atualizador.versao_efetiva()
	lver.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	lver.position = Vector2(vp_w - 200, vp_h - 38.0)
	lver.size = Vector2(110, 42)
	lver.add_theme_font_size_override("font_size", 27)
	lver.add_theme_color_override("font_color", Color(0.6, 0.8, 1.0, 0.9))
	mc.add_child(lver)


	var wordmark_deco := Control.new()
	wordmark_deco.position = Vector2(24, 24)
	wordmark_deco.size = Vector2(360, 86)
	wordmark_deco.mouse_filter = Control.MOUSE_FILTER_IGNORE
	wordmark_deco.draw.connect(func():
		var c := Color(0.28, 0.78, 1.0, 0.28)
		wordmark_deco.draw_line(Vector2(8, 16), Vector2(360, 16), c, 1.0)
		wordmark_deco.draw_line(Vector2(8, 74), Vector2(286, 74), Color(0.28, 0.78, 1.0, 0.15), 1.0)
		wordmark_deco.draw_line(Vector2(360, 16), Vector2(376, 32), Color(0.28, 0.78, 1.0, 0.14), 1.0)
	)
	mc.add_child(wordmark_deco)

	var titulo:= Label.new()
	titulo.text = "CYRON  DEFENSE"
	titulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	titulo.position = Vector2(36, 35)
	titulo.size = Vector2(400, 42)
	titulo.clip_text = true
	titulo.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	titulo.add_theme_font_size_override("font_size", 29)
	titulo.add_theme_color_override("font_color", Color(0.90, 0.96, 1.0, 0.98))
	_ui_title_label(titulo, 5.0)
	mc.add_child(titulo)

	var subtitulo:= Label.new()
	subtitulo.text = "Defenda a torre. Sobreviva Ã s waves."
	subtitulo.text = "SISTEMA DEFENSIVO ORBITAL"
	subtitulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	subtitulo.position = Vector2(39, 75)
	subtitulo.size = Vector2(320, 22)
	subtitulo.add_theme_font_size_override("font_size", 12)
	subtitulo.add_theme_color_override("font_color", Color(0.38, 0.78, 1.0, 0.78))
	_ui_tech_label(subtitulo, 1.0)
	mc.add_child(subtitulo)


	var diff_lbl:= Label.new()
	diff_lbl.visible = false
	diff_lbl.text = "DIFICULDADE"
	diff_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	diff_lbl.position = Vector2(0, 208)
	diff_lbl.size = Vector2(vp_w, 20)
	diff_lbl.add_theme_font_size_override("font_size", 14)
	diff_lbl.add_theme_color_override("font_color", Color(0.5, 0.65, 0.8))
	mc.add_child(diff_lbl)

	var diff_dados := [
		["FÃCIL",   0, Color(0.1, 0.88, 0.42)],
		["NORMAL",  1, Color(0.0, 0.72, 1.0)],
		["DIFÃCIL", 2, Color(1.0, 0.28, 0.18)],
		["ABISMO",  3, Color(0.85, 0.18, 0.18)],
	]
	var diff_unlock := [
		true,
		Salvar.pode_jogar_normal(),
		Salvar.pode_jogar_dificil(),
		Salvar.pode_acessar_abismo()
	]
	var diff_req := [
		"",
		Salvar.requisito_normal(),
		Salvar.requisito_dificil(),
		Salvar.requisito_abismo()
	]
	var diff_btns : Array = []
	const DBTN_W  : float = 148.0
	const DBTN_GAP: float = 8.0
	var diff_total_w : float = diff_dados.size() * DBTN_W + (diff_dados.size() - 1) * DBTN_GAP
	var diff_start_x : float = (vp_w - diff_total_w) * 0.5

	for di in range(diff_dados.size()):
		var dd      : Array  = diff_dados[di] as Array
		var dtxt    : String = dd[0] as String
		var didx    : int    = dd[1] as int
		var dcor    : Color  = dd[2] as Color
		var desbloq : bool   = diff_unlock[di] as bool
		var req_txt : String = diff_req[di] as String
		var is_abismo : bool = didx == 3
		if not is_abismo and Salvar.dificuldade == didx and not desbloq:
			Salvar.dificuldade = maxi(0, didx - 1)
			Salvar.salvar()
		var dbtn := Button.new()
		dbtn.visible = false
		var lbl_ab := ""
		if is_abismo and desbloq and Salvar.high_score_abismo > 0:
			lbl_ab = "\n[ rec: %d ]" % Salvar.high_score_abismo
		dbtn.text = ("ðŸ”’ " if not desbloq else "") + dtxt + lbl_ab
		dbtn.position   = Vector2(diff_start_x + float(di) * (DBTN_W + DBTN_GAP), 232)
		dbtn.size       = Vector2(DBTN_W, 42)
		dbtn.focus_mode = Control.FOCUS_NONE
		dbtn.disabled   = not desbloq
		var cor_eff : Color = Color(dcor.r*0.45, dcor.g*0.45, dcor.b*0.45) if not desbloq else dcor
		var sty_d := StyleBoxFlat.new()
		var ativo := (not is_abismo and Salvar.dificuldade == didx and desbloq)
		sty_d.bg_color     = Color(cor_eff.r*0.2, cor_eff.g*0.2, cor_eff.b*0.2, 0.92) if ativo else Color(0.04, 0.06, 0.10, 0.88)
		sty_d.border_color = Color(cor_eff.r, cor_eff.g, cor_eff.b, 1.0 if ativo else (0.22 if not desbloq else 0.55))
		for side in ["left","right","top","bottom"]: sty_d.set("border_width_" + side, 2 if ativo else 1)
		for corner in ["top_left","top_right","bottom_left","bottom_right"]: sty_d.set("corner_radius_" + corner, 8)
		for st in ["normal","pressed","hover","hover_pressed","disabled"]: dbtn.add_theme_stylebox_override(st, sty_d)
		dbtn.add_theme_font_size_override("font_size", 15)
		dbtn.add_theme_color_override("font_color", Color(cor_eff.r+0.2, cor_eff.g+0.2, cor_eff.b+0.2))
		var desbloq_cap := desbloq; var didx_cap := didx; var is_abismo_cap := is_abismo
		dbtn.pressed.connect(func():
			if not desbloq_cap: return
			if is_abismo_cap:
				Acessibilidade.processar("menu_abismo",
					"Modo Abismo. Partida sem fim com dificuldade crescente.",
					_jogar_abismo)
				return
			var descs_dif := ["FÃ¡cil. Score x0.4.", "Normal. Score x1.0.", "DifÃ­cil. Score x1.6. Cristal extra por wave."]
			Acessibilidade.processar("dificuldade_" + str(didx_cap), descs_dif[didx_cap], func():
				Salvar.dificuldade = didx_cap
				Salvar.salvar()
				for bi in range(diff_btns.size()):
					var bb    : Button = diff_btns[bi] as Button
					var bdd   : Array  = diff_dados[bi] as Array
					var bunlk : bool   = diff_unlock[bi] as bool
					var bab   : bool   = (bdd[1] as int) == 3
					var bativ2 := not bab and Salvar.dificuldade == (bdd[1] as int) and bunlk
					var bcor  : Color = bdd[2] as Color
					var bceff : Color = Color(bcor.r*0.45, bcor.g*0.45, bcor.b*0.45) if not bunlk else bcor
					var bsty := StyleBoxFlat.new()
					bsty.bg_color     = Color(bceff.r*0.2, bceff.g*0.2, bceff.b*0.2, 0.92) if bativ2 else Color(0.04, 0.06, 0.10, 0.88)
					bsty.border_color = Color(bceff.r, bceff.g, bceff.b, 1.0 if bativ2 else (0.22 if not bunlk else 0.55))
					for s in ["left","right","top","bottom"]: bsty.set("border_width_" + s, 2 if bativ2 else 1)
					for c in ["top_left","top_right","bottom_left","bottom_right"]: bsty.set("corner_radius_" + c, 8)
					for st2 in ["normal","pressed","hover","hover_pressed","disabled"]: bb.add_theme_stylebox_override(st2, bsty)
		)
	)
		mc.add_child(dbtn)
		diff_btns.append(dbtn)
		if not desbloq and req_txt != "":
			var rlbl := Label.new()
			rlbl.visible = false
			rlbl.text = req_txt
			rlbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			rlbl.position = Vector2(diff_start_x + float(di) * (DBTN_W + DBTN_GAP), 278)
			rlbl.size = Vector2(DBTN_W, 46)
			rlbl.autowrap_mode = TextServer.AUTOWRAP_WORD
			rlbl.add_theme_font_size_override("font_size", 11)
			rlbl.add_theme_color_override("font_color", Color(0.55, 0.6, 0.65, 0.9))
			rlbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
			mc.add_child(rlbl)


	var mb_w: float = 344.0
	var mb_h: float = 70.0
	var mb_gap: float = 14.0
	var mb_x: float = safe_left
	var mb_sz:= Vector2(mb_w, mb_h)
	var mb_y: float = 166.0

	_tut_diff_rect = Rect2()
	var btn_jogar:= _criar_btn("JOGAR", Vector2(mb_x, mb_y), Color(0.0, 0.72, 1.0), mb_sz)
	_tut_jogar_rect = Rect2(mb_x, mb_y, mb_w, mb_h)
	if Salvar.save_bloqueado:
		btn_jogar.disabled = true
		btn_jogar.modulate = Color(0.4, 0.4, 0.4, 0.6)
		var lbloq:= Label.new()
		lbloq.text = "âš   Save requer v%d+  â€”  Atualize o jogo" % Salvar.versao_max_jogada
		lbloq.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbloq.position = Vector2(0, mb_y - 22)
		lbloq.size = Vector2(vp_w, 20)
		lbloq.add_theme_font_size_override("font_size", 13)
		lbloq.add_theme_color_override("font_color", Color(1.0, 0.55, 0.2))
		mc.add_child(lbloq)
	else:
		btn_jogar.pressed.connect(func():
			if Salvar.tem_checkpoint():
				_mostrar_dialog_continuar_ou_novo(mc)
			else:
				Acessibilidade.processar("menu_jogar",
					"Jogar. Inicia uma nova partida no mapa atual.", _jogar))
	mc.add_child(btn_jogar)
	mb_y += mb_h + mb_gap


	var btn_loja:= _criar_btn("LOJA", Vector2(mb_x, mb_y), Color(1.0, 0.78, 0.0), mb_sz)
	_tut_loja_rect = Rect2(mb_x, mb_y, mb_w, mb_h)
	btn_loja.pressed.connect( func():
		Acessibilidade.processar("menu_loja", 
			"Loja. Compra melhorias permanentes com ouro acumulado nas partidas.", 
			func(): _abrir_loja(ui)))
	mc.add_child(btn_loja)
	mb_y += mb_h + mb_gap

	var btn_inv := _criar_btn("INVENTÁRIO", Vector2(mb_x, mb_y), Color(0.35, 0.82, 0.6), mb_sz)
	_tut_inv_rect = Rect2(mb_x, mb_y, mb_w, mb_h)
	btn_inv.pressed.connect(func():
		Acessibilidade.processar("menu_inventario",
			"InventÃ¡rio. Veja e equipe itens na sua torre.",
			func(): _abrir_inventario(ui)))
	mc.add_child(btn_inv)
	mb_y += mb_h + mb_gap

	var btn_tal:= _criar_btn("TECNOLOGIAS", Vector2(mb_x, mb_y), Color(0.5, 0.25, 1.0), mb_sz)
	_tut_tal_rect = Rect2(mb_x, mb_y, mb_w, mb_h)
	btn_tal.pressed.connect( func():
		Acessibilidade.processar("menu_talentos", 
			"Tecnologias. Centro de tecnologia permanente comprado com cristais.", 
			func(): _abrir_talentos(ui)))
	mc.add_child(btn_tal)
	mb_y += mb_h + mb_gap

	var btn_hist:= _criar_btn("ESTATÃSTICAS", Vector2(mb_x, mb_y), Color(0.1, 0.85, 0.6), mb_sz)
	_tut_hist_rect = Rect2(8, 8, 80, 120)
	btn_hist.visible = false
	btn_hist.disabled = true
	btn_hist.pressed.connect( func():
		Acessibilidade.processar("menu_stats", 
			"EstatÃ­sticas. Ver histÃ³rico das Ãºltimas partidas e recordes.", 
			func(): _abrir_hist(ui)))
	mc.add_child(btn_hist)

	var btn_sair:= _criar_btn("SAIR", Vector2(mb_x, mb_y), Color(0.8, 0.2, 0.2), mb_sz)
	btn_sair.pressed.connect( func():
		Acessibilidade.processar("menu_sair", "Sair. Fecha o jogo.", 
			func(): get_tree().quit()))
	mc.add_child(btn_sair)


	var btn_cfg:= Button.new()
	btn_cfg.text = "CONFIG"
	btn_cfg.position = Vector2(vp_w - 158.0, 8)
	btn_cfg.size = Vector2(150, 38)
	btn_cfg.focus_mode = Control.FOCUS_NONE
	btn_cfg.add_theme_font_size_override("font_size", 16)
	var sty_cfg:= StyleBoxFlat.new()
	sty_cfg.bg_color = Color(0.08, 0.1, 0.14, 0.9)
	sty_cfg.border_color = Color(0.38, 0.45, 0.55, 0.75)
	for side in ["left", "right", "top", "bottom"]:
		sty_cfg.set("border_width_" + side, 1)
	for corner in ["top_left", "top_right", "bottom_left", "bottom_right"]:
		sty_cfg.set("corner_radius_" + corner, 6)
	btn_cfg.add_theme_stylebox_override("normal", sty_cfg)
	var sty_cfg_h: StyleBoxFlat = sty_cfg.duplicate()
	sty_cfg_h.bg_color = Color(0.15, 0.18, 0.24, 0.95)
	sty_cfg_h.border_color = Color(0.55, 0.65, 0.8, 1.0)
	btn_cfg.add_theme_stylebox_override("hover", sty_cfg_h)
	btn_cfg.add_theme_color_override("font_color", Color(0.72, 0.8, 0.92))
	_ui_tech_label(btn_cfg, 1.0)
	btn_cfg.pressed.connect( func():
		Acessibilidade.processar("menu_config", 
			"ConfiguraÃ§Ãµes. Ajustar volume de som, mÃºsica, dificuldade e acessibilidade.", 
			func(): _abrir_config(ui)))
	mc.add_child(btn_cfg)

	var currency_w : float = 286.0
	var currency_x : float = btn_cfg.position.x - currency_w - 10.0
	if currency_x >= 360.0:
		_add_currency_status(mc, Vector2(currency_x, 9.0), false, 90)
	else:
		_add_currency_status(mc, Vector2(maxf(8.0, vp_w - 248.0), 52.0), true, 90)


	var quick_sz := Vector2(124.0, 104.0)
	var quick_gap := 10.0
	var quick_y := 76.0
	var quick_x := vp_w - quick_sz.x - 18.0

	var btn_ac:= _ui_image_menu_button(MENU_ACCESSIBILITY_TEXTURE, Vector2(quick_x, quick_y), quick_sz)
	btn_ac.pressed.connect( func():
		var novo: bool = not Salvar.acessibilidade_ativo
		Acessibilidade.set_ativo(novo)
	)
	mc.add_child(btn_ac)

	var btn_rank:= _ui_image_menu_button(MENU_RANKING_TEXTURE, Vector2(quick_x, quick_y + quick_sz.y + quick_gap), quick_sz)
	btn_rank.pressed.connect( func():
		if not _ranking_overlay and not _config_overlay and not _loja_overlay and not _talentos_overlay:
			_abrir_ranking(ui))
	mc.add_child(btn_rank)

	var discord_sz := Vector2(94.0, 94.0)
	var btn_discord_menu:= _ui_image_menu_button(MENU_DISCORD_TEXTURE, Vector2(quick_x + (quick_sz.x - discord_sz.x) * 0.5, quick_y + (quick_sz.y + quick_gap) * 2.0), discord_sz)
	btn_discord_menu.pressed.connect(_abrir_discord_com_premio)
	mc.add_child(btn_discord_menu)
	_discord_reward_badge = _criar_discord_reward_badge(btn_discord_menu)
	_atualizar_discord_reward_badge()


	_perfil_btn = Control.new()
	_perfil_btn.position = Vector2(34, 610)
	_perfil_btn.size = Vector2(56, 56)
	_perfil_btn.mouse_filter = Control.MOUSE_FILTER_STOP
	_perfil_btn.draw.connect(_on_perfil_draw.bind(_perfil_btn))
	_perfil_btn.gui_input.connect(_on_perfil_input)
	mc.add_child(_perfil_btn)

	var lperf:= Label.new()
	lperf.name = "LPerfilNome"
	lperf.text = _perfil_nome_curto()
	lperf.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lperf.position = Vector2(14, 668)
	lperf.size = Vector2(96, 22)
	lperf.add_theme_font_size_override("font_size", 11)
	lperf.add_theme_color_override("font_color", Color(0.86, 0.90, 0.96, 0.82))
	_ui_tech_label(lperf, 0.0)
	mc.add_child(lperf)

	var btn_patente:= Button.new()
	btn_patente.text = ""
	btn_patente.position = Vector2(104, 606)
	btn_patente.size = Vector2(162, 50)
	btn_patente.focus_mode = Control.FOCUS_NONE
	btn_patente.add_theme_font_size_override("font_size", 1)
	_ui_premium_button(btn_patente, Color(1.0, 0.78, 0.16), Salvar.pontos_atributo > 0)
	btn_patente.pressed.connect(func(): _abrir_patente(ui))
	mc.add_child(btn_patente)

	var patente_preview := Control.new()
	patente_preview.set_anchors_preset(Control.PRESET_FULL_RECT)
	patente_preview.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var patente_xp_max : int = maxi(1, Salvar.xp_para_proximo_nivel())
	var patente_xp_atual : int = clampi(Salvar.xp_conta, 0, patente_xp_max)
	var patente_prog : float = clampf(float(patente_xp_atual) / float(patente_xp_max), 0.0, 1.0)
	var patente_nome : String = Salvar.patente_conta().to_upper()
	if patente_nome.length() > 14:
		patente_nome = patente_nome.substr(0, 12) + ".."
	patente_preview.draw.connect(func():
		var w := patente_preview.size.x
		var gold := Color(1.0, 0.82, 0.22, 0.96)
		var soft := Color(0.86, 0.90, 1.0, 0.78)
		patente_preview.draw_string(_font_tech, Vector2(12, 15), "PATENTE", HORIZONTAL_ALIGNMENT_LEFT, w - 24.0, 11, gold)
		patente_preview.draw_string(_font_tech, Vector2(12, 29), "LV %d" % Salvar.nivel_conta, HORIZONTAL_ALIGNMENT_LEFT, 38.0, 12, Color(1.0, 0.92, 0.42, 0.96))
		patente_preview.draw_string(_font_tech, Vector2(52, 29), patente_nome, HORIZONTAL_ALIGNMENT_LEFT, w - 64.0, 10, soft)
		var bar := Rect2(12, 36, w - 24.0, 5)
		patente_preview.draw_rect(bar, Color(0.20, 0.13, 0.02, 0.82), true)
		patente_preview.draw_rect(Rect2(bar.position, Vector2(bar.size.x * patente_prog, bar.size.y)), Color(1.0, 0.72, 0.12, 0.95), true)
		patente_preview.draw_rect(bar, Color(1.0, 0.82, 0.24, 0.62), false, 1.0)
	)
	btn_patente.add_child(patente_preview)


	var btn_aval_sm:= Button.new()
	btn_aval_sm.text = "AVALIAÇÃO"
	btn_aval_sm.position = Vector2(104, 660)
	btn_aval_sm.size = Vector2(162, 34)
	btn_aval_sm.focus_mode = Control.FOCUS_NONE
	btn_aval_sm.add_theme_font_size_override("font_size", 13)
	var sty_av:= StyleBoxFlat.new()
	sty_av.bg_color = Color(0.05, 0.15, 0.25, 0.9)
	sty_av.border_color = Color(0.2, 0.75, 1.0, 0.8)
	for s in ["left", "right", "top", "bottom"]: sty_av.set("border_width_" + s, 2)
	for c in ["top_left", "top_right", "bottom_left", "bottom_right"]: sty_av.set("corner_radius_" + c, 8)
	btn_aval_sm.add_theme_stylebox_override("normal", sty_av)
	btn_aval_sm.add_theme_color_override("font_color", Color(0.2, 0.85, 1.0))
	btn_aval_sm.pressed.connect( func(): _abrir_avaliacao(ui))
	mc.add_child(btn_aval_sm)
	_corrigir_textos_ui(mc)


func _criar_btn(texto: String, pos: Vector2, cor: Color, sz: Vector2 = Vector2(300, 60)) -> Button:
	var btn:= Button.new()
	btn.text = ""
	btn.position = pos
	btn.size = sz
	btn.focus_mode = Control.FOCUS_NONE
	btn.add_theme_font_size_override("font_size", 19)
	_ui_premium_button(btn, cor, false)

	var kind := "alcance"
	var sub := ""
	match texto:
		"JOGAR":
			kind = "jogar"; sub = "ENTRAR EM BATALHA"
		"LOJA":
			kind = "loja"; sub = "ADQUIRA RECURSOS"
		"INVENTÁRIO", "INVENT\u00c1RIO", "INVENTÃRIO", "INVENTÃƒÂRIO":
			kind = "inventario"; sub = "GERENCIE SEUS ITENS"
		"TECNOLOGIAS":
			kind = "talentos"; sub = "CENTRO TECNOLOGICO"
		"TALENTOS":
			kind = "talentos"; sub = "CENTRO TECNOLOGICO"
		"SAIR":
			kind = "sair"; sub = "ENCERRAR SESSAO"
		_:
			kind = "comandante"; sub = ""

	var icon := Control.new()
	icon.position = Vector2(10, 9)
	icon.size = Vector2(52, 52)
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon.draw.connect(func():
		_ui_draw_menu_icon(icon, kind, Vector2(26, 26), cor, 1.0)
	)
	btn.add_child(icon)

	var title := Label.new()
	title.text = texto
	title.position = Vector2(82, 11)
	title.size = Vector2(sz.x - 96, 26)
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	title.clip_text = true
	title.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	title.add_theme_font_size_override("font_size", 22)
	title.add_theme_color_override("font_color", Color(0.92, 0.94, 1.0, 0.96))
	_ui_tech_label(title, 2.0)
	btn.add_child(title)
	var desc := Label.new()
	desc.text = sub
	desc.position = Vector2(82, 39)
	desc.size = Vector2(sz.x - 96, 18)
	desc.mouse_filter = Control.MOUSE_FILTER_IGNORE
	desc.clip_text = true
	desc.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	desc.add_theme_font_size_override("font_size", 11)
	desc.add_theme_color_override("font_color", Color(minf(cor.r + 0.24, 1.0), minf(cor.g + 0.24, 1.0), minf(cor.b + 0.24, 1.0), 0.82))
	_ui_tech_label(desc, 1.0)
	btn.add_child(desc)
	var deco := Control.new()
	deco.size = sz
	deco.mouse_filter = Control.MOUSE_FILTER_IGNORE
	deco.draw.connect(func():
		var w := deco.size.x
		var h := deco.size.y
		var cut := 14.0
		var poly := PackedVector2Array([Vector2(cut, 0), Vector2(w - cut, 0), Vector2(w, cut), Vector2(w, h - cut), Vector2(w - cut, h), Vector2(cut, h), Vector2(0, h - cut), Vector2(0, cut), Vector2(cut, 0)])
		deco.draw_polyline(poly, Color(cor.r, cor.g, cor.b, 0.92), 1.8)
		deco.draw_line(Vector2(70, 8), Vector2(w - 22, 8), Color(cor.r, cor.g, cor.b, 0.22), 1.0)
		deco.draw_line(Vector2(70, h - 8), Vector2(w - 46, h - 8), Color(cor.r, cor.g, cor.b, 0.18), 1.0)
		deco.draw_rect(Rect2(0, 0, 72, h), Color(cor.r * 0.10, cor.g * 0.10, cor.b * 0.10, 0.36), true)
		deco.draw_line(Vector2(72, 10), Vector2(72, h - 10), Color(cor.r, cor.g, cor.b, 0.26), 1.0)
	)
	btn.add_child(deco)
	btn.move_child(deco, 0)

	return btn


func _menu_safe_margin_x() -> float:
	var margin := 36.0
	if OS.has_feature("android") or OS.has_feature("ios"):
		margin = 52.0
	var screen := DisplayServer.get_display_safe_area()
	if screen.size.x > 0.0:
		margin = maxf(margin, float(screen.position.x) + 20.0)
	return margin


func _criar_discord_reward_badge(parent: Control) -> Control:
	var badge := Control.new()
	badge.size = Vector2(58.0, 50.0)
	badge.position = Vector2(parent.size.x - badge.size.x + 2.0, -2.0)
	badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	badge.draw.connect(func():
		var center := badge.size * 0.5
		var chest_tex := _bau_sprite("lendario")
		if chest_tex != null:
			var chest_rect := Rect2(center.x - 25.0, center.y - 18.5, 50.0, 37.0)
			badge.draw_texture_rect(chest_tex, chest_rect, false, Color.WHITE)
		var dot_pos := Vector2(48.0, 8.0)
		badge.draw_circle(dot_pos, 5.0, Color(0.02, 0.04, 0.08, 0.96))
		badge.draw_circle(dot_pos, 3.8, Color(1.0, 0.18, 0.18, 0.96))
		badge.draw_line(dot_pos + Vector2(0.0, -2.0), dot_pos + Vector2(0.0, 0.8), Color.WHITE, 0.9)
		badge.draw_circle(dot_pos + Vector2(0.0, 2.6), 0.75, Color.WHITE)
	)
	parent.add_child(badge)
	return badge


func _atualizar_discord_reward_badge() -> void:
	if not (_discord_reward_badge and is_instance_valid(_discord_reward_badge)):
		return
	_discord_reward_badge.visible = _discord_reward_badge_visivel and Salvar.nome_jogador.strip_edges() != "" and not Salvar.discord_reward_claimed
	_discord_reward_badge.queue_redraw()


func _ocultar_discord_reward_badge() -> void:
	_discord_reward_badge_visivel = false
	if not Salvar.discord_reward_claimed:
		Salvar.discord_reward_claimed = true
		Salvar.salvar()
	_atualizar_discord_reward_badge()


func _mostrar_popup_cyron(titulo: String, corpo: String, linhas: Array, cor: Color = Color(0.18, 0.85, 1.0)) -> void:
	if _cyron_popup_overlay and is_instance_valid(_cyron_popup_overlay):
		_cyron_popup_overlay.queue_free()
	var vp := get_viewport().get_visible_rect().size
	var overlay := CanvasLayer.new()
	overlay.layer = 120
	add_child(overlay)
	_cyron_popup_overlay = overlay

	var shade := ColorRect.new()
	shade.color = Color(0.0, 0.0, 0.0, 0.68)
	shade.position = Vector2.ZERO
	shade.size = vp
	overlay.add_child(shade)

	var panel_w : float = minf(560.0, vp.x - 48.0)
	var panel_h : float = 286.0
	var panel := PanelContainer.new()
	panel.position = Vector2((vp.x - panel_w) * 0.5, (vp.y - panel_h) * 0.5)
	panel.size = Vector2(panel_w, panel_h)
	var sty := StyleBoxFlat.new()
	sty.bg_color = Color(0.035, 0.045, 0.075, 0.98)
	sty.border_color = Color(cor.r, cor.g, cor.b, 0.92)
	for side in ["left", "right", "top", "bottom"]:
		sty.set("border_width_" + side, 2)
	for corner in ["top_left", "top_right", "bottom_left", "bottom_right"]:
		sty.set("corner_radius_" + corner, 10)
	sty.shadow_color = Color(cor.r, cor.g, cor.b, 0.22)
	sty.shadow_size = 18
	panel.add_theme_stylebox_override("panel", sty)
	overlay.add_child(panel)

	var content := Control.new()
	content.custom_minimum_size = Vector2(panel_w, panel_h)
	panel.add_child(content)
	_ui_panel_frame(content, Rect2(8.0, 8.0, panel_w - 16.0, panel_h - 16.0), cor, 0.85)

	var icon := Control.new()
	icon.position = Vector2(28.0, 62.0)
	icon.size = Vector2(132.0, 132.0)
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon.draw.connect(func():
		var icon_center := Vector2(66.0, 68.0)
		icon.draw_circle(icon_center, 62.0, Color(cor.r, cor.g, cor.b, 0.08))
		icon.draw_arc(icon_center, 56.0, 0, TAU, 44, Color(1.0, 0.82, 0.12, 0.58), 2.0, true)
		_draw_bau_popup_icon(icon, icon_center)
	)
	content.add_child(icon)

	var title_lbl := Label.new()
	title_lbl.text = titulo
	title_lbl.position = Vector2(176.0, 38.0)
	title_lbl.size = Vector2(panel_w - 218.0, 42.0)
	title_lbl.add_theme_font_size_override("font_size", 23)
	title_lbl.add_theme_color_override("font_color", Color(0.95, 0.98, 1.0, 1.0))
	_ui_title_label(title_lbl, 3.0)
	content.add_child(title_lbl)

	var body_lbl := Label.new()
	body_lbl.text = corpo
	body_lbl.position = Vector2(178.0, 84.0)
	body_lbl.size = Vector2(panel_w - 220.0, 42.0)
	body_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body_lbl.add_theme_font_size_override("font_size", 14)
	body_lbl.add_theme_color_override("font_color", Color(0.72, 0.82, 0.94, 0.92))
	_ui_tech_label(body_lbl, 0.0)
	content.add_child(body_lbl)

	var y := 136.0
	for line in linhas:
		var row := Label.new()
		row.text = String(line)
		row.position = Vector2(178.0, y)
		row.size = Vector2(panel_w - 220.0, 24.0)
		row.add_theme_font_size_override("font_size", 15)
		row.add_theme_color_override("font_color", Color(1.0, 0.86, 0.22, 0.96))
		_ui_tech_label(row, 0.0)
		content.add_child(row)
		y += 25.0

	var btn := Button.new()
	btn.text = "COLETADO"
	btn.position = Vector2(panel_w - 182.0, panel_h - 62.0)
	btn.size = Vector2(142.0, 38.0)
	btn.focus_mode = Control.FOCUS_NONE
	btn.add_theme_font_size_override("font_size", 14)
	_ui_premium_button(btn, cor, true)
	btn.pressed.connect(func():
		if _cyron_popup_overlay and is_instance_valid(_cyron_popup_overlay):
			_cyron_popup_overlay.queue_free()
			_cyron_popup_overlay = null
	)
	content.add_child(btn)


func _mostrar_popup_premio_discord() -> void:
	_mostrar_popup_cyron(
		"PREMIO RECEBIDO",
		"Recompensas do Discord adicionadas na sua conta.",
		["+2 BAUS LENDARIOS", "+25 CRISTAIS", "+1 ORBE"],
		Color(0.22, 0.86, 1.0)
	)


func _mostrar_popup_discord_aviso(titulo: String, corpo: String) -> void:
	_mostrar_popup_cyron(titulo, corpo, [], Color(0.62, 0.36, 1.0))


func _configurar_discord_link() -> void:
	if not RankingOnline.discord_vinculo_concluido.is_connected(_on_discord_vinculo_concluido):
		RankingOnline.discord_vinculo_concluido.connect(_on_discord_vinculo_concluido)
	if not RankingOnline.discord_invite_pronto.is_connected(_on_discord_invite_pronto):
		RankingOnline.discord_invite_pronto.connect(_on_discord_invite_pronto)
	var code := _codigo_discord_dos_argumentos()
	if code != "":
		call_deferred("_confirmar_discord_link", code)


func _abrir_discord_com_premio() -> void:
	if Salvar.nome_jogador == "" or Salvar.senha_jogador == "":
		_mostrar_popup_discord_aviso("ACESSO NECESSARIO", "Entre na sua conta para receber o premio do Discord. Vou abrir o servidor mesmo assim.")
		OS.shell_open(DISCORD_CANAL_URL)
		return
	RankingOnline.solicitar_discord_invite()


func _codigo_discord_dos_argumentos() -> String:
	for arg in OS.get_cmdline_args():
		var txt := str(arg)
		if txt.begins_with("cyrondefense://"):
			var query := ""
			var qpos := txt.find("?")
			if qpos >= 0:
				query = txt.substr(qpos + 1)
			for part in query.split("&", false):
				var kv := (part as String).split("=", true, 1)
				if kv.size() == 2 and (kv[0] as String) == "code":
					return (kv[1] as String).uri_decode().strip_edges().to_upper()
	return ""


func _confirmar_discord_link(code: String) -> void:
	RankingOnline.confirmar_discord_link(code)


func _on_discord_vinculo_concluido(ok: bool, erro: String) -> void:
	if ok:
		_mostrar_popup_discord_aviso("DISCORD VINCULADO", "Conta conectada com sucesso ao servidor.")
	else:
		_mostrar_popup_discord_aviso("FALHA NO VINCULO", erro if erro != "" else "Nao foi possivel vincular o Discord.")


func _on_discord_invite_pronto(ok: bool, url: String, erro: String) -> void:
	if ok and url != "":
		OS.shell_open(url)
		_buscar_premio_discord_depois()
	else:
		var msg := erro if erro != "" else "Nao foi possivel preparar o premio agora."
		if msg.to_lower().find("ja resgatado") >= 0:
			_ocultar_discord_reward_badge()
		_mostrar_popup_discord_aviso("DISCORD", msg + "\nAbrindo o servidor mesmo assim.")
		OS.shell_open(DISCORD_CANAL_URL)


func _buscar_premio_discord_depois() -> void:
	if _discord_premio_poll_ativo:
		return
	_discord_premio_poll_ativo = true
	await get_tree().create_timer(4.0).timeout
	RankingOnline.confirmar_discord_invite_aberto()
	for _i in range(12):
		await get_tree().create_timer(5.0).timeout
		RankingOnline.buscar_premios_pendentes()
	_discord_premio_poll_ativo = false


func _mostrar_dialog_continuar_ou_novo(mc: Control) -> void:
	# Remove dialog anterior se existir
	var _old := mc.find_child("DialogContinuar", false, false)
	if _old and is_instance_valid(_old):
		_old.queue_free()

	var vp   : Vector2 = get_viewport().get_visible_rect().size
	var dw   : float   = 380.0
	var dh   : float   = 230.0
	var dlg  := ColorRect.new()
	dlg.name          = "DialogContinuar"
	dlg.color         = Color(0.04, 0.06, 0.12, 0.97)
	dlg.position      = Vector2((vp.x - dw) * 0.5, (vp.y - dh) * 0.5)
	dlg.size          = Vector2(dw, dh)
	dlg.mouse_filter  = Control.MOUSE_FILTER_STOP

	# Borda
	var brd := ReferenceRect.new()
	brd.border_color  = Color(0.28, 0.78, 1.0, 0.5)
	brd.border_width  = 2.0
	brd.editor_only   = false
	brd.size          = Vector2(dw, dh)
	brd.mouse_filter  = Control.MOUSE_FILTER_IGNORE
	dlg.add_child(brd)

	# Título
	var _cp_wave  : int = int(Salvar.run_checkpoint.get("wave",  0)) + 1
	var _cp_score : int = int(Salvar.run_checkpoint.get("score", 0))
	var tit_dlg   := Label.new()
	tit_dlg.text                 = "PARTIDA SALVA ENCONTRADA"
	tit_dlg.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tit_dlg.position             = Vector2(0, 20)
	tit_dlg.size                 = Vector2(dw, 26)
	tit_dlg.add_theme_font_size_override("font_size", 17)
	tit_dlg.add_theme_color_override("font_color", Color(0.6, 0.85, 1.0, 0.9))
	tit_dlg.mouse_filter         = Control.MOUSE_FILTER_IGNORE
	dlg.add_child(tit_dlg)

	var sub_dlg := Label.new()
	sub_dlg.text                 = "Wave %d  •  Score %s" % [_cp_wave, _format_num(_cp_score)]
	sub_dlg.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub_dlg.position             = Vector2(0, 48)
	sub_dlg.size                 = Vector2(dw, 22)
	sub_dlg.add_theme_font_size_override("font_size", 14)
	sub_dlg.add_theme_color_override("font_color", Color(0.75, 0.9, 0.65, 0.85))
	sub_dlg.mouse_filter         = Control.MOUSE_FILTER_IGNORE
	dlg.add_child(sub_dlg)

	# Botão CONTINUAR RUN
	var btn_cont := _criar_btn("▶  CONTINUAR RUN",
		Vector2(20, 84), Color(0.25, 1.0, 0.55), Vector2(dw - 40.0, 56.0))
	btn_cont.add_theme_font_size_override("font_size", 20)
	btn_cont.pressed.connect(func():
		dlg.queue_free()
		# Restaurar flags de modo do checkpoint antes de entrar
		var _cp_now := Salvar.run_checkpoint
		Salvar.abismo_modo_ativo = bool(_cp_now.get("modo_abismo", false))
		get_tree().change_scene_to_file("res://scenes/Main.tscn"))
	dlg.add_child(btn_cont)

	# Botão NOVA PARTIDA
	var btn_nova := _criar_btn("✦  NOVA PARTIDA",
		Vector2(20, 152), Color(0.3, 0.6, 1.0), Vector2(dw - 40.0, 56.0))
	btn_nova.add_theme_font_size_override("font_size", 20)
	btn_nova.pressed.connect(func():
		dlg.queue_free()
		Salvar.limpar_checkpoint()
		Acessibilidade.processar("menu_jogar",
			"Jogar. Inicia uma nova partida.", _jogar))
	dlg.add_child(btn_nova)

	mc.add_child(dlg)


func _jogar() -> void :
	Salvar.abismo_modo_ativo = false
	Salvar.dificuldade = 1
	Salvar.salvar()
	get_tree().change_scene_to_file("res://scenes/Main.tscn")


func _jogar_abismo() -> void :
	Salvar.abismo_modo_ativo = true
	get_tree().change_scene_to_file("res://scenes/Main.tscn")


func _bau_info(tier: String) -> Dictionary:
	match tier:
		"raro":
			return {"nome":"Bau Ionico", "sub":"Drop raro", "cor":Color(0.22,0.72,1.0), "luz":Color(0.40,0.95,1.0)}
		"epico":
			return {"nome":"Bau Nebular", "sub":"Drop epico", "cor":Color(0.78,0.25,1.0), "luz":Color(1.0,0.45,1.0)}
		"lendario":
			return {"nome":"Bau Estelar", "sub":"Drop lendario", "cor":Color(1.0,0.70,0.12), "luz":Color(1.0,0.92,0.35)}
		_:
			return {"nome":"Bau Basico", "sub":"Drop comum", "cor":Color(0.55,0.64,0.78), "luz":Color(0.72,0.92,1.0)}


func _bau_sprite(tier: String) -> Texture2D:
	var key := "bau_%s" % tier
	if _bau_sprite_cache.has(key):
		return _bau_sprite_cache[key] as Texture2D
	var path := BAU_SPRITE_BASE + key + ".png"
	var tex : Texture2D = null
	if ResourceLoader.exists(path):
		tex = load(path) as Texture2D
	_bau_sprite_cache[key] = tex
	return tex


func _bau_open_sprite(tier: String) -> Texture2D:
	var key := "bau_%s_open" % tier
	if _bau_sprite_cache.has(key):
		return _bau_sprite_cache[key] as Texture2D
	var path := BAU_SPRITE_BASE + key + ".png"
	var tex : Texture2D = null
	if ResourceLoader.exists(path):
		tex = load(path) as Texture2D
	_bau_sprite_cache[key] = tex
	return tex


func _item_sprite(key: String) -> Texture2D:
	if key == "":
		return null
	if _item_sprite_cache.has(key):
		return _item_sprite_cache[key] as Texture2D
	var path := ITEM_SPRITE_BASE + key + ".png"
	var tex : Texture2D = null
	if ResourceLoader.exists(path):
		tex = load(path) as Texture2D
	_item_sprite_cache[key] = tex
	return tex


func _comandante_asset_key(pid: String) -> String:
	var key := pid
	if key == "eclipse":
		key = "phantom"
	if key == "":
		key = "cyron"
	return key


func _comandante_desbloqueado(pid: String) -> bool:
	var raw := str(pid)
	var key := _comandante_asset_key(raw)
	if raw == "":
		return false
	if raw in Salvar.pets_desbloqueados or key in Salvar.pets_desbloqueados:
		return true
	return key == "cyron" and Salvar.pet_ia_comprado


func _comandante_home_visual_pid() -> String:
	var raw := str(Salvar.pet_ativo)
	if _comandante_desbloqueado(raw):
		return _comandante_asset_key(raw)
	return ""


func _comandante_fundo_key(pid: String) -> String:
	match _comandante_asset_key(pid):
		"phantom":
			return "eira_fundo"
		"nexus":
			return "dante_fundo"
		_:
			return "cyron_fundo"


func _comandante_sprite(pid: String) -> Texture2D:
	var key := _comandante_asset_key(pid)
	if _comandante_sprite_cache.has(key):
		return _comandante_sprite_cache[key] as Texture2D
	var path := COMANDANTE_SPRITE_BASE + key + ".png"
	var tex : Texture2D = null
	if ResourceLoader.exists(path):
		tex = load(path) as Texture2D
	_comandante_sprite_cache[key] = tex
	return tex


func _load_texture_file(path: String) -> Texture2D:
	if ResourceLoader.exists(path):
		var imported_tex := load(path) as Texture2D
		if imported_tex != null:
			return imported_tex
	if not FileAccess.file_exists(path):
		return null
	var img := Image.load_from_file(path)
	if img == null:
		var abs_path := ProjectSettings.globalize_path(path)
		if abs_path != path:
			img = Image.load_from_file(abs_path)
	if img == null or img.get_width() <= 0 or img.get_height() <= 0:
		return null
	return ImageTexture.create_from_image(img)


func _currency_texture(tipo: String) -> Texture2D:
	var key : String = "cristais" if tipo in ["cristais", "cristal", "crystal"] else "ouro"
	if _currency_texture_cache.has(key):
		return _currency_texture_cache[key] as Texture2D
	var path : String = UI_CRYSTAL_TEXTURE_PATH if key == "cristais" else UI_COIN_TEXTURE_PATH
	var tex := _load_texture_file(path)
	_currency_texture_cache[key] = tex
	return tex


func _format_currency_amount(value: int) -> String:
	return NumberFormatter.compact_int(value)


func _draw_currency_icon(c: Control, tipo: String, rect: Rect2, alpha: float = 1.0) -> bool:
	var tex := _currency_texture(tipo)
	if tex != null:
		_draw_texture_contain(c, tex, rect, alpha)
		return true
	var is_crystal : bool = tipo in ["cristais", "cristal", "crystal"]
	var col : Color = Color(0.35, 0.9, 1.0, alpha) if is_crystal else Color(1.0, 0.76, 0.12, alpha)
	var center : Vector2 = rect.position + rect.size * 0.5
	var r : float = minf(rect.size.x, rect.size.y) * 0.42
	if is_crystal:
		var pts := PackedVector2Array([
			center + Vector2(0.0, -r),
			center + Vector2(r * 0.62, -r * 0.10),
			center + Vector2(r * 0.34, r * 0.80),
			center + Vector2(-r * 0.34, r * 0.80),
			center + Vector2(-r * 0.62, -r * 0.10),
		])
		var fill := Color(col.r * 0.12, col.g * 0.12, col.b * 0.18, alpha * 0.95)
		c.draw_polygon(pts, PackedColorArray([fill, fill, fill, fill, fill]))
		pts.append(pts[0])
		c.draw_polyline(pts, col, 2.0, true)
	else:
		c.draw_circle(center, r, Color(col.r * 0.22, col.g * 0.16, 0.02, alpha * 0.95))
		c.draw_arc(center, r, 0.0, TAU, 64, col, 2.2, true)
		c.draw_circle(center, r * 0.35, Color(col.r, col.g, col.b, alpha * 0.72))
	return true


func _draw_currency_pill(c: Control, rect: Rect2, tipo: String, amount: int, accent: Color) -> void:
	var cut : float = minf(10.0, rect.size.y * 0.30)
	var p0 : Vector2 = rect.position
	var p1 : Vector2 = rect.end
	var shape := PackedVector2Array([
		p0 + Vector2(cut, 0.0),
		Vector2(p1.x, p0.y),
		Vector2(p1.x, p1.y - cut),
		Vector2(p1.x - cut, p1.y),
		Vector2(p0.x, p1.y),
		Vector2(p0.x, p0.y + cut),
	])
	var fill := Color(0.018, 0.028, 0.046, 0.88)
	c.draw_polygon(shape, PackedColorArray([fill, fill, fill, fill, fill, fill]))
	for gi in range(3, 0, -1):
		c.draw_polyline(PackedVector2Array([shape[0], shape[1], shape[2], shape[3], shape[4], shape[5], shape[0]]),
			Color(accent.r, accent.g, accent.b, 0.08 * float(gi)), float(gi) * 2.0, true)
	c.draw_polyline(PackedVector2Array([shape[0], shape[1], shape[2], shape[3], shape[4], shape[5], shape[0]]),
		Color(accent.r, accent.g, accent.b, 0.78), 1.2, true)
	c.draw_line(p0 + Vector2(cut + 8.0, rect.size.y - 4.0), p0 + Vector2(rect.size.x - cut - 10.0, rect.size.y - 4.0),
		Color(accent.r, accent.g, accent.b, 0.22), 1.0)
	var icon_rect := Rect2(rect.position + Vector2(3.0, -3.0), Vector2(rect.size.y + 6.0, rect.size.y + 6.0))
	_draw_currency_icon(c, tipo, icon_rect, 1.0)
	c.draw_string(_font_tech, Vector2(rect.position.x + rect.size.y + 13.0, rect.position.y + rect.size.y * 0.66),
		_format_currency_amount(amount), HORIZONTAL_ALIGNMENT_LEFT, rect.size.x - rect.size.y - 16.0, 16, Color(0.94, 0.97, 1.0, 0.98))


func _add_currency_status(parent: Node, pos: Vector2, compact: bool = false, z: int = 80) -> Control:
	var w : float = 236.0 if compact else 276.0
	var h : float = 38.0
	var hud := Control.new()
	hud.name = "CurrencyStatus"
	hud.position = pos
	hud.size = Vector2(w, h)
	hud.z_index = z
	hud.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(hud)
	hud.draw.connect(func():
		var gap : float = 8.0
		var pill_w : float = (w - gap) * 0.5
		_draw_currency_pill(hud, Rect2(0.0, 0.0, pill_w, h), "ouro", Salvar.ouro_banco, Color(1.0, 0.72, 0.10))
		_draw_currency_pill(hud, Rect2(pill_w + gap, 0.0, pill_w, h), "cristais", Salvar.cristais, Color(0.42, 0.90, 1.0))
	)
	_add_currency_hint_hitbox(hud, Rect2(0.0, 0.0, (w - 8.0) * 0.5, h), "MOEDA CYTRON", "Usada na loja e em melhorias permanentes.", Color(1.0, 0.72, 0.10))
	_add_currency_hint_hitbox(hud, Rect2(((w - 8.0) * 0.5) + 8.0, 0.0, (w - 8.0) * 0.5, h), "CRISTAIS", "Usados em talentos, cargas e recompensas.", Color(0.42, 0.90, 1.0))
	return hud


func _add_currency_hint_hitbox(parent: Control, rect: Rect2, titulo: String, desc: String, accent: Color) -> void:
	var hit := Control.new()
	hit.position = rect.position
	hit.size = rect.size
	hit.mouse_filter = Control.MOUSE_FILTER_STOP
	hit.mouse_entered.connect(func(): _mostrar_menu_hint(hit, titulo, desc, accent))
	hit.mouse_exited.connect(_ocultar_menu_hint)
	hit.gui_input.connect(func(event: InputEvent):
		if event is InputEventMouseButton:
			var mb := event as InputEventMouseButton
			if mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT:
				_mostrar_menu_hint(hit, titulo, desc, accent, true)
		elif event is InputEventScreenTouch:
			var touch := event as InputEventScreenTouch
			if touch.pressed:
				_mostrar_menu_hint(hit, titulo, desc, accent, true)
	)
	parent.add_child(hit)


func _mostrar_menu_hint(target: Control, titulo: String, desc: String, accent: Color, auto_hide: bool = false) -> void:
	if not _menu_contents or not is_instance_valid(_menu_contents):
		return
	_menu_hint_seq += 1
	var seq := _menu_hint_seq
	if _menu_hint_popup and is_instance_valid(_menu_hint_popup):
		_menu_hint_popup.queue_free()
	var rect := target.get_global_rect()
	var vp := get_viewport().get_visible_rect().size
	var panel_w : float = minf(310.0, maxf(220.0, vp.x - 16.0))
	var panel_h : float = 88.0
	var pos := Vector2(rect.position.x + rect.size.x * 0.5 - panel_w * 0.5, rect.position.y + rect.size.y + 8.0)
	pos.x = clampf(pos.x, 8.0, maxf(8.0, vp.x - panel_w - 8.0))
	if pos.y + panel_h > vp.y - 12.0:
		pos.y = rect.position.y - panel_h - 8.0
	var popup := Control.new()
	popup.position = pos
	popup.size = Vector2(panel_w, panel_h)
	popup.z_index = 500
	popup.mouse_filter = Control.MOUSE_FILTER_IGNORE
	popup.draw.connect(func():
		var r := Rect2(Vector2.ZERO, popup.size)
		popup.draw_rect(r, Color(0.02, 0.03, 0.052, 0.96), true)
		popup.draw_rect(r, Color(accent.r, accent.g, accent.b, 0.84), false, 1.6)
		popup.draw_line(Vector2(12.0, 38.0), Vector2(panel_w - 12.0, 38.0), Color(accent.r, accent.g, accent.b, 0.22), 1.0)
		var pointer_x := clampf(rect.position.x + rect.size.x * 0.5 - pos.x, 18.0, panel_w - 18.0)
		var top_pointer := pos.y > rect.position.y
		var y0 := 0.0 if top_pointer else panel_h
		var dir := -1.0 if top_pointer else 1.0
		var tri := PackedVector2Array([
			Vector2(pointer_x - 7.0, y0),
			Vector2(pointer_x + 7.0, y0),
			Vector2(pointer_x, y0 + 7.0 * dir)
		])
		popup.draw_colored_polygon(tri, Color(accent.r, accent.g, accent.b, 0.84))
	)
	_menu_contents.add_child(popup)
	_menu_hint_popup = popup

	var title_lbl := Label.new()
	title_lbl.text = titulo
	title_lbl.position = Vector2(14.0, 8.0)
	title_lbl.size = Vector2(panel_w - 28.0, 24.0)
	title_lbl.add_theme_font_size_override("font_size", 14)
	title_lbl.add_theme_color_override("font_color", Color(accent.r, accent.g, accent.b, 0.98))
	_ui_tech_label(title_lbl, 0.0)
	popup.add_child(title_lbl)

	var desc_lbl := Label.new()
	desc_lbl.text = desc
	desc_lbl.position = Vector2(14.0, 39.0)
	desc_lbl.size = Vector2(panel_w - 28.0, 40.0)
	desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc_lbl.clip_text = true
	desc_lbl.text_overrun_behavior = TextServer.OVERRUN_TRIM_WORD_ELLIPSIS
	desc_lbl.add_theme_font_size_override("font_size", 10)
	desc_lbl.add_theme_color_override("font_color", Color(0.80, 0.88, 0.98, 0.92))
	_ui_tech_label(desc_lbl, 0.0)
	popup.add_child(desc_lbl)
	if auto_hide:
		await get_tree().create_timer(2.4).timeout
		if seq == _menu_hint_seq and _menu_hint_popup and is_instance_valid(_menu_hint_popup):
			_menu_hint_popup.queue_free()
			_menu_hint_popup = null


func _ocultar_menu_hint() -> void:
	_menu_hint_seq += 1
	if _menu_hint_popup and is_instance_valid(_menu_hint_popup):
		_menu_hint_popup.queue_free()
	_menu_hint_popup = null


func _comandante_menu_bg(pid: String) -> Texture2D:
	var key := _comandante_asset_key(pid)
	var bg_key := _comandante_fundo_key(pid)
	if _comandante_bg_cache.has(bg_key):
		return _comandante_bg_cache[bg_key] as Texture2D
	var tex : Texture2D = null
	var nomes := [
		bg_key,
		key + "_fundo",
		key + "_full",
		key
	]
	var exts := [".png", ".jpg", ".jpeg", ".webp"]
	for nome in nomes:
		for ext in exts:
			var path : String = COMANDANTE_MENU_BG_BASE + str(nome) + str(ext)
			tex = _load_texture_file(path)
			if tex != null:
				break
		if tex != null:
			break
	_comandante_bg_cache[bg_key] = tex
	return tex


func _mapa_fundo_texture(mapa: Dictionary) -> Texture2D:
	var path := str(mapa.get("bg", ""))
	if path == "":
		return null
	if _mapa_bg_cache.has(path):
		return _mapa_bg_cache[path] as Texture2D
	var tex := _load_texture_file(path)
	_mapa_bg_cache[path] = tex
	return tex


func _draw_menu_mapa_fundo(c: Control, rect: Rect2, mapa_override: Dictionary = {}) -> void:
	var info : Dictionary = mapa_override if not mapa_override.is_empty() else Salvar.mapa_teste_info()
	var id : String = str(info.get("id", "setor_inicial"))
	var cor : Color = info.get("cor", Color(0.0, 0.72, 1.0)) as Color
	var tex := _mapa_fundo_texture(info)
	if tex != null:
		_draw_texture_cover(c, tex, rect, 1.0)
		return
	if id == "setor_inicial":
		_draw_menu_setor_inicial(c, rect)
		return
	var bg_top := Color(0.010 + cor.r * 0.050, 0.012 + cor.g * 0.040, 0.030 + cor.b * 0.080, 1.0)
	var bg_bot := Color(0.004 + cor.r * 0.025, 0.004 + cor.g * 0.020, 0.012 + cor.b * 0.045, 1.0)
	c.draw_rect(rect, bg_bot, true)
	for i in range(9):
		var y : float = rect.position.y + float(i) * rect.size.y / 9.0
		var t : float = float(i) / 8.0
		var band := bg_top.lerp(bg_bot, t)
		c.draw_rect(Rect2(rect.position.x, y, rect.size.x, rect.size.y / 9.0 + 2.0), band, true)

	_draw_menu_estrelas(c, rect, id, cor)
	match id:
		"nebulosa_fraturada":
			_draw_menu_nebulosa(c, rect, Vector2(0.66, 0.26), 620.0, Color(0.75, 0.18, 1.0, 0.24), Color(0.0, 0.85, 1.0, 0.12))
			_draw_menu_planeta(c, rect, Vector2(0.80, 0.22), 155.0, Color(0.32, 0.05, 0.48), Color(0.95, 0.22, 1.0), 0.78)
			_draw_menu_planeta(c, rect, Vector2(0.14, 0.82), 62.0, Color(0.03, 0.18, 0.24), Color(0.0, 0.95, 1.0), 0.48)
		"orbita_glacial":
			_draw_menu_nebulosa(c, rect, Vector2(0.27, 0.25), 560.0, Color(0.25, 0.80, 1.0, 0.22), Color(0.8, 1.0, 1.0, 0.11))
			_draw_menu_planeta(c, rect, Vector2(0.79, 0.75), 180.0, Color(0.07, 0.22, 0.34), Color(0.55, 0.90, 1.0), 0.82)
			_draw_menu_anel_planeta(c, rect, Vector2(0.79, 0.75), 240.0, Color(0.72, 0.95, 1.0, 0.38))
		"nucleo_abissal":
			_draw_menu_nebulosa(c, rect, Vector2(0.50, 0.50), 720.0, Color(0.78, 0.04, 0.22, 0.22), Color(0.45, 0.0, 0.75, 0.16))
			_draw_menu_planeta(c, rect, Vector2(0.14, 0.19), 128.0, Color(0.18, 0.02, 0.06), Color(1.0, 0.12, 0.35), 0.78)
			_draw_menu_planeta(c, rect, Vector2(0.88, 0.36), 82.0, Color(0.14, 0.02, 0.20), Color(0.8, 0.1, 1.0), 0.52)
		"coroa_void":
			_draw_menu_nebulosa(c, rect, Vector2(0.53, 0.32), 740.0, Color(1.0, 0.66, 0.08, 0.20), Color(0.45, 0.15, 1.0, 0.16))
			_draw_menu_planeta(c, rect, Vector2(0.76, 0.21), 190.0, Color(0.26, 0.18, 0.03), Color(1.0, 0.80, 0.16), 0.86)
			_draw_menu_anel_planeta(c, rect, Vector2(0.76, 0.21), 270.0, Color(1.0, 0.78, 0.22, 0.42))
		_:
			_draw_menu_nebulosa(c, rect, Vector2(0.59, 0.24), 540.0, Color(0.0, 0.55, 1.0, 0.18), Color(0.0, 1.0, 0.78, 0.10))
			_draw_menu_planeta(c, rect, Vector2(0.84, 0.22), 142.0, Color(0.04, 0.13, 0.25), Color(0.0, 0.75, 1.0), 0.70)
			_draw_menu_planeta(c, rect, Vector2(0.14, 0.72), 72.0, Color(0.04, 0.18, 0.12), Color(0.0, 1.0, 0.72), 0.42)


func _draw_menu_setor_inicial(c: Control, rect: Rect2) -> void:
	c.draw_rect(rect, Color(0.0, 0.0, 0.0, 1.0), true)
	var rng := RandomNumberGenerator.new()
	rng.seed = 42
	for i in range(210):
		var p := Vector2(
			rng.randf_range(rect.position.x, rect.position.x + rect.size.x),
			rng.randf_range(rect.position.y, rect.position.y + rect.size.y)
		)
		var s : float = rng.randf_range(0.45, 1.20)
		var a : float = rng.randf_range(0.08, 0.42)
		if i % 13 == 0:
			s = rng.randf_range(1.1, 1.8)
			a = rng.randf_range(0.22, 0.55)
		c.draw_circle(p, s * 0.5, Color(0.75, 0.86, 1.0, a))


func _draw_menu_estrelas(c: Control, rect: Rect2, seed_id: String, cor: Color) -> void:
	var base : int = abs(hash(seed_id))
	for i in range(95):
		var x : float = rect.position.x + float((base + i * 173) % maxi(1, int(rect.size.x)))
		var y : float = rect.position.y + float((base / 7 + i * 97) % maxi(1, int(rect.size.y)))
		var s : float = 0.7 + float((base + i * 19) % 9) * 0.12
		var a : float = 0.16 + float((base + i * 31) % 10) * 0.025
		c.draw_circle(Vector2(x, y), s, Color(0.75 + cor.r * 0.25, 0.82 + cor.g * 0.18, 1.0, a))


func _draw_menu_nebulosa(c: Control, rect: Rect2, rel_pos: Vector2, raio: float, c1: Color, c2: Color) -> void:
	var pos := rect.position + Vector2(rect.size.x * rel_pos.x, rect.size.y * rel_pos.y)
	var scale := rect.size.y / 720.0
	for i in range(8, 0, -1):
		var t : float = float(i) / 8.0
		var off := Vector2(sin(float(i)) * 38.0, cos(float(i) * 1.7) * 24.0) * scale
		c.draw_circle(pos + off, raio * scale * t, Color(c1.r, c1.g, c1.b, c1.a * t * 0.85))
	for i in range(5, 0, -1):
		var t : float = float(i) / 5.0
		var off2 := Vector2(-90.0 + float(i) * 36.0, 46.0 - float(i) * 18.0) * scale
		c.draw_circle(pos + off2, raio * scale * 0.42 * t, Color(c2.r, c2.g, c2.b, c2.a * t * 1.25))


func _draw_menu_planeta(c: Control, rect: Rect2, rel_pos: Vector2, raio: float, base: Color, luz: Color, alpha: float) -> void:
	var scale := rect.size.y / 720.0
	var pos := rect.position + Vector2(rect.size.x * rel_pos.x, rect.size.y * rel_pos.y)
	var rr := raio * scale
	for i in range(7, 0, -1):
		var t : float = float(i) / 7.0
		c.draw_circle(pos, rr * t, Color(base.r + luz.r * 0.10 * (1.0 - t), base.g + luz.g * 0.10 * (1.0 - t), base.b + luz.b * 0.10 * (1.0 - t), alpha * t))
	c.draw_circle(pos + Vector2(-rr * 0.28, -rr * 0.22), rr * 0.48, Color(luz.r, luz.g, luz.b, alpha * 0.22))
	c.draw_arc(pos, rr + 2.0, 0.0, TAU, 64, Color(luz.r, luz.g, luz.b, alpha * 0.55), 1.6)


func _draw_menu_anel_planeta(c: Control, rect: Rect2, rel_pos: Vector2, raio: float, cor: Color) -> void:
	var scale := rect.size.y / 720.0
	var pos := rect.position + Vector2(rect.size.x * rel_pos.x, rect.size.y * rel_pos.y)
	var pts := PackedVector2Array()
	for i in range(90):
		var a := float(i) / 89.0 * TAU
		pts.append(pos + Vector2(cos(a) * raio * scale, sin(a) * raio * scale * 0.22).rotated(-0.28))
	if pts.size() > 1:
		c.draw_polyline(pts, cor, 1.5)


func _draw_texture_cover(c: Control, tex: Texture2D, rect: Rect2, alpha: float = 1.0) -> void:
	if tex == null:
		return
	var tw := float(tex.get_width())
	var th := float(tex.get_height())
	if tw <= 0.0 or th <= 0.0 or rect.size.x <= 0.0 or rect.size.y <= 0.0:
		return
	var target_ratio := rect.size.x / rect.size.y
	var src_ratio := tw / th
	var src := Rect2(0.0, 0.0, tw, th)
	if src_ratio > target_ratio:
		var new_w := th * target_ratio
		src.position.x = (tw - new_w) * 0.5
		src.size.x = new_w
	else:
		var new_h := tw / target_ratio
		src.position.y = (th - new_h) * 0.5
		src.size.y = new_h
	c.draw_texture_rect_region(tex, rect, src, Color(1, 1, 1, alpha))


func _draw_texture_contain(c: Control, tex: Texture2D, rect: Rect2, alpha: float = 1.0) -> Rect2:
	if tex == null:
		return Rect2()
	var tw := float(tex.get_width())
	var th := float(tex.get_height())
	if tw <= 0.0 or th <= 0.0 or rect.size.x <= 0.0 or rect.size.y <= 0.0:
		return Rect2()
	var scale := minf(rect.size.x / tw, rect.size.y / th)
	var dst_size := Vector2(tw * scale, th * scale)
	var dst := Rect2(rect.position + (rect.size - dst_size) * 0.5, dst_size)
	c.draw_texture_rect(tex, dst, false, Color(1, 1, 1, alpha))
	return dst


func _texture_cover_source_rect(tex: Texture2D, rect: Rect2, src: Rect2, focus_y: float = 0.5) -> Rect2:
	if tex == null:
		return Rect2()
	var source := Rect2(src.position, src.size)
	if source.size.x <= 0.0 or source.size.y <= 0.0:
		source = Rect2(0.0, 0.0, float(tex.get_width()), float(tex.get_height()))
	if source.size.x <= 0.0 or source.size.y <= 0.0 or rect.size.x <= 0.0 or rect.size.y <= 0.0:
		return Rect2()
	var target_ratio := rect.size.x / rect.size.y
	var src_ratio := source.size.x / source.size.y
	if src_ratio > target_ratio:
		var new_w := source.size.y * target_ratio
		source.position.x += (source.size.x - new_w) * 0.5
		source.size.x = new_w
	else:
		var new_h := source.size.x / target_ratio
		source.position.y += (source.size.y - new_h) * clampf(focus_y, 0.0, 1.0)
		source.size.y = new_h
	return source


func _draw_texture_cover_region(c: Control, tex: Texture2D, rect: Rect2, src: Rect2, alpha: float = 1.0, focus_y: float = 0.5) -> void:
	var source := _texture_cover_source_rect(tex, rect, src, focus_y)
	if source.size.x <= 0.0 or source.size.y <= 0.0:
		return
	c.draw_texture_rect_region(tex, rect, source, Color(1, 1, 1, alpha))


func _draw_texture_cover_chamfered(c: Control, tex: Texture2D, rect: Rect2, src: Rect2, cut_x: float, cut_y: float, alpha: float = 1.0, focus_y: float = 0.5) -> void:
	var source := _texture_cover_source_rect(tex, rect, src, focus_y)
	if source.size.x <= 0.0 or source.size.y <= 0.0:
		return
	var tex_size : Vector2 = Vector2(float(tex.get_width()), float(tex.get_height()))
	if tex_size.x <= 0.0 or tex_size.y <= 0.0:
		return
	var cx : float = clampf(cut_x, 0.0, rect.size.x * 0.45)
	var cy : float = clampf(cut_y, 0.0, rect.size.y * 0.45)
	var p0 : Vector2 = rect.position
	var p1 : Vector2 = rect.end
	var pts := PackedVector2Array([
		p0 + Vector2(cx, 0.0),
		Vector2(p1.x - cx, p0.y),
		Vector2(p1.x, p0.y + cy),
		Vector2(p1.x, p1.y - cy),
		Vector2(p1.x - cx, p1.y),
		Vector2(p0.x + cx, p1.y),
		Vector2(p0.x, p1.y - cy),
		Vector2(p0.x, p0.y + cy),
	])
	var uvs := PackedVector2Array()
	for p in pts:
		var rel : Vector2 = (p - rect.position) / rect.size
		var tex_uv : Vector2 = source.position + Vector2(source.size.x * rel.x, source.size.y * rel.y)
		uvs.append(Vector2(tex_uv.x / tex_size.x, tex_uv.y / tex_size.y))
	var cols := PackedColorArray()
	for _i in range(pts.size()):
		cols.append(Color(1.0, 1.0, 1.0, alpha))
	c.draw_polygon(pts, cols, uvs, tex)


func _draw_texture_contain_region(c: Control, tex: Texture2D, rect: Rect2, src: Rect2, alpha: float = 1.0) -> Rect2:
	if tex == null:
		return Rect2()
	var source := Rect2(src.position, src.size)
	if source.size.x <= 0.0 or source.size.y <= 0.0:
		source = Rect2(0.0, 0.0, float(tex.get_width()), float(tex.get_height()))
	if source.size.x <= 0.0 or source.size.y <= 0.0 or rect.size.x <= 0.0 or rect.size.y <= 0.0:
		return Rect2()
	var scale := minf(rect.size.x / source.size.x, rect.size.y / source.size.y)
	var dst_size := Vector2(source.size.x * scale, source.size.y * scale)
	var dst := Rect2(rect.position + (rect.size - dst_size) * 0.5, dst_size)
	c.draw_texture_rect_region(tex, dst, source, Color(1, 1, 1, alpha))
	return dst


func _comandante_card_source_rect(tex: Texture2D) -> Rect2:
	if tex == null:
		return Rect2()
	var tw := float(tex.get_width())
	var th := float(tex.get_height())
	if tw <= 0.0 or th <= 0.0:
		return Rect2()
	var crop_left := minf(32.0, maxf(16.0, round(tw * 0.045)))
	var crop_right := minf(28.0, maxf(12.0, round(tw * 0.035)))
	if crop_left + crop_right >= tw * 0.35:
		crop_left = 0.0
		crop_right = 0.0
	return Rect2(crop_left, 0.0, tw - crop_left - crop_right, th)


func _reward_commander_portrait_rect(card_rect: Rect2) -> Rect2:
	var inset_x : float = maxf(8.0, card_rect.size.x * 0.052)
	var inset_y : float = maxf(8.0, card_rect.size.y * 0.032)
	return Rect2(card_rect.position + Vector2(inset_x, inset_y),
		card_rect.size - Vector2(inset_x * 2.0, inset_y * 2.0))


func _draw_comandante_card_art(c: Control, tex: Texture2D, rect: Rect2, escura: Color, pulse_alpha: float) -> Rect2:
	var src := _comandante_card_source_rect(tex)
	if src.size.x <= 0.0 or src.size.y <= 0.0:
		return Rect2()
	_draw_texture_cover_region(c, tex, rect, src, 1.0, 0.24)
	c.draw_rect(rect, Color(escura.r, escura.g, escura.b, pulse_alpha), true)
	return rect


func _comandante_face_source_rect(tex: Texture2D, pid: String) -> Rect2:
	if tex == null:
		return Rect2()
	var tw := float(tex.get_width())
	var th := float(tex.get_height())
	if tw <= 0.0 or th <= 0.0:
		return Rect2()
	var key := _comandante_asset_key(pid)
	var focus := Vector2(0.52, 0.32)
	match key:
		"nexus":
			focus = Vector2(0.62, 0.285)
		"phantom":
			focus = Vector2(0.39, 0.305)
		_:
			focus = Vector2(0.53, 0.325)
	var size := minf(tw * 0.60, th * 0.30)
	var pos := Vector2(focus.x * tw - size * 0.5, focus.y * th - size * 0.5)
	pos.x = clampf(pos.x, 0.0, tw - size)
	pos.y = clampf(pos.y, 0.0, th - size)
	return Rect2(pos, Vector2(size, size))


func _draw_comandante_face(c: Control, pid: String, rect: Rect2, alpha: float = 1.0) -> bool:
	var tex := _comandante_sprite(pid)
	if tex == null:
		return false
	var src := _comandante_face_source_rect(tex, pid)
	if src.size.x <= 0.0 or src.size.y <= 0.0:
		return false
	var meta := _comandante_meta(pid)
	var cor : Color = meta.get("cor", Color(0.25, 0.75, 1.0)) as Color
	var frame := StyleBoxFlat.new()
	frame.bg_color = Color(cor.r * 0.08, cor.g * 0.08, cor.b * 0.08, 0.88 * alpha)
	frame.border_color = Color(cor.r + 0.12, cor.g + 0.12, cor.b + 0.12, 0.78 * alpha)
	frame.set_border_width_all(2)
	frame.set_corner_radius_all(8)
	c.draw_style_box(frame, rect)
	var inner := rect.grow(-3.0)
	if inner.size.x <= 0.0 or inner.size.y <= 0.0:
		return true
	_draw_texture_cover_region(c, tex, inner, src, alpha)
	c.draw_rect(inner, Color(0.0, 0.0, 0.0, 0.16 * alpha), true)
	var shine := StyleBoxFlat.new()
	shine.bg_color = Color(0.0, 0.0, 0.0, 0.0)
	shine.border_color = Color(1.0, 1.0, 1.0, 0.10 * alpha)
	shine.set_border_width_all(1)
	shine.set_corner_radius_all(6)
	c.draw_style_box(shine, inner)
	return true


func _comandante_face_slot_rect(slot_size: float) -> Rect2:
	var pad_x : float = maxf(6.0, slot_size * 0.09)
	var top : float = maxf(6.0, slot_size * 0.08)
	var bottom : float = maxf(18.0, slot_size * 0.24)
	return Rect2(pad_x, top, maxf(1.0, slot_size - pad_x * 2.0), maxf(1.0, slot_size - top - bottom))


func _sprite_search_text(txt: String) -> String:
	var s := _texto_ui_limpo(txt).to_lower()
	var repl := {
		"á": "a", "à": "a", "â": "a", "ã": "a",
		"é": "e", "ê": "e",
		"í": "i",
		"ó": "o", "ô": "o", "õ": "o",
		"ú": "u",
		"ç": "c",
	}
	for k in repl.keys():
		s = s.replace(str(k), str(repl[k]))
	return s


func _item_sprite_key(tipo: String, nome: String = "", id: String = "") -> String:
	match tipo:
		"arsenal":
			return id
		"hab", "habil":
			match id:
				"eletrico":
					return "pulso_eletrico"
				"gelo":
					return "bomba_de_gelo"
				"devastador":
					return "pulso_final"
		"cons":
			match id:
				"revive", "vela":
					return "vela_da_alma"
				"orbe":
					return "orbe_de_cura"
				"cristal", "barreira":
					return "cristal_barreira"
				"runa":
					return "runa_de_furia"
		"pet_card":
			if id == "phantom" or "Phantom" in nome or "Hacker" in nome:
				return "carta_hacker_si"
			if id == "nexus" or "Nexus" in nome or "Dante" in nome:
				return "carta_nexus"
			if id == "cyron" or "Cyron" in nome:
				return "carta_cyron"
		"pet":
			if id == "phantom" or id == "hacker" or id == "hacker_si" or "Phantom" in nome or "Hacker" in nome:
				return "assistente_phantom"
			if id == "nexus" or "Nexus" in nome or "Dante" in nome:
				return "assistente_dante"
			if id == "cyron" or "Cyron" in nome:
				return "assistente_cyron"
	var low := _sprite_search_text(nome)
	if "vela" in low:
		return "vela_da_alma"
	if "orbe de cura" in low:
		return "orbe_de_cura"
	if "cristal" in low or "barreira" in low:
		return "cristal_barreira"
	if "runa" in low:
		return "runa_de_furia"
	if "pulso eletr" in low or "pulso el" in low:
		return "pulso_eletrico"
	if "gelo" in low:
		return "bomba_de_gelo"
	if "pulso final" in low:
		return "pulso_final"
	if "canhao de plasma" in low:
		return "canhao_plasma"
	if "campo defletor" in low:
		return "campo_defletor"
	if "bateria" in low and "cristal" in low:
		return "bateria_cristal"
	if "fragmento lunar" in low:
		return "fragmento_lunar"
	if "coracao estelar" in low:
		return "coracao_estelar"
	if "lente orbital" in low:
		return "lente_orbital"
	return ""


func _item_sprite_key_from_item(item: Dictionary) -> String:
	var tipo := str(item.get("tipo", ""))
	var nome := str(item.get("nome", ""))
	match tipo:
		"arsenal":
			return _item_sprite_key(tipo, nome, str(item.get("arsenal_id", "")))
		"hab":
			return _item_sprite_key(tipo, nome, str(item.get("hid", "")))
		"habil":
			return _item_sprite_key(tipo, nome, str(item.get("hid", "")))
		"cons":
			return _item_sprite_key(tipo, nome, str(item.get("cons_id", "")))
		"pet_card":
			return _item_sprite_key(tipo, nome, str(item.get("pid", "")))
		"pet":
			return _item_sprite_key(tipo, nome, str(item.get("pid", "")))
	return ""


func _usar_sprite_item_na_mochila(item: Dictionary) -> bool:
	var tipo := str(item.get("tipo", ""))
	if tipo == "pet" or tipo == "pet_card":
		return true
	return _usar_sprite_key_na_mochila(_item_sprite_key_from_item(item))


func _debug_preview_ativo() -> bool:
	return DEBUG_MOCHILA_MOSTRAR_TODOS_ITENS and OS.is_debug_build()


func _debug_liberar_preview_item(item: Dictionary) -> Dictionary:
	if not bool(item.get("preview", false)) or not _debug_preview_ativo():
		return item
	var out : Dictionary = item.duplicate(true)
	out["preview"] = false
	var tipo : String = str(out.get("tipo", ""))
	match tipo:
		"bau":
			var tier : String = str(out.get("bau_id", "comum"))
			if not Salvar.baus_estoque.has(tier):
				return {}
			Salvar.baus_estoque[tier] = int(Salvar.baus_estoque.get(tier, 0)) + 1
			out["qtd"] = 1
			var binfo := _bau_info(tier)
			out["nome"] = "%s x1" % str(binfo.get("nome", "Bau"))
			Salvar.salvar()
		"arsenal":
			var aid : String = str(out.get("arsenal_id", ""))
			if aid == "" or not Salvar.ARSENAL_INFO.has(aid):
				return {}
			if not (aid in Salvar.arsenal_itens_desbloqueados):
				Salvar.ganhar_item_arsenal(aid)
			else:
				Salvar.normalizar_arsenal()
				Salvar.salvar()
		"skin":
			var sid : String = str(out.get("sid", ""))
			if sid == "" or not Salvar.SKINS_INFO.has(sid):
				return {}
			if not (sid in Salvar.skins_desbloqueadas):
				Salvar.skins_desbloqueadas.append(sid)
			Salvar.salvar()
		"pet":
			var pid : String = str(out.get("pid", ""))
			if pid == "" or not Salvar.PETS_INFO.has(pid):
				return {}
			if not (pid in Salvar.pets_desbloqueados):
				Salvar.pets_desbloqueados.append(pid)
			Salvar.pet_niveis[pid] = int(Salvar.pet_niveis.get(pid, 1))
			Salvar.pet_cartas[pid] = int(Salvar.pet_cartas.get(pid, 0))
			Salvar.salvar()
		"hab":
			var hid : String = str(out.get("hid", ""))
			if hid == "" or not Salvar.HABIL_INFO.has(hid):
				return {}
			Salvar.habil_cargas[hid] = max(1, int(Salvar.habil_cargas.get(hid, 0)))
			out["cargas"] = int(Salvar.habil_cargas.get(hid, 1))
			Salvar.salvar()
		"cons":
			var cid : String = str(out.get("cons_id", ""))
			match cid:
				"revive":
					Salvar.revive_loja_estoque = max(1, Salvar.revive_loja_estoque)
				"orbe":
					Salvar.orbe_cura_estoque = max(1, Salvar.orbe_cura_estoque)
				"cristal":
					Salvar.cristal_barreira_estoque = max(1, Salvar.cristal_barreira_estoque)
				"runa":
					Salvar.runa_furia_estoque = max(1, Salvar.runa_furia_estoque)
				_:
					return {}
			out["nome"] = str(out.get("nome", "")).replace("x0", "x1")
			Salvar.normalizar_cons_equipados()
			Salvar.salvar()
		_:
			return {}
	return out


func _usar_sprite_key_na_mochila(key: String) -> bool:
	return key != "" and ITEM_SPRITES_MOCHILA_ATIVOS.has(key)


func _draw_item_sprite(c: Control, key: String, rect: Rect2, alpha: float = 1.0) -> bool:
	var tex := _item_sprite(key)
	if tex == null:
		return false
	_draw_texture_contain(c, tex, rect, alpha)
	return true


func _draw_item_sprite_contain(c: Control, key: String, rect: Rect2, alpha: float = 1.0) -> bool:
	var tex := _item_sprite(key)
	if tex == null:
		return false
	_draw_texture_contain(c, tex, rect, alpha)
	return true


func _reward_card_texture(raridade: String) -> Texture2D:
	var key := str(raridade)
	if not REWARD_CARD_TEXTURE_PATHS.has(key):
		key = "comum"
	if _reward_card_texture_cache.has(key):
		return _reward_card_texture_cache[key] as Texture2D
	var path : String = str(REWARD_CARD_TEXTURE_PATHS.get(key, REWARD_CARD_BASE_PATH))
	var tex : Texture2D = null
	if ResourceLoader.exists(path):
		tex = load(path) as Texture2D
	if tex == null:
		var img := Image.new()
		if img.load(ProjectSettings.globalize_path(path)) == OK:
			tex = ImageTexture.create_from_image(img)
	_reward_card_texture_cache[key] = tex
	return tex


func _reward_card_rarity(item: Dictionary) -> String:
	var rar : String = str(item.get("raridade", ""))
	if rar in ["comum", "raro", "epico", "lendario"]:
		return rar
	match str(item.get("tipo", "")):
		"skin", "pet", "arsenal", "bau":
			return "lendario"
		"pet_card", "upgrade":
			return "epico"
		"habil", "cons":
			return "raro"
		_:
			return "comum"


func _draw_reward_card_base(c: Control, rect: Rect2, raridade: String, alpha: float = 1.0) -> void:
	var tex := _reward_card_texture(raridade)
	if tex == null:
		return
	var tex_size : Vector2 = tex.get_size()
	var src := Rect2(
		Vector2(tex_size.x * 0.105, tex_size.y * 0.070),
		Vector2(tex_size.x * 0.790, tex_size.y * 0.825)
	)
	c.draw_texture_rect_region(tex, rect, src, Color(1.0, 1.0, 1.0, alpha))


func _is_reward_showcase_item(item: Dictionary) -> bool:
	var tipo : String = str(item.get("tipo", ""))
	return tipo == "skin" or tipo == "pet" or tipo == "pet_card"


func _order_bau_reward_cards(items: Array) -> Array:
	var normais : Array = []
	var especiais : Array = []
	for raw in items:
		var item : Dictionary = raw as Dictionary
		if _is_reward_showcase_item(item):
			especiais.append(item)
		else:
			normais.append(item)
	return normais + especiais


func _reward_commander_pid(item: Dictionary) -> String:
	var pid : String = str(item.get("pid", ""))
	if pid != "" and Salvar.PETS_INFO.has(pid):
		return pid
	var low : String = str(item.get("nome", "")).to_lower()
	for raw_pid in Salvar.PETS_INFO.keys():
		var spid : String = str(raw_pid)
		var info : Dictionary = Salvar.PETS_INFO.get(spid, {}) as Dictionary
		var nome : String = str(info.get("nome", spid)).to_lower()
		if nome != "" and nome in low:
			return spid
	if "dante" in low or "nexus" in low:
		return "nexus"
	if "eira" in low or "phantom" in low or "eclipse" in low:
		return "phantom"
	if "aurora" in low:
		return "aurora"
	return "cyron"


func _reward_skin_id(item: Dictionary) -> String:
	var sid : String = str(item.get("sid", ""))
	if sid != "" and Salvar.SKINS_INFO.has(sid):
		return sid
	var low : String = str(item.get("nome", "")).to_lower()
	for raw_sid in Salvar.SKINS_INFO.keys():
		var ssid : String = str(raw_sid)
		var info : Dictionary = Salvar.SKINS_INFO.get(ssid, {}) as Dictionary
		var nome : String = str(info.get("nome", ssid)).to_lower()
		if nome != "" and nome in low:
			return ssid
	return "padrao"


func _draw_skin_reward_preview(c: Control, skin_id: String, rect: Rect2, cor: Color, alpha: float = 1.0) -> void:
	var center : Vector2 = rect.position + rect.size * 0.5
	var radius : float = minf(rect.size.x, rect.size.y) * 0.28
	var t : float = Time.get_ticks_msec() * 0.001
	var cor2 : Color = Color(0.0, 1.0, 0.88) if skin_id == "saberpunk" else cor
	var cor3 : Color = Color(0.95, 0.16, 1.0) if skin_id == "saberpunk" else Color(cor.r + 0.18, cor.g + 0.18, cor.b + 0.18)
	for gi in range(7, 0, -1):
		var mix : Color = cor2 if gi % 2 == 0 else cor3
		c.draw_circle(center, radius + float(gi) * 10.0, Color(mix.r, mix.g, mix.b, 0.045 * alpha / float(gi)))
	for ring in range(3):
		var rr : float = radius + float(ring) * 20.0 + sin(t * 1.4 + float(ring)) * 3.0
		c.draw_arc(center, rr, t * (0.35 + float(ring) * 0.15), t * (0.35 + float(ring) * 0.15) + TAU * 0.72, 96,
			Color(cor2.r, cor2.g, cor2.b, (0.35 - float(ring) * 0.08) * alpha), 2.0, true)
	var hex := PackedVector2Array()
	for hi in range(6):
		var a : float = float(hi) * TAU / 6.0 + PI / 6.0 + t * 0.10
		hex.append(center + Vector2(cos(a), sin(a)) * radius)
	var fills := PackedColorArray()
	for _i in range(hex.size()):
		fills.append(Color(cor.r * 0.12, cor.g * 0.12, cor.b * 0.12, 0.88 * alpha))
	c.draw_polygon(hex, fills)
	var border := PackedVector2Array(hex)
	border.append(hex[0])
	c.draw_polyline(border, Color(cor3.r, cor3.g, cor3.b, 0.84 * alpha), 3.0, true)
	c.draw_polyline(border, Color(1.0, 1.0, 1.0, 0.18 * alpha), 1.0, true)
	var dir : Vector2 = Vector2(cos(-PI * 0.35), sin(-PI * 0.35))
	var lat : Vector2 = dir.rotated(PI / 2.0)
	var base : Vector2 = center - dir * radius * 0.28
	var tip : Vector2 = center + dir * radius * 0.78
	var body := PackedVector2Array([
		base - lat * radius * 0.34,
		base + lat * radius * 0.34,
		tip + lat * radius * 0.10,
		tip - lat * radius * 0.10,
	])
	var body_fill := PackedColorArray([
		Color(cor.r * 0.26, cor.g * 0.26, cor.b * 0.26, 0.96 * alpha),
		Color(cor.r * 0.22, cor.g * 0.22, cor.b * 0.22, 0.96 * alpha),
		Color(cor.r + 0.10, cor.g + 0.10, cor.b + 0.10, 0.96 * alpha),
		Color(cor.r * 0.16, cor.g * 0.16, cor.b * 0.16, 0.96 * alpha),
	])
	c.draw_polygon(body, body_fill)
	c.draw_circle(base, radius * 0.28, Color(cor.r * 0.10, cor.g * 0.10, cor.b * 0.10, 0.92 * alpha))
	c.draw_circle(base, radius * 0.16, Color(cor2.r, cor2.g, cor2.b, 0.92 * alpha))
	c.draw_circle(tip, radius * 0.13 + sin(t * 4.0) * 2.0, Color(cor3.r, cor3.g, cor3.b, 0.92 * alpha))
	for pi in range(12):
		var a2 : float = float(pi) * TAU / 12.0 + t * 0.9
		c.draw_circle(center + Vector2(cos(a2) * radius * 1.25, sin(a2) * radius * 0.72), 2.0,
			Color(cor2.r, cor2.g, cor2.b, 0.34 * alpha))


func _skin_reward_texture(skin_id: String) -> Texture2D:
	var sid : String = str(skin_id)
	if _skin_sprite_cache.has(sid):
		return _skin_sprite_cache[sid] as Texture2D
	var candidates := [
		"res://assets/sprites/skins/%s.png" % sid,
		"res://assets/skins/%s.png" % sid,
		"res://assets/sprites/itens/skin_%s.png" % sid,
	]
	var tex : Texture2D = null
	for path in candidates:
		tex = _load_texture_file(path)
		if tex != null:
			break
	_skin_sprite_cache[sid] = tex
	return tex


func _draw_reward_item_visual(c: Control, item: Dictionary, rect: Rect2, alpha: float = 1.0) -> bool:
	var tipo : String = str(item.get("tipo", ""))
	match tipo:
		"ouro":
			return _draw_currency_icon(c, "ouro", rect, alpha)
		"cristais":
			return _draw_currency_icon(c, "cristais", rect, alpha)
		"pet", "pet_card":
			var pid : String = _reward_commander_pid(item)
			var tex := _comandante_sprite(pid)
			if tex != null:
				_draw_texture_cover_chamfered(c, tex, rect, _comandante_card_source_rect(tex),
					minf(rect.size.x * 0.18, 24.0), minf(rect.size.y * 0.12, 24.0), alpha, 0.24)
				return true
			return _draw_comandante_face(c, pid, rect, alpha)
		"skin":
			var sid : String = _reward_skin_id(item)
			var skin_tex := _skin_reward_texture(sid)
			if skin_tex != null:
				_draw_texture_contain(c, skin_tex, rect, alpha)
				return true
			var sinfo : Dictionary = Salvar.SKINS_INFO.get(sid, {}) as Dictionary
			var scolor : Color = sinfo.get("cor", item.get("cor", Color(1.0, 0.55, 0.18))) as Color
			_draw_skin_reward_preview(c, sid, rect, scolor, alpha)
			return true
		"bau":
			var bau_id : String = str(item.get("bau_id", item.get("id", "raro")))
			var bau_tex := _bau_sprite(bau_id)
			if bau_tex != null:
				_draw_texture_contain(c, bau_tex, rect, alpha)
				return true
		"upgrade":
			var uid : String = str(item.get("upgrade_id", ""))
			var uinfo : Dictionary = Salvar.LOJA_INFO.get(uid, {}) as Dictionary
			var uc : Color = uinfo.get("cor", item.get("cor", Color(1.0, 0.78, 0.18))) as Color
			var center : Vector2 = rect.position + rect.size * 0.5
			var r : float = minf(rect.size.x, rect.size.y) * 0.38
			for gi in range(5, 0, -1):
				c.draw_circle(center, r + float(gi) * 7.0, Color(uc.r, uc.g, uc.b, 0.040 * alpha / float(gi)))
			var hex := PackedVector2Array()
			for hi in range(6):
				var a : float = float(hi) * TAU / 6.0 + PI / 6.0
				hex.append(center + Vector2(cos(a), sin(a)) * r)
			var fill := PackedColorArray()
			for _fi in range(hex.size()):
				fill.append(Color(uc.r * 0.12, uc.g * 0.12, uc.b * 0.12, 0.94 * alpha))
			c.draw_polygon(hex, fill)
			var outline := PackedVector2Array(hex)
			outline.append(hex[0])
			c.draw_polyline(outline, Color(uc.r + 0.16, uc.g + 0.16, uc.b + 0.16, 0.88 * alpha), 2.6, true)
			c.draw_line(center + Vector2(-r * 0.30, r * 0.16), center + Vector2(0.0, -r * 0.28), Color(1.0, 1.0, 1.0, 0.92 * alpha), 4.0)
			c.draw_line(center + Vector2(0.0, -r * 0.28), center + Vector2(r * 0.30, r * 0.16), Color(1.0, 1.0, 1.0, 0.92 * alpha), 4.0)
			c.draw_line(center + Vector2(0.0, -r * 0.28), center + Vector2(0.0, r * 0.32), Color(1.0, 1.0, 1.0, 0.92 * alpha), 4.0)
			return true
	var sprite_key : String = _item_sprite_key_from_item(item)
	if sprite_key != "":
		return _draw_item_sprite(c, sprite_key, rect, alpha)
	return false


func _draw_reward_commander_portrait(c: Control, item: Dictionary, rect: Rect2, alpha: float = 1.0) -> bool:
	var pid : String = _reward_commander_pid(item)
	var tex := _comandante_sprite(pid)
	c.draw_rect(rect, Color(0.0, 0.0, 0.0, 0.18 * alpha), true)
	if tex != null:
		_draw_texture_cover_chamfered(c, tex, rect, _comandante_card_source_rect(tex),
			minf(rect.size.x * 0.18, 32.0), minf(rect.size.y * 0.12, 34.0), alpha, 0.24)
		return true
	return _draw_comandante_face(c, pid, rect, alpha)


func _draw_reward_sealed_card(c: Control, rect: Rect2, raridade: String, cor: Color, titulo: String, alpha: float = 1.0) -> void:
	_draw_reward_card_base(c, rect, raridade, alpha)
	var center : Vector2 = rect.position + rect.size * 0.5
	var t : float = Time.get_ticks_msec() * 0.001
	var inner := rect.grow(-24.0)
	c.draw_rect(inner, Color(0.0, 0.0, 0.0, 0.50 * alpha), true)
	for gi in range(6, 0, -1):
		c.draw_circle(center, minf(rect.size.x, rect.size.y) * (0.16 + float(gi) * 0.045),
			Color(cor.r, cor.g, cor.b, 0.030 * alpha / float(gi)))
	for ring in range(3):
		var rr : float = minf(rect.size.x, rect.size.y) * (0.23 + float(ring) * 0.075)
		var start : float = t * (0.7 + float(ring) * 0.18) + float(ring)
		c.draw_arc(center, rr, start, start + TAU * 0.70, 72,
			Color(cor.r + 0.12, cor.g + 0.12, cor.b + 0.12, (0.52 - float(ring) * 0.12) * alpha), 2.0, true)
	var diamond_r : float = minf(rect.size.x, rect.size.y) * 0.20
	var diamond := PackedVector2Array([
		center + Vector2(0.0, -diamond_r),
		center + Vector2(diamond_r * 0.72, 0.0),
		center + Vector2(0.0, diamond_r),
		center + Vector2(-diamond_r * 0.72, 0.0),
	])
	var fills := PackedColorArray()
	for _i in range(diamond.size()):
		fills.append(Color(cor.r * 0.09, cor.g * 0.09, cor.b * 0.12, 0.86 * alpha))
	c.draw_polygon(diamond, fills)
	var outline := PackedVector2Array()
	for p in diamond:
		outline.append(p)
	outline.append(diamond[0])
	c.draw_polyline(outline, Color(cor.r + 0.18, cor.g + 0.18, cor.b + 0.18, 0.88 * alpha), 3.0, true)
	c.draw_string(_font_title, Vector2(rect.position.x, rect.position.y + 38.0), titulo, HORIZONTAL_ALIGNMENT_CENTER,
		rect.size.x, 16, Color(cor.r + 0.18, cor.g + 0.18, cor.b + 0.18, 0.92 * alpha))
	c.draw_string(ThemeDB.fallback_font, Vector2(rect.position.x, center.y + 20.0), "?", HORIZONTAL_ALIGNMENT_CENTER,
		rect.size.x, 54, Color(1.0, 1.0, 1.0, 0.96 * alpha))
	c.draw_string(ThemeDB.fallback_font, Vector2(rect.position.x, rect.end.y - 44.0), "REVELACAO", HORIZONTAL_ALIGNMENT_CENTER,
		rect.size.x, 16, Color(0.78, 0.88, 1.0, 0.70 * alpha))
	for pi in range(16):
		var a : float = float(pi) * TAU / 16.0 + t * 1.25
		c.draw_circle(center + Vector2(cos(a) * diamond_r * 1.85, sin(a) * diamond_r * 1.22), 1.8,
			Color(cor.r + 0.20, cor.g + 0.20, cor.b + 0.20, 0.34 * alpha))


func _draw_reward_card_portrait_cutouts(c: Control, rect: Rect2, bg: Color, cor: Color, alpha: float = 1.0) -> void:
	var cut_x : float = minf(rect.size.x * 0.28, 46.0)
	var cut_y : float = minf(rect.size.y * 0.16, 52.0)
	var p0 : Vector2 = rect.position
	var p1 : Vector2 = rect.end
	var fill := Color(bg.r, bg.g, bg.b, 0.98 * alpha)
	c.draw_polygon(PackedVector2Array([p0, p0 + Vector2(cut_x, 0.0), p0 + Vector2(0.0, cut_y)]), PackedColorArray([fill, fill, fill]))
	c.draw_polygon(PackedVector2Array([Vector2(p1.x, p0.y), Vector2(p1.x - cut_x, p0.y), Vector2(p1.x, p0.y + cut_y)]), PackedColorArray([fill, fill, fill]))
	c.draw_polygon(PackedVector2Array([Vector2(p0.x, p1.y), Vector2(p0.x + cut_x, p1.y), Vector2(p0.x, p1.y - cut_y)]), PackedColorArray([fill, fill, fill]))
	c.draw_polygon(PackedVector2Array([p1, p1 - Vector2(cut_x, 0.0), p1 - Vector2(0.0, cut_y)]), PackedColorArray([fill, fill, fill]))


func _show_reward_special_overlay(parent: Node, item: Dictionary, finished: Callable, preview_mode: bool = false) -> void:
	if not _is_reward_showcase_item(item):
		if finished.is_valid():
			finished.call()
		return
	var tipo : String = str(item.get("tipo", ""))
	var vp : Vector2 = get_viewport().get_visible_rect().size
	var raridade : String = _reward_card_rarity(item)
	var qtd : int = int(item.get("qtd", 1))
	var nome : String = str(item.get("nome", ""))
	var cor : Color = Color(1.0, 0.55, 0.18)
	var titulo : String = "PREVIEW DE SKIN" if preview_mode else "SKIN DESBLOQUEADA"
	var subtitulo : String = "Visual apenas para preview" if preview_mode else "Visual adicionado ao inventario"
	if tipo == "pet" or tipo == "pet_card":
		var pid : String = _reward_commander_pid(item)
		var pinfo : Dictionary = Salvar.PETS_INFO.get(pid, {}) as Dictionary
		var pmeta : Dictionary = _comandante_meta(pid)
		cor = pmeta.get("cor", pinfo.get("cor", Color(0.25, 0.75, 1.0))) as Color
		nome = str(pinfo.get("nome", nome.replace("Cartas de ", "")))
		if tipo == "pet":
			titulo = "PREVIEW DE COMANDANTE" if preview_mode else "COMANDANTE DESBLOQUEADO"
			subtitulo = "Comandante apenas no preview" if preview_mode else "Novo comandante adicionado"
		else:
			titulo = "PREVIEW DE COMANDANTE" if preview_mode else "CARTAS DE COMANDANTE"
			subtitulo = "+%d cartas no preview" % qtd if preview_mode else "+%d cartas coletadas" % qtd
	else:
		var sid : String = _reward_skin_id(item)
		var sinfo : Dictionary = Salvar.SKINS_INFO.get(sid, {}) as Dictionary
		cor = sinfo.get("cor", cor) as Color
		nome = str(sinfo.get("nome", nome))

	var overlay := ColorRect.new()
	overlay.name = "RewardSpecialOverlay"
	overlay.color = Color(0.0, 0.0, 0.0, 0.0)
	overlay.size = vp
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	overlay.z_index = 220
	parent.add_child(overlay)

	var bg_fx := Control.new()
	bg_fx.size = vp
	bg_fx.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.add_child(bg_fx)
	bg_fx.draw.connect(func():
		var now : float = Time.get_ticks_msec() * 0.001
		bg_fx.draw_rect(Rect2(Vector2.ZERO, vp), Color(0.0, 0.0, 0.0, 0.54), true)
		var center : Vector2 = vp * 0.5
		for gi in range(8, 0, -1):
			bg_fx.draw_circle(center, 110.0 + float(gi) * 52.0, Color(cor.r, cor.g, cor.b, 0.030 / float(gi)))
		for line in range(10):
			var y : float = fposmod(now * 32.0 + float(line) * 74.0, vp.y + 120.0) - 60.0
			bg_fx.draw_line(Vector2(0.0, y), Vector2(vp.x, y - 32.0), Color(cor.r, cor.g, cor.b, 0.035), 1.0)
		for pi in range(20):
			var a : float = float(pi) * TAU / 20.0 + now * 0.45
			var rr : float = 140.0 + float(pi % 5) * 34.0
			bg_fx.draw_circle(center + Vector2(cos(a) * rr, sin(a) * rr * 0.56), 2.0,
				Color(cor.r + 0.12, cor.g + 0.12, cor.b + 0.12, 0.28))
	)

	var pw : float = minf(640.0, vp.x - 36.0)
	var ph : float = minf(640.0, vp.y - 26.0)
	var panel := _inv_painel(overlay, (vp.x - pw) * 0.5, (vp.y - ph) * 0.5, pw, ph,
		Color(cor.r * 0.035, cor.g * 0.035, cor.b * 0.045, 0.98), Color(cor.r, cor.g, cor.b, 0.86), 3)
	panel.pivot_offset = Vector2(pw * 0.5, ph * 0.5)
	panel.scale = Vector2(0.72, 0.72)
	panel.modulate.a = 0.0
	panel.visible = false
	_inv_lbl(panel, titulo, 18.0, 26.0, pw - 36.0, 34.0, 26,
		Color(cor.r + 0.18, cor.g + 0.18, cor.b + 0.18, 0.98), HORIZONTAL_ALIGNMENT_CENTER)
	_inv_lbl(panel, subtitulo, 18.0, 62.0, pw - 36.0, 24.0, 15,
		Color(0.72, 0.86, 1.0, 0.76), HORIZONTAL_ALIGNMENT_CENTER)

	var art := Control.new()
	art.position = Vector2((pw - 360.0) * 0.5, 108.0)
	art.size = Vector2(360.0, 330.0)
	art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(art)
	var local_t0 : float = Time.get_ticks_msec() * 0.001
	art.draw.connect(func():
		var now : float = Time.get_ticks_msec() * 0.001
		var age : float = now - local_t0
		var card_rect := Rect2(74.0, 6.0 + sin(age * 1.7) * 4.0, 212.0, 306.0)
		if tipo == "pet" or tipo == "pet_card":
			_draw_reward_card_base(art, card_rect, raridade, 1.0)
			var pid2 : String = _reward_commander_pid(item)
			var tex := _comandante_sprite(pid2)
			var portrait_rect := _reward_commander_portrait_rect(card_rect)
			var portrait_bg := Color(0.0, 0.0, 0.0, 1.0)
			art.draw_rect(portrait_rect, Color(portrait_bg.r, portrait_bg.g, portrait_bg.b, 0.20), true)
			if tex != null:
				_draw_texture_cover_chamfered(art, tex, portrait_rect, _comandante_card_source_rect(tex),
					minf(portrait_rect.size.x * 0.18, 34.0), minf(portrait_rect.size.y * 0.12, 38.0), 0.98, 0.24)
			else:
				_draw_comandante_face(art, pid2, portrait_rect, 0.96)
		else:
			var sid2 : String = _reward_skin_id(item)
			_draw_skin_reward_preview(art, sid2, Rect2(20.0, 8.0, 320.0, 304.0), cor, 1.0)
	)

	var nome_lbl := _inv_lbl(panel, nome.to_upper(), 24.0, ph - 164.0, pw - 48.0, 46.0, 34,
		Color(1.0, 1.0, 1.0, 0.98), HORIZONTAL_ALIGNMENT_CENTER)
	nome_lbl.add_theme_font_override("font", _font_title)
	var extra_text : String = "NOVA SKIN DISPONIVEL"
	if tipo == "pet_card":
		extra_text = "+%d CARTAS" % qtd
	elif tipo == "pet":
		extra_text = "NOVO COMANDANTE"
	_inv_lbl(panel, extra_text, 24.0, ph - 112.0, pw - 48.0, 28.0, 20,
		Color(cor.r + 0.18, cor.g + 0.18, cor.b + 0.18, 0.94), HORIZONTAL_ALIGNMENT_CENTER)
	_inv_lbl(panel, "TOQUE PARA CONTINUAR", 24.0, ph - 58.0, pw - 48.0, 24.0, 15,
		Color(0.80, 0.88, 1.0, 0.70), HORIZONTAL_ALIGNMENT_CENTER)

	var intro_w : float = minf(238.0, vp.x * 0.42)
	var intro_h : float = intro_w * 1.44
	if intro_h > vp.y * 0.62:
		intro_h = vp.y * 0.62
		intro_w = intro_h / 1.44
	var intro_card := Control.new()
	intro_card.name = "RewardIntroCard"
	intro_card.position = (vp - Vector2(intro_w, intro_h)) * 0.5
	intro_card.size = Vector2(intro_w, intro_h)
	intro_card.pivot_offset = intro_card.size * 0.5
	intro_card.scale = Vector2(0.20, 0.20)
	intro_card.modulate.a = 0.0
	intro_card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	intro_card.z_index = 226
	overlay.add_child(intro_card)
	intro_card.draw.connect(func():
		var now : float = Time.get_ticks_msec() * 0.001
		var pulse : float = 0.84 + 0.16 * sin(now * 4.0)
		for gi in range(7, 0, -1):
			intro_card.draw_circle(intro_card.size * 0.5, intro_w * (0.22 + float(gi) * 0.075),
				Color(cor.r, cor.g, cor.b, 0.025 * pulse / float(gi)))
		_draw_reward_sealed_card(intro_card, Rect2(Vector2.ZERO, intro_card.size), raridade, cor, "CARTA ESPECIAL", 1.0)
	)

	var intro_flash := ColorRect.new()
	intro_flash.name = "RewardIntroFlash"
	intro_flash.color = Color(cor.r + 0.25, cor.g + 0.25, cor.b + 0.25, 1.0)
	intro_flash.modulate.a = 0.0
	intro_flash.size = vp
	intro_flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	intro_flash.z_index = 227
	overlay.add_child(intro_flash)

	var redraw_timer := Timer.new()
	redraw_timer.wait_time = 0.033
	redraw_timer.autostart = true
	redraw_timer.timeout.connect(func():
		if is_instance_valid(bg_fx):
			bg_fx.queue_redraw()
		if is_instance_valid(intro_card):
			intro_card.queue_redraw()
		if is_instance_valid(art):
			art.queue_redraw()
	)
	overlay.add_child(redraw_timer)

	var tap := Button.new()
	tap.position = Vector2.ZERO
	tap.size = vp
	tap.text = ""
	tap.focus_mode = Control.FOCUS_NONE
	tap.disabled = true
	var empty := StyleBoxEmpty.new()
	for key in ["normal", "hover", "pressed", "disabled", "focus", "hover_pressed"]:
		tap.add_theme_stylebox_override(key, empty)
	overlay.add_child(tap)

	var tw_in := create_tween()
	tw_in.set_parallel(true)
	tw_in.tween_property(overlay, "color", Color(0.0, 0.0, 0.0, 0.90), 0.18)
	tw_in.tween_property(intro_card, "scale", Vector2(1.0, 1.0), 0.24).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw_in.tween_property(intro_card, "modulate:a", 1.0, 0.16)
	tw_in.set_parallel(false)
	tw_in.tween_method(func(v):
		if not is_instance_valid(intro_card):
			return
		var sx : float = 0.10 + 0.92 * abs(cos(float(v) * TAU * 3.0))
		var sy : float = 1.00 + 0.07 * sin(float(v) * PI * 3.0)
		intro_card.scale = Vector2(sx, sy)
		intro_card.rotation_degrees = sin(float(v) * TAU * 3.0) * 3.0
		intro_card.queue_redraw()
	, 0.0, 1.0, 1.05).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	tw_in.tween_property(intro_card, "scale", Vector2(1.12, 1.12), 0.10).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw_in.tween_property(intro_flash, "modulate:a", 0.88, 0.07)
	tw_in.tween_property(intro_flash, "modulate:a", 0.0, 0.18)
	tw_in.tween_callback(func():
		if is_instance_valid(intro_card):
			intro_card.visible = false
		panel.visible = true
	)
	tw_in.set_parallel(true)
	tw_in.tween_property(panel, "scale", Vector2(1.0, 1.0), 0.34).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw_in.tween_property(panel, "modulate:a", 1.0, 0.18)
	tw_in.set_parallel(false)
	tw_in.tween_callback(func():
		tap.disabled = false
	)
	tap.pressed.connect(func():
		tap.disabled = true
		var tw_out := create_tween()
		tw_out.set_parallel(true)
		tw_out.tween_property(panel, "scale", Vector2(1.10, 1.10), 0.16).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
		tw_out.tween_property(panel, "modulate:a", 0.0, 0.14)
		tw_out.tween_property(overlay, "color", Color(0.0, 0.0, 0.0, 0.0), 0.18)
		tw_out.set_parallel(false)
		tw_out.tween_callback(func():
			if is_instance_valid(overlay):
				overlay.queue_free()
			if finished.is_valid():
				finished.call()
		)
	)


func _draw_bau_icon(c: Control, tier: String, count: int, abertura_prog: float = -1.0) -> void:
	var info := _bau_info(tier)
	var cor : Color = info["cor"] as Color
	var luz : Color = info["luz"] as Color
	var w : float = c.size.x
	var h : float = c.size.y
	var cx : float = w * 0.5
	var pequeno : bool = h <= 96.0
	var mini : bool = h <= 64.0
	var cy : float = h * (0.47 if pequeno else 0.55)
	var t : float = Time.get_ticks_msec() * 0.001
	var abrindo : bool = abertura_prog >= 0.0
	var active : float = 1.0 if count > 0 or abrindo else 0.28
	var glow : float = (0.55 + 0.45 * sin(t * 2.0)) * active
	var tex := _bau_sprite(tier)

	if abrindo:
		var open_tex := _bau_open_sprite(tier)
		if open_tex != null:
			var glow_y : float = cy + (4.0 if pequeno else 16.0)
			var glow_r : float = minf(w, h) * (0.34 if pequeno else 0.50)
			c.draw_circle(Vector2(cx, glow_y), glow_r, Color(luz.r, luz.g, luz.b, 0.14 + 0.08 * glow))
			c.draw_circle(Vector2(cx, glow_y + (1.0 if pequeno else 2.0)), glow_r * 0.64, Color(cor.r, cor.g, cor.b, 0.10))
			var frame_h : float = float(open_tex.get_height())
			var frame_w : float = frame_h * 4.0 / 3.0
			var frames : int = maxi(1, int(round(float(open_tex.get_width()) / frame_w)))
			var prog : float = clampf(abertura_prog, 0.0, 0.999)
			var frame : int = clampi(int(floor(prog * float(frames))), 0, frames - 1)
			var crop_top : float = 20.0
			var src := Rect2(frame_w * float(frame), crop_top, frame_w, frame_h - crop_top)
			var sprite_w : float = minf(w * 1.02, 218.0)
			var sprite_h : float = sprite_w * frame_h / frame_w
			if h < 126.0:
				sprite_w = minf(w * (0.70 if mini else 0.78), 162.0)
				sprite_h = sprite_w * frame_h / frame_w
			var pulse_open : float = 1.0 + sin(prog * PI) * 0.08
			sprite_w *= pulse_open
			sprite_h *= pulse_open
			var scale_y : float = sprite_h / frame_h
			var rect := Rect2(cx - sprite_w * 0.5, cy - sprite_h * 0.5 + crop_top * scale_y, sprite_w, sprite_h - crop_top * scale_y)
			c.draw_texture_rect_region(open_tex, rect, src, Color(1.0, 1.0, 1.0, 1.0))
			if prog > 0.34 and prog < 0.82:
				var burst : float = sin((prog - 0.34) / 0.48 * PI)
				c.draw_circle(Vector2(cx, cy - sprite_h * 0.22), 26.0 + 34.0 * burst, Color(luz.r, luz.g, luz.b, 0.18 * burst))
				c.draw_line(Vector2(cx, cy - sprite_h * 0.42), Vector2(cx, cy - sprite_h * 0.90), Color(luz.r, luz.g, luz.b, 0.36 * burst), 4.0)
			return

	if tex != null:
		var glow_y : float = cy + (4.0 if pequeno else 16.0)
		var glow_r : float = minf(w, h) * (0.34 if pequeno else 0.46)
		c.draw_circle(Vector2(cx, glow_y), glow_r, Color(luz.r, luz.g, luz.b, 0.08 * active + 0.04 * glow))
		c.draw_circle(Vector2(cx, glow_y + (1.0 if pequeno else 2.0)), glow_r * 0.65, Color(cor.r, cor.g, cor.b, 0.055 * active))
		var sprite_w : float = minf(w * 0.92, 190.0)
		var sprite_h : float = sprite_w * 0.75
		if h < 126.0:
			sprite_w = minf(w * (0.64 if mini else 0.72), 142.0)
			sprite_h = sprite_w * 0.75
		var rect := Rect2(cx - sprite_w * 0.5, cy - sprite_h * 0.5, sprite_w, sprite_h)
		c.draw_texture_rect(tex, rect, false, Color(1.0, 1.0, 1.0, active))
		if count <= 0:
			c.draw_rect(rect.grow(4.0), Color(0.0, 0.0, 0.0, 0.50))
		if tier == "lendario" and count > 0:
			for i in range(8):
				var a := float(i) * TAU / 8.0 + t * 1.4
				var orbit_x : float = minf(sprite_w * (0.42 if pequeno else 0.56), w * 0.36)
				var orbit_y : float = minf(sprite_h * (0.26 if pequeno else 0.36), h * 0.24)
				c.draw_circle(Vector2(cx + cos(a) * orbit_x, cy - (2.0 if pequeno else 6.0) + sin(a) * orbit_y), 1.7 if pequeno else 2.6,
					Color(1.0, 0.86, 0.18, 0.35 + 0.22 * glow))
		return

	c.draw_circle(Vector2(cx, cy + 30.0), 72.0, Color(luz.r, luz.g, luz.b, 0.06 * active))
	c.draw_rect(Rect2(cx - 72.0, cy + 62.0, 144.0, 12.0), Color(0.0, 0.0, 0.0, 0.24))
	c.draw_circle(Vector2(cx - 72.0, cy + 68.0), 6.0, Color(0.0, 0.0, 0.0, 0.24))
	c.draw_circle(Vector2(cx + 72.0, cy + 68.0), 6.0, Color(0.0, 0.0, 0.0, 0.24))
	c.draw_rect(Rect2(cx - 72.0, cy - 12.0, 144.0, 72.0), Color(cor.r * 0.42, cor.g * 0.42, cor.b * 0.42, 0.98 * active))
	c.draw_rect(Rect2(cx - 72.0, cy - 12.0, 144.0, 72.0), Color(0.05, 0.05, 0.08, 0.55 * active), false, 3.0)
	c.draw_polygon(PackedVector2Array([
		Vector2(cx - 78.0, cy - 18.0),
		Vector2(cx - 50.0, cy - 56.0),
		Vector2(cx + 50.0, cy - 56.0),
		Vector2(cx + 78.0, cy - 18.0),
	]), PackedColorArray([
		Color(cor.r * 0.72, cor.g * 0.72, cor.b * 0.72, active),
		Color(cor.r * 0.95, cor.g * 0.95, cor.b * 0.95, active),
		Color(cor.r * 0.95, cor.g * 0.95, cor.b * 0.95, active),
		Color(cor.r * 0.72, cor.g * 0.72, cor.b * 0.72, active),
	]))
	c.draw_line(Vector2(cx - 76.0, cy - 17.0), Vector2(cx + 76.0, cy - 17.0), Color(0.08,0.08,0.12,0.82 * active), 4.0)
	for sx in [-54.0, 54.0]:
		c.draw_rect(Rect2(cx + sx - 11.0, cy - 50.0, 22.0, 110.0), Color(0.86,0.88,0.92,0.82 * active))
		c.draw_rect(Rect2(cx + sx - 11.0, cy - 50.0, 22.0, 110.0), Color(0.05,0.05,0.07,0.45 * active), false, 2.0)
	c.draw_rect(Rect2(cx - 22.0, cy - 22.0, 44.0, 44.0), Color(luz.r, luz.g, luz.b, 0.32 + 0.22 * glow))
	c.draw_rect(Rect2(cx - 22.0, cy - 22.0, 44.0, 44.0), Color(1.0,1.0,1.0,0.72 * active), false, 2.4)
	c.draw_circle(Vector2(cx, cy), 10.0 + 2.0 * glow, Color(luz.r, luz.g, luz.b, 0.85 * active))
	c.draw_line(Vector2(cx - 76.0, cy + 10.0), Vector2(cx + 76.0, cy + 10.0), Color(luz.r, luz.g, luz.b, 0.16 * active), 3.0)
	if tier == "lendario":
		for i in range(6):
			var a := float(i) * TAU / 6.0 + t
			c.draw_circle(Vector2(cx + cos(a) * 92.0, cy - 5.0 + sin(a) * 44.0), 3.0, Color(1.0,0.9,0.25,0.45 * active))


func _draw_bau_popup_icon(c: Control, center: Vector2) -> void:
	var tex := _bau_sprite("lendario")
	if tex == null:
		_draw_bau_icon(c, "lendario", 1)
		return
	var t := Time.get_ticks_msec() * 0.001
	var glow := 0.55 + 0.45 * sin(t * 2.0)
	c.draw_circle(center, 34.0, Color(1.0, 0.92, 0.35, 0.08 + 0.04 * glow))
	c.draw_circle(center + Vector2(0.0, 1.0), 22.0, Color(1.0, 0.70, 0.12, 0.06))

	var src := Rect2(28.0, 34.0, 200.0, 130.0)
	var dst_size := Vector2(94.0, 61.0)
	var dst := Rect2(center - dst_size * 0.5, dst_size)
	c.draw_texture_rect_region(tex, dst, src, Color.WHITE)

	for i in range(8):
		var a := float(i) * TAU / 8.0 + t * 1.4
		c.draw_circle(center + Vector2(cos(a) * 40.0, -3.0 + sin(a) * 22.0), 1.7, Color(1.0, 0.86, 0.18, 0.35 + 0.22 * glow))


func _abrir_baus(ui: CanvasLayer) -> void:
	var menu_estava_visivel : bool = _menu_contents and _menu_contents.visible
	if menu_estava_visivel:
		_menu_contents.hide()
	var vp := get_viewport().get_visible_rect().size
	var ov := ColorRect.new()
	ov.color = Color(0.0, 0.0, 0.0, 0.90)
	ov.size = vp
	ov.mouse_filter = Control.MOUSE_FILTER_STOP
	ui.add_child(ov)

	var pw : float = minf(1080.0, vp.x - 32.0)
	var ph : float = minf(640.0, vp.y - 32.0)
	var pnl := _inv_painel(ov, (vp.x - pw) * 0.5, (vp.y - ph) * 0.5, pw, ph,
		Color(0.025, 0.035, 0.055, 0.98), Color(1.0, 0.72, 0.16, 0.62), 2)
	_inv_lbl(pnl, "BAUS DA MOCHILA", 0, 18, pw, 36, 30, Color(1.0, 0.78, 0.18), HORIZONTAL_ALIGNMENT_CENTER)
	_inv_lbl(pnl, "Ganhos nas waves. Abra para receber ouro, cristais, skins, comandantes, habilidades e consumíveis.", 28, 56, pw - 56, 28, 16,
		Color(0.72, 0.86, 1.0, 0.78), HORIZONTAL_ALIGNMENT_CENTER)
	var res_lbl := _inv_lbl(pnl, "Selecione um bau para abrir.", 34, ph - 142.0, pw - 68.0, 72, 17,
		Color(0.78, 0.82, 0.90), HORIZONTAL_ALIGNMENT_CENTER)
	res_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD
	var rewards_cont := Control.new()
	rewards_cont.position = Vector2(28.0, ph - 126.0)
	rewards_cont.size = Vector2(pw - 56.0, 62.0)
	rewards_cont.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pnl.add_child(rewards_cont)
	var _reward_color := func(tipo: String) -> Color:
		match tipo:
			"ouro":
				return Color(1.0, 0.78, 0.12)
			"cristais":
				return Color(0.25, 0.95, 1.0)
			"skin":
				return Color(1.0, 0.42, 0.18)
			"pet", "pet_card":
				return Color(0.25, 0.75, 1.0)
			"habil":
				return Color(0.35, 0.95, 1.0)
			"cons":
				return Color(0.45, 1.0, 0.35)
			"upgrade":
				return Color(0.92, 0.28, 1.0)
			_:
				return Color(0.8, 0.82, 0.9)
	var _reward_icon := func(tipo: String) -> String:
		match tipo:
			"ouro":
				return "O"
			"cristais":
				return "C"
			"skin":
				return "S"
			"pet", "pet_card":
				return "A"
			"habil":
				return "H"
			"cons":
				return "+"
			"upgrade":
				return "UP"
			_:
				return "?"
	var _build_rewards := func(recompensas: Array) -> void:
		for old in rewards_cont.get_children():
			old.queue_free()
		if recompensas.is_empty():
			return
		var r_gap : float = 8.0
		var r_cols : int = mini(4, recompensas.size())
		var r_w : float = (rewards_cont.size.x - r_gap * float(r_cols - 1)) / float(r_cols)
		var r_h : float = rewards_cont.size.y
		for ri in range(recompensas.size()):
			if ri >= 4:
				break
			var item : Dictionary = recompensas[ri] as Dictionary
			var tipo : String = str(item.get("tipo", ""))
			var cor_r : Color = _reward_color.call(tipo) as Color
			var card_r := _inv_painel(rewards_cont, float(ri) * (r_w + r_gap), 0.0, r_w, r_h,
				Color(cor_r.r * 0.12, cor_r.g * 0.12, cor_r.b * 0.12, 0.96),
				Color(cor_r.r, cor_r.g, cor_r.b, 0.74), 2)
			var badge := Control.new()
			badge.position = Vector2(8, 8)
			badge.size = Vector2(38, 38)
			badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
			card_r.add_child(badge)
			var icon_txt : String = _reward_icon.call(tipo) as String
			var sprite_key_r := _item_sprite_key_from_item(item)
			badge.draw.connect(func():
				if sprite_key_r != "" and _draw_item_sprite(badge, sprite_key_r, Rect2(2.0, 2.0, 34.0, 34.0)):
					return
				badge.draw_circle(Vector2(19, 19), 18.0, Color(cor_r.r, cor_r.g, cor_r.b, 0.22))
				badge.draw_arc(Vector2(19, 19), 17.0, 0.0, TAU, 36, Color(cor_r.r, cor_r.g, cor_r.b, 0.88), 2.0, true)
				badge.draw_string(ThemeDB.fallback_font, Vector2(0, 25), icon_txt, HORIZONTAL_ALIGNMENT_CENTER, 38, 16, Color(1.0, 1.0, 1.0, 0.95))
			)
			var nome_r : String = str(item.get("nome", "Item"))
			var qtd_r : int = int(item.get("qtd", 1))
			_inv_lbl(card_r, nome_r, 50, 9, r_w - 58, 24, 13, Color(0.92, 0.94, 1.0), HORIZONTAL_ALIGNMENT_LEFT)
			var tipo_legenda : String = "Cartas" if tipo == "pet_card" else ("Comandante" if tipo == "pet" else tipo.capitalize())
			_inv_lbl(card_r, "%s  x%d" % [tipo_legenda, qtd_r], 50, 32, r_w - 58, 20, 12,
				Color(cor_r.r + 0.18, cor_r.g + 0.18, cor_r.b + 0.18, 0.92), HORIZONTAL_ALIGNMENT_LEFT)

	var tiers := [
		["comum", "COMUM"],
		["raro", "RARO"],
		["epico", "EPICO"],
		["lendario", "LENDARIO"],
	]
	var chest_buttons : Dictionary = {}
	var chest_counts : Dictionary = {}
	var card_controls : Array = []
	var chest_open_started : Dictionary = {}
	var cols : int = 2 if pw < 760.0 else 4
	var gap : float = 14.0
	var card_w : float = (pw - 56.0 - gap * float(cols - 1)) / float(cols)
	var card_h : float = 250.0 if cols == 4 else 188.0
	var start_y : float = 96.0
	for i in range(tiers.size()):
		var td : Array = tiers[i] as Array
		var tid : String = td[0] as String
		var info := _bau_info(tid)
		var cor : Color = info["cor"] as Color
		var col : int = i % cols
		var row : int = i / cols
		var x : float = 28.0 + float(col) * (card_w + gap)
		var y : float = start_y + float(row) * (card_h + gap)
		var card := Button.new()
		card.position = Vector2(x, y)
		card.size = Vector2(card_w, card_h)
		card.clip_contents = true
		card.focus_mode = Control.FOCUS_NONE
		card.add_theme_font_size_override("font_size", 15)
		card.text = ""
		var sty := StyleBoxFlat.new()
		sty.bg_color = Color(cor.r * 0.10, cor.g * 0.10, cor.b * 0.10, 0.96)
		sty.border_color = Color(cor.r, cor.g, cor.b, 0.70)
		for side in ["left","right","top","bottom"]: sty.set("border_width_" + side, 2)
		for corner in ["top_left","top_right","bottom_left","bottom_right"]: sty.set("corner_radius_" + corner, 10)
		var sty_h := sty.duplicate()
		sty_h.bg_color = Color(cor.r * 0.18, cor.g * 0.18, cor.b * 0.18, 0.98)
		card.add_theme_stylebox_override("normal", sty)
		card.add_theme_stylebox_override("hover", sty_h)
		card.add_theme_stylebox_override("pressed", sty_h)
		pnl.add_child(card)
		chest_buttons[tid] = card

		var title := _inv_lbl(card, str(info["nome"]), 8, 12, card_w - 16, 26, 22 if cols == 4 else 18,
			Color(1.0, 1.0, 1.0, 0.96), HORIZONTAL_ALIGNMENT_CENTER)
		title.add_theme_color_override("font_shadow_color", Color(0,0,0,0.85))
		title.add_theme_constant_override("shadow_offset_x", 2)
		title.add_theme_constant_override("shadow_offset_y", 2)
		_inv_lbl(card, str(info["sub"]).to_upper(), 8, 40, card_w - 16, 22, 15,
			Color(cor.r + 0.18, cor.g + 0.18, cor.b + 0.18, 0.9), HORIZONTAL_ALIGNMENT_CENTER)
		var icon := Control.new()
		icon.position = Vector2(0, 60)
		icon.size = Vector2(card_w, card_h - 120)
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		card.add_child(icon)
		icon.draw.connect(func():
			var abertura_prog : float = -1.0
			if chest_open_started.has(tid):
				abertura_prog = clampf((Time.get_ticks_msec() * 0.001 - float(chest_open_started[tid])) / 0.92, 0.0, 1.0)
			_draw_bau_icon(icon, tid, int(Salvar.baus_estoque.get(tid, 0)), abertura_prog)
		)
		card_controls.append(icon)
		var count_lbl := _inv_lbl(card, "", 8, card_h - 56, card_w - 16, 28, 24,
			Color(1.0, 0.92, 0.42), HORIZONTAL_ALIGNMENT_CENTER)
		chest_counts[tid] = count_lbl
		card.pressed.connect(func():
			chest_open_started[tid] = Time.get_ticks_msec() * 0.001
			res_lbl.text = "Abrindo %s..." % str(info["nome"])
			_build_rewards.call([])
			var r : Dictionary = Salvar.abrir_bau(tid)
			for raw_t in tiers:
				var tx : Array = raw_t as Array
				var tk : String = tx[0] as String
				var qtd : int = int(Salvar.baus_estoque.get(tk, 0))
				if chest_counts.has(tk):
					(chest_counts[tk] as Label).text = "x%d" % qtd
				if chest_buttons.has(tk):
					(chest_buttons[tk] as Button).disabled = qtd <= 0
			for cc in card_controls:
				if is_instance_valid(cc):
					(cc as Control).queue_redraw()
			if r.is_empty():
				chest_open_started.erase(tid)
				res_lbl.text = "Voce nao tem esse bau para abrir."
				_build_rewards.call([])
				return
			var recompensas_abertas : Array = r.get("recompensas", []) as Array
			get_tree().create_timer(0.62, true).timeout.connect(func():
				if is_instance_valid(ov):
					res_lbl.text = "%s aberto  |  Raridade %s" % [str(info["nome"]), str(r.get("raridade", "")).capitalize()]
					_build_rewards.call(recompensas_abertas)
			)
		)
		var qtd_ini : int = int(Salvar.baus_estoque.get(tid, 0))
		count_lbl.text = "x%d" % qtd_ini
		card.disabled = qtd_ini <= 0

	var anim := Timer.new()
	anim.wait_time = 0.033
	anim.autostart = true
	anim.timeout.connect(func():
		for c in card_controls:
			if is_instance_valid(c):
				(c as Control).queue_redraw()
	)
	ov.add_child(anim)

	var fechar := Button.new()
	fechar.text = "FECHAR"
	fechar.position = Vector2((pw - 260.0) * 0.5, ph - 58.0)
	fechar.size = Vector2(260, 42)
	fechar.focus_mode = Control.FOCUS_NONE
	fechar.add_theme_font_size_override("font_size", 18)
	fechar.pressed.connect(func():
		ov.queue_free()
		if menu_estava_visivel and _menu_contents:
			_menu_contents.show()
	)
	pnl.add_child(fechar)


func _abrir_bau_grande(ui: CanvasLayer, tier: String, ao_finalizar: Callable, preview: bool = false, recompensas_override: Array = [], titulo_override: String = "") -> void:
	var info := _bau_info(tier)
	var cor : Color = info["cor"] as Color
	var luz : Color = info["luz"] as Color
	var recompensas_raw : Array = recompensas_override
	if recompensas_raw.is_empty():
		var r : Dictionary = Salvar.abrir_bau(tier, preview)
		if r.is_empty():
			return
		recompensas_raw = r.get("recompensas", []) as Array
	Som.bau_abertura_inicio(tier)
	var recompensas : Array = _order_bau_reward_cards(recompensas_raw)
	var titulo_bau : String = titulo_override.strip_edges()
	if titulo_bau == "":
		titulo_bau = ("%s  PREVIEW" % str(info["nome"]) if preview else str(info["nome"]))
	var vp := get_viewport().get_visible_rect().size
	var ov := ColorRect.new()
	ov.color = Color(0.0, 0.0, 0.0, 0.86)
	ov.size = vp
	ov.mouse_filter = Control.MOUSE_FILTER_STOP
	ov.z_index = 90
	ui.add_child(ov)
	_bau_abertura_overlay = ov
	ov.tree_exited.connect(func():
		if _bau_abertura_overlay == ov:
			_bau_abertura_overlay = null
	)

	var bau_fullscreen_margin : float = 8.0 if minf(vp.x, vp.y) < 720.0 else 14.0
	var pw : float = maxf(360.0, vp.x - bau_fullscreen_margin * 2.0)
	var ph : float = maxf(500.0, vp.y - bau_fullscreen_margin * 2.0)
	var pnl := _inv_painel(ov, (vp.x - pw) * 0.5, (vp.y - ph) * 0.5, pw, ph,
		Color(0.018, 0.024, 0.040, 0.98), Color(cor.r, cor.g, cor.b, 0.76), 2)
	_inv_lbl(pnl, titulo_bau.to_upper(), 0, 18, pw, 36, 30,
		Color(cor.r + 0.12, cor.g + 0.12, cor.b + 0.12), HORIZONTAL_ALIGNMENT_CENTER)
	var status_lbl := _inv_lbl(pnl, "Abrindo...", 0, 56, pw, 24, 16,
		Color(0.72, 0.84, 1.0, 0.78), HORIZONTAL_ALIGNMENT_CENTER)

	var chest := Control.new()
	var chest_w : float = clampf(pw * 0.44, 420.0, 560.0)
	var chest_h : float = clampf(ph * 0.34, 270.0, 360.0)
	chest.position = Vector2((pw - chest_w) * 0.5, maxf(86.0, ph * 0.14))
	chest.size = Vector2(chest_w, chest_h)
	chest.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pnl.add_child(chest)
	var start_t : float = Time.get_ticks_msec() * 0.001
	var abertura_dur : float = 1.05
	chest.draw.connect(func():
		var now : float = Time.get_ticks_msec() * 0.001
		var prog : float = clampf((now - start_t) / abertura_dur, 0.0, 1.0)
		var pulse_open : float = sin(clampf(prog, 0.0, 1.0) * PI)
		chest.draw_circle(Vector2(chest.size.x * 0.5, chest.size.y * 0.58), 152.0 + 18.0 * pulse_open,
			Color(luz.r, luz.g, luz.b, 0.055 + 0.08 * pulse_open))
		chest.draw_arc(Vector2(chest.size.x * 0.5, chest.size.y * 0.60), 172.0, -PI * 0.08, TAU - PI * 0.08, 96,
			Color(cor.r, cor.g, cor.b, 0.22 + 0.25 * pulse_open), 2.0, true)
		_draw_bau_icon(chest, tier, 1, prog)
		if prog > 0.28:
			var burst : float = sin(clampf((prog - 0.28) / 0.52, 0.0, 1.0) * PI)
			for i in range(14):
				var a := float(i) * TAU / 14.0 + now * 0.7
				var rr := 82.0 + 80.0 * burst + float(i % 3) * 10.0
				chest.draw_circle(Vector2(chest.size.x * 0.5 + cos(a) * rr, chest.size.y * 0.45 + sin(a) * rr * 0.45),
					2.2, Color(luz.r, luz.g, luz.b, 0.44 * burst))
	)

	var rewards_cont := Control.new()
	var rewards_margin_x : float = clampf(pw * 0.045, 26.0, 64.0)
	rewards_cont.position = Vector2(rewards_margin_x, 96.0)
	rewards_cont.size = Vector2(pw - rewards_margin_x * 2.0, ph - 190.0)
	rewards_cont.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rewards_cont.visible = false
	pnl.add_child(rewards_cont)

	var btn := Button.new()
	btn.text = "CONTINUAR"
	btn.position = Vector2((pw - 280.0) * 0.5, ph - 68.0)
	btn.size = Vector2(280.0, 46.0)
	btn.visible = false
	btn.focus_mode = Control.FOCUS_NONE
	btn.add_theme_font_size_override("font_size", 18)
	pnl.add_child(btn)
	btn.pressed.connect(func():
		ov.queue_free()
		if ao_finalizar.is_valid():
			ao_finalizar.call()
	)

	var _reward_color_big := func(tipo: String) -> Color:
		match tipo:
			"ouro":
				return Color(1.0, 0.78, 0.12)
			"cristais":
				return Color(0.25, 0.95, 1.0)
			"skin":
				return Color(1.0, 0.55, 0.18)
			"pet", "pet_card":
				return Color(0.25, 0.75, 1.0)
			"habil":
				return Color(0.35, 0.95, 1.0)
			"cons":
				return Color(0.45, 1.0, 0.35)
			"bau":
				return Color(1.0, 0.72, 0.16)
			"upgrade":
				return Color(1.0, 0.78, 0.18)
			_:
				return Color(0.88, 0.88, 0.92)
	var _reward_icon_big := func(tipo: String) -> String:
		match tipo:
			"ouro":
				return "O"
			"cristais":
				return "C"
			"skin":
				return "S"
			"pet", "pet_card":
				return "A"
			"habil":
				return "H"
			"cons":
				return "+"
			"bau":
				return "B"
			"upgrade":
				return "UP"
			_:
				return "?"
	var _build_rewards_big := func() -> void:
		for old in rewards_cont.get_children():
			old.queue_free()
		var max_cards : int = 8 if rewards_cont.size.x >= 680.0 else 5
		var total : int = mini(max_cards, recompensas.size())
		if total <= 0:
			return
		status_lbl.text = "%d cartas restantes" % total
		var strip_h : float = 112.0 if rewards_cont.size.y >= 440.0 else 88.0
		var card_w : float = clampf(rewards_cont.size.x * 0.24, 150.0, 250.0)
		var card_h : float = card_w * 1.36
		var max_card_h : float = maxf(170.0, rewards_cont.size.y - strip_h - 28.0)
		if card_h > max_card_h:
			card_h = max_card_h
			card_w = card_h / 1.36
		var center_pos := Vector2((rewards_cont.size.x - card_w) * 0.5, maxf(6.0, (rewards_cont.size.y - strip_h - card_h) * 0.42))
		var collected_cont := Control.new()
		collected_cont.name = "CollectedRewardStrip"
		collected_cont.position = Vector2(0.0, rewards_cont.size.y - strip_h)
		collected_cont.size = Vector2(rewards_cont.size.x, strip_h)
		collected_cont.pivot_offset = Vector2(rewards_cont.size.x * 0.5, strip_h * 0.5)
		collected_cont.mouse_filter = Control.MOUSE_FILTER_IGNORE
		rewards_cont.add_child(collected_cont)
		var current_slot := Control.new()
		current_slot.name = "CurrentRewardSlot"
		current_slot.position = Vector2.ZERO
		current_slot.size = rewards_cont.size
		current_slot.mouse_filter = Control.MOUSE_FILTER_IGNORE
		rewards_cont.add_child(current_slot)
		var reveladas : Array = [0]
		var current_idx : Array = [0]
		var bloqueado : Array = [false]
		var current_card_ref : Array = [null]
		var spawn_current : Array = [Callable()]
		var finish_reveal : Array = [Callable()]
		var final_collected_center_y : float = clampf((rewards_cont.size.y - strip_h) * 0.58, 112.0, rewards_cont.size.y - strip_h - 6.0)
		var collected_gap : float = 10.0 if total <= 5 else 8.0
		var final_collected_base_scale : float = 1.72 if total <= 5 else (1.48 if total <= 6 else 1.30)
		var final_mini_w : float = clampf((collected_cont.size.x - collected_gap * float(maxi(total - 1, 0))) / float(total), 58.0, 90.0)
		var final_total_w : float = final_mini_w * float(total) + collected_gap * float(maxi(total - 1, 0))
		var final_collected_scale : float = minf(final_collected_base_scale, (collected_cont.size.x - 24.0) / maxf(1.0, final_total_w))
		var _preencher_frente := func(card: Panel, idx: int, item: Dictionary) -> void:
			var tipo : String = str(item.get("tipo", ""))
			var rc : Color = _reward_color_big.call(tipo) as Color
			var raridade_card : String = _reward_card_rarity(item)
			var qtd_r : int = int(item.get("qtd", 1))
			var nome_r : String = str(item.get("nome", "Item"))
			for child in card.get_children():
				(child as CanvasItem).hide()
				(child as Node).queue_free()
			var fx := Control.new()
			fx.size = Vector2(card_w, card_h)
			fx.mouse_filter = Control.MOUSE_FILTER_IGNORE
			card.add_child(fx)
			var icon_txt : String = _reward_icon_big.call(tipo) as String
			fx.draw.connect(func():
				var now : float = Time.get_ticks_msec() * 0.001
				var cx : float = card_w * 0.5
				var cy : float = card_h * 0.49
				_draw_reward_card_base(fx, Rect2(Vector2.ZERO, Vector2(card_w, card_h)), raridade_card, 0.96)
				fx.draw_rect(Rect2(20.0, 39.0, card_w - 40.0, card_h - 82.0), Color(0.0, 0.0, 0.0, 0.22), true)
				for gi in range(5, 0, -1):
					fx.draw_circle(Vector2(cx, cy), 24.0 + float(gi) * 8.0, Color(rc.r, rc.g, rc.b, 0.024 / float(gi)))
				fx.draw_arc(Vector2(cx, cy), 42.0 + sin(now * 2.4 + float(idx)) * 1.5, now * 0.55, now * 0.55 + TAU * 0.82, 58,
					Color(rc.r, rc.g, rc.b, 0.42), 1.6, true)
				if tipo == "pet" or tipo == "pet_card":
					var portrait_area := Rect2(22.0, 39.0, card_w - 44.0, card_h - 86.0)
					_draw_reward_commander_portrait(fx, item, portrait_area, 1.0)
				else:
					var icon_sz : float = 96.0 if tipo == "skin" else 84.0
					fx.draw_circle(Vector2(cx, cy), icon_sz * 0.46, Color(0.0, 0.0, 0.0, 0.40))
					if _draw_reward_item_visual(fx, item, Rect2(cx - icon_sz * 0.5, cy - icon_sz * 0.5, icon_sz, icon_sz), 1.0):
						pass
					else:
						var badge_r : float = 31.0
						fx.draw_circle(Vector2(cx, cy), badge_r + 12.0, Color(rc.r, rc.g, rc.b, 0.08))
						fx.draw_circle(Vector2(cx, cy), badge_r, Color(rc.r * 0.24, rc.g * 0.24, rc.b * 0.18, 0.92))
						fx.draw_arc(Vector2(cx, cy), badge_r, 0.0, TAU, 46, Color(rc.r, rc.g, rc.b, 0.85), 2.2, true)
						fx.draw_string(ThemeDB.fallback_font, Vector2(0.0, cy + 10.0), icon_txt, HORIZONTAL_ALIGNMENT_CENTER, card_w, 28,
							Color(1.0, 1.0, 1.0, 0.96))
				for pi in range(6):
					var a := now * 1.2 + float(pi) * TAU / 6.0
					fx.draw_circle(Vector2(cx + cos(a) * 48.0, cy + sin(a) * 31.0), 1.5,
						Color(rc.r + 0.12, rc.g + 0.12, rc.b + 0.12, 0.45))
			)
			var tipo_txt : String = tipo.capitalize()
			if tipo == "habil":
				tipo_txt = "Habilidade"
			elif tipo == "pet":
				tipo_txt = "Comandante"
			elif tipo == "pet_card":
				tipo_txt = "Cartas"
			elif tipo == "cons":
				tipo_txt = "Consumível"
			elif tipo == "bau":
				tipo_txt = "Bau"
			_inv_lbl(card, tipo_txt.to_upper(), 8.0, 14.0, card_w - 16.0, 18.0, 11,
				Color(rc.r + 0.18, rc.g + 0.18, rc.b + 0.18, 0.86), HORIZONTAL_ALIGNMENT_CENTER)
			var nome_lbl := _inv_lbl(card, nome_r, 10.0, card_h - 66.0, card_w - 20.0, 34.0, 13,
				Color(0.94, 0.96, 1.0), HORIZONTAL_ALIGNMENT_CENTER)
			nome_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD
			_inv_lbl(card, "x%d" % qtd_r, 0.0, card_h - 31.0, card_w, 22.0, 18,
				Color(rc.r + 0.2, rc.g + 0.2, rc.b + 0.2, 0.95), HORIZONTAL_ALIGNMENT_CENTER)

		var _add_collected_card := func(item: Dictionary, idx: int) -> void:
			var tipo : String = str(item.get("tipo", ""))
			var rc : Color = _reward_color_big.call(tipo) as Color
			var raridade_card : String = _reward_card_rarity(item)
			var count : int = int(collected_cont.get_child_count())
			var gap_m : float = collected_gap
			var mini_w : float = final_mini_w
			var mini_h : float = mini_w * 1.22
			var total_w_m : float = mini_w * float(total) + gap_m * float(maxi(total - 1, 0))
			var start_x_m : float = (collected_cont.size.x - total_w_m) * 0.5
			var mini := _inv_painel(collected_cont, start_x_m + float(count) * (mini_w + gap_m), strip_h - mini_h - 5.0, mini_w, mini_h,
				Color(rc.r * 0.04, rc.g * 0.04, rc.b * 0.06, 0.98), Color(rc.r, rc.g, rc.b, 0.82), 2)
			mini.add_theme_stylebox_override("panel", StyleBoxEmpty.new())
			mini.modulate.a = 0.0
			mini.scale = Vector2(0.70, 0.70)
			mini.pivot_offset = Vector2(mini_w * 0.5, mini_h * 0.5)
			var nome_m : String = str(item.get("nome", "Item"))
			var qtd_m : int = int(item.get("qtd", 1))
			var fx_m := Control.new()
			fx_m.size = Vector2(mini_w, mini_h)
			fx_m.mouse_filter = Control.MOUSE_FILTER_IGNORE
			mini.add_child(fx_m)
			fx_m.draw.connect(func():
				_draw_reward_card_base(fx_m, Rect2(Vector2.ZERO, Vector2(mini_w, mini_h)), raridade_card, 0.88)
				var cx : float = mini_w * 0.5
				var cy : float = mini_h * 0.48
				if tipo == "pet" or tipo == "pet_card":
					var portrait_area := Rect2(mini_w * 0.115, mini_h * 0.115, mini_w * 0.77, mini_h * 0.64)
					_draw_reward_commander_portrait(fx_m, item, portrait_area, 1.0)
				else:
					fx_m.draw_circle(Vector2(cx, cy), mini_w * 0.26, Color(rc.r, rc.g, rc.b, 0.18))
					fx_m.draw_arc(Vector2(cx, cy), mini_w * 0.28, 0.0, TAU, 42, Color(rc.r, rc.g, rc.b, 0.78), 1.5, true)
					var mini_icon := Rect2(cx - mini_w * 0.27, cy - mini_w * 0.27, mini_w * 0.54, mini_w * 0.54)
					if _draw_reward_item_visual(fx_m, item, mini_icon, 1.0):
						pass
					else:
						fx_m.draw_string(ThemeDB.fallback_font, Vector2(0.0, cy + 7.0), _reward_icon_big.call(tipo) as String,
							HORIZONTAL_ALIGNMENT_CENTER, mini_w, 20.0, Color.WHITE)
			)
			var short_name : String = nome_m
			if short_name.length() > 9:
				short_name = short_name.substr(0, 8) + "."
			_inv_lbl(mini, short_name, 4.0, mini_h - 23.0, mini_w - 8.0, 13.0, 8,
				Color(0.92, 0.94, 1.0, 0.88), HORIZONTAL_ALIGNMENT_CENTER)
			_inv_lbl(mini, "x%d" % qtd_m, 0.0, mini_h - 13.0, mini_w, 12.0, 9,
				Color(rc.r + 0.18, rc.g + 0.18, rc.b + 0.18, 0.96), HORIZONTAL_ALIGNMENT_CENTER)
			var pop := create_tween()
			pop.set_parallel(true)
			pop.tween_property(mini, "modulate:a", 1.0, 0.12)
			pop.tween_property(mini, "scale", Vector2(1.0, 1.0), 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

		var _criar_verso := func(card: Panel, idx: int, item: Dictionary, tap_cb: Callable) -> void:
			var tipo : String = str(item.get("tipo", ""))
			var rc : Color = _reward_color_big.call(tipo) as Color
			var raridade_card : String = _reward_card_rarity(item)
			var fx := Control.new()
			fx.size = Vector2(card_w, card_h)
			fx.mouse_filter = Control.MOUSE_FILTER_IGNORE
			card.add_child(fx)
			fx.draw.connect(func():
				var now : float = Time.get_ticks_msec() * 0.001
				var cx : float = card_w * 0.5
				var cy : float = card_h * 0.48
				_draw_reward_card_base(fx, Rect2(Vector2.ZERO, Vector2(card_w, card_h)), raridade_card, 0.90)
				fx.draw_rect(Rect2(18.0, 35.0, card_w - 36.0, card_h - 72.0), Color(0.0, 0.0, 0.0, 0.42), true)
				for gi in range(4, 0, -1):
					fx.draw_circle(Vector2(cx, cy), 28.0 + float(gi) * 15.0, Color(rc.r, rc.g, rc.b, 0.030 / float(gi)))
				var diamond := PackedVector2Array([
					Vector2(cx, cy - 45.0),
					Vector2(cx + 38.0, cy),
					Vector2(cx, cy + 45.0),
					Vector2(cx - 38.0, cy),
				])
				fx.draw_polygon(diamond, PackedColorArray([
					Color(rc.r * 0.12, rc.g * 0.12, rc.b * 0.12, 0.92),
					Color(rc.r * 0.08, rc.g * 0.08, rc.b * 0.08, 0.92),
					Color(rc.r * 0.04, rc.g * 0.04, rc.b * 0.04, 0.92),
					Color(rc.r * 0.08, rc.g * 0.08, rc.b * 0.08, 0.92),
				]))
				fx.draw_polyline(PackedVector2Array([diamond[0], diamond[1], diamond[2], diamond[3], diamond[0]]),
					Color(rc.r, rc.g, rc.b, 0.92), 2.2, true)
				fx.draw_arc(Vector2(cx, cy), 56.0 + sin(now * 2.2 + float(idx)) * 2.0, now * 0.7, now * 0.7 + TAU * 0.78, 72,
					Color(rc.r + 0.16, rc.g + 0.16, rc.b + 0.16, 0.58), 1.8, true)
				fx.draw_arc(Vector2(cx, cy), 68.0, -now * 0.45, -now * 0.45 + TAU * 0.52, 72,
					Color(1.0, 1.0, 1.0, 0.18), 1.0, true)
				fx.draw_rect(Rect2(4.0, 4.0, card_w - 8.0, card_h - 8.0),
					Color(rc.r + 0.18, rc.g + 0.18, rc.b + 0.18, 0.48 + 0.16 * sin(now * 5.0)), false, 2.0)
				fx.draw_string(ThemeDB.fallback_font, Vector2(0.0, cy + 10.0), "?", HORIZONTAL_ALIGNMENT_CENTER, card_w, 42,
					Color(1.0, 1.0, 1.0, 0.92))
				for pi in range(7):
					var a := now * 1.5 + float(pi) * TAU / 7.0
					fx.draw_circle(Vector2(cx + cos(a) * 52.0, cy + sin(a) * 36.0), 1.5,
						Color(rc.r + 0.12, rc.g + 0.12, rc.b + 0.12, 0.44))
			)
			_inv_lbl(card, "CARTA", 8.0, 16.0, card_w - 16.0, 18.0, 12,
				Color(rc.r + 0.20, rc.g + 0.20, rc.b + 0.20, 0.86), HORIZONTAL_ALIGNMENT_CENTER)
			_inv_lbl(card, "TOQUE", 8.0, card_h - 35.0, card_w - 16.0, 18.0, 12,
				Color(0.86, 0.90, 1.0, 0.82), HORIZONTAL_ALIGNMENT_CENTER)
			var tap := Button.new()
			tap.position = Vector2.ZERO
			tap.size = Vector2(card_w, card_h)
			tap.text = ""
			tap.focus_mode = Control.FOCUS_NONE
			var empty_style := StyleBoxEmpty.new()
			for key in ["normal", "hover", "pressed", "disabled", "focus", "hover_pressed"]:
				tap.add_theme_stylebox_override(key, empty_style)
			card.add_child(tap)
			tap.pressed.connect(func():
				if bool(card.get_meta("revelada", false)):
					return
				if bool(bloqueado[0]):
					return
				if tap_cb.is_valid():
					tap_cb.call()
			)

		finish_reveal[0] = func(card: Panel, item: Dictionary, idx: int) -> void:
			var remaining_before : int = total - int(current_idx[0])
			status_lbl.text = "%d cartas restantes" % maxi(remaining_before - 1, 0)
			var fly := create_tween()
			fly.set_parallel(true)
			fly.tween_property(card, "position", Vector2(center_pos.x, rewards_cont.size.y - strip_h - card_h * 0.28), 0.18).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
			fly.tween_property(card, "scale", Vector2(0.28, 0.28), 0.18).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
			fly.tween_property(card, "modulate:a", 0.0, 0.14)
			fly.set_parallel(false)
			fly.tween_callback(func():
				if is_instance_valid(card):
					card.queue_free()
				_add_collected_card.call(item, idx)
				reveladas[0] = int(reveladas[0]) + 1
				current_idx[0] = int(current_idx[0]) + 1
				bloqueado[0] = false
				if int(current_idx[0]) >= total:
					status_lbl.text = "%s  |  recompensas coletadas" % titulo_bau
					collected_cont.set_meta("final_collected_center", true)
					var center_tw := create_tween()
					center_tw.set_parallel(true)
					center_tw.tween_property(collected_cont, "position:y", final_collected_center_y, 0.32).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
					center_tw.tween_property(collected_cont, "scale", Vector2(final_collected_scale * 1.06, final_collected_scale * 1.06), 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
					center_tw.set_parallel(false)
					center_tw.tween_property(collected_cont, "scale", Vector2(final_collected_scale, final_collected_scale), 0.14).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
					center_tw.tween_callback(func():
						btn.visible = true
					)
				else:
					(spawn_current[0] as Callable).call()
			)

		var _reveal_current := func(card: Panel, idx: int, item: Dictionary) -> void:
			if bool(bloqueado[0]) or bool(card.get_meta("revelada", false)):
				return
			bloqueado[0] = true
			card.set_meta("revelada", true)
			var tipo : String = str(item.get("tipo", ""))
			Som.bau_carta_revelar(tipo)
			var special_item : bool = _is_reward_showcase_item(item)
			var base_rot : float = card.rotation_degrees
			var flip := create_tween()
			flip.set_parallel(true)
			flip.tween_property(card, "scale", Vector2(0.04, 1.10), 0.12).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
			flip.tween_property(card, "rotation_degrees", base_rot + 178.0, 0.12).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
			flip.set_parallel(false)
			flip.tween_callback(func():
				if is_instance_valid(card) and not special_item:
					_preencher_frente.call(card, idx, item)
			)
			flip.set_parallel(true)
			flip.tween_property(card, "scale", Vector2(1.12, 1.08), 0.14).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
			flip.tween_property(card, "rotation_degrees", base_rot + 360.0, 0.14).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
			flip.set_parallel(false)
			flip.tween_property(card, "scale", Vector2(1.0, 1.0), 0.10).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
			flip.parallel().tween_property(card, "rotation_degrees", base_rot, 0.10).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
			flip.set_parallel(false)
			flip.tween_callback(func():
				if special_item:
					_show_reward_special_overlay(ov, item, func():
						if is_instance_valid(card):
							_preencher_frente.call(card, idx, item)
						(finish_reveal[0] as Callable).call(card, item, idx)
					, preview)
				else:
					(finish_reveal[0] as Callable).call(card, item, idx)
			)

		spawn_current[0] = func() -> void:
			for child in current_slot.get_children():
				child.queue_free()
			var idx : int = int(current_idx[0])
			if idx >= total:
				return
			bloqueado[0] = true
			var item_c : Dictionary = recompensas[idx] as Dictionary
			var tipo_c : String = str(item_c.get("tipo", ""))
			var rc_c : Color = _reward_color_big.call(tipo_c) as Color
			status_lbl.text = "%d/%d cartas restantes" % [total - idx, total]
			var card := _inv_painel(current_slot, center_pos.x, center_pos.y, card_w, card_h,
				Color(rc_c.r * 0.05, rc_c.g * 0.05, rc_c.b * 0.07, 0.98), Color(rc_c.r, rc_c.g, rc_c.b, 0.84), 3)
			card.name = "CurrentRewardCard"
			card.add_theme_stylebox_override("panel", StyleBoxEmpty.new())
			card.pivot_offset = Vector2(card_w * 0.5, card_h * 0.5)
			card.position = center_pos + Vector2(0.0, -28.0)
			card.scale = Vector2(0.22, 0.22)
			card.rotation_degrees = -7.0
			card.modulate.a = 0.0
			card.set_meta("revelada", false)
			current_card_ref[0] = card
			_criar_verso.call(card, idx, item_c, func():
				_reveal_current.call(card, idx, item_c)
			)
			var tw := create_tween()
			tw.set_parallel(true)
			tw.tween_property(card, "position", center_pos, 0.28).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
			tw.tween_property(card, "scale", Vector2(1.0, 1.0), 0.30).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
			tw.tween_property(card, "rotation_degrees", 0.0, 0.26).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
			tw.tween_property(card, "modulate:a", 1.0, 0.12)
			tw.set_parallel(false)
			tw.tween_callback(func():
				bloqueado[0] = false
			)

		(spawn_current[0] as Callable).call()

	var anim := Timer.new()
	anim.wait_time = 0.033
	anim.autostart = true
	anim.timeout.connect(func():
		if is_instance_valid(chest):
			chest.queue_redraw()
		if is_instance_valid(rewards_cont):
			for card_raw in rewards_cont.get_children():
				if card_raw is Control:
					var card_ctrl := card_raw as Control
					card_ctrl.queue_redraw()
					for child_raw in card_ctrl.get_children():
						if child_raw is Control:
							(child_raw as Control).queue_redraw()
	)
	ov.add_child(anim)
	get_tree().create_timer(abertura_dur + 0.16, true).timeout.connect(func():
		if is_instance_valid(ov):
			status_lbl.text = "Toque na carta para revelar."
			Som.bau_abertura_final(tier)
			if is_instance_valid(chest):
				chest.hide()
			rewards_cont.visible = true
			_build_rewards_big.call()
	)


func _abrir_mapas(ui: CanvasLayer) -> void:
	if _menu_contents:
		_menu_contents.hide()
	if _mapas_overlay and is_instance_valid(_mapas_overlay):
		_mapas_overlay.queue_free()
	var vp := get_viewport().get_visible_rect().size
	var ov := ColorRect.new()
	ov.color = Color(0.0, 0.0, 0.0, 0.90)
	ov.size = vp
	ov.mouse_filter = Control.MOUSE_FILTER_STOP
	ui.add_child(ov)
	_mapas_overlay = ov

	var mapa_bg_info : Dictionary = Salvar.mapa_teste_info()
	var mapa_fundo := Control.new()
	mapa_fundo.name = "MapasFundo"
	mapa_fundo.position = Vector2.ZERO
	mapa_fundo.size = vp
	mapa_fundo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	mapa_fundo.set_meta("mapa_bg_path", str(mapa_bg_info.get("bg", "")))
	mapa_fundo.draw.connect(func():
		_draw_menu_mapa_fundo(mapa_fundo, Rect2(Vector2.ZERO, mapa_fundo.size), mapa_bg_info)
		mapa_fundo.draw_rect(Rect2(Vector2.ZERO, mapa_fundo.size), Color(0.0, 0.0, 0.0, 0.34), true)
		var cor_bg : Color = mapa_bg_info.get("cor", Color(0.0, 0.72, 1.0)) as Color
		mapa_fundo.draw_rect(Rect2(Vector2.ZERO, mapa_fundo.size), Color(cor_bg.r, cor_bg.g, cor_bg.b, 0.08), true)
	)
	ov.add_child(mapa_fundo)

	var pw : float = minf(1040.0, vp.x - 36.0)
	var ph : float = minf(860.0, vp.y - 20.0)
	var px : float = (vp.x - pw) * 0.5
	var py : float = (vp.y - ph) * 0.5
	var pnl := _inv_painel(ov, px, py, pw, ph, Color(0.025, 0.035, 0.06, 0.98), Color(0.0, 0.95, 0.85, 0.62), 2)
	_inv_lbl(pnl, "MAPAS DA TORRE", 0, 18, pw, 36, 28, Color(0.55, 1.0, 0.92), HORIZONTAL_ALIGNMENT_CENTER)
	_inv_lbl(pnl, "Todos liberados para teste enquanto os modelos estao em criacao.", 36, 56, pw - 72, 24, 15, Color(0.62, 0.76, 0.82), HORIZONTAL_ALIGNMENT_CENTER)

	var cols : int = 2 if pw < 760.0 else 3
	var gap : float = 14.0
	var card_w : float = (pw - 56.0 - gap * float(cols - 1)) / float(cols)
	var card_h : float = 132.0
	var start_y : float = 98.0
	for i in range(Salvar.MAPAS_TORRE.size()):
		var mapa : Dictionary = Salvar.MAPAS_TORRE[i] as Dictionary
		var col : int = i % cols
		var row : int = i / cols
		var pos := Vector2(28.0 + float(col) * (card_w + gap), start_y + float(row) * (card_h + gap))
		var cor : Color = mapa.get("cor", Color(0.0, 0.72, 1.0)) as Color
		var ativo : bool = str(mapa.get("id", "")) == Salvar.mapa_teste_id
		var card := Button.new()
		card.position = pos
		card.size = Vector2(card_w, card_h)
		card.focus_mode = Control.FOCUS_NONE
		card.text = ""
		var sty := StyleBoxFlat.new()
		sty.bg_color = Color(cor.r * 0.10, cor.g * 0.10, cor.b * 0.12, 0.94)
		sty.border_color = Color(cor.r, cor.g, cor.b, 1.0 if ativo else 0.48)
		for side in ["left", "right", "top", "bottom"]:
			sty.set("border_width_" + side, 3 if ativo else 1)
		for corner in ["top_left", "top_right", "bottom_left", "bottom_right"]:
			sty.set("corner_radius_" + corner, 8)
		card.add_theme_stylebox_override("normal", sty)
		card.add_theme_stylebox_override("hover", sty)
		pnl.add_child(card)

		_inv_lbl(card, str(mapa.get("nome", "Mapa")), 12, 10, card_w - 24, 24, 18, Color(cor.r + 0.18, cor.g + 0.18, cor.b + 0.18), HORIZONTAL_ALIGNMENT_LEFT)
		_inv_lbl(card, str(mapa.get("faixa", "")), card_w - 126, 12, 112, 22, 13, Color(1.0, 0.86, 0.25), HORIZONTAL_ALIGNMENT_RIGHT)
		_inv_lbl(card, str(mapa.get("tema", "")), 12, 38, card_w - 24, 20, 13, Color(0.74, 0.86, 0.92), HORIZONTAL_ALIGNMENT_LEFT)
		var desc := _inv_lbl(card, str(mapa.get("desc", "")), 12, 63, card_w - 24, 38, 12, Color(0.58, 0.66, 0.74), HORIZONTAL_ALIGNMENT_LEFT)
		desc.autowrap_mode = TextServer.AUTOWRAP_WORD
		var mult_txt := "Mobs %.2fx  HP %.2fx  Vel %.2fx" % [float(mapa.get("mob_mult", 1.0)), float(mapa.get("hp_mult", 1.0)), float(mapa.get("speed_mult", 1.0))]
		_inv_lbl(card, mult_txt, 12, 105, card_w - 24, 18, 11, Color(0.88, 0.78, 0.55), HORIZONTAL_ALIGNMENT_LEFT)
		if ativo:
			_inv_lbl(card, "SELECIONADO", card_w - 118, 105, 104, 18, 11, Color(0.35, 1.0, 0.55), HORIZONTAL_ALIGNMENT_RIGHT)
		var mid : String = str(mapa.get("id", "setor_inicial"))
		card.pressed.connect(func():
			Salvar.mapa_teste_id = mid
			Salvar.salvar()
			ov.queue_free()
			if _mapas_overlay == ov:
				_mapas_overlay = null
			if _menu_contents:
				_menu_contents.show()
			_abrir_mapas(ui)
		)

	# â”€â”€ ComparaÃ§Ã£o de mÃ©todos de sprite â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
	var rows_used  : int   = (Salvar.MAPAS_TORRE.size() + cols - 1) / cols
	var amostras_y : float = start_y + float(rows_used) * (card_h + gap) + 14.0

	_inv_lbl(pnl, "COMPARAÃ‡ÃƒO DE MÃ‰TODOS DE GERAÃ‡ÃƒO DE SPRITE", 0, amostras_y, pw, 22, 14,
		Color(0.55, 1.0, 0.92), HORIZONTAL_ALIGNMENT_CENTER)

	# Colunas: cada mÃ©todo. Linhas: nave tipo.
	# MÃ©todos: ChatGPT | Python Skia | Node.js Canvas | Python aggdraw
	var metodos := ["ChatGPT\n(IA)", "Python\nSkia", "Node.js\nCanvas", "Python\naggdraw"]
	var cores_metodo := [Color(1.0,0.85,0.2), Color(0.2,0.9,0.4), Color(0.3,0.7,1.0), Color(0.8,0.5,1.0)]

	var naves_rows := [
		["Nave/Interceptador",
			"res://assets/sprites/amostras/chatgpt_nave.png",
			"res://assets/sprites/amostras/skia_interceptador.png",
			"res://assets/sprites/amostras/canvas_interceptador.png",
			"res://assets/sprites/amostras/amostra_interceptador.png"],
		["Kamikaze",
			"res://assets/sprites/amostras/chatgpt_kamikaze.png",
			"res://assets/sprites/amostras/skia_kamikaze.png",
			"res://assets/sprites/amostras/canvas_kamikaze.png",
			"res://assets/sprites/amostras/amostra_kamikaze.png"],
		["Boss",
			"res://assets/sprites/amostras/chatgpt_boss.png",
			"res://assets/sprites/amostras/skia_boss.png",
			"res://assets/sprites/amostras/canvas_boss.png",
			"res://assets/sprites/amostras/amostra_boss.png"],
	]

	var sz_s   : float = 72.0
	var gap_s  : float = 8.0
	var col_w  : float = sz_s + gap_s
	var row_h  : float = sz_s + 24.0
	# Calcular x de inicio centrado
	var label_w : float = 88.0
	var total_cols_w : float = label_w + float(metodos.size()) * col_w
	var sx0 : float = (pw - total_cols_w) * 0.5
	var sy0 : float = amostras_y + 30.0

	# CabeÃ§alhos de mÃ©todo
	for mi in range(metodos.size()):
		var hx : float = sx0 + label_w + float(mi) * col_w
		var header := Panel.new()
		header.position = Vector2(hx, sy0)
		header.size     = Vector2(sz_s, 32)
		var hs := StyleBoxFlat.new()
		hs.bg_color     = Color(cores_metodo[mi].r*0.15, cores_metodo[mi].g*0.15, cores_metodo[mi].b*0.15, 0.85)
		hs.border_color = Color(cores_metodo[mi].r, cores_metodo[mi].g, cores_metodo[mi].b, 0.6)
		for side in ["left","right","top","bottom"]: hs.set("border_width_"+side, 1)
		for corner in ["top_left","top_right","bottom_left","bottom_right"]: hs.set("corner_radius_"+corner, 4)
		header.add_theme_stylebox_override("panel", hs)
		pnl.add_child(header)
		_inv_lbl(header, metodos[mi], 0, 2, sz_s, 28, 9, cores_metodo[mi], HORIZONTAL_ALIGNMENT_CENTER)

	# Linhas por tipo de nave
	for ri in range(naves_rows.size()):
		var row_data : Array = naves_rows[ri]
		var nave_nome : String = row_data[0]
		var ry : float = sy0 + 38.0 + float(ri) * row_h

		# Label da nave
		_inv_lbl(pnl, nave_nome, sx0, ry + sz_s * 0.5 - 8, label_w - 4, 18, 11,
			Color(0.78, 0.88, 0.96), HORIZONTAL_ALIGNMENT_RIGHT)

		# Cards de sprite por mÃ©todo
		for mi in range(metodos.size()):
			var sx : float = sx0 + label_w + float(mi) * col_w
			var scard := Panel.new()
			scard.position = Vector2(sx, ry)
			scard.size     = Vector2(sz_s, sz_s + 16)
			var sty_s := StyleBoxFlat.new()
			sty_s.bg_color     = Color(0.03, 0.05, 0.08, 0.9)
			sty_s.border_color = Color(cores_metodo[mi].r, cores_metodo[mi].g, cores_metodo[mi].b, 0.3)
			for side in ["left","right","top","bottom"]: sty_s.set("border_width_"+side, 1)
			for corner in ["top_left","top_right","bottom_left","bottom_right"]: sty_s.set("corner_radius_"+corner, 4)
			scard.add_theme_stylebox_override("panel", sty_s)
			pnl.add_child(scard)

			var arq : String = row_data[mi + 1]
			if ResourceLoader.exists(arq):
				var tex := load(arq) as Texture2D
				var tr := TextureRect.new()
				tr.texture      = tex
				tr.position     = Vector2(3, 2)
				tr.size         = Vector2(sz_s - 6, sz_s - 4)
				tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
				tr.expand_mode  = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
				scard.add_child(tr)
			else:
				_inv_lbl(scard, "N/A", 0, sz_s*0.4, sz_s, 18, 10, Color(0.5,0.5,0.5), HORIZONTAL_ALIGNMENT_CENTER)

	# â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
	var fechar := Button.new()
	fechar.text = "FECHAR"
	fechar.position = Vector2((pw - 240.0) * 0.5, ph - 66.0)
	fechar.size = Vector2(240, 44)
	fechar.focus_mode = Control.FOCUS_NONE
	fechar.add_theme_font_size_override("font_size", 18)
	fechar.pressed.connect(func():
		ov.queue_free()
		if _mapas_overlay == ov:
			_mapas_overlay = null
		if _menu_contents:
			_menu_contents.show()
	)
	pnl.add_child(fechar)


func _perfil_cor() -> Color:
	var nome: String = Salvar.nome_jogador
	if nome == "":
		return Color(0.35, 0.4, 0.5)
	var h: int = 0
	for i in range(nome.length()):
		h = (h * 31 + nome.unicode_at(i)) & 16777215
	return Color.from_hsv(float(h & 255) / 255.0, 0.65, 0.9)


func _perfil_iniciais() -> String:
	var nome: String = Salvar.nome_jogador.strip_edges()
	if nome == "":
		return "?"
	var partes:= nome.split(" ", false)
	if partes.size() >= 2:
		return (partes[0].left(1) + partes[1].left(1)).to_upper()
	return nome.left(2).to_upper()


func _perfil_nome_curto() -> String:
	var nome: String = Salvar.nome_jogador.strip_edges()
	if nome == "":
		return "sem nome"
	return nome.left(12) + ("â€¦" if nome.length() > 12 else "")


const _AVATAR_NOMES:= ["Iniciais", "Torre", "Berserker", "Raio", "Boss"]
const _AVATAR_CORES:= [
	Color(0.5, 0.6, 0.8), 
	Color(0.0, 0.72, 1.0), 
	Color(1.0, 0.08, 0.55), 
	Color(0.25, 0.95, 1.0), 
	Color(0.8, 0.18, 0.05), 
]


func _draw_avatar_icone(c: Control, cx: float, cy: float, r: float, idx: int) -> void :
	var cor: Color = _AVATAR_CORES[idx] if idx < _AVATAR_CORES.size() else Color(0.6, 0.6, 0.6)
	match idx:
		0:
			var font: Font = ThemeDB.fallback_font
			if font == null:
				c.draw_circle(Vector2(cx, cy), r * 0.35, Color(cor.r, cor.g, cor.b, 0.8))
				return
			var txt: String = _perfil_iniciais()
			var fs: int = int(r * 0.9) if txt.length() == 1 else int(r * 0.65)
			var tw: float = font.get_string_size(txt, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
			c.draw_string(font, Vector2(cx - tw * 0.5, cy + float(fs) * 0.36), 
				txt, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, 
				Color(cor.r + 0.25, cor.g + 0.25, cor.b + 0.25, 1.0))
		1:
			var pts:= PackedVector2Array()
			for i in range(6):
				var a:= float(i) * TAU / 6.0 + PI / 6.0
				pts.append(Vector2(cx + cos(a) * r * 0.68, cy + sin(a) * r * 0.68))
			c.draw_polygon(pts, _cores(pts.size(), Color(0.02, 0.08, 0.2, 0.92)))
			var borda:= PackedVector2Array(pts);borda.append(pts[0])
			c.draw_polyline(borda, Color(cor.r, cor.g, cor.b, 0.95), r * 0.12)
			c.draw_circle(Vector2(cx, cy), r * 0.22, Color(cor.r + 0.2, cor.g + 0.2, cor.b, 0.95))

			var cdir:= Vector2(0.7, -0.7)
			var clat:= cdir.rotated(PI * 0.5) * r * 0.12
			var ctip:= Vector2(cx, cy) + cdir * r * 0.72
			var gun:= PackedVector2Array([
				Vector2(cx, cy) - clat, Vector2(cx, cy) + clat, 
				ctip + clat * 0.4, ctip - clat * 0.4, 
			])
			c.draw_polygon(gun, _cores(gun.size(), Color(cor.r, cor.g, cor.b, 0.9)))
		2:
			var star_pts:= PackedVector2Array()
			for i in range(16):
				var a:= float(i) * TAU / 16.0 - PI * 0.5
				var rad:= r * (0.68 if i % 2 == 0 else 0.3)
				star_pts.append(Vector2(cx + cos(a) * rad, cy + sin(a) * rad))
			c.draw_polygon(star_pts, _cores(star_pts.size(), Color(cor.r * 0.3, cor.g * 0.1, cor.b * 0.2, 0.92)))
			var star_b:= PackedVector2Array(star_pts);star_b.append(star_pts[0])
			c.draw_polyline(star_b, Color(cor.r, cor.g, cor.b, 0.95), r * 0.08)
			c.draw_circle(Vector2(cx, cy), r * 0.18, Color(1.0, 0.5, 0.7, 0.9))

			for i in range(4):
				var ea:= float(i) * TAU / 4.0 + PI * 0.25
				c.draw_line(
					Vector2(cx + cos(ea) * r * 0.72, cy + sin(ea) * r * 0.72), 
					Vector2(cx + cos(ea) * r * 0.9, cy + sin(ea) * r * 0.9), 
					Color(1.0, 0.6, 0.1, 0.7), r * 0.1)
		3:
			var bolt:= PackedVector2Array([
				Vector2(cx + r * 0.1, cy - r * 0.72), 
				Vector2(cx - r * 0.12, cy - r * 0.05), 
				Vector2(cx + r * 0.2, cy - r * 0.05), 
				Vector2(cx - r * 0.1, cy + r * 0.72), 
				Vector2(cx + r * 0.08, cy + r * 0.08), 
				Vector2(cx - r * 0.18, cy + r * 0.08), 
			])

			for gi in range(3, 0, -1):
				c.draw_polygon(bolt, _cores(bolt.size(), 
					Color(cor.r, cor.g, cor.b, 0.08 * float(gi))))
			c.draw_polygon(bolt, _cores(bolt.size(), Color(cor.r * 0.2, cor.g * 0.5, cor.b * 0.7, 0.92)))
			var bolt_b:= PackedVector2Array(bolt);bolt_b.append(bolt[0])
			c.draw_polyline(bolt_b, Color(cor.r, cor.g, cor.b, 0.95), r * 0.09)
			c.draw_polyline(bolt_b, Color(1.0, 1.0, 1.0, 0.45), r * 0.04)

			for i in range(5):
				var sa:= float(i) * TAU / 5.0
				c.draw_circle(
					Vector2(cx + cos(sa) * r * 0.55, cy + sin(sa) * r * 0.55), 
					r * 0.06, Color(cor.r, cor.g, cor.b, 0.6))
		4:
			var bpts:= PackedVector2Array()
			for i in range(6):
				var a:= float(i) * TAU / 6.0
				bpts.append(Vector2(cx + cos(a) * r * 0.58, cy + sin(a) * r * 0.58))
			c.draw_polygon(bpts, _cores(bpts.size(), Color(0.12, 0.02, 0.02, 0.92)))
			var bptb:= PackedVector2Array(bpts);bptb.append(bpts[0])
			c.draw_polyline(bptb, Color(cor.r, cor.g, cor.b, 0.9), r * 0.1)

			for i in range(6):
				var a1:= float(i) * TAU / 6.0
				var a2:= a1 + TAU / 12.0
				var p1:= Vector2(cx + cos(a1) * r * 0.58, cy + sin(a1) * r * 0.58)
				var p2:= Vector2(cx + cos(a2) * r * 0.82, cy + sin(a2) * r * 0.82)
				var p3:= Vector2(cx + cos(a1 + TAU / 6.0) * r * 0.58, cy + sin(a1 + TAU / 6.0) * r * 0.58)
				var sp:= PackedVector2Array([p1, p2, p3])
				c.draw_polygon(sp, _cores(3, Color(cor.r * 0.4, cor.g * 0.1, 0.0, 0.85)))
				c.draw_polyline(PackedVector2Array([p1, p2, p3]), Color(cor.r, cor.g * 0.5, 0.0, 0.8), r * 0.07)

			c.draw_circle(Vector2(cx - r * 0.2, cy - r * 0.08), r * 0.1, Color(1.0, 0.2, 0.0, 0.9))
			c.draw_circle(Vector2(cx + r * 0.2, cy - r * 0.08), r * 0.1, Color(1.0, 0.2, 0.0, 0.9))
			c.draw_circle(Vector2(cx, cy + r * 0.2), r * 0.07, Color(0.8, 0.1, 0.0, 0.7))


func _on_perfil_draw(c: Control) -> void :
	var idx: int = Salvar.avatar_idx
	var cor: Color = _AVATAR_CORES[idx] if idx < _AVATAR_CORES.size() else _perfil_cor()
	var w: float = c.size.x
	var h: float = c.size.y
	if w > 60.0 and h <= 52.0:
		var pp_wide: float = sin(pulse * 1.1) * 0.15 + 0.85
		var cut_wide: float = 10.0
		var chip := PackedVector2Array([
			Vector2(cut_wide, 0.0), Vector2(w - cut_wide, 0.0), Vector2(w, cut_wide),
			Vector2(w, h - cut_wide), Vector2(w - cut_wide, h), Vector2(cut_wide, h),
			Vector2(0.0, h - cut_wide), Vector2(0.0, cut_wide)
		])
		var chip_fill := PackedColorArray()
		for _ci in range(chip.size()):
			chip_fill.append(Color(0.018, 0.032, 0.052, 0.70))
		c.draw_polygon(chip, chip_fill)
		c.draw_polyline(chip + PackedVector2Array([chip[0]]), Color(cor.r, cor.g, cor.b, 0.58), 1.5)
		c.draw_line(Vector2(54.0, 9.0), Vector2(w - 18.0, 9.0), Color(cor.r, cor.g, cor.b, 0.18), 1.0)
		c.draw_line(Vector2(54.0, h - 9.0), Vector2(w - 34.0, h - 9.0), Color(cor.r, cor.g, cor.b, 0.13), 1.0)
		var c_wide := Vector2(24.0, h * 0.5)
		var r_wide := 17.5
		for wi in range(3, 0, -1):
			c.draw_circle(c_wide, r_wide + float(wi) * 3.0, Color(cor.r, cor.g, cor.b, 0.045 * pp_wide / float(wi)))
		c.draw_circle(c_wide, r_wide, Color(0.04, 0.06, 0.1, 0.96))
		c.draw_arc(c_wide, r_wide, 0.0, TAU, 56, Color(cor.r, cor.g, cor.b, 0.9 * pp_wide), 2.0)
		_draw_avatar_icone(c, c_wide.x, c_wide.y, r_wide * 0.82, idx)
		var edit_wide := c_wide + Vector2(r_wide * 0.64, r_wide * 0.64)
		c.draw_circle(edit_wide, 5.0, Color(0.06, 0.08, 0.12, 0.95))
		c.draw_arc(edit_wide, 5.0, 0.0, TAU, 20, Color(cor.r, cor.g, cor.b, 0.72 * pp_wide), 1.1)
		c.draw_line(edit_wide + Vector2(-2.2, 2.0), edit_wide + Vector2(2.2, -2.0), Color(cor.r + 0.2, cor.g + 0.2, cor.b + 0.2, 0.9 * pp_wide), 1.2)
		return

	if w <= 60.0:
		var cc := Vector2(w * 0.5, h * 0.5)
		var rr := minf(w, h) * 0.40
		var pp: float = sin(pulse * 1.1) * 0.15 + 0.85
		for gi in range(3, 0, -1):
			c.draw_circle(cc, rr + float(gi) * 3.0, Color(cor.r, cor.g, cor.b, 0.045 * pp / float(gi)))
		c.draw_circle(cc, rr, Color(0.04, 0.06, 0.1, 0.96))
		c.draw_arc(cc, rr, 0.0, TAU, 56, Color(cor.r, cor.g, cor.b, 0.9 * pp), 2.0)
		_draw_avatar_icone(c, cc.x, cc.y, rr * 0.82, idx)
		var edit_small := cc + Vector2(rr * 0.64, rr * 0.64)
		c.draw_circle(edit_small, 5.0, Color(0.06, 0.08, 0.12, 0.95))
		c.draw_arc(edit_small, 5.0, 0.0, TAU, 20, Color(cor.r, cor.g, cor.b, 0.72 * pp), 1.1)
		c.draw_line(edit_small + Vector2(-2.2, 2.0), edit_small + Vector2(2.2, -2.0), Color(cor.r + 0.2, cor.g + 0.2, cor.b + 0.2, 0.9 * pp), 1.2)
		return

	var cut: float = 9.0
	var panel := PackedVector2Array([
		Vector2(cut, 0.0), Vector2(w - cut, 0.0), Vector2(w, cut),
		Vector2(w, h - cut), Vector2(w - cut, h), Vector2(cut, h),
		Vector2(0.0, h - cut), Vector2(0.0, cut)
	])
	var panel_fill := PackedColorArray()
	for _i in range(panel.size()):
		panel_fill.append(Color(0.018, 0.032, 0.052, 0.72))
	c.draw_polygon(panel, panel_fill)
	c.draw_polyline(panel + PackedVector2Array([panel[0]]), Color(cor.r, cor.g, cor.b, 0.42), 1.2)
	c.draw_line(Vector2(48.0, 8.0), Vector2(w - 18.0, 8.0), Color(cor.r, cor.g, cor.b, 0.16), 1.0)
	c.draw_line(Vector2(48.0, h - 8.0), Vector2(w - 42.0, h - 8.0), Color(cor.r, cor.g, cor.b, 0.12), 1.0)

	var cx: float = 25.0
	var cy: float = h * 0.5
	var r: float = 17.0
	var p: float = sin(pulse * 1.1) * 0.15 + 0.85

	for i in range(4, 0, -1):
		c.draw_circle(Vector2(cx, cy), r + float(i) * 4.0, 
			Color(cor.r, cor.g, cor.b, 0.04 * p / float(i)))
	c.draw_circle(Vector2(cx, cy), r, Color(0.04, 0.06, 0.1, 0.95))
	c.draw_arc(Vector2(cx, cy), r, 0.0, TAU, 64, 
		Color(cor.r, cor.g, cor.b, 0.9 * p), 2.5)

	_draw_avatar_icone(c, cx, cy, r * 0.8, idx)


	var edit_c := Vector2(cx + r * 0.66, cy + r * 0.64)
	c.draw_circle(edit_c, 5.5, Color(0.06, 0.08, 0.12, 0.95))
	c.draw_arc(edit_c, 5.5, 0.0, TAU, 24, Color(cor.r, cor.g, cor.b, 0.75 * p), 1.2)
	c.draw_line(edit_c + Vector2(-2.7, 2.5), edit_c + Vector2(2.7, -2.5),
		Color(cor.r + 0.2, cor.g + 0.2, cor.b + 0.2, 0.9 * p), 1.4)
	c.draw_line(edit_c + Vector2(1.4, -3.5), edit_c + Vector2(3.4, -1.5),
		Color(cor.r + 0.2, cor.g + 0.2, cor.b + 0.2, 0.9 * p), 1.1)


func _on_perfil_input(event: InputEvent) -> void :
	if _is_primary_press(event):
		if (
			not _perfil_overlay and not _config_overlay and not _loja_overlay
			and not _talentos_overlay and not _ranking_overlay
		):
			_abrir_perfil(_ui_main)


func _abrir_perfil(ui: CanvasLayer) -> void :
	if _perfil_overlay:
		return
	if _menu_contents:
		_menu_contents.hide()

	var vp:= get_viewport().get_visible_rect().size
	var bg:= ColorRect.new()
	bg.color = Color(0.0, 0.0, 0.0, 0.8)
	bg.position = Vector2.ZERO
	bg.size = vp
	bg.mouse_filter = Control.MOUSE_FILTER_STOP
	ui.add_child(bg)
	_perfil_overlay = bg

	var pw: float = 560.0
	var ph: float = 720.0
	var pnl:= Panel.new()
	pnl.position = Vector2((vp.x - pw) * 0.5, (vp.y - ph) * 0.5)
	pnl.size = Vector2(pw, ph)
	pnl.mouse_filter = Control.MOUSE_FILTER_STOP
	var sty_p:= StyleBoxFlat.new()
	sty_p.bg_color = Color(0.04, 0.06, 0.1, 0.97)
	sty_p.border_color = _perfil_cor()
	for side in ["left", "right", "top", "bottom"]:
		sty_p.set("border_width_" + side, 2)
	for corner in ["top_left", "top_right", "bottom_left", "bottom_right"]:
		sty_p.set("corner_radius_" + corner, 16)
	pnl.add_theme_stylebox_override("panel", sty_p)
	bg.add_child(pnl)
	_perfil_panel = pnl


	var avatar:= Control.new()
	avatar.position = Vector2((pw - 108.0) * 0.5, 14)
	avatar.size = Vector2(108, 108)
	avatar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	avatar.draw.connect(func():
		var aidx: int = Salvar.avatar_idx
		var acor: Color = _AVATAR_CORES[aidx] if aidx < _AVATAR_CORES.size() else _perfil_cor()
		var acx: float = 54.0; var acy: float = 54.0; var ar: float = 46.0
		var _asc_av : int = Salvar.ascensoes
		var _niv_av : int = _nivel_prestigio(_asc_av)
		if _niv_av > 0:
			var _ptex_av : Texture2D = _carregar_simbolo_prestigio(_niv_av)
			var _rcor_av : Color
			match _niv_av:
				1, 2: _rcor_av = Color(0.72, 0.92, 1.0)
				3, 4: _rcor_av = Color(0.40, 0.95, 1.0)
				5, 6: _rcor_av = Color(1.0,  0.45, 1.0)
				_:    _rcor_av = Color(1.0,  0.92, 0.35)
			# Imagem maior que o circulo — bracos da estrela ficam visiveis alem do ar
			const _MAR_AV : float = 18.0
			if _ptex_av != null:
				avatar.draw_texture_rect(_ptex_av,
					Rect2(-_MAR_AV, -_MAR_AV, 108.0 + _MAR_AV * 2.0, 108.0 + _MAR_AV * 2.0),
					false, Color(1.0, 1.0, 1.0, 0.96))
			# Circulo escuro — fundo do avatar (mascara centro da imagem)
			avatar.draw_circle(Vector2(acx, acy), ar, Color(0.04, 0.06, 0.1, 1.0))
			# Arco colorido define borda do circulo
			avatar.draw_arc(Vector2(acx, acy), ar, 0.0, TAU, 80,
				Color(_rcor_av.r, _rcor_av.g, _rcor_av.b, 0.95), 3.0, true)
		else:
			for i in range(5, 0, -1):
				avatar.draw_circle(Vector2(acx, acy), ar + float(i) * 4.0,
					Color(acor.r, acor.g, acor.b, 0.04 / float(i)))
			avatar.draw_circle(Vector2(acx, acy), ar, Color(0.04, 0.06, 0.1, 0.97))
			avatar.draw_arc(Vector2(acx, acy), ar, 0.0, TAU, 80,
				Color(acor.r, acor.g, acor.b, 0.95), 3.0, true)
		_draw_avatar_icone(avatar, acx, acy, ar * 0.78, aidx)
	)
	pnl.add_child(avatar)

	var tit:= Label.new()
	tit.text = "MEU  PERFIL"
	tit.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tit.position = Vector2(0, 122)
	tit.size = Vector2(pw, 28)
	tit.add_theme_font_size_override("font_size", 26)
	tit.add_theme_color_override("font_color", _perfil_cor())
	_ui_title_label(tit, 4.0)
	pnl.add_child(tit)

	var sep0:= ColorRect.new()
	sep0.color = Color(_perfil_cor().r, _perfil_cor().g, _perfil_cor().b, 0.25)
	sep0.position = Vector2(30, 148)
	sep0.size = Vector2(pw - 60.0, 1)
	pnl.add_child(sep0)

	var _sty_input:= func() -> StyleBoxFlat:
		var s:= StyleBoxFlat.new()
		s.bg_color = Color(0.06, 0.08, 0.14, 0.97)
		s.border_color = Color(_perfil_cor().r, _perfil_cor().g, _perfil_cor().b, 0.8)
		for side2 in ["left", "right", "top", "bottom"]: s.set("border_width_" + side2, 2)
		for c2 in ["top_left", "top_right", "bottom_left", "bottom_right"]: s.set("corner_radius_" + c2, 8)
		return s

	var _sty_btn:= func(cor_bg: Color, cor_brd: Color) -> StyleBoxFlat:
		var s:= StyleBoxFlat.new()
		s.bg_color = cor_bg
		s.border_color = cor_brd
		for side2 in ["left", "right", "top", "bottom"]: s.set("border_width_" + side2, 2)
		for c2 in ["top_left", "top_right", "bottom_left", "bottom_right"]: s.set("corner_radius_" + c2, 8)
		return s

	var _registrado: bool = Salvar.senha_jogador != ""

	if _registrado:



		# ── Nome + badge inline (igual ao ranking) ───────────────────────────
		var nome_badge_ctrl := Control.new()
		nome_badge_ctrl.position = Vector2(20, 158)
		nome_badge_ctrl.size = Vector2(pw - 40.0, 38)
		nome_badge_ctrl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		nome_badge_ctrl.draw.connect(func():
			var _font_nb : Font = ThemeDB.fallback_font
			if _font_nb == null: return
			var _nome_nb : String = Salvar.nome_jogador
			const _FS_NB := 22
			var _nw_nb   : float = _font_nb.get_string_size(_nome_nb, HORIZONTAL_ALIGNMENT_LEFT, -1, _FS_NB).x
			var _cx_nb   : float = (pw - 40.0) * 0.5
			var _tx_nb   : float = _cx_nb - _nw_nb * 0.5
			# Sombra + texto do nome
			nome_badge_ctrl.draw_string(_font_nb, Vector2(_tx_nb + 1.0, _FS_NB + 1.0), _nome_nb,
				HORIZONTAL_ALIGNMENT_LEFT, -1, _FS_NB, Color(0, 0, 0, 0.55))
			nome_badge_ctrl.draw_string(_font_nb, Vector2(_tx_nb, _FS_NB), _nome_nb,
				HORIZONTAL_ALIGNMENT_LEFT, -1, _FS_NB, Color(0.92, 0.97, 1.0))
			# Badge ao lado direito do nome
			var _asc_nb  : int = Salvar.ascensoes
			var _niv_nb  : int = _nivel_prestigio(_asc_nb)
			if _niv_nb <= 0: return
			var _ncor_nb : Color
			match _niv_nb:
				1, 2: _ncor_nb = Color(0.72, 0.92, 1.0)
				3, 4: _ncor_nb = Color(0.40, 0.95, 1.0)
				5, 6: _ncor_nb = Color(1.0,  0.45, 1.0)
				_:    _ncor_nb = Color(1.0,  0.92, 0.35)
			const BSZNB := 30.0
			var _bx_nb : float = _tx_nb + _nw_nb + 5.0
			var _by_nb : float = _FS_NB * 0.5 - BSZNB * 0.5
			var _bcx_nb : float = _bx_nb + BSZNB * 0.5
			var _bcy_nb : float = _by_nb + BSZNB * 0.5
			var _ptex_nb : Texture2D = _carregar_simbolo_prestigio(_niv_nb)
			if _ptex_nb != null:
				nome_badge_ctrl.draw_texture_rect(_ptex_nb, Rect2(_bx_nb, _by_nb, BSZNB, BSZNB), false)
			else:
				nome_badge_ctrl.draw_circle(Vector2(_bcx_nb, _bcy_nb), BSZNB * 0.44, Color(0.08, 0.06, 0.14, 0.9))
			# Numero no centro do badge
			var _txt_nb : String = str(_asc_nb)
			var _fs_n   : int    = 9 if _asc_nb >= 100 else 11
			var _tw_nb  : float  = _font_nb.get_string_size(_txt_nb, HORIZONTAL_ALIGNMENT_LEFT, -1, _fs_n).x
			nome_badge_ctrl.draw_string(_font_nb, Vector2(_bcx_nb - _tw_nb * 0.5 + 1.0, _bcy_nb + _fs_n * 0.36 + 1.0),
				_txt_nb, HORIZONTAL_ALIGNMENT_LEFT, -1, _fs_n, Color(0, 0, 0, 0.75))
			nome_badge_ctrl.draw_string(_font_nb, Vector2(_bcx_nb - _tw_nb * 0.5, _bcy_nb + _fs_n * 0.36),
				_txt_nb, HORIZONTAL_ALIGNMENT_LEFT, -1, _fs_n, _ncor_nb)
		)
		pnl.add_child(nome_badge_ctrl)

		var _tem_email: bool = Salvar.email_jogador != ""
		var email_lbl:= Label.new()
		email_lbl.text = Salvar.email_jogador if _tem_email else "Sem e-mail cadastrado"
		email_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		email_lbl.position = Vector2(30, 200)
		email_lbl.size = Vector2(pw - 60.0, 20)
		email_lbl.add_theme_font_size_override("font_size", 18)
		email_lbl.add_theme_color_override("font_color",
			Color(0.5, 0.68, 0.9, 0.85) if _tem_email else Color(1.0, 0.72, 0.22, 0.9))
		pnl.add_child(email_lbl)


		if not _tem_email:
			var aviso:= Label.new()
			aviso.text = "Adicione um e-mail para recuperar sua conta caso esqueÃ§a a senha."
			aviso.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			aviso.autowrap_mode = TextServer.AUTOWRAP_WORD
			aviso.position = Vector2(40, 254)
			aviso.size = Vector2(pw - 80.0, 36)
			aviso.add_theme_font_size_override("font_size", 18)
			aviso.add_theme_color_override("font_color", Color(1.0, 0.85, 0.4, 0.9))
			pnl.add_child(aviso)

			var email_ed:= LineEdit.new()
			email_ed.name = "EmailAdd"
			email_ed.placeholder_text = "seu@email.com"
			email_ed.position = Vector2(40, 258)
			email_ed.size = Vector2(pw - 80.0, 36)
			email_ed.focus_mode = Control.FOCUS_CLICK
			email_ed.max_length = 80
			email_ed.add_theme_font_size_override("font_size", 22)
			email_ed.add_theme_stylebox_override("normal", _sty_input.call())
			email_ed.add_theme_color_override("font_color", Color(1.0, 0.96, 0.8))
			pnl.add_child(email_ed)

			var senha_ed:= LineEdit.new()
			senha_ed.name = "SenhaAdd"
			senha_ed.placeholder_text = "Confirme sua senha"
			senha_ed.secret = true
			senha_ed.position = Vector2(40, 300)
			senha_ed.size = Vector2(pw - 80.0, 36)
			senha_ed.focus_mode = Control.FOCUS_CLICK
			senha_ed.max_length = 40
			senha_ed.add_theme_font_size_override("font_size", 22)
			senha_ed.add_theme_stylebox_override("normal", _sty_input.call())
			senha_ed.add_theme_color_override("font_color", Color(1.0, 0.96, 0.8))
			pnl.add_child(senha_ed)

			var status_ea:= Label.new()
			status_ea.name = "StatusEmail"
			status_ea.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			status_ea.position = Vector2(40, 340)
			status_ea.size = Vector2(pw - 80.0, 20)
			status_ea.add_theme_font_size_override("font_size", 18)
			pnl.add_child(status_ea)

			var btn_email:= Button.new()
			btn_email.text = "SALVAR E-MAIL"
			btn_email.position = Vector2(40, 364)
			btn_email.size = Vector2(pw - 80.0, 34)
			btn_email.focus_mode = Control.FOCUS_NONE
			btn_email.add_theme_font_size_override("font_size", 20)
			btn_email.add_theme_stylebox_override("normal", 
				_sty_btn.call(Color(0.1, 0.14, 0.06, 0.95), Color(0.55, 0.85, 0.22, 0.9)))
			btn_email.add_theme_color_override("font_color", Color(0.7, 1.0, 0.4))
			pnl.add_child(btn_email)

			var _email_conn:= func(ok: bool) -> void :
				if not pnl or not is_instance_valid(pnl): return
				var sl: Label = pnl.get_node_or_null("StatusEmail") as Label
				if not sl: return
				if ok:
					var em: String = (pnl.get_node_or_null("EmailAdd") as LineEdit).text.strip_edges()
					Salvar.email_jogador = em
					Salvar.salvar()
					sl.text = "E-mail salvo!"
					sl.add_theme_color_override("font_color", Color(0.4, 1.0, 0.55))
				else:
					sl.text = "Senha incorreta ou erro de conexÃ£o."
					sl.add_theme_color_override("font_color", Color(1.0, 0.4, 0.35))
			if not RankingOnline.email_atualizado.is_connected(_email_conn):
				RankingOnline.email_atualizado.connect(_email_conn)

			btn_email.pressed.connect( func() -> void :
				var em: String = email_ed.text.strip_edges()
				var sw: String = senha_ed.text.strip_edges()
				var sl: Label = pnl.get_node_or_null("StatusEmail") as Label
				if em == "" or "@" not in em:
					if sl: sl.text = "E-mail invÃ¡lido"
					if sl: sl.add_theme_color_override("font_color", Color(1.0, 0.88, 0.2))
					return
				if sw == "":
					if sl: sl.text = "Digite sua senha"
					if sl: sl.add_theme_color_override("font_color", Color(1.0, 0.88, 0.2))
					return
				if sl: sl.text = "Salvandoâ€¦"
				if sl: sl.add_theme_color_override("font_color", Color(0.6, 0.8, 1.0))
				RankingOnline.adicionar_email(Salvar.nome_jogador, sw, em)
			)


		var _cy: float = 406.0 if not _tem_email else 218.0
		var bw: float = (pw - 100.0) * 0.5

		var _av_y: float = _cy + 14.0
		var sep_av:= ColorRect.new()
		sep_av.color = Color(0.3, 0.4, 0.6, 0.18)
		sep_av.position = Vector2(30, _av_y)
		sep_av.size = Vector2(pw - 60.0, 1)
		pnl.add_child(sep_av)

		var lavt:= Label.new()
		lavt.text = "AVATAR"
		lavt.position = Vector2(40, _av_y + 6)
		lavt.size = Vector2(pw - 80.0, 18)
		lavt.add_theme_font_size_override("font_size", 16)
		lavt.add_theme_color_override("font_color", Color(0.5, 0.6, 0.8))
		pnl.add_child(lavt)

		var av_size: float = 64.0; var av_gap: float = 10.0
		var av_total: float = 5.0 * av_size + 4.0 * av_gap
		var av_x0: float = (pw - av_total) * 0.5
		var av_btns: Array = []
		for ai in range(5):
			var av_ctrl:= Control.new()
			av_ctrl.position = Vector2(av_x0 + float(ai) * (av_size + av_gap), _av_y + 26)
			av_ctrl.size = Vector2(av_size, av_size + 16)
			av_ctrl.mouse_filter = Control.MOUSE_FILTER_STOP
			var ai_cap:= ai
			av_ctrl.draw.connect( func():
				var acor: Color = _AVATAR_CORES[ai_cap] if ai_cap < _AVATAR_CORES.size() else Color(0.5, 0.6, 0.8)
				var sel: bool = Salvar.avatar_idx == ai_cap
				var acx: float = av_size * 0.5; var acy: float = av_size * 0.5; var ar: float = av_size * 0.42
				if sel:
					for gi in range(3, 0, -1):
						av_ctrl.draw_circle(Vector2(acx, acy), ar + float(gi) * 4.0, Color(acor.r, acor.g, acor.b, 0.06 / float(gi)))
				av_ctrl.draw_circle(Vector2(acx, acy), ar, Color(acor.r * 0.12, acor.g * 0.12, acor.b * 0.12, 0.95))
				av_ctrl.draw_arc(Vector2(acx, acy), ar, 0.0, TAU, 64, 
					Color(acor.r, acor.g, acor.b, 1.0 if sel else 0.35), 4.0 if sel else 1.5)
				_draw_avatar_icone(av_ctrl, acx, acy, ar * 0.72, ai_cap)
				var font: Font = ThemeDB.fallback_font
				var nm: String = _AVATAR_NOMES[ai_cap] if ai_cap < _AVATAR_NOMES.size() else ""
				var tw: float = font.get_string_size(nm, HORIZONTAL_ALIGNMENT_LEFT, -1, 9).x
				av_ctrl.draw_string(font, Vector2(acx - tw * 0.5, av_size + 12.0), nm, 
					HORIZONTAL_ALIGNMENT_LEFT, -1, 9, Color(acor.r + 0.1, acor.g + 0.1, acor.b + 0.1, 0.85 if sel else 0.5))
			)
			av_ctrl.gui_input.connect( func(event: InputEvent):
				if _is_primary_press(event):
					Salvar.avatar_idx = ai_cap;Salvar.salvar()
					RankingOnline.envio_inicial()
					for ab in av_btns: (ab as Control).queue_redraw()
					if avatar and is_instance_valid(avatar): avatar.queue_redraw()
					if _perfil_btn and is_instance_valid(_perfil_btn): _perfil_btn.queue_redraw()
			)
			pnl.add_child(av_ctrl);av_btns.append(av_ctrl)


		var _rec_y: float = _av_y + 26 + av_size + 20

		# â”€â”€ TÃ­tulo MEUS RECORDES â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
		var sep_rec:= ColorRect.new()
		sep_rec.color = Color(_perfil_cor().r, _perfil_cor().g, _perfil_cor().b, 0.18)
		sep_rec.position = Vector2(30, _rec_y)
		sep_rec.size = Vector2(pw - 60.0, 1)
		pnl.add_child(sep_rec)

		var lrec:= Label.new()
		lrec.text = "MEUS RECORDES"
		lrec.position = Vector2(40, _rec_y + 8)
		lrec.size = Vector2(pw - 80.0, 20)
		lrec.add_theme_font_size_override("font_size", 13)
		lrec.add_theme_color_override("font_color", Color(0.5, 0.6, 0.8, 0.75))
		pnl.add_child(lrec)

		# â”€â”€ Painel de fundo da tabela â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
		var rec_bg := Panel.new()
		rec_bg.position = Vector2(30, _rec_y + 32)
		rec_bg.size = Vector2(pw - 60.0, 142)
		var rec_sty := StyleBoxFlat.new()
		rec_sty.bg_color = Color(0.06, 0.08, 0.14, 0.72)
		rec_sty.border_color = Color(0.22, 0.28, 0.42, 0.45)
		for _rs in ["left","right","top","bottom"]: rec_sty.set("border_width_"+_rs, 1)
		for _rc in ["top_left","top_right","bottom_left","bottom_right"]: rec_sty.set("corner_radius_"+_rc, 6)
		rec_bg.add_theme_stylebox_override("panel", rec_sty)
		rec_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
		pnl.add_child(rec_bg)

		# â”€â”€ CabeÃ§alho da tabela â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
		var hdr_bg := ColorRect.new()
		hdr_bg.color = Color(0.12, 0.16, 0.26, 0.80)
		hdr_bg.position = Vector2(0, 0); hdr_bg.size = Vector2(pw - 60.0, 26)
		hdr_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
		rec_bg.add_child(hdr_bg)

		var _hdr := func(txt: String, px: float, pw2: float, align: int) -> void:
			var hl := Label.new()
			hl.text = txt; hl.position = Vector2(px, 5); hl.size = Vector2(pw2, 16)
			hl.horizontal_alignment = align
			hl.add_theme_font_size_override("font_size", 11)
			hl.add_theme_color_override("font_color", Color(0.55, 0.65, 0.85, 0.65))
			hl.mouse_filter = Control.MOUSE_FILTER_IGNORE
			rec_bg.add_child(hl)
		_hdr.call("DIFICULDADE", 12.0, 120.0, HORIZONTAL_ALIGNMENT_LEFT)
		_hdr.call("MELHOR ONDA", 140.0, 90.0, HORIZONTAL_ALIGNMENT_CENTER)
		_hdr.call("MELHOR SCORE", 240.0, pw - 60.0 - 250.0, HORIZONTAL_ALIGNMENT_RIGHT)

		var sep_hdr := ColorRect.new()
		sep_hdr.color = Color(0.22, 0.28, 0.42, 0.5)
		sep_hdr.position = Vector2(8, 26); sep_hdr.size = Vector2(pw - 76.0, 1)
		sep_hdr.mouse_filter = Control.MOUSE_FILTER_IGNORE
		rec_bg.add_child(sep_hdr)

		# â”€â”€ Linhas de dados â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
		var rec_dados:= [
			["Fácil",   Salvar.melhor_wave_facil,   Salvar.high_score_facil,   Color(0.1, 0.88, 0.42)],
			["Normal",  Salvar.melhor_wave_normal,  Salvar.high_score_normal,  Color(0.0, 0.72, 1.0)],
			["Difícil", Salvar.melhor_wave_dificil, Salvar.high_score_dificil, Color(1.0, 0.28, 0.18)],
			["Abismo",  Salvar.melhor_wave_abismo,  Salvar.high_score_abismo,  Color(0.88, 0.08, 0.08)],
		]
		var ry: float = 28.0
		for ri in range(rec_dados.size()):
			var rd = rec_dados[ri]
			var rwave : int  = rd[1] as int
			var rscore : int = rd[2] as int
			var rc2: Color   = rd[3] as Color
			var row_h : float = 28.0

			if ri % 2 == 0:
				var row_bg := ColorRect.new()
				row_bg.color = Color(rc2.r, rc2.g, rc2.b, 0.04)
				row_bg.position = Vector2(0, ry); row_bg.size = Vector2(pw - 60.0, row_h)
				row_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
				rec_bg.add_child(row_bg)

			# barra cor lateral
			var bar := ColorRect.new()
			bar.color = Color(rc2.r, rc2.g, rc2.b, 0.55)
			bar.position = Vector2(0, ry + 5); bar.size = Vector2(3, row_h - 10)
			bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
			rec_bg.add_child(bar)

			var lname := Label.new()
			lname.text = rd[0] as String
			lname.position = Vector2(12, ry + 5); lname.size = Vector2(120, 20)
			lname.add_theme_font_size_override("font_size", 14)
			lname.add_theme_color_override("font_color", Color(rc2.r, rc2.g, rc2.b, 0.9))
			lname.mouse_filter = Control.MOUSE_FILTER_IGNORE
			rec_bg.add_child(lname)

			var lwave := Label.new()
			lwave.text = "%d" % rwave if rwave > 0 else "â€”"
			lwave.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			lwave.position = Vector2(140, ry + 5); lwave.size = Vector2(90, 20)
			lwave.add_theme_font_size_override("font_size", 14)
			lwave.add_theme_color_override("font_color",
				Color(rc2.r + 0.15, rc2.g + 0.15, rc2.b + 0.15) if rwave > 0 else Color(0.3, 0.35, 0.45))
			lwave.mouse_filter = Control.MOUSE_FILTER_IGNORE
			rec_bg.add_child(lwave)

			var lscore := Label.new()
			lscore.text = _format_num(rscore) if rscore > 0 else "â€”"
			lscore.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
			lscore.position = Vector2(240, ry + 5); lscore.size = Vector2(pw - 60.0 - 250.0, 20)
			lscore.add_theme_font_size_override("font_size", 14)
			lscore.add_theme_color_override("font_color",
				Color(rc2.r + 0.15, rc2.g + 0.15, rc2.b + 0.15) if rscore > 0 else Color(0.3, 0.35, 0.45))
			lscore.mouse_filter = Control.MOUSE_FILTER_IGNORE
			rec_bg.add_child(lscore)

			ry += row_h
			if ri < rec_dados.size() - 1:
				var sep_row := ColorRect.new()
				sep_row.color = Color(0.18, 0.22, 0.32, 0.4)
				sep_row.position = Vector2(8, ry); sep_row.size = Vector2(pw - 76.0, 1)
				sep_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
				rec_bg.add_child(sep_row)

	else:



		var tab_y: float = 166.0
		var tab_w: float = (pw - 80.0) * 0.5
		var tab_reg:= Button.new()
		var tab_ent:= Button.new()
		var cont_reg:= Control.new()
		var cont_ent:= Control.new()

		var _sty_tab_on:= func() -> StyleBoxFlat:
			var s:= StyleBoxFlat.new()
			s.bg_color = Color(_perfil_cor().r * 0.18, _perfil_cor().g * 0.18, _perfil_cor().b * 0.18, 0.97)
			s.border_color = _perfil_cor()
			for sd in ["left", "right", "top", "bottom"]: s.set("border_width_" + sd, 2)
			for cr in ["top_left", "top_right", "bottom_left", "bottom_right"]: s.set("corner_radius_" + cr, 6)
			return s
		var _sty_tab_off:= func() -> StyleBoxFlat:
			var s:= StyleBoxFlat.new()
			s.bg_color = Color(0.06, 0.08, 0.12, 0.8)
			s.border_color = Color(0.2, 0.25, 0.35, 0.6)
			for sd in ["left", "right", "top", "bottom"]: s.set("border_width_" + sd, 2)
			for cr in ["top_left", "top_right", "bottom_left", "bottom_right"]: s.set("corner_radius_" + cr, 6)
			return s

		for tb in [tab_reg, tab_ent]:
			tb.focus_mode = Control.FOCUS_NONE
			tb.add_theme_font_size_override("font_size", 21)
			tb.size = Vector2(tab_w, 34)
		tab_reg.text = "REGISTRAR"
		tab_reg.position = Vector2(40, tab_y)
		tab_ent.text = "ENTRAR"
		tab_ent.position = Vector2(40 + tab_w + 4, tab_y)

		cont_reg.position = Vector2(0, tab_y + 38)
		cont_reg.size = Vector2(pw, ph - tab_y - 38)
		cont_ent.position = cont_reg.position
		cont_ent.size = cont_reg.size

		pnl.add_child(tab_reg);pnl.add_child(tab_ent)
		pnl.add_child(cont_reg);pnl.add_child(cont_ent)

		var _sel_aba:= func(reg: bool) -> void :
			tab_reg.add_theme_stylebox_override("normal", _sty_tab_on.call() if reg else _sty_tab_off.call())
			tab_ent.add_theme_stylebox_override("normal", _sty_tab_off.call() if reg else _sty_tab_on.call())
			tab_reg.add_theme_color_override("font_color", _perfil_cor() if reg else Color(0.45, 0.55, 0.7))
			tab_ent.add_theme_color_override("font_color", _perfil_cor() if not reg else Color(0.45, 0.55, 0.7))
			cont_reg.visible = reg
			cont_ent.visible = not reg


		var nome_reg: LineEdit = _perfil_add_field(cont_reg, "Nome no ranking:", 6, "Apelido (mÃ¡x 20)", false, 20, _sty_input)
		var email_reg: LineEdit = _perfil_add_field(cont_reg, "E-mail:", 76, "seu@email.com", false, 80, _sty_input)
		var senha_reg: LineEdit = _perfil_add_field(cont_reg, "Criar senha:", 146, "MÃ­nimo 4 caracteres", true, 40, _sty_input)
		nome_reg.name = "NomeReg"
		email_reg.name = "EmailReg"
		senha_reg.name = "SenhaReg"

		var status_reg:= Label.new()
		status_reg.name = "StatusReg"
		status_reg.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		status_reg.autowrap_mode = TextServer.AUTOWRAP_WORD
		status_reg.position = Vector2(40, 222)
		status_reg.size = Vector2(pw - 80.0, 34)
		status_reg.add_theme_font_size_override("font_size", 18)
		status_reg.add_theme_color_override("font_color", Color(0.4, 0.85, 0.5))
		cont_reg.add_child(status_reg)

		var btn_reg:= Button.new()
		btn_reg.text = "CRIAR CONTA"
		btn_reg.position = Vector2(40, 260)
		btn_reg.size = Vector2(pw - 80.0, 40)
		btn_reg.focus_mode = Control.FOCUS_NONE
		btn_reg.add_theme_font_size_override("font_size", 22)
		btn_reg.add_theme_stylebox_override("normal", 
			_sty_btn.call(Color(0.08, 0.18, 0.1, 0.95), Color(0.28, 0.85, 0.42, 0.9)))
		btn_reg.add_theme_color_override("font_color", Color(0.42, 1.0, 0.56))
		cont_reg.add_child(btn_reg)

		var _reg_conn:= func(ok: bool, erro: String) -> void :
			if not pnl or not is_instance_valid(pnl): return
			var sl: Label = cont_reg.get_node_or_null("StatusReg") as Label
			if not sl: return
			if ok:
				var nm: String = (cont_reg.get_node_or_null("NomeReg") as LineEdit).text.strip_edges()
				var em: String = (cont_reg.get_node_or_null("EmailReg") as LineEdit).text.strip_edges()
				var sw: String = (cont_reg.get_node_or_null("SenhaReg") as LineEdit).text.strip_edges()
				Salvar.nome_jogador = nm
				Salvar.email_jogador = em
				Salvar.senha_jogador = RankingOnline._hash(sw)
				Salvar.credenciais_versao = 1
				Salvar.salvar()
				sl.text = "Conta criada! Bem-vindo, %s!" % nm
				sl.add_theme_color_override("font_color", Color(0.4, 1.0, 0.55))
				RankingOnline.envio_inicial()
				if _menu_contents and is_instance_valid(_menu_contents):
					var ln = _menu_contents.find_child("LPerfilNome")
					if ln: (ln as Label).text = _perfil_nome_curto()
				if _perfil_btn and is_instance_valid(_perfil_btn): _perfil_btn.queue_redraw()
			else:
				sl.text = erro
				sl.add_theme_color_override("font_color", Color(1.0, 0.4, 0.35))
		if not RankingOnline.registro_concluido.is_connected(_reg_conn):
			RankingOnline.registro_concluido.connect(_reg_conn)

		btn_reg.pressed.connect( func() -> void :
			var nm: String = nome_reg.text.strip_edges()
			var em: String = email_reg.text.strip_edges()
			var sw: String = senha_reg.text.strip_edges()
			var sl: Label = cont_reg.get_node_or_null("StatusReg") as Label
			if nm == "":
				sl.text = "Digite um nome";sl.add_theme_color_override("font_color", Color(1.0, 0.88, 0.2));return
			if em == "" or "@" not in em:
				sl.text = "Digite um e-mail vÃ¡lido";sl.add_theme_color_override("font_color", Color(1.0, 0.88, 0.2));return
			if sw.length() < 4:
				sl.text = "Senha muito curta (mÃ­n. 4)";sl.add_theme_color_override("font_color", Color(1.0, 0.88, 0.2));return
			sl.text = "Registrandoâ€¦";sl.add_theme_color_override("font_color", Color(0.6, 0.8, 1.0))
			RankingOnline.registrar_nome(nm, em, sw)
		)


		var id_ent: LineEdit = _perfil_add_field(cont_ent, "Nome ou e-mail:", 6, "Seu nome ou email", false, 80, _sty_input)
		var senha_ent: LineEdit = _perfil_add_field(cont_ent, "Senha:", 76, "Sua senha", true, 40, _sty_input)
		id_ent.name = "IdEnt"
		senha_ent.name = "SenhaEnt"

		var status_ent:= Label.new()
		status_ent.name = "StatusEnt"
		status_ent.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		status_ent.autowrap_mode = TextServer.AUTOWRAP_WORD
		status_ent.position = Vector2(40, 152)
		status_ent.size = Vector2(pw - 80.0, 34)
		status_ent.add_theme_font_size_override("font_size", 18)
		status_ent.add_theme_color_override("font_color", Color(0.4, 0.85, 0.5))
		cont_ent.add_child(status_ent)

		var btn_ent:= Button.new()
		btn_ent.text = "ENTRAR"
		btn_ent.position = Vector2(40, 190)
		btn_ent.size = Vector2(pw - 80.0, 40)
		btn_ent.focus_mode = Control.FOCUS_NONE
		btn_ent.add_theme_font_size_override("font_size", 22)
		btn_ent.add_theme_stylebox_override("normal", 
			_sty_btn.call(Color(0.06, 0.1, 0.2, 0.95), Color(0.28, 0.55, 0.95, 0.9)))
		btn_ent.add_theme_color_override("font_color", Color(0.5, 0.82, 1.0))
		cont_ent.add_child(btn_ent)

		var _login_conn:= func(ok: bool, nome_ret: String, email_ret: String) -> void :
			if not pnl or not is_instance_valid(pnl): return
			var sl: Label = cont_ent.get_node_or_null("StatusEnt") as Label
			if not sl: return
			if ok:
				var sw: String = (cont_ent.get_node_or_null("SenhaEnt") as LineEdit).text.strip_edges()
				var _conta_anterior : String = Salvar.nome_jogador
				Salvar.nome_jogador = nome_ret
				Salvar.email_jogador = email_ret
				Salvar.senha_jogador = RankingOnline._hash(sw)
				Salvar.credenciais_versao = 1
				Salvar.salvar()
				sl.text = "Bem-vindo, %s!" % nome_ret
				sl.add_theme_color_override("font_color", Color(0.4, 1.0, 0.55))
				RankingOnline.download_save(nome_ret, func(s_ok: bool, dados: Dictionary, force: bool = false) -> void :
					if s_ok:
						if force or _conta_anterior != nome_ret:
							Salvar.importar_cloud_forcado(dados)
							if force: RankingOnline._limpar_force_sync(nome_ret)
						else:
							Salvar.importar_cloud(dados)
						RankingOnline.buscar_premios_pendentes()
				)
				if _menu_contents and is_instance_valid(_menu_contents):
					var ln = _menu_contents.find_child("LPerfilNome")
					if ln: (ln as Label).text = _perfil_nome_curto()
				if _perfil_btn and is_instance_valid(_perfil_btn): _perfil_btn.queue_redraw()
				await get_tree().create_timer(1.2).timeout
				if pnl and is_instance_valid(pnl):
					_fechar_perfil()
					_abrir_perfil(_ui_main)
			else:
				sl.text = "Nome/e-mail ou senha incorretos."
				sl.add_theme_color_override("font_color", Color(1.0, 0.4, 0.35))
		if not RankingOnline.login_verificado.is_connected(_login_conn):
			RankingOnline.login_verificado.connect(_login_conn)

		btn_ent.pressed.connect( func() -> void :
			var id: String = id_ent.text.strip_edges()
			var sw: String = senha_ent.text.strip_edges()
			var sl: Label = cont_ent.get_node_or_null("StatusEnt") as Label
			if id == "":
				sl.text = "Digite seu nome ou e-mail";sl.add_theme_color_override("font_color", Color(1.0, 0.88, 0.2));return
			if sw == "":
				sl.text = "Digite sua senha";sl.add_theme_color_override("font_color", Color(1.0, 0.88, 0.2));return
			sl.text = "Verificandoâ€¦";sl.add_theme_color_override("font_color", Color(0.6, 0.8, 1.0))
			RankingOnline.verificar_login(id, sw, Callable())
		)

		tab_reg.pressed.connect( func() -> void : _sel_aba.call(true))
		tab_ent.pressed.connect( func() -> void : _sel_aba.call(false))
		_sel_aba.call(true)


	var btn_stats:= Button.new()
	btn_stats.text = "ESTATISTICAS"
	btn_stats.position = Vector2(40, ph - 112.0)
	btn_stats.size = Vector2(pw - 80.0, 44)
	btn_stats.focus_mode = Control.FOCUS_NONE
	btn_stats.add_theme_font_size_override("font_size", 20)
	var sty_stats:= StyleBoxFlat.new()
	sty_stats.bg_color = Color(0.02, 0.14, 0.10, 0.95)
	sty_stats.border_color = Color(0.1, 0.85, 0.6, 0.82)
	for side in ["left", "right", "top", "bottom"]: sty_stats.set("border_width_" + side, 2)
	for corner in ["top_left", "top_right", "bottom_left", "bottom_right"]: sty_stats.set("corner_radius_" + corner, 8)
	btn_stats.add_theme_stylebox_override("normal", sty_stats)
	btn_stats.add_theme_color_override("font_color", Color(0.45, 1.0, 0.75))
	btn_stats.pressed.connect(func():
		Acessibilidade.processar("perfil_stats",
			"Estatisticas. Ver historico das ultimas partidas e recordes.",
			func():
				_fechar_perfil()
				_abrir_hist(ui)))
	pnl.add_child(btn_stats)

	var btn_f:= Button.new()
	btn_f.text = "FECHAR"
	btn_f.position = Vector2((pw - 200.0) * 0.5, ph - 56.0)
	btn_f.size = Vector2(200, 60)
	btn_f.focus_mode = Control.FOCUS_NONE
	btn_f.add_theme_font_size_override("font_size", 22)
	var sty_f:= StyleBoxFlat.new()
	sty_f.bg_color = Color(0.06, 0.08, 0.12, 0.95)
	sty_f.border_color = Color(_perfil_cor().r, _perfil_cor().g, _perfil_cor().b, 0.6)
	for side in ["left", "right", "top", "bottom"]: sty_f.set("border_width_" + side, 2)
	for corner in ["top_left", "top_right", "bottom_left", "bottom_right"]: sty_f.set("corner_radius_" + corner, 8)
	btn_f.add_theme_stylebox_override("normal", sty_f)
	btn_f.add_theme_color_override("font_color", Color(_perfil_cor().r + 0.2, _perfil_cor().g + 0.2, _perfil_cor().b + 0.2))
	btn_f.pressed.connect(_fechar_perfil)
	pnl.add_child(btn_f)
	_corrigir_textos_ui(pnl)


func _perfil_add_field(parent: Control, lbl_txt: String, y: float, ph_txt: String, secret: bool, max_len: int, sty_fn: Callable) -> LineEdit:
	var lbl:= Label.new()
	lbl.text = lbl_txt
	lbl.position = Vector2(40, y)
	lbl.size = Vector2(480, 30)
	lbl.add_theme_font_size_override("font_size", 20)
	lbl.add_theme_color_override("font_color", Color(0.75, 0.85, 1.0))
	parent.add_child(lbl)
	var ed:= LineEdit.new()
	ed.placeholder_text = ph_txt
	ed.secret = secret
	ed.position = Vector2(40, y + 22)
	ed.size = Vector2(480, 57)
	ed.focus_mode = Control.FOCUS_CLICK
	ed.max_length = max_len
	ed.add_theme_font_size_override("font_size", 24)
	ed.add_theme_stylebox_override("normal", sty_fn.call())
	ed.add_theme_color_override("font_color", Color(1.0, 0.96, 0.8))
	parent.add_child(ed)
	return ed


func _fechar_perfil() -> void :
	if _perfil_overlay and is_instance_valid(_perfil_overlay):
		_perfil_overlay.queue_free()
	_perfil_overlay = null
	_perfil_panel = null
	if _menu_contents:
		_menu_contents.show()
	if _perfil_btn and is_instance_valid(_perfil_btn):
		_perfil_btn.queue_redraw()




func _abrir_ranking(ui: CanvasLayer) -> void :
	if _ranking_overlay:
		return
	if _menu_contents:
		_menu_contents.hide()

	var vp:= get_viewport().get_visible_rect().size
	var VW: float = vp.x
	var VH: float = vp.y


	var bg:= ColorRect.new()
	bg.color = Color(0.01, 0.012, 0.024, 0.985)
	bg.position = Vector2.ZERO
	bg.size = vp
	bg.mouse_filter = Control.MOUSE_FILTER_STOP
	ui.add_child(bg)
	_ranking_overlay = bg
	_ranking_panel = bg


	var tit:= Label.new()
	tit.text = "RANKING GLOBAL"
	tit.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	tit.position = Vector2(24, 10)
	tit.size = Vector2(VW * 0.55, 46)
	tit.add_theme_font_size_override("font_size", 34)
	tit.add_theme_color_override("font_color", Color(1.0, 0.85, 0.2))
	_ui_title_label(tit, 3.0)
	tit.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bg.add_child(tit)

	var sub:= Label.new()
	sub.text = "BETA TEMPORADA %d  |  FINALIZA EM %s  |  MAIOR WAVE ALCANCADA" % [
		RankingOnline.temporada_display_numero(),
		_ranking_tempo_temporada_texto()
	]
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	sub.position = Vector2(28, 44)
	sub.size = Vector2(VW * 0.76, 26)
	sub.add_theme_font_size_override("font_size", 14)
	sub.add_theme_color_override("font_color", Color(0.38, 0.86, 1.0, 0.82))
	sub.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bg.add_child(sub)


	var ts_lbl:= Label.new()
	ts_lbl.name = "TimestampLbl"
	ts_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	ts_lbl.position = Vector2(VW - 430, 14)
	ts_lbl.size = Vector2(406, 24)
	ts_lbl.add_theme_font_size_override("font_size", 13)
	ts_lbl.add_theme_color_override("font_color", Color(0.5, 0.6, 0.7, 0.8))
	ts_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bg.add_child(ts_lbl)
	_ranking_ts_lbl = ts_lbl

	var sep:= ColorRect.new()
	sep.color = Color(1.0, 0.78, 0.1, 0.28)
	sep.position = Vector2(20, 78)
	sep.size = Vector2(VW - 40, 2)
	sep.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bg.add_child(sep)


	var sep2:= ColorRect.new()
	sep2.color = Color(1.0, 0.78, 0.1, 0.18)
	sep2.position = Vector2(20, 90)
	sep2.size = Vector2(VW - 40, 2)
	sep2.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bg.add_child(sep2)

	var premio_lbl:= Label.new()
	premio_lbl.text = "PRÊMIOS TOP 3: TOP 1 - 3x Baú Estelar + 300 cristais   |   TOP 2 - 2x Baú Estelar + 180 cristais   |   TOP 3 - 1x Baú Estelar + 100 cristais"
	premio_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	premio_lbl.position = Vector2(26, 94)
	premio_lbl.size = Vector2(VW - 52, 22)
	premio_lbl.add_theme_font_size_override("font_size", 14)
	premio_lbl.add_theme_color_override("font_color", Color(1.0, 0.88, 0.28, 0.86))
	premio_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bg.add_child(premio_lbl)

	var campeoes_cont:= Control.new()
	campeoes_cont.name = "CampeoesTemporadaAnterior"
	campeoes_cont.position = Vector2(28, 116)
	campeoes_cont.size = Vector2(VW - 56, 26)
	campeoes_cont.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bg.add_child(campeoes_cont)
	_ranking_campeoes_cont = campeoes_cont
	_render_campeoes_temporada_anterior(-1, [])


	var podio_ctrl:= Control.new()
	podio_ctrl.position = Vector2(0, 142)
	podio_ctrl.size = Vector2(VW, 222)
	podio_ctrl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	podio_ctrl.set_meta("podio", true)
	podio_ctrl.set_meta("entries", [])
	podio_ctrl.set_meta("ctrl_w", VW)
	podio_ctrl.draw.connect( func(): _draw_podio(podio_ctrl, podio_ctrl.get_meta("entries", [])))
	bg.add_child(podio_ctrl)

	var sep3:= ColorRect.new()
	sep3.color = Color(1.0, 0.78, 0.1, 0.18)
	sep3.position = Vector2(20, 370)
	sep3.size = Vector2(VW - 40, 2)
	sep3.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bg.add_child(sep3)


	var hdr_pos:= Label.new()
	hdr_pos.text = "#"
	hdr_pos.position = Vector2(28, 376)
	hdr_pos.size = Vector2(58, 28)
	hdr_pos.add_theme_font_size_override("font_size", 17)
	hdr_pos.add_theme_color_override("font_color", Color(0.55, 0.65, 0.75))
	hdr_pos.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bg.add_child(hdr_pos)

	var hdr_nome:= Label.new()
	hdr_nome.text = "NOME"
	hdr_nome.position = Vector2(96, 376)
	hdr_nome.size = Vector2(560, 28)
	hdr_nome.add_theme_font_size_override("font_size", 17)
	hdr_nome.add_theme_color_override("font_color", Color(0.55, 0.65, 0.75))
	hdr_nome.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bg.add_child(hdr_nome)

	var hdr_wave:= Label.new()
	hdr_wave.text = "WAVE"
	hdr_wave.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hdr_wave.position = Vector2(680, 376)
	hdr_wave.size = Vector2(240, 28)
	hdr_wave.add_theme_font_size_override("font_size", 17)
	hdr_wave.add_theme_color_override("font_color", Color(0.55, 0.65, 0.75))
	hdr_wave.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bg.add_child(hdr_wave)

	var hdr_score:= Label.new()
	hdr_score.text = "SCORE"
	hdr_score.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	hdr_score.position = Vector2(940, 376)
	hdr_score.size = Vector2(VW - 960, 28)
	hdr_score.add_theme_font_size_override("font_size", 17)
	hdr_score.add_theme_color_override("font_color", Color(0.55, 0.65, 0.75))
	hdr_score.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bg.add_child(hdr_score)

	var sep4:= ColorRect.new()
	sep4.color = Color(0.55, 0.65, 0.75, 0.15)
	sep4.position = Vector2(20, 406)
	sep4.size = Vector2(VW - 40, 2)
	sep4.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bg.add_child(sep4)


	for gi in range(4, 0, -1):
		var g_rect:= ColorRect.new()
		g_rect.color = Color(1.0, 0.78, 0.1, 0.04 / float(gi))
		g_rect.position = Vector2(0, float(gi) - 1)
		g_rect.size = Vector2(VW, 3)
		g_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		bg.add_child(g_rect)
	var neon_top:= ColorRect.new()
	neon_top.color = Color(1.0, 0.85, 0.15, 0.7)
	neon_top.position = Vector2(0, 0)
	neon_top.size = Vector2(VW, 2)
	neon_top.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bg.add_child(neon_top)



	var scroll:= ScrollContainer.new()
	scroll.position = Vector2(20, 410)
	scroll.size = Vector2(VW - 40, VH - 410 - 56)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	scroll.mouse_filter = Control.MOUSE_FILTER_STOP
	bg.add_child(scroll)

	var lista_cont:= VBoxContainer.new()
	lista_cont.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lista_cont.add_theme_constant_override("separation", 2)
	lista_cont.mouse_filter = Control.MOUSE_FILTER_PASS
	scroll.add_child(lista_cont)
	_ranking_lista = lista_cont

	var load_lbl:= Label.new()
	load_lbl.name = "LoadLabel"
	load_lbl.text = "Carregando ranking..."
	load_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	load_lbl.add_theme_font_size_override("font_size", 22)
	load_lbl.add_theme_color_override("font_color", Color(0.5, 0.65, 0.8))
	lista_cont.add_child(load_lbl)


	var pos_lbl:= Label.new()
	pos_lbl.name = "PosicaoJogador"
	pos_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	pos_lbl.position = Vector2(20, VH - 46)
	pos_lbl.size = Vector2(400, 38)
	pos_lbl.add_theme_font_size_override("font_size", 15)
	pos_lbl.add_theme_color_override("font_color", Color(0.5, 0.75, 1.0, 0.8))
	pos_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bg.add_child(pos_lbl)
	_ranking_pos_lbl = pos_lbl


	var btn_f:= Button.new()
	btn_f.text = "FECHAR"
	btn_f.position = Vector2((VW - 220) * 0.5, VH - 50)
	btn_f.size = Vector2(220, 46)
	btn_f.focus_mode = Control.FOCUS_NONE
	btn_f.add_theme_font_size_override("font_size", 22)
	var sty_f:= StyleBoxFlat.new()
	sty_f.bg_color = Color(0.08, 0.08, 0.05, 0.95)
	sty_f.border_color = Color(1.0, 0.78, 0.1, 0.85)
	for side in ["left", "right", "top", "bottom"]:
		sty_f.set("border_width_" + side, 2)
	for corner in ["top_left", "top_right", "bottom_left", "bottom_right"]:
		sty_f.set("corner_radius_" + corner, 8)
	btn_f.add_theme_stylebox_override("normal", sty_f)
	var sty_fh: StyleBoxFlat = sty_f.duplicate()
	sty_fh.bg_color = Color(0.18, 0.14, 0.02, 0.98)
	sty_fh.border_color = Color(1.0, 0.95, 0.3, 1.0)
	btn_f.add_theme_stylebox_override("hover", sty_fh)
	btn_f.add_theme_color_override("font_color", Color(1.0, 0.88, 0.3))
	btn_f.pressed.connect(_fechar_ranking)
	bg.add_child(btn_f)

	if Salvar.nome_jogador.strip_edges().to_upper() == "BOSS QUEIXO":
		var btn_adm:= Button.new()
		btn_adm.text = "ADMIN: FORCAR SYNC"
		btn_adm.position = Vector2(20, VH - 50)
		btn_adm.size = Vector2(340, 46)
		btn_adm.focus_mode = Control.FOCUS_NONE
		btn_adm.add_theme_font_size_override("font_size", 18)
		var sty_adm:= StyleBoxFlat.new()
		sty_adm.bg_color = Color(0.18, 0.06, 0.02, 0.95)
		sty_adm.border_color = Color(1.0, 0.45, 0.1, 0.85)
		for s in ["left", "right", "top", "bottom"]: sty_adm.set("border_width_" + s, 2)
		for c2 in ["top_left", "top_right", "bottom_left", "bottom_right"]: sty_adm.set("corner_radius_" + c2, 6)
		btn_adm.add_theme_stylebox_override("normal", sty_adm)
		btn_adm.add_theme_color_override("font_color", Color(1.0, 0.65, 0.2))
		btn_adm.pressed.connect( func() -> void :
			RankingOnline.envio_inicial()
			_ranking_carregando = false
			_carregar_ranking()
			btn_adm.text = "Sincronizando..."
			btn_adm.disabled = true
			await get_tree().create_timer(4.0).timeout
			if btn_adm and is_instance_valid(btn_adm):
				btn_adm.text = "ADMIN: FORCAR SYNC"
				btn_adm.disabled = false
		)
		bg.add_child(btn_adm)


	if not RankingOnline.ranking_carregado.is_connected(_on_ranking_carregado):
		RankingOnline.ranking_carregado.connect(_on_ranking_carregado)
	if not RankingOnline.campeoes_temporada_anterior_carregados.is_connected(_on_campeoes_temporada_anterior_carregados):
		RankingOnline.campeoes_temporada_anterior_carregados.connect(_on_campeoes_temporada_anterior_carregados)


	if Salvar.nome_jogador.strip_edges() == "":
		var banner:= Panel.new()
		banner.name = "BannerSemNome"
		banner.position = Vector2(20, 344)
		banner.size = Vector2(VW - 40, 76)
		banner.z_index = 2
		var sty_b:= StyleBoxFlat.new()
		sty_b.bg_color = Color(0.1, 0.07, 0.02, 0.97)
		sty_b.border_color = Color(1.0, 0.78, 0.1, 0.8)
		for s in ["left", "right", "top", "bottom"]: sty_b.set("border_width_" + s, 1)
		for c2 in ["top_left", "top_right", "bottom_left", "bottom_right"]: sty_b.set("corner_radius_" + c2, 8)
		banner.add_theme_stylebox_override("panel", sty_b)
		bg.add_child(banner)

		var lban:= Label.new()
		lban.text = "Voce ainda nao definiu seu nome â€” configure no perfil para aparecer no ranking!"
		lban.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lban.autowrap_mode = TextServer.AUTOWRAP_WORD
		lban.position = Vector2(10, 5)
		lban.size = Vector2(VW - 280, 66)
		lban.add_theme_font_size_override("font_size", 19)
		lban.add_theme_color_override("font_color", Color(1.0, 0.88, 0.3))
		banner.add_child(lban)

		var btn_ir:= Button.new()
		btn_ir.text = "IR AO PERFIL"
		btn_ir.position = Vector2(VW - 268, 8)
		btn_ir.size = Vector2(240, 58)
		btn_ir.focus_mode = Control.FOCUS_NONE
		btn_ir.add_theme_font_size_override("font_size", 18)
		var sty_ir:= StyleBoxFlat.new()
		sty_ir.bg_color = Color(0.18, 0.12, 0.02, 0.95)
		sty_ir.border_color = Color(1.0, 0.78, 0.1, 1.0)
		for s in ["left", "right", "top", "bottom"]: sty_ir.set("border_width_" + s, 2)
		for c2 in ["top_left", "top_right", "bottom_left", "bottom_right"]: sty_ir.set("corner_radius_" + c2, 6)
		btn_ir.add_theme_stylebox_override("normal", sty_ir)
		btn_ir.add_theme_color_override("font_color", Color(1.0, 0.9, 0.3))
		btn_ir.pressed.connect( func():
			_fechar_ranking()
			_abrir_perfil(_ui_main)
		)
		banner.add_child(btn_ir)

	_carregar_ranking()


func _fechar_ranking() -> void :
	if _ranking_overlay and is_instance_valid(_ranking_overlay):
		_ranking_overlay.queue_free()
	_ranking_overlay = null
	_ranking_panel = null
	_ranking_lista = null
	_ranking_ts_lbl = null
	_ranking_pos_lbl = null
	_ranking_campeoes_cont = null
	if _menu_contents:
		_menu_contents.show()


func _abrir_patente(ui: CanvasLayer) -> void:
	if _attributes_screen and is_instance_valid(_attributes_screen):
		return
	if _menu_contents:
		_menu_contents.hide()
	_attributes_screen = ATTRIBUTES_SCREEN.instantiate()
	_attributes_screen.closed.connect(_fechar_patente)
	ui.add_child(_attributes_screen)


func _rebuild_patente() -> void:
	if not _patente_panel or not is_instance_valid(_patente_panel):
		return
	for ch in _patente_panel.get_children():
		ch.queue_free()
	var p : Panel = _patente_panel as Panel
	var pw : float = p.size.x
	var ph : float = p.size.y
	var cor := Color(1.0, 0.78, 0.16)
	var xp_need : int = Salvar.xp_para_proximo_nivel()
	var xp_pct : float = clampf(float(Salvar.xp_conta) / maxf(float(xp_need), 1.0), 0.0, 1.0)
	var bg_fx := Control.new()
	bg_fx.size = Vector2(pw, ph)
	bg_fx.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bg_fx.draw.connect(func():
		bg_fx.draw_rect(Rect2(Vector2.ZERO, bg_fx.size), Color(0.004, 0.006, 0.014, 0.99))
		bg_fx.draw_circle(Vector2(pw * 0.58, 184.0), 270.0, Color(0.35, 0.12, 0.75, 0.11))
		bg_fx.draw_circle(Vector2(pw * 0.60, 220.0), 176.0, Color(0.15, 0.46, 1.0, 0.055))
		bg_fx.draw_arc(Vector2(pw * 0.60, 230.0), 230.0, -PI * 0.96, -PI * 0.04, 128, Color(0.90, 0.55, 1.0, 0.24), 3.0, true)
		bg_fx.draw_rect(Rect2(16, 16, pw - 32, ph - 32), Color(0.05, 0.08, 0.16, 0.28), false, 1.0)
		for i in range(15):
			var x := 34.0 + float(i) * 68.0
			bg_fx.draw_line(Vector2(x, 22), Vector2(x - 80.0, ph - 54), Color(0.35, 0.15, 1.0, 0.030), 1.0)
		for i in range(36):
			var sx := fmod(float(i * 83), pw - 54.0) + 27.0
			var sy := fmod(float(i * 47), ph - 90.0) + 38.0
			bg_fx.draw_circle(Vector2(sx, sy), 1.0 + float(i % 3) * 0.4, Color(0.55, 0.78, 1.0, 0.20))
		for corner in [Vector2(20, 20), Vector2(pw - 20, 20), Vector2(20, ph - 20), Vector2(pw - 20, ph - 20)]:
			bg_fx.draw_circle(corner, 3.0, Color(1.0, 0.78, 0.16, 0.85))
	)
	p.add_child(bg_fx)
	var top := Control.new()
	top.position = Vector2(28, 28)
	top.size = Vector2(pw - 56, 190)
	top.mouse_filter = Control.MOUSE_FILTER_IGNORE
	top.draw.connect(func():
		top.draw_rect(Rect2(Vector2.ZERO, top.size), Color(0.012, 0.016, 0.035, 0.74))
		top.draw_rect(Rect2(Vector2.ZERO, top.size), Color(0.28, 0.16, 1.0, 0.38), false, 1.2)
		top.draw_line(Vector2(132, 122), Vector2(top.size.x - 320, 122), Color(0.54, 0.20, 1.0, 0.28), 1.0)
		top.draw_line(Vector2(132, 158), Vector2(top.size.x - 360, 158), Color(0.2, 0.9, 1.0, 0.18), 1.0)
	)
	p.add_child(top)
	_inv_lbl(p, "PATENTE ESPACIAL", 72, 44, 260, 24, 16, Color(0.78, 0.38, 1.0))
	_inv_lbl(p, "NIVEL DA CONTA", 72, 68, 336, 44, 33, Color(0.95, 0.96, 1.0))
	_inv_lbl(p, "%d" % Salvar.nivel_conta, 370, 68, 86, 48, 38, Color(0.70, 0.25, 1.0))
	_inv_lbl(p, Salvar.patente_conta().to_upper(), 72, 116, 360, 28, 19, Color(0.78, 0.32, 1.0))
	var prox : Dictionary = Salvar.proxima_patente_conta()
	var prox_txt : String = "PATENTE MAXIMA ALCANCADA" if prox.is_empty() else "PROXIMA PATENTE: %s (NV. %d)" % [str(prox.get("nome", "")).to_upper(), int(prox.get("nivel", 0))]
	_inv_lbl(p, "XP: %d / %d" % [Salvar.xp_conta, xp_need], 72, 150, 120, 22, 14, Color(0.78, 0.84, 0.95))
	_inv_lbl(p, prox_txt, 72, 178, 430, 20, 12, Color(0.62, 0.70, 0.84))
	var bar := Control.new()
	bar.position = Vector2(194, 154)
	bar.size = Vector2(390, 12)
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bar.draw.connect(func():
		bar.draw_rect(Rect2(Vector2.ZERO, bar.size), Color(0.0, 0.0, 0.0, 0.64))
		bar.draw_rect(Rect2(Vector2(2, 2), Vector2(maxf(0.0, (bar.size.x - 4.0) * xp_pct), bar.size.y - 4.0)), Color(0.72, 0.28, 1.0, 0.96))
		bar.draw_rect(Rect2(Vector2.ZERO, bar.size), Color(0.72, 0.28, 1.0, 0.76), false, 1.4)
		bar.draw_circle(Vector2(2.0 + (bar.size.x - 4.0) * xp_pct, bar.size.y * 0.5), 6.0, Color(1.0, 0.75, 1.0, 0.78))
	)
	p.add_child(bar)
	_inv_lbl(p, "ATRIBUTOS DA CONTA", 0, 228, pw, 34, 24, Color(0.92, 0.92, 1.0), HORIZONTAL_ALIGNMENT_CENTER)
	_inv_lbl(p, "PONTOS DISPONIVEIS", pw * 0.5 - 145, 264, 210, 22, 14, Color(0.78, 0.34, 1.0), HORIZONTAL_ALIGNMENT_RIGHT)
	_inv_lbl(p, "%d" % Salvar.pontos_atributo, pw * 0.5 + 78, 255, 50, 38, 29, Color(0.86, 0.45, 1.0), HORIZONTAL_ALIGNMENT_CENTER)
	_inv_lbl(p, "Cada nivel concede +1 ponto permanente.", 38, 296, pw - 330, 18, 11, Color(0.58, 0.64, 0.82), HORIZONTAL_ALIGNMENT_CENTER)
	var card_ids : Array[String] = ["vida", "defesa", "dano", "agilidade", "alcance", "fortuna", "critico", "tecnologia"]
	var left_x := 34.0
	var right_w := 230.0
	var left_w := pw - right_w - 90.0
	var cgap := 16.0
	var card_w := (left_w - cgap * 3.0) / 4.0
	var card_h := minf(128.0, (ph - 382.0) / 2.0)
	var card_y := 322.0
	for i in range(card_ids.size()):
		var row : int = i / 4
		var col : int = i % 4
		_criar_patente_card_dashboard(p, card_ids[i], Vector2(left_x + float(col) * (card_w + cgap), card_y + float(row) * (card_h + 16.0)), Vector2(card_w, card_h))
	_criar_patente_resumo_bonus(p, Vector2(pw - right_w - 34.0, 304.0), Vector2(right_w, ph - 358.0))
	var fechar := Button.new()
	fechar.text = "VOLTAR"
	fechar.position = Vector2((pw - 180.0) * 0.5, ph - 54.0)
	fechar.size = Vector2(180.0, 36.0)
	fechar.focus_mode = Control.FOCUS_NONE
	fechar.add_theme_font_size_override("font_size", 14)
	_ui_premium_button(fechar, Color(0.10, 0.72, 0.86), false)
	fechar.pressed.connect(_fechar_patente)
	p.add_child(fechar)


func _criar_patente_recurso(parent: Node, pos: Vector2, icone: String, valor: int, cor: Color) -> void:
	var box := Control.new()
	box.position = pos
	box.size = Vector2(86, 34)
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.draw.connect(func():
		box.draw_rect(Rect2(Vector2.ZERO, box.size), Color(0.015, 0.020, 0.040, 0.82))
		box.draw_rect(Rect2(Vector2.ZERO, box.size), Color(cor.r, cor.g, cor.b, 0.34), false, 1.0)
		box.draw_circle(Vector2(16, 17), 10.0, Color(cor.r, cor.g, cor.b, 0.20))
		box.draw_arc(Vector2(16, 17), 10.0, 0.0, TAU, 28, Color(cor.r, cor.g, cor.b, 0.95), 1.4, true)
		box.draw_string(_font_tech, Vector2(10, 22), icone, HORIZONTAL_ALIGNMENT_CENTER, 12, 14, cor)
		box.draw_string(_font_tech, Vector2(32, 23), _format_num(valor), HORIZONTAL_ALIGNMENT_LEFT, 50, 16, Color(0.92, 0.94, 1.0))
	)
	parent.add_child(box)


func _format_num(v: int) -> String:
	return NumberFormatter.compact_int(v)


func _criar_patente_card_dashboard(parent: Node, aid: String, pos: Vector2, sz: Vector2) -> void:
	var info : Dictionary = Salvar.ATRIBUTOS_CONTA_INFO[aid] as Dictionary
	var lvl : int = int(Salvar.atributos_conta.get(aid, 0))
	var max_lvl : int = int(info.get("max", 0))
	var cor : Color = _patente_attr_cor(aid)
	var card := _inv_painel(parent, pos.x, pos.y, sz.x, sz.y,
		Color(cor.r * 0.045, cor.g * 0.045, cor.b * 0.060, 0.94),
		Color(cor.r, cor.g, cor.b, 0.76), 1)
	card.mouse_filter = Control.MOUSE_FILTER_PASS
	var fx := Control.new()
	fx.size = sz
	fx.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fx.draw.connect(func():
		var cut := 13.0
		var poly := PackedVector2Array([
			Vector2(cut, 0), Vector2(sz.x - cut, 0), Vector2(sz.x, cut),
			Vector2(sz.x, sz.y - cut), Vector2(sz.x - cut, sz.y), Vector2(cut, sz.y),
			Vector2(0, sz.y - cut), Vector2(0, cut), Vector2(cut, 0)
		])
		fx.draw_colored_polygon(poly, Color(cor.r * 0.035, cor.g * 0.035, cor.b * 0.050, 0.98))
		fx.draw_polyline(poly, Color(cor.r, cor.g, cor.b, 0.95), 1.5)
		fx.draw_circle(Vector2(34, 34), 27.0, Color(cor.r, cor.g, cor.b, 0.12))
		fx.draw_arc(Vector2(34, 34), 27.0, -PI * 0.78 + pulse * 0.5, PI * 1.18 + pulse * 0.5, 58, Color(cor.r, cor.g, cor.b, 0.95), 2.4, true)
		_draw_patente_card_icon(fx, aid, Vector2(34, 34), cor)
		var segs := mini(12, max_lvl)
		var filled := int(round(float(lvl) / maxf(float(max_lvl), 1.0) * float(segs)))
		var sx := 16.0
		var sy := 76.0
		var sw := (sz.x - 32.0 - float(segs - 1) * 3.0) / float(segs)
		for si in range(segs):
			var r := Rect2(sx + float(si) * (sw + 3.0), sy, sw, 6.0)
			fx.draw_rect(r, Color(cor.r, cor.g, cor.b, 0.90 if si < filled else 0.16))
			fx.draw_rect(r, Color(cor.r, cor.g, cor.b, 0.34), false, 0.8)
		fx.draw_circle(Vector2(sz.x - 24, sz.y - 26), 26.0, Color(cor.r, cor.g, cor.b, 0.075))
	)
	card.add_child(fx)
	_inv_lbl(card, str(info.get("nome", aid)).to_upper(), 70, 17, sz.x - 134, 20, 13, cor)
	_inv_lbl(card, "%d/%d" % [lvl, max_lvl], sz.x - 56, 18, 44, 18, 10, Color(0.78, 0.84, 0.92), HORIZONTAL_ALIGNMENT_RIGHT)
	_inv_lbl(card, _patente_total_bonus_text(aid, lvl), 12, sz.y - 38, sz.x - 56, 18, 12, Color(cor.r + 0.18, cor.g + 0.18, cor.b + 0.18), HORIZONTAL_ALIGNMENT_CENTER)
	var plus := Button.new()
	plus.text = "+"
	plus.position = Vector2(sz.x - 38, sz.y - 38)
	plus.size = Vector2(30, 30)
	plus.focus_mode = Control.FOCUS_NONE
	plus.disabled = Salvar.pontos_atributo <= 0 or lvl >= max_lvl
	plus.add_theme_font_size_override("font_size", 18)
	_ui_premium_button(plus, cor, not plus.disabled)
	plus.pressed.connect(_on_patente_atributo_pressed.bind(aid))
	card.add_child(plus)


func _draw_patente_card_icon(c: Control, aid: String, center: Vector2, cor: Color) -> void:
	match aid:
		"vida":
			var heart := PackedVector2Array([center + Vector2(0, 15), center + Vector2(-18, -2), center + Vector2(-9, -16), center, center + Vector2(9, -16), center + Vector2(18, -2), center + Vector2(0, 15)])
			c.draw_colored_polygon(heart, Color(cor.r, cor.g, cor.b, 0.90))
		"defesa":
			var sh := PackedVector2Array([center + Vector2(0, -18), center + Vector2(17, -8), center + Vector2(12, 14), center + Vector2(0, 21), center + Vector2(-12, 14), center + Vector2(-17, -8), center + Vector2(0, -18)])
			c.draw_polyline(sh, Color(cor.r, cor.g, cor.b, 0.95), 2.0)
		"dano":
			c.draw_arc(center, 18, 0, TAU, 42, Color(cor.r, cor.g, cor.b, 0.95), 2.0, true)
			c.draw_line(center + Vector2(-17, 0), center + Vector2(17, 0), cor, 1.8)
			c.draw_line(center + Vector2(0, -17), center + Vector2(0, 17), cor, 1.8)
		"agilidade":
			c.draw_line(center + Vector2(-14, 13), center + Vector2(16, -15), cor, 3.0)
			c.draw_line(center + Vector2(-4, 16), center + Vector2(20, -7), Color(cor.r, cor.g, cor.b, 0.62), 2.0)
		"alcance":
			for r in [8.0, 15.0, 22.0]:
				c.draw_arc(center, r, -PI * 0.82, -PI * 0.18, 22, Color(cor.r, cor.g, cor.b, 0.78), 1.6, true)
			c.draw_line(center, center + Vector2(0, 20), cor, 2.0)
		"fortuna":
			c.draw_circle(center + Vector2(-5, 3), 9.0, Color(cor.r, cor.g, cor.b, 0.88))
			c.draw_circle(center + Vector2(7, -5), 9.0, Color(cor.r, cor.g, cor.b, 0.62))
		"critico":
			var star := PackedVector2Array()
			for i in range(11):
				var rr := 20.0 if i % 2 == 0 else 7.0
				var a := -PI * 0.5 + float(i) * TAU / 10.0
				star.append(center + Vector2(cos(a), sin(a)) * rr)
			c.draw_colored_polygon(star, Color(cor.r, cor.g, cor.b, 0.92))
		"tecnologia":
			c.draw_rect(Rect2(center - Vector2(14, 14), Vector2(28, 28)), Color(cor.r, cor.g, cor.b, 0.28), false, 2.0)
			c.draw_rect(Rect2(center - Vector2(7, 7), Vector2(14, 14)), Color(cor.r, cor.g, cor.b, 0.86), false, 1.6)
		_:
			c.draw_string(_font_title, center + Vector2(-18, 8), _patente_attr_sigla(aid), HORIZONTAL_ALIGNMENT_CENTER, 36, 18, cor)


func _patente_total_bonus_text(aid: String, lvl: int) -> String:
	match aid:
		"vida": return "+%d HP" % (lvl * 8)
		"dano": return "+%d%% DANO" % lvl
		"defesa": return "-%.1f%% DANO" % (float(lvl) * 0.3)
		"agilidade": return "+%.1f%% CADENCIA" % (float(lvl) * 0.6)
		"alcance": return "+%d ALCANCE" % (lvl * 3)
		"fortuna": return "+%d%% OURO" % lvl
		"critico": return "+%.1f%% CRITICO" % (float(lvl) * 0.25)
		"tecnologia": return "-%.1f%% COOLDOWN" % (float(lvl) * 0.4)
	return ""


func _criar_patente_resumo_bonus(parent: Node, pos: Vector2, sz: Vector2) -> void:
	var panel := _inv_painel(parent, pos.x, pos.y, sz.x, sz.y, Color(0.010, 0.014, 0.030, 0.94), Color(0.34, 0.42, 0.80, 0.58), 1)
	_inv_lbl(panel, "RESUMO DE BONUS", 0, 12, sz.x, 22, 13, Color(0.78, 0.84, 1.0), HORIZONTAL_ALIGNMENT_CENTER)
	var ids : Array[String] = ["vida", "defesa", "dano", "agilidade", "alcance", "fortuna", "critico", "tecnologia"]
	for i in range(ids.size()):
		var aid := ids[i]
		var lvl : int = int(Salvar.atributos_conta.get(aid, 0))
		var y := 38.0 + float(i) * 21.0
		var cor := _patente_attr_cor(aid)
		var row := Control.new()
		row.position = Vector2(12, y)
		row.size = Vector2(sz.x - 24, 20)
		row.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.draw.connect(func():
			row.draw_line(Vector2(0, 19), Vector2(row.size.x, 19), Color(0.25, 0.32, 0.55, 0.28), 1.0)
			row.draw_circle(Vector2(10, 10), 8.0, Color(cor.r, cor.g, cor.b, 0.18))
			row.draw_arc(Vector2(10, 10), 8.0, 0.0, TAU, 22, Color(cor.r, cor.g, cor.b, 0.88), 1.2, true)
			row.draw_string(_font_tech, Vector2(26, 14), _patente_total_bonus_text(aid, lvl), HORIZONTAL_ALIGNMENT_LEFT, row.size.x - 26, 12, Color(cor.r + 0.10, cor.g + 0.10, cor.b + 0.10, 0.95))
		)
		panel.add_child(row)
	if sz.y >= 232.0:
		_inv_lbl(panel, "COMO FUNCIONA", 0, sz.y - 72, sz.x, 18, 11, Color(0.86, 0.86, 1.0), HORIZONTAL_ALIGNMENT_CENTER)
		var desc := Label.new()
		desc.text = "Ganhe XP nas partidas.\nCada nivel concede 1 ponto.\nOs bonus sao permanentes."
		desc.position = Vector2(16, sz.y - 50)
		desc.size = Vector2(sz.x - 32, 42)
		desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		desc.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		desc.add_theme_font_size_override("font_size", 9)
		desc.add_theme_color_override("font_color", Color(0.62, 0.68, 0.86))
		_ui_tech_label(desc, 0.0)
		desc.mouse_filter = Control.MOUSE_FILTER_IGNORE
		panel.add_child(desc)


func _criar_patente_nav_inferior(parent: Node, pw: float, ph: float) -> void:
	var nav := Control.new()
	nav.position = Vector2(28, ph - 48)
	nav.size = Vector2(pw - 190, 30)
	nav.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var labels : Array[String] = ["INICIO", "ARSENAL", "COMANDANTES", "ATRIBUTOS", "INVENTARIO", "MISSOES", "LOJA"]
	nav.draw.connect(func():
		nav.draw_rect(Rect2(Vector2.ZERO, nav.size), Color(0.010, 0.014, 0.032, 0.92))
		nav.draw_rect(Rect2(Vector2.ZERO, nav.size), Color(0.25, 0.40, 0.90, 0.35), false, 1.0)
		var item_w := nav.size.x / float(labels.size())
		for i in range(labels.size()):
			var x := float(i) * item_w
			var active := labels[i] == "ATRIBUTOS"
			var cc := Color(0.72, 0.28, 1.0, 0.30) if active else Color(0.10, 0.16, 0.32, 0.28)
			nav.draw_rect(Rect2(x + 2, 3, item_w - 4, nav.size.y - 6), cc)
			nav.draw_line(Vector2(x + item_w, 6), Vector2(x + item_w, nav.size.y - 6), Color(0.25, 0.40, 0.90, 0.22), 1.0)
			nav.draw_string(_font_tech, Vector2(x, 20), labels[i], HORIZONTAL_ALIGNMENT_CENTER, item_w, 11, Color(0.95, 0.80, 1.0, 0.98) if active else Color(0.64, 0.70, 0.88, 0.84))
	)
	parent.add_child(nav)


func _criar_patente_modulo(parent: Node, aid: String, pos: Vector2, sz: Vector2) -> void:
	var info : Dictionary = Salvar.ATRIBUTOS_CONTA_INFO[aid] as Dictionary
	var lvl : int = int(Salvar.atributos_conta.get(aid, 0))
	var max_lvl : int = int(info.get("max", 0))
	var cor : Color = _patente_attr_cor(aid)
	var card := _inv_painel(parent, pos.x, pos.y, sz.x, sz.y,
		Color(cor.r * 0.055, cor.g * 0.055, cor.b * 0.065, 0.96),
		Color(cor.r, cor.g, cor.b, 0.74), 1)
	card.mouse_filter = Control.MOUSE_FILTER_PASS
	var fx := Control.new()
	fx.size = sz
	fx.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fx.draw.connect(func():
		var cut := 13.0
		var poly := PackedVector2Array([
			Vector2(cut, 0), Vector2(sz.x - cut, 0), Vector2(sz.x, cut),
			Vector2(sz.x, sz.y - cut), Vector2(sz.x - cut, sz.y), Vector2(cut, sz.y),
			Vector2(0, sz.y - cut), Vector2(0, cut), Vector2(cut, 0)
		])
		fx.draw_colored_polygon(poly, Color(cor.r * 0.035, cor.g * 0.035, cor.b * 0.052, 0.98))
		fx.draw_polyline(poly, Color(cor.r, cor.g, cor.b, 0.92), 1.6)
		fx.draw_circle(Vector2(33, 34), 24.0, Color(cor.r, cor.g, cor.b, 0.10))
		fx.draw_arc(Vector2(33, 34), 24.0, -PI * 0.80 + pulse * 0.55, PI * 1.20 + pulse * 0.55, 64, Color(cor.r, cor.g, cor.b, 0.95), 2.8, true)
		fx.draw_arc(Vector2(33, 34), 16.0, PI * 0.20 - pulse * 0.35, PI * 1.72 - pulse * 0.35, 42, Color(1.0, 1.0, 1.0, 0.22), 1.2, true)
		fx.draw_string(_font_title, Vector2(15, 40), _patente_attr_sigla(aid), HORIZONTAL_ALIGNMENT_CENTER, 36, 18, Color(cor.r + 0.22, cor.g + 0.22, cor.b + 0.22, 0.96))
		var pct := clampf(float(lvl) / maxf(float(max_lvl), 1.0), 0.0, 1.0)
		fx.draw_rect(Rect2(12, sz.y - 12, sz.x - 24, 4), Color(0.0, 0.0, 0.0, 0.58))
		fx.draw_rect(Rect2(12, sz.y - 12, (sz.x - 24) * pct, 4), Color(cor.r, cor.g, cor.b, 0.96))
		fx.draw_circle(Vector2(sz.x - 22, sz.y - 20), 24.0, Color(cor.r, cor.g, cor.b, 0.055))
	)
	card.add_child(fx)
	_inv_lbl(card, str(info.get("nome", aid)).to_upper(), 66, 13, sz.x - 104, 20, 14, cor)
	_inv_lbl(card, "Nv %d/%d" % [lvl, max_lvl], sz.x - 66, 15, 50, 17, 11, Color(0.78, 0.84, 0.92), HORIZONTAL_ALIGNMENT_RIGHT)
	_inv_lbl(card, str(info.get("desc", "")), 16, 48, sz.x - 58, 20, 11, Color(0.60, 0.70, 0.82))
	var plus := Button.new()
	plus.text = "+"
	plus.position = Vector2(sz.x - 40, sz.y - 42)
	plus.size = Vector2(30, 30)
	plus.focus_mode = Control.FOCUS_NONE
	plus.disabled = Salvar.pontos_atributo <= 0 or lvl >= max_lvl
	plus.add_theme_font_size_override("font_size", 18)
	_ui_premium_button(plus, cor, not plus.disabled)
	plus.pressed.connect(_on_patente_atributo_pressed.bind(aid))
	card.add_child(plus)


func _on_patente_atributo_pressed(id: String) -> void:
	if Salvar.gastar_ponto_atributo(id):
		_rebuild_patente()


func _patente_attr_sigla(id: String) -> String:
	match id:
		"vida": return "HP"
		"dano": return "DM"
		"defesa": return "DF"
		"agilidade": return "AG"
		"alcance": return "AL"
		"fortuna": return "$"
		"critico": return "CR"
		"tecnologia": return "TC"
	return "++"


func _patente_attr_cor(id: String) -> Color:
	match id:
		"vida": return Color(0.24, 1.0, 0.50)
		"dano": return Color(1.0, 0.35, 0.16)
		"defesa": return Color(0.35, 0.70, 1.0)
		"agilidade": return Color(0.78, 0.35, 1.0)
		"alcance": return Color(0.16, 0.85, 1.0)
		"fortuna": return Color(1.0, 0.78, 0.16)
		"critico": return Color(1.0, 0.50, 0.08)
		"tecnologia": return Color(0.30, 1.0, 0.86)
	return Color(0.85, 0.9, 1.0)


func _fechar_patente() -> void:
	if _attributes_screen and is_instance_valid(_attributes_screen):
		_attributes_screen.queue_free()
	_attributes_screen = null
	if _patente_overlay and is_instance_valid(_patente_overlay):
		_patente_overlay.queue_free()
	_patente_overlay = null
	_patente_panel = null
	if _menu_contents:
		_menu_contents.show()


func _carregar_ranking() -> void :
	if _ranking_carregando:
		return
	_ranking_carregando = true


	var estimado: Array = RankingOnline.get_lista_estimada()
	_popular_lista(estimado, true)


	_atualizar_timestamp(true)


	RankingOnline.buscar_ranking()
	RankingOnline.buscar_campeoes_temporada_anterior()


func _atualizar_timestamp(estimado: bool) -> void :
	if not _ranking_ts_lbl or not is_instance_valid(_ranking_ts_lbl):
		return
	var seg: int = RankingOnline.segundos_desde_atualizacao()
	if seg < 0:
		_ranking_ts_lbl.text = "Sem dados em cache â€” sincronizando..."
	elif estimado:
		if seg < 60:
			_ranking_ts_lbl.text = "Estimado · atualizado há menos de 1 min"
		elif seg < 3600:
			_ranking_ts_lbl.text = "Estimado · atualizado há %d min" % (seg / 60)
		else:
			_ranking_ts_lbl.text = "Estimado · atualizado há %dh" % (seg / 3600)
	else:
		_ranking_ts_lbl.text = "Dados reais do servidor"


func _ranking_tempo_temporada_texto() -> String:
	var seg: int = RankingOnline.segundos_para_fim_temporada()
	var dias: int = seg / 86400
	var horas: int = (seg % 86400) / 3600
	var mins: int = (seg % 3600) / 60
	if dias > 0:
		return "%dd %dh" % [dias, horas]
	if horas > 0:
		return "%dh %dmin" % [horas, mins]
	return "%dmin" % maxi(1, mins)


## Retorna 0-5: nivel do badge de prestigio baseado em quantidade de ascensoes.
## 0=sem badge, 1=primeira ascensao, 2=5 asc, 3=10, 4=15, 5=20+
func _nivel_prestigio(asc: int) -> int:
	# 8 badges: progressao crescente
	if asc <= 0:  return 0
	if asc <= 2:  return 1
	if asc <= 5:  return 2
	if asc <= 10: return 3
	if asc <= 18: return 4
	if asc <= 30: return 5
	if asc <= 50: return 6
	if asc <= 80: return 7
	return 8


## Carrega (com cache via meta) o simbolo de prestigio do nivel especificado.
## Busca res://assets/prestigio/prestigio_N.png (N = 1..16).
## Retorna null se a imagem nao existir — o render usa fallback textual (✦).
func _carregar_simbolo_prestigio(nivel: int) -> Texture2D:
	if nivel <= 0: return null
	var _ck_done := "_simb_prest_%d_ok" % nivel
	var _ck_tex  := "_simb_prest_%d" % nivel
	if has_meta(_ck_done):
		return get_meta(_ck_tex) if has_meta(_ck_tex) else null
	set_meta(_ck_done, true)
	var _paths := [
		"res://assets/prestigio/prestigio_%d.png" % nivel,
		"res://assets/ui/prestigio_%d.png" % nivel,
		"res://assets/prestigio_%d.png" % nivel,
	]
	for _p in _paths:
		if ResourceLoader.exists(_p):
			var _t = load(_p)
			if _t is Texture2D:
				set_meta(_ck_tex, _t)
				return _t
	return null


func _on_ranking_carregado(entradas: Array) -> void :
	_ranking_carregando = false
	if not _ranking_panel or not is_instance_valid(_ranking_panel):
		return
	if not _ranking_lista or not is_instance_valid(_ranking_lista):
		return
	_popular_lista(entradas, false)
	_atualizar_timestamp(false)


func _on_campeoes_temporada_anterior_carregados(temporada: int, entradas: Array) -> void :
	_render_campeoes_temporada_anterior(temporada, entradas)


func _render_campeoes_temporada_anterior(temporada: int, entradas: Array) -> void :
	if not _ranking_campeoes_cont or not is_instance_valid(_ranking_campeoes_cont):
		return
	for ch in _ranking_campeoes_cont.get_children():
		ch.queue_free()
	if temporada < 0 or entradas.is_empty():
		_ranking_campeoes_cont.visible = false
		return
	_ranking_campeoes_cont.visible = true
	var medalhas: Array = ["🥇", "🥈", "🥉"]
	var partes: Array = []
	for i in range(mini(3, entradas.size())):
		var e: Dictionary = entradas[i] as Dictionary
		var nome: String = String(e.get("nome", "?")).strip_edges()
		if nome == "":
			nome = "?"
		var medalha: String = medalhas[i] if i < medalhas.size() else ""
		partes.append("%s %s" % [medalha, nome])
	var lbl:= Label.new()
	lbl.text = "Campeões T%d:  %s" % [temporada, "   ".join(partes)]
	lbl.add_theme_font_size_override("font_size", 13)
	lbl.add_theme_color_override("font_color", Color(1.0, 0.85, 0.25))
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	lbl.size = _ranking_campeoes_cont.size
	_ranking_campeoes_cont.add_child(lbl)


func _popular_lista(entradas: Array, is_estimado: bool) -> void :
	if not _ranking_lista or not is_instance_valid(_ranking_lista):
		return
	for ch in _ranking_lista.get_children():
		ch.queue_free()
	entradas = entradas.duplicate(true)
	entradas.sort_custom(func(a, b):
		var da: Dictionary = a as Dictionary
		var db: Dictionary = b as Dictionary
		var wa: int = int(da.get("wave", 0))
		var wb: int = int(db.get("wave", 0))
		if wa == wb:
			return int(da.get("score", 0)) > int(db.get("score", 0))
		return wa > wb
	)
	var _vw: float = get_viewport().get_visible_rect().size.x
	var _row_w: float = _vw - 40.0


	var _nome_local:= Salvar.nome_jogador.strip_edges()
	var entradas_podio:= entradas.duplicate(true)
	for _ep in range(entradas_podio.size()):
		var _ed: Dictionary = entradas_podio[_ep] as Dictionary
		var _en: String = str(_ed.get("nome", "")).strip_edges()
		var _el: bool = _ed.get("local", false) as bool
		if _el or (_nome_local != "" and _en == _nome_local):
			_ed["avatar_idx"] = Salvar.avatar_idx
			entradas_podio[_ep] = _ed


	if _ranking_panel and is_instance_valid(_ranking_panel):
		for ch in _ranking_panel.get_children():
			if ch.get_meta("podio", false):
				(ch as Control).set_meta("entries", entradas_podio)
				(ch as Control).queue_redraw()
				break

	if entradas.is_empty():
		var vazio:= Label.new()
		vazio.text = "Nenhum recorde por wave registrado ainda."
		vazio.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		vazio.add_theme_font_size_override("font_size", 22)
		vazio.add_theme_color_override("font_color", Color(0.5, 0.55, 0.6))
		_ranking_lista.add_child(vazio)
		return

	var nome_local: String = Salvar.nome_jogador.strip_edges()


	if _ranking_pos_lbl and is_instance_valid(_ranking_pos_lbl) and nome_local != "":
		var pos_jogador: int = -1
		for pi in range(entradas.size()):
			var pe: Dictionary = entradas[pi] as Dictionary
			var pn: String = pe.get("nome", "") as String
			var pe_local: bool = pe.get("local", false) as bool
			if pe_local or (pn == nome_local):
				pos_jogador = pi + 1
				break
		if pos_jogador > 0:
			_ranking_pos_lbl.text = "Sua posição: %dº lugar" % pos_jogador
		else:
			_ranking_pos_lbl.text = "Voce nao esta no top %d ainda" % entradas.size()

	for i in range(entradas.size()):
		var e: Dictionary = entradas[i] as Dictionary
		var nome: String = e.get("nome", "???") as String
		var scr: int = int(e.get("score", 0))
		var wave: int = int(e.get("wave", 0))
		var pos: int = i + 1
		var e_local: bool = e.get("local", false) as bool
		var e_voce: bool = e_local or (nome_local != "" and nome == nome_local)

		var row:= Control.new()
		row.custom_minimum_size = Vector2(_row_w, 44)
		row.mouse_filter = Control.MOUSE_FILTER_PASS


		var row_bg:= ColorRect.new()
		row_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row_bg.size = Vector2(_row_w, 44)
		if e_voce:
			row_bg.color = Color(0.1, 0.6, 1.0, 0.13)
		elif pos == 1:
			row_bg.color = Color(1.0, 0.82, 0.0, 0.1)
		elif pos == 2:
			row_bg.color = Color(0.75, 0.75, 0.75, 0.07)
		elif pos == 3:
			row_bg.color = Color(0.72, 0.38, 0.1, 0.1)
		elif i % 2 == 0:
			row_bg.color = Color(1.0, 1.0, 1.0, 0.03)
		else:
			row_bg.color = Color(0.0, 0.0, 0.0, 0.0)
		row.add_child(row_bg)


		var medal_txt: String
		var medal_cor: Color
		match pos:
			1: medal_txt = "1.";medal_cor = Color(1.0, 0.85, 0.1)
			2: medal_txt = "2.";medal_cor = Color(0.82, 0.82, 0.82)
			3: medal_txt = "3.";medal_cor = Color(0.8, 0.5, 0.2)
			_: medal_txt = str(pos);medal_cor = Color(0.5, 0.6, 0.7)

		var lbl_pos:= Label.new()
		lbl_pos.text = medal_txt
		lbl_pos.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl_pos.position = Vector2(0, 0)
		lbl_pos.size = Vector2(66, 44)
		lbl_pos.add_theme_font_size_override("font_size", 20)
		lbl_pos.add_theme_color_override("font_color", medal_cor)
		lbl_pos.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.add_child(lbl_pos)


		var _asc: int = int(e.get("ascensoes", 0))
		var _nivel_asc: int = _nivel_prestigio(_asc)

		var _row_av_idx: int = -1
		if e_voce:
			_row_av_idx = Salvar.avatar_idx
		else:
			var _rv = e.get("avatar_idx", null)
			if _rv != null:
				var _rvt:= typeof(_rv)
				if _rvt == TYPE_INT or _rvt == TYPE_FLOAT:
					var _rvi:= int(_rv)
					if _rvi >= 0 and _rvi < 5:
						_row_av_idx = _rvi
		if _row_av_idx >= 0:
			var av_ctrl:= Control.new()
			av_ctrl.position = Vector2(66, 4)
			av_ctrl.size = Vector2(36, 36)
			av_ctrl.mouse_filter = Control.MOUSE_FILTER_IGNORE
			var _cap_av     := _row_av_idx
			var _cap_niv_av := _nivel_asc
			av_ctrl.draw.connect(func():
				var _acor_av : Color = (_AVATAR_CORES[_cap_av] if _cap_av < _AVATAR_CORES.size() else Color(0.6, 0.6, 0.6))
				if _cap_niv_av > 0:
					var _ptex_row := _carregar_simbolo_prestigio(_cap_niv_av)
					const _MAR_R : float = 9.0
					if _ptex_row != null:
						av_ctrl.draw_texture_rect(_ptex_row,
							Rect2(-_MAR_R, -_MAR_R, 36.0 + _MAR_R * 2.0, 36.0 + _MAR_R * 2.0),
							false, Color(1.0, 1.0, 1.0, 0.94))
					av_ctrl.draw_circle(Vector2(18, 18), 14.0, Color(0.04, 0.06, 0.12, 1.0))
				else:
					av_ctrl.draw_circle(Vector2(18, 18), 14.0, Color(0.04, 0.06, 0.12, 0.97))
					av_ctrl.draw_arc(Vector2(18, 18), 14.0, 0.0, TAU, 32,
						_acor_av * (Color(1, 1, 1, 0.85) if e_voce else Color(0.7, 0.7, 0.7, 0.7)), 1.5)
				_draw_avatar_icone(av_ctrl, 18.0, 18.0, 11.0, _cap_av))
			row.add_child(av_ctrl)


		var nome_x: float = 108.0 if _row_av_idx >= 0 else 76.0

		# ── Badge de prestigio: rente ao nome + contador colorido ────────────
		const BADGE_SZ := 34.0
		const NOME_FONT_SZ := 20

		var _nome_max_w: float = (448.0 if e_voce else 548.0) if _row_av_idx >= 0 else (480.0 if e_voce else 580.0)
		var _font_r: Font = ThemeDB.fallback_font
		var _nome_txt_w: float = _font_r.get_string_size(nome, HORIZONTAL_ALIGNMENT_LEFT, -1, NOME_FONT_SZ).x if _font_r != null else 120.0

		# Badge de prestigio fica DEPOIS do nome com margem — nome nao eh cortado
		const BADGE_SZ2 := 44.0
		const BADGE_MARGEM := 6.0   # espaco entre fim do nome e o badge
		var _nome_w_real : float = minf(_nome_txt_w + 4.0, _nome_max_w - (BADGE_SZ2 + BADGE_MARGEM + 2.0) if _nivel_asc > 0 else _nome_max_w)

		var lbl_nome:= Label.new()
		lbl_nome.text = nome
		lbl_nome.position = Vector2(nome_x, 0)
		lbl_nome.size = Vector2(_nome_w_real, 44)
		lbl_nome.add_theme_font_size_override("font_size", NOME_FONT_SZ)
		lbl_nome.add_theme_color_override("font_color",
			Color(0.4, 0.85, 1.0) if e_voce else
			(Color(1.0, 0.95, 0.7) if pos <= 3 else Color(0.78, 0.88, 1.0)))
		lbl_nome.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.add_child(lbl_nome)

		if _nivel_asc > 0:
			var _ptex: Texture2D = _carregar_simbolo_prestigio(_nivel_asc)
			var _badge_x: float = nome_x + _nome_w_real + BADGE_MARGEM

			# Cores exatas do sistema de baus do jogo
			var _num_cor : Color
			var _cor_base: Color
			var _cor_luz : Color
			match _nivel_asc:
				1, 2:
					_num_cor  = Color(0.72, 0.92, 1.0)
					_cor_base = Color(0.55, 0.64, 0.78)
					_cor_luz  = Color(0.72, 0.92, 1.0)
				3, 4:
					_num_cor  = Color(0.40, 0.95, 1.0)
					_cor_base = Color(0.22, 0.72, 1.0)
					_cor_luz  = Color(0.40, 0.95, 1.0)
				5, 6:
					_num_cor  = Color(1.0,  0.45, 1.0)
					_cor_base = Color(0.78, 0.25, 1.0)
					_cor_luz  = Color(1.0,  0.45, 1.0)
				_:  # 7 e 8 — lendario
					_num_cor  = Color(1.0,  0.92, 0.35)
					_cor_base = Color(1.0,  0.70, 0.12)
					_cor_luz  = Color(1.0,  0.92, 0.35)

			var _pbadge := Control.new()
			_pbadge.position = Vector2(_badge_x, (44.0 - BADGE_SZ2) * 0.5)
			_pbadge.size = Vector2(BADGE_SZ2, BADGE_SZ2)
			_pbadge.mouse_filter = Control.MOUSE_FILTER_IGNORE

			var _cap_tx   := _ptex
			var _cap_asc  := _asc
			var _cap_niv  := _nivel_asc
			var _cap_ncor := _num_cor
			var _cap_cb   := _cor_base
			var _cap_cl   := _cor_luz

			_pbadge.draw.connect(func():
				var _t   : float = float(Time.get_ticks_msec()) / 1000.0
				var _ctr := Vector2(BADGE_SZ2 * 0.5, BADGE_SZ2 * 0.5)

				# ── Fragmentos de cristal flutuando ao redor do badge ─────────
				# Quantidade cresce com nivel: 3 (comum) ate 10 (lendario max)
				var _nf      : int   = 2 + _cap_niv
				var _orb     : float = BADGE_SZ2 * 0.35   # raio proximo ao badge
				var _spd     : float = 0.25 + float(_cap_niv) * 0.04
				var _max_r   : float = BADGE_SZ2 * 0.40   # fragmentos nao passam daqui

				for _fi in _nf:
					var _seed   : float = float(_fi) * 1.618
					var _ang    : float = _t * _spd * TAU + (TAU / float(_nf)) * float(_fi)
					var _drift  : float = sin(_t * 1.2 + _seed * 2.3) * BADGE_SZ2 * 0.04
					var _r      : float = _orb + _drift
					var _pos    := _ctr + Vector2(cos(_ang), sin(_ang)) * _r

					# Garante que fragmento nao sai dos limites do badge
					if (_pos - _ctr).length() > _max_r:
						continue

					var _pulse  : float = (sin(_t * 1.8 + _seed * 1.7) + 1.0) * 0.5
					var _sz     : float = 1.5 + _pulse * 1.8   # 1.5 a 3.3 px
					var _alpha  : float = 0.35 + _pulse * 0.55

					var _fc := Color(_cap_cb.r, _cap_cb.g, _cap_cb.b, _alpha)
					var _fl := Color(_cap_cl.r, _cap_cl.g, _cap_cl.b, _alpha * 0.6)

					_pbadge.draw_circle(_pos, _sz, _fc)
					_pbadge.draw_circle(_pos + Vector2(0, -_sz * 0.5), _sz * 0.4, _fl)

					# Trilha curta
					for _tr in 2:
						var _ta  : float = _ang - (_tr + 1) * 0.10
						var _tp  := _ctr + Vector2(cos(_ta), sin(_ta)) * _r
						if (_tp - _ctr).length() > _max_r:
							continue
						var _tfa : float = _alpha * (0.28 - float(_tr) * 0.10)
						if _tfa > 0.0:
							_pbadge.draw_circle(_tp, _sz * (0.55 - float(_tr) * 0.15),
								Color(_cap_cb.r, _cap_cb.g, _cap_cb.b, _tfa))

				# ── Imagem do badge (sobre os fragmentos) ─────────────────────
				if _cap_tx != null:
					_pbadge.draw_texture_rect(_cap_tx, Rect2(Vector2.ZERO, Vector2(BADGE_SZ2, BADGE_SZ2)), false)
				else:
					_pbadge.draw_circle(_ctr, BADGE_SZ2 * 0.40, Color(0.08, 0.06, 0.14, 0.92))

				# ── Numero no centro ──────────────────────────────────────────
				var _font := ThemeDB.fallback_font
				if _font:
					var _txt := str(_cap_asc)
					var _fs  : int = 13 if _cap_asc >= 100 else 15
					var _tw  : float = _font.get_string_size(_txt, HORIZONTAL_ALIGNMENT_LEFT, -1, _fs).x
					var _px  : float = _ctr.x - _tw * 0.5
					var _py  : float = _ctr.y + _fs * 0.36
					_pbadge.draw_string(_font, Vector2(_px + 1.0, _py + 1.0), _txt,
						HORIZONTAL_ALIGNMENT_LEFT, -1, _fs, Color(0, 0, 0, 0.80))
					_pbadge.draw_string(_font, Vector2(_px, _py), _txt,
						HORIZONTAL_ALIGNMENT_LEFT, -1, _fs, _cap_ncor))

			var _tmr := Timer.new()
			_tmr.wait_time = 0.05
			_tmr.autostart = true
			_tmr.timeout.connect(func(): if is_instance_valid(_pbadge): _pbadge.queue_redraw())
			_pbadge.add_child(_tmr)
			row.add_child(_pbadge)

		if e_voce:
			var badge:= Label.new()
			badge.text = "VOCE *" if is_estimado else "VOCE"
			badge.position = Vector2(566, 6)
			badge.size = Vector2(110, 32)
			badge.add_theme_font_size_override("font_size", 15)
			badge.add_theme_color_override("font_color", Color(0.3, 0.9, 1.0, 0.95))
			badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
			row.add_child(badge)

		var lbl_wave:= Label.new()
		lbl_wave.text = "Wave  %d" % wave
		lbl_wave.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl_wave.position = Vector2(686, 0)
		lbl_wave.size = Vector2(240, 44)
		lbl_wave.add_theme_font_size_override("font_size", 20)
		lbl_wave.add_theme_color_override("font_color", Color(1.0, 0.88, 0.3, 0.9))
		lbl_wave.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.add_child(lbl_wave)

		var lbl_score:= Label.new()
		lbl_score.text = _format_num(scr)
		lbl_score.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		lbl_score.position = Vector2(940, 0)
		lbl_score.size = Vector2(_row_w - 952, 44)
		lbl_score.add_theme_font_size_override("font_size", 20)
		lbl_score.add_theme_color_override("font_color", 
			Color(0.25, 1.0, 0.62) if pos <= 3 else Color(0.62, 0.95, 1.0))
		lbl_score.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.add_child(lbl_score)

		_ranking_lista.add_child(row)


func _draw_podio(ctrl: Control, entradas: Array) -> void :
	const COR_OURO:= Color(1.0, 0.82, 0.05)
	const COR_PRATA:= Color(0.78, 0.82, 0.9)
	const COR_BRONZE:= Color(0.85, 0.52, 0.22)

	var CW: float = ctrl.get_meta("ctrl_w", 1000.0)
	var BASE_Y: float = ctrl.size.y - 8.0
	var cx: float = CW * 0.5


	var podio_dados:= [
		{"idx": 1, "x": cx - 255.0, "h": 68.0, "dw": 200.0, "cor": COR_PRATA, "label": "2º"}, 
		{"idx": 0, "x": cx, "h": 100.0, "dw": 230.0, "cor": COR_OURO, "label": "1º"}, 
		{"idx": 2, "x": cx + 255.0, "h": 50.0, "dw": 190.0, "cor": COR_BRONZE, "label": "3º"}, 
	]


	var palco_x: float = cx - 460.0
	ctrl.draw_rect(Rect2(palco_x, BASE_Y, 920, 8), Color(1.0, 0.78, 0.1, 0.18))
	ctrl.draw_rect(Rect2(palco_x, BASE_Y + 8, 920, 4), Color(1.0, 0.78, 0.1, 0.07))

	for pd in podio_dados:
		var idx: int = pd["idx"] as int
		var px: float = pd["x"] as float
		var ph: float = pd["h"] as float
		var dw: float = pd["dw"] as float
		var pcor: Color = pd["cor"] as Color
		var plbl: String = pd["label"] as String
		var dx: float = px - dw * 0.5

		if idx >= entradas.size():
			ctrl.draw_rect(Rect2(dx, BASE_Y - ph, dw, ph), 
				Color(pcor.r * 0.05, pcor.g * 0.05, pcor.b * 0.05, 0.65))
			ctrl.draw_rect(Rect2(dx, BASE_Y - ph, dw, ph), 
				Color(pcor.r * 0.2, pcor.g * 0.2, pcor.b * 0.2, 0.3), false, 1.5)
			_draw_text_centered(ctrl, "â€”", Vector2(px, BASE_Y - ph * 0.5 + 6.0), 
				14, Color(pcor.r * 0.4, pcor.g * 0.4, pcor.b * 0.4, 0.4))
			continue

		var e: Dictionary = entradas[idx] as Dictionary
		var nome: String = (e.get("nome", "???") as String).left(14)
		var scr: int = int(e.get("score", 0))
		var wave: int = int(e.get("wave", 0))


		var glow_steps: int = 7 if idx == 0 else 4
		var glow_alpha: float = 0.038 if idx == 0 else 0.022
		for gi in range(glow_steps, 0, -1):
			var spread: float = float(gi) * 2.2
			ctrl.draw_rect(
				Rect2(dx - spread, BASE_Y - ph - spread, dw + spread * 2.0, ph + spread), 
				Color(pcor.r, pcor.g, pcor.b, glow_alpha / float(gi)))


		var stripes: int = 12
		for si in range(stripes):
			var sy: float = BASE_Y - ph + float(si) * ph / float(stripes)
			var sh: float = ph / float(stripes) + 1.0
			var t: float = float(si) / float(stripes - 1)
			var bright: float
			if t < 0.25:
				bright = lerp(0.5, 0.12, t / 0.25)
			elif t < 0.75:
				bright = lerp(0.12, 0.07, (t - 0.25) / 0.5)
			else:
				bright = lerp(0.07, 0.16, (t - 0.75) / 0.25)
			ctrl.draw_rect(Rect2(dx, sy, dw, sh), 
				Color(pcor.r * bright, pcor.g * bright, pcor.b * bright, 0.97))


		ctrl.draw_line(Vector2(dx + 5, BASE_Y - ph + 6), 
			Vector2(dx + 5, BASE_Y - 6), 
			Color(pcor.r, pcor.g, pcor.b, 0.26), 2.5)
		ctrl.draw_line(Vector2(dx + 13, BASE_Y - ph + 10), 
			Vector2(dx + 13, BASE_Y - ph + ph * 0.38), 
			Color(1.0, 1.0, 1.0, 0.1), 1.5)


		ctrl.draw_rect(Rect2(dx, BASE_Y - ph, dw, ph), 
			Color(pcor.r, pcor.g, pcor.b, 0.92), false, 2.0)

		ctrl.draw_rect(Rect2(dx + 2, BASE_Y - ph + 2, dw - 4, ph - 4), 
			Color(pcor.r, pcor.g, pcor.b, 0.2), false, 1.0)


		_draw_text_centered(ctrl, plbl, Vector2(px, BASE_Y - 10.0), 
			16, Color(pcor.r, pcor.g, pcor.b, 0.82))


		var ty: float = BASE_Y - ph - 8.0

		_draw_text_centered(ctrl, "Wave %d" % wave, Vector2(px, ty), 
			12, Color(1.0, 0.85, 0.3, 0.8))
		ty -= 18.0

		_draw_text_centered(ctrl, "%s pts" % _format_num(scr), Vector2(px, ty),
			13, Color(pcor.r + 0.15, pcor.g + 0.15, pcor.b + 0.15, 0.95))
		ty -= 20.0

		var _asc_p: int = int(e.get("ascensoes", 0))
		var _nivel_p: int = _nivel_prestigio(_asc_p)

		# ── Nome + badge ao lado (mesmo nivel) ───────────────────────────
		_draw_text_centered(ctrl, nome, Vector2(px, ty), 15, Color(1.0, 0.97, 0.88, 0.98))
		if _nivel_p > 0:
			var _font_p  : Font      = ThemeDB.fallback_font
			var _ptex_p  : Texture2D = _carregar_simbolo_prestigio(_nivel_p)
			const BADGE_SZ_P := 40.0
			var _ncor_p : Color
			match _nivel_p:
				1, 2: _ncor_p = Color(0.72, 0.92, 1.0)
				3, 4: _ncor_p = Color(0.40, 0.95, 1.0)
				5, 6: _ncor_p = Color(1.0,  0.45, 1.0)
				_:    _ncor_p = Color(1.0,  0.92, 0.35)
			# posicao: logo a direita do nome centrado, badge centralizado na linha do texto
			var _nw_p  : float = _font_p.get_string_size(nome, HORIZONTAL_ALIGNMENT_LEFT, -1, 15).x if _font_p else 80.0
			var _bx_p  : float = px + _nw_p * 0.5 + 4.0
			var _by_p  : float = ty - BADGE_SZ_P * 0.5 - 8.0
			var _bcx_p : float = _bx_p + BADGE_SZ_P * 0.5
			var _bcy_p : float = _by_p + BADGE_SZ_P * 0.5
			if _ptex_p != null:
				ctrl.draw_texture_rect(_ptex_p, Rect2(_bx_p, _by_p, BADGE_SZ_P, BADGE_SZ_P), false)
			else:
				ctrl.draw_circle(Vector2(_bcx_p, _bcy_p), BADGE_SZ_P * 0.44, Color(0.08, 0.06, 0.14, 0.9))
			if _font_p != null:
				var _txt_p : String = str(_asc_p)
				var _fs_p  : int    = 9 if _asc_p >= 100 else 11
				var _tw_p  : float  = _font_p.get_string_size(_txt_p, HORIZONTAL_ALIGNMENT_LEFT, -1, _fs_p).x
				ctrl.draw_string(_font_p, Vector2(_bcx_p - _tw_p * 0.5 + 1.0, _bcy_p + _fs_p * 0.36 + 1.0),
					_txt_p, HORIZONTAL_ALIGNMENT_LEFT, -1, _fs_p, Color(0, 0, 0, 0.75))
				ctrl.draw_string(_font_p, Vector2(_bcx_p - _tw_p * 0.5, _bcy_p + _fs_p * 0.36),
					_txt_p, HORIZONTAL_ALIGNMENT_LEFT, -1, _fs_p, _ncor_p)
		ty -= 22.0


		var av_r: float = 21.0 if idx == 0 else 17.0
		var av_cx: float = px
		var av_cy: float = ty - av_r


		if idx == 0:
			for ag in range(5, 0, -1):
				ctrl.draw_circle(Vector2(av_cx, av_cy), av_r + float(ag) * 2.8, 
					Color(pcor.r, pcor.g, pcor.b, 0.05 / float(ag)))


		ctrl.draw_circle(Vector2(av_cx, av_cy), av_r,
			Color(pcor.r * 0.16, pcor.g * 0.16, pcor.b * 0.16, 0.95))
		var _arc_cor_p : Color = Color(pcor.r, pcor.g, pcor.b, 0.95)
		if _nivel_p > 0:
			# Anel colorido por nivel de prestigio (avatar pequeno demais pra imagem)
			match _nivel_p:
				1, 2: _arc_cor_p = Color(0.72, 0.92, 1.0, 1.0)
				3, 4: _arc_cor_p = Color(0.40, 0.95, 1.0, 1.0)
				5, 6: _arc_cor_p = Color(1.0,  0.45, 1.0, 1.0)
				_:    _arc_cor_p = Color(1.0,  0.92, 0.35, 1.0)
		ctrl.draw_arc(Vector2(av_cx, av_cy), av_r, 0.0, TAU, 40, _arc_cor_p, 2.0)

		ctrl.draw_arc(Vector2(av_cx, av_cy - av_r * 0.28), av_r * 0.52,
			PI + 0.5, TAU - 0.5, 10,
			Color(1.0, 1.0, 1.0, 0.28), 2.0)


		var av_icon_idx: int = 1
		var _raw_av = e.get("avatar_idx", null)
		if _raw_av != null:
			var _t:= typeof(_raw_av)
			if _t == TYPE_INT or _t == TYPE_FLOAT:
				var _av_i:= int(_raw_av)
				if _av_i >= 0 and _av_i < 5:
					av_icon_idx = _av_i
		_draw_avatar_icone(ctrl, av_cx, av_cy, av_r * 0.82, av_icon_idx)


func _draw_text_centered(ctrl: Control, txt: String, pos: Vector2, size: int, cor: Color) -> void :
	var font: Font = ThemeDB.fallback_font
	if font == null:
		return
	var tw: float = font.get_string_size(txt, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
	ctrl.draw_string(font, pos + Vector2( - tw * 0.5, 0.0), txt, HORIZONTAL_ALIGNMENT_LEFT, -1, size, cor)




func _abrir_hist(_ui: CanvasLayer) -> void :
	if _hist_overlay:
		return
	if _menu_contents:
		_menu_contents.hide()


	const _CARTA_INFO:= {
		"dano_m": {"nome": "Força Bruta", "cor": Color(1.0, 0.42, 0.1)},
		"dano_g": {"nome": "Canhão de Obsidiana", "cor": Color(1.0, 0.58, 0.0)},
		"cad_m": {"nome": "Ritmo Acelerado", "cor": Color(0.75, 0.2, 1.0)},
		"cad_g": {"nome": "Metralhadora", "cor": Color(0.9, 0.3, 1.0)},
		"range_m": {"nome": "Visão Ampla", "cor": Color(0.12, 0.62, 1.0)},
		"range_g": {"nome": "Olho de Deus", "cor": Color(0.2, 0.80, 1.0)},
		"vida_m": {"nome": "Couraça", "cor": Color(0.12, 1.0, 0.45)},
		"vida_g": {"nome": "Fortaleza", "cor": Color(0.1, 0.9, 0.4)},
		"vel": {"nome": "Projétil Sônico", "cor": Color(0.95, 0.95, 0.12)},
		"escudo": {"nome": "Escudo Arcano", "cor": Color(0.2, 0.6, 1.0)},
		"dano": {"nome": "Dano", "cor": Color(1.0, 0.42, 0.1)}, 
		"cadencia": {"nome": "CadÃªncia", "cor": Color(0.75, 0.2, 1.0)}, 
		"alcance": {"nome": "Alcance", "cor": Color(0.12, 0.62, 1.0)}, 
		"vida": {"nome": "Vida / Cura", "cor": Color(0.12, 1.0, 0.45)}, 
		"pierce": {"nome": "Bala Perfurante", "cor": Color(1.0, 0.88, 0.12)}, 
		"multi": {"nome": "CanhÃ£o Duplo", "cor": Color(0.12, 1.0, 0.88)}, 
		"speed": {"nome": "ProjÃ©til SÃ´nico", "cor": Color(0.95, 0.95, 0.12)}, 
		"regen": {"nome": "RegeneraÃ§Ã£o", "cor": Color(0.4, 1.0, 0.55)}, 
		"reducao": {"nome": "Escudo Arcano", "cor": Color(0.2, 0.6, 1.0)}, 
		"ouro": {"nome": "Toque de Midas", "cor": Color(1.0, 0.82, 0.1)}, 
		"fragmento": {"nome": "Fragmento Arcano", "cor": Color(1.0, 0.65, 0.0)}, 
		"raio": {"nome": "Raio Arcano", "cor": Color(0.4, 0.72, 1.0)}, 
		"corrente": {"nome": "Corrente ElÃ©trica", "cor": Color(0.25, 0.95, 1.0)}, 
		"veneno": {"nome": "Veneno Arcano", "cor": Color(0.25, 1.0, 0.2)}, 
		"critico": {"nome": "Golpe CrÃ­tico", "cor": Color(1.0, 0.5, 0.05)}, 
		"explosao": {"nome": "ExplosÃ£o Mortal", "cor": Color(1.0, 0.38, 0.05)}, 
		"chama": {"nome": "Chama PerpÃ©tua", "cor": Color(1.0, 0.58, 0.08)}, 
		"overdrive": {"nome": "Overdrive", "cor": Color(1.0, 0.8, 0.0)}, 
		"armadura_i": {"nome": "Armadura Invertida", "cor": Color(0.85, 0.25, 0.95)}, 
		"bencao": {"nome": "BÃªnÃ§Ã£o de Energia", "cor": Color(1.0, 0.95, 0.25)}, 
		"saque": {"nome": "Saque em Massa", "cor": Color(1.0, 0.82, 0.08)}, 
		"recuperacao": {"nome": "RecuperaÃ§Ã£o RÃ¡pida", "cor": Color(0.25, 1.0, 0.5)}, 
		"tempestade": {"nome": "Tempestade Arcana", "cor": Color(0.55, 0.8, 1.0)}, 
		"fissura": {"nome": "Fissura Venenosa", "cor": Color(0.38, 1.0, 0.3)}, 
		"cacador": {"nome": "CaÃ§ador de Fantasmas", "cor": Color(0.88, 0.55, 1.0)}, 
		"rajada": {"nome": "Rajada de Tiros", "cor": Color(1.0, 0.72, 0.15)}, 
		"carga": {"nome": "Tiro Carregado", "cor": Color(0.88, 0.3, 0.05)}, 
		"gelo": {"nome": "Campo de Gelo", "cor": Color(0.45, 0.82, 1.0)}, 
	}


	var _vp_hist_bg:= get_viewport().get_visible_rect().size
	var bg:= ColorRect.new()
	bg.color = Color(0.0, 0.0, 0.0, 0.82)
	bg.position = Vector2.ZERO
	bg.size = _vp_hist_bg
	bg.mouse_filter = Control.MOUSE_FILTER_STOP
	_ui_main.add_child(bg)
	_hist_overlay = bg


	var _vp_hist: float = get_viewport().get_visible_rect().size.x
	var pnl:= Panel.new()
	pnl.position = Vector2((_vp_hist - 1000.0) * 0.5, 50)
	pnl.size = Vector2(1000, 630)
	pnl.mouse_filter = Control.MOUSE_FILTER_STOP
	var sty_pnl:= StyleBoxFlat.new()
	sty_pnl.bg_color = Color(0.04, 0.07, 0.12, 0.97)
	sty_pnl.border_color = Color(0.1, 0.85, 0.6, 0.85)
	for side in ["left", "right", "top", "bottom"]:
		sty_pnl.set("border_width_" + side, 2)
	for corner in ["top_left", "top_right", "bottom_left", "bottom_right"]:
		sty_pnl.set("corner_radius_" + corner, 14)
	pnl.add_theme_stylebox_override("panel", sty_pnl)
	bg.add_child(pnl)
	_hist_panel = pnl


	var tit:= Label.new()
	tit.text = "ESTATÍSTICAS  GLOBAIS"
	tit.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tit.position = Vector2(0, 18)
	tit.size = Vector2(1000, 44)
	tit.add_theme_font_size_override("font_size", 28)
	tit.add_theme_color_override("font_color", Color(0.1, 0.85, 0.6))
	_ui_title_label(tit, 4.0)
	pnl.add_child(tit)


	var sep:= ColorRect.new()
	sep.color = Color(0.1, 0.85, 0.6, 0.35)
	sep.position = Vector2(30, 66)
	sep.size = Vector2(940, 1)
	pnl.add_child(sep)


	var partidas: int = Salvar.total_partidas
	var media_wave: float = (float(Salvar.total_waves_completadas) / float(max(1, partidas)))

	var left_scroll_g:= ScrollContainer.new()
	left_scroll_g.position = Vector2(40, 82)
	left_scroll_g.size = Vector2(460, 490)
	left_scroll_g.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	left_scroll_g.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	left_scroll_g.mouse_filter = Control.MOUSE_FILTER_STOP
	pnl.add_child(left_scroll_g)

	var left_cont_g:= Control.new()
	left_cont_g.mouse_filter = Control.MOUSE_FILTER_IGNORE
	left_scroll_g.add_child(left_cont_g)

	var cy:= 0.0

	var hdr_e:= Label.new()
	hdr_e.text = "RESUMO  GERAL"
	hdr_e.position = Vector2(0, cy)
	hdr_e.size = Vector2(450, 46)
	hdr_e.add_theme_font_size_override("font_size", 34)
	hdr_e.add_theme_color_override("font_color", Color(0.5, 0.7, 0.9, 0.8))
	left_cont_g.add_child(hdr_e)
	cy += 50.0

	var linhas_esq:= [
		["Partidas jogadas", str(partidas), Color(0.8, 0.9, 1.0)], 
		["Melhor wave", str(Salvar.melhor_wave), Color(1.0, 0.92, 0.2)], 
		["Wave média", "%.1f" % media_wave, Color(0.7, 0.85, 1.0)], 
		["Mobs eliminados", _format_num(Salvar.total_mobs_mortos), Color(0.0, 0.82, 1.0)], 
		["Bosses derrotados", _format_num(Salvar.total_boss_mortos), Color(1.0, 0.35, 0.1)], 
		["Ouro acumulado", _format_num(Salvar.total_ouro_ganho), Color(1.0, 0.82, 0.1)], 
		["Score total", _format_num(Salvar.total_score), Color(0.55, 1.0, 0.6)], 
		["RECORDES", "", Color(0.35, 0.5, 0.45)], 
		["Recorde  Normal", _format_num(Salvar.high_score_normal), Color(0.2, 1.0, 0.55)], 
		["Recorde  Dificil", _format_num(Salvar.high_score_dificil), Color(1.0, 0.65, 0.15)], 
		["Recorde  Facil", _format_num(Salvar.high_score_facil), Color(0.4, 0.78, 0.4)], 
		["Recorde  Abismo", _format_num(Salvar.high_score_abismo), Color(1.0, 0.32, 0.32)], 
	]

	for linha in linhas_esq:
		var chave: String = linha[0] as String
		var valor: String = linha[1] as String
		var cor: Color = linha[2] as Color

		var lbl_c:= Label.new()
		lbl_c.text = chave
		lbl_c.position = Vector2(0, cy)
		lbl_c.size = Vector2(280, 44)
		lbl_c.add_theme_font_size_override("font_size", 28)
		lbl_c.add_theme_color_override("font_color", Color(0.65, 0.75, 0.88))
		left_cont_g.add_child(lbl_c)

		var lbl_v:= Label.new()
		lbl_v.text = valor
		lbl_v.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		lbl_v.position = Vector2(0, cy)
		lbl_v.size = Vector2(450, 44)
		lbl_v.add_theme_font_size_override("font_size", 28)
		lbl_v.add_theme_color_override("font_color", cor)
		left_cont_g.add_child(lbl_v)

		cy += 50.0


	var hist_sep_line:= ColorRect.new()
	hist_sep_line.color = Color(0.1, 0.85, 0.6, 0.25)
	hist_sep_line.position = Vector2(0, cy + 4.0)
	hist_sep_line.size = Vector2(450, 1)
	left_cont_g.add_child(hist_sep_line)
	cy += 16.0

	var hist_hdr:= Label.new()
	hist_hdr.text = "ÃšLTIMAS 10 PARTIDAS"
	hist_hdr.position = Vector2(0, cy)
	hist_hdr.size = Vector2(450, 40)
	hist_hdr.add_theme_font_size_override("font_size", 24)
	hist_hdr.add_theme_color_override("font_color", Color(0.5, 0.7, 0.9, 0.8))
	left_cont_g.add_child(hist_hdr)
	cy += 44.0

	const _DIFF_NOMES: Array = ["FÃCIL", "NORMAL", "DIFÃCIL", "ABISMO"]
	const _DIFF_CORES: Array = [Color(0.1, 0.88, 0.42), Color(0.2, 1.0, 0.55), Color(1.0, 0.65, 0.15), Color(1.0, 0.32, 0.32)]

	if Salvar.historico_partidas.is_empty():
		var sem_hist:= Label.new()
		sem_hist.text = "Nenhuma partida registrada ainda."
		sem_hist.position = Vector2(0, cy)
		sem_hist.size = Vector2(450, 36)
		sem_hist.add_theme_font_size_override("font_size", 22)
		sem_hist.add_theme_color_override("font_color", Color(0.4, 0.45, 0.5))
		left_cont_g.add_child(sem_hist)
		cy += 40.0
	else:
		for entrada in Salvar.historico_partidas:
			if not (entrada is Dictionary): continue
			var e: Dictionary = entrada as Dictionary
			var diff_idx: int = clampi(int(e.get("dificuldade", 1)), 0, 3)
			var dnome: String = _DIFF_NOMES[diff_idx] as String
			var dcor: Color = _DIFF_CORES[diff_idx] as Color
			var txt: String = "W%d  Score %s  %s mobs  [%s]" % [
				int(e.get("wave", 0)), _format_num(int(e.get("score", 0))), 
				_format_num(int(e.get("mobs", 0))), dnome
			]
			var lhist:= Label.new()
			lhist.text = txt
			lhist.position = Vector2(0, cy)
			lhist.size = Vector2(450, 34)
			lhist.add_theme_font_size_override("font_size", 22)
			lhist.add_theme_color_override("font_color", Color(dcor.r, dcor.g, dcor.b, 0.9))
			left_cont_g.add_child(lhist)
			cy += 38.0

	left_cont_g.custom_minimum_size = Vector2(450, cy + 10.0)


	var right_scroll_g:= ScrollContainer.new()
	right_scroll_g.position = Vector2(520, 82)
	right_scroll_g.size = Vector2(460, 490)
	right_scroll_g.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	right_scroll_g.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	right_scroll_g.mouse_filter = Control.MOUSE_FILTER_STOP
	pnl.add_child(right_scroll_g)

	var right_cont_g:= Control.new()
	right_cont_g.mouse_filter = Control.MOUSE_FILTER_IGNORE
	right_scroll_g.add_child(right_cont_g)

	var dy:= 0.0

	var hdr_d:= Label.new()
	hdr_d.text = "CARTAS  MAIS  ESCOLHIDAS"
	hdr_d.position = Vector2(0, dy)
	hdr_d.size = Vector2(450, 44)
	hdr_d.add_theme_font_size_override("font_size", 30)
	hdr_d.add_theme_color_override("font_color", Color(0.5, 0.7, 0.9, 0.8))
	right_cont_g.add_child(hdr_d)
	dy += 50.0


	var pares: Array = []
	for cid in Salvar.total_cartas.keys():
		var cnt: int = int(Salvar.total_cartas[cid])
		if cnt > 0:
			pares.append([cnt, cid as String])
	pares.sort_custom( func(a, b): return (a[0] as int) > (b[0] as int))

	if pares.is_empty():
		var vazio:= Label.new()
		vazio.text = "Nenhuma partida registrada ainda."
		vazio.position = Vector2(0, dy)
		vazio.size = Vector2(450, 40)
		vazio.add_theme_font_size_override("font_size", 22)
		vazio.add_theme_color_override("font_color", Color(0.5, 0.55, 0.6))
		right_cont_g.add_child(vazio)
		dy += 44.0
	else:
		var max_cnt: int = max(1, int((pares[0] as Array)[0]))
		var top: int = min(pares.size(), 12)
		for i in range(top):
			var par: Array = pares[i] as Array
			var cnt: int = int(par[0])
			var cid: String = par[1] as String
			var info: Dictionary = _CARTA_INFO.get(cid, {"nome": cid, "cor": Color(0.6, 0.6, 0.6)}) as Dictionary
			var nome: String = info["nome"] as String
			var ccor: Color = info["cor"] as Color

			var barra_bg:= ColorRect.new()
			barra_bg.color = Color(0.08, 0.1, 0.14, 0.6)
			barra_bg.position = Vector2(0, dy + 6.0)
			barra_bg.size = Vector2(450, 34)
			right_cont_g.add_child(barra_bg)

			var pct: float = float(cnt) / float(max_cnt)
			var barra:= ColorRect.new()
			barra.color = Color(ccor.r * 0.5, ccor.g * 0.5, ccor.b * 0.5, 0.55)
			barra.position = Vector2(0, dy + 6.0)
			barra.size = Vector2(450.0 * pct, 34)
			right_cont_g.add_child(barra)

			var lbl_n:= Label.new()
			lbl_n.text = nome
			lbl_n.position = Vector2(6, dy)
			lbl_n.size = Vector2(340, 44)
			lbl_n.add_theme_font_size_override("font_size", 28)
			lbl_n.add_theme_color_override("font_color", Color(ccor.r + 0.2, ccor.g + 0.2, ccor.b + 0.2))
			right_cont_g.add_child(lbl_n)

			var lbl_q:= Label.new()
			lbl_q.text = "×%d" % cnt
			lbl_q.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
			lbl_q.position = Vector2(0, dy)
			lbl_q.size = Vector2(450, 44)
			lbl_q.add_theme_font_size_override("font_size", 28)
			lbl_q.add_theme_color_override("font_color", Color(ccor.r + 0.3, ccor.g + 0.3, ccor.b + 0.3))
			right_cont_g.add_child(lbl_q)

			dy += 52.0

	right_cont_g.custom_minimum_size = Vector2(450, dy + 10.0)


	if partidas == 0:
		var nota:= Label.new()
		nota.text = "Jogue algumas partidas para acumular estatÃ­sticas!"
		nota.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		nota.position = Vector2(0, 550)
		nota.size = Vector2(1000, 28)
		nota.add_theme_font_size_override("font_size", 18)
		nota.add_theme_color_override("font_color", Color(0.5, 0.6, 0.7))
		pnl.add_child(nota)


	var btn_f:= Button.new()
	btn_f.text = "FECHAR"
	btn_f.position = Vector2(400, 580)
	btn_f.size = Vector2(200, 38)
	btn_f.focus_mode = Control.FOCUS_NONE
	btn_f.add_theme_font_size_override("font_size", 16)
	var sty_f:= StyleBoxFlat.new()
	sty_f.bg_color = Color(0.08, 0.12, 0.16, 0.95)
	sty_f.border_color = Color(0.1, 0.85, 0.6, 0.85)
	for side in ["left", "right", "top", "bottom"]:
		sty_f.set("border_width_" + side, 2)
	for corner in ["top_left", "top_right", "bottom_left", "bottom_right"]:
		sty_f.set("corner_radius_" + corner, 8)
	btn_f.add_theme_stylebox_override("normal", sty_f)
	var sty_fh: StyleBoxFlat = sty_f.duplicate()
	sty_fh.bg_color = Color(0.12, 0.22, 0.18, 0.98)
	sty_fh.border_color = Color(0.15, 1.0, 0.7, 1.0)
	btn_f.add_theme_stylebox_override("hover", sty_fh)
	btn_f.add_theme_color_override("font_color", Color(0.2, 1.0, 0.7))
	btn_f.pressed.connect( func():
		if _hist_overlay and is_instance_valid(_hist_overlay):
			_hist_overlay.queue_free()
		_hist_overlay = null
		_hist_panel = null
		if _menu_contents:
			_menu_contents.show()
	)
	pnl.add_child(btn_f)
	_corrigir_textos_ui(pnl)




func _abrir_config(ui: CanvasLayer) -> void :
	if _config_overlay:
		return
	if _menu_contents:
		_menu_contents.hide()
	_ui_ref = ui
	_config_confirm = false

	var _vp_cfg:= get_viewport().get_visible_rect().size
	_config_overlay = ColorRect.new()
	_config_overlay.color = Color(0.0, 0.0, 0.02, 0.88)
	_config_overlay.position = Vector2.ZERO
	_config_overlay.size = _vp_cfg
	ui.add_child(_config_overlay)

	_config_panel = Control.new()
	_config_panel.position = Vector2((_vp_cfg.x - 1100.0) * 0.5, 10)
	_config_panel.size = Vector2(1100, 770)
	ui.add_child(_config_panel)


	var bg:= Panel.new()
	bg.position = Vector2.ZERO
	bg.size = Vector2(1100, 760)
	var bg_sty:= StyleBoxFlat.new()
	bg_sty.bg_color = Color(0.04, 0.05, 0.09, 0.97)
	bg_sty.border_color = Color(0.35, 0.45, 0.6, 0.7)
	for side in ["left", "right", "top", "bottom"]:
		bg_sty.set("border_width_" + side, 2)
	for corner in ["top_left", "top_right", "bottom_left", "bottom_right"]:
		bg_sty.set("corner_radius_" + corner, 14)
	bg.add_theme_stylebox_override("panel", bg_sty)
	_config_panel.add_child(bg)


	var tit:= Label.new()
	tit.text = "CONFIGURAÇÕES"
	tit.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tit.position = Vector2(0, 16)
	tit.size = Vector2(1100, 50)
	tit.add_theme_font_size_override("font_size", 34)
	tit.add_theme_color_override("font_color", Color(0.72, 0.82, 1.0))
	_ui_title_label(tit, 4.0)
	_config_panel.add_child(tit)


	var sep:= ColorRect.new()
	sep.color = Color(0.3, 0.4, 0.6, 0.35)
	sep.position = Vector2(40, 68)
	sep.size = Vector2(1020, 2)
	_config_panel.add_child(sep)


	var stats_txt:= "High Score: %s     Ouro no banco: %s     Cristais: %s" % [
		_format_num(Salvar.high_score), _format_num(Salvar.ouro_banco), _format_num(Salvar.cristais)]
	var lstats:= Label.new()
	lstats.text = stats_txt
	lstats.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lstats.autowrap_mode = TextServer.AUTOWRAP_WORD
	lstats.position = Vector2(40, 73)
	lstats.size = Vector2(1020, 32)
	lstats.add_theme_font_size_override("font_size", 17)
	lstats.add_theme_color_override("font_color", Color(0.55, 0.62, 0.72))
	_config_panel.add_child(lstats)

	var sep2:= ColorRect.new()
	sep2.color = Color(0.3, 0.4, 0.6, 0.2)
	sep2.position = Vector2(40, 108)
	sep2.size = Vector2(1020, 2)
	_config_panel.add_child(sep2)


	var lvol:= Label.new()
	lvol.text = "Volume SFX:"
	lvol.position = Vector2(40, 115)
	lvol.size = Vector2(220, 34)
	lvol.add_theme_font_size_override("font_size", 20)
	lvol.add_theme_color_override("font_color", Color(0.72, 0.82, 1.0))
	_config_panel.add_child(lvol)

	var slider:= HSlider.new()
	slider.min_value = 0.0
	slider.max_value = 1.0
	slider.step = 0.05
	slider.value = Som.volume_sfx
	slider.position = Vector2(270, 118)
	slider.size = Vector2(780, 28)
	slider.focus_mode = Control.FOCUS_NONE
	slider.value_changed.connect( func(val: float):
		Som.volume_sfx = val
		Salvar.volume_sfx = val
		Salvar.salvar()
	)
	_config_panel.add_child(slider)


	var lmus:= Label.new()
	lmus.text = "Volume MÃºsica:"
	lmus.position = Vector2(40, 153)
	lmus.size = Vector2(220, 34)
	lmus.add_theme_font_size_override("font_size", 20)
	lmus.add_theme_color_override("font_color", Color(0.72, 0.82, 1.0))
	_config_panel.add_child(lmus)

	var slider_mus:= HSlider.new()
	slider_mus.min_value = 0.0
	slider_mus.max_value = 1.0
	slider_mus.step = 0.05
	slider_mus.value = Som.volume_musica
	slider_mus.position = Vector2(270, 156)
	slider_mus.size = Vector2(780, 28)
	slider_mus.focus_mode = Control.FOCUS_NONE
	slider_mus.value_changed.connect( func(val: float):
		Som.set_volume_musica(val)
		Salvar.salvar()
	)
	_config_panel.add_child(slider_mus)


	var lpausa:= Label.new()
	lpausa.text = "Pausa automÃ¡tica entre waves:"
	lpausa.position = Vector2(40, 194)
	lpausa.size = Vector2(500, 34)
	lpausa.add_theme_font_size_override("font_size", 20)
	lpausa.add_theme_color_override("font_color", Color(0.72, 0.82, 1.0))
	_config_panel.add_child(lpausa)

	var chk:= CheckButton.new()
	chk.button_pressed = Salvar.pausa_auto_wave
	chk.position = Vector2(700, 191)
	chk.size = Vector2(200, 42)
	chk.focus_mode = Control.FOCUS_NONE
	chk.add_theme_font_size_override("font_size", 24)
	chk.toggled.connect( func(val: bool):
		Salvar.pausa_auto_wave = val
		Salvar.salvar()
	)
	_config_panel.add_child(chk)


	var ltela:= Label.new()
	ltela.text = "Tela cheia  (F11):"
	ltela.position = Vector2(40, 238)
	ltela.size = Vector2(500, 34)
	ltela.add_theme_font_size_override("font_size", 20)
	ltela.add_theme_color_override("font_color", Color(0.72, 0.82, 1.0))
	_config_panel.add_child(ltela)

	var chk_fs:= CheckButton.new()
	var _is_mobile : bool = OS.has_feature("android") or OS.has_feature("ios")
	chk_fs.button_pressed = _is_mobile or DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN
	chk_fs.disabled = _is_mobile
	chk_fs.position = Vector2(700, 235)
	chk_fs.size = Vector2(200, 42)
	chk_fs.focus_mode = Control.FOCUS_NONE
	chk_fs.add_theme_font_size_override("font_size", 24)
	if not _is_mobile:
		chk_fs.toggled.connect( func(val: bool):
			if val:
				DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
			else:
				DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		)
	_config_panel.add_child(chk_fs)


	var lacess:= Label.new()
	lacess.text = "Acessibilidade (glaucoma):"
	lacess.position = Vector2(40, 282)
	lacess.size = Vector2(500, 34)
	lacess.add_theme_font_size_override("font_size", 20)
	lacess.add_theme_color_override("font_color", Color(0.72, 0.82, 1.0))
	_config_panel.add_child(lacess)

	var lacess2:= Label.new()
	lacess2.text = "(3 cliques para confirmar + leitura de tela)"
	lacess2.position = Vector2(40, 314)
	lacess2.size = Vector2(500, 24)
	lacess2.add_theme_font_size_override("font_size", 15)
	lacess2.add_theme_color_override("font_color", Color(0.5, 0.6, 0.78))
	_config_panel.add_child(lacess2)

	var chk_ac:= CheckButton.new()
	chk_ac.button_pressed = Salvar.acessibilidade_ativo
	chk_ac.position = Vector2(700, 279)
	chk_ac.size = Vector2(200, 42)
	chk_ac.focus_mode = Control.FOCUS_NONE
	chk_ac.add_theme_font_size_override("font_size", 24)
	chk_ac.toggled.connect( func(val: bool):
		Acessibilidade.set_ativo(val)
	)
	_config_panel.add_child(chk_ac)


	var lnome:= Label.new()
	lnome.text = "Nome no Ranking Online:"
	lnome.position = Vector2(40, 344)
	lnome.size = Vector2(420, 34)
	lnome.add_theme_font_size_override("font_size", 19)
	lnome.add_theme_color_override("font_color", Color(1.0, 0.88, 0.3))
	_config_panel.add_child(lnome)

	_cfg_nome_antigo = Salvar.nome_jogador
	var nome_edit:= LineEdit.new()
	nome_edit.text = Salvar.nome_jogador
	nome_edit.placeholder_text = "Seu nome no ranking (mÃ¡x 20)"
	nome_edit.position = Vector2(470, 342)
	nome_edit.size = Vector2(590, 38)
	nome_edit.focus_mode = Control.FOCUS_CLICK
	nome_edit.max_length = 20
	nome_edit.add_theme_font_size_override("font_size", 22)
	var sty_nome:= StyleBoxFlat.new()
	sty_nome.bg_color = Color(0.1, 0.09, 0.03, 0.95)
	sty_nome.border_color = Color(1.0, 0.78, 0.1, 0.7)
	for side in ["left", "right", "top", "bottom"]: sty_nome.set("border_width_" + side, 1)
	for corner in ["top_left", "top_right", "bottom_left", "bottom_right"]: sty_nome.set("corner_radius_" + corner, 6)
	nome_edit.add_theme_stylebox_override("normal", sty_nome)
	nome_edit.add_theme_color_override("font_color", Color(1.0, 0.95, 0.6))
	nome_edit.text_changed.connect( func(val: String):
		Salvar.nome_jogador = val.strip_edges()
		Salvar.salvar()
	)
	nome_edit.focus_exited.connect( func():
		var novo:= Salvar.nome_jogador.strip_edges()
		if novo != _cfg_nome_antigo and _cfg_nome_antigo != "" and novo != "":
			RankingOnline.renomear(_cfg_nome_antigo, novo, Salvar.senha_jogador)
			_cfg_nome_antigo = novo
	)
	_config_panel.add_child(nome_edit)

	var lnome_hint:= Label.new()
	lnome_hint.text = "Seu apelido aparece no ranking global · Deixe vazio para não participar"
	lnome_hint.position = Vector2(40, 383)
	lnome_hint.size = Vector2(1020, 22)
	lnome_hint.add_theme_font_size_override("font_size", 14)
	lnome_hint.add_theme_color_override("font_color", Color(0.55, 0.5, 0.28))
	_config_panel.add_child(lnome_hint)


	var sep4:= ColorRect.new()
	sep4.color = Color(0.3, 0.4, 0.6, 0.2)
	sep4.position = Vector2(40, 409)
	sep4.size = Vector2(1020, 2)
	_config_panel.add_child(sep4)


	var laviso:= Label.new()
	laviso.text = "RESETAR JOGO apaga todo o progresso: ouro, cristais, talentos e melhorias."
	laviso.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	laviso.autowrap_mode = TextServer.AUTOWRAP_WORD
	laviso.position = Vector2(40, 414)
	laviso.size = Vector2(1020, 40)
	laviso.add_theme_font_size_override("font_size", 17)
	laviso.add_theme_color_override("font_color", Color(0.85, 0.6, 0.35))
	_config_panel.add_child(laviso)


	var btn_reset:= Button.new()
	btn_reset.text = "RESETAR JOGO"
	btn_reset.position = Vector2(200, 458)
	btn_reset.size = Vector2(700, 50)
	btn_reset.focus_mode = Control.FOCUS_NONE
	btn_reset.add_theme_font_size_override("font_size", 22)
	var sty_r:= StyleBoxFlat.new()
	sty_r.bg_color = Color(0.22, 0.05, 0.05, 0.92)
	sty_r.border_color = Color(0.85, 0.18, 0.18, 0.85)
	for side in ["left", "right", "top", "bottom"]:
		sty_r.set("border_width_" + side, 2)
	for corner in ["top_left", "top_right", "bottom_left", "bottom_right"]:
		sty_r.set("corner_radius_" + corner, 10)
	btn_reset.add_theme_stylebox_override("normal", sty_r)
	var sty_rh: StyleBoxFlat = sty_r.duplicate()
	sty_rh.bg_color = Color(0.42, 0.08, 0.08, 0.96)
	sty_rh.border_color = Color(1.0, 0.28, 0.28, 1.0)
	btn_reset.add_theme_stylebox_override("hover", sty_rh)
	btn_reset.add_theme_color_override("font_color", Color(1.0, 0.55, 0.55))
	btn_reset.pressed.connect(_on_reset_press.bind(btn_reset))
	_config_panel.add_child(btn_reset)


	var lconfirm:= Label.new()
	lconfirm.name = "LConfirm"
	lconfirm.text = "Clique novamente para confirmar o reset!"
	lconfirm.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lconfirm.position = Vector2(40, 512)
	lconfirm.size = Vector2(1020, 28)
	lconfirm.add_theme_font_size_override("font_size", 17)
	lconfirm.add_theme_color_override("font_color", Color(1.0, 0.35, 0.35))
	lconfirm.visible = false
	_config_panel.add_child(lconfirm)


	if Salvar.nome_jogador != "":
		var btn_logout:= Button.new()
		btn_logout.text = "SAIR DA CONTA  (" + Salvar.nome_jogador + ")"
		btn_logout.position = Vector2(200, 548)
		btn_logout.size = Vector2(700, 50)
		btn_logout.focus_mode = Control.FOCUS_NONE
		btn_logout.add_theme_font_size_override("font_size", 18)
		var sty_lo:= StyleBoxFlat.new()
		sty_lo.bg_color = Color(0.12, 0.06, 0.18, 0.92)
		sty_lo.border_color = Color(0.65, 0.25, 0.9, 0.75)
		for side in ["left", "right", "top", "bottom"]:
			sty_lo.set("border_width_" + side, 1)
		for corner in ["top_left", "top_right", "bottom_left", "bottom_right"]:
			sty_lo.set("corner_radius_" + corner, 8)
		btn_logout.add_theme_stylebox_override("normal", sty_lo)
		var sty_loh: StyleBoxFlat = sty_lo.duplicate()
		sty_loh.bg_color = Color(0.22, 0.08, 0.32, 0.96)
		sty_loh.border_color = Color(0.85, 0.35, 1.0, 0.9)
		btn_logout.add_theme_stylebox_override("hover", sty_loh)
		btn_logout.add_theme_color_override("font_color", Color(0.82, 0.55, 1.0))
		btn_logout.pressed.connect(func():
			var _acc_path := Salvar._save_path()
			Salvar.limpar_dados()
			Salvar.nome_jogador       = ""
			Salvar.email_jogador      = ""
			Salvar.senha_jogador      = ""
			Salvar.player_id          = ""
			Salvar.id_sequencial      = 0
			Salvar.nome_ja_renomeado  = false
			Salvar.credenciais_versao = 0
			var _dir := DirAccess.open("user://")
			if _dir:
				if FileAccess.file_exists(_acc_path): _dir.remove(_acc_path.get_file())
				if FileAccess.file_exists("user://save.json"): _dir.remove("save.json")
			get_tree().change_scene_to_file("res://scenes/Menu.tscn"))
		_config_panel.add_child(btn_logout)

	var btn_f:= Button.new()
	btn_f.text = "FECHAR"
	btn_f.position = Vector2(200, 608)
	btn_f.size = Vector2(700, 50)
	btn_f.focus_mode = Control.FOCUS_NONE
	btn_f.add_theme_font_size_override("font_size", 21)
	var sty_f:= StyleBoxFlat.new()
	sty_f.bg_color = Color(0.08, 0.08, 0.1, 0.9)
	sty_f.border_color = Color(0.38, 0.4, 0.48, 0.7)
	for side in ["left", "right", "top", "bottom"]:
		sty_f.set("border_width_" + side, 1)
	for corner in ["top_left", "top_right", "bottom_left", "bottom_right"]:
		sty_f.set("corner_radius_" + corner, 8)
	btn_f.add_theme_stylebox_override("normal", sty_f)
	btn_f.add_theme_color_override("font_color", Color(0.6, 0.62, 0.68))
	btn_f.pressed.connect( func():
		Acessibilidade.processar("config_fechar", "Fechar configuraÃ§Ãµes.", _fechar_config))
	_config_panel.add_child(btn_f)
	_corrigir_textos_ui(_config_panel)


func _abrir_tutorial() -> void:
	if _tut_overlay: return
	var vp := get_viewport().get_visible_rect().size
	_tut_overlay = CanvasLayer.new()
	_tut_overlay.layer = 10
	add_child(_tut_overlay)

	var passos := [
		{"titulo": "Bem-vindo ao Cyron Defense!",
		 "texto": "VocÃª controla uma torre que defende contra\nondas de inimigos cada vez mais fortes.\nVamos aprender a jogar passo a passo!",
		 "rect": Rect2(), "cor": Color(0.25, 0.78, 1.0)},
		{"titulo": "DIFICULDADE",
		 "texto": "Escolha a dificuldade aqui antes de jogar.\nComece pelo FÃCIL para aprender!\nModos mais difÃ­ceis se desbloqueiam com o tempo.",
		 "rect": _tut_diff_rect, "cor": Color(0.25, 0.78, 1.0)},
		{"titulo": "JOGAR",
		 "texto": "Clique aqui para iniciar uma partida.\nSua torre ATIRA AUTOMATICAMENTE nos inimigos.\nSobreviva o mÃ¡ximo de waves possÃ­vel!",
		 "rect": _tut_jogar_rect, "cor": Color(0.0, 0.72, 1.0)},
		{"titulo": "LOJA",
		 "texto": "Use o ouro ganho nas partidas para comprar\nmelhorias PERMANENTES da sua torre.\nForÃ§a, ResistÃªncia, VisÃ£o, CadÃªncia e Fortuna.",
		 "rect": _tut_loja_rect, "cor": Color(1.0, 0.78, 0.0)},
		{"titulo": "INVENTÃRIO",
		 "texto": "Equipe Skins que dÃ£o bÃ´nus Ã  torre,\nComandantes que operam a torre por vocÃª\ne Habilidades especiais ativÃ¡veis em jogo.",
		 "rect": _tut_inv_rect, "cor": Color(0.35, 0.82, 0.6)},
		{"titulo": "TALENTOS",
		 "texto": "Desbloqueie Talentos com cristais ganhos nas partidas.\nDÃ£o bÃ´nus PERMANENTES a cada partida.\nConstrua uma Ã¡rvore poderosa ao longo do tempo!",
		 "rect": _tut_tal_rect, "cor": Color(0.5, 0.25, 1.0)},
		{"titulo": "ESTATÃSTICAS",
		 "texto": "Acompanhe seu progresso: recordes,\nhistÃ³rico de partidas e mobs eliminados.\nCompita no RANKING GLOBAL com outros jogadores!",
		 "rect": _tut_hist_rect, "cor": Color(0.1, 0.85, 0.6)},
		{"titulo": "Pronto para jogar!",
		 "texto": "VocÃª aprendeu o bÃ¡sico!\nAgora jogue sua primeira partida no modo FÃCIL.\nDicas em jogo vÃ£o te guiar durante as waves.",
		 "rect": Rect2(), "cor": Color(0.25, 0.78, 1.0)},
	]

	var step_wrap := [0]

	var bg := ColorRect.new()
	bg.color = Color(0.0, 0.0, 0.0, 0.0)
	bg.position = Vector2.ZERO; bg.size = vp
	bg.mouse_filter = Control.MOUSE_FILTER_STOP
	_tut_overlay.add_child(bg)

	var highlight := Control.new()
	highlight.position = Vector2.ZERO; highlight.size = vp
	highlight.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_tut_overlay.add_child(highlight)

	var panel_h : float = 220.0
	var panel := Panel.new()
	panel.position = Vector2(vp.x * 0.5 - 320, vp.y - panel_h - 20)
	panel.size = Vector2(640, panel_h)
	var psty := StyleBoxFlat.new()
	psty.bg_color = Color(0.04, 0.06, 0.12, 0.97)
	psty.border_color = Color(0.28, 0.55, 0.95, 0.9)
	for s in ["left","right","top","bottom"]: psty.set("border_width_"+s, 2)
	for c in ["top_left","top_right","bottom_left","bottom_right"]: psty.set("corner_radius_"+c, 12)
	panel.add_theme_stylebox_override("panel", psty)
	_tut_overlay.add_child(panel)

	var lbarra := Label.new()
	lbarra.name = "LBarra"
	lbarra.position = Vector2(16, 10); lbarra.size = Vector2(610, 18)
	lbarra.add_theme_font_size_override("font_size", 12)
	lbarra.add_theme_color_override("font_color", Color(0.4, 0.5, 0.7))
	panel.add_child(lbarra)

	var ltit := Label.new()
	ltit.name = "LTit"
	ltit.position = Vector2(16, 28); ltit.size = Vector2(610, 30)
	ltit.add_theme_font_size_override("font_size", 22)
	ltit.add_theme_color_override("font_color", Color(0.85, 0.9, 1.0))
	panel.add_child(ltit)

	var ltxt := Label.new()
	ltxt.name = "LTxt"
	ltxt.position = Vector2(16, 62); ltxt.size = Vector2(610, 90)
	ltxt.autowrap_mode = TextServer.AUTOWRAP_WORD
	ltxt.add_theme_font_size_override("font_size", 16)
	ltxt.add_theme_color_override("font_color", Color(0.72, 0.8, 0.92))
	panel.add_child(ltxt)

	var btn_pular := Button.new()
	btn_pular.text = "Pular Tutorial"
	btn_pular.position = Vector2(16, panel_h - 46); btn_pular.size = Vector2(160, 34)
	btn_pular.focus_mode = Control.FOCUS_NONE
	btn_pular.add_theme_font_size_override("font_size", 14)
	var sty_p := StyleBoxFlat.new(); sty_p.bg_color = Color(0.1,0.1,0.14,0.9)
	sty_p.border_color = Color(0.35,0.4,0.5,0.6)
	for s in ["left","right","top","bottom"]: sty_p.set("border_width_"+s,1)
	for c in ["top_left","top_right","bottom_left","bottom_right"]: sty_p.set("corner_radius_"+c,6)
	btn_pular.add_theme_stylebox_override("normal", sty_p)
	btn_pular.add_theme_color_override("font_color", Color(0.5,0.55,0.65))
	panel.add_child(btn_pular)

	var btn_prox := Button.new()
	btn_prox.name = "BtnProx"
	btn_prox.text = "PrÃ³ximo  â†’"
	btn_prox.position = Vector2(464, panel_h - 46); btn_prox.size = Vector2(160, 34)
	btn_prox.focus_mode = Control.FOCUS_NONE
	btn_prox.add_theme_font_size_override("font_size", 15)
	var sty_n := StyleBoxFlat.new(); sty_n.bg_color = Color(0.06,0.12,0.28,0.95)
	sty_n.border_color = Color(0.28,0.55,0.95,0.85)
	for s in ["left","right","top","bottom"]: sty_n.set("border_width_"+s,2)
	for c in ["top_left","top_right","bottom_left","bottom_right"]: sty_n.set("corner_radius_"+c,6)
	btn_prox.add_theme_stylebox_override("normal", sty_n)
	btn_prox.add_theme_color_override("font_color", Color(0.5,0.82,1.0))
	panel.add_child(btn_prox)

	var _atualizar_passo := func(idx: int) -> void:
		var p : Dictionary = passos[idx] as Dictionary
		var cor : Color = p["cor"] as Color
		var rect : Rect2 = p["rect"] as Rect2
		var total := passos.size()

		lbarra.text = "Passo %d de %d" % [idx + 1, total]
		ltit.text   = p["titulo"] as String
		ltxt.text   = p["texto"] as String
		ltit.add_theme_color_override("font_color", Color(cor.r+0.1, cor.g+0.1, cor.b+0.1, 1.0))
		psty.border_color = Color(cor.r*0.7, cor.g*0.7, cor.b*0.7, 0.9)
		panel.add_theme_stylebox_override("panel", psty)

		var btn_p : Button = btn_prox
		var eh_ultimo := (idx == total - 1)
		btn_p.text = "Jogar Agora!" if eh_ultimo else "PrÃ³ximo  â†’"
		var sty_nn := sty_n.duplicate() as StyleBoxFlat
		sty_nn.border_color = Color(cor.r*0.6, cor.g*0.6, cor.b*0.6, 0.85) if not eh_ultimo else Color(0.1,0.65,0.2,0.9)
		sty_nn.bg_color = Color(0.06,0.14,0.06,0.95) if eh_ultimo else Color(0.06,0.12,0.28,0.95)
		btn_p.add_theme_stylebox_override("normal", sty_nn)
		btn_p.add_theme_color_override("font_color", Color(0.4,1.0,0.5) if eh_ultimo else Color(0.5,0.82,1.0))

		bg.color = Color(0.0, 0.0, 0.0, 0.0 if rect == Rect2() else 0.72)
		highlight.queue_redraw()

	highlight.draw.connect(func():
		var idx : int = step_wrap[0] as int
		var p : Dictionary = passos[idx] as Dictionary
		var rect : Rect2 = p["rect"] as Rect2
		var cor : Color = p["cor"] as Color
		if rect == Rect2(): return
		var pad := 6.0
		var r := Rect2(rect.position - Vector2(pad, pad), rect.size + Vector2(pad*2, pad*2))
		highlight.draw_rect(r, Color(cor.r, cor.g, cor.b, 0.18), true)
		highlight.draw_rect(r, Color(cor.r, cor.g, cor.b, 0.9), false, 2.5)
		var arr_x := r.position.x + r.size.x * 0.5
		var arr_y := r.position.y + r.size.y + 8
		var pts := PackedVector2Array([Vector2(arr_x, arr_y), Vector2(arr_x - 10, arr_y + 16), Vector2(arr_x + 10, arr_y + 16)])
		highlight.draw_polygon(pts, PackedColorArray([Color(cor.r, cor.g, cor.b, 0.9), Color(cor.r, cor.g, cor.b, 0.9), Color(cor.r, cor.g, cor.b, 0.9)]))
	)

	var _fechar_tut := func() -> void:
		Salvar.tutorial_menu_visto = true
		Salvar.salvar()
		if _tut_overlay and is_instance_valid(_tut_overlay):
			_tut_overlay.queue_free()
		_tut_overlay = null

	btn_pular.pressed.connect(func():
		_fechar_tut.call()
	)

	btn_prox.pressed.connect(func():
		var idx : int = step_wrap[0] as int
		if idx >= passos.size() - 1:
			_fechar_tut.call()
			return
		step_wrap[0] = idx + 1
		_atualizar_passo.call(step_wrap[0])
		highlight.queue_redraw()
	)

	_atualizar_passo.call(0)


func _on_reset_press(btn: Button) -> void :
	if not _config_confirm:
		_config_confirm = true
		btn.text = "CONFIRMAR RESET?"
		var sty_c:= StyleBoxFlat.new()
		sty_c.bg_color = Color(0.55, 0.06, 0.06, 0.95)
		sty_c.border_color = Color(1.0, 0.2, 0.2, 1.0)
		for side in ["left", "right", "top", "bottom"]:
			sty_c.set("border_width_" + side, 2)
		for corner in ["top_left", "top_right", "bottom_left", "bottom_right"]:
			sty_c.set("corner_radius_" + corner, 10)
		btn.add_theme_stylebox_override("normal", sty_c)
		var lc = _config_panel.find_child("LConfirm")
		if lc: lc.visible = true
	else:
		RankingOnline.remover_do_ranking(Salvar.nome_jogador)
		RankingOnline.apagar_save_nuvem(Salvar.nome_jogador, Salvar.player_id)
		Salvar.resetar()
		Salvar.nome_jogador       = ""
		Salvar.email_jogador      = ""
		Salvar.senha_jogador      = ""
		Salvar.player_id          = ""
		Salvar.id_sequencial      = 0
		Salvar.nome_ja_renomeado  = false
		Salvar.credenciais_versao = 0
		if FileAccess.file_exists("user://save.json"):
			DirAccess.open("user://").remove("save.json")
		Som.upgrade()
		get_tree().change_scene_to_file("res://scenes/Menu.tscn")


func _fechar_config() -> void :
	Acessibilidade.cancelar_foco()
	if _config_overlay and is_instance_valid(_config_overlay):
		_config_overlay.queue_free()
	if _config_panel and is_instance_valid(_config_panel):
		_config_panel.queue_free()
	_config_overlay = null
	_config_panel = null
	_config_confirm = false
	_ui_ref = null
	if _menu_contents:
		_menu_contents.show()




func _inv_painel(parent: Node, x: float, y: float, w: float, h: float,
		bg: Color, bord: Color, bw: int = 1) -> Panel:
	var p := Panel.new()
	p.position = Vector2(x, y); p.size = Vector2(w, h)
	p.mouse_filter = Control.MOUSE_FILTER_PASS
	var s := StyleBoxFlat.new()
	s.bg_color = bg; s.border_color = bord
	for sd in ["left","right","top","bottom"]: s.set("border_width_" + sd, bw)
	for c in ["top_left","top_right","bottom_left","bottom_right"]: s.set("corner_radius_" + c, 3)
	p.add_theme_stylebox_override("panel", s)
	parent.add_child(p)
	return p


func _ui_premium_style(cor: Color, active: bool = false) -> StyleBoxFlat:
	var sty := StyleBoxFlat.new()
	sty.bg_color = Color(cor.r * (0.13 if active else 0.07), cor.g * (0.13 if active else 0.07), cor.b * (0.13 if active else 0.07), 0.94)
	sty.border_color = Color(cor.r, cor.g, cor.b, 0.82 if active else 0.48)
	for side in ["left", "right", "top", "bottom"]:
		sty.set("border_width_" + side, 2 if active else 1)
	for corner in ["top_left", "top_right", "bottom_left", "bottom_right"]:
		sty.set("corner_radius_" + corner, 3)
	return sty


func _ui_premium_button(btn: Button, cor: Color, active: bool = false) -> void:
	var normal := _ui_premium_style(cor, active)
	var hover := _ui_premium_style(Color(minf(cor.r + 0.10, 1.0), minf(cor.g + 0.10, 1.0), minf(cor.b + 0.10, 1.0)), true)
	var pressed := _ui_premium_style(Color(cor.r * 0.85, cor.g * 0.85, cor.b * 0.85), true)
	btn.add_theme_stylebox_override("normal", normal)
	btn.add_theme_stylebox_override("hover", hover)
	btn.add_theme_stylebox_override("pressed", pressed)
	btn.add_theme_stylebox_override("focus", normal)
	btn.add_theme_stylebox_override("hover_pressed", pressed)
	btn.add_theme_color_override("font_color", Color(minf(cor.r + 0.34, 1.0), minf(cor.g + 0.34, 1.0), minf(cor.b + 0.34, 1.0), 0.96))
	btn.add_theme_font_override("font", _font_tech)


func _ui_tech_label(label: Control, spacing: float = 1.0) -> void:
	label.add_theme_font_override("font", _font_tech)
	label.add_theme_constant_override("outline_size", 0)
	label.add_theme_constant_override("letter_spacing", int(spacing))


func _ui_add_button_texture_icon(btn: Button, tex: Texture2D, region: Rect2, icon_size: Vector2 = Vector2(32, 32)) -> void:
	var atlas := AtlasTexture.new()
	atlas.atlas = tex
	atlas.region = region

	var icon := TextureRect.new()
	icon.position = Vector2(4, (btn.size.y - icon_size.y) * 0.5)
	icon.size = icon_size
	icon.custom_minimum_size = Vector2.ZERO
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon.texture = atlas
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	btn.add_child(icon)


func _ui_image_menu_button(tex: Texture2D, pos: Vector2, sz: Vector2) -> Button:
	var btn := Button.new()
	btn.text = ""
	btn.position = pos
	btn.size = sz
	btn.custom_minimum_size = sz
	btn.focus_mode = Control.FOCUS_NONE
	btn.flat = true

	var empty := StyleBoxEmpty.new()
	for state in ["normal", "hover", "pressed", "focus", "hover_pressed", "disabled"]:
		btn.add_theme_stylebox_override(state, empty)

	var image := TextureRect.new()
	image.position = Vector2.ZERO
	image.size = sz
	image.custom_minimum_size = Vector2.ZERO
	image.mouse_filter = Control.MOUSE_FILTER_IGNORE
	image.texture = tex
	image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	btn.add_child(image)

	btn.mouse_entered.connect(func():
		image.modulate = Color(1.12, 1.12, 1.12, 1.0)
	)
	btn.mouse_exited.connect(func():
		image.modulate = Color.WHITE
	)
	btn.button_down.connect(func():
		image.scale = Vector2(0.96, 0.96)
		image.position = sz * 0.02
	)
	btn.button_up.connect(func():
		image.scale = Vector2.ONE
		image.position = Vector2.ZERO
	)
	return btn


func _ui_title_label(label: Label, spacing: float = 4.0) -> void:
	label.text = _texto_ui_limpo(label.text).to_upper()
	_ui_tech_label(label, spacing)
	label.add_theme_font_override("font", _font_title)
	label.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.72))
	label.add_theme_constant_override("shadow_offset_x", 1)
	label.add_theme_constant_override("shadow_offset_y", 1)


func _ui_trim_fit(txt: String, max_len: int) -> String:
	if txt.length() <= max_len:
		return txt
	return txt.substr(0, max_len - 1) + "."


func _ui_panel_frame(parent: Node, rect: Rect2, cor: Color, alpha: float = 0.65) -> Control:
	var fr := Control.new()
	fr.position = rect.position
	fr.size = rect.size
	fr.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fr.draw.connect(func():
		var w := fr.size.x
		var h := fr.size.y
		var cut := 18.0
		var pts := PackedVector2Array([
			Vector2(cut, 0), Vector2(w - cut, 0), Vector2(w, cut),
			Vector2(w, h - cut), Vector2(w - cut, h), Vector2(cut, h),
			Vector2(0, h - cut), Vector2(0, cut), Vector2(cut, 0)
		])
		fr.draw_polyline(pts, Color(cor.r, cor.g, cor.b, 0.22 * alpha), 1.0)
		fr.draw_line(Vector2(26, 10), Vector2(w * 0.38, 10), Color(cor.r, cor.g, cor.b, 0.22 * alpha), 1.0)
		fr.draw_line(Vector2(w - 26, h - 10), Vector2(w * 0.62, h - 10), Color(cor.r, cor.g, cor.b, 0.18 * alpha), 1.0)
		var cl := 34.0
		var c := Color(cor.r, cor.g, cor.b, 0.48 * alpha)
		fr.draw_line(Vector2(0, 0), Vector2(cl, 0), c, 1.5)
		fr.draw_line(Vector2(0, 0), Vector2(0, cl), c, 1.5)
		fr.draw_line(Vector2(w, 0), Vector2(w - cl, 0), c, 1.5)
		fr.draw_line(Vector2(w, 0), Vector2(w, cl), c, 1.5)
		fr.draw_line(Vector2(0, h), Vector2(cl, h), c, 1.5)
		fr.draw_line(Vector2(0, h), Vector2(0, h - cl), c, 1.5)
		fr.draw_line(Vector2(w, h), Vector2(w - cl, h), c, 1.5)
		fr.draw_line(Vector2(w, h), Vector2(w, h - cl), c, 1.5)
	)
	parent.add_child(fr)
	return fr


func _ui_header_title(parent: Node, txt: String, y: float, w: float, cor: Color) -> void:
	var deco := Control.new()
	deco.position = Vector2(0, y)
	deco.size = Vector2(w, 42)
	deco.mouse_filter = Control.MOUSE_FILTER_IGNORE
	deco.draw.connect(func():
		var cx := w * 0.5
		deco.draw_line(Vector2(cx - 190.0, 24.0), Vector2(cx - 74.0, 24.0), Color(cor.r, cor.g, cor.b, 0.34), 1.0)
		deco.draw_line(Vector2(cx + 74.0, 24.0), Vector2(cx + 190.0, 24.0), Color(cor.r, cor.g, cor.b, 0.34), 1.0)
		deco.draw_line(Vector2(cx - 74.0, 24.0), Vector2(cx - 52.0, 17.0), Color(cor.r, cor.g, cor.b, 0.20), 1.0)
		deco.draw_line(Vector2(cx + 74.0, 24.0), Vector2(cx + 52.0, 17.0), Color(cor.r, cor.g, cor.b, 0.20), 1.0)
	)
	parent.add_child(deco)
	var h := _inv_lbl(parent, txt, 0, y + 5.0, w, 34, 23, Color(0.92, 0.92, 0.98, 0.96), HORIZONTAL_ALIGNMENT_CENTER)
	_ui_title_label(h, 4.0)


func _ui_top_button(parent: Node, txt: String, x: float, y: float, w: float, cor: Color) -> Button:
	var btn := Button.new()
	btn.text = txt
	btn.position = Vector2(x, y)
	btn.size = Vector2(w, 32.0)
	btn.focus_mode = Control.FOCUS_NONE
	btn.add_theme_font_size_override("font_size", 12)
	_ui_premium_button(btn, cor, false)
	parent.add_child(btn)
	return btn


func _ui_draw_stat_icon(c: Control, kind: String, center: Vector2, cor: Color, sc: float = 1.0) -> void:
	var glow := Color(cor.r, cor.g, cor.b, 0.16)
	c.draw_circle(center, 12.0 * sc, glow)
	match kind:
		"dano":
			var pts := PackedVector2Array([center + Vector2(-3, -12) * sc, center + Vector2(7, -3) * sc, center + Vector2(1, -2) * sc, center + Vector2(5, 12) * sc, center + Vector2(-7, 1) * sc, center + Vector2(-1, 0) * sc])
			c.draw_colored_polygon(pts, Color(cor.r, cor.g, cor.b, 0.88))
		"vida":
			c.draw_circle(center + Vector2(-4, -2) * sc, 5.0 * sc, Color(cor.r, cor.g, cor.b, 0.85))
			c.draw_circle(center + Vector2(4, -2) * sc, 5.0 * sc, Color(cor.r, cor.g, cor.b, 0.85))
			var pts2 := PackedVector2Array([center + Vector2(-9, 0) * sc, center + Vector2(9, 0) * sc, center + Vector2(0, 12) * sc])
			c.draw_colored_polygon(pts2, Color(cor.r, cor.g, cor.b, 0.85))
		"cadencia":
			c.draw_arc(center, 9.0 * sc, PI * 0.24, PI * 1.75, 24, Color(cor.r, cor.g, cor.b, 0.95), 2.4 * sc, true)
			c.draw_circle(center + Vector2(3, -2) * sc, 3.0 * sc, Color(cor.r, cor.g, cor.b, 0.60))
		"alcance":
			c.draw_arc(center, 10.0 * sc, 0, TAU, 36, Color(cor.r, cor.g, cor.b, 0.95), 2.0 * sc, true)
			c.draw_circle(center, 3.0 * sc, Color(cor.r, cor.g, cor.b, 0.95))
		"regen":
			c.draw_line(center + Vector2(-9, 0) * sc, center + Vector2(9, 0) * sc, Color(cor.r, cor.g, cor.b, 0.9), 3.0 * sc)
			c.draw_line(center + Vector2(0, -9) * sc, center + Vector2(0, 9) * sc, Color(cor.r, cor.g, cor.b, 0.9), 3.0 * sc)
		"reduc":
			var pts3 := PackedVector2Array([center + Vector2(0, -12) * sc, center + Vector2(10, -5) * sc, center + Vector2(7, 9) * sc, center + Vector2(0, 13) * sc, center + Vector2(-7, 9) * sc, center + Vector2(-10, -5) * sc])
			c.draw_polyline(pts3 + PackedVector2Array([pts3[0]]), Color(cor.r, cor.g, cor.b, 0.95), 2.0 * sc)
		"multi":
			for off in [-6.0, 0.0, 6.0]:
				c.draw_line(center + Vector2(off, -9) * sc, center + Vector2(off, 9) * sc, Color(cor.r, cor.g, cor.b, 0.84), 2.0 * sc)
		"comandante":
			var pts4 := PackedVector2Array([center + Vector2(0, -12) * sc, center + Vector2(11, 0) * sc, center + Vector2(0, 12) * sc, center + Vector2(-11, 0) * sc])
			c.draw_polyline(pts4 + PackedVector2Array([pts4[0]]), Color(cor.r, cor.g, cor.b, 0.92), 2.0 * sc)
			c.draw_circle(center, 3.0 * sc, Color(cor.r, cor.g, cor.b, 0.92))
		"fortuna":
			for i in range(5):
				var a := -PI * 0.5 + float(i) * TAU / 5.0
				var b := a + PI / 5.0
				c.draw_line(center, center + Vector2(cos(a), sin(a)) * 11.0 * sc, Color(cor.r, cor.g, cor.b, 0.86), 1.8 * sc)
				c.draw_line(center + Vector2(cos(a), sin(a)) * 11.0 * sc, center + Vector2(cos(b), sin(b)) * 5.0 * sc, Color(cor.r, cor.g, cor.b, 0.70), 1.4 * sc)
		_:
			c.draw_circle(center, 5.0 * sc, Color(cor.r, cor.g, cor.b, 0.9))


func _ui_draw_menu_icon(c: Control, kind: String, center: Vector2, cor: Color, sc: float = 1.0) -> void:
	var pts := PackedVector2Array()
	for i in range(8):
		var a := float(i) * TAU / 8.0 + PI / 8.0
		pts.append(center + Vector2(cos(a), sin(a)) * 22.0 * sc)
	var fill := PackedColorArray()
	for _i in range(8):
		fill.append(Color(cor.r * 0.08, cor.g * 0.08, cor.b * 0.08, 0.76))
	c.draw_polygon(pts, fill)
	var loop := PackedVector2Array(pts)
	loop.append(pts[0])
	c.draw_polyline(loop, Color(cor.r, cor.g, cor.b, 0.82), 1.8 * sc)
	c.draw_circle(center, 15.0 * sc, Color(cor.r, cor.g, cor.b, 0.10))
	match kind:
		"jogar":
			c.draw_arc(center, 12.0 * sc, 0, TAU, 36, Color(0.92,0.98,1.0,0.85), 1.4 * sc, true)
			c.draw_line(center + Vector2(-15,0) * sc, center + Vector2(15,0) * sc, Color(cor.r,cor.g,cor.b,0.75), 1.4 * sc)
			c.draw_line(center + Vector2(0,-15) * sc, center + Vector2(0,15) * sc, Color(cor.r,cor.g,cor.b,0.75), 1.4 * sc)
			c.draw_circle(center, 4.0 * sc, Color(cor.r, cor.g, cor.b, 0.95))
		"loja":
			var basket := PackedVector2Array([
				center + Vector2(-13, -7) * sc,
				center + Vector2(13, -7) * sc,
				center + Vector2(9, 7) * sc,
				center + Vector2(-8, 7) * sc,
				center + Vector2(-13, -7) * sc
			])
			var basket_fill := PackedColorArray([
				Color(cor.r, cor.g, cor.b, 0.18),
				Color(cor.r, cor.g, cor.b, 0.18),
				Color(cor.r, cor.g, cor.b, 0.10),
				Color(cor.r, cor.g, cor.b, 0.10)
			])
			c.draw_polygon(PackedVector2Array([basket[0], basket[1], basket[2], basket[3]]), basket_fill)
			c.draw_line(center + Vector2(-17, -13) * sc, center + Vector2(-13, -7) * sc, Color(0.98, 0.95, 0.82, 0.88), 2.3 * sc)
			c.draw_polyline(basket, Color(cor.r, cor.g, cor.b, 0.96), 2.1 * sc)
			c.draw_line(center + Vector2(-8, -3) * sc, center + Vector2(10, -3) * sc, Color(cor.r, cor.g, cor.b, 0.52), 1.3 * sc)
			c.draw_line(center + Vector2(-6, 2) * sc, center + Vector2(8, 2) * sc, Color(cor.r, cor.g, cor.b, 0.44), 1.2 * sc)
			c.draw_line(center + Vector2(-6, -6) * sc, center + Vector2(-3, 6) * sc, Color(cor.r, cor.g, cor.b, 0.46), 1.2 * sc)
			c.draw_line(center + Vector2(3, -6) * sc, center + Vector2(1, 6) * sc, Color(cor.r, cor.g, cor.b, 0.46), 1.2 * sc)
			c.draw_circle(center + Vector2(-6, 12) * sc, 3.0 * sc, Color(0.98, 0.95, 0.82, 0.92))
			c.draw_circle(center + Vector2(8, 12) * sc, 3.0 * sc, Color(0.98, 0.95, 0.82, 0.92))
			c.draw_circle(center + Vector2(-6, 12) * sc, 1.4 * sc, Color(0.02, 0.02, 0.03, 0.88))
			c.draw_circle(center + Vector2(8, 12) * sc, 1.4 * sc, Color(0.02, 0.02, 0.03, 0.88))
		"inventario":
			var top := center + Vector2(0, -15) * sc
			var right := center + Vector2(14, -6) * sc
			var bottom_r := center + Vector2(14, 8) * sc
			var bottom := center + Vector2(0, 16) * sc
			var bottom_l := center + Vector2(-14, 8) * sc
			var left := center + Vector2(-14, -6) * sc
			var cube := PackedVector2Array([top, right, bottom_r, bottom, bottom_l, left, top])
			c.draw_polyline(cube, Color(cor.r, cor.g, cor.b, 0.94), 2.0 * sc)
			c.draw_line(left, center, Color(cor.r, cor.g, cor.b, 0.58), 1.4 * sc)
			c.draw_line(right, center, Color(cor.r, cor.g, cor.b, 0.58), 1.4 * sc)
			c.draw_line(center, bottom, Color(cor.r, cor.g, cor.b, 0.58), 1.4 * sc)
			c.draw_circle(center, 3.3 * sc, Color(0.94, 0.98, 1.0, 0.86))
		"talentos":
			var star := PackedVector2Array()
			for i in range(12):
				var radius := 15.0 if i % 2 == 0 else 6.2
				var ang := -PI * 0.5 + float(i) * TAU / 12.0
				star.append(center + Vector2(cos(ang), sin(ang)) * radius * sc)
			star.append(star[0])
			c.draw_polyline(star, Color(cor.r, cor.g, cor.b, 0.94), 1.9 * sc)
			c.draw_arc(center, 10.0 * sc, 0.0, TAU, 36, Color(cor.r, cor.g, cor.b, 0.34), 1.0 * sc, true)
			c.draw_circle(center, 3.0 * sc, Color(0.95, 0.94, 1.0, 0.9))
			for i in range(6):
				var ang2 := -PI * 0.5 + float(i) * TAU / 6.0
				c.draw_line(center, center + Vector2(cos(ang2), sin(ang2)) * 11.0 * sc, Color(cor.r, cor.g, cor.b, 0.42), 1.0 * sc)
		"sair":
			var door := PackedVector2Array([
				center + Vector2(-15, -14) * sc,
				center + Vector2(4, -14) * sc,
				center + Vector2(4, 14) * sc,
				center + Vector2(-15, 14) * sc,
				center + Vector2(-15, -14) * sc
			])
			c.draw_polyline(door, Color(cor.r, cor.g, cor.b, 0.78), 1.8 * sc)
			var arr := PackedVector2Array([center + Vector2(-4, -5) * sc, center + Vector2(10, -5) * sc, center + Vector2(10, -13) * sc, center + Vector2(20, 0) * sc, center + Vector2(10, 13) * sc, center + Vector2(10, 5) * sc, center + Vector2(-4, 5) * sc])
			c.draw_colored_polygon(arr, Color(cor.r, cor.g, cor.b, 0.80))
			c.draw_polyline(arr + PackedVector2Array([arr[0]]), Color(1.0, 0.9, 0.82, 0.60), 1.1 * sc)
		_:
			_ui_draw_stat_icon(c, kind, center, cor, 1.25 * sc)


func _ui_stat_icon(parent: Node, kind: String, cor: Color, x: float, y: float, sz: float) -> Control:
	var ico := Control.new()
	ico.position = Vector2(x, y)
	ico.size = Vector2(sz, sz)
	ico.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ico.draw.connect(func():
		_ui_draw_stat_icon(ico, kind, Vector2(sz * 0.5, sz * 0.5), cor, sz / 28.0)
	)
	parent.add_child(ico)
	return ico


func _inv_lbl(parent: Node, txt: String, x: float, y: float, w: float, h: float,
		fs: int, cor: Color, align: int = HORIZONTAL_ALIGNMENT_LEFT) -> Label:
	var l := Label.new()
	l.text = txt; l.position = Vector2(x, y); l.size = Vector2(w, h)
	l.add_theme_font_size_override("font_size", fs)
	l.add_theme_color_override("font_color", cor)
	_ui_tech_label(l, 0.0)
	l.horizontal_alignment = align
	l.clip_text = true
	l.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(l)
	return l


func _comandante_meta(pid: String) -> Dictionary:
	match pid:
		"nexus":
			return {
				"titulo": "COMANDANTE SUPREMO",
				"coligacao": "COLIGAÇÃO RUBRA",
				"lema": "POR PODER. POR ORDEM. POR SUPREMACIA.",
				"cor": Color(1.0, 0.10, 0.08),
				"escura": Color(0.18, 0.02, 0.015)
			}
		"phantom", "eclipse":
			return {
				"titulo": "COMANDANTE DE INTELIGÊNCIA",
				"coligacao": "COLIGAÇÃO PHANTOM",
				"lema": "POR CONHECIMENTO. POR SOMBRA. POR EVOLUÇÃO.",
				"cor": Color(0.72, 0.22, 1.0),
				"escura": Color(0.08, 0.02, 0.14)
			}
		_:
			return {
				"titulo": "COMANDANTE OPERACIONAL",
				"coligacao": "COLIGAÇÃO ÁUREA",
				"lema": "POR HONRA. POR DEVER. POR EQUILÍBRIO.",
				"cor": Color(1.0, 0.78, 0.18),
				"escura": Color(0.14, 0.10, 0.02)
			}


func _inv_fundo_comando(parent: Node, vp: Vector2, cor: Color) -> Control:
	var bg := Control.new()
	bg.position = Vector2.ZERO
	bg.size = vp
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bg.draw.connect(func():
		bg.draw_rect(Rect2(Vector2.ZERO, vp), Color(0.004, 0.006, 0.012, 1.0), true)
		var mid := Vector2(vp.x * 0.55, vp.y * 0.48)
		for r in range(7):
			var rr := 120.0 + float(r) * 74.0
			bg.draw_arc(mid, rr, -0.55, 0.78, 80, Color(cor.r, cor.g, cor.b, 0.030), 1.0, true)
		for i in range(52):
			var x := fmod(float(i * 149 + 37), maxf(vp.x, 1.0))
			var y := fmod(float(i * 83 + 71), maxf(vp.y, 1.0))
			var a := 0.18 + 0.20 * absf(sin(float(i) * 1.7))
			bg.draw_circle(Vector2(x, y), 0.7 + float(i % 3) * 0.35, Color(0.55, 0.78, 1.0, a))
		for gx in range(0, int(vp.x) + 80, 80):
			bg.draw_line(Vector2(float(gx), 42), Vector2(float(gx) + 36.0, vp.y - 30.0), Color(cor.r, cor.g, cor.b, 0.018), 1.0)
		bg.draw_line(Vector2(16, 28), Vector2(vp.x - 16, 28), Color(cor.r, cor.g, cor.b, 0.24), 1.0)
		bg.draw_line(Vector2(16, vp.y - 18), Vector2(vp.x - 16, vp.y - 18), Color(cor.r, cor.g, cor.b, 0.18), 1.0)
		var cpad := 15.0
		var clen := 42.0
		var corners := [
			[Vector2(cpad, cpad), Vector2(cpad + clen, cpad), Vector2(cpad, cpad + clen)],
			[Vector2(vp.x - cpad, cpad), Vector2(vp.x - cpad - clen, cpad), Vector2(vp.x - cpad, cpad + clen)],
			[Vector2(cpad, vp.y - cpad), Vector2(cpad + clen, vp.y - cpad), Vector2(cpad, vp.y - cpad - clen)],
			[Vector2(vp.x - cpad, vp.y - cpad), Vector2(vp.x - cpad - clen, vp.y - cpad), Vector2(vp.x - cpad, vp.y - cpad - clen)]
		]
		for cdata in corners:
			bg.draw_line(cdata[0], cdata[1], Color(cor.r, cor.g, cor.b, 0.42), 1.5)
			bg.draw_line(cdata[0], cdata[2], Color(cor.r, cor.g, cor.b, 0.42), 1.5)
	)
	parent.add_child(bg)
	return bg


func _inv_decorar_painel(p: Panel, cor: Color, intensidade: float = 1.0) -> void:
	var deco := Control.new()
	deco.position = Vector2.ZERO
	deco.size = p.size
	deco.mouse_filter = Control.MOUSE_FILTER_IGNORE
	deco.draw.connect(func():
		var w := deco.size.x
		var h := deco.size.y
		var cut := 12.0
		var pts := PackedVector2Array([
			Vector2(cut, 0), Vector2(w - cut, 0), Vector2(w, cut),
			Vector2(w, h - cut), Vector2(w - cut, h), Vector2(cut, h),
			Vector2(0, h - cut), Vector2(0, cut), Vector2(cut, 0)
		])
		deco.draw_rect(Rect2(2, 2, w - 4, h - 4), Color(cor.r * 0.05, cor.g * 0.05, cor.b * 0.05, 0.06 * intensidade), true)
		deco.draw_polyline(pts, Color(cor.r, cor.g, cor.b, 0.30 * intensidade), 1.0)
		deco.draw_polyline(PackedVector2Array([Vector2(18, 8), Vector2(w * 0.34, 8)]), Color(cor.r, cor.g, cor.b, 0.12 * intensidade), 1.0)
		deco.draw_polyline(PackedVector2Array([Vector2(w - 18, h - 8), Vector2(w * 0.66, h - 8)]), Color(cor.r, cor.g, cor.b, 0.12 * intensidade), 1.0)
		for i in range(3):
			var off := float(i) * 6.0
			deco.draw_line(Vector2(8 + off, 8), Vector2(8, 8 + off), Color(cor.r, cor.g, cor.b, 0.28 * intensidade), 1.0)
			deco.draw_line(Vector2(w - 8 - off, 8), Vector2(w - 8, 8 + off), Color(cor.r, cor.g, cor.b, 0.28 * intensidade), 1.0)
			deco.draw_line(Vector2(8 + off, h - 8), Vector2(8, h - 8 - off), Color(cor.r, cor.g, cor.b, 0.28 * intensidade), 1.0)
			deco.draw_line(Vector2(w - 8 - off, h - 8), Vector2(w - 8, h - 8 - off), Color(cor.r, cor.g, cor.b, 0.28 * intensidade), 1.0)
	)
	p.add_child(deco)


func _inv_titulo_secao(parent: Node, txt: String, x: float, y: float, w: float, cor: Color, track_nodes = null) -> Label:
	var line_l := ColorRect.new()
	line_l.color = Color(cor.r, cor.g, cor.b, 0.28)
	line_l.position = Vector2(x + 8.0, y + 9.0)
	line_l.size = Vector2(maxf(8.0, w * 0.20), 1.0)
	line_l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(line_l)
	var line_r := ColorRect.new()
	line_r.color = Color(cor.r, cor.g, cor.b, 0.28)
	line_r.position = Vector2(x + w - maxf(8.0, w * 0.20) - 8.0, y + 9.0)
	line_r.size = Vector2(maxf(8.0, w * 0.20), 1.0)
	line_r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(line_r)
	var label := _inv_lbl(parent, txt, x, y, w, 18, 11, Color(cor.r + 0.12, cor.g + 0.12, cor.b + 0.12, 0.86), HORIZONTAL_ALIGNMENT_CENTER)
	if track_nodes is Array:
		track_nodes.append(line_l)
		track_nodes.append(line_r)
		track_nodes.append(label)
	return label


func _abrir_inventario(ui: CanvasLayer) -> void:
	if _menu_contents:
		_menu_contents.hide()
	Salvar.normalizar_cons_equipados()
	if _inventario_overlay and is_instance_valid(_inventario_overlay):
		_inventario_overlay.queue_free()

	var _mob : bool = OS.has_feature("android") or OS.has_feature("ios")
	var vp  := get_viewport().get_visible_rect().size
	var ov  := ColorRect.new()
	ov.color = Color(0.0, 0.0, 0.0, 0.97); ov.size = vp
	ui.add_child(ov)
	_inventario_overlay = ov
	var _cmd_meta_top := _comandante_meta(str(Salvar.pet_ativo))
	var _cmd_cor_top : Color = _cmd_meta_top["cor"] as Color
	_inv_fundo_comando(ov, vp, _cmd_cor_top)
	_ui_panel_frame(ov, Rect2(8.0, 8.0, vp.x - 16.0, minf(vp.y - 16.0, 704.0)), Color(0.42, 0.70, 0.95), 0.82)

	var _fechar_inventario := func() -> void:
		var _cmd_mudou := _menu_comandante_atual != _comandante_home_visual_pid()
		_inventario_arsenal_aberto = false
		_inventario_filtro_atual = "tudo"
		ov.queue_free()
		if _inventario_overlay == ov:
			_inventario_overlay = null
		if _cmd_mudou:
			get_tree().change_scene_to_file("res://scenes/Menu.tscn")
			return
		if _menu_contents:
			_menu_contents.show()

	_ui_header_title(ov, "INVENT\u00c1RIO", 20.0, vp.x, _cmd_cor_top)
	_add_currency_status(ov, Vector2(maxf(14.0, vp.x - 252.0), 18.0), true, 90)

	var m       := Salvar.melhorias
	var t_dano  : float = 35.0 + (m.get("forca",       0) as int) * 8.0
	var t_hp    : float = 170.0 + (m.get("resistencia",0) as int) * 40.0
	var t_cad   : float = 1.2  + (m.get("cadencia",   0) as int) * 0.2
	var t_range : float = 220.0 + (m.get("visao",      0) as int) * 25.0
	var t_regen : float = 0.0; var t_reduc : float = 0.0
	var t_multi : bool  = false
	if Salvar.talento_ativo("p1"): t_dano  += 30.0
	if Salvar.talento_ativo("p2"): t_cad   += 0.5
	if Salvar.talento_ativo("p3"): t_multi  = true
	if Salvar.talento_ativo("p4"): t_dano  += 80.0
	if Salvar.talento_ativo("r1"): t_reduc  = 25.0
	if Salvar.talento_ativo("r2"): t_regen += 4.0
	if Salvar.talento_ativo("r4"): t_hp    += 100.0
	if Salvar.talento_ativo("colosso"): t_dano += 50.0; t_hp += 50.0; t_cad += 0.3
	if Salvar.talento_ativo("tita"): t_dano += 150.0; t_hp += 200.0
	if Salvar.talento_ativo("sobrev"): t_regen += 1.0
	if Salvar.talento_ativo("genoci"):
		var kills_acima_stats : int = max(0, Salvar.total_mobs_mortos - 10000) / 1000
		t_dano += float(kills_acima_stats) * 2.0
	var skin_i    : Dictionary = Salvar.SKINS_INFO.get(Salvar.skin_ativa, {}) as Dictionary
	var skin_cor  : Color      = skin_i.get("cor",  Color(1.0, 0.82, 0.0)) as Color
	var skin_nome : String     = skin_i.get("nome", "Padr\u00e3o") as String
	var skn_tipo  : String     = skin_i.get("bonus_tipo", "") as String
	var skn_val   : float      = skin_i.get("bonus_val",  0.0) as float
	var t_ouro_bonus : float = 0.0
	match skn_tipo:
		"dano":     t_dano  *= (1.0 + skn_val)
		"alcance":  t_range *= (1.0 + skn_val)
		"cadencia": t_cad   *= (1.0 + skn_val)
		"ouro":     t_ouro_bonus += skn_val
		"premium_dano_alc": t_dano *= (1.0 + skn_val); t_range *= (1.0 + skn_val)
		"premium_cad_score": t_cad *= (1.0 + skn_val)
		"beta":     t_dano *= (1.0+skn_val); t_cad *= (1.0+skn_val); t_range *= (1.0+skn_val); t_regen += 1.0
	var equip_bonus : Dictionary = Salvar.equipamentos_bonus_stats()
	t_dano *= float(equip_bonus.get("dano_mult", 1.0))
	t_cad *= float(equip_bonus.get("cadencia_mult", 1.0))
	t_range *= float(equip_bonus.get("alcance_mult", 1.0))
	t_hp *= float(equip_bonus.get("vida_mult", 1.0))
	t_regen += float(equip_bonus.get("regen_flat", 0.0))
	t_reduc = clampf((t_reduc / 100.0) + float(equip_bonus.get("reducao_dano", 0.0)), 0.0, 0.75) * 100.0
	t_ouro_bonus += float(equip_bonus.get("ouro_mult", 0.0))
	var asc_bonus_preview : Dictionary = Salvar.bonus_ascensao_stats()
	t_dano *= float(asc_bonus_preview.get("dano_mult", 1.0))
	t_hp *= float(asc_bonus_preview.get("vida_mult", 1.0))
	t_cad *= float(asc_bonus_preview.get("cadencia_mult", 1.0))
	t_ouro_bonus += float(asc_bonus_preview.get("ouro_mult", 0.0))

	var SX  : float = 30.0  if _mob else 12.0
	var SW  : float = (220.0 * vp.x / 1244.0) if _mob else 220.0
	var MX  : float = SX + SW + 8.0
	var RX  : float = round(723.0 * vp.x / 1244.0) if _mob else 744.0
	var   RW  : float = vp.x - RX - 8.0
	var TY  : float = 92.0  if _mob else 86.0
	var SKW : float = (265.0 * vp.x / 1244.0) if _mob else 265.0
	var SQS : float = (RX - MX - SKW - 8.0) if _mob else 210.0
	const SKH : float = 404.0
	const ASH : float = 200.0
	const HW  : float = 106.0
	const HH  : float = 92.0
	const HGAP: float = 8.0

	var sp_h : float = 660.0 if _mob else 574.0
	var sp := _inv_painel(ov, SX, TY, SW, sp_h,
		Color(0.018,0.025,0.040,0.96), Color(0.24,0.48,0.72,0.45), 1)
	_inv_decorar_painel(sp, Color(0.30,0.65,1.0), 0.75)
	_inv_titulo_secao(ov, "ESTAT\u00cdSTICAS", SX, TY-20, SW, Color(0.42,0.72,1.0))

	var stats : Array = [
		["Dano",         "%.0f"    % t_dano,  Color(1.0,0.22,0.18), "dano"],
		["Vida m\u00e1xima",  "%.0f HP"  % t_hp,   Color(0.2,1.0,0.58), "vida"],
		["Cad\u00eancia",     "%.2f /s"  % t_cad,  Color(0.82,0.22,1.0), "cadencia"],
		["Alcance",      "%.0f px"  % t_range, Color(0.12,0.72,1.0), "alcance"],
	]
	if t_regen  > 0.0: stats.append(["Regenera\u00e7\u00e3o","%.0f HP/s" % t_regen, Color(0.3,1.0,0.55), "regen"])
	if t_reduc  > 0.0: stats.append(["Red. dano","%.0f%%" % t_reduc,  Color(0.2,0.6,1.0), "reduc"])
	if t_multi:        stats.append(["Tiro m\u00faltiplo","Ativo",   Color(0.12,1.0,0.88), "multi"])
	if Salvar.ascensoes > 0:
		stats.append(["Ascensao", "Nv.%d" % Salvar.ascensoes, Color(1.0,0.78,0.18), "fortuna"])
	var _pet_ativo_stats : bool = Salvar.pet_ativo_jogavel()
	if _pet_ativo_stats:
		var _pis : Dictionary = Salvar.PETS_INFO.get(Salvar.pet_ativo, {}) as Dictionary
		var _pns : String = str(_pis.get("nome","Comandante")) if not _pis.is_empty() else "Comandante"
		var _pcs : Color = _pis.get("cor",Color(0.25,0.75,1.0)) as Color if not _pis.is_empty() else Color(0.25,0.75,1.0)
		stats.append(["Comandante", _pns, _pcs, "comandante"])
		var _pstats_resumo : Dictionary = Salvar.pet_stats(Salvar.pet_ativo)
		var _pcd_atq : float = float(_pstats_resumo.get("cd_ataque", 1.8))
		stats.append(["Cmd dano", "%.0f" % float(_pstats_resumo.get("dano", 0.0)), _pcs, "dano"])
		stats.append(["Cmd cad.", "%.2f /s" % (1.0 / maxf(_pcd_atq, 0.05)), _pcs, "cadencia"])
		stats.append(["Cmd alcance", "%.0f px" % float(_pstats_resumo.get("alcance", 0.0)), _pcs, "alcance"])
		stats.append(["Cmd hab.", "CD %.0fs" % float(_pstats_resumo.get("hab_cd", 0.0)), _pcs, "comandante"])
	var _ars_cor := Color(1.0, 0.78, 0.16)
	var _ars_dano_pct : float = (float(equip_bonus.get("dano_mult", 1.0)) - 1.0) * 100.0
	var _ars_cad_pct : float = (float(equip_bonus.get("cadencia_mult", 1.0)) - 1.0) * 100.0
	var _ars_alc_pct : float = (float(equip_bonus.get("alcance_mult", 1.0)) - 1.0) * 100.0
	var _ars_vida_pct : float = (float(equip_bonus.get("vida_mult", 1.0)) - 1.0) * 100.0
	var _ars_regen : float = float(equip_bonus.get("regen_flat", 0.0))
	var _ars_red_pct : float = float(equip_bonus.get("reducao_dano", 0.0)) * 100.0
	if _ars_dano_pct > 0.1: stats.append(["Arsenal dano", "+%.0f%%" % _ars_dano_pct, _ars_cor, "dano"])
	if _ars_cad_pct > 0.1: stats.append(["Arsenal cad.", "+%.0f%%" % _ars_cad_pct, _ars_cor, "cadencia"])
	if _ars_alc_pct > 0.1: stats.append(["Arsenal alcance", "+%.0f%%" % _ars_alc_pct, _ars_cor, "alcance"])
	if _ars_vida_pct > 0.1: stats.append(["Arsenal vida", "+%.0f%%" % _ars_vida_pct, _ars_cor, "vida"])
	if _ars_regen > 0.0: stats.append(["Arsenal regen", "+%.0f HP/s" % _ars_regen, _ars_cor, "regen"])
	if _ars_red_pct > 0.1: stats.append(["Arsenal red.", "+%.0f%%" % _ars_red_pct, _ars_cor, "reduc"])
	if float(equip_bonus.get("cooldown_mult", 0.0)) < -0.001:
		stats.append(["Arsenal CD", "%.0f%%" % (float(equip_bonus.get("cooldown_mult", 0.0)) * 100.0), _ars_cor, "comandante"])
	if float(equip_bonus.get("boss_dano_mult", 0.0)) > 0.001:
		stats.append(["Boss dano", "+%.0f%%" % (float(equip_bonus.get("boss_dano_mult", 0.0)) * 100.0), _ars_cor, "dano"])
	if float(equip_bonus.get("pet_poder_mult", 0.0)) > 0.001:
		stats.append(["Poder cmd", "+%.0f%%" % (float(equip_bonus.get("pet_poder_mult", 0.0)) * 100.0), _ars_cor, "comandante"])
	if float(equip_bonus.get("bloqueio_chance", 0.0)) > 0.001:
		stats.append(["Bloqueio", "+%.0f%%" % (float(equip_bonus.get("bloqueio_chance", 0.0)) * 100.0), _ars_cor, "reduc"])
	if float(equip_bonus.get("efeito_mult", 0.0)) > 0.001:
		stats.append(["Efeitos", "+%.0f%%" % (float(equip_bonus.get("efeito_mult", 0.0)) * 100.0), _ars_cor, "comandante"])
	if float(equip_bonus.get("repetir_assistente", 0.0)) > 0.001:
		stats.append(["Repetir cmd", "+%.0f%%" % (float(equip_bonus.get("repetir_assistente", 0.0)) * 100.0), _ars_cor, "comandante"])
	if equip_bonus.get("boss_escudo", false) == true:
		stats.append(["Escudo boss", "Ativo", _ars_cor, "reduc"])
	if equip_bonus.get("barreira_hp_baixo", false) == true:
		stats.append(["Barreira HP", "Ativo", _ars_cor, "reduc"])
	var sc_b : float = skin_i.get("score_mult",0.0) as float
	if sc_b > 0.0: stats.append(["Score b\u00f4nus","+%.0f%%" % (sc_b*100.0), skin_cor, "fortuna"])
	if t_ouro_bonus > 0.0: stats.append(["Ouro bônus","+%.0f%%" % (t_ouro_bonus*100.0), skin_cor, "fortuna"])
	if skn_val > 0.0 and skn_tipo != "ouro" and skn_tipo != "":
		var skn_label : String = {"dano":"Skin dano","alcance":"Skin alc.","cadencia":"Skin cad.","beta":"Skin beta"}.get(skn_tipo,"Skin")
		stats.append([skn_label, "+%.0f%%" % (skn_val*100.0), skin_cor, "comandante"])

	for _lk in Salvar.LOJA_INFO.keys():
		var _lv : int = Salvar.melhorias.get(_lk, 0) as int
		if _lv > 0:
			var _li : Dictionary = Salvar.LOJA_INFO[_lk] as Dictionary
			var _ln : String = str(_li.get("nome",""))
			var _lc : Color  = _li.get("cor", Color(0.7,0.7,0.7)) as Color
			var _kind : String = str({"forca":"dano", "resistencia":"vida", "visao":"alcance", "cadencia":"cadencia", "fortuna":"fortuna"}.get(str(_lk), "comandante"))
			stats.append([_ln, "Nv.%d / 3" % _lv, _lc, _kind])
	var stats_scroll := ScrollContainer.new()
	stats_scroll.position = Vector2(0, 6)
	stats_scroll.size = Vector2(SW, sp_h - 12.0)
	stats_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	stats_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	stats_scroll.clip_contents = true
	sp.add_child(stats_scroll)
	var stats_content := Control.new()
	stats_content.size = Vector2(SW, sp_h - 12.0)
	stats_content.custom_minimum_size = Vector2(SW, sp_h - 12.0)
	stats_scroll.add_child(stats_content)
	var sy2 : float = 4.0
	for si in range(stats.size()):
		var st  : Array = stats[si] as Array
		var sc2 : Color = st[2] as Color
		var skind : String = str(st[3]) if st.size() > 3 else "comandante"
		if si > 0:
			var sep2 := ColorRect.new(); sep2.color=Color(0.22,0.34,0.48,0.26)
			sep2.position=Vector2(12,sy2-1); sep2.size=Vector2(SW-24,1)
			sep2.mouse_filter=Control.MOUSE_FILTER_IGNORE; stats_content.add_child(sep2)
		_ui_stat_icon(stats_content, skind, sc2, (2.0 if _mob else 9.0), sy2 + (5.0 if _mob else 4.0), 26.0)
		_inv_lbl(stats_content, st[0] as String, (32 if _mob else 42), sy2+2, (int(SW*0.62) if _mob else SW-112), 28, 14, Color(0.76,0.84,0.92,0.90))
		_inv_lbl(stats_content, st[1] as String, (int(SW*0.68) if _mob else SW-72), sy2+2, (SW-int(SW*0.68) if _mob else 64), 28, 14,
			Color(sc2.r+0.15,sc2.g+0.15,sc2.b+0.15), HORIZONTAL_ALIGNMENT_RIGHT)
		sy2 += (42.0 if _mob else 36.0)
	stats_content.size = Vector2(SW, maxf(sp_h - 12.0, sy2 + 8.0))
	stats_content.custom_minimum_size = stats_content.size

	var upd_wrap : Array = [null]
	var _normal_center_nodes : Array = []
	var _arsenal_mode : Array = [_inventario_arsenal_aberto]

	var skp := _inv_painel(ov, MX, TY, SKW, SKH,
		Color(skin_cor.r*0.09,skin_cor.g*0.09,skin_cor.b*0.09,0.95),
		Color(skin_cor.r,skin_cor.g,skin_cor.b,0.86), 2)
	_inv_decorar_painel(skp, skin_cor, 1.0)
	_normal_center_nodes.append(skp)
	_inv_titulo_secao(ov, "SKIN EQUIPADA", MX, TY-20, SKW, skin_cor, _normal_center_nodes)
	var td := Control.new(); td.size=Vector2(SKW,SKH); td.mouse_filter=Control.MOUSE_FILTER_IGNORE
	var tc := skin_cor; var sk_nome_cap := skin_nome; var sk_sid_cap := Salvar.skin_ativa
	td.draw.connect(func():
		var t := Time.get_ticks_msec() * 0.001
		var tcx:=SKW*0.5; var tcy:=SKH*0.5-20.0+sin(t*1.1)*5.0
		if sk_sid_cap=="saberpunk":
			var rs:=52.0; var sp_vio:=Color(0.62,0.0,1.0)
			var pts_s:=PackedVector2Array()
			for hi_s in range(6):
				var a_s:=float(hi_s)*TAU/6.0+PI/6.0+t*0.15; pts_s.append(Vector2(tcx+cos(a_s)*rs,tcy+sin(a_s)*rs))
			var brd_s:=PackedVector2Array(pts_s); brd_s.append(pts_s[0])
			var pa_s := 0.72+sin(t*2.2)*0.28
			for bi_s in range(2,0,-1): td.draw_polyline(brd_s,Color(tc.r,tc.g,tc.b,0.15/float(bi_s)),float(bi_s)*3.5)
			td.draw_polyline(brd_s,Color(tc.r+0.1,tc.g+0.05,tc.b,pa_s),2.5)
			for vi in range(6):
				var vc:=sp_vio if (vi%2==0) else Color(tc.r+0.1,tc.g+0.1,tc.b+0.1)
				td.draw_circle(pts_s[vi],5.5,Color(vc.r,vc.g,vc.b,pa_s))
			var ring_r := rs*0.46+sin(t*1.5)*2.0
			td.draw_arc(Vector2(tcx,tcy),ring_r,0.0,TAU,48,Color(sp_vio.r,sp_vio.g,sp_vio.b,0.65+sin(t*1.8)*0.25),2.2,true)
			for pi3 in range(3):
				var oa:=t*1.8+float(pi3)*TAU/3.0; var or3:=rs*1.1
				var pc3:=sp_vio if (pi3%2==0) else Color(tc.r+0.1,tc.g+0.1,tc.b+0.1)
				td.draw_circle(Vector2(tcx+cos(oa-0.45)*or3,tcy+sin(oa-0.45)*or3),3.0,Color(sp_vio.r,sp_vio.g,sp_vio.b,0.28))
				td.draw_circle(Vector2(tcx+cos(oa)*or3,tcy+sin(oa)*or3),5.0,Color(pc3.r,pc3.g,pc3.b,0.92))
			var ang_s:=-PI*0.38+sin(t*0.65)*0.12; var cdir_s:=Vector2(cos(ang_s),sin(ang_s))
			var clat_s:=cdir_s.rotated(PI/2.0)*7.0; var base_s:=Vector2(tcx,tcy); var tip_s:=base_s+cdir_s*58.0
			var gun_s:=PackedVector2Array([base_s-clat_s*0.4,base_s+clat_s*0.4,tip_s+clat_s*0.2,tip_s-clat_s*0.2])
			var gf_s:=PackedColorArray(); for _g_s in range(4): gf_s.append(Color(sp_vio.r,sp_vio.g,sp_vio.b,0.95))
			td.draw_polygon(gun_s,gf_s)
			td.draw_circle(tip_s,8.0,Color(1.0,1.0,1.0,0.65+sin(t*3.5)*0.35))
		else:
			var r:=48.0
			for gi in range(4,0,-1): td.draw_circle(Vector2(tcx,tcy),r+float(gi)*10.0,Color(tc.r,tc.g,tc.b,0.04/float(gi)))
			var pts:=PackedVector2Array()
			for hi in range(6):
				var a:=float(hi)*TAU/6.0+PI/6.0+t*0.18; pts.append(Vector2(tcx+cos(a)*r,tcy+sin(a)*r))
			var fills:=PackedColorArray(); for _f in range(6): fills.append(Color(tc.r*0.15,tc.g*0.15,tc.b*0.15,0.97))
			td.draw_polygon(pts,fills)
			var brd:=PackedVector2Array(pts); brd.append(pts[0])
			for bi in range(3,0,-1): td.draw_polyline(brd,Color(tc.r,tc.g,tc.b,0.12/float(bi)),float(bi)*3.0)
			var pa := 0.78+sin(t*2.2)*0.22
			td.draw_polyline(brd,Color(tc.r+0.2,tc.g+0.18,tc.b,pa),2.2)
			td.draw_circle(Vector2(tcx,tcy),12.0,Color(tc.r+0.2,tc.g+0.2,tc.b,pa))
			var ang:=-PI*0.38+sin(t*0.65)*0.12; var cdir:=Vector2(cos(ang),sin(ang))
			var clat:=cdir.rotated(PI/2.0)*7.0; var base:=Vector2(tcx,tcy); var tip:=base+cdir*58.0
			var gun:=PackedVector2Array([base-clat*0.4,base+clat*0.4,tip+clat*0.2,tip-clat*0.2])
			var gf:=PackedColorArray(); for _g in range(4): gf.append(Color(tc.r,tc.g,tc.b,0.95))
			td.draw_polygon(gun,gf)
			td.draw_circle(tip,8.0,Color(1.0,1.0,1.0,0.65+sin(t*3.5)*0.35))
		td.draw_string(ThemeDB.fallback_font,Vector2(0,SKH-42),
			sk_nome_cap,HORIZONTAL_ALIGNMENT_CENTER,SKW,18,Color(tc.r+0.2,tc.g+0.2,tc.b+0.2,0.95))
		td.draw_string(ThemeDB.fallback_font,Vector2(0,SKH-22),
			"TORRE ATIVA",HORIZONTAL_ALIGNMENT_CENTER,SKW,11,Color(0.55,0.65,0.65,0.6))
	)
	skp.add_child(td)
	var _skp_btn := Button.new(); _skp_btn.position=Vector2(0,0); _skp_btn.size=Vector2(SKW,SKH)
	_skp_btn.focus_mode=Control.FOCUS_NONE; _skp_btn.mouse_default_cursor_shape=Control.CURSOR_POINTING_HAND
	var _skp_es:=StyleBoxEmpty.new()
	for _se in ["normal","hover","pressed","focus"]: _skp_btn.add_theme_stylebox_override(_se,_skp_es)
	var _skin_det := {"tipo":"skin","sid":Salvar.skin_ativa,"nome":skin_nome,"cor":skin_cor,
		"desc":skin_i.get("desc","") as String,"ativo":true}
	_skp_btn.pressed.connect(func(): if upd_wrap[0]: upd_wrap[0].call(_skin_det))
	skp.add_child(_skp_btn)

	var pet_tem : bool = Salvar.pet_ativo_jogavel()
	var _pinfo_asp : Dictionary = Salvar.PETS_INFO.get(Salvar.pet_ativo, {}) as Dictionary
	if _pinfo_asp.is_empty() and pet_tem:
		_pinfo_asp = Salvar.PETS_INFO.get("cyron", {}) as Dictionary
	var pc : Color = _pinfo_asp.get("cor", Color(0.25,0.75,1.0)) as Color if pet_tem else Color(0.25,0.75,1.0)
	var _cmd_meta := _comandante_meta(str(Salvar.pet_ativo))
	var _cmd_titulo : String = str(_cmd_meta.get("titulo", "COMANDANTE"))
	var _cmd_coligacao : String = str(_cmd_meta.get("coligacao", "COLIGAÇÃO ÁUREA"))
	var _cmd_lema : String = str(_cmd_meta.get("lema", "POR HONRA. POR DEVER. POR EQUILIBRIO."))
	var _cmd_titulo_curto : String = _cmd_titulo.replace("COMANDANTE DE ", "").replace("COMANDANTE ", "")
	var _cmd_coligacao_curta : String = _cmd_coligacao.replace("COLIGAÇÃO ", "")
	var _cmd_cor : Color = _cmd_meta.get("cor", pc) as Color
	var _cmd_escura : Color = _cmd_meta.get("escura", Color(pc.r*0.12, pc.g*0.12, pc.b*0.12)) as Color
	var asp := Control.new()
	asp.size = Vector2(SQS, ASH)
	asp.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var _asp_title := Label.new()
	_asp_title.visible = false
	var pad := Control.new(); pad.size=Vector2(SQS,ASH); pad.mouse_filter=Control.MOUSE_FILTER_IGNORE
	var pcc := pc; var pt := not pet_tem
	var _pnome_asp := str(_pinfo_asp.get("nome", "Comandante")) if pet_tem else ""
	var _ppid_asp  := str(Salvar.pet_ativo)
	var _psprite_asp := _item_sprite_key("pet", _pnome_asp, _ppid_asp)
	pad.draw.connect(func():
		var t := Time.get_ticks_msec() * 0.001
		var pcx:=SQS*0.5; var pcy:=ASH*0.43+sin(t*1.2)*3.0; var s:=2.5; var am:=1.0 if not pt else 0.25
		var ac := pcc if not pt else Color(0.25,0.45,0.65)
		var bv := Color(ac.r,ac.g,ac.b,am)
		if not pt:
			var _asp_nivel : int = Salvar.pet_nivel(_ppid_asp)
			pad.draw_rect(Rect2(10, 8, SQS - 20.0, ASH - 16.0), Color(0.0, 0.0, 0.0, 0.20), false, 1.0)
			for _gl in range(3):
				pad.draw_line(Vector2(16, 22.0 + float(_gl) * 18.0), Vector2(SQS - 16.0, 14.0 + float(_gl) * 18.0), Color(_cmd_cor.r, _cmd_cor.g, _cmd_cor.b, 0.06), 1.0)
			pad.draw_circle(Vector2(pcx, pcy + 2.0), 58.0, Color(_cmd_cor.r, _cmd_cor.g, _cmd_cor.b, 0.055))
			if _psprite_asp != "":
				_draw_item_sprite(pad, _psprite_asp, Rect2(pcx - 54.0, pcy - 66.0, 108.0, 132.0), am)
			else:
				match _ppid_asp:
					"nexus":
						var pts2:=PackedVector2Array()
						for i2 in 8: var a2:=float(i2)*TAU/8.0+PI/8.0+t*0.5; pts2.append(Vector2(pcx+cos(a2)*s*14.0,pcy+sin(a2)*s*14.0))
						var fills2:=PackedColorArray(); for _f2 in 8: fills2.append(Color(0.18,0.09,0.03,0.95*am))
						pad.draw_polygon(pts2,fills2)
						var brd2:=PackedVector2Array(pts2); brd2.append(pts2[0])
						pad.draw_polyline(brd2,Color(ac.r,ac.g,ac.b,am),2.5)
						pad.draw_circle(Vector2(pcx,pcy),s*4.5+sin(t*3.0)*s*1.2,Color(ac.r,ac.g,ac.b,0.85*am))
						pad.draw_circle(Vector2(pcx,pcy),s*2.0,Color(1.0,0.9,0.7,0.95*am))
					"phantom":
						var dp:=PackedVector2Array([Vector2(pcx,pcy-s*14),Vector2(pcx+s*11,pcy),Vector2(pcx,pcy+s*11),Vector2(pcx-s*11,pcy)])
						var fa2:=0.55+sin(t*2.5)*0.2
						var dfills:=PackedColorArray(); for _f3 in 4: dfills.append(Color(0.12,0.04,0.2,fa2*am))
						pad.draw_polygon(dp,dfills)
						var dbrd:=PackedVector2Array(dp); dbrd.append(dp[0])
						pad.draw_polyline(dbrd,Color(ac.r,ac.g,ac.b,am),2.5)
						pad.draw_circle(Vector2(pcx,pcy),s*3.5,Color(0,0,0,0.9*am))
						pad.draw_circle(Vector2(pcx,pcy),s*2.0,Color(ac.r,ac.g,ac.b,0.95*am))
						pad.draw_arc(Vector2(pcx,pcy),s*15.0,0.0,TAU,32,Color(ac.r,ac.g,ac.b,0.12+sin(t*2.0)*0.06),1.6)
					_:
						pad.draw_rect(Rect2(pcx-8*s,pcy-7*s,16*s,14*s),Color(0.06,0.12,0.24,0.96*am))
						pad.draw_line(Vector2(pcx-8*s,pcy-7*s),Vector2(pcx+8*s,pcy-7*s),bv,2.5)
						pad.draw_line(Vector2(pcx+8*s,pcy-7*s),Vector2(pcx+8*s,pcy+7*s),bv,2.5)
						pad.draw_line(Vector2(pcx+8*s,pcy+7*s),Vector2(pcx-8*s,pcy+7*s),bv,2.5)
						pad.draw_line(Vector2(pcx-8*s,pcy+7*s),Vector2(pcx-8*s,pcy-7*s),bv,2.5)
						var scan := fmod(t*22.0, 14.0*s)
						pad.draw_line(Vector2(pcx-8*s+2,pcy-7*s+scan),Vector2(pcx+8*s-2,pcy-7*s+scan),Color(ac.r,ac.g,ac.b,0.25*am),1.2)
						pad.draw_line(Vector2(pcx,pcy-7*s),Vector2(pcx,pcy-15*s),Color(0.45,0.85,1.0,0.8*am),2.5)
						var blink := 0.5+sin(t*4.0)*0.5
						pad.draw_circle(Vector2(pcx,pcy-16*s),4.5,Color(ac.r,ac.g,ac.b,clampf(blink,0.1,1.0)*am))
						pad.draw_rect(Rect2(pcx-5*s,pcy-5*s,10*s,7*s),Color(0,0.06,0.16,0.96*am))
						pad.draw_circle(Vector2(pcx,pcy-1.5*s),2.5,Color(ac.r,ac.g,ac.b,am))
						pad.draw_line(Vector2(pcx-4*s,pcy+7*s),Vector2(pcx-5*s,pcy+14*s),Color(0.45,0.85,1.0,0.7*am),3.0)
						pad.draw_line(Vector2(pcx+4*s,pcy+7*s),Vector2(pcx+5*s,pcy+14*s),Color(0.45,0.85,1.0,0.7*am),3.0)
			pad.draw_string(_font_tech,Vector2(0,ASH-58),
				_pnome_asp,HORIZONTAL_ALIGNMENT_CENTER,SQS,13,
				Color(pcc.r+0.25,pcc.g+0.25,pcc.b+0.25,0.9))
			pad.draw_string(_font_tech,Vector2(0,ASH-42),
				_cmd_titulo_curto,HORIZONTAL_ALIGNMENT_CENTER,SQS,8,
				Color(0.78,0.78,0.84,0.82))
			pad.draw_string(_font_tech,Vector2(0,ASH-28),
				_cmd_coligacao_curta,HORIZONTAL_ALIGNMENT_CENTER,SQS,8,
				Color(_cmd_cor.r+0.12,_cmd_cor.g+0.12,_cmd_cor.b+0.12,0.9))
			var _asp_xpi := Salvar.pet_cartas_info(_ppid_asp)
			var _asp_xp_prog : float = float(_asp_xpi.get("prog",0.0))
			var _asp_xp_n : int = int(_asp_xpi.get("nivel",1))
			var _asp_bw : float = SQS*0.7; var _asp_bx : float = (SQS-_asp_bw)*0.5
			pad.draw_rect(Rect2(_asp_bx,ASH-18,_asp_bw,5),Color(0.18,0.18,0.22,0.45))
			if _asp_xp_n < 5:
				pad.draw_rect(Rect2(_asp_bx,ASH-18,_asp_bw*_asp_xp_prog,5),Color(_cmd_cor.r*0.75,_cmd_cor.g*0.75,_cmd_cor.b*0.75,0.9))
			var _lv_str2 : String = "Nv.%d"%_asp_xp_n if _asp_xp_n<5 else "MÁX."
			pad.draw_string(_font_tech,Vector2(0,ASH-5),_lv_str2,HORIZONTAL_ALIGNMENT_CENTER,SQS,10,Color(_cmd_cor.r+0.2,_cmd_cor.g+0.2,_cmd_cor.b+0.2,0.9))
		else:
			pad.draw_string(ThemeDB.fallback_font,Vector2(0,ASH*0.5-8),
				"N\u00e3o adquirido",HORIZONTAL_ALIGNMENT_CENTER,SQS,14,Color(0.38,0.38,0.42))
	)
	asp.add_child(pad)
	var _anim_nodes : Array = [td]
	var _anim_t := Timer.new(); _anim_t.wait_time=0.033; _anim_t.autostart=true
	_anim_t.timeout.connect(func():
		for _an in _anim_nodes:
			if is_instance_valid(_an): _an.queue_redraw())
	ov.add_child(_anim_t)
	if pet_tem:
		var _pdesc_asp := str(_pinfo_asp.get("desc","")) if not _pinfo_asp.is_empty() else "Comandante da torre.\nHacker Sistêmico: 2x cadência por 15s."
		var _asp_btn := Button.new(); _asp_btn.position=Vector2(0,0); _asp_btn.size=Vector2(SQS,ASH)
		_asp_btn.focus_mode=Control.FOCUS_NONE; _asp_btn.mouse_default_cursor_shape=Control.CURSOR_POINTING_HAND
		var _asp_es:=StyleBoxEmpty.new()
		for _ae in ["normal","hover","pressed","focus"]: _asp_btn.add_theme_stylebox_override(_ae,_asp_es)
		var _apc:=pc; var _apn:=_pnome_asp; var _apd:=_pdesc_asp
		_asp_btn.pressed.connect(func(): if upd_wrap[0]: upd_wrap[0].call({"tipo":"pet",
			"nome":_apn,"cor":_apc,"ativo":true,"desc":_apd,"pid":_ppid_asp}))
		asp.add_child(_asp_btn)

	var hx0 : float = MX + SKW + 8.0
	var hab_ids : Array = Salvar.HABIL_INFO.keys()
	var hab_slot_ids : Array = []
	for hid_slot in hab_ids:
		if int(Salvar.habil_cargas.get(hid_slot, 0)) > 0:
			hab_slot_ids.append(hid_slot)
	var hab_visible_slots : int = clampi(maxi(3, hab_ids.size()), 3, 4)
	var HAB_W : float = SQS
	var HAB_GAP : float = 8.0
	var HAB_H : float = (SKH - float(hab_visible_slots - 1) * HAB_GAP) / float(hab_visible_slots)
	for hi in range(hab_visible_slots):
		var hpx : float = hx0
		var hpy : float = TY + float(hi)*(HAB_H+HAB_GAP)
		if hi < hab_slot_ids.size():
			var hid   : String = hab_slot_ids[hi] as String
			var hinfo : Dictionary = Salvar.HABIL_INFO[hid] as Dictionary
			var hcor  : Color  = hinfo["cor"] as Color
			var hnome : String = hinfo["nome"] as String
			var cargas: int    = Salvar.habil_cargas.get(hid, 0) as int
			var htm   : bool   = cargas > 0
			var hp2 := _inv_painel(ov, hpx, hpy, HAB_W, HAB_H,
				Color(hcor.r*0.14,hcor.g*0.14,hcor.b*0.14,0.96) if htm else Color(0.04,0.05,0.08,0.94),
				Color(hcor.r,hcor.g,hcor.b,0.75 if htm else 0.2), 2 if htm else 1)
			_normal_center_nodes.append(hp2)
			var hisd := Control.new(); hisd.size=Vector2(HAB_W,HAB_H)
			hisd.mouse_filter=Control.MOUSE_FILTER_IGNORE
			var hcc := hcor; var hhtm := htm; var hcg := cargas
			var hsprite := _item_sprite_key("hab", hnome, hid)
			if not _usar_sprite_key_na_mochila(hsprite):
				hsprite = ""
			hisd.draw.connect(func():
				var hcx:=HAB_W*0.5; var hcy:=HAB_H*0.40
				hisd.draw_circle(Vector2(hcx,hcy),20.0,Color(hcc.r*0.22,hcc.g*0.22,hcc.b*0.22,0.9))
				if hsprite != "":
					_draw_item_sprite(hisd, hsprite, Rect2(hcx - 27.0, hcy - 27.0, 54.0, 54.0), 1.0 if hhtm else 0.35)
				else:
					hisd.draw_arc(Vector2(hcx,hcy),18.0,0.0,TAU,48,
						Color(hcc.r,hcc.g,hcc.b,0.88 if hhtm else 0.22),2.5,true)
					hisd.draw_circle(Vector2(hcx,hcy),7.0,
						Color(hcc.r+0.2,hcc.g+0.2,hcc.b+0.2,0.95 if hhtm else 0.3))
				for pi2 in range(3):
					var ppx:=hcx-10.0+float(pi2)*10.0
					hisd.draw_circle(Vector2(ppx,float(HAB_H)-12.0),3.5,
						Color(hcc.r,hcc.g,hcc.b,0.9) if pi2<hcg else Color(0.12,0.14,0.18))
			)
			hp2.add_child(hisd)
			var _hbtn := Button.new(); _hbtn.position=Vector2(0,0); _hbtn.size=Vector2(HAB_W,HAB_H)
			_hbtn.focus_mode=Control.FOCUS_NONE; _hbtn.mouse_default_cursor_shape=Control.CURSOR_POINTING_HAND
			var _hes:=StyleBoxEmpty.new()
			for _he in ["normal","hover","pressed","focus"]: _hbtn.add_theme_stylebox_override(_he,_hes)
			var _hdet := {"tipo":"hab","nome":hnome,"cor":hcor,"cargas":cargas,"hid":hid,
				"desc":hinfo.get("desc","") as String,"ativo":htm}
			_hbtn.pressed.connect(func(): if upd_wrap[0]: upd_wrap[0].call(_hdet))
			hp2.add_child(_hbtn)
			var hshort:=hnome.substr(0,12)+("." if hnome.length()>12 else "")
			_inv_lbl(hp2,hshort,0,HAB_H-34,HAB_W,16,11,
				Color(hcor.r+0.2,hcor.g+0.2,hcor.b+0.2,0.9 if htm else 0.4),
				HORIZONTAL_ALIGNMENT_CENTER)
		else:
			var _empty_hp := _inv_painel(ov, hpx, hpy, HAB_W, HAB_H, Color(0.03,0.04,0.06,0.7), Color(0.2,0.2,0.25,0.25), 1)
			_normal_center_nodes.append(_empty_hp)

	var _hlab := _inv_titulo_secao(ov, "HABILIDADES", hx0, TY-20, SQS, Color(0.48,0.78,1.0), _normal_center_nodes)
	_hlab.z_index = 5
	var scroll_y : float = TY + SKH + 32.0
	var scroll_w : float = RX - MX - 10.0
	var SCROLL_H : float = 662.0 - scroll_y
	var scr_p := _inv_painel(ov, MX, scroll_y, scroll_w, SCROLL_H,
		Color(0.018,0.024,0.040,0.95), Color(0.28,0.42,0.60,0.36), 1)
	_inv_decorar_painel(scr_p, Color(0.34,0.62,0.86), 0.45)
	scr_p.clip_contents = true
	_normal_center_nodes.append(scr_p)
	var hscr := HScrollBar.new()
	hscr.position=Vector2(0,SCROLL_H-14); hscr.size=Vector2(scroll_w,14); scr_p.add_child(hscr)
	var hcont := Control.new()
	hcont.position=Vector2(6,14); hcont.size=Vector2(scroll_w-12,SCROLL_H-28)
	hcont.mouse_filter=Control.MOUSE_FILTER_PASS; scr_p.add_child(hcont)
	var IW:float=(scroll_w - 28.0) / 3.0; var IH:float=SCROLL_H-36
	var _cons_rebuild_wrap : Array = [null]
	var _rebuild_slots_wrap : Array = [null]
	var _upd_wrap_ref : Array = []  # preenchido apÃ³s upd_wrap ser criado
	# Closure reutilizÃ¡vel â€” rebuild ao equipar/desequipar
	var _build_cons := func():
		for _old in hcont.get_children(): _old.queue_free()
		var _iw2 : float = IW; var _ih2 : float = IH; var _ix2 : float = 0.0
		var _db2 : Dictionary = {
			"revive":  {"nome":"Vela da Alma",    "cor":Color(0.55,1.0,0.35),"est":Salvar.revive_loja_estoque,
						"max":Salvar.REVIVE_LOJA_MAX,"desc":"Restaura 50%% da vida automaticamente ao ser derrotado.","icone":"vela"},
			"orbe":    {"nome":"Orbe de Cura",    "cor":Color(0.2,0.85,0.45),"est":Salvar.orbe_cura_estoque,
						"max":Salvar.ORBE_CURA_MAX,"desc":"Restaura 50%% do HP máximo da torre ao ser usado.","icone":"orbe"},
			"cristal": {"nome":"Cristal Barreira","cor":Color(0.3,0.55,1.0),"est":Salvar.cristal_barreira_estoque,
						"max":Salvar.CRISTAL_BARREIRA_MAX,"desc":"Absorve o próximo golpe fatal, salvando a torre.","icone":"escudo"},
			"runa":    {"nome":"Runa de F\u00faria","cor":Color(1.0,0.45,0.1),"est":Salvar.runa_furia_estoque,
						"max":Salvar.RUNA_FURIA_MAX,"desc":"+80%% de dano por 8s. Ativar manualmente no HUD.","icone":"furia"},
		}
		for _eq_id in Salvar.cons_equipados:
			if not _db2.has(_eq_id): continue
			var _csi2 : Dictionary = _db2[_eq_id] as Dictionary
			var _cc2 : Color = _csi2["cor"] as Color
			var _ce2 : int   = _csi2["est"] as int
			var _cm2 : int   = _csi2["max"] as int
			var _ca2 : bool  = _ce2 > 0
			var _cp3 := _inv_painel(hcont,_ix2,0,_iw2,_ih2,
				Color(_cc2.r*0.10,_cc2.g*0.10,_cc2.b*0.10,0.96) if _ca2 else Color(0.04,0.05,0.08,0.94),
				Color(_cc2.r,_cc2.g,_cc2.b,0.78 if _ca2 else 0.2), 2 if _ca2 else 1)
			var _clb2 := ColorRect.new()
			_clb2.color = Color(_cc2.r,_cc2.g,_cc2.b,0.7 if _ca2 else 0.15)
			_clb2.position = Vector2(0,0); _clb2.size = Vector2(4,_ih2); _cp3.add_child(_clb2)
			var _iso2 : float = minf(44.0, _ih2 * 0.30)
			var _in2 := Control.new()
			_in2.position = Vector2((_iw2-_iso2)*0.5, 5)
			_in2.size = Vector2(_iso2,_iso2); _in2.mouse_filter = Control.MOUSE_FILTER_IGNORE
			_cp3.add_child(_in2)
			var _it2 : String = _csi2["icone"] as String
			var _ic2 : Color = _cc2; var _ia2 : float = 1.0 if _ca2 else 0.3
			var _cons_sprite := _item_sprite_key("cons", str(_csi2["nome"]), str(_eq_id))
			if not _usar_sprite_key_na_mochila(_cons_sprite):
				_cons_sprite = ""
			_in2.draw.connect(func():
				var _hf2 := Vector2(_iso2*0.5,_iso2*0.5); var _r2 := _iso2*0.46
				if _cons_sprite != "" and _draw_item_sprite(_in2, _cons_sprite, Rect2(0.0, 0.0, _iso2, _iso2), _ia2):
					return
				match _it2:
					"vela":
						_in2.draw_circle(_hf2+Vector2(0,_r2*0.55),_r2*0.55,Color(_ic2.r*0.3,_ic2.g*0.3,_ic2.b*0.1,0.4*_ia2))
						var _fl3:=PackedVector2Array([_hf2+Vector2(0,-_r2),_hf2+Vector2(-_r2*0.55,_r2*0.35),_hf2+Vector2(0,0),_hf2+Vector2(_r2*0.55,_r2*0.35)])
						_in2.draw_colored_polygon(_fl3,Color(_ic2.r,_ic2.g*0.7,0.1,0.95*_ia2))
						var _fl4:=PackedVector2Array([_hf2+Vector2(0,-_r2*0.6),_hf2+Vector2(-_r2*0.28,_r2*0.18),_hf2+Vector2(0,-_r2*0.06),_hf2+Vector2(_r2*0.28,_r2*0.18)])
						_in2.draw_colored_polygon(_fl4,Color(1.0,0.95,0.5,0.9*_ia2))
						_in2.draw_rect(Rect2(_hf2+Vector2(-_r2*0.18,_r2*0.58),Vector2(_r2*0.36,_r2*0.65)),Color(_ic2.r*0.4,_ic2.g*0.4,0.1,0.8*_ia2))
					"orbe":
						_in2.draw_circle(_hf2,_r2,Color(_ic2.r*0.15,_ic2.g*0.25,_ic2.b*0.15,0.9*_ia2))
						_in2.draw_arc(_hf2,_r2,0,TAU,48,Color(_ic2.r,_ic2.g,_ic2.b,0.9*_ia2),2.5)
						_in2.draw_line(_hf2+Vector2(0,-_r2*0.6),_hf2+Vector2(0,_r2*0.6),Color(_ic2.r+0.3,_ic2.g+0.2,_ic2.b+0.2,0.95*_ia2),3.0)
						_in2.draw_line(_hf2+Vector2(-_r2*0.6,0),_hf2+Vector2(_r2*0.6,0),Color(_ic2.r+0.3,_ic2.g+0.2,_ic2.b+0.2,0.95*_ia2),3.0)
					"escudo":
						var _pts3:=PackedVector2Array()
						for _s3 in range(6):
							_pts3.append(_hf2+Vector2(cos(_s3*TAU/6.0-PI*0.5),sin(_s3*TAU/6.0-PI*0.5))*_r2)
						_in2.draw_colored_polygon(_pts3,Color(_ic2.r*0.15,_ic2.g*0.2,_ic2.b*0.3,0.9*_ia2))
						_in2.draw_polyline(_pts3+PackedVector2Array([_pts3[0]]),Color(_ic2.r,_ic2.g,_ic2.b,0.9*_ia2),2.5)
						_in2.draw_arc(_hf2,_r2*0.5,0,TAU,32,Color(_ic2.r,_ic2.g,_ic2.b,0.35*_ia2),1.5)
					"furia":
						var _pts4:=PackedVector2Array([_hf2+Vector2(0,-_r2),_hf2+Vector2(_r2*0.72,0),_hf2+Vector2(0,_r2),_hf2+Vector2(-_r2*0.72,0)])
						_in2.draw_colored_polygon(_pts4,Color(_ic2.r*0.25,_ic2.g*0.08,_ic2.b*0.04,0.9*_ia2))
						_in2.draw_polyline(_pts4+PackedVector2Array([_pts4[0]]),Color(_ic2.r,_ic2.g*0.6,_ic2.b*0.2,0.9*_ia2),2.5)
						_in2.draw_line(_hf2+Vector2(-_r2*0.28,-_r2*0.45),_hf2+Vector2(_r2*0.18,0),Color(1.0,0.9,0.3,0.95*_ia2),2.5)
						_in2.draw_line(_hf2+Vector2(_r2*0.18,0),_hf2+Vector2(-_r2*0.14,_r2*0.1),Color(1.0,0.9,0.3,0.95*_ia2),2.5)
						_in2.draw_line(_hf2+Vector2(-_r2*0.14,_r2*0.1),_hf2+Vector2(_r2*0.28,_r2*0.45),Color(1.0,0.9,0.3,0.95*_ia2),2.5)
			)
			var _iyn2 : float = _iso2 + 8.0
			_inv_lbl(_cp3,_csi2["nome"] as String,0,_iyn2,_iw2,15,10,
				Color(_cc2.r+0.2,_cc2.g+0.2,_cc2.b+0.1) if _ca2 else Color(0.38,0.38,0.42),HORIZONTAL_ALIGNMENT_CENTER)
			_inv_lbl(_cp3,"%d/%d" % [_ce2,_cm2],0,_iyn2+16,_iw2,13,10,
				Color(_cc2.r,_cc2.g,_cc2.b,0.75) if _ca2 else Color(0.28,0.28,0.32),HORIZONTAL_ALIGNMENT_CENTER)
			if _ca2:
				var _cbtn2 := Button.new(); _cbtn2.position=Vector2(0,0); _cbtn2.size=Vector2(_iw2,_ih2)
				_cbtn2.focus_mode=Control.FOCUS_NONE; _cbtn2.mouse_default_cursor_shape=Control.CURSOR_POINTING_HAND
				var _cbes2 := StyleBoxEmpty.new()
				for _cbe2 in ["normal","hover","pressed","focus"]: _cbtn2.add_theme_stylebox_override(_cbe2,_cbes2)
				var _cn3 : String = (_csi2["nome"] as String)+" \u00d7%d" % _ce2
				var _cd3 : String = _csi2["desc"] as String
				var _cc3 : Color = _cc2; var _eid3 : String = _eq_id
				_cbtn2.pressed.connect(func():
					if not _upd_wrap_ref.is_empty() and _upd_wrap_ref[0]:
						_upd_wrap_ref[0].call({"tipo":"cons","nome":_cn3,"cor":_cc3,"ativo":true,"cons_id":_eid3,"desc":_cd3}))
				_cp3.add_child(_cbtn2)
			_ix2 += _iw2 + 8.0
		hcont.custom_minimum_size=Vector2(_ix2+4,_ih2)
		hscr.max_value=maxf(0,_ix2+4-(scroll_w-12))
	_cons_rebuild_wrap[0] = _build_cons
	_build_cons.call()
	hscr.min_value=0.0; hscr.page=scroll_w-12
	hscr.value_changed.connect(func(v:float): hcont.position.x=6.0-v)
	var _clab := _inv_lbl(ov, "CONSUM\u00cdVEIS", MX, scroll_y-16, scroll_w, 18, 11,
		Color(0.5,0.65,0.8,0.75))
	_clab.z_index = 5
	_normal_center_nodes.append(_clab)

	var arsenal_panel := Control.new()
	arsenal_panel.position = Vector2(MX, TY - 20.0)
	arsenal_panel.size = Vector2(RX - MX - 10.0, 662.0 - TY + 20.0)
	arsenal_panel.visible = false
	arsenal_panel.mouse_filter = Control.MOUSE_FILTER_PASS
	ov.add_child(arsenal_panel)
	var _aw : float = arsenal_panel.size.x
	var _slot_gap : float = 12.0
	_inv_titulo_secao(arsenal_panel, "COMANDANTE", 0, 0, SKW, _cmd_cor)
	_inv_titulo_secao(arsenal_panel, "ARSENAL DA TORRE", SKW + _slot_gap, 0, _aw - SKW - _slot_gap, Color(0.92,0.92,0.98))
	var _cmd_card := _inv_painel(arsenal_panel, 0.0, 20.0, SKW, SKH,
		Color(0.008, 0.010, 0.016, 0.98),
		Color(_cmd_cor.r, _cmd_cor.g, _cmd_cor.b, 0.84), 2)
	_cmd_card.clip_contents = true
	_inv_decorar_painel(_cmd_card, _cmd_cor, 0.58)
	var _cmd_portrait := Control.new()
	_cmd_portrait.name = "ComandanteSlotArte"
	_cmd_portrait.set_meta("art_fill_mode", "cover_full_slot")
	_cmd_portrait.size = Vector2(SKW, SKH)
	_cmd_portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_cmd_card.add_child(_cmd_portrait)
	var _cmd_sprite := _psprite_asp
	var _cmd_portrait_tex := _comandante_sprite(_ppid_asp)
	var _cmd_nome := _pnome_asp
	var _cmd_pet_tem := pet_tem
	_cmd_portrait.draw.connect(func():
		var t := Time.get_ticks_msec() * 0.001
		_cmd_portrait.draw_rect(Rect2(Vector2.ZERO, Vector2(SKW, SKH)), Color(0.0, 0.0, 0.0, 0.92), true)
		if _cmd_pet_tem and _cmd_portrait_tex != null:
			_draw_comandante_card_art(_cmd_portrait, _cmd_portrait_tex, Rect2(0.0, 0.0, SKW, SKH), _cmd_escura, 0.06 + 0.03 * sin(t * 1.2))
		elif _cmd_pet_tem and _cmd_sprite != "":
			var cc := Vector2(SKW * 0.5, SKH * 0.40)
			for ring in range(4):
				_cmd_portrait.draw_arc(cc, 58.0 + float(ring) * 18.0, -1.9 + sin(t * 0.3) * 0.2, 1.25, 64, Color(_cmd_cor.r, _cmd_cor.g, _cmd_cor.b, 0.050), 1.0, true)
			_draw_item_sprite(_cmd_portrait, _cmd_sprite, Rect2(SKW * 0.5 - 78.0, 46.0, 156.0, 206.0), 1.0)
			_cmd_portrait.draw_line(Vector2(18, SKH - 128.0), Vector2(SKW - 18.0, SKH - 128.0), Color(_cmd_cor.r, _cmd_cor.g, _cmd_cor.b, 0.35), 1.0)
			_cmd_portrait.draw_string(_font_tech, Vector2(0, SKH - 104.0), _cmd_nome.to_upper(), HORIZONTAL_ALIGNMENT_CENTER, SKW, 25, Color(_cmd_cor.r+0.18,_cmd_cor.g+0.18,_cmd_cor.b+0.18,0.98))
			_cmd_portrait.draw_string(_font_tech, Vector2(0, SKH - 74.0), _cmd_titulo_curto, HORIZONTAL_ALIGNMENT_CENTER, SKW, 10, Color(0.84,0.82,0.88,0.82))
			_cmd_portrait.draw_string(_font_tech, Vector2(0, SKH - 48.0), _cmd_coligacao_curta, HORIZONTAL_ALIGNMENT_CENTER, SKW, 12, Color(_cmd_cor.r+0.1,_cmd_cor.g+0.1,_cmd_cor.b+0.1,0.92))
		else:
			_cmd_portrait.draw_string(_font_tech, Vector2(0, SKH * 0.45), "SEM COMANDANTE", HORIZONTAL_ALIGNMENT_CENTER, SKW, 14, Color(0.45,0.48,0.56,0.75))
			_cmd_portrait.draw_line(Vector2(18, SKH - 128.0), Vector2(SKW - 18.0, SKH - 128.0), Color(_cmd_cor.r, _cmd_cor.g, _cmd_cor.b, 0.35), 1.0)
			_cmd_portrait.draw_string(_font_tech, Vector2(0, SKH - 104.0), _cmd_nome.to_upper(), HORIZONTAL_ALIGNMENT_CENTER, SKW, 25, Color(_cmd_cor.r+0.18,_cmd_cor.g+0.18,_cmd_cor.b+0.18,0.98))
			_cmd_portrait.draw_string(_font_tech, Vector2(0, SKH - 74.0), _cmd_titulo_curto, HORIZONTAL_ALIGNMENT_CENTER, SKW, 10, Color(0.84,0.82,0.88,0.82))
			_cmd_portrait.draw_string(_font_tech, Vector2(0, SKH - 48.0), _cmd_coligacao_curta, HORIZONTAL_ALIGNMENT_CENTER, SKW, 12, Color(_cmd_cor.r+0.1,_cmd_cor.g+0.1,_cmd_cor.b+0.1,0.92))
			_cmd_portrait.draw_circle(Vector2(SKW * 0.5, SKH - 21.0), 3.0 + sin(t * 2.2) * 0.8, Color(_cmd_cor.r, _cmd_cor.g, _cmd_cor.b, 0.9))
	)
	_anim_nodes.append(_cmd_portrait)
	var _slot_names := [
		["canhao", "MÓDULO", "Dano e disparos", Color(1.0,0.46,0.16)],
		["nucleo", "NÚCLEO", "Vida e energia", Color(0.20,0.90,1.0)],
		["blindagem", "DEFESA", "Defesa e regen.", Color(0.35,1.0,0.55)],
		["reliquia", "ARTEFATO", "Efeito especial", Color(0.92,0.32,1.0)],
	]
	var _skin_rel_y : float = 20.0
	var _side_x : float = SKW + _slot_gap
	var _side_w : float = _aw - _side_x
	var _side_h : float = (SKH - _slot_gap) * 0.5
	var _bottom_y : float = _skin_rel_y + SKH + _slot_gap
	var _bottom_h : float = 662.0 - (_bottom_y + arsenal_panel.position.y)
	var _bottom_w : float = (_aw - _slot_gap) * 0.5
	for _ai in range(_slot_names.size()):
		var _sd : Array = _slot_names[_ai] as Array
		var _slot_id : String = _sd[0] as String
		var _sx : float
		var _sy_a : float
		var _slot_w : float
		var _slot_h : float
		if _ai < 2:
			_sx = _side_x
			_sy_a = _skin_rel_y + float(_ai) * (_side_h + _slot_gap)
			_slot_w = _side_w
			_slot_h = _side_h
		else:
			_sx = float(_ai - 2) * (_bottom_w + _slot_gap)
			_sy_a = _bottom_y
			_slot_w = _bottom_w
			_slot_h = _bottom_h
		var _eq_id : String = str(Salvar.arsenal_equipado.get(_slot_id, ""))
		var _ainfo : Dictionary = Salvar.ARSENAL_INFO.get(_eq_id, {}) as Dictionary
		var _tem_item : bool = not _ainfo.is_empty()
		var _sc : Color = Salvar.arsenal_raridade_cor(str(_ainfo.get("raridade","comum"))) if _tem_item else (_sd[3] as Color)
		var _sc_ico : Color = (_ainfo.get("cor", _sd[3]) as Color) if _tem_item else (_sd[3] as Color)
		var _sp := _inv_painel(arsenal_panel, _sx, _sy_a, _slot_w, _slot_h,
			Color(_sc.r*0.10,_sc.g*0.10,_sc.b*0.10,0.94) if _tem_item else Color(0.025,0.026,0.040,0.88),
			Color(_sc.r,_sc.g,_sc.b,0.58) if _tem_item else Color(0.14,0.15,0.20,0.45),
			2 if _tem_item else 1)
		_inv_decorar_painel(_sp, _sc, 0.72 if _tem_item else 0.28)
		var _ico := Control.new()
		var _ico_max_h : float = _slot_h - (70.0 if _tem_item else 96.0)
		var _ico_size : float = minf(96.0, maxf(54.0, minf(_slot_w * 0.56, _ico_max_h)))
		_ico.position = Vector2((_slot_w - _ico_size) * 0.5, 20.0 if _tem_item else 30.0)
		_ico.size = Vector2(_ico_size,_ico_size)
		_ico.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_sp.add_child(_ico)
		var _slot_idx : int = _ai
		var _slot_sprite_key : String = _item_sprite_key("arsenal", str(_ainfo.get("nome", "")), _eq_id)
		if not _usar_sprite_key_na_mochila(_slot_sprite_key):
			_slot_sprite_key = ""
		_ico.draw.connect(func():
			if not _tem_item:
				return
			var _c := Vector2(_ico.size.x * 0.5, _ico.size.y * 0.5)
			var _scale : float = _ico.size.x / 58.0
			var _r := 22.0 * _scale
			_ico.draw_circle(_c, _r + 10.0, Color(_sc_ico.r,_sc_ico.g,_sc_ico.b,0.08))
			if _slot_sprite_key != "":
				var _sprite_sz : float = _ico.size.x * 0.96
				if _draw_item_sprite(_ico, _slot_sprite_key, Rect2(_c.x - _sprite_sz * 0.5, _c.y - _sprite_sz * 0.5, _sprite_sz, _sprite_sz)):
					return
			match _slot_idx:
				0:
					_ico.draw_rect(Rect2(_c.x-17.0*_scale,_c.y-5.0*_scale,34.0*_scale,10.0*_scale), Color(_sc_ico.r,_sc_ico.g,_sc_ico.b,0.25))
					_ico.draw_rect(Rect2(_c.x-17.0*_scale,_c.y-5.0*_scale,34.0*_scale,10.0*_scale), Color(_sc_ico.r,_sc_ico.g,_sc_ico.b,0.92), false, 2.0)
					_ico.draw_circle(Vector2(_c.x-12.0*_scale,_c.y), 8.0*_scale, Color(_sc_ico.r,_sc_ico.g,_sc_ico.b,0.45))
				1:
					_ico.draw_arc(_c, _r, 0, TAU, 48, Color(_sc_ico.r,_sc_ico.g,_sc_ico.b,0.92), 2.5, true)
					_ico.draw_circle(_c, 9.0*_scale, Color(_sc_ico.r,_sc_ico.g,_sc_ico.b,0.72))
				2:
					var _pts := PackedVector2Array([_c+Vector2(0,-22)*_scale,_c+Vector2(18,-12)*_scale,_c+Vector2(14,13)*_scale,_c+Vector2(0,23)*_scale,_c+Vector2(-14,13)*_scale,_c+Vector2(-18,-12)*_scale])
					_ico.draw_colored_polygon(_pts, Color(_sc_ico.r*0.18,_sc_ico.g*0.18,_sc_ico.b*0.18,0.9))
					_ico.draw_polyline(_pts + PackedVector2Array([_pts[0]]), Color(_sc_ico.r,_sc_ico.g,_sc_ico.b,0.92), 2.0)
				_:
					var _pts2 := PackedVector2Array([_c+Vector2(0,-23)*_scale,_c+Vector2(19,0)*_scale,_c+Vector2(0,23)*_scale,_c+Vector2(-19,0)*_scale])
					_ico.draw_colored_polygon(_pts2, Color(_sc_ico.r*0.22,_sc_ico.g*0.10,_sc_ico.b*0.22,0.9))
					_ico.draw_polyline(_pts2 + PackedVector2Array([_pts2[0]]), Color(_sc_ico.r,_sc_ico.g,_sc_ico.b,0.94), 2.0)
					_ico.draw_circle(_c, 5.0*_scale, Color(1.0,1.0,1.0,0.82))
		)
		if not _tem_item:
			_inv_lbl(_sp, _sd[1] as String, 0, _slot_h - 74.0, _slot_w, 22, 15,
				Color(0.34,0.38,0.48,0.82),
				HORIZONTAL_ALIGNMENT_CENTER)
		var _item_nome_slot : String = (_ainfo.get("nome", _sd[2]) as String) if _tem_item else "Slot vazio"
		if _item_nome_slot.length() > 18:
			_item_nome_slot = _item_nome_slot.substr(0, 16) + ".."
		_inv_lbl(_sp, _item_nome_slot, 8, _slot_h - (46.0 if _tem_item else 48.0), _slot_w-16, 18, 11,
			Color(0.58,0.66,0.78,0.82) if _tem_item else Color(0.28,0.31,0.38,0.68),
			HORIZONTAL_ALIGNMENT_CENTER)
		var _rar_txt : String = str(_ainfo.get("raridade", "vazio")).to_upper() if _tem_item else "VAZIO"
		_inv_lbl(_sp, _rar_txt, 0, _slot_h - 25.0, _slot_w, 16, 10,
			Color(_sc.r+0.12,_sc.g+0.12,_sc.b+0.12,0.78) if _tem_item else Color(0.24,0.26,0.32,0.72),
			HORIZONTAL_ALIGNMENT_CENTER)
		if _tem_item:
			var _slot_btn := Button.new()
			_slot_btn.position = Vector2.ZERO
			_slot_btn.size = Vector2(_slot_w, _slot_h)
			_slot_btn.flat = true
			_slot_btn.focus_mode = Control.FOCUS_NONE
			var _slot_det := {"nome":str(_ainfo.get("nome",_eq_id)), "cor":_sc, "ativo":true, "tipo":"arsenal",
				"arsenal_id":_eq_id, "slot":_slot_id, "raridade":str(_ainfo.get("raridade","comum")),
				"desc":"%s\n\n%s" % [str(_ainfo.get("desc","")), Salvar.arsenal_bonus_texto(_eq_id)]}
			_slot_btn.pressed.connect(func(): if upd_wrap[0]: upd_wrap[0].call(_slot_det))
			_sp.add_child(_slot_btn)

	var bp_h : float = 660.0 - TY
	var bp := _inv_painel(ov, RX, TY, RW, bp_h,
		Color(0.030,0.026,0.044,0.97), Color(0.54,0.36,0.70,0.58), 2)
	_inv_decorar_painel(bp, Color(0.72,0.42,1.0), 0.82)
	_inv_titulo_secao(ov, "MOCHILA", RX, TY-20, RW, Color(0.72,0.42,1.0))
	var sep_bp:=ColorRect.new(); sep_bp.color=Color(0.45,0.3,0.55,0.4)
	sep_bp.position=Vector2(10,24); sep_bp.size=Vector2(RW-20,1)
	sep_bp.mouse_filter=Control.MOUSE_FILTER_IGNORE; bp.add_child(sep_bp)

	var GRID_W  : float
	var DET_X   : float
	var DET_W   : float
	if _mob:
		GRID_W = 412.0
		DET_X  = GRID_W + 8.0
		DET_W  = minf(RW - DET_X - 8.0, 200.0)
	else:
		GRID_W = 366.0
		DET_X  = GRID_W + 8.0
		DET_W  = minf(RW - DET_X - 8.0, 250.0)
	var vsep2:=ColorRect.new(); vsep2.color=Color(0.45,0.3,0.55,0.3)
	vsep2.position=Vector2(DET_X-4,26); vsep2.size=Vector2(1,bp_h-32)
	vsep2.mouse_filter=Control.MOUSE_FILTER_IGNORE; bp.add_child(vsep2)

	_inv_lbl(bp,"DETALHES",DET_X,4,DET_W,18,10,
		Color(0.5,0.5,0.75,0.6),HORIZONTAL_ALIGNMENT_CENTER)

	var det_icon2 := Control.new()
	var _ico_sz : float = 52.0 if _mob else 56.0
	det_icon2.position=Vector2(DET_X+(DET_W-_ico_sz)*0.5,26)
	det_icon2.size=Vector2(_ico_sz,_ico_sz); det_icon2.mouse_filter=Control.MOUSE_FILTER_IGNORE
	det_icon2.clip_contents = true
	bp.add_child(det_icon2)
	_anim_nodes.append(det_icon2)

	var det_nome := _inv_lbl(bp,"â€”",DET_X,88,DET_W,22,(22 if _mob else 16),
		Color(0.85,0.85,0.9),HORIZONTAL_ALIGNMENT_CENTER)
	var det_tipo := _inv_lbl(bp,"",DET_X,108,DET_W,18,(16 if _mob else 13),
		Color(0.55,0.6,0.78,0.8),HORIZONTAL_ALIGNMENT_CENTER)
	var det_desc_y : float = 128.0
	var det_desc_h : float = maxf(130.0, bp_h - det_desc_y - 126.0)
	var det_desc_scroll := ScrollContainer.new()
	det_desc_scroll.position = Vector2(DET_X, det_desc_y)
	det_desc_scroll.size = Vector2(DET_W, det_desc_h)
	det_desc_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	det_desc_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	det_desc_scroll.clip_contents = true
	bp.add_child(det_desc_scroll)
	var det_desc := Label.new()
	det_desc.text = ""
	det_desc.position = Vector2.ZERO
	det_desc.size = Vector2(DET_W - 8.0, det_desc_h)
	det_desc.custom_minimum_size = Vector2(DET_W - 8.0, det_desc_h)
	det_desc.add_theme_font_size_override("font_size", (15 if _mob else 14))
	det_desc.add_theme_color_override("font_color", Color(0.62,0.72,0.8,0.85))
	_ui_tech_label(det_desc, 0.0)
	det_desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	det_desc.mouse_filter = Control.MOUSE_FILTER_IGNORE
	det_desc_scroll.add_child(det_desc)
	det_desc.autowrap_mode=TextServer.AUTOWRAP_WORD
	det_desc.clip_contents=false
	var xp_bar := Control.new()
	xp_bar.position=Vector2(DET_X+4,bp_h-78); xp_bar.size=Vector2(DET_W-8,18)
	xp_bar.mouse_filter=Control.MOUSE_FILTER_IGNORE; xp_bar.visible=false
	bp.add_child(xp_bar)
	var xp_bar_wrap : Array = [xp_bar]

	var _det_btn_h : float = 44.0 if _mob else 34.0
	var equip_btn := Button.new()
	equip_btn.text="EQUIPAR"; equip_btn.position=Vector2(DET_X+4,bp_h-54)
	equip_btn.size=Vector2(DET_W-8,_det_btn_h); equip_btn.focus_mode=Control.FOCUS_NONE
	equip_btn.visible=false; equip_btn.add_theme_font_size_override("font_size",17 if _mob else 15)
	var esty:=StyleBoxFlat.new()
	esty.bg_color=Color(0.08,0.12,0.28,0.92)
	esty.border_color=Color(0.35,0.55,1.0,0.75)
	for es in ["left","right","top","bottom"]: esty.set("border_width_"+es,2)
	for ec in ["top_left","top_right","bottom_left","bottom_right"]: esty.set("corner_radius_"+ec,6)
	equip_btn.add_theme_stylebox_override("normal",esty)
	equip_btn.add_theme_color_override("font_color",Color(0.6,0.8,1.0))
	bp.add_child(equip_btn)

	var comprar_btn := Button.new()
	comprar_btn.text="COMPRAR"; comprar_btn.position=Vector2(DET_X+4,bp_h-54)
	comprar_btn.size=Vector2(DET_W-8,_det_btn_h); comprar_btn.focus_mode=Control.FOCUS_NONE
	comprar_btn.visible=false; comprar_btn.add_theme_font_size_override("font_size",16 if _mob else 14)
	var csty:=StyleBoxFlat.new()
	csty.bg_color=Color(0.04,0.16,0.06,0.92)
	csty.border_color=Color(0.25,0.85,0.35,0.75)
	for cs in ["left","right","top","bottom"]: csty.set("border_width_"+cs,2)
	for cc in ["top_left","top_right","bottom_left","bottom_right"]: csty.set("corner_radius_"+cc,6)
	comprar_btn.add_theme_stylebox_override("normal",csty)
	comprar_btn.add_theme_color_override("font_color",Color(0.4,1.0,0.5))
	bp.add_child(comprar_btn)

	var sel_wrap : Array = [{}]
	var det_refs : Array = [det_nome, det_tipo, det_desc, det_icon2, equip_btn, sel_wrap, comprar_btn, xp_bar_wrap]
	var _refresh_inventario := func():
		if is_instance_valid(ov):
			ov.queue_free()
		_abrir_inventario(ui)
	var _refresh_inventario_item := func(item: Dictionary):
		_inventario_reselect_item = item.duplicate(true)
		_refresh_inventario.call()
	var _refresh_selected_wrap : Array = [null]
	var _upd_slot := func(item: Dictionary):
		det_refs[5][0] = item
		var ityp : String = item.get("tipo","") as String
		var _preview_item : bool = bool(item.get("preview", false))
		var _eb_reset : Button = det_refs[4] as Button
		var _cb_reset : Button = det_refs[6] as Button
		if _eb_reset and is_instance_valid(_eb_reset):
			_eb_reset.position = Vector2(DET_X+4,bp_h-54)
			_eb_reset.size = Vector2(DET_W-8,_det_btn_h)
			_eb_reset.disabled = false
		if _cb_reset and is_instance_valid(_cb_reset):
			_cb_reset.position = Vector2(DET_X+4,bp_h-54)
			_cb_reset.size = Vector2(DET_W-8,_det_btn_h)
			_cb_reset.disabled = false
		var _xpb_reset : Control = det_refs[7][0] as Control
		if _xpb_reset and is_instance_valid(_xpb_reset):
			_xpb_reset.position = Vector2(DET_X+4,bp_h-78)
			_xpb_reset.size = Vector2(DET_W-8,18)
		var _desc_reset : Label = det_refs[2] as Label
		if _desc_reset and is_instance_valid(_desc_reset):
			_desc_reset.position = Vector2.ZERO
			_desc_reset.size = Vector2(DET_W - 8.0, det_desc_h)
			_desc_reset.custom_minimum_size = Vector2(DET_W - 8.0, det_desc_h)
			_desc_reset.clip_contents = false
		if det_desc_scroll and is_instance_valid(det_desc_scroll):
			det_desc_scroll.position = Vector2(DET_X, det_desc_y)
			det_desc_scroll.size = Vector2(DET_W, det_desc_h)
			det_desc_scroll.scroll_vertical = 0
		det_refs[0].text = item.get("nome","") as String
		if   ityp == "skin": det_refs[1].text = "Skin"
		elif ityp == "bau":  det_refs[1].text = "Bau da mochila  \u00d7%d" % int(item.get("qtd", 0))
		elif ityp == "hab":  det_refs[1].text = "Habilidade \u00d7%d / 3" % (item.get("cargas",0) as int)
		elif ityp == "pet":
			det_refs[1].text = "Comandante"
		elif ityp == "arsenal":
			det_refs[1].text = "%s  %s" % [Salvar.arsenal_slot_nome(str(item.get("slot",""))), str(item.get("raridade","")).capitalize()]
		elif ityp == "cons": det_refs[1].text = "Consum\u00edvel"
		else:                det_refs[1].text = ""
		if _preview_item:
			det_refs[1].text = "%s  PREVIEW" % str(det_refs[1].text)
		if ityp == "pet":
			var _desc_pet : Label = det_refs[2] as Label
			if _desc_pet and is_instance_valid(_desc_pet):
				_desc_pet.add_theme_font_size_override("font_size", 10 if _mob else 9)
				var _pet_desc_h : float = 520.0 if _mob else 430.0
				_desc_pet.size = Vector2(DET_W - 8.0, _pet_desc_h)
				_desc_pet.custom_minimum_size = Vector2(DET_W - 8.0, _pet_desc_h)
			var _pdesc_pid := str(item.get("pid","cyron"))
			var _pdesc_info : Dictionary = Salvar.PETS_INFO.get(_pdesc_pid, {}) as Dictionary
			if not _pdesc_info.is_empty():
				var _pmeta_desc := _comandante_meta(_pdesc_pid)
				var _pd_nivel  : int   = Salvar.pet_nivel(_pdesc_pid)
				var _pd_stats  : Dictionary = Salvar.pet_stats(_pdesc_pid)
				var _pd_dano   := "%.0f"  % float(_pd_stats.get("dano",    0.0))
				var _pd_vel    := "%.0f"  % float(_pd_stats.get("vel",     0.0))
				var _pd_alc    := "%.0f"  % float(_pd_stats.get("alcance", 0.0))
				var _pd_cd     := "%.0fs" % float(_pd_stats.get("hab_cd",  0.0))
				var _pd_dur    := "%.0fs" % float(_pd_stats.get("hab_dur", 0.0))
				det_refs[2].text = "%s\n%s\n\nNv.%d  |  Dano: %s  Vel: %s  Alcance: %s\nCD hab: %s  Dur: %s\n\n%s" % [
					str(_pmeta_desc.get("titulo","COMANDANTE")),
					str(_pmeta_desc.get("coligacao","COLIGAÇÃO")),
					_pd_nivel,_pd_dano,_pd_vel,_pd_alc,_pd_cd,_pd_dur,Salvar.pet_evolucoes_status_texto(_pdesc_pid)
				]
			else:
				det_refs[2].text = item.get("desc","") as String
		else:
			det_refs[2].add_theme_font_size_override("font_size", 15 if _mob else 14)
			det_refs[2].text = item.get("desc","") as String
		det_refs[3].queue_redraw()
		if ityp != "pet":
			var _xpb3 : Control = det_refs[7][0] as Control
			if _xpb3 and is_instance_valid(_xpb3): _xpb3.visible = false
		if ityp == "bau":
			det_refs[4].visible = false
			det_refs[6].text = "ABRIR TESTE" if _preview_item else "ABRIR"
			det_refs[6].disabled = (not _preview_item) and int(item.get("qtd", 0)) <= 0
			det_refs[6].visible = true
		elif ityp == "skin":
			var _sid_chk : String = item.get("sid","") as String
			var ja_eq : bool = Salvar.skin_ativa == _sid_chk
			det_refs[4].text = "EQUIPADA" if ja_eq else "EQUIPAR"
			det_refs[4].disabled = ja_eq
			det_refs[4].visible = true
			det_refs[6].visible = false
		elif ityp == "hab":
			det_refs[4].visible = false
			var hcargas : int = item.get("cargas",0) as int
			var hhid : String = item.get("hid","") as String
			if hcargas < 3 and hhid != "" and Salvar.HABIL_INFO.has(hhid):
				var hcusto : int = (Salvar.HABIL_INFO[hhid] as Dictionary).get("custo_cristal",0) as int
				det_refs[6].text = "COMPRAR  (%d \u2666)" % hcusto
				det_refs[6].disabled = Salvar.cristais < hcusto
				det_refs[6].visible = true
			else:
				det_refs[6].visible = false
		elif ityp == "cons":
			det_refs[6].visible = false
			var _cid_eq : String = item.get("cons_id","") as String
			var _eq_now : bool = _cid_eq != "" and (_cid_eq in Salvar.cons_equipados)
			det_refs[4].text = "DESEQUIPAR" if _eq_now else "EQUIPAR"
			det_refs[4].disabled = ((not _eq_now) and Salvar.cons_equipados.size() >= 3)
			det_refs[4].visible = _cid_eq != ""
		elif ityp == "pet":
			det_refs[6].visible = false
			var _xpb : Control = det_refs[7][0] as Control
			var _ppid_upd := str(item.get("pid","cyron"))
			var _xpi := Salvar.pet_cartas_info(_ppid_upd)
			if _xpb and is_instance_valid(_xpb):
				_xpb.visible = true
				_xpb.position = Vector2(DET_X+4,bp_h-116)
				_xpb.size = Vector2(DET_W-8,18)
				var _xp_cor : Color = Salvar.PETS_INFO.get(_ppid_upd,{}).get("cor",Color(0.25,0.75,1.0)) as Color
				var _xp_prog : float = float(_xpi.get("prog",0.0))
				var _xp_n : int = int(_xpi.get("nivel",1))
				var _xp_cur : int = int(_xpi.get("cartas",0))
				var _xp_nec : int = int(_xpi.get("necessario",300))
				for _xbc in _xpb.draw.get_connections(): _xpb.draw.disconnect((_xbc as Dictionary)["callable"] as Callable)
				_xpb.draw.connect(func():
					var _bw:=float(_xpb.size.x); var _bh:=float(_xpb.size.y)
					_xpb.draw_rect(Rect2(0,4,_bw,_bh-8),Color(0.08,0.08,0.12,0.9))
					if _xp_n < 5:
						_xpb.draw_rect(Rect2(0,4,_bw*_xp_prog,_bh-8),Color(_xp_cor.r*0.7,_xp_cor.g*0.7,_xp_cor.b*0.7,0.9))
						_xpb.draw_arc(Rect2(0,4,_bw,_bh-8).get_center(),(_bh-8)*0.5,0,TAU,16,Color(_xp_cor.r,_xp_cor.g,_xp_cor.b,0.3),1.0)
					var font3:=ThemeDB.fallback_font
					var lv_str:="Nv.%d"%_xp_n if _xp_n<5 else "MÁX."
					var xp_str:="%d / %d cartas"%[_xp_cur,_xp_nec] if _xp_n<5 else "Nível Máximo"
					_xpb.draw_string(font3,Vector2(2,_bh-2),lv_str,HORIZONTAL_ALIGNMENT_LEFT,60,10,Color(_xp_cor.r+0.2,_xp_cor.g+0.2,_xp_cor.b+0.2,0.95))
					_xpb.draw_string(font3,Vector2(0,_bh-2),xp_str,HORIZONTAL_ALIGNMENT_RIGHT,_bw,10,Color(0.6,0.65,0.7,0.8))
				)
				_xpb.queue_redraw()
			var _cb_pet : Button = det_refs[6] as Button
			if _cb_pet and is_instance_valid(_cb_pet):
				var _xp_n_btn : int = int(_xpi.get("nivel",1))
				var _xp_cur_btn : int = int(_xpi.get("cartas", 0))
				var _xp_nec_btn : int = int(_xpi.get("necessario",0))
				if _xp_n_btn < 5:
					_cb_pet.position = Vector2(DET_X+4,bp_h-92)
					_cb_pet.size = Vector2(DET_W-8,32)
					_cb_pet.text = "EVOLUIR  %d/%d" % [_xp_cur_btn, _xp_nec_btn]
					_cb_pet.disabled = _preview_item or not Salvar.pode_evoluir_pet(_ppid_upd)
					_cb_pet.visible = true
				else:
					_cb_pet.visible = false
			var _pativo_upd : bool = (str(Salvar.pet_ativo) == _ppid_upd)
			var _eb2 : Button = det_refs[4] as Button
			if _eb2 and is_instance_valid(_eb2):
				if _pativo_upd:
					_eb2.text = "EQUIPADO"
					_eb2.disabled = true
					_eb2.visible = true
				else:
					_eb2.text = "EQUIPAR"
					_eb2.disabled = false
					_eb2.visible = true
		elif ityp == "arsenal":
			det_refs[6].visible = false
			var _aid_upd : String = str(item.get("arsenal_id", ""))
			var _slot_upd : String = str(item.get("slot", ""))
			var _ars_eq : bool = _aid_upd != "" and str(Salvar.arsenal_equipado.get(_slot_upd, "")) == _aid_upd
			det_refs[4].text = "DESEQUIPAR" if _ars_eq else "EQUIPAR"
			det_refs[4].disabled = _aid_upd == ""
			det_refs[4].visible = _aid_upd != ""
		else:
			det_refs[4].visible = false
			det_refs[6].visible = false
			var _xpb2 : Control = det_refs[7][0] as Control
			if _xpb2 and is_instance_valid(_xpb2): _xpb2.visible = false
	upd_wrap[0] = _upd_slot
	_upd_wrap_ref.clear()
	_upd_wrap_ref.append(_upd_slot)
	var _refresh_selected := func(cur: Dictionary, rebuild_cons: bool = false):
		if cur.is_empty():
			return
		if not _rebuild_slots_wrap.is_empty() and _rebuild_slots_wrap[0]:
			_rebuild_slots_wrap[0].call("tudo")
		if rebuild_cons and not _cons_rebuild_wrap.is_empty() and _cons_rebuild_wrap[0]:
			_cons_rebuild_wrap[0].call()
		if upd_wrap[0]:
			upd_wrap[0].call(cur)
	_refresh_selected_wrap[0] = _refresh_selected

	det_icon2.draw.connect(func():
		if sel_wrap[0].is_empty(): return
		var ic3 : Color = sel_wrap[0].get("cor", Color(0.5,0.5,0.5)) as Color
		var it3d : String = sel_wrap[0].get("tipo","") as String
		var cx3:=28.0; var cy3:=26.0
		if it3d == "bau":
			_draw_bau_icon(det_icon2, str(sel_wrap[0].get("bau_id", "comum")), int(sel_wrap[0].get("qtd", 1)))
			return
		if it3d == "pet" and _draw_comandante_face(det_icon2, str(sel_wrap[0].get("pid", "cyron")), Rect2(cx3 - 27.0, cy3 - 27.0, 54.0, 54.0)):
			return
		var sprite_key3 := _item_sprite_key_from_item(sel_wrap[0])
		if sprite_key3 != "" and _usar_sprite_item_na_mochila(sel_wrap[0]):
			if _draw_item_sprite(det_icon2, sprite_key3, Rect2(cx3 - 25.0, cy3 - 25.0, 50.0, 50.0)):
				return
		if it3d == "skin":
			var sid3 := str(sel_wrap[0].get("sid",""))
			if sid3 == "saberpunk":
				var rs3:=15.0; var sp3_vio:=Color(0.62,0.0,1.0)
				var pts_sp3:=PackedVector2Array()
				for hii3 in range(6):
					var a_sp3:=float(hii3)*TAU/6.0+PI/6.0; pts_sp3.append(Vector2(cx3+cos(a_sp3)*rs3,cy3+sin(a_sp3)*rs3))
				var brd_sp3:=PackedVector2Array(pts_sp3); brd_sp3.append(pts_sp3[0])
				det_icon2.draw_polyline(brd_sp3,Color(ic3.r+0.1,ic3.g+0.05,ic3.b,0.95),1.8)
				for vi3 in range(6):
					var vc3:=sp3_vio if (vi3%2==0) else Color(ic3.r+0.1,ic3.g+0.1,ic3.b+0.1)
					det_icon2.draw_circle(pts_sp3[vi3],2.5,Color(vc3.r,vc3.g,vc3.b,0.95))
				det_icon2.draw_arc(Vector2(cx3,cy3),rs3*0.5,0.0,TAU,32,Color(sp3_vio.r,sp3_vio.g,sp3_vio.b,0.6),1.4,true)
				var ang_sp3:=-PI*0.38; var cd_sp3:=Vector2(cos(ang_sp3),sin(ang_sp3))
				var cl_sp3:=cd_sp3.rotated(PI/2.0)*2.5; var tip_sp3:=Vector2(cx3,cy3)+cd_sp3*20.0
				var g_sp3:=PackedVector2Array([Vector2(cx3,cy3)-cl_sp3*0.4,Vector2(cx3,cy3)+cl_sp3*0.4,tip_sp3+cl_sp3*0.2,tip_sp3-cl_sp3*0.2])
				var gf_sp3:=PackedColorArray(); for _gsp3 in range(4): gf_sp3.append(Color(sp3_vio.r,sp3_vio.g,sp3_vio.b,0.95))
				det_icon2.draw_polygon(g_sp3,gf_sp3)
				det_icon2.draw_circle(tip_sp3,2.5,Color(1.0,1.0,1.0,0.8))
			else:
				var r3:=13.0
				var pts3:=PackedVector2Array()
				for hi3 in range(6):
					var a3:=float(hi3)*TAU/6.0+PI/6.0; pts3.append(Vector2(cx3+cos(a3)*r3,cy3+sin(a3)*r3))
				var f3:=PackedColorArray(); for _ff3 in range(6): f3.append(Color(ic3.r*0.2,ic3.g*0.2,ic3.b*0.2,0.97))
				det_icon2.draw_polygon(pts3,f3)
				var b3l:=PackedVector2Array(pts3); b3l.append(pts3[0])
				det_icon2.draw_polyline(b3l,Color(ic3.r+0.2,ic3.g+0.18,ic3.b,1.0),1.8)
				det_icon2.draw_circle(Vector2(cx3,cy3),4.5,Color(ic3.r+0.2,ic3.g+0.2,ic3.b,1.0))
				var ang3:=-PI*0.38; var cd3:=Vector2(cos(ang3),sin(ang3))
				var cl3:=cd3.rotated(PI/2.0)*2.5; var tip3:=Vector2(cx3,cy3)+cd3*20.0
				var g3:=PackedVector2Array([Vector2(cx3,cy3)-cl3*0.4,Vector2(cx3,cy3)+cl3*0.4,tip3+cl3*0.2,tip3-cl3*0.2])
				var gf3:=PackedColorArray(); for _gg3 in range(4): gf3.append(Color(ic3.r,ic3.g,ic3.b,0.95))
				det_icon2.draw_polygon(g3,gf3)
		elif it3d == "pet":
			var pid3 := str(sel_wrap[0].get("pid","cyron"))
			match pid3:
				"nexus":
					var pts_d:=PackedVector2Array()
					for i_d in 8: var a_d:=float(i_d)*TAU/8.0+PI/8.0; pts_d.append(Vector2(cx3+cos(a_d)*16,cy3+sin(a_d)*16))
					var f_d:=PackedColorArray(); for _xd in 8: f_d.append(Color(0.18,0.09,0.03,0.95))
					det_icon2.draw_polygon(pts_d,f_d)
					var br_d:=PackedVector2Array(pts_d); br_d.append(pts_d[0])
					det_icon2.draw_polyline(br_d,Color(ic3.r,ic3.g,ic3.b,0.9),2.0)
					det_icon2.draw_circle(Vector2(cx3,cy3),6.0,Color(ic3.r,ic3.g,ic3.b,0.85))
					det_icon2.draw_circle(Vector2(cx3,cy3),3.0,Color(1.0,0.9,0.7,0.95))
				"phantom":
					var dp_d:=PackedVector2Array([Vector2(cx3,cy3-20),Vector2(cx3+15,cy3),Vector2(cx3,cy3+14),Vector2(cx3-15,cy3)])
					var df_d:=PackedColorArray(); for _xd2 in 4: df_d.append(Color(0.12,0.04,0.2,0.9))
					det_icon2.draw_polygon(dp_d,df_d)
					var db_d:=PackedVector2Array(dp_d); db_d.append(dp_d[0])
					det_icon2.draw_polyline(db_d,Color(ic3.r,ic3.g,ic3.b,0.9),1.8)
					det_icon2.draw_circle(Vector2(cx3,cy3),5.0,Color(0,0,0,0.9))
					det_icon2.draw_circle(Vector2(cx3,cy3),3.5,Color(ic3.r,ic3.g,ic3.b,0.95))
					det_icon2.draw_arc(Vector2(cx3,cy3),22.0,0.0,TAU,32,Color(ic3.r,ic3.g,ic3.b,0.15),1.2)
				_:
					var s3:=1.2; var b3c:=Color(ic3.r,ic3.g,ic3.b,0.9)
					det_icon2.draw_rect(Rect2(cx3-8*s3,cy3-7*s3,16*s3,14*s3),Color(0.06,0.12,0.24,0.96))
					det_icon2.draw_line(Vector2(cx3-8*s3,cy3-7*s3),Vector2(cx3+8*s3,cy3-7*s3),b3c,2.0)
					det_icon2.draw_line(Vector2(cx3+8*s3,cy3-7*s3),Vector2(cx3+8*s3,cy3+7*s3),b3c,2.0)
					det_icon2.draw_line(Vector2(cx3+8*s3,cy3+7*s3),Vector2(cx3-8*s3,cy3+7*s3),b3c,2.0)
					det_icon2.draw_line(Vector2(cx3-8*s3,cy3+7*s3),Vector2(cx3-8*s3,cy3-7*s3),b3c,2.0)
					det_icon2.draw_line(Vector2(cx3,cy3-7*s3),Vector2(cx3,cy3-13*s3),Color(0.45,0.85,1.0,0.8),1.8)
					det_icon2.draw_circle(Vector2(cx3,cy3-14*s3),3.0,Color(ic3.r,ic3.g,ic3.b,1.0))
		elif it3d == "arsenal":
			var slot_d : String = str(sel_wrap[0].get("slot", ""))
			var rr_d : String = str(sel_wrap[0].get("raridade", "comum"))
			var rc_d : Color = Salvar.arsenal_raridade_cor(rr_d)
			det_icon2.draw_circle(Vector2(cx3,cy3),22,Color(ic3.r*0.15,ic3.g*0.15,ic3.b*0.15,0.9))
			det_icon2.draw_arc(Vector2(cx3,cy3),22,0,TAU,48,Color(rc_d.r,rc_d.g,rc_d.b,0.95),2.6,true)
			match slot_d:
				"canhao":
					det_icon2.draw_rect(Rect2(cx3-18,cy3-5,34,10),Color(ic3.r,ic3.g,ic3.b,0.35))
					det_icon2.draw_rect(Rect2(cx3-18,cy3-5,34,10),Color(ic3.r,ic3.g,ic3.b,0.95),false,2.2)
					det_icon2.draw_circle(Vector2(cx3-13,cy3),8,Color(ic3.r,ic3.g,ic3.b,0.65))
				"nucleo":
					det_icon2.draw_circle(Vector2(cx3,cy3),10,Color(ic3.r,ic3.g,ic3.b,0.82))
					det_icon2.draw_arc(Vector2(cx3,cy3),15,0,TAU,32,Color(ic3.r,ic3.g,ic3.b,0.45),2.0,true)
				"blindagem":
					var pts_a:=PackedVector2Array([Vector2(cx3,cy3-22),Vector2(cx3+18,cy3-10),Vector2(cx3+14,cy3+14),Vector2(cx3,cy3+23),Vector2(cx3-14,cy3+14),Vector2(cx3-18,cy3-10)])
					det_icon2.draw_colored_polygon(pts_a,Color(ic3.r*0.18,ic3.g*0.18,ic3.b*0.18,0.9))
					det_icon2.draw_polyline(pts_a+PackedVector2Array([pts_a[0]]),Color(ic3.r,ic3.g,ic3.b,0.95),2.2)
				_:
					var pts_b:=PackedVector2Array([Vector2(cx3,cy3-23),Vector2(cx3+19,cy3),Vector2(cx3,cy3+23),Vector2(cx3-19,cy3)])
					det_icon2.draw_colored_polygon(pts_b,Color(ic3.r*0.22,ic3.g*0.10,ic3.b*0.22,0.9))
					det_icon2.draw_polyline(pts_b+PackedVector2Array([pts_b[0]]),Color(ic3.r,ic3.g,ic3.b,0.95),2.2)
					det_icon2.draw_circle(Vector2(cx3,cy3),5,Color(1.0,1.0,1.0,0.85))
		elif it3d == "cons":
			var inome_d : String = sel_wrap[0].get("nome","") as String
			if "Vela" in inome_d:
				det_icon2.draw_circle(Vector2(cx3,cy3+8),10,Color(ic3.r*0.3,ic3.g*0.3,ic3.b*0.1,0.4))
				var fl_d:=PackedVector2Array([Vector2(cx3,cy3-18),Vector2(cx3-9,cy3+6),Vector2(cx3,cy3),Vector2(cx3+9,cy3+6)])
				det_icon2.draw_colored_polygon(fl_d,Color(ic3.r,ic3.g*0.7,0.1,0.95))
				var fl2_d:=PackedVector2Array([Vector2(cx3,cy3-11),Vector2(cx3-4,cy3+2),Vector2(cx3,cy3-2),Vector2(cx3+4,cy3+2)])
				det_icon2.draw_colored_polygon(fl2_d,Color(1.0,0.95,0.5,0.9))
				det_icon2.draw_rect(Rect2(cx3-3,cy3+10,6,11),Color(ic3.r*0.4,ic3.g*0.4,0.1,0.8))
			elif "Orbe" in inome_d:
				det_icon2.draw_circle(Vector2(cx3,cy3),18,Color(ic3.r*0.15,ic3.g*0.25,ic3.b*0.15,0.9))
				det_icon2.draw_arc(Vector2(cx3,cy3),18,0,TAU,48,Color(ic3.r,ic3.g,ic3.b,0.9),2.5)
				det_icon2.draw_line(Vector2(cx3,cy3-11),Vector2(cx3,cy3+11),Color(ic3.r+0.3,ic3.g+0.2,ic3.b+0.2,0.95),3.5)
				det_icon2.draw_line(Vector2(cx3-11,cy3),Vector2(cx3+11,cy3),Color(ic3.r+0.3,ic3.g+0.2,ic3.b+0.2,0.95),3.5)
			elif "Cristal" in inome_d:
				var pts_cd:=PackedVector2Array()
				for _sci3 in range(6):
					var a_cd:=_sci3*TAU/6.0-PI*0.5
					pts_cd.append(Vector2(cx3+cos(a_cd)*18,cy3+sin(a_cd)*18))
				det_icon2.draw_colored_polygon(pts_cd,Color(ic3.r*0.15,ic3.g*0.2,ic3.b*0.3,0.9))
				det_icon2.draw_polyline(pts_cd+PackedVector2Array([pts_cd[0]]),Color(ic3.r,ic3.g,ic3.b,0.9),2.5)
				det_icon2.draw_arc(Vector2(cx3,cy3),9,0,TAU,24,Color(ic3.r,ic3.g,ic3.b,0.4),1.5)
			elif "Runa" in inome_d:
				var pts_rd:=PackedVector2Array([Vector2(cx3,cy3-22),Vector2(cx3+16,cy3),Vector2(cx3,cy3+22),Vector2(cx3-16,cy3)])
				det_icon2.draw_colored_polygon(pts_rd,Color(ic3.r*0.25,ic3.g*0.08,ic3.b*0.04,0.9))
				det_icon2.draw_polyline(pts_rd+PackedVector2Array([pts_rd[0]]),Color(ic3.r,ic3.g*0.6,ic3.b*0.2,0.9),2.5)
				det_icon2.draw_line(Vector2(cx3-5,cy3-8),Vector2(cx3+3,cy3),Color(1.0,0.9,0.3,0.95),2.5)
				det_icon2.draw_line(Vector2(cx3+3,cy3),Vector2(cx3-3,cy3+2),Color(1.0,0.9,0.3,0.95),2.5)
				det_icon2.draw_line(Vector2(cx3-3,cy3+2),Vector2(cx3+5,cy3+10),Color(1.0,0.9,0.3,0.95),2.5)
			else:
				det_icon2.draw_circle(Vector2(cx3,cy3),16,Color(ic3.r*0.25,ic3.g*0.25,ic3.b*0.25,0.9))
				det_icon2.draw_arc(Vector2(cx3,cy3),14,0,TAU,32,Color(ic3.r,ic3.g,ic3.b,0.85),2.5,true)
		else:
			det_icon2.draw_circle(Vector2(cx3,cy3),16.0,Color(ic3.r*0.25,ic3.g*0.25,ic3.b*0.25,0.9))
			det_icon2.draw_arc(Vector2(cx3,cy3),14.0,0.0,TAU,40,Color(ic3.r,ic3.g,ic3.b,0.85),2.5,true)
			det_icon2.draw_circle(Vector2(cx3,cy3),5.0,Color(ic3.r+0.2,ic3.g+0.2,ic3.b+0.2,0.9))
	)

	equip_btn.pressed.connect(func():
		var cur : Dictionary = det_refs[5][0] as Dictionary
		if bool(cur.get("preview", false)):
			cur = _debug_liberar_preview_item(cur)
			if cur.is_empty():
				return
			det_refs[5][0] = cur
		if cur.get("tipo","") == "skin":
			var sid_eq : String = cur.get("sid","") as String
			if Salvar.skin_ativa != sid_eq:
				Salvar.equipar_skin(sid_eq)
				_refresh_inventario_item.call(cur)
		elif cur.get("tipo","") == "cons":
			var cid : String = cur.get("cons_id","") as String
			if cid == "": return
			if cid in Salvar.cons_equipados:
				Salvar.cons_equipados.erase(cid)
			elif Salvar.cons_equipados.size() < 3:
				Salvar.cons_equipados.append(cid)
			else: return
			Salvar.salvar()
			_refresh_inventario_item.call(cur)
		elif cur.get("tipo","") == "pet":
			var pid_eq : String = cur.get("pid","") as String
			if pid_eq != "" and Salvar.pet_ativo != pid_eq:
				Salvar.equipar_pet(pid_eq)
				_refresh_inventario_item.call(cur)
		elif cur.get("tipo","") == "arsenal":
			var aid_eq : String = str(cur.get("arsenal_id", ""))
			var slot_eq : String = str(cur.get("slot", ""))
			if aid_eq == "" or slot_eq == "":
				return
			if str(Salvar.arsenal_equipado.get(slot_eq, "")) == aid_eq:
				Salvar.desequipar_slot_arsenal(slot_eq)
			else:
				Salvar.equipar_item_arsenal(aid_eq)
			_refresh_inventario_item.call(cur)
	)

	comprar_btn.pressed.connect(func():
		var cur : Dictionary = det_refs[5][0] as Dictionary
		if cur.get("tipo","") == "bau":
			var btier_c : String = str(cur.get("bau_id", "comum"))
			var bau_preview : bool = bool(cur.get("preview", false))
			if bau_preview:
				cur = _debug_liberar_preview_item(cur)
				if cur.is_empty():
					return
				btier_c = str(cur.get("bau_id", "comum"))
				bau_preview = false
			var ao_fechar_bau := func():
				_refresh_inventario.call()
			_abrir_bau_grande(ui, btier_c, ao_fechar_bau, bau_preview)
		elif cur.get("tipo","") == "hab":
			var hid_c : String = cur.get("hid","") as String
			if bool(cur.get("preview", false)):
				cur = _debug_liberar_preview_item(cur)
				if cur.is_empty():
					return
				_refresh_inventario_item.call(cur)
			elif Salvar.comprar_carga_habil(hid_c):
				_refresh_inventario_item.call(cur)
		elif cur.get("tipo","") == "pet":
			var pid_ev : String = str(cur.get("pid",""))
			if Salvar.evoluir_pet(pid_ev):
				Som.upgrade()
				_refresh_inventario_item.call(cur)
	)

	var SLOT_SZ : float = 86.0 if _mob else 76.0
	var SLOT_GAP: float = 9.0 if _mob else 10.0
	var GRID_PAD_X : float = 10.0 if _mob else 14.0
	var GRID_PAD_BOTTOM : float = 12.0 if _mob else 14.0
	var cols : int = maxi(1, int((GRID_W - GRID_PAD_X * 2.0 + SLOT_GAP) / (SLOT_SZ + SLOT_GAP)))

	var bag_items : Array = []
	var _bau_ordem_inv := ["comum", "raro", "epico", "lendario"]
	for _btier in _bau_ordem_inv:
		var _btier_s : String = str(_btier)
		var _bqtd : int = int(Salvar.baus_estoque.get(_btier_s, 0))
		if _bqtd <= 0:
			continue
		var _binfo := _bau_info(_btier_s)
		var _bcor : Color = _binfo["cor"] as Color
		bag_items.append({"nome":"%s x%d" % [str(_binfo["nome"]), _bqtd],
			"cor":_bcor, "ativo":true, "tipo":"bau", "bau_id":_btier_s, "qtd":_bqtd,
			"raridade":_btier_s,
			"desc":"Abra para receber ouro, cristais, skins, comandantes, habilidades, consumíveis e até outro baú."})
	Salvar.normalizar_arsenal()
	for aid in Salvar.arsenal_itens_desbloqueados:
		var aid_s : String = str(aid)
		var ai2 : Dictionary = Salvar.ARSENAL_INFO.get(aid_s, {}) as Dictionary
		if ai2.is_empty():
			continue
		var aslot : String = str(ai2.get("slot", ""))
		var aativa : bool = str(Salvar.arsenal_equipado.get(aslot, "")) == aid_s
		var arar : String = str(ai2.get("raridade", "comum"))
		var acor : Color = ai2.get("cor", Salvar.arsenal_raridade_cor(arar)) as Color
		bag_items.append({"nome": str(ai2.get("nome", aid_s)), "cor": acor,
			"ativo": aativa, "tipo": "arsenal", "arsenal_id": aid_s, "slot": aslot,
			"raridade": arar,
			"desc": "%s\n\n%s" % [str(ai2.get("desc","")), Salvar.arsenal_bonus_texto(aid_s)]})
	for sid in Salvar.skins_desbloqueadas:
		var si2 : Dictionary = Salvar.SKINS_INFO.get(sid, {}) as Dictionary
		if not SHOW_PREMIUM_PURCHASES and bool(si2.get("premium", false)):
			continue
		var sativa : bool = Salvar.skin_ativa == sid
		bag_items.append({"nome": si2.get("nome","Skin") as String,
			"cor": si2.get("cor", Color(1.0,0.82,0.0)) as Color,
			"ativo": sativa, "tipo": "skin", "sid": sid,
			"desc": si2.get("desc","") as String})
	for hid2 in Salvar.HABIL_INFO.keys():
		var hc2 : int = Salvar.habil_cargas.get(hid2, 0) as int
		var hi2 : Dictionary = Salvar.HABIL_INFO[hid2] as Dictionary
		bag_items.append({"nome": hi2["nome"] as String,
			"cor": hi2["cor"] as Color, "ativo": hc2 > 0, "tipo": "hab",
			"cargas": hc2, "hid": hid2,
			"desc": hi2.get("desc","") as String})
	var _all_pets : Array = Array(Salvar.pets_desbloqueados)
	if Salvar.pet_ia_comprado and not ("cyron" in _all_pets): _all_pets.append("cyron")
	for _pid3 in _all_pets:
		var _pi3 : Dictionary = Salvar.PETS_INFO.get(_pid3, {}) as Dictionary
		if _pi3.is_empty(): continue
		if not SHOW_PREMIUM_PURCHASES and bool(_pi3.get("premium", false)):
			continue
		if bool(_pi3.get("premium", false)) and not (str(_pid3) in Salvar.pets_desbloqueados):
			continue
		var _pativo3 : bool = (str(_pid3) == Salvar.pet_ativo)
		bag_items.append({"nome":str(_pi3.get("nome",_pid3)),"cor":_pi3.get("cor",Color(0.25,0.75,1.0)) as Color,
			"ativo":_pativo3,"tipo":"pet","desc":str(_pi3.get("desc","")),"pid":str(_pid3)})
	if Salvar.revive_loja_estoque > 0:
		bag_items.append({"nome":"Vela da Alma x%d" % Salvar.revive_loja_estoque,
			"cor":Color(0.55,1.0,0.35),"ativo":"revive" in Salvar.cons_equipados,"tipo":"cons","cons_id":"revive",
			"desc":"Restaura 50%% da vida automaticamente ao ser derrotado."})
	if Salvar.orbe_cura_estoque > 0:
		bag_items.append({"nome":"Orbe de Cura x%d" % Salvar.orbe_cura_estoque,
			"cor":Color(0.2,0.85,0.45),"ativo":"orbe" in Salvar.cons_equipados,"tipo":"cons","cons_id":"orbe",
			"desc":"Restaura 50%% do HP máximo da torre ao ser usado."})
	if Salvar.cristal_barreira_estoque > 0:
		bag_items.append({"nome":"Cristal Barreira x%d" % Salvar.cristal_barreira_estoque,
			"cor":Color(0.3,0.55,1.0),"ativo":"cristal" in Salvar.cons_equipados,"tipo":"cons","cons_id":"cristal",
			"desc":"Absorve o próximo golpe fatal, salvando a torre."})
	if Salvar.runa_furia_estoque > 0:
		bag_items.append({"nome":"Runa de F\u00faria x%d" % Salvar.runa_furia_estoque,
			"cor":Color(1.0,0.45,0.1),"ativo":"runa" in Salvar.cons_equipados,"tipo":"cons","cons_id":"runa",
			"desc":"+80%% de dano por 8s. Ativar manualmente no HUD."})

	if DEBUG_MOCHILA_MOSTRAR_TODOS_ITENS and OS.is_debug_build():
		var _bag_has := func(tipo: String, key: String, value: String) -> bool:
			for _raw in bag_items:
				var _it : Dictionary = _raw as Dictionary
				if str(_it.get("tipo", "")) == tipo and str(_it.get(key, "")) == value:
					return true
			return false
		for _prev_btier in _bau_ordem_inv:
			var _prev_btier_s : String = str(_prev_btier)
			if _bag_has.call("bau", "bau_id", _prev_btier_s):
				continue
			var _prev_binfo := _bau_info(_prev_btier_s)
			var _prev_bcor : Color = _prev_binfo["cor"] as Color
			bag_items.append({"nome":"%s x0" % str(_prev_binfo["nome"]),
				"cor":_prev_bcor, "ativo":false, "tipo":"bau", "bau_id":_prev_btier_s, "qtd":0,
				"raridade":_prev_btier_s, "preview":true,
				"desc":"PREVIEW DEBUG\nAbra para receber ouro, cristais, skins, comandantes, habilidades, consumiveis e ate outro bau."})
		for _prev_aid in Salvar.ARSENAL_INFO.keys():
			var _prev_aid_s : String = str(_prev_aid)
			if _bag_has.call("arsenal", "arsenal_id", _prev_aid_s):
				continue
			var _prev_ai : Dictionary = Salvar.ARSENAL_INFO.get(_prev_aid_s, {}) as Dictionary
			if _prev_ai.is_empty():
				continue
			var _prev_slot : String = str(_prev_ai.get("slot", ""))
			var _prev_rar : String = str(_prev_ai.get("raridade", "comum"))
			var _prev_acor : Color = _prev_ai.get("cor", Salvar.arsenal_raridade_cor(_prev_rar)) as Color
			bag_items.append({"nome": str(_prev_ai.get("nome", _prev_aid_s)), "cor": _prev_acor,
				"ativo": false, "tipo": "arsenal", "arsenal_id": _prev_aid_s, "slot": _prev_slot,
				"raridade": _prev_rar, "preview":true,
				"desc": "PREVIEW DEBUG\n%s\n\n%s" % [str(_prev_ai.get("desc","")), Salvar.arsenal_bonus_texto(_prev_aid_s)]})
		for _prev_sid in Salvar.SKINS_INFO.keys():
			var _prev_sid_s : String = str(_prev_sid)
			if _bag_has.call("skin", "sid", _prev_sid_s):
				continue
			var _prev_si : Dictionary = Salvar.SKINS_INFO.get(_prev_sid_s, {}) as Dictionary
			if _prev_si.is_empty():
				continue
			if not SHOW_PREMIUM_PURCHASES and bool(_prev_si.get("premium", false)):
				continue
			bag_items.append({"nome": _prev_si.get("nome","Skin") as String,
				"cor": _prev_si.get("cor", Color(1.0,0.82,0.0)) as Color,
				"ativo": false, "tipo": "skin", "sid": _prev_sid_s, "preview":true,
				"desc": "PREVIEW DEBUG\n%s" % str(_prev_si.get("desc",""))})
		for _prev_pid in Salvar.PETS_INFO.keys():
			var _prev_pid_s : String = str(_prev_pid)
			if _bag_has.call("pet", "pid", _prev_pid_s):
				continue
			var _prev_pi : Dictionary = Salvar.PETS_INFO.get(_prev_pid_s, {}) as Dictionary
			if _prev_pi.is_empty():
				continue
			if bool(_prev_pi.get("premium", false)):
				continue
			bag_items.append({"nome":str(_prev_pi.get("nome",_prev_pid_s)),
				"cor":_prev_pi.get("cor",Color(0.25,0.75,1.0)) as Color,
				"ativo":false,"tipo":"pet","desc":"PREVIEW DEBUG\n%s" % str(_prev_pi.get("desc","")),
				"pid":_prev_pid_s, "preview":true})
		var _prev_cons := [
			{"id":"revive","nome":"Vela da Alma x0","cor":Color(0.55,1.0,0.35),"desc":"Restaura 50%% da vida automaticamente ao ser derrotado."},
			{"id":"orbe","nome":"Orbe de Cura x0","cor":Color(0.2,0.85,0.45),"desc":"Restaura 50%% do HP maximo da torre ao ser usado."},
			{"id":"cristal","nome":"Cristal Barreira x0","cor":Color(0.3,0.55,1.0),"desc":"Absorve o proximo golpe fatal, salvando a torre."},
			{"id":"runa","nome":"Runa de Furia x0","cor":Color(1.0,0.45,0.1),"desc":"+80%% de dano por 8s. Ativar manualmente no HUD."},
		]
		for _prev_craw in _prev_cons:
			var _prev_cd : Dictionary = _prev_craw as Dictionary
			var _prev_cid : String = str(_prev_cd.get("id", ""))
			if _bag_has.call("cons", "cons_id", _prev_cid):
				continue
			bag_items.append({"nome":str(_prev_cd.get("nome", "Consumivel x0")),
				"cor":_prev_cd.get("cor", Color(0.55,1.0,0.35)) as Color,
				"ativo":false,"tipo":"cons","cons_id":_prev_cid,"preview":true,
				"desc":"PREVIEW DEBUG\n%s" % str(_prev_cd.get("desc", ""))})

	# â”€â”€ Filtros da mochila â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
	var _cat_rank := {"bau": 0, "arsenal": 1, "skin": 2, "pet": 3, "hab": 4, "cons": 5}
	var _rar_rank := {"lendario": 0, "epico": 1, "raro": 2, "comum": 3}
	bag_items.sort_custom(func(a, b):
		var da : Dictionary = a as Dictionary
		var db : Dictionary = b as Dictionary
		var ca : int = int(_cat_rank.get(str(da.get("tipo", "")), 99))
		var cb : int = int(_cat_rank.get(str(db.get("tipo", "")), 99))
		if ca != cb:
			return ca < cb
		if str(da.get("tipo", "")) == "bau" and str(db.get("tipo", "")) == "bau":
			return _bau_ordem_inv.find(str(da.get("bau_id", ""))) < _bau_ordem_inv.find(str(db.get("bau_id", "")))
		var ra : int = int(_rar_rank.get(str(da.get("raridade", "")), 50))
		var rb : int = int(_rar_rank.get(str(db.get("raridade", "")), 50))
		if ra != rb:
			return ra < rb
		var aa : int = 0 if da.get("ativo", false) == true else 1
		var ab : int = 0 if db.get("ativo", false) == true else 1
		if aa != ab:
			return aa < ab
		return str(da.get("nome", "")).naturalnocasecmp_to(str(db.get("nome", ""))) < 0
	)

	var _filt_tipos := ["tudo","arsenal","skin","hab","pet","cons"]
	var _filt_labels := ["TUDO","ARS.","SKINS","HABIL.","CMD.","CONS."]
	var _filt_cores := [Color(0.5,0.5,0.6),Color(0.85,0.45,1.0),Color(1.0,0.82,0.0),Color(0.3,0.7,1.0),Color(0.25,0.75,1.0),Color(0.55,1.0,0.35)]
	if not _inventario_filtro_atual in _filt_tipos:
		_inventario_filtro_atual = "tudo"
	var _filt_wrap : Array = [_inventario_filtro_atual]
	var _fbtns_wrap : Array = []
	var _filt_y : float = 28.0
	var _filt_h : float = 36.0 if _mob else 30.0
	var _filt_total_w : float = GRID_W - 8.0
	var _filt_gap : float = 5.0
	var _filt_btn_w : float = (_filt_total_w - float(_filt_tipos.size()-1)*_filt_gap) / float(_filt_tipos.size())
	for _fi in _filt_tipos.size():
		var _fb := Button.new()
		_fb.text = _filt_labels[_fi]
		_fb.position = Vector2(4.0 + float(_fi)*(_filt_btn_w+_filt_gap), _filt_y)
		_fb.size = Vector2(_filt_btn_w, _filt_h)
		_fb.focus_mode = Control.FOCUS_NONE
		_fb.add_theme_font_size_override("font_size", 12 if _mob else 10)
		var _fbc : Color  = _filt_cores[_fi] as Color
		var _fbt : String = _filt_tipos[_fi]  as String
		var _fsty_n := StyleBoxFlat.new()
		_fsty_n.bg_color = Color(_fbc.r*0.050,_fbc.g*0.050,_fbc.b*0.065,0.90)
		_fsty_n.border_color = Color(_fbc.r,_fbc.g,_fbc.b,0.22)
		_fsty_n.content_margin_left = 4
		_fsty_n.content_margin_right = 4
		for _fss in ["left","right","top","bottom"]: _fsty_n.set("border_width_"+_fss,1)
		for _fsc in ["top_left","top_right","bottom_left","bottom_right"]: _fsty_n.set("corner_radius_"+_fsc,3)
		var _fsty_a := StyleBoxFlat.new()
		_fsty_a.bg_color = Color(_fbc.r*0.18,_fbc.g*0.18,_fbc.b*0.20,0.98)
		_fsty_a.border_color = Color(minf(_fbc.r+0.18,1.0),minf(_fbc.g+0.18,1.0),minf(_fbc.b+0.18,1.0),0.96)
		_fsty_a.content_margin_left = 4
		_fsty_a.content_margin_right = 4
		for _fssa in ["left","right","top","bottom"]: _fsty_a.set("border_width_"+_fssa,2)
		for _fsca in ["top_left","top_right","bottom_left","bottom_right"]: _fsty_a.set("corner_radius_"+_fsca,3)
		_fb.add_theme_stylebox_override("normal", _fsty_n)
		_fb.add_theme_stylebox_override("hover",  _fsty_a)
		_fb.add_theme_stylebox_override("pressed",_fsty_a)
		_fb.add_theme_color_override("font_color", Color(_fbc.r+0.18,_fbc.g+0.18,_fbc.b+0.18,0.86))
		_fb.add_theme_color_override("font_hover_color", Color(1.0,1.0,1.0,0.95))
		_fb.add_theme_color_override("font_pressed_color", Color(1.0,1.0,1.0,1.0))
		var _fdecor := Control.new()
		_fdecor.set_anchors_preset(Control.PRESET_FULL_RECT)
		_fdecor.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var _fdecor_cor : Color = _fbc
		var _fdecor_tipo : String = _fbt
		_fdecor.draw.connect(func():
			var w := _fdecor.size.x
			var h := _fdecor.size.y
			var active := _inventario_filtro_atual == _fdecor_tipo
			var cut := 6.0
			var poly := PackedVector2Array([
				Vector2(cut, 1), Vector2(w - cut, 1), Vector2(w - 1, cut),
				Vector2(w - 1, h - cut), Vector2(w - cut, h - 1), Vector2(cut, h - 1),
				Vector2(1, h - cut), Vector2(1, cut), Vector2(cut, 1)
			])
			if active:
				for _glow_i in range(3, 0, -1):
					_fdecor.draw_polyline(poly, Color(_fdecor_cor.r,_fdecor_cor.g,_fdecor_cor.b,0.055 * float(_glow_i)), float(_glow_i) * 1.8)
				_fdecor.draw_rect(Rect2(9, h - 6, w - 18, 2), Color(_fdecor_cor.r,_fdecor_cor.g,_fdecor_cor.b,0.92), true)
				_fdecor.draw_circle(Vector2(10, h * 0.5), 3.0, Color(_fdecor_cor.r,_fdecor_cor.g,_fdecor_cor.b,0.95))
				_fdecor.draw_line(Vector2(w - 17, 7), Vector2(w - 7, 7), Color(_fdecor_cor.r,_fdecor_cor.g,_fdecor_cor.b,0.72), 1.2)
			else:
				_fdecor.draw_circle(Vector2(9, h * 0.5), 2.0, Color(_fdecor_cor.r,_fdecor_cor.g,_fdecor_cor.b,0.34))
				_fdecor.draw_line(Vector2(w - 15, h - 6), Vector2(w - 7, h - 6), Color(_fdecor_cor.r,_fdecor_cor.g,_fdecor_cor.b,0.28), 1.0)
			_fdecor.draw_polyline(poly, Color(_fdecor_cor.r,_fdecor_cor.g,_fdecor_cor.b,0.42 if active else 0.18), 1.0)
		)
		_fb.add_child(_fdecor)
		var _fsty_n_c := _fsty_n
		var _fsty_a_c := _fsty_a
		_fb.pressed.connect(func():
			_filt_wrap[0] = _fbt
			_inventario_filtro_atual = _fbt
			for _afbi in _fbtns_wrap.size():
				var _afbd : Array = _fbtns_wrap[_afbi] as Array
				var _is_sel : bool = (_filt_tipos[_afbi] == _fbt)
				(_afbd[0] as Button).add_theme_stylebox_override("normal", _afbd[2] if _is_sel else _afbd[1])
				(_afbd[0] as Button).add_theme_color_override("font_color", Color(1.0,1.0,1.0,0.96) if _is_sel else Color((_afbd[3] as Color).r+0.18,(_afbd[3] as Color).g+0.18,(_afbd[3] as Color).b+0.18,0.86))
				if _afbd.size() > 4 and is_instance_valid(_afbd[4] as Control):
					(_afbd[4] as Control).queue_redraw()
			_rebuild_slots_wrap[0].call(_fbt)
		)
		bp.add_child(_fb)
		_fbtns_wrap.append([_fb, _fsty_n_c, _fsty_a_c, _fbc, _fdecor])

	var _grid_view_y : float = _filt_y + _filt_h + (14.0 if _mob else 10.0)
	var _grid_view_h : float = bp_h - _grid_view_y - GRID_PAD_BOTTOM
	var _slot_view := Control.new()
	_slot_view.position = Vector2(0.0, _grid_view_y)
	_slot_view.size = Vector2(GRID_W, _grid_view_h)
	_slot_view.clip_contents = true
	_slot_view.mouse_filter = Control.MOUSE_FILTER_PASS
	bp.add_child(_slot_view)

	var _slot_cont := Control.new()
	_slot_cont.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_slot_view.add_child(_slot_cont)

	var _slot_scroll := VScrollBar.new()
	_slot_scroll.position = Vector2(GRID_W - 8.0, _grid_view_y)
	_slot_scroll.size = Vector2(8.0, _grid_view_h)
	_slot_scroll.visible = false
	_slot_scroll.step = SLOT_SZ + SLOT_GAP
	bp.add_child(_slot_scroll)
	_slot_scroll.value_changed.connect(func(v: float):
		_inventario_scroll_target = v
		_slot_cont.position.y = -v
	)
	_inventario_scroll_enabled = true
	_inventario_scroll_bar = _slot_scroll
	_inventario_scroll_content = _slot_cont
	_inventario_scroll_view_h = _grid_view_h
	_inventario_scroll_area = _slot_view.get_global_rect().grow(10.0)
	ov.tree_exiting.connect(func():
		if _inventario_scroll_content == _slot_cont:
			_limpar_scroll_mochila()
	)
	var _slot_wheel_scroll := func(ev: InputEvent) -> void:
		if not (ev is InputEventMouseButton):
			return
		var mb := ev as InputEventMouseButton
		if not mb.pressed:
			return
		var delta := 0.0
		if mb.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			delta = 46.0
		elif mb.button_index == MOUSE_BUTTON_WHEEL_UP:
			delta = -46.0
		else:
			return
		_aplicar_scroll_mochila(delta)
		get_viewport().set_input_as_handled()
	_slot_view.gui_input.connect(_slot_wheel_scroll)
	bp.gui_input.connect(_slot_wheel_scroll)

	var _rebuild_slots := func(ftype: String) -> void:
		for _old_ch in _slot_cont.get_children(): _old_ch.queue_free()
		_slot_cont.position = Vector2.ZERO
		_slot_scroll.value = 0.0
		_inventario_scroll_target = 0.0
		var _fitems : Array = bag_items if ftype=="tudo" else bag_items.filter(func(it): return it.get("tipo","")==ftype)
		var rows_fit : int = int(_grid_view_h / (SLOT_SZ + SLOT_GAP))
		var total_slots : int = maxi(_fitems.size() + 2, cols * rows_fit)
		var rows_total : int = int(ceil(float(total_slots) / float(cols)))
		var content_h : float = maxf(_grid_view_h, float(rows_total) * (SLOT_SZ + SLOT_GAP) - SLOT_GAP)
		_slot_cont.size = Vector2(GRID_W, content_h)
		_slot_scroll.visible = content_h > _grid_view_h + 2.0
		_slot_scroll.min_value = 0.0
		_slot_scroll.max_value = content_h
		_slot_scroll.page = _grid_view_h
		for si3 in range(total_slots):
			var sc3 : int = si3 % cols
			var sr3 : int = si3 / cols
			var sx3 : float = GRID_PAD_X + float(sc3)*(SLOT_SZ+SLOT_GAP)
			var sy3 : float = float(sr3)*(SLOT_SZ+SLOT_GAP)
			if sx3 + SLOT_SZ > GRID_W - GRID_PAD_X: break
			var has_item : bool = si3 < _fitems.size()
			var item : Dictionary = _fitems[si3] as Dictionary if has_item else {}
			var _item_cor : Color = (item.get("cor", Color(0.5,0.5,0.5)) as Color) if has_item else Color(0.12,0.12,0.18)
			var icor : Color = _item_cor
			if has_item and item.get("tipo","") == "arsenal":
				icor = Salvar.arsenal_raridade_cor(str(item.get("raridade","comum")))
			var iativo: bool = (item.get("ativo", false) as bool) if has_item else false
			if not has_item:
				var _ep := _inv_painel(_slot_cont,sx3,sy3,SLOT_SZ,SLOT_SZ,Color(0.07,0.07,0.10,0.8),Color(0.2,0.2,0.25,0.2),1)
				_ep.mouse_filter = Control.MOUSE_FILTER_IGNORE
				continue
			var sbtn := Button.new()
			sbtn.position=Vector2(sx3,sy3); sbtn.size=Vector2(SLOT_SZ,SLOT_SZ)
			sbtn.clip_contents = true
			sbtn.focus_mode=Control.FOCUS_NONE
			var sty_n:=StyleBoxFlat.new()
			sty_n.bg_color=Color(icor.r*0.18,icor.g*0.18,icor.b*0.18,0.95)
			sty_n.border_color=Color(icor.r,icor.g,icor.b,0.75 if iativo else 0.3)
			for ssd in ["left","right","top","bottom"]: sty_n.set("border_width_"+ssd,2 if iativo else 1)
			for ssc in ["top_left","top_right","bottom_left","bottom_right"]: sty_n.set("corner_radius_"+ssc,9)
			var sty_h:=StyleBoxFlat.new()
			sty_h.bg_color=Color(icor.r*0.35,icor.g*0.35,icor.b*0.35,0.98)
			sty_h.border_color=Color(minf(icor.r+0.25,1.0),minf(icor.g+0.25,1.0),minf(icor.b+0.25,1.0),1.0)
			for ssd2 in ["left","right","top","bottom"]: sty_h.set("border_width_"+ssd2,2)
			for ssc2 in ["top_left","top_right","bottom_left","bottom_right"]: sty_h.set("corner_radius_"+ssc2,9)
			sbtn.add_theme_stylebox_override("normal",sty_n)
			sbtn.add_theme_stylebox_override("hover",sty_h)
			sbtn.add_theme_stylebox_override("pressed",sty_h)
			sbtn.add_theme_stylebox_override("disabled",sty_n)
			sbtn.gui_input.connect(_slot_wheel_scroll)
			var itype : String = item.get("tipo","") as String
			var isd := Control.new(); isd.size=Vector2(SLOT_SZ,SLOT_SZ)
			isd.mouse_filter=Control.MOUSE_FILTER_IGNORE
			var ic := _item_cor
			var it := itype
			var isid := item.get("sid","") as String
			var ipid := item.get("pid","") as String
			var ibau := item.get("bau_id","") as String
			var ibau_qtd : int = int(item.get("qtd", 0))
			var sprite_key_i := _item_sprite_key_from_item(item)
			isd.draw.connect(func():
				var t2 := Time.get_ticks_msec() * 0.001
				var cx:=SLOT_SZ*0.5; var cy:=SLOT_SZ*0.42+sin(t2*1.1)*2.0
				if it=="bau":
					_draw_bau_icon(isd, ibau, ibau_qtd)
				elif it=="pet" and _draw_comandante_face(isd, ipid, _comandante_face_slot_rect(SLOT_SZ)):
					pass
				elif sprite_key_i != "" and _usar_sprite_item_na_mochila(item) and _draw_item_sprite(isd, sprite_key_i, Rect2(cx - 30.0, cy - 30.0, 60.0, 60.0)):
					pass
				elif it=="skin" and isid=="saberpunk":
					var rs2:=15.0; var sp2_vio:=Color(0.62,0.0,1.0)
					var pts_sp:=PackedVector2Array()
					for hii2 in range(6):
						var a_sp:=float(hii2)*TAU/6.0+PI/6.0+t2*0.15; pts_sp.append(Vector2(cx+cos(a_sp)*rs2,cy+sin(a_sp)*rs2))
					var brd_sp:=PackedVector2Array(pts_sp); brd_sp.append(pts_sp[0])
					var pa_sp := 0.72+sin(t2*2.2)*0.28
					isd.draw_polyline(brd_sp,Color(ic.r+0.1,ic.g+0.05,ic.b,pa_sp),1.8)
					for vi2 in range(6):
						var vc2:=sp2_vio if (vi2%2==0) else Color(ic.r+0.1,ic.g+0.1,ic.b+0.1)
						isd.draw_circle(pts_sp[vi2],2.5,Color(vc2.r,vc2.g,vc2.b,pa_sp))
					var rr2:=rs2*0.48+sin(t2*1.5)*1.0
					isd.draw_arc(Vector2(cx,cy),rr2,0.0,TAU,32,Color(sp2_vio.r,sp2_vio.g,sp2_vio.b,0.6+sin(t2*1.8)*0.2),1.4,true)
					for pi_sp in range(2):
						var oa2:=t2*2.0+float(pi_sp)*PI; var or_sp:=rs2*1.1
						var pc2:=sp2_vio if (pi_sp==0) else Color(ic.r+0.1,ic.g+0.1,ic.b+0.1)
						isd.draw_circle(Vector2(cx+cos(oa2-0.4)*or_sp,cy+sin(oa2-0.4)*or_sp),1.5,Color(sp2_vio.r,sp2_vio.g,sp2_vio.b,0.25))
						isd.draw_circle(Vector2(cx+cos(oa2)*or_sp,cy+sin(oa2)*or_sp),3.0,Color(pc2.r,pc2.g,pc2.b,0.92))
					var ang_sp:=-PI*0.38+sin(t2*0.65)*0.12; var cd_sp:=Vector2(cos(ang_sp),sin(ang_sp))
					var cl_sp:=cd_sp.rotated(PI/2.0)*2.2; var tip_sp:=Vector2(cx,cy)+cd_sp*17.0
					var g_sp:=PackedVector2Array([Vector2(cx,cy)-cl_sp*0.4,Vector2(cx,cy)+cl_sp*0.4,tip_sp+cl_sp*0.2,tip_sp-cl_sp*0.2])
					var gf_sp:=PackedColorArray(); for _gsp in range(4): gf_sp.append(Color(sp2_vio.r,sp2_vio.g,sp2_vio.b,0.95))
					isd.draw_polygon(g_sp,gf_sp)
					isd.draw_circle(tip_sp,2.5,Color(1.0,1.0,1.0,0.7+sin(t2*3.5)*0.3))
				elif it=="skin":
					var r2:=12.0
					var pts2:=PackedVector2Array()
					for hii in range(6):
						var a2:=float(hii)*TAU/6.0+PI/6.0+t2*0.18; pts2.append(Vector2(cx+cos(a2)*r2,cy+sin(a2)*r2))
					var f2:=PackedColorArray(); for _ff in range(6): f2.append(Color(ic.r*0.2,ic.g*0.2,ic.b*0.2,0.97))
					isd.draw_polygon(pts2,f2)
					var b2:=PackedVector2Array(pts2); b2.append(pts2[0])
					var pa2 := 0.78+sin(t2*2.2)*0.22
					isd.draw_polyline(b2,Color(ic.r+0.2,ic.g+0.18,ic.b,pa2),1.8)
					isd.draw_circle(Vector2(cx,cy),4.0,Color(ic.r+0.2,ic.g+0.2,ic.b,pa2))
					var ang2:=-PI*0.38+sin(t2*0.65)*0.12; var cd2:=Vector2(cos(ang2),sin(ang2))
					var cl2:=cd2.rotated(PI/2.0)*2.2; var tip2:=Vector2(cx,cy)+cd2*17.0
					var g2:=PackedVector2Array([Vector2(cx,cy)-cl2*0.4,Vector2(cx,cy)+cl2*0.4,tip2+cl2*0.2,tip2-cl2*0.2])
					var gf2:=PackedColorArray(); for _gg in range(4): gf2.append(Color(ic.r,ic.g,ic.b,0.95))
					isd.draw_polygon(g2,gf2)
					isd.draw_circle(tip2,3.0,Color(1.0,1.0,1.0,0.65+sin(t2*3.5)*0.35))
				elif it=="pet":
					match ipid:
						"nexus":
							var pts_nx:=PackedVector2Array()
							for i_nx in 8: var a_nx:=float(i_nx)*TAU/8.0+PI/8.0+t2*0.5; pts_nx.append(Vector2(cx+cos(a_nx)*20,cy+sin(a_nx)*20))
							var f_nx:=PackedColorArray(); for _x_nx in 8: f_nx.append(Color(0.18,0.09,0.03,0.95))
							isd.draw_polygon(pts_nx,f_nx)
							var br_nx:=PackedVector2Array(pts_nx); br_nx.append(pts_nx[0])
							isd.draw_polyline(br_nx,Color(ic.r,ic.g,ic.b,0.9),2.0)
							isd.draw_circle(Vector2(cx,cy),7.0+sin(t2*3.0)*2.0,Color(ic.r,ic.g,ic.b,0.85))
							isd.draw_circle(Vector2(cx,cy),3.5,Color(1.0,0.9,0.7,0.95))
						"phantom":
							var fa_ph:=0.55+sin(t2*2.5)*0.2
							var dp_ph:=PackedVector2Array([Vector2(cx,cy-22),Vector2(cx+18,cy),Vector2(cx,cy+18),Vector2(cx-18,cy)])
							var df_ph:=PackedColorArray(); for _x_ph in 4: df_ph.append(Color(0.12,0.04,0.2,fa_ph))
							isd.draw_polygon(dp_ph,df_ph)
							var db_ph:=PackedVector2Array(dp_ph); db_ph.append(dp_ph[0])
							isd.draw_polyline(db_ph,Color(ic.r,ic.g,ic.b,0.9),1.8)
							isd.draw_circle(Vector2(cx,cy),5.5,Color(0,0,0,0.9))
							isd.draw_circle(Vector2(cx,cy),4.0,Color(ic.r,ic.g,ic.b,0.95))
							isd.draw_arc(Vector2(cx,cy),24.0,0.0,TAU,32,Color(ic.r,ic.g,ic.b,0.12+sin(t2*2.0)*0.06),1.4)
						_:
							var s2:=1.2
							var b3:=Color(ic.r,ic.g,ic.b,0.9)
							isd.draw_rect(Rect2(cx-8*s2,cy-7*s2,16*s2,14*s2),Color(0.06,0.12,0.24,0.96))
							isd.draw_line(Vector2(cx-8*s2,cy-7*s2),Vector2(cx+8*s2,cy-7*s2),b3,2.0)
							isd.draw_line(Vector2(cx+8*s2,cy-7*s2),Vector2(cx+8*s2,cy+7*s2),b3,2.0)
							isd.draw_line(Vector2(cx+8*s2,cy+7*s2),Vector2(cx-8*s2,cy+7*s2),b3,2.0)
							isd.draw_line(Vector2(cx-8*s2,cy+7*s2),Vector2(cx-8*s2,cy-7*s2),b3,2.0)
							var sc2:=fmod(t2*22.0,14.0*s2)
							isd.draw_line(Vector2(cx-8*s2+1,cy-7*s2+sc2),Vector2(cx+8*s2-1,cy-7*s2+sc2),Color(ic.r,ic.g,ic.b,0.25),1.0)
							isd.draw_line(Vector2(cx,cy-7*s2),Vector2(cx,cy-13*s2),Color(0.45,0.85,1.0,0.8),1.8)
							isd.draw_circle(Vector2(cx,cy-14*s2),3.0,Color(ic.r,ic.g,ic.b,clampf(0.5+sin(t2*4.0)*0.5,0.1,1.0)))
				elif it=="arsenal":
					var slot_i : String = item.get("slot","") as String
					var rar_i : String = item.get("raridade","comum") as String
					var rc_i : Color = Salvar.arsenal_raridade_cor(rar_i)
					var pa_i := 0.72+sin(t2*2.0)*0.16
					isd.draw_circle(Vector2(cx,cy),20,Color(ic.r*0.12,ic.g*0.12,ic.b*0.12,0.9))
					isd.draw_arc(Vector2(cx,cy),20,0,TAU,44,Color(rc_i.r,rc_i.g,rc_i.b,pa_i),2.2,true)
					match slot_i:
						"canhao":
							isd.draw_rect(Rect2(cx-17,cy-5,32,10),Color(ic.r,ic.g,ic.b,0.35))
							isd.draw_rect(Rect2(cx-17,cy-5,32,10),Color(ic.r,ic.g,ic.b,0.92),false,2.0)
							isd.draw_circle(Vector2(cx-12,cy),7.5,Color(ic.r,ic.g,ic.b,0.62))
						"nucleo":
							isd.draw_circle(Vector2(cx,cy),9,Color(ic.r,ic.g,ic.b,0.82))
							isd.draw_arc(Vector2(cx,cy),15,0,TAU,32,Color(ic.r,ic.g,ic.b,0.42),2.0,true)
						"blindagem":
							var pts_ai:=PackedVector2Array([Vector2(cx,cy-21),Vector2(cx+17,cy-10),Vector2(cx+13,cy+13),Vector2(cx,cy+22),Vector2(cx-13,cy+13),Vector2(cx-17,cy-10)])
							isd.draw_colored_polygon(pts_ai,Color(ic.r*0.18,ic.g*0.18,ic.b*0.18,0.9))
							isd.draw_polyline(pts_ai+PackedVector2Array([pts_ai[0]]),Color(ic.r,ic.g,ic.b,0.92),2.0)
						_:
							var pts_bi:=PackedVector2Array([Vector2(cx,cy-22),Vector2(cx+18,cy),Vector2(cx,cy+22),Vector2(cx-18,cy)])
							isd.draw_colored_polygon(pts_bi,Color(ic.r*0.22,ic.g*0.10,ic.b*0.22,0.9))
							isd.draw_polyline(pts_bi+PackedVector2Array([pts_bi[0]]),Color(ic.r,ic.g,ic.b,0.92),2.0)
							isd.draw_circle(Vector2(cx,cy),5,Color(1.0,1.0,1.0,0.82))
				elif it=="cons":
					var inome_c : String = item.get("nome","") as String
					var pa_c := 0.75+sin(t2*2.0)*0.15
					if "Vela" in inome_c:
						isd.draw_circle(Vector2(cx,cy+10),11,Color(ic.r*0.3,ic.g*0.3,ic.b*0.1,0.4))
						var fl_c:=PackedVector2Array([Vector2(cx,cy-18),Vector2(cx-9,cy+6),Vector2(cx,cy),Vector2(cx+9,cy+6)])
						isd.draw_colored_polygon(fl_c,Color(ic.r,ic.g*0.7,0.1,0.95*pa_c))
						var fl2_c:=PackedVector2Array([Vector2(cx,cy-11),Vector2(cx-4,cy+2),Vector2(cx,cy-2),Vector2(cx+4,cy+2)])
						isd.draw_colored_polygon(fl2_c,Color(1.0,0.95,0.5,0.9*pa_c))
						isd.draw_rect(Rect2(cx-3,cy+11,6,10),Color(ic.r*0.4,ic.g*0.4,0.1,0.8*pa_c))
					elif "Orbe" in inome_c:
						isd.draw_circle(Vector2(cx,cy),18,Color(ic.r*0.15,ic.g*0.25,ic.b*0.15,0.9))
						isd.draw_arc(Vector2(cx,cy),18,0,TAU,40,Color(ic.r,ic.g,ic.b,pa_c),2.5)
						isd.draw_line(Vector2(cx,cy-11),Vector2(cx,cy+11),Color(ic.r+0.3,ic.g+0.2,ic.b+0.2,pa_c),3.5)
						isd.draw_line(Vector2(cx-11,cy),Vector2(cx+11,cy),Color(ic.r+0.3,ic.g+0.2,ic.b+0.2,pa_c),3.5)
					elif "Cristal" in inome_c:
						var pts_c:=PackedVector2Array()
						for _sci in range(6):
							var a_c:=_sci*TAU/6.0-PI*0.5
							pts_c.append(Vector2(cx+cos(a_c)*18,cy+sin(a_c)*18))
						isd.draw_colored_polygon(pts_c,Color(ic.r*0.15,ic.g*0.2,ic.b*0.3,0.9))
						isd.draw_polyline(pts_c+PackedVector2Array([pts_c[0]]),Color(ic.r,ic.g,ic.b,pa_c),2.5)
						isd.draw_arc(Vector2(cx,cy),9,0,TAU,24,Color(ic.r,ic.g,ic.b,0.4*pa_c),1.5)
					elif "Runa" in inome_c:
						var pts_r:=PackedVector2Array([Vector2(cx,cy-22),Vector2(cx+16,cy),Vector2(cx,cy+22),Vector2(cx-16,cy)])
						isd.draw_colored_polygon(pts_r,Color(ic.r*0.25,ic.g*0.08,ic.b*0.04,0.9))
						isd.draw_polyline(pts_r+PackedVector2Array([pts_r[0]]),Color(ic.r,ic.g*0.6,ic.b*0.2,pa_c),2.5)
						isd.draw_line(Vector2(cx-5,cy-8),Vector2(cx+3,cy),Color(1.0,0.9,0.3,pa_c),2.5)
						isd.draw_line(Vector2(cx+3,cy),Vector2(cx-3,cy+2),Color(1.0,0.9,0.3,pa_c),2.5)
						isd.draw_line(Vector2(cx-3,cy+2),Vector2(cx+5,cy+10),Color(1.0,0.9,0.3,pa_c),2.5)
					else:
						isd.draw_circle(Vector2(cx,cy),14,Color(ic.r*0.25,ic.g*0.25,ic.b*0.25,0.9))
						isd.draw_arc(Vector2(cx,cy),12,0,TAU,32,Color(ic.r,ic.g,ic.b,pa_c),2.5,true)
				else:
					var pa3 := 0.7+sin(t2*2.2)*0.15
					isd.draw_circle(Vector2(cx,cy),14.0,Color(ic.r*0.25,ic.g*0.25,ic.b*0.25,0.9))
					isd.draw_arc(Vector2(cx,cy),12.0,0.0,TAU,40,Color(ic.r,ic.g,ic.b,pa3),2.5,true)
					isd.draw_circle(Vector2(cx,cy),4.5,Color(ic.r+0.2,ic.g+0.2,ic.b+0.2,pa3))
			)
			_anim_nodes.append(isd)
			sbtn.add_child(isd)
			var inome : String = item.get("nome","") as String
			var short : String = inome.substr(0, 8) + ("." if inome.length()>8 else "")
			_inv_lbl(sbtn,short,0,SLOT_SZ-16,SLOT_SZ,16,(13 if _mob else 11),
				Color(icor.r+0.2,icor.g+0.2,icor.b+0.2,0.9),HORIZONTAL_ALIGNMENT_CENTER)
			var _ic := item.duplicate()
			sbtn.pressed.connect(func():
				if Time.get_ticks_msec() < _inventario_touch_suppress_tap_until:
					return
				_upd_slot.call(_ic)
			)
			if itype == "pet":
				var _plv_pid := item.get("pid","cyron") as String
				var _plv := Salvar.pet_nivel(_plv_pid)
				_inv_lbl(sbtn,"Nv.%d"%_plv,0,2,SLOT_SZ,14,(12 if _mob else 10),Color(icor.r+0.3,icor.g+0.3,icor.b+0.3,0.95),HORIZONTAL_ALIGNMENT_RIGHT)
			_slot_cont.add_child(sbtn)

	# â”€â”€ Chamada inicial e marcar TUDO ativo â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
	_rebuild_slots_wrap[0] = _rebuild_slots
	for _afbi_ini in _fbtns_wrap.size():
		var _afbd_ini : Array = _fbtns_wrap[_afbi_ini] as Array
		var _is_sel_ini : bool = (_filt_tipos[_afbi_ini] == _inventario_filtro_atual)
		(_afbd_ini[0] as Button).add_theme_stylebox_override("normal", _afbd_ini[2] if _is_sel_ini else _afbd_ini[1])
		(_afbd_ini[0] as Button).add_theme_color_override("font_color", Color(1.0,1.0,1.0,0.96) if _is_sel_ini else Color((_afbd_ini[3] as Color).r+0.18,(_afbd_ini[3] as Color).g+0.18,(_afbd_ini[3] as Color).b+0.18,0.86))
		if _afbd_ini.size() > 4 and is_instance_valid(_afbd_ini[4] as Control):
			(_afbd_ini[4] as Control).queue_redraw()
	_rebuild_slots.call(_inventario_filtro_atual)
	if not _inventario_reselect_item.is_empty():
		var _reselect_ref : Dictionary = _inventario_reselect_item.duplicate(true)
		_inventario_reselect_item.clear()
		var _reselect_found : Dictionary = {}
		var _reselect_tipo : String = str(_reselect_ref.get("tipo", ""))
		for _bag_raw in bag_items:
			var _bag_item : Dictionary = _bag_raw as Dictionary
			if str(_bag_item.get("tipo", "")) != _reselect_tipo:
				continue
			var _same_item : bool = false
			match _reselect_tipo:
				"bau":
					_same_item = str(_bag_item.get("bau_id", "")) == str(_reselect_ref.get("bau_id", ""))
				"skin":
					_same_item = str(_bag_item.get("sid", "")) == str(_reselect_ref.get("sid", ""))
				"pet":
					_same_item = str(_bag_item.get("pid", "")) == str(_reselect_ref.get("pid", ""))
				"hab":
					_same_item = str(_bag_item.get("hid", "")) == str(_reselect_ref.get("hid", ""))
				"cons":
					_same_item = str(_bag_item.get("cons_id", "")) == str(_reselect_ref.get("cons_id", ""))
				"arsenal":
					_same_item = str(_bag_item.get("arsenal_id", "")) == str(_reselect_ref.get("arsenal_id", ""))
				_:
					_same_item = str(_bag_item.get("nome", "")) == str(_reselect_ref.get("nome", ""))
			if _same_item:
				_reselect_found = _bag_item
				break
		if _reselect_found.is_empty():
			_reselect_found = _reselect_ref
		if upd_wrap[0]:
			upd_wrap[0].call(_reselect_found)

	var sep_bot:=ColorRect.new(); sep_bot.color=Color(1.0,0.82,0.1,0.15)
	sep_bot.position=Vector2(15,662); sep_bot.size=Vector2(vp.x-30,1)
	sep_bot.mouse_filter=Control.MOUSE_FILTER_IGNORE; ov.add_child(sep_bot)
	var bottom_gap : float = 12.0
	var bottom_total : float = minf(560.0, float(vp.x) - 36.0)
	var close_w : float = floor((bottom_total - bottom_gap) * 0.62)
	var arsenal_w : float = bottom_total - close_w - bottom_gap
	var bottom_x : float = (float(vp.x) - bottom_total) * 0.5
	var btn_f:=Button.new()
	btn_f.text="FECHAR"; btn_f.position=Vector2(bottom_x,668); btn_f.size=Vector2(close_w,48)
	btn_f.focus_mode=Control.FOCUS_NONE; btn_f.add_theme_font_size_override("font_size",22)
	var fsty:=StyleBoxFlat.new()
	fsty.bg_color=Color(0.06,0.06,0.10,0.92); fsty.border_color=Color(0.45,0.45,0.55,0.6)
	for s in ["left","right","top","bottom"]: fsty.set("border_width_"+s,1)
	for c in ["top_left","top_right","bottom_left","bottom_right"]: fsty.set("corner_radius_"+c,8)
	btn_f.add_theme_stylebox_override("normal",fsty)
	btn_f.add_theme_color_override("font_color",Color(0.7,0.7,0.75))
	btn_f.pressed.connect(_fechar_inventario)
	ov.add_child(btn_f)

	var btn_arsenal := Button.new()
	btn_arsenal.text = "ARSENAL"
	btn_arsenal.position = Vector2(bottom_x + close_w + bottom_gap, 668)
	btn_arsenal.size = Vector2(arsenal_w, 48)
	btn_arsenal.focus_mode = Control.FOCUS_NONE
	btn_arsenal.add_theme_font_size_override("font_size", 20 if arsenal_w >= 150.0 else 17)
	var asty := StyleBoxFlat.new()
	asty.bg_color = Color(_cmd_escura.r*0.75,_cmd_escura.g*0.75,_cmd_escura.b*0.75,0.94)
	asty.border_color = Color(_cmd_cor.r,_cmd_cor.g,_cmd_cor.b,0.62)
	for s2 in ["left","right","top","bottom"]: asty.set("border_width_"+s2,2)
	for c2 in ["top_left","top_right","bottom_left","bottom_right"]: asty.set("corner_radius_"+c2,8)
	var asty_on := asty.duplicate() as StyleBoxFlat
	asty_on.bg_color = Color(_cmd_cor.r*0.18,_cmd_cor.g*0.18,_cmd_cor.b*0.18,0.98)
	asty_on.border_color = Color(_cmd_cor.r+0.12,_cmd_cor.g+0.12,_cmd_cor.b+0.12,0.92)
	var asty_hover := asty_on.duplicate() as StyleBoxFlat
	asty_hover.bg_color = Color(_cmd_cor.r*0.24,_cmd_cor.g*0.24,_cmd_cor.b*0.24,0.98)
	btn_arsenal.add_theme_stylebox_override("normal", asty)
	btn_arsenal.add_theme_stylebox_override("hover", asty_hover)
	btn_arsenal.add_theme_stylebox_override("pressed", asty_on)
	btn_arsenal.add_theme_color_override("font_color", Color(_cmd_cor.r+0.18,_cmd_cor.g+0.18,_cmd_cor.b+0.18,0.9))
	var _set_arsenal_mode := func(_on: bool) -> void:
		_arsenal_mode[0] = _on
		_inventario_arsenal_aberto = _on
		arsenal_panel.visible = _on
		for _node in _normal_center_nodes:
			if _node is CanvasItem:
				(_node as CanvasItem).visible = not _on
		btn_arsenal.text = "VOLTAR" if _on else "ARSENAL"
		btn_arsenal.add_theme_stylebox_override("normal", asty_on if _on else asty)
		btn_arsenal.add_theme_color_override("font_color", Color(_cmd_cor.r+0.24,_cmd_cor.g+0.24,_cmd_cor.b+0.24,1.0) if _on else Color(_cmd_cor.r+0.18,_cmd_cor.g+0.18,_cmd_cor.b+0.18,0.9))
	btn_arsenal.pressed.connect(func():
		_set_arsenal_mode.call(not (_arsenal_mode[0] == true))
	)
	ov.add_child(btn_arsenal)
	if _arsenal_mode[0] == true:
		_set_arsenal_mode.call(true)
	_corrigir_textos_ui(ov)


func _abrir_loja(ui: CanvasLayer) -> void :
	if _loja_overlay:
		return
	if _menu_contents:
		_menu_contents.hide()
	_ui_ref = ui
	var _vp_loja:= get_viewport().get_visible_rect().size
	_loja_overlay = ColorRect.new()
	_loja_overlay.color = Color(0.0, 0.0, 0.0, 0.88)
	_loja_overlay.position = Vector2.ZERO
	_loja_overlay.size = _vp_loja
	ui.add_child(_loja_overlay)
	_rebuild_loja()

	if "saberpunk" in Salvar.skins_desbloqueadas:
		Som.saberpunk_resgatar()


func _rebuild_loja() -> void :

	var _scroll_y_salvo: float = 0.0
	if _loja_scroll_node and is_instance_valid(_loja_scroll_node):
		_scroll_y_salvo = float(_loja_scroll_node.scroll_vertical)

	if _loja_panel != null and is_instance_valid(_loja_panel):
		_loja_panel.queue_free()
	_loja_scroll_cont = null
	_loja_scroll_node = null


	var vp_w: float = get_viewport().get_visible_rect().size.x
	var is_mobile_loja : bool = OS.has_feature("android") or OS.has_feature("ios")
	var outer:= Panel.new()
	outer.position = Vector2.ZERO
	outer.size = Vector2(vp_w, 720)
	outer.mouse_filter = Control.MOUSE_FILTER_PASS
	var sty_o:= StyleBoxFlat.new()
	sty_o.bg_color = Color(0.04, 0.06, 0.1, 0.97)
	sty_o.border_color = Color(0.0, 0.0, 0.0, 0.0)
	for side in ["left", "right", "top", "bottom"]: sty_o.set("border_width_" + side, 0)
	outer.add_theme_stylebox_override("panel", sty_o)
	_ui_ref.add_child(outer)
	_loja_panel = outer


	var titulo:= Label.new()
	titulo.text = "LOJA PERMANENTE"
	titulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	titulo.position = Vector2(0, 8)
	titulo.size = Vector2(vp_w, 40)
	titulo.add_theme_font_size_override("font_size", 34)
	titulo.add_theme_color_override("font_color", Color(1.0, 0.85, 0.15))
	_ui_title_label(titulo, 4.0)
	outer.add_child(titulo)


	var lo:= Label.new()
	lo.text = ""
	lo.visible = false
	lo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lo.position = Vector2(0, 65)
	lo.size = Vector2(vp_w, 24)
	lo.add_theme_font_size_override("font_size", 22)
	lo.add_theme_color_override("font_color", Color(1.0, 0.88, 0.2))
	outer.add_child(lo)
	_add_currency_status(outer, Vector2(maxf(14.0, vp_w - 252.0), 54.0), true, 85)


	var loja_scroll_y : float = 116.0 if is_mobile_loja else 108.0
	var loja_bottom_h : float = 58.0
	var sep_topo:= ColorRect.new()
	sep_topo.color = Color(1.0, 0.85, 0.15, 0.22)
	sep_topo.position = Vector2(15, loja_scroll_y - 5.0)
	sep_topo.size = Vector2(vp_w - 30.0, 1)
	sep_topo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	outer.add_child(sep_topo)


	var scroll_h: float = 720.0 - loja_scroll_y - loja_bottom_h
	var scroll:= ScrollContainer.new()
	scroll.position = Vector2(0, loja_scroll_y)
	scroll.size = Vector2(vp_w, scroll_h)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	scroll.scroll_deadzone = 4
	outer.add_child(scroll)


	var cont_w: float = vp_w
	_loja_cont_w = cont_w
	var cont:= Control.new()
	cont.custom_minimum_size = Vector2(cont_w, 890)
	cont.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cont.mouse_filter = Control.MOUSE_FILTER_PASS
	scroll.add_child(cont)
	_loja_scroll_cont = cont
	_loja_scroll_node = scroll

	if _scroll_y_salvo > 0.0:
		scroll.call_deferred("set", "scroll_vertical", int(_scroll_y_salvo))

	var tipos:= Salvar.LOJA_INFO.keys()
	for i in range(tipos.size()):
		_criar_card_loja(tipos[i] as String, i)


	var sep_skins:= ColorRect.new()
	sep_skins.color = Color(1.0, 0.85, 0.15, 0.28)
	sep_skins.position = Vector2(15, 424)
	sep_skins.size = Vector2(_loja_cont_w - 30.0, 1)
	sep_skins.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cont.add_child(sep_skins)

	var skins_hdr:= Label.new()
	skins_hdr.text = "— SKINS DA TORRE —"
	skins_hdr.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	skins_hdr.position = Vector2(0, 432)
	skins_hdr.size = Vector2(_loja_cont_w, 34)
	skins_hdr.add_theme_font_size_override("font_size", 27)
	skins_hdr.add_theme_color_override("font_color", Color(1.0, 0.85, 0.15, 0.88))
	skins_hdr.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cont.add_child(skins_hdr)

	var skin_desc_lbl:= Label.new()
	skin_desc_lbl.text = "Skins alteram a aparência e dão um bônus permanente à torre"
	skin_desc_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	skin_desc_lbl.position = Vector2(0, 470)
	skin_desc_lbl.size = Vector2(_loja_cont_w, 26)
	skin_desc_lbl.add_theme_font_size_override("font_size", 21)
	skin_desc_lbl.add_theme_color_override("font_color", Color(0.5, 0.6, 0.65, 0.7))
	skin_desc_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cont.add_child(skin_desc_lbl)

	var skin_ids:= Salvar.SKINS_INFO.keys()
	var skin_idx: int = 0
	for si in range(skin_ids.size()):
		var sid: String = skin_ids[si] as String
		if sid == "saberpunk":
			continue
		if (Salvar.SKINS_INFO[sid] as Dictionary).get("premium", false) == true:
			continue
		_criar_card_skin(sid, skin_idx)
		skin_idx += 1


	var sep_habil:= ColorRect.new()
	sep_habil.color = Color(0.25, 0.95, 1.0, 0.28)
	sep_habil.position = Vector2(15, 762)
	sep_habil.size = Vector2(_loja_cont_w - 30.0, 1)
	sep_habil.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cont.add_child(sep_habil)

	var habil_hdr:= Label.new()
	habil_hdr.text = "— HABILIDADES ATIVAS —"
	habil_hdr.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	habil_hdr.position = Vector2(0, 770)
	habil_hdr.size = Vector2(_loja_cont_w, 34)
	habil_hdr.add_theme_font_size_override("font_size", 27)
	habil_hdr.add_theme_color_override("font_color", Color(0.25, 0.95, 1.0, 0.88))
	habil_hdr.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cont.add_child(habil_hdr)

	var habil_sub:= Label.new()
	habil_sub.text = "Cooldown compartilhado: 45s  •  Máx. 3 cargas por habilidade  •  Pago com cristais"
	habil_sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	habil_sub.position = Vector2(0, 808)
	habil_sub.size = Vector2(_loja_cont_w, 26)
	habil_sub.add_theme_font_size_override("font_size", 21)
	habil_sub.add_theme_color_override("font_color", Color(0.5, 0.65, 0.7, 0.7))
	habil_sub.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cont.add_child(habil_sub)

	var habil_ids:= Salvar.HABIL_INFO.keys()
	for hi in range(habil_ids.size()):
		_criar_card_habil(habil_ids[hi] as String, hi)


	var sep_cons:= ColorRect.new()
	sep_cons.color = Color(0.55, 1.0, 0.35, 0.28)
	sep_cons.position = Vector2(15, 1443)
	sep_cons.size = Vector2(_loja_cont_w - 30.0, 1)
	sep_cons.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cont.add_child(sep_cons)

	var cons_hdr:= Label.new()
	cons_hdr.text = "— ITENS CONSUMÍVEIS —"
	cons_hdr.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	cons_hdr.position = Vector2(0, 1451)
	cons_hdr.size = Vector2(_loja_cont_w, 34)
	cons_hdr.add_theme_font_size_override("font_size", 27)
	cons_hdr.add_theme_color_override("font_color", Color(0.55, 1.0, 0.35, 0.88))
	cons_hdr.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cont.add_child(cons_hdr)

	var cons_sub:= Label.new()
	cons_sub.text = "Consumíveis usados em partida  •  Pagos com ouro"
	cons_sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	cons_sub.position = Vector2(0, 1489)
	cons_sub.size = Vector2(_loja_cont_w, 26)
	cons_sub.add_theme_font_size_override("font_size", 14)
	cons_sub.add_theme_color_override("font_color", Color(0.5, 0.65, 0.5, 0.7))
	cons_sub.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cont.add_child(cons_sub)

	_criar_grid_consumiveis()

	var sep_beta:= ColorRect.new()
	sep_beta.color = Color(0.0, 1.0, 0.88, 0.3)
	sep_beta.position = Vector2(15, 1870)
	sep_beta.size = Vector2(_loja_cont_w - 30.0, 1)
	sep_beta.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cont.add_child(sep_beta)

	var beta_hdr:= Label.new()
	beta_hdr.text = "— BETA EXCLUSIVO —"
	beta_hdr.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	beta_hdr.position = Vector2(0, 1878)
	beta_hdr.size = Vector2(_loja_cont_w, 34)
	beta_hdr.add_theme_font_size_override("font_size", 30)
	beta_hdr.add_theme_color_override("font_color", Color(0.0, 1.0, 0.88, 0.95))
	beta_hdr.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cont.add_child(beta_hdr)

	var beta_sub:= Label.new()
	beta_sub.text = "Skin exclusiva para os primeiros 10 beta testadores  •  Gratuita  •  Permanente"
	beta_sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	beta_sub.position = Vector2(0, 1916)
	beta_sub.size = Vector2(_loja_cont_w, 26)
	beta_sub.add_theme_font_size_override("font_size", 20)
	beta_sub.add_theme_color_override("font_color", Color(0.4, 0.7, 0.65, 0.75))
	beta_sub.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cont.add_child(beta_sub)

	_criar_card_beta_skin()

	var sep_prem:= ColorRect.new()
	if SHOW_PREMIUM_PURCHASES:
		sep_prem.color = Color(1.0, 0.45, 0.95, 0.3)
		sep_prem.position = Vector2(15, 2320)
		sep_prem.size = Vector2(_loja_cont_w - 30.0, 1)
		sep_prem.mouse_filter = Control.MOUSE_FILTER_IGNORE
		cont.add_child(sep_prem)

		var prem_hdr:= Label.new()
		prem_hdr.text = "— ITENS PREMIUM —"
		prem_hdr.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		prem_hdr.position = Vector2(0, 2328)
		prem_hdr.size = Vector2(_loja_cont_w, 34)
		prem_hdr.add_theme_font_size_override("font_size", 28)
		prem_hdr.add_theme_color_override("font_color", Color(1.0, 0.45, 0.95, 0.95))
		prem_hdr.mouse_filter = Control.MOUSE_FILTER_IGNORE
		cont.add_child(prem_hdr)

		var prem_sub:= Label.new()
		prem_sub.text = "Pagos em dinheiro real. A compra será liberada quando Google Play Billing estiver conectado."
		prem_sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		prem_sub.position = Vector2(0, 2366)
		prem_sub.size = Vector2(_loja_cont_w, 26)
		prem_sub.add_theme_font_size_override("font_size", 18)
		prem_sub.add_theme_color_override("font_color", Color(0.75, 0.55, 0.78, 0.78))
		prem_sub.mouse_filter = Control.MOUSE_FILTER_IGNORE
		cont.add_child(prem_sub)

		_criar_grid_premium(2410.0)

	# â”€â”€ COMANDANTES â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
	var sep_ass:= ColorRect.new()
	sep_ass.color = Color(0.25, 0.65, 1.0, 0.28)
	sep_ass.position = Vector2(15, 1035)
	sep_ass.size = Vector2(_loja_cont_w - 30.0, 1)
	sep_ass.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cont.add_child(sep_ass)

	var ass_hdr:= Label.new()
	ass_hdr.text = "— COMANDANTES —"
	ass_hdr.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ass_hdr.position = Vector2(0, 1043)
	ass_hdr.size = Vector2(_loja_cont_w, 34)
	ass_hdr.add_theme_font_size_override("font_size", 27)
	ass_hdr.add_theme_color_override("font_color", Color(0.25, 0.65, 1.0, 0.88))
	ass_hdr.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cont.add_child(ass_hdr)

	var ass_sub:= Label.new()
	ass_sub.text = "Companheiros que atacam mobs e ativam habilidades especiais  •  Pagos com ouro"
	ass_sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ass_sub.position = Vector2(0, 1081)
	ass_sub.size = Vector2(_loja_cont_w, 26)
	ass_sub.add_theme_font_size_override("font_size", 19)
	ass_sub.add_theme_color_override("font_color", Color(0.45, 0.6, 0.75, 0.7))
	ass_sub.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cont.add_child(ass_sub)

	var pet_keys:= []
	for pk in Salvar.PETS_INFO.keys():
		var pet_id_k : String = pk as String
		if not ((Salvar.PETS_INFO[pet_id_k] as Dictionary).get("premium", false) == true):
			pet_keys.append(pet_id_k)
	for pi in range(pet_keys.size()):
		var pet_id_p : String = pet_keys[pi] as String
		if (Salvar.PETS_INFO[pet_id_p] as Dictionary).get("premium", false) == true:
			continue
		_criar_card_assistente(pet_id_p, pi, pet_keys.size())

	cont.custom_minimum_size = Vector2(cont_w, 2820 if SHOW_PREMIUM_PURCHASES else 2360)


	var sep_bot:= ColorRect.new()
	sep_bot.color = Color(1.0, 0.85, 0.15, 0.18)
	sep_bot.position = Vector2(15, 662)
	sep_bot.size = Vector2(vp_w - 30.0, 1)
	sep_bot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	outer.add_child(sep_bot)


	var btn:= Button.new()
	btn.text = "FECHAR"
	btn.position = Vector2((vp_w - 360.0) * 0.5, 664)
	btn.size = Vector2(360, 52)
	btn.focus_mode = Control.FOCUS_NONE
	btn.add_theme_font_size_override("font_size", 27)
	var sty:= StyleBoxFlat.new()
	sty.bg_color = Color(0.1, 0.1, 0.1, 0.9)
	sty.border_color = Color(0.4, 0.4, 0.4)
	for side in ["left", "right", "top", "bottom"]:
		sty.set("border_width_" + side, 2)
	for corner in ["top_left", "top_right", "bottom_left", "bottom_right"]:
		sty.set("corner_radius_" + corner, 8)
	btn.add_theme_stylebox_override("normal", sty)
	btn.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	btn.pressed.connect( func():
		Acessibilidade.processar("loja_fechar", "Fechar loja.", _fechar_loja))
	outer.add_child(btn)
	_corrigir_textos_ui(outer)


func _make_compra_reward(tipo: String, nome: String, qtd: int = 1, raridade: String = "raro", extra: Dictionary = {}) -> Dictionary:
	var item : Dictionary = extra.duplicate(true)
	item["tipo"] = tipo
	item["nome"] = nome
	item["qtd"] = max(1, qtd)
	item["raridade"] = raridade
	return item


func _reward_compra_upgrade(tipo: String) -> Dictionary:
	var info : Dictionary = Salvar.LOJA_INFO.get(tipo, {}) as Dictionary
	var nome : String = str(info.get("nome", tipo)).replace("\n", " ")
	var nivel : int = int(Salvar.melhorias.get(tipo, 0))
	var cor : Color = info.get("cor", Color(1.0, 0.78, 0.18)) as Color
	return _make_compra_reward("upgrade", "%s Nv.%d" % [nome, nivel], 1, "epico", {"upgrade_id": tipo, "cor": cor})


func _reward_compra_skin(skin_id: String, raridade: String = "lendario") -> Dictionary:
	var info : Dictionary = Salvar.SKINS_INFO.get(skin_id, {}) as Dictionary
	var nome : String = str(info.get("nome", skin_id))
	return _make_compra_reward("skin", nome, 1, raridade, {"sid": skin_id})


func _reward_compra_habil(hid: String) -> Dictionary:
	var info : Dictionary = Salvar.HABIL_INFO.get(hid, {}) as Dictionary
	var nome : String = str(info.get("nome", hid))
	return _make_compra_reward("habil", nome, 1, "raro", {"hid": hid})


func _reward_compra_cons(cons_id: String, nome: String, qtd: int = 1) -> Dictionary:
	return _make_compra_reward("cons", nome, qtd, "raro", {"cons_id": cons_id})


func _reward_compra_pet(pid: String) -> Dictionary:
	var info : Dictionary = Salvar.PETS_INFO.get(pid, {}) as Dictionary
	var nome : String = str(info.get("nome", pid))
	return _make_compra_reward("pet", nome, 1, "lendario", {"pid": pid})


func _snapshot_compra_premium() -> Dictionary:
	return {
		"ouro": Salvar.ouro_banco,
		"cristais": Salvar.cristais,
		"orbe": Salvar.orbe_cura_estoque,
		"cristal": Salvar.cristal_barreira_estoque,
		"runa": Salvar.runa_furia_estoque,
		"revive": Salvar.revive_loja_estoque,
	}


func _recompensas_premium_compra(id: String, antes: Dictionary) -> Array:
	var info : Dictionary = Salvar.PREMIUM_INFO.get(id, {}) as Dictionary
	var out : Array = []
	var tipo : String = str(info.get("tipo", ""))
	var unlock : String = str(info.get("unlock", ""))
	match tipo:
		"skin":
			out.append(_reward_compra_skin(unlock, "lendario"))
		"pet":
			out.append(_reward_compra_pet(unlock))
		"pack":
			var ouro_ganho : int = Salvar.ouro_banco - int(antes.get("ouro", Salvar.ouro_banco))
			var cristais_ganhos : int = Salvar.cristais - int(antes.get("cristais", Salvar.cristais))
			var orbe_ganho : int = Salvar.orbe_cura_estoque - int(antes.get("orbe", Salvar.orbe_cura_estoque))
			var cristal_ganho : int = Salvar.cristal_barreira_estoque - int(antes.get("cristal", Salvar.cristal_barreira_estoque))
			var runa_ganha : int = Salvar.runa_furia_estoque - int(antes.get("runa", Salvar.runa_furia_estoque))
			var revive_ganho : int = Salvar.revive_loja_estoque - int(antes.get("revive", Salvar.revive_loja_estoque))
			if ouro_ganho > 0:
				out.append(_make_compra_reward("ouro", "Cytron", ouro_ganho, "raro"))
			if cristais_ganhos > 0:
				out.append(_make_compra_reward("cristais", "Cristais", cristais_ganhos, "epico"))
			if orbe_ganho > 0:
				out.append(_reward_compra_cons("orbe", "Orbe de Cura", orbe_ganho))
			if cristal_ganho > 0:
				out.append(_reward_compra_cons("barreira", "Cristal Barreira", cristal_ganho))
			if runa_ganha > 0:
				out.append(_reward_compra_cons("runa", "Runa de Furia", runa_ganha))
			if revive_ganho > 0:
				out.append(_reward_compra_cons("vela", "Vela da Alma", revive_ganho))
	if out.is_empty():
		out.append(_make_compra_reward("ouro", str(info.get("nome", "Compra")), 1, "raro"))
	return out


func _mostrar_compra_bau(titulo: String, recompensas: Array, tier: String = "raro") -> void:
	if recompensas.is_empty() or not _ui_main or not is_instance_valid(_ui_main):
		_rebuild_loja()
		return
	_abrir_bau_grande(_ui_main, tier, func(): _rebuild_loja(), false, recompensas, titulo)


func _criar_card_loja(tipo: String, idx: int) -> void :
	var info: Dictionary = Salvar.LOJA_INFO[tipo] as Dictionary
	var cor: Color = info["cor"] as Color
	var lvl: int = Salvar.melhorias[tipo] as int
	var max_lvl: int = Salvar.MAX_LVL


	var n_loja: int = Salvar.LOJA_INFO.size()
	var tw_loja: float = float(n_loja) * 218.0 - 16.0
	var sx_loja: float = (_loja_cont_w - tw_loja) * 0.5
	var card:= Panel.new()
	card.position = Vector2(sx_loja + float(idx) * 218.0, 6)
	card.size = Vector2(202, 410)
	card.mouse_filter = Control.MOUSE_FILTER_PASS
	var sty:= StyleBoxFlat.new()
	sty.bg_color = Color(cor.r * 0.08, cor.g * 0.08, cor.b * 0.08, 0.95)
	sty.border_color = Color(cor.r, cor.g, cor.b, 0.9 if lvl > 0 else 0.55)
	for side in ["left", "right", "top", "bottom"]:
		sty.set("border_width_" + side, 2)
	for corner in ["top_left", "top_right", "bottom_left", "bottom_right"]:
		sty.set("corner_radius_" + corner, 10)
	card.add_theme_stylebox_override("panel", sty)
	_loja_scroll_cont.add_child(card)


	var lnome:= Label.new()
	lnome.text = info["nome"] as String
	lnome.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lnome.position = Vector2(0, 12)
	lnome.size = Vector2(202, 42)
	lnome.add_theme_font_size_override("font_size", 19)
	lnome.add_theme_color_override("font_color", cor)
	card.add_child(lnome)


	var dots:= ""
	for d in range(max_lvl):
		dots += "â—  " if d < lvl else "â—‹  "
	var ldots:= Label.new()
	ldots.text = dots.strip_edges()
	ldots.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ldots.position = Vector2(0, 56)
	ldots.size = Vector2(202, 39)
	ldots.add_theme_font_size_override("font_size", 21)
	ldots.add_theme_color_override("font_color", Color(cor.r, cor.g, cor.b, 0.9))
	card.add_child(ldots)


	var sep1:= ColorRect.new()
	sep1.color = Color(cor.r, cor.g, cor.b, 0.25)
	sep1.position = Vector2(20, 98)
	sep1.size = Vector2(162, 3)
	card.add_child(sep1)


	var ldesc:= Label.new()
	ldesc.text = info["desc"] as String
	ldesc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ldesc.autowrap_mode = TextServer.AUTOWRAP_WORD
	ldesc.position = Vector2(10, 103)
	ldesc.size = Vector2(182, 90)
	ldesc.add_theme_font_size_override("font_size", 17)
	ldesc.add_theme_color_override("font_color", Color(0.74, 0.78, 0.83))
	card.add_child(ldesc)


	var bonus:= Salvar.bonus_texto(tipo, lvl)
	if bonus != "":
		var lb:= Label.new()
		lb.text = bonus
		lb.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lb.position = Vector2(0, 198)
		lb.size = Vector2(202, 24)
		lb.add_theme_font_size_override("font_size", 16)
		lb.add_theme_color_override("font_color", Color(0.45, 0.95, 0.55))
		card.add_child(lb)


	var sep2:= ColorRect.new()
	sep2.color = Color(cor.r, cor.g, cor.b, 0.18)
	sep2.position = Vector2(20, 228)
	sep2.size = Vector2(162, 3)
	card.add_child(sep2)

	if lvl >= max_lvl:
		var lmax:= Label.new()
		lmax.text = "OK MAXIMO"
		lmax.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lmax.position = Vector2(0, 234)
		lmax.size = Vector2(202, 42)
		lmax.add_theme_font_size_override("font_size", 17)
		lmax.add_theme_color_override("font_color", Color(0.4, 0.92, 0.5, 0.9))
		card.add_child(lmax)
	else:
		var custos: Array = info["custos"] as Array
		var custo: int = custos[lvl] as int
		var pode = Salvar.ouro_banco >= custo

		var lcusto:= Label.new()
		lcusto.text = "Custo: %d ouro" % custo
		lcusto.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lcusto.position = Vector2(0, 234)
		lcusto.size = Vector2(202, 24)
		lcusto.add_theme_font_size_override("font_size", 16)
		lcusto.add_theme_color_override("font_color", 
				Color(1.0, 0.88, 0.12) if pode else Color(0.42, 0.42, 0.42))
		card.add_child(lcusto)

		var btn_c:= Button.new()
		btn_c.text = "COMPRAR"
		btn_c.position = Vector2(21, 264)
		btn_c.size = Vector2(160, 46)
		btn_c.focus_mode = Control.FOCUS_NONE
		btn_c.disabled = not pode
		btn_c.add_theme_font_size_override("font_size", 18)
		var sty_c:= StyleBoxFlat.new()
		if pode:
			sty_c.bg_color = Color(cor.r * 0.2, cor.g * 0.2, cor.b * 0.2, 0.92)
			sty_c.border_color = Color(cor.r, cor.g, cor.b, 0.85)
		else:
			sty_c.bg_color = Color(0.08, 0.08, 0.08, 0.7)
			sty_c.border_color = Color(0.28, 0.28, 0.28)
		for side in ["left", "right", "top", "bottom"]:
			sty_c.set("border_width_" + side, 2)
		for corner in ["top_left", "top_right", "bottom_left", "bottom_right"]:
			sty_c.set("corner_radius_" + corner, 8)
		btn_c.add_theme_stylebox_override("normal", sty_c)
		btn_c.add_theme_color_override("font_color", 
				Color(cor.r + 0.15, cor.g + 0.15, cor.b + 0.15) if pode else Color(0.35, 0.35, 0.35))
		var info_loja: Dictionary = Salvar.LOJA_INFO[tipo] as Dictionary
		var nome_loja: String = info_loja["nome"] as String
		var desc_loja: String = (info_loja["desc"] as String).replace("\n", " ")
		btn_c.pressed.connect( func() -> void :
			Acessibilidade.processar(
				"loja_" + tipo, 
				"%s â€” %s. Custo: %d ouro." % [nome_loja, desc_loja, custo], 
				func(): _comprar_upgrade(tipo)
			)
		)
		card.add_child(btn_c)


func _comprar_upgrade(tipo: String) -> void :
	if Salvar.comprar(tipo):
		var recompensas : Array = [_reward_compra_upgrade(tipo)]
		Som.upgrade()
		_mostrar_compra_bau("COMPRA REALIZADA", recompensas, "epico")


func _criar_card_skin(skin_id: String, idx: int) -> void :
	var info: Dictionary = Salvar.SKINS_INFO[skin_id] as Dictionary
	var cor: Color = info["cor"] as Color
	var nome: String = info["nome"] as String
	var desc: String = info["desc"] as String
	var custo: int = info["custo"] as int
	var desbloq: bool = skin_id in Salvar.skins_desbloqueadas
	var ativa: bool = Salvar.skin_ativa == skin_id
	var pode_c: bool = Salvar.pode_comprar_skin(skin_id)

	const CARD_W: float = 198.0
	const CARD_H: float = 248.0
	const GAP: float = 10.0
	var n: int = 0
	for _sidn in Salvar.SKINS_INFO.keys():
		if str(_sidn) == "saberpunk":
			continue
		if (Salvar.SKINS_INFO[str(_sidn)] as Dictionary).get("premium", false) == true:
			continue
		n += 1
	var tw: float = float(n) * (CARD_W + GAP) - GAP
	var sx: float = (_loja_cont_w - tw) * 0.5 + float(idx) * (CARD_W + GAP)


	var card:= Panel.new()
	card.position = Vector2(sx, 500)
	card.size = Vector2(CARD_W, CARD_H)
	card.mouse_filter = Control.MOUSE_FILTER_PASS
	var sty:= StyleBoxFlat.new()
	sty.bg_color = Color(cor.r * 0.13, cor.g * 0.13, cor.b * 0.13, 0.96) if desbloq else Color(0.04, 0.04, 0.07, 0.92)
	sty.border_color = Color(cor.r, cor.g, cor.b, 1.0) if ativa\
else (Color(cor.r * 0.6, cor.g * 0.6, cor.b * 0.6, 0.75) if desbloq\
else Color(0.2, 0.2, 0.24))
	for side in ["left", "right", "top", "bottom"]:
		sty.set("border_width_" + side, 3 if ativa else 1)
	for corner in ["top_left", "top_right", "bottom_left", "bottom_right"]:
		sty.set("corner_radius_" + corner, 9)
	card.add_theme_stylebox_override("panel", sty)
	_loja_scroll_cont.add_child(card)


	var lnome:= Label.new()
	lnome.text = nome
	lnome.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lnome.position = Vector2(0, 4)
	lnome.size = Vector2(CARD_W, 17)
	lnome.add_theme_font_size_override("font_size", 17)
	lnome.add_theme_color_override("font_color", 
		Color(cor.r + 0.25, cor.g + 0.25, cor.b + 0.25) if desbloq else Color(0.36, 0.36, 0.4))
	card.add_child(lnome)



	var prev_w:= 80.0
	var prev_h:= 62.0
	var prev:= Control.new()
	prev.position = Vector2((CARD_W - prev_w) * 0.5, 23)
	prev.size = Vector2(prev_w, prev_h)
	prev.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var cc:= cor
	var locked:= not desbloq
	prev.draw.connect( func():
		var cx:= prev_w * 0.5
		var cy:= prev_h * 0.5
		var r:= 14.0
		var am:= 0.45 if locked else 1.0
		if skin_id == "saberpunk":
			var tfx: float = Time.get_ticks_msec() * 0.001
			var cyan_sp: Color = Color(0.0, 1.0, 0.88)
			var mage_sp: Color = Color(0.88, 0.0, 1.0)
			for gi in range(5, 0, -1):
				var gc_sp: Color = cyan_sp if gi % 2 != 0 else mage_sp
				prev.draw_circle(Vector2(cx, cy), r + float(gi) * 4.0,
					Color(gc_sp.r, gc_sp.g, gc_sp.b, 0.05 * am / float(gi)))
			var pts_sp: PackedVector2Array = PackedVector2Array()
			for hi in range(6):
				var a_sp: float = float(hi) * TAU / 6.0 + PI / 6.0 + tfx * 0.35
				pts_sp.append(Vector2(cx + cos(a_sp) * r, cy + sin(a_sp) * r))
			var fills_sp: PackedColorArray = PackedColorArray()
			for _f in range(pts_sp.size()):
				fills_sp.append(Color(0.0, 0.12, 0.14, 0.97))
			prev.draw_polygon(pts_sp, fills_sp)
			var brd_sp: PackedVector2Array = PackedVector2Array(pts_sp)
			brd_sp.append(pts_sp[0])
			prev.draw_polyline(brd_sp, Color(mage_sp.r, mage_sp.g, mage_sp.b, 0.7 * am), 2.2)
			prev.draw_polyline(brd_sp, Color(cyan_sp.r, cyan_sp.g, cyan_sp.b, 0.95 * am), 1.4)
			prev.draw_circle(Vector2(cx, cy), 5.0, Color(cyan_sp.r, cyan_sp.g, cyan_sp.b, am))
			prev.draw_circle(Vector2(cx, cy), 2.5, Color(1.0, 1.0, 1.0, 0.9))
			var ang_sp: float = -PI * 0.38 + sin(tfx * 0.8) * 0.15
			var cdir_sp: Vector2 = Vector2(cos(ang_sp), sin(ang_sp))
			var clat_sp: Vector2 = cdir_sp.rotated(PI / 2.0) * 2.8
			var base_sp: Vector2 = Vector2(cx, cy)
			var tip_sp: Vector2 = base_sp + cdir_sp * 17.0
			var gun_sp: PackedVector2Array = PackedVector2Array([
				base_sp - clat_sp * 0.4, base_sp + clat_sp * 0.4,
				tip_sp + clat_sp * 0.12, tip_sp - clat_sp * 0.12,
			])
			var gf_sp: PackedColorArray = PackedColorArray()
			for _g in range(gun_sp.size()):
				gf_sp.append(Color(cyan_sp.r, cyan_sp.g, cyan_sp.b, 0.92 * am))
			prev.draw_polygon(gun_sp, gf_sp)
			prev.draw_circle(tip_sp, 3.2, Color(mage_sp.r, mage_sp.g, mage_sp.b, 0.9 * am))
			prev.draw_circle(tip_sp, 1.8, Color(1.0, 1.0, 1.0, 0.9 * am))
			if locked:
				var lx:= cx + 12.0; var ly:= cy + 10.0
				prev.draw_arc(Vector2(lx, ly - 4.0), 4.5, PI, TAU, 10,
					Color(0.65, 0.65, 0.65, 0.8), 1.8)
				prev.draw_rect(Rect2(lx - 4.5, ly - 1.0, 9.0, 7.0),
					Color(0.45, 0.45, 0.45, 0.7))
			return

		for gi in range(4, 0, -1):
			prev.draw_circle(Vector2(cx, cy), r + float(gi) * 4.0, 
				Color(cc.r, cc.g, cc.b, 0.06 * am / float(gi)))

		var pts:= PackedVector2Array()
		for hi in range(6):
			var a:= float(hi) * TAU / 6.0 + PI / 6.0
			pts.append(Vector2(cx + cos(a) * r, cy + sin(a) * r))
		var fills:= PackedColorArray()
		for _f in range(pts.size()):
			fills.append(Color(cc.r * 0.12, cc.g * 0.12, cc.b * 0.12, 0.95))
		prev.draw_polygon(pts, fills)

		var brd:= PackedVector2Array(pts);brd.append(pts[0])
		for bi in range(3, 0, -1):
			prev.draw_polyline(brd, Color(cc.r, cc.g, cc.b, 0.18 * am / float(bi)), float(bi) * 2.0)
		prev.draw_polyline(brd, Color(cc.r + 0.22, cc.g + 0.18, cc.b, am), 1.8)

		prev.draw_circle(Vector2(cx, cy), 4.5, Color(cc.r + 0.2, cc.g + 0.2, cc.b, am))

		var ang:= - PI * 0.38
		var cdir:= Vector2(cos(ang), sin(ang))
		var clat:= cdir.rotated(PI / 2.0) * 2.8
		var base:= Vector2(cx, cy)
		var tip:= base + cdir * 17.0
		var gun:= PackedVector2Array([
			base - clat * 0.4, base + clat * 0.4, 
			tip + clat * 0.12, tip - clat * 0.12, 
		])
		var gf:= PackedColorArray()
		for _g in range(gun.size()): gf.append(Color(cc.r, cc.g, cc.b, 0.92 * am))
		prev.draw_polygon(gun, gf)
		prev.draw_circle(tip, 3.2, Color(1.0, 1.0, 1.0, 0.85 * am))

		if locked:
			var lx:= cx + 12.0; var ly:= cy + 10.0
			prev.draw_arc(Vector2(lx, ly - 4.0), 4.5, PI, TAU, 10, 
				Color(0.65, 0.65, 0.65, 0.8), 1.8)
			prev.draw_rect(Rect2(lx - 4.5, ly - 1.0, 9.0, 7.0), 
				Color(0.45, 0.45, 0.45, 0.7))
	)
	card.add_child(prev)


	var ldesc:= Label.new()
	ldesc.text = desc
	ldesc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ldesc.autowrap_mode = TextServer.AUTOWRAP_WORD
	ldesc.position = Vector2(6, 88)
	ldesc.size = Vector2(CARD_W - 12, 100)
	ldesc.add_theme_font_size_override("font_size", 13)
	ldesc.add_theme_color_override("font_color",
		Color(0.62, 0.7, 0.76) if desbloq else Color(0.32, 0.34, 0.37))
	card.add_child(ldesc)


	var sep_i:= ColorRect.new()
	sep_i.color = Color(cor.r, cor.g, cor.b, 0.18 if desbloq else 0.07)
	sep_i.position = Vector2(12, 192)
	sep_i.size = Vector2(CARD_W - 24, 1)
	card.add_child(sep_i)

	var footer_status:= Label.new()
	footer_status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	footer_status.position = Vector2(0, 198)
	footer_status.size = Vector2(CARD_W, 16)
	footer_status.add_theme_font_size_override("font_size", 14)
	footer_status.add_theme_color_override("font_color",
		Color(cor.r + 0.16, cor.g + 0.16, cor.b + 0.16) if desbloq else (Color(1.0, 0.85, 0.12) if pode_c else Color(0.36, 0.36, 0.36)))
	footer_status.text = "No inventario" if desbloq else "%d ouro" % custo
	card.add_child(footer_status)

	var footer_btn:= _criar_btn_skin("COMPRADO" if desbloq else "COMPRAR", cor, pode_c or desbloq)
	footer_btn.position = Vector2(18, 216)
	footer_btn.size = Vector2(CARD_W - 36, 25)
	footer_btn.disabled = desbloq or not pode_c
	card.add_child(footer_btn)
	if not desbloq:
		var skin_desc_cp: String = "%s - %s. Custo: %d ouro." % [nome, desc, custo]
		footer_btn.pressed.connect( func():
			Acessibilidade.processar("skin_cp_" + skin_id, skin_desc_cp, func():
				if Salvar.comprar_skin(skin_id):
					var recompensas : Array = [_reward_compra_skin(skin_id, "lendario")]
					Som.upgrade()
					_mostrar_compra_bau("SKIN COMPRADA", recompensas, "lendario")
			)
		)


func _criar_card_habil(hid: String, idx: int) -> void :
	var info: Dictionary = Salvar.HABIL_INFO[hid] as Dictionary
	var cor: Color = info["cor"] as Color
	var nome: String = info["nome"] as String
	var custo: int = info["custo_cristal"] as int
	var cargas: int = Salvar.habil_cargas.get(hid, 0) as int
	var pode: bool = Salvar.cristais >= custo and cargas < 3

	const CARD_W: float = 340.0
	const CARD_H: float = 175.0
	const GAP: float = 12.0
	var n: int = Salvar.HABIL_INFO.size()
	var tw: float = float(n) * (CARD_W + GAP) - GAP
	var cx: float = (_loja_cont_w - tw) * 0.5 + float(idx) * (CARD_W + GAP)

	var card:= Panel.new()
	card.position = Vector2(cx, 848)
	card.size = Vector2(CARD_W, CARD_H)
	card.mouse_filter = Control.MOUSE_FILTER_PASS
	var sty:= StyleBoxFlat.new()
	sty.bg_color = Color(cor.r * 0.09, cor.g * 0.09, cor.b * 0.09, 0.97)
	sty.border_color = Color(cor.r, cor.g, cor.b, 0.9)
	for side in ["left", "right", "top", "bottom"]: sty.set("border_width_" + side, 2)
	for corner in ["top_left", "top_right", "bottom_left", "bottom_right"]: sty.set("corner_radius_" + corner, 10)
	card.add_theme_stylebox_override("panel", sty)
	_loja_scroll_cont.add_child(card)


	var icone_ctrl:= Control.new()
	icone_ctrl.position = Vector2(8, 8)
	icone_ctrl.size = Vector2(52, 78)
	icone_ctrl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(icone_ctrl)

	var ic_bg:= Panel.new()
	ic_bg.position = Vector2(0, 0)
	ic_bg.size = Vector2(52, 78)
	ic_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var ic_sty:= StyleBoxFlat.new()
	ic_sty.bg_color = Color(cor.r * 0.18, cor.g * 0.18, cor.b * 0.18, 0.95)
	ic_sty.border_color = Color(cor.r, cor.g, cor.b, 0.6)
	for s in ["left", "right", "top", "bottom"]: ic_sty.set("border_width_" + s, 1)
	for c in ["top_left", "top_right", "bottom_left", "bottom_right"]: ic_sty.set("corner_radius_" + c, 8)
	ic_bg.add_theme_stylebox_override("panel", ic_sty)
	icone_ctrl.add_child(ic_bg)

	var ic_colors_map: Dictionary = {
		"eletrico": Color(1.0, 0.92, 0.1), 
		"gelo": Color(0.35, 0.85, 1.0), 
		"devastador": Color(1.0, 0.45, 0.1), 
	}
	var ic_col: Color = ic_colors_map.get(hid, Color(0.85, 0.75, 1.0))
	var hid_cap: String = hid
	ic_bg.draw.connect( func():
		var ccx:= 26.0; var ccy:= 26.0
		match hid_cap:
			"eletrico":

				var pts:= PackedVector2Array([
					Vector2(30, 8), Vector2(20, 27), Vector2(25, 27), 
					Vector2(22, 45), Vector2(33, 27), Vector2(28, 27), 
				])
				ic_bg.draw_colored_polygon(pts, ic_col)
			"gelo":

				for ai in [0, 60, 120]:
					var ang:= deg_to_rad(float(ai))
					var gp1:= Vector2(ccx + cos(ang) * 17.0, ccy + sin(ang) * 17.0)
					var gp2:= Vector2(ccx - cos(ang) * 17.0, ccy - sin(ang) * 17.0)
					ic_bg.draw_line(gp1, gp2, ic_col, 2.5)
				ic_bg.draw_circle(Vector2(ccx, ccy), 4.0, ic_col)
			"devastador":

				var bpts:= PackedVector2Array()
				for bi in range(8):
					var ba:= deg_to_rad(float(bi) * 45.0 - 90.0)
					var br: float = 17.0 if bi % 2 == 0 else 7.0
					bpts.append(Vector2(ccx + cos(ba) * br, ccy + sin(ba) * br))
				ic_bg.draw_colored_polygon(bpts, ic_col)
			_:
				ic_bg.draw_circle(Vector2(ccx, ccy), 13.0, ic_col)
	)


	var lnome:= Label.new()
	lnome.text = nome.to_upper()
	lnome.position = Vector2(66, 6)
	lnome.size = Vector2(CARD_W - 70, 20)
	lnome.add_theme_font_size_override("font_size", 18)
	lnome.add_theme_color_override("font_color", Color(minf(cor.r + 0.3, 1.0), minf(cor.g + 0.3, 1.0), minf(cor.b + 0.3, 1.0)))
	lnome.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(lnome)


	for d in range(3):
		var bar:= Panel.new()
		bar.position = Vector2(66 + d * 74, 28)
		bar.size = Vector2(68, 18)
		var bsty:= StyleBoxFlat.new()
		bsty.bg_color = Color(cor.r, cor.g, cor.b, 0.85) if d < cargas else Color(0.12, 0.12, 0.14, 0.9)
		bsty.border_color = Color(cor.r, cor.g, cor.b, 0.5)
		for s in ["left", "right", "top", "bottom"]: bsty.set("border_width_" + s, 1)
		for c in ["top_left", "top_right", "bottom_left", "bottom_right"]: bsty.set("corner_radius_" + c, 3)
		bar.add_theme_stylebox_override("panel", bsty)
		bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
		card.add_child(bar)


	var lcargas:= Label.new()
	lcargas.text = "%d / 3 cargas" % cargas
	lcargas.position = Vector2(66, 42)
	lcargas.size = Vector2(160, 24)
	lcargas.add_theme_font_size_override("font_size", 14)
	lcargas.add_theme_color_override("font_color", 
		Color(0.45, 1.0, 0.55) if cargas == 3 else Color(0.6, 0.7, 0.8))
	lcargas.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(lcargas)


	var sep:= ColorRect.new()
	sep.color = Color(cor.r, cor.g, cor.b, 0.22)
	sep.position = Vector2(8, 66)
	sep.size = Vector2(CARD_W - 16, 1)
	sep.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(sep)


	var stats_txt: Dictionary = {
		"eletrico": ["Paralisa mobs: 1.8s", "Boss: imune", "Cooldown: 45s"], 
		"gelo": ["Reduz vel. 80% / 2.5s", "Boss: âˆ’40% vel.", "Cooldown: 45s"], 
		"devastador": ["Remove 35% HP atual", "Boss: âˆ’12% HP", "Cooldown: 45s"], 
	}
	var linhas: Array = stats_txt.get(hid, []) as Array
	var stat_cores: Array = [
		Color(minf(cor.r + 0.2, 1.0), minf(cor.g + 0.2, 1.0), minf(cor.b + 0.2, 1.0)), 
		Color(0.65, 0.65, 0.72), 
		Color(0.5, 0.5, 0.58), 
	]
	for li in range(linhas.size()):
		var ls:= Label.new()
		ls.text = linhas[li] as String
		ls.position = Vector2(10 + (li % 2) * 160, 72 + (li / 2) * 18)
		ls.size = Vector2(155, 24)
		ls.add_theme_font_size_override("font_size", 14)
		ls.add_theme_color_override("font_color", stat_cores[li])
		ls.mouse_filter = Control.MOUSE_FILTER_IGNORE
		card.add_child(ls)


	var sep2:= ColorRect.new()
	sep2.color = Color(cor.r, cor.g, cor.b, 0.15)
	sep2.position = Vector2(8, 110)
	sep2.size = Vector2(CARD_W - 16, 1)
	sep2.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(sep2)

	if cargas >= 3:
		var lfull:= Label.new()
		lfull.text = "CARGAS CHEIAS"
		lfull.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lfull.position = Vector2(0, 126)
		lfull.size = Vector2(CARD_W, 22)
		lfull.add_theme_font_size_override("font_size", 16)
		lfull.add_theme_color_override("font_color", Color(0.4, 0.92, 0.52))
		lfull.mouse_filter = Control.MOUSE_FILTER_IGNORE
		card.add_child(lfull)
	else:
		var lcusto:= Label.new()
		lcusto.text = "%d cristais / carga" % custo
		lcusto.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lcusto.position = Vector2(0, 114)
		lcusto.size = Vector2(CARD_W, 16)
		lcusto.add_theme_font_size_override("font_size", 14)
		lcusto.add_theme_color_override("font_color", 
			Color(0.55, 0.95, 1.0) if pode else Color(0.35, 0.35, 0.38))
		lcusto.mouse_filter = Control.MOUSE_FILTER_IGNORE
		card.add_child(lcusto)

		var bcmp:= Button.new()
		bcmp.text = "+ COMPRAR CARGA"
		bcmp.position = Vector2((CARD_W - 180.0) * 0.5, 132)
		bcmp.size = Vector2(180, 39)
		bcmp.focus_mode = Control.FOCUS_NONE
		bcmp.disabled = not pode
		bcmp.add_theme_font_size_override("font_size", 13)
		var bs:= StyleBoxFlat.new()
		bs.bg_color = Color(cor.r * 0.28, cor.g * 0.28, cor.b * 0.28, 0.92) if pode else Color(0.06, 0.06, 0.06, 0.75)
		bs.border_color = Color(cor.r, cor.g, cor.b, 0.85) if pode else Color(0.2, 0.2, 0.22)
		for s in ["left", "right", "top", "bottom"]: bs.set("border_width_" + s, 1)
		for c in ["top_left", "top_right", "bottom_left", "bottom_right"]: bs.set("corner_radius_" + c, 6)
		bcmp.add_theme_stylebox_override("normal", bs)
		bcmp.add_theme_color_override("font_color", 
			Color(minf(cor.r + 0.25, 1.0), minf(cor.g + 0.25, 1.0), minf(cor.b + 0.25, 1.0)) if pode else Color(0.26, 0.26, 0.26))
		var desc_h: String = (info["desc"] as String).replace("\n", " ")
		bcmp.pressed.connect( func():
			Acessibilidade.processar(
				"habil_carga_" + hid, 
				"%s â€” %s. Custo: %d cristais." % [info["nome"] as String, desc_h, custo], 
				func():
					if Salvar.comprar_carga_habil(hid):
						var recompensas : Array = [_reward_compra_habil(hid)]
						Som.upgrade()
						_mostrar_compra_bau("CARGA COMPRADA", recompensas, "raro")
			)
		)
		card.add_child(bcmp)


func _criar_btn_skin(txt: String, cor: Color, ativo: bool) -> Button:
	var btn:= Button.new()
	btn.text = txt
	btn.focus_mode = Control.FOCUS_NONE
	btn.add_theme_font_size_override("font_size", 15)
	var s:= StyleBoxFlat.new()
	s.bg_color = Color(cor.r * 0.22, cor.g * 0.22, cor.b * 0.22, 0.88) if ativo else Color(0.06, 0.06, 0.06, 0.75)
	s.border_color = Color(cor.r, cor.g, cor.b, 0.8) if ativo else Color(0.18, 0.18, 0.18)
	for side in ["left", "right", "top", "bottom"]: s.set("border_width_" + side, 1)
	for c in ["top_left", "top_right", "bottom_left", "bottom_right"]: s.set("corner_radius_" + c, 5)
	btn.add_theme_stylebox_override("normal", s)
	btn.add_theme_stylebox_override("disabled", s)
	var sh: StyleBoxFlat = s.duplicate()
	sh.bg_color = Color(cor.r * 0.38, cor.g * 0.38, cor.b * 0.38, 0.95) if ativo else s.bg_color
	btn.add_theme_stylebox_override("hover", sh)
	btn.add_theme_color_override("font_color", 
		Color(cor.r + 0.2, cor.g + 0.2, cor.b + 0.2) if ativo else Color(0.26, 0.26, 0.26))
	btn.add_theme_color_override("font_disabled_color",
		Color(cor.r + 0.15, cor.g + 0.15, cor.b + 0.15, 0.82) if ativo else Color(0.32, 0.32, 0.32, 0.75))
	return btn


func _criar_card_revive() -> void :
	var cor: Color = Color(0.55, 1.0, 0.35)
	var estoque: int = Salvar.revive_loja_estoque
	var cheio: bool = estoque >= Salvar.REVIVE_LOJA_MAX
	var ouro_ok: bool = Salvar.ouro_banco >= Salvar.REVIVE_LOJA_CUSTO

	var card:= Panel.new()
	card.position = Vector2((_loja_cont_w - 520.0) * 0.5, 1450)
	card.size = Vector2(520, 190)
	card.mouse_filter = Control.MOUSE_FILTER_PASS
	var sty:= StyleBoxFlat.new()
	sty.bg_color = Color(cor.r * 0.08, cor.g * 0.08, cor.b * 0.08, 0.95)
	sty.border_color = Color(cor.r, cor.g, cor.b, 0.85)
	for s in ["left", "right", "top", "bottom"]: sty.set("border_width_" + s, 2)
	for c in ["top_left", "top_right", "bottom_left", "bottom_right"]: sty.set("corner_radius_" + c, 10)
	card.add_theme_stylebox_override("panel", sty)
	_loja_scroll_cont.add_child(card)

	var nome_lbl:= Label.new()
	nome_lbl.text = "VELA DA ALMA"
	nome_lbl.position = Vector2(16, 12)
	nome_lbl.size = Vector2(300, 42)
	nome_lbl.add_theme_font_size_override("font_size", 21)
	nome_lbl.add_theme_color_override("font_color", Color(0.75, 1.0, 0.45))
	nome_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(nome_lbl)

	var estoque_lbl:= Label.new()
	estoque_lbl.text = "Estoque: %d / %d" % [estoque, Salvar.REVIVE_LOJA_MAX]
	estoque_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	estoque_lbl.position = Vector2(0, 12)
	estoque_lbl.size = Vector2(504, 42)
	estoque_lbl.add_theme_font_size_override("font_size", 17)
	estoque_lbl.add_theme_color_override("font_color", 
		Color(0.55, 1.0, 0.35) if not cheio else Color(0.45, 0.65, 0.35))
	estoque_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(estoque_lbl)

	var desc_lbl:= Label.new()
	desc_lbl.text = "Ao morrer, renasce com 35% de HP.\nUma vez por partida. Acumula com o revive da Alma (cristais)."
	desc_lbl.position = Vector2(16, 59)
	desc_lbl.size = Vector2(488, 66)
	desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD
	desc_lbl.add_theme_font_size_override("font_size", 14)
	desc_lbl.add_theme_color_override("font_color", Color(0.55, 0.72, 0.55))
	desc_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(desc_lbl)

	var btn:= Button.new()
	btn.text = "COMPRAR  —  %d ouro" % Salvar.REVIVE_LOJA_CUSTO if not cheio\
else "ESTOQUE CHEIO  (%d/%d)" % [estoque, Salvar.REVIVE_LOJA_MAX]
	btn.position = Vector2(16, 130)
	btn.size = Vector2(488, 51)
	btn.focus_mode = Control.FOCUS_NONE
	btn.disabled = cheio or not ouro_ok
	btn.add_theme_font_size_override("font_size", 16)
	var bsty:= StyleBoxFlat.new()
	var btn_ativo: bool = not cheio and ouro_ok
	bsty.bg_color = Color(0.1, 0.25, 0.1, 0.92) if btn_ativo else Color(0.08, 0.08, 0.08, 0.7)
	bsty.border_color = Color(0.45, 0.88, 0.25, 0.9) if btn_ativo else Color(0.3, 0.4, 0.25, 0.5)
	for s in ["left", "right", "top", "bottom"]: bsty.set("border_width_" + s, 1)
	for c in ["top_left", "top_right", "bottom_left", "bottom_right"]: bsty.set("corner_radius_" + c, 6)
	btn.add_theme_stylebox_override("normal", bsty)
	btn.add_theme_color_override("font_color", 
		Color(0.7, 1.0, 0.4) if btn_ativo else Color(0.4, 0.5, 0.35))
	btn.pressed.connect( func():
		if Salvar.comprar_revive_loja():
			_mostrar_compra_bau("CONSUMIVEL COMPRADO", [_reward_compra_cons("vela", "Vela da Alma")], "raro"))
	card.add_child(btn)


func _criar_grid_consumiveis() -> void:
	var itens := [
		{"nome": "VELA DA ALMA",       "cor": Color(0.55, 1.0, 0.35),  "custo": Salvar.REVIVE_LOJA_CUSTO,      "max": Salvar.REVIVE_LOJA_MAX,        "est": Salvar.revive_loja_estoque,      "desc": "Renasce com 35%% HP ao morrer.\n1 uso por partida.",                          "fn": func() -> bool: return Salvar.comprar_revive_loja(),       "icone": "vela"},
		{"nome": "ORBE DE CURA",        "cor": Color(0.2, 0.85, 0.45),  "custo": Salvar.ORBE_CURA_CUSTO,        "max": Salvar.ORBE_CURA_MAX,           "est": Salvar.orbe_cura_estoque,        "desc": "Restaura 50%% HP máximo\nao iniciar a partida.",                              "fn": func() -> bool: return Salvar.comprar_orbe_cura(),          "icone": "orbe"},
		{"nome": "CRISTAL DE BARREIRA", "cor": Color(0.3, 0.55, 1.0),   "custo": Salvar.CRISTAL_BARREIRA_CUSTO, "max": Salvar.CRISTAL_BARREIRA_MAX,    "est": Salvar.cristal_barreira_estoque, "desc": "Absorve o próximo golpe\nletal automaticamente.",                             "fn": func() -> bool: return Salvar.comprar_cristal_barreira(),   "icone": "escudo"},
		{"nome": "RUNA DE FÚRIA",       "cor": Color(1.0, 0.45, 0.1),   "custo": Salvar.RUNA_FURIA_CUSTO,       "max": Salvar.RUNA_FURIA_MAX,          "est": Salvar.runa_furia_estoque,       "desc": "+80%% dano por 3 waves.\nAtivar manualmente no HUD.",                        "fn": func() -> bool: return Salvar.comprar_runa_furia(),         "icone": "furia"},
	]

	var cw     : float = 270.0
	var ch     : float = 310.0
	var gap    : float = 12.0
	var cols   : int   = 4
	var row_w  : float = float(cols) * cw + float(cols - 1) * gap
	var ox     : float = (_loja_cont_w - row_w) * 0.5
	var oy     : float = 1530.0

	for i in itens.size():
		var item  : Dictionary = itens[i] as Dictionary
		var cor   : Color      = item["cor"] as Color
		var est   : int        = item["est"] as int
		var max_e : int        = item["max"] as int
		var custo : int        = item["custo"] as int
		var cheio : bool       = est >= max_e
		var ok    : bool       = Salvar.ouro_banco >= custo and not cheio
		var cx    : float      = ox + float(i) * (cw + gap)

		var card := Panel.new()
		card.position = Vector2(cx, oy)
		card.size     = Vector2(cw, ch)
		card.mouse_filter = Control.MOUSE_FILTER_PASS
		var sty := StyleBoxFlat.new()
		sty.bg_color     = Color(cor.r*0.07, cor.g*0.07, cor.b*0.07, 0.96)
		sty.border_color = Color(cor.r*0.8, cor.g*0.8, cor.b*0.8, 0.80)
		for s in ["left","right","top","bottom"]: sty.set("border_width_"+s, 2)
		for c2 in ["top_left","top_right","bottom_left","bottom_right"]: sty.set("corner_radius_"+c2, 10)
		card.add_theme_stylebox_override("panel", sty)
		_loja_scroll_cont.add_child(card)

		# Ícone procedural
		var icone := Control.new()
		icone.position     = Vector2((cw - 64.0) * 0.5, 10.0)
		icone.size         = Vector2(64.0, 64.0)
		icone.mouse_filter = Control.MOUSE_FILTER_IGNORE
		card.add_child(icone)
		var tipo_icone : String = item["icone"] as String
		icone.draw.connect(func():
			var f    := ThemeDB.fallback_font
			var ic   := Vector2(32.0, 32.0)
			var c3   : Color = cor
			match tipo_icone:
				"vela":
					# Chama: triângulo + halo
					icone.draw_circle(ic + Vector2(0, 10), 12, Color(c3.r*0.3, c3.g*0.3, c3.b*0.1, 0.4))
					var flame := PackedVector2Array([ic+Vector2(0,-22), ic+Vector2(-10,8), ic+Vector2(0,2), ic+Vector2(10,8)])
					icone.draw_colored_polygon(flame, Color(c3.r, c3.g*0.7, 0.1, 0.95))
					var flame2 := PackedVector2Array([ic+Vector2(0,-14), ic+Vector2(-5,4), ic+Vector2(0,-1), ic+Vector2(5,4)])
					icone.draw_colored_polygon(flame2, Color(1.0, 0.95, 0.5, 0.9))
					icone.draw_circle(ic + Vector2(0, 14), 8, Color(c3.r*0.2, c3.g*0.2, c3.b*0.1, 0.7))
					icone.draw_rect(Rect2(ic+Vector2(-4,14), Vector2(8,14)), Color(c3.r*0.4, c3.g*0.4, 0.1, 0.8))
				"orbe":
					# Orbe de cura: círculo + cruz
					icone.draw_circle(ic, 26, Color(c3.r*0.15, c3.g*0.25, c3.b*0.15, 0.9))
					icone.draw_arc(ic, 26, 0, TAU, 64, Color(c3.r, c3.g, c3.b, 0.9), 3.0)
					icone.draw_arc(ic, 20, 0, TAU, 64, Color(c3.r, c3.g, c3.b, 0.3), 1.0)
					icone.draw_line(ic+Vector2(0,-14), ic+Vector2(0,14), Color(c3.r+0.3,c3.g+0.2,c3.b+0.2,0.95), 4.0)
					icone.draw_line(ic+Vector2(-14,0), ic+Vector2(14,0), Color(c3.r+0.3,c3.g+0.2,c3.b+0.2,0.95), 4.0)
				"escudo":
					# Escudo: forma hexagonal achatada
					var pts := PackedVector2Array()
					for _si in range(6):
						var a : float = _si * TAU / 6.0 - PI * 0.5
						pts.append(ic + Vector2(cos(a), sin(a)) * 26.0)
					icone.draw_colored_polygon(pts, Color(c3.r*0.15, c3.g*0.2, c3.b*0.3, 0.9))
					icone.draw_polyline(pts + PackedVector2Array([pts[0]]), Color(c3.r, c3.g, c3.b, 0.9), 3.0)
					icone.draw_arc(ic, 14, 0, TAU, 48, Color(c3.r, c3.g, c3.b, 0.4), 1.5)
					icone.draw_string(f, ic+Vector2(-8, 7), "âœ¦", HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color(c3.r+0.3, c3.g+0.3, c3.b+0.3, 0.9))
				"furia":
					# Runa: losango com raio
					var pts2 := PackedVector2Array([ic+Vector2(0,-28), ic+Vector2(20,0), ic+Vector2(0,28), ic+Vector2(-20,0)])
					icone.draw_colored_polygon(pts2, Color(c3.r*0.25, c3.g*0.08, c3.b*0.04, 0.9))
					icone.draw_polyline(pts2 + PackedVector2Array([pts2[0]]), Color(c3.r, c3.g*0.6, c3.b*0.2, 0.9), 3.0)
					icone.draw_line(ic+Vector2(-6,-10), ic+Vector2(4,0),  Color(1.0,0.9,0.3,0.95), 3.0)
					icone.draw_line(ic+Vector2(4,0),    ic+Vector2(-4,2), Color(1.0,0.9,0.3,0.95), 3.0)
					icone.draw_line(ic+Vector2(-4,2),   ic+Vector2(6,12), Color(1.0,0.9,0.3,0.95), 3.0)
		)

		# Nome
		var nome_lbl := Label.new()
		nome_lbl.text = item["nome"] as String
		nome_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		nome_lbl.position = Vector2(0, 78); nome_lbl.size = Vector2(cw, 28)
		nome_lbl.add_theme_font_size_override("font_size", 13)
		nome_lbl.add_theme_color_override("font_color", Color(cor.r+0.2, cor.g+0.2, cor.b+0.1, 1.0))
		nome_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		card.add_child(nome_lbl)

		# Estoque
		var est_lbl := Label.new()
		est_lbl.text = "%d / %d" % [est, max_e]
		est_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		est_lbl.position = Vector2(0, 104); est_lbl.size = Vector2(cw, 22)
		est_lbl.add_theme_font_size_override("font_size", 13)
		est_lbl.add_theme_color_override("font_color", Color(cor.r, cor.g, cor.b, 0.6) if not cheio else Color(0.4,0.6,0.4))
		est_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		card.add_child(est_lbl)

		# Descrição
		var desc_lbl := Label.new()
		desc_lbl.text = item["desc"] as String
		desc_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD
		desc_lbl.position = Vector2(8, 128); desc_lbl.size = Vector2(cw - 16, 60)
		desc_lbl.add_theme_font_size_override("font_size", 12)
		desc_lbl.add_theme_color_override("font_color", Color(0.6, 0.72, 0.6))
		desc_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		card.add_child(desc_lbl)

		# Botão
		var btn := Button.new()
		btn.text = "%d ouro" % custo if not cheio else "CHEIO"
		btn.position = Vector2(8, 250); btn.size = Vector2(cw - 16, 48)
		btn.focus_mode = Control.FOCUS_NONE
		btn.disabled = not ok
		btn.add_theme_font_size_override("font_size", 13)
		var bsty := StyleBoxFlat.new()
		bsty.bg_color     = Color(cor.r*0.18, cor.g*0.25, cor.b*0.12, 0.92) if ok else Color(0.08,0.08,0.08,0.7)
		bsty.border_color = Color(cor.r*0.7, cor.g*0.9, cor.b*0.4, 0.85)    if ok else Color(0.3,0.35,0.25,0.5)
		for s in ["left","right","top","bottom"]: bsty.set("border_width_"+s, 1)
		for c2 in ["top_left","top_right","bottom_left","bottom_right"]: bsty.set("corner_radius_"+c2, 6)
		btn.add_theme_stylebox_override("normal", bsty)
		btn.add_theme_color_override("font_color", Color(cor.r+0.2, cor.g+0.3, cor.b+0.1) if ok else Color(0.4,0.5,0.35))
		var fn_c : Callable = item["fn"] as Callable
		var nome_compra : String = item["nome"] as String
		var cons_id_compra : String = tipo_icone
		if cons_id_compra == "escudo":
			cons_id_compra = "barreira"
		elif cons_id_compra == "furia":
			cons_id_compra = "runa"
		btn.pressed.connect(func():
			if fn_c.call():
				_mostrar_compra_bau("CONSUMIVEL COMPRADO", [_reward_compra_cons(cons_id_compra, nome_compra)], "raro"))
		card.add_child(btn)


func _criar_card_beta_skin() -> void :
	var cor: Color = Color(0.0, 1.0, 0.88)
	var ja_tem: bool = "saberpunk" in Salvar.skins_desbloqueadas
	var logado: bool = Salvar.nome_jogador != ""

	var card:= Panel.new()
	card.position = Vector2((_loja_cont_w - 700.0) * 0.5, 1950)
	card.size = Vector2(700, 300)
	card.mouse_filter = Control.MOUSE_FILTER_PASS
	var sty:= StyleBoxFlat.new()
	sty.bg_color = Color(0.0, 0.08, 0.1, 0.97)
	sty.border_color = Color(0.0, 1.0, 0.88, 1.0) if ja_tem else Color(0.0, 0.65, 0.55, 0.75)
	for s in ["left", "right", "top", "bottom"]: sty.set("border_width_" + s, 2 if ja_tem else 1)
	for c in ["top_left", "top_right", "bottom_left", "bottom_right"]: sty.set("corner_radius_" + c, 12)
	card.add_theme_stylebox_override("panel", sty)
	_loja_scroll_cont.add_child(card)


	var fx:= Control.new()
	fx.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	fx.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fx.z_index = 0
	var fx_t: float = 0.0
	var cyan:= Color(0.0, 1.0, 0.88)
	var mage:= Color(0.88, 0.0, 1.0)
	fx.draw.connect( func():
		var p: float = sin(fx_t * 2.2) * 0.25 + 0.75
		var pw: float = 700.0
		var ph: float = 220.0
		var cx3: float = pw * 0.5
		var cy3: float = ph * 0.5


		for gi in range(5, 0, -1):
			var gc: Color = cyan if gi % 2 != 0 else mage
			fx.draw_circle(Vector2(cx3, cy3), 
				60.0 + float(gi) * 28.0, 
				Color(gc.r, gc.g, gc.b, 0.022 * p / float(gi)))


		for pi2 in range(8):
			var pa: float = fx_t * 1.8 + float(pi2) * TAU / 8.0
			var pr: float = 55.0 + sin(fx_t * 2.5 + float(pi2)) * 8.0
			var pcor: Color = cyan if pi2 % 2 == 0 else mage
			fx.draw_circle(Vector2(cx3 + cos(pa) * pr, cy3 + sin(pa) * pr * 0.55), 
				3.0, Color(pcor.r, pcor.g, pcor.b, 0.75 * p))


		var r1: float = 45.0 + sin(fx_t * 3.0) * 5.0
		var r2: float = 65.0 + cos(fx_t * 2.2) * 6.0
		fx.draw_arc(Vector2(cx3, cy3), r1, 0.0, TAU, 64, 
			Color(cyan.r, cyan.g, cyan.b, 0.55 * p), 1.5)
		fx.draw_arc(Vector2(cx3, cy3), r2, fx_t, fx_t + TAU * 0.75, 64, 
			Color(mage.r, mage.g, mage.b, 0.4 * p), 1.2)


		for sl in range(2):
			var sy: float = cy3 + sin(fx_t * 4.0 + float(sl) * PI) * 28.0
			fx.draw_line(Vector2(cx3 - 42.0, sy), Vector2(cx3 + 42.0, sy), 
				Color(cyan.r, cyan.g, cyan.b, 0.18 * p), 1.0)


		var hpts:= PackedVector2Array()
		for hi in range(6):
			var ha: float = float(hi) * TAU / 6.0 + PI / 6.0
			hpts.append(Vector2(cx3 + cos(ha) * 36.0, cy3 + sin(ha) * 36.0))
		var hbrd:= PackedVector2Array(hpts);hbrd.append(hpts[0])
		for bi in range(3, 0, -1):
			fx.draw_polyline(hbrd, Color(mage.r, mage.g, mage.b, 0.35 / float(bi) * p), float(bi) * 3.0)
		fx.draw_polyline(hbrd, Color(cyan.r, cyan.g, cyan.b, 0.9), 1.8)


		fx.draw_circle(Vector2(cx3, cy3), 9.0, Color(mage.r, mage.g, mage.b, 0.6 * p))
		fx.draw_circle(Vector2(cx3, cy3), 5.5, Color(cyan.r, cyan.g, cyan.b, p))
		fx.draw_circle(Vector2(cx3, cy3), 2.5, Color(1.0, 1.0, 1.0, 0.9))


		var cang: float = fx_t * 0.9
		var cdir: Vector2 = Vector2(cos(cang), sin(cang))
		var clat: Vector2 = cdir.rotated(PI * 0.5) * 4.5
		var ctip: Vector2 = Vector2(cx3, cy3) + cdir * 48.0
		var base2: Vector2 = Vector2(cx3, cy3)
		var gun2:= PackedVector2Array([base2 - clat * 0.4, base2 + clat * 0.4, 
										ctip + clat * 0.15, ctip - clat * 0.15])
		var gcols:= PackedColorArray()
		for _gc in range(4): gcols.append(Color(cyan.r, cyan.g, cyan.b, 0.85 * p))
		fx.draw_polygon(gun2, gcols)
		fx.draw_circle(ctip, 5.5, Color(mage.r, mage.g, mage.b, 0.85 * p))
		fx.draw_circle(ctip, 3.0, Color(1.0, 1.0, 1.0, p))


		fx.draw_rect(Rect2(0, 0, pw, ph), 
			Color(cyan.r, cyan.g, cyan.b, 0.2 * p), false, 1.5 + p * 1.0)
	)
	var fx_timer:= Timer.new()
	fx_timer.wait_time = 0.033
	fx_timer.autostart = true
	fx_timer.timeout.connect( func():
		fx_t += 0.033
		fx.queue_redraw())
	fx.add_child(fx_timer)
	card.add_child(fx)


	var prev:= Control.new()
	prev.position = Vector2(18, 16)
	prev.size = Vector2(90, 135)
	prev.mouse_filter = Control.MOUSE_FILTER_IGNORE
	prev.draw.connect( func():
		var cx:= 45.0; var cy:= 45.0; var r:= 20.0
		var am: float = 1.0

		for gi in range(5, 0, -1):
			var gc: Color = Color(0.0, 1.0, 0.88, 0.07 / float(gi)) if gi % 2 == 0\
else Color(0.88, 0.0, 1.0, 0.05 / float(gi))
			prev.draw_circle(Vector2(cx, cy), r + float(gi) * 5.0, gc)

		var pts:= PackedVector2Array()
		for hi in range(6):
			var a:= float(hi) * TAU / 6.0 + PI / 6.0
			pts.append(Vector2(cx + cos(a) * r, cy + sin(a) * r))
		var fills:= PackedColorArray()
		for _f in range(pts.size()): fills.append(Color(0.0, 0.12, 0.14, 0.97))
		prev.draw_polygon(pts, fills)

		var brd:= PackedVector2Array(pts);brd.append(pts[0])
		prev.draw_polyline(brd, Color(0.88, 0.0, 1.0, 0.5), 3.5)
		prev.draw_polyline(brd, Color(0.0, 1.0, 0.88, am), 1.5)

		prev.draw_circle(Vector2(cx, cy), 5.0, Color(0.0, 1.0, 0.88, am))
		prev.draw_circle(Vector2(cx, cy), 2.5, Color(1.0, 1.0, 1.0, 0.9))

		var ang:= - PI * 0.38
		var cdir:= Vector2(cos(ang), sin(ang))
		var clat:= cdir.rotated(PI / 2.0) * 3.0
		var base:= Vector2(cx, cy); var tip:= base + cdir * 22.0
		var gun:= PackedVector2Array([base - clat * 0.4, base + clat * 0.4, tip + clat * 0.12, tip - clat * 0.12])
		var gf:= PackedColorArray();for _g in range(gun.size()): gf.append(Color(0.0, 1.0, 0.88, 0.95))
		prev.draw_polygon(gun, gf)
		prev.draw_circle(tip, 3.8, Color(0.88, 0.0, 1.0, 0.9))
	)
	card.add_child(prev)


	var nome_lbl:= Label.new()
	nome_lbl.text = "SaberPunk"
	nome_lbl.position = Vector2(120, 12)
	nome_lbl.size = Vector2(280, 48)
	nome_lbl.add_theme_font_size_override("font_size", 27)
	nome_lbl.add_theme_color_override("font_color", Color(0.0, 1.0, 0.88))
	nome_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(nome_lbl)

	var badge:= Label.new()
	badge.text = "BETA EXCLUSIVA"
	badge.position = Vector2(120, 62)
	badge.size = Vector2(200, 30)
	badge.add_theme_font_size_override("font_size", 13)
	badge.add_theme_color_override("font_color", Color(0.88, 0.0, 1.0, 0.9))
	badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(badge)


	var bonus_items: Array = [
		["âš”  +4% Dano", Color(0.0, 1.0, 0.88)], 
		["âš¡  +4% CadÃªncia", Color(0.0, 1.0, 0.88)], 
		["ðŸŽ¯  +4% Alcance", Color(0.0, 1.0, 0.88)], 
		["â™¥  +1 HP/s Regen", Color(0.55, 1.0, 0.55)], 
		["â˜…  +1% Score/kill", Color(1.0, 0.88, 0.2)], 
	]
	for bi in range(bonus_items.size()):
		var item: Array = bonus_items[bi]
		var bg:= ColorRect.new()
		bg.color = Color(0.0, 0.05, 0.08, 0.82)
		bg.position = Vector2(418, 8 + float(bi) * 22)
		bg.size = Vector2(268, 30)
		bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
		card.add_child(bg)
		var lbl:= Label.new()
		lbl.text = item[0] as String
		lbl.position = Vector2(422, 9 + float(bi) * 22)
		lbl.size = Vector2(260, 27)
		lbl.add_theme_font_size_override("font_size", 13)
		lbl.add_theme_color_override("font_color", item[1] as Color)
		lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		card.add_child(lbl)


	var restantes_lbl:= Label.new()
	restantes_lbl.text = "Consultando servidor..."
	restantes_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	restantes_lbl.position = Vector2(0, 159)
	restantes_lbl.size = Vector2(700, 33)
	restantes_lbl.add_theme_font_size_override("font_size", 15)
	restantes_lbl.add_theme_color_override("font_color", Color(0.5, 0.7, 0.65))
	restantes_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(restantes_lbl)


	var sep_c:= ColorRect.new()
	sep_c.color = Color(0.0, 1.0, 0.88, 0.15)
	sep_c.position = Vector2(16, 194)
	sep_c.size = Vector2(668, 2)
	sep_c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(sep_c)


	var _mk_sty_b:= func(bcor: Color, ativo: bool) -> StyleBoxFlat:
		var s:= StyleBoxFlat.new()
		s.bg_color = Color(bcor.r * (0.18 if ativo else 0.05), 
							   bcor.g * (0.18 if ativo else 0.05), 
							   bcor.b * (0.18 if ativo else 0.05), 0.95)
		s.border_color = Color(bcor.r, bcor.g, bcor.b, 0.95 if ativo else 0.35)
		for sd in ["left", "right", "top", "bottom"]: s.set("border_width_" + sd, 2)
		for cn in ["top_left", "top_right", "bottom_left", "bottom_right"]: s.set("corner_radius_" + cn, 8)
		return s

	var btn_principal:= Button.new()
	btn_principal.position = Vector2(16, 205)
	btn_principal.size = Vector2(380, 78)
	btn_principal.focus_mode = Control.FOCUS_NONE
	btn_principal.add_theme_font_size_override("font_size", 17)

	if ja_tem:
		var ativa: bool = Salvar.skin_ativa == "saberpunk"
		btn_principal.text = "EQUIPADA" if ativa else "EQUIPAR"
		btn_principal.add_theme_stylebox_override("normal", _mk_sty_b.call(cor, true))
		btn_principal.add_theme_color_override("font_color", Color(0.0, 1.0, 0.88))
		if not ativa:
			btn_principal.pressed.connect( func():
				Salvar.equipar_skin("saberpunk")
				_rebuild_loja())
	elif not logado:
		btn_principal.text = "FAÃ‡A LOGIN PARA RESGATAR"
		btn_principal.disabled = true
		btn_principal.add_theme_stylebox_override("normal", _mk_sty_b.call(cor, false))
		btn_principal.add_theme_color_override("font_color", Color(0.35, 0.55, 0.5))
	else:
		btn_principal.text = "RESGATAR GRATUITAMENTE"
		btn_principal.add_theme_stylebox_override("normal", _mk_sty_b.call(cor, true))
		btn_principal.add_theme_stylebox_override("hover", _mk_sty_b.call(Color(0.55, 1.0, 0.85), true))
		btn_principal.add_theme_color_override("font_color", Color(0.0, 1.0, 0.88))
		btn_principal.disabled = true
		btn_principal.pressed.connect( func():
			btn_principal.disabled = true
			btn_principal.text = "Resgatando..."
			RankingOnline.beta_resgatado.connect( func(ok: bool, erro: String):
				if ok:
					Som.saberpunk_resgatar()

					if not (Salvar.nome_jogador in _beta_donos_cache):
						_beta_donos_cache.append(Salvar.nome_jogador)
					_rebuild_loja()
				else:
					btn_principal.text = erro if erro != "" else "Sem amostras disponÃ­veis"
					btn_principal.disabled = true
			, CONNECT_ONE_SHOT)
			RankingOnline.resgatar_beta(Salvar.nome_jogador))
	card.add_child(btn_principal)


	var btn_lista:= Button.new()
	btn_lista.text = "VER BETA TESTADORES"
	btn_lista.position = Vector2(406, 205)
	btn_lista.size = Vector2(278, 78)
	btn_lista.focus_mode = Control.FOCUS_NONE
	btn_lista.add_theme_font_size_override("font_size", 14)
	btn_lista.add_theme_stylebox_override("normal", _mk_sty_b.call(Color(0.88, 0.0, 1.0), true))
	btn_lista.add_theme_stylebox_override("hover", _mk_sty_b.call(Color(1.0, 0.3, 1.0), true))
	btn_lista.add_theme_color_override("font_color", Color(0.88, 0.55, 1.0))
	btn_lista.pressed.connect( func(): _abrir_painel_beta_donos())
	card.add_child(btn_lista)


	if _on_beta_info_loja.is_valid() and RankingOnline.beta_info_recebida.is_connected(_on_beta_info_loja):
		RankingOnline.beta_info_recebida.disconnect(_on_beta_info_loja)
	_on_beta_info_loja = func(restantes: int, _donos: Array):
		restantes_lbl.text = "%d de %d amostras disponÃ­veis" % [restantes, RankingOnline._BETA_MAX]
		restantes_lbl.add_theme_color_override("font_color", 
			Color(0.0, 1.0, 0.6) if restantes > 0 else Color(0.8, 0.25, 0.25))
		if not ja_tem and logado:
			btn_principal.disabled = restantes <= 0
	RankingOnline.beta_info_recebida.connect(_on_beta_info_loja, CONNECT_ONE_SHOT)
	RankingOnline.buscar_info_beta()


var _on_beta_info_loja: Callable = Callable()
var _beta_donos_cache: Array = []


func _abrir_painel_beta_donos() -> void :
	var vp:= get_viewport().get_visible_rect().size
	var ov:= ColorRect.new()
	ov.color = Color(0.0, 0.0, 0.0, 0.88)
	ov.position = Vector2.ZERO
	ov.size = vp
	ov.z_index = 50
	ov.mouse_filter = Control.MOUSE_FILTER_STOP

	if _loja_panel and is_instance_valid(_loja_panel):
		_loja_panel.get_parent().add_child(ov)
	else:
		return

	var pnl:= Panel.new()
	pnl.position = Vector2((vp.x - 460.0) * 0.5, (vp.y - 500.0) * 0.5)
	pnl.size = Vector2(460, 500)
	pnl.mouse_filter = Control.MOUSE_FILTER_STOP
	var psty:= StyleBoxFlat.new()
	psty.bg_color = Color(0.0, 0.06, 0.1, 0.98)
	psty.border_color = Color(0.0, 1.0, 0.88, 0.9)
	for s in ["left", "right", "top", "bottom"]: psty.set("border_width_" + s, 2)
	for c in ["top_left", "top_right", "bottom_left", "bottom_right"]: psty.set("corner_radius_" + c, 14)
	pnl.add_theme_stylebox_override("panel", psty)
	ov.add_child(pnl)

	var tit:= Label.new()
	tit.text = "BETA TESTADORES"
	tit.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tit.position = Vector2(0, 18)
	tit.size = Vector2(460, 48)
	tit.add_theme_font_size_override("font_size", 33)
	tit.add_theme_color_override("font_color", Color(0.0, 1.0, 0.88))
	tit.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pnl.add_child(tit)

	var sub:= Label.new()
	sub.text = "Skin SaberPunk â€” Exclusiva"
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.position = Vector2(0, 52)
	sub.size = Vector2(460, 27)
	sub.add_theme_font_size_override("font_size", 20)
	sub.add_theme_color_override("font_color", Color(0.88, 0.0, 1.0, 0.8))
	sub.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pnl.add_child(sub)

	var sep:= ColorRect.new()
	sep.color = Color(0.0, 1.0, 0.88, 0.25)
	sep.position = Vector2(20, 76);sep.size = Vector2(420, 2)
	sep.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pnl.add_child(sep)

	var scroll:= ScrollContainer.new()
	scroll.position = Vector2(20, 84)
	scroll.size = Vector2(420, 360)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	scroll.mouse_filter = Control.MOUSE_FILTER_STOP
	pnl.add_child(scroll)

	var lista_cont:= VBoxContainer.new()
	lista_cont.custom_minimum_size = Vector2(400, 0)
	lista_cont.mouse_filter = Control.MOUSE_FILTER_IGNORE
	scroll.add_child(lista_cont)

	var _preencher_lista:= func(donos: Array):
		for child in lista_cont.get_children(): child.queue_free()
		if donos.is_empty():
			var vazio:= Label.new()
			vazio.text = "Nenhuma amostra resgatada ainda."
			vazio.add_theme_font_size_override("font_size", 21)
			vazio.add_theme_color_override("font_color", Color(0.4, 0.55, 0.5))
			lista_cont.add_child(vazio)
			return
		for i in range(donos.size()):
			var row:= Label.new()
			row.text = "#%d  %s" % [i + 1, donos[i] as String]
			row.custom_minimum_size = Vector2(400, 32)
			row.add_theme_font_size_override("font_size", 24)
			row.add_theme_color_override("font_color", 
				Color(0.0, 1.0, 0.88) if i == 0 else Color(0.65, 0.88, 0.82))
			lista_cont.add_child(row)


	if not _beta_donos_cache.is_empty():
		_preencher_lista.call(_beta_donos_cache)
	else:
		var carregando:= Label.new()
		carregando.text = "Carregando..."
		carregando.add_theme_font_size_override("font_size", 21)
		carregando.add_theme_color_override("font_color", Color(0.5, 0.7, 0.65))
		lista_cont.add_child(carregando)
		RankingOnline.beta_info_recebida.connect( func(restantes: int, donos: Array):
			_beta_donos_cache = donos
			_preencher_lista.call(donos)
			var cnt_lbl:= sub
			cnt_lbl.text = "Skin SaberPunk  â€¢  %d/%d amostras resgatadas" %\
[donos.size(), RankingOnline._BETA_MAX]
		, CONNECT_ONE_SHOT)
		RankingOnline.buscar_info_beta()

	var btn_fechar:= Button.new()
	btn_fechar.text = "FECHAR"
	btn_fechar.position = Vector2(130, 454)
	btn_fechar.size = Vector2(200, 54)
	btn_fechar.focus_mode = Control.FOCUS_NONE
	btn_fechar.add_theme_font_size_override("font_size", 22)
	var bsty:= StyleBoxFlat.new()
	bsty.bg_color = Color(0.05, 0.05, 0.07, 0.9)
	bsty.border_color = Color(0.3, 0.3, 0.35)
	for s in ["left", "right", "top", "bottom"]: bsty.set("border_width_" + s, 1)
	for c in ["top_left", "top_right", "bottom_left", "bottom_right"]: bsty.set("corner_radius_" + c, 8)
	btn_fechar.add_theme_stylebox_override("normal", bsty)
	btn_fechar.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
	btn_fechar.pressed.connect( func(): ov.queue_free())
	pnl.add_child(btn_fechar)


func _criar_grid_premium(base_y: float) -> void:
	var ids : Array = Salvar.PREMIUM_INFO.keys()
	var cols : int = 4
	var card_w : float = 242.0
	var card_h : float = 176.0
	var gap : float = 14.0
	var total_w : float = float(cols) * card_w + float(cols - 1) * gap
	var sx : float = maxf(18.0, (_loja_cont_w - total_w) * 0.5)
	for i in range(ids.size()):
		var col : int = i % cols
		var row : int = i / cols
		_criar_card_premium(ids[i] as String, Vector2(sx + float(col) * (card_w + gap), base_y + float(row) * (card_h + gap)), Vector2(card_w, card_h))


func _criar_card_premium(id: String, pos: Vector2, sz: Vector2) -> void:
	var info : Dictionary = Salvar.PREMIUM_INFO[id] as Dictionary
	var cor : Color = info.get("cor", Color(1.0, 0.45, 0.95)) as Color
	var comprado : bool = Salvar.premium_ja_comprado(id)
	var card := Panel.new()
	card.position = pos
	card.size = sz
	card.mouse_filter = Control.MOUSE_FILTER_PASS
	var sty := StyleBoxFlat.new()
	sty.bg_color = Color(cor.r * 0.10, cor.g * 0.10, cor.b * 0.10, 0.96)
	sty.border_color = Color(cor.r, cor.g, cor.b, 0.95 if comprado else 0.58)
	for side in ["left", "right", "top", "bottom"]: sty.set("border_width_" + side, 2 if comprado else 1)
	for corner in ["top_left", "top_right", "bottom_left", "bottom_right"]: sty.set("corner_radius_" + corner, 8)
	card.add_theme_stylebox_override("panel", sty)
	_loja_scroll_cont.add_child(card)
	var nome := Label.new()
	nome.text = str(info.get("nome", id))
	nome.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	nome.position = Vector2(8, 8)
	nome.size = Vector2(sz.x - 16.0, 24)
	nome.add_theme_font_size_override("font_size", 18)
	nome.add_theme_color_override("font_color", Color(cor.r + 0.18, cor.g + 0.12, cor.b + 0.18, 1.0))
	card.add_child(nome)
	var preco := Label.new()
	preco.text = str(info.get("preco", ""))
	preco.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	preco.position = Vector2(8, 34)
	preco.size = Vector2(sz.x - 16.0, 22)
	preco.add_theme_font_size_override("font_size", 17)
	preco.add_theme_color_override("font_color", Color(1.0, 0.86, 0.22))
	card.add_child(preco)
	var desc := Label.new()
	desc.text = str(info.get("desc", ""))
	desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD
	desc.position = Vector2(12, 62)
	desc.size = Vector2(sz.x - 24.0, 58)
	desc.add_theme_font_size_override("font_size", 13)
	desc.add_theme_color_override("font_color", Color(0.70, 0.74, 0.82))
	card.add_child(desc)
	var btn := Button.new()
	btn.text = "ADQUIRIDO" if comprado else "COMPRAR"
	btn.position = Vector2(22, sz.y - 46.0)
	btn.size = Vector2(sz.x - 44.0, 34)
	btn.focus_mode = Control.FOCUS_NONE
	btn.disabled = comprado
	btn.add_theme_font_size_override("font_size", 16)
	var bst := StyleBoxFlat.new()
	bst.bg_color = Color(cor.r * 0.20, cor.g * 0.16, cor.b * 0.22, 0.95) if not comprado else Color(0.08, 0.14, 0.10, 0.92)
	bst.border_color = Color(cor.r, cor.g, cor.b, 0.85) if not comprado else Color(0.3, 0.95, 0.55, 0.75)
	for side in ["left", "right", "top", "bottom"]: bst.set("border_width_" + side, 2)
	for corner in ["top_left", "top_right", "bottom_left", "bottom_right"]: bst.set("corner_radius_" + corner, 7)
	btn.add_theme_stylebox_override("normal", bst)
	btn.add_theme_stylebox_override("disabled", bst)
	btn.add_theme_color_override("font_color", Color(1.0, 0.82, 1.0) if not comprado else Color(0.55, 1.0, 0.7))
	var produto : String = str(info.get("produto", id))
	btn.pressed.connect(func(): _solicitar_compra_premium(id, produto))
	card.add_child(btn)


func _solicitar_compra_premium(id: String, produto: String) -> void:
	var info : Dictionary = Salvar.PREMIUM_INFO.get(id, {}) as Dictionary
	var nome : String = str(info.get("nome", id))
	var preco : String = str(info.get("preco", ""))
	if DEBUG_PREMIUM_TEST_PURCHASES:
		var antes : Dictionary = _snapshot_compra_premium()
		if Salvar.liberar_premium(id):
			Som.upgrade()
			RankingOnline.upload_save(Salvar.nome_jogador, Salvar.exportar_cloud())
			_mostrar_compra_bau("COMPRA TESTE", _recompensas_premium_compra(id, antes), "lendario")
		return
	OS.alert("Compra premium ainda nao esta conectada ao Google Play Billing.\n\nProduto: %s\nID: %s\nPreco: %s" % [nome, produto, preco], "Cyron Defense")


func _criar_card_assistente(pid: String, idx: int, total: int) -> void :
	var info: Dictionary = Salvar.PETS_INFO.get(pid, {}) as Dictionary
	if info.is_empty(): return
	var cor: Color = info.get("cor", Color(0.25,0.65,1.0)) as Color
	var nome: String = str(info.get("nome", pid))
	var desc: String = str(info.get("desc", ""))
	var custo: int = int(info.get("custo", 0))
	var stats_pet : Dictionary = Salvar.pet_stats(pid)
	var dano: float = float(stats_pet.get("dano", info.get("dano", 0.0)))
	var vel: float = float(stats_pet.get("vel", info.get("vel", 0.0)))
	var alcance: float = float(stats_pet.get("alcance", info.get("alcance", 0.0)))
	var hab_nome: String = str(info.get("hab_nome", ""))
	var hab_cd: float = float(stats_pet.get("hab_cd", info.get("hab_cd", 0.0)))
	var all_pets: Array = Array(Salvar.pets_desbloqueados)
	if Salvar.pet_ia_comprado and not ("cyron" in all_pets): all_pets.append("cyron")
	var ja_tem: bool = pid in all_pets
	var pode_c: bool = Salvar.ouro_banco >= custo
	var ativo: bool = ja_tem and str(Salvar.pet_ativo) == pid

	const CARD_W: float = 300.0
	const CARD_H: float = 310.0
	const GAP: float = 16.0
	var tw: float = float(total) * (CARD_W + GAP) - GAP
	var sx: float = (_loja_cont_w - tw) * 0.5 + float(idx) * (CARD_W + GAP)

	var card:= Panel.new()
	card.position = Vector2(sx, 1113)
	card.size = Vector2(CARD_W, CARD_H)
	card.mouse_filter = Control.MOUSE_FILTER_PASS
	var sty:= StyleBoxFlat.new()
	sty.bg_color = Color(cor.r*0.1, cor.g*0.1, cor.b*0.1, 0.96) if ja_tem else Color(0.04,0.04,0.07,0.92)
	sty.border_color = Color(cor.r, cor.g, cor.b, 1.0) if ativo else (Color(cor.r*0.65,cor.g*0.65,cor.b*0.65,0.75) if ja_tem else Color(0.2,0.2,0.25))
	for sd in ["left","right","top","bottom"]: sty.set("border_width_"+sd, 3 if ativo else 1)
	for cc in ["top_left","top_right","bottom_left","bottom_right"]: sty.set("corner_radius_"+cc, 10)
	card.add_theme_stylebox_override("panel", sty)
	_loja_scroll_cont.add_child(card)

	var lnome:= Label.new()
	var _lv_sfx : String = ("  Nv." + str(Salvar.pet_nivel(pid))) if ja_tem else ""
	lnome.text = nome.to_upper() + _lv_sfx
	lnome.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lnome.position = Vector2(0, 10)
	lnome.size = Vector2(CARD_W, 28)
	lnome.add_theme_font_size_override("font_size", 20)
	lnome.add_theme_color_override("font_color", Color(cor.r+0.2,cor.g+0.2,cor.b+0.2) if ja_tem else Color(0.36,0.36,0.4))
	card.add_child(lnome)

	# Mini preview
	var prev:= Control.new()
	prev.position = Vector2((CARD_W-96.0)*0.5, 42)
	prev.size = Vector2(96, 96)
	prev.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var pc2 := cor; var pja := ja_tem; var ppid := pid
	prev.draw.connect(func():
		var t2 := Time.get_ticks_msec()*0.001
		var cx:=48.0; var cy:=48.0; var am:=1.0 if pja else 0.35
		if _draw_comandante_face(prev, ppid, Rect2(0.0, 0.0, prev.size.x, prev.size.y), am):
			return
		match ppid:
			"nexus":
				var pts3:=PackedVector2Array()
				for i3 in 8: var a3:=float(i3)*TAU/8.0+PI/8.0+t2*0.5; pts3.append(Vector2(cx+cos(a3)*22,cy+sin(a3)*22))
				var f3:=PackedColorArray(); for _x3 in 8: f3.append(Color(0.18,0.09,0.03,0.95*am))
				prev.draw_polygon(pts3,f3)
				var b3:=PackedVector2Array(pts3); b3.append(pts3[0])
				prev.draw_polyline(b3,Color(pc2.r,pc2.g,pc2.b,am),2.0)
				prev.draw_circle(Vector2(cx,cy),8.0+sin(t2*3.0)*2.0,Color(pc2.r,pc2.g,pc2.b,0.85*am))
				prev.draw_circle(Vector2(cx,cy),4.0,Color(1.0,0.9,0.7,0.95*am))
			"phantom":
				var fa3:=0.55+sin(t2*2.5)*0.2
				var dp3:=PackedVector2Array([Vector2(cx,cy-24),Vector2(cx+18,cy),Vector2(cx,cy+18),Vector2(cx-18,cy)])
				var df3:=PackedColorArray(); for _x4 in 4: df3.append(Color(0.12,0.04,0.2,fa3*am))
				prev.draw_polygon(dp3,df3)
				var db3:=PackedVector2Array(dp3); db3.append(dp3[0])
				prev.draw_polyline(db3,Color(pc2.r,pc2.g,pc2.b,am),1.8)
				prev.draw_circle(Vector2(cx,cy),6.5,Color(0,0,0,0.9*am))
				prev.draw_circle(Vector2(cx,cy),4.0,Color(pc2.r,pc2.g,pc2.b,0.95*am))
				prev.draw_arc(Vector2(cx,cy),28.0,0.0,TAU,32,Color(pc2.r,pc2.g,pc2.b,0.12+sin(t2*2.0)*0.06),1.2)
			_:
				prev.draw_rect(Rect2(cx-11,cy-10,22,20),Color(0.06,0.12,0.24,0.96*am))
				prev.draw_line(Vector2(cx-11,cy-10),Vector2(cx+11,cy-10),Color(pc2.r,pc2.g,pc2.b,am),2.0)
				prev.draw_line(Vector2(cx+11,cy-10),Vector2(cx+11,cy+10),Color(pc2.r,pc2.g,pc2.b,am),2.0)
				prev.draw_line(Vector2(cx+11,cy+10),Vector2(cx-11,cy+10),Color(pc2.r,pc2.g,pc2.b,am),2.0)
				prev.draw_line(Vector2(cx-11,cy+10),Vector2(cx-11,cy-10),Color(pc2.r,pc2.g,pc2.b,am),2.0)
				prev.draw_line(Vector2(cx,cy-10),Vector2(cx,cy-19),Color(pc2.r,pc2.g,pc2.b,0.8*am),2.0)
				var blink3:=0.5+sin(t2*4.0)*0.5
				prev.draw_circle(Vector2(cx,cy-20),3.5,Color(pc2.r,pc2.g,pc2.b,clampf(blink3,0.1,1.0)*am))
				prev.draw_rect(Rect2(cx-7,cy-8,14,10),Color(0,0.06,0.16,0.96*am))
				prev.draw_circle(Vector2(cx,cy-3),3.5,Color(pc2.r,pc2.g,pc2.b,am))
	)
	var _atimer:= Timer.new(); _atimer.wait_time=0.033; _atimer.autostart=true
	_atimer.timeout.connect(func(): if is_instance_valid(prev): prev.queue_redraw())
	card.add_child(prev)
	card.add_child(_atimer)

	if ja_tem:
		var _xpi2c : Dictionary = Salvar.pet_cartas_info(pid)
		var xpbar2 := Control.new()
		xpbar2.position = Vector2(12, 142); xpbar2.size = Vector2(CARD_W-24, 16)
		xpbar2.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var _xp2_prog : float = float(_xpi2c.get("prog",0.0))
		var _xp2_n    : int   = int(_xpi2c.get("nivel",1))
		var _xp2_cur  : int   = int(_xpi2c.get("cartas",0))
		var _xp2_nec  : int   = int(_xpi2c.get("necessario",300))
		xpbar2.draw.connect(func():
			var bw2:=float(xpbar2.size.x); var bh2:=float(xpbar2.size.y)
			xpbar2.draw_rect(Rect2(0,3,bw2,bh2-6),Color(0.08,0.08,0.12,0.9))
			if _xp2_n < 5:
				xpbar2.draw_rect(Rect2(0,3,bw2*_xp2_prog,bh2-6),Color(cor.r*0.65,cor.g*0.65,cor.b*0.65,0.9))
			var f4:=ThemeDB.fallback_font
			var s4:="Nv.%d"%_xp2_n if _xp2_n<5 else "MÁX."
			var s4b:="%d/%d cartas"%[_xp2_cur,_xp2_nec] if _xp2_n<5 else "Nível Máximo"
			xpbar2.draw_string(f4,Vector2(2,bh2-1),s4,HORIZONTAL_ALIGNMENT_LEFT,50,9,Color(cor.r+0.2,cor.g+0.2,cor.b+0.2,0.95))
			xpbar2.draw_string(f4,Vector2(0,bh2-1),s4b,HORIZONTAL_ALIGNMENT_RIGHT,bw2,9,Color(0.55,0.6,0.65,0.8))
		)
		card.add_child(xpbar2)
	var stats_lbl:= Label.new()
	stats_lbl.text = "Dano: %.0f  |  Vel: %.0f  |  Alcance: %.0f\n%s  (CD: %.0fs)" % [dano, vel, alcance, hab_nome, hab_cd]
	stats_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stats_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD
	var stats_y : float = 162.0 if ja_tem else 146.0
	stats_lbl.position = Vector2(8, stats_y)
	stats_lbl.size = Vector2(CARD_W-16, 44)
	stats_lbl.add_theme_font_size_override("font_size", 12)
	stats_lbl.add_theme_color_override("font_color", Color(cor.r+0.1,cor.g+0.1,cor.b+0.1,0.75) if ja_tem else Color(0.35,0.38,0.42))
	stats_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(stats_lbl)

	var desc_lbl:= Label.new()
	desc_lbl.text = Salvar.pet_evolucoes_status_texto(pid) if ja_tem else desc
	desc_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD
	desc_lbl.position = Vector2(8, stats_y + 48.0)
	desc_lbl.size = Vector2(CARD_W-16, 46)
	desc_lbl.add_theme_font_size_override("font_size", 9 if ja_tem else 12)
	desc_lbl.add_theme_color_override("font_color", Color(0.5,0.65,0.72,0.8) if ja_tem else Color(0.3,0.33,0.36))
	desc_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(desc_lbl)

	var btn:= Button.new()
	if ativo:
		btn.text = "EQUIPADO"
	elif ja_tem:
		btn.text = "EQUIPAR"
	else:
		btn.text = "COMPRAR  —  %d ouro" % custo
	btn.position = Vector2(12, 255)
	btn.size = Vector2(CARD_W-24, 44)
	btn.focus_mode = Control.FOCUS_NONE
	btn.disabled = ativo or (not ja_tem and not pode_c)
	btn.add_theme_font_size_override("font_size", 14)
	var bsty2:= StyleBoxFlat.new()
	var btn_ok: bool = (ja_tem and not ativo) or (not ja_tem and pode_c)
	bsty2.bg_color = Color(cor.r*0.18,cor.g*0.18,cor.b*0.18,0.92) if btn_ok else Color(0.07,0.07,0.07,0.7)
	bsty2.border_color = Color(cor.r,cor.g,cor.b,0.85) if btn_ok else Color(0.25,0.25,0.3,0.5)
	for sd2 in ["left","right","top","bottom"]: bsty2.set("border_width_"+sd2,1)
	for cc2 in ["top_left","top_right","bottom_left","bottom_right"]: bsty2.set("corner_radius_"+cc2,6)
	btn.add_theme_stylebox_override("normal", bsty2)
	btn.add_theme_color_override("font_color", Color(cor.r+0.2,cor.g+0.2,cor.b+0.2) if btn_ok else Color(0.38,0.38,0.42))
	var _ppid4 := pid
	btn.pressed.connect(func():
		if ja_tem:
			Salvar.equipar_pet(_ppid4)
			_rebuild_loja()
		else:
			if Salvar.comprar_pet(_ppid4):
				_mostrar_compra_bau("COMANDANTE COMPRADO", [_reward_compra_pet(_ppid4)], "lendario"))
	card.add_child(btn)


func _fechar_loja() -> void :
	Acessibilidade.cancelar_foco()
	var _cmd_mudou := _menu_comandante_atual != _comandante_home_visual_pid()
	if _loja_overlay:
		_loja_overlay.queue_free()
	if _loja_panel:
		_loja_panel.queue_free()
	_loja_overlay = null
	_loja_panel = null
	_loja_scroll_cont = null
	_loja_scroll_node = null
	_ui_ref = null
	if _cmd_mudou:
		get_tree().change_scene_to_file("res://scenes/Menu.tscn")
		return
	if _menu_contents:
		_menu_contents.show()




const _AVAL_ABAS:= ["LOJA", "CARTAS", "TALENTOS", "CONFIG", "DIFICULDADES", "GERAL"]
const _AVAL_CORES:= [
	Color(1.0, 0.78, 0.0), Color(0.5, 0.25, 1.0), Color(0.85, 0.25, 0.95), 
	Color(0.25, 0.85, 1.0), Color(1.0, 0.35, 0.35), Color(0.25, 1.0, 0.65)
]
const _AVAL_PERGUNTAS:= [
	"Como vocÃª avalia a Loja Permanente?\n(upgrades, preÃ§os, variedade)", 
	"Como vocÃª avalia o sistema de Cartas?\n(variedade, balanceamento, sinergia)", 
	"Como vocÃª avalia a Ãrvore de Talentos?\n(progressÃ£o, custo, impacto)", 
	"Como vocÃª avalia as ConfiguraÃ§Ãµes?\n(opÃ§Ãµes disponÃ­veis, acessibilidade)", 
	"Como vocÃª avalia as Dificuldades?\n(balanceamento, progressÃ£o de dificuldade)", 
	"AvaliaÃ§Ã£o geral do jogo.\n(experiÃªncia completa, diversÃ£o, vontade de jogar novamente)", 
]

func _abrir_avaliacao(ui: CanvasLayer) -> void :
	if _aval_overlay: return
	if _menu_contents: _menu_contents.hide()
	_ui_ref = ui
	var vp:= get_viewport().get_visible_rect().size
	var vw: float = vp.x
	var vh: float = vp.y
	_aval_overlay = ColorRect.new()
	_aval_overlay.color = Color(0.0, 0.0, 0.0, 0.92)
	_aval_overlay.size = vp
	ui.add_child(_aval_overlay)

	var tit:= Label.new()
	tit.text = "AVALIAÃ‡ÃƒO DO JOGO"
	tit.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tit.position = Vector2(0, 14)
	tit.size = Vector2(vw, 38)
	tit.add_theme_font_size_override("font_size", 32)
	tit.add_theme_color_override("font_color", Color(0.2, 0.85, 1.0))
	_aval_overlay.add_child(tit)
	var sub:= Label.new()
	sub.text = "Seu feedback ajuda a melhorar o jogo"
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.position = Vector2(0, 52)
	sub.size = Vector2(vw, 24)
	sub.add_theme_font_size_override("font_size", 16)
	sub.add_theme_color_override("font_color", Color(0.55, 0.65, 0.7))
	_aval_overlay.add_child(sub)

	var tab_x: float = 20.0
	var tab_w: float = 190.0
	var tab_h: float = 64.0
	var tab_gap: float = 10.0
	var tab_y0: float = 86.0
	for i in range(_AVAL_ABAS.size()):
		var tb:= Button.new()
		tb.text = _AVAL_ABAS[i]
		tb.position = Vector2(tab_x, tab_y0 + float(i) * (tab_h + tab_gap))
		tb.size = Vector2(tab_w, tab_h)
		tb.focus_mode = Control.FOCUS_NONE
		tb.set_meta("aval_tab_idx", i)
		tb.add_theme_font_size_override("font_size", 22)
		var idx:= i
		tb.pressed.connect( func(): _aval_trocar_aba(idx))
		_aval_overlay.add_child(tb)

	_aval_conteudo = Control.new()
	_aval_conteudo.position = Vector2(tab_x + tab_w + 16.0, 86.0)
	_aval_conteudo.size = Vector2(vw - tab_x - tab_w - 36.0, vh - 150.0)
	_aval_conteudo.mouse_filter = Control.MOUSE_FILTER_PASS
	_aval_overlay.add_child(_aval_conteudo)

	var btn_fechar:= Button.new()
	btn_fechar.text = "FECHAR"
	btn_fechar.position = Vector2(vw * 0.5 - 310.0, vh - 62.0)
	btn_fechar.size = Vector2(290, 50)
	btn_fechar.focus_mode = Control.FOCUS_NONE
	btn_fechar.add_theme_font_size_override("font_size", 22)
	var sty_f:= StyleBoxFlat.new()
	sty_f.bg_color = Color(0.12, 0.12, 0.12)
	sty_f.border_color = Color(0.45, 0.45, 0.45)
	for s in ["left", "right", "top", "bottom"]: sty_f.set("border_width_" + s, 1)
	for c in ["top_left", "top_right", "bottom_left", "bottom_right"]: sty_f.set("corner_radius_" + c, 8)
	btn_fechar.add_theme_stylebox_override("normal", sty_f)
	btn_fechar.pressed.connect(_fechar_avaliacao)
	_aval_overlay.add_child(btn_fechar)
	var btn_enviar:= Button.new()
	btn_enviar.text = "ENVIAR AVALIAÃ‡ÃƒO"
	btn_enviar.position = Vector2(vw * 0.5 + 20.0, vh - 62.0)
	btn_enviar.size = Vector2(290, 50)
	btn_enviar.focus_mode = Control.FOCUS_NONE
	btn_enviar.add_theme_font_size_override("font_size", 22)
	var sty_e:= StyleBoxFlat.new()
	sty_e.bg_color = Color(0.05, 0.25, 0.4)
	sty_e.border_color = Color(0.2, 0.75, 1.0)
	for s in ["left", "right", "top", "bottom"]: sty_e.set("border_width_" + s, 2)
	for c in ["top_left", "top_right", "bottom_left", "bottom_right"]: sty_e.set("corner_radius_" + c, 8)
	btn_enviar.add_theme_stylebox_override("normal", sty_e)
	btn_enviar.add_theme_color_override("font_color", Color(0.2, 0.85, 1.0))
	btn_enviar.pressed.connect( func(): _aval_enviar(btn_enviar))
	_aval_overlay.add_child(btn_enviar)


	if Salvar.nome_jogador == "BOSS QUEIXO":
		var btn_admin:= Button.new()
		btn_admin.text = "VER AVALIAÃ‡Ã•ES"
		btn_admin.position = Vector2(vw - 200.0, 14)
		btn_admin.size = Vector2(186, 36)
		btn_admin.focus_mode = Control.FOCUS_NONE
		btn_admin.add_theme_font_size_override("font_size", 13)
		var sty_adm:= StyleBoxFlat.new()
		sty_adm.bg_color = Color(0.18, 0.06, 0.06, 0.95)
		sty_adm.border_color = Color(1.0, 0.3, 0.3, 0.85)
		for s in ["left", "right", "top", "bottom"]: sty_adm.set("border_width_" + s, 1)
		for c in ["top_left", "top_right", "bottom_left", "bottom_right"]: sty_adm.set("corner_radius_" + c, 6)
		btn_admin.add_theme_stylebox_override("normal", sty_adm)
		btn_admin.add_theme_color_override("font_color", Color(1.0, 0.5, 0.5))
		btn_admin.pressed.connect( func(): _abrir_admin_avaliacoes())
		_aval_overlay.add_child(btn_admin)

	_aval_trocar_aba(0)
	_corrigir_textos_ui(_aval_overlay)


func _aval_trocar_aba(idx: int) -> void :
	_aval_aba = idx
	for child in _aval_conteudo.get_children():
		child.queue_free()
	var cw: float = _aval_conteudo.size.x
	var cor: Color = _AVAL_CORES[idx]

	var lbl_q:= Label.new()
	lbl_q.text = _AVAL_PERGUNTAS[idx]
	lbl_q.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl_q.autowrap_mode = TextServer.AUTOWRAP_WORD
	lbl_q.position = Vector2(0, 10)
	lbl_q.size = Vector2(cw, 60)
	lbl_q.add_theme_font_size_override("font_size", 16)
	lbl_q.add_theme_color_override("font_color", Color(0.7, 0.74, 0.8))
	_aval_conteudo.add_child(lbl_q)

	var star_x: float = cw * 0.5 - 130.0
	for s in range(5):
		var btn_s:= Button.new()
		btn_s.text = "â˜…"
		btn_s.position = Vector2(star_x + float(s) * 56.0, 80)
		btn_s.size = Vector2(52, 52)
		btn_s.focus_mode = Control.FOCUS_NONE
		btn_s.add_theme_font_size_override("font_size", 28)
		var filled: bool = (s + 1) <= _aval_notas[idx]
		btn_s.add_theme_color_override("font_color", cor if filled else Color(0.35, 0.35, 0.35))
		var si:= s
		btn_s.pressed.connect( func():
			_aval_notas[_aval_aba] = si + 1
			_aval_trocar_aba(_aval_aba))
		_aval_conteudo.add_child(btn_s)

	var nota_txt:= ["Sem nota", "Ruim", "Regular", "Bom", "Ã“timo", "Excelente"]
	var lbl_nota:= Label.new()
	lbl_nota.text = nota_txt[_aval_notas[idx]]
	lbl_nota.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl_nota.position = Vector2(0, 136)
	lbl_nota.size = Vector2(cw, 24)
	lbl_nota.add_theme_font_size_override("font_size", 17)
	lbl_nota.add_theme_color_override("font_color", cor if _aval_notas[idx] > 0 else Color(0.4, 0.4, 0.4))
	_aval_conteudo.add_child(lbl_nota)

	var sep:= ColorRect.new()
	sep.color = Color(cor.r, cor.g, cor.b, 0.25)
	sep.position = Vector2(cw * 0.5 - 280.0, 168)
	sep.size = Vector2(560, 1)
	_aval_conteudo.add_child(sep)

	var lbl_c:= Label.new()
	lbl_c.text = "ComentÃ¡rio (opcional):"
	lbl_c.position = Vector2(cw * 0.5 - 280.0, 176)
	lbl_c.size = Vector2(380, 22)
	lbl_c.add_theme_font_size_override("font_size", 14)
	lbl_c.add_theme_color_override("font_color", Color(0.55, 0.6, 0.65))
	_aval_conteudo.add_child(lbl_c)

	var te:= TextEdit.new()
	te.text = _aval_textos[idx]
	te.position = Vector2(cw * 0.5 - 280.0, 200)
	te.size = Vector2(560, 110)
	te.placeholder_text = "Escreva seu comentÃ¡rio aqui..."
	te.add_theme_font_size_override("font_size", 15)
	var sty_te:= StyleBoxFlat.new()
	sty_te.bg_color = Color(0.06, 0.07, 0.1)
	sty_te.border_color = Color(cor.r, cor.g, cor.b, 0.4)
	for s in ["left", "right", "top", "bottom"]: sty_te.set("border_width_" + s, 1)
	for c in ["top_left", "top_right", "bottom_left", "bottom_right"]: sty_te.set("corner_radius_" + c, 6)
	te.add_theme_stylebox_override("normal", sty_te)
	te.add_theme_stylebox_override("focus", sty_te)
	var aidx:= idx
	te.text_changed.connect( func(): _aval_textos[aidx] = te.text)
	_aval_conteudo.add_child(te)

	var prog:= Label.new()
	var respondidas:= _aval_notas.filter( func(n): return n > 0).size()
	prog.text = "%d / %d avaliadas" % [respondidas, _AVAL_ABAS.size()]
	prog.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	prog.position = Vector2(0, 318)
	prog.size = Vector2(cw, 22)
	prog.add_theme_font_size_override("font_size", 14)
	prog.add_theme_color_override("font_color", Color(0.45, 0.55, 0.45))
	_aval_conteudo.add_child(prog)

	for node in _aval_overlay.get_children():
		if not (node is Button): continue
		if not (node as Button).has_meta("aval_tab_idx"): continue
		var i: int = int((node as Button).get_meta("aval_tab_idx"))
		var tc: Color = _AVAL_CORES[i]
		var ativo: bool = (i == idx)
		var sty_tb:= StyleBoxFlat.new()
		sty_tb.bg_color = Color(tc.r * 0.25, tc.g * 0.25, tc.b * 0.25, 0.95) if ativo else Color(0.06, 0.07, 0.09, 0.9)
		sty_tb.border_color = Color(tc.r, tc.g, tc.b, 0.9) if ativo else Color(0.22, 0.22, 0.22, 0.7)
		for s in ["left", "right", "top", "bottom"]: sty_tb.set("border_width_" + s, 2 if ativo else 1)
		for c in ["top_left", "top_right", "bottom_left", "bottom_right"]: sty_tb.set("corner_radius_" + c, 6)
		(node as Button).add_theme_stylebox_override("normal", sty_tb)
		(node as Button).add_theme_color_override("font_color", 
			Color(tc.r + 0.1, tc.g + 0.05, tc.b) if ativo else Color(0.5, 0.5, 0.5))
	_corrigir_textos_ui(_aval_overlay)


func _aval_enviar(btn: Button) -> void :
	var tem_nota: bool = _aval_notas.any( func(n): return n > 0)
	if not tem_nota:
		btn.text = "Avalie ao menos 1 aba!"
		return
	btn.text = "Enviando..."
	btn.disabled = true
	var dados:= {
		"nome": Salvar.nome_jogador if Salvar.nome_jogador != "" else "Anonimo", 
		"loja_nota": _aval_notas[0], "loja_texto": _aval_textos[0], 
		"cartas_nota": _aval_notas[1], "cartas_texto": _aval_textos[1], 
		"talentos_nota": _aval_notas[2], "talentos_texto": _aval_textos[2], 
		"config_nota": _aval_notas[3], "config_texto": _aval_textos[3], 
		"dificuldades_nota": _aval_notas[4], "dificuldades_texto": _aval_textos[4], 
		"geral_nota": _aval_notas[5], "geral_texto": _aval_textos[5], 
	}
	RankingOnline.avaliacao_enviada.connect( func(ok: bool):
		if ok:
			btn.text = "Enviado! Obrigado!"
			_aval_notas = [0, 0, 0, 0, 0, 0]
			_aval_textos = ["", "", "", "", "", ""]
			await get_tree().create_timer(1.5).timeout
			_fechar_avaliacao()
		else:
			btn.text = "Erro ao enviar. Tente novamente."
			btn.disabled = false
	, CONNECT_ONE_SHOT)
	RankingOnline.enviar_avaliacao(dados)


func _abrir_admin_avaliacoes() -> void :
	var vp:= get_viewport().get_visible_rect().size
	var vw: float = vp.x
	var vh: float = vp.y
	var pnl:= Panel.new()
	pnl.position = Vector2(0, 0)
	pnl.size = vp
	pnl.z_index = 50
	pnl.mouse_filter = Control.MOUSE_FILTER_STOP
	var sty:= StyleBoxFlat.new()
	sty.bg_color = Color(0.03, 0.04, 0.06, 0.98)
	sty.border_color = Color(1.0, 0.3, 0.3, 0.7)
	for s in ["left", "right", "top", "bottom"]: sty.set("border_width_" + s, 2)
	pnl.add_theme_stylebox_override("panel", sty)
	_aval_overlay.add_child(pnl)

	var tit:= Label.new()
	tit.text = "AVALIAÃ‡Ã•ES RECEBIDAS"
	tit.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tit.position = Vector2(0, 10);tit.size = Vector2(vw, 34)
	tit.add_theme_font_size_override("font_size", 26)
	tit.add_theme_color_override("font_color", Color(1.0, 0.4, 0.4))
	pnl.add_child(tit)

	var lbl_load:= Label.new()
	lbl_load.text = "Carregando..."
	lbl_load.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl_load.position = Vector2(0, vh * 0.5 - 20)
	lbl_load.size = Vector2(vw, 30)
	lbl_load.add_theme_font_size_override("font_size", 18)
	lbl_load.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
	pnl.add_child(lbl_load)

	var btn_f:= Button.new()
	btn_f.text = "FECHAR"
	btn_f.position = Vector2((vw - 200.0) * 0.5, vh - 50.0)
	btn_f.size = Vector2(200, 42)
	btn_f.focus_mode = Control.FOCUS_NONE
	btn_f.add_theme_font_size_override("font_size", 16)
	btn_f.pressed.connect( func(): pnl.queue_free())
	pnl.add_child(btn_f)

	RankingOnline.buscar_avaliacoes( func(ok: bool, lista: Array) -> void :
		if not is_instance_valid(pnl): return
		lbl_load.queue_free()
		if not ok or lista.is_empty():
			var lbl_vazio:= Label.new()
			lbl_vazio.text = "Nenhuma avaliaÃ§Ã£o ainda."
			lbl_vazio.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			lbl_vazio.position = Vector2(0, vh * 0.5 - 15)
			lbl_vazio.size = Vector2(vw, 30)
			lbl_vazio.add_theme_font_size_override("font_size", 17)
			lbl_vazio.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
			pnl.add_child(lbl_vazio)
			return

		const ABAS_K:= ["loja", "cartas", "talentos", "config", "dificuldades", "geral"]
		const ABAS_N:= ["Loja", "Cartas", "Talentos", "Config", "Difics", "Geral"]
		var medias_txt:= ""
		for k in range(ABAS_K.size()):
			var soma: float = 0.0; var cnt: int = 0
			for e in lista:
				var n: int = int((e as Dictionary).get(ABAS_K[k] + "_nota", 0))
				if n > 0: soma += n;cnt += 1
			medias_txt += "%s: %.1f  " % [ABAS_N[k], soma / cnt if cnt > 0 else 0.0]
		var lbl_med:= Label.new()
		lbl_med.text = "MÃ‰DIAS â€” " + medias_txt + "  (%d respostas)" % lista.size()
		lbl_med.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl_med.position = Vector2(10, 48);lbl_med.size = Vector2(vw - 20, 26)
		lbl_med.add_theme_font_size_override("font_size", 14)
		lbl_med.add_theme_color_override("font_color", Color(0.85, 0.85, 0.45))
		pnl.add_child(lbl_med)

		var scroll:= ScrollContainer.new()
		scroll.position = Vector2(10, 80)
		scroll.size = Vector2(vw - 20, vh - 140)
		scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
		scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
		scroll.scroll_deadzone = 4
		scroll.mouse_filter = Control.MOUSE_FILTER_STOP
		pnl.add_child(scroll)
		var cont:= VBoxContainer.new()
		cont.custom_minimum_size = Vector2(vw - 40, 0)
		cont.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		cont.mouse_filter = Control.MOUSE_FILTER_PASS
		cont.add_theme_constant_override("separation", 8)
		scroll.add_child(cont)
		for entry in lista:
			var e: Dictionary = entry as Dictionary
			var row:= PanelContainer.new()
			row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			var sty_r:= StyleBoxFlat.new()
			sty_r.bg_color = Color(0.06, 0.07, 0.1, 0.9)
			sty_r.border_color = Color(0.3, 0.3, 0.35)
			for s in ["left", "right", "top", "bottom"]: sty_r.set("border_width_" + s, 1)
			for c in ["top_left", "top_right", "bottom_left", "bottom_right"]: sty_r.set("corner_radius_" + c, 6)
			sty_r.set("content_margin_left", 12.0)
			sty_r.set("content_margin_right", 12.0)
			sty_r.set("content_margin_top", 8.0)
			sty_r.set("content_margin_bottom", 8.0)
			row.add_theme_stylebox_override("panel", sty_r)
			var vbox:= VBoxContainer.new()
			vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			vbox.mouse_filter = Control.MOUSE_FILTER_PASS
			row.add_child(vbox)
			row.mouse_filter = Control.MOUSE_FILTER_PASS

			var data_str: String = str(e.get("criado_em", "")).left(10)
			var lnome:= Label.new()
			lnome.text = "%s  â€”  %s" % [str(e.get("nome", "?")), data_str]
			lnome.add_theme_font_size_override("font_size", 15)
			lnome.add_theme_color_override("font_color", Color(0.9, 0.85, 0.5))
			lnome.mouse_filter = Control.MOUSE_FILTER_IGNORE
			vbox.add_child(lnome)

			var notas_str:= ""
			for k in range(ABAS_K.size()):
				var n: int = int(e.get(ABAS_K[k] + "_nota", 0))
				if n > 0: notas_str += "%s:%s  " % [ABAS_N[k], "â˜…".repeat(n)]
			if notas_str != "":
				var lnotas:= Label.new()
				lnotas.text = notas_str
				lnotas.mouse_filter = Control.MOUSE_FILTER_IGNORE
				lnotas.add_theme_font_size_override("font_size", 13)
				lnotas.add_theme_color_override("font_color", Color(0.85, 0.75, 0.2))
				vbox.add_child(lnotas)

			for k in range(ABAS_K.size()):
				var txt: String = str(e.get(ABAS_K[k] + "_texto", "")).strip_edges()
				if txt != "":
					var lc:= Label.new()
					lc.text = "[%s] %s" % [ABAS_N[k], txt]
					lc.autowrap_mode = TextServer.AUTOWRAP_WORD
					lc.mouse_filter = Control.MOUSE_FILTER_IGNORE
					lc.size_flags_horizontal = Control.SIZE_EXPAND_FILL
					lc.add_theme_font_size_override("font_size", 13)
					lc.add_theme_color_override("font_color", Color(0.65, 0.7, 0.75))
					vbox.add_child(lc)
			cont.add_child(row)

			var sep_e:= HSeparator.new()
			sep_e.modulate = Color(0.2, 0.2, 0.25, 0.5)
			cont.add_child(sep_e)
	)


func _fechar_avaliacao() -> void :
	if _aval_overlay:
		_aval_overlay.queue_free()
	_aval_overlay = null
	_aval_conteudo = null
	if _menu_contents: _menu_contents.show()




func _abrir_talentos(ui: CanvasLayer) -> void :
	if _talentos_overlay:
		return
	if _menu_contents:
		_menu_contents.hide()
	_debug_garantir_recursos_talentos()
	_ui_ref = ui
	var _vp_tal:= get_viewport().get_visible_rect().size
	_talentos_overlay = ColorRect.new()
	_talentos_overlay.color = Color(0.02, 0.03, 0.07, 0.92)
	_talentos_overlay.position = Vector2.ZERO
	_talentos_overlay.size = _vp_tal
	ui.add_child(_talentos_overlay)
	_rebuild_talentos()


func _debug_garantir_recursos_talentos() -> void:
	if not OS.is_debug_build():
		return
	var alterou := false
	if Salvar.ouro_banco < 50000:
		Salvar.ouro_banco = 50000
		alterou = true
	if Salvar.cristais < 5000:
		Salvar.cristais = 5000
		alterou = true
	if alterou:
		Salvar.salvar(false)


func _rebuild_talentos() -> void :
	_talento_pendente = ""
	_talento_pendente_toques = 0
	for tw in _tree_tweens:
		if is_instance_valid(tw):
			(tw as Tween).kill()
	_tree_tweens.clear()

	if _talentos_panel != null and is_instance_valid(_talentos_panel):
		_talentos_panel.queue_free()
	_talento_reset_confirmar = false
	var _vp_w: float = get_viewport().get_visible_rect().size.x


	var mg: float = 16.0
	_COL_W = (_vp_w - mg * 2.0) / 10.0
	_COL_OFF = mg + _COL_W * 0.5
	_no_half = clampf(_COL_W * 0.24, 28.0, 34.0)
	_fus_xs = [_vp_w * 0.167, _vp_w * 0.5, _vp_w * 0.833]
	_fus_ys = [240.0, 440.0]
	_sit_xs = [_vp_w * 0.125, _vp_w * 0.375, _vp_w * 0.625, _vp_w * 0.875]
	_sit_y = 230.0
	_leg_xs = [_vp_w * 0.2, _vp_w * 0.5, _vp_w * 0.8]
	_leg_y = 450.0
	if OS.has_feature("android") or OS.has_feature("ios"):
		_sit_y = 270.0
		_leg_y = 490.0

	var _SCROLL_Y_OFF: float = 146.0 if (OS.has_feature("android") or OS.has_feature("ios")) else 134.0
	var _vp_h: float = get_viewport().get_visible_rect().size.y
	_ROW_H = maxf(80.0, _no_half * 2.0 + 14.0)
	_ROW_OFF = _SCROLL_Y_OFF + _no_half + 64.0


	var _max_tiers: int = 1
	for _br_k in _BRANCH_TIERS:
		var _bt: int = (_BRANCH_TIERS[_br_k] as Array).size()
		if _bt > _max_tiers: _max_tiers = _bt
	_talentos_content_y_off = _SCROLL_Y_OFF
	var _content_h: float = (_ROW_OFF - _SCROLL_Y_OFF) + float(_max_tiers) * _ROW_H + _no_half + 30.0
	if _tab_talentos == "ramos":
		_content_h = maxf(_content_h, _fan_root_pos().y - _SCROLL_Y_OFF + _no_half * 2.0 + 68.0)

	_talentos_panel = Control.new()
	_talentos_panel.position = Vector2(0, 0)
	_talentos_panel.size = Vector2(_vp_w, _vp_h)
	_talentos_panel.clip_contents = true
	_ui_ref.add_child(_talentos_panel)
	_talent_map_hitboxes.clear()
	_talent_map_bg_rect = null
	_talent_constellation_layer = null

	var fundo:= ARVORE_FUNDO.new()
	fundo.size = Vector2(_vp_w, _vp_h)
	fundo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fundo.z_index = 1
	_talentos_panel.add_child(fundo)


	var titulo:= Label.new()
	titulo.text = "CENTRO  DE  TECNOLOGIA"
	titulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	titulo.position = Vector2(0, 8)
	titulo.size = Vector2(_vp_w, 34)
	titulo.z_index = 20
	titulo.add_theme_font_size_override("font_size", 30)
	titulo.add_theme_color_override("font_color", Color(0.68, 0.45, 1.0))
	_ui_title_label(titulo, 4.0)
	_talentos_panel.add_child(titulo)

	var desbloq: int = Salvar.talentos.size()
	var total_t: int = Salvar.TALENTOS_INFO.size() - 1
	var is_mobile_tal : bool = OS.has_feature("android") or OS.has_feature("ios")
	var info_w : float = minf(420.0, _vp_w - 32.0)
	var info_bg:= Panel.new()
	info_bg.position = Vector2((_vp_w - info_w) * 0.5, 43)
	info_bg.size = Vector2(info_w, 34 if is_mobile_tal else 30)
	info_bg.z_index = 19
	var info_sty:= StyleBoxFlat.new()
	info_sty.bg_color = Color(0.03, 0.04, 0.08, 0.76)
	info_sty.border_color = Color(0.25, 0.55, 0.8, 0.35)
	for side in ["left", "right", "top", "bottom"]:
		info_sty.set("border_width_" + side, 1)
	for corner in ["top_left", "top_right", "bottom_left", "bottom_right"]:
		info_sty.set("corner_radius_" + corner, 8)
	info_bg.add_theme_stylebox_override("panel", info_sty)
	_talentos_panel.add_child(info_bg)
	var lc:= Label.new()
	lc.text = "%d / %d tecnologias" % [desbloq, total_t]
	lc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lc.position = Vector2(0, 46)
	lc.size = Vector2(_vp_w, 22)
	lc.z_index = 20
	lc.add_theme_font_size_override("font_size", 18)
	lc.add_theme_color_override("font_color", Color(0.55, 0.88, 1.0))
	_talentos_panel.add_child(lc)
	var currency_tal_x : float = maxf(14.0, _vp_w - 252.0)
	var currency_tal_y : float = 12.0
	_add_currency_status(_talentos_panel, Vector2(currency_tal_x, currency_tal_y), true, 90)


	var tabs_data: Array = [
		["TECNOLOGIAS", "ramos", Color(0.68, 0.45, 1.0)], 
		["FUSOES", "fusoes", Color(0.4, 0.82, 0.4)], 
		["PROTOCOLOS", "especiais", Color(0.88, 0.72, 0.28)], 
	]
	var tab_w: float = minf(190.0, (_vp_w - 32.0 - 20.0) / 3.0)
	var tab_gap: float = 10.0
	var tab_h: float = 52.0 if is_mobile_tal else 44.0
	var tab_y: float = 84.0 if is_mobile_tal else 78.0
	var tab_total_w: float = float(tabs_data.size()) * tab_w + float(tabs_data.size() - 1) * tab_gap
	var tab_x_start: float = (_vp_w - tab_total_w) * 0.5
	for ti in range(tabs_data.size()):
		var td: Array = tabs_data[ti] as Array
		var tbtn:= Button.new()
		tbtn.text = td[0] as String
		tbtn.position = Vector2(tab_x_start + float(ti) * (tab_w + tab_gap), tab_y)
		tbtn.size = Vector2(tab_w, tab_h)
		tbtn.focus_mode = Control.FOCUS_NONE
		tbtn.z_index = 20
		tbtn.add_theme_font_size_override("font_size", 22)
		var sty_t:= StyleBoxFlat.new()
		var tab_cor: Color = td[2] as Color
		var ativo_t: bool = (_tab_talentos == (td[1] as String))
		sty_t.bg_color = Color(tab_cor.r * 0.2, tab_cor.g * 0.12, tab_cor.b * 0.22, 0.95) if ativo_t else Color(0.04, 0.04, 0.08, 0.88)
		sty_t.border_color = Color(tab_cor.r, tab_cor.g, tab_cor.b, 0.9) if ativo_t else Color(0.28, 0.24, 0.35)
		for side in ["left", "right", "top", "bottom"]:
			sty_t.set("border_width_" + side, 2)
		for corner in ["top_left", "top_right", "bottom_left", "bottom_right"]:
			sty_t.set("corner_radius_" + corner, 7)
		tbtn.add_theme_stylebox_override("normal", sty_t)
		tbtn.add_theme_color_override("font_color", Color(tab_cor.r + 0.1, tab_cor.g + 0.05, tab_cor.b, 1.0) if ativo_t else Color(0.5, 0.46, 0.58))
		var tab_id: String = td[1] as String
		var tab_nom: String = td[0] as String
		var tab_descs:= {
			"ramos": "Tecnologias. Mapa orbital de talentos com requisitos interligados a partir do nucleo.", 
			"fusoes": "Fusoes. Tecnologias especiais que combinam dois ou mais ramos diferentes.", 
			"especiais": "Protocolos. Tecnologias situacionais e de legado desbloqueadas por conquistas globais.", 
		}
		tbtn.pressed.connect( func() -> void :
			Acessibilidade.processar("tab_talento_" + tab_id, 
				tab_descs.get(tab_id, tab_nom) as String, 
				func():
					_tab_talentos = tab_id
					_rebuild_talentos()
			)
		)
		_talentos_panel.add_child(tbtn)


	var sc:= ScrollContainer.new()
	sc.position = Vector2(0, _SCROLL_Y_OFF)
	sc.size = Vector2(_vp_w, maxf(100.0, _vp_h - _SCROLL_Y_OFF - 70.0))
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	sc.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED if _tab_talentos == "ramos" else ScrollContainer.SCROLL_MODE_AUTO
	sc.mouse_filter = Control.MOUSE_FILTER_STOP
	sc.z_index = 2
	_talentos_panel.add_child(sc)
	_talentos_scroll = sc

	var content:= Control.new()
	content.custom_minimum_size = Vector2(_vp_w, _content_h)
	content.mouse_filter = Control.MOUSE_FILTER_PASS
	sc.add_child(content)


	var tooltip:= _mk_tooltip()
	tooltip.z_index = 30
	_talentos_panel.add_child(tooltip)


	match _tab_talentos:
		"ramos": _build_tab_ramos(fundo, tooltip, content)
		"fusoes": _build_tab_fusoes(fundo, tooltip, content)
		"especiais": _build_tab_especiais(fundo, tooltip, content)


	var pode_asc: bool = Salvar.pode_ascender()
	var total_asc: int = Salvar.talentos_necessarios_ascensao()
	var liberados_asc: int = Salvar.talentos_liberados_para_ascensao()
	var proxima_asc: int = Salvar.ascensoes + 1
	var btn_asc:= Button.new()
	btn_asc.text = ("ASCENDER +%d" % proxima_asc) if pode_asc else ("ASCENSAO %d/%d" % [liberados_asc, total_asc])
	var asc_x: float = 24.0
	var asc_y: float = tab_y + tab_h + 12.0
	btn_asc.position = Vector2(asc_x, asc_y)
	btn_asc.size = Vector2(248.0, 38.0)
	btn_asc.focus_mode = Control.FOCUS_NONE
	btn_asc.z_index = 20
	btn_asc.disabled = not pode_asc
	btn_asc.add_theme_font_size_override("font_size", 17)
	var sty_a:= StyleBoxFlat.new()
	sty_a.bg_color = Color(0.22, 0.1, 0.04, 0.95) if pode_asc else Color(0.06, 0.06, 0.08, 0.85)
	sty_a.border_color = Color(1.0, 0.6, 0.1, 0.8) if pode_asc else Color(0.3, 0.3, 0.32)
	for side in ["left", "right", "top", "bottom"]:
		sty_a.set("border_width_" + side, 2)
	for corner in ["top_left", "top_right", "bottom_left", "bottom_right"]:
		sty_a.set("corner_radius_" + corner, 10)
	btn_asc.add_theme_stylebox_override("normal", sty_a)
	btn_asc.add_theme_color_override("font_color", Color(1.0, 0.72, 0.2) if pode_asc else Color(0.45, 0.45, 0.45))
	btn_asc.pressed.connect( func() -> void :
		if Salvar.pode_ascender():
			_mostrar_confirmacao_ascensao(proxima_asc)
	)
	_talentos_panel.add_child(btn_asc)


	var btn_f:= Button.new()
	btn_f.text = "VOLTAR"
	btn_f.position = Vector2((_vp_w - 240.0) * 0.5, minf(656.0, _vp_h - 58.0))
	btn_f.size = Vector2(240.0, 48)
	btn_f.focus_mode = Control.FOCUS_NONE
	btn_f.z_index = 20
	btn_f.add_theme_font_size_override("font_size", 27)
	var sty_f:= StyleBoxFlat.new()
	sty_f.bg_color = Color(0.08, 0.08, 0.1, 0.95)
	sty_f.border_color = Color(0.4, 0.4, 0.42)
	for side in ["left", "right", "top", "bottom"]:
		sty_f.set("border_width_" + side, 2)
	for corner in ["top_left", "top_right", "bottom_left", "bottom_right"]:
		sty_f.set("corner_radius_" + corner, 10)
	btn_f.add_theme_stylebox_override("normal", sty_f)
	btn_f.add_theme_color_override("font_color", Color(0.72, 0.72, 0.72))
	btn_f.pressed.connect( func():
		Acessibilidade.processar("talentos_fechar", "Voltar do centro de tecnologia.", _fechar_talentos))
	_talentos_panel.add_child(btn_f)
	_corrigir_textos_ui(_talentos_panel)






func _mostrar_confirmacao_ascensao(nivel_destino: int) -> void:
	if _ui_ref == null or not is_instance_valid(_ui_ref):
		return
	# Remove confirmacao anterior se existir (em qualquer pai)
	for _cn in [_talentos_panel, _ui_ref]:
		if _cn != null and is_instance_valid(_cn) and _cn.has_node("AscensaoConfirm"):
			_cn.get_node("AscensaoConfirm").queue_free()

	var vp: Vector2 = get_viewport().get_visible_rect().size
	var overlay := ColorRect.new()
	overlay.name = "AscensaoConfirm"
	overlay.color = Color(0.0, 0.0, 0.0, 0.68)
	overlay.position = Vector2.ZERO
	overlay.size = vp
	# Direto no CanvasLayer — acima de tudo, sem conflito de z_index interno
	overlay.z_index = 200
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	_ui_ref.add_child(overlay)

	var panel_w: float = minf(640.0, vp.x - 32.0)
	var panel_h: float = minf(500.0, vp.y - 40.0)
	var panel := Panel.new()
	panel.position = Vector2((vp.x - panel_w) * 0.5, (vp.y - panel_h) * 0.5)
	panel.size = Vector2(panel_w, panel_h)
	panel.z_index = 0   # filho do overlay — z_index relativo ao pai ja e 200
	var sty := StyleBoxFlat.new()
	sty.bg_color = Color(0.025, 0.020, 0.014, 0.97)
	sty.border_color = Color(1.0, 0.66, 0.12, 0.88)
	for side in ["left", "right", "top", "bottom"]:
		sty.set("border_width_" + side, 2)
	for corner in ["top_left", "top_right", "bottom_left", "bottom_right"]:
		sty.set("corner_radius_" + corner, 12)
	panel.add_theme_stylebox_override("panel", sty)
	overlay.add_child(panel)

	var titulo := Label.new()
	titulo.text = "ASCENSAO +%d" % nivel_destino
	titulo.position = Vector2(24.0, 18.0)
	titulo.size = Vector2(panel_w - 48.0, 42.0)
	titulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	titulo.add_theme_font_size_override("font_size", 30)
	titulo.add_theme_color_override("font_color", Color(1.0, 0.78, 0.22))
	_ui_tech_label(titulo, 0.0)
	panel.add_child(titulo)

	var custo_cristais: int = Salvar.ascensao_custo_cristais()
	var total_talentos: int = Salvar.talentos_necessarios_ascensao()
	var talentos_ok: int = Salvar.talentos_liberados_para_ascensao()
	var bonus_txt: String = Salvar.ascensao_bonus_texto(nivel_destino)

	var btn_w: float = minf(220.0, (panel_w - 76.0) * 0.5)
	var btn_y: float = panel_h - 60.0
	var aviso_y: float = btn_y - 32.0
	var corpo_h: float = aviso_y - 84.0

	var corpo := Label.new()
	corpo.position = Vector2(24.0, 70.0)
	corpo.size = Vector2(panel_w - 48.0, corpo_h)
	corpo.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	corpo.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	corpo.add_theme_font_size_override("font_size", 15)
	corpo.add_theme_color_override("font_color", Color(0.86, 0.88, 0.92))
	_ui_tech_label(corpo, 0.0)
	corpo.text = (
		"ZERA: ouro, arvore de talentos, melhorias de loja.\n"
		+ "MANTEM: cristais, skins, baus, consumiveis, atributos, nivel e recordes.\n\n"
		+ "⚠  GASTE seu ouro antes — ele sera perdido!\n\n"
		+ "Custo: %d cristais    Talentos: %d/%d\n\n" % [custo_cristais, talentos_ok, total_talentos]
		+ "Bonus apos ascensao:\n%s" % bonus_txt
	)
	panel.add_child(corpo)

	var aviso := Label.new()
	aviso.position = Vector2(24.0, aviso_y)
	aviso.size = Vector2(panel_w - 48.0, 28.0)
	aviso.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	aviso.add_theme_font_size_override("font_size", 13)
	aviso.add_theme_color_override("font_color", Color(1.0, 0.54, 0.22))
	aviso.text = "Confirme somente se quiser gastar os recursos agora."
	panel.add_child(aviso)
	var cancelar := Button.new()
	cancelar.text = "CANCELAR"
	cancelar.position = Vector2(24.0, btn_y)
	cancelar.size = Vector2(btn_w, 42.0)
	cancelar.focus_mode = Control.FOCUS_NONE
	cancelar.add_theme_font_size_override("font_size", 18)
	_ui_premium_button(cancelar, Color(0.55, 0.55, 0.60), false)
	cancelar.pressed.connect(func() -> void:
		if is_instance_valid(overlay):
			overlay.queue_free()
	)
	panel.add_child(cancelar)

	var confirmar := Button.new()
	confirmar.text = "ASCENDER"
	confirmar.position = Vector2(panel_w - btn_w - 24.0, btn_y)
	confirmar.size = Vector2(btn_w, 42.0)
	confirmar.focus_mode = Control.FOCUS_NONE
	confirmar.add_theme_font_size_override("font_size", 18)
	_ui_premium_button(confirmar, Color(1.0, 0.66, 0.10), true)
	confirmar.pressed.connect(func() -> void:
		if Salvar.ascender():
			Som.upgrade()
			if is_instance_valid(overlay):
				overlay.queue_free()
			# Sincroniza novo nivel de prestigio com servidor imediatamente
			RankingOnline.envio_inicial()
			# Atualiza badge no botao de perfil (menu principal)
			if _perfil_btn and is_instance_valid(_perfil_btn):
				_perfil_btn.queue_redraw()
			_rebuild_talentos()
		else:
			aviso.text = "Recursos insuficientes ou arvore incompleta."
			aviso.add_theme_color_override("font_color", Color(1.0, 0.25, 0.22))
	)
	panel.add_child(confirmar)


var _COL_W: float = 118.0
var _COL_OFF: float = 79.0
var _ROW_H: float = 80.0
var _ROW_OFF: float = 168.0
var _no_half: float = 40.0
var _fus_xs: Array = [204.0, 610.0, 1016.0]
var _fus_ys: Array = [240.0, 430.0]
var _sit_xs: Array = [153.0, 459.0, 765.0, 1071.0]
var _sit_y: float = 230.0
var _leg_xs: Array = [244.0, 610.0, 976.0]
var _leg_y: float = 440.0
const _BRANCH_ORDER: Array = ["p", "b", "r", "t", "e", "g", "s", "m", "f", "x"]
const _BRANCH_NAMES: Array = ["ARSENAL", "RISCO", "DEFESA", "CONTROLE", 
								"ENERGIA", "CRIO", "SOMBRA", "COMANDO", "RECOMPENSAS", "CAOS"]
const _BRANCH_TIERS: Dictionary = {
	"p": ["p1", "p2", "p3", "p4", "p5"], 
	"b": ["b1", "b2", "b3", "b4"], 
	"r": ["r1", "r2", "r3", "r4", "token", "r5"], 
	"t": ["t1", "t2", "t3", "t4"], 
	"e": ["e1", "e2", "e3", "e4", "e5"], 
	"g": ["g1", "g2", "g3", "g4"], 
	"s": ["s1", "s2", "s3", "s4", "s5"], 
	"m": ["m1", "m2", "m3", "m4"], 
	"f": ["f1", "f2", "f3", "f4", "f5"], 
	"x": ["x1", "x2", "x3", "x4"], 
}
const _BRANCH_COLORS: Dictionary = {
	"p": Color(1.0, 0.42, 0.1), 
	"b": Color(0.88, 0.08, 0.08), 
	"r": Color(0.12, 0.62, 1.0), 
	"t": Color(0.52, 0.28, 1.0), 
	"e": Color(0.22, 0.92, 1.0), 
	"g": Color(0.18, 0.68, 1.0), 
	"s": Color(0.62, 0.12, 0.88), 
	"m": Color(0.75, 0.28, 0.95), 
	"f": Color(1.0, 0.88, 0.12), 
	"x": Color(0.95, 0.55, 0.0), 
}
const _TECH_TREE_IDS: Array = [
	"p1", "p2", "p3", "p4", "p5",
	"b1", "b2", "b3", "b4",
	"r1", "r2", "r3", "r4", "token", "r5",
	"t1", "t2", "t3", "t4",
	"e1", "e2", "e3", "e4", "e5",
	"g1", "g2", "g3", "g4",
	"s1", "s2", "s3", "s4", "s5",
	"m1", "m2", "m3", "m4",
	"f1", "f2", "f3", "f4", "f5",
	"x1", "x2", "x3", "x4",
	"colosso", "predador", "alquim", "tita", "relamp", "canhao_g",
]
const _TECH_MAJOR_IDS: Array = [
	"p3", "p5", "b4", "r3", "token", "r5", "t4", "e4", "e5",
	"g4", "s4", "s5", "m4", "f5", "x4",
]
const _TECH_FUSION_IDS: Array = ["colosso", "predador", "alquim", "tita", "relamp", "canhao_g"]
const _TECH_TREE_POS: Dictionary = {
	"p1": Vector2(0.42, 0.42), "p2": Vector2(0.33, 0.37), "p3": Vector2(0.25, 0.32), "p4": Vector2(0.17, 0.27), "p5": Vector2(0.10, 0.21),
	"b1": Vector2(0.39, 0.50), "b2": Vector2(0.30, 0.55), "b3": Vector2(0.21, 0.59), "b4": Vector2(0.12, 0.65),
	"r1": Vector2(0.43, 0.58), "r2": Vector2(0.34, 0.68), "r3": Vector2(0.25, 0.76), "r4": Vector2(0.18, 0.84), "token": Vector2(0.12, 0.93), "r5": Vector2(0.28, 0.92),
	"t1": Vector2(0.49, 0.61), "t2": Vector2(0.45, 0.72), "t3": Vector2(0.43, 0.84), "t4": Vector2(0.40, 0.94),
	"e1": Vector2(0.54, 0.62), "e2": Vector2(0.57, 0.75), "e3": Vector2(0.57, 0.88), "e4": Vector2(0.52, 0.96), "e5": Vector2(0.63, 0.96),
	"g1": Vector2(0.60, 0.58), "g2": Vector2(0.69, 0.68), "g3": Vector2(0.77, 0.76), "g4": Vector2(0.85, 0.84),
	"s1": Vector2(0.61, 0.50), "s2": Vector2(0.72, 0.54), "s3": Vector2(0.83, 0.57), "s4": Vector2(0.92, 0.62), "s5": Vector2(0.95, 0.49),
	"m1": Vector2(0.60, 0.41), "m2": Vector2(0.70, 0.35), "m3": Vector2(0.80, 0.29), "m4": Vector2(0.89, 0.22),
	"f1": Vector2(0.55, 0.36), "f2": Vector2(0.62, 0.27), "f3": Vector2(0.67, 0.18), "f4": Vector2(0.72, 0.10), "f5": Vector2(0.57, 0.09),
	"x1": Vector2(0.46, 0.36), "x2": Vector2(0.42, 0.25), "x3": Vector2(0.36, 0.15), "x4": Vector2(0.30, 0.08),
	"colosso": Vector2(0.44, 0.47), "predador": Vector2(0.73, 0.50), "alquim": Vector2(0.66, 0.30), "tita": Vector2(0.17, 0.56), "relamp": Vector2(0.70, 0.72), "canhao_g": Vector2(0.49, 0.63),
}
const _TECH_CONSTELLATION_POS: Dictionary = {
	"raiz": Vector2(0.095, 0.500),
	"m1": Vector2(0.225, 0.040), "m2": Vector2(0.410, 0.040), "m3": Vector2(0.615, 0.040), "m4": Vector2(0.820, 0.040),
	"f1": Vector2(0.255, 0.140), "f2": Vector2(0.455, 0.140), "f3": Vector2(0.665, 0.140), "f4": Vector2(0.875, 0.140), "f5": Vector2(0.965, 0.140),
	"p1": Vector2(0.215, 0.250), "p2": Vector2(0.390, 0.250), "p3": Vector2(0.580, 0.250), "p4": Vector2(0.780, 0.250), "p5": Vector2(0.955, 0.250),
	"t1": Vector2(0.260, 0.360), "t2": Vector2(0.455, 0.360), "t3": Vector2(0.665, 0.360), "t4": Vector2(0.875, 0.360),
	"e1": Vector2(0.220, 0.475), "e2": Vector2(0.415, 0.475), "e3": Vector2(0.625, 0.475), "e4": Vector2(0.835, 0.475), "e5": Vector2(0.965, 0.475),
	"s1": Vector2(0.265, 0.585), "s2": Vector2(0.465, 0.585), "s3": Vector2(0.675, 0.585), "s4": Vector2(0.890, 0.585), "s5": Vector2(0.965, 0.585),
	"x1": Vector2(0.225, 0.695), "x2": Vector2(0.425, 0.695), "x3": Vector2(0.640, 0.695), "x4": Vector2(0.860, 0.695),
	"g1": Vector2(0.275, 0.800), "g2": Vector2(0.480, 0.800), "g3": Vector2(0.695, 0.800), "g4": Vector2(0.915, 0.800),
	"r1": Vector2(0.225, 0.900), "r2": Vector2(0.405, 0.900), "r3": Vector2(0.595, 0.900), "r4": Vector2(0.790, 0.900), "token": Vector2(0.860, 0.940), "r5": Vector2(0.965, 0.900),
	"b1": Vector2(0.295, 0.995), "b2": Vector2(0.500, 0.995), "b3": Vector2(0.710, 0.995), "b4": Vector2(0.930, 0.995),
	"alquim": Vector2(0.925, 0.040), "canhao_g": Vector2(0.805, 0.800), "colosso": Vector2(0.870, 0.250), "predador": Vector2(0.735, 0.475), "relamp": Vector2(0.755, 0.585), "tita": Vector2(0.150, 0.995),
}
const _TALENT_MAP_SAFE_TOP: float = 0.155
const _TALENT_MAP_SAFE_BOTTOM: float = 0.855
const _TECH_CONSTELLATIONS: Array = [
	{"name": "COMANDO", "sub": "MAESTRIA", "color": Color(0.24, 0.95, 0.78), "label": Vector2(0.790, 0.106), "points": ["m1", "m2", "m3", "m4"], "lines": [["m1", "m2"], ["m2", "m3"], ["m3", "m4"], ["m2", "f3"]]},
	{"name": "FORTUNA", "sub": "RECOMPENSA", "color": Color(1.0, 0.82, 0.16), "label": Vector2(0.785, 0.186), "points": ["f1", "f2", "f3", "f4", "f5"], "lines": [["f1", "f2"], ["f2", "f3"], ["f3", "f4"], ["f4", "f5"], ["f2", "p3"]]},
	{"name": "ARSENAL", "sub": "DANO", "color": Color(1.0, 0.52, 0.12), "label": Vector2(0.790, 0.266), "points": ["p1", "p2", "p3", "p4", "p5"], "lines": [["p1", "p2"], ["p2", "p3"], ["p3", "p4"], ["p4", "p5"], ["p2", "t2"], ["p3", "colosso"]]},
	{"name": "TEMPORAL", "sub": "RITMO", "color": Color(0.66, 0.28, 1.0), "label": Vector2(0.790, 0.346), "points": ["t1", "t2", "t3", "t4"], "lines": [["t1", "t2"], ["t2", "t3"], ["t3", "t4"], ["t2", "e3"]]},
	{"name": "ENERGIA", "sub": "NUCLEO", "color": Color(0.20, 0.86, 1.0), "label": Vector2(0.790, 0.431), "points": ["e1", "e2", "e3", "e4", "e5"], "lines": [["e1", "e2"], ["e2", "e3"], ["e3", "e4"], ["e4", "e5"], ["e3", "s3"], ["e2", "predador"]]},
	{"name": "SOMBRA", "sub": "CORROSAO", "color": Color(0.70, 0.25, 1.0), "label": Vector2(0.790, 0.516), "points": ["s1", "s2", "s3", "s4", "s5"], "lines": [["s1", "s2"], ["s2", "s3"], ["s3", "s4"], ["s4", "s5"], ["s3", "x3"]]},
	{"name": "CAOS", "sub": "VARIACAO", "color": Color(0.25, 0.95, 0.92), "label": Vector2(0.790, 0.601), "points": ["x1", "x2", "x3", "x4"], "lines": [["x1", "x2"], ["x2", "x3"], ["x3", "x4"], ["x2", "g2"]]},
	{"name": "GLACIAL", "sub": "CONTROLE", "color": Color(0.40, 0.78, 1.0), "label": Vector2(0.790, 0.686), "points": ["g1", "g2", "g3", "g4"], "lines": [["g1", "g2"], ["g2", "g3"], ["g3", "g4"], ["g3", "canhao_g"]]},
	{"name": "DEFESA", "sub": "CASCO", "color": Color(0.28, 0.72, 1.0), "label": Vector2(0.790, 0.771), "points": ["r1", "r2", "r3", "r4", "token", "r5"], "lines": [["r1", "r2"], ["r2", "r3"], ["r3", "r4"], ["r4", "token"], ["token", "r5"], ["r3", "b2"], ["r4", "tita"]]},
	{"name": "BERSERKER", "sub": "RISCO", "color": Color(1.0, 0.18, 0.12), "label": Vector2(0.790, 0.856), "points": ["b1", "b2", "b3", "b4"], "lines": [["b1", "b2"], ["b2", "b3"], ["b3", "b4"], ["b2", "g2"]]},
]
const _TECH_CLUSTER_LABELS: Array = [
	["ARSENAL", Vector2(0.350, 0.205), "p"],
	["DEFESA", Vector2(0.360, 0.815), "r"],
	["ENERGIA", Vector2(0.420, 0.455), "e"],
	["SOMBRA", Vector2(0.650, 0.605), "s"],
	["GLACIAL", Vector2(0.515, 0.900), "g"],
	["COMANDO", Vector2(0.515, 0.110), "m"],
	["FORTUNA", Vector2(0.655, 0.295), "f"],
	["BERSERKER", Vector2(0.470, 0.965), "b"],
	["TEMPORAL", Vector2(0.565, 0.315), "t"],
	["CAOS", Vector2(0.590, 0.690), "x"],
]
const _TALENT_CALIBRATION_GROUPS: Array = [
	"NUCLEO",
	"DRACO",
	"LEAO",
	"CETUS",
	"ESCORPIAO",
	"PEGASO",
	"FENIX",
	"VIRGEM",
	"ANDROMEDA",
	"URSA MAIOR",
	"TOURO",
	"ORION",
]


func _col_center_x(col: int) -> float:
	return _COL_OFF + float(col) * _COL_W


func _tier_center_y(tier: int) -> float:
	return _ROW_OFF + float(tier) * _ROW_H


func _tech_tree_bounds() -> Rect2:
	var vp: Vector2 = get_viewport().get_visible_rect().size
	var left: float = maxf(212.0, vp.x * 0.145)
	var right: float = vp.x - maxf(34.0, vp.x * 0.035)
	var top: float = 54.0
	var bottom: float = vp.y - 72.0
	if bottom < top + 360.0:
		bottom = top + 360.0
	return Rect2(left, top, maxf(400.0, right - left), maxf(300.0, bottom - top))


func _tech_tree_norm_pos(n: Vector2) -> Vector2:
	var b: Rect2 = _tech_tree_bounds()
	var nx: float = clampf(n.x, 0.0, 1.0)
	var ny: float = clampf(n.y, 0.0, 1.0)
	return Vector2(
		lerpf(b.position.x, b.position.x + b.size.x, nx),
		lerpf(b.position.y + b.size.y, b.position.y, ny)
	)


func _tech_tree_root_pos() -> Vector2:
	if _TECH_CONSTELLATION_POS.has("raiz"):
		return _talent_norm_to_screen(_TECH_CONSTELLATION_POS["raiz"] as Vector2)
	return _tech_tree_norm_pos(Vector2(0.50, 0.50))


func _fan_root_pos() -> Vector2:
	return _tech_tree_root_pos()


func _tech_tree_pos(id: String) -> Vector2:
	if TALENT_USE_CALIBRATION_POSITIONS and _talent_calibration_positions.has(id):
		return _talent_norm_to_screen(_talent_calibration_positions[id] as Vector2)
	if _TECH_CONSTELLATION_POS.has(id):
		return _talent_norm_to_screen(_TECH_CONSTELLATION_POS[id] as Vector2)
	if _TECH_TREE_POS.has(id):
		return _tech_tree_norm_pos(_TECH_TREE_POS[id] as Vector2)
	return Vector2(get_viewport().get_visible_rect().size.x * 0.5, 340.0)


func _talento_no_half(id: String) -> float:
	if id == "raiz":
		return clampf(_no_half * 1.04, 30.0, 36.0)
	if _TECH_FUSION_IDS.has(id):
		return clampf(_no_half * 1.16, 32.0, 40.0)
	if _TECH_MAJOR_IDS.has(id):
		return clampf(_no_half * 1.02, 29.0, 35.0)
	if _tab_talentos == "ramos":
		return clampf(_no_half * 0.76, 22.0, 27.0)
	return _no_half


func _talent_hitbox_size(id: String) -> Vector2:
	if _tab_talentos == "ramos":
		var scale: float = clampf(get_viewport().get_visible_rect().size.x / 1280.0, 0.76, 1.04)
		if id == "raiz":
			return Vector2(96.0, 48.0) * scale
		if _TECH_MAJOR_IDS.has(id):
			return Vector2(136.0, 42.0) * scale
		return Vector2(118.0, 36.0) * scale
	var half: float = maxf(_talento_no_half(id), 26.0)
	return Vector2(half * 2.0, half * 2.0)


func _tech_branch_color_for_id(id: String) -> Color:
	for br in _BRANCH_ORDER:
		var tiers: Array = _BRANCH_TIERS[br as String] as Array
		if tiers.has(id):
			return _BRANCH_COLORS[br as String] as Color
	if _TECH_FUSION_IDS.has(id):
		var info: Dictionary = Salvar.TALENTOS_INFO[id] as Dictionary
		return info["cor"] as Color
	var fallback: Dictionary = Salvar.TALENTOS_INFO.get(id, {}) as Dictionary
	return fallback.get("cor", Color(0.55, 0.82, 1.0)) as Color


func _tech_connection_points(from_pos: Vector2, to_pos: Vector2) -> Array:
	var dx: float = to_pos.x - from_pos.x
	var dy: float = to_pos.y - from_pos.y
	if absf(dx) < 36.0 or absf(dy) < 36.0:
		return [from_pos, to_pos]
	var bend: Vector2 = Vector2(
		from_pos.x + dx * 0.52,
		from_pos.y + dy * 0.48 - clampf(absf(dx) * 0.045, 8.0, 24.0)
	)
	return [from_pos, bend, to_pos]


func _tech_main_tree_ids() -> Array:
	var ids: Array = []
	for tid_any in _TECH_TREE_IDS:
		var tid: String = tid_any as String
		if _TECH_FUSION_IDS.has(tid):
			continue
		ids.append(tid)
	return ids


func _talent_map_fit_scale(vp: Vector2) -> float:
	if vp.x <= 0.0 or vp.y <= 0.0:
		return 1.0
	return minf(vp.x / TALENT_MAP_SOURCE_SIZE.x, vp.y / TALENT_MAP_SOURCE_SIZE.y)


func _talent_map_default_zoom(vp: Vector2) -> float:
	var fit_scale: float = _talent_map_fit_scale(vp)
	if fit_scale <= 0.0:
		return 1.0
	var cover_scale: float = maxf(vp.x / TALENT_MAP_SOURCE_SIZE.x, vp.y / TALENT_MAP_SOURCE_SIZE.y)
	return clampf(cover_scale / fit_scale, 1.0, 2.0)


func _ensure_talent_map_zoom(vp: Vector2) -> void:
	if _talent_map_zoom <= 0.0:
		_talent_map_zoom = _talent_map_default_zoom(vp)


func _clamp_talent_map_pan(pan: Vector2, draw_size: Vector2, view_size: Vector2) -> Vector2:
	var overflow_x: float = maxf(0.0, draw_size.x - view_size.x)
	return Vector2(
		clampf(pan.x, -overflow_x, 0.0) if overflow_x > 0.0 else 0.0,
		0.0
	)


func _talent_map_rect() -> Rect2:
	var vp: Vector2 = get_viewport().get_visible_rect().size
	if vp.x <= 0.0 or vp.y <= 0.0:
		return Rect2(Vector2.ZERO, TALENT_MAP_SOURCE_SIZE)
	_talent_map_zoom = 1.0
	var detail_rect: Rect2 = _talent_text_rect_screen()
	var left: float = detail_rect.end.x + 28.0
	var top: float = 112.0
	var right: float = vp.x - 24.0
	var bottom: float = vp.y - 34.0
	if OS.has_feature("android") or OS.has_feature("ios"):
		top = 126.0
		bottom = vp.y - 44.0
	var min_w: float = minf(620.0, maxf(280.0, vp.x - left - 24.0))
	var min_h: float = minf(390.0, maxf(240.0, vp.y - top - 92.0))
	if right - left < min_w:
		left = maxf(detail_rect.end.x + 16.0, right - min_w)
	if bottom - top < min_h:
		top = maxf(126.0, bottom - min_h)
	var view_size: Vector2 = Vector2(maxf(280.0, right - left), maxf(220.0, bottom - top))
	var content_width: float = view_size.x
	if _tab_talentos == "ramos":
		content_width = view_size.x * (2.45 if OS.has_feature("android") or OS.has_feature("ios") else 2.30)
	var content_size: Vector2 = Vector2(maxf(view_size.x, content_width), view_size.y)
	_talent_map_pan = _clamp_talent_map_pan(_talent_map_pan, content_size, view_size)
	return Rect2(Vector2(left, top) + _talent_map_pan, content_size)


func _mapa_estelar_pos(x: float, y: float) -> Vector2:
	var r: Rect2 = _talent_map_rect()
	return r.position + Vector2(x * r.size.x / TALENT_MAP_SOURCE_SIZE.x, y * r.size.y / TALENT_MAP_SOURCE_SIZE.y)


func _mapa_estelar_size(w: float, h: float) -> Vector2:
	var r: Rect2 = _talent_map_rect()
	return Vector2(w * r.size.x / TALENT_MAP_SOURCE_SIZE.x, h * r.size.y / TALENT_MAP_SOURCE_SIZE.y)


func _talent_norm_to_screen(pos: Vector2) -> Vector2:
	var r: Rect2 = _talent_map_rect()
	var safe_y: float = lerpf(_TALENT_MAP_SAFE_TOP, _TALENT_MAP_SAFE_BOTTOM, clampf(pos.y, 0.0, 1.0))
	return r.position + Vector2(pos.x * r.size.x, safe_y * r.size.y)


func _talent_screen_to_norm(pos: Vector2) -> Vector2:
	var r: Rect2 = _talent_map_rect()
	if r.size.x <= 0.0 or r.size.y <= 0.0:
		return Vector2.ZERO
	var raw_y: float = clampf((pos.y - r.position.y) / r.size.y, 0.0, 1.0)
	var norm_y: float = inverse_lerp(_TALENT_MAP_SAFE_TOP, _TALENT_MAP_SAFE_BOTTOM, raw_y)
	return Vector2(clampf((pos.x - r.position.x) / r.size.x, 0.0, 1.0), clampf(norm_y, 0.0, 1.0))


func _talent_text_rect_screen() -> Rect2:
	var vp: Vector2 = get_viewport().get_visible_rect().size
	var panel_w: float = clampf(vp.x * 0.18, 210.0, 270.0)
	var panel_h: float = clampf(vp.y - 250.0, 300.0, 440.0)
	var panel_y: float = clampf(vp.y * 0.34, 190.0, maxf(196.0, vp.y - panel_h - 96.0))
	return Rect2(Vector2(22.0, panel_y), Vector2(panel_w, panel_h))


func _talent_map_point_hits_node(pos: Vector2) -> bool:
	for id_any in _talent_map_hitboxes.keys():
		var id: String = id_any as String
		var btn: Button = _talent_map_hitboxes[id] as Button
		if btn != null and is_instance_valid(btn) and btn.get_global_rect().has_point(pos):
			return true
	return false


func _talent_map_point_hits_fixed_ui(pos: Vector2) -> bool:
	var vp: Vector2 = get_viewport().get_visible_rect().size
	if _talent_text_rect_screen().has_point(pos):
		return true
	if pos.y < 165.0:
		return true
	if pos.y > vp.y - 92.0:
		return true
	return false


func _talent_map_navigation_available() -> bool:
	return _talentos_panel != null and is_instance_valid(_talentos_panel) and _tab_talentos == "ramos"


func _handle_talent_map_navigation_input(event: InputEvent) -> bool:
	if not _talent_map_navigation_available():
		_talent_map_dragging = false
		return false
	# Overlay de confirmacao de ascensao aberto — nao capturar nenhum input do mapa
	var _confirm_open: bool = (
		(_ui_ref != null and is_instance_valid(_ui_ref) and _ui_ref.has_node("AscensaoConfirm"))
		or (_talentos_panel != null and is_instance_valid(_talentos_panel) and _talentos_panel.has_node("AscensaoConfirm"))
	)
	if _confirm_open:
		_talent_map_dragging = false
		return false
	if event is InputEventKey:
		var key:= event as InputEventKey
		if key.pressed and not key.echo and key.keycode == KEY_HOME:
			_talent_map_pan = Vector2.ZERO
			_talent_map_zoom = 0.0
			_refresh_talent_map_runtime_layout()
			get_viewport().set_input_as_handled()
			return true
	if event is InputEventMouseButton:
		var mb:= event as InputEventMouseButton
		if mb.pressed and (
			mb.button_index == MOUSE_BUTTON_WHEEL_UP
			or mb.button_index == MOUSE_BUTTON_WHEEL_DOWN
			or mb.button_index == MOUSE_BUTTON_WHEEL_LEFT
			or mb.button_index == MOUSE_BUTTON_WHEEL_RIGHT
		):
			if _talent_map_point_hits_fixed_ui(mb.position):
				return false
			var scroll_step: float = 96.0
			if mb.button_index == MOUSE_BUTTON_WHEEL_DOWN or mb.button_index == MOUSE_BUTTON_WHEEL_RIGHT:
				_talent_map_pan.x -= scroll_step
			else:
				_talent_map_pan.x += scroll_step
			_refresh_talent_map_runtime_layout()
			get_viewport().set_input_as_handled()
			return true
		if mb.button_index == MOUSE_BUTTON_LEFT or mb.button_index == MOUSE_BUTTON_RIGHT or mb.button_index == MOUSE_BUTTON_MIDDLE:
			if mb.pressed:
				if _talent_map_point_hits_fixed_ui(mb.position) or _talent_map_point_hits_node(mb.position):
					_talent_map_dragging = false
					return false
				_talent_map_dragging = true
				_talent_map_drag_last = mb.position
				get_viewport().set_input_as_handled()
				return true
			if _talent_map_dragging:
				_talent_map_dragging = false
				get_viewport().set_input_as_handled()
				return true
	if event is InputEventMouseMotion and _talent_map_dragging:
		var mm:= event as InputEventMouseMotion
		_talent_map_pan.x += mm.position.x - _talent_map_drag_last.x
		_talent_map_drag_last = mm.position
		_refresh_talent_map_runtime_layout()
		get_viewport().set_input_as_handled()
		return true
	if event is InputEventScreenDrag:
		var sd:= event as InputEventScreenDrag
		_talent_map_pan.x += sd.relative.x
		_refresh_talent_map_runtime_layout()
		get_viewport().set_input_as_handled()
		return true
	return false


func _refresh_talent_map_runtime_layout() -> void:
	if not _talent_map_navigation_available():
		return
	var map_rect: Rect2 = _talent_map_rect()
	if _talent_map_bg_rect != null and is_instance_valid(_talent_map_bg_rect):
		_talent_map_bg_rect.position = map_rect.position
		_talent_map_bg_rect.size = map_rect.size
	if _talent_constellation_layer != null and is_instance_valid(_talent_constellation_layer):
		_talent_constellation_layer.position = Vector2.ZERO
		_talent_constellation_layer.size = get_viewport().get_visible_rect().size
		if _talent_constellation_layer.has_method("setup"):
			_talent_constellation_layer.call("setup", _tech_constellations_for_screen(), _tech_constellation_screen_positions(), _tech_constellation_states(), [], _tech_constellation_node_titles())
	_apply_talent_detail_layout()
	for id_any in _talent_map_hitboxes.keys():
		var id: String = id_any as String
		var btn: Button = _talent_map_hitboxes[id] as Button
		if btn == null or not is_instance_valid(btn):
			continue
		var centro: Vector2 = _no_pos_talento(id)
		var hit_size: Vector2 = _talent_hitbox_size(id)
		var parent_is_panel: bool = btn.get_parent() == _talentos_panel
		var offset: Vector2 = Vector2.ZERO if parent_is_panel else Vector2(0.0, _talentos_content_y_off)
		btn.position = centro - hit_size * 0.5 - offset
		btn.size = hit_size
	if _talent_calibration_active:
		_refresh_talent_calibration_overlay()


func _talent_calibration_ids() -> Array:
	var ids: Array = ["raiz"]
	ids.append_array(_TECH_TREE_IDS)
	return ids


func _talent_calibration_current_id() -> String:
	var ids: Array = _talent_calibration_ids()
	if ids.is_empty():
		return "raiz"
	_talent_calibration_index = clampi(_talent_calibration_index, 0, ids.size() - 1)
	return ids[_talent_calibration_index] as String


func _talent_calibration_display_name(id: String) -> String:
	if Salvar.TALENTOS_INFO.has(id):
		var info: Dictionary = Salvar.TALENTOS_INFO[id] as Dictionary
		return _texto_ui_limpo((info["nome"] as String).replace("\n", " "))
	return id


func _talent_calibration_note_for(id: String) -> String:
	return str(_talent_calibration_notes_by_id.get(id, ""))


func _save_current_talent_calibration_note() -> void:
	if _talent_calibration_desc_edit == null or not is_instance_valid(_talent_calibration_desc_edit):
		return
	var id: String = _talent_calibration_current_id()
	_talent_calibration_notes_by_id[id] = _talent_calibration_desc_edit.text.strip_edges()


func _calibration_desc_contains(screen_pos: Vector2) -> bool:
	if _talent_calibration_desc_edit == null or not is_instance_valid(_talent_calibration_desc_edit):
		return false
	return _talent_calibration_desc_edit.get_global_rect().has_point(screen_pos)


func _talent_calibration_current_group() -> String:
	if _TALENT_CALIBRATION_GROUPS.is_empty():
		return "NUCLEO"
	_talent_calibration_group_index = clampi(_talent_calibration_group_index, 0, _TALENT_CALIBRATION_GROUPS.size() - 1)
	return _TALENT_CALIBRATION_GROUPS[_talent_calibration_group_index] as String


func _talent_calibration_group_for_key(keycode: int) -> String:
	var index: int = -1
	match keycode:
		KEY_1:
			index = 0
		KEY_2:
			index = 1
		KEY_3:
			index = 2
		KEY_4:
			index = 3
		KEY_5:
			index = 4
		KEY_6:
			index = 5
		KEY_7:
			index = 6
		KEY_8:
			index = 7
		KEY_9:
			index = 8
		KEY_0:
			index = 9
		_:
			index = -1
	if index < 0 or index >= _TALENT_CALIBRATION_GROUPS.size():
		return ""
	return _TALENT_CALIBRATION_GROUPS[index] as String


func _set_talent_calibration_group(group_name: String) -> void:
	var idx: int = _TALENT_CALIBRATION_GROUPS.find(group_name)
	if idx < 0:
		return
	_talent_calibration_group_index = idx
	var id: String = _talent_calibration_current_id()
	_talent_calibration_groups_by_id[id] = group_name
	_write_talent_calibration_file(false)
	_refresh_talent_calibration_overlay()


func _cycle_talent_calibration_group(delta: int) -> void:
	if _TALENT_CALIBRATION_GROUPS.is_empty():
		return
	_talent_calibration_group_index = wrapi(_talent_calibration_group_index + delta, 0, _TALENT_CALIBRATION_GROUPS.size())
	_set_talent_calibration_group(_talent_calibration_current_group())


func _talent_calibration_available() -> bool:
	return OS.is_debug_build() and _talentos_panel != null and is_instance_valid(_talentos_panel) and _tab_talentos == "ramos"


func _handle_talent_calibration_input(event: InputEvent) -> bool:
	if event is InputEventKey:
		var key:= event as InputEventKey
		if not key.pressed or key.echo or not key.ctrl_pressed:
			return false
		match key.keycode:
			KEY_M:
				_toggle_talent_calibration()
				get_viewport().set_input_as_handled()
				return true
			KEY_N:
				if _talent_calibration_active:
					_talent_calibration_step(1)
					get_viewport().set_input_as_handled()
					return true
			KEY_B:
				if _talent_calibration_active:
					_talent_calibration_step(-1)
					get_viewport().set_input_as_handled()
					return true
			KEY_T:
				if _talent_calibration_active:
					_talent_calibration_area_mode = not _talent_calibration_area_mode
					_talent_calibration_dragging = false
					_refresh_talent_calibration_overlay()
					get_viewport().set_input_as_handled()
					return true
			KEY_E:
				if _talent_calibration_active:
					_export_talent_calibration()
					get_viewport().set_input_as_handled()
					return true
			KEY_R:
				if _talent_calibration_active:
					var cid: String = _talent_calibration_current_id()
					_talent_calibration_positions.erase(cid)
					_talent_calibration_notes_by_id.erase(cid)
					_write_talent_calibration_file(false)
					_refresh_talent_calibration_overlay()
					get_viewport().set_input_as_handled()
					return true
		return false

	if not _talent_calibration_active or not _talent_calibration_available():
		return false

	if event is InputEventMouseMotion and _talent_calibration_dragging:
		_talent_calibration_drag_current = (event as InputEventMouseMotion).position
		_refresh_talent_calibration_overlay()
		get_viewport().set_input_as_handled()
		return true

	if event is InputEventMouseButton:
		var mb:= event as InputEventMouseButton
		if mb.button_index != MOUSE_BUTTON_LEFT:
			return false
		if _calibration_desc_contains(mb.position):
			return false
		if mb.pressed:
			if _talent_calibration_area_mode:
				_talent_calibration_dragging = true
				_talent_calibration_drag_start = mb.position
				_talent_calibration_drag_current = mb.position
			else:
				_record_talent_calibration_point(mb.position)
			get_viewport().set_input_as_handled()
			return true
		if _talent_calibration_area_mode and _talent_calibration_dragging:
			_talent_calibration_dragging = false
			_talent_calibration_drag_current = mb.position
			_record_talent_calibration_rect(_talent_calibration_drag_start, _talent_calibration_drag_current)
			get_viewport().set_input_as_handled()
			return true
	return false


func _toggle_talent_calibration() -> void:
	if not _talent_calibration_available():
		_talent_calibration_active = false
		_refresh_talent_calibration_overlay()
		return
	_talent_calibration_active = not _talent_calibration_active
	_talent_calibration_dragging = false
	_refresh_talent_calibration_overlay()


func _talent_calibration_step(delta: int) -> void:
	_save_current_talent_calibration_note()
	var ids: Array = _talent_calibration_ids()
	if ids.is_empty():
		return
	_talent_calibration_index = clampi(_talent_calibration_index + delta, 0, ids.size() - 1)
	_refresh_talent_calibration_overlay()


func _record_talent_calibration_point(screen_pos: Vector2) -> void:
	_save_current_talent_calibration_note()
	var id: String = _talent_calibration_current_id()
	_talent_calibration_positions[id] = _talent_screen_to_norm(screen_pos)
	_write_talent_calibration_file(false)
	_talent_calibration_step(1)


func _record_talent_calibration_rect(start_pos: Vector2, end_pos: Vector2) -> void:
	var a: Vector2 = _talent_screen_to_norm(start_pos)
	var b: Vector2 = _talent_screen_to_norm(end_pos)
	var left: float = minf(a.x, b.x)
	var top: float = minf(a.y, b.y)
	var right: float = maxf(a.x, b.x)
	var bottom: float = maxf(a.y, b.y)
	_talent_calibration_text_rect_norm = Rect2(Vector2(left, top), Vector2(maxf(0.01, right - left), maxf(0.01, bottom - top)))
	_write_talent_calibration_file(false)
	_refresh_talent_calibration_overlay()
	_mostrar_detalhe_talento(_talent_calibration_current_id())


func _calibration_round(value: float) -> float:
	return roundf(value * 10000.0) / 10000.0


func _talent_calibration_data() -> Dictionary:
	_save_current_talent_calibration_note()
	var positions_out: Dictionary = {}
	var notes_out: Dictionary = {}
	var entries_out: Dictionary = {}
	for id_any in _talent_calibration_ids():
		var id: String = id_any as String
		var entry: Dictionary = {
			"name": _talent_calibration_display_name(id),
			"note": _talent_calibration_note_for(id)
		}
		if _talent_calibration_positions.has(id):
			var p: Vector2 = _talent_calibration_positions[id] as Vector2
			var pos_arr: Array = [_calibration_round(p.x), _calibration_round(p.y)]
			positions_out[id] = pos_arr
			entry["position"] = pos_arr
		if _talent_calibration_note_for(id) != "":
			notes_out[id] = _talent_calibration_note_for(id)
		if entry.has("position") or entry["note"] != "":
			entries_out[id] = entry
	var r: Rect2 = _talent_calibration_text_rect_norm
	return {
		"version": 1,
		"background": TALENT_MAP_TEXTURE_PATH,
		"entries": entries_out,
		"positions": positions_out,
		"notes": notes_out,
		"text_rect": [_calibration_round(r.position.x), _calibration_round(r.position.y), _calibration_round(r.size.x), _calibration_round(r.size.y)]
	}


func _write_talent_calibration_file(copy_to_clipboard: bool) -> void:
	var data: Dictionary = _talent_calibration_data()
	var json_txt: String = JSON.stringify(data, "\t")
	var abs_path: String = ProjectSettings.globalize_path(TALENT_CALIBRATION_EXPORT_PATH)
	DirAccess.make_dir_recursive_absolute(abs_path.get_base_dir())
	var file:= FileAccess.open(abs_path, FileAccess.WRITE)
	if file != null:
		file.store_string(json_txt)
		file.close()
	if copy_to_clipboard:
		DisplayServer.clipboard_set(json_txt)
	print("[TalentosCalibracao] Exportado em: ", abs_path)


func _export_talent_calibration() -> void:
	_write_talent_calibration_file(true)
	if _talento_detalhe_estado and is_instance_valid(_talento_detalhe_estado):
		_talento_detalhe_estado.text = "CALIBRACAO EXPORTADA\nArquivo salvo e JSON copiado."
		_talento_detalhe_estado.add_theme_color_override("font_color", Color(0.55, 1.0, 0.70))
	_refresh_talent_calibration_overlay()


func _load_talent_calibration() -> void:
	var abs_path: String = ProjectSettings.globalize_path(TALENT_CALIBRATION_EXPORT_PATH)
	if not FileAccess.file_exists(abs_path):
		return
	var txt: String = FileAccess.get_file_as_string(abs_path)
	var parsed: Variant = JSON.parse_string(txt)
	if not (parsed is Dictionary):
		return
	var data: Dictionary = parsed as Dictionary
	var pos_data: Dictionary = data.get("positions", {}) as Dictionary
	for key_any in pos_data.keys():
		var key: String = key_any as String
		var arr: Array = pos_data[key] as Array
		if arr.size() >= 2:
			_talent_calibration_positions[key] = Vector2(float(arr[0]), float(arr[1]))
	var notes_data: Dictionary = data.get("notes", {}) as Dictionary
	for note_key_any in notes_data.keys():
		var note_key: String = note_key_any as String
		_talent_calibration_notes_by_id[note_key] = str(notes_data[note_key])
	var entries_data: Dictionary = data.get("entries", {}) as Dictionary
	for entry_key_any in entries_data.keys():
		var entry_key: String = entry_key_any as String
		var entry: Dictionary = entries_data[entry_key] as Dictionary
		if entry.has("note"):
			_talent_calibration_notes_by_id[entry_key] = str(entry["note"])
		if entry.has("position"):
			var epos: Array = entry["position"] as Array
			if epos.size() >= 2:
				_talent_calibration_positions[entry_key] = Vector2(float(epos[0]), float(epos[1]))
	var rect_arr: Array = data.get("text_rect", []) as Array
	if rect_arr.size() >= 4:
		_talent_calibration_text_rect_norm = Rect2(Vector2(float(rect_arr[0]), float(rect_arr[1])), Vector2(float(rect_arr[2]), float(rect_arr[3])))


func _ensure_talent_calibration_layer() -> Control:
	if _talent_calibration_layer != null and is_instance_valid(_talent_calibration_layer):
		return _talent_calibration_layer
	if not _talent_calibration_available():
		return null
	_talent_calibration_layer = Control.new()
	_talent_calibration_layer.name = "TalentCalibrationLayer"
	_talent_calibration_layer.position = Vector2.ZERO
	_talent_calibration_layer.size = get_viewport().get_visible_rect().size
	_talent_calibration_layer.z_index = 86
	_talent_calibration_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_talentos_panel.add_child(_talent_calibration_layer)
	return _talent_calibration_layer


func _add_calibration_rect(parent: Control, rect: Rect2, color: Color) -> void:
	var panel:= Panel.new()
	panel.position = rect.position
	panel.size = rect.size
	panel.z_index = 88
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var sty:= StyleBoxFlat.new()
	sty.bg_color = Color(color.r, color.g, color.b, 0.06)
	sty.border_color = color
	for side in ["left", "right", "top", "bottom"]:
		sty.set("border_width_" + side, 2)
	panel.add_theme_stylebox_override("panel", sty)
	parent.add_child(panel)


func _add_calibration_dot(parent: Control, pos: Vector2, color: Color, text: String) -> void:
	var dot:= ColorRect.new()
	dot.color = color
	dot.position = pos - Vector2(5.0, 5.0)
	dot.size = Vector2(10.0, 10.0)
	dot.z_index = 89
	dot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(dot)
	if text != "":
		var lbl:= Label.new()
		lbl.text = text
		lbl.position = pos + Vector2(7.0, -9.0)
		lbl.size = Vector2(92.0, 18.0)
		lbl.z_index = 89
		lbl.add_theme_font_size_override("font_size", 10)
		lbl.add_theme_color_override("font_color", color)
		lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		parent.add_child(lbl)


func _refresh_talent_calibration_overlay() -> void:
	if not _talent_calibration_active or not _talent_calibration_available():
		if _talent_calibration_layer != null and is_instance_valid(_talent_calibration_layer):
			_talent_calibration_layer.queue_free()
		_talent_calibration_layer = null
		return
	var layer: Control = _ensure_talent_calibration_layer()
	if layer == null:
		return
	for child in layer.get_children():
		child.queue_free()

	var id: String = _talent_calibration_current_id()
	var ids: Array = _talent_calibration_ids()
	var current_name: String = _talent_calibration_display_name(id)
	var mode_txt: String = "AREA DE TEXTO" if _talent_calibration_area_mode else "ESTRELAS"

	var hint_panel:= Panel.new()
	hint_panel.position = Vector2(330.0, 10.0)
	hint_panel.size = Vector2(500.0, 74.0)
	hint_panel.z_index = 90
	hint_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var hint_sty:= StyleBoxFlat.new()
	hint_sty.bg_color = Color(0.015, 0.012, 0.030, 0.86)
	hint_sty.border_color = Color(0.65, 0.42, 1.0, 0.88)
	for side in ["left", "right", "top", "bottom"]:
		hint_sty.set("border_width_" + side, 1)
	for corner in ["top_left", "top_right", "bottom_left", "bottom_right"]:
		hint_sty.set("corner_radius_" + corner, 8)
	hint_panel.add_theme_stylebox_override("panel", hint_sty)
	layer.add_child(hint_panel)

	var hint:= Label.new()
	hint.text = "CALIBRADOR: %s  |  %d/%d  |  %s\nCtrl+M liga/desliga  Ctrl+N/B proximo/anterior  Ctrl+T area  Ctrl+E exporta\n%s" % [
		mode_txt, _talent_calibration_index + 1, ids.size(), id, current_name
	]
	hint.position = Vector2(12.0, 7.0)
	hint.size = Vector2(476.0, 62.0)
	hint.z_index = 91
	hint.add_theme_font_size_override("font_size", 12)
	hint.add_theme_color_override("font_color", Color(0.82, 0.92, 1.0))
	hint_panel.add_child(hint)

	var desc_panel:= Panel.new()
	desc_panel.position = Vector2(330.0, 88.0)
	desc_panel.size = Vector2(500.0, 44.0)
	desc_panel.z_index = 90
	var desc_sty:= StyleBoxFlat.new()
	desc_sty.bg_color = Color(0.012, 0.016, 0.026, 0.92)
	desc_sty.border_color = Color(0.28, 0.84, 1.0, 0.78)
	for side in ["left", "right", "top", "bottom"]:
		desc_sty.set("border_width_" + side, 1)
	for corner in ["top_left", "top_right", "bottom_left", "bottom_right"]:
		desc_sty.set("corner_radius_" + corner, 8)
	desc_panel.add_theme_stylebox_override("panel", desc_sty)
	layer.add_child(desc_panel)

	_talent_calibration_desc_edit = LineEdit.new()
	_talent_calibration_desc_edit.placeholder_text = "Descricao desse ponto: constelacao, funcao, requisito, observacao..."
	_talent_calibration_desc_edit.text = _talent_calibration_note_for(id)
	_talent_calibration_desc_edit.position = Vector2(10.0, 7.0)
	_talent_calibration_desc_edit.size = Vector2(480.0, 30.0)
	_talent_calibration_desc_edit.z_index = 91
	_talent_calibration_desc_edit.add_theme_font_size_override("font_size", 13)
	_talent_calibration_desc_edit.add_theme_color_override("font_color", Color(0.92, 0.96, 1.0))
	_talent_calibration_desc_edit.add_theme_color_override("font_placeholder_color", Color(0.45, 0.57, 0.68))
	_talent_calibration_desc_edit.text_changed.connect(func(new_text: String) -> void:
		_talent_calibration_notes_by_id[id] = new_text.strip_edges()
	)
	_talent_calibration_desc_edit.text_submitted.connect(func(_txt: String) -> void:
		_save_current_talent_calibration_note()
		_write_talent_calibration_file(false)
	)
	desc_panel.add_child(_talent_calibration_desc_edit)

	for key_any in _talent_calibration_positions.keys():
		var key: String = key_any as String
		var p: Vector2 = _talent_norm_to_screen(_talent_calibration_positions[key] as Vector2)
		_add_calibration_dot(layer, p, Color(0.25, 1.0, 0.55), key)

	var current_pos: Vector2 = _tech_tree_pos(id)
	_add_calibration_dot(layer, current_pos, Color(1.0, 0.84, 0.16), "atual")

	_add_calibration_rect(layer, _talent_text_rect_screen(), Color(0.30, 0.92, 1.0, 0.86))
	if _talent_calibration_dragging:
		var start: Vector2 = _talent_calibration_drag_start
		var end: Vector2 = _talent_calibration_drag_current
		var drag_rect:= Rect2(Vector2(minf(start.x, end.x), minf(start.y, end.y)), Vector2(absf(end.x - start.x), absf(end.y - start.y)))
		_add_calibration_rect(layer, drag_rect, Color(1.0, 0.72, 0.18, 0.95))


func _talentos_liberados_agora_count() -> int:
	var total: int = 0
	for tid_any in _TECH_TREE_IDS:
		var tid: String = tid_any as String
		if Salvar.pode_comprar_talento(tid):
			total += 1
	return total


func _tech_constellation_screen_positions() -> Dictionary:
	var out: Dictionary = {"raiz": _tech_tree_pos("raiz")}
	for tid_any in _tech_main_tree_ids():
		var tid: String = tid_any as String
		if Salvar.TALENTOS_INFO.has(tid):
			out[tid] = _tech_tree_pos(tid)
	return out


func _tech_constellations_for_screen() -> Array:
	var out: Array = []
	for group_any in _TECH_CONSTELLATIONS:
		var group: Dictionary = (group_any as Dictionary).duplicate(true)
		if group.has("label"):
			group["label_screen"] = _talent_norm_to_screen(group["label"] as Vector2)
		out.append(group)
	return out


func _tech_constellation_node_titles() -> Dictionary:
	var out: Dictionary = {}
	var ids: Array = ["raiz"]
	ids.append_array(_tech_main_tree_ids())
	for id_any in ids:
		var id: String = id_any as String
		if not Salvar.TALENTOS_INFO.has(id):
			continue
		var info: Dictionary = Salvar.TALENTOS_INFO[id] as Dictionary
		var nome_linhas: PackedStringArray = (info.get("nome", id) as String).split("\n", false, 1)
		var titulo: String = _texto_ui_limpo(nome_linhas[0] if nome_linhas.size() > 0 else id)
		var subtitulo: String = _texto_ui_limpo(nome_linhas[1] if nome_linhas.size() > 1 else (info.get("ramo", "") as String))
		out[id] = {
			"title": titulo,
			"sub": subtitulo,
			"cost": 0 if id == "raiz" else Salvar.custo_efetivo_talento(id),
		}
	return out


func _talent_req_names(reqs: Array, missing_only: bool = false) -> String:
	var nomes: PackedStringArray = PackedStringArray()
	for r_any in reqs:
		var rid: String = r_any as String
		if rid == "" or rid == "raiz":
			continue
		if missing_only and Salvar.talento_ativo(rid):
			continue
		var req_info: Dictionary = Salvar.TALENTOS_INFO.get(rid, {}) as Dictionary
		var nome: String = _texto_ui_limpo((req_info.get("nome", rid) as String).replace("\n", " "))
		if nome != "":
			nomes.append(nome)
	if nomes.is_empty() and missing_only:
		return _talent_req_names(reqs, false)
	return ", ".join(nomes)


func _tech_constellation_states() -> Dictionary:
	var out: Dictionary = {"raiz": {"active": true, "available": false}}
	for tid_any in _tech_main_tree_ids():
		var tid: String = tid_any as String
		if not Salvar.TALENTOS_INFO.has(tid):
			continue
		out[tid] = {
			"active": Salvar.talento_ativo(tid),
			"available": Salvar.pode_comprar_talento(tid),
			"color": _tech_branch_color_for_id(tid),
		}
	return out


func _criar_constellation_layer(pai: Control) -> void:
	var layer: Control = CONSTELLATION_FUNDO.new()
	layer.position = Vector2.ZERO
	layer.size = get_viewport().get_visible_rect().size
	layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.z_index = 4
	pai.add_child(layer)
	_talent_constellation_layer = layer
	if layer.has_method("setup"):
		layer.call("setup", _tech_constellations_for_screen(), _tech_constellation_screen_positions(), _tech_constellation_states(), [], _tech_constellation_node_titles())


func _criar_painel_mapa_estelar(pai: Control) -> void:
	var panel_rect: Rect2 = _talent_text_rect_screen()
	var pad: float = maxf(8.0, panel_rect.size.x * 0.05)
	var cover:= Panel.new()
	cover.position = panel_rect.position
	cover.size = panel_rect.size
	cover.z_index = 23
	cover.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var cover_sty:= StyleBoxFlat.new()
	cover_sty.bg_color = Color(0.006, 0.010, 0.018, 0.72)
	cover_sty.border_color = Color(0.24, 0.72, 1.0, 0.38)
	cover_sty.shadow_color = Color(0.0, 0.60, 1.0, 0.18)
	cover_sty.shadow_size = 8
	for side in ["left", "right", "top", "bottom"]:
		cover_sty.set("border_width_" + side, 2)
	for corner in ["top_left", "top_right", "bottom_left", "bottom_right"]:
		cover_sty.set("corner_radius_" + corner, 10)
	cover.add_theme_stylebox_override("panel", cover_sty)
	cover.draw.connect(func() -> void:
		var rr: Rect2 = Rect2(Vector2.ZERO, cover.size)
		var header: Rect2 = Rect2(8.0, 8.0, maxf(8.0, cover.size.x - 16.0), 34.0)
		var desc_box: Rect2 = Rect2(10.0, 104.0, maxf(8.0, cover.size.x - 20.0), maxf(58.0, cover.size.y - 238.0))
		var status_box: Rect2 = Rect2(10.0, maxf(168.0, cover.size.y - 124.0), maxf(8.0, cover.size.x - 20.0), 78.0)
		cover.draw_rect(header, Color(0.02, 0.06, 0.10, 0.58), true)
		cover.draw_rect(header, Color(0.22, 0.80, 1.0, 0.20), false, 1.0)
		cover.draw_line(Vector2(14.0, 51.0), Vector2(cover.size.x - 14.0, 51.0), Color(1.0, 0.74, 0.16, 0.28), 1.0, true)
		cover.draw_rect(desc_box, Color(0.004, 0.018, 0.030, 0.58), true)
		cover.draw_rect(desc_box, Color(0.18, 0.72, 1.0, 0.24), false, 1.0)
		cover.draw_rect(status_box, Color(0.035, 0.022, 0.006, 0.52), true)
		cover.draw_rect(status_box, Color(1.0, 0.72, 0.14, 0.24), false, 1.0)
		var mark: Color = Color(1.0, 0.76, 0.18, 0.52)
		cover.draw_line(Vector2(0.0, 18.0), Vector2(16.0, 0.0), mark, 1.2, true)
		cover.draw_line(Vector2(cover.size.x, 18.0), Vector2(cover.size.x - 16.0, 0.0), mark, 1.2, true)
		cover.draw_line(Vector2(0.0, cover.size.y - 18.0), Vector2(16.0, cover.size.y), mark, 1.2, true)
		cover.draw_line(Vector2(cover.size.x, cover.size.y - 18.0), Vector2(cover.size.x - 16.0, cover.size.y), mark, 1.2, true)
	)
	pai.add_child(cover)
	_talento_detalhe_cover = cover

	_talento_detalhe_nome = Label.new()
	_talento_detalhe_nome.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_talento_detalhe_nome.position = panel_rect.position + Vector2(pad, pad + 46.0)
	_talento_detalhe_nome.size = Vector2(panel_rect.size.x - pad * 2.0, 32.0)
	_talento_detalhe_nome.z_index = 32
	_talento_detalhe_nome.add_theme_font_size_override("font_size", 18)
	_talento_detalhe_nome.add_theme_color_override("font_color", Color(0.92, 0.96, 1.0))
	pai.add_child(_talento_detalhe_nome)

	_talento_detalhe_sub = Label.new()
	_talento_detalhe_sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_talento_detalhe_sub.position = panel_rect.position + Vector2(pad, pad + 78.0)
	_talento_detalhe_sub.size = Vector2(panel_rect.size.x - pad * 2.0, 24.0)
	_talento_detalhe_sub.z_index = 32
	_talento_detalhe_sub.add_theme_font_size_override("font_size", 12)
	_talento_detalhe_sub.add_theme_color_override("font_color", Color(0.56, 0.82, 1.0))
	pai.add_child(_talento_detalhe_sub)

	_talento_detalhe_desc = Label.new()
	_talento_detalhe_desc.position = panel_rect.position + Vector2(pad + 4.0, pad + 118.0)
	_talento_detalhe_desc.size = Vector2(panel_rect.size.x - pad * 2.0 - 8.0, maxf(80.0, panel_rect.size.y - 252.0))
	_talento_detalhe_desc.z_index = 32
	_talento_detalhe_desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_talento_detalhe_desc.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	_talento_detalhe_desc.add_theme_font_size_override("font_size", 12)
	_talento_detalhe_desc.add_theme_color_override("font_color", Color(0.80, 0.86, 0.94))
	pai.add_child(_talento_detalhe_desc)

	_talento_detalhe_estado = Label.new()
	_talento_detalhe_estado.position = panel_rect.position + Vector2(pad + 4.0, panel_rect.size.y - 116.0)
	_talento_detalhe_estado.size = Vector2(panel_rect.size.x - pad * 2.0 - 8.0, 74.0)
	_talento_detalhe_estado.z_index = 32
	_talento_detalhe_estado.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_talento_detalhe_estado.add_theme_font_size_override("font_size", 11)
	_talento_detalhe_estado.add_theme_color_override("font_color", Color(1.0, 0.82, 0.38))
	pai.add_child(_talento_detalhe_estado)

	_apply_talent_detail_layout()
	# Card oculto por padrao — aparece ao selecionar um no
	_ocultar_card_talento()


func _apply_talent_detail_layout() -> void:
	if _talento_detalhe_nome == null or not is_instance_valid(_talento_detalhe_nome):
		return
	var panel_rect: Rect2 = _talent_text_rect_screen()
	var pad: float = maxf(8.0, panel_rect.size.x * 0.05)
	var inner_w: float = maxf(24.0, panel_rect.size.x - pad * 2.0)
	if _talento_detalhe_cover != null and is_instance_valid(_talento_detalhe_cover):
		_talento_detalhe_cover.position = panel_rect.position
		_talento_detalhe_cover.size = panel_rect.size
	_talento_detalhe_nome.position = panel_rect.position + Vector2(pad, pad + 12.0)
	_talento_detalhe_nome.size = Vector2(inner_w, 32.0)
	if _talento_detalhe_sub != null and is_instance_valid(_talento_detalhe_sub):
		_talento_detalhe_sub.position = panel_rect.position + Vector2(pad, pad + 78.0)
		_talento_detalhe_sub.size = Vector2(inner_w, 24.0)
	if _talento_detalhe_desc != null and is_instance_valid(_talento_detalhe_desc):
		_talento_detalhe_desc.position = panel_rect.position + Vector2(pad + 4.0, pad + 118.0)
		_talento_detalhe_desc.size = Vector2(maxf(24.0, inner_w - 8.0), maxf(54.0, panel_rect.size.y - 252.0))
	if _talento_detalhe_estado != null and is_instance_valid(_talento_detalhe_estado):
		_talento_detalhe_estado.position = panel_rect.position + Vector2(pad + 4.0, maxf(pad + 170.0, panel_rect.size.y - 116.0))
		_talento_detalhe_estado.size = Vector2(maxf(24.0, inner_w - 8.0), 74.0)


func _ocultar_card_talento() -> void:
	if _talento_detalhe_cover and is_instance_valid(_talento_detalhe_cover):
		_talento_detalhe_cover.visible = false
	for lbl in [_talento_detalhe_nome, _talento_detalhe_sub, _talento_detalhe_desc, _talento_detalhe_estado]:
		if lbl and is_instance_valid(lbl):
			lbl.visible = false


func _mostrar_detalhe_talento(id: String) -> void:
	if _talento_detalhe_nome == null or not is_instance_valid(_talento_detalhe_nome):
		return
	# Revelar card na primeira selecao
	if _talento_detalhe_cover and is_instance_valid(_talento_detalhe_cover):
		_talento_detalhe_cover.visible = true
	for lbl in [_talento_detalhe_nome, _talento_detalhe_sub, _talento_detalhe_desc, _talento_detalhe_estado]:
		if lbl and is_instance_valid(lbl):
			lbl.visible = true
	var info: Dictionary = Salvar.TALENTOS_INFO[id] as Dictionary
	var parts: PackedStringArray = (info["nome"] as String).split("\n", false, 1)
	var cor: Color = info["cor"] as Color
	var ativo: bool = Salvar.talento_ativo(id)
	var pode: bool = Salvar.pode_comprar_talento(id)
	var custo: int = Salvar.custo_efetivo_talento(id)
	_talento_detalhe_nome.text = _texto_ui_limpo(parts[0])
	_talento_detalhe_nome.add_theme_color_override("font_color", Color(cor.r + 0.15, cor.g + 0.10, cor.b + 0.06, 1.0))
	_talento_detalhe_sub.text = _texto_ui_limpo(parts[1] if parts.size() > 1 else "O INICIO")
	_talento_detalhe_sub.add_theme_color_override("font_color", Color(cor.r, cor.g, cor.b, 0.96))
	_talento_detalhe_desc.text = _texto_ui_limpo(info.get("efeito", info.get("desc", "")) as String)
	if id == "raiz" or ativo:
		_talento_detalhe_estado.text = "COMPRADO\nTecnologia ativa na conta."
		_talento_detalhe_estado.add_theme_color_override("font_color", Color(0.55, 1.0, 0.70))
	elif pode:
		_talento_detalhe_estado.text = "LIBERADO PARA COMPRAR\nCusto: %d cristais.\nToque 3x na estrela." % custo
		_talento_detalhe_estado.add_theme_color_override("font_color", Color(0.52, 0.92, 1.0))
	else:
		var reqs: Array = Salvar.requisitos_talento(id)
		var req_str: String = _talent_req_names(reqs, true)
		_talento_detalhe_estado.text = "BLOQUEADO\nFalta: %s\nCusto: %d cristais." % [req_str, custo]
		_talento_detalhe_estado.add_theme_color_override("font_color", Color(0.78, 0.78, 0.82))


func _criar_hitbox_talento(id: String, pai: Control, tooltip: Panel) -> void:
	var centro: Vector2 = _no_pos_talento(id)
	var hit_size: Vector2 = _talent_hitbox_size(id)
	var parent_is_panel: bool = pai == _talentos_panel
	var offset: Vector2 = Vector2.ZERO if parent_is_panel else Vector2(0.0, _talentos_content_y_off)
	var btn:= Button.new()
	btn.text = ""
	btn.position = centro - hit_size * 0.5 - offset
	btn.size = hit_size
	btn.z_index = 18
	btn.focus_mode = Control.FOCUS_NONE
	for state in ["normal", "hover", "pressed", "disabled"]:
		var st:= StyleBoxFlat.new()
		st.bg_color = Color(0, 0, 0, 0)
		st.border_color = Color(0, 0, 0, 0)
		btn.add_theme_stylebox_override(state, st)
	btn.mouse_entered.connect(func() -> void:
		_mostrar_detalhe_talento(id)
	)
	btn.pressed.connect(func() -> void:
		_acionar_talento_mapa(id, tooltip)
	)
	pai.add_child(btn)
	_talent_map_hitboxes[id] = btn


func _acionar_talento_mapa(id: String, tooltip: Panel) -> void:
	_mostrar_detalhe_talento(id)
	if id == "raiz":
		return
	var info_t: Dictionary = Salvar.TALENTOS_INFO[id] as Dictionary
	var nome_t: String = _texto_ui_limpo((info_t["nome"] as String).replace("\n", " "))
	var efeito_t: String = _texto_ui_limpo(info_t.get("efeito", info_t.get("desc", "")) as String)
	var custo_t: int = Salvar.custo_efetivo_talento(id)
	var ja_ativo: bool = Salvar.talento_ativo(id)
	var pode_c: bool = Salvar.pode_comprar_talento(id)
	var estado: String = "Já ativo." if ja_ativo else ("Custo: %d cristais." % custo_t if pode_c else "Bloqueado. Custo: %d cristais." % custo_t)
	var desc_fala: String = _texto_ui_limpo("%s. %s %s" % [nome_t, efeito_t, estado])
	if Acessibilidade.ativo:
		Acessibilidade.processar("talento_" + id, desc_fala, func():
			if pode_c:
				_comprar_talento_no(id)
		)
		return
	if _talento_pendente != id:
		_talento_pendente = id
		_talento_pendente_toques = 1
	else:
		_talento_pendente_toques += 1
	if ja_ativo or not pode_c:
		_talento_pendente_toques = 1
		return
	if _talento_detalhe_estado and is_instance_valid(_talento_detalhe_estado):
		if _talento_pendente_toques < 3:
			_talento_detalhe_estado.text = "LIBERADO PARA COMPRAR\nToque mais %d vez(es) para comprar.\nCusto: %d cristais." % [3 - _talento_pendente_toques, custo_t]
		else:
			_talento_pendente = ""
			_talento_pendente_toques = 0
			tooltip.visible = false
			_comprar_talento_no(id)


func _build_tab_ramos(fundo: Control, tooltip: Panel, content: Control) -> void :
	fundo.linhas.clear()
	fundo.visible = true
	_criar_constellation_layer(_talentos_panel)
	_criar_painel_mapa_estelar(_talentos_panel)
	_criar_hitbox_talento("raiz", _talentos_panel, tooltip)

	for nid_any in _TECH_TREE_IDS:
		var nid: String = nid_any as String
		if _TECH_FUSION_IDS.has(nid):
			continue
		if Salvar.TALENTOS_INFO.has(nid):
			_criar_hitbox_talento(nid, _talentos_panel, tooltip)


func _build_tab_fusoes(fundo: Control, tooltip: Panel, content: Control) -> void :
	var _vp_w_fus: float = get_viewport().get_visible_rect().size.x
	var _vp_h_fus: float = get_viewport().get_visible_rect().size.y
	var cols: int = 2 if _vp_w_fus >= 940.0 else 1
	var card_gap: float = 18.0
	var card_w: float = minf(510.0, (_vp_w_fus - 72.0 - float(cols - 1) * card_gap) / float(cols))
	var card_h: float = 154.0
	var total_w: float = float(cols) * card_w + float(cols - 1) * card_gap
	var start_x: float = (_vp_w_fus - total_w) * 0.5
	var start_y: float = 64.0
	var recipes: Array = _fusion_recipes()
	var rows: int = int(ceil(float(recipes.size()) / float(cols)))
	content.custom_minimum_size = Vector2(_vp_w_fus, maxf(content.custom_minimum_size.y, start_y + float(rows) * (card_h + card_gap) + 72.0))

	var sec:= Label.new()
	sec.text = "MODULOS DE FUSAO  -  junte emblemas de ramos para liberar tecnologias hibridas"
	sec.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sec.position = Vector2(0, 18.0)
	sec.size = Vector2(_vp_w_fus, 22)
	sec.z_index = 5
	sec.add_theme_font_size_override("font_size", 20)
	sec.add_theme_color_override("font_color", Color(0.55, 0.82, 0.55))
	content.add_child(sec)

	for fi in range(recipes.size()):
		var rec: Dictionary = recipes[fi] as Dictionary
		var col: int = fi % cols
		var row: int = fi / cols
		var pos := Vector2(start_x + float(col) * (card_w + card_gap), start_y + float(row) * (card_h + card_gap))
		_criar_card_fusao(content, tooltip, rec.get("id", "") as String, rec.get("reqs", []) as Array, pos, Vector2(card_w, card_h))


func _fusion_recipes() -> Array:
	return [
		{"id": "colosso", "reqs": ["p1", "r1", "f1"]},
		{"id": "predador", "reqs": ["s2", "g1"]},
		{"id": "alquim", "reqs": ["m2", "f2"]},
		{"id": "tita", "reqs": ["p4", "r4"]},
		{"id": "relamp", "reqs": ["e3", "s3"]},
		{"id": "canhao_g", "reqs": ["p3", "g3"]},
	]


func _criar_card_fusao(pai: Control, tooltip: Panel, id: String, reqs: Array, pos: Vector2, tam: Vector2) -> void:
	if id == "" or not Salvar.TALENTOS_INFO.has(id):
		return
	var info: Dictionary = Salvar.TALENTOS_INFO[id] as Dictionary
	var cor: Color = info.get("cor", Color(1.0, 0.55, 0.12)) as Color
	var ativo: bool = Salvar.talento_ativo(id)
	var pode: bool = Salvar.pode_comprar_talento(id)

	var card:= Panel.new()
	card.position = pos
	card.size = tam
	card.z_index = 5
	card.mouse_filter = Control.MOUSE_FILTER_PASS
	var sty:= StyleBoxFlat.new()
	sty.bg_color = Color(0.018, 0.014, 0.010, 0.78)
	sty.border_color = Color(cor.r, cor.g, cor.b, 0.75 if ativo or pode else 0.30)
	for side in ["left", "right", "top", "bottom"]:
		sty.set("border_width_" + side, 2)
	for corner in ["top_left", "top_right", "bottom_left", "bottom_right"]:
		sty.set("corner_radius_" + corner, 10)
	card.add_theme_stylebox_override("panel", sty)
	pai.add_child(card)

	var nome:= Label.new()
	nome.text = _texto_ui_limpo((info.get("nome", id) as String).replace("\n", " "))
	nome.position = Vector2(14.0, 10.0)
	nome.size = Vector2(tam.x - 28.0, 36.0)
	nome.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	nome.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	nome.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	nome.clip_text = true
	nome.add_theme_font_size_override("font_size", 15)
	nome.add_theme_color_override("font_color", Color(cor.r + 0.10, cor.g + 0.08, cor.b + 0.04, 1.0))
	card.add_child(nome)

	var input_y: float = 72.0
	var req_count: int = max(1, reqs.size())
	var input_start_x: float = 28.0
	var input_gap: float = minf(54.0, maxf(40.0, (tam.x * 0.42) / float(req_count)))
	for i in range(reqs.size()):
		var req_id: String = reqs[i] as String
		var center := Vector2(input_start_x + float(i) * input_gap, input_y)
		_criar_glyph_fusao(card, tooltip, req_id, center, 20.0, false)
		if i < reqs.size() - 1:
			var plus:= Label.new()
			plus.text = "+"
			plus.position = center + Vector2(input_gap * 0.5 - 9.0, -12.0)
			plus.size = Vector2(18.0, 22.0)
			plus.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			plus.add_theme_font_size_override("font_size", 18)
			plus.add_theme_color_override("font_color", Color(0.95, 0.82, 0.36, 0.90))
			card.add_child(plus)

	var arrow:= Label.new()
	arrow.text = ">"
	arrow.position = Vector2(tam.x * 0.49 - 12.0, input_y - 17.0)
	arrow.size = Vector2(32.0, 32.0)
	arrow.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	arrow.add_theme_font_size_override("font_size", 26)
	arrow.add_theme_color_override("font_color", Color(1.0, 0.72, 0.22, 0.78))
	card.add_child(arrow)

	var out_center := Vector2(tam.x * 0.67, input_y)
	_criar_glyph_fusao(card, tooltip, id, out_center, 32.0, true)

	var deco:= ColorRect.new()
	deco.position = Vector2(tam.x * 0.76, 103.0)
	deco.size = Vector2(tam.x * 0.18, 1.5)
	deco.color = Color(cor.r, cor.g, cor.b, 0.34)
	deco.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(deco)

	var status:= Label.new()
	status.text = _fusion_status_card_text(id, reqs)
	status.position = Vector2(14.0, tam.y - 39.0)
	status.size = Vector2(tam.x - 28.0, 32.0)
	status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	status.clip_text = true
	status.add_theme_font_size_override("font_size", 11)
	status.add_theme_color_override("font_color", Color(0.48, 1.0, 0.66) if ativo else (Color(0.54, 0.92, 1.0) if pode else Color(0.86, 0.68, 0.42)))
	card.add_child(status)


func _criar_glyph_fusao(pai: Control, tooltip: Panel, id: String, centro: Vector2, half: float, interativo: bool) -> void:
	if not Salvar.TALENTOS_INFO.has(id):
		return
	var no:= TALENTO_NO.new()
	no.id = id
	no.cor = _tech_branch_color_for_id(id)
	no.ativo = Salvar.talento_ativo(id)
	no.pode = Salvar.pode_comprar_talento(id)
	no.position = centro - Vector2(half, half)
	no.size = Vector2(half * 2.0, half * 2.0)
	no.pivot_offset = Vector2(half, half)
	no.z_index = 8
	no.hover_in.connect(func(hid: String) -> void:
		var screen_pos: Vector2 = pai.get_global_rect().position + centro
		_mostrar_tooltip(tooltip, hid, screen_pos)
	)
	no.hover_out.connect(func() -> void:
		tooltip.visible = false
	)
	if interativo:
		no.pressionado.connect(func(hid: String) -> void:
			var screen_pos: Vector2 = pai.get_global_rect().position + centro
			_acionar_fusao_card(hid, tooltip, screen_pos)
		)
	pai.add_child(no)


func _acionar_fusao_card(id: String, tooltip: Panel, screen_pos: Vector2) -> void:
	_mostrar_tooltip(tooltip, id, screen_pos)
	if Salvar.talento_ativo(id):
		return
	if not Salvar.pode_comprar_talento(id):
		return
	if _talento_pendente != id:
		_talento_pendente = id
		_talento_pendente_toques = 1
	else:
		_talento_pendente_toques += 1
	var le_confirm: Label = tooltip.get_node("LEf") as Label
	if _talento_pendente_toques < 3:
		le_confirm.text = "Toque mais %d vez(es) para fundir este modulo." % (3 - _talento_pendente_toques)
		le_confirm.add_theme_color_override("font_color", Color(1.0, 0.78, 0.18))
		return
	_talento_pendente = ""
	_talento_pendente_toques = 0
	tooltip.visible = false
	_comprar_talento_no(id)


func _fusion_status_text(id: String, reqs: Array) -> String:
	if Salvar.talento_ativo(id):
		return "FUSAO ATIVA"
	if Salvar.pode_comprar_talento(id):
		return "PRONTO PARA FUNDIR  |  toque 3x no modulo maior"
	var faltando:= PackedStringArray()
	for req_any in reqs:
		var req_id: String = req_any as String
		if not Salvar.talento_ativo(req_id):
			var req_info: Dictionary = Salvar.TALENTOS_INFO.get(req_id, {}) as Dictionary
			faltando.append(_texto_ui_limpo((req_info.get("nome", req_id) as String).replace("\n", " ")))
	return "REQUER:\n%s" % ", ".join(faltando)


func _fusion_status_card_text(id: String, reqs: Array) -> String:
	if Salvar.talento_ativo(id):
		return "FUSAO ATIVA"
	if Salvar.pode_comprar_talento(id):
		return "PRONTO PARA FUNDIR"
	var faltando: int = 0
	for req_any in reqs:
		if not Salvar.talento_ativo(req_any as String):
			faltando += 1
	if faltando == 1:
		return "FALTA 1 REQUISITO"
	return "FALTAM %d REQUISITOS" % faltando


func _build_tab_especiais(fundo: Control, tooltip: Panel, content: Control) -> void :
	var yoff: float = _talentos_content_y_off

	var _vp_w_esp: float = get_viewport().get_visible_rect().size.x
	var header_y := 24.0
	var sit_lbl:= Label.new()
	sit_lbl.text = "PROTOCOLOS  -  tecnologias situacionais de combate"
	sit_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sit_lbl.position = Vector2(0, header_y)
	sit_lbl.size = Vector2(_vp_w_esp, 22)
	sit_lbl.z_index = 5
	sit_lbl.add_theme_font_size_override("font_size", 20)
	sit_lbl.add_theme_color_override("font_color", Color(0.88, 0.72, 0.28))
	content.add_child(sit_lbl)

	var sit_nodes: Array = ["cazador", "exter", "anti_t", "purif"]
	for si in range(sit_nodes.size()):
		var nid: String = sit_nodes[si] as String
		_criar_no_talento(nid, content, tooltip)


	var leg_sep:= ColorRect.new()
	leg_sep.position = Vector2(40, 362.0 - yoff)
	leg_sep.size = Vector2(_vp_w_esp - 80.0, 1)
	leg_sep.color = Color(0.6, 0.5, 0.28, 0.35)
	leg_sep.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.add_child(leg_sep)

	var leg_lbl:= Label.new()
	leg_lbl.text = "LEGADO  -  tecnologias liberadas por feitos da conta"
	leg_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	leg_lbl.position = Vector2(0, 368.0 - yoff)
	leg_lbl.size = Vector2(_vp_w_esp, 22)
	leg_lbl.z_index = 5
	leg_lbl.add_theme_font_size_override("font_size", 20)
	leg_lbl.add_theme_color_override("font_color", Color(0.6, 0.5, 0.28))
	content.add_child(leg_lbl)


	var prog_texts: Array = [
		"100 partidas jogadas  (%d / 100)" % Salvar.total_partidas, 
		"10.000 kills totais  (%d / 10000)" % Salvar.total_mobs_mortos, 
		"Atingir a wave 30  (melhor: %d)" % Salvar.melhor_wave, 
	]
	if Salvar.legado_debug_liberado():
		prog_texts = [
			"DEBUG liberado  (%d / 100)" % Salvar.total_partidas,
			"DEBUG liberado  (%d / 10000)" % Salvar.total_mobs_mortos,
			"DEBUG liberado  (melhor: %d)" % Salvar.melhor_wave,
		]
	var leg_nodes: Array = ["veteran", "genoci", "sobrev"]
	for li in range(leg_nodes.size()):
		var nid: String = leg_nodes[li] as String
		_criar_no_talento(nid, content, tooltip)
		var pl:= Label.new()
		pl.text = prog_texts[li] as String
		pl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		var px: Vector2 = _no_pos_talento(nid)
		var pl_mobile := OS.has_feature("android") or OS.has_feature("ios")
		var pl_w : float = 230.0 if pl_mobile else 190.0
		pl.position = Vector2(px.x - pl_w * 0.5, px.y - yoff + _no_half + 12.0)
		pl.size = Vector2(pl_w, 42)
		pl.z_index = 5
		pl.autowrap_mode = TextServer.AUTOWRAP_WORD
		pl.add_theme_font_size_override("font_size", 16 if pl_mobile else 18)
		var desbloq_leg: bool = Salvar.pode_comprar_talento(nid) or Salvar.talento_ativo(nid)
		pl.add_theme_color_override("font_color", 
			Color(0.4, 0.9, 0.45) if desbloq_leg else Color(0.65, 0.55, 0.38))
		content.add_child(pl)


func _no_pos_talento(id: String) -> Vector2:

	match _tab_talentos:
		"ramos":
			if id == "raiz" or (not _TECH_FUSION_IDS.has(id) and _TECH_TREE_IDS.has(id)):
				return _tech_tree_pos(id)
		"fusoes":
			var fusoes_order: Array = ["colosso", "predador", "alquim", "tita", "relamp", "canhao_g"]
			var fi: int = fusoes_order.find(id)
			if fi >= 0:
				var xs: Array = _fus_xs
				var ys: Array = _fus_ys
				return Vector2(xs[fi % 3] as float, ys[fi / 3] as float)
		"especiais":
			var sit_order: Array = ["cazador", "exter", "anti_t", "purif"]
			var si: int = sit_order.find(id)
			if si >= 0:
				return Vector2(_sit_xs[si] as float, _sit_y)
			var leg_order: Array = ["veteran", "genoci", "sobrev"]
			var li: int = leg_order.find(id)
			if li >= 0:
				return Vector2(_leg_xs[li] as float, _leg_y)
	var vp_cx: float = get_viewport().get_visible_rect().size.x * 0.5
	return Vector2(vp_cx, 340.0)


func _mk_tooltip() -> Panel:
	var tp:= Panel.new()
	tp.visible = false
	tp.size = Vector2(480, 330)
	tp.z_index = 20
	var sty:= StyleBoxFlat.new()
	sty.bg_color = Color(0.04, 0.04, 0.07, 0.97)
	sty.border_color = Color(0.55, 0.35, 1.0, 0.8)
	for side in ["left", "right", "top", "bottom"]:
		sty.set("border_width_" + side, 2)
	for corner in ["top_left", "top_right", "bottom_left", "bottom_right"]:
		sty.set("corner_radius_" + corner, 10)
	tp.add_theme_stylebox_override("panel", sty)

	var ln:= Label.new();ln.name = "LNome"
	ln.position = Vector2(14, 12)
	ln.size = Vector2(452, 32)
	ln.add_theme_font_size_override("font_size", 22)
	ln.add_theme_color_override("font_color", Color(0.9, 0.85, 1.0))
	tp.add_child(ln)

	var ls:= Label.new();ls.name = "LSub"
	ls.position = Vector2(14, 42)
	ls.size = Vector2(452, 22)
	ls.add_theme_font_size_override("font_size", 14)
	ls.add_theme_color_override("font_color", Color(0.72, 0.68, 0.85))
	tp.add_child(ls)

	var sep:= ColorRect.new()
	sep.color = Color(0.55, 0.35, 1.0, 0.35)
	sep.position = Vector2(14, 72)
	sep.size = Vector2(452, 2)
	tp.add_child(sep)

	var ld:= Label.new();ld.name = "LDesc"
	ld.position = Vector2(14, 82)
	ld.size = Vector2(452, 170)
	ld.autowrap_mode = TextServer.AUTOWRAP_WORD
	ld.add_theme_font_size_override("font_size", 16)
	ld.add_theme_color_override("font_color", Color(0.7, 0.74, 0.8))
	tp.add_child(ld)

	var le:= Label.new();le.name = "LEf"
	le.position = Vector2(14, 258)
	le.size = Vector2(452, 62)
	le.autowrap_mode = TextServer.AUTOWRAP_WORD
	le.add_theme_font_size_override("font_size", 15)
	le.add_theme_color_override("font_color", Color(0.35, 1.0, 0.5))
	tp.add_child(le)
	return tp


func _criar_no_raiz_talento(pai: Control, tooltip: Panel) -> void:
	var info: Dictionary = Salvar.TALENTOS_INFO["raiz"] as Dictionary
	var cor: Color = info["cor"] as Color
	var centro: Vector2 = _tech_tree_root_pos()
	var half: float = _talento_no_half("raiz")

	var no:= TALENTO_NO.new()
	no.id = "raiz"
	no.cor = cor
	no.ativo = true
	no.pode = false
	no.position = centro - Vector2(half, half) - Vector2(0.0, _talentos_content_y_off)
	no.size = Vector2(half * 2.0, half * 2.0)
	no.pivot_offset = Vector2(half, half)
	no.scale = Vector2(0.72, 0.72)
	no.z_index = 8
	no.hover_in.connect(func(hid: String): _mostrar_tooltip(tooltip, hid, _tech_tree_root_pos()))
	no.hover_out.connect(func(): tooltip.visible = false)
	no.gui_input.connect(func(ev: InputEvent) -> void:
		if _is_primary_press(ev):
			_mostrar_tooltip(tooltip, "raiz", _tech_tree_root_pos())
	)
	pai.add_child(no)
	var tw_root:= create_tween()
	_tree_tweens.append(tw_root)
	tw_root.tween_property(no, "scale", Vector2(1.0, 1.0), 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

	var lbl:= Label.new()
	lbl.text = "NUCLEO"
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.position = Vector2(centro.x - 82.0, centro.y - _talentos_content_y_off - half - 30.0)
	lbl.size = Vector2(164.0, 24.0)
	lbl.z_index = 9
	lbl.add_theme_font_size_override("font_size", 15)
	lbl.add_theme_color_override("font_color", Color(0.55, 0.9, 1.0))
	pai.add_child(lbl)


func _criar_no_talento(id: String, pai: Control, tooltip: Panel) -> void :
	if id == "raiz":
		return
	var info: Dictionary = Salvar.TALENTOS_INFO[id] as Dictionary
	var cor: Color = info["cor"] as Color
	var ativo: bool = Salvar.talento_ativo(id)
	var pode: bool = Salvar.pode_comprar_talento(id)
	var centro: Vector2 = _no_pos_talento(id)

	var no:= TALENTO_NO.new()
	no.id = id
	no.cor = cor
	no.ativo = ativo
	no.pode = pode
	var half: float = _talento_no_half(id)
	no.position = centro - Vector2(half, half) - Vector2(0.0, _talentos_content_y_off)
	no.size = Vector2(half * 2.0, half * 2.0)
	no.pivot_offset = Vector2(half, half)
	no.scale = Vector2(0.55, 0.55)
	no.hover_in.connect( func(hid: String): _mostrar_tooltip(tooltip, hid, _no_pos_talento(hid)))
	no.hover_out.connect( func(): tooltip.visible = false)

	var id_cap:= id
	no.gui_input.connect( func(ev: InputEvent) -> void :
		if not _is_primary_press(ev): return
		var info_t: Dictionary = Salvar.TALENTOS_INFO[id_cap] as Dictionary
		var nome_t: String = (info_t["nome"] as String).replace("\n", " ")
		var efeito_t: String = info_t.get("efeito", info_t.get("desc", "")) as String
		var custo_t: int = Salvar.custo_efetivo_talento(id_cap)
		var ja_ativo: bool = Salvar.talento_ativo(id_cap)
		var pode_c: bool = Salvar.pode_comprar_talento(id_cap)
		var estado: String
		if ja_ativo:
			estado = "Já ativo."
		elif pode_c:
			estado = "Custo: %d cristais. Clique 3 vezes para comprar." % custo_t
		else:
			estado = "Bloqueado. Custo: %d cristais." % custo_t
		nome_t = _texto_ui_limpo(nome_t)
		efeito_t = _texto_ui_limpo(efeito_t)
		estado = _texto_ui_limpo(estado)
		var desc_fala: String = _texto_ui_limpo("%s. %s %s" % [nome_t, efeito_t, estado])
		if Acessibilidade.ativo:

			if ja_ativo:
				Acessibilidade.processar("talento_" + id_cap, desc_fala, 
					func(): pass)
			elif pode_c:
				Acessibilidade.processar("talento_" + id_cap, desc_fala, 
					func(): _comprar_talento_no(id_cap))
			else:
				Acessibilidade.processar("talento_" + id_cap, desc_fala, 
					func(): pass)
		else:

			if _talento_pendente != id_cap:
				_talento_pendente = id_cap
				_talento_pendente_toques = 1
				_mostrar_tooltip(tooltip, id_cap, _no_pos_talento(id_cap))
			else:
				_talento_pendente_toques += 1
				_mostrar_tooltip(tooltip, id_cap, _no_pos_talento(id_cap))
				if ja_ativo or not pode_c:
					_talento_pendente_toques = 1
					return
				var le_confirm: Label = tooltip.get_node("LEf") as Label
				if _talento_pendente_toques < 3:
					le_confirm.text = "Toque mais 1 vez para comprar (%d/3)" % _talento_pendente_toques
					le_confirm.add_theme_color_override("font_color", Color(1.0, 0.78, 0.18))
				else:
					_talento_pendente = ""
					_talento_pendente_toques = 0
					tooltip.visible = false
					_comprar_talento_no(id_cap)
	)
	pai.add_child(no)
	var tw:= create_tween()
	_tree_tweens.append(tw)
	var delay: float = clampf((centro.y - 130.0) / 2200.0, 0.0, 0.22)
	tw.tween_property(no, "scale", Vector2(1.0, 1.0), 0.20).set_delay(delay).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _mostrar_tooltip(tooltip: Panel, id: String, node_pos: Vector2) -> void :
	var info: Dictionary = Salvar.TALENTOS_INFO[id] as Dictionary
	var cor: Color = info["cor"] as Color
	var ativo: bool = Salvar.talento_ativo(id)
	var pode: bool = Salvar.pode_comprar_talento(id)
	var custo: int = Salvar.custo_efetivo_talento(id)

	var sty:= StyleBoxFlat.new()
	sty.bg_color = Color(0.04, 0.04, 0.07, 0.97)
	sty.border_color = Color(cor.r, cor.g, cor.b, 0.9)
	for side in ["left", "right", "top", "bottom"]:
		sty.set("border_width_" + side, 2)
	for corner in ["top_left", "top_right", "bottom_left", "bottom_right"]:
		sty.set("corner_radius_" + corner, 10)
	tooltip.add_theme_stylebox_override("panel", sty)

	var parts: PackedStringArray = (info["nome"] as String).split("\n", false, 1)
	var ln: Label = tooltip.get_node("LNome") as Label
	ln.text = _texto_ui_limpo(parts[0])
	ln.add_theme_color_override("font_color", Color(cor.r + 0.1, cor.g + 0.05, cor.b, 1.0))
	var ls: Label = tooltip.get_node("LSub") as Label
	ls.text = _texto_ui_limpo(parts[1] if parts.size() > 1 else "")
	ls.visible = parts.size() > 1

	var ld: Label = tooltip.get_node("LDesc") as Label
	ld.text = _texto_ui_limpo(info["efeito"] as String)

	var le: Label = tooltip.get_node("LEf") as Label
	if id == "raiz" or ativo:
		le.text = "OK  Tecnologia ativa"
		le.add_theme_color_override("font_color", Color(0.3, 1.0, 0.45))
	elif pode:
		le.text = "Custo: %d cristais  |  Toque 3x para desbloquear" % custo
		le.add_theme_color_override("font_color", Color(0.55, 0.9, 1.0))
	else:
		var reqs: Array = Salvar.requisitos_talento(id)
		var req_str: String = _talent_req_names(reqs, true)
		le.text = "Falta: %s  |  Custo: ◆%d" % [req_str, custo]
		le.add_theme_color_override("font_color", Color(0.65, 0.35, 0.35))


	var sv: float = _talentos_scroll.get_v_scroll() if (_talentos_scroll and is_instance_valid(_talentos_scroll)) else 0.0
	var tp_w: float = tooltip.size.x
	var tp_h: float = tooltip.size.y
	var vp_w_t: float = get_viewport().get_visible_rect().size.x
	var vp_h_t: float = get_viewport().get_visible_rect().size.y
	var off: float = _talento_no_half(id) + 8.0
	var tp_x: float = node_pos.x + off
	var tp_y: float = node_pos.y - sv - 60.0

	if tp_x + tp_w > vp_w_t - 4.0:
		tp_x = node_pos.x - off - tp_w
	tp_x = clamp(tp_x, 4.0, vp_w_t - tp_w - 4.0)
	tp_y = clamp(tp_y, 70.0, vp_h_t - tp_h - 10.0)
	tooltip.position = Vector2(tp_x, tp_y)
	tooltip.visible = true


func _comprar_talento_no(id: String) -> void :
	if Salvar.comprar_talento(id):
		Som.upgrade()
		_rebuild_talentos()


func _fechar_talentos() -> void :
	Acessibilidade.cancelar_foco()
	_talento_pendente = ""
	_talento_pendente_toques = 0
	for tw in _tree_tweens:
		if is_instance_valid(tw):
			(tw as Tween).kill()
	_tree_tweens.clear()
	_talentos_scroll = null
	if _talentos_overlay:
		_talentos_overlay.queue_free()
	if _talentos_panel:
		_talentos_panel.queue_free()
	_talentos_overlay = null
	_talentos_panel = null
	_ui_ref = null
	if _menu_contents:
		_menu_contents.show()


func _cores(n: int, c: Color) -> PackedColorArray:
	var arr:= PackedColorArray()
	arr.resize(n)
	arr.fill(c)
	return arr
