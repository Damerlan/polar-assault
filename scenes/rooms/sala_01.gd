extends Node2D

var player: Node = null
@onready var killzone = $KillZone
@onready var y_sort: Node = $YSort
var game_over_triggered := false


func _ready() -> void:
	_bind_player_death_signal()

	if Global.coming_from_boss:
		GameManager.tempo_partida = Global.saved_run_time
		GameManager.contando = true
		Global.coming_from_boss = false
	else:
		GameManager.iniciar_partida()
		
	var gm = get_tree().get_first_node_in_group("GameManager")
	if gm:
		gm.state = GameManager.GameState.PLAYING
	
	#sistema da boss roms


func _bind_player_death_signal() -> void:
	player = get_tree().get_first_node_in_group("Player")
	if player and player.has_signal("morreu") and not player.morreu.is_connected(_on_player_morreu):
		player.morreu.connect(_on_player_morreu)



	
func _on_player_morreu():
	if game_over_triggered:
		return

	game_over_triggered = true
	GameManager.on_player_morreu()
