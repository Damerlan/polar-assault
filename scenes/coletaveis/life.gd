#Life - Updated 13-01-26
extends Area2D

@onready var anim: AnimatedSprite2D = $Anim
#@onready var collect_sound: AudioStreamPlayer2D = $collect_sound
@onready var collision: CollisionShape2D = $CollisionShape2D
@onready var asp_colect_efect: AudioStreamPlayer = $Audio/ASPColectEfect


var collected := false

func _ready():
	# 🔗 Conecta os sinais corretamente
	anim.animation_finished.connect(_on_anim_animation_finished)
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node2D) -> void:
	if collected:
		return

	if not body.is_in_group("Player"):
		return

	collected = true

	# 🔒 Desliga colisão
	collision.set_deferred("disabled", true)
	
	asp_colect_efect.play()
	anim.play("colect")

func _on_anim_animation_finished() -> void:
	# 💚 adiciona vida
	ScoreManager.add_life()
	queue_free()
