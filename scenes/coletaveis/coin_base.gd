extends Area2D
class_name CoinBase

@onready var anim: AnimatedSprite2D = $Anim
@onready var collision: CollisionShape2D = $CollisionShape2D

@export var value: int = 1

var collected := false

signal collect_coin(value)

func _ready():
	connect("collect_coin", Callable(self, "_on_collect"))

func _on_body_entered(_body: Node2D) -> void:
	if collected:
		return

	collected = true
	collision.set_deferred("disabled", true)

	collect_efx()
	anim.play("collect")

func _on_anim_animation_finished() -> void:
	emit_signal("collect_coin", value)

func _on_collect(v: int) -> void:
	ScoreManager.add_coin(v)
	queue_free()

func collect_efx():
	# futuramente som ou partículas
	pass
