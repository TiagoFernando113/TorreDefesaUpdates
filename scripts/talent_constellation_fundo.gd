extends Control

var groups: Array = []
var positions: Dictionary = {}
var states: Dictionary = {}
var fusion_recipes: Array = []
var node_titles: Dictionary = {}
var pulse: float = 0.0

const MAJOR_IDS: Array = [
	"raiz", "p3", "p5", "b4", "r3", "token", "r5", "t4", "e4", "e5",
	"g4", "s4", "s5", "m4", "f5", "x4", "colosso", "predador", "alquim",
	"tita", "relamp", "canhao_g",
]
const ROOT_BRANCH_STARTS: Array = [
	"m1", "f1", "p1", "t1", "e1", "s1", "x1", "g1", "r1", "b1",
]


var _cached_font: Font = null

func setup(groups_in: Array, positions_in: Dictionary, states_in: Dictionary, fusion_recipes_in: Array = [], node_titles_in: Dictionary = {}) -> void:
	groups = groups_in
	positions = positions_in
	states = states_in
	fusion_recipes = fusion_recipes_in
	node_titles = node_titles_in
	_cached_font = get_theme_default_font()
	queue_redraw()


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE


var _redraw_acc: float = 0.0
const REDRAW_INTERVAL: float = 0.05  # 20 fps — suficiente para animacao suave

func _process(delta: float) -> void:
	pulse += delta
	_redraw_acc += delta
	if _redraw_acc >= REDRAW_INTERVAL:
		_redraw_acc -= REDRAW_INTERVAL
		queue_redraw()


func _draw() -> void:
	if positions.is_empty():
		return
	_draw_system_backplate()
	for group_any in groups:
		_draw_group_links(group_any as Dictionary)
	_draw_root_links()
	_draw_fusion_links()
	for group_any in groups:
		_draw_group_nodes(group_any as Dictionary)
	_draw_fusion_gates()
	if positions.has("raiz"):
		_draw_node("raiz", positions["raiz"] as Vector2, Color(1.0, 0.78, 0.20), true)


func _draw_system_backplate() -> void:
	var area: Rect2 = _tree_area().grow(58.0).intersection(Rect2(Vector2.ZERO, size))
	draw_rect(area, Color(0.002, 0.004, 0.010, 0.18), true)
	for i in range(110):
		var x: float = fmod(float(i * 97 + 31), maxf(1.0, size.x))
		var y: float = fmod(float(i * i * 43 + 19), maxf(1.0, size.y))
		var twinkle: float = 0.36 + 0.24 * sin(pulse * 0.8 + float(i) * 1.7)
		draw_circle(Vector2(x, y), 0.7 + float(i % 3) * 0.18, Color(0.45, 0.76, 1.0, twinkle * 0.16))
	if area.size.x > 0.0 and area.size.y > 0.0:
		_draw_corner_brackets(area, Color(0.36, 0.68, 1.0, 0.16), 30.0)


func _tree_area() -> Rect2:
	var first := true
	var min_p := Vector2.ZERO
	var max_p := Vector2.ZERO
	for p_any in positions.values():
		var p: Vector2 = p_any as Vector2
		if first:
			min_p = p
			max_p = p
			first = false
		else:
			min_p.x = minf(min_p.x, p.x)
			min_p.y = minf(min_p.y, p.y)
			max_p.x = maxf(max_p.x, p.x)
			max_p.y = maxf(max_p.y, p.y)
	if first:
		return Rect2(Vector2.ZERO, size)
	return Rect2(min_p, max_p - min_p)


func _draw_corner_brackets(rect: Rect2, color: Color, len: float) -> void:
	var corners := [
		rect.position,
		Vector2(rect.end.x, rect.position.y),
		rect.end,
		Vector2(rect.position.x, rect.end.y),
	]
	var dirs := [
		[Vector2.RIGHT, Vector2.DOWN],
		[Vector2.LEFT, Vector2.DOWN],
		[Vector2.LEFT, Vector2.UP],
		[Vector2.RIGHT, Vector2.UP],
	]
	for i in range(4):
		var p: Vector2 = corners[i]
		var d: Array = dirs[i]
		draw_line(p, p + (d[0] as Vector2) * len, color, 1.35, true)
		draw_line(p, p + (d[1] as Vector2) * len, color, 1.35, true)


func _draw_fusion_links() -> void:
	if fusion_recipes.is_empty():
		return
	for rec_any in fusion_recipes:
		var rec: Dictionary = rec_any as Dictionary
		var id: String = rec.get("id", "") as String
		var reqs: Array = rec.get("reqs", []) as Array
		if id == "" or not positions.has(id):
			continue
		var gate: Vector2 = positions[id] as Vector2
		var gate_state: Dictionary = states.get(id, {}) as Dictionary
		var gate_active: bool = gate_state.get("active", false) == true
		var gate_available: bool = gate_state.get("available", false) == true
		var alpha: float = 0.20 if gate_active else (0.16 if gate_available else 0.07)
		var gate_color: Color = _state_color(id, Color(1.0, 0.72, 0.18))
		for req_any in reqs:
			var req_id: String = req_any as String
			if not positions.has(req_id):
				continue
			var req_pos: Vector2 = positions[req_id] as Vector2
			_draw_orthogonal_link(req_pos, gate, gate_color, alpha, 1.25)


func _draw_energy_curve(a: Vector2, b: Vector2, c: Vector2, color: Color, alpha: float) -> void:
	var pts := PackedVector2Array()
	for i in range(18):
		var t: float = float(i) / 17.0
		var p: Vector2 = a.lerp(b, t).lerp(b.lerp(c, t), t)
		pts.append(p)
	if pts.size() < 2:
		return
	draw_polyline(pts, Color(color.r, color.g, color.b, alpha * 0.16), 7.0, true)
	draw_polyline(pts, Color(color.r, color.g, color.b, alpha * 0.68), 1.7, true)
	draw_polyline(pts, Color(1.0, 1.0, 1.0, alpha * 0.42), 0.75, true)


func _draw_fusion_gates() -> void:
	if fusion_recipes.is_empty():
		return
	var font: Font = _cached_font if _cached_font != null else get_theme_default_font()
	for rec_any in fusion_recipes:
		var rec: Dictionary = rec_any as Dictionary
		var id: String = rec.get("id", "") as String
		if id == "" or not positions.has(id):
			continue
		var reqs: Array = rec.get("reqs", []) as Array
		_draw_fusion_gate(id, positions[id] as Vector2, reqs, font)


func _draw_fusion_gate(id: String, pos: Vector2, reqs: Array, font: Font) -> void:
	var state: Dictionary = states.get(id, {}) as Dictionary
	var active: bool = state.get("active", false) == true
	var available: bool = state.get("available", false) == true
	var blocked: bool = not active and not available
	var color: Color = _state_color(id, Color(1.0, 0.72, 0.18))
	if blocked:
		color = Color(0.44, 0.38, 0.24, 0.70)
	var wave: float = sin(pulse * 3.4 + pos.x * 0.02) * 0.5 + 0.5
	var r: float = 17.0
	var glow: float = 0.26 if active else (0.20 if available else 0.07)
	for i in range(4, 0, -1):
		draw_circle(pos, r + float(i) * 5.0, Color(color.r, color.g, color.b, glow * (0.55 + wave * 0.45) / float(i) * 0.22))
	var diamond := PackedVector2Array([
		pos + Vector2(0.0, -r - 6.0),
		pos + Vector2(r + 6.0, 0.0),
		pos + Vector2(0.0, r + 6.0),
		pos + Vector2(-r - 6.0, 0.0),
	])
	draw_colored_polygon(diamond, Color(0.014, 0.010, 0.020, 0.94))
	var closed := PackedVector2Array(diamond)
	closed.append(diamond[0])
	draw_polyline(closed, Color(color.r, color.g, color.b, 0.84 if not blocked else 0.36), 1.7, true)
	draw_arc(pos, r + 2.0, -pulse * 0.9, -pulse * 0.9 + TAU * 0.82, 48, Color(color.r, color.g, color.b, 0.46 if not blocked else 0.14), 1.1)
	_draw_star(pos, 8.5, Color(color.r, color.g, color.b, 0.96 if not blocked else 0.38))
	for i in range(reqs.size()):
		var a: float = -PI * 0.5 + float(i) * TAU / maxf(3.0, float(reqs.size()))
		var p: Vector2 = pos + Vector2(cos(a), sin(a)) * 31.0
		draw_circle(p, 2.5, Color(color.r, color.g, color.b, 0.72 if not blocked else 0.22))
	if font != null:
		draw_string(font, pos + Vector2(-42.0, 34.0), "FUSAO", HORIZONTAL_ALIGNMENT_CENTER, 84.0, 8, Color(color.r, color.g, color.b, 0.42 if not blocked else 0.18))


func _state_color(id: String, fallback: Color) -> Color:
	var state: Dictionary = states.get(id, {}) as Dictionary
	if state.has("color"):
		return state["color"] as Color
	for group_any in groups:
		var group: Dictionary = group_any as Dictionary
		if (group.get("points", []) as Array).has(id):
			return group.get("color", fallback) as Color
	return fallback


func _draw_root_links() -> void:
	if not positions.has("raiz"):
		return
	var root: Vector2 = positions["raiz"] as Vector2
	var start_points: Array = []
	var min_x: float = 1000000.0
	var min_y: float = 1000000.0
	var max_y: float = -1000000.0
	for id_any in ROOT_BRANCH_STARTS:
		var id: String = id_any as String
		if not positions.has(id):
			continue
		var p: Vector2 = positions[id] as Vector2
		start_points.append([id, p])
		min_x = minf(min_x, p.x)
		min_y = minf(min_y, p.y)
		max_y = maxf(max_y, p.y)
	if start_points.is_empty():
		return
	var trunk_start_x: float = root.x + 54.0
	var trunk_end_x: float = clampf(min_x - 34.0, root.x + 76.0, root.x + 190.0)
	var trunk_x: float = trunk_end_x
	var trunk_color := Color(0.54, 0.68, 0.86)
	var root_exit: Vector2 = _card_anchor("raiz", Vector2(trunk_start_x, root.y))
	_draw_path([root_exit, Vector2(trunk_start_x, root.y), Vector2(trunk_x, root.y)], trunk_color, 0.20, 1.10)
	_draw_line(Vector2(trunk_x, min_y), Vector2(trunk_x, max_y), trunk_color, 0.075, 0.75)

	var sorted_points: Array = start_points.duplicate(true)
	sorted_points.sort_custom(func(a: Array, b: Array) -> bool:
		return (a[1] as Vector2).y < (b[1] as Vector2).y
	)
	for item_any in sorted_points:
		var item: Array = item_any as Array
		var id: String = item[0] as String
		var p: Vector2 = item[1] as Vector2
		var branch_color: Color = _link_state_color("raiz", id)
		var elbow := Vector2(trunk_x, p.y)
		var start: Vector2 = _card_anchor(id, elbow)
		var alpha: float = _link_alpha("raiz", id)
		_draw_path([elbow, start], branch_color, alpha, 1.0)


func _draw_group_links(group: Dictionary) -> void:
	var lines: Array = group.get("lines", []) as Array
	for line_any in lines:
		var line: Array = line_any as Array
		if line.size() < 2:
			continue
		var a_id: String = line[0] as String
		var b_id: String = line[1] as String
		if positions.has(a_id) and positions.has(b_id):
			_draw_circuit_link(a_id, b_id, _link_state_color(a_id, b_id), _link_alpha(a_id, b_id), 1.25)


func _draw_group_nodes(group: Dictionary) -> void:
	var color: Color = group.get("color", Color(0.55, 0.82, 1.0)) as Color
	var points: Array = group.get("points", []) as Array
	for id_any in points:
		var id: String = id_any as String
		if positions.has(id):
			_draw_node(id, positions[id] as Vector2, color, MAJOR_IDS.has(id))


func _draw_line(a: Vector2, b: Vector2, color: Color, alpha: float, width: float) -> void:
	draw_line(a, b, Color(color.r, color.g, color.b, alpha * 0.12), width + 7.0, true)
	draw_line(a, b, Color(color.r, color.g, color.b, alpha * 0.46), width + 1.8, true)
	draw_line(a, b, Color(1.0, 1.0, 1.0, alpha * 0.30), 0.85, true)


func _draw_circuit_link(a_id: String, b_id: String, color: Color, alpha: float, width: float) -> void:
	var a_center: Vector2 = positions[a_id] as Vector2
	var b_center: Vector2 = positions[b_id] as Vector2
	var a: Vector2 = _card_anchor(a_id, b_center)
	var b: Vector2 = _card_anchor(b_id, a_center)
	if absf(a.y - b.y) < 7.0 or absf(a.x - b.x) < 7.0:
		_draw_line(a, b, color, alpha, width)
		return
	var mid_x: float = lerpf(a.x, b.x, 0.50)
	_draw_path([a, Vector2(mid_x, a.y), Vector2(mid_x, b.y), b], color, alpha, width)


func _draw_path(points: Array, color: Color, alpha: float, width: float) -> void:
	if points.size() < 2:
		return
	for i in range(points.size() - 1):
		_draw_line(points[i] as Vector2, points[i + 1] as Vector2, color, alpha, width)


func _draw_orthogonal_link(a: Vector2, b: Vector2, color: Color, alpha: float, width: float) -> void:
	if absf(a.x - b.x) < 4.0 or absf(a.y - b.y) < 4.0:
		_draw_line(a, b, color, alpha, width)
		return
	var mid_x: float = lerpf(a.x, b.x, 0.54)
	_draw_path([a, Vector2(mid_x, a.y), Vector2(mid_x, b.y), b], color, alpha, width)


func _draw_node(id: String, pos: Vector2, base_color: Color, major: bool) -> void:
	var state: Dictionary = states.get(id, {}) as Dictionary
	var active: bool = state.get("active", false) == true
	var available: bool = state.get("available", false) == true
	var root: bool = id == "raiz"
	var blocked: bool = not root and not active and not available
	var color: Color = _node_state_color(id, base_color)
	if blocked:
		color = Color(0.35, 0.42, 0.54, 0.90)
	elif available and not active:
		color = Color(0.42, 0.96, 1.0, 1.0)
	elif active:
		color = Color(1.0, 0.60, 0.12, 1.0)

	if root:
		_draw_research_card(id, pos, color, true, true, false)
		return

	_draw_research_card(id, pos, color, major, active, available)


func _node_rect(id: String, pos: Vector2, major: bool = false, root: bool = false) -> Rect2:
	var scale: float = clampf(size.x / 1280.0, 0.76, 1.04)
	var w: float = 96.0 if root else (136.0 if major else 118.0)
	var h: float = 48.0 if root else (42.0 if major else 36.0)
	return Rect2(pos - Vector2(w * scale, h * scale) * 0.5, Vector2(w * scale, h * scale))


func _card_anchor(id: String, target: Vector2) -> Vector2:
	if not positions.has(id):
		return target
	var pos: Vector2 = positions[id] as Vector2
	var rect: Rect2 = _node_rect(id, pos, MAJOR_IDS.has(id), id == "raiz")
	var d: Vector2 = target - rect.get_center()
	if absf(d.x) > absf(d.y):
		return Vector2(rect.end.x if d.x >= 0.0 else rect.position.x, rect.get_center().y)
	return Vector2(rect.get_center().x, rect.end.y if d.y >= 0.0 else rect.position.y)


func _link_state_color(a_id: String, b_id: String) -> Color:
	var a_state: Dictionary = states.get(a_id, {}) as Dictionary
	var b_state: Dictionary = states.get(b_id, {}) as Dictionary
	var a_active: bool = a_id == "raiz" or a_state.get("active", false) == true
	var b_active: bool = b_id == "raiz" or b_state.get("active", false) == true
	var b_available: bool = b_state.get("available", false) == true
	if a_active and b_active:
		return Color(1.0, 0.58, 0.12)
	if a_active and b_available:
		return Color(0.24, 0.88, 1.0)
	return Color(0.34, 0.47, 0.64)


func _link_alpha(a_id: String, b_id: String) -> float:
	var a_state: Dictionary = states.get(a_id, {}) as Dictionary
	var b_state: Dictionary = states.get(b_id, {}) as Dictionary
	var a_active: bool = a_id == "raiz" or a_state.get("active", false) == true
	var b_active: bool = b_id == "raiz" or b_state.get("active", false) == true
	var b_available: bool = b_state.get("available", false) == true
	if a_active and b_active:
		return 0.48
	if a_active and b_available:
		return 0.42
	return 0.14


func _node_state_color(id: String, fallback: Color) -> Color:
	if id == "raiz":
		return Color(1.0, 0.88, 0.20)
	var state: Dictionary = states.get(id, {}) as Dictionary
	if state.get("active", false) == true:
		return Color(1.0, 0.58, 0.12)
	if state.get("available", false) == true:
		return Color(0.24, 0.88, 1.0)
	return Color(0.38, 0.48, 0.62)


func _draw_research_card(id: String, pos: Vector2, color: Color, major: bool, active: bool, available: bool) -> void:
	var root: bool = id == "raiz"
	var rect: Rect2 = _node_rect(id, pos, major, root)
	var blocked: bool = not root and not active and not available
	var font: Font = _cached_font if _cached_font != null else get_theme_default_font()
	var bg: Color = Color(0.015, 0.022, 0.036, 0.92)
	if active:
		bg = Color(0.085, 0.050, 0.016, 0.94)
	elif available:
		bg = Color(0.010, 0.050, 0.070, 0.94)
	elif blocked:
		bg = Color(0.010, 0.014, 0.024, 0.90)

	var cut: float = minf(rect.size.y * 0.32, 10.0)
	var poly: PackedVector2Array = _cut_card_points(rect, cut)
	if active or available or root:
		for i in range(4, 0, -1):
			draw_colored_polygon(_cut_card_points(rect.grow(float(i) * 2.3), cut + float(i)), Color(color.r, color.g, color.b, 0.020 * float(i)))
	draw_colored_polygon(poly, bg)
	var closed: PackedVector2Array = PackedVector2Array(poly)
	closed.append(poly[0])
	draw_polyline(closed, Color(color.r, color.g, color.b, 0.92 if not blocked else 0.40), 1.45, true)
	draw_polyline(_cut_card_points(rect.grow(-3.0), maxf(3.0, cut - 2.0)), Color(1.0, 1.0, 1.0, 0.10 if blocked else 0.22), 0.75, true)

	var accent: Rect2 = Rect2(rect.position + Vector2(3.0, rect.size.y - 5.0), Vector2(rect.size.x - 6.0, 2.0))
	draw_rect(accent, Color(color.r, color.g, color.b, 0.45 if not blocked else 0.16), true)
	var icon_center: Vector2 = rect.position + Vector2(rect.size.y * 0.52, rect.size.y * 0.50)
	var icon_r: float = rect.size.y * (0.30 if root else 0.25)
	draw_circle(icon_center, icon_r + 8.0, Color(color.r, color.g, color.b, 0.08 if blocked else 0.18))
	draw_circle(icon_center, icon_r, Color(0.0, 0.0, 0.0, 0.45))
	draw_arc(icon_center, icon_r + 2.0, -PI * 0.5, PI * 1.5, 28, Color(color.r, color.g, color.b, 0.70 if not blocked else 0.30), 1.3, true)
	_draw_node_icon(id, icon_center, icon_r, color, blocked)

	if font != null:
		var title_info: Dictionary = node_titles.get(id, {}) as Dictionary
		var title: String = str(title_info.get("title", "INICIO" if root else id)).strip_edges().to_upper()
		var sub: String = str(title_info.get("sub", "")).strip_edges().to_upper()
		var state_txt: String = "INICIO" if root else ("OK" if active else ("LIB" if available else "LOCK"))
		var text_x: float = rect.position.x + rect.size.y * 0.90
		var text_w: float = rect.size.x - (text_x - rect.position.x) - 8.0
		var title_lines: PackedStringArray = _wrap_card_text(title, 13 if major else 11, 2)
		var sub_lines: PackedStringArray = _wrap_card_text(sub, 14 if major else 12, 1)
		var line_size: int = 8 if root else 7
		var line_gap: float = 8.0 if root else 7.4
		var total_h: float = float(title_lines.size()) * line_gap + (7.0 if not sub_lines.is_empty() else 0.0)
		var line_y: float = rect.position.y + maxf(9.0, (rect.size.y - total_h) * 0.5 + line_size)
		for title_line in title_lines:
			draw_string(font, Vector2(text_x, line_y), title_line, HORIZONTAL_ALIGNMENT_CENTER, text_w, line_size, Color(0.88, 0.94, 1.0, 0.95 if not blocked else 0.42))
			line_y += line_gap
		if not sub_lines.is_empty():
			draw_string(font, Vector2(text_x, line_y + 0.5), sub_lines[0], HORIZONTAL_ALIGNMENT_CENTER, text_w, 6, Color(color.r, color.g, color.b, 0.72 if not blocked else 0.24))
		draw_string(font, rect.position + Vector2(rect.size.x - 34.0, rect.size.y - 10.0), state_txt, HORIZONTAL_ALIGNMENT_RIGHT, 28.0, 6, Color(color.r, color.g, color.b, 0.82 if not blocked else 0.32))


func _cut_card_points(rect: Rect2, cut: float) -> PackedVector2Array:
	var p0: Vector2 = rect.position
	var p1: Vector2 = rect.end
	return PackedVector2Array([
		Vector2(p0.x + cut, p0.y),
		Vector2(p1.x - cut, p0.y),
		Vector2(p1.x, p0.y + cut),
		Vector2(p1.x, p1.y - cut),
		Vector2(p1.x - cut, p1.y),
		Vector2(p0.x + cut, p1.y),
		Vector2(p0.x, p1.y - cut),
		Vector2(p0.x, p0.y + cut),
	])


func _clip_text(text: String, max_chars: int) -> String:
	var clean: String = text.strip_edges().replace("\n", " ")
	if clean.length() <= max_chars:
		return clean
	return clean.substr(0, maxi(1, max_chars - 1)) + "."


func _wrap_card_text(text: String, max_chars: int, max_lines: int) -> PackedStringArray:
	var clean: String = text.strip_edges().replace("\n", " ")
	var out: PackedStringArray = PackedStringArray()
	if clean == "" or max_lines <= 0:
		return out
	var words: PackedStringArray = clean.split(" ", false)
	var current: String = ""
	for word in words:
		var part: String = _clip_text(word, max_chars) if word.length() > max_chars else word
		var candidate: String = part if current == "" else current + " " + part
		if candidate.length() <= max_chars:
			current = candidate
			continue
		if current != "":
			out.append(current)
		current = part
		if out.size() >= max_lines:
			break
	if current != "" and out.size() < max_lines:
		out.append(current)
	if out.is_empty():
		out.append(_clip_text(clean, max_chars))
	return out


func _node_glyph(id: String) -> String:
	if id == "raiz":
		return "LAB"
	if id.begins_with("p"):
		return "DMG"
	if id.begins_with("r"):
		return "DEF"
	if id.begins_with("f"):
		return "$"
	if id.begins_with("e"):
		return "EN"
	if id.begins_with("s"):
		return "VX"
	if id.begins_with("m"):
		return "CMD"
	if id.begins_with("g"):
		return "ICE"
	if id.begins_with("b"):
		return "RISK"
	if id.begins_with("t"):
		return "TMP"
	if id.begins_with("x"):
		return "RNG"
	return "+"


func _draw_node_icon(id: String, center: Vector2, r: float, color: Color, blocked: bool) -> void:
	var alpha: float = 0.36 if blocked else 0.96
	var c: Color = Color(color.r, color.g, color.b, alpha)
	var soft: Color = Color(color.r, color.g, color.b, alpha * 0.20)
	draw_circle(center, r * 0.40, soft)
	match _node_icon_kind(id):
		"lab":
			_draw_icon_lab(center, r, c)
		"dano":
			_draw_icon_crosshair(center, r, c)
		"crosshair":
			_draw_icon_crosshair(center, r, c)
		"defesa":
			_draw_icon_shield(center, r, c)
		"fortuna":
			_draw_icon_coin(center, r, c)
		"energia":
			_draw_icon_lightning(center, r, c)
		"sombra":
			_draw_icon_crescent(center, r, c)
		"comando":
			_draw_icon_crown(center, r, c)
		"glacial":
			_draw_icon_snow(center, r, c)
		"risco":
			_draw_icon_flame(center, r, c)
		"temporal":
			_draw_icon_hourglass(center, r, c)
		"caos":
			_draw_icon_dice(center, r, c)
		"fusion":
			_draw_icon_fusion(center, r, c)
		"rapid":
			_draw_icon_chevrons(center, r, c)
		"double_shot":
			_draw_icon_double_barrel(center, r, c)
		"missile":
			_draw_icon_missile(center, r, c)
		"heart":
			_draw_icon_heart(center, r, c)
		"phoenix":
			_draw_icon_wing(center, r, c)
		"wall":
			_draw_icon_wall(center, r, c)
		"vault":
			_draw_icon_vault(center, r, c)
		"credit":
			_draw_icon_credit(center, r, c)
		"converter":
			_draw_icon_converter(center, r, c)
		"crystal":
			_draw_icon_crystal(center, r, c)
		"radar":
			_draw_icon_radar(center, r, c)
		"cards":
			_draw_icon_cards(center, r, c)
		"eye":
			_draw_icon_eye(center, r, c)
		"acid":
			_draw_icon_acid(center, r, c)
		"plague":
			_draw_icon_plague(center, r, c)
		"infinity":
			_draw_icon_infinity(center, r, c)
		"avalanche":
			_draw_icon_avalanche(center, r, c)
		"pulse":
			_draw_icon_pulse(center, r, c)
		"boss":
			_draw_icon_skull(center, r, c)
		"rewind":
			_draw_icon_rewind(center, r, c)
		"explosion":
			_draw_icon_explosion(center, r, c)
		"medal":
			_draw_icon_medal(center, r, c)
		"hybrid_colosso":
			_draw_icon_shield(center + Vector2(-r * 0.14, 0.0), r * 0.72, c)
			_draw_icon_crosshair(center + Vector2(r * 0.18, 0.0), r * 0.62, c)
		"hybrid_predador":
			_draw_icon_acid(center + Vector2(-r * 0.15, 0.0), r * 0.72, c)
			_draw_icon_snow(center + Vector2(r * 0.18, 0.0), r * 0.56, c)
		"hybrid_alquim":
			_draw_icon_flask(center, r, c)
		"hybrid_tita":
			_draw_icon_wall(center + Vector2(-r * 0.10, 0.0), r * 0.70, c)
			_draw_icon_crown(center + Vector2(r * 0.16, -r * 0.02), r * 0.60, c)
		"hybrid_relamp":
			_draw_icon_lightning(center + Vector2(-r * 0.14, 0.0), r * 0.72, c)
			_draw_icon_crescent(center + Vector2(r * 0.18, 0.0), r * 0.58, c)
		"hybrid_cannon_ice":
			_draw_icon_double_barrel(center + Vector2(-r * 0.10, 0.0), r * 0.68, c)
			_draw_icon_snow(center + Vector2(r * 0.22, 0.0), r * 0.52, c)
		_:
			_draw_icon_star(center, r, c)


func _node_icon_kind(id: String) -> String:
	if id == "raiz":
		return "lab"
	var by_id: Dictionary = {
		"p1": "flame",
		"p2": "rapid",
		"p3": "double_shot",
		"p4": "missile",
		"p5": "flame",
		"r1": "defesa",
		"r2": "heart",
		"r3": "phoenix",
		"r4": "wall",
		"r5": "defesa",
		"token": "defesa",
		"f1": "fortuna",
		"f2": "credit",
		"f3": "converter",
		"f4": "crystal",
		"f5": "vault",
		"e1": "energia",
		"e2": "pulse",
		"e3": "explosion",
		"e4": "eye",
		"e5": "energia",
		"s1": "sombra",
		"s2": "acid",
		"s3": "plague",
		"s4": "infinity",
		"m1": "radar",
		"m2": "crystal",
		"m3": "rewind",
		"m4": "cards",
		"g1": "glacial",
		"g2": "avalanche",
		"g3": "avalanche",
		"g4": "pulse",
		"b1": "acid",
		"b2": "rapid",
		"b3": "fortuna",
		"b4": "explosion",
		"t1": "temporal",
		"t2": "pulse",
		"t3": "boss",
		"t4": "rewind",
		"x1": "caos",
		"x2": "star",
		"x3": "rewind",
		"x4": "cards",
		"cazador": "boss",
		"exter": "explosion",
		"anti_t": "crosshair",
		"purif": "heart",
		"veteran": "medal",
		"genoci": "boss",
		"sobrev": "heart",
		"colosso": "hybrid_colosso",
		"predador": "hybrid_predador",
		"alquim": "hybrid_alquim",
		"tita": "hybrid_tita",
		"relamp": "hybrid_relamp",
		"canhao_g": "hybrid_cannon_ice",
	}
	if by_id.has(id):
		return by_id[id] as String
	if id.begins_with("p"):
		return "dano"
	if id.begins_with("r"):
		return "defesa"
	if id.begins_with("f"):
		return "fortuna"
	if id.begins_with("e"):
		return "energia"
	if id.begins_with("s"):
		return "sombra"
	if id.begins_with("m"):
		return "comando"
	if id.begins_with("g"):
		return "glacial"
	if id.begins_with("b"):
		return "risco"
	if id.begins_with("t"):
		return "temporal"
	if id.begins_with("x"):
		return "caos"
	return "tech"


func _draw_icon_lab(c: Vector2, r: float, color: Color) -> void:
	var pts: PackedVector2Array = _hex_points(c, r * 0.54)
	var closed: PackedVector2Array = PackedVector2Array(pts)
	closed.append(pts[0])
	draw_polyline(closed, color, 1.5, true)
	draw_line(c + Vector2(-r * 0.32, 0.0), c + Vector2(r * 0.32, 0.0), color, 1.3, true)
	draw_line(c + Vector2(0.0, -r * 0.32), c + Vector2(0.0, r * 0.32), color, 1.3, true)
	draw_circle(c, r * 0.08, color)


func _draw_icon_crosshair(c: Vector2, r: float, color: Color) -> void:
	draw_arc(c, r * 0.48, 0.0, TAU, 32, color, 1.4, true)
	draw_line(c + Vector2(-r * 0.64, 0.0), c + Vector2(-r * 0.26, 0.0), color, 1.3, true)
	draw_line(c + Vector2(r * 0.26, 0.0), c + Vector2(r * 0.64, 0.0), color, 1.3, true)
	draw_line(c + Vector2(0.0, -r * 0.64), c + Vector2(0.0, -r * 0.26), color, 1.3, true)
	draw_line(c + Vector2(0.0, r * 0.26), c + Vector2(0.0, r * 0.64), color, 1.3, true)
	draw_circle(c, r * 0.08, color)


func _draw_icon_shield(c: Vector2, r: float, color: Color) -> void:
	var pts: PackedVector2Array = PackedVector2Array()
	pts.append(c + Vector2(0.0, -r * 0.62))
	pts.append(c + Vector2(r * 0.48, -r * 0.34))
	pts.append(c + Vector2(r * 0.36, r * 0.28))
	pts.append(c + Vector2(0.0, r * 0.64))
	pts.append(c + Vector2(-r * 0.36, r * 0.28))
	pts.append(c + Vector2(-r * 0.48, -r * 0.34))
	pts.append(c + Vector2(0.0, -r * 0.62))
	draw_polyline(pts, color, 1.5, true)
	draw_line(c + Vector2(0.0, -r * 0.42), c + Vector2(0.0, r * 0.36), Color(color.r, color.g, color.b, color.a * 0.58), 1.0, true)


func _draw_icon_coin(c: Vector2, r: float, color: Color) -> void:
	draw_arc(c, r * 0.48, 0.0, TAU, 32, color, 1.4, true)
	draw_circle(c, r * 0.18, Color(color.r, color.g, color.b, color.a * 0.45))
	draw_line(c + Vector2(-r * 0.34, r * 0.34), c + Vector2(r * 0.32, r * 0.34), color, 1.2, true)
	draw_line(c + Vector2(-r * 0.26, r * 0.48), c + Vector2(r * 0.24, r * 0.48), Color(color.r, color.g, color.b, color.a * 0.70), 1.0, true)


func _draw_icon_lightning(c: Vector2, r: float, color: Color) -> void:
	var pts: PackedVector2Array = PackedVector2Array()
	pts.append(c + Vector2(-r * 0.06, -r * 0.66))
	pts.append(c + Vector2(r * 0.34, -r * 0.08))
	pts.append(c + Vector2(r * 0.06, -r * 0.08))
	pts.append(c + Vector2(r * 0.16, r * 0.62))
	pts.append(c + Vector2(-r * 0.34, -r * 0.02))
	pts.append(c + Vector2(-r * 0.06, -r * 0.02))
	draw_colored_polygon(pts, Color(color.r, color.g, color.b, color.a * 0.30))
	pts.append(c + Vector2(-r * 0.06, -r * 0.66))
	draw_polyline(pts, color, 1.2, true)


func _draw_icon_crescent(c: Vector2, r: float, color: Color) -> void:
	draw_arc(c, r * 0.52, -PI * 0.62, PI * 0.82, 28, color, 1.7, true)
	draw_arc(c + Vector2(r * 0.22, 0.0), r * 0.42, -PI * 0.62, PI * 0.82, 22, Color(color.r, color.g, color.b, color.a * 0.58), 1.2, true)
	draw_circle(c + Vector2(-r * 0.20, -r * 0.18), r * 0.06, color)


func _draw_icon_crown(c: Vector2, r: float, color: Color) -> void:
	var pts: PackedVector2Array = PackedVector2Array()
	pts.append(c + Vector2(-r * 0.58, r * 0.26))
	pts.append(c + Vector2(-r * 0.38, -r * 0.36))
	pts.append(c + Vector2(-r * 0.10, r * 0.02))
	pts.append(c + Vector2(0.0, -r * 0.54))
	pts.append(c + Vector2(r * 0.14, r * 0.02))
	pts.append(c + Vector2(r * 0.42, -r * 0.36))
	pts.append(c + Vector2(r * 0.58, r * 0.26))
	draw_polyline(pts, color, 1.5, true)
	draw_line(c + Vector2(-r * 0.48, r * 0.36), c + Vector2(r * 0.48, r * 0.36), color, 1.6, true)


func _draw_icon_snow(c: Vector2, r: float, color: Color) -> void:
	for i in range(6):
		var a: float = float(i) * TAU / 6.0
		var tip: Vector2 = c + Vector2(cos(a), sin(a)) * r * 0.58
		var inner: Vector2 = c + Vector2(cos(a), sin(a)) * r * 0.14
		draw_line(inner, tip, color, 1.25, true)
		var side_a: float = a + PI * 0.20
		var side_b: float = a - PI * 0.20
		draw_line(tip, tip - Vector2(cos(side_a), sin(side_a)) * r * 0.16, color, 0.9, true)
		draw_line(tip, tip - Vector2(cos(side_b), sin(side_b)) * r * 0.16, color, 0.9, true)
	draw_circle(c, r * 0.08, color)


func _draw_icon_flame(c: Vector2, r: float, color: Color) -> void:
	var pts: PackedVector2Array = PackedVector2Array()
	pts.append(c + Vector2(0.0, -r * 0.66))
	pts.append(c + Vector2(r * 0.34, -r * 0.16))
	pts.append(c + Vector2(r * 0.22, r * 0.42))
	pts.append(c + Vector2(0.0, r * 0.64))
	pts.append(c + Vector2(-r * 0.30, r * 0.22))
	pts.append(c + Vector2(-r * 0.18, -r * 0.18))
	draw_colored_polygon(pts, Color(color.r, color.g, color.b, color.a * 0.22))
	pts.append(c + Vector2(0.0, -r * 0.66))
	draw_polyline(pts, color, 1.3, true)
	draw_line(c + Vector2(0.0, r * 0.38), c + Vector2(r * 0.10, -r * 0.18), Color(color.r, color.g, color.b, color.a * 0.58), 1.0, true)


func _draw_icon_hourglass(c: Vector2, r: float, color: Color) -> void:
	draw_line(c + Vector2(-r * 0.42, -r * 0.52), c + Vector2(r * 0.42, -r * 0.52), color, 1.4, true)
	draw_line(c + Vector2(-r * 0.42, r * 0.52), c + Vector2(r * 0.42, r * 0.52), color, 1.4, true)
	draw_line(c + Vector2(-r * 0.36, -r * 0.44), c + Vector2(r * 0.28, r * 0.44), color, 1.1, true)
	draw_line(c + Vector2(r * 0.36, -r * 0.44), c + Vector2(-r * 0.28, r * 0.44), color, 1.1, true)
	draw_circle(c, r * 0.06, color)


func _draw_icon_dice(c: Vector2, r: float, color: Color) -> void:
	var rr: Rect2 = Rect2(c - Vector2(r * 0.38, r * 0.38), Vector2(r * 0.76, r * 0.76))
	draw_rect(rr, color, false, 1.3)
	var d: float = r * 0.20
	for p in [Vector2(-d, -d), Vector2(d, -d), Vector2(0.0, 0.0), Vector2(-d, d), Vector2(d, d)]:
		draw_circle(c + p, r * 0.045, color)


func _draw_icon_fusion(c: Vector2, r: float, color: Color) -> void:
	var a: Vector2 = c + Vector2(0.0, -r * 0.42)
	var b: Vector2 = c + Vector2(-r * 0.42, r * 0.28)
	var d: Vector2 = c + Vector2(r * 0.42, r * 0.28)
	draw_line(a, b, color, 1.2, true)
	draw_line(b, d, color, 1.2, true)
	draw_line(d, a, color, 1.2, true)
	draw_circle(a, r * 0.13, color)
	draw_circle(b, r * 0.13, color)
	draw_circle(d, r * 0.13, color)


func _draw_icon_star(c: Vector2, r: float, color: Color) -> void:
	for i in range(8):
		var a: float = float(i) * TAU / 8.0
		var length: float = r * (0.62 if i % 2 == 0 else 0.42)
		draw_line(c, c + Vector2(cos(a), sin(a)) * length, color, 1.1, true)
	draw_circle(c, r * 0.10, color)


func _draw_icon_chevrons(c: Vector2, r: float, color: Color) -> void:
	for i in range(3):
		var off: float = (float(i) - 1.0) * r * 0.24
		var pts: PackedVector2Array = PackedVector2Array()
		pts.append(c + Vector2(-r * 0.42 + off, -r * 0.38))
		pts.append(c + Vector2(r * 0.08 + off, 0.0))
		pts.append(c + Vector2(-r * 0.42 + off, r * 0.38))
		draw_polyline(pts, color, 1.45, true)
	draw_line(c + Vector2(-r * 0.48, r * 0.50), c + Vector2(r * 0.50, r * 0.50), Color(color.r, color.g, color.b, color.a * 0.55), 1.0, true)


func _draw_icon_double_barrel(c: Vector2, r: float, color: Color) -> void:
	var top: Rect2 = Rect2(c + Vector2(-r * 0.58, -r * 0.34), Vector2(r * 0.82, r * 0.22))
	var bot: Rect2 = Rect2(c + Vector2(-r * 0.58, r * 0.12), Vector2(r * 0.82, r * 0.22))
	draw_rect(top, color, false, 1.25)
	draw_rect(bot, color, false, 1.25)
	draw_line(c + Vector2(r * 0.22, -r * 0.23), c + Vector2(r * 0.58, -r * 0.23), color, 1.6, true)
	draw_line(c + Vector2(r * 0.22, r * 0.23), c + Vector2(r * 0.58, r * 0.23), color, 1.6, true)
	draw_circle(c + Vector2(r * 0.66, -r * 0.23), r * 0.05, color)
	draw_circle(c + Vector2(r * 0.66, r * 0.23), r * 0.05, color)


func _draw_icon_missile(c: Vector2, r: float, color: Color) -> void:
	var pts: PackedVector2Array = PackedVector2Array()
	pts.append(c + Vector2(r * 0.62, 0.0))
	pts.append(c + Vector2(r * 0.14, -r * 0.28))
	pts.append(c + Vector2(-r * 0.52, -r * 0.24))
	pts.append(c + Vector2(-r * 0.36, 0.0))
	pts.append(c + Vector2(-r * 0.52, r * 0.24))
	pts.append(c + Vector2(r * 0.14, r * 0.28))
	pts.append(c + Vector2(r * 0.62, 0.0))
	draw_colored_polygon(pts, Color(color.r, color.g, color.b, color.a * 0.16))
	draw_polyline(pts, color, 1.3, true)
	draw_line(c + Vector2(-r * 0.62, -r * 0.38), c + Vector2(-r * 0.36, 0.0), color, 1.0, true)
	draw_line(c + Vector2(-r * 0.62, r * 0.38), c + Vector2(-r * 0.36, 0.0), color, 1.0, true)


func _draw_icon_heart(c: Vector2, r: float, color: Color) -> void:
	draw_circle(c + Vector2(-r * 0.20, -r * 0.16), r * 0.22, Color(color.r, color.g, color.b, color.a * 0.20))
	draw_circle(c + Vector2(r * 0.20, -r * 0.16), r * 0.22, Color(color.r, color.g, color.b, color.a * 0.20))
	var pts: PackedVector2Array = PackedVector2Array()
	pts.append(c + Vector2(-r * 0.44, -r * 0.08))
	pts.append(c + Vector2(-r * 0.22, -r * 0.38))
	pts.append(c + Vector2(0.0, -r * 0.20))
	pts.append(c + Vector2(r * 0.22, -r * 0.38))
	pts.append(c + Vector2(r * 0.44, -r * 0.08))
	pts.append(c + Vector2(0.0, r * 0.56))
	pts.append(c + Vector2(-r * 0.44, -r * 0.08))
	draw_polyline(pts, color, 1.4, true)


func _draw_icon_wing(c: Vector2, r: float, color: Color) -> void:
	var left: PackedVector2Array = PackedVector2Array()
	left.append(c + Vector2(-r * 0.08, r * 0.40))
	left.append(c + Vector2(-r * 0.58, r * 0.18))
	left.append(c + Vector2(-r * 0.38, -r * 0.10))
	left.append(c + Vector2(-r * 0.62, -r * 0.34))
	left.append(c + Vector2(-r * 0.12, -r * 0.16))
	draw_polyline(left, color, 1.35, true)
	var right: PackedVector2Array = PackedVector2Array()
	for p in left:
		right.append(Vector2(c.x + (c.x - p.x), p.y))
	draw_polyline(right, color, 1.35, true)
	draw_line(c + Vector2(0.0, -r * 0.40), c + Vector2(0.0, r * 0.48), color, 1.0, true)


func _draw_icon_wall(c: Vector2, r: float, color: Color) -> void:
	var w: float = r * 0.82
	var h: float = r * 0.54
	var rr: Rect2 = Rect2(c - Vector2(w * 0.5, h * 0.5), Vector2(w, h))
	draw_rect(rr, color, false, 1.3)
	for i in range(1, 3):
		var x: float = rr.position.x + w * float(i) / 3.0
		draw_line(Vector2(x, rr.position.y), Vector2(x, rr.end.y), Color(color.r, color.g, color.b, color.a * 0.55), 0.8, true)
	draw_line(Vector2(rr.position.x, c.y), Vector2(rr.end.x, c.y), Color(color.r, color.g, color.b, color.a * 0.55), 0.8, true)


func _draw_icon_vault(c: Vector2, r: float, color: Color) -> void:
	var rr: Rect2 = Rect2(c - Vector2(r * 0.48, r * 0.36), Vector2(r * 0.96, r * 0.72))
	draw_rect(rr, color, false, 1.25)
	draw_arc(c, r * 0.24, 0.0, TAU, 24, color, 1.1, true)
	draw_circle(c, r * 0.06, color)
	draw_line(c + Vector2(-r * 0.26, r * 0.44), c + Vector2(r * 0.26, r * 0.44), color, 1.2, true)


func _draw_icon_credit(c: Vector2, r: float, color: Color) -> void:
	var rr: Rect2 = Rect2(c - Vector2(r * 0.56, r * 0.34), Vector2(r * 1.12, r * 0.68))
	draw_rect(rr, color, false, 1.2)
	draw_rect(Rect2(rr.position + Vector2(r * 0.08, r * 0.12), Vector2(r * 0.96, r * 0.10)), Color(color.r, color.g, color.b, color.a * 0.38), true)
	draw_line(rr.position + Vector2(r * 0.12, r * 0.45), rr.position + Vector2(r * 0.48, r * 0.45), color, 1.0, true)


func _draw_icon_converter(c: Vector2, r: float, color: Color) -> void:
	draw_arc(c, r * 0.40, -PI * 0.10, PI * 1.10, 24, color, 1.35, true)
	draw_arc(c, r * 0.40, PI * 0.90, PI * 2.10, 24, color, 1.35, true)
	var a1: Vector2 = c + Vector2(cos(PI * 1.10), sin(PI * 1.10)) * r * 0.40
	var a2: Vector2 = c + Vector2(cos(PI * 2.10), sin(PI * 2.10)) * r * 0.40
	draw_line(a1, a1 + Vector2(r * 0.16, -r * 0.05), color, 1.1, true)
	draw_line(a2, a2 + Vector2(-r * 0.16, r * 0.05), color, 1.1, true)
	draw_circle(c, r * 0.10, color)


func _draw_icon_crystal(c: Vector2, r: float, color: Color) -> void:
	var pts: PackedVector2Array = PackedVector2Array()
	pts.append(c + Vector2(0.0, -r * 0.62))
	pts.append(c + Vector2(r * 0.40, -r * 0.08))
	pts.append(c + Vector2(r * 0.20, r * 0.58))
	pts.append(c + Vector2(-r * 0.20, r * 0.58))
	pts.append(c + Vector2(-r * 0.40, -r * 0.08))
	pts.append(c + Vector2(0.0, -r * 0.62))
	draw_colored_polygon(pts, Color(color.r, color.g, color.b, color.a * 0.16))
	draw_polyline(pts, color, 1.3, true)
	draw_line(c + Vector2(0.0, -r * 0.48), c + Vector2(0.0, r * 0.48), Color(color.r, color.g, color.b, color.a * 0.62), 0.9, true)


func _draw_icon_radar(c: Vector2, r: float, color: Color) -> void:
	for mul in [0.22, 0.40, 0.58]:
		draw_arc(c, r * mul, -PI * 0.92, -PI * 0.08, 18, color, 1.1, true)
	draw_line(c, c + Vector2(0.0, r * 0.58), color, 1.2, true)
	draw_circle(c, r * 0.07, color)


func _draw_icon_cards(c: Vector2, r: float, color: Color) -> void:
	var back: Rect2 = Rect2(c - Vector2(r * 0.30, r * 0.46), Vector2(r * 0.44, r * 0.60))
	var front: Rect2 = Rect2(c - Vector2(r * 0.06, r * 0.34), Vector2(r * 0.44, r * 0.60))
	draw_rect(back, Color(color.r, color.g, color.b, color.a * 0.40), false, 1.0)
	draw_rect(front, color, false, 1.2)
	draw_circle(front.position + front.size * 0.5, r * 0.08, color)


func _draw_icon_eye(c: Vector2, r: float, color: Color) -> void:
	var left: Vector2 = c + Vector2(-r * 0.58, 0.0)
	var right: Vector2 = c + Vector2(r * 0.58, 0.0)
	draw_arc(c, r * 0.58, -PI * 0.90, -PI * 0.10, 24, color, 1.25, true)
	draw_arc(c, r * 0.58, PI * 0.10, PI * 0.90, 24, color, 1.25, true)
	draw_line(left, c + Vector2(0.0, -r * 0.28), Color(color.r, color.g, color.b, color.a * 0.55), 0.9, true)
	draw_line(right, c + Vector2(0.0, -r * 0.28), Color(color.r, color.g, color.b, color.a * 0.55), 0.9, true)
	draw_circle(c, r * 0.14, color)


func _draw_icon_acid(c: Vector2, r: float, color: Color) -> void:
	var pts: PackedVector2Array = PackedVector2Array()
	pts.append(c + Vector2(0.0, -r * 0.62))
	pts.append(c + Vector2(r * 0.32, -r * 0.08))
	pts.append(c + Vector2(r * 0.24, r * 0.42))
	pts.append(c + Vector2(0.0, r * 0.62))
	pts.append(c + Vector2(-r * 0.24, r * 0.42))
	pts.append(c + Vector2(-r * 0.32, -r * 0.08))
	pts.append(c + Vector2(0.0, -r * 0.62))
	draw_colored_polygon(pts, Color(color.r, color.g, color.b, color.a * 0.18))
	draw_polyline(pts, color, 1.3, true)
	draw_circle(c + Vector2(0.0, r * 0.18), r * 0.08, color)


func _draw_icon_plague(c: Vector2, r: float, color: Color) -> void:
	draw_circle(c, r * 0.20, Color(color.r, color.g, color.b, color.a * 0.32))
	for i in range(6):
		var a: float = float(i) * TAU / 6.0
		var p: Vector2 = c + Vector2(cos(a), sin(a)) * r * 0.48
		draw_line(c, p, color, 1.0, true)
		draw_circle(p, r * 0.08, color)


func _draw_icon_infinity(c: Vector2, r: float, color: Color) -> void:
	draw_arc(c + Vector2(-r * 0.22, 0.0), r * 0.28, -PI * 0.10, PI * 1.90, 32, color, 1.3, true)
	draw_arc(c + Vector2(r * 0.22, 0.0), r * 0.28, PI * 0.10, PI * 2.10, 32, color, 1.3, true)
	draw_line(c + Vector2(-r * 0.02, -r * 0.06), c + Vector2(r * 0.02, r * 0.06), color, 1.0, true)


func _draw_icon_avalanche(c: Vector2, r: float, color: Color) -> void:
	var mountain: PackedVector2Array = PackedVector2Array()
	mountain.append(c + Vector2(-r * 0.58, r * 0.48))
	mountain.append(c + Vector2(-r * 0.18, -r * 0.40))
	mountain.append(c + Vector2(r * 0.08, r * 0.06))
	mountain.append(c + Vector2(r * 0.26, -r * 0.28))
	mountain.append(c + Vector2(r * 0.58, r * 0.48))
	draw_polyline(mountain, color, 1.3, true)
	draw_circle(c + Vector2(-r * 0.08, -r * 0.10), r * 0.06, color)
	draw_circle(c + Vector2(r * 0.20, r * 0.14), r * 0.05, color)


func _draw_icon_pulse(c: Vector2, r: float, color: Color) -> void:
	for mul in [0.24, 0.42, 0.60]:
		draw_arc(c, r * mul, 0.0, TAU, 32, Color(color.r, color.g, color.b, color.a * (0.95 - mul)), 1.0, true)
	draw_line(c + Vector2(-r * 0.62, 0.0), c + Vector2(r * 0.62, 0.0), color, 0.9, true)
	draw_circle(c, r * 0.08, color)


func _draw_icon_skull(c: Vector2, r: float, color: Color) -> void:
	draw_circle(c + Vector2(0.0, -r * 0.10), r * 0.36, Color(color.r, color.g, color.b, color.a * 0.14))
	draw_arc(c + Vector2(0.0, -r * 0.10), r * 0.36, PI * 0.15, PI * 1.85, 28, color, 1.2, true)
	draw_circle(c + Vector2(-r * 0.14, -r * 0.12), r * 0.06, color)
	draw_circle(c + Vector2(r * 0.14, -r * 0.12), r * 0.06, color)
	draw_line(c + Vector2(-r * 0.18, r * 0.30), c + Vector2(r * 0.18, r * 0.30), color, 1.2, true)
	draw_line(c + Vector2(0.0, r * 0.08), c + Vector2(0.0, r * 0.26), color, 1.0, true)


func _draw_icon_rewind(c: Vector2, r: float, color: Color) -> void:
	var left: PackedVector2Array = PackedVector2Array()
	left.append(c + Vector2(-r * 0.48, 0.0))
	left.append(c + Vector2(-r * 0.06, -r * 0.34))
	left.append(c + Vector2(-r * 0.06, r * 0.34))
	left.append(c + Vector2(-r * 0.48, 0.0))
	var right: PackedVector2Array = PackedVector2Array()
	right.append(c + Vector2(-r * 0.04, 0.0))
	right.append(c + Vector2(r * 0.38, -r * 0.34))
	right.append(c + Vector2(r * 0.38, r * 0.34))
	right.append(c + Vector2(-r * 0.04, 0.0))
	draw_polyline(left, color, 1.3, true)
	draw_polyline(right, color, 1.3, true)
	draw_line(c + Vector2(r * 0.54, -r * 0.40), c + Vector2(r * 0.54, r * 0.40), color, 1.1, true)


func _draw_icon_explosion(c: Vector2, r: float, color: Color) -> void:
	for i in range(10):
		var a: float = float(i) * TAU / 10.0
		var inner: Vector2 = c + Vector2(cos(a), sin(a)) * r * 0.16
		var outer: Vector2 = c + Vector2(cos(a), sin(a)) * r * (0.62 if i % 2 == 0 else 0.42)
		draw_line(inner, outer, color, 1.2, true)
	draw_circle(c, r * 0.10, color)


func _draw_icon_medal(c: Vector2, r: float, color: Color) -> void:
	draw_arc(c + Vector2(0.0, r * 0.04), r * 0.34, 0.0, TAU, 32, color, 1.2, true)
	_draw_icon_star(c + Vector2(0.0, r * 0.04), r * 0.42, color)
	draw_line(c + Vector2(-r * 0.18, -r * 0.28), c + Vector2(-r * 0.34, -r * 0.62), color, 1.0, true)
	draw_line(c + Vector2(r * 0.18, -r * 0.28), c + Vector2(r * 0.34, -r * 0.62), color, 1.0, true)


func _draw_icon_flask(c: Vector2, r: float, color: Color) -> void:
	draw_line(c + Vector2(-r * 0.16, -r * 0.58), c + Vector2(r * 0.16, -r * 0.58), color, 1.2, true)
	draw_line(c + Vector2(-r * 0.10, -r * 0.58), c + Vector2(-r * 0.10, -r * 0.12), color, 1.0, true)
	draw_line(c + Vector2(r * 0.10, -r * 0.58), c + Vector2(r * 0.10, -r * 0.12), color, 1.0, true)
	var body: PackedVector2Array = PackedVector2Array()
	body.append(c + Vector2(-r * 0.10, -r * 0.12))
	body.append(c + Vector2(-r * 0.42, r * 0.52))
	body.append(c + Vector2(r * 0.42, r * 0.52))
	body.append(c + Vector2(r * 0.10, -r * 0.12))
	body.append(c + Vector2(-r * 0.10, -r * 0.12))
	draw_colored_polygon(body, Color(color.r, color.g, color.b, color.a * 0.16))
	draw_polyline(body, color, 1.25, true)
	draw_line(c + Vector2(-r * 0.24, r * 0.24), c + Vector2(r * 0.24, r * 0.24), Color(color.r, color.g, color.b, color.a * 0.55), 1.0, true)


func _hex_points(c: Vector2, r: float) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in range(6):
		var a := float(i) * TAU / 6.0 + PI / 6.0
		pts.append(c + Vector2(cos(a), sin(a)) * r)
	return pts


func _draw_star(c: Vector2, r: float, color: Color) -> void:
	var pts := PackedVector2Array()
	for i in range(16):
		var rr: float = r if i % 2 == 0 else r * 0.30
		var a: float = -PI * 0.5 + float(i) * TAU / 16.0
		pts.append(c + Vector2(cos(a), sin(a)) * rr)
	draw_colored_polygon(pts, Color(color.r, color.g, color.b, color.a * 0.28))
	for i in range(8):
		var a: float = -PI * 0.5 + float(i) * TAU / 8.0
		draw_line(c, c + Vector2(cos(a), sin(a)) * r, color, 1.0, true)


func _draw_group_label(group: Dictionary) -> void:
	var name: String = group.get("name", "") as String
	var sub: String = group.get("sub", "") as String
	if name == "":
		return
	var color: Color = group.get("color", Color(0.55, 0.82, 1.0)) as Color
	var font: Font = _cached_font if _cached_font != null else get_theme_default_font()
	if font == null:
		return
	var points: Array = group.get("points", []) as Array
	var p: Vector2 = group.get("label_screen", Vector2.ZERO) as Vector2
	var count: int = 0
	var acc: Vector2 = Vector2.ZERO
	if p == Vector2.ZERO:
		for id_any in points:
			var id: String = id_any as String
			if positions.has(id):
				acc += positions[id] as Vector2
				count += 1
		if count > 0:
			p = acc / float(count)
	p -= Vector2(64.0, 32.0)
	draw_string(font, p + Vector2(1.5, 1.5), name, HORIZONTAL_ALIGNMENT_CENTER, 128.0, 12, Color(0.0, 0.0, 0.0, 0.74))
	draw_string(font, p, name, HORIZONTAL_ALIGNMENT_CENTER, 128.0, 12, Color(color.r, color.g, color.b, 0.70))
	draw_string(font, p + Vector2(0.0, 13.0), sub, HORIZONTAL_ALIGNMENT_CENTER, 128.0, 7, Color(color.r, color.g, color.b, 0.48))
