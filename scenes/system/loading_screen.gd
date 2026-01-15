extends Control

@export var next_scene := "res://scenes/rooms/sala_01.tscn"
@export var min_loading_time := 1.5 # tempo mínimo visível (em segundos)

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

func try_finish():
	if loading_finished and min_timer.time_left <= 0:
		var packed = load(next_scene)
		get_tree().change_scene_to_packed(packed)

func get_heavy_resources() -> Array:
	return [
		"res://scenes/rooms/sala_01.tscn",
		"res://scenes/plataforms/plataforma_comum.tscn", 
		"res://scenes/plataforms/plataforma_congelada.tscn", 
		"res://scenes/plataforms/plataforma_espinhos.tscn", 
		"res://scenes/plataforms/plataforma_movel.tscn", 
		"res://scenes/plataforms/plataform_breackin.tscn", 
		"res://scenes/plataforms/ring_plataform.tscn",
		"res://scenes/coletaveis/coin.tscn", 
		"res://scenes/coletaveis/coin_coper.tscn", 
		"res://scenes/coletaveis/coin_gold.tscn", 
		"res://scenes/coletaveis/coin_silver.tscn", 
		"res://scenes/coletaveis/gem_base.tscn", 
		"res://scenes/coletaveis/gem_diamond.tscn", 
		"res://scenes/coletaveis/gem_emerald.tscn", 
		"res://scenes/coletaveis/gem_ruby.tscn", 
		"res://scenes/coletaveis/life.tscn",
		"res://scenes/objects_system/Cameras/camera_game_play.tscn",
		"res://entities/player.tscn"
		
	]


func _on_min_time_timeout() -> void:
	try_finish()
