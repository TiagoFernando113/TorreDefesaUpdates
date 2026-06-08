extends Control

@onready var crystals_label = $Panel/CrystalsLabel
@onready var close_button = $Panel/CloseButton

var jogo = null
var talents = {}

# Definição dos talentos (3 ramos, 9 nós)
const TALENTS_DATA = {
	"attack": {
		"name": "ATAQUE",
		"color": Color(1.0, 0.3, 0.3),
		"nodes": [
			{"id": "attack_1", "name": "Dano Aprimorado", "desc": "+15% dano da torre", "cost": 1},
			{"id": "attack_2", "name": "Dano Potente", "desc": "+25% dano da torre", "cost": 2, "req": "attack_1"},
			{"id": "attack_3", "name": "Dano Devastador", "desc": "+35% dano da torre", "cost": 3, "req": "attack_2"}
		]
	},
	"defense": {
		"name": "DEFESA",
		"color": Color(0.3, 1.0, 0.3),
		"nodes": [
			{"id": "defense_1", "name": "Armadura Leve", "desc": "+20% vida da torre", "cost": 1},
			{"id": "defense_2", "name": "Armadura Pesada", "desc": "+35% vida da torre", "cost": 2, "req": "defense_1"},
			{"id": "defense_3", "name": "Armadura de Titânio", "desc": "+50% vida da torre", "cost": 3, "req": "defense_2"}
		]
	},
	"utility": {
		"name": "UTILIDADE",
		"color": Color(0.3, 0.3, 1.0),
		"nodes": [
			{"id": "utility_1", "name": "Velocidade de Tiro", "desc": "+20% cadência de tiro", "cost": 1},
			{"id": "utility_2", "name": "Precisão Aprimorada", "desc": "+30% cadência de tiro", "cost": 2, "req": "utility_1"},
			{"id": "utility_3", "name": "Tiro Rápido", "desc": "+45% cadência de tiro", "cost": 3, "req": "utility_2"}
		]
	}
}

func _ready():
	close_button.pressed.connect(_on_close_pressed)
	_create_talent_nodes()
	update_display()

func _create_talent_nodes():
	# Criar nós de talento para cada ramo
	var branch_x = 150
	for branch_key in TALENTS_DATA.keys():
		var branch_data = TALENTS_DATA[branch_key]
		var branch_y = 120

		# Título do ramo
		var branch_title = Label.new()
		branch_title.text = branch_data.name
		branch_title.position = Vector2(branch_x - 50, branch_y - 40)
		branch_title.size = Vector2(200, 30)
		branch_title.theme_override_colors.font_color = branch_data.color
		branch_title.theme_override_font_sizes.font_size = 18
		branch_title.horizontal_alignment = 1  # CENTER
		$Panel.add_child(branch_title)

		# Criar nós individuais
		for i in range(branch_data.nodes.size()):
			var node_data = branch_data.nodes[i]
			_create_talent_node(node_data, branch_x, branch_y + i * 120, branch_data.color)

		branch_x += 250

func _create_talent_node(data, x, y, color):
	# Container do nó
	var container = PanelContainer.new()
	container.position = Vector2(x - 80, y)
	container.size = Vector2(160, 100)

	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.1, 0.1, 0.15, 0.8)
	style.border_color = color
	style.content_margin_left = 8
	style.content_margin_right = 8
	style.content_margin_top = 8
	style.content_margin_bottom = 8
	container.add_theme_stylebox_override("panel", style)

	var vbox = VBoxContainer.new()
	vbox.anchor_right = 1.0
	vbox.anchor_bottom = 1.0
	container.add_child(vbox)

	# Nome do talento
	var name_label = Label.new()
	name_label.text = data.name
	name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	name_label.theme_override_colors.font_color = color
	name_label.theme_override_font_sizes.font_size = 14
	vbox.add_child(name_label)

	# Descrição
	var desc_label = Label.new()
	desc_label.text = data.desc
	desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc_label.theme_override_colors.font_color = Color(0.8, 0.8, 0.8)
	desc_label.theme_override_font_sizes.font_size = 11
	vbox.add_child(desc_label)

	# Custo
	var cost_label = Label.new()
	cost_label.text = "Custo: %d cristal%s" % [data.cost, "s" if data.cost > 1 else ""]
	cost_label.theme_override_colors.font_color = Color(0.9, 0.9, 0.5)
	cost_label.theme_override_font_sizes.font_size = 12
	vbox.add_child(cost_label)

	# Botão de compra
	var buy_button = Button.new()
	buy_button.text = "Comprar"
	buy_button.name = "buy_" + data.id
	buy_button.flat = true
	buy_button.theme_override_colors.font_color = Color(1, 1, 1)
	buy_button.theme_override_font_sizes.font_size = 12

	# Verificar se o talento já foi comprado ou está disponível
	if data.id in talents:
		buy_button.text = "Comprado"
		buy_button.disabled = true
	elif "req" in data and not (data.req in talents):
		buy_button.text = "Bloqueado"
		buy_button.disabled = true
	else:
		buy_button.pressed.connect(_on_buy_talent.bind(data.id, data.cost))

	vbox.add_child(buy_button)

	$Panel.add_child(container)

func _on_buy_talent(talent_id, cost):
	if jogo and jogo.crystals >= cost:
		jogo.crystals -= cost
		talents[talent_id] = true
		update_display()
		_refresh_talent_buttons()

		# Aplicar efeito do talento
		_apply_talent_effect(talent_id)

func _apply_talent_effect(talent_id):
	if not jogo or not jogo.torre:
		return

	match talent_id:
		"attack_1":
			jogo.torre.damage *= 1.15
		"attack_2":
			jogo.torre.damage *= 1.25
		"attack_3":
			jogo.torre.damage *= 1.35
		"defense_1":
			jogo.torre.max_hp *= 1.2
			jogo.torre.hp *= 1.2
		"defense_2":
			jogo.torre.max_hp *= 1.35
			jogo.torre.hp *= 1.35
		"defense_3":
			jogo.torre.max_hp *= 1.5
		"utility_1":
			jogo.torre.fire_rate *= 1.2
		"utility_2":
			jogo.torre.fire_rate *= 1.3
		"utility_3":
			jogo.torre.fire_rate *= 1.45

func _refresh_talent_buttons():
	# Atualizar estado dos botões após compra de talento
	for child in $Panel.get_children():
		if child is PanelContainer:
			for grandchild in child.get_children():
				if grandchild is VBoxContainer:
					for element in grandchild.get_children():
						if element is Button and element.name.begins_with("buy_"):
							var talent_id = element.name.replace("buy_", "")
							# Encontrar dados do talento
							var talent_data = null
							for branch in TALENTS_DATA.values():
								for node in branch.nodes:
									if node.id == talent_id:
										talent_data = node
										break
								if talent_data:
									break

							if talent_data:
								if talent_id in talents:
									element.text = "Comprado"
									element.disabled = true
								elif "req" in talent_data and not (talent_data.req in talents):
									element.text = "Bloqueado"
									element.disabled = true
								else:
									element.text = "Comprar"
									element.disabled = false

func update_display():
	if crystals_label and jogo:
		crystals_label.text = "Cristais disponíveis: %d" % jogo.crystals

func _on_close_pressed():
	hide()
