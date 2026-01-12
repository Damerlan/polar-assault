extends Node

@onready var music_player := AudioStreamPlayer.new()
@onready var sfx_player := AudioStreamPlayer.new()

var music_atual: AudioStream = null


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.




func play_music(stream: AudioStream):
	if stream == null:
		return
	if music_atual == stream:
		return
	
	music_atual = stream
	music_player.stream = stream
	music_player.play()
	

func stop_music():
	music_player.stop()
	music_atual = null
