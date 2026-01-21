extends Node2D

# ===============================
# REFERÊNCIAS DE NODES
# ===============================
@onready var label := $Panel/MarginContainer/Label
@onready var panel := $Panel
@onready var type_sound: AudioStreamPlayer = $Audio/ASPKeyEfect

# ===============================
# CONFIGURAÇÕES
# ===============================
@export var max_text_width := 100
@export var typing_speed := 0.03

# OUTLINE
@export var outline_base_size := 2        # Tamanho normal da borda
@export var outline_pulse_size := 4       # Tamanho máximo do pulse
@export var outline_pulse_time := 0.08    # Duração da animação

# SOM
@export var sound_every := 2
var sound_counter := 0

# ===============================
# CONTROLE DE DIGITAÇÃO
# ===============================
var full_text := ""
var char_index := 0
var typing := false

var follow_target: Node2D
var outline_tween: Tween

signal finished_typing

# ===============================
# READY – CONFIGURAÇÃO VISUAL
# ===============================
func _ready():
	# 🎨 OUTLINE PRINCIPAL
	label.add_theme_color_override("font_outline_color", Color.BLACK)
	label.add_theme_constant_override("outline_size", outline_base_size)

	# 🌫️ SOMBRA (SIMULA BORDA DUPLA)
	label.add_theme_color_override("shadow_color", Color(0, 0, 0, 0.7))
	label.add_theme_constant_override("shadow_offset_x", 2)
	label.add_theme_constant_override("shadow_offset_y", 2)

# ===============================
# QUEBRA DE TEXTO INTELIGENTE
# ===============================
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

# ===============================
# POSICIONAMENTO
# ===============================
func show_at(world_position: Vector2) -> void:
	global_position = world_position
	show()

func follow(node: Node2D):
	follow_target = node

func _process(_delta):
	if follow_target:
		global_position = follow_target.global_position

# ===============================
# TEXTO E DIGITAÇÃO
# ===============================
func set_text(text: String):
	full_text = wrap_text_smart(text)
	label.text = ""
	char_index = 0
	typing = true
	_start_typing()

func _start_typing():
	while char_index < full_text.length():
		var current_char := full_text[char_index]
		label.text += current_char
		char_index += 1
		update_size()

		# 🔊 Som apenas em letras visíveis
		if current_char != " " and current_char != "\n":
			_play_type_sound()
			_pulse_outline()   # ✨ ANIMA OUTLINE

		await get_tree().create_timer(typing_speed).timeout

	typing = false
	emit_signal("finished_typing")

# ===============================
# SOM DE DIGITAÇÃO
# ===============================
func _play_type_sound():
	if type_sound and not type_sound.playing:
		type_sound.play()

# ===============================
# ANIMAÇÃO DO OUTLINE (PULSE)
# ===============================
func _pulse_outline():
	# Cancela tween anterior se existir
	if outline_tween and outline_tween.is_running():
		outline_tween.kill()

	outline_tween = create_tween()

	# Aumenta o outline
	outline_tween.tween_method(
		func(value):
			label.add_theme_constant_override("outline_size", value),
		outline_base_size,
		outline_pulse_size,
		outline_pulse_time * 0.5
	)

	# Volta ao tamanho normal
	outline_tween.tween_method(
		func(value):
			label.add_theme_constant_override("outline_size", value),
		outline_pulse_size,
		outline_base_size,
		outline_pulse_time * 0.5
	)

# ===============================
# AJUSTE AUTOMÁTICO DO BALÃO
# ===============================
func update_size():
	await get_tree().process_frame
	panel.size = panel.get_minimum_size()
