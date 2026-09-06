extends RefCounted
## Módulo ISOLADO: Painel de Comando ("Núcleo").
## Trilhas de stat upadas com Energia ⚡ (per-run). UI própria no HUD.
## Carregado com guarda por main.gd via load() — se ESTE módulo falhar, o jogo
## segue sem ele (sem painel/energia) e NÃO trava a partida.

const ICONE_SCENE = preload("res://scripts/icone_upgrade.gd")

var jogo = null  # ref ao main.gd

const TRILHAS : Array = ["dano", "cadencia", "vida", "regen", "alcance", "crit", "critdano", "energia"]
# Por trilha:
#   modo "pct"         → soma base_stat * frac ao stat (efeito = id da trilha)
#   modo "regen_pct"   → soma base_VIDA * frac ao regen_rate (HP/s) — Vida ≠ Regen!
#   modo "crit_chance" → soma frac à chance de crítico (torre cap 0.75)
#   modo "crit_mult"   → soma frac ao multiplicador de crítico
# frac também é o passo mostrado no HUD (frac*100 por nível). suf = sufixo (% ou %/s).
# Custo (Energia) linear: base + nível*step.
const CFG : Dictionary = {
	"dano":     {"nome": "Dano",       "modo": "pct",         "frac": 0.05,  "cap": 120, "base": 6,  "step": 2, "icone": "dano",        "cor": Color(1.0, 0.45, 0.12)},
	"cadencia": {"nome": "Cadência",   "modo": "pct",         "frac": 0.02,  "cap": 80,  "base": 10, "step": 4, "icone": "cadencia",    "cor": Color(0.80, 0.30, 1.0)},
	"vida":     {"nome": "Vida",       "modo": "pct",         "frac": 0.04,  "cap": 120, "base": 5,  "step": 2, "icone": "vida",        "cor": Color(0.20, 1.0, 0.45)},
	"regen":    {"nome": "Regen",      "modo": "regen_pct",   "frac": 0.015, "cap": 60,  "base": 8,  "step": 3, "icone": "regeneracao", "cor": Color(0.40, 1.0,  0.65), "suf": "%/s"},
	"alcance":  {"nome": "Alcance",    "modo": "pct",         "frac": 0.02,  "cap": 25,  "base": 12, "step": 8, "icone": "alcance",     "cor": Color(0.20, 0.75, 1.0)},
	"crit":     {"nome": "Chance Crít","modo": "crit_chance", "frac": 0.005, "cap": 80,  "base": 14, "step": 5, "icone": "critico",     "cor": Color(1.0, 0.85, 0.25)},
	"critdano": {"nome": "Dano Crít",  "modo": "crit_mult",   "frac": 0.10,  "cap": 60,  "base": 16, "step": 6, "icone": "perfurante",  "cor": Color(1.0, 0.35, 0.20)},
	"energia":  {"nome": "Ganho ⚡",   "modo": "energia_ganho","frac": 0.06,  "cap": 60,  "base": 10, "step": 4, "icone": "ouro",        "cor": Color(0.30, 0.80, 1.0)},
}
# Renda de Energia
const E_KILL : int = 1
const E_WAVE_BASE : int = 5   # + a própria wave (escala com progresso)
const E_BOSS : int = 25
# Energia inicial: dá agência ao iniciante já na wave 1 (torre base é fraca sem
# loja/cartas). Trivial p/ veterano, decisivo p/ conta nova chegar na wave 10.
const ENERGIA_INICIAL : int = 110

var _niveis  : Dictionary = {"dano": 0, "cadencia": 0, "vida": 0, "regen": 0, "alcance": 0, "crit": 0, "critdano": 0, "energia": 0}
var _energia : int = ENERGIA_INICIAL   # começa com um empurrão (sobrescrito no checkpoint)
var _base    : Dictionary = {}   # stat-base da torre (p/ calcular o % aditivo)
var _btns    : Dictionary = {}
var _lbls    : Dictionary = {}


func _init(j) -> void:
	jogo = j


# ── Lógica ───────────────────────────────────────────────────────────────────
func _cfg(trilha: String) -> Dictionary:
	return CFG.get(trilha, {}) as Dictionary

func cap(trilha: String) -> int:
	return int(_cfg(trilha).get("cap", 0))

func custo(trilha: String) -> int:
	if not CFG.has(trilha): return 0
	var c : Dictionary = _cfg(trilha)
	return int(c["base"]) + int(_niveis.get(trilha, 0)) * int(c["step"])

func nivel(trilha: String) -> int:
	return int(_niveis.get(trilha, 0))

func energia() -> int:
	return _energia

# % acumulada (para exibir): nível * frac * 100
func pct_total(trilha: String) -> float:
	if not CFG.has(trilha): return 0.0
	return float(_niveis.get(trilha, 0)) * float(_cfg(trilha)["frac"]) * 100.0

# % que o PRÓXIMO nível adiciona
func pct_inc(trilha: String) -> float:
	if not CFG.has(trilha): return 0.0
	return float(_cfg(trilha)["frac"]) * 100.0

func capturar_base() -> void:
	var t = (jogo.torre if jogo else null)
	if not t or not is_instance_valid(t): return
	_base = {
		"dano":     float(t.damage),
		"cadencia": float(t.fire_rate),
		"vida":     float(t.max_hp),
		"alcance":  float(t.range_r),
	}

func _mult_energia() -> float:
	# Bônus de GANHO de energia da trilha "energia" (+frac por nível).
	var cfg : Dictionary = CFG.get("energia", {}) as Dictionary
	return 1.0 + float(_niveis.get("energia", 0)) * float(cfg.get("frac", 0.0))

func ganhar_energia(n: int) -> void:
	if n <= 0: return
	_energia += int(round(float(n) * _mult_energia()))
	atualizar_ui()

func upar(trilha: String) -> bool:
	if not CFG.has(trilha): return false
	var nv : int = int(_niveis.get(trilha, 0))
	if nv >= cap(trilha): return false
	var c : int = custo(trilha)
	if _energia < c: return false
	if _base.is_empty(): capturar_base()
	_energia -= c
	_niveis[trilha] = nv + 1
	var t = (jogo.torre if jogo else null)
	if t and is_instance_valid(t):
		var cfg : Dictionary = _cfg(trilha)
		var frac : float = float(cfg["frac"])
		match str(cfg.get("modo", "pct")):
			"pct":
				# % aditivo do base: cada nível soma base * frac ao stat.
				t.aplicar_carta(trilha, float(_base.get(trilha, 0.0)) * frac)
			"regen_pct":
				# Regen é separado da Vida: + (% do HP-base) por segundo.
				t.aplicar_carta("regen", float(_base.get("vida", 0.0)) * frac)
			"crit_chance":
				t.aplicar_carta("critico", frac)
			"crit_mult":
				t.aplicar_carta("crit_mult", frac)
	atualizar_ui()
	Som.upgrade()
	return true

func serializar() -> Dictionary:
	return {"niveis": _niveis.duplicate(true), "energia": _energia, "base": _base.duplicate(true)}

func restaurar(d: Dictionary) -> void:
	var n = d.get("niveis", {})
	if n is Dictionary:
		for tr in TRILHAS:
			_niveis[tr] = int((n as Dictionary).get(tr, 0))
	_energia = int(d.get("energia", 0))
	var b = d.get("base", {})
	if b is Dictionary and not (b as Dictionary).is_empty():
		_base = (b as Dictionary).duplicate(true)


# ── UI (coluna esquerda do HUD) ──────────────────────────────────────────────
func _hud_parent():
	if jogo and is_instance_valid(jogo.ui_node):
		return jogo.ui_node
	return null

func _fmt(v: float) -> String:
	# Mostra inteiro quando exato, senão 1 decimal (ex.: 0.5).
	if absf(v - roundf(v)) < 0.05:
		return "%d" % int(roundf(v))
	return "%.1f" % v

func limpar_ui() -> void:
	for d in [_btns, _lbls]:
		for nodo in (d as Dictionary).values():
			if nodo and is_instance_valid(nodo):
				(nodo as Node).queue_free()
		(d as Dictionary).clear()

func criar_ui() -> void:
	var hud = _hud_parent()
	if hud == null: return
	limpar_ui()
	var w : float = 172.0
	var h : float = 42.0
	var gap : float = 4.0
	var x : float = 12.0
	var y0 : float = 112.0

	var tit := Label.new()
	tit.text = "NÚCLEO"
	tit.position = Vector2(x + 2.0, y0 - 22.0)
	tit.size     = Vector2(w + 40.0, 18.0)
	tit.add_theme_font_size_override("font_size", 13)
	tit.add_theme_color_override("font_color", Color(0.62, 0.72, 0.88, 0.92))
	tit.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud.add_child(tit)
	_lbls["_tit"] = tit

	for i in range(TRILHAS.size()):
		var trilha : String = str(TRILHAS[i])
		var cfg : Dictionary = _cfg(trilha)
		var cor : Color = cfg.get("cor", Color.WHITE) as Color
		var by : float = y0 + float(i) * (h + gap)

		var btn := Button.new()
		btn.position   = Vector2(x, by)
		btn.size       = Vector2(w, h)
		btn.focus_mode = Control.FOCUS_NONE
		var sty := StyleBoxFlat.new()
		sty.bg_color = Color(cor.r * 0.13, cor.g * 0.13, cor.b * 0.15, 0.94)
		sty.border_color = Color(cor.r, cor.g, cor.b, 0.78)
		sty.set("border_width_left", 4)
		for s in ["right","top","bottom"]: sty.set("border_width_" + s, 1)
		for c in ["top_left","top_right","bottom_left","bottom_right"]: sty.set("corner_radius_" + c, 8)
		btn.add_theme_stylebox_override("normal", sty)
		var sty_h : StyleBoxFlat = sty.duplicate()
		sty_h.bg_color = Color(cor.r * 0.26, cor.g * 0.26, cor.b * 0.28, 0.97)
		btn.add_theme_stylebox_override("hover", sty_h)
		btn.add_theme_stylebox_override("pressed", sty_h)
		var sty_d : StyleBoxFlat = sty.duplicate()
		sty_d.bg_color = Color(0.08, 0.08, 0.10, 0.85)
		sty_d.border_color = Color(0.4, 0.4, 0.45, 0.5)
		btn.add_theme_stylebox_override("disabled", sty_d)
		var trilha_cap : String = trilha
		btn.pressed.connect(func() -> void: upar(trilha_cap))
		hud.add_child(btn)
		_btns[trilha] = btn

		# Mini-ícone da trilha
		var ico := ICONE_SCENE.new()
		ico.tipo = str(cfg.get("icone", "dano"))
		ico.cor  = Color(cor.r + 0.15, cor.g + 0.15, cor.b + 0.15, 1.0)
		ico.position = Vector2(8.0, 9.0)
		ico.size     = Vector2(28.0, 28.0)
		ico.mouse_filter = Control.MOUSE_FILTER_IGNORE
		btn.add_child(ico)

		# Nome
		var lnome := Label.new()
		lnome.text = str(cfg.get("nome", trilha)).to_upper()
		lnome.position = Vector2(44.0, 5.0)
		lnome.size     = Vector2(w - 50.0, 18.0)
		lnome.add_theme_font_size_override("font_size", 13)
		lnome.add_theme_color_override("font_color", Color(cor.r + 0.28, cor.g + 0.28, cor.b + 0.28, 1.0))
		lnome.mouse_filter = Control.MOUSE_FILTER_IGNORE
		btn.add_child(lnome)

		# Valor atual (+inc)  ·  custo
		var lval := Label.new()
		lval.position = Vector2(44.0, 24.0)
		lval.size     = Vector2(w - 50.0, 18.0)
		lval.add_theme_font_size_override("font_size", 12)
		lval.add_theme_color_override("font_color", Color(0.86, 0.91, 0.80))
		lval.mouse_filter = Control.MOUSE_FILTER_IGNORE
		btn.add_child(lval)
		_lbls[trilha] = lval

	atualizar_ui()

func atualizar_ui() -> void:
	var e : int = _energia
	var tit = _lbls.get("_tit")
	if tit and is_instance_valid(tit):
		tit.text = "NÚCLEO   ⚡ %d" % e
	for trilha in _btns.keys():
		var btn = _btns[trilha]
		var lbl = _lbls.get(trilha)
		if not (btn and is_instance_valid(btn)): continue
		var nv : int = nivel(trilha)
		var cp : int = cap(trilha)
		var suf : String = str(_cfg(trilha).get("suf", "%"))
		var atual : String = "+" + _fmt(pct_total(trilha)) + suf
		if nv >= cp:
			if lbl: lbl.text = "%s  ·  MÁX" % atual
			btn.disabled = true
		else:
			var c : int = custo(trilha)
			# "atual (+inc) ⚡custo"  — ex.: +18% (+1)  ⚡80
			if lbl: lbl.text = "%s (+%s)  ⚡%d" % [atual, _fmt(pct_inc(trilha)), c]
			btn.disabled = e < c
