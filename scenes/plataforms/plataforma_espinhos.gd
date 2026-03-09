#Plataforma_com_Espinhos - Updated 12-01-26
extends StaticBody2D

var visibility = Global.VISIBILITY
@export var damage_easy := 10
@export var damage_medium := 16
@export var damage_hard := 24

var base_y := 0.0
var player = null
var can_damage := true
@export var damage_cooldown := 0.25


func _ready() -> void:
	base_y = global_position.y
	player = get_tree().get_first_node_in_group("Player")


func _process(_delta: float) -> void:
	# Remove a plataforma quando o player já passou muito acima
	if player == null:
		return

	if position.y > player.position.y + visibility:
		queue_free()


# 🚀 Posição segura DEFINITIVA
func register_as_safe(): 
	GameManager.last_safe_position = global_position
	GameManager.last_safe_platform = self


# Causa dano ao Player
func _on_area_2d_body_entered(body: Node2D) -> void:
	if not can_damage:
		return
	if not body.is_in_group("Player"):
		return
	if body is CharacterBody2D and body.has_method("take_hit"):
		can_damage = false
		var dir: int = sign(body.global_position.x - global_position.x)
		if dir == 0:
			dir = -1
		body.take_hit(_get_spike_damage(), dir)
		await get_tree().create_timer(damage_cooldown).timeout
		can_damage = true


func _get_spike_damage() -> int:
	match Global.balance_preset:
		Global.BalancePreset.EASY:
			return damage_easy
		Global.BalancePreset.HARD:
			return damage_hard
		_:
			return damage_medium
