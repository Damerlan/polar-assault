extends CanvasLayer

@onready var score_label = $Control/LabelRisingLevel

@onready var label_coleta: Label = $Control/LabelColect


func _ready() -> void:
	#atuliza ao iniciar
	update_score()
	_update_itens()
	ScoreManager.connect("collect_coin", Callable(self, "_on_coin_collected"))
	
	#conecta os sinais
	GameManager.autura_changed.connect(_on_altura_changed)
	#GameManager.lives_changed.connect(_on_lives_changed)
	
func _on_coin_collected():
	_update_itens()

func _update_itens():
	label_coleta.text = str(ScoreManager.itens) + "+"

func _on_altura_changed(value):
	score_label.text = str(value)
	

func _process(_delta: float) -> void:
	update_score()

func update_score():
	score_label.text = str(ScoreManager.altura) + "m"
	#lives_label.text = str(Nglobal.lives)
