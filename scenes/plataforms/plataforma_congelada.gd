#Plataforma_Congelada - Updated 12-01-26
extends StaticBody2D

@export var ice_accel_multiplier := 0.25
@export var ice_decel_multiplier := 0.1

var visibility = Global.visibility

var base_y := 0.0
var player = null


func _ready() -> void:
	base_y = global_position.y
	player = get_tree().get_first_node_in_group("Player")


func _process(_delta: float) -> void:
	# Remove a plataforma quando o player já passou muito acima
	if player == null:
		return

	if position.y > player.position.y + visibility:
		queue_free()


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
