extends Node2D

enum GameState {
	LOBBY,
	PLAYING,
	RANKING,
	GAME_OVER
	}

@onready var ui_efect: AudioStreamPlayer = $ui_efect
@onready var btn_sair: Button = $Control/BoxContainer/VBoxContainer/BtnSair

func _ready() -> void:
	var gm = get_tree().get_first_node_in_group("GameManager")
	if gm:
		gm.state = GameManager.GameState.LOBBY

	#esconder o botão sair no web e mobile
	if OS.has_feature("mobile") or OS.has_feature("web_android") or OS.has_feature("web_ios"):
		btn_sair.disabled = true

func _on_btn_start_pressed() -> void:
	ui_efx()
	get_tree().change_scene_to_file("res://scenes/system/loading_screen.tscn")
	#get_tree().change_scene_to_file("res://scenes/loading_screen.tscn")


func _on_btn_ranking_pressed() -> void:
	ui_efx()
	var next_scene = "ranking"
	get_tree().change_scene_to_file("res://scenes/" + next_scene +".tscn")


func _on_btn_full_pressed() -> void:
	#botão de tela cheia ou janela
	GameManager.toggle_fullscreen()


func _on_btn_sair_pressed() -> void:
	ui_efx()
	get_tree().quit()


func ui_efx():
	ui_efect.play()

func _unhandled_input(event):
	if event.is_action_pressed("ui_start"):
		var gm = get_tree().get_first_node_in_group("GameManager")
		if gm:
			gm.start_game()
