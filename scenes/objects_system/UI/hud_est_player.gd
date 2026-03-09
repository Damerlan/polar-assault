extends CanvasLayer

@onready var health_bar = $VBoxContainer/TPBHealtBar
@onready var xp_bar = $VBoxContainer/XPBar
@onready var level_label = $VBoxContainer/LabelLevel
var player_ref: Node = null

func _ready():
	update_all()
	Global.level_up.connect(_on_level_up)
	call_deferred("_bind_player_signal")
	Global.xp_changed.connect(update_xp)

func _process(_delta: float) -> void:
	if player_ref == null or not is_instance_valid(player_ref):
		_bind_player_signal()

func _bind_player_signal() -> void:
	var player := get_tree().get_first_node_in_group("Player")
	if player == null:
		return

	if player_ref == player:
		return

	player_ref = player
	if player_ref.has_signal("health_changed"):
		if not player_ref.health_changed.is_connected(update_health):
			player_ref.health_changed.connect(update_health)

	update_health()

func update_all():
	update_health()
	update_xp()
	update_level()

func update_health():
	if player_ref and is_instance_valid(player_ref):
		if "max_health" in player_ref and "current_health" in player_ref:
			health_bar.max_value = player_ref.max_health
			health_bar.value = player_ref.current_health
			return

	health_bar.max_value = Global.lives_limit
	health_bar.value = Global.lives

func update_xp():
	xp_bar.max_value = Global.get_xp_to_next_level(Global.player_level)
	xp_bar.value = Global.player_xp

func update_level():
	level_label.text = "LV." + str(Global.player_level)

func _on_level_up():
	update_all()
