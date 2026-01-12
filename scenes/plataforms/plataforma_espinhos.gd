#Plataforma_com_Espinhos - Updated 12-01-26
extends StaticBody2D

@export var visibility := 400

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


# 🚀 Posição segura DEFINITIVA
func register_as_safe(): 
	Global.last_safe_position = global_position
	Global.last_safe_platform = self


# Causa dano ao Player
func _on_area_2d_body_entered(body: Node2D) -> void:
	if body is CharacterBody2D and body.has_method("take_hit"):
		body.take_hit()
