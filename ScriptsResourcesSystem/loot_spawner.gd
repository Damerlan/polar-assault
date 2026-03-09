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
@export var max_special_spawn_chance := 0.22
@export var boss_key_spawn_chance := 0.05

var key_min_height := Global.MIN_HEIGHT_FOR_BOSS_KEY
var key_min_level := Global.MIN_LEVEL_FOR_BOSS_KEY
var key_weight_scale := Global.KEY_WEIGHT_SCALE

# ===============================
# AUTO-DETECÇÃO
# ===============================
@onready var coins_container: Node2D = get_parent().get_node_or_null("Coins")
@onready var specials_container: Node2D = get_parent().get_node_or_null("Specials")
@onready var keys_container: Node2D = get_parent().get_node_or_null("Keys")
#@onready var keys_container: Node2D = $Keys

func _ready():
	_apply_balance_preset()

	# Segurança absoluta
	if coins_container:
		_spawn_coins()

		
	if specials_container:
		var chance := ScoreManager.get_special_chance_by_height(
			get_parent().global_position.y
		)
		chance = min(chance, max_special_spawn_chance)
		_spawn_special(chance)


func _apply_balance_preset() -> void:
	match Global.balance_preset:
		Global.BalancePreset.EASY:
			max_special_spawn_chance = 0.24
			key_min_height = 520.0
			key_min_level = 1
			key_weight_scale = 0.42
			boss_key_spawn_chance = 0.08
		Global.BalancePreset.HARD:
			max_special_spawn_chance = 0.26
			key_min_height = 650.0
			key_min_level = 2
			key_weight_scale = 0.38
			boss_key_spawn_chance = 0.05
		_:
			max_special_spawn_chance = 0.23
			key_min_height = 620.0
			key_min_level = Global.MIN_LEVEL_FOR_BOSS_KEY
			key_weight_scale = 0.36
			boss_key_spawn_chance = 0.06

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
			(i - (max_coins - 1) / 2.0) * coin_spacing,
			-16
		)

		coins_container.add_child(coin)

# ===============================
# ESPECIAL (JOIA / VIDA / POWER)
# ===============================
func _spawn_special_old(spawn_chance: float):
	if randf() > spawn_chance:
		return

	var data := Global.pick_variant(special_variants)
	var special: Node2D = data["scene"].instantiate()

	special.position = Vector2(0, special_height_offset)
	specials_container.add_child(special)
	
func _spawn_special(spawn_chance: float):
	var run_height := float(ScoreManager.altura)
	if _can_spawn_boss_key(run_height) and randf() <= boss_key_spawn_chance:
		_spawn_boss_key()
		return

	if randf() > spawn_chance:
		return

	var pool := _build_special_pool()
	if pool.is_empty():
		return

	var data := Global.pick_variant(pool)
	var special: Node2D = data["scene"].instantiate()
	var id := String(data.get("id", ""))
	var spawn_y := special_height_offset

	if id.begins_with("gem"):
		spawn_y -= 10
		if ScoreManager.altura < 700:
			spawn_y -= 8

	if id == "bosskey":
		Global.boss_key_spawned_this_run = true

	# Se for key, conecta sinal automaticamente
	if special.has_signal("key_collected"):
		#special.key_collected.connect(_on_key_collected)
		special.key_collected.connect(_on_key_collected)

	special.position = Vector2(0, spawn_y)
	specials_container.add_child(special)


func _spawn_boss_key() -> void:
	var key_scene := _get_key_scene()
	if key_scene == null:
		return

	var special: Node2D = key_scene.instantiate()
	if special.has_signal("key_collected"):
		special.key_collected.connect(_on_key_collected)

	Global.boss_key_spawned_this_run = true
	special.position = Vector2(0, special_height_offset - 6)
	specials_container.add_child(special)


func _get_key_scene() -> PackedScene:
	for v in special_variants:
		if String(v.get("id", "")) == "bosskey":
			return v.get("scene", null)
	return null


func _can_spawn_boss_key(run_height: float) -> bool:
	if Global.boss_key_spawned_this_run:
		return false
	if Global.player_level < key_min_level:
		return false

	var min_height_for_key: float = max(
		key_min_height,
		Global.last_boss_entry_height + Global.MIN_HEIGHT_BETWEEN_BOSS_KEYS
	)
	return run_height >= min_height_for_key

func _build_special_pool() -> Array[Dictionary]:
	var pool: Array[Dictionary] = []
	var run_height := float(ScoreManager.altura)

	for v in special_variants:
		var id := String(v.get("id", ""))
		if id == "bosskey":
			if Global.boss_key_spawned_this_run:
				continue
			if Global.player_level < key_min_level:
				continue
			var min_height_for_key: float = max(
				key_min_height,
				Global.last_boss_entry_height + Global.MIN_HEIGHT_BETWEEN_BOSS_KEYS
			)
			if run_height < min_height_for_key:
				continue

			var key_data := v.duplicate(true)
			key_data["chance"] = float(key_data["chance"]) * key_weight_scale
			pool.append(key_data)
			continue

		pool.append(v)

	return pool
# ===============================
# KEY (BOSS ENTRY)
# ===============================
func _on_key_collected(_boss_id: String) -> void:
	GameManager.request_boss_entry(
		BossRoomManager.pick_room_by_level(Global.player_level)
	)
