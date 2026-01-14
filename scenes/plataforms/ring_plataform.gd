extends StaticBody2D

@export var ice_accel_multiplier := 0.25
@export var ice_decel_multiplier := 0.1


@export var shake_strength := 6.0
@export var shake_duration := 0.15
@export var shake_speed := 60.0

var original_position: Vector2
var shaking := false
var player = null
var visibility = Global.visibility

func _ready():
	original_position = position

func _physics_process(_delta):
	if player == null:
		return
	
	if position.y > player.position.y + visibility:
		queue_free()

func shake():
	print("💥 PLATAFORMA SACUDINDO")
	if shaking:
		return

	shaking = true
	original_position = global_position

	var timer := 0.0

	while timer < shake_duration:
		timer += get_process_delta_time()

		var offset_x = randf_range(-shake_strength, shake_strength)
		var offset_y = randf_range(-shake_strength * 0.3, shake_strength * 0.3)

		global_position = original_position + Vector2(offset_x, offset_y)
		await get_tree().process_frame

	global_position = original_position
	shaking = false


func _on_ice_area_body_entered(body: Node2D) -> void:
	if body.is_in_group("Player"):
		body.enter_ice(
			ice_accel_multiplier,
			ice_decel_multiplier
		)


func _on_ice_area_body_exited(body: Node2D) -> void:
	if body.is_in_group("Player"):
		body.exit_ice()

func is_ice() -> bool:
	return true
