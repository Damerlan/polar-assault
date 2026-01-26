#Plataform Breacking - Updated 12-01-26
extends CharacterBody2D

@export var tremor_duration := 0.4
@export var fall_delay := 0.2
@export var gravity := 1200.0
@export var tremor_strength := 2.0
@onready var asp_crash: AudioStreamPlayer = $ASPCrash

var activated := false
var falling := false
var original_position: Vector2
var player = null
var visibility = Global.visibility

func _ready():
	original_position = position
	
	player = get_tree().get_first_node_in_group("Player")

func _physics_process(delta):
	if falling:
		velocity.y += gravity * delta
		move_and_slide()
		
	if player == null:
		return
	
	if position.y > player.position.y + visibility:
		queue_free()

func _on_area_2d_body_entered(body):
	if activated:
		return
	
	if body.is_in_group("Player"):
		activated = true
		asp_crash.play()
		start_tremor()

func start_tremor():
	var elapsed := 0.0
	
	while elapsed < tremor_duration:
		position.x = original_position.x + randf_range(-tremor_strength, tremor_strength)
		await get_tree().create_timer(0.03).timeout
		elapsed += 0.03
	asp_crash.play()
	position = original_position
	await get_tree().create_timer(fall_delay).timeout
	start_fall()

func start_fall():
	falling = true
	#modulate.a = lerp(modulate.a, 0.0, delta * 2)

	# 🔓 Desativa colisão completamente
	collision_layer = 0
	collision_mask = 0
