extends Control
## Mini Cidade — meta-progressão estilo Clash of Clans
## Ref: developers-hub-org/clash-of-clans-clone (C# Unity)
##
##  FEATURES:
##   ▸ Mapa com grid 10×7, edifícios colocados em coordenadas "gx,gy"
##   ▸ Loja (bottom panel) com 6 cards — igual UI_Shop.cs
##   ▸ PLACING: ghost segue cursor, clique coloca edifício
##   ▸ SELECTED: popup de opções sobre o edifício
##   ▸ MOVER: reposicionar edifício para outra célula vazia
##   ▸ TREINAR: Quartel treina soldados (defendem naves)
##   ▸ ATACAR: Arsenal carrega bombardeio p/ próxima run
##   ▸ COLETAR: Mina devolve mana bônus (mecânica de recurso)
##   ▸ Animação de naves atacando a cidade
##   ▸ Sprites CC0 do CoC clone

signal fechado

# ══════════════════════════════════════════════════════════════════════════════
#  DEFINIÇÃO DOS EDIFÍCIOS
# ══════════════════════════════════════════════════════════════════════════════
const EDIFICIOS : Dictionary = {
	"forja":   {"nome": "FORJA",   "cor": Color(1.00, 0.50, 0.10),
				"bonus_txt": "+Dano à torre",       "bonus_desc": ["L1: +10 dano","L2: +25 dano","L3: +50 dano"]},
	"quartel": {"nome": "QUARTEL", "cor": Color(0.30, 0.85, 1.00),
				"bonus_txt": "+Cadência + Soldados", "bonus_desc": ["L1: +0.3 cad","L2: +0.6 cad","L3: +1.0 cad"]},
	"arsenal": {"nome": "ARSENAL", "cor": Color(0.20, 1.00, 0.40),
				"bonus_txt": "+Alcance + Bombardeio","bonus_desc": ["L1: +30 alc","L2: +65 alc","L3: +110 alc"]},
	"lab":     {"nome": "LAB",     "cor": Color(0.88, 0.38, 1.00),
				"bonus_txt": "+Perfuração",          "bonus_desc": ["L1: +1 pierce","L2: +1 pierce","L3: +2 pierce"]},
	"muralha": {"nome": "MURALHA", "cor": Color(0.70, 0.70, 0.75),
				"bonus_txt": "Defesa automática",    "bonus_desc": ["L1: 100 HP","L2: 200 HP","L3: 350 HP"]},
	"mina":    {"nome": "MINA",    "cor": Color(1.00, 0.90, 0.15),
				"bonus_txt": "+Mana por kill",       "bonus_desc": ["L1: +1 mana","L2: +2 mana","L3: +3 mana"]},
}

const CUSTO_BUILD    : int   = 50
const CUSTOS_UP      : Array = [0, 120, 250]
const CUSTO_REPAIR   : int   = 40
const CUSTO_TREINAR  : int   = 30   # por lote de 10 soldados
const CUSTO_ATACAR   : int   = 60   # carregar bombardeio
const MAX_SOLDADOS   : int   = 50
const MAX_HP         : Array = [100, 200, 350]

# ══════════════════════════════════════════════════════════════════════════════
#  GRID
# ══════════════════════════════════════════════════════════════════════════════
const GRID_COLS : int   = 10
const GRID_ROWS : int   = 7
const CELL_W    : float = 88.0
const CELL_H    : float = 78.0
const GRID_OX   : float = 200.0
const GRID_OY   : float = 72.0

# ══════════════════════════════════════════════════════════════════════════════
#  BOTÕES FIXOS
# ══════════════════════════════════════════════════════════════════════════════
const BTN_BACK : Rect2 = Rect2(20,   676, 120, 40)
const BTN_SHOP : Rect2 = Rect2(1140, 676, 120, 40)

# ══════════════════════════════════════════════════════════════════════════════
#  ESTADOS
# ══════════════════════════════════════════════════════════════════════════════
enum State {
	IDLE,       # mapa livre
	SHOP,       # painel da loja aberto
	PLACING,    # escolhendo célula para novo edifício
	SELECTED,   # edifício selecionado → popup de opções
	MOVING      # movendo edifício para nova célula
}

var _state      : State  = State.IDLE
var _sel_key    : String = ""
var _move_src   : String = ""   # chave do edifício sendo movido
var _place_tipo : String = ""
var _hover_gx   : int    = -1
var _hover_gy   : int    = -1

# ── Animação de naves ──────────────────────────────────────────────────────
var _nav_ativo  : bool  = false
var _nav_timer  : float = 0.0
var _nav_ships  : Array = []   # [{px, py, vx, dead, hit_t}]
var _nav_hits   : Array = []   # [{px, py, r, t}] explosões

# ══════════════════════════════════════════════════════════════════════════════
#  HIT-ZONES
# ══════════════════════════════════════════════════════════════════════════════
var _hz_cells      : Dictionary = {}
var _hz_shop_cards : Array      = []
var _hz_opt_btns   : Array      = []

var _pulse  : float = 0.0
var _ui_ref : Node  = null

# ── Sprites CC0 ────────────────────────────────────────────────────────────
var _sprites : Dictionary = {}

# ──────────────────────────────────────────────────────────────────────────────
func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	z_index      = 50
	visible      = false
	mouse_filter = Control.MOUSE_FILTER_STOP
	process_mode = Node.PROCESS_MODE_ALWAYS
	_sprites = {
		"forja":   load("res://assets/cidade/blacksmith.png"),
		"quartel": load("res://assets/cidade/watch_tower.png"),
		"arsenal": load("res://assets/cidade/tower_round.png"),
		"lab":     load("res://assets/cidade/cathedral.png"),
		"muralha": load("res://assets/cidade/fort.png"),
		"mina":    load("res://assets/cidade/mine.png"),
	}


# ══════════════════════════════════════════════════════════════════════════════
#  API PÚBLICA
# ══════════════════════════════════════════════════════════════════════════════
func aplicar_bonus_torre(torre: Node) -> void:
	if not is_instance_valid(torre): return
	torre.damage      += Salvar.cidade_bonus_dano()
	torre.fire_rate   += Salvar.cidade_bonus_fr()
	torre.range_r     += Salvar.cidade_bonus_range()
	torre.pierce_count = mini(int(torre.get("pierce_count")) + Salvar.cidade_bonus_pierce(), 3)
	# Arsenal carregado → bônus de cadência na próxima run (one-shot)
	if Salvar.arsenal_carregado:
		torre.fire_rate   += 0.8
		Salvar.arsenal_carregado = false
		Salvar.salvar()


func on_mob_morreu(ui_node: Node, total_kills: int) -> void:
	Salvar.mana_cidade += 1 + Salvar.cidade_bonus_mana()
	if total_kills % 5 == 0 and is_instance_valid(ui_node) \
			and ui_node.has_method("atualizar_mana_cidade"):
		ui_node.call("atualizar_mana_cidade", Salvar.mana_cidade)


func on_fim_wave(wave: int, ui_node: Node) -> void:
	if wave > 0 and wave % 3 == 0 and not Salvar.cidade_slots.is_empty():
		var sold_antes : int = Salvar.quartel_soldados
		Salvar.cidade_aplicar_dano_nave(35)
		var sold_mortos : int = sold_antes - Salvar.quartel_soldados
		if is_instance_valid(ui_node) and ui_node.has_method("mostrar_notificacao_consumivel"):
			var msg : String = "Naves atacaram a Cidade!"
			if sold_mortos > 0:
				msg += "  ( %d soldados morreram )" % sold_mortos
			ui_node.mostrar_notificacao_consumivel(msg, Color(1.0, 0.35, 0.35))


func abrir(ui_node: Node = null) -> void:
	_ui_ref   = ui_node
	_migrar_slots_antigos()
	visible   = true
	_state    = State.IDLE
	_sel_key  = ""; _move_src = ""; _place_tipo = ""
	_hover_gx = -1; _hover_gy = -1
	get_tree().paused = true
	if is_instance_valid(ui_node): ui_node.visible = false
	queue_redraw()


func fechar() -> void:
	visible = false
	get_tree().paused = false
	if is_instance_valid(_ui_ref): _ui_ref.visible = true
	emit_signal("fechado")


func _process(delta: float) -> void:
	if not visible: return
	_pulse += delta * 3.5
	# Animação naves
	if _nav_ativo:
		_nav_timer += delta
		_tick_naves(delta)
	queue_redraw()


# ══════════════════════════════════════════════════════════════════════════════
#  HELPERS
# ══════════════════════════════════════════════════════════════════════════════
func _cell_rect(gx: int, gy: int) -> Rect2:
	return Rect2(GRID_OX + gx * CELL_W, GRID_OY + gy * CELL_H, CELL_W, CELL_H)

func _cell_key(gx: int, gy: int) -> String:
	return "%d,%d" % [gx, gy]

func _key_to_gxy(key: String) -> Vector2i:
	var p := key.split(",")
	return Vector2i(int(p[0]), int(p[1]))

func _building_at(gx: int, gy: int) -> Dictionary:
	var d = Salvar.cidade_slots.get(_cell_key(gx, gy), {})
	return d if d is Dictionary else {}

func _max_hp(data: Dictionary) -> int:
	return MAX_HP[clampi(int(data.get("nivel", 1)) - 1, 0, 2)]

func _migrar_slots_antigos() -> void:
	var default_pos : Array = ["2,2","4,2","6,2","2,4","4,4","6,4"]
	var old_keys    : Array = []
	for k in Salvar.cidade_slots.keys():
		if (k as String).begins_with("s"): old_keys.append(k)
	if old_keys.is_empty(): return
	for i in range(mini(old_keys.size(), default_pos.size())):
		var ok := old_keys[i] as String
		var nk := default_pos[i] as String
		if not Salvar.cidade_slots.has(nk):
			Salvar.cidade_slots[nk] = Salvar.cidade_slots[ok]
		Salvar.cidade_slots.erase(ok)
	Salvar.salvar()

# ══════════════════════════════════════════════════════════════════════════════
#  ANIMAÇÃO DE NAVES
# ══════════════════════════════════════════════════════════════════════════════
func iniciar_ataque_naves() -> void:
	_nav_ativo = true; _nav_timer = 0.0
	_nav_ships.clear(); _nav_hits.clear()
	# Spawna 4 naves voando da direita
	for i in range(4):
		_nav_ships.append({
			"px": 1340.0 + i * 80.0,
			"py": 90.0 + i * 110.0,
			"vx": -(220.0 + i * 25.0),
			"dead": false,
			"hit_t": -1.0,
		})

func _tick_naves(delta: float) -> void:
	var todas_mortas : bool = true
	for ship in _nav_ships:
		if ship["dead"] as bool: continue
		todas_mortas = false
		ship["px"] = (ship["px"] as float) + (ship["vx"] as float) * delta
		# Atingiu a zona da cidade?
		if (ship["px"] as float) < 1000.0 and (ship["hit_t"] as float) < 0.0:
			ship["hit_t"] = _nav_timer
			ship["dead"]  = true
			# Explosão
			_nav_hits.append({"px": ship["px"], "py": ship["py"], "r": 0.0, "t": 0.0})
	# Anima explosões
	for hit in _nav_hits:
		hit["t"] = (hit["t"] as float) + delta
		hit["r"] = (hit["t"] as float) * 80.0
	# Limpa explosões velhas e remove naves que saíram pela esquerda
	_nav_hits = _nav_hits.filter(func(h): return (h["t"] as float) < 0.8)
	if todas_mortas and _nav_hits.is_empty():
		_nav_ativo = false


# ══════════════════════════════════════════════════════════════════════════════
#  DRAW PRINCIPAL
# ══════════════════════════════════════════════════════════════════════════════
func _draw() -> void:
	_hz_cells.clear(); _hz_shop_cards.clear(); _hz_opt_btns.clear()

	var font := ThemeDB.fallback_font
	var vp   := get_viewport().get_visible_rect().size

	# Fundo escuro
	draw_rect(Rect2(Vector2.ZERO, vp), Color(0.04, 0.06, 0.09, 1.0))

	# Terreno da cidade
	var map_r := Rect2(GRID_OX - 10, GRID_OY - 10,
					   GRID_COLS * CELL_W + 20, GRID_ROWS * CELL_H + 20)
	draw_rect(map_r, Color(0.10, 0.20, 0.09, 1.0))
	draw_rect(map_r, Color(0.22, 0.48, 0.18, 0.72), false, 2.5)

	# Células
	for gy in range(GRID_ROWS):
		for gx in range(GRID_COLS):
			var r   := _cell_rect(gx, gy)
			var key := _cell_key(gx, gy)
			_hz_cells[key] = r
			var even : bool = (gx + gy) % 2 == 0
			draw_rect(r, Color(0.12, 0.25, 0.11, 0.55) if even \
					  else Color(0.09, 0.18, 0.08, 0.55))
			var data := _building_at(gx, gy)

			# Highlight de destino para PLACING / MOVING
			if _state in [State.PLACING, State.MOVING] \
					and gx == _hover_gx and gy == _hover_gy:
				var ok : bool = data.is_empty()
				draw_rect(r, Color(0.0,1.0,0.3,0.28) if ok else Color(1.0,0.1,0.1,0.28))
				draw_rect(r, Color(0.0,1.0,0.3,0.85) if ok else Color(1.0,0.2,0.2,0.85), false, 2.5)

			if data.is_empty():
				if _state in [State.IDLE, State.SELECTED]:
					var p := 0.10 + sin(_pulse + gx * 0.4 + gy * 0.7) * 0.06
					draw_rect(r, Color(0.22, 0.50, 0.18, p), false, 1.0)
			else:
				_draw_building_in_cell(r, gx, gy, data, key == _sel_key)

	# Ghost de placement/moving
	if _state in [State.PLACING, State.MOVING] and _hover_gx >= 0:
		var gr  := _cell_rect(_hover_gx, _hover_gy)
		var ghost_tipo := _place_tipo if _state == State.PLACING \
						else (_building_at(_key_to_gxy(_move_src).x,
										   _key_to_gxy(_move_src).y).get("tipo","") as String)
		var tex := _sprites.get(ghost_tipo, null) as Texture2D
		if tex:
			var ts : float = minf(gr.size.x, gr.size.y) * 0.82
			draw_texture_rect(tex,
				Rect2(gr.get_center() - Vector2(ts,ts)*0.5, Vector2(ts,ts)),
				false, Color(1.0,1.0,1.0,0.50))
		var ef   := EDIFICIOS.get(ghost_tipo, {}) as Dictionary
		var gcor := ef.get("cor", Color.WHITE) as Color
		draw_rect(gr, Color(gcor.r, gcor.g, gcor.b, 0.65), false, 2.5)

	# Animação naves
	if _nav_ativo: _draw_naves()

	# ── Top bar ──────────────────────────────────────────────────────────────
	draw_rect(Rect2(0, 0, vp.x, 64.0), Color(0.03, 0.04, 0.08, 0.97))
	draw_line(Vector2(0, 64), Vector2(vp.x, 64), Color(0.25, 0.45, 0.80, 0.50), 1.5)
	draw_string(font, Vector2(22, 44), "CIDADE BASE",
				HORIZONTAL_ALIGNMENT_LEFT, -1, 32, Color(0.80, 0.92, 1.0))
	# Mana badge
	draw_rect(Rect2(vp.x - 196, 10, 176, 44), Color(0.06, 0.10, 0.22, 0.95))
	draw_rect(Rect2(vp.x - 196, 10, 176, 44), Color(0.28, 0.52, 1.0, 0.55), false, 2.0)
	draw_string(font, Vector2(vp.x - 184, 38),
				"Mana: %d" % Salvar.mana_cidade,
				HORIZONTAL_ALIGNMENT_LEFT, -1, 22, Color(0.50, 0.85, 1.0))
	# Soldados badge
	if Salvar.quartel_soldados > 0:
		var s_str := "Soldados: %d" % Salvar.quartel_soldados
		draw_rect(Rect2(vp.x - 400, 10, 196, 44), Color(0.04, 0.14, 0.28, 0.95))
		draw_rect(Rect2(vp.x - 400, 10, 196, 44), Color(0.25, 0.75, 1.0, 0.55), false, 2.0)
		draw_string(font, Vector2(vp.x - 390, 38),
					s_str, HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color(0.50, 0.90, 1.0))
	# Arsenal carregado badge
	if Salvar.arsenal_carregado:
		draw_rect(Rect2(vp.x - 620, 10, 210, 44), Color(0.04, 0.20, 0.04, 0.95))
		draw_rect(Rect2(vp.x - 620, 10, 210, 44), Color(0.20, 1.0, 0.40, 0.70), false, 2.0)
		draw_string(font, Vector2(vp.x - 612, 38),
					"BOMBARDEIO PRONTO", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color(0.30, 1.0, 0.50))
	# Bônus ativos
	var bs : String = ""
	var db := Salvar.cidade_bonus_dano();   if db > 0: bs += "+%d dmg  " % int(db)
	var fb := Salvar.cidade_bonus_fr();     if fb > 0: bs += "+%.1fcd  " % fb
	var rb := Salvar.cidade_bonus_range();  if rb > 0: bs += "+%dalc  " % int(rb)
	var pb := Salvar.cidade_bonus_pierce(); if pb > 0: bs += "+%dpierce" % pb
	if bs != "":
		draw_string(font, Vector2(220, 50), bs,
					HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color(0.50, 0.90, 0.42, 0.85))

	# ── Bottom bar ───────────────────────────────────────────────────────────
	draw_rect(Rect2(0, 658, vp.x, 62.0), Color(0.03, 0.04, 0.08, 0.97))
	draw_line(Vector2(0, 658), Vector2(vp.x, 658), Color(0.25, 0.45, 0.80, 0.50), 1.5)
	_draw_btn(BTN_BACK, "< VOLTAR", Color(0.35, 0.52, 0.80))
	var sc := Color(0.12,1.0,0.55) if _state == State.SHOP else Color(1.0,0.72,0.12)
	_draw_btn(BTN_SHOP, "LOJA", sc)
	# Hint
	match _state:
		State.PLACING:
			var ef := EDIFICIOS.get(_place_tipo, {}) as Dictionary
			draw_string(font, Vector2(vp.x*0.5-240, 684),
				"Clique no mapa para colocar %s   ( ESC = cancelar )" % ef.get("nome","?"),
				HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color(0.78, 1.0, 0.60))
		State.MOVING:
			draw_string(font, Vector2(vp.x*0.5-240, 684),
				"Clique na célula de destino para mover   ( ESC = cancelar )",
				HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color(1.0, 0.90, 0.40))

	# ── Painéis por estado ────────────────────────────────────────────────────
	match _state:
		State.SHOP:     _draw_shop_panel()
		State.SELECTED: _draw_building_options()


# ══════════════════════════════════════════════════════════════════════════════
#  EDIFÍCIO NA CÉLULA
# ══════════════════════════════════════════════════════════════════════════════
func _draw_building_in_cell(r: Rect2, _gx: int, _gy: int,
							data: Dictionary, selected: bool) -> void:
	var font  := ThemeDB.fallback_font
	var tipo  := data.get("tipo", "") as String
	var nivel : int = int(data.get("nivel", 1))
	var hp    : int = int(data.get("hp", 0))
	var mhp   : int = _max_hp(data)
	var ef    := EDIFICIOS.get(tipo, {}) as Dictionary
	var cor   := ef.get("cor", Color.WHITE) as Color

	if selected:
		draw_rect(r, Color(cor.r*.22, cor.g*.22, cor.b*.22,
						   0.40+sin(_pulse)*0.12))
		draw_rect(r, Color(cor.r, cor.g, cor.b, 0.90), false, 3.0)
	else:
		draw_rect(r, Color(cor.r*.07, cor.g*.07, cor.b*.07, 0.40))
		draw_rect(r, Color(cor.r, cor.g, cor.b, 0.30), false, 1.5)

	var tex := _sprites.get(tipo, null) as Texture2D
	var cx  : float = r.get_center().x
	var cy  : float = r.get_center().y - 7.0
	if tex:
		var ts : float = minf(r.size.x, r.size.y) * 0.78
		draw_texture_rect(tex, Rect2(cx-ts*.5, cy-ts*.5, ts, ts), false)
	else:
		_draw_icon_geo(tipo, cor, Vector2(cx, cy), 18.0)

	# Badge especial por tipo
	if tipo == "quartel" and Salvar.quartel_soldados > 0:
		var s_lbl := "%d" % Salvar.quartel_soldados
		draw_rect(Rect2(r.position.x+2, r.position.y+2, 30, 18), Color(0.0,0.0,0.0,0.75))
		draw_string(font, Vector2(r.position.x+4, r.position.y+15),
					s_lbl, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(0.50,0.90,1.0))
	if tipo == "arsenal" and Salvar.arsenal_carregado:
		draw_rect(Rect2(r.position.x+2, r.position.y+2, 14, 14), Color(0.0,0.8,0.2,0.90))

	# Pontinhos de nível
	for li in range(3):
		var dc := cor if li < nivel else Color(cor.r, cor.g, cor.b, 0.18)
		draw_circle(Vector2(cx-8+float(li)*8, r.position.y+r.size.y-18), 3.5, dc)

	# HP bar
	var hf  : float = clampf(float(hp)/float(maxi(mhp,1)), 0.0, 1.0)
	var bx  : float = r.position.x+4;  var by_ : float = r.position.y+r.size.y-9
	var bw  : float = r.size.x-8
	draw_rect(Rect2(bx, by_, bw, 5), Color(0.06,0.06,0.06,0.85))
	var hcol := Color(0.20,1.0,0.45) if hf>.50 else (Color(1.0,0.80,0.15) if hf>.25 else Color(1.0,0.22,0.22))
	draw_rect(Rect2(bx, by_, bw*hf, 5), hcol)


# ══════════════════════════════════════════════════════════════════════════════
#  BOTÃO HELPER
# ══════════════════════════════════════════════════════════════════════════════
func _draw_btn(r: Rect2, label: String, cor: Color) -> void:
	var font := ThemeDB.fallback_font
	draw_rect(r, Color(cor.r*.10, cor.g*.10, cor.b*.10, 0.96))
	draw_rect(r, Color(cor.r, cor.g, cor.b, 0.72), false, 2.0)
	var tw : float = float(label.length()) * 7.5
	draw_string(font, Vector2(r.get_center().x-tw*.5, r.position.y+r.size.y*.68),
				label, HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color(cor.r, cor.g, cor.b))


# ══════════════════════════════════════════════════════════════════════════════
#  SHOP PANEL  (UI_Shop.cs)
# ══════════════════════════════════════════════════════════════════════════════
func _draw_shop_panel() -> void:
	var font := ThemeDB.fallback_font
	var vp   := get_viewport().get_visible_rect().size

	const PH : float = 286.0
	var po := Vector2(0.0, vp.y - PH - 62.0)

	draw_rect(Rect2(po, Vector2(vp.x, PH)), Color(0.03, 0.05, 0.13, 0.97))
	draw_line(po, Vector2(vp.x, po.y), Color(0.35, 0.62, 1.0, 0.65), 2.5)
	draw_string(font, po + Vector2(22, 34),
				"CONSTRUIR   ( custo: %d mana )" % CUSTO_BUILD,
				HORIZONTAL_ALIGNMENT_LEFT, -1, 20, Color(0.82, 0.94, 1.0))

	const CW : float = 176.0;  const CH : float = 218.0;  const CG : float = 12.0
	var total_w : float = 6.0*CW + 5.0*CG
	var cx0 : float = (vp.x - total_w) * 0.5
	var cy0 : float = po.y + 50.0

	var tipos : Array = EDIFICIOS.keys()
	for i in range(tipos.size()):
		var tipo := tipos[i] as String
		var cr   := Rect2(cx0 + float(i)*(CW+CG), cy0, CW, CH)
		var ef   := EDIFICIOS[tipo] as Dictionary
		var cor  := ef.get("cor", Color.WHITE) as Color

		var ja_tem : bool = false
		for sid in Salvar.cidade_slots.keys():
			if (Salvar.cidade_slots[sid] as Dictionary).get("tipo","") == tipo:
				ja_tem = true; break
		var sem_mana := Salvar.mana_cidade < CUSTO_BUILD
		var pode     := not ja_tem and not sem_mana

		var bg_a : float = 0.90 if pode else 0.35
		draw_rect(cr, Color(cor.r*.15, cor.g*.15, cor.b*.15, bg_a))
		draw_rect(cr, Color(cor.r, cor.g, cor.b, 0.72 if pode else 0.18), false, 2.5)

		var ccx : float = cr.get_center().x
		var ccy : float = cr.position.y + CH*0.42

		if ja_tem:
			draw_rect(cr, Color(0,0,0,0.55))
			var tx2 := _sprites.get(tipo, null) as Texture2D
			if tx2:
				var ts2 : float = CW*.60
				draw_texture_rect(tx2, Rect2(ccx-ts2*.5, cr.position.y+16, ts2, ts2),
								  false, Color(1,1,1,0.30))
			draw_string(font, Vector2(ccx-46, ccy+22), "CONSTRUÍDO",
						HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color(0.55,0.55,0.55))
		else:
			var tex  := _sprites.get(tipo, null) as Texture2D
			var alp  : float = 1.0 if pode else 0.38
			if tex:
				var ts : float = CW*.70
				draw_texture_rect(tex, Rect2(ccx-ts*.5, cr.position.y+10, ts, ts),
								  false, Color(1,1,1,alp))
			else:
				_draw_icon_geo(tipo, Color(cor.r,cor.g,cor.b,alp), Vector2(ccx,ccy-22), 28.0)

			var nome := ef.get("nome","") as String
			draw_string(font, Vector2(ccx - float(nome.length())*5.5, ccy+26),
						nome, HORIZONTAL_ALIGNMENT_LEFT, -1, 18,
						Color(1,1,1,0.95 if pode else 0.40))
			var bt := ef.get("bonus_txt","") as String
			draw_string(font, Vector2(ccx - float(bt.length())*3.5, ccy+44),
						bt, HORIZONTAL_ALIGNMENT_LEFT, -1, 12,
						Color(cor.r,cor.g,cor.b,0.85 if pode else 0.28))
			draw_string(font, Vector2(ccx-30, ccy+62),
						"%d mana" % CUSTO_BUILD, HORIZONTAL_ALIGNMENT_LEFT, -1, 14,
						Color(0.28,1.0,0.48) if pode else Color(1.0,0.28,0.28))
			if pode:
				_hz_shop_cards.append({"rect": cr, "tipo": tipo})


# ══════════════════════════════════════════════════════════════════════════════
#  BUILDING OPTIONS POPUP  (UI_BuildingOptions.cs — SetStatus)
# ══════════════════════════════════════════════════════════════════════════════
func _draw_building_options() -> void:
	var gxy  := _key_to_gxy(_sel_key)
	var data  = _building_at(gxy.x, gxy.y)
	if data.is_empty(): _state = State.IDLE; queue_redraw(); return

	var font  := ThemeDB.fallback_font
	var tipo  := data.get("tipo", "") as String
	var nivel : int = int(data.get("nivel", 1))
	var hp    : int = int(data.get("hp", 0))
	var mhp   : int = _max_hp(data)
	var ef    := EDIFICIOS.get(tipo, {}) as Dictionary
	var cor   := ef.get("cor", Color.WHITE) as Color

	# Calcular altura do popup dinamicamente
	var num_btns : int = 1  # MOVER sempre
	if nivel < 3: num_btns += 1      # UPGRADE
	if hp < mhp:  num_btns += 1      # REPARAR
	num_btns += 1                    # DEMOLIR
	if tipo == "quartel": num_btns += 1   # TREINAR
	if tipo == "arsenal": num_btns += 1   # ATACAR / DESCARREGAR

	const BH : float = 42.0; const BG : float = 7.0
	var PH : float = 100.0 + float(num_btns) * (BH + BG)
	const PW : float = 340.0

	var cell_r := _cell_rect(gxy.x, gxy.y)
	var px : float = clampf(cell_r.get_center().x - PW*.5, 8.0, 1272.0-PW)
	var py : float = clampf(cell_r.position.y - PH - 12.0, 68.0, 650.0-PH)
	var po := Vector2(px, py)

	draw_rect(Rect2(po, Vector2(PW, PH)), Color(0.04, 0.05, 0.10, 0.97))
	draw_rect(Rect2(po, Vector2(PW, PH)), Color(cor.r,cor.g,cor.b,0.62), false, 3.0)

	# Header
	var tex := _sprites.get(tipo, null) as Texture2D
	if tex: draw_texture_rect(tex, Rect2(po.x+8, po.y+8, 58, 58), false)
	else:   _draw_icon_geo(tipo, cor, po+Vector2(37,37), 18.0)
	draw_string(font, po+Vector2(74, 30), ef.get("nome","") as String,
				HORIZONTAL_ALIGNMENT_LEFT, -1, 22, cor)

	# Info de nível e bônus
	var bd := ef.get("bonus_desc", []) as Array
	var bd_txt := bd[clampi(nivel-1,0,2)] as String if bd.size() > 0 else ""
	draw_string(font, po+Vector2(74, 50),
				"Nível %d   HP %d/%d" % [nivel, hp, mhp],
				HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color(0.75,0.85,0.95))
	draw_string(font, po+Vector2(74, 65),
				bd_txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color(cor.r,cor.g,cor.b,0.85))

	# HP bar
	var hf  : float = clampf(float(hp)/float(maxi(mhp,1)), 0.0, 1.0)
	draw_rect(Rect2(po.x+10, po.y+78, PW-20, 6), Color(0.08,0.08,0.08,0.90))
	var hc := Color(0.20,1.0,0.45) if hf>.50 else (Color(1.0,0.80,0.15) if hf>.25 else Color(1.0,0.22,0.22))
	draw_rect(Rect2(po.x+10, po.y+78, (PW-20)*hf, 6), hc)

	# ── Botões de ação ────────────────────────────────────────────────────────
	var ay : float = po.y + 96.0
	const ABW : float = PW - 20.0

	# MOVER (todos os edifícios) — CoC: "Move Building"
	var mr := Rect2(po.x+10, ay, ABW, BH)
	draw_rect(mr, Color(0.12, 0.10, 0.22, 0.95))
	draw_rect(mr, Color(0.75, 0.55, 1.0, 0.70), false, 2.0)
	draw_string(font, Vector2(po.x+20, ay+28), "↔ MOVER",
				HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color(0.85, 0.70, 1.0))
	_hz_opt_btns.append({"rect": mr, "acao": "mover"})
	ay += BH + BG

	# UPGRADE  (UI_BuildingUpgrade.cs)
	if nivel < 3:
		var custo_up : int = CUSTOS_UP[nivel]
		var pode_up  : bool = Salvar.mana_cidade >= custo_up
		var ur := Rect2(po.x+10, ay, ABW, BH)
		draw_rect(ur, Color(0.08,0.16,0.28,0.95) if pode_up else Color(0.06,0.07,0.10,0.60))
		draw_rect(ur, Color(0.28,0.68,1.0,0.72 if pode_up else 0.18), false, 2.0)
		draw_string(font, Vector2(po.x+20, ay+28),
					"▲ UPGRADE  L%d → L%d   ( %d mana )" % [nivel, nivel+1, custo_up],
					HORIZONTAL_ALIGNMENT_LEFT, -1, 16,
					Color(0.48,0.88,1.0,1.0 if pode_up else 0.28))
		if pode_up: _hz_opt_btns.append({"rect": ur, "acao": "upgrade"})
		ay += BH + BG

	# TREINAR soldados (quartel)
	if tipo == "quartel":
		var sold    : int  = Salvar.quartel_soldados
		var espaco  : int  = MAX_SOLDADOS - sold
		var pode_tr : bool = Salvar.mana_cidade >= CUSTO_TREINAR and espaco >= 10
		var tr := Rect2(po.x+10, ay, ABW, BH)
		draw_rect(tr, Color(0.04,0.14,0.22,0.95) if pode_tr else Color(0.06,0.07,0.10,0.60))
		draw_rect(tr, Color(0.25,0.75,1.0,0.72 if pode_tr else 0.18), false, 2.0)
		var tr_txt : String
		if espaco < 10:
			tr_txt = "TREINAR  ( máx atingido: %d/%d )" % [sold, MAX_SOLDADOS]
		else:
			tr_txt = "TREINAR +10 soldados  ( %d mana )   %d/%d" % [CUSTO_TREINAR, sold, MAX_SOLDADOS]
		draw_string(font, Vector2(po.x+20, ay+28), tr_txt,
					HORIZONTAL_ALIGNMENT_LEFT, -1, 15,
					Color(0.50,0.88,1.0,1.0 if pode_tr else 0.28))
		if pode_tr: _hz_opt_btns.append({"rect": tr, "acao": "treinar"})
		ay += BH + BG

	# ATACAR (arsenal) — carrega bombardeio para próxima run
	if tipo == "arsenal":
		if Salvar.arsenal_carregado:
			var ar := Rect2(po.x+10, ay, ABW, BH)
			draw_rect(ar, Color(0.04, 0.20, 0.04, 0.95))
			draw_rect(ar, Color(0.20, 1.0, 0.40, 0.70), false, 2.0)
			draw_string(font, Vector2(po.x+20, ay+28),
						"BOMBARDEIO PRONTO  ( aplica na próxima run )",
						HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color(0.30, 1.0, 0.50))
			_hz_opt_btns.append({"rect": ar, "acao": "decarregar"})
		else:
			var pode_at : bool = Salvar.mana_cidade >= CUSTO_ATACAR
			var ar := Rect2(po.x+10, ay, ABW, BH)
			draw_rect(ar, Color(0.18,0.08,0.04,0.95) if pode_at else Color(0.06,0.07,0.10,0.60))
			draw_rect(ar, Color(1.0,0.55,0.15,0.72 if pode_at else 0.18), false, 2.0)
			draw_string(font, Vector2(po.x+20, ay+28),
						"CARREGAR BOMBARDEIO  ( %d mana )   +0.8 cad run" % CUSTO_ATACAR,
						HORIZONTAL_ALIGNMENT_LEFT, -1, 15,
						Color(1.0,0.70,0.30,1.0 if pode_at else 0.28))
			if pode_at: _hz_opt_btns.append({"rect": ar, "acao": "atacar"})
		ay += BH + BG

	# REPARAR
	if hp < mhp:
		var pode_rep : bool = Salvar.mana_cidade >= CUSTO_REPAIR
		var rr := Rect2(po.x+10, ay, ABW, BH)
		draw_rect(rr, Color(0.07,0.18,0.10,0.95) if pode_rep else Color(0.06,0.07,0.10,0.60))
		draw_rect(rr, Color(0.20,0.90,0.40,0.72 if pode_rep else 0.18), false, 2.0)
		draw_string(font, Vector2(po.x+20, ay+28),
					"♥ REPARAR   ( %d mana )" % CUSTO_REPAIR,
					HORIZONTAL_ALIGNMENT_LEFT, -1, 16,
					Color(0.28,1.0,0.50,1.0 if pode_rep else 0.28))
		if pode_rep: _hz_opt_btns.append({"rect": rr, "acao": "reparar"})
		ay += BH + BG

	# DEMOLIR
	var dr := Rect2(po.x+10, ay, ABW, BH)
	draw_rect(dr, Color(0.22,0.04,0.04,0.95))
	draw_rect(dr, Color(1.0,0.28,0.28,0.55), false, 2.0)
	draw_string(font, Vector2(po.x+20, ay+28),
				"✕ DEMOLIR   ( +10 mana devolvido )",
				HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color(1.0,0.42,0.42))
	_hz_opt_btns.append({"rect": dr, "acao": "demolir"})


# ══════════════════════════════════════════════════════════════════════════════
#  ANIMAÇÃO DE NAVES ATACANDO
# ══════════════════════════════════════════════════════════════════════════════
func _draw_naves() -> void:
	for ship in _nav_ships:
		if ship["dead"] as bool: continue
		var sx : float = ship["px"] as float
		var sy : float = ship["py"] as float
		# Corpo da nave (triângulo vermelho)
		var pts := PackedVector2Array([
			Vector2(sx+20, sy),
			Vector2(sx-20, sy-10),
			Vector2(sx-20, sy+10),
		])
		draw_colored_polygon(pts, Color(0.90, 0.15, 0.15, 0.90))
		# Asas
		draw_line(Vector2(sx-10, sy), Vector2(sx-10, sy-20), Color(0.80,0.10,0.10,0.80), 2.5)
		draw_line(Vector2(sx-10, sy), Vector2(sx-10, sy+20), Color(0.80,0.10,0.10,0.80), 2.5)
		# Motor
		draw_circle(Vector2(sx-22, sy), 4.0, Color(1.0, 0.60, 0.10, 0.90))
	# Explosões
	for hit in _nav_hits:
		var r  : float = hit["r"] as float
		var t  : float = hit["t"] as float
		var a  : float = clampf(1.0 - t/0.8, 0.0, 1.0)
		draw_circle(Vector2(hit["px"] as float, hit["py"] as float), r,
					Color(1.0, 0.55, 0.10, a * 0.75))
		draw_circle(Vector2(hit["px"] as float, hit["py"] as float), r * 0.5,
					Color(1.0, 0.90, 0.20, a * 0.90))


# ══════════════════════════════════════════════════════════════════════════════
#  ÍCONE GEOMÉTRICO (fallback)
# ══════════════════════════════════════════════════════════════════════════════
func _draw_icon_geo(tipo: String, cor: Color, c: Vector2, s: float) -> void:
	match tipo:
		"forja":
			draw_line(c+Vector2(0,-s),       c+Vector2(s*.8,s*.7),  cor, 2.5)
			draw_line(c+Vector2(s*.8,s*.7),  c+Vector2(-s*.8,s*.7), cor, 2.5)
			draw_line(c+Vector2(-s*.8,s*.7), c+Vector2(0,-s),       cor, 2.5)
		"quartel":
			draw_arc(c, s, 0, TAU, 28, cor, 2.5)
			draw_line(c+Vector2(-s,0), c+Vector2(s,0), cor, 2.0)
			draw_line(c+Vector2(0,-s), c+Vector2(0,s), cor, 2.0)
		"arsenal":
			draw_line(c+Vector2(-s,0),       c+Vector2(s*.4,0),  cor, 3.0)
			draw_line(c+Vector2(-s*.1,-s*.6),c+Vector2(s*.5,0),  cor, 2.5)
			draw_line(c+Vector2(-s*.1,s*.6), c+Vector2(s*.5,0),  cor, 2.5)
		"lab":
			for hi in range(6):
				var a1 := float(hi)/6.0*TAU; var a2 := float(hi+1)/6.0*TAU
				draw_line(c+Vector2(cos(a1),sin(a1))*s,
						  c+Vector2(cos(a2),sin(a2))*s, cor, 2.5)
		"muralha":
			draw_rect(Rect2(c.x-s,c.y-s*.25,s*2.0,s*.85), Color(cor.r,cor.g,cor.b,.18))
			draw_rect(Rect2(c.x-s,c.y-s*.25,s*2.0,s*.85), cor, false, 2.5)
		"mina":
			draw_line(c+Vector2(0,-s),      c+Vector2(s*.65,0), cor, 2.5)
			draw_line(c+Vector2(s*.65,0),   c+Vector2(0,s),     cor, 2.5)
			draw_line(c+Vector2(0,s),       c+Vector2(-s*.65,0),cor, 2.5)
			draw_line(c+Vector2(-s*.65,0),  c+Vector2(0,-s),    cor, 2.5)


# ══════════════════════════════════════════════════════════════════════════════
#  INPUT
# ══════════════════════════════════════════════════════════════════════════════
func _input(event: InputEvent) -> void:
	if not visible: return

	if event is InputEventKey:
		var ev := event as InputEventKey
		if ev.pressed and ev.keycode == KEY_ESCAPE:
			match _state:
				State.PLACING:
					_state = State.IDLE; _place_tipo = ""; _hover_gx=-1; _hover_gy=-1
				State.MOVING:
					_state = State.SELECTED; _move_src = ""
				State.SHOP, State.SELECTED:
					_state = State.IDLE; _sel_key = ""
				_:
					fechar()
			queue_redraw()
			get_viewport().set_input_as_handled()
		return

	if event is InputEventMouseMotion:
		_update_hover((event as InputEventMouseMotion).position)
		return

	var pos : Vector2
	var pressed : bool = false
	if event is InputEventMouseButton:
		var ev := event as InputEventMouseButton
		if ev.button_index == MOUSE_BUTTON_LEFT and ev.pressed:
			pos = ev.position; pressed = true
	elif event is InputEventScreenTouch:
		var ev := event as InputEventScreenTouch
		if ev.pressed: pos = ev.position; pressed = true

	if pressed:
		_handle_tap(pos)
		get_viewport().set_input_as_handled()


func _update_hover(pos: Vector2) -> void:
	if not (_state in [State.PLACING, State.MOVING]): return
	for key in _hz_cells.keys():
		if (_hz_cells[key] as Rect2).has_point(pos):
			var gxy := _key_to_gxy(key)
			if gxy.x != _hover_gx or gxy.y != _hover_gy:
				_hover_gx = gxy.x; _hover_gy = gxy.y; queue_redraw()
			return
	if _hover_gx != -1 or _hover_gy != -1:
		_hover_gx = -1; _hover_gy = -1; queue_redraw()


func _handle_tap(pos: Vector2) -> void:
	# Botão Voltar
	if BTN_BACK.has_point(pos): fechar(); return

	# Botão Loja
	if BTN_SHOP.has_point(pos):
		_state = State.IDLE if _state == State.SHOP else State.SHOP
		_sel_key = ""; _place_tipo = ""; queue_redraw(); return

	# Modo PLACING → colocar edifício
	if _state == State.PLACING:
		for key in _hz_cells.keys():
			if (_hz_cells[key] as Rect2).has_point(pos):
				var gxy := _key_to_gxy(key)
				if _building_at(gxy.x, gxy.y).is_empty():
					_construir(key, _place_tipo)
				_state = State.IDLE; _place_tipo = ""; _hover_gx=-1; _hover_gy=-1
				queue_redraw(); return
		return

	# Modo MOVING → mover edifício para nova célula
	if _state == State.MOVING:
		for key in _hz_cells.keys():
			if (_hz_cells[key] as Rect2).has_point(pos):
				var gxy := _key_to_gxy(key)
				if _building_at(gxy.x, gxy.y).is_empty() and key != _move_src:
					_mover_edificio(_move_src, key)
				_state = State.SELECTED; _sel_key = _move_src; _move_src = ""
				_hover_gx=-1; _hover_gy=-1; queue_redraw(); return
		return

	# Botões de opção
	if _state == State.SELECTED:
		for btn in _hz_opt_btns:
			if (btn["rect"] as Rect2).has_point(pos):
				_executar_acao(btn["acao"] as String); return

	# Cards da loja
	if _state == State.SHOP:
		for card in _hz_shop_cards:
			if (card["rect"] as Rect2).has_point(pos):
				_state = State.PLACING; _place_tipo = card["tipo"] as String
				_hover_gx=-1; _hover_gy=-1; queue_redraw(); return
		_state = State.IDLE; queue_redraw(); return

	# Células do mapa
	for key in _hz_cells.keys():
		if (_hz_cells[key] as Rect2).has_point(pos):
			if _state == State.SELECTED and key == _sel_key:
				_state = State.IDLE; _sel_key = ""
			else:
				var gxy := _key_to_gxy(key)
				if not _building_at(gxy.x, gxy.y).is_empty():
					_state = State.SELECTED; _sel_key = key
				else:
					_state = State.IDLE; _sel_key = ""
			queue_redraw(); return

	_state = State.IDLE; _sel_key = ""; queue_redraw()


# ══════════════════════════════════════════════════════════════════════════════
#  AÇÕES
# ══════════════════════════════════════════════════════════════════════════════
func _construir(slot_key: String, tipo: String) -> void:
	if Salvar.mana_cidade < CUSTO_BUILD: return
	Salvar.mana_cidade -= CUSTO_BUILD
	Salvar.cidade_slots[slot_key] = {"tipo": tipo, "nivel": 1, "hp": MAX_HP[0]}
	Salvar.salvar()


func _mover_edificio(src: String, dst: String) -> void:
	if not Salvar.cidade_slots.has(src): return
	Salvar.cidade_slots[dst] = Salvar.cidade_slots[src]
	Salvar.cidade_slots.erase(src)
	_sel_key = dst
	Salvar.salvar()


func _executar_acao(acao: String) -> void:
	if _sel_key == "": return
	var gxy  := _key_to_gxy(_sel_key)
	var data  = _building_at(gxy.x, gxy.y)
	if data.is_empty(): _state = State.IDLE; return

	match acao:
		"mover":
			_move_src = _sel_key
			_state    = State.MOVING
			_hover_gx = -1; _hover_gy = -1

		"upgrade":
			var nivel : int = int(data.get("nivel", 1))
			if nivel >= 3: return
			var custo : int = CUSTOS_UP[nivel]
			if Salvar.mana_cidade < custo: return
			Salvar.mana_cidade -= custo
			data["nivel"] = nivel + 1
			data["hp"]    = MAX_HP[nivel]
			Salvar.cidade_slots[_sel_key] = data
			Salvar.salvar()

		"treinar":
			if Salvar.mana_cidade < CUSTO_TREINAR: return
			if Salvar.quartel_soldados >= MAX_SOLDADOS: return
			Salvar.mana_cidade -= CUSTO_TREINAR
			Salvar.quartel_soldados = mini(Salvar.quartel_soldados + 10, MAX_SOLDADOS)
			Salvar.salvar()

		"atacar":
			if Salvar.mana_cidade < CUSTO_ATACAR: return
			Salvar.mana_cidade -= CUSTO_ATACAR
			Salvar.arsenal_carregado = true
			Salvar.salvar()

		"decarregar":
			# Cancela bombardeio carregado, devolve metade do custo
			Salvar.arsenal_carregado = false
			Salvar.mana_cidade += CUSTO_ATACAR / 2
			Salvar.salvar()

		"reparar":
			if Salvar.mana_cidade < CUSTO_REPAIR: return
			Salvar.mana_cidade -= CUSTO_REPAIR
			data["hp"] = _max_hp(data)
			Salvar.cidade_slots[_sel_key] = data
			Salvar.salvar()

		"demolir":
			Salvar.mana_cidade += 10
			Salvar.cidade_slots.erase(_sel_key)
			_state = State.IDLE; _sel_key = ""
			Salvar.salvar()

	if acao != "mover":
		queue_redraw()
