extends Node2D

@export var platform_scene: PackedScene
@export var moving_platform_scene: PackedScene
@export var falling_platform_scene: PackedScene

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

func _get_moving_platform_chance() -> float:
	if player == null:
		return base_moving_chance

	var t = clamp(abs(player.global_position.y) / height_for_max_chance, 0.0, 1.0)
	return lerp(base_moving_chance, max_moving_chance, t)


func _get_falling_platform_chance() -> float:
	if player == null:
		return base_falling_chance

	var t = clamp(abs(player.global_position.y) / height_for_max_falling, 0.0, 1.0)
	return lerp(base_falling_chance, max_falling_chance, t)


# ---------- SPAWN REAL ----------

func _spawn_platform():
	var cam := get_viewport().get_camera_2d()
	if cam == null:
		return

	var half_w = get_viewport_rect().size.x * 0.5
	var y_offset = randf_range(distance_between.x, min(distance_between.y, max_jump_height))
	last_platform_y -= y_offset

	var min_x = cam.global_position.x - half_w + screen_margin
	var max_x = cam.global_position.x + half_w - screen_margin

	var roll = randf()
	var p
	var unstable := false

	if not last_platform_was_unstable:
		if roll < _get_falling_platform_chance() and falling_platform_scene:
			p = falling_platform_scene.instantiate()
			unstable = true
		elif roll < _get_falling_platform_chance() + _get_moving_platform_chance() and moving_platform_scene:
			p = moving_platform_scene.instantiate()
			unstable = true
		else:
			p = platform_scene.instantiate()
	else:
		p = platform_scene.instantiate()

	p.global_position = Vector2(randf_range(min_x, max_x), last_platform_y)
	get_parent().get_node("YSort").add_child(p)

	last_platform_was_unstable = unstable
