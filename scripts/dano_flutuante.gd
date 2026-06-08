extends Node2D
## Número de dano flutuante — aparece no mob, sobe e some.

var _label : Label = null
var _timer : float = 0.0
var _vel_y : float = -80.0
const DUR  : float = 0.85


func iniciar(texto: String, cor: Color, tamanho_px: int = 18) -> void:
	_timer      = DUR
	_label      = Label.new()
	_label.text = texto
	_label.add_theme_font_size_override("font_size", tamanho_px)
	_label.add_theme_color_override("font_color", cor)
	_label.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.75))
	_label.add_theme_constant_override("shadow_offset_x", 1)
	_label.add_theme_constant_override("shadow_offset_y", 1)
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.position = Vector2(-32, -12)
	_label.size     = Vector2(64, 24)
	add_child(_label)


func _process(delta: float) -> void:
	_timer -= delta
	if _timer <= 0.0:
		queue_free()
		return
	position.y += _vel_y * delta
	_vel_y      = lerpf(_vel_y, -10.0, delta * 4.5)
	if _label:
		_label.modulate.a = clampf(_timer / DUR, 0.0, 1.0)
