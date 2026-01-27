extends Area2D
class_name CoinBase

@onready var anim: AnimatedSprite2D = $Anim
@onready var collision: CollisionShape2D = $CollisionShape2D
@onready var asp_colect_efect: AudioStreamPlayer = $Audio/ASPColectEfect

@export var value: int = 1
var collected := false

signal collect_coin(value)

func _ready():
	body_entered.connect(_on_body_entered)
	anim.animation_finished.connect(_on_anim_animation_finished)
	collect_coin.connect(_on_collect)

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
	Global.add_xp(value)
	queue_free()

func collect_efx():
	asp_colect_efect.play()
	pass
