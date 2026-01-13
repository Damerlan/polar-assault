extends Control

@export var next_scene := "res://scenes/sala_01.tscn"
@export var min_loading_time := 1.0 # tempo mínimo visível (em segundos)

@onready var progress_bar = $ProgressBar
@onready var min_timer: Timer = $min_time

var loading_finished := false

func _ready():
	min_timer.wait_time = min_loading_time
	min_timer.start()
	Loader.start_loading(get_heavy_resources())

func _process(_delta):
	Loader.update()
	progress_bar.value = Loader.progress * 100.0

	if not Loader.loading and not loading_finished:
		loading_finished = true

		# força compilação das cenas pesadas
		for res in Loader.loaded_resources.values():
			if res is PackedScene:
				res.instantiate()

		try_finish()

func _on_MinTimer_timeout():
	try_finish()

func try_finish():
	if loading_finished and min_timer.time_left <= 0:
		var packed = load(next_scene)
		get_tree().change_scene_to_packed(packed)

func get_heavy_resources() -> Array:
	return [
		#"res://scenes/sala_01.tscn",
		#"res://entities/player_peko.tscn",
		#"res://audio/music/ClementPanchout_ Life_is_full_of_Joy.mp3",
		#"res://plataforms/plataforma.tscn",
		#"res://plataforms/plataform_breaking.tscn",
		#"res://plataforms/plataform_up_down.tscn",
		"res://plataforms/safe_plataform.tscn"
	]


func _on_min_time_timeout() -> void:
	try_finish()
