extends Area2D

@export var boss_id: String = "boss_easy_01"

@onready var anim: AnimatedSprite2D = $Anim
@onready var key_collect: AudioStreamPlayer = $KeyCollect
#@onready var gem_collect: AudioStreamPlayer = $GemCollect
@onready var collision: CollisionShape2D = $CollisionShape2D

@export var value: int = 1
var collected := false



func _ready():
	connect("body_entered", Callable(self, "_on_body_entered"))

func _on_body_entered(body: Node) -> void:
	if collected:
		return

	collected = true
	collision.set_deferred("disabled", true)

	collect_efx()
	anim.play("colect")
	
	# Garante que só o player ativa
	if not body.is_in_group("Player"):
		return

	# Evita ativação duplicada
	set_deferred("monitoring", false)

	# Solicita ao GameManager a entrada na sala especial
	GameManager.start_special_room(
	BossRoomManager.pick_room_by_level(Global.player_level)
)

	# Remove o item do mapa
	queue_free()

func _on_anim_animation_finished() -> void:
	#emit_signal("collect_gem", value)
	pass

func _on_collect(v):
	ScoreManager.add_coin(v)
	queue_free()

func collect_efx():
	if key_collect:
		key_collect.play()
