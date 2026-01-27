extends CanvasLayer

@onready var health_bar = $VBoxContainer/TPBHealtBar
@onready var xp_bar = $VBoxContainer/XPBar
@onready var level_label = $VBoxContainer/LabelLevel

func _ready():
	update_all()
	Global.level_up.connect(_on_level_up)
	var player = get_tree().get_first_node_in_group("Player")
	if player:
		player.health_changed.connect(update_health)
	Global.xp_changed.connect(update_xp)

func update_all():
	update_health()
	update_xp()
	update_level()

func update_health():
	var player = get_tree().get_first_node_in_group("Player")

	health_bar.max_value = Global.lives_limit
	health_bar.value = Global.lives

func update_xp():
	xp_bar.max_value = Global.get_xp_to_next_level(Global.player_level)
	xp_bar.value = Global.player_xp

func update_level():
	level_label.text = "Lv " + str(Global.player_level)

func _on_level_up():
	update_all()
