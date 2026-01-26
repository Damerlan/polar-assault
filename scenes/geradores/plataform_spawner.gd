#PlataformSpawner - Updated 26-01-26
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

@export var screen_margin := 45
@export var max_platforms_on_screen := 9

# -------- DIFICULDADE PROGRESSIVA --------
@export var difficulty_height := 5000.0
@export var easy_ratio := 0.35
@export var hard_ratio := 0.80

#0.15 → 45px (bem perto mesmo)
#0.25 → 75px
#0.35 → 105px
#0.45 → 135px
@export var horizontal_easy := 0.45
@export var horizontal_hard := 0.65

var max_jump_height := 240.0
var max_jump_distance := 300.0 # será atualizado pelo player se existir função

var last_platform_y := 0.0
var last_platform_x := 0.0

var player
var last_platform_was_unstable := false


func _ready():
	player = get_tree().get_first_node_in_group("Player")
	if player:
		last_platform_y = player.global_position.y + 100
		last_platform_x = player.global_position.x
		max_jump_height = player.get_max_jump_height()
		
		# se você tiver essa função no player
		if player.has_method("get_max_jump_distance"):
			max_jump_distance = player.get_max_jump_distance()

	_spawn_initial_platforms()


func _process(_delta):
	_spawn_platform_if_needed()


# ---------- SPAWN INICIAL (SUPER FÁCIL) ----------
func _spawn_initial_platforms():
	for i in range(7):
		_spawn_platform_initial()


func _spawn_platform_initial():
	var cam := get_viewport().get_camera_2d()
	if cam == null:
		return

	var safe_gap := max_jump_height * 0.30
	last_platform_y -= safe_gap

	var platform = platform_variants[0]["scene"].instantiate()
	platform.global_position = Vector2(last_platform_x, last_platform_y)

	get_parent().get_node("YSort").add_child(platform)
	last_platform_was_unstable = false


# ---------- SPAWN NORMAL ----------
func _spawn_platform():
	var cam := get_viewport().get_camera_2d()
	if cam == null or player == null:
		return

	var half_w = get_viewport_rect().size.x * 0.5

	# 🔥 progresso baseado na altura
	var height_progress = clamp(
		abs(player.global_position.y) / difficulty_height,
		0.0,
		1.0
	)

	# --------- VERTICAL ---------
	var current_ratio = lerp(easy_ratio, hard_ratio, height_progress)

	var max_gap = max_jump_height * current_ratio
	var min_gap = max_gap * 0.6

	var y_offset = randf_range(min_gap, max_gap)
	last_platform_y -= y_offset

	# --------- HORIZONTAL ---------
	var horizontal_ratio = lerp(horizontal_easy, horizontal_hard, height_progress)
	var max_horizontal_offset = max_jump_distance * horizontal_ratio

	var min_x_limit = cam.global_position.x - half_w + screen_margin
	var max_x_limit = cam.global_position.x + half_w - screen_margin

	var new_x = last_platform_x + randf_range(-max_horizontal_offset, max_horizontal_offset)
	new_x = clamp(new_x, min_x_limit, max_x_limit)

	# --------- ESCOLHA DE TIPO ---------
	var data: Dictionary
	if last_platform_was_unstable:
		data = platform_variants[0]
	else:
		data = _pick_platform()

	var platform = data["scene"].instantiate()
	platform.global_position = Vector2(new_x, last_platform_y)

	get_parent().get_node("YSort").add_child(platform)

	last_platform_x = new_x
	last_platform_was_unstable = data["unstable"]


# ---------- ESCOLHA ----------
func _pick_platform() -> Dictionary:
	var total := 0.0
	for p in platform_variants:
		total += p["chance"]

	if total <= 0.0:
		return platform_variants[0]

	var roll := randf() * total
	var acc := 0.0

	for p in platform_variants:
		acc += p["chance"]
		if roll <= acc:
			return p

	return platform_variants[0]


# ---------- CONTROLE DE SPAWN ----------
func _spawn_platform_if_needed():
	var cam := get_viewport().get_camera_2d()
	if cam == null:
		return

	if _count_platforms_on_screen() >= max_platforms_on_screen:
		return

	var screen_top = cam.global_position.y - get_viewport_rect().size.y * 0.5

	if last_platform_y > screen_top - max_jump_height:
		_spawn_platform()


func _count_platforms_on_screen() -> int:
	var count := 0
	for c in get_parent().get_node("YSort").get_children():
		if c.global_position.y < get_viewport().get_camera_2d().global_position.y + 400:
			count += 1
	return count
