extends RefCounted
## Modulo do menu - tela de LOJA (Fase 2 da modularizacao).
## Estado da tela vive aqui; helpers compartilhados ficam no menu (acesso via m).
## Extraido de menu.gd em 2026-06-12 (tools/extrair_loja.ps1).

var m  # menu principal (menu.gd)

func _init(menu) -> void:
	m = menu


func limpar_refs() -> void:
	# Resize recria a UI inteira: solta as referencias sem queue_free
	_loja_overlay = null
	_loja_panel = null
	_loja_scroll_cont = null
	_loja_scroll_node = null

var _loja_overlay = null
var _loja_panel = null
var _loja_scroll_cont: Control = null
var _loja_scroll_node: ScrollContainer = null
var _loja_cont_w: float = 1244.0


func _abrir_loja(ui: CanvasLayer) -> void :
	if _loja_overlay:
		return
	if m._menu_contents:
		m._menu_contents.hide()
	m._ui_ref = ui
	var _vp_loja: Vector2 = m.get_viewport().get_visible_rect().size
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


	var vp_w: float = m.get_viewport().get_visible_rect().size.x
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
	m._ui_ref.add_child(outer)
	_loja_panel = outer


	var titulo:= Label.new()
	titulo.text = "LOJA PERMANENTE"
	titulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	titulo.position = Vector2(0, 8)
	titulo.size = Vector2(vp_w, 40)
	titulo.add_theme_font_size_override("font_size", 34)
	titulo.add_theme_color_override("font_color", Color(1.0, 0.85, 0.15))
	m._ui_title_label(titulo, 4.0)
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
	m._add_currency_status(outer, Vector2(maxf(14.0, vp_w - 252.0), 54.0), true, 85)


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
	if m.SHOW_PREMIUM_PURCHASES:
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

	# ── COMANDANTES ────────────────────────────────────────────────────────────
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

	cont.custom_minimum_size = Vector2(cont_w, 2820 if m.SHOW_PREMIUM_PURCHASES else 2360)


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
	m._corrigir_textos_ui(outer)


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
	if recompensas.is_empty() or not m._ui_main or not is_instance_valid(m._ui_main):
		_rebuild_loja()
		return
	m._abrir_bau_grande(m._ui_main, tier, func(): _rebuild_loja(), false, recompensas, titulo)


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
				"%s — %s. Custo: %d ouro." % [nome_loja, desc_loja, custo], 
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
		"gelo": ["Reduz vel. 80% / 2.5s", "Boss: −40% vel.", "Cooldown: 45s"], 
		"devastador": ["Remove 35% HP atual", "Boss: −12% HP", "Cooldown: 45s"], 
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
				"%s — %s. Custo: %d cristais." % [info["nome"] as String, desc_h, custo], 
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
					icone.draw_string(f, ic+Vector2(-8, 7), "✦", HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color(c3.r+0.3, c3.g+0.3, c3.b+0.3, 0.9))
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
		["⚔  +4% Dano", Color(0.0, 1.0, 0.88)], 
		["⚡  +4% Cadência", Color(0.0, 1.0, 0.88)], 
		["ðŸŽ¯  +4% Alcance", Color(0.0, 1.0, 0.88)], 
		["♥  +1 HP/s Regen", Color(0.55, 1.0, 0.55)], 
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
		btn_principal.text = "FAÇA LOGIN PARA RESGATAR"
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
					btn_principal.text = erro if erro != "" else "Sem amostras disponíveis"
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
		restantes_lbl.text = "%d de %d amostras disponíveis" % [restantes, RankingOnline._BETA_MAX]
		restantes_lbl.add_theme_color_override("font_color", 
			Color(0.0, 1.0, 0.6) if restantes > 0 else Color(0.8, 0.25, 0.25))
		if not ja_tem and logado:
			btn_principal.disabled = restantes <= 0
	RankingOnline.beta_info_recebida.connect(_on_beta_info_loja, CONNECT_ONE_SHOT)
	RankingOnline.buscar_info_beta()


var _on_beta_info_loja: Callable = Callable()
var _beta_donos_cache: Array = []


func _abrir_painel_beta_donos() -> void :
	var vp: Vector2 = m.get_viewport().get_visible_rect().size
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
	sub.text = "Skin SaberPunk — Exclusiva"
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
			cnt_lbl.text = "Skin SaberPunk  •  %d/%d amostras resgatadas" %\
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
	if m.DEBUG_PREMIUM_TEST_PURCHASES:
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
		if m._draw_comandante_face(prev, ppid, Rect2(0.0, 0.0, prev.size.x, prev.size.y), am):
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
	var _cmd_mudou: bool = m._menu_comandante_atual != m._comandante_home_visual_pid()
	if _loja_overlay:
		_loja_overlay.queue_free()
	if _loja_panel:
		_loja_panel.queue_free()
	_loja_overlay = null
	_loja_panel = null
	_loja_scroll_cont = null
	_loja_scroll_node = null
	m._ui_ref = null
	if _cmd_mudou:
		m.get_tree().change_scene_to_file("res://scenes/Menu.tscn")
		return
	if m._menu_contents:
		m._menu_contents.show()

