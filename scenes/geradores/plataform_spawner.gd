extends Node2D

@export var platform_variants: Array[Dictionary] = [
	{
		"id": "normal",
		"scene": preload("res://scenes/plataforms/plataforma_comum.tscn"),
		"chance": 0.9,
		"unstable": false
	},
	{
		"id": "moving",
		"scene": preload("res://scenes/plataforms/plataforma_movel.tscn"),
		"chance": 0.03,
		"unstable": true
	},
	{
		"id": "falling",
		"scene": preload("res://scenes/plataforms/plataform_breackin.tscn"),
		"chance": 0.2,
		"unstable": true
	},
	{
		"id": "ice",
		"scene": preload("res://scenes/plataforms/plataforma_congelada.tscn"),
		"chance": 0.3,
		"unstable": false
	},
	{
		"id": "spikes",
		"scene": preload("res://scenes/plataforms/plataforma_espinhos.tscn"),
		"chance": 0.1,
		"unstable": true
	}
]

@export var screen_margin := 45.0
@export var difficulty_height := 5000.0

@export var spawn_ahead_pixels := 220.0
@export var cleanup_below_pixels := 320.0

@export var vertical_easy_ratio := 0.45
@export var vertical_hard_ratio := 0.70

@export var horizontal_easy_ratio := 0.30
@export var horizontal_hard_ratio := 0.52

var max_jump_height := 240.0
var max_jump_distance := 300.0

var player: Node2D = null
var ysort: Node = null

var spawn_cursor_y := 0.0
var last_platform_x := 0.0
var unstable_streak := 0


func _ready() -> void:
	_apply_balance_preset()

	ysort = get_parent().get_node_or_null("YSort")
	player = get_tree().get_first_node_in_group("Player")

	if ysort == null or player == null:
		return

	if player.has_method("get_max_jump_height"):
		max_jump_height = player.get_max_jump_height()
	if player.has_method("get_max_jump_distance"):
		max_jump_distance = player.get_max_jump_distance()

	last_platform_x = player.global_position.x
	spawn_cursor_y = player.global_position.y + 20.0

	_spawn_initial_batch()


func _process(_delta: float) -> void:
	if ysort == null:
		ysort = get_parent().get_node_or_null("YSort")
	if player == null or not is_instance_valid(player):
		player = get_tree().get_first_node_in_group("Player")

	if ysort == null or player == null:
		return

	_cleanup_below_camera()
	_fill_ahead_of_camera()


func _apply_balance_preset() -> void:
	match Global.balance_preset:
		Global.BalancePreset.EASY:
			vertical_easy_ratio = 0.40
			vertical_hard_ratio = 0.60
			horizontal_easy_ratio = 0.24
			horizontal_hard_ratio = 0.42
			screen_margin = 52.0
			spawn_ahead_pixels = 240.0
		Global.BalancePreset.HARD:
			vertical_easy_ratio = 0.52
			vertical_hard_ratio = 0.76
			horizontal_easy_ratio = 0.36
			horizontal_hard_ratio = 0.58
			screen_margin = 40.0
			spawn_ahead_pixels = 200.0
		_:
			vertical_easy_ratio = 0.45
			vertical_hard_ratio = 0.70
			horizontal_easy_ratio = 0.30
			horizontal_hard_ratio = 0.52
			screen_margin = 45.0
			spawn_ahead_pixels = 220.0


func _spawn_initial_batch() -> void:
	var cam := get_viewport().get_camera_2d()
	if cam == null:
		return

	var top_limit := _camera_top_y(cam) - spawn_ahead_pixels
	while spawn_cursor_y > top_limit:
		_spawn_one_platform(0.0)


func _fill_ahead_of_camera() -> void:
	var cam := get_viewport().get_camera_2d()
	if cam == null:
		return

	var top_limit := _camera_top_y(cam) - spawn_ahead_pixels
	var safety := 0
	while spawn_cursor_y > top_limit and safety < 16:
		var progress: float = clamp(
			float(ScoreManager.altura) / difficulty_height,
			0.0,
			1.0
		)
		_spawn_one_platform(progress)
		safety += 1


func _spawn_one_platform(progress: float) -> void:
	var cam := get_viewport().get_camera_2d()
	if cam == null:
		return

	var gap_ratio: float = lerp(vertical_easy_ratio, vertical_hard_ratio, progress)
	var max_vertical_gap: float = max_jump_height * gap_ratio
	max_vertical_gap = clamp(max_vertical_gap, 56.0, max_jump_height * 0.78)
	var min_vertical_gap: float = max(44.0, max_vertical_gap * 0.68)

	var y_gap := randf_range(min_vertical_gap, max_vertical_gap)
	spawn_cursor_y -= y_gap

	var half_w := get_viewport_rect().size.x * 0.5
	var min_x := cam.global_position.x - half_w + screen_margin
	var max_x := cam.global_position.x + half_w - screen_margin

	var h_ratio: float = lerp(horizontal_easy_ratio, horizontal_hard_ratio, progress)
	var max_h_offset: float = max_jump_distance * h_ratio
	max_h_offset = clamp(max_h_offset, 45.0, max_jump_distance * 0.70)

	var x_offset := randf_range(-max_h_offset, max_h_offset)
	if abs(x_offset) < 18.0:
		x_offset = 18.0 * (-1.0 if randf() < 0.5 else 1.0)

	var new_x: float = clamp(last_platform_x + x_offset, min_x, max_x)

	var data := _pick_platform_variant(progress)
	var platform: Node2D = data["scene"].instantiate()
	platform.global_position = Vector2(new_x, spawn_cursor_y)
	ysort.add_child(platform)

	last_platform_x = new_x
	unstable_streak = unstable_streak + 1 if bool(data["unstable"]) else 0


func _pick_platform_variant(progress: float) -> Dictionary:
	if unstable_streak >= 1:
		return platform_variants[0]

	var weighted: Array[Dictionary] = []
	var total := 0.0

	for variant in platform_variants:
		var w := float(variant["chance"])
		var id := String(variant["id"])

		match id:
			"normal":
				w *= lerp(1.30, 0.90, progress)
			"ice":
				w *= lerp(0.90, 1.20, progress)
			"moving":
				w *= lerp(0.55, 1.10, progress)
			"falling":
				w *= lerp(0.45, 1.00, progress)
			"spikes":
				if progress < 0.35:
					continue
				w *= lerp(0.30, 0.95, progress)

		if w <= 0.0:
			continue

		var entry := variant.duplicate(true)
		entry["_w"] = w
		weighted.append(entry)
		total += w

	if weighted.is_empty() or total <= 0.0:
		return platform_variants[0]

	var roll := randf() * total
	var acc := 0.0
	for entry in weighted:
		acc += float(entry["_w"])
		if roll <= acc:
			entry.erase("_w")
			return entry

	return platform_variants[0]


func _cleanup_below_camera() -> void:
	var cam := get_viewport().get_camera_2d()
	if cam == null or ysort == null:
		return

	var bottom_limit := _camera_bottom_y(cam) + cleanup_below_pixels
	for child in ysort.get_children():
		if child is Node2D and child.global_position.y > bottom_limit:
			child.queue_free()


func _camera_top_y(cam: Camera2D) -> float:
	return cam.global_position.y - get_viewport_rect().size.y * 0.5


func _camera_bottom_y(cam: Camera2D) -> float:
	return cam.global_position.y + get_viewport_rect().size.y * 0.5
