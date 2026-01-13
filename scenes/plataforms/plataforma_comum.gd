#Plataforma_comum - Updated 12-01-26
extends StaticBody2D

var visibility = Global.visibility
var player = null

# -------- COINS --------
var max_coins: int = Global.max_coins
var coin_spawn_chance: float = Global.coin_spawn_chance
var coin_spacing: int = Global.coin_spacing
@export var coin_scene: PackedScene

# -------- GEM --------
var gem_spawn_chance: float = Global.gem_spawn_chance  # 8%
@export var gem_scene: PackedScene
var special_height_offset: int = Global.special_height_offset

# -------- LIFE --------
var life_spawn_chance: float = Global.life_spawn_chance
@export var life_scene: PackedScene
var life_height_offset: int = -Global.life_height_offset

# ----------------------

func _ready() -> void:
	player = get_tree().get_first_node_in_group("Player")
	gem_spawn_chance = ScoreManager.get_gem_chance_by_height(global_position.y)

	spawn_coins()
	spawn_gem()
	spawn_life()


# 🪙 COINS
func spawn_coins():
	var coins_container = $Coins
	
	for c in coins_container.get_children():
		c.queue_free()

	for i in max_coins:
		if randf() <= coin_spawn_chance:
			var coin = coin_scene.instantiate()
			coin.position = Vector2(
				(i - max_coins / 2.0) * coin_spacing,
				-16
			)
			coins_container.add_child(coin)


# 💎 GEM
func spawn_gem():
	if randf() > gem_spawn_chance:
		return

	var gem = gem_scene.instantiate()
	gem.position = Vector2(0, special_height_offset)
	$Specials.add_child(gem)


# ❤️ LIFE
func spawn_life():
	if randf() > life_spawn_chance:
		return

	# Evita life + gem juntas (boa prática)
	if $Specials.get_child_count() > 0:
		return

	var life = life_scene.instantiate()
	life.position = Vector2(0, life_height_offset)
	$Lifes.add_child(life)


func _process(_delta: float) -> void:
	if player == null:
		return
	
	if position.y > player.position.y + visibility:
		queue_free()


# 🚀 Posição segura DEFINITIVA
func register_as_safe():
	GameManager.last_safe_position = global_position
	GameManager.last_safe_platform = self
