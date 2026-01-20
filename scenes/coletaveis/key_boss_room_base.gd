extends Area2D

@export var boss_id := "boss_01"

func _on_body_entered(body):
	if body.is_in_group("player"):
		GameManager.enter_boss_room(boss_id)
		queue_free()
