extends Control
## Mini Cidade — Vila estilo Clash of Clans (Fase 1)
## Ref: developers-hub-org/clash-of-clans-clone
##
##  ▸ Grid ISOMÉTRICO (losango, vista 3/4) — igual ao CoC
##  ▸ Recursos completos: Ouro · Elixir · Elixir Escuro · Gemas (via CocSalvar)
##  ▸ Coletores produzem ao longo do tempo, depósitos limitam capacidade
##  ▸ Loja de construção categorizada (recurso/defesa/exército/outro)
##  ▸ Quartel treina tropas de verdade (fila com timer)
##  ▸ Popup de edifício: mover / upgrade / reparar / coletar / demolir / acelerar
##  ▸ Construtores limitados (igual CoC)
##
##  Dados/definições  : res://scripts/coc/coc_dados.gd   (const DADOS)
##  Estado/persistência: autoload CocSalvar → coc_save.json
##
##  FASE 2 (não implementado aqui): torre atirando, naves 24h, batalha, pesquisa.
##  Os métodos aplicar_bonus_torre / on_mob_morreu / on_fim_wave são preservados
##  intactos para o main.gd não quebrar (economia de mana via Salvar, intocada).

signal fechado

const DADOS = preload("res://scripts/coc/coc_dados.gd")

# ══════════════════════════════════════════════════════════════════════════════
#  GRID ISOMÉTRICO
# ══════════════════════════════════════════════════════════════════════════════
const GRID_N  : int   = 14        # grade N×N
const TILE_W  : float = 76.0      # largura do losango
const TILE_H  : float = 38.0      # altura do losango (2:1)
const ORIGIN_Y: float = 96.0      # deslocamento vertical do topo do grid

# DEBUG: dinheiro infinito na cidade (deixar false pra produção)
const DINHEIRO_INFINITO : bool = true

# ══════════════════════════════════════════════════════════════════════════════
#  UI Layout
# ══════════════════════════════════════════════════════════════════════════════
const TOP_H : float = 66.0
const BOT_H : float = 58.0

# ══════════════════════════════════════════════════════════════════════════════
#  ESTADO
# ══════════════════════════════════════════════════════════════════════════════
enum State { IDLE, SHOP, PLACING, SELECTED, MOVING, TRAIN }

var _state      : State  = State.IDLE
var _shop_cat   : String = "recurso"
var _sel_key    : String = ""
var _move_src   : String = ""
var _place_tipo : String = ""
var _train_key  : String = ""    # quartel aberto no painel de treino
var _hover_gx   : int    = -1
var _hover_gy   : int    = -1
var _pulse      : float  = 0.0
var _ui_ref     : Node   = null

# ── Hit-zones (preenchidas no _draw, consumidas no tap) ───────────────────────
var _hz_shop   : Array = []
var _hz_opt    : Array = []
var _hz_train  : Array = []
var _hz_fixed  : Array = []
var _hz_builds : Array = []   # [{rect, key}] área clicável de cada prédio (corpo do sprite)

# ── Notificações ──────────────────────────────────────────────────────────────
var _noticias : Array = []   # [{msg, cor, t}]

# ── Sprites ───────────────────────────────────────────────────────────────────
var _sprites : Dictionary = {}

# ══════════════════════════════════════════════════════════════════════════════
#  READY
# ══════════════════════════════════════════════════════════════════════════════
func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	z_index      = 50
	visible      = false
	mouse_filter = Control.MOUSE_FILTER_STOP
	process_mode = Node.PROCESS_MODE_ALWAYS
	# Sprites próprios (SVG) por tipo — gerados em tools/gen_sprites_coc.py
	for tipo in ["prefeitura","mina_ouro","deposito_ouro","coletor_elixir","deposito_elixir",
				 "mina_escura","deposito_escuro","quartel","quartel_escuro","acampamento",
				 "fabrica_feitico","fabrica_escura","laboratorio","canhao","torre_arqueiros",
				 "morteiro","def_aerea","torre_mago","tesla","xbow","muralha",
				 "cabana_construtor","castelo_cla","altar_rei","altar_rainha"]:
		_sprites[tipo] = _load_sprite("res://assets/cidade/coc/%s.svg" % tipo)

func _load_sprite(path: String) -> Texture2D:
	if ResourceLoader.exists(path): return load(path) as Texture2D
	return null

# ══════════════════════════════════════════════════════════════════════════════
#  API PÚBLICA  (contrato com main.gd — NÃO mudar assinaturas)
# ══════════════════════════════════════════════════════════════════════════════
func abrir(ui_node: Node = null) -> void:
	_ui_ref = ui_node
	CocSalvar.carregar()
	CocSalvar.init_vila_padrao()
	visible    = true
	_state     = State.IDLE
	_shop_cat  = "recurso"
	_sel_key   = ""; _move_src = ""; _place_tipo = ""; _train_key = ""
	_hover_gx  = -1; _hover_gy = -1
	get_tree().paused = true
	if is_instance_valid(ui_node): ui_node.visible = false
	queue_redraw()

func fechar() -> void:
	CocSalvar.salvar()
	visible = false
	get_tree().paused = false
	if is_instance_valid(_ui_ref): _ui_ref.visible = true
	emit_signal("fechado")

func notificar(msg: String, cor: Color = Color.WHITE) -> void:
	_noticias.append({"msg": msg, "cor": cor, "t": 3.0})

# ── FASE 2 — preservados intactos (economia de mana via Salvar) ───────────────
func aplicar_bonus_torre(torre: Node) -> void:
	if not is_instance_valid(torre): return
	torre.damage      += Salvar.cidade_bonus_dano()
	torre.fire_rate   += Salvar.cidade_bonus_fr()
	torre.range_r     += Salvar.cidade_bonus_range()
	torre.pierce_count = mini(int(torre.get("pierce_count")) + Salvar.cidade_bonus_pierce(), 3)
	if Salvar.arsenal_carregado:
		torre.fire_rate += 0.8
		Salvar.arsenal_carregado = false
		Salvar.salvar()

func on_mob_morreu(ui_node: Node, total_kills: int) -> void:
	Salvar.mana_cidade += 1 + Salvar.cidade_bonus_mana()
	if total_kills % 5 == 0 and is_instance_valid(ui_node) \
			and ui_node.has_method("atualizar_mana_cidade"):
		ui_node.call("atualizar_mana_cidade", Salvar.mana_cidade)

func on_fim_wave(wave: int, ui_node: Node) -> void:
	var mana_moinho : int = 0
	for sd in Salvar.cidade_slots.values():
		if (sd as Dictionary).get("tipo","") == "moinho" and int((sd as Dictionary).get("hp",0)) > 0:
			match int((sd as Dictionary).get("nivel",1)):
				1: mana_moinho += 3
				2: mana_moinho += 6
				3: mana_moinho += 10
	if mana_moinho > 0:
		Salvar.mana_cidade += mana_moinho
		if is_instance_valid(ui_node) and ui_node.has_method("mostrar_notificacao_consumivel"):
			ui_node.mostrar_notificacao_consumivel(
				"Moinho gerou +%d mana" % mana_moinho, Color(0.55, 0.95, 0.45))

# ══════════════════════════════════════════════════════════════════════════════
#  PROCESS
# ══════════════════════════════════════════════════════════════════════════════
func _process(delta: float) -> void:
	if not visible: return
	_pulse += delta * 3.5

	if DINHEIRO_INFINITO:
		CocSalvar.ouro   = 99000000
		CocSalvar.elixir = 99000000
		CocSalvar.escuro = 99000000
		CocSalvar.gemas  = 99000000

	CocSalvar.tick_recursos(delta)
	var concluidos := CocSalvar.tick_construcoes()
	for c in concluidos:
		var tnome : String = (DADOS.EDIFICIOS.get((c as Dictionary).get("tipo",""),{}) as Dictionary).get("nome","?")
		notificar("✓ %s N%d pronto!" % [tnome, (c as Dictionary).get("nivel",1)], Color(0.5,1.0,0.4))
	var prontos := CocSalvar.tick_treino()
	for tipo in prontos:
		notificar("Tropa pronta: %s" % (DADOS.TROPAS.get(tipo,{}) as Dictionary).get("nome","?"),
				  Color(0.4,0.85,1.0))

	# Notificações decaem
	var remover_n : Array = []
	for n in _noticias:
		(n as Dictionary)["t"] = float((n as Dictionary).get("t",0.0)) - delta
		if float((n as Dictionary).get("t",0.0)) <= 0.0: remover_n.append(n)
	for n in remover_n: _noticias.erase(n)

	queue_redraw()

# ══════════════════════════════════════════════════════════════════════════════
#  MATEMÁTICA ISOMÉTRICA
# ══════════════════════════════════════════════════════════════════════════════
func _iso_origin() -> Vector2:
	var vp := get_viewport().get_visible_rect().size
	return Vector2(vp.x * 0.5, TOP_H + ORIGIN_Y)

func _cell_center(gx: int, gy: int) -> Vector2:
	var o := _iso_origin()
	return Vector2(
		o.x + float(gx - gy) * TILE_W * 0.5,
		o.y + float(gx + gy) * TILE_H * 0.5)

func _cell_center_o(o: Vector2, gx: int, gy: int) -> Vector2:
	return Vector2(
		o.x + float(gx - gy) * TILE_W * 0.5,
		o.y + float(gx + gy) * TILE_H * 0.5)

func _screen_to_cell(pos: Vector2) -> Vector2i:
	var o  := _iso_origin()
	var dx := pos.x - o.x
	var dy := pos.y - o.y
	var fa := dx / (TILE_W * 0.5)
	var fb := dy / (TILE_H * 0.5)
	var gx := int(floor((fb + fa) * 0.5))
	var gy := int(floor((fb - fa) * 0.5))
	return Vector2i(gx, gy)

func _diamond_pts(c: Vector2) -> PackedVector2Array:
	return PackedVector2Array([
		Vector2(c.x,               c.y - TILE_H * 0.5),
		Vector2(c.x + TILE_W * 0.5, c.y),
		Vector2(c.x,               c.y + TILE_H * 0.5),
		Vector2(c.x - TILE_W * 0.5, c.y),
	])

func _cell_key(gx: int, gy: int) -> String:
	return "%d,%d" % [gx, gy]

func _key_to_gxy(key: String) -> Vector2i:
	var p := key.split(",")
	if p.size() < 2: return Vector2i(-999, -999)
	return Vector2i(int(p[0]), int(p[1]))

func _em_grid(gx: int, gy: int) -> bool:
	return gx >= 0 and gx < GRID_N and gy >= 0 and gy < GRID_N

# ══════════════════════════════════════════════════════════════════════════════
#  DRAW PRINCIPAL
# ══════════════════════════════════════════════════════════════════════════════
func _draw() -> void:
	_hz_shop.clear(); _hz_opt.clear(); _hz_train.clear(); _hz_fixed.clear(); _hz_builds.clear()

	var vp := get_viewport().get_visible_rect().size
	draw_rect(Rect2(Vector2.ZERO, vp), Color(0.05,0.08,0.11,1.0))

	_draw_terreno()
	_draw_edificios()
	_draw_ghost()

	_draw_top_bar(vp)
	_draw_bottom(vp)

	if _state == State.SHOP:     _draw_loja(vp)
	if _state == State.TRAIN:    _draw_treino(vp)
	if _state == State.SELECTED and _sel_key != "": _draw_popup(vp)

	_draw_noticias(vp)

# ── Terreno isométrico ────────────────────────────────────────────────────────
func _draw_terreno() -> void:
	var o := _iso_origin()
	for gy in range(GRID_N):
		for gx in range(GRID_N):
			var c   := _cell_center_o(o, gx, gy)
			var pts := _diamond_pts(c)
			# Grama com variação por hash
			var h := (gx * 7 + gy * 13) % 11
			var base := Color(0.16,0.40,0.15)
			if h < 3:   base = Color(0.18,0.44,0.16)
			elif h > 8: base = Color(0.14,0.36,0.13)
			draw_colored_polygon(pts, base)
			draw_polyline(_fechar_poly(pts), Color(0.10,0.24,0.10,0.55), 1.0)

			# Highlight de colocação/movimento
			if _state in [State.PLACING, State.MOVING] and gx == _hover_gx and gy == _hover_gy:
				var livre : bool = CocSalvar.slot(_cell_key(gx,gy)).is_empty()
				draw_colored_polygon(pts, Color(0.2,1.0,0.4,0.30) if livre else Color(1.0,0.2,0.2,0.30))
				draw_polyline(_fechar_poly(pts),
					Color(0.3,1.0,0.5,0.9) if livre else Color(1.0,0.3,0.3,0.9), 2.0)

func _fechar_poly(pts: PackedVector2Array) -> PackedVector2Array:
	var r := PackedVector2Array(pts)
	r.append(pts[0])
	return r

# ── Edifícios (ordenados por profundidade gx+gy) ─────────────────────────────
func _draw_edificios() -> void:
	var o := _iso_origin()
	var ordem : Array = []
	for key in CocSalvar.slots.keys():
		var gxy := _key_to_gxy(key)
		ordem.append({"key": key, "depth": gxy.x + gxy.y, "gx": gxy.x, "gy": gxy.y})
	ordem.sort_custom(func(a, b): return int(a["depth"]) < int(b["depth"]))

	for e in ordem:
		var key := e["key"] as String
		var gx  := int(e["gx"]); var gy := int(e["gy"])
		var c   := _cell_center_o(o, gx, gy)
		_draw_edificio(c, key, key == _sel_key)

func _draw_edificio(c: Vector2, key: String, sel: bool) -> void:
	var font := ThemeDB.fallback_font
	var d    := CocSalvar.slot(key)
	if d.is_empty(): return
	var tipo  := d.get("tipo","") as String
	var nivel : int = int(d.get("nivel",1))
	var hp    : int = int(d.get("hp",0))
	var hp_m  : int = DADOS.hp_max(tipo, nivel)
	var ef    := DADOS.EDIFICIOS.get(tipo,{}) as Dictionary
	var cor   := ef.get("cor",Color.WHITE) as Color
	var central := ef.get("central",false) as bool

	# Sombra elíptica (losango achatado escuro)
	var shadow := PackedVector2Array([
		Vector2(c.x,               c.y - TILE_H*0.22),
		Vector2(c.x + TILE_W*0.42, c.y),
		Vector2(c.x,               c.y + TILE_H*0.22),
		Vector2(c.x - TILE_W*0.42, c.y),
	])
	draw_colored_polygon(shadow, Color(0,0,0,0.28))

	# Base destacada se selecionado
	if sel:
		var pts := _diamond_pts(c)
		draw_colored_polygon(pts, Color(cor.r,cor.g,cor.b,0.22 + sin(_pulse)*0.10))
		draw_polyline(_fechar_poly(pts), Color(cor.r,cor.g,cor.b,0.95), 2.5)

	# Sprite (ancorado pela base, sobe do tile)
	var tex := _sprites.get(tipo,null) as Texture2D
	var ts  : float = TILE_W * (1.35 if central else 1.05)
	var click_r : Rect2
	if tex:
		var w := ts
		var hh := ts * (float(tex.get_height()) / float(maxi(tex.get_width(),1)))
		click_r = Rect2(c.x - w*0.5, c.y + TILE_H*0.25 - hh, w, hh)
		draw_texture_rect(tex, click_r, false)
	else:
		# fallback: bloco colorido
		draw_colored_polygon(_diamond_pts(c), Color(cor.r*0.6,cor.g*0.6,cor.b*0.6,0.9))
		click_r = Rect2(c.x - TILE_W*0.5, c.y - TILE_H*0.5, TILE_W, TILE_H)
	# Área clicável = corpo do prédio + o tile (mais fácil de acertar)
	var tile_r := Rect2(c.x - TILE_W*0.5, c.y - TILE_H*0.5, TILE_W, TILE_H)
	_hz_builds.append({"rect": click_r.merge(tile_r), "key": key})

	# Nível (pontos)
	for li in range(int(ef.get("max_nivel",3))):
		var dc := cor if li < nivel else Color(cor.r,cor.g,cor.b,0.20)
		draw_circle(Vector2(c.x - 10 + float(li)*9, c.y - TILE_H*0.5 - 6), 3.5, dc)

	# Barra de HP
	if hp_m > 0:
		var hf : float = clampf(float(hp)/float(maxi(hp_m,1)), 0.0, 1.0)
		var bw := TILE_W * 0.7
		var bx := c.x - bw*0.5
		var by := c.y - TILE_H*0.5 - 14
		draw_rect(Rect2(bx,by,bw,4), Color(0.05,0.05,0.05,0.85))
		var hc := Color(0.2,1.0,0.45) if hf>0.5 else (Color(1.0,0.8,0.15) if hf>0.25 else Color(1.0,0.22,0.22))
		draw_rect(Rect2(bx,by,bw*hf,4), hc)

	# Acúmulo de recurso (coletor) — bolha "!"
	var cap_rec := ef.get("cap_recurso",[]) as Array
	if cap_rec.size() > 0:
		var acum := CocSalvar.slot_acum(key)
		var cap_v : float = float(int(cap_rec[clampi(nivel-1,0,cap_rec.size()-1)]))
		var fill  : float = clampf(acum/maxf(cap_v,1.0), 0.0, 1.0)
		if fill >= 0.95:
			var bp := Vector2(c.x + TILE_W*0.28, c.y - TILE_H*0.5 - 22)
			draw_circle(bp, 10.0 + sin(_pulse)*1.5, Color(1.0,0.85,0.10,0.95))
			draw_string(font, bp - Vector2(3,-5), "!", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(0,0,0))

	# Em construção: overlay + timer
	if CocSalvar.slot_em_construcao(key):
		draw_colored_polygon(_diamond_pts(c), Color(0,0,0,0.5))
		var fim_ms := _fim_construcao(key)
		if fim_ms > 0:
			var rest := maxi(0, (fim_ms - Time.get_ticks_msec())/1000)
			draw_string(font, c - Vector2(16,0), "🔨", HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color(1.0,0.8,0.2))
			draw_string(font, c + Vector2(-16,16), _fmt_tempo(rest), HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color(1,0.9,0.5))

func _fim_construcao(key: String) -> int:
	for c in CocSalvar.construcoes:
		if (c as Dictionary).get("key","") == key:
			return int((c as Dictionary).get("fim_ms",0))
	return 0

# ── Ghost (preview de colocação) ──────────────────────────────────────────────
func _draw_ghost() -> void:
	if not (_state in [State.PLACING, State.MOVING]): return
	if _hover_gx < 0 or not _em_grid(_hover_gx, _hover_gy): return
	var c := _cell_center(_hover_gx, _hover_gy)
	var tipo := _place_tipo if _state == State.PLACING else CocSalvar.slot_tipo(_move_src)
	var tex := _sprites.get(tipo, null) as Texture2D
	if tex:
		var w := TILE_W * 1.05
		var hh := w * (float(tex.get_height())/float(maxi(tex.get_width(),1)))
		draw_texture_rect(tex, Rect2(c.x - w*0.5, c.y + TILE_H*0.25 - hh, w, hh), false, Color(1,1,1,0.55))

# ══════════════════════════════════════════════════════════════════════════════
#  TOP BAR — recursos
# ══════════════════════════════════════════════════════════════════════════════
func _draw_top_bar(vp: Vector2) -> void:
	var font := ThemeDB.fallback_font
	draw_rect(Rect2(0,0,vp.x,TOP_H), Color(0.03,0.04,0.08,0.97))
	draw_line(Vector2(0,TOP_H), Vector2(vp.x,TOP_H), Color(0.25,0.45,0.80,0.50), 1.5)

	_badge(font, 10,  "🥇 %d/%d" % [CocSalvar.ouro,   CocSalvar.cap_ouro()],   Color(1.0,0.85,0.10), 180)
	_badge(font, 196, "💜 %d/%d" % [CocSalvar.elixir, CocSalvar.cap_elixir()], Color(0.88,0.38,1.0), 180)
	_badge(font, 382, "🌑 %d/%d" % [CocSalvar.escuro, CocSalvar.cap_escuro()], Color(0.55,0.30,0.80), 180)
	_badge(font, 568, "💎 %d" % CocSalvar.gemas, Color(0.20,0.90,0.55), 110)
	var cl := CocSalvar.construtores_livres()
	_badge(font, 684, "🔨 %d/%d" % [cl, CocSalvar.construtores_total],
		   Color(0.85,0.55,0.22) if cl>0 else Color(1.0,0.30,0.30), 110)

func _badge(font: Font, x: float, txt: String, cor: Color, w: float) -> void:
	draw_rect(Rect2(x,10,w,44), Color(cor.r*0.06,cor.g*0.06,cor.b*0.06,0.95))
	draw_rect(Rect2(x,10,w,44), Color(cor.r,cor.g,cor.b,0.45), false, 1.5)
	draw_string(font, Vector2(x+6,36), txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 16, cor)

# ══════════════════════════════════════════════════════════════════════════════
#  BOTTOM — botões fixos
# ══════════════════════════════════════════════════════════════════════════════
func _draw_bottom(vp: Vector2) -> void:
	var font := ThemeDB.fallback_font
	var by := vp.y - BOT_H
	draw_rect(Rect2(0,by,vp.x,BOT_H), Color(0.03,0.04,0.08,0.97))
	draw_line(Vector2(0,by), Vector2(vp.x,by), Color(0.25,0.45,0.80,0.50), 1.5)

	# LOJA
	var loja_r := Rect2(20, by+9, 150, BOT_H-18)
	var loja_on : bool = _state == State.SHOP
	draw_rect(loja_r, Color(0.10,0.18,0.30,0.95) if loja_on else Color(0.06,0.10,0.18,0.85))
	draw_rect(loja_r, Color(0.40,0.65,1.0,0.8), false, 2.0)
	draw_string(font, Vector2(loja_r.position.x+28, loja_r.position.y+30), "🛒 LOJA",
				HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color(0.85,0.93,1.0))
	_hz_fixed.append({"rect":loja_r,"acao":"loja"})

	# FECHAR
	var fch_r := Rect2(vp.x-150, by+9, 130, BOT_H-18)
	draw_rect(fch_r, Color(0.25,0.08,0.08,0.95))
	draw_rect(fch_r, Color(1.0,0.3,0.3,0.7), false, 2.0)
	draw_string(font, Vector2(fch_r.position.x+24, fch_r.position.y+30), "✕ SAIR",
				HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color(1.0,0.6,0.6))
	_hz_fixed.append({"rect":fch_r,"acao":"fechar"})

	# Dica de modo
	if _state == State.PLACING:
		var ef := DADOS.EDIFICIOS.get(_place_tipo,{}) as Dictionary
		draw_string(font, Vector2(vp.x*0.5-200, by+34),
			"Clique numa célula para colocar %s  (ESC cancela)" % ef.get("nome","?"),
			HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color(0.78,1.0,0.6))
	elif _state == State.MOVING:
		draw_string(font, Vector2(vp.x*0.5-180, by+34),
			"Clique no destino  (ESC cancela)",
			HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color(1.0,0.9,0.4))

# ══════════════════════════════════════════════════════════════════════════════
#  LOJA
# ══════════════════════════════════════════════════════════════════════════════
func _draw_loja(vp: Vector2) -> void:
	var font := ThemeDB.fallback_font
	# painel
	var pr := Rect2(0, TOP_H, vp.x, vp.y - TOP_H - BOT_H)
	draw_rect(pr, Color(0.04,0.05,0.10,0.96))

	# categorias
	var cats  : Array = ["recurso","defesa","exercito","outro"]
	var nomes : Array = ["RECURSOS","DEFESA","EXÉRCITO","OUTROS"]
	var ctw := (vp.x-40.0)/float(cats.size())
	for ci in range(cats.size()):
		var cr := Rect2(20+float(ci)*ctw, TOP_H+8, ctw-8, 38)
		var on : bool = _shop_cat == cats[ci]
		draw_rect(cr, Color(0.12,0.18,0.28,0.95) if on else Color(0.06,0.08,0.15,0.8))
		draw_rect(cr, Color(0.40,0.65,1.0,0.8) if on else Color(0.20,0.30,0.50,0.4), false, 2.0)
		draw_string(font, Vector2(cr.get_center().x-float(nomes[ci].length())*5.0, cr.position.y+26),
					nomes[ci], HORIZONTAL_ALIGNMENT_LEFT, -1, 14,
					Color(0.9,0.96,1.0) if on else Color(0.55,0.65,0.8))
		_hz_shop.append({"rect":cr,"acao":"cat","cat":cats[ci]})

	# cards
	var CW := 168.0; var CH := 200.0; var CG := 10.0
	var items : Array = []
	for k in DADOS.EDIFICIOS.keys():
		if (DADOS.EDIFICIOS[k] as Dictionary).get("cat","") == _shop_cat:
			items.append(k)

	var cx0 := 24.0; var cy0 := TOP_H + 58.0
	var col := 0
	var max_col := int((vp.x - 48.0) / (CW + CG))
	max_col = maxi(max_col, 1)
	var row := 0
	var construtores_livres := CocSalvar.construtores_livres()

	for idx in range(items.size()):
		var tipo := items[idx] as String
		var ef   := DADOS.EDIFICIOS[tipo] as Dictionary
		var cor  := ef.get("cor",Color.WHITE) as Color
		var cr   := Rect2(cx0 + float(col)*(CW+CG), cy0 + float(row)*(CH+CG), CW, CH)

		var co := int(ef.get("custo_ouro",0))
		var ce := int(ef.get("custo_elixir",0))
		var cd := int(ef.get("custo_escuro",0))
		var pode_pagar : bool = CocSalvar.tem_ouro(co) and CocSalvar.tem_elixir(ce) and CocSalvar.tem_escuro(cd)
		var tem_slot   : bool = _tem_slot_vazio()
		var tem_constr : bool = construtores_livres > 0
		var central    : bool = ef.get("central",false) as bool
		var ja_tem     : bool = central and CocSalvar._tem_tipo(tipo)
		var pode       : bool = pode_pagar and tem_slot and tem_constr and not ja_tem

		var alpha : float = 1.0 if pode else 0.35
		draw_rect(cr, Color(cor.r*0.12,cor.g*0.12,cor.b*0.12,0.92))
		draw_rect(cr, Color(cor.r,cor.g,cor.b,0.72 if pode else 0.18), false, 2.5)
		if not pode: draw_rect(cr, Color(0,0,0,0.45))

		var tex := _sprites.get(tipo,null) as Texture2D
		var ccx := cr.get_center().x
		if tex:
			var ts := CW*0.6
			var hh := ts * (float(tex.get_height())/float(maxi(tex.get_width(),1)))
			draw_texture_rect(tex, Rect2(ccx-ts*0.5, cr.position.y+12, ts, hh), false, Color(1,1,1,alpha))
		draw_string(font, Vector2(ccx-float((ef.get("nome","") as String).length())*4.5, cr.position.y+CH*0.62),
					ef.get("nome","") as String, HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color(1,1,1,0.95 if pode else 0.38))

		var custo_str := ""
		if co > 0: custo_str += "%d🥇 " % co
		if ce > 0: custo_str += "%d💜 " % ce
		if cd > 0: custo_str += "%d🌑 " % cd
		if custo_str == "": custo_str = "GRÁTIS"
		draw_string(font, Vector2(ccx-float(custo_str.length())*4.0, cr.position.y+CH*0.62+20),
					custo_str, HORIZONTAL_ALIGNMENT_LEFT, -1, 12,
					Color(0.28,1.0,0.48) if pode else Color(1.0,0.28,0.28))

		var bdesc := ef.get("bonus_desc",[]) as Array
		if bdesc.size() > 0:
			draw_string(font, Vector2(cr.position.x+8, cr.position.y+CH*0.62+38), bdesc[0] as String,
						HORIZONTAL_ALIGNMENT_LEFT, CW-16, 11, Color(cor.r,cor.g,cor.b,0.75 if pode else 0.28))

		if ja_tem:
			draw_string(font, Vector2(ccx-32, cr.position.y+CH-12), "CONSTRUÍDO",
						HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color(0.5,0.55,0.5))
		elif not tem_constr:
			draw_string(font, Vector2(ccx-38, cr.position.y+CH-12), "SEM CONSTRUTOR",
						HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color(1.0,0.6,0.2,0.8))
		elif pode:
			_hz_shop.append({"rect":cr,"acao":"construir","tipo":tipo})

		col += 1
		if col >= max_col: col = 0; row += 1

# ══════════════════════════════════════════════════════════════════════════════
#  TREINO
# ══════════════════════════════════════════════════════════════════════════════
func _draw_treino(vp: Vector2) -> void:
	var font := ThemeDB.fallback_font
	var agora_ms := Time.get_ticks_msec()
	var pr := Rect2(0, TOP_H, vp.x, vp.y - TOP_H - BOT_H)
	draw_rect(pr, Color(0.04,0.06,0.12,0.96))

	# header
	draw_string(font, Vector2(20, TOP_H+34), "TREINAR TROPAS",
				HORIZONTAL_ALIGNMENT_LEFT, -1, 22, Color(0.8,0.95,1.0))
	var cap_t := CocSalvar.cap_tropas_total()
	var cap_u := CocSalvar.cap_tropas_usada()
	draw_string(font, Vector2(vp.x-260, TOP_H+34), "Espaço: %d/%d" % [cap_u, cap_t],
				HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color(0.7,0.9,0.7))

	# determinar quartel escuro?
	var q_tipo := CocSalvar.slot_tipo(_train_key)
	var escuro_q : bool = q_tipo == "quartel_escuro"

	var TW := 150.0; var TH := 104.0; var TG := 8.0
	var tx0 := 20.0; var ty := TOP_H + 56.0
	var col := 0
	var max_col := maxi(int((vp.x-40.0)/(TW+TG)), 1)

	for tipo in DADOS.TROPAS.keys():
		var td := DADOS.TROPAS[tipo] as Dictionary
		var qt := td.get("quartel_tipo","normal") as String
		var is_escuro : bool = qt == "escuro"
		if is_escuro != escuro_q: continue   # quartel normal só treina tropa normal e vice-versa

		var ce := int(td.get("custo_elixir",0))
		var cd := int(td.get("custo_escuro",0))
		var cap_livre := CocSalvar.cap_tropas_livre()
		var pode_pay : bool = (ce==0 or CocSalvar.tem_elixir(ce)) and (cd==0 or CocSalvar.tem_escuro(cd))
		var pode : bool = cap_livre >= int(td.get("cap",1)) and pode_pay

		var cr := Rect2(tx0 + float(col)*(TW+TG), ty, TW, TH)
		draw_rect(cr, Color(0.06,0.10,0.18,0.92))
		draw_rect(cr, Color(0.3,0.85,1.0,0.6 if pode else 0.18), false, 2.0)
		if not pode: draw_rect(cr, Color(0,0,0,0.4))

		var ccx := cr.get_center().x
		draw_string(font, Vector2(ccx-float((td.get("nome","") as String).length())*4.0, cr.position.y+16),
					td.get("nome","") as String, HORIZONTAL_ALIGNMENT_LEFT, -1, 13,
					Color(0.9,0.96,1.0,1.0 if pode else 0.4))
		draw_string(font, Vector2(cr.position.x+4, cr.position.y+32),
					"HP:%d  %ddps" % [int(td.get("hp",0)), int(td.get("dano_s",0))],
					HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color(0.7,0.8,0.9,0.8 if pode else 0.35))
		draw_string(font, Vector2(cr.position.x+4, cr.position.y+45),
					"Cap:%d  %ds" % [int(td.get("cap",1)), int(td.get("tempo_treino_s",60))],
					HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color(0.7,0.8,0.9,0.8 if pode else 0.35))
		var cs := ""
		if ce > 0: cs = "%d💜" % ce
		if cd > 0: cs = "%d🌑" % cd
		draw_string(font, Vector2(ccx-float(cs.length())*4.5, cr.position.y+62), cs,
					HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color(0.28,1.0,0.48,1.0 if pode else 0.25))
		if pode:
			var btn := Rect2(cr.position.x+TW-32, cr.position.y+TH-30, 28, 26)
			draw_rect(btn, Color(0.10,0.50,0.15,0.95))
			draw_rect(btn, Color(0.2,1.0,0.4,0.8), false, 2.0)
			draw_string(font, Vector2(btn.position.x+8, btn.position.y+18), "+",
						HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color(0.3,1.0,0.5))
			_hz_train.append({"rect":btn,"acao":"treinar","tipo":tipo})
		col += 1
		if col >= max_col: col = 0; ty += TH+TG

	# inventário de tropas prontas
	var inv_y := vp.y - BOT_H - 100.0
	draw_line(Vector2(0,inv_y), Vector2(vp.x,inv_y), Color(0.25,0.45,0.8,0.5), 1.5)
	draw_string(font, Vector2(12, inv_y+22), "PRONTAS:", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(0.7,0.85,1.0))
	var ix := 110.0
	for tipo in CocSalvar.tropas.keys():
		var cnt := int(CocSalvar.tropas[tipo])
		if cnt <= 0: continue
		var nome := (DADOS.TROPAS.get(tipo,{}) as Dictionary).get("nome","?") as String
		draw_string(font, Vector2(ix, inv_y+22), "%s×%d" % [nome,cnt],
					HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color(0.8,0.95,1.0))
		ix += float(nome.length()*8 + 30)

	# filas de treino ativas
	var fila_y := inv_y + 36.0
	var fx := 12.0
	for bk in CocSalvar.fila_treino.keys():
		var fila := CocSalvar.fila_treino[bk] as Array
		if fila.is_empty(): continue
		var item := fila[0] as Dictionary
		var resto := maxi(0, (int(item.get("fim_ms",0)) - agora_ms)/1000)
		var tipo := item.get("tipo","") as String
		var td := DADOS.TROPAS.get(tipo,{}) as Dictionary
		var total_s := int(td.get("tempo_treino_s",60))
		var pct := clampf(1.0 - float(resto)/float(maxi(total_s,1)), 0.0, 1.0)
		var prr := Rect2(fx, fila_y, 160, 26)
		draw_rect(prr, Color(0.05,0.10,0.20,0.95))
		draw_rect(Rect2(prr.position, Vector2(prr.size.x*pct, prr.size.y)), Color(0.1,0.5,0.9,0.7))
		draw_rect(prr, Color(0.28,0.65,1.0,0.6), false, 1.5)
		draw_string(font, Vector2(fx+4, fila_y+18), "%s %s" % [td.get("nome","?"), _fmt_tempo(resto)],
					HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(0.9,0.96,1.0))
		if fila.size() > 1:
			draw_string(font, Vector2(fx+136, fila_y+18), "+%d" % (fila.size()-1),
						HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color(0.6,0.75,1.0))
		fx += 170.0

# ══════════════════════════════════════════════════════════════════════════════
#  POPUP de edifício
# ══════════════════════════════════════════════════════════════════════════════
func _draw_popup(vp: Vector2) -> void:
	var font := ThemeDB.fallback_font
	var data := CocSalvar.slot(_sel_key)
	if data.is_empty(): _state = State.IDLE; return

	var gxy   := _key_to_gxy(_sel_key)
	var tipo  := data.get("tipo","") as String
	var nivel : int = int(data.get("nivel",1))
	var hp    : int = int(data.get("hp",0))
	var hp_m  : int = DADOS.hp_max(tipo, nivel)
	var ef    := DADOS.EDIFICIOS.get(tipo,{}) as Dictionary
	var cor   := ef.get("cor",Color.WHITE) as Color
	var max_n : int = int(ef.get("max_nivel",3))
	var central : bool = ef.get("central",false) as bool
	var heroi   : bool = ef.get("heroi",false) as bool
	var em_constr : bool = CocSalvar.slot_em_construcao(_sel_key)

	# montar botões
	var btns : Array = []
	if not em_constr:
		btns.append("mover")
		if nivel < max_n: btns.append("upgrade")
		if hp < hp_m:     btns.append("reparar")
		if tipo in ["mina_ouro","coletor_elixir","mina_escura"] and CocSalvar.slot_acum(_sel_key) >= 1.0:
			btns.append("coletar")
		if tipo == "quartel" or tipo == "quartel_escuro": btns.append("treinar")
		if not central and not heroi: btns.append("demolir")
	else:
		btns.append("acelerar")

	var BH := 40.0; var BG := 7.0
	var PW := 330.0
	var PH := 92.0 + float(btns.size())*(BH+BG)

	var c := _cell_center(gxy.x, gxy.y)
	var px := clampf(c.x - PW*0.5, 8.0, vp.x-PW-8)
	var py := clampf(c.y - PH - 40.0, TOP_H+4, vp.y-BOT_H-PH-4)
	var po := Vector2(px, py)

	draw_rect(Rect2(po, Vector2(PW,PH)), Color(0.04,0.05,0.10,0.97))
	draw_rect(Rect2(po, Vector2(PW,PH)), Color(cor.r,cor.g,cor.b,0.62), false, 3.0)

	# header
	var tex := _sprites.get(tipo,null) as Texture2D
	var icon_s : float = 64.0
	if tex:
		var hh := icon_s * (float(tex.get_height())/float(maxi(tex.get_width(),1)))
		draw_texture_rect(tex, Rect2(po+Vector2(8,6), Vector2(icon_s,hh)), false)
	var nome := ef.get("nome","") as String
	if central: nome = "★ " + nome + " ★"
	draw_string(font, po+Vector2(80,28), nome, HORIZONTAL_ALIGNMENT_LEFT, -1, 20, cor)
	draw_string(font, po+Vector2(80,50), "N%d   HP %d/%d" % [nivel,hp,hp_m],
				HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color(0.75,0.85,0.95))
	var bd := ef.get("bonus_desc",[]) as Array
	if bd.size() > 0:
		draw_string(font, po+Vector2(80,68), bd[clampi(nivel-1,0,bd.size()-1)] as String,
					HORIZONTAL_ALIGNMENT_LEFT, PW-90, 12, Color(cor.r,cor.g,cor.b,0.85))

	# botões
	var ay := po.y + 88.0
	for btn in btns:
		var br := Rect2(po.x+10, ay, PW-20, BH)
		var pode := true
		var label := ""
		match btn:
			"mover":   label = "↔ MOVER"; _opt_btn(br, label, Color(0.75,0.55,1.0))
			"upgrade":
				var co := DADOS.custo_upgrade(tipo, nivel, "ouro")
				var ce := DADOS.custo_upgrade(tipo, nivel, "elixir")
				var cd := DADOS.custo_upgrade(tipo, nivel, "escuro")
				pode = CocSalvar.tem_ouro(co) and CocSalvar.tem_elixir(ce) and CocSalvar.tem_escuro(cd) and CocSalvar.tem_construtor_livre()
				var cu := ""
				if co>0: cu += "%d🥇 " % co
				if ce>0: cu += "%d💜 " % ce
				if cd>0: cu += "%d🌑 " % cd
				_opt_btn(br, "▲ UPGRADE N%d→N%d  %s" % [nivel,nivel+1,cu], Color(0.28,0.68,1.0), pode)
			"reparar":
				var cr2 := hp_m/10
				pode = CocSalvar.tem_ouro(cr2)
				_opt_btn(br, "♥ REPARAR (%d ouro)" % cr2, Color(0.2,0.9,0.4), pode)
			"coletar":
				var acum := int(CocSalvar.slot_acum(_sel_key))
				_opt_btn(br, "⬇ COLETAR +%d" % acum, Color(1.0,0.85,0.1))
			"treinar":  _opt_btn(br, "⚔ TREINAR TROPAS", Color(0.3,0.85,1.0))
			"acelerar":
				pode = CocSalvar.tem_gemas(5)
				_opt_btn(br, "⚡ ACELERAR (5 💎)", Color(0.4,1.0,0.6), pode)
			"demolir":  _opt_btn(br, "✕ DEMOLIR (50% volta)", Color(1.0,0.28,0.28))
		if pode:
			_hz_opt.append({"rect":br,"acao":btn})
		ay += BH+BG

func _opt_btn(r: Rect2, label: String, cor: Color, ativo: bool = true) -> void:
	var font := ThemeDB.fallback_font
	draw_rect(r, Color(cor.r*0.10,cor.g*0.10,cor.b*0.10, 0.95 if ativo else 0.4))
	draw_rect(r, Color(cor.r,cor.g,cor.b, 0.72 if ativo else 0.18), false, 2.0)
	draw_string(font, Vector2(r.position.x+12, r.position.y+26), label,
				HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(cor.r,cor.g,cor.b, 1.0 if ativo else 0.3))

# ══════════════════════════════════════════════════════════════════════════════
#  NOTIFICAÇÕES
# ══════════════════════════════════════════════════════════════════════════════
func _draw_noticias(vp: Vector2) -> void:
	var font := ThemeDB.fallback_font
	var ny := TOP_H + 10.0
	for n in _noticias:
		var nd := n as Dictionary
		var t_f := float(nd.get("t",0.0))
		var a := clampf(t_f/0.5, 0.0, 1.0) * clampf(t_f, 0.0, 1.0)
		var cor := nd.get("cor",Color.WHITE) as Color
		var msg := nd.get("msg","") as String
		draw_string(font, Vector2(vp.x-12-float(msg.length())*8.5, ny), msg,
					HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color(cor.r,cor.g,cor.b,a))
		ny += 22.0

# ══════════════════════════════════════════════════════════════════════════════
#  INPUT
# ══════════════════════════════════════════════════════════════════════════════
func _input(event: InputEvent) -> void:
	if not visible: return

	if event is InputEventKey:
		var ev := event as InputEventKey
		if ev.pressed and ev.keycode == KEY_ESCAPE:
			match _state:
				State.PLACING: _state=State.IDLE; _place_tipo=""; _hover_gx=-1; _hover_gy=-1
				State.MOVING:  _state=State.SELECTED; _move_src=""
				State.SHOP:    _state=State.IDLE
				State.TRAIN:   _state=State.IDLE; _train_key=""
				State.SELECTED:_state=State.IDLE; _sel_key=""
				_: fechar()
			queue_redraw(); get_viewport().set_input_as_handled()
		return

	if event is InputEventMouseMotion:
		_update_hover((event as InputEventMouseMotion).position); return

	var pos : Vector2; var pressed := false
	if event is InputEventMouseButton:
		var ev := event as InputEventMouseButton
		if ev.button_index == MOUSE_BUTTON_LEFT and ev.pressed: pos = ev.position; pressed = true
	elif event is InputEventScreenTouch:
		var ev := event as InputEventScreenTouch
		if ev.pressed: pos = ev.position; pressed = true

	if pressed:
		_handle_tap(pos); get_viewport().set_input_as_handled()

func _update_hover(pos: Vector2) -> void:
	if not (_state in [State.PLACING, State.MOVING]): return
	var gxy := _screen_to_cell(pos)
	if _em_grid(gxy.x, gxy.y):
		if gxy.x != _hover_gx or gxy.y != _hover_gy:
			_hover_gx = gxy.x; _hover_gy = gxy.y; queue_redraw()
	elif _hover_gx != -1:
		_hover_gx = -1; _hover_gy = -1; queue_redraw()

func _handle_tap(pos: Vector2) -> void:
	# botões fixos sempre primeiro
	for h in _hz_fixed:
		if ((h as Dictionary)["rect"] as Rect2).has_point(pos):
			match (h as Dictionary).get("acao",""):
				"fechar": fechar()
				"loja":   _toggle_loja()
			return

	# painel da loja
	if _state == State.SHOP:
		for h in _hz_shop:
			var hd := h as Dictionary
			if not (hd["rect"] as Rect2).has_point(pos): continue
			if hd.get("acao","") == "cat":
				_shop_cat = hd.get("cat","recurso") as String; queue_redraw(); return
			if hd.get("acao","") == "construir":
				_state = State.PLACING; _place_tipo = hd.get("tipo","") as String
				_hover_gx = -1; _hover_gy = -1; queue_redraw(); return
		return

	# painel de treino
	if _state == State.TRAIN:
		for h in _hz_train:
			var hd := h as Dictionary
			if not (hd["rect"] as Rect2).has_point(pos): continue
			if hd.get("acao","") == "treinar":
				_treinar_tropa(hd.get("tipo","") as String); return
		return

	# popup de opções
	if _state == State.SELECTED:
		for h in _hz_opt:
			if ((h as Dictionary)["rect"] as Rect2).has_point(pos):
				_executar_acao((h as Dictionary).get("acao","") as String); return

	# colocação
	if _state == State.PLACING:
		var g := _screen_to_cell(pos)
		if _em_grid(g.x, g.y) and CocSalvar.slot(_cell_key(g.x,g.y)).is_empty():
			_construir(_cell_key(g.x,g.y), _place_tipo)
		_state = State.IDLE; _place_tipo = ""; _hover_gx = -1; _hover_gy = -1
		queue_redraw(); return

	# movimento
	if _state == State.MOVING:
		var g := _screen_to_cell(pos)
		if _em_grid(g.x, g.y):
			var nk := _cell_key(g.x,g.y)
			if CocSalvar.slot(nk).is_empty() and nk != _move_src:
				CocSalvar.slots[nk] = CocSalvar.slots[_move_src]
				CocSalvar.slots.erase(_move_src)
				_sel_key = nk; CocSalvar.salvar()
		_state = State.SELECTED; _move_src = ""; _hover_gx = -1; _hover_gy = -1
		queue_redraw(); return

	# seleção — testa corpo dos prédios primeiro (frontmost = último desenhado)
	for i in range(_hz_builds.size()-1, -1, -1):
		var hb := _hz_builds[i] as Dictionary
		if (hb["rect"] as Rect2).has_point(pos):
			var key := hb["key"] as String
			if _state == State.SELECTED and key == _sel_key:
				_state = State.IDLE; _sel_key = ""
			else:
				_state = State.SELECTED; _sel_key = key
			queue_redraw(); return

	# fallback: seleção pelo tile sob o cursor
	var gc := _screen_to_cell(pos)
	if _em_grid(gc.x, gc.y):
		var key := _cell_key(gc.x, gc.y)
		if not CocSalvar.slot(key).is_empty():
			if _state == State.SELECTED and key == _sel_key:
				_state = State.IDLE; _sel_key = ""
			else:
				_state = State.SELECTED; _sel_key = key
			queue_redraw(); return
	_state = State.IDLE; _sel_key = ""; queue_redraw()

func _toggle_loja() -> void:
	if _state == State.SHOP:
		_state = State.IDLE
	else:
		_state = State.SHOP; _sel_key = ""; _train_key = ""
	queue_redraw()

# ══════════════════════════════════════════════════════════════════════════════
#  AÇÕES
# ══════════════════════════════════════════════════════════════════════════════
func _construir(key: String, tipo: String) -> void:
	var ef := DADOS.EDIFICIOS.get(tipo,{}) as Dictionary
	var co := int(ef.get("custo_ouro",0))
	var ce := int(ef.get("custo_elixir",0))
	var cd := int(ef.get("custo_escuro",0))
	if not (CocSalvar.tem_ouro(co) and CocSalvar.tem_elixir(ce) and CocSalvar.tem_escuro(cd)): return
	if not CocSalvar.tem_construtor_livre(): return
	CocSalvar.ouro -= co; CocSalvar.elixir -= ce; CocSalvar.escuro -= cd
	CocSalvar.slots[key] = {"tipo":tipo,"nivel":1,"hp":0,"acum":0.0}
	var constr_s := int(ef.get("constr_s",30))
	if constr_s > 0:
		CocSalvar.construcoes.append({"key":key,"tipo":tipo,"nivel_alvo":1,
			"fim_ms":Time.get_ticks_msec()+constr_s*1000})
		notificar("Construindo %s..." % ef.get("nome","?"), Color(0.85,0.55,0.22))
	else:
		var hp_arr := ef.get("hp",[100,200,300]) as Array
		CocSalvar.slots[key]["hp"] = int(hp_arr[0])
		notificar("%s construído!" % ef.get("nome","?"), Color(0.5,1.0,0.4))
		if tipo == "cabana_construtor": CocSalvar.construtores_total += 1
	CocSalvar.salvar()

func _executar_acao(acao: String) -> void:
	if _sel_key == "": return
	var data := CocSalvar.slot(_sel_key)
	if data.is_empty(): _state = State.IDLE; return
	var tipo  := data.get("tipo","") as String
	var nivel : int = int(data.get("nivel",1))
	var ef    := DADOS.EDIFICIOS.get(tipo,{}) as Dictionary

	match acao:
		"mover":
			_move_src = _sel_key; _state = State.MOVING; _hover_gx=-1; _hover_gy=-1

		"upgrade":
			var max_n : int = int(ef.get("max_nivel",3))
			if nivel >= max_n: return
			var co := DADOS.custo_upgrade(tipo, nivel, "ouro")
			var ce := DADOS.custo_upgrade(tipo, nivel, "elixir")
			var cd := DADOS.custo_upgrade(tipo, nivel, "escuro")
			if not (CocSalvar.tem_ouro(co) and CocSalvar.tem_elixir(ce) and CocSalvar.tem_escuro(cd)): return
			if not CocSalvar.tem_construtor_livre(): return
			CocSalvar.ouro-=co; CocSalvar.elixir-=ce; CocSalvar.escuro-=cd
			var ts := DADOS.tempo_upgrade_s(tipo, nivel)
			data["hp"] = 0
			CocSalvar.slots[_sel_key] = data
			CocSalvar.construcoes.append({"key":_sel_key,"tipo":tipo,"nivel_alvo":nivel+1,
				"fim_ms":Time.get_ticks_msec()+ts*1000})
			notificar("Melhorando %s N%d..." % [ef.get("nome","?"),nivel+1], Color(0.28,0.68,1.0))
			CocSalvar.salvar()

		"reparar":
			var hp_m := DADOS.hp_max(tipo, nivel)
			var custo := hp_m/10
			if not CocSalvar.tem_ouro(custo): return
			CocSalvar.ouro -= custo
			data["hp"] = hp_m
			CocSalvar.slots[_sel_key] = data
			CocSalvar.salvar()

		"coletar":
			var ganho := CocSalvar.coletar(_sel_key)
			if ganho > 0: notificar("+%d coletado" % ganho, Color(1.0,0.85,0.1))

		"treinar":
			_train_key = _sel_key; _state = State.TRAIN; queue_redraw(); return

		"acelerar":
			if not CocSalvar.tem_gemas(5): return
			CocSalvar.gemas -= 5
			for c in CocSalvar.construcoes:
				if (c as Dictionary).get("key","") == _sel_key:
					(c as Dictionary)["fim_ms"] = Time.get_ticks_msec() - 1
			CocSalvar.salvar()
			notificar("Construção acelerada!", Color(0.4,1.0,0.6))

		"demolir":
			if ef.get("central",false) as bool or ef.get("heroi",false) as bool: return
			var co := int(int(ef.get("custo_ouro",0))*0.5)
			var ce := int(int(ef.get("custo_elixir",0))*0.5)
			var cd := int(int(ef.get("custo_escuro",0))*0.5)
			CocSalvar.ouro   = mini(CocSalvar.ouro+co,   CocSalvar.cap_ouro())
			CocSalvar.elixir = mini(CocSalvar.elixir+ce, CocSalvar.cap_elixir())
			CocSalvar.escuro = mini(CocSalvar.escuro+cd, CocSalvar.cap_escuro())
			CocSalvar.slots.erase(_sel_key)
			var rem : Array = []
			for c in CocSalvar.construcoes:
				if (c as Dictionary).get("key","") == _sel_key: rem.append(c)
			for c in rem: CocSalvar.construcoes.erase(c)
			if tipo == "cabana_construtor":
				CocSalvar.construtores_total = maxi(2, CocSalvar.construtores_total-1)
			_state = State.IDLE; _sel_key = ""
			CocSalvar.salvar()
			notificar("Edifício demolido.", Color(1.0,0.42,0.42))

	if acao != "mover" and acao != "treinar":
		queue_redraw()

func _treinar_tropa(tipo: String) -> void:
	var td := DADOS.TROPAS.get(tipo,{}) as Dictionary
	if td.is_empty(): return
	var ce := int(td.get("custo_elixir",0))
	var cd := int(td.get("custo_escuro",0))
	if ce > 0 and not CocSalvar.tem_elixir(ce): return
	if cd > 0 and not CocSalvar.tem_escuro(cd): return
	if CocSalvar.cap_tropas_livre() < int(td.get("cap",1)): return
	CocSalvar.elixir -= ce; CocSalvar.escuro -= cd

	var qt := "quartel" if td.get("quartel_tipo","")=="normal" else "quartel_escuro"
	var best_key := _quartel_melhor(qt)
	if best_key == "":
		CocSalvar.elixir += ce; CocSalvar.escuro += cd
		notificar("Nenhum quartel disponível!", Color(1.0,0.4,0.4)); return
	var fila := CocSalvar.fila_treino.get(best_key, []) as Array
	var agora_ms := Time.get_ticks_msec()
	var fim_ms : int
	if fila.is_empty():
		fim_ms = agora_ms + int(td.get("tempo_treino_s",60))*1000
	else:
		var ult := fila[-1] as Dictionary
		fim_ms = int(ult.get("fim_ms",agora_ms)) + int(td.get("tempo_treino_s",60))*1000
	fila.append({"tipo":tipo,"fim_ms":fim_ms})
	CocSalvar.fila_treino[best_key] = fila
	CocSalvar.salvar()
	notificar("Treinando %s..." % td.get("nome","?"), Color(0.3,0.85,1.0))

# ══════════════════════════════════════════════════════════════════════════════
#  HELPERS
# ══════════════════════════════════════════════════════════════════════════════
func _tem_slot_vazio() -> bool:
	for gy in range(GRID_N):
		for gx in range(GRID_N):
			if CocSalvar.slot(_cell_key(gx,gy)).is_empty(): return true
	return false

func _quartel_melhor(tipo: String) -> String:
	var best_key := ""; var menor_fila := 9999
	for key in CocSalvar.slots.keys():
		if CocSalvar.slot_tipo(key) != tipo: continue
		if CocSalvar.slot_em_construcao(key): continue
		var fs := (CocSalvar.fila_treino.get(key,[]) as Array).size()
		if fs < menor_fila: menor_fila = fs; best_key = key
	return best_key

func _fmt_tempo(s: int) -> String:
	if s >= 3600: return "%dh%02dm" % [s/3600, (s%3600)/60]
	if s >= 60:   return "%dm%02ds" % [s/60, s%60]
	return "%ds" % s
