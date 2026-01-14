extends Node
class_name LootSpawner

# ===============================
# CONFIGURAÇÕES (DEFAULT GLOBAL)
# ===============================
@export var coin_variants: Array[Dictionary] = Global.COIN_VARIANTS
@export var special_variants: Array[Dictionary] = Global.SPECIAL_VARIANTS


@export var max_coins := Global.MAX_COINS
@export var coin_spawn_chance := Global.COIN_SPAWN_CHANCE
@export var coin_spacing := Global.COIN_SPACING

@export var special_height_offset := Global.SPECIAL_HEIGHT_OFFSET

# ===============================
# AUTO-DETECÇÃO
# ===============================
@onready var coins_container: Node2D = get_parent().get_node_or_null("Coins")
@onready var specials_container: Node2D = get_parent().get_node_or_null("Specials")

func _ready():
	# Segurança absoluta
	if coins_container:
		_spawn_coins()

	if specials_container:
		var chance := ScoreManager.get_special_chance_by_height(
			get_parent().global_position.y
		)
		_spawn_special(chance)

# ===============================
# MOEDAS
# ===============================
func _spawn_coins():
	for i in max_coins:
		if randf() > coin_spawn_chance:
			continue

		var data := Global.pick_variant(coin_variants)
		var coin: Node2D = data["scene"].instantiate()

		coin.position = Vector2(
			(i - max_coins / 2.0) * coin_spacing,
			-16
		)

		coins_container.add_child(coin)

# ===============================
# ESPECIAL (JOIA / VIDA / POWER)
# ===============================
func _spawn_special(spawn_chance: float):
	if randf() > spawn_chance:
		return

	var data := Global.pick_variant(special_variants)
	var special: Node2D = data["scene"].instantiate()

	special.position = Vector2(0, special_height_offset)
	specials_container.add_child(special)
