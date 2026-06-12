extends Control
## Talentos V2 — "NEXO ESTELAR" (beta)
## ─────────────────────────────────────────────────────────────────────────────
## Árvore de talentos radial estilo Path of Exile / Stellaris.
## Raiz no centro, 10 ramos irradiando como braços de galáxia em espiral,
## fusões nas interseções, anel interno com situacionais + legado.
##
## Mesmos dados e persistência da tela antiga — usa apenas a API do Salvar:
##   talento_ativo · requisitos_talento · custo_efetivo_talento
##   pode_comprar_talento · comprar_talento · redefinir_talentos
##
## Aberta pelo botão "✦ NEXO (BETA)" na tela de talentos do menu.
## Remover = deletar este arquivo + hook no menu.gd. Zero migração de save.

signal fechado
signal abrir_classico  # abre a tela classica (ascensao vive la)

# ── Layout (espaço-mundo, raiz em (0,0)) ─────────────────────────────────────
const BRANCH_ORDER : Array = ["p", "b", "t", "e", "g", "r", "s", "m", "x", "f"]
const BRANCH_NOMES : Dictionary = {
	"p": "ARSENAL",   "b": "BERSERKER", "t": "TEMPORAL", "e": "ENERGIA",
	"g": "GLACIAL",   "r": "FORTALEZA", "s": "SOMBRA",   "m": "MAESTRIA",
	"x": "CAOS",      "f": "ECONOMIA",
}
# Cadeias especiais (token vive entre r4 e r5)
const CHAIN_OVERRIDE : Dictionary = { "r": ["r1", "r2", "r3", "r4", "token", "r5"] }
const SITUACIONAIS : Array = ["cazador", "exter", "anti_t", "purif"]
const LEGADO       : Array = ["veteran", "genoci", "sobrev"]

const RAIO_T1      : float = 195.0   # raio do tier 1
const RAIO_STEP    : float = 130.0   # distância entre tiers
const RAIO_ANEL    : float = 102.0   # anel interno (situacionais + legado)
const ESPIRAL_DEG  : float = 7.5     # torção do braço por tier (galáxia)
const ANG_INICIO   : float = -PI / 2.0  # ramo P aponta para cima

const ZOOM_MIN : float = 0.42
const ZOOM_MAX : float = 1.65

# ── Estado ───────────────────────────────────────────────────────────────────
var _pos      : Dictionary = {}   # id -> Vector2 mundo
var _ramo_de  : Dictionary = {}   # id -> letra do ramo ("" = especial)
var _fusoes   : Array      = []   # ids de fusão (derivados)
var _cor_ramo : Dictionary = {}   # letra -> Color

var _cam        : Vector2 = Vector2.ZERO
var _zoom       : float   = 0.8
var _zoom_alvo  : float   = 0.8
var _press_pos  : Vector2 = Vector2.ZERO
var _press_ui   : String  = ""
var _dragging   : bool    = false
var _mouse_down : bool    = false
var _drag_vel   : Vector2 = Vector2.ZERO
var _cam_alvo   : Vector2 = Vector2.ZERO
var _cam_anim   : bool    = false
var _sel_id     : String  = ""
var _painel_esq : bool    = false   # lado do painel, fixado no momento da seleção
var _hover_id   : String  = ""

var _pulse        : float = 0.0
var _flux         : float = 0.0   # fase das partículas de energia nos links
var _abertura_t   : float = 0.0   # 0→1 animação de entrada
var _reset_arm_t  : float = 0.0   # >0 = botão reset armado ("CONFIRMA?")
var _toast_txt    : String = ""
var _toast_t      : float = 0.0
var _fx           : Array = []    # partículas de compra
var _estrelas     : Array = []
var _cometas      : Array = []    # estrelas cadentes do fundo
var _cometa_cd    : float = 3.0
var _floats       : Array = []    # textos flutuantes ("-45" na compra)
var _dominado     : Dictionary = {}  # letra do ramo -> bool (todos comprados)

var _ui_hit       : Dictionary = {}  # nome -> Rect2 (hitboxes da UI fixa)
var _redraw_acc   : float = 0.0
const REDRAW_DT   : float = 0.033    # ~30 fps idle (drag redesenha direto)

var _fonte : Font = null


# ── Setup ────────────────────────────────────────────────────────────────────

func _ready() -> void:
	# Tamanho manual (padrão do projeto) — anchors não cobrem certo sob
	# CanvasLayer com stretch "expand"
	position = Vector2.ZERO
	size = get_viewport().get_visible_rect().size
	get_viewport().size_changed.connect(func():
		position = Vector2.ZERO
		size = get_viewport().get_visible_rect().size
		queue_redraw())
	mouse_filter = Control.MOUSE_FILTER_STOP
	z_index = 300  # tela de talentos antiga usa z_index 19-30; overlay fica acima de tudo
	_fonte = get_theme_default_font()
	_montar_layout()
	_gerar_estrelas()
	_recalc_dominio()
	_zoom = 0.30
	_zoom_alvo = 0.80
	_abertura_t = 0.0


func _recalc_dominio() -> void:
	for br in BRANCH_ORDER:
		var cadeia : Array = _cadeia_do_ramo(br as String)
		var completo : bool = not cadeia.is_empty()
		for cid in cadeia:
			if not Salvar.talento_ativo(cid as String):
				completo = false
				break
		_dominado[br] = completo


func _montar_layout() -> void:
	_pos.clear(); _ramo_de.clear(); _fusoes.clear(); _cor_ramo.clear()
	_pos["raiz"] = Vector2.ZERO
	_ramo_de["raiz"] = ""
	var usados : Dictionary = { "raiz": true }

	# Braços dos ramos (espiral)
	for i in range(BRANCH_ORDER.size()):
		var br : String = BRANCH_ORDER[i]
		var cadeia : Array = _cadeia_do_ramo(br)
		if cadeia.is_empty():
			continue
		var ang0 : float = ANG_INICIO + TAU * float(i) / float(BRANCH_ORDER.size())
		for t in range(cadeia.size()):
			var id : String = cadeia[t]
			var ang : float = ang0 + deg_to_rad(ESPIRAL_DEG) * float(t)
			var raio : float = RAIO_T1 + RAIO_STEP * float(t)
			_pos[id] = Vector2(cos(ang), sin(ang)) * raio
			_ramo_de[id] = br
			usados[id] = true
		var info0 : Dictionary = Salvar.TALENTOS_INFO.get(cadeia[0], {}) as Dictionary
		_cor_ramo[br] = info0.get("cor", Color(0.5, 0.8, 1.0)) as Color

	# Anel interno: situacionais + legado intercalados
	var anel : Array = []
	for id in SITUACIONAIS:
		if Salvar.TALENTOS_INFO.has(id): anel.append(id)
	for id in LEGADO:
		if Salvar.TALENTOS_INFO.has(id): anel.append(id)
	for k in range(anel.size()):
		var id_a : String = anel[k]
		var ang_a : float = ANG_INICIO + deg_to_rad(18.0) + TAU * float(k) / float(anel.size())
		_pos[id_a] = Vector2(cos(ang_a), sin(ang_a)) * RAIO_ANEL
		_ramo_de[id_a] = ""
		usados[id_a] = true

	# Fusões: tudo que sobrou — posição = média dos pais, empurrada p/ fora
	for tid in Salvar.TALENTOS_INFO.keys():
		var id_f : String = tid as String
		if usados.has(id_f):
			continue
		_fusoes.append(id_f)
		var reqs : Array = Salvar.requisitos_talento(id_f)
		var soma := Vector2.ZERO
		var n : int = 0
		for r in reqs:
			if _pos.has(r as String):
				soma += _pos[r as String] as Vector2
				n += 1
		var p : Vector2 = (soma / float(maxi(n, 1)))
		if p.length() < 60.0:
			p = Vector2(0, -1) * 60.0
		p = p + p.normalized() * 46.0
		_pos[id_f] = p
		_ramo_de[id_f] = ""

	# Relaxamento: afasta fusões que caíram em cima de outros nós
	for _i in range(10):
		for fid in _fusoes:
			var fp : Vector2 = _pos[fid] as Vector2
			for oid in _pos.keys():
				if oid == fid: continue
				var op : Vector2 = _pos[oid] as Vector2
				var d : Vector2 = fp - op
				if d.length() < 78.0:
					fp += d.normalized() * (78.0 - d.length()) * 0.6
			_pos[fid] = fp


func _cadeia_do_ramo(br: String) -> Array:
	if CHAIN_OVERRIDE.has(br):
		var out : Array = []
		for id in CHAIN_OVERRIDE[br] as Array:
			if Salvar.TALENTOS_INFO.has(id as String):
				out.append(id as String)
		return out
	var tiers : Array = []
	for tid in Salvar.TALENTOS_INFO.keys():
		var id : String = tid as String
		if id.length() == 2 and id[0] == br and id[1].is_valid_int():
			tiers.append(id)
	tiers.sort()
	return tiers


func _gerar_estrelas() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 777
	for i in range(170):
		_estrelas.append({
			"pos": Vector2(rng.randf_range(-1250.0, 1250.0), rng.randf_range(-1100.0, 1100.0)),
			"r": rng.randf_range(0.5, 1.9),
			"par": [0.22, 0.45, 0.72][rng.randi_range(0, 2)],
			"ph": rng.randf_range(0.0, TAU),
		})


# ── Transform mundo ↔ tela ───────────────────────────────────────────────────

func _w2s(p: Vector2) -> Vector2:
	return (p - _cam) * _zoom + size * 0.5

func _s2w(p: Vector2) -> Vector2:
	return (p - size * 0.5) / _zoom + _cam


# ── Loop ─────────────────────────────────────────────────────────────────────

func _process(delta: float) -> void:
	_pulse += delta
	_flux  += delta * 0.55
	if _abertura_t < 1.0:
		_abertura_t = minf(_abertura_t + delta / 0.75, 1.0)
	_zoom = lerpf(_zoom, _zoom_alvo, minf(delta * 9.0, 1.0))
	# Câmera animada (foco no nó selecionado / centro)
	if _cam_anim:
		_cam = _cam.lerp(_cam_alvo, minf(delta * 6.0, 1.0))
		if _cam.distance_to(_cam_alvo) < 2.0:
			_cam_anim = false
	# Inércia do pan
	if not _mouse_down and _drag_vel.length() > 2.0:
		_cam -= _drag_vel * delta / _zoom * 6.0
		_drag_vel = _drag_vel.lerp(Vector2.ZERO, minf(delta * 7.0, 1.0))
	_clamp_cam()
	# Cometas (estrelas cadentes)
	_cometa_cd -= delta
	if _cometa_cd <= 0.0:
		_cometa_cd = randf_range(4.5, 9.0)
		var ca : float = randf() * TAU
		_cometas.append({
			"pos": Vector2(randf_range(-850.0, 850.0), randf_range(-750.0, 750.0)),
			"vel": Vector2(cos(ca), sin(ca)) * randf_range(650.0, 1000.0), "t": 0.0,
		})
	var cvivos : Array = []
	for c_any in _cometas:
		var cm : Dictionary = c_any as Dictionary
		cm["t"] = float(cm["t"]) + delta
		if float(cm["t"]) < 1.1:
			cvivos.append(cm)
	_cometas = cvivos
	# Textos flutuantes
	var fvivos : Array = []
	for f_any in _floats:
		var fl : Dictionary = f_any as Dictionary
		fl["t"] = float(fl["t"]) + delta
		if float(fl["t"]) < 1.2:
			fvivos.append(fl)
	_floats = fvivos
	if _reset_arm_t > 0.0:
		_reset_arm_t = maxf(_reset_arm_t - delta, 0.0)
	if _toast_t > 0.0:
		_toast_t = maxf(_toast_t - delta, 0.0)
	# FX
	var vivos : Array = []
	for fx_any in _fx:
		var fx : Dictionary = fx_any as Dictionary
		fx["t"] = float(fx["t"]) + delta
		if float(fx["t"]) < float(fx["dur"]):
			vivos.append(fx)
	_fx = vivos
	_redraw_acc += delta
	if _redraw_acc >= REDRAW_DT or _dragging or _cam_anim or not _fx.is_empty() or _abertura_t < 1.0:
		_redraw_acc = 0.0
		queue_redraw()


func _clamp_cam() -> void:
	var lim : float = RAIO_T1 + RAIO_STEP * 6.0
	_cam.x = clampf(_cam.x, -lim, lim)
	_cam.y = clampf(_cam.y, -lim, lim)


# ── Input ────────────────────────────────────────────────────────────────────

func _input(event: InputEvent) -> void:
	if not visible:
		return
	var k := event as InputEventKey
	if k != null and k.pressed and k.keycode == KEY_ESCAPE:
		get_viewport().set_input_as_handled()
		_fechar()


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_WHEEL_UP and mb.pressed:
			_zoom_no_cursor(1.12, mb.position)
		elif mb.button_index == MOUSE_BUTTON_WHEEL_DOWN and mb.pressed:
			_zoom_no_cursor(1.0 / 1.12, mb.position)
		elif mb.button_index == MOUSE_BUTTON_LEFT:
			if mb.pressed:
				_mouse_down = true
				_dragging   = false
				_press_pos  = mb.position
				_press_ui   = _hit_ui(mb.position)
				_drag_vel   = Vector2.ZERO
			else:
				_mouse_down = false
				if not _dragging:
					_clique(mb.position)
				_dragging = false
		elif mb.button_index == MOUSE_BUTTON_RIGHT and mb.pressed:
			# Botão direito: só info (painel), nunca compra
			var nid_r := _hit_no(mb.position)
			if nid_r != "":
				_sel_id = nid_r
				_painel_esq = _w2s(_pos[nid_r] as Vector2).x > size.x * 0.5
				queue_redraw()
		accept_event()
	elif event is InputEventMouseMotion:
		var mm := event as InputEventMouseMotion
		if _mouse_down and _press_ui == "":
			if not _dragging and (mm.position - _press_pos).length() > 11.0:
				_dragging = true
				_cam_anim = false
			if _dragging:
				_cam -= mm.relative / _zoom
				_drag_vel = mm.relative
				_clamp_cam()
				queue_redraw()
		else:
			var h := _hit_no(mm.position)
			if h != _hover_id:
				_hover_id = h
				queue_redraw()
		accept_event()


func _zoom_no_cursor(fator: float, sp: Vector2) -> void:
	var mundo : Vector2 = _s2w(sp)
	_zoom = clampf(_zoom * fator, ZOOM_MIN, ZOOM_MAX)
	_zoom_alvo = _zoom
	_cam = mundo - (sp - size * 0.5) / _zoom
	_clamp_cam()
	queue_redraw()


func _clique(sp: Vector2) -> void:
	var ui := _hit_ui(sp)
	if ui != "":
		_acao_ui(ui)
		return
	var nid := _hit_no(sp)
	if nid != "":
		# CLIQUE ÚNICO COMPRA. Zero fricção.
		if Salvar.pode_comprar_talento(nid):
			_comprar(nid)
		elif _sel_id == nid:
			_sel_id = ""
			Som.upgrade()
		else:
			# Não-comprável: abre painel de info (lado travado na seleção)
			_sel_id = nid
			_painel_esq = _w2s(_pos[nid] as Vector2).x > size.x * 0.5
			Som.upgrade()
			if not Salvar.talento_ativo(nid):
				_toast(_motivo_bloqueio(nid, Salvar.custo_efetivo_talento(nid)))
		queue_redraw()
		return
	_sel_id = ""
	queue_redraw()


func _acao_ui(nome: String) -> void:
	match nome:
		"fechar":
			_fechar()
		"zoom_in":
			_zoom_alvo = clampf(_zoom_alvo * 1.28, ZOOM_MIN, ZOOM_MAX)
		"zoom_out":
			_zoom_alvo = clampf(_zoom_alvo / 1.28, ZOOM_MIN, ZOOM_MAX)
		"centro":
			_cam_alvo = Vector2.ZERO
			_cam_anim = true
			_zoom_alvo = 0.8
		"reset":
			if _reset_arm_t > 0.0:
				var devolvido : int = Salvar.redefinir_talentos()
				_reset_arm_t = 0.0
				_sel_id = ""
				_recalc_dominio()
				_toast("◆ %d cristais devolvidos" % devolvido)
				Som.upgrade()
			else:
				_reset_arm_t = 3.0
		"comprar":
			if _sel_id != "" and Salvar.pode_comprar_talento(_sel_id):
				_comprar(_sel_id)
		"classico":
			abrir_classico.emit()
			_fechar()
			return
	queue_redraw()


func _hit_ui(sp: Vector2) -> String:
	for nome in _ui_hit.keys():
		if (_ui_hit[nome] as Rect2).has_point(sp):
			return nome as String
	return ""


func _hit_no(sp: Vector2) -> String:
	var melhor := ""
	var melhor_d : float = 1e9
	for tid in _pos.keys():
		var id : String = tid as String
		var spn : Vector2 = _w2s(_pos[id] as Vector2)
		var rr : float = maxf(_raio_no(id) * _zoom, 27.0)
		var d : float = sp.distance_to(spn)
		if d <= rr and d < melhor_d:
			melhor_d = d
			melhor = id
	return melhor


func _fechar() -> void:
	fechado.emit()
	queue_free()


# ── Compra ───────────────────────────────────────────────────────────────────

func _comprar(id: String) -> void:
	var custo_pago : int = Salvar.custo_efetivo_talento(id)
	if not Salvar.comprar_talento(id):
		_toast("Não foi possível desbloquear")
		return
	_recalc_dominio()
	var cor : Color = _cor_no(id)
	var p : Vector2 = _pos[id] as Vector2
	_floats.append({ "pos": p + Vector2(0, -42.0), "txt": "-%d ◆" % custo_pago, "t": 0.0, "cor": Color(0.55, 0.95, 1.0) })
	var br_d : String = _ramo_de.get(id, "") as String
	if br_d != "" and bool(_dominado.get(br_d, false)):
		_floats.append({ "pos": p + Vector2(0, -70.0), "txt": "%s DOMINADO!" % BRANCH_NOMES.get(br_d, ""), "t": 0.0, "cor": Color(1.0, 0.85, 0.25) })
	_fx.append({ "tipo": "flash", "pos": p, "t": 0.0, "dur": 0.18, "cor": Color.WHITE })
	_fx.append({ "tipo": "shock", "pos": p, "t": 0.0, "dur": 0.50, "cor": cor })
	for i in range(16):
		var ang : float = TAU * float(i) / 16.0 + randf() * 0.3
		_fx.append({
			"tipo": "spark", "pos": p, "t": 0.0, "dur": 0.65,
			"vel": Vector2(cos(ang), sin(ang)) * randf_range(90.0, 220.0), "cor": cor,
		})
	for r in Salvar.requisitos_talento(id):
		if _pos.has(r as String):
			_fx.append({
				"tipo": "surge", "de": _pos[r as String], "para": p,
				"t": 0.0, "dur": 0.35, "cor": cor,
			})
	if _fusoes.has(id):
		Som.talento_fusao()
	elif _ramo_de.get(id, "") == "":
		Som.talento_especial()
	else:
		Som.talento_ramo()


func _toast(txt: String) -> void:
	_toast_txt = txt
	_toast_t = 2.2


# ── Helpers de estado ────────────────────────────────────────────────────────

func _raio_no(id: String) -> float:
	if id == "raiz":
		return 34.0
	if _fusoes.has(id):
		return 30.0
	if _ramo_de.get(id, "") == "":
		return 21.0
	var info : Dictionary = Salvar.TALENTOS_INFO.get(id, {}) as Dictionary
	var custo : int = int(info.get("custo", 9))
	return 30.0 if custo >= 90 else 25.0


func _cor_no(id: String) -> Color:
	var info : Dictionary = Salvar.TALENTOS_INFO.get(id, {}) as Dictionary
	return info.get("cor", Color(0.5, 0.8, 1.0)) as Color


func _no_visivel_abertura(id: String) -> float:
	# Onda radial na abertura: nós distantes aparecem depois
	if _abertura_t >= 1.0:
		return 1.0
	var raio : float = (_pos[id] as Vector2).length()
	var frente : float = _abertura_t * (RAIO_T1 + RAIO_STEP * 6.5) * 1.25
	return clampf((frente - raio) / 120.0, 0.0, 1.0)


func _total_nos() -> int:
	return maxi(0, Salvar.TALENTOS_INFO.size() - 1)


func _comprados() -> int:
	var n : int = 0
	for tid in Salvar.TALENTOS_INFO.keys():
		if tid != "raiz" and Salvar.talento_ativo(tid as String):
			n += 1
	return n


# ── Desenho ──────────────────────────────────────────────────────────────────

func _draw() -> void:
	_ui_hit.clear()
	_draw_fundo()
	_draw_grid_polar()
	_draw_links()
	_draw_nos()
	_draw_fx()
	_draw_floats()
	_draw_header()
	_draw_painel()
	_draw_hover_tooltip()
	_draw_toast()


func _draw_floats() -> void:
	for f_any in _floats:
		var fl : Dictionary = f_any as Dictionary
		var t : float = float(fl["t"]) / 1.2
		var cor : Color = fl["cor"] as Color
		var sp : Vector2 = _w2s((fl["pos"] as Vector2) + Vector2(0, -46.0 * t))
		var txt : String = str(fl["txt"])
		var w : float = _fonte.get_string_size(txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 16).x
		draw_string(_fonte, sp - Vector2(w * 0.5, 0), txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 16,
				Color(cor.r, cor.g, cor.b, 1.0 - t * t))


func _draw_hover_tooltip() -> void:
	if _hover_id == "" or _hover_id == _sel_id or _dragging:
		return
	if not Salvar.TALENTOS_INFO.has(_hover_id):
		return
	var info : Dictionary = Salvar.TALENTOS_INFO[_hover_id] as Dictionary
	var cor : Color = _cor_no(_hover_id)
	var nome : String = str(info.get("nome", _hover_id)).replace("\n", " ")
	var sub : String
	if Salvar.talento_ativo(_hover_id):
		sub = "ATIVO"
	elif Salvar.pode_comprar_talento(_hover_id):
		sub = "◆ %d — CLIQUE PARA COMPRAR" % Salvar.custo_efetivo_talento(_hover_id)
	else:
		sub = "Bloqueado"
	var fs_n : int = 14
	var w : float = maxf(_fonte.get_string_size(nome, HORIZONTAL_ALIGNMENT_LEFT, -1, fs_n).x,
			_fonte.get_string_size(sub, HORIZONTAL_ALIGNMENT_LEFT, -1, 11).x) + 24.0
	var mp : Vector2 = get_local_mouse_position() + Vector2(16, -54)
	mp.x = clampf(mp.x, 4.0, size.x - w - 4.0)
	mp.y = clampf(mp.y, 56.0, size.y - 50.0)
	var r := Rect2(mp, Vector2(w, 44))
	draw_rect(r, Color(0.015, 0.025, 0.06, 0.94), true)
	draw_rect(r, Color(cor.r, cor.g, cor.b, 0.55), false, 1.0)
	draw_string(_fonte, mp + Vector2(12, 18), nome, HORIZONTAL_ALIGNMENT_LEFT, -1, fs_n, cor)
	draw_string(_fonte, mp + Vector2(12, 35), sub, HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color(0.72, 0.80, 0.92))


func _draw_fundo() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.008, 0.012, 0.034), true)
	# Nebulosas por ramo (blobs suaves atrás de cada braço; fortes se dominado)
	for i in range(BRANCH_ORDER.size()):
		var br : String = BRANCH_ORDER[i]
		if not _cor_ramo.has(br):
			continue
		var cor : Color = _cor_ramo[br] as Color
		var neb_a : float = 0.055 if bool(_dominado.get(br, false)) else 0.022
		var ang0 : float = ANG_INICIO + TAU * float(i) / float(BRANCH_ORDER.size())
		for k in range(4):
			var ang : float = ang0 + deg_to_rad(ESPIRAL_DEG) * float(k + 1)
			var raio : float = RAIO_T1 + RAIO_STEP * (float(k) + 0.5)
			var p : Vector2 = _w2s(Vector2(cos(ang), sin(ang)) * raio)
			var rr : float = (130.0 - float(k) * 12.0) * _zoom
			draw_circle(p, rr, Color(cor.r, cor.g, cor.b, neb_a))
	# Starfield com parallax
	for s_any in _estrelas:
		var s : Dictionary = s_any as Dictionary
		var par : float = float(s["par"])
		var sp : Vector2 = ((s["pos"] as Vector2) - _cam * par) * _zoom + size * 0.5
		if sp.x < -10.0 or sp.y < -10.0 or sp.x > size.x + 10.0 or sp.y > size.y + 10.0:
			continue
		var tw : float = 0.35 + 0.30 * sin(_pulse * 0.9 + float(s["ph"]))
		draw_circle(sp, float(s["r"]) * (0.6 + par * 0.6), Color(0.55, 0.78, 1.0, tw * 0.30))
	# Cometas (estrelas cadentes, parallax de fundo)
	for c_any in _cometas:
		var cm : Dictionary = c_any as Dictionary
		var ct : float = float(cm["t"])
		var ca : float = sin(minf(ct / 1.1, 1.0) * PI)  # fade in/out
		var cp : Vector2 = (cm["pos"] as Vector2) + (cm["vel"] as Vector2) * ct
		var csp : Vector2 = (cp - _cam * 0.6) * _zoom + size * 0.5
		var cauda : Vector2 = (cm["vel"] as Vector2).normalized() * -78.0 * _zoom
		draw_line(csp + cauda, csp, Color(0.65, 0.85, 1.0, 0.30 * ca), 1.4)
		draw_circle(csp, 2.3, Color(0.88, 0.96, 1.0, 0.85 * ca))
	# Brilho central do nexo
	var c : Vector2 = _w2s(Vector2.ZERO)
	draw_circle(c, 240.0 * _zoom, Color(0.25, 0.55, 1.0, 0.04))
	draw_circle(c, 120.0 * _zoom, Color(0.45, 0.75, 1.0, 0.05))


func _draw_grid_polar() -> void:
	var c : Vector2 = _w2s(Vector2.ZERO)
	var cor := Color(0.40, 0.66, 1.0, 0.028)
	for t in range(7):
		var raio : float = (RAIO_T1 + RAIO_STEP * float(t)) * _zoom
		draw_arc(c, raio, 0.0, TAU, 72, cor, 1.0)
	draw_arc(c, RAIO_ANEL * _zoom, 0.0, TAU, 40, Color(1.0, 0.85, 0.35, 0.06), 1.0)
	for i in range(BRANCH_ORDER.size()):
		var ang : float = ANG_INICIO + TAU * float(i) / float(BRANCH_ORDER.size())
		var a : Vector2 = c + Vector2(cos(ang), sin(ang)) * RAIO_T1 * 0.55 * _zoom
		var b : Vector2 = c + Vector2(cos(ang + deg_to_rad(ESPIRAL_DEG * 6.0)), sin(ang + deg_to_rad(ESPIRAL_DEG * 6.0))) * (RAIO_T1 + RAIO_STEP * 6.2) * _zoom
		draw_line(a, b, cor, 1.0)


func _arco_link(de: Vector2, para: Vector2) -> PackedVector2Array:
	# Interpola em coordenadas polares — o link acompanha a espiral do braço
	var pts := PackedVector2Array()
	var r1 : float = de.length()
	var r2 : float = para.length()
	var a1 : float = de.angle()
	var a2 : float = para.angle()
	var diff : float = wrapf(a2 - a1, -PI, PI)
	const STEPS : int = 13
	for i in range(STEPS + 1):
		var t : float = float(i) / float(STEPS)
		if r1 < 8.0:  # saindo da raiz: linha reta suave
			pts.append(_w2s(de.lerp(para, t)))
		else:
			var rr : float = lerpf(r1, r2, t)
			var aa : float = a1 + diff * t
			pts.append(_w2s(Vector2(cos(aa), sin(aa)) * rr))
	return pts


func _draw_links() -> void:
	for tid in Salvar.TALENTOS_INFO.keys():
		var id : String = tid as String
		if id == "raiz" or not _pos.has(id):
			continue
		var alpha_ab : float = _no_visivel_abertura(id)
		if alpha_ab <= 0.01:
			continue
		var reqs : Array = Salvar.requisitos_talento(id)
		if reqs.is_empty():
			reqs = ["raiz"]
		var eh_fusao : bool = _fusoes.has(id)
		for r_any in reqs:
			var rid : String = r_any as String
			if not _pos.has(rid):
				continue
			var de : Vector2 = _pos[rid] as Vector2
			var para : Vector2 = _pos[id] as Vector2
			# Culling grosseiro
			var sa : Vector2 = _w2s(de)
			var sb : Vector2 = _w2s(para)
			var bb := Rect2(sa, Vector2.ZERO).expand(sb).grow(60.0)
			if not bb.intersects(Rect2(Vector2.ZERO, size)):
				continue
			var pts : PackedVector2Array = _arco_link(de, para)
			var pai_ok   : bool = Salvar.talento_ativo(rid)
			var filho_ok : bool = Salvar.talento_ativo(id)
			var cor : Color = _cor_no(id)
			if filho_ok and pai_ok:
				# Comprado: linha viva com energia fluindo (1 pulso sutil por link)
				draw_polyline(pts, Color(cor.r, cor.g, cor.b, 0.12 * alpha_ab), 5.0)
				draw_polyline(pts, Color(cor.r, cor.g, cor.b, 0.62 * alpha_ab), 2.0)
				var t : float = fmod(_flux * 0.45 + de.length() * 0.0017, 1.0)
				var idx : float = t * float(pts.size() - 1)
				var i0 : int = int(idx)
				var p : Vector2 = (pts[i0] as Vector2).lerp(pts[mini(i0 + 1, pts.size() - 1)] as Vector2, idx - float(i0))
				draw_circle(p, 2.6 * sqrt(_zoom), Color(cor.r * 0.5 + 0.5, cor.g * 0.5 + 0.5, cor.b * 0.5 + 0.5, 0.65 * alpha_ab))
			elif pai_ok and Salvar.pode_comprar_talento(id):
				# Disponível: pulso respirando
				var br_ : float = 0.45 + 0.30 * sin(_pulse * 2.6)
				draw_polyline(pts, Color(cor.r, cor.g, cor.b, br_ * 0.55 * alpha_ab), 2.0)
			else:
				var a_lk : float = (0.16 if eh_fusao else 0.12) * alpha_ab
				draw_polyline(pts, Color(0.35, 0.45, 0.62, a_lk), 1.2)


func _draw_nos() -> void:
	var margem := Rect2(Vector2.ZERO, size).grow(90.0)
	for tid in _pos.keys():
		var id : String = tid as String
		var sp : Vector2 = _w2s(_pos[id] as Vector2)
		if not margem.has_point(sp):
			continue
		var ab : float = _no_visivel_abertura(id)
		if ab <= 0.01:
			continue
		_draw_no(id, sp, ab)
	# Labels de ramo quando afastado
	if _zoom < 0.62:
		for i in range(BRANCH_ORDER.size()):
			var br : String = BRANCH_ORDER[i]
			if not _cor_ramo.has(br):
				continue
			var ang : float = ANG_INICIO + TAU * float(i) / float(BRANCH_ORDER.size()) + deg_to_rad(ESPIRAL_DEG * 2.5)
			var p : Vector2 = _w2s(Vector2(cos(ang), sin(ang)) * (RAIO_T1 + RAIO_STEP * 2.6))
			var cadeia : Array = _cadeia_do_ramo(br)
			var compr : int = 0
			for cid in cadeia:
				if Salvar.talento_ativo(cid as String):
					compr += 1
			var cor : Color = _cor_ramo[br] as Color
			var txt : String
			var cor_lbl : Color
			if bool(_dominado.get(br, false)):
				txt = "%s — DOMINADO" % BRANCH_NOMES.get(br, br.to_upper())
				var dp : float = 0.75 + 0.25 * sin(_pulse * 2.2)
				cor_lbl = Color(1.0, 0.85, 0.25, dp * _abertura_t)
			else:
				txt = "%s  %d/%d" % [BRANCH_NOMES.get(br, br.to_upper()), compr, cadeia.size()]
				cor_lbl = Color(cor.r, cor.g, cor.b, 0.85 * _abertura_t)
			var w : float = _fonte.get_string_size(txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 15).x
			draw_string(_fonte, p - Vector2(w * 0.5, -5.0), txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 15, cor_lbl)


func _draw_no(id: String, sp: Vector2, ab: float) -> void:
	var cor : Color = _cor_no(id)
	var rr : float = _raio_no(id) * _zoom
	var ativo : bool = Salvar.talento_ativo(id)
	var pode  : bool = Salvar.pode_comprar_talento(id)
	var major : bool = _raio_no(id) >= 30.0
	var eh_legado : bool = LEGADO.has(id)

	# Escala de "pop" na abertura
	rr *= 0.5 + 0.5 * ab

	if id == "raiz":
		var pr : float = 1.0 + 0.06 * sin(_pulse * 2.0)
		draw_circle(sp, rr * 1.9 * pr, Color(1.0, 0.85, 0.30, 0.10 * ab))
		draw_circle(sp, rr * 1.15, Color(0.06, 0.05, 0.02, 0.95 * ab))
		draw_arc(sp, rr * 1.15, 0.0, TAU, 40, Color(1.0, 0.82, 0.25, 0.9 * ab), 2.5)
		draw_circle(sp, rr * 0.62 * pr, Color(1.0, 0.85, 0.30, 0.85 * ab))
		_draw_hex(sp, rr * 1.55, _pulse * 0.25, Color(1.0, 0.82, 0.25, 0.35 * ab), 1.5)
		# Anéis orbitais decorativos (sentidos opostos)
		var oa1 : float = _pulse * 0.9
		draw_arc(sp, rr * 2.1, oa1, oa1 + PI * 0.85, 20, Color(0.55, 0.80, 1.0, 0.30 * ab), 1.2)
		var oa2 : float = -_pulse * 0.6
		draw_arc(sp, rr * 2.45, oa2, oa2 + PI * 0.55, 16, Color(1.0, 0.82, 0.25, 0.22 * ab), 1.2)
		return

	# Halo / glow (sutil — só um respiro)
	if ativo:
		var pr2 : float = 1.0 + 0.06 * sin(_pulse * 2.4 + sp.x * 0.01)
		draw_circle(sp, rr * 1.45 * pr2, Color(cor.r, cor.g, cor.b, 0.08 * ab))
	elif pode:
		var pr3 : float = 0.5 + 0.5 * sin(_pulse * 3.0)
		draw_circle(sp, rr * 1.55, Color(cor.r, cor.g, cor.b, (0.05 + 0.07 * pr3) * ab))

	# Corpo
	var fundo_c : Color
	if ativo:
		fundo_c = Color(cor.r * 0.30, cor.g * 0.30, cor.b * 0.30, 0.96 * ab)
	elif pode:
		fundo_c = Color(0.05, 0.07, 0.13, 0.94 * ab)
	else:
		fundo_c = Color(0.035, 0.045, 0.08, 0.90 * ab)
	draw_circle(sp, rr, fundo_c)

	# Borda
	var borda_a : float
	var borda_w : float
	if ativo:
		borda_a = 1.0; borda_w = 2.8
	elif pode:
		borda_a = 0.55 + 0.35 * sin(_pulse * 3.0); borda_w = 2.0
	else:
		borda_a = 0.22; borda_w = 1.2
	draw_arc(sp, rr, 0.0, TAU, 36, Color(cor.r, cor.g, cor.b, borda_a * ab), borda_w)

	# Hexágono giratório nos majors
	if major:
		var rot_dir : float = 1.0 if ativo else 0.35
		_draw_hex(sp, rr * 1.34, _pulse * 0.30 * rot_dir, Color(cor.r, cor.g, cor.b, (0.32 if ativo else 0.12) * ab), 1.2)

	# Partícula orbitando os compráveis
	if pode and not ativo:
		var oa : float = _pulse * 2.2 + sp.y * 0.013
		var op : Vector2 = sp + Vector2(cos(oa), sin(oa)) * rr * 1.32
		draw_circle(op, 2.6 * sqrt(_zoom), Color(cor.r * 0.5 + 0.5, cor.g * 0.5 + 0.5, cor.b * 0.5 + 0.5, 0.9 * ab))

	# Glifo
	var glifo_a : float = (1.0 if (ativo or pode) else 0.40) * ab
	_draw_glifo(id, sp, rr * 0.52, Color(cor.r * 0.6 + 0.4, cor.g * 0.6 + 0.4, cor.b * 0.6 + 0.4, glifo_a))

	# Cadeado nos legado não conquistados
	if eh_legado and not ativo and not pode and not _req_conquista_ok(id):
		_draw_cadeado(sp + Vector2(rr * 0.72, -rr * 0.72), 6.0 * sqrt(_zoom), Color(1.0, 0.8, 0.3, 0.85 * ab))

	# Anel de seleção
	if id == _sel_id:
		var sa : float = _pulse * 1.8
		draw_arc(sp, rr * 1.55, sa, sa + PI * 0.7, 18, Color(1, 1, 1, 0.85 * ab), 2.0)
		draw_arc(sp, rr * 1.55, sa + PI, sa + PI * 1.7, 18, Color(1, 1, 1, 0.85 * ab), 2.0)
	elif id == _hover_id:
		draw_arc(sp, rr * 1.42, 0.0, TAU, 30, Color(1, 1, 1, 0.30 * ab), 1.2)

	# Nome abaixo — só onde importa: compráveis, selecionado e hover
	# (comprados/bloqueados ficam limpos; tooltip e painel cobrem o resto)
	if _zoom >= 0.72 and (pode or id == _sel_id or id == _hover_id):
		var info : Dictionary = Salvar.TALENTOS_INFO.get(id, {}) as Dictionary
		var nome : String = str(info.get("nome", id)).replace("\n", " ")
		var fs : int = 11
		var w : float = _fonte.get_string_size(nome, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
		draw_string(_fonte, sp + Vector2(-w * 0.5, rr + 15.0), nome,
				HORIZONTAL_ALIGNMENT_LEFT, -1, fs,
				Color(0.82, 0.88, 1.0, 0.85 * ab))


func _req_conquista_ok(id: String) -> bool:
	match id:
		"veteran": return Salvar.legado_debug_liberado() or Salvar.total_partidas >= 100
		"genoci":  return Salvar.legado_debug_liberado() or Salvar.total_mobs_mortos >= 10000
		"sobrev":  return Salvar.legado_debug_liberado() or Salvar.melhor_wave >= 30
	return true


# ── Glifos ───────────────────────────────────────────────────────────────────

func _draw_hex(c: Vector2, r: float, rot: float, cor: Color, w: float) -> void:
	var pts := PackedVector2Array()
	for i in range(7):
		var a : float = rot + TAU * float(i) / 6.0
		pts.append(c + Vector2(cos(a), sin(a)) * r)
	draw_polyline(pts, cor, w)


func _draw_cadeado(c: Vector2, s: float, cor: Color) -> void:
	draw_rect(Rect2(c + Vector2(-s * 0.7, -s * 0.1), Vector2(s * 1.4, s * 1.1)), cor, false, 1.6)
	draw_arc(c + Vector2(0, -s * 0.1), s * 0.45, PI, TAU, 10, cor, 1.6)


func _draw_glifo(id: String, c: Vector2, s: float, cor: Color) -> void:
	var w : float = maxf(1.6, 2.0 * sqrt(_zoom))
	if _fusoes.has(id):
		# Estrela de 4 pontas
		draw_line(c + Vector2(0, -s), c + Vector2(s * 0.28, -s * 0.28), cor, w)
		draw_line(c + Vector2(s * 0.28, -s * 0.28), c + Vector2(s, 0), cor, w)
		draw_line(c + Vector2(s, 0), c + Vector2(s * 0.28, s * 0.28), cor, w)
		draw_line(c + Vector2(s * 0.28, s * 0.28), c + Vector2(0, s), cor, w)
		draw_line(c + Vector2(0, s), c + Vector2(-s * 0.28, s * 0.28), cor, w)
		draw_line(c + Vector2(-s * 0.28, s * 0.28), c + Vector2(-s, 0), cor, w)
		draw_line(c + Vector2(-s, 0), c + Vector2(-s * 0.28, -s * 0.28), cor, w)
		draw_line(c + Vector2(-s * 0.28, -s * 0.28), c + Vector2(0, -s), cor, w)
		return
	if LEGADO.has(id):
		# Louros
		draw_arc(c + Vector2(-s * 0.25, 0), s * 0.85, PI * 0.55, PI * 1.45, 12, cor, w)
		draw_arc(c + Vector2(s * 0.25, 0), s * 0.85, -PI * 0.45, PI * 0.45, 12, cor, w)
		return
	if SITUACIONAIS.has(id):
		# Alvo
		draw_arc(c, s * 0.85, 0.0, TAU, 20, cor, w)
		draw_line(c + Vector2(-s, 0), c + Vector2(-s * 0.4, 0), cor, w)
		draw_line(c + Vector2(s * 0.4, 0), c + Vector2(s, 0), cor, w)
		draw_line(c + Vector2(0, -s), c + Vector2(0, -s * 0.4), cor, w)
		draw_line(c + Vector2(0, s * 0.4), c + Vector2(0, s), cor, w)
		draw_circle(c, s * 0.18, cor)
		return
	match _ramo_de.get(id, ""):
		"p":  # Chama
			draw_line(c + Vector2(0, -s), c + Vector2(s * 0.62, s * 0.5), cor, w)
			draw_line(c + Vector2(s * 0.62, s * 0.5), c + Vector2(-s * 0.62, s * 0.5), cor, w)
			draw_line(c + Vector2(-s * 0.62, s * 0.5), c + Vector2(0, -s), cor, w)
			draw_line(c + Vector2(0, s * 0.5), c + Vector2(0, -s * 0.15), cor, w)
		"r":  # Escudo
			var pts := PackedVector2Array([
				c + Vector2(-s * 0.7, -s * 0.6), c + Vector2(s * 0.7, -s * 0.6),
				c + Vector2(s * 0.7, s * 0.1), c + Vector2(0, s),
				c + Vector2(-s * 0.7, s * 0.1), c + Vector2(-s * 0.7, -s * 0.6),
			])
			draw_polyline(pts, cor, w)
		"f":  # Diamante
			var pts2 := PackedVector2Array([
				c + Vector2(0, -s), c + Vector2(s * 0.75, 0),
				c + Vector2(0, s), c + Vector2(-s * 0.75, 0), c + Vector2(0, -s),
			])
			draw_polyline(pts2, cor, w)
			draw_line(c + Vector2(-s * 0.75, 0), c + Vector2(s * 0.75, 0), cor, w * 0.7)
		"e":  # Raio
			draw_line(c + Vector2(s * 0.3, -s), c + Vector2(-s * 0.3, 0.0), cor, w)
			draw_line(c + Vector2(-s * 0.3, 0.0), c + Vector2(s * 0.25, s * 0.05), cor, w)
			draw_line(c + Vector2(s * 0.25, s * 0.05), c + Vector2(-s * 0.3, s), cor, w)
		"s":  # Gota tóxica
			draw_line(c + Vector2(0, -s), c + Vector2(s * 0.55, s * 0.15), cor, w)
			draw_line(c + Vector2(0, -s), c + Vector2(-s * 0.55, s * 0.15), cor, w)
			draw_arc(c + Vector2(0, s * 0.15), s * 0.55, 0.0, PI, 14, cor, w)
		"m":  # Carta
			draw_rect(Rect2(c + Vector2(-s * 0.55, -s * 0.8), Vector2(s * 1.1, s * 1.6)), cor, false, w)
			draw_line(c + Vector2(0, -s * 0.3), c + Vector2(s * 0.25, 0), cor, w * 0.8)
			draw_line(c + Vector2(s * 0.25, 0), c + Vector2(0, s * 0.3), cor, w * 0.8)
			draw_line(c + Vector2(0, s * 0.3), c + Vector2(-s * 0.25, 0), cor, w * 0.8)
			draw_line(c + Vector2(-s * 0.25, 0), c + Vector2(0, -s * 0.3), cor, w * 0.8)
		"g":  # Floco de neve
			for i in range(3):
				var a : float = PI * float(i) / 3.0
				var d : Vector2 = Vector2(cos(a), sin(a)) * s
				draw_line(c - d, c + d, cor, w)
		"b":  # Garra tripla
			for i in range(3):
				var off : float = (float(i) - 1.0) * s * 0.5
				draw_line(c + Vector2(off - s * 0.3, -s * 0.7), c + Vector2(off + s * 0.3, s * 0.7), cor, w)
		"t":  # Ampulheta
			draw_line(c + Vector2(-s * 0.6, -s * 0.8), c + Vector2(s * 0.6, -s * 0.8), cor, w)
			draw_line(c + Vector2(-s * 0.6, -s * 0.8), c + Vector2(s * 0.6, s * 0.8), cor, w)
			draw_line(c + Vector2(s * 0.6, -s * 0.8), c + Vector2(-s * 0.6, s * 0.8), cor, w)
			draw_line(c + Vector2(-s * 0.6, s * 0.8), c + Vector2(s * 0.6, s * 0.8), cor, w)
		"x":  # Dado
			draw_rect(Rect2(c + Vector2(-s * 0.7, -s * 0.7), Vector2(s * 1.4, s * 1.4)), cor, false, w)
			draw_circle(c + Vector2(-s * 0.3, -s * 0.3), s * 0.13, cor)
			draw_circle(c, s * 0.13, cor)
			draw_circle(c + Vector2(s * 0.3, s * 0.3), s * 0.13, cor)
		_:
			draw_circle(c, s * 0.3, cor)


# ── FX ───────────────────────────────────────────────────────────────────────

func _draw_fx() -> void:
	for fx_any in _fx:
		var fx : Dictionary = fx_any as Dictionary
		var t : float = float(fx["t"]) / float(fx["dur"])
		var cor : Color = fx["cor"] as Color
		match str(fx["tipo"]):
			"flash":
				var sp : Vector2 = _w2s(fx["pos"] as Vector2)
				draw_circle(sp, 50.0 * _zoom * (0.6 + t), Color(1, 1, 1, 0.75 * (1.0 - t)))
			"shock":
				var sp2 : Vector2 = _w2s(fx["pos"] as Vector2)
				var raio : float = lerpf(24.0, 175.0, ease(t, 0.4)) * _zoom
				draw_arc(sp2, raio, 0.0, TAU, 48, Color(cor.r, cor.g, cor.b, 0.85 * (1.0 - t)), 3.0 * (1.0 - t) + 0.5)
			"spark":
				var p : Vector2 = (fx["pos"] as Vector2) + (fx["vel"] as Vector2) * float(fx["t"])
				var sp3 : Vector2 = _w2s(p)
				draw_circle(sp3, 3.0 * (1.0 - t) * sqrt(_zoom) + 0.5,
						Color(cor.r * 0.4 + 0.6, cor.g * 0.4 + 0.6, cor.b * 0.4 + 0.6, 1.0 - t))
			"surge":
				var a : Vector2 = fx["de"] as Vector2
				var b : Vector2 = fx["para"] as Vector2
				var head : Vector2 = _w2s(a.lerp(b, t))
				var tail : Vector2 = _w2s(a.lerp(b, maxf(t - 0.25, 0.0)))
				draw_line(tail, head, Color(cor.r * 0.5 + 0.5, cor.g * 0.5 + 0.5, cor.b * 0.5 + 0.5, 0.95), 3.5)
				draw_circle(head, 4.5 * sqrt(_zoom), Color(1, 1, 1, 0.9))


# ── UI fixa (header / painel / toast) ────────────────────────────────────────

func _draw_header() -> void:
	var a : float = _abertura_t
	# Barra superior
	draw_rect(Rect2(0, 0, size.x, 52), Color(0.01, 0.015, 0.04, 0.88 * a), true)
	draw_line(Vector2(0, 52), Vector2(size.x, 52), Color(0.35, 0.65, 1.0, 0.25 * a), 1.0)
	draw_string(_fonte, Vector2(18, 33), "NEXO ESTELAR", HORIZONTAL_ALIGNMENT_LEFT, -1, 20, Color(0.70, 0.88, 1.0, a))
	# Cristais
	var cri : String = "◆ %d" % Salvar.cristais
	draw_string(_fonte, Vector2(260, 33), cri, HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color(0.55, 0.95, 1.0, a))
	# Progresso + disponíveis agora
	var prog : String = "%d/%d NÓS" % [_comprados(), _total_nos()]
	draw_string(_fonte, Vector2(380, 33), prog, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(0.65, 0.72, 0.85, 0.9 * a))
	var disp : int = 0
	for tid in Salvar.TALENTOS_INFO.keys():
		if Salvar.pode_comprar_talento(tid as String):
			disp += 1
	if disp > 0:
		var dpls : float = 0.65 + 0.35 * sin(_pulse * 2.8)
		draw_string(_fonte, Vector2(486, 33), "%d DISPONÍVEL%s" % [disp, "" if disp == 1 else "EIS"],
				HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color(0.30, 1.0, 0.55, dpls * a))

	# Botões à direita
	var bx : float = size.x - 110.0
	_botao("fechar", Rect2(bx, 9, 96, 34), "X FECHAR", Color(1.0, 0.45, 0.40), a)
	bx -= 116.0
	var rtxt : String = "CONFIRMA?" if _reset_arm_t > 0.0 else "REDEFINIR"
	var rcor : Color = Color(1.0, 0.25, 0.2) if _reset_arm_t > 0.0 else Color(0.75, 0.65, 0.40)
	_botao("reset", Rect2(bx, 9, 106, 34), rtxt, rcor, a)
	bx -= 116.0
	_botao("classico", Rect2(bx, 9, 106, 34), "ASCENSÃO", Color(1.0, 0.82, 0.25), a)
	bx -= 88.0
	_botao("centro", Rect2(bx, 9, 78, 34), "CENTRO", Color(0.55, 0.80, 1.0), a)
	bx -= 50.0
	_botao("zoom_in", Rect2(bx, 9, 40, 34), "+", Color(0.55, 0.80, 1.0), a)
	bx -= 46.0
	_botao("zoom_out", Rect2(bx, 9, 40, 34), "-", Color(0.55, 0.80, 1.0), a)


func _botao(nome: String, r: Rect2, txt: String, cor: Color, a: float) -> void:
	_ui_hit[nome] = r
	var hover : bool = r.has_point(get_local_mouse_position())
	draw_rect(r, Color(cor.r * 0.12, cor.g * 0.12, cor.b * 0.12, (0.85 if hover else 0.6) * a), true)
	draw_rect(r, Color(cor.r, cor.g, cor.b, (0.9 if hover else 0.45) * a), false, 1.4)
	var fs : int = 14
	var w : float = _fonte.get_string_size(txt, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
	draw_string(_fonte, r.position + Vector2((r.size.x - w) * 0.5, r.size.y * 0.5 + 5.0), txt,
			HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color(cor.r, cor.g, cor.b, (1.0 if hover else 0.85) * a))


func _draw_painel() -> void:
	if _sel_id == "" or not Salvar.TALENTOS_INFO.has(_sel_id):
		return
	var info : Dictionary = Salvar.TALENTOS_INFO[_sel_id] as Dictionary
	var cor : Color = _cor_no(_sel_id)
	var pw : float = minf(330.0, size.x * 0.42)
	# Lado fixado na seleção (_painel_esq) — zoom/pan não movem o painel
	var px : float = (14.0) if _painel_esq else (size.x - pw - 14.0)
	var py : float = 66.0
	var ph : float = 268.0
	var r := Rect2(px, py, pw, ph)
	# SEM hitbox de fundo: cliques atravessam o painel até o mapa — o painel
	# nunca rouba o clique de um nó (só o botão DESBLOQUEAR captura)

	draw_rect(r, Color(0.012, 0.02, 0.05, 0.94), true)
	draw_rect(r, Color(cor.r, cor.g, cor.b, 0.55), false, 1.5)
	draw_line(r.position + Vector2(0, 46), r.position + Vector2(pw, 46), Color(cor.r, cor.g, cor.b, 0.30), 1.0)

	# Título + categoria
	var nome : String = str(info.get("nome", _sel_id)).replace("\n", " ")
	draw_string(_fonte, r.position + Vector2(14, 30), nome, HORIZONTAL_ALIGNMENT_LEFT, -1, 19, cor)
	var cat : String
	if _sel_id == "raiz":               cat = "NÚCLEO"
	elif _fusoes.has(_sel_id):          cat = "FUSÃO CROSS-RAMO"
	elif LEGADO.has(_sel_id):           cat = "LEGADO"
	elif SITUACIONAIS.has(_sel_id):     cat = "SITUACIONAL"
	else:
		var br : String = _ramo_de.get(_sel_id, "") as String
		cat = "RAMO %s" % BRANCH_NOMES.get(br, br.to_upper())
	draw_string(_fonte, r.position + Vector2(14, 42), cat, HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color(0.6, 0.68, 0.82, 0.85))

	# Efeito (texto completo)
	var efeito : String = str(info.get("efeito", info.get("desc", "")))
	draw_multiline_string(_fonte, r.position + Vector2(14, 68), efeito,
			HORIZONTAL_ALIGNMENT_LEFT, pw - 28.0, 13, 6, Color(0.82, 0.87, 0.97, 0.95))

	# Rodapé: custo + botão / estado
	var ativo : bool = Salvar.talento_ativo(_sel_id)
	var by : float = py + ph - 52.0
	if ativo:
		draw_string(_fonte, Vector2(px + 14, by + 30), "✓ ATIVO", HORIZONTAL_ALIGNMENT_LEFT, -1, 17, Color(0.30, 1.0, 0.55))
	elif _sel_id == "raiz":
		draw_string(_fonte, Vector2(px + 14, by + 30), "SEMPRE ATIVO", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(1.0, 0.85, 0.35))
	else:
		var custo : int = Salvar.custo_efetivo_talento(_sel_id)
		var pode : bool = Salvar.pode_comprar_talento(_sel_id)
		if pode:
			_botao("comprar", Rect2(px + 14, by, pw - 28.0, 40), "DESBLOQUEAR  —  ◆ %d" % custo, Color(0.25, 1.0, 0.50), 1.0)
		else:
			var motivo : String = _motivo_bloqueio(_sel_id, custo)
			draw_rect(Rect2(px + 14, by, pw - 28.0, 40), Color(0.5, 0.2, 0.2, 0.20), true)
			draw_rect(Rect2(px + 14, by, pw - 28.0, 40), Color(1.0, 0.4, 0.35, 0.40), false, 1.2)
			draw_multiline_string(_fonte, Vector2(px + 24, by + 17), motivo,
					HORIZONTAL_ALIGNMENT_LEFT, pw - 48.0, 11, 2, Color(1.0, 0.62, 0.55, 0.95))


func _motivo_bloqueio(id: String, custo: int) -> String:
	var partes : Array = []
	for r_any in Salvar.requisitos_talento(id):
		var rid : String = r_any as String
		if not Salvar.talento_ativo(rid):
			var rinfo : Dictionary = Salvar.TALENTOS_INFO.get(rid, {}) as Dictionary
			partes.append("Requer %s" % str(rinfo.get("nome", rid)).replace("\n", " "))
	match id:
		"veteran":
			if not _req_conquista_ok(id): partes.append("Requer 100 partidas (%d)" % Salvar.total_partidas)
		"genoci":
			if not _req_conquista_ok(id): partes.append("Requer 10.000 kills (%d)" % Salvar.total_mobs_mortos)
		"sobrev":
			if not _req_conquista_ok(id): partes.append("Requer wave 30 (melhor: %d)" % Salvar.melhor_wave)
	if partes.is_empty() and Salvar.cristais < custo:
		partes.append("Faltam ◆ %d cristais" % (custo - Salvar.cristais))
	if partes.is_empty():
		partes.append("Bloqueado")
	return " · ".join(PackedStringArray(partes))


func _draw_toast() -> void:
	if _toast_t <= 0.0:
		return
	var a : float = clampf(_toast_t / 0.4, 0.0, 1.0)
	var fs : int = 15
	var w : float = _fonte.get_string_size(_toast_txt, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
	var r := Rect2(size.x * 0.5 - w * 0.5 - 18.0, size.y - 96.0, w + 36.0, 36.0)
	draw_rect(r, Color(0.02, 0.03, 0.07, 0.92 * a), true)
	draw_rect(r, Color(0.45, 0.75, 1.0, 0.5 * a), false, 1.2)
	draw_string(_fonte, r.position + Vector2(18.0, 24.0), _toast_txt, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color(0.85, 0.92, 1.0, a))
