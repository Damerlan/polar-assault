extends CanvasLayer

@onready var time_label: Label = $Control/LabelTime

func _ready():
	GameManager.tempo_atualizado.connect(_atualizar_tempo)

func _atualizar_tempo(tempo: float):
	time_label.text = GameManager.formatar_tempo(tempo)
