extends Control

@export var main_menu_scene := "res://scenes/system/loby_01.tscn"
@onready var ui_efect: AudioStreamPlayer = $ui_efect
@onready var btn_sair: Button = $Panel/BoxContainer/VBoxContainer/BtnQuitGame


func _ready():
	GameManager.pause_requested.connect(toggle_pause)
	hide()
	
	#esconder o botão sair no web e mobile
	if OS.has_feature("mobile") or OS.has_feature("web_android") or OS.has_feature("web_ios"):
		btn_sair.disabled = true



func _input(event):
	if event.is_action_pressed("ui_cancel"):
		toggle_pause()

func toggle_pause():
	if get_tree().paused:
		resume_game()
	else:
		pause_game()

func pause_game():
	get_tree().paused = true
	show()

func resume_game():
	hide()
	get_tree().paused = false

# -----------------------------
# BOTÕES
# -----------------------------

func _on_btn_return_pressed() -> void:
	ui_efx()
	resume_game()

func _on_btn_loby_pressed() -> void:
	ui_efx()
	get_tree().paused = false
	get_tree().change_scene_to_file(main_menu_scene)

	

func ui_efx():
	ui_efect.play()


func _on_btn_quit_game_pressed() -> void:
	ui_efx()
	get_tree().quit()
