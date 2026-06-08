extends Control

@onready var progress_bar = $Panel/Progress
@onready var label = $Panel/Label

var total_mobs = 0
var defeated_mobs = 0
var current_wave = 0

func _ready():
	update_display()

func set_wave_info(wave_num: int, total_wave_mobs: int):
	current_wave = wave_num
	total_mobs = total_wave_mobs
	defeated_mobs = 0
	update_display()

func mob_defeated():
	defeated_mobs += 1
	update_display()

func update_display():
	if label:
		label.text = "Wave %d: %d/%d" % [current_wave, defeated_mobs, total_mobs]

	if progress_bar:
		var progress_ratio = float(defeated_mobs) / max(1, total_mobs)
		progress_bar.value = progress_ratio * 100

func reset():
	defeated_mobs = 0
	update_display()