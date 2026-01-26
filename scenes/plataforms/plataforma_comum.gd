#Plataforma_comum - Updated 11-01-26
# Plataforma_comum.gd
# Plataforma_comum.gd
extends StaticBody2D

var visibility := Global.visibility
var player: Node = null

@onready var loot_spawner: LootSpawner = $LootSpawner

func _ready() -> void:
	player = get_tree().get_first_node_in_group("Player")

func _process(_delta):
	if player and position.y > player.position.y + visibility:
		queue_free()


func register_as_safe():
	GameManager.last_safe_position = global_position
	GameManager.last_safe_platform = self
