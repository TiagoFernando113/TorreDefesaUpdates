extends CanvasLayer

const ICONE_SCENE = preload("res://scripts/icone_upgrade.gd")
const NumberFormatter = preload("res://scripts/number_formatter.gd")
const UI_COIN_TEXTURE_PATH : String = "res://assets/sprites/ui_hud/cytron_coin_icon.png"
const UI_CRYSTAL_TEXTURE_PATH : String = "res://assets/sprites/ui_hud/cyron_crystal_icon.png"
const UI_STATS_BUTTON_SHEET_PATH : String = "res://assets/sprites/ui_hud/stats_button_sheet.png"
const UI_STATS_BUTTON_FRAMES : int = 6

var jogo = null

var _hud          : Control = null
var _top_lbl      : Label   = null
var _currency_hud : Control = null
var _kills_lbl    : Label   = null
var _mod_lbl      : Label   = null
var _build_lbl    : Label   = null   # Identidade de Build
var _alma_overlay  = null            # Overlay do Sistema de Alma
var _upgrade_ativo := false
var _overlay       = null
var _panel         = null
var _pause_overlay  = null
var _vel_btns         : Array = []
var _carta_pendente_efeito : String = ""
var _carta_pendente_val    : float  = 0.0
var _carta_pendente_btn    : Button = null
var _token_icon    : Control = null
var _tooltip_panel  = null   # Tooltip do hover nas cartas
var _boss_hp_bar    = null   # Barra de HP do boss
var _boss_entrada_overlay : Control = null   # Overlay de entrada do boss (pode ser fechado)
var _mapa_resumo_overlay : Control = null
var _matchmaking_overlay : Control = null
var _habil_btns     : Dictionary = {}
var _consumivel_slots : Dictionary = {}
var _consumivel_btns  : Dictionary = {}
var _consumivel_lbls  : Dictionary = {}
var _consumivel_nome_lbls : Dictionary = {}
var _habil_cd_lbl   : Label = null
var _habil_cd_maxs  : Dictionary = {}   # id → max cd inicial
var _habil_cds_ui   : Dictionary = {}   # id → cd restante atual
var _btn_cors       : Dictionary = {}
var _btn_stys       : Dictionary = {}
var _hacker_btn     : Button = null
var _hacker_sty_n   : StyleBoxFlat = null
var _slot_drawer                   = null   # habil_slot_drawer.gd instance
var _habil_tooltip  : Control = null
var _iniciar_wave_btn = null
var _hud_gold : int = 0
var _hud_cristais : int = 0
var _hud_coin_tex : Texture2D = null
var _hud_crystal_tex : Texture2D = null
var _stats_button_tex : Texture2D = null

const UPGRADES_INFO := {
	"dano": {
		"nome": "DANO +",
		"desc": "Cada projétil causa\nmais dano por impacto.\nEficaz contra todos\nos tipos de inimigos.",
		"cor": Color(1.0, 0.42, 0.1),
	},
	"alcance": {
		"nome": "ALCANCE +",
		"desc": "Amplia o raio de\ndetecção da torre.\nAtaca inimigos antes\ndeles chegarem perto.",
		"cor": Color(0.12, 0.62, 1.0),
	},
	"cadencia": {
		"nome": "CADÊNCIA +",
		"desc": "Aumenta a velocidade\nde disparo da torre.\nMais tiros por segundo\nsignifica mais dano.",
		"cor": Color(0.75, 0.2, 1.0),
	},
	"vida": {
		"nome": "VIDA +",
		"desc": "Restaura 50 HP e\naumenta a vida máxima.\nEssencial para aguentar\nwaves mais longas.",
		"cor": Color(0.12, 1.0, 0.45),
	},
	"perfurante": {
		"nome": "PERFURANTE",
		"desc": "Projéteis atravessam\naté 3 inimigos antes\nde desaparecerem.\nÓtimo contra grupos.",
		"cor": Color(1.0, 0.88, 0.12),
	},
	"multitiro": {
		"nome": "MULTI-TIRO",
		"desc": "A torre dispara em\n2 alvos ao mesmo tempo.\nDobra a eficiência\ncontra múltiplos mobs.",
		"cor": Color(0.12, 1.0, 0.88),
	},
	"velocidade": {
		"nome": "VELOCIDADE +",
		"desc": "Projéteis se movem\nmuito mais rápido.\nMobs rápidos não\nconseguem escapar.",
		"cor": Color(0.95, 0.95, 0.12),
	},
	"regeneracao": {
		"nome": "REGENERAÇÃO",
		"desc": "A torre recupera\n2 HP por segundo\nautomaticamente\ndurante o combate.",
		"cor": Color(0.4, 1.0, 0.55),
	},
}


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_criar_hud()


func _criar_hud() -> void:
	_hud = Control.new()
	_hud.set_anchors_preset(Control.PRESET_FULL_RECT)
	_hud.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_hud.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(_hud)

	_top_lbl = Label.new()
	_top_lbl.position = Vector2(18, 10)
	_top_lbl.size     = Vector2(820, 36)
	_top_lbl.add_theme_font_size_override("font_size", 26)
	_top_lbl.add_theme_color_override("font_color", Color(0.65, 0.88, 1.0))
	_hud.add_child(_top_lbl)

	_currency_hud = Control.new()
	_currency_hud.position = Vector2(360, 8)
	_currency_hud.size = Vector2(230, 34)
	_currency_hud.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_currency_hud.draw.connect(_draw_currency_hud)
	_hud.add_child(_currency_hud)

	# Kills counter (wave atual)
	_kills_lbl = Label.new()
	_kills_lbl.position = Vector2(18, 46)
	_kills_lbl.size     = Vector2(600, 26)
	_kills_lbl.add_theme_font_size_override("font_size", 20)
	_kills_lbl.add_theme_color_override("font_color", Color(0.55, 0.78, 0.55))
	_hud.add_child(_kills_lbl)

	# Label do modificador de wave
	_mod_lbl = Label.new()
	_mod_lbl.position = Vector2(18, 66)
	_mod_lbl.size     = Vector2(400, 39)
	_mod_lbl.add_theme_font_size_override("font_size", 24)
	_mod_lbl.add_theme_color_override("font_color", Color(1.0, 0.62, 0.12))
	_hud.add_child(_mod_lbl)

	_criar_controles_velocidade()

	# Label da Identidade de Build (canto inferior esquerdo acima dos kills)
	_build_lbl = Label.new()
	var _vp_hud := get_viewport().get_visible_rect().size
	var _mobile_hud := OS.has_feature("android") or OS.has_feature("ios")
	_build_lbl.position = Vector2(12, maxf(84.0, _vp_hud.y - (136.0 if _mobile_hud else 30.0)))
	_build_lbl.size     = Vector2(500, 30)
	_build_lbl.add_theme_font_size_override("font_size", 20)
	_build_lbl.add_theme_color_override("font_color", Color(1.0, 0.88, 0.22, 0.0))
	_hud.add_child(_build_lbl)

	_criar_habil_hud()



func _load_hud_texture(path: String) -> Texture2D:
	if ResourceLoader.exists(path):
		return load(path) as Texture2D
	if FileAccess.file_exists(path):
		var img := Image.load_from_file(path)
		if img != null and img.get_width() > 0 and img.get_height() > 0:
			return ImageTexture.create_from_image(img)
	var abs_path := ProjectSettings.globalize_path(path)
	if abs_path != path and FileAccess.file_exists(abs_path):
		var img_abs := Image.load_from_file(abs_path)
		if img_abs != null and img_abs.get_width() > 0 and img_abs.get_height() > 0:
			return ImageTexture.create_from_image(img_abs)
	return null


func _format_hud_amount(value: int) -> String:
	return NumberFormatter.compact_int(value)


func _fmt_num(value: int) -> String:
	return NumberFormatter.compact_int(value)


func _fmt_float(value: float) -> String:
	return NumberFormatter.compact_float(value)


func _draw_hud_texture_contain(c: Control, tex: Texture2D, rect: Rect2, alpha: float = 1.0) -> bool:
	if tex == null:
		return false
	var tw := float(tex.get_width())
	var th := float(tex.get_height())
	if tw <= 0.0 or th <= 0.0:
		return false
	var scale : float = minf(rect.size.x / tw, rect.size.y / th)
	var dst_size := Vector2(tw * scale, th * scale)
	var dst := Rect2(rect.position + (rect.size - dst_size) * 0.5, dst_size)
	c.draw_texture_rect(tex, dst, false, Color(1.0, 1.0, 1.0, alpha))
	return true


func _draw_stats_button_sprite(c: Control) -> void:
	if _stats_button_tex == null:
		_stats_button_tex = _load_hud_texture(UI_STATS_BUTTON_SHEET_PATH)
	if _stats_button_tex == null:
		var fallback_rect : Rect2 = Rect2(Vector2.ZERO, c.size).grow(-8.0)
		c.draw_rect(fallback_rect, Color(0.05, 0.035, 0.0, 0.78), true)
		c.draw_rect(fallback_rect, Color(1.0, 0.76, 0.08, 0.92), false, 2.0)
		c.draw_string(ThemeDB.fallback_font, Vector2(0.0, c.size.y * 0.58),
			"ESTATISTICAS", HORIZONTAL_ALIGNMENT_CENTER, c.size.x, 18, Color(1.0, 0.85, 0.1))
		return
	var frame_count : int = max(1, UI_STATS_BUTTON_FRAMES)
	var frame_idx : int = 0
	if c.has_meta("frame"):
		frame_idx = int(c.get_meta("frame"))
	frame_idx = frame_idx % frame_count
	var frame_w : float = float(_stats_button_tex.get_width()) / float(frame_count)
	var frame_h : float = float(_stats_button_tex.get_height())
	if frame_w <= 0.0 or frame_h <= 0.0:
		return
	var src_rect : Rect2 = Rect2(Vector2(frame_w * float(frame_idx), 0.0), Vector2(frame_w, frame_h))
	var scale : float = minf(c.size.x / frame_w, c.size.y / frame_h)
	var dst_size : Vector2 = Vector2(frame_w * scale, frame_h * scale)
	var dst_rect : Rect2 = Rect2((c.size - dst_size) * 0.5, dst_size)
	c.draw_texture_rect_region(_stats_button_tex, dst_rect, src_rect, Color.WHITE)
	var hot: bool = c.get_meta("hot", false) == true
	var pressed: bool = c.get_meta("pressed", false) == true
	if hot or pressed:
		var accent := Color(0.35, 0.85, 1.0, 0.26 if hot else 0.0)
		if pressed:
			accent = Color(1.0, 0.82, 0.22, 0.34)
		var glow_rect := Rect2(Vector2.ZERO, c.size).grow(-6.0)
		c.draw_rect(glow_rect, Color(accent.r, accent.g, accent.b, accent.a * 0.22), true)
		c.draw_rect(glow_rect, Color(accent.r, accent.g, accent.b, accent.a), false, 2.0)


func _draw_hud_currency_pill(c: Control, rect: Rect2, tex: Texture2D, amount: int, accent: Color, fallback_crystal: bool = false) -> void:
	var icon_rect := Rect2(rect.position + Vector2(0.0, -4.0), Vector2(rect.size.y + 8.0, rect.size.y + 8.0))
	if not _draw_hud_texture_contain(c, tex, icon_rect, 1.0):
		var center := icon_rect.position + icon_rect.size * 0.5
		var radius := minf(icon_rect.size.x, icon_rect.size.y) * 0.42
		if fallback_crystal:
			var pts := PackedVector2Array([
				center + Vector2(0.0, -radius),
				center + Vector2(radius * 0.58, 0.0),
				center + Vector2(0.0, radius),
				center + Vector2(-radius * 0.58, 0.0),
			])
			var crystal_fill := Color(accent.r * 0.12, accent.g * 0.12, accent.b * 0.18, 0.95)
			c.draw_polygon(pts, PackedColorArray([crystal_fill, crystal_fill, crystal_fill, crystal_fill]))
			pts.append(pts[0])
			c.draw_polyline(pts, accent, 2.0, true)
		else:
			c.draw_circle(center, radius, Color(accent.r * 0.24, accent.g * 0.18, 0.02, 0.95))
			c.draw_arc(center, radius, 0.0, TAU, 56, accent, 2.0, true)
	var txt := _format_hud_amount(amount)
	var txt_pos := Vector2(rect.position.x + rect.size.y + 10.0, rect.position.y + 23.0)
	var txt_w := rect.size.x - rect.size.y - 10.0
	c.draw_string(ThemeDB.fallback_font, txt_pos + Vector2(1.5, 1.5),
		txt, HORIZONTAL_ALIGNMENT_LEFT, txt_w, 18, Color(0.0, 0.0, 0.0, 0.76))
	c.draw_string(ThemeDB.fallback_font, txt_pos,
		txt, HORIZONTAL_ALIGNMENT_LEFT, txt_w, 18, Color(0.94, 0.97, 1.0, 0.98))


func _draw_currency_hud() -> void:
	if _hud_coin_tex == null:
		_hud_coin_tex = _load_hud_texture(UI_COIN_TEXTURE_PATH)
	if _hud_crystal_tex == null:
		_hud_crystal_tex = _load_hud_texture(UI_CRYSTAL_TEXTURE_PATH)
	if _currency_hud == null:
		return
	var gap : float = 8.0
	var pill_w : float = (_currency_hud.size.x - gap) * 0.5
	_draw_hud_currency_pill(_currency_hud, Rect2(0.0, 0.0, pill_w, _currency_hud.size.y), _hud_coin_tex, _hud_gold, Color(1.0, 0.74, 0.12), false)
	_draw_hud_currency_pill(_currency_hud, Rect2(pill_w + gap, 0.0, pill_w, _currency_hud.size.y), _hud_crystal_tex, _hud_cristais, Color(0.42, 0.90, 1.0), true)


func _reposicionar_currency_hud(top_text: String) -> void:
	if _currency_hud == null or not is_instance_valid(_currency_hud):
		return
	var min_x : float = 340.0
	var desired_x : float = _top_lbl.position.x + minf(float(top_text.length()) * 13.0, 500.0) + 18.0
	var speed_x : float = get_viewport().get_visible_rect().size.x - 500.0
	if not _vel_btns.is_empty() and is_instance_valid(_vel_btns[0]):
		speed_x = (_vel_btns[0] as Button).position.x
	var max_x : float = speed_x - _currency_hud.size.x - 18.0
	var x : float = clampf(maxf(min_x, desired_x), min_x, maxf(min_x, max_x))
	_currency_hud.position = Vector2(x, 8.0)



func _criar_habil_hud() -> void:
	var ids    : Array  = Salvar.HABIL_INFO.keys()
	# Oculta tudo se nenhuma habilidade foi comprada
	var alguma_comprada : bool = false
	for _hk in ids:
		if (Salvar.habil_cargas.get(_hk, 0) as int) > 0:
			alguma_comprada = true
			break
	var has_hk : bool   = Salvar.pet_ativo_jogavel()
	var r      : float  = 40.0
	var step   : float  = r * 2.0 + 12.0   # centro a centro
	var hk_gap : float  = 18.0
	var total_w : float = float(ids.size()) * step - 12.0 + (hk_gap + r * 2.0 if has_hk else 0.0)
	var vp_size := get_viewport().get_visible_rect().size
	var vp_w   : float  = vp_size.x
	var cx0    : float  = (vp_w - total_w) * 0.5 + r   # centro x do primeiro slot
	var cy     : float  = minf(672.0, vp_size.y - r - 18.0) # centro y dos slots

	if not alguma_comprada and not has_hk:
		return

	# Conta apenas slots com cargas > 0 para calcular largura real
	var ids_visiveis : Array = []
	for _hv in ids:
		if (Salvar.habil_cargas.get(_hv, 0) as int) > 0:
			ids_visiveis.append(_hv)
	var n_vis : int = ids_visiveis.size()
	total_w = float(n_vis) * step - 12.0 + (hk_gap + r * 2.0 if has_hk else 0.0)
	cx0     = (vp_w - total_w) * 0.5 + r

	# Drawer procedural circular
	var scr := load("res://scripts/habil_slot_drawer.gd")
	_slot_drawer = scr.new()
	_slot_drawer.slot_cors    = []
	_slot_drawer.slot_nomes   = []
	_slot_drawer.slot_cargas  = []
	_slot_drawer.slot_cd_prog = []
	_slot_drawer.slot_cd_secs = []
	_slot_drawer.slot_centers = []
	_hud.add_child(_slot_drawer)

	for i in range(ids_visiveis.size()):
		var hid    : String     = ids_visiveis[i] as String
		var info   : Dictionary = Salvar.HABIL_INFO[hid] as Dictionary
		var cor    : Color      = info["cor"] as Color
		var cargas : int        = Salvar.habil_cargas.get(hid, 0) as int
		var nome   : String     = (info["nome"] as String).split(" ")[0]
		var center := Vector2(cx0 + float(i) * step, cy)

		_slot_drawer.slot_cors.append(cor)
		_slot_drawer.slot_nomes.append(nome)
		_slot_drawer.slot_cargas.append(cargas)
		_slot_drawer.slot_cd_prog.append(1.0)
		_slot_drawer.slot_cd_secs.append(0.0)
		_slot_drawer.slot_centers.append(center)
		_btn_cors[hid] = cor

		var btn := Button.new()
		btn.position   = center - Vector2(r, r)
		btn.size       = Vector2(r * 2.0, r * 2.0)
		btn.focus_mode = Control.FOCUS_NONE
		var sty_inv := StyleBoxEmpty.new()
		for st in ["normal","hover","pressed","disabled","hover_pressed","focus"]:
			btn.add_theme_stylebox_override(st, sty_inv)
		btn.disabled = false

		var hid_cap  := hid
		var info_cap := info
		var cor_cap  := cor
		btn.pressed.connect(func():
			var desc_a : String = "%s — %s" % [
				info_cap["nome"] as String,
				(info_cap["desc"] as String).replace("\n", " ")]
			Acessibilidade.processar("habil_" + hid_cap, desc_a, func():
				if jogo and is_instance_valid(jogo):
					jogo.call("ativar_habilidade", hid_cap))
		)
		btn.mouse_entered.connect(func():
			_mostrar_habil_tooltip(hid_cap, info_cap, cor_cap, btn.global_position))
		btn.mouse_exited.connect(_esconder_habil_tooltip)
		btn.gui_input.connect(func(event: InputEvent):
			_processar_toque_habil_tooltip(event, hid_cap, info_cap, cor_cap, btn))
		_hud.add_child(btn)
		_habil_btns[hid] = btn

	# Slot do Hacker
	if has_hk:
		var hcx : float = cx0 + float(n_vis) * step - 12.0 + hk_gap + r
		var hcenter := Vector2(hcx, cy)
		_slot_drawer.hk_ativo  = true
		_slot_drawer.hk_center = hcenter
		var _hk_pinfo : Dictionary = Salvar.PETS_INFO.get(Salvar.pet_ativo, {}) as Dictionary
		if not _hk_pinfo.is_empty():
			var _hk_stats : Dictionary = Salvar.pet_stats(Salvar.pet_ativo)
			_slot_drawer.hk_cor  = _hk_pinfo.get("cor",     Color(0.2,1.0,0.5)) as Color
			_slot_drawer.hk_nome = str(_hk_pinfo.get("hab_nome", "HACK"))
			_slot_drawer.hk_dur  = float(_hk_stats.get("hab_dur", _hk_pinfo.get("hab_dur", 15.0)))
			var _hk_icon_path : String = "res://assets/sprites/itens/assistente_cyron.png"
			match str(Salvar.pet_ativo):
				"nexus":
					_hk_icon_path = "res://assets/sprites/itens/assistente_dante.png"
				"phantom", "eclipse":
					_hk_icon_path = "res://assets/sprites/itens/assistente_phantom.png"
				"aurora":
					_hk_icon_path = "res://assets/sprites/itens/assistente_cyron.png"
			if ResourceLoader.exists(_hk_icon_path):
				_slot_drawer.hk_tex = load(_hk_icon_path) as Texture2D

		_hacker_btn = Button.new()
		_hacker_btn.position   = hcenter - Vector2(r, r)
		_hacker_btn.size       = Vector2(r * 2.0, r * 2.0)
		_hacker_btn.focus_mode = Control.FOCUS_NONE
		var sty_inv2 := StyleBoxEmpty.new()
		for st in ["normal","hover","pressed","disabled","hover_pressed","focus"]:
			_hacker_btn.add_theme_stylebox_override(st, sty_inv2)
		_hacker_btn.pressed.connect(func():
			if jogo and is_instance_valid(jogo) and jogo.pet_assistente and is_instance_valid(jogo.pet_assistente):
				jogo.pet_assistente.ativar_hacker()
		)
		_hud.add_child(_hacker_btn)

	_habil_tooltip = _criar_habil_tooltip_painel()
	_hud.add_child(_habil_tooltip)
	var _dummy_lbl := Label.new()
	_habil_cd_lbl = _dummy_lbl
	_hud.add_child(_habil_cd_lbl)


func atualizar_habil_cd(id: String, cd: float) -> void:
	if cd > 0.0:
		if (_habil_cds_ui.get(id, 0.0) as float) <= 0.0:
			_habil_cd_maxs[id] = cd   # guarda max na primeira chamada
		_habil_cds_ui[id] = cd
		if _habil_btns.has(id):
			var btn : Button = _habil_btns[id] as Button
			if is_instance_valid(btn): btn.disabled = true
	else:
		_habil_cds_ui.erase(id)
		_habil_cd_maxs.erase(id)
		# Reativa apenas este slot se ainda tem cargas
		if _habil_btns.has(id):
			var cargas : int = Salvar.habil_cargas.get(id, 0) as int
			var btn : Button = _habil_btns[id] as Button
			if is_instance_valid(btn): btn.disabled = cargas <= 0


func atualizar_habil_cargas() -> void:
	var ids : Array = Salvar.HABIL_INFO.keys()
	for i in range(ids.size()):
		var hid    : String = ids[i] as String
		var cargas : int    = Salvar.habil_cargas.get(hid, 0) as int
		if _slot_drawer and is_instance_valid(_slot_drawer) and i < _slot_drawer.slot_cargas.size():
			_slot_drawer.slot_cargas[i]  = cargas
			_slot_drawer.slot_cd_prog[i] = 1.0 if cargas > 0 else 0.0
		if _habil_btns.has(hid):
			var btn : Button = _habil_btns[hid] as Button
			if is_instance_valid(btn): btn.disabled = cargas <= 0


func mostrar_efeito_habil(id: String, cor: Color) -> void:
	# ── 1. Flash de tela ──────────────────────────────────────────────────────
	var flash := ColorRect.new()
	flash.color   = Color(cor.r, cor.g, cor.b, 0.38)
	flash.z_index = 50
	flash.set_anchors_preset(Control.PRESET_FULL_RECT)
	flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_hud.add_child(flash)
	var tw_flash := create_tween()
	tw_flash.tween_property(flash, "color:a", 0.0, 0.30)
	tw_flash.tween_callback(flash.queue_free)

	# ── 2. Ícone grande no centro ─────────────────────────────────────────────
	var icones : Dictionary = {"eletrico": "RAIO", "gelo": "GELO", "devastador": "DANO"}
	var icone_txt : String = icones.get(id, "UP")

	var ic := Label.new()
	ic.text                 = icone_txt
	ic.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ic.position             = Vector2(540, 260)
	ic.size                 = Vector2(200, 180)
	ic.z_index              = 51
	ic.add_theme_font_size_override("font_size", 56)
	ic.add_theme_color_override("font_color", Color(cor.r, cor.g, cor.b, 0.0))
	ic.mouse_filter         = Control.MOUSE_FILTER_IGNORE
	_hud.add_child(ic)
	var tw_ic := create_tween()
	tw_ic.tween_property(ic, "modulate:a", 1.0, 0.08)   # aparece rápido
	tw_ic.parallel().tween_property(ic, "position:y", 220.0, 0.08)
	tw_ic.tween_property(ic, "modulate:a", 0.0, 0.45)   # some devagar
	tw_ic.parallel().tween_property(ic, "position:y", 160.0, 0.45)
	tw_ic.tween_callback(ic.queue_free)

	# ── 3. Nome da habilidade em texto grande ─────────────────────────────────
	var nomes : Dictionary = {
		"eletrico":   "PULSO ELÉTRICO",
		"gelo":       "BOMBA DE GELO",
		"devastador": "PULSO FINAL",
	}
	var nome_txt : String = nomes.get(id, id.to_upper())

	var nm := Label.new()
	nm.text                 = nome_txt
	nm.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	nm.position             = Vector2(290, 390)
	nm.size                 = Vector2(700, 63)
	nm.z_index              = 51
	nm.add_theme_font_size_override("font_size", 51)
	nm.add_theme_color_override("font_color", Color(cor.r, cor.g, cor.b, 0.0))
	nm.mouse_filter         = Control.MOUSE_FILTER_IGNORE
	_hud.add_child(nm)
	var tw_nm := create_tween()
	tw_nm.tween_property(nm, "modulate:a", 1.0, 0.10)
	tw_nm.parallel().tween_property(nm, "position:y", 370.0, 0.10)
	tw_nm.tween_property(nm, "modulate:a", 0.0, 0.55).set_delay(0.35)
	tw_nm.tween_callback(nm.queue_free)

	# ── 4. Barra horizontal de energia expandindo do centro ───────────────────
	# Barra direita: começa em x=640, cresce para a direita
	var barra_r := ColorRect.new()
	barra_r.color      = Color(cor.r, cor.g, cor.b, 0.75)
	barra_r.z_index    = 50
	barra_r.size       = Vector2(0.0, 6)
	barra_r.position   = Vector2(640.0, 358.0)
	barra_r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_hud.add_child(barra_r)
	var tw_r := create_tween()
	tw_r.tween_property(barra_r, "size:x",    580.0, 0.18)
	tw_r.tween_property(barra_r, "modulate:a", 0.0,  0.22)
	tw_r.tween_callback(barra_r.queue_free)

	# Barra esquerda: começa em x=640, cresce para a esquerda (move posição + aumenta tamanho)
	var barra_l := ColorRect.new()
	barra_l.color      = Color(cor.r, cor.g, cor.b, 0.75)
	barra_l.z_index    = 50
	barra_l.size       = Vector2(0.0, 6)
	barra_l.position   = Vector2(640.0, 358.0)
	barra_l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_hud.add_child(barra_l)
	var tw_l := create_tween()
	tw_l.tween_property(barra_l, "size:x",     580.0, 0.18)
	tw_l.parallel().tween_property(barra_l, "position:x", 60.0,  0.18)
	tw_l.tween_property(barra_l, "modulate:a",  0.0,  0.22)
	tw_l.tween_callback(barra_l.queue_free)


func _criar_habil_tooltip_painel() -> Panel:
	var p := Panel.new()
	p.z_index  = 60
	p.visible  = false
	p.size     = Vector2(340, 150)
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var sty := StyleBoxFlat.new()
	sty.bg_color     = Color(0.04, 0.05, 0.10, 0.96)
	sty.border_color = Color(0.35, 0.35, 0.50, 0.80)
	for s in ["left","right","top","bottom"]: sty.set("border_width_" + s, 1)
	for c in ["top_left","top_right","bottom_left","bottom_right"]: sty.set("corner_radius_" + c, 6)
	p.add_theme_stylebox_override("panel", sty)
	return p


func _mostrar_habil_tooltip(hid: String, info: Dictionary, cor: Color, btn_pos: Vector2) -> void:
	if not _habil_tooltip or not is_instance_valid(_habil_tooltip): return
	# Limpa filhos anteriores
	for ch in _habil_tooltip.get_children(): ch.queue_free()

	var cargas  : int    = int(Salvar.habil_cargas.get(hid, 0))
	var nome    : String = info.get("nome", hid) as String
	var desc    : String = info.get("desc", "") as String
	var custo   : int    = int(info.get("custo_cristal", 0))
	var cor_borda : Color = cor

	# Atualiza a borda com a cor da habilidade
	var sty := StyleBoxFlat.new()
	sty.bg_color     = Color(0.04, 0.05, 0.10, 0.96)
	sty.border_color = Color(cor_borda.r * 0.7, cor_borda.g * 0.7, cor_borda.b * 0.7, 0.90)
	for s in ["left","right","top","bottom"]: sty.set("border_width_" + s, 2)
	for c in ["top_left","top_right","bottom_left","bottom_right"]: sty.set("corner_radius_" + c, 6)
	_habil_tooltip.add_theme_stylebox_override("panel", sty)

	# Nome
	var lnome := Label.new()
	lnome.text     = nome
	lnome.position = Vector2(12, 10)
	lnome.size     = Vector2(316, 42)
	lnome.add_theme_font_size_override("font_size", 24)
	lnome.add_theme_color_override("font_color",
		Color(cor.r + 0.2, cor.g + 0.2, cor.b + 0.2))
	lnome.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_habil_tooltip.add_child(lnome)

	# Descrição
	var ldesc := Label.new()
	ldesc.text            = desc
	ldesc.position        = Vector2(12, 40)
	ldesc.size            = Vector2(316, 96)
	ldesc.autowrap_mode   = TextServer.AUTOWRAP_WORD
	ldesc.add_theme_font_size_override("font_size", 21)
	ldesc.add_theme_color_override("font_color", Color(0.78, 0.78, 0.85))
	ldesc.mouse_filter    = Control.MOUSE_FILTER_IGNORE
	_habil_tooltip.add_child(ldesc)

	# Cargas e custo
	var lcarga := Label.new()
	var txt_carga : String
	if cargas > 0:
		txt_carga = "Cargas: %d/3" % cargas
	else:
		txt_carga = "Sem cargas - %d cristais na loja" % custo
	lcarga.text     = txt_carga
	lcarga.position = Vector2(12, 110)
	lcarga.size     = Vector2(316, 42)
	lcarga.add_theme_font_size_override("font_size", 21)
	lcarga.add_theme_color_override("font_color",
		Color(0.45, 1.0, 0.55) if cargas > 0 else Color(0.75, 0.55, 0.30))
	lcarga.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_habil_tooltip.add_child(lcarga)

	# Posiciona acima do botão (centralizado)
	var tip_w : float = 340.0
	var tip_h : float = 150.0
	var px    : float = clampf(btn_pos.x + 70.0 - tip_w * 0.5, 4.0, get_viewport().get_visible_rect().size.x - tip_w - 4.0)
	var py    : float = btn_pos.y - tip_h - 8.0
	_habil_tooltip.position = Vector2(px, py)
	_habil_tooltip.size     = Vector2(tip_w, tip_h)
	_habil_tooltip.visible  = true


func _processar_toque_habil_tooltip(event: InputEvent, hid: String, info: Dictionary, cor: Color, btn: Control) -> void:
	if event is InputEventScreenTouch:
		var touch := event as InputEventScreenTouch
		if touch.pressed:
			_mostrar_habil_tooltip(hid, info, cor, btn.global_position)
		else:
			_esconder_habil_tooltip()
	elif event is InputEventScreenDrag:
		_mostrar_habil_tooltip(hid, info, cor, btn.global_position)
	elif event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_LEFT:
			if mb.pressed:
				_mostrar_habil_tooltip(hid, info, cor, btn.global_position)
			else:
				_esconder_habil_tooltip()


func _esconder_habil_tooltip() -> void:
	if _habil_tooltip and is_instance_valid(_habil_tooltip):
		_habil_tooltip.visible = false


func _criar_controles_velocidade() -> void:
	var dados := [["||", 0.0], ["1x", 1.0], ["1.5x", 1.5], ["2x", 2.0], ["3x", 3.0]]
	var btn_w  : int = 80
	var gap    : int = 6
	var total_w := dados.size() * btn_w + (dados.size() - 1) * gap
	var start_x := int(get_viewport().get_visible_rect().size.x) - total_w - 64

	for d in dados:
		var btn      := Button.new()
		btn.text      = d[0] as String
		btn.position  = Vector2(start_x + _vel_btns.size() * (btn_w + gap), 14)
		btn.size      = Vector2(btn_w, 50)
		btn.focus_mode = Control.FOCUS_NONE
		btn.add_theme_font_size_override("font_size", 22)

		var sty := StyleBoxFlat.new()
		sty.bg_color     = Color(0.06, 0.10, 0.16, 0.90)
		sty.border_color = Color(0.28, 0.48, 0.68, 0.75)
		for side in ["left","right","top","bottom"]:
			sty.set("border_width_" + side, 1)
		for corner in ["top_left","top_right","bottom_left","bottom_right"]:
			sty.set("corner_radius_" + corner, 4)
		btn.add_theme_stylebox_override("normal", sty)

		var sty_h : StyleBoxFlat = sty.duplicate()
		sty_h.bg_color = Color(0.14, 0.24, 0.38, 0.95)
		btn.add_theme_stylebox_override("hover",         sty_h)
		btn.add_theme_stylebox_override("pressed",       sty_h)
		btn.add_theme_stylebox_override("hover_pressed", sty_h)
		btn.add_theme_color_override("font_color", Color(0.72, 0.88, 1.0))

		var vel_cap  : float  = d[1] as float
		var nome_cap : String = d[0] as String
		btn.pressed.connect(func():
			var desc_v := "Velocidade " + nome_cap + ("  — pausar" if vel_cap == 0.0 else "")
			Acessibilidade.processar("vel_" + nome_cap, desc_v, func(): _definir_velocidade(vel_cap))
		)
		_hud.add_child(btn)
		_vel_btns.append(btn)




func _definir_velocidade(vel: float) -> void:
	if jogo and jogo.wave >= 35:
		vel = minf(vel, maxf(jogo._vel_cap, 1.5))
	Engine.time_scale = vel
	# Destaca o botão ativo
	var dados := [0.0, 1.0, 1.5, 2.0, 3.0]
	for i in range(_vel_btns.size()):
		var ativo := (dados[i] as float) == vel
		var sty := StyleBoxFlat.new()
		sty.bg_color     = Color(0.08, 0.20, 0.35, 0.95) if ativo else Color(0.06, 0.10, 0.16, 0.90)
		sty.border_color = Color(0.0, 0.82, 1.0, 1.0)    if ativo else Color(0.28, 0.48, 0.68, 0.75)
		for side in ["left","right","top","bottom"]:
			sty.set("border_width_" + side, 2 if ativo else 1)
		for corner in ["top_left","top_right","bottom_left","bottom_right"]:
			sty.set("corner_radius_" + corner, 4)
		(_vel_btns[i] as Button).add_theme_stylebox_override("normal", sty)

	if vel == 0.0 and _pause_overlay == null:
		var vp_rect   : Vector2 = get_viewport().get_visible_rect().size
		var vp_w_pause : float  = vp_rect.x
		var vp_h_pause : float  = vp_rect.y
		var btn_x : float       = (vp_w_pause - 300.0) * 0.5
		var cy    : float       = vp_h_pause * 0.5   # centro vertical

		_pause_overlay = Control.new()
		_pause_overlay.position = Vector2.ZERO
		_pause_overlay.size     = Vector2(vp_w_pause, vp_h_pause)
		_hud.add_child(_pause_overlay)

		# Fundo escuro (cobre tela toda)
		var bg := ColorRect.new()
		bg.color    = Color(0.0, 0.0, 0.0, 0.55)
		bg.position = Vector2.ZERO
		bg.size     = Vector2(vp_w_pause, vp_h_pause)
		bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_pause_overlay.add_child(bg)

		# Label PAUSADO — acima dos botões
		var lbl := Label.new()
		lbl.text                 = "PAUSADO"
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl.position             = Vector2(btn_x, cy - 215)
		lbl.size                 = Vector2(300, 72)
		lbl.mouse_filter         = Control.MOUSE_FILTER_IGNORE
		lbl.add_theme_font_size_override("font_size", 66)
		lbl.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0, 0.85))
		_pause_overlay.add_child(lbl)

		# Botão CONTINUAR
		var btn_c := _criar_pause_btn("CONTINUAR", Vector2(btn_x, cy - 135), Color(0.0, 0.82, 0.45))
		btn_c.pressed.connect(func(): _definir_velocidade(1.0))
		_pause_overlay.add_child(btn_c)

		# Botão ESTATÍSTICAS
		var btn_st := _criar_pause_btn("ESTATÍSTICAS", Vector2(btn_x, cy - 63), Color(0.25, 0.65, 1.0))
		btn_st.pressed.connect(func(): _mostrar_status_panel())
		_pause_overlay.add_child(btn_st)

		# Botão PAUSAR RUN — oculto em arena (handler já garante isso internamente)
		var btn_p := _criar_pause_btn("PAUSAR RUN  💾", Vector2(btn_x, cy + 9), Color(0.35, 0.72, 1.0))
		btn_p.pressed.connect(func():
			if jogo and is_instance_valid(jogo):
				jogo.pausar_e_sair_da_partida()
		)
		_pause_overlay.add_child(btn_p)

		# Botão SAIR (abandona)
		var btn_s := _criar_pause_btn("SAIR (ABANDONAR)", Vector2(btn_x, cy + 81), Color(0.9, 0.22, 0.22))
		btn_s.pressed.connect(func():
			if jogo and is_instance_valid(jogo):
				jogo.sair_da_partida()
		)
		_pause_overlay.add_child(btn_s)

	elif vel != 0.0 and _pause_overlay != null:
		_pause_overlay.queue_free()
		_pause_overlay = null


func _set_velocidade_visivel(visivel: bool) -> void:
	for btn in _vel_btns:
		if btn and is_instance_valid(btn):
			(btn as Button).visible = visivel
			(btn as Button).disabled = not visivel
	if not visivel and _pause_overlay != null:
		_pause_overlay.queue_free()
		_pause_overlay = null


func _criar_pause_btn(texto: String, pos: Vector2, cor: Color) -> Button:
	var btn := Button.new()
	btn.text     = texto
	btn.position = pos
	btn.size     = Vector2(300, 60)
	btn.add_theme_font_size_override("font_size", 22)
	var sty := StyleBoxFlat.new()
	sty.bg_color     = Color(cor.r * 0.15, cor.g * 0.15, cor.b * 0.15, 0.92)
	sty.border_color = Color(cor.r, cor.g, cor.b, 0.9)
	for side in ["left","right","top","bottom"]:
		sty.set("border_width_" + side, 2)
	for corner in ["top_left","top_right","bottom_left","bottom_right"]:
		sty.set("corner_radius_" + corner, 10)
	btn.add_theme_stylebox_override("normal", sty)
	var sty_h : StyleBoxFlat = sty.duplicate()
	sty_h.bg_color = Color(cor.r * 0.30, cor.g * 0.30, cor.b * 0.30, 0.96)
	btn.add_theme_stylebox_override("hover", sty_h)
	btn.add_theme_color_override("font_color", Color(cor.r + 0.25, cor.g + 0.25, cor.b + 0.25))
	return btn


func _process(_delta: float) -> void:
	_atualizar_bloqueio_velocidade_boss()
	if not _slot_drawer or not is_instance_valid(_slot_drawer):
		return
	# Atualiza apenas slots visíveis (cargas > 0 no início da partida)
	var _all_ids : Array = Salvar.HABIL_INFO.keys()
	var _vis_ids : Array = []
	for _vi in _all_ids:
		if _habil_btns.has(_vi):
			_vis_ids.append(_vi)

	for i in range(_vis_ids.size()):
		if i >= _slot_drawer.slot_cargas.size(): break
		var hid    : String = _vis_ids[i] as String
		var cur_cd : float  = _habil_cds_ui.get(hid, 0.0) as float
		var max_cd : float  = _habil_cd_maxs.get(hid, 45.0) as float
		_slot_drawer.slot_cargas[i] = Salvar.habil_cargas.get(hid, 0)
		if cur_cd > 0.0:
			_slot_drawer.slot_cd_prog[i] = 1.0 - clamp(cur_cd / max_cd, 0.0, 1.0)
			_slot_drawer.slot_cd_secs[i] = cur_cd
		else:
			_slot_drawer.slot_cd_prog[i] = 1.0 if _slot_drawer.slot_cargas[i] > 0 else 0.0
			_slot_drawer.slot_cd_secs[i] = 0.0
		if _habil_btns.has(hid):
			(_habil_btns[hid] as Button).disabled = _slot_drawer.slot_cargas[i] <= 0 or cur_cd > 0.0

	# Atualiza slot do hacker
	if _slot_drawer.hk_ativo and _hacker_btn and is_instance_valid(_hacker_btn):
		var pet = jogo.pet_assistente if (jogo and is_instance_valid(jogo)) else null
		if pet and is_instance_valid(pet):
			var cd : float = pet.get_hacker_cd()
			var _hk_cd_max : float = float(Salvar.pet_stats(Salvar.pet_ativo).get("hab_cd", 35.0))
			_slot_drawer.hk_prog    = 1.0 - clamp(cd / _hk_cd_max, 0.0, 1.0) if cd > 0.0 else 1.0
			_slot_drawer.hk_analise = pet.get_em_analise()
			_slot_drawer.hk_boost   = pet.get_boost_prog()
			_slot_drawer.hk_cd_secs = cd
			_hacker_btn.disabled    = pet.get_em_analise() or cd > 0.0


func _atualizar_bloqueio_velocidade_boss() -> void:
	if _vel_btns.is_empty():
		return
	for i in range(_vel_btns.size()):
		var btn := _vel_btns[i] as Button
		if not btn or not is_instance_valid(btn):
			continue
		btn.disabled = false
		btn.modulate = Color.WHITE


func atualizar_hud(score: int, gold: int, wave: int) -> void:
	if _top_lbl:
		_hud_gold = gold
		_hud_cristais = Salvar.cristais
		var _modo_ab : bool = jogo and is_instance_valid(jogo) and jogo.get("modo_abismo") as bool
		_set_velocidade_visivel(true)
		if _currency_hud and is_instance_valid(_currency_hud):
			_currency_hud.show()
		_top_lbl.text = "Wave: %d   Score: %s" % [wave, _fmt_num(score)]
		if _currency_hud and is_instance_valid(_currency_hud):
			_reposicionar_currency_hud(_top_lbl.text)
			_currency_hud.queue_redraw()
		# Cor muda conforme dificuldade
		match Salvar.dificuldade:
			0: _top_lbl.add_theme_color_override("font_color", Color(0.45, 0.72, 0.45))  # verde apagado
			1: _top_lbl.add_theme_color_override("font_color", Color(0.65, 0.88, 1.0))   # azul (original)
			2: _top_lbl.add_theme_color_override("font_color", Color(1.0,  0.62, 0.35))  # laranja


func mostrar_matchmaking_overlay() -> void:
	if _matchmaking_overlay and is_instance_valid(_matchmaking_overlay):
		_matchmaking_overlay.queue_free()

	var ov := Control.new()
	ov.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ov.z_index = 20
	_hud.add_child(ov)
	_matchmaking_overlay = ov

	# Fundo semi-transparente
	var bg := ColorRect.new()
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0.04, 0.02, 0.08, 0.88)
	ov.add_child(bg)

	var vp := get_viewport().get_visible_rect().size
	var font := ThemeDB.fallback_font

	# Painel central
	var pnl := Panel.new()
	var pw : float = 480.0
	var ph : float = 160.0
	pnl.position = Vector2((vp.x - pw) * 0.5, (vp.y - ph) * 0.5)
	pnl.size = Vector2(pw, ph)
	var sty := StyleBoxFlat.new()
	sty.bg_color = Color(0.06, 0.02, 0.12, 0.98)
	sty.border_color = Color(0.6, 0.3, 1.0, 0.9)
	for side in ["left","right","top","bottom"]: sty.set("border_width_" + side, 2)
	for c in ["top_left","top_right","bottom_left","bottom_right"]: sty.set("corner_radius_" + c, 12)
	pnl.add_theme_stylebox_override("panel", sty)
	ov.add_child(pnl)

	var titulo := Label.new()
	titulo.text = "PROCURANDO OPONENTE"
	titulo.add_theme_font_size_override("font_size", 22)
	titulo.add_theme_color_override("font_color", Color(0.85, 0.55, 1.0))
	titulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	titulo.position = Vector2(0, 22)
	titulo.size = Vector2(pw, 32)
	pnl.add_child(titulo)

	var sub := Label.new()
	sub.text = "Buscando jogador real...\nSe ninguem entrar em 30s, um bot assumira o lugar."
	sub.add_theme_font_size_override("font_size", 15)
	sub.add_theme_color_override("font_color", Color(0.75, 0.75, 0.9))
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	sub.position = Vector2(20, 66)
	sub.size = Vector2(pw - 40, 60)
	pnl.add_child(sub)

	# Animação de pontos piscando
	var dots := Label.new()
	dots.name = "Dots"
	dots.text = "..."
	dots.add_theme_font_size_override("font_size", 28)
	dots.add_theme_color_override("font_color", Color(0.5, 0.9, 1.0))
	dots.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	dots.position = Vector2(0, 118)
	dots.size = Vector2(pw, 30)
	pnl.add_child(dots)

	# Tween para piscar os pontos
	var tween := create_tween().set_loops()
	tween.tween_callback(func():
		if dots and is_instance_valid(dots):
			dots.text = [".", "..", "..."][int(Time.get_ticks_msec() / 500) % 3]
	).set_delay(0.5)


func ocultar_matchmaking_overlay() -> void:
	if _matchmaking_overlay and is_instance_valid(_matchmaking_overlay):
		_matchmaking_overlay.queue_free()
	_matchmaking_overlay = null


func fechar_cartas() -> void:
	_fechar_tooltip()
	if _overlay and is_instance_valid(_overlay):
		_overlay.queue_free()
	if _panel and is_instance_valid(_panel):
		_panel.queue_free()
	_overlay = null
	_panel = null
	_upgrade_ativo = false
	_carta_pendente_btn = null
	_carta_pendente_efeito = ""
	_carta_pendente_val = 0.0


func atualizar_build_nome(nome: String) -> void:
	if not _build_lbl or not is_instance_valid(_build_lbl):
		return
	if nome == "":
		_build_lbl.text = ""
		_build_lbl.add_theme_color_override("font_color", Color(1.0, 0.88, 0.22, 0.0))
		return
	_build_lbl.text = "[ %s ]" % nome
	# Animação: aparece com flash dourado
	var tween := create_tween()
	tween.tween_method(
		func(a: float) -> void:
			if _build_lbl and is_instance_valid(_build_lbl):
				_build_lbl.add_theme_color_override("font_color", Color(1.0, 0.88, 0.22, a)),
		0.0, 1.0, 0.6
	)


func mostrar_banner_abismo() -> void:
	# Banner vermelho escuro no topo indicando Modo Abismo
	var vp_w_ab : float = get_viewport().get_visible_rect().size.x
	var banner := ColorRect.new()
	banner.color        = Color(0.35, 0.02, 0.02, 0.75)
	banner.position     = Vector2(0.0, 0.0)
	banner.size         = Vector2(vp_w_ab, 20.0)
	banner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_hud.add_child(banner)

	var lbl := Label.new()
	lbl.text                 = "MODO ABISMO ATIVO"
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.position             = Vector2(0, 2)
	lbl.size                 = Vector2(vp_w_ab, 16)
	lbl.add_theme_font_size_override("font_size", 16)
	lbl.add_theme_color_override("font_color", Color(1.0, 0.38, 0.38, 0.90))
	lbl.mouse_filter         = Control.MOUSE_FILTER_IGNORE
	banner.add_child(lbl)


func mostrar_tela_alma(score: int, wave: int, gold: int, custo: int,
		cb_morte: Callable, cb_reviver: Callable) -> void:
	if _alma_overlay and is_instance_valid(_alma_overlay):
		return

	var vp_w_alma : float = get_viewport().get_visible_rect().size.x
	var ov := ColorRect.new()
	ov.color    = Color(0.0, 0.0, 0.0, 0.82)
	ov.z_index  = 30
	ov.position = Vector2.ZERO
	ov.size     = Vector2(vp_w_alma, 720)
	_hud.add_child(ov)
	_alma_overlay = ov

	# Título DERROTA
	var t1 := Label.new()
	t1.text                 = "DERROTA"
	t1.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	t1.position             = Vector2(0, 185)
	t1.size                 = Vector2(vp_w_alma, 72)
	t1.add_theme_font_size_override("font_size", 88)
	t1.add_theme_color_override("font_color", Color(0.85, 0.12, 0.12))
	t1.mouse_filter         = Control.MOUSE_FILTER_IGNORE
	ov.add_child(t1)

	# Stats
	var t2 := Label.new()
	t2.text                 = "Wave %d   |   Score: %s" % [wave, _fmt_num(score)]
	t2.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	t2.position             = Vector2(0, 276)
	t2.size                 = Vector2(vp_w_alma, 34)
	t2.add_theme_font_size_override("font_size", 32)
	t2.add_theme_color_override("font_color", Color(0.65, 0.65, 0.65))
	t2.mouse_filter         = Control.MOUSE_FILTER_IGNORE
	ov.add_child(t2)

	# Texto da Alma
	var tem_cristais : bool = Salvar.cristais >= custo
	var t3 := Label.new()
	t3.text                 = "Invocar a Alma custa %d cristais (voce tem %d)" % [custo, Salvar.cristais]
	t3.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	t3.position             = Vector2(0, 322)
	t3.size                 = Vector2(vp_w_alma, 26)
	t3.add_theme_font_size_override("font_size", 20)
	t3.add_theme_color_override("font_color",
		Color(1.0, 0.88, 0.22) if tem_cristais else Color(0.55, 0.35, 0.35))
	t3.mouse_filter         = Control.MOUSE_FILTER_IGNORE
	ov.add_child(t3)

	var t4 := Label.new()
	t4.text                 = "A torre renasce com 35% de vida. Apenas 1 vez por partida."
	t4.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	t4.position             = Vector2(0, 356)
	t4.size                 = Vector2(vp_w_alma, 22)
	t4.add_theme_font_size_override("font_size", 17)
	t4.add_theme_color_override("font_color", Color(0.50, 0.62, 0.50))
	t4.mouse_filter         = Control.MOUSE_FILTER_IGNORE
	ov.add_child(t4)

	# Botão INVOCAR ALMA
	var _mk_sty := func(cor: Color, ativo: bool) -> StyleBoxFlat:
		var s := StyleBoxFlat.new()
		s.bg_color     = Color(cor.r * (0.22 if ativo else 0.06),
							   cor.g * (0.22 if ativo else 0.06),
							   cor.b * (0.22 if ativo else 0.06), 0.95)
		s.border_color = Color(cor.r, cor.g, cor.b, 1.0 if ativo else 0.35)
		for sd in ["left","right","top","bottom"]: s.set("border_width_" + sd, 2)
		for cn in ["top_left","top_right","bottom_left","bottom_right"]: s.set("corner_radius_" + cn, 10)
		return s

	var btn_alma := Button.new()
	btn_alma.text                = "INVOCAR ALMA  [ -%d cristais ]" % custo
	btn_alma.position            = Vector2((vp_w_alma - 700.0) * 0.5, 398)
	btn_alma.size                = Vector2(700, 72)
	btn_alma.add_theme_font_size_override("font_size", 26)
	var cor_alma := Color(0.88, 0.62, 0.08)
	btn_alma.add_theme_stylebox_override("normal", _mk_sty.call(cor_alma, tem_cristais))
	btn_alma.add_theme_stylebox_override("hover",  _mk_sty.call(Color(1.0, 0.80, 0.20), tem_cristais))
	btn_alma.add_theme_color_override("font_color",
		Color(1.0, 0.92, 0.45) if tem_cristais else Color(0.45, 0.35, 0.25))
	btn_alma.disabled = not tem_cristais
	btn_alma.pressed.connect(cb_reviver)
	ov.add_child(btn_alma)

	# Botão ACEITAR DERROTA
	var btn_morte := Button.new()
	btn_morte.text                = "ACEITAR DERROTA"
	btn_morte.position            = Vector2((vp_w_alma - 700.0) * 0.5, 482)
	btn_morte.size                = Vector2(700, 60)
	btn_morte.add_theme_font_size_override("font_size", 22)
	var cor_morte := Color(0.55, 0.20, 0.20)
	btn_morte.add_theme_stylebox_override("normal", _mk_sty.call(cor_morte, true))
	btn_morte.add_theme_stylebox_override("hover",  _mk_sty.call(Color(0.80, 0.25, 0.25), true))
	btn_morte.add_theme_color_override("font_color", Color(0.75, 0.45, 0.45))
	btn_morte.pressed.connect(cb_morte)
	ov.add_child(btn_morte)


func fechar_tela_alma() -> void:
	if _alma_overlay and is_instance_valid(_alma_overlay):
		_alma_overlay.queue_free()
	_alma_overlay = null


func mostrar_tela_revive_loja(score: int, wave: int, _gold: int,
		cb_morte: Callable, cb_reviver: Callable) -> void:
	if _alma_overlay and is_instance_valid(_alma_overlay):
		return
	var vp_w_r : float = get_viewport().get_visible_rect().size.x
	var ov := ColorRect.new()
	ov.color    = Color(0.0, 0.0, 0.0, 0.82)
	ov.z_index  = 30
	ov.position = Vector2.ZERO
	ov.size     = Vector2(vp_w_r, 720)
	_hud.add_child(ov)
	_alma_overlay = ov

	var t1 := Label.new()
	t1.text                 = "DERROTA"
	t1.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	t1.position             = Vector2(0, 175)
	t1.size                 = Vector2(vp_w_r, 72)
	t1.add_theme_font_size_override("font_size", 88)
	t1.add_theme_color_override("font_color", Color(0.85, 0.12, 0.12))
	t1.mouse_filter         = Control.MOUSE_FILTER_IGNORE
	ov.add_child(t1)

	var t2 := Label.new()
	t2.text                 = "Wave %d   |   Score: %s" % [wave, _fmt_num(score)]
	t2.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	t2.position             = Vector2(0, 262)
	t2.size                 = Vector2(vp_w_r, 32)
	t2.add_theme_font_size_override("font_size", 32)
	t2.add_theme_color_override("font_color", Color(0.65, 0.65, 0.65))
	t2.mouse_filter         = Control.MOUSE_FILTER_IGNORE
	ov.add_child(t2)

	var estoque : int = Salvar.revive_loja_estoque
	var t3 := Label.new()
	t3.text                 = "Você tem %d Vela(s) da Alma no estoque" % estoque
	t3.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	t3.position             = Vector2(0, 305)
	t3.size                 = Vector2(vp_w_r, 26)
	t3.add_theme_font_size_override("font_size", 21)
	t3.add_theme_color_override("font_color", Color(1.0, 0.78, 0.22))
	t3.mouse_filter         = Control.MOUSE_FILTER_IGNORE
	ov.add_child(t3)

	var t4 := Label.new()
	t4.text                 = "A torre renasce com 35% de vida. Apenas 1 Vela por partida."
	t4.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	t4.position             = Vector2(0, 340)
	t4.size                 = Vector2(vp_w_r, 22)
	t4.add_theme_font_size_override("font_size", 17)
	t4.add_theme_color_override("font_color", Color(0.50, 0.62, 0.50))
	t4.mouse_filter         = Control.MOUSE_FILTER_IGNORE
	ov.add_child(t4)

	var _mk_sty := func(cor: Color, ativo: bool) -> StyleBoxFlat:
		var s := StyleBoxFlat.new()
		s.bg_color     = Color(cor.r * (0.22 if ativo else 0.06),
							   cor.g * (0.22 if ativo else 0.06),
							   cor.b * (0.22 if ativo else 0.06), 0.95)
		s.border_color = Color(cor.r, cor.g, cor.b, 1.0 if ativo else 0.35)
		for sd in ["left","right","top","bottom"]: s.set("border_width_" + sd, 2)
		for cn in ["top_left","top_right","bottom_left","bottom_right"]: s.set("corner_radius_" + cn, 10)
		return s

	var btn_revive := Button.new()
	btn_revive.text     = "USAR VELA DA ALMA  [ -%d do estoque ]" % 1
	btn_revive.position = Vector2((vp_w_r - 700.0) * 0.5, 382)
	btn_revive.size     = Vector2(700, 70)
	btn_revive.add_theme_font_size_override("font_size", 26)
	var cor_rev := Color(0.55, 0.88, 0.25)
	btn_revive.add_theme_stylebox_override("normal", _mk_sty.call(cor_rev, true))
	btn_revive.add_theme_stylebox_override("hover",  _mk_sty.call(Color(0.70, 1.0, 0.35), true))
	btn_revive.add_theme_color_override("font_color", Color(0.75, 1.0, 0.45))
	btn_revive.pressed.connect(cb_reviver)
	ov.add_child(btn_revive)

	var btn_morte := Button.new()
	btn_morte.text     = "ACEITAR DERROTA"
	btn_morte.position = Vector2((vp_w_r - 700.0) * 0.5, 464)
	btn_morte.size     = Vector2(700, 60)
	btn_morte.add_theme_font_size_override("font_size", 22)
	var cor_morte := Color(0.55, 0.20, 0.20)
	btn_morte.add_theme_stylebox_override("normal", _mk_sty.call(cor_morte, true))
	btn_morte.add_theme_stylebox_override("hover",  _mk_sty.call(Color(0.80, 0.25, 0.25), true))
	btn_morte.add_theme_color_override("font_color", Color(0.75, 0.45, 0.45))
	btn_morte.pressed.connect(cb_morte)
	ov.add_child(btn_morte)


func mostrar_flash_cura() -> void:
	var fl := ColorRect.new()
	fl.color   = Color(0.15, 1.0, 0.45, 0.38)
	fl.z_index = 25
	fl.set_anchors_preset(Control.PRESET_FULL_RECT)
	fl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_hud.add_child(fl)
	var tw := create_tween()
	tw.tween_property(fl, "color:a", 0.0, 0.7)
	tw.tween_callback(fl.queue_free)


func mostrar_reviver_flash() -> void:
	# Flash dourado na tela ao reviver
	var fl := ColorRect.new()
	fl.color   = Color(1.0, 0.85, 0.2, 0.55)
	fl.z_index = 25
	fl.set_anchors_preset(Control.PRESET_FULL_RECT)
	fl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_hud.add_child(fl)
	var tw := create_tween()
	tw.tween_property(fl, "color:a", 0.0, 0.8)
	tw.tween_callback(fl.queue_free)

	var lbl := Label.new()
	lbl.text                 = "ALMA INVOCADA"
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.position             = Vector2(0, 300)
	lbl.size                 = Vector2(get_viewport().get_visible_rect().size.x, 60)
	lbl.add_theme_font_size_override("font_size", 63)
	lbl.add_theme_color_override("font_color", Color(1.0, 0.92, 0.35))
	lbl.mouse_filter         = Control.MOUSE_FILTER_IGNORE
	fl.add_child(lbl)


func mostrar_notificacao_consumivel(texto: String, cor: Color) -> void:
	var vp_w : float = get_viewport().get_visible_rect().size.x
	var lbl := Label.new()
	lbl.text                 = texto
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.position             = Vector2(0, 140)
	lbl.size                 = Vector2(vp_w, 40)
	lbl.add_theme_font_size_override("font_size", 22)
	lbl.add_theme_color_override("font_color", cor)
	lbl.add_theme_color_override("font_shadow_color", Color(0,0,0,0.8))
	lbl.add_theme_constant_override("shadow_offset_x", 1)
	lbl.add_theme_constant_override("shadow_offset_y", 1)
	lbl.z_index      = 22
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_hud.add_child(lbl)
	var tw := create_tween()
	tw.tween_interval(2.0)
	tw.tween_property(lbl, "modulate:a", 0.0, 0.5)
	tw.tween_callback(lbl.queue_free)


func criar_consumivel_hud() -> void:
	for dict in [_consumivel_slots, _consumivel_btns, _consumivel_lbls, _consumivel_nome_lbls]:
		for node in (dict as Dictionary).values():
			if node and is_instance_valid(node):
				(node as Node).queue_free()
		(dict as Dictionary).clear()

	var info_list : Array = []
	var info_by_id : Dictionary = {
		"orbe":    {"id":"orbe",    "nome":"ORBE",    "cor":Color(0.25, 1.0,  0.45), "estoque":Salvar.orbe_cura_estoque},
		"cristal": {"id":"cristal", "nome":"BARREIRA","cor":Color(0.35, 0.55, 1.0),  "estoque":Salvar.cristal_barreira_estoque},
		"runa":    {"id":"runa",    "nome":"RUNA",    "cor":Color(1.0,  0.45, 0.1),  "estoque":Salvar.runa_furia_estoque}
	}
	for cid in Salvar.cons_equipados:
		var id := str(cid)
		if not info_by_id.has(id):
			continue
		var info : Dictionary = info_by_id[id] as Dictionary
		if int(info["estoque"]) > 0:
			info_list.append(info)
	if info_list.is_empty(): return

	var r    : float = 38.0
	var step : float = r * 2.0 + 12.0
	var vp   := get_viewport().get_visible_rect().size
	var is_mobile := OS.has_feature("android") or OS.has_feature("ios")
	var cy   : float = vp.y - r - (120.0 if is_mobile else 18.0)

	for i in range(info_list.size()):
		var ci     : Dictionary = info_list[info_list.size() - 1 - i] as Dictionary
		var id_c   : String     = ci["id"]      as String
		var cor_c  : Color      = ci["cor"]     as Color
		var est_c  : int        = ci["estoque"] as int
		var nome_c : String     = ci["nome"]    as String
		var cx     : float      = vp.x - r - 16.0 - float(i) * step

		var slot     := Control.new()
		var sz_h     : float = r + 2.0
		var cor_cap  : Color  = cor_c
		var id_cap   : String = id_c
		slot.position     = Vector2(cx - sz_h, cy - sz_h)
		slot.size         = Vector2(sz_h * 2.0, sz_h * 2.0)
		slot.mouse_filter = Control.MOUSE_FILTER_IGNORE
		slot.draw.connect(func():
			slot.draw_circle(Vector2(sz_h, sz_h), r, Color(0.04, 0.05, 0.10, 0.93))
			slot.draw_arc(Vector2(sz_h, sz_h), r - 1.0, 0.0, TAU, 48, cor_cap, 2.5, false)
			_draw_consumivel_icone(slot, Vector2(sz_h, sz_h), r * 0.44, id_cap, cor_cap)
		)
		_hud.add_child(slot)
		_consumivel_slots[id_c] = slot

		var lnome := Label.new()
		lnome.text = nome_c
		lnome.position     = Vector2(cx - r, cy + r + 3.0)
		lnome.size         = Vector2(r * 2.0, 15.0)
		lnome.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lnome.add_theme_font_size_override("font_size", 11)
		lnome.add_theme_color_override("font_color", Color(cor_c.r * 0.85, cor_c.g * 0.85, cor_c.b * 0.85, 0.85))
		lnome.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_hud.add_child(lnome)
		_consumivel_nome_lbls[id_c] = lnome

		var lstock := Label.new()
		lstock.text = "x%d" % est_c
		lstock.position = Vector2(cx + r * 0.25, cy - r - 1.0)
		lstock.size     = Vector2(r, 15.0)
		lstock.add_theme_font_size_override("font_size", 12)
		lstock.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0, 0.82))
		lstock.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_hud.add_child(lstock)
		_consumivel_lbls[id_c] = lstock

		var btn := Button.new()
		btn.position   = Vector2(cx - r, cy - r)
		btn.size       = Vector2(r * 2.0, r * 2.0)
		btn.focus_mode = Control.FOCUS_NONE
		btn.z_index    = 8
		var sty_inv := StyleBoxEmpty.new()
		for st in ["normal","hover","pressed","disabled","hover_pressed","focus"]:
			btn.add_theme_stylebox_override(st, sty_inv)
		var id_btn : String = id_c
		btn.pressed.connect(func():
			if jogo and is_instance_valid(jogo):
				jogo.call("_usar_consumivel", id_btn))
		_hud.add_child(btn)
		_consumivel_btns[id_c] = btn


func _draw_consumivel_icone(ctrl: Control, center: Vector2, ir: float, id: String, cor: Color) -> void:
	match id:
		"orbe":
			var arm : float = ir * 0.85
			ctrl.draw_circle(center, ir * 0.30, Color(cor.r, cor.g, cor.b, 0.35))
			ctrl.draw_line(center + Vector2(-arm, 0.0), center + Vector2(arm, 0.0), cor, 4.0)
			ctrl.draw_line(center + Vector2(0.0, -arm), center + Vector2(0.0, arm), cor, 4.0)
		"cristal":
			var pts_h := PackedVector2Array()
			for j in 6:
				var ang : float = float(j) / 6.0 * TAU - PI / 6.0
				pts_h.append(center + Vector2(cos(ang), sin(ang)) * ir)
			for j in 6:
				ctrl.draw_line(pts_h[j], pts_h[(j + 1) % 6], cor, 2.5)
			ctrl.draw_line(center + Vector2(0.0, -ir * 0.52), center + Vector2(ir * 0.42, 0.0), cor, 2.0)
			ctrl.draw_line(center + Vector2(ir * 0.42, 0.0),  center + Vector2(0.0, ir * 0.52), cor, 2.0)
			ctrl.draw_line(center + Vector2(0.0, ir * 0.52),  center + Vector2(-ir * 0.42, 0.0), cor, 2.0)
			ctrl.draw_line(center + Vector2(-ir * 0.42, 0.0), center + Vector2(0.0, -ir * 0.52), cor, 2.0)
		"runa":
			var bolt := PackedVector2Array([
				center + Vector2( 4.5, -ir),
				center + Vector2(-2.5, -1.0),
				center + Vector2( 6.0, -1.0),
				center + Vector2(-4.5,  ir),
				center + Vector2( 2.5,  2.0),
				center + Vector2(-6.0,  2.0),
				center + Vector2( 4.5, -ir),
			])
			ctrl.draw_polyline(bolt, cor, 3.0)


func atualizar_consumivel_slot(id: String) -> void:
	var est : int = 0
	match id:
		"orbe":    est = Salvar.orbe_cura_estoque
		"cristal": est = 0
		"runa":    est = Salvar.runa_furia_estoque
	if _consumivel_lbls.has(id):
		var lb := _consumivel_lbls[id] as Label
		if is_instance_valid(lb): lb.text = "x%d" % est
	var cor_map : Dictionary = {
		"orbe":    Color(0.25, 1.0,  0.45),
		"cristal": Color(0.35, 0.55, 1.0),
		"runa":    Color(1.0,  0.45, 0.1),
	}
	_animar_consumivel_uso(id, cor_map.get(id, Color(1.0, 1.0, 1.0)) as Color)
	if est <= 0:
		if _consumivel_slots.has(id):
			var sl := _consumivel_slots[id] as Control
			if is_instance_valid(sl): sl.visible = false
		if _consumivel_btns.has(id):
			var bt := _consumivel_btns[id] as Button
			if is_instance_valid(bt):
				bt.disabled = true
				bt.visible = false
		if _consumivel_lbls.has(id):
			var lb := _consumivel_lbls[id] as Label
			if is_instance_valid(lb):
				lb.visible = false
				lb.add_theme_color_override("font_color", Color(0.4, 0.4, 0.4, 0.55))
		if _consumivel_nome_lbls.has(id):
			var nl := _consumivel_nome_lbls[id] as Label
			if is_instance_valid(nl): nl.visible = false


func _animar_consumivel_uso(id: String, cor: Color) -> void:
	if not _consumivel_slots.has(id): return
	var sl := _consumivel_slots[id] as Control
	if not is_instance_valid(sl): return
	sl.pivot_offset = sl.size * 0.5

	var vp   := get_viewport().get_visible_rect().size
	var slot_center := sl.position + sl.size * 0.5

	# ── 1. Flash de tela ────────────────────────────────────────────────────────
	var flash := ColorRect.new()
	flash.color        = Color(cor.r, cor.g, cor.b, 0.28)
	flash.z_index      = 50
	flash.set_anchors_preset(Control.PRESET_FULL_RECT)
	flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_hud.add_child(flash)
	var tw_fl := create_tween()
	tw_fl.tween_property(flash, "color:a", 0.0, 0.50)
	tw_fl.tween_callback(flash.queue_free)

	# ── 2. Nome do item no centro da tela ───────────────────────────────────────
	var nomes := {"orbe":"ORBE DE CURA", "cristal":"CRISTAL DE BARREIRA", "runa":"RUNA DE FURIA"}
	var nm := Label.new()
	nm.text                 = nomes.get(id, id.to_upper())
	nm.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	nm.position             = Vector2(0.0, vp.y * 0.5 - 28.0)
	nm.size                 = Vector2(vp.x, 56.0)
	nm.z_index              = 51
	nm.add_theme_font_size_override("font_size", 48)
	nm.add_theme_color_override("font_color", Color(cor.r, cor.g, cor.b, 0.0))
	nm.mouse_filter         = Control.MOUSE_FILTER_IGNORE
	_hud.add_child(nm)
	var tw_nm := create_tween()
	tw_nm.tween_property(nm, "modulate:a", 1.0, 0.09)
	tw_nm.parallel().tween_property(nm, "position:y", vp.y * 0.5 - 38.0, 0.09)
	tw_nm.tween_property(nm, "modulate:a", 0.0, 0.55).set_delay(0.28)
	tw_nm.parallel().tween_property(nm, "position:y", vp.y * 0.5 - 68.0, 0.55)
	tw_nm.tween_callback(nm.queue_free)

	# ── 3. Barras de energia expandindo do centro da tela ───────────────────────
	var bar_y : float = vp.y * 0.5 + 22.0
	var bar_cx : float = vp.x * 0.5
	for side in [-1.0, 1.0]:
		var bar := ColorRect.new()
		bar.color        = Color(cor.r, cor.g, cor.b, 0.72)
		bar.z_index      = 50
		bar.size         = Vector2(0.0, 4.0)
		bar.position     = Vector2(bar_cx, bar_y)
		bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_hud.add_child(bar)
		var tw_bar := create_tween()
		if side > 0.0:
			tw_bar.tween_property(bar, "size:x", bar_cx, 0.17)
		else:
			tw_bar.tween_property(bar, "size:x", bar_cx, 0.17)
			tw_bar.parallel().tween_property(bar, "position:x", 0.0, 0.17)
		tw_bar.tween_property(bar, "modulate:a", 0.0, 0.20)
		tw_bar.tween_callback(bar.queue_free)

	# ── 4. Slot: escala bounce + glow intenso ──────────────────────────────────
	var tw_sl := create_tween()
	tw_sl.tween_property(sl, "scale", Vector2(1.55, 1.55), 0.12).set_ease(Tween.EASE_OUT)
	tw_sl.parallel().tween_property(sl, "modulate", Color(3.0, 3.0, 3.0, 1.0), 0.08)
	tw_sl.tween_property(sl, "scale", Vector2(0.85, 0.85), 0.10).set_ease(Tween.EASE_IN)
	tw_sl.parallel().tween_property(sl, "modulate", Color(1.2, 1.2, 1.2, 1.0), 0.13)
	tw_sl.tween_property(sl, "scale", Vector2(1.0, 1.0), 0.10)
	tw_sl.tween_property(sl, "modulate:a", 0.28, 0.42)

	# ── 5. Três anéis expansivos no slot (defasados) ───────────────────────────
	for ri in range(3):
		var rng := Control.new()
		var rw : float = 100.0
		rng.position     = slot_center - Vector2(rw, rw)
		rng.size         = Vector2(rw * 2.0, rw * 2.0)
		rng.mouse_filter = Control.MOUSE_FILTER_IGNORE
		rng.z_index      = 10
		var rrad  : float = 20.0
		var ralph : float = 1.0 - float(ri) * 0.22
		var rwid  : float = 4.0 - float(ri) * 0.9
		var rcor  : Color = cor
		rng.draw.connect(func():
			rng.draw_arc(Vector2(rw, rw), rrad, 0.0, TAU, 72, Color(rcor.r, rcor.g, rcor.b, ralph), rwid, false))
		_hud.add_child(rng)
		var tw_r := create_tween()
		tw_r.tween_interval(float(ri) * 0.09)
		tw_r.tween_method(func(v: float) -> void:
			rrad  = 20.0 + v * 80.0
			ralph = (1.0 - float(ri) * 0.22) * (1.0 - v)
			rng.queue_redraw(),
			0.0, 1.0, 0.50)
		tw_r.tween_callback(rng.queue_free)

	# ── 6. 20 partículas burst com velocidades variadas ────────────────────────
	for pi in range(20):
		var sp := Control.new()
		var ang_p  : float = float(pi) / 20.0 * TAU
		var sz_p   : float = 2.0 + float(pi % 5) * 1.2
		var dist_p : float = 0.0
		var alp_p  : float = 1.0
		var pcor   : Color = cor
		sp.position     = slot_center - Vector2(sz_p, sz_p)
		sp.size         = Vector2(sz_p * 2.0, sz_p * 2.0)
		sp.mouse_filter = Control.MOUSE_FILTER_IGNORE
		sp.z_index      = 11
		sp.draw.connect(func():
			sp.draw_circle(Vector2(sz_p, sz_p), sz_p, Color(pcor.r, pcor.g, pcor.b, alp_p)))
		_hud.add_child(sp)
		var dmax  : float = 42.0 + float(pi % 6) * 16.0
		var spd   : float = 0.28 + float(pi % 4) * 0.07
		var ac    : float = ang_p
		var szc   : float = sz_p
		var sc_ref := slot_center
		var tw_p := create_tween()
		tw_p.tween_interval(float(pi % 3) * 0.03)
		tw_p.tween_method(func(v: float) -> void:
			dist_p = v * dmax
			alp_p  = 1.0 - v * v
			sp.position = sc_ref - Vector2(szc, szc) + Vector2(cos(ac), sin(ac)) * dist_p
			sp.queue_redraw(),
			0.0, 1.0, spd)
		tw_p.tween_callback(sp.queue_free)

	# ── 7. Raios radiais (linhas brancas que explodem do slot) ─────────────────
	var ray_ctrl := Control.new()
	var rw2 : float = 120.0
	ray_ctrl.position     = slot_center - Vector2(rw2, rw2)
	ray_ctrl.size         = Vector2(rw2 * 2.0, rw2 * 2.0)
	ray_ctrl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ray_ctrl.z_index      = 9
	var ray_prog  : float = 0.0
	var ray_alpha : float = 0.9
	var ray_cor   : Color = cor
	ray_ctrl.draw.connect(func():
		for ri2 in range(8):
			var a2 : float = float(ri2) / 8.0 * TAU + ray_prog * 0.5
			var r0 := Vector2(rw2, rw2) + Vector2(cos(a2), sin(a2)) * (22.0 + ray_prog * 20.0)
			var r1 := Vector2(rw2, rw2) + Vector2(cos(a2), sin(a2)) * (22.0 + ray_prog * rw2 * 0.75)
			ray_ctrl.draw_line(r0, r1, Color(ray_cor.r * 1.4, ray_cor.g * 1.4, ray_cor.b * 1.4, ray_alpha * 0.75), 2.5))
	_hud.add_child(ray_ctrl)
	var tw_ray := create_tween()
	tw_ray.tween_method(func(v: float) -> void:
		ray_prog  = v
		ray_alpha = 0.9 * (1.0 - v)
		ray_ctrl.queue_redraw(),
		0.0, 1.0, 0.38)
	tw_ray.tween_callback(ray_ctrl.queue_free)


func atualizar_kills(mortos: int, total: int) -> void:
	if _kills_lbl:
		_kills_lbl.text = "Kills: %d / %d" % [mortos, total]


func mostrar_wave(wave: int, mod: String = "") -> void:
	# Atualiza label do modificador
	if _mod_lbl:
		match mod:
			"furia":    _mod_lbl.text = "WAVE FURIA - Inimigos +35% dano"
			"densa":    _mod_lbl.text = "WAVE DENSA - +40% mais inimigos"
			"elite":    _mod_lbl.text = "WAVE ELITE - Normais viram Elite"
			"blindada": _mod_lbl.text = "WAVE BLINDADA - +3 escudos por mob"
			_:          _mod_lbl.text = ""

	var lbl := Label.new()
	lbl.text = "WAVE  %d" % wave
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.position = Vector2(490, 280)
	lbl.size     = Vector2(300, 90)
	lbl.add_theme_font_size_override("font_size", 69)
	lbl.add_theme_color_override("font_color", Color(0.3, 0.82, 1.0))
	_hud.add_child(lbl)

	if mod != "":
		var cores_mod := {
			"furia":    Color(1.0, 0.55, 0.1),
			"densa":    Color(0.8, 0.55, 1.0),
			"elite":    Color(1.0, 0.82, 0.1),
			"blindada": Color(0.55, 0.82, 1.0),
		}
		var lbl_mod := Label.new()
		lbl_mod.text = "[ %s ]" % mod.to_upper()
		lbl_mod.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl_mod.position = Vector2(490, 342)
		lbl_mod.size     = Vector2(300, 48)
		lbl_mod.add_theme_font_size_override("font_size", 27)
		lbl_mod.add_theme_color_override("font_color", cores_mod.get(mod, Color(1.0, 0.8, 0.3)) as Color)
		_hud.add_child(lbl_mod)
		var tw2 := create_tween()
		tw2.tween_property(lbl_mod, "modulate:a", 0.0, 1.6).set_delay(0.8)
		tw2.tween_callback(lbl_mod.queue_free)

	var tw := create_tween()
	tw.tween_property(lbl, "modulate:a", 0.0, 1.4).set_delay(0.7)
	tw.tween_callback(lbl.queue_free)


func mostrar_btn_iniciar_wave() -> void:
	# Botão aparece após carta ser escolhida quando pausa_auto_wave está ativo
	var btn := Button.new()
	btn.text      = "▶  INICIAR WAVE"
	btn.position  = Vector2(490, 650)
	btn.size      = Vector2(300, 69)
	btn.focus_mode = Control.FOCUS_NONE
	btn.add_theme_font_size_override("font_size", 27)
	var sty := StyleBoxFlat.new()
	sty.bg_color     = Color(0.0, 0.15, 0.08, 0.95)
	sty.border_color = Color(0.0, 0.82, 0.45, 0.9)
	for side in ["left","right","top","bottom"]:
		sty.set("border_width_" + side, 2)
	for corner in ["top_left","top_right","bottom_left","bottom_right"]:
		sty.set("corner_radius_" + corner, 10)
	btn.add_theme_stylebox_override("normal", sty)
	var sty_h : StyleBoxFlat = sty.duplicate()
	sty_h.bg_color = Color(0.0, 0.28, 0.14, 0.97)
	btn.add_theme_stylebox_override("hover", sty_h)
	btn.add_theme_color_override("font_color", Color(0.3, 1.0, 0.6))
	btn.pressed.connect(func():
		btn.queue_free()
		_iniciar_wave_btn = null
		if jogo and is_instance_valid(jogo):
			jogo.call("_iniciar_wave")
	)
	_hud.add_child(btn)
	_iniciar_wave_btn = btn


var _reroll_count : int  = 0
const _REROLL_MAX : int  = 5
var _m4_usado     : bool = false

func mostrar_cartas(cartas: Array, is_x4: bool = false) -> void:
	if _upgrade_ativo:
		return
	_upgrade_ativo  = true

	_overlay = ColorRect.new()
	_overlay.color = Color(0.18, 0.05, 0.0, 0.86) if is_x4 else Color(0.0, 0.0, 0.02, 0.82)
	_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	_overlay.z_index = 100
	_hud.add_child(_overlay)

	var vp_w_c : float = get_viewport().get_visible_rect().size.x
	_panel = Control.new()
	_panel.position = Vector2(0, 0)
	_panel.size     = Vector2(vp_w_c, 720)
	_panel.z_index  = 101
	_hud.add_child(_panel)

	# Título
	var titulo := Label.new()
	if is_x4:
		titulo.text = "CARTA  DO  ACASO"
		titulo.add_theme_color_override("font_color", Color(1.0, 0.65, 0.15))
	else:
		titulo.text = "ESCOLHA  UMA  CARTA"
		titulo.add_theme_color_override("font_color", Color(0.82, 0.72, 1.0))
	titulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	titulo.position             = Vector2(0, 81)
	titulo.size                 = Vector2(vp_w_c, 52)
	titulo.add_theme_font_size_override("font_size", 37)
	_panel.add_child(titulo)

	# Subtítulo especial X4
	if is_x4:
		var sub_x4 := Label.new()
		sub_x4.text                 = "Kill em combate ativou o talento Carta do Acaso"
		sub_x4.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		sub_x4.position             = Vector2(0, 60)
		sub_x4.size                 = Vector2(vp_w_c, 20)
		sub_x4.add_theme_font_size_override("font_size", 13)
		sub_x4.add_theme_color_override("font_color", Color(1.0, 0.55, 0.10, 0.85))
		_panel.add_child(sub_x4)

	# Cartas centradas — largura dinâmica baseada na quantidade
	var n_cartas  : int   = cartas.size()
	var card_h    : float = 410.0
	var gap       : float = 20.0
	var margem    : float = 30.0
	var card_w    : float = 265.0
	var total_w   : float = float(n_cartas) * card_w + float(n_cartas - 1) * gap
	# Reduz card_w se não couber na tela
	if total_w > vp_w_c - margem * 2.0:
		card_w  = (vp_w_c - margem * 2.0 - float(n_cartas - 1) * gap) / float(n_cartas)
		total_w = vp_w_c - margem * 2.0
	var start_x   : float = (vp_w_c - total_w) * 0.5
	var start_y   : float = 140.0

	for i in range(cartas.size()):
		var carta : Dictionary = cartas[i] as Dictionary
		_criar_carta(carta, start_x + float(i) * (card_w + gap), start_y, card_w, card_h)

	# ── Wave preview ──────────────────────────────────────────────────────────
	if jogo and is_instance_valid(jogo):
		var next_cfg = jogo.call("get_next_wave_config")
		if next_cfg is Dictionary:
			var cfg : Dictionary = next_cfg as Dictionary
			# Conta tipos presentes
			var nomes_tipo := {
				"normal":"Nrm", "fast":"Rápido", "tank":"Tank", "elite":"Elite",
				"berserker":"Bsrk", "colossus":"Coloss",
				"atirador":"Atrd", "curandeiro":"Cur", "invocador":"Inv",
				"bruxo":"Bruxo", "suporte":"Sup",
				"escudeiro":"Escud", "fantasma":"Fantas", "boss1":"BOSS",
				"vampiro":"Vampiro", "espelho":"Espelho", "ladrao":"Ladrão", "ancora":"Âncora",
				"regenerador":"Regen", "divididor":"Divid", "kamikaze":"Kami", "blindado":"Blind", "necromante":"Necro"
			}
			var partes : Array = []
			for t in nomes_tipo.keys():
				var qtd : int = int(cfg.get(t, 0))
				if qtd > 0:
					partes.append("%d×%s" % [qtd, nomes_tipo[t] as String])
			if not partes.is_empty():
				var prv_lbl := Label.new()
				prv_lbl.name = "ProxWave"
				prv_lbl.text = "Próxima wave:  " + "  ·  ".join(partes)
				prv_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
				prv_lbl.position = Vector2(0, 556)
				prv_lbl.size     = Vector2(vp_w_c, 20)
				prv_lbl.add_theme_font_size_override("font_size", 14)
				prv_lbl.add_theme_color_override("font_color", Color(0.50, 0.62, 0.78))
				_panel.add_child(prv_lbl)

	# ── Botão de reroll ───────────────────────────────────────────────────────
	var esgotado : bool = _reroll_count >= _REROLL_MAX
	var base_rr  : int  = 200 - (50 if Salvar.talento_ativo("m3") else 0)
	var custo_rr : int  = base_rr + _reroll_count * 100   # escala: 200, 300, 400, 500, 600
	var btn_rr := Button.new()
	btn_rr.text       = "REROLL  (%d ouro)   [%d/%d]" % [custo_rr, _reroll_count, _REROLL_MAX] if not esgotado \
						else "REROLL  esgotado  [%d/%d]" % [_reroll_count, _REROLL_MAX]
	var mobile_cards := OS.has_feature("android") or OS.has_feature("ios")
	var rr_w := minf(560.0, vp_w_c - 60.0)
	var rr_h := 54.0 if mobile_cards else 42.0
	btn_rr.position   = Vector2((vp_w_c - rr_w) * 0.5, 574.0 if mobile_cards else 580.0)
	btn_rr.size       = Vector2(rr_w, rr_h)
	btn_rr.focus_mode = Control.FOCUS_NONE
	btn_rr.add_theme_font_size_override("font_size", 17)
	var sty_rr := StyleBoxFlat.new()
	sty_rr.bg_color     = Color(0.10, 0.12, 0.10, 0.92)
	sty_rr.border_color = Color(0.55, 0.82, 0.30, 0.85) if not esgotado else Color(0.4, 0.4, 0.4, 0.6)
	for side in ["left","right","top","bottom"]: sty_rr.set("border_width_" + side, 1)
	for corner in ["top_left","top_right","bottom_left","bottom_right"]: sty_rr.set("corner_radius_" + corner, 6)
	btn_rr.add_theme_stylebox_override("normal", sty_rr)
	btn_rr.add_theme_color_override("font_color",
		Color(0.70, 0.95, 0.45) if not esgotado else Color(0.45, 0.45, 0.45))
	btn_rr.pressed.connect(func() -> void:
		if _reroll_count >= _REROLL_MAX:
			return   # bloqueado definitivamente
		if not (jogo and is_instance_valid(jogo)): return
		var custo_atual : int = base_rr + _reroll_count * 100
		var desc_rr := "Reroll. Custo: %d ouro. Restam %d usos." % [custo_atual, _REROLL_MAX - _reroll_count]
		Acessibilidade.processar("cartas_reroll", desc_rr, func():
			if _reroll_count >= _REROLL_MAX: return
			if not (jogo and is_instance_valid(jogo)): return
			var c : int = base_rr + _reroll_count * 100
			if jogo.gold < c:
				var sty_err : StyleBoxFlat = sty_rr.duplicate()
				sty_err.border_color = Color(1.0, 0.22, 0.22)
				btn_rr.add_theme_stylebox_override("normal", sty_err)
				return
			_reroll_count  += 1
			_upgrade_ativo  = false
			_carta_pendente_btn    = null
			_carta_pendente_efeito = ""
			_carta_pendente_val    = 0.0
			if _overlay: _overlay.queue_free(); _overlay = null
			if _panel:   _panel.queue_free();   _panel   = null
			jogo.call("reroll_cartas", c)
		)
	)
	_panel.add_child(btn_rr)


func _raridade_cor(r: String) -> Color:
	match r:
		"incomum":  return Color(0.22, 0.88, 0.42)
		"raro":     return Color(0.28, 0.55, 1.0)
		"epico":    return Color(1.0,  0.80, 0.08)
		"lendario": return Color(1.0,  0.35, 0.85)
	return Color(0.55, 0.55, 0.58)   # comum


func _raridade_texto(r: String) -> String:
	match r:
		"incomum":  return "◆◆  INCOMUM"
		"raro":     return "◆◆◆  RARO"
		"epico":    return "◆◆◆◆  ÉPICO"
		"lendario": return "★★★★★  LENDÁRIA"
	return "◆  COMUM"


func _criar_carta(carta: Dictionary, x: float, y: float, w: float, h: float) -> void:
	var cor      : Color  = carta["cor"]      as Color
	var nome     : String = carta["nome"]     as String
	var desc     : String = carta["desc"]     as String
	var efeito   : String = carta["efeito"]   as String
	var val      : float  = carta["val"]      as float
	var raridade : String = carta.get("raridade", "comum") as String

	var card := Button.new()
	card.position   = Vector2(x, y)
	card.size       = Vector2(w, h)
	card.text       = ""
	card.focus_mode = Control.FOCUS_NONE

	var rcor  : Color = _raridade_cor(raridade)
	var bw    : int   = 2 if raridade == "comum" else (3 if raridade == "incomum" else (4 if raridade == "raro" else 5))
	var sty := StyleBoxFlat.new()
	sty.bg_color     = Color(cor.r * 0.09, cor.g * 0.09, cor.b * 0.09, 0.95)
	sty.border_color = rcor if raridade != "comum" else Color(cor.r, cor.g, cor.b, 0.80)
	for side in ["left","right","top","bottom"]:
		sty.set("border_width_" + side, bw)
	for corner in ["top_left","top_right","bottom_left","bottom_right"]:
		sty.set("corner_radius_" + corner, 14)
	card.add_theme_stylebox_override("normal", sty)
	var sty_h : StyleBoxFlat = sty.duplicate()
	sty_h.bg_color     = Color(cor.r * 0.22, cor.g * 0.22, cor.b * 0.22, 0.97)
	sty_h.border_color = rcor if raridade != "comum" else Color(cor.r, cor.g, cor.b, 1.0)
	for side in ["left","right","top","bottom"]:
		sty_h.set("border_width_" + side, bw + 1)
	card.add_theme_stylebox_override("hover", sty_h)
	_panel.add_child(card)

	# Círculo de fundo do ícone
	var bg_ico := ColorRect.new()
	bg_ico.color        = Color(cor.r * 0.07, cor.g * 0.07, cor.b * 0.07, 0.92)
	bg_ico.position     = Vector2((w - 108.0) * 0.5, 12.0)
	bg_ico.size         = Vector2(108.0, 162)
	bg_ico.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(bg_ico)

	# Ícone animado (mapa efeito → tipo de ícone)
	var _mapa_icone := {
		"dano": "dano",       "cadencia": "cadencia",   "alcance": "alcance",
		"vida": "vida",       "pierce":   "perfurante",  "multi":   "multitiro",
		"speed": "velocidade","regen":    "regeneracao", "reducao": "escudo",
		"ouro": "ouro",
	}
	var icone       := ICONE_SCENE.new()
	icone.tipo       = _mapa_icone.get(efeito, "dano") as String
	icone.cor        = cor
	icone.position   = Vector2((w - 100.0) * 0.5, 20.0)
	icone.size       = Vector2(100.0, 150)
	card.add_child(icone)

	# Separador superior
	var sep := ColorRect.new()
	sep.color       = Color(cor.r, cor.g, cor.b, 0.35)
	sep.position    = Vector2(24.0, 178)
	sep.size        = Vector2(w - 48.0, 2.0)
	sep.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(sep)

	# Nome
	var lnome := Label.new()
	lnome.text                 = nome
	lnome.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lnome.position             = Vector2(8.0, 189)
	lnome.size                 = Vector2(w - 16.0, 38.0)
	lnome.add_theme_font_size_override("font_size", 20)
	lnome.add_theme_color_override("font_color", Color(cor.r + 0.15, cor.g + 0.10, cor.b, 1.0))
	card.add_child(lnome)

	# Descrição do bônus
	var ldesc := Label.new()
	ldesc.text                 = desc
	ldesc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ldesc.autowrap_mode        = TextServer.AUTOWRAP_WORD
	ldesc.position             = Vector2(14.0, 248)
	ldesc.size                 = Vector2(w - 28.0, 86.0)
	ldesc.add_theme_font_size_override("font_size", 16)
	ldesc.add_theme_color_override("font_color", Color(0.78, 0.82, 0.88))
	card.add_child(ldesc)

	# Badge de raridade
	var lrar := Label.new()
	lrar.text                 = _raridade_texto(raridade)
	lrar.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lrar.position             = Vector2(0.0, h - 68.0)
	lrar.size                 = Vector2(w, 18.0)
	lrar.add_theme_font_size_override("font_size", 12)
	lrar.add_theme_color_override("font_color", _raridade_cor(raridade))
	card.add_child(lrar)

	# Rodapé
	var lsel := Label.new()
	lsel.name                 = "LblSel"
	lsel.text                 = "ESCOLHER"
	lsel.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lsel.position             = Vector2(0.0, h - 44.0)
	lsel.size                 = Vector2(w, 36.0)
	lsel.add_theme_font_size_override("font_size", 15)
	lsel.add_theme_color_override("font_color", Color(cor.r, cor.g, cor.b, 0.68))
	card.add_child(lsel)

	var efeito_cap := efeito
	var val_cap    := val
	var id_cap     := carta.get("id", efeito) as String
	var sty_sel    := sty.duplicate() as StyleBoxFlat
	sty_sel.bg_color     = Color(cor.r * 0.35, cor.g * 0.35, cor.b * 0.35, 0.98)
	sty_sel.border_color = Color(cor.r, cor.g, cor.b, 1.0)
	for side in ["left","right","top","bottom"]:
		sty_sel.set("border_width_" + side, bw + 3)
	# Guarda estilo e cor original no metadata para restauração correta
	card.set_meta("sty_normal",  sty)
	card.set_meta("cor_lbl_sel", Color(cor.r, cor.g, cor.b, 0.68))

	var nome_cap := nome
	var desc_cap := desc
	var rar_cap  := raridade
	card.pressed.connect(func():
		if _carta_pendente_btn == card:
			# 2º clique — confirmar (passa por acessibilidade se ativa)
			var desc_fala := "%s — %s. Raridade: %s." % [nome_cap, desc_cap.replace("\n"," "), rar_cap]
			Acessibilidade.processar("carta_" + efeito_cap + "_" + nome_cap, desc_fala,
				func(): _escolheu_carta(efeito_cap, val_cap, id_cap))
		else:
			# Restaura carta anterior usando seu próprio estilo/cor originais
			if _carta_pendente_btn and is_instance_valid(_carta_pendente_btn):
				var sty_orig : StyleBoxFlat = _carta_pendente_btn.get_meta("sty_normal")
				_carta_pendente_btn.add_theme_stylebox_override("normal", sty_orig)
				_carta_pendente_btn.scale        = Vector2.ONE
				_carta_pendente_btn.rotation     = 0.0
				_carta_pendente_btn.pivot_offset = Vector2.ZERO
				var lbl_ant : Label = _carta_pendente_btn.get_node_or_null("LblSel")
				if lbl_ant:
					lbl_ant.text = "ESCOLHER"
					var cor_orig : Color = _carta_pendente_btn.get_meta("cor_lbl_sel")
					lbl_ant.add_theme_color_override("font_color", cor_orig)
			_carta_pendente_btn    = card
			_carta_pendente_efeito = efeito_cap
			_carta_pendente_val    = val_cap
			card.add_theme_stylebox_override("normal", sty_sel)
			lsel.text = "CONFIRMAR"
			lsel.add_theme_color_override("font_color", Color(cor.r + 0.2, cor.g + 0.2, cor.b + 0.2, 1.0))
			# Acessibilidade: anuncia a carta ao selecionar
			if Acessibilidade.ativo:
				Acessibilidade.falar("%s — %s" % [nome_cap, desc_cap.replace("\n"," ")])
			# Animação: balanço + crescimento
			card.pivot_offset = card.size * 0.5
			var tw := card.create_tween()
			tw.set_parallel(true)
			tw.tween_property(card, "scale", Vector2(1.07, 1.07), 0.18).set_ease(Tween.EASE_OUT)
			tw.tween_property(card, "rotation", deg_to_rad(3.5), 0.12).set_ease(Tween.EASE_OUT)
			tw.chain().tween_property(card, "rotation", deg_to_rad(-3.0), 0.18).set_ease(Tween.EASE_IN_OUT)
			tw.chain().tween_property(card, "rotation", deg_to_rad(2.0), 0.14).set_ease(Tween.EASE_IN_OUT)
			tw.chain().tween_property(card, "rotation", 0.0, 0.12).set_ease(Tween.EASE_OUT)
	)

	# Tooltip: aparece ao passar o mouse sobre a carta
	var picks_atuais : int = 0
	var picks_max    : int = int(carta.get("max_picks", 99))
	if jogo and is_instance_valid(jogo):
		var colhidas = jogo.get("_cartas_colhidas")
		if colhidas is Dictionary:
			picks_atuais = int((colhidas as Dictionary).get(carta.get("id", ""), 0))
		picks_max = jogo.call("_carta_max_picks", carta)
	var id_carta : String = carta.get("id", "") as String
	card.mouse_entered.connect(_mostrar_tooltip.bind(carta, card, picks_atuais, picks_max, id_carta))
	card.mouse_exited.connect(_fechar_tooltip)


func _escolheu_carta(efeito: String, val: float, id: String = "") -> void:
	Acessibilidade.cancelar_foco()
	if _carta_pendente_btn and is_instance_valid(_carta_pendente_btn):
		_carta_pendente_btn.scale    = Vector2.ONE
		_carta_pendente_btn.rotation = 0.0
	_carta_pendente_btn    = null
	_carta_pendente_efeito = ""
	_carta_pendente_val    = 0.0
	_reroll_count  = 0
	_upgrade_ativo = false
	_fechar_tooltip()
	Som.upgrade()
	if _overlay: _overlay.queue_free()
	if _panel:   _panel.queue_free()
	_overlay = null
	_panel   = null
	if jogo:
		# M4 — Dupla Escolha: 1× por partida permite pegar 2 cartas.
		# NUNCA aplica à escolha de ARMA (é seleção especial, não carta dupla).
		if efeito != "arma" and Salvar.talento_ativo("m4") and not _m4_usado:
			_m4_usado = true
			jogo.aplicar_carta_m4(efeito, val, id)
		else:
			jogo.aplicar_carta(efeito, val, id)


func _mostrar_tooltip(carta: Dictionary, card: Control,
		picks_atuais: int, picks_max: int, id_carta: String) -> void:
	_fechar_tooltip()
	if not _panel or not is_instance_valid(_panel):
		return
	var cor    : Color  = carta.get("cor",      Color.WHITE) as Color
	var nome   : String = carta.get("nome",     "") as String
	var desc   : String = carta.get("desc",     "") as String
	var rar    : String = carta.get("raridade", "comum") as String

	# Posição do tooltip: abaixo das cartas
	var tp := Panel.new()
	tp.position = Vector2(0, 624)
	tp.size     = Vector2(_panel.size.x if _panel else 1280.0, 96)
	tp.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var sty_tp := StyleBoxFlat.new()
	sty_tp.bg_color     = Color(cor.r * 0.08, cor.g * 0.08, cor.b * 0.12, 0.96)
	sty_tp.border_color = Color(cor.r, cor.g, cor.b, 0.60)
	for side in ["left","right","top","bottom"]:
		sty_tp.set("border_width_" + side, 1)
	tp.add_theme_stylebox_override("panel", sty_tp)
	_panel.add_child(tp)
	_tooltip_panel = tp

	# Nome
	var lnome := Label.new()
	lnome.text = nome
	lnome.position = Vector2(20, 8)
	lnome.size     = Vector2(400, 45)
	lnome.add_theme_font_size_override("font_size", 36)
	lnome.add_theme_color_override("font_color", Color(cor.r + 0.2, cor.g + 0.2, cor.b + 0.2))
	lnome.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tp.add_child(lnome)

	# Raridade
	var lrar := Label.new()
	lrar.text = _raridade_texto(rar)
	lrar.position = Vector2(20, 59)
	lrar.size     = Vector2(220, 33)
	lrar.add_theme_font_size_override("font_size", 26)
	lrar.add_theme_color_override("font_color", _raridade_cor(rar))
	lrar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tp.add_child(lrar)

	# Descrição
	var ldesc := Label.new()
	ldesc.text = desc.replace("\n", "  ·  ")
	ldesc.position = Vector2(360, 8)
	ldesc.size     = Vector2(560, 42)
	ldesc.add_theme_font_size_override("font_size", 27)
	ldesc.add_theme_color_override("font_color", Color(0.78, 0.85, 0.92))
	ldesc.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tp.add_child(ldesc)

	# Picks (acúmulo)
	var lpick := Label.new()
	if picks_max >= 99:
		lpick.text = "Selecionada %d vez(es)  ·  Sem limite" % picks_atuais
		lpick.add_theme_color_override("font_color", Color(0.55, 0.72, 0.55))
	else:
		lpick.text = "Selecionada %d/%d vez(es) nesta partida" % [picks_atuais, picks_max]
		lpick.add_theme_color_override("font_color",
			Color(0.9, 0.3, 0.3) if picks_atuais >= picks_max else Color(0.55, 0.72, 0.55))
	lpick.position = Vector2(360, 59)
	lpick.size     = Vector2(480, 33)
	lpick.add_theme_font_size_override("font_size", 26)
	lpick.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tp.add_child(lpick)

	# Preview: stat atual → stat depois de aplicar a carta
	var preview_txt : String = ""
	var efeito_tt : String = carta.get("efeito", "") as String
	var val_tt    : float  = carta.get("val",    0.0) as float
	if jogo and is_instance_valid(jogo) and jogo.torre and is_instance_valid(jogo.torre):
		var tt = jogo.torre
		match efeito_tt:
			"dano":     preview_txt = "Dano: %.0f → %.0f" % [tt.damage,    tt.damage    + val_tt]
			"cadencia": preview_txt = "Cadência: %.2f → %.2f /s" % [tt.fire_rate, tt.fire_rate + val_tt]
			"alcance":  preview_txt = "Alcance: %.0f → %.0f px" % [tt.range_r,   tt.range_r  + val_tt]
			"vida":     preview_txt = "HP máx: %.0f → %.0f" % [tt.max_hp,  tt.max_hp   + val_tt]
			"veneno":   preview_txt = "Veneno DPS: %.0f → %.0f" % [tt.veneno_dps, tt.veneno_dps + val_tt]
			"critico":  preview_txt = "Chance crítico: %.0f%% → %.0f%%" % [tt.crit_chance*100.0, (tt.crit_chance+val_tt)*100.0]
			"regen":    preview_txt = "Regen: %.1f → %.1f HP/s" % [tt.regen_rate, tt.regen_rate + val_tt]
			"speed":    preview_txt = "Vel. projétil: +%.0f" % val_tt
	if preview_txt != "":
		var lprev := Label.new()
		lprev.text     = preview_txt
		lprev.position = Vector2(950, 59)
		lprev.size     = Vector2(290, 33)
		lprev.add_theme_font_size_override("font_size", 26)
		lprev.add_theme_color_override("font_color", Color(1.0, 0.92, 0.45))
		lprev.mouse_filter = Control.MOUSE_FILTER_IGNORE
		tp.add_child(lprev)

	# Próxima wave label — mover para ficar abaixo do tooltip
	var prv_lbl_node = _panel.get_node_or_null("ProxWave")
	if prv_lbl_node:
		(prv_lbl_node as Label).visible = false


func _fechar_tooltip() -> void:
	if _tooltip_panel and is_instance_valid(_tooltip_panel):
		_tooltip_panel.queue_free()
	_tooltip_panel = null
	if _panel and is_instance_valid(_panel):
		var prv = _panel.get_node_or_null("ProxWave")
		if prv: (prv as Label).visible = true


# ── Atalhos de teclado ────────────────────────────────────────────────────────

func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey): return
	if not (event as InputEventKey).pressed: return
	var kc : int = (event as InputEventKey).keycode
	match kc:
		KEY_SPACE:
			# Toggle pausa
			if Engine.time_scale > 0.0:
				_definir_velocidade(0.0)
			else:
				_definir_velocidade(1.0)
		KEY_1:
			_definir_velocidade(1.0)
		KEY_2:
			_definir_velocidade(2.0)
		KEY_3:
			_definir_velocidade(3.0)
		KEY_ENTER, KEY_KP_ENTER:
			# Iniciar wave se botão estiver visível
			if _iniciar_wave_btn and is_instance_valid(_iniciar_wave_btn):
				_iniciar_wave_btn.pressed.emit()
		KEY_F11:
			if not OS.has_feature("android") and not OS.has_feature("ios"):
				var modo := DisplayServer.window_get_mode()
				if modo == DisplayServer.WINDOW_MODE_FULLSCREEN:
					DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
				else:
					DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)


# ── Barra de HP do Boss ───────────────────────────────────────────────────────

func mostrar_boss_hp_bar(nome: String, max_hp_val: float) -> void:
	esconder_boss_hp_bar()

	var bar_h : float = 28.0
	var bar_y : float = 720.0 - bar_h - 4.0

	var vp_w_boss : float = get_viewport().get_visible_rect().size.x
	var cont := Control.new()
	cont.position     = Vector2(0.0, bar_y)
	cont.size         = Vector2(vp_w_boss, bar_h)
	cont.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_hud.add_child(cont)
	_boss_hp_bar = cont

	# Fundo escuro
	var bg := ColorRect.new()
	bg.color        = Color(0.05, 0.0, 0.0, 0.90)
	bg.position     = Vector2.ZERO
	bg.size         = Vector2(vp_w_boss, bar_h)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cont.add_child(bg)

	# Barra de HP (preenchida)
	var fill := ColorRect.new()
	fill.name        = "Fill"
	fill.color       = Color(0.88, 0.08, 0.05, 1.0)
	fill.position    = Vector2(0.0, 0.0)
	fill.size        = Vector2(vp_w_boss, bar_h)
	fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cont.add_child(fill)

	# Borda brilhante
	var bord := ColorRect.new()
	bord.color        = Color(1.0, 0.28, 0.08, 0.75)
	bord.position     = Vector2(0.0, 0.0)
	bord.size         = Vector2(vp_w_boss, 2.0)
	bord.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cont.add_child(bord)

	# Label do nome
	var lbl := Label.new()
	lbl.text                 = "%s   HP" % nome
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.set_anchors_preset(Control.PRESET_FULL_RECT)
	lbl.add_theme_font_size_override("font_size", 21)
	lbl.add_theme_color_override("font_color", Color(1.0, 0.85, 0.85, 0.92))
	lbl.mouse_filter         = Control.MOUSE_FILTER_IGNORE
	cont.add_child(lbl)

	# Guarda o max_hp como metadado
	cont.set_meta("max_hp", max_hp_val)


func atualizar_boss_hp(hp: float, max_hp: float) -> void:
	if not _boss_hp_bar or not is_instance_valid(_boss_hp_bar):
		return
	var fill = _boss_hp_bar.find_child("Fill")
	if fill:
		var ratio : float = clampf(hp / max_hp, 0.0, 1.0)
		(fill as ColorRect).size = Vector2(_boss_hp_bar.size.x * ratio, (fill as ColorRect).size.y)
		# Muda cor conforme HP: verde → amarelo → vermelho
		if ratio > 0.50:
			(fill as ColorRect).color = Color(0.88, 0.08, 0.05)
		elif ratio > 0.25:
			(fill as ColorRect).color = Color(0.88, 0.45, 0.05)
		else:
			(fill as ColorRect).color = Color(1.0, 0.18, 0.05)


func esconder_boss_hp_bar() -> void:
	if _boss_hp_bar and is_instance_valid(_boss_hp_bar):
		_boss_hp_bar.queue_free()
	_boss_hp_bar = null


func mostrar_game_over(score: int, wave: int, gold: int = 0,
		custo_alma: int = 0, cb_alma: Callable = Callable(),
		tem_vela: bool = false, cb_vela: Callable = Callable(),
		cb_sair: Callable = Callable()) -> void:
	fechar_cartas()
	var vp_size : Vector2 = get_viewport().get_visible_rect().size
	var vp_w : float = vp_size.x
	var vp_h : float = vp_size.y
	var compacto_go : bool = vp_h <= 760.0
	var modo_abismo : bool = jogo and is_instance_valid(jogo) and (jogo.get("modo_abismo") as bool)
	var diff_idx    : int   = Salvar.dificuldade
	var diff_nomes  : Array = ["FÁCIL  ×0.4", "NORMAL  ×1.0", "DIFÍCIL  ×1.6"]
	var diff_cores  : Array = [Color(0.4,0.8,0.4), Color(0.65,0.88,1.0), Color(1.0,0.55,0.2)]
	var diff_txt    : String = ("ABISMO  ×2.0" if modo_abismo else diff_nomes[diff_idx])
	var diff_cor    : Color  = (Color(1.0,0.28,0.28) if modo_abismo else diff_cores[diff_idx])
	var hs_val      : int    = Salvar.high_score_facil if (diff_idx==0 and not modo_abismo) else Salvar.high_score

	# ── Overlay escuro (root — fechar_tela_alma() libera tudo) ─────────
	var ov := ColorRect.new()
	ov.color        = Color(0.04, 0.0, 0.02, 0.0)
	ov.z_index      = 20; ov.position = Vector2.ZERO; ov.size = Vector2(vp_w, vp_h)
	ov.mouse_filter = Control.MOUSE_FILTER_STOP
	ov.process_mode = Node.PROCESS_MODE_ALWAYS
	_hud.add_child(ov)
	_alma_overlay = ov
	var tw_ov := create_tween()
	tw_ov.tween_property(ov, "color", Color(0.04, 0.0, 0.02, 0.92), 0.75)

	# ── Flash de impacto ─────────────────────────
	var flash := ColorRect.new()
	flash.color = Color(0.55, 0.0, 0.0, 0.0)
	flash.position = Vector2.ZERO; flash.size = Vector2(vp_w, vp_h)
	flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ov.add_child(flash)

	# ── DERROTA — desenho customizado ──────────────────
	var _go_cor := Color(0.88, 0.06, 0.06)
	var _go_txt := "DERROTA"
	var titulo := Control.new()
	titulo.size = Vector2(vp_w, 112 if compacto_go else 130)
	titulo.position = Vector2(0, -180)
	titulo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	titulo.draw.connect(func():
		var _font := ThemeDB.fallback_font
		var _bw : float = titulo.size.x
		var _fs : int = 78 if compacto_go else 100
		var _ty : float = 86.0 if compacto_go else 100.0
		titulo.draw_string(_font, Vector2(6, _ty), _go_txt,
			HORIZONTAL_ALIGNMENT_CENTER, _bw, _fs, Color(0.0,0.0,0.0,0.65))
		for _gi in range(4):
			titulo.draw_string(_font, Vector2(0, _ty - float(_gi)*1.5), _go_txt,
				HORIZONTAL_ALIGNMENT_CENTER, _bw, _fs,
				Color(_go_cor.r, 0.0, 0.0, 0.07 - float(_gi)*0.015))
		titulo.draw_string(_font, Vector2(0, _ty), _go_txt,
			HORIZONTAL_ALIGNMENT_CENTER, _bw, _fs, _go_cor)
		titulo.draw_string(_font, Vector2(0, _ty - 8.0), _go_txt,
			HORIZONTAL_ALIGNMENT_CENTER, _bw, _fs, Color(1.0, 0.6, 0.6, 0.10))
	)
	ov.add_child(titulo)

	var sep := ColorRect.new()
	sep.color = Color(_go_cor.r, 0.04, 0.04, 0.0)
	sep.size = Vector2(520, 2); sep.position = Vector2((vp_w-520)*0.5, 122 if compacto_go else 152)
	sep.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ov.add_child(sep)

	# ── Animação: título cai + impacto ─────────────────
	var tw_t := create_tween()
	tw_t.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	tw_t.tween_interval(0.25)
	tw_t.tween_property(titulo, "position:y", 58.0 if compacto_go else 90.0, 0.5)
	tw_t.tween_callback(func():
		Som.game_over_som()
		var tw_fl := create_tween()
		tw_fl.tween_property(flash, "color:a", 0.38, 0.04)
		tw_fl.tween_property(flash, "color:a", 0.0, 0.45)
		var tw_sh := create_tween()
		for _si in range(7):
			tw_sh.tween_property(titulo, "position:x",
				randf_range(-10.0, 10.0) * (1.0 - float(_si)*0.13), 0.035)
		tw_sh.tween_property(titulo, "position:x", 0.0, 0.04)
		var tw_sep := create_tween()
		tw_sep.tween_property(sep, "color:a", 0.6, 0.35)
	)

	# ── Botões de revive (entre título e stats) ───────────────
	var _mk_sty_go := func(bg: Color, brd: Color) -> StyleBoxFlat:
		var _s := StyleBoxFlat.new()
		_s.bg_color = bg; _s.border_color = brd
		for _sd2 in ["left","right","top","bottom"]: _s.set("border_width_"+_sd2, 2)
		for _cr in ["top_left","top_right","bottom_left","bottom_right"]: _s.set("corner_radius_"+_cr, 8)
		return _s

	# ── Stats em sequência ────────────────────────────────────
	var _stats : Array = [
		[diff_txt, diff_cor, 26],
		["Wave %d" % wave, Color(0.75,0.75,0.75), 34],
		["Score: %s" % _fmt_num(score), Color(0.92,0.92,1.0), 44],
		["Recorde: %s" % _fmt_num(hs_val), Color(0.5,0.5,0.55), 22],
		["+ %s ouro depositado" % _fmt_num(gold), Color(1.0,0.85,0.15), 26],
	]
	var _sy : float = 168.0 if compacto_go else 210.0
	var _sd : float = 0.95
	for _st in _stats:
		var _sl := Label.new()
		_sl.text = _st[0] as String
		_sl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		var _fs_stat : int = _st[2] as int
		if compacto_go:
			_fs_stat = maxi(17, int(float(_fs_stat) * 0.78))
		_sl.add_theme_font_size_override("font_size", _fs_stat)
		_sl.add_theme_color_override("font_color", _st[1] as Color)
		_sl.size = Vector2(vp_w, 42 if compacto_go else 52); _sl.position = Vector2(0, _sy + 12)
		_sl.modulate.a = 0.0
		_sl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		ov.add_child(_sl)
		var _tw_s := create_tween()
		_tw_s.tween_interval(_sd)
		_tw_s.parallel().tween_property(_sl, "modulate:a", 1.0, 0.4)
		_tw_s.parallel().tween_property(_sl, "position:y", _sy, 0.4).set_ease(Tween.EASE_OUT)
		_sy += float(_fs_stat) + (4.0 if compacto_go else 8.0); _sd += 0.16

	# ── Botões de revive (após stats) ────────────────────────────────────────
	var _btn_w_go : float = minf(500.0, vp_w - 80.0)
	var _rev_h : float = 44.0 if compacto_go else 52.0
	var _nav_main_h : float = 50.0 if compacto_go else 62.0
	var _nav_h : float = 44.0 if compacto_go else 54.0
	var _gap_go : float = 8.0 if compacto_go else 14.0
	var _rbx : float = (vp_w - _btn_w_go) * 0.5
	var _rby : float = _sy + (6.0 if compacto_go else 12.0)

	if custo_alma > 0:
		var _tem_cr : bool = Salvar.cristais >= custo_alma
		var _balma := Button.new()
		_balma.text = "INVOCAR ALMA  [ -%d cristais ]" % custo_alma
		_balma.focus_mode = Control.FOCUS_NONE
		_balma.custom_minimum_size = Vector2(_btn_w_go, _rev_h); _balma.size = Vector2(_btn_w_go, _rev_h)
		_balma.position = Vector2(_rbx, _rby); _balma.modulate.a = 0.0
		_balma.add_theme_font_size_override("font_size", 20 if compacto_go else 24)
		var _bg_a := Color(0.22,0.16,0.0,0.92) if _tem_cr else Color(0.08,0.08,0.08,0.92)
		var _br_a := Color(0.88,0.62,0.08)     if _tem_cr else Color(0.4,0.4,0.4)
		var _fc_a := Color(1.0,0.92,0.45)       if _tem_cr else Color(0.45,0.40,0.30)
		_balma.add_theme_stylebox_override("normal", _mk_sty_go.call(_bg_a, _br_a) as StyleBoxFlat)
		_balma.add_theme_color_override("font_color", _fc_a)
		_balma.disabled = not _tem_cr
		ov.add_child(_balma)
		var _twa := create_tween(); _twa.tween_interval(_sd); _twa.tween_property(_balma, "modulate:a", 1.0, 0.3)
		if _tem_cr:
			_balma.pressed.connect(func():
				Acessibilidade.processar("gameover_revive_alma",
					"Invocar Alma. Usa %d cristais para reviver a torre." % custo_alma,
					func(): cb_alma.call()))
		_rby += _rev_h + 8.0; _sd += 0.12

	if tem_vela:
		var _estq : int = Salvar.revive_loja_estoque
		var _bvela := Button.new()
		_bvela.text = "USAR VELA DA ALMA  [ estoque: %d ]" % _estq
		_bvela.focus_mode = Control.FOCUS_NONE
		_bvela.custom_minimum_size = Vector2(_btn_w_go, _rev_h); _bvela.size = Vector2(_btn_w_go, _rev_h)
		_bvela.position = Vector2(_rbx, _rby); _bvela.modulate.a = 0.0
		_bvela.add_theme_font_size_override("font_size", 20 if compacto_go else 24)
		_bvela.add_theme_stylebox_override("normal", _mk_sty_go.call(Color(0.0,0.12,0.22,0.92), Color(0.28,0.70,1.0)) as StyleBoxFlat)
		_bvela.add_theme_color_override("font_color", Color(0.65,0.90,1.0))
		ov.add_child(_bvela)
		var _twv := create_tween(); _twv.tween_interval(_sd); _twv.tween_property(_bvela, "modulate:a", 1.0, 0.3)
		_bvela.pressed.connect(func():
			Acessibilidade.processar("gameover_revive_vela",
				"Usar Vela da Alma. Revive a torre sem custo de cristais.",
				func(): cb_vela.call()))
		_rby += _rev_h + 8.0; _sd += 0.12

	# ── Botões de navegação ───────────────────────────────
	var _bx1 : float = (vp_w - _btn_w_go) * 0.5
	var _by1 : float = _rby + _gap_go
	var _by2 : float = _by1 + _nav_main_h + 8.0
	var _bd1 : float = _sd + 0.10
	var _bd2 : float = _sd + 0.22

	var btn := Button.new()
	btn.text = "JOGAR NOVAMENTE"; btn.focus_mode = Control.FOCUS_NONE
	btn.custom_minimum_size = Vector2(_btn_w_go,_nav_main_h); btn.size = Vector2(_btn_w_go,_nav_main_h)
	btn.position = Vector2(_bx1, _by1); btn.z_index = 1; btn.modulate.a = 0.0
	btn.add_theme_font_size_override("font_size", 27 if compacto_go else 33)
	btn.add_theme_stylebox_override("normal", _mk_sty_go.call(Color(0.08,0.22,0.5,0.92), Color(0.28,0.65,1.0)) as StyleBoxFlat)
	btn.add_theme_color_override("font_color", Color.WHITE)
	ov.add_child(btn)
	var _twb1 := create_tween(); _twb1.tween_interval(_bd1); _twb1.tween_property(btn, "modulate:a", 1.0, 0.3)
	btn.pressed.connect(func():
		cb_sair.call()
		Acessibilidade.processar("gameover_jogar_novamente",
			"Jogar novamente. Inicia uma nova partida.",
			func(): Som.parar_musica(); get_tree().reload_current_scene()))

	var btn_stats := Button.new()
	btn_stats.text = "VER ESTATÍSTICAS DA RUN"; btn_stats.focus_mode = Control.FOCUS_NONE
	btn_stats.custom_minimum_size = Vector2(_btn_w_go,_nav_h); btn_stats.size = Vector2(_btn_w_go,_nav_h)
	btn_stats.position = Vector2(_bx1, _by2); btn_stats.z_index = 1; btn_stats.modulate.a = 0.0
	btn_stats.add_theme_font_size_override("font_size", 22 if compacto_go else 27)
	btn_stats.add_theme_stylebox_override("normal", _mk_sty_go.call(Color(0.06,0.18,0.12,0.92), Color(0.2,0.75,0.45)) as StyleBoxFlat)
	btn_stats.add_theme_color_override("font_color", Color(0.55,1.0,0.72))
	ov.add_child(btn_stats)
	btn_stats.text = ""
	var _stats_btn_size : Vector2 = Vector2(124.0, 126.0) if compacto_go else Vector2(158.0, 162.0)
	var _stats_btn_margin : float = 18.0 if compacto_go else 24.0
	btn_stats.custom_minimum_size = _stats_btn_size
	btn_stats.size = _stats_btn_size
	btn_stats.position = Vector2(_stats_btn_margin, vp_h - _stats_btn_size.y - _stats_btn_margin)
	btn_stats.pivot_offset = _stats_btn_size * 0.5
	btn_stats.z_index = 3
	btn_stats.flat = true
	btn_stats.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	for _stats_state in ["normal", "hover", "pressed", "disabled", "focus"]:
		btn_stats.add_theme_stylebox_override(_stats_state, StyleBoxEmpty.new())
	btn_stats.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0, 0.0))
	btn_stats.add_theme_color_override("font_hover_color", Color(1.0, 1.0, 1.0, 0.0))
	btn_stats.add_theme_color_override("font_pressed_color", Color(1.0, 1.0, 1.0, 0.0))

	var _stats_sprite := Control.new()
	_stats_sprite.size = _stats_btn_size
	_stats_sprite.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_stats_sprite.set_meta("frame", 0)
	_stats_sprite.set_meta("hot", false)
	_stats_sprite.set_meta("pressed", false)
	_stats_sprite.draw.connect(func() -> void:
		_draw_stats_button_sprite(_stats_sprite))
	btn_stats.add_child(_stats_sprite)

	var _stats_hover_in := func() -> void:
		_stats_sprite.set_meta("hot", true)
		_stats_sprite.queue_redraw()
	var _stats_hover_out := func() -> void:
		_stats_sprite.set_meta("frame", 0)
		_stats_sprite.set_meta("hot", false)
		_stats_sprite.set_meta("pressed", false)
		_stats_sprite.queue_redraw()
	var _stats_press_in := func() -> void:
		_stats_sprite.set_meta("hot", true)
		_stats_sprite.set_meta("pressed", true)
		_stats_sprite.queue_redraw()
	var _stats_press_out := func() -> void:
		_stats_sprite.set_meta("pressed", false)
		_stats_sprite.queue_redraw()
	btn_stats.mouse_entered.connect(_stats_hover_in)
	btn_stats.mouse_exited.connect(_stats_hover_out)
	btn_stats.button_down.connect(_stats_press_in)
	btn_stats.button_up.connect(_stats_press_out)
	var _twb2 := create_tween(); _twb2.tween_interval(_bd2); _twb2.tween_property(btn_stats, "modulate:a", 1.0, 0.3)
	btn_stats.pressed.connect(func():
		cb_sair.call()
		Acessibilidade.processar("gameover_stats",
			"Ver estatísticas da partida. Mostra detalhes do que aconteceu nessa run.",
			func(): _mostrar_stats_run(score, wave, gold, modo_abismo)))

	var btn_menu := Button.new()
	btn_menu.text = "MENU PRINCIPAL"; btn_menu.focus_mode = Control.FOCUS_NONE
	btn_menu.custom_minimum_size = Vector2(_btn_w_go,_nav_h); btn_menu.size = Vector2(_btn_w_go,_nav_h)
	btn_menu.position = Vector2(_bx1, _by2); btn_menu.z_index = 1; btn_menu.modulate.a = 0.0
	btn_menu.add_theme_font_size_override("font_size", 22 if compacto_go else 27)
	btn_menu.add_theme_stylebox_override("normal", _mk_sty_go.call(Color(0.12,0.12,0.12,0.9), Color(0.4,0.4,0.4)) as StyleBoxFlat)
	btn_menu.add_theme_color_override("font_color", Color(0.7,0.7,0.7))
	ov.add_child(btn_menu)
	var _twb3 := create_tween(); _twb3.tween_interval(_bd2); _twb3.tween_property(btn_menu, "modulate:a", 1.0, 0.3)
	btn_menu.pressed.connect(func():
		cb_sair.call()
		Acessibilidade.processar("gameover_menu",
			"Voltar ao menu principal.",
			func(): Som.parar_musica(); get_tree().change_scene_to_file("res://scenes/Menu.tscn")))



func _mostrar_stats_run(score: int, wave: int, gold: int, modo_abismo: bool) -> void:
	# ── Coleta de dados via get_status_data() ────────────────────────────────
	var sd : Dictionary = {}
	var colhidas : Dictionary = {}
	if jogo and is_instance_valid(jogo) and jogo.has_method("get_status_data"):
		sd = jogo.get_status_data()
		var c = jogo.get("_cartas_colhidas")
		if c is Dictionary: colhidas = c as Dictionary

	var mobs_mortos   : int   = int(sd.get("mobs_mortos", 0))
	var boss_mortos   : int   = int(sd.get("boss_mortos", 0))
	var dano_causado  : float = float(sd.get("dano_causado", 0.0))
	var dano_recebido : float = float(sd.get("dano_recebido", 0.0))
	var torre_hp      : float = float(sd.get("hp", 0.0))
	var torre_max_hp  : float = float(sd.get("max_hp", 0.0))
	var torre_damage  : float = float(sd.get("damage", 0.0))
	var torre_range   : float = float(sd.get("range_r", 0.0))
	var torre_fr      : float = float(sd.get("fire_rate", 0.0))
	var torre_dr      : float = float(sd.get("damage_reduction", 0.0))
	var torre_pierce  : int   = int(sd.get("pierce_count", 0))
	var torre_multi   : int   = int(sd.get("multi_lvl", 0))
	var torre_crit    : float = float(sd.get("crit_chance", 0.0))
	var veneno_dps    : float = float(sd.get("veneno_dps", 0.0))
	var bencao_kills  : int   = int(sd.get("bencao_kills", 0))

	var diff_nomes : Array  = ["FÁCIL", "NORMAL", "DIFÍCIL"]
	var diff_idx   : int    = Salvar.dificuldade
	var diff_txt   : String = ("ABISMO" if modo_abismo else diff_nomes[diff_idx])

	# ── Overlay fundo ────────────────────────────────────────────────────────
	var vp_w_stats : float = get_viewport().get_visible_rect().size.x
	var ov := ColorRect.new()
	ov.color    = Color(0.0, 0.0, 0.0, 0.92)
	ov.z_index  = 30
	ov.position = Vector2.ZERO
	ov.size     = Vector2(vp_w_stats, 720)
	ov.mouse_filter = Control.MOUSE_FILTER_STOP
	_hud.add_child(ov)

	# ── Painel principal ─────────────────────────────────────────────────────
	var painel := Panel.new()
	painel.position = Vector2((vp_w_stats - 1180.0) * 0.5, 4)
	painel.size     = Vector2(1180, 714)
	painel.z_index  = 31
	var psty := StyleBoxFlat.new()
	psty.bg_color     = Color(0.04, 0.05, 0.09, 0.98)
	psty.border_color = Color(0.22, 0.65, 0.40, 0.85)
	for s in ["left","right","top","bottom"]: psty.set("border_width_" + s, 2)
	for c in ["top_left","top_right","bottom_left","bottom_right"]: psty.set("corner_radius_" + c, 10)
	painel.add_theme_stylebox_override("panel", psty)
	_hud.add_child(painel)

	# Título
	var titulo := Label.new()
	titulo.text                 = "ESTATÍSTICAS DA RUN"
	titulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	titulo.position             = Vector2(0, 12)
	titulo.size                 = Vector2(1160, 36)
	titulo.add_theme_font_size_override("font_size", 17)
	titulo.add_theme_color_override("font_color", Color(0.45, 1.0, 0.65))
	titulo.mouse_filter         = Control.MOUSE_FILTER_IGNORE
	painel.add_child(titulo)

	var sep_top := ColorRect.new()
	sep_top.position     = Vector2(30, 54)
	sep_top.size         = Vector2(1100, 1)
	sep_top.color        = Color(0.22, 0.65, 0.40, 0.45)
	sep_top.mouse_filter = Control.MOUSE_FILTER_IGNORE
	painel.add_child(sep_top)

	# ── Helper inline ─────────────────────────────────────────────────────────
	var _lbl := func(parent: Control, txt: String, px: float, py: float, fs: int, cor: Color, w: float = 420.0) -> void:
		var l := Label.new()
		l.text     = txt
		l.position = Vector2(px, py)
		l.size     = Vector2(w, float(fs) + 16.0)
		l.add_theme_font_size_override("font_size", fs)
		l.add_theme_color_override("font_color", cor)
		l.mouse_filter = Control.MOUSE_FILTER_IGNORE
		parent.add_child(l)

	var _sec := func(parent: Control, txt: String, px: float, py: float) -> void:
		var l := Label.new()
		l.text     = txt
		l.position = Vector2(px, py)
		l.size     = Vector2(430.0, 40.0)
		l.add_theme_font_size_override("font_size", 19)
		l.add_theme_color_override("font_color", Color(0.45, 0.45, 0.55))
		l.mouse_filter = Control.MOUSE_FILTER_IGNORE
		parent.add_child(l)

		var sep := ColorRect.new()
		sep.position     = Vector2(px, py + 38.0)
		sep.size         = Vector2(430.0, 1.0)
		sep.color        = Color(0.22, 0.22, 0.30, 0.5)
		sep.mouse_filter = Control.MOUSE_FILTER_IGNORE
		parent.add_child(sep)

	# ═══════════════════════════════════════════════════════════════════════
	# COLUNA ESQUERDA  – ScrollContainer (x=30..468)
	# ═══════════════════════════════════════════════════════════════════════
	var left_scroll := ScrollContainer.new()
	left_scroll.position               = Vector2(30, 62)
	left_scroll.size                   = Vector2(430, 610)
	left_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	left_scroll.vertical_scroll_mode   = ScrollContainer.SCROLL_MODE_AUTO
	left_scroll.mouse_filter           = Control.MOUSE_FILTER_STOP
	painel.add_child(left_scroll)

	var left_cont := Control.new()
	left_cont.mouse_filter = Control.MOUSE_FILTER_IGNORE
	left_scroll.add_child(left_cont)

	var lx : float = 0.0
	var ly : float = 0.0
	var sp : float = 38.0

	_sec.call(left_cont, "RESULTADO", lx, ly)
	ly += 42.0
	_lbl.call(left_cont, "Wave alcançada",   lx,       ly, 15, Color(0.55, 0.55, 0.65))
	_lbl.call(left_cont, "%d" % wave,        lx + 240, ly, 20, Color(0.88, 0.88, 1.00))
	ly += sp
	_lbl.call(left_cont, "Score final",      lx,       ly, 15, Color(0.55, 0.55, 0.65))
	_lbl.call(left_cont, _fmt_num(score),    lx + 240, ly, 20, Color(0.88, 0.88, 1.00))
	ly += sp
	_lbl.call(left_cont, "Dificuldade",      lx,       ly, 15, Color(0.55, 0.55, 0.65))
	_lbl.call(left_cont, diff_txt,           lx + 240, ly, 20, Color(0.88, 0.88, 1.00))
	ly += sp
	_lbl.call(left_cont, "Ouro depositado",  lx,       ly, 15, Color(0.55, 0.55, 0.65))
	_lbl.call(left_cont, _fmt_num(gold),     lx + 240, ly, 20, Color(1.00, 0.85, 0.15))
	ly += sp + 16.0

	_sec.call(left_cont, "COMBATE", lx, ly)
	ly += 42.0
	_lbl.call(left_cont, "Mobs eliminados",  lx,       ly, 15, Color(0.55, 0.55, 0.65))
	_lbl.call(left_cont, "%d" % mobs_mortos, lx + 240, ly, 20, Color(1.00, 0.60, 0.35))
	ly += sp
	_lbl.call(left_cont, "Bosses abatidos",  lx,       ly, 15, Color(0.55, 0.55, 0.65))
	_lbl.call(left_cont, "%d" % boss_mortos, lx + 240, ly, 20, Color(1.00, 0.35, 0.35))
	ly += sp
	_lbl.call(left_cont, "Dano causado",     lx,       ly, 15, Color(0.55, 0.55, 0.65))
	_lbl.call(left_cont, "%.0f" % dano_causado,  lx + 240, ly, 20, Color(1.00, 0.55, 0.20))
	ly += sp
	_lbl.call(left_cont, "Dano recebido",    lx,       ly, 15, Color(0.55, 0.55, 0.65))
	_lbl.call(left_cont, "%.0f" % dano_recebido, lx + 240, ly, 20, Color(1.00, 0.30, 0.30))
	ly += sp + 16.0

	_sec.call(left_cont, "TORRE FINAL", lx, ly)
	ly += 42.0
	_lbl.call(left_cont, "HP",              lx,       ly, 15, Color(0.55, 0.55, 0.65))
	_lbl.call(left_cont, "%.0f / %.0f" % [torre_hp, torre_max_hp], lx + 240, ly, 20, Color(0.30, 1.00, 0.50))
	ly += sp
	_lbl.call(left_cont, "Dano / tiro",     lx,       ly, 15, Color(0.55, 0.55, 0.65))
	_lbl.call(left_cont, "%.1f" % torre_damage,   lx + 240, ly, 20, Color(1.00, 0.55, 0.20))
	ly += sp
	_lbl.call(left_cont, "DPS estimado",    lx,       ly, 15, Color(0.55, 0.55, 0.65))
	_lbl.call(left_cont, "%.1f" % (torre_damage * torre_fr), lx + 240, ly, 20, Color(1.00, 0.72, 0.15))
	ly += sp
	_lbl.call(left_cont, "Alcance",         lx,       ly, 15, Color(0.55, 0.55, 0.65))
	_lbl.call(left_cont, "%.0f px" % torre_range,    lx + 240, ly, 20, Color(0.35, 0.72, 1.00))
	ly += sp
	_lbl.call(left_cont, "Cadência",        lx,       ly, 15, Color(0.55, 0.55, 0.65))
	_lbl.call(left_cont, "%.2f /s" % torre_fr,       lx + 240, ly, 20, Color(0.78, 0.45, 1.00))
	ly += sp
	_lbl.call(left_cont, "Red. de dano",    lx,       ly, 15, Color(0.55, 0.55, 0.65))
	_lbl.call(left_cont, "%.0f%%" % (torre_dr * 100.0), lx + 240, ly, 20, Color(0.45, 0.90, 0.65))
	ly += sp
	if torre_pierce > 0:
		_lbl.call(left_cont, "Perfurante",  lx,       ly, 15, Color(0.55, 0.55, 0.65))
		_lbl.call(left_cont, "%d alvo(s)" % torre_pierce, lx + 240, ly, 20, Color(1.00, 0.88, 0.12))
		ly += sp
	if torre_multi > 0:
		_lbl.call(left_cont, "Multi-tiro",  lx,       ly, 15, Color(0.55, 0.55, 0.65))
		_lbl.call(left_cont, "Nível %d" % torre_multi, lx + 240, ly, 20, Color(0.88, 0.50, 1.00))
		ly += sp
	if torre_crit > 0.0:
		_lbl.call(left_cont, "Chance crítica", lx,    ly, 15, Color(0.55, 0.55, 0.65))
		_lbl.call(left_cont, "%.0f%%" % (torre_crit * 100.0), lx + 240, ly, 20, Color(1.00, 0.72, 0.15))
		ly += sp
	if veneno_dps > 0.0:
		_lbl.call(left_cont, "Veneno DPS",  lx,       ly, 15, Color(0.55, 0.55, 0.65))
		_lbl.call(left_cont, "%.1f" % veneno_dps,     lx + 240, ly, 20, Color(0.48, 1.00, 0.35))
		ly += sp
	if bencao_kills > 0:
		_lbl.call(left_cont, "Kills bênção", lx,      ly, 15, Color(0.55, 0.55, 0.65))
		_lbl.call(left_cont, "%d" % bencao_kills,     lx + 240, ly, 20, Color(1.00, 0.95, 0.55))
		ly += sp

	# ── Habilidades ativas – cargas restantes ────────────────────────────────
	var attr_bonus_raw_go = sd.get("atributos_bonus", {})
	var attr_niveis_raw_go = sd.get("atributos_niveis", {})
	var attr_bonus_go : Dictionary = attr_bonus_raw_go if attr_bonus_raw_go is Dictionary else {}
	var attr_niveis_go : Dictionary = attr_niveis_raw_go if attr_niveis_raw_go is Dictionary else {}
	var attr_rows_go : Array = _st_atributos_rows(attr_bonus_go, attr_niveis_go)
	if not attr_rows_go.is_empty():
		ly += 10.0
		_sec.call(left_cont, "ATRIBUTOS DA CONTA", lx, ly)
		ly += 42.0
		for row in attr_rows_go:
			_lbl.call(left_cont, str(row[0]), lx, ly, 15, Color(0.55, 0.55, 0.65))
			_lbl.call(left_cont, str(row[1]), lx + 200, ly, 17, row[2] as Color)
			ly += sp

	var cargas_eletrico   : int = int(Salvar.habil_cargas.get("eletrico",   0))
	var cargas_gelo       : int = int(Salvar.habil_cargas.get("gelo",       0))
	var cargas_devastador : int = int(Salvar.habil_cargas.get("devastador", 0))

	ly += 10.0
	_sec.call(left_cont, "HABILIDADES ATIVAS", lx, ly)
	ly += 42.0
	_lbl.call(left_cont, "Pulso Elétrico",  lx,       ly, 15, Color(0.55, 0.55, 0.65))
	_lbl.call(left_cont, "%d carga(s)" % cargas_eletrico,   lx + 240, ly, 18, Color(0.25, 0.95, 1.00))
	ly += sp
	_lbl.call(left_cont, "Bomba de Gelo",   lx,       ly, 15, Color(0.55, 0.55, 0.65))
	_lbl.call(left_cont, "%d carga(s)" % cargas_gelo,       lx + 240, ly, 18, Color(0.55, 0.88, 1.00))
	ly += sp
	_lbl.call(left_cont, "Pulso Final",     lx,       ly, 15, Color(0.55, 0.55, 0.65))
	_lbl.call(left_cont, "%d carga(s)" % cargas_devastador, lx + 240, ly, 18, Color(1.00, 0.55, 0.15))
	ly += sp

	left_cont.custom_minimum_size = Vector2(420, ly + 20.0)

	# ═══════════════════════════════════════════════════════════════════════
	# COLUNA DIREITA  – Cartas com ScrollContainer  (x=490..1130)
	# ═══════════════════════════════════════════════════════════════════════
	var sep_vert := ColorRect.new()
	sep_vert.position     = Vector2(468, 62)
	sep_vert.size         = Vector2(1, 610)
	sep_vert.color        = Color(0.22, 0.22, 0.30, 0.55)
	sep_vert.mouse_filter = Control.MOUSE_FILTER_IGNORE
	painel.add_child(sep_vert)

	var cx_title := Label.new()
	cx_title.text                 = "CARTAS ESCOLHIDAS"
	cx_title.position             = Vector2(480, 62)
	cx_title.size                 = Vector2(670, 22)
	cx_title.add_theme_font_size_override("font_size", 13)
	cx_title.add_theme_color_override("font_color", Color(0.55, 0.60, 0.75))
	cx_title.mouse_filter         = Control.MOUSE_FILTER_IGNORE
	painel.add_child(cx_title)

	var sep_cx := ColorRect.new()
	sep_cx.position     = Vector2(480, 86)
	sep_cx.size         = Vector2(670, 1)
	sep_cx.color        = Color(0.22, 0.22, 0.30, 0.5)
	sep_cx.mouse_filter = Control.MOUSE_FILTER_IGNORE
	painel.add_child(sep_cx)

	var scroll := ScrollContainer.new()
	scroll.position               = Vector2(480, 92)
	scroll.size                   = Vector2(672, 570)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.vertical_scroll_mode   = ScrollContainer.SCROLL_MODE_AUTO
	scroll.mouse_filter           = Control.MOUSE_FILTER_STOP
	scroll.scroll_deadzone        = 0
	painel.add_child(scroll)

	var sc_inner := Control.new()
	sc_inner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	scroll.add_child(sc_inner)

	var cy : float = 6.0

	if colhidas.is_empty():
		var vazio := Label.new()
		vazio.text     = "Nenhuma carta coletada."
		vazio.position = Vector2(10, cy)
		vazio.add_theme_font_size_override("font_size", 9)
		vazio.add_theme_color_override("font_color", Color(0.45, 0.45, 0.50))
		vazio.mouse_filter = Control.MOUSE_FILTER_IGNORE
		sc_inner.add_child(vazio)
		cy += 30.0
	else:
		var _nomes : Dictionary = {}
		var _cores_carta : Dictionary = {}
		if jogo and is_instance_valid(jogo):
			var cartas_arr = jogo.get("CARTAS")
			if cartas_arr is Array:
				for ct in (cartas_arr as Array):
					if ct is Dictionary:
						_nomes[(ct as Dictionary).get("id", "")] = (ct as Dictionary).get("nome", "")
						_cores_carta[(ct as Dictionary).get("id", "")] = (ct as Dictionary).get("cor", Color.WHITE)

		var sorted_ids : Array = colhidas.keys()
		sorted_ids.sort_custom(func(a, b): return colhidas.get(a, 0) > colhidas.get(b, 0))

		for cid in sorted_ids:
			var cnt  : int    = int(colhidas.get(cid, 0))
			var nome : String = _nomes.get(cid, cid) as String
			var ccor : Color  = _cores_carta.get(cid, Color(0.65, 0.65, 0.72)) as Color

			var card_bg := Panel.new()
			card_bg.position = Vector2(4, cy)
			card_bg.size     = Vector2(648, 54)
			var cbsty := StyleBoxFlat.new()
			cbsty.bg_color     = Color(ccor.r * 0.12, ccor.g * 0.12, ccor.b * 0.12, 0.82)
			cbsty.border_color = Color(ccor.r * 0.65, ccor.g * 0.65, ccor.b * 0.65, 0.60)
			for s in ["left","right","top","bottom"]: cbsty.set("border_width_" + s, 1)
			for c in ["top_left","top_right","bottom_left","bottom_right"]: cbsty.set("corner_radius_" + c, 6)
			card_bg.add_theme_stylebox_override("panel", cbsty)
			card_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
			sc_inner.add_child(card_bg)

			var cbar := ColorRect.new()
			cbar.color = Color(ccor.r, ccor.g, ccor.b, 0.55)
			cbar.position = Vector2(0, 6); cbar.size = Vector2(3, 42)
			cbar.mouse_filter = Control.MOUSE_FILTER_IGNORE
			card_bg.add_child(cbar)

			var cnt_lbl := Label.new()
			cnt_lbl.text                 = "×%d" % cnt
			cnt_lbl.position             = Vector2(8, 18)
			cnt_lbl.size                 = Vector2(44, 20)
			cnt_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			cnt_lbl.add_theme_font_size_override("font_size", 12)
			cnt_lbl.add_theme_color_override("font_color", Color(minf(ccor.r + 0.25, 1.0), minf(ccor.g + 0.18, 1.0), minf(ccor.b + 0.10, 1.0), 0.70))
			cnt_lbl.mouse_filter         = Control.MOUSE_FILTER_IGNORE
			card_bg.add_child(cnt_lbl)

			var nome_lbl := Label.new()
			nome_lbl.text         = nome
			nome_lbl.position     = Vector2(58, 15)
			nome_lbl.size         = Vector2(582, 26)
			nome_lbl.add_theme_font_size_override("font_size", 18)
			nome_lbl.add_theme_color_override("font_color", Color(minf(ccor.r + 0.22, 1.0), minf(ccor.g + 0.18, 1.0), minf(ccor.b + 0.05, 1.0), 0.95))
			nome_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
			card_bg.add_child(nome_lbl)

			cy += 58.0

	sc_inner.custom_minimum_size = Vector2(652, cy + 8.0)

	# ── Botão fechar ─────────────────────────────────────────────────────────
	var btn_fechar := Button.new()
	btn_fechar.text                = "FECHAR"
	btn_fechar.position            = Vector2(390, 668)
	btn_fechar.size                = Vector2(400, 46)
	btn_fechar.add_theme_font_size_override("font_size", 12)
	var bfsty := StyleBoxFlat.new()
	bfsty.bg_color     = Color(0.08, 0.08, 0.08, 0.92)
	bfsty.border_color = Color(0.30, 0.30, 0.30)
	for s in ["left","right","top","bottom"]: bfsty.set("border_width_" + s, 2)
	for c in ["top_left","top_right","bottom_left","bottom_right"]: bfsty.set("corner_radius_" + c, 8)
	btn_fechar.add_theme_stylebox_override("normal", bfsty)
	btn_fechar.add_theme_color_override("font_color", Color(0.65, 0.65, 0.65))
	btn_fechar.pressed.connect(func():
		painel.queue_free()
		ov.queue_free())
	painel.add_child(btn_fechar)


func ganhar_token() -> void:
	# Remove ícone anterior se existir
	if _token_icon and is_instance_valid(_token_icon):
		_token_icon.queue_free()

	# Popup dourado central
	var popup := Label.new()
	popup.text                 = "TOKEN DA ESPERANÇA"
	popup.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	popup.position             = Vector2(390.0, 300.0)
	popup.size                 = Vector2(500.0, 78)
	popup.z_index              = 90
	popup.add_theme_font_size_override("font_size", 45)
	popup.add_theme_color_override("font_color", Color(1.0, 0.92, 0.15))
	_hud.add_child(popup)
	var tw_pop := create_tween()
	tw_pop.tween_property(popup, "position:y", 240.0, 1.0)
	tw_pop.parallel().tween_property(popup, "modulate:a", 0.0, 1.0).set_delay(0.6)
	tw_pop.tween_callback(popup.queue_free)

	# Ícone do token: moeda dourada no canto inferior esquerdo
	var icone := Panel.new()
	icone.size     = Vector2(52.0, 78)
	icone.z_index  = 85
	var sty := StyleBoxFlat.new()
	sty.bg_color = Color(0.14, 0.10, 0.02, 0.94)
	sty.border_color = Color(1.0, 0.85, 0.18, 1.0)
	for s in ["left","right","top","bottom"]:
		sty.set("border_width_" + s, 3)
	for c in ["top_left","top_right","bottom_left","bottom_right"]:
		sty.set("corner_radius_" + c, 26)
	icone.add_theme_stylebox_override("panel", sty)

	var estrela := Label.new()
	estrela.text                 = "*"
	estrela.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	estrela.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
	estrela.set_anchors_preset(Control.PRESET_FULL_RECT)
	estrela.add_theme_font_size_override("font_size", 39)
	estrela.add_theme_color_override("font_color", Color(1.0, 0.90, 0.15))
	icone.add_child(estrela)

	var lbl_t := Label.new()
	lbl_t.text                 = "TOKEN"
	lbl_t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl_t.position             = Vector2(-6.0, 52.0)
	lbl_t.size                 = Vector2(64.0, 27)
	lbl_t.add_theme_font_size_override("font_size", 15)
	lbl_t.add_theme_color_override("font_color", Color(1.0, 0.85, 0.20, 0.80))
	icone.add_child(lbl_t)

	# Entra deslizando pela esquerda
	icone.position = Vector2(-70.0, 655.0)
	_hud.add_child(icone)
	_token_icon = icone

	var tw_in := create_tween()
	tw_in.tween_property(icone, "position:x", 18.0, 0.5)\
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

	# Pulso de borda dourado ao pousar
	tw_in.tween_callback(func() -> void:
		var tw_pulse := create_tween().set_loops(0)
		tw_pulse.tween_property(icone, "modulate",
			Color(1.2, 1.2, 0.8, 1.0), 0.7)
		tw_pulse.tween_property(icone, "modulate",
			Color(1.0, 1.0, 1.0, 1.0), 0.7)
	)


func usar_token() -> void:
	if not (_token_icon and is_instance_valid(_token_icon)):
		return

	var icone := _token_icon
	_token_icon = null
	icone.z_index = 95

	# Voa para o centro da tela
	var tw := create_tween()
	tw.tween_property(icone, "position",
		Vector2(614.0, 334.0), 0.4)\
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	tw.tween_callback(func() -> void: _explodir_token(icone))


func _explodir_token(icone: Control) -> void:
	icone.queue_free()

	# Raios irradiando do centro
	for i in range(12):
		var ray := ColorRect.new()
		ray.size     = Vector2(5.0, 105)
		ray.color    = Color(1.0, 0.88, 0.12, 0.80)
		ray.z_index  = 95
		ray.position = Vector2(637.0, 360.0)
		var ang : float = float(i) * TAU / 12.0
		_hud.add_child(ray)
		var tw_r := create_tween()
		tw_r.tween_property(ray, "position",
			Vector2(640.0 + cos(ang) * 160.0 - 2.0,
					360.0 + sin(ang) * 160.0 - 35.0), 0.55)
		tw_r.parallel().tween_property(ray, "modulate:a", 0.0, 0.55)
		tw_r.tween_callback(ray.queue_free)

	# Círculo de expansão
	var ring := ColorRect.new()
	ring.color    = Color(1.0, 0.92, 0.15, 0.60)
	ring.size     = Vector2(20.0, 30)
	ring.position = Vector2(630.0, 350.0)
	ring.z_index  = 94
	_hud.add_child(ring)
	var tw_ring := create_tween()
	tw_ring.tween_property(ring, "size",   Vector2(260.0, 260.0), 0.45)
	tw_ring.parallel().tween_property(ring, "position", Vector2(510.0, 230.0), 0.45)
	tw_ring.parallel().tween_property(ring, "modulate:a", 0.0, 0.45)
	tw_ring.tween_callback(ring.queue_free)

	# Texto central
	var lbl := Label.new()
	lbl.text                 = "PROTEÇÃO\nATIVADA!"
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.position             = Vector2(390.0, 296.0)
	lbl.size                 = Vector2(500.0, 128.0)
	lbl.z_index              = 96
	lbl.add_theme_font_size_override("font_size", 72)
	lbl.add_theme_color_override("font_color", Color(1.0, 0.92, 0.15))
	_hud.add_child(lbl)

	lbl.modulate = Color(1.0, 1.0, 1.0, 0.0)
	var tw_lbl := create_tween()
	tw_lbl.tween_property(lbl, "modulate:a", 1.0, 0.20)
	tw_lbl.tween_property(lbl, "modulate:a", 0.0, 1.20).set_delay(0.9)
	tw_lbl.tween_callback(lbl.queue_free)


func mostrar_sombra_boss(pos_mundo: Vector2) -> void:
	# Converte posição do mundo para coordenadas de tela
	var vp     := get_viewport()
	var cam    := vp.get_camera_2d() if vp else null
	var zoom   : float = cam.zoom.x if cam else 1.0
	var screen_pos : Vector2 = (pos_mundo - Vector2(640.0, 360.0)) * zoom + Vector2(640.0, 360.0)

	# Silhueta: painel escuro-avermelhado com "???"
	var sombra := Panel.new()
	sombra.size     = Vector2(64.0, 120)
	sombra.z_index  = 70
	sombra.position = screen_pos - Vector2(32.0, 40.0)
	sombra.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var sty := StyleBoxFlat.new()
	sty.bg_color     = Color(0.55, 0.05, 0.05, 0.0)   # começa transparente
	sty.border_color = Color(1.0, 0.18, 0.18, 0.0)
	for s in ["left","right","top","bottom"]:
		sty.set("border_width_" + s, 2)
	for c in ["top_left","top_right","bottom_left","bottom_right"]:
		sty.set("corner_radius_" + c, 8)
	sombra.add_theme_stylebox_override("panel", sty)
	_hud.add_child(sombra)

	# Ícone "???"
	var lbl := Label.new()
	lbl.text                 = "???"
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
	lbl.set_anchors_preset(Control.PRESET_FULL_RECT)
	lbl.mouse_filter         = Control.MOUSE_FILTER_IGNORE
	lbl.add_theme_font_size_override("font_size", 27)
	lbl.add_theme_color_override("font_color", Color(1.0, 0.35, 0.35, 0.0))
	sombra.add_child(lbl)

	# Animação: fade-in rápido → pisca → fade-out
	var tw := create_tween()
	# Fade in (0 → 1 em 0.3s)
	tw.tween_method(func(a: float) -> void:
		sty.bg_color     = Color(0.55, 0.05, 0.05, a * 0.75)
		sty.border_color = Color(1.0, 0.18, 0.18, a)
		sombra.add_theme_stylebox_override("panel", sty)
		lbl.add_theme_color_override("font_color", Color(1.0, 0.35, 0.35, a))
	, 0.0, 1.0, 0.35)

	# Pisca 2× durante 1.4s
	tw.tween_method(func(a: float) -> void:
		var flicker : float = 0.55 + 0.45 * sin(a * TAU * 2.5)
		sty.bg_color     = Color(0.55, 0.05, 0.05, flicker * 0.75)
		sty.border_color = Color(1.0, 0.18, 0.18, flicker)
		sombra.add_theme_stylebox_override("panel", sty)
		lbl.add_theme_color_override("font_color", Color(1.0, 0.35, 0.35, flicker))
	, 0.0, 1.0, 1.4)

	# Fade out (1 → 0 em 0.5s)
	tw.tween_method(func(a: float) -> void:
		sty.bg_color     = Color(0.55, 0.05, 0.05, (1.0 - a) * 0.75)
		sty.border_color = Color(1.0, 0.18, 0.18, 1.0 - a)
		sombra.add_theme_stylebox_override("panel", sty)
		lbl.add_theme_color_override("font_color", Color(1.0, 0.35, 0.35, 1.0 - a))
	, 0.0, 1.0, 0.5)

	tw.tween_callback(sombra.queue_free)


func fechar_overlay_boss() -> void:
	if _boss_entrada_overlay and is_instance_valid(_boss_entrada_overlay):
		_boss_entrada_overlay.queue_free()
	_boss_entrada_overlay = null


func mostrar_entrada_boss(nome: String, cor: Color) -> void:
	# Descarta overlay anterior se ainda estiver na tela
	fechar_overlay_boss()
	var vp_w_boss_in : float = get_viewport().get_visible_rect().size.x
	var overlay := Control.new()
	overlay.position     = Vector2.ZERO
	overlay.size         = Vector2(vp_w_boss_in, 720)
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.z_index      = 80
	add_child(overlay)
	_boss_entrada_overlay = overlay

	# Fundo escuro
	var bg := ColorRect.new()
	bg.color        = Color(0.0, 0.0, 0.0, 0.62)
	bg.position     = Vector2.ZERO
	bg.size         = Vector2(vp_w_boss_in, 720)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.add_child(bg)

	# Linha superior decorativa
	var top_line := Label.new()
	top_line.text                 = "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
	top_line.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	top_line.position             = Vector2(0, 212)
	top_line.size                 = Vector2(vp_w_boss_in, 32)
	top_line.mouse_filter         = Control.MOUSE_FILTER_IGNORE
	top_line.add_theme_font_size_override("font_size", 24)
	top_line.add_theme_color_override("font_color", Color(cor.r, cor.g, cor.b, 0.50))
	overlay.add_child(top_line)

	# Subtítulo
	var sub := Label.new()
	sub.text                 = "— CHEFE APARECEU —"
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.position             = Vector2(0, 244)
	sub.size                 = Vector2(vp_w_boss_in, 40)
	sub.mouse_filter         = Control.MOUSE_FILTER_IGNORE
	sub.add_theme_font_size_override("font_size", 30)
	sub.add_theme_color_override("font_color", Color(0.78, 0.78, 0.80, 0.88))
	overlay.add_child(sub)

	# Nome do chefe/boss em destaque
	var lbl := Label.new()
	lbl.text                 = nome
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.position             = Vector2(0, 284)
	lbl.size                 = Vector2(vp_w_boss_in, 92)
	lbl.mouse_filter         = Control.MOUSE_FILTER_IGNORE
	lbl.add_theme_font_size_override("font_size", 108)
	lbl.add_theme_color_override("font_color", cor)
	overlay.add_child(lbl)

	# Linha inferior decorativa
	var bot_line := Label.new()
	bot_line.text                 = "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
	bot_line.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	bot_line.position             = Vector2(0, 378)
	bot_line.size                 = Vector2(vp_w_boss_in, 32)
	bot_line.mouse_filter         = Control.MOUSE_FILTER_IGNORE
	bot_line.add_theme_font_size_override("font_size", 24)
	bot_line.add_theme_color_override("font_color", Color(cor.r, cor.g, cor.b, 0.50))
	overlay.add_child(bot_line)

	# Fade-in
	overlay.modulate = Color(1.0, 1.0, 1.0, 0.0)
	var tw := create_tween()
	tw.tween_property(overlay, "modulate:a", 1.0, 0.45)

	# Fade-out e remoção após 2.5 segundos reais
	var overlay_ref: WeakRef = weakref(overlay)
	get_tree().create_timer(2.5, true, false, true).timeout.connect(func() -> void:
		var overlay_node: Object = overlay_ref.get_ref()
		if overlay_node and is_instance_valid(overlay_node):
			var tw2 := create_tween()
			tw2.tween_property(overlay_node, "modulate:a", 0.0, 0.55)
			tw2.tween_callback(func() -> void:
				var node: Object = overlay_ref.get_ref()
				if node and is_instance_valid(node):
					node.queue_free()
			)
		if _boss_entrada_overlay == overlay_node:
			_boss_entrada_overlay = null
	)


# ── PAINEL DE ESTATÍSTICAS ────────────────────────────────────────────────────

func mostrar_resumo_mapa(dados: Dictionary, ao_final: Callable = Callable()) -> void:
	if _mapa_resumo_overlay and is_instance_valid(_mapa_resumo_overlay):
		_mapa_resumo_overlay.queue_free()
	var root : Node = _hud if _hud and is_instance_valid(_hud) else self
	var vp_w : float = get_viewport().get_visible_rect().size.x
	var vp_h : float = get_viewport().get_visible_rect().size.y
	var overlay := Control.new()
	overlay.position = Vector2.ZERO
	overlay.size = Vector2(vp_w, vp_h)
	overlay.z_index = 118
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	root.add_child(overlay)
	_mapa_resumo_overlay = overlay

	var bg := ColorRect.new()
	bg.color = Color(0.004, 0.006, 0.014, 0.94)
	bg.position = Vector2.ZERO
	bg.size = Vector2(vp_w, vp_h)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.add_child(bg)

	for i in range(9):
		var scan := ColorRect.new()
		scan.color = Color(0.0, 0.72, 1.0, 0.022)
		scan.position = Vector2(0.0, 72.0 + float(i) * 68.0)
		scan.size = Vector2(vp_w, 1.0)
		scan.mouse_filter = Control.MOUSE_FILTER_IGNORE
		overlay.add_child(scan)
	for i in range(7):
		var vline := ColorRect.new()
		vline.color = Color(1.0, 0.18, 0.04, 0.018)
		vline.position = Vector2(82.0 + float(i) * 184.0, 0.0)
		vline.size = Vector2(1.0, vp_h)
		vline.mouse_filter = Control.MOUSE_FILTER_IGNORE
		overlay.add_child(vline)

	var panel := Panel.new()
	panel.size = Vector2(minf(860.0, vp_w - 92.0), 510.0)
	panel.position = Vector2((vp_w - panel.size.x) * 0.5, maxf(86.0, (vp_h - panel.size.y) * 0.5))
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var sty := StyleBoxFlat.new()
	sty.bg_color = Color(0.010, 0.016, 0.026, 0.96)
	sty.border_color = Color(0.0, 0.78, 1.0, 0.82)
	sty.set_border_width_all(2)
	for c in ["top_left", "top_right", "bottom_left", "bottom_right"]:
		sty.set("corner_radius_" + c, 6)
	panel.add_theme_stylebox_override("panel", sty)
	overlay.add_child(panel)

	var alert := ColorRect.new()
	alert.color = Color(1.0, 0.15, 0.04, 0.12)
	alert.position = Vector2(0, 0)
	alert.size = Vector2(panel.size.x, 5)
	alert.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(alert)

	var header_line := ColorRect.new()
	header_line.color = Color(0.0, 0.78, 1.0, 0.40)
	header_line.position = Vector2(42, 108)
	header_line.size = Vector2(panel.size.x - 84, 1)
	header_line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(header_line)

	var title := Label.new()
	title.text = "SETOR CONCLUIDO"
	title.position = Vector2(0, 25)
	title.size = Vector2(panel.size.x, 56)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 42)
	title.add_theme_color_override("font_color", Color(0.70, 0.94, 1.0))
	panel.add_child(title)

	var sub := Label.new()
	sub.text = "DANTE RECUOU  //  %s  >  %s" % [str(dados.get("mapa", "Setor")), str(dados.get("proximo_mapa", "Proximo Setor"))]
	sub.position = Vector2(34, 78)
	sub.size = Vector2(panel.size.x - 68, 30)
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.add_theme_font_size_override("font_size", 18)
	sub.add_theme_color_override("font_color", Color(1.0, 0.34, 0.18, 0.95))
	panel.add_child(sub)

	var linhas : Array = [
		["Gold coletado", "+%s" % _fmt_num(int(dados.get("gold", 0))), Color(1.0, 0.80, 0.12)],
		["Score do setor", "+%s" % _fmt_num(int(dados.get("score", 0))), Color(0.55, 0.88, 1.0)],
		["Score total", _fmt_num(int(dados.get("score_total", 0))), Color(0.78, 0.82, 0.90)],
		["Cristais", "+%s" % _fmt_num(int(dados.get("cristais", 0))), Color(0.65, 0.95, 1.0)],
	]
	var baus_raw = dados.get("baus", {})
	var baus_txt := "Nenhum"
	if baus_raw is Dictionary and not (baus_raw as Dictionary).is_empty():
		var partes : Array = []
		for k in (baus_raw as Dictionary).keys():
			partes.append("%s x%d" % [str(k).capitalize(), int((baus_raw as Dictionary).get(k, 0))])
		baus_txt = ", ".join(partes)
	linhas.append(["Baus", baus_txt, Color(1.0, 0.52, 0.10)])

	var y := 138.0
	for linha in linhas:
		var row : Array = linha as Array
		var cell := Panel.new()
		cell.position = Vector2(54, y - 6.0)
		cell.size = Vector2(panel.size.x - 108.0, 38.0)
		cell.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var cell_style := StyleBoxFlat.new()
		cell_style.bg_color = Color(0.0, 0.72, 1.0, 0.035)
		cell_style.border_color = Color(0.0, 0.72, 1.0, 0.18)
		cell_style.set_border_width_all(1)
		for c2 in ["top_left", "top_right", "bottom_left", "bottom_right"]:
			cell_style.set("corner_radius_" + c2, 4)
		cell.add_theme_stylebox_override("panel", cell_style)
		panel.add_child(cell)

		var nome := Label.new()
		nome.text = str(row[0])
		nome.position = Vector2(78, y)
		nome.size = Vector2(330, 28)
		nome.add_theme_font_size_override("font_size", 19)
		nome.add_theme_color_override("font_color", Color(0.66, 0.78, 0.86))
		panel.add_child(nome)
		var valor := Label.new()
		valor.text = str(row[1])
		valor.position = Vector2(panel.size.x - 390, y)
		valor.size = Vector2(310, 28)
		valor.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		valor.add_theme_font_size_override("font_size", 22)
		valor.add_theme_color_override("font_color", row[2] as Color)
		panel.add_child(valor)
		y += 48.0

	var next_lbl := Label.new()
	next_lbl.text = "SINCRONIZANDO SALTO PARA O PROXIMO SETOR"
	next_lbl.position = Vector2(0, 398)
	next_lbl.size = Vector2(panel.size.x, 34)
	next_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	next_lbl.add_theme_font_size_override("font_size", 18)
	next_lbl.add_theme_color_override("font_color", Color(0.80, 0.94, 1.0, 0.92))
	panel.add_child(next_lbl)

	var progress_bg := ColorRect.new()
	progress_bg.color = Color(0.0, 0.08, 0.12, 0.90)
	progress_bg.position = Vector2(92, 444)
	progress_bg.size = Vector2(panel.size.x - 184, 7)
	progress_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(progress_bg)

	var progress := ColorRect.new()
	progress.color = Color(0.0, 0.78, 1.0, 0.88)
	progress.position = progress_bg.position
	progress.size = Vector2(0, 7)
	progress.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(progress)

	var footer := Label.new()
	footer.text = "RECOMPENSAS REGISTRADAS  //  CARTAS DISPONIVEIS EM BREVE"
	footer.position = Vector2(0, 462)
	footer.size = Vector2(panel.size.x, 24)
	footer.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	footer.add_theme_font_size_override("font_size", 13)
	footer.add_theme_color_override("font_color", Color(1.0, 0.32, 0.16, 0.74))
	panel.add_child(footer)

	overlay.modulate = Color(1.0, 1.0, 1.0, 0.0)
	var tw_in := create_tween()
	tw_in.tween_property(overlay, "modulate:a", 1.0, 0.45)
	var tw_prog := create_tween()
	tw_prog.tween_property(progress, "size:x", progress_bg.size.x, 7.2)
	get_tree().create_timer(7.35, true, false, true).timeout.connect(func() -> void:
		var overlay_ref := _mapa_resumo_overlay
		if overlay_ref and is_instance_valid(overlay_ref):
			var tw_out := create_tween()
			tw_out.tween_property(overlay_ref, "modulate:a", 0.0, 0.55)
			tw_out.tween_callback(func() -> void:
				if overlay_ref and is_instance_valid(overlay_ref):
					overlay_ref.queue_free()
				if _mapa_resumo_overlay == overlay_ref:
					_mapa_resumo_overlay = null
				if ao_final.is_valid():
					ao_final.call()
			)
		else:
			if ao_final.is_valid():
				ao_final.call()
	)


func _mostrar_status_panel() -> void:
	if not jogo or not is_instance_valid(jogo):
		return

	# Obtém dados de main.gd via call() — sem dynamic .get() em nodes
	var raw = jogo.call("get_status_data")
	if not (raw is Dictionary):
		return
	var d : Dictionary = raw

	# Esconde o pause overlay para não bloquear input do painel
	if _pause_overlay and is_instance_valid(_pause_overlay):
		_pause_overlay.hide()

	# ── Estrutura do painel ───────────────────────────────────────────────────
	var vp_w_sp : float = get_viewport().get_visible_rect().size.x
	# Fundo que bloqueia TODOS os cliques (STOP, não IGNORE)
	var bg_dim := ColorRect.new()
	bg_dim.color        = Color(0.0, 0.0, 0.0, 0.70)
	bg_dim.z_index      = 95
	bg_dim.position     = Vector2.ZERO
	bg_dim.size         = Vector2(vp_w_sp, 720)
	bg_dim.mouse_filter = Control.MOUSE_FILTER_STOP
	_hud.add_child(bg_dim)

	var pnl := Panel.new()
	pnl.size         = Vector2(880, 650)
	pnl.position     = Vector2((vp_w_sp - 880.0) * 0.5, 30)
	pnl.z_index      = 96
	pnl.clip_contents = true
	pnl.mouse_filter = Control.MOUSE_FILTER_STOP
	var sty_pnl := StyleBoxFlat.new()
	sty_pnl.bg_color     = Color(0.05, 0.08, 0.15, 0.97)
	sty_pnl.border_color = Color(0.22, 0.55, 0.88, 0.85)
	for s in ["left","right","top","bottom"]:
		sty_pnl.set("border_width_" + s, 2)
	for c in ["top_left","top_right","bottom_left","bottom_right"]:
		sty_pnl.set("corner_radius_" + c, 10)
	pnl.add_theme_stylebox_override("panel", sty_pnl)
	_hud.add_child(pnl)
	# Sem tween — Engine.time_scale = 0 durante pausa congelaria a animação

	# Título
	var title := Label.new()
	title.text                 = "ESTATÍSTICAS DA PARTIDA"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.position             = Vector2(0, 14)
	title.size                 = Vector2(880, 51)
	title.add_theme_font_size_override("font_size", 33)
	title.add_theme_color_override("font_color", Color(0.5, 0.85, 1.0))
	pnl.add_child(title)

	var sep_top := ColorRect.new()
	sep_top.color    = Color(0.22, 0.55, 0.88, 0.4)
	sep_top.size     = Vector2(840, 2)
	sep_top.position = Vector2(20, 54)
	pnl.add_child(sep_top)

	# Botão fechar
	var btn_x := Button.new()
	btn_x.text       = "FECHAR"
	btn_x.position   = Vector2(300, 606)
	btn_x.size       = Vector2(280, 54)
	btn_x.focus_mode = Control.FOCUS_NONE
	btn_x.add_theme_font_size_override("font_size", 21)
	var sty_x := StyleBoxFlat.new()
	sty_x.bg_color     = Color(0.08, 0.16, 0.28, 0.95)
	sty_x.border_color = Color(0.25, 0.60, 1.0, 0.8)
	for s in ["left","right","top","bottom"]:
		sty_x.set("border_width_" + s, 1)
	for c in ["top_left","top_right","bottom_left","bottom_right"]:
		sty_x.set("corner_radius_" + c, 6)
	btn_x.add_theme_stylebox_override("normal", sty_x)
	btn_x.add_theme_color_override("font_color", Color(0.6, 0.85, 1.0))
	btn_x.pressed.connect(func() -> void:
		pnl.queue_free()
		bg_dim.queue_free()
		if _pause_overlay and is_instance_valid(_pause_overlay):
			_pause_overlay.show()
	)
	pnl.add_child(btn_x)

	# Divisória vertical
	var div_v := ColorRect.new()
	div_v.color    = Color(0.22, 0.55, 0.88, 0.28)
	div_v.size     = Vector2(1, 538)
	div_v.position = Vector2(436, 58)
	pnl.add_child(div_v)

	# ── COLUNA ESQUERDA: Torre + Habilidades ─────────────────────────────────
	var cy := 66.0
	var cx1 := 22.0

	_st_header(pnl, "TORRE", cx1, cy, Color(0.5, 0.85, 1.0))
	cy += 28.0

	var hp       : float = float(d.get("hp",                   0.0))
	var max_hp   : float = float(d.get("max_hp",               0.0))
	var damage   : float = float(d.get("damage",               0.0))
	var range_r  : float = float(d.get("range_r",              0.0))
	var fire_rate: float = float(d.get("fire_rate",            0.0))
	var regen    : float = float(d.get("regen_rate",           0.0))
	var dr       : float = float(d.get("damage_reduction",     0.0))
	var pierce   : int   = int  (d.get("pierce_count",         0))
	var multi_nv : int   = int  (d.get("multi_lvl",            0))
	var chama    : float = float(d.get("chama_bonus_por_kill", 0.0))

	_st_row(pnl, "Vida",      "%.0f / %.0f" % [hp, max_hp],  Color(0.12, 1.0,  0.45), cx1, cy); cy += 23.0
	_st_row(pnl, "Dano",      "%.0f" % damage,                Color(1.0,  0.42, 0.1),  cx1, cy); cy += 23.0
	_st_row(pnl, "Cadência",  "%.2f tiros/s" % fire_rate,     Color(0.75, 0.2,  1.0),  cx1, cy); cy += 23.0
	_st_row(pnl, "Alcance",   "%.0f px" % range_r,            Color(0.12, 0.62, 1.0),  cx1, cy); cy += 23.0
	if regen > 0.0:
		_st_row(pnl, "Regeneração",  "%.1f HP/s" % regen,           Color(0.4,  1.0,  0.55), cx1, cy); cy += 23.0
	if dr > 0.0:
		_st_row(pnl, "Red. de dano", "%.0f%%" % (dr * 100.0),       Color(0.2,  0.6,  1.0),  cx1, cy); cy += 23.0
	if pierce > 0:
		_st_row(pnl, "Perfuração",   "%d inimigo(s)" % pierce,       Color(1.0,  0.88, 0.12), cx1, cy); cy += 23.0
	if multi_nv > 0:
		_st_row(pnl, "Canhões orb.", "%d extra(s)" % multi_nv,       Color(0.12, 1.0,  0.88), cx1, cy); cy += 23.0
	if chama > 0.0:
		_st_row(pnl, "Chama acum.",  "+%.1f/kill" % chama,           Color(1.0,  0.58, 0.08), cx1, cy); cy += 23.0

	cy += 10.0
	_st_header(pnl, "HABILIDADES ATIVAS", cx1, cy, Color(1.0, 0.75, 0.18))
	cy += 28.0

	var raio_nv  : int   = int  (d.get("raio_nivel",        0))
	var raio_dano: float = float(d.get("raio_dano",         0.0))
	var corrente : bool  = bool (d.get("corrente_ativa",    false))
	var veneno   : float = float(d.get("veneno_dps",        0.0))
	var crit     : float = float(d.get("crit_chance",       0.0))
	var explosao : bool  = bool (d.get("explosao_ativa",    false))
	var overdrive: bool  = bool (d.get("overdrive_ativa",   false))
	var armor_inv: bool  = bool (d.get("armadura_inv",      false))
	var bencao   : bool  = bool (d.get("bencao_ativa",      false))
	var bencao_k : int   = int  (d.get("bencao_kills",      0))
	var recup    : bool  = bool (d.get("recuperacao_ativa", false))
	var imortal  : bool  = bool (d.get("imortal_ativo",     false))
	var rajada   : bool  = bool (d.get("rajada_ativa",      false))
	var carga    : bool  = bool (d.get("carga_ativa",       false))
	var gelo     : bool  = bool (d.get("gelo_ativo",        false))

	var tem_hab := false
	if raio_nv > 0:
		_st_row(pnl, "Raio Arcano",      "Nível %d  +%.0f dano" % [raio_nv, raio_dano], Color(0.40, 0.72, 1.0), cx1, cy); cy += 20.0; tem_hab = true
	if corrente:
		_st_row(pnl, "Corrente Elétrica","Saltos em +2 alvos",  Color(0.25, 0.95, 1.0), cx1, cy); cy += 20.0; tem_hab = true
	if veneno > 0.0:
		_st_row(pnl, "Veneno Arcano",    "%.0f dps / 4s" % veneno, Color(0.25, 1.0, 0.2), cx1, cy); cy += 20.0; tem_hab = true
	if crit > 0.0:
		_st_row(pnl, "Golpe Crítico",    "%.0f%% chance 3x" % (crit * 100.0), Color(1.0, 0.50, 0.05), cx1, cy); cy += 20.0; tem_hab = true
	if explosao:
		_st_row(pnl, "Explosão Mortal",  "Ativa ao matar",      Color(1.0, 0.38, 0.05), cx1, cy); cy += 20.0; tem_hab = true
	if overdrive:
		_st_row(pnl, "Overdrive",        "Cadência x2 pós-boss",Color(1.0, 0.80, 0.0),  cx1, cy); cy += 20.0; tem_hab = true
	if armor_inv:
		_st_row(pnl, "Arm. Invertida",   "+60% dano <30% HP",   Color(0.85, 0.25, 0.95),cx1, cy); cy += 20.0; tem_hab = true
	if bencao:
		_st_row(pnl, "Bênção",           "%d/15 kills = 8x tiro" % bencao_k, Color(1.0, 0.95, 0.25), cx1, cy); cy += 20.0; tem_hab = true
	if recup:
		_st_row(pnl, "Recuperação",      "15 HP/s pós-boss",    Color(0.25, 1.0, 0.50), cx1, cy); cy += 20.0; tem_hab = true
	if imortal:
		_st_row(pnl, "Fênix",            "1x sobrevive com 1 HP",Color(0.5, 0.88, 1.0),  cx1, cy); cy += 20.0; tem_hab = true
	if rajada:
		_st_row(pnl, "Rajada",           "3 projéteis ±15°",     Color(1.0, 0.72, 0.15), cx1, cy); cy += 20.0; tem_hab = true
	if carga:
		_st_row(pnl, "Tiro Carregado",   "Sem alvo 3.5s = 6× dano",Color(0.88, 0.30, 0.05), cx1, cy); cy += 20.0; tem_hab = true
	if gelo:
		_st_row(pnl, "Campo de Gelo",    "-45% vel. no alcance", Color(0.45, 0.82, 1.0), cx1, cy); cy += 20.0; tem_hab = true
	if not tem_hab:
		_st_row(pnl, "—", "Nenhuma ativa ainda", Color(0.45, 0.45, 0.45), cx1, cy)

	# ── COLUNA DIREITA: Cartas + Partida + Loja ───────────────────────────────
	var cx2 := 454.0
	cy = 66.0

	_st_header(pnl, "CARTAS DESTA PARTIDA", cx2, cy, Color(1.0, 0.88, 0.12))
	cy += 28.0

	var cartas_raw = d.get("cartas", {})
	var cartas : Dictionary = cartas_raw if cartas_raw is Dictionary else {}
	if cartas.is_empty():
		_st_linha_carta(pnl, "Nenhuma carta ainda", cx2, cy, Color(0.45, 0.45, 0.45))
		cy += 20.0
	else:
		var carta_ids : Array = cartas.keys()
		var max_cartas : int = 5
		var mostradas  : int = 0
		for cid in carta_ids:
			if mostradas >= max_cartas: break
			var qtd  : int    = int(cartas[cid])
			var nome : String = _st_nome_carta(str(cid))
			var cor  : Color  = _st_cor_carta(str(cid))
			_st_linha_carta(pnl, nome + ("  x%d" % qtd if qtd > 1 else ""), cx2, cy, cor)
			cy += 20.0
			mostradas += 1
		if carta_ids.size() > max_cartas:
			_st_linha_carta(pnl, "... + %d outras" % (carta_ids.size() - max_cartas), cx2, cy, Color(0.45, 0.45, 0.45))
			cy += 20.0

	cy += 12.0
	_st_header(pnl, "PARTIDA", cx2, cy, Color(0.5, 0.85, 1.0))
	cy += 28.0

	_st_row(pnl, "Wave atual",    "%d" % int(d.get("wave",        0)), Color(0.5,  0.85, 1.0),  cx2, cy); cy += 23.0
	_st_row(pnl, "Score",         _fmt_num(int(d.get("score",     0))), Color(1.0,  0.92, 0.15), cx2, cy); cy += 23.0
	_st_row(pnl, "Ouro em mãos",  _fmt_num(int(d.get("gold",      0))), Color(1.0,  0.82, 0.10), cx2, cy); cy += 23.0
	_st_row(pnl, "Mobs mortos",   "%d" % int(d.get("mobs_mortos", 0)), Color(0.78, 0.82, 0.88), cx2, cy); cy += 23.0
	_st_row(pnl, "Bosses mortos", "%d" % int(d.get("boss_mortos", 0)), Color(1.0,  0.35, 0.35), cx2, cy); cy += 23.0
	_st_row(pnl, "Dano causado",  _fmt_float(float(d.get("dano_causado",  0.0))), Color(1.0,  0.55, 0.05), cx2, cy); cy += 23.0
	_st_row(pnl, "Dano recebido", _fmt_float(float(d.get("dano_recebido", 0.0))), Color(1.0,  0.22, 0.22), cx2, cy); cy += 23.0

	var attr_bonus_raw = d.get("atributos_bonus", {})
	var attr_niveis_raw = d.get("atributos_niveis", {})
	var attr_bonus : Dictionary = attr_bonus_raw if attr_bonus_raw is Dictionary else {}
	var attr_niveis : Dictionary = attr_niveis_raw if attr_niveis_raw is Dictionary else {}
	var attr_rows : Array = _st_atributos_rows(attr_bonus, attr_niveis)
	if not attr_rows.is_empty():
		cy += 10.0
		_st_header(pnl, "ATRIBUTOS DA CONTA", cx2, cy, Color(0.35, 1.0, 0.90))
		cy += 26.0
		for row in attr_rows:
			_st_row_mini(pnl, str(row[0]), str(row[1]), row[2] as Color, cx2, cy)
			cy += 17.0
		return

	cy += 12.0
	_st_header(pnl, "MELHORIAS DA LOJA", cx2, cy, Color(0.62, 0.88, 0.42))
	cy += 28.0

	var mel_raw = d.get("melhorias", {})
	var mel : Dictionary = mel_raw if mel_raw is Dictionary else {}
	var forca_n  : int = int(mel.get("forca",       0))
	var resist_n : int = int(mel.get("resistencia", 0))
	var visao_n  : int = int(mel.get("visao",       0))
	var cad_n    : int = int(mel.get("cadencia",    0))
	var fort_n   : int = int(mel.get("fortuna",     0))

	_st_row(pnl, "Força",       "+%d dano base"    % (forca_n  * 8),    Color(1.0,  0.42, 0.1),  cx2, cy); cy += 23.0
	_st_row(pnl, "Resistência", "+%d HP máximo"    % (resist_n * 40),   Color(0.12, 1.0,  0.45), cx2, cy); cy += 23.0
	_st_row(pnl, "Visão",       "+%d alcance"      % (visao_n  * 25),   Color(0.12, 0.62, 1.0),  cx2, cy); cy += 23.0
	_st_row(pnl, "Cadência",    "+%.1f tiros/s"    % (cad_n    * 0.2),  Color(0.75, 0.2,  1.0),  cx2, cy); cy += 23.0
	_st_row(pnl, "Fortuna",     "+%d%% ouro/kill"  % (fort_n   * 15),   Color(1.0,  0.88, 0.12), cx2, cy)


# ── Helpers do painel ─────────────────────────────────────────────────────────

func _st_header(parent: Control, texto: String, x: float, y: float, cor: Color) -> void:
	var lbl := Label.new()
	lbl.text     = texto
	lbl.position = Vector2(x, y)
	lbl.size     = Vector2(408, 30)
	lbl.add_theme_font_size_override("font_size", 16)
	lbl.add_theme_color_override("font_color", cor * Color(1, 1, 1, 0.75))
	parent.add_child(lbl)
	var linha := ColorRect.new()
	linha.color    = Color(cor.r, cor.g, cor.b, 0.22)
	linha.size     = Vector2(408, 2)
	linha.position = Vector2(x, y + 18)
	parent.add_child(linha)


func _st_row(parent: Control, chave: String, valor: String, cor: Color, x: float, y: float) -> void:
	var lk := Label.new()
	lk.text     = chave
	lk.position = Vector2(x, y)
	lk.size     = Vector2(200, 30)
	lk.add_theme_font_size_override("font_size", 20)
	lk.add_theme_color_override("font_color", Color(0.72, 0.78, 0.88))
	parent.add_child(lk)
	var lv := Label.new()
	lv.text                 = valor
	lv.position             = Vector2(x + 200, y)
	lv.size                 = Vector2(205, 30)
	lv.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	lv.add_theme_font_size_override("font_size", 20)
	lv.add_theme_color_override("font_color", cor)
	parent.add_child(lv)


func _st_row_mini(parent: Control, chave: String, valor: String, cor: Color, x: float, y: float) -> void:
	var lk := Label.new()
	lk.text     = chave
	lk.position = Vector2(x, y)
	lk.size     = Vector2(185, 24)
	lk.add_theme_font_size_override("font_size", 15)
	lk.add_theme_color_override("font_color", Color(0.62, 0.68, 0.78))
	parent.add_child(lk)
	var lv := Label.new()
	lv.text                 = valor
	lv.position             = Vector2(x + 185, y)
	lv.size                 = Vector2(220, 24)
	lv.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	lv.add_theme_font_size_override("font_size", 15)
	lv.add_theme_color_override("font_color", cor)
	parent.add_child(lv)


func _st_atributos_rows(bonus: Dictionary, niveis: Dictionary) -> Array:
	var rows : Array = []
	var vida := float(bonus.get("vida_flat", 0.0))
	var dano_pct := (float(bonus.get("dano_mult", 1.0)) - 1.0) * 100.0
	var defesa_pct := float(bonus.get("reducao_dano", 0.0)) * 100.0
	var cadencia_pct := (float(bonus.get("cadencia_mult", 1.0)) - 1.0) * 100.0
	var alcance := float(bonus.get("alcance_flat", 0.0))
	var ouro_pct := float(bonus.get("ouro_mult", 0.0)) * 100.0
	var crit_pct := float(bonus.get("crit_chance", 0.0)) * 100.0
	var cd_pct := absf(float(bonus.get("cooldown_mult", 0.0)) * 100.0)

	if vida > 0.01:
		rows.append(["Vida", "+%.0f HP  Nv.%d" % [vida, int(niveis.get("vida", 0))], Color(0.25, 1.0, 0.48)])
	if dano_pct > 0.01:
		rows.append(["Dano", "+%.0f%%  Nv.%d" % [dano_pct, int(niveis.get("dano", 0))], Color(1.0, 0.48, 0.12)])
	if defesa_pct > 0.01:
		rows.append(["Defesa", "+%.1f%%  Nv.%d" % [defesa_pct, int(niveis.get("defesa", 0))], Color(0.35, 0.72, 1.0)])
	if cadencia_pct > 0.01:
		rows.append(["Cadencia", "+%.1f%%  Nv.%d" % [cadencia_pct, int(niveis.get("agilidade", 0))], Color(0.82, 0.35, 1.0)])
	if alcance > 0.01:
		rows.append(["Alcance", "+%.0f px  Nv.%d" % [alcance, int(niveis.get("alcance", 0))], Color(0.25, 0.92, 1.0)])
	if ouro_pct > 0.01:
		rows.append(["Fortuna", "+%.0f%% ouro  Nv.%d" % [ouro_pct, int(niveis.get("fortuna", 0))], Color(1.0, 0.88, 0.12)])
	if crit_pct > 0.01:
		rows.append(["Critico", "+%.1f%% chance  Nv.%d" % [crit_pct, int(niveis.get("critico", 0))], Color(1.0, 0.62, 0.08)])
	if cd_pct > 0.01:
		rows.append(["Tecnologia", "-%.1f%% recarga  Nv.%d" % [cd_pct, int(niveis.get("tecnologia", 0))], Color(0.45, 1.0, 0.88)])
	return rows


func _st_linha_carta(parent: Control, texto: String, x: float, y: float, cor: Color) -> void:
	# Bolinha colorida + nome da carta (largura total da coluna)
	var dot := ColorRect.new()
	dot.color    = cor
	dot.size     = Vector2(7, 10)
	dot.position = Vector2(x, y + 6)
	parent.add_child(dot)
	var lbl := Label.new()
	lbl.text     = texto
	lbl.position = Vector2(x + 12, y)
	lbl.size     = Vector2(400, 30)
	lbl.add_theme_font_size_override("font_size", 20)
	lbl.add_theme_color_override("font_color", cor)
	parent.add_child(lbl)


func _st_nome_carta(id: String) -> String:
	match id:
		"dano_m":      return "Força Bruta"
		"dano_g":      return "Canhão de Obsidiana"
		"cad_m":       return "Ritmo Acelerado"
		"cad_g":       return "Metralhadora"
		"range_m":     return "Visão Ampla"
		"range_g":     return "Olho de Deus"
		"vida_m":      return "Couraça"
		"vida_g":      return "Fortaleza"
		"pierce":      return "Bala Perfurante"
		"multi":       return "Canhão Duplo"
		"vel":         return "Projétil Sônico"
		"regen":       return "Regeneração"
		"escudo":      return "Escudo Arcano"
		"ouro":        return "Toque de Midas"
		"fragmento":   return "Fragmento Arcano"
		"raio":        return "Raio Arcano"
		"corrente":    return "Corrente Elétrica"
		"veneno":      return "Veneno Arcano"
		"critico":     return "Golpe Crítico"
		"explosao":    return "Explosão Mortal"
		"chama":       return "Chama Perpétua"
		"overdrive":   return "Overdrive"
		"armadura_i":  return "Armadura Invertida"
		"bencao":      return "Bênção de Energia"
		"saque":       return "Saque em Massa"
		"recuperacao": return "Recuperação Rápida"
	return id


func _st_cor_carta(id: String) -> Color:
	match id:
		"dano_m","dano_g":        return Color(1.0,  0.42, 0.1)
		"cad_m","cad_g":          return Color(0.75, 0.2,  1.0)
		"range_m","range_g":      return Color(0.12, 0.62, 1.0)
		"vida_m","vida_g":        return Color(0.12, 1.0,  0.45)
		"pierce","fragmento":     return Color(1.0,  0.88, 0.12)
		"multi":                  return Color(0.12, 1.0,  0.88)
		"vel":                    return Color(0.95, 0.95, 0.12)
		"regen":                  return Color(0.4,  1.0,  0.55)
		"escudo":                 return Color(0.2,  0.6,  1.0)
		"ouro":                   return Color(1.0,  0.82, 0.1)
		"raio","corrente":        return Color(0.40, 0.72, 1.0)
		"veneno":                 return Color(0.25, 1.0,  0.2)
		"critico","chama":        return Color(1.0,  0.50, 0.05)
		"explosao":               return Color(1.0,  0.38, 0.05)
		"overdrive","bencao":     return Color(1.0,  0.80, 0.0)
		"armadura_i":             return Color(0.85, 0.25, 0.95)
		"saque","recuperacao":    return Color(0.25, 1.0,  0.50)
	return Color(0.65, 0.65, 0.65)


func mostrar_nivel_up_pet(nivel: int) -> void:
	if not _hud or not is_instance_valid(_hud): return
	var vp := get_viewport().get_visible_rect().size
	var cor : Color = Salvar.PETS_INFO.get(Salvar.pet_ativo, {}).get("cor", Color(0.25,0.75,1.0)) as Color
	var nome : String = str(Salvar.PETS_INFO.get(Salvar.pet_ativo, {}).get("nome","Comandante"))
	var lbl := Label.new()
	lbl.text = "%s  Nível %d!" % [nome, nivel]
	lbl.add_theme_font_size_override("font_size", 22)
	lbl.add_theme_color_override("font_color", Color(cor.r+0.2,cor.g+0.2,cor.b+0.2))
	lbl.size = Vector2(400, 36)
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.position = Vector2((vp.x - 400.0)*0.5, vp.y*0.38)
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_hud.add_child(lbl)
	var lbl_ref: WeakRef = weakref(lbl)
	var t := Timer.new(); t.wait_time = 2.2; t.one_shot = true
	t.timeout.connect(func():
		var lbl_node: Object = lbl_ref.get_ref()
		if lbl_node and is_instance_valid(lbl_node):
			lbl_node.queue_free()
		if is_instance_valid(t):
			t.queue_free()
	)
	_hud.add_child(t); t.start()
