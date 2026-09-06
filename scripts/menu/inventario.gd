extends RefCounted
## Modulo do menu - INVENTARIO + BAUS (Fase 3 da modularizacao).
## Helpers de sprite/reward compartilhados ficam no menu (acesso via m).
## Extraido de menu.gd em 2026-06-12 (tools/extrair_inventario.ps1).

var m  # menu principal (menu.gd)

func _init(menu) -> void:
	m = menu


func limpar_refs() -> void:
	# Resize recria a UI inteira: solta as referencias sem queue_free
	_inventario_overlay = null
	_bau_abertura_overlay = null
	_inventario_scroll_bar = null
	_inventario_scroll_content = null
	_inventario_scroll_tween = null
	_inventario_scroll_enabled = false

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
var _inventario_overlay: ColorRect = null
var _bau_abertura_overlay: ColorRect = null


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
				m.get_viewport().set_input_as_handled()
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
		m.get_viewport().set_input_as_handled()
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
	if not _inventario_scroll_area.has_point(m.get_viewport().get_mouse_position()):
		return
	_aplicar_scroll_mochila(delta)
	m.get_viewport().set_input_as_handled()


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
	_inventario_scroll_tween = m.create_tween()
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




func _abrir_bau_grande(ui: CanvasLayer, tier: String, ao_finalizar: Callable, preview: bool = false, recompensas_override: Array = [], titulo_override: String = "") -> void:
	var info: Dictionary = m._bau_info(tier)
	var cor : Color = info["cor"] as Color
	var luz : Color = info["luz"] as Color
	var recompensas_raw : Array = recompensas_override
	if recompensas_raw.is_empty():
		var r : Dictionary = Salvar.abrir_bau(tier, preview)
		if r.is_empty():
			return
		recompensas_raw = r.get("recompensas", []) as Array
	Som.bau_abertura_inicio(tier)
	var recompensas : Array = m._order_bau_reward_cards(recompensas_raw)
	var titulo_bau : String = titulo_override.strip_edges()
	if titulo_bau == "":
		titulo_bau = ("%s  PREVIEW" % str(info["nome"]) if preview else str(info["nome"]))
	var vp: Vector2 = m.get_viewport().get_visible_rect().size
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
	var pnl: Panel = m._inv_painel(ov, (vp.x - pw) * 0.5, (vp.y - ph) * 0.5, pw, ph,
		Color(0.018, 0.024, 0.040, 0.98), Color(cor.r, cor.g, cor.b, 0.76), 2)
	m._inv_lbl(pnl, titulo_bau.to_upper(), 0, 18, pw, 36, 30,
		Color(cor.r + 0.12, cor.g + 0.12, cor.b + 0.12), HORIZONTAL_ALIGNMENT_CENTER)
	var status_lbl: Label = m._inv_lbl(pnl, "Abrindo...", 0, 56, pw, 24, 16,
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
		m._draw_bau_icon(chest, tier, 1, prog)
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
			var raridade_card : String = m._reward_card_rarity(item)
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
				m._draw_reward_card_base(fx, Rect2(Vector2.ZERO, Vector2(card_w, card_h)), raridade_card, 0.96)
				fx.draw_rect(Rect2(20.0, 39.0, card_w - 40.0, card_h - 82.0), Color(0.0, 0.0, 0.0, 0.22), true)
				for gi in range(5, 0, -1):
					fx.draw_circle(Vector2(cx, cy), 24.0 + float(gi) * 8.0, Color(rc.r, rc.g, rc.b, 0.024 / float(gi)))
				fx.draw_arc(Vector2(cx, cy), 42.0 + sin(now * 2.4 + float(idx)) * 1.5, now * 0.55, now * 0.55 + TAU * 0.82, 58,
					Color(rc.r, rc.g, rc.b, 0.42), 1.6, true)
				if tipo == "pet" or tipo == "pet_card":
					var portrait_area := Rect2(22.0, 39.0, card_w - 44.0, card_h - 86.0)
					m._draw_reward_commander_portrait(fx, item, portrait_area, 1.0)
				else:
					var icon_sz : float = 96.0 if tipo == "skin" else 84.0
					fx.draw_circle(Vector2(cx, cy), icon_sz * 0.46, Color(0.0, 0.0, 0.0, 0.40))
					if m._draw_reward_item_visual(fx, item, Rect2(cx - icon_sz * 0.5, cy - icon_sz * 0.5, icon_sz, icon_sz), 1.0):
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
			m._inv_lbl(card, tipo_txt.to_upper(), 8.0, 14.0, card_w - 16.0, 18.0, 11,
				Color(rc.r + 0.18, rc.g + 0.18, rc.b + 0.18, 0.86), HORIZONTAL_ALIGNMENT_CENTER)
			var nome_lbl: Label = m._inv_lbl(card, nome_r, 10.0, card_h - 66.0, card_w - 20.0, 34.0, 13,
				Color(0.94, 0.96, 1.0), HORIZONTAL_ALIGNMENT_CENTER)
			nome_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD
			m._inv_lbl(card, "x%d" % qtd_r, 0.0, card_h - 31.0, card_w, 22.0, 18,
				Color(rc.r + 0.2, rc.g + 0.2, rc.b + 0.2, 0.95), HORIZONTAL_ALIGNMENT_CENTER)

		var _add_collected_card := func(item: Dictionary, idx: int) -> void:
			var tipo : String = str(item.get("tipo", ""))
			var rc : Color = _reward_color_big.call(tipo) as Color
			var raridade_card : String = m._reward_card_rarity(item)
			var count : int = int(collected_cont.get_child_count())
			var gap_m : float = collected_gap
			var mini_w : float = final_mini_w
			var mini_h : float = mini_w * 1.22
			var total_w_m : float = mini_w * float(total) + gap_m * float(maxi(total - 1, 0))
			var start_x_m : float = (collected_cont.size.x - total_w_m) * 0.5
			var mini: Panel = m._inv_painel(collected_cont, start_x_m + float(count) * (mini_w + gap_m), strip_h - mini_h - 5.0, mini_w, mini_h,
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
				m._draw_reward_card_base(fx_m, Rect2(Vector2.ZERO, Vector2(mini_w, mini_h)), raridade_card, 0.88)
				var cx : float = mini_w * 0.5
				var cy : float = mini_h * 0.48
				if tipo == "pet" or tipo == "pet_card":
					var portrait_area := Rect2(mini_w * 0.115, mini_h * 0.115, mini_w * 0.77, mini_h * 0.64)
					m._draw_reward_commander_portrait(fx_m, item, portrait_area, 1.0)
				else:
					fx_m.draw_circle(Vector2(cx, cy), mini_w * 0.26, Color(rc.r, rc.g, rc.b, 0.18))
					fx_m.draw_arc(Vector2(cx, cy), mini_w * 0.28, 0.0, TAU, 42, Color(rc.r, rc.g, rc.b, 0.78), 1.5, true)
					var mini_icon := Rect2(cx - mini_w * 0.27, cy - mini_w * 0.27, mini_w * 0.54, mini_w * 0.54)
					if m._draw_reward_item_visual(fx_m, item, mini_icon, 1.0):
						pass
					else:
						fx_m.draw_string(ThemeDB.fallback_font, Vector2(0.0, cy + 7.0), _reward_icon_big.call(tipo) as String,
							HORIZONTAL_ALIGNMENT_CENTER, mini_w, 20.0, Color.WHITE)
			)
			var short_name : String = nome_m
			if short_name.length() > 9:
				short_name = short_name.substr(0, 8) + "."
			m._inv_lbl(mini, short_name, 4.0, mini_h - 23.0, mini_w - 8.0, 13.0, 8,
				Color(0.92, 0.94, 1.0, 0.88), HORIZONTAL_ALIGNMENT_CENTER)
			m._inv_lbl(mini, "x%d" % qtd_m, 0.0, mini_h - 13.0, mini_w, 12.0, 9,
				Color(rc.r + 0.18, rc.g + 0.18, rc.b + 0.18, 0.96), HORIZONTAL_ALIGNMENT_CENTER)
			var pop: Tween = m.create_tween()
			pop.set_parallel(true)
			pop.tween_property(mini, "modulate:a", 1.0, 0.12)
			pop.tween_property(mini, "scale", Vector2(1.0, 1.0), 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

		var _criar_verso := func(card: Panel, idx: int, item: Dictionary, tap_cb: Callable) -> void:
			var tipo : String = str(item.get("tipo", ""))
			var rc : Color = _reward_color_big.call(tipo) as Color
			var raridade_card : String = m._reward_card_rarity(item)
			var fx := Control.new()
			fx.size = Vector2(card_w, card_h)
			fx.mouse_filter = Control.MOUSE_FILTER_IGNORE
			card.add_child(fx)
			fx.draw.connect(func():
				var now : float = Time.get_ticks_msec() * 0.001
				var cx : float = card_w * 0.5
				var cy : float = card_h * 0.48
				m._draw_reward_card_base(fx, Rect2(Vector2.ZERO, Vector2(card_w, card_h)), raridade_card, 0.90)
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
			m._inv_lbl(card, "CARTA", 8.0, 16.0, card_w - 16.0, 18.0, 12,
				Color(rc.r + 0.20, rc.g + 0.20, rc.b + 0.20, 0.86), HORIZONTAL_ALIGNMENT_CENTER)
			m._inv_lbl(card, "TOQUE", 8.0, card_h - 35.0, card_w - 16.0, 18.0, 12,
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
			var fly: Tween = m.create_tween()
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
					var center_tw: Tween = m.create_tween()
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
			var special_item : bool = m._is_reward_showcase_item(item)
			var base_rot : float = card.rotation_degrees
			var flip: Tween = m.create_tween()
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
					m._show_reward_special_overlay(ov, item, func():
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
			var card: Panel = m._inv_painel(current_slot, center_pos.x, center_pos.y, card_w, card_h,
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
			var tw: Tween = m.create_tween()
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
	m.get_tree().create_timer(abertura_dur + 0.16, true).timeout.connect(func():
		if is_instance_valid(ov):
			status_lbl.text = "Toque na carta para revelar."
			Som.bau_abertura_final(tier)
			if is_instance_valid(chest):
				chest.hide()
			rewards_cont.visible = true
			_build_rewards_big.call()
	)




func _abrir_inventario(ui: CanvasLayer) -> void:
	if m._menu_contents:
		m._menu_contents.hide()
	Salvar.normalizar_cons_equipados()
	if _inventario_overlay and is_instance_valid(_inventario_overlay):
		_inventario_overlay.queue_free()

	var _mob : bool = BuildConfig.is_mobile()
	var vp: Vector2 = m.get_viewport().get_visible_rect().size
	var ov  := ColorRect.new()
	ov.color = Color(0.0, 0.0, 0.0, 0.97); ov.size = vp
	ui.add_child(ov)
	_inventario_overlay = ov
	var _cmd_meta_top: Dictionary = m._comandante_meta(str(Salvar.pet_ativo))
	var _cmd_cor_top : Color = _cmd_meta_top["cor"] as Color
	m._inv_fundo_comando(ov, vp, _cmd_cor_top)
	m._ui_panel_frame(ov, Rect2(8.0, 8.0, vp.x - 16.0, minf(vp.y - 16.0, 704.0)), Color(0.42, 0.70, 0.95), 0.82)

	var _fechar_inventario := func() -> void:
		var _cmd_mudou: bool = m._menu_comandante_atual != m._comandante_home_visual_pid()
		_inventario_arsenal_aberto = false
		_inventario_filtro_atual = "tudo"
		ov.queue_free()
		if _inventario_overlay == ov:
			_inventario_overlay = null
		if _cmd_mudou:
			m.get_tree().change_scene_to_file("res://scenes/Menu.tscn")
			return
		if m._menu_contents:
			m._menu_contents.show()

	m._ui_header_title(ov, "INVENT\u00c1RIO", 20.0, vp.x, _cmd_cor_top)
	m._add_currency_status(ov, Vector2(maxf(14.0, vp.x - 252.0), 18.0), true, 90)

	var mel     := Salvar.melhorias
	var t_dano  : float = 35.0 + (mel.get("forca",       0) as int) * 8.0
	var t_hp    : float = 170.0 + (mel.get("resistencia",0) as int) * 40.0
	var t_cad   : float = 1.2  + (mel.get("cadencia",   0) as int) * 0.2
	var t_range : float = 220.0 + (mel.get("visao",      0) as int) * 25.0
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

	var sp_h : float = (660.0 - TY) if _mob else 574.0  # mobile: termina no mesmo y=660 do PC (antes 660 estourava o separador)
	var sp: Panel = m._inv_painel(ov, SX, TY, SW, sp_h,
		Color(0.018,0.025,0.040,0.96), Color(0.24,0.48,0.72,0.45), 1)
	m._inv_decorar_painel(sp, Color(0.30,0.65,1.0), 0.75)
	m._inv_titulo_secao(ov, "ESTAT\u00cdSTICAS", SX, TY-20, SW, Color(0.42,0.72,1.0))

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
		m._ui_stat_icon(stats_content, skind, sc2, (2.0 if _mob else 9.0), sy2 + (5.0 if _mob else 4.0), 26.0)
		m._inv_lbl(stats_content, st[0] as String, (32 if _mob else 42), sy2+2, (int(SW*0.62) if _mob else SW-112), 28, 14, Color(0.76,0.84,0.92,0.90))
		m._inv_lbl(stats_content, st[1] as String, (int(SW*0.68) if _mob else SW-72), sy2+2, (SW-int(SW*0.68) if _mob else 64), 28, 14,
			Color(sc2.r+0.15,sc2.g+0.15,sc2.b+0.15), HORIZONTAL_ALIGNMENT_RIGHT)
		sy2 += (42.0 if _mob else 36.0)
	stats_content.size = Vector2(SW, maxf(sp_h - 12.0, sy2 + 8.0))
	stats_content.custom_minimum_size = stats_content.size

	var upd_wrap : Array = [null]
	var _normal_center_nodes : Array = []
	var _arsenal_mode : Array = [_inventario_arsenal_aberto]

	var skp: Panel = m._inv_painel(ov, MX, TY, SKW, SKH,
		Color(skin_cor.r*0.09,skin_cor.g*0.09,skin_cor.b*0.09,0.95),
		Color(skin_cor.r,skin_cor.g,skin_cor.b,0.86), 2)
	m._inv_decorar_painel(skp, skin_cor, 1.0)
	_normal_center_nodes.append(skp)
	m._inv_titulo_secao(ov, "SKIN EQUIPADA", MX, TY-20, SKW, skin_cor, _normal_center_nodes)
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
	var _cmd_meta: Dictionary = m._comandante_meta(str(Salvar.pet_ativo))
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
	var _psprite_asp: String = m._item_sprite_key("pet", _pnome_asp, _ppid_asp)
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
				m._draw_item_sprite(pad, _psprite_asp, Rect2(pcx - 54.0, pcy - 66.0, 108.0, 132.0), am)
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
			pad.draw_string(m._font_tech,Vector2(0,ASH-58),
				_pnome_asp,HORIZONTAL_ALIGNMENT_CENTER,SQS,13,
				Color(pcc.r+0.25,pcc.g+0.25,pcc.b+0.25,0.9))
			pad.draw_string(m._font_tech,Vector2(0,ASH-42),
				_cmd_titulo_curto,HORIZONTAL_ALIGNMENT_CENTER,SQS,8,
				Color(0.78,0.78,0.84,0.82))
			pad.draw_string(m._font_tech,Vector2(0,ASH-28),
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
			pad.draw_string(m._font_tech,Vector2(0,ASH-5),_lv_str2,HORIZONTAL_ALIGNMENT_CENTER,SQS,10,Color(_cmd_cor.r+0.2,_cmd_cor.g+0.2,_cmd_cor.b+0.2,0.9))
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
			var hp2: Panel = m._inv_painel(ov, hpx, hpy, HAB_W, HAB_H,
				Color(hcor.r*0.14,hcor.g*0.14,hcor.b*0.14,0.96) if htm else Color(0.04,0.05,0.08,0.94),
				Color(hcor.r,hcor.g,hcor.b,0.75 if htm else 0.2), 2 if htm else 1)
			_normal_center_nodes.append(hp2)
			var hisd := Control.new(); hisd.size=Vector2(HAB_W,HAB_H)
			hisd.mouse_filter=Control.MOUSE_FILTER_IGNORE
			var hcc := hcor; var hhtm := htm; var hcg := cargas
			var hsprite: String = m._item_sprite_key("hab", hnome, hid)
			if not m._usar_sprite_key_na_mochila(hsprite):
				hsprite = ""
			hisd.draw.connect(func():
				var hcx:=HAB_W*0.5; var hcy:=HAB_H*0.40
				hisd.draw_circle(Vector2(hcx,hcy),20.0,Color(hcc.r*0.22,hcc.g*0.22,hcc.b*0.22,0.9))
				if hsprite != "":
					m._draw_item_sprite(hisd, hsprite, Rect2(hcx - 27.0, hcy - 27.0, 54.0, 54.0), 1.0 if hhtm else 0.35)
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
			m._inv_lbl(hp2,hshort,0,HAB_H-34,HAB_W,16,11,
				Color(hcor.r+0.2,hcor.g+0.2,hcor.b+0.2,0.9 if htm else 0.4),
				HORIZONTAL_ALIGNMENT_CENTER)
		else:
			var _empty_hp: Panel = m._inv_painel(ov, hpx, hpy, HAB_W, HAB_H, Color(0.03,0.04,0.06,0.7), Color(0.2,0.2,0.25,0.25), 1)
			_normal_center_nodes.append(_empty_hp)

	var _hlab: Label = m._inv_titulo_secao(ov, "HABILIDADES", hx0, TY-20, SQS, Color(0.48,0.78,1.0), _normal_center_nodes)
	_hlab.z_index = 5
	var scroll_y : float = TY + SKH + 32.0
	var scroll_w : float = RX - MX - 10.0
	var SCROLL_H : float = 662.0 - scroll_y
	var scr_p: Panel = m._inv_painel(ov, MX, scroll_y, scroll_w, SCROLL_H,
		Color(0.018,0.024,0.040,0.95), Color(0.28,0.42,0.60,0.36), 1)
	m._inv_decorar_painel(scr_p, Color(0.34,0.62,0.86), 0.45)
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
	var _upd_wrap_ref : Array = []  # preenchido após upd_wrap ser criado
	# Closure reutilizável — rebuild ao equipar/desequipar
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
			var _cp3: Panel = m._inv_painel(hcont,_ix2,0,_iw2,_ih2,
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
			var _cons_sprite: String = m._item_sprite_key("cons", str(_csi2["nome"]), str(_eq_id))
			if not m._usar_sprite_key_na_mochila(_cons_sprite):
				_cons_sprite = ""
			_in2.draw.connect(func():
				var _hf2 := Vector2(_iso2*0.5,_iso2*0.5); var _r2 := _iso2*0.46
				if _cons_sprite != "" and m._draw_item_sprite(_in2, _cons_sprite, Rect2(0.0, 0.0, _iso2, _iso2), _ia2):
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
			m._inv_lbl(_cp3,_csi2["nome"] as String,0,_iyn2,_iw2,15,10,
				Color(_cc2.r+0.2,_cc2.g+0.2,_cc2.b+0.1) if _ca2 else Color(0.38,0.38,0.42),HORIZONTAL_ALIGNMENT_CENTER)
			m._inv_lbl(_cp3,"%d/%d" % [_ce2,_cm2],0,_iyn2+16,_iw2,13,10,
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
	var _clab: Label = m._inv_lbl(ov, "CONSUM\u00cdVEIS", MX, scroll_y-16, scroll_w, 18, 11,
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
	m._inv_titulo_secao(arsenal_panel, "COMANDANTE", 0, 0, SKW, _cmd_cor)
	m._inv_titulo_secao(arsenal_panel, "ARSENAL DA TORRE", SKW + _slot_gap, 0, _aw - SKW - _slot_gap, Color(0.92,0.92,0.98))
	var _cmd_card: Panel = m._inv_painel(arsenal_panel, 0.0, 20.0, SKW, SKH,
		Color(0.008, 0.010, 0.016, 0.98),
		Color(_cmd_cor.r, _cmd_cor.g, _cmd_cor.b, 0.84), 2)
	_cmd_card.clip_contents = true
	m._inv_decorar_painel(_cmd_card, _cmd_cor, 0.58)
	var _cmd_portrait := Control.new()
	_cmd_portrait.name = "ComandanteSlotArte"
	_cmd_portrait.set_meta("art_fill_mode", "cover_full_slot")
	_cmd_portrait.size = Vector2(SKW, SKH)
	_cmd_portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_cmd_card.add_child(_cmd_portrait)
	var _cmd_sprite := _psprite_asp
	var _cmd_portrait_tex: Texture2D = m._comandante_sprite(_ppid_asp)
	var _cmd_nome := _pnome_asp
	var _cmd_pet_tem := pet_tem
	_cmd_portrait.draw.connect(func():
		var t := Time.get_ticks_msec() * 0.001
		_cmd_portrait.draw_rect(Rect2(Vector2.ZERO, Vector2(SKW, SKH)), Color(0.0, 0.0, 0.0, 0.92), true)
		if _cmd_pet_tem and _cmd_portrait_tex != null:
			m._draw_comandante_card_art(_cmd_portrait, _cmd_portrait_tex, Rect2(0.0, 0.0, SKW, SKH), _cmd_escura, 0.06 + 0.03 * sin(t * 1.2))
		elif _cmd_pet_tem and _cmd_sprite != "":
			var cc := Vector2(SKW * 0.5, SKH * 0.40)
			for ring in range(4):
				_cmd_portrait.draw_arc(cc, 58.0 + float(ring) * 18.0, -1.9 + sin(t * 0.3) * 0.2, 1.25, 64, Color(_cmd_cor.r, _cmd_cor.g, _cmd_cor.b, 0.050), 1.0, true)
			m._draw_item_sprite(_cmd_portrait, _cmd_sprite, Rect2(SKW * 0.5 - 78.0, 46.0, 156.0, 206.0), 1.0)
			_cmd_portrait.draw_line(Vector2(18, SKH - 128.0), Vector2(SKW - 18.0, SKH - 128.0), Color(_cmd_cor.r, _cmd_cor.g, _cmd_cor.b, 0.35), 1.0)
			_cmd_portrait.draw_string(m._font_tech, Vector2(0, SKH - 104.0), _cmd_nome.to_upper(), HORIZONTAL_ALIGNMENT_CENTER, SKW, 25, Color(_cmd_cor.r+0.18,_cmd_cor.g+0.18,_cmd_cor.b+0.18,0.98))
			_cmd_portrait.draw_string(m._font_tech, Vector2(0, SKH - 74.0), _cmd_titulo_curto, HORIZONTAL_ALIGNMENT_CENTER, SKW, 10, Color(0.84,0.82,0.88,0.82))
			_cmd_portrait.draw_string(m._font_tech, Vector2(0, SKH - 48.0), _cmd_coligacao_curta, HORIZONTAL_ALIGNMENT_CENTER, SKW, 12, Color(_cmd_cor.r+0.1,_cmd_cor.g+0.1,_cmd_cor.b+0.1,0.92))
		else:
			_cmd_portrait.draw_string(m._font_tech, Vector2(0, SKH * 0.45), "SEM COMANDANTE", HORIZONTAL_ALIGNMENT_CENTER, SKW, 14, Color(0.45,0.48,0.56,0.75))
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
		var _sp: Panel = m._inv_painel(arsenal_panel, _sx, _sy_a, _slot_w, _slot_h,
			Color(_sc.r*0.10,_sc.g*0.10,_sc.b*0.10,0.94) if _tem_item else Color(0.025,0.026,0.040,0.88),
			Color(_sc.r,_sc.g,_sc.b,0.58) if _tem_item else Color(0.14,0.15,0.20,0.45),
			2 if _tem_item else 1)
		m._inv_decorar_painel(_sp, _sc, 0.72 if _tem_item else 0.28)
		var _ico := Control.new()
		var _ico_max_h : float = _slot_h - (70.0 if _tem_item else 96.0)
		var _ico_size : float = minf(96.0, maxf(54.0, minf(_slot_w * 0.56, _ico_max_h)))
		_ico.position = Vector2((_slot_w - _ico_size) * 0.5, 20.0 if _tem_item else 30.0)
		_ico.size = Vector2(_ico_size,_ico_size)
		_ico.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_sp.add_child(_ico)
		var _slot_idx : int = _ai
		var _slot_sprite_key : String = m._item_sprite_key("arsenal", str(_ainfo.get("nome", "")), _eq_id)
		if not m._usar_sprite_key_na_mochila(_slot_sprite_key):
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
				if m._draw_item_sprite(_ico, _slot_sprite_key, Rect2(_c.x - _sprite_sz * 0.5, _c.y - _sprite_sz * 0.5, _sprite_sz, _sprite_sz)):
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
			m._inv_lbl(_sp, _sd[1] as String, 0, _slot_h - 74.0, _slot_w, 22, 15,
				Color(0.34,0.38,0.48,0.82),
				HORIZONTAL_ALIGNMENT_CENTER)
		var _item_nome_slot : String = (_ainfo.get("nome", _sd[2]) as String) if _tem_item else "Slot vazio"
		if _item_nome_slot.length() > 18:
			_item_nome_slot = _item_nome_slot.substr(0, 16) + ".."
		m._inv_lbl(_sp, _item_nome_slot, 8, _slot_h - (46.0 if _tem_item else 48.0), _slot_w-16, 18, 11,
			Color(0.58,0.66,0.78,0.82) if _tem_item else Color(0.28,0.31,0.38,0.68),
			HORIZONTAL_ALIGNMENT_CENTER)
		var _rar_txt : String = str(_ainfo.get("raridade", "vazio")).to_upper() if _tem_item else "VAZIO"
		m._inv_lbl(_sp, _rar_txt, 0, _slot_h - 25.0, _slot_w, 16, 10,
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
	var bp: Panel = m._inv_painel(ov, RX, TY, RW, bp_h,
		Color(0.030,0.026,0.044,0.97), Color(0.54,0.36,0.70,0.58), 2)
	m._inv_decorar_painel(bp, Color(0.72,0.42,1.0), 0.82)
	m._inv_titulo_secao(ov, "MOCHILA", RX, TY-20, RW, Color(0.72,0.42,1.0))
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

	m._inv_lbl(bp,"DETALHES",DET_X,4,DET_W,18,10,
		Color(0.5,0.5,0.75,0.6),HORIZONTAL_ALIGNMENT_CENTER)

	var det_icon2 := Control.new()
	var _ico_sz : float = 52.0 if _mob else 56.0
	det_icon2.position=Vector2(DET_X+(DET_W-_ico_sz)*0.5,26)
	det_icon2.size=Vector2(_ico_sz,_ico_sz); det_icon2.mouse_filter=Control.MOUSE_FILTER_IGNORE
	det_icon2.clip_contents = true
	bp.add_child(det_icon2)
	_anim_nodes.append(det_icon2)

	var det_nome: Label = m._inv_lbl(bp,"—",DET_X,88,DET_W,22,(22 if _mob else 16),
		Color(0.85,0.85,0.9),HORIZONTAL_ALIGNMENT_CENTER)
	var det_tipo: Label = m._inv_lbl(bp,"",DET_X,108,DET_W,18,(16 if _mob else 13),
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
	m._ui_tech_label(det_desc, 0.0)
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
				var _pmeta_desc: Dictionary = m._comandante_meta(_pdesc_pid)
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
			m._draw_bau_icon(det_icon2, str(sel_wrap[0].get("bau_id", "comum")), int(sel_wrap[0].get("qtd", 1)))
			return
		if it3d == "pet" and m._draw_comandante_face(det_icon2, str(sel_wrap[0].get("pid", "cyron")), Rect2(cx3 - 27.0, cy3 - 27.0, 54.0, 54.0)):
			return
		var sprite_key3: String = m._item_sprite_key_from_item(sel_wrap[0])
		if sprite_key3 != "" and m._usar_sprite_item_na_mochila(sel_wrap[0]):
			if m._draw_item_sprite(det_icon2, sprite_key3, Rect2(cx3 - 25.0, cy3 - 25.0, 50.0, 50.0)):
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
			cur = m._debug_liberar_preview_item(cur)
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
				cur = m._debug_liberar_preview_item(cur)
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
				cur = m._debug_liberar_preview_item(cur)
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
		var _binfo: Dictionary = m._bau_info(_btier_s)
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
		if not m.SHOW_PREMIUM_PURCHASES and bool(si2.get("premium", false)):
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
		if not m.SHOW_PREMIUM_PURCHASES and bool(_pi3.get("premium", false)):
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

	if m.DEBUG_MOCHILA_MOSTRAR_TODOS_ITENS and OS.is_debug_build():
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
			var _prev_binfo: Dictionary = m._bau_info(_prev_btier_s)
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
			if not m.SHOW_PREMIUM_PURCHASES and bool(_prev_si.get("premium", false)):
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

	# ── Filtros da mochila ──────────────────────────────────────────────────
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
		m.get_viewport().set_input_as_handled()
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
				var _ep: Panel = m._inv_painel(_slot_cont,sx3,sy3,SLOT_SZ,SLOT_SZ,Color(0.07,0.07,0.10,0.8),Color(0.2,0.2,0.25,0.2),1)
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
			var sprite_key_i: String = m._item_sprite_key_from_item(item)
			isd.draw.connect(func():
				var t2 := Time.get_ticks_msec() * 0.001
				var cx:=SLOT_SZ*0.5; var cy:=SLOT_SZ*0.42+sin(t2*1.1)*2.0
				if it=="bau":
					m._draw_bau_icon(isd, ibau, ibau_qtd)
				elif it=="pet" and m._draw_comandante_face(isd, ipid, m._comandante_face_slot_rect(SLOT_SZ)):
					pass
				elif sprite_key_i != "" and m._usar_sprite_item_na_mochila(item) and m._draw_item_sprite(isd, sprite_key_i, Rect2(cx - 30.0, cy - 30.0, 60.0, 60.0)):
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
			m._inv_lbl(sbtn,short,0,SLOT_SZ-16,SLOT_SZ,16,(13 if _mob else 11),
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
				m._inv_lbl(sbtn,"Nv.%d"%_plv,0,2,SLOT_SZ,14,(12 if _mob else 10),Color(icor.r+0.3,icor.g+0.3,icor.b+0.3,0.95),HORIZONTAL_ALIGNMENT_RIGHT)
			_slot_cont.add_child(sbtn)

	# ── Chamada inicial e marcar TUDO ativo ─────────────────────────────────
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
	m._corrigir_textos_ui(ov)


