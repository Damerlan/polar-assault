#Plataforma_Congelada - Updated 12-01-26
extends StaticBody2D

@export var ice_accel_multiplier := 0.25
@export var ice_decel_multiplier := 0.1


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
