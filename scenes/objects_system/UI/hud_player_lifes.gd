extends CanvasLayer

@onready var hearts_container: HBoxContainer = $Control/HeartsContainer
@onready var heart_tamplate: TextureRect = $Control/HeartsContainer/HeartIcon


func _ready() -> void:
	heart_tamplate.visible = false #o tamplate sempre fica escondido
	
	ScoreManager.lives_changed.connect(update_hearts)
	
	update_hearts()
	

func update_hearts():
	#limpa todos os corações antigos
	for child in hearts_container.get_children():
		if child != heart_tamplate:
			child.queue_free()
		
	#cria novos corações baseado na vida atual
	for i in range(Global.lives):
		var heart = heart_tamplate.duplicate()
		heart.visible = true
		hearts_container.add_child(heart)
