extends Area2D
class_name GemBase

@onready var anim: AnimatedSprite2D = $Anim
@onready var gem_collect: AudioStreamPlayer = $GemCollect
@onready var collision: CollisionShape2D = $CollisionShape2D

@export var value: int = 1
var collected := false

signal collect_gem(value)

func _ready() -> void:
	# 🔗 Conexões seguras (funcionam em herança)
	body_entered.connect(_on_body_entered)
	anim.animation_finished.connect(_on_anim_animation_finished)
	collect_gem.connect(_on_collect)

	# 🛡️ Segurança
	assert(anim)
	assert(collision)

func _on_body_entered(_body: Node2D) -> void:
	if collected:
		return

	collected = true
	collision.set_deferred("disabled", true)

	collect_efx()
	anim.play("colect")

func _on_anim_animation_finished() -> void:
	emit_signal("collect_gem", value)

func _on_collect(v):
	ScoreManager.add_coin(v)
	queue_free()

func collect_efx():
	if gem_collect:
		gem_collect.play()
