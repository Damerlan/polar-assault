#PlataformSpawner - Updated 14-01-26
extends Node2D

@export var platform_variants: Array[Dictionary] = [
	{
		"id": "normal",
		"scene": preload("res://scenes/plataforms/plataforma_comum.tscn"),
		"chance": 1.0,
		"unstable": false
	},
	{
		"id": "moving",
		"scene": preload("res://scenes/plataforms/plataforma_movel.tscn"),
		"chance": 0.0,
		"unstable": true
	},
	{
		"id": "falling",
		"scene": preload("res://scenes/plataforms/plataform_breackin.tscn"),
		"chance": 0.0,
		"unstable": true
	},
	{
		"id": "ice",
		"scene": preload("res://scenes/plataforms/plataforma_congelada.tscn"), #escorregadia
		"chance": 0.3,
		"unstable": false
	},
	{
		"id": "spikes",
		"scene": preload("res://scenes/plataforms/plataforma_espinhos.tscn"), #espinhos
		"chance": 0.1,
		"unstable": true
	}
	
]

@export var distance_between := Vector2(190, 380) # 👈 mais espaçado
@export var screen_margin := 45

# ----- PROGRESSÃO -----

@export var base_moving_chance := 0.03
@export var max_moving_chance := 0.35
@export var height_for_max_chance := 6000.0

@export var base_falling_chance := 0.03
@export var max_falling_chance := 0.22
@export var height_for_max_falling := 5000.0

# ----- CONTROLE DE DENSIDADE -----

@export var max_platforms_on_screen := 7   # 👈 LIMITE REAL
@export var max_jump_height := 300

# --------------------------------

var last_platform_y := 0.0
var player
var last_platform_was_unstable := false


func _ready():
	player = get_tree().get_first_node_in_group("Player")
	if player:
		last_platform_y = player.global_position.y + 100
	_spawn_initial_platforms()


func _process(_delta):
	_spawn_platform_if_needed()


# ---------- SPAWN INICIAL ----------

func _spawn_initial_platforms():
	for i in range(5):
		_spawn_platform()


func _update_platform_chances():
	if player == null:
		return

	var h: float = abs(player.global_position.y)

	for p: Dictionary in platform_variants:
		match p["id"]:
			"moving":
				p["chance"] = lerp(
					base_moving_chance,
					max_moving_chance,
					clamp(h / height_for_max_chance, 0.0, 1.0)
				)

			"falling":
				p["chance"] = lerp(
					base_falling_chance,
					max_falling_chance,
					clamp(h / height_for_max_falling, 0.0, 1.0)
				)


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


func _spawn_platform():
	var cam := get_viewport().get_camera_2d()
	if cam == null:
		return

	_update_platform_chances()

	var half_w = get_viewport_rect().size.x * 0.5
	var y_offset = randf_range(distance_between.x, min(distance_between.y, max_jump_height))
	last_platform_y -= y_offset

	var min_x = cam.global_position.x - half_w + screen_margin
	var max_x = cam.global_position.x + half_w - screen_margin

	var data: Dictionary
	if last_platform_was_unstable:
		data = platform_variants[0]
	else:
		data = _pick_platform()

	var platform = data["scene"].instantiate()
	platform.global_position = Vector2(randf_range(min_x, max_x), last_platform_y)
	get_parent().get_node("YSort").add_child(platform)

	last_platform_was_unstable = data["unstable"]


# ---------- CONTROLE DE SPAWN ----------
func _spawn_platform_if_needed():
	var cam := get_viewport().get_camera_2d()
	if cam == null:
		return

	# 🔒 limita quantidade de plataformas
	if _count_platforms_on_screen() >= max_platforms_on_screen:
		return

	var screen_top = cam.global_position.y - get_viewport_rect().size.y * 0.5

	# só spawna quando realmente faltar plataforma acima
	if last_platform_y > screen_top - max_jump_height:
		_spawn_platform()


func _count_platforms_on_screen() -> int:
	var count := 0
	for c in get_parent().get_node("YSort").get_children():
		if c.global_position.y < get_viewport().get_camera_2d().global_position.y + 400:
			count += 1
	return count


# ---------- CHANCES ----------




# ---------- SPAWN REAL ----------
