extends Node2D


@export var dialogue_sequence := [
	{"speaker": "boss", "text": "Eu vou te fazer andar na prancha, intruso!"},
	{"speaker": "player", "text": "Devolva meu tesouro, Pirata!"},
	{"speaker": "boss", "text": "Hahaha! Venha pegar, projeto de marujo!"}
]

@onready var player := get_tree().get_first_node_in_group("Player")
@onready var boss := get_tree().get_first_node_in_group("Boss")
@onready var camera: Camera2D = $Camera2D


# ─────────── AJUSTES DE SALA ───────────
@export var player_jump_force := -520.0    #Player
@export var player_soft_jump_multiplier := 0.8	#Player
@export var player_momentum_jump_multiplier := 0.25	#Player

@export var intro_camera_position := Vector2.ZERO
@export var pan_offset := Vector2(120, 0)
@export var pan_duration := 1.5

@export var intro_zoom := Vector2(0.9, 0.9)
@export var fight_zoom := Vector2(1.0, 1.0)

@export var camera_follow_speed := 4.0
@export var camera_soft_limit := 0.08


# ─────────── CONTROLE DE ESTADO ───────────
var dialogue_index := 0
var fight_started := false
var can_advance := false
var in_dialogue := false

var camera_target_position: Vector2


func _ready():
	camera_target_position = intro_camera_position
	setup_camera_intro()
	play_intro_pan()
	start_intro()


# ─────────── CAMERA ───────────

func setup_camera_intro():
	camera.global_position = intro_camera_position
	camera.zoom = Vector2(1, 1)
	camera.position_smoothing_enabled = false
	camera.drag_horizontal_enabled = false
	camera.drag_vertical_enabled = false


func play_intro_pan():
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_OUT)

	tween.tween_property(
		camera,
		"global_position",
		intro_camera_position + pan_offset,
		pan_duration
	)

	tween.parallel().tween_property(
		camera,
		"zoom",
		intro_zoom,
		pan_duration
	)


func start_camera_follow():
	fight_started = true

	camera.position_smoothing_enabled = true
	camera.position_smoothing_speed = camera_follow_speed

	camera.drag_horizontal_enabled = true
	camera.drag_vertical_enabled = true

	var tween := create_tween()
	tween.tween_property(camera, "zoom", fight_zoom, 0.6)


func _process(delta):
	if not fight_started:
		return

	# alvo suavizado (amortece os limites)
	camera_target_position = camera_target_position.lerp(
		player.global_position,
		camera_soft_limit
	)

	camera.global_position = camera.global_position.lerp(
		camera_target_position,
		delta * camera_follow_speed
	)


# ─────────── FLOW DA SALA ───────────

func start_intro():
	player.can_control = false

	player.apply_boss_room_jump(
		player_jump_force,
		player_soft_jump_multiplier,
		player_momentum_jump_multiplier
	)

	boss.state = boss.State.INTRO
	dialogue_index = 0
	in_dialogue = true

	show_next_dialogue()


func show_next_dialogue():
	if dialogue_index >= dialogue_sequence.size():
		end_intro()
		return

	var line = dialogue_sequence[dialogue_index]
	var balloon

	if line.speaker == "boss":
		balloon = boss.show_dialogue(line.text)
	else:
		balloon = player.show_dialogue(line.text)

	can_advance = false
	in_dialogue = true

	balloon.finished_typing.connect(_on_typing_finished, CONNECT_ONE_SHOT)
	dialogue_index += 1


func _on_typing_finished():
	can_advance = true


func end_intro():
	player.clear_dialogue()
	boss.clear_dialogue()

	in_dialogue = false
	player.can_control = true
	boss.state = boss.State.CHASE

	start_camera_follow()
	GameManager.iniciar_partida()


# ─────────── INPUT ───────────

func _unhandled_input(event):
	if not in_dialogue or not can_advance:
		return

	if event.is_action_pressed("ui_accept"):
		player.clear_dialogue()
		boss.clear_dialogue()
		show_next_dialogue()


# ─────────── FIM DA LUTA ───────────

func on_boss_defeated():
	player.restore_default_jump()
	abrir_portas()


func abrir_portas() -> void:
	pass


func _on_drop_area_body_entered(body: Node2D) -> void:
	#verifica se quem entrou é o player
	if body.is_in_group("Player"):
		#chama o metodo hit
		if body.has_method("take_hit"):
			body.take_hit()
			print("Player tomo um dano")
	
	print("Alguem caiu aqui")
#player := get_tree().get_first_node_in_group("Player")
