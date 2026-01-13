extends Node2D

@onready var label := $Panel/MarginContainer/Label
@onready var panel := $Panel
@onready var type_sound: AudioStreamPlayer = $TypeSound

@export var max_text_width := 100

@export var sound_every := 2
var sound_counter := 0

var full_text := ""
var char_index := 0
var typing_speed := 0.03
var typing := false

var follow_target: Node2D

signal finished_typing

func wrap_text_smart(text: String) -> String:
	var words := text.split(" ")
	var lines := []
	var current_line := ""

	for word in words:
		var test_line := current_line
		if test_line != "":
			test_line += " "
		test_line += word

		label.text = test_line
		if label.get_minimum_size().x > max_text_width:
			lines.append(current_line)
			current_line = word
		else:
			current_line = test_line

	if current_line != "":
		lines.append(current_line)

	return "\n".join(lines)
	
func show_at(world_position: Vector2) -> void:
	global_position = world_position
	show()

func follow(node: Node2D):
	follow_target = node

func _process(_delta):
	if follow_target:
		global_position = follow_target.global_position

func set_text(text: String):
	full_text = wrap_text_smart(text)
	label.text = ""
	char_index = 0
	typing = true
	_start_typing()

func _start_typing():
	while char_index < full_text.length():
		var char := full_text[char_index]
		label.text += char
		char_index += 1
		update_size()

		# 🔊 Som só em letras visíveis
		if char != " " and char != "\n" and type_sound:
			if not type_sound.playing:
				type_sound.play()

		await get_tree().create_timer(typing_speed).timeout

	typing = false
	emit_signal("finished_typing")

func update_size():
	await get_tree().process_frame
	panel.size = panel.get_minimum_size()
