extends Area2D

@export var fall_damage := 25

func _on_body_entered(body: Node2D) -> void:
	if body is CharacterBody2D and body.has_method("take_fall_damage"):
		body.take_fall_damage(fall_damage)
