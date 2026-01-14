#Plataforma Movel - Updated 12-01-26
extends StaticBody2D

var visibility = Global.visibility

@export var amplitude := 32.0
@export var speed := 1.5

var base_y := 0.0
var player = null


func _ready() -> void:
	base_y = global_position.y
	player = get_tree().get_first_node_in_group("Player")


func _process(_delta: float) -> void:
	# Movimento vertical (sobe e desce)
	global_position.y = base_y + sin(Time.get_ticks_msec() * 0.002 * speed) * amplitude

	# Remove a plataforma quando o player já passou muito acima
	if player == null:
		return

	if position.y > player.position.y + visibility:
		queue_free()
	



# 🚀 Posição segura DEFINITIVA
func register_as_safe(): 
	GameManager.last_safe_position = global_position
	GameManager.last_safe_platform = self
		
