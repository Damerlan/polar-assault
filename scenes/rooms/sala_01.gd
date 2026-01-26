extends Node2D

@onready var player = $Player
@onready var killzone = $KillZone
@onready var y_sort: Node = $YSort


func _ready() -> void:
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



	
func _on_player_morreu():
	GameManager.finalizar_partida()
	#para o tempo
	get_tree().paused = true
	
	#pequena espera
	await get_tree().create_timer(0.8).timeout
	
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/UI/game_over.tscn")
