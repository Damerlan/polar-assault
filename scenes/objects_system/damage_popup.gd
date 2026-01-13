extends Node2D

@export var float_distance := 24.0
@export var duration := 0.6

@export var start_scale := 0.7
@export var end_scale := 1.2

@export var shake_strength := 2.0

@onready var label: Label = $Label

var start_pos: Vector2
var elapsed := 0.0
var rng := RandomNumberGenerator.new()

func setup(value: int):
	# texto com sinal negativo
	label.text = "-" + str(value)

	start_pos = global_position
	scale = Vector2.ONE * start_scale

	# COR INICIAL (amarelo)
	label.modulate = Color(1.0, 1.0, 0.2, 1.0)

	# OUTLINE PIXEL ART
	label.add_theme_color_override("font_outline_color", Color.BLACK)
	label.add_theme_constant_override("outline_size", 2)

	rng.randomize()


func _process(delta):
	elapsed += delta
	var t := elapsed / duration
	t = clamp(t, 0.0, 1.0)

	# SUBIR
	global_position.y = lerp(
		start_pos.y,
		start_pos.y - float_distance,
		t
	)

	# SCALE (pequeno → grande)
	var s: float = lerp(start_scale, end_scale, ease_out(t))
	scale = Vector2.ONE * s

	# COR (amarelo → vermelho)
	label.modulate.r = lerp(1.0, 1.0, t)
	label.modulate.g = lerp(1.0, 0.2, t)
	label.modulate.b = lerp(0.2, 0.2, t)

	# SHAKE LEVE
	var shake := Vector2(
		rng.randf_range(-shake_strength, shake_strength),
		rng.randf_range(-shake_strength, shake_strength)
	)
	position += shake * (1.0 - t)

	# FADE OUT
	label.modulate.a = lerp(1.0, 0.0, t)

	if t >= 1.0:
		queue_free()


func ease_out(t: float) -> float:
	return 1.0 - pow(1.0 - t, 3)
