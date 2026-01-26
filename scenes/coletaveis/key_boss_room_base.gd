extends Area2D
@export var boss_id: String = "boss_easy_01"

@onready var anim: AnimatedSprite2D = get_node_or_null("Anim")
@onready var key_collect: AudioStreamPlayer = get_node_or_null("Audio/ASPColectEfect")
@onready var collision: CollisionShape2D = get_node_or_null("CollisionShape2D")

signal key_collected(boss_id: String)


var collected := false

func _ready():
	connect("body_entered", Callable(self, "_on_body_entered"))

func _on_body_entered(body: Node) -> void:
	if collected:
		return
	if not body.is_in_group("Player"):
		return

	collected = true

	if collision:
		collision.set_deferred("disabled", true)

	set_deferred("monitoring", false)

	if key_collect:
		key_collect.play()

	if anim:
		anim.play("colect")

	emit_signal("key_collected", boss_id)
