# GameManager - Updated 12-01-26
extends Node

# ─────────── VARIÁVEIS ───────────

# ---- CONTROLE DA PARTIDA ----
var tempo_partida: float = 0.0
var contando: bool = false


# ---- GAME STATE MACHINE ----
enum GameState {
	LOBBY,
	PLAYING,
	RANKING,
	GAME_OVER
}

var state: GameState = GameState.LOBBY

# ---- SISTEMA DE PLATAFORMAS SEGURAS ----
var last_safe_position: Vector2 = Vector2.ZERO
var last_safe_platform: Node = null

const EMERGENCY_PLATFORM_SCENE := preload("res://scenes/plataforms/plataforma_comum.tscn")
var emergency_platform: Node = null

# ---- WORLD / SCENE ----
var world: Node
var tracked_player: Node = null

# ---- FADE ----
const SCREEN_FADE := preload("res://scenes/system/screen_fade.tscn")
var screen_fade: CanvasLayer

# ---- SALAS ESPECIAIS / BOSS ----
var current_room_data := {}
var return_position := Vector2.ZERO
var boss_entry_score := 0
var boss_entry_lives := 0

# ─────────── SINAIS ───────────
signal tempo_atualizado(tempo: float)
signal partida_finalizada(tempo_final: float)
signal autura_changed(value)

signal pause_requested
signal show_teclado

# ─────────── SYSTEM ───────────
func _ready():
	ScoreManager.connect("morreu", _on_player_morreu)
	add_to_group("GameManager")

	screen_fade = SCREEN_FADE.instantiate()
	get_tree().root.call_deferred("add_child", screen_fade)
	await get_tree().process_frame

	if screen_fade:
		var fade_rect := screen_fade.get_node_or_null("FadeRect")
		if fade_rect:
			fade_rect.modulate.a = 0.0
		screen_fade.hide()


	world = get_tree().current_scene
	_ensure_player_death_connection()
	print("GameManager ativo, estado:", state)

func _process(delta):
	_ensure_player_death_connection()

	if contando:
		tempo_partida += delta
		emit_signal("tempo_atualizado", tempo_partida)

	if Input.is_action_just_pressed("TogleFullscreen"):
		toggle_fullscreen()

# ─────────── RUN / SCORE ───────────
func reset_run():
	Global.lives = Global.lives_limit
	Global.boss_key_spawned_this_run = false
	ScoreManager.altura = 0
	ScoreManager.tempo = 0.0
	ScoreManager.itens = 0
	last_safe_position = Vector2.ZERO
	last_safe_platform = null
	Global.boss_seals_gained.clear()

func update_autura(player_y):
	ScoreManager.altura = max(ScoreManager.altura, -player_y)
	emit_signal("autura_changed", ScoreManager.altura)
	#Global.add_xp(20)

func update_coleta(item):
	ScoreManager.itens += item

# ─────────── GAME OVER ───────────
func _on_player_morreu():
	if state == GameState.GAME_OVER:
		return

	finalizar_partida()
	state = GameState.GAME_OVER
	await game_over()

func game_over():
	if screen_fade:
		screen_fade.fade_in(0.6)
		await screen_fade.fade_finished

	get_tree().change_scene_to_file("res://scenes/UI/game_over.tscn")
	await get_tree().process_frame

	if screen_fade:
		screen_fade.fade_out(0.6)

func iniciar_partida():
	if Global.coming_from_boss:
		return
	
	tempo_partida = 0.0
	contando = true

func finalizar_partida():
	contando = false
	emit_signal("partida_finalizada", tempo_partida)

# ─────────── START GAME ───────────
func start_game():
	match state:
		GameState.LOBBY, GameState.GAME_OVER:
			_start_game_flow()

func _start_game_flow():
	reset_run()
	state = GameState.PLAYING

	if screen_fade:
		screen_fade.fade_in(0.5)
		await screen_fade.fade_finished

	get_tree().change_scene_to_file("res://scenes/system/loading_screen.tscn")
	await get_tree().process_frame

	if screen_fade:
		screen_fade.fade_out(0.5)

	world = get_tree().current_scene

# ─────────── SAFE PLATFORM ───────────
func spawn_emergency_platform(pos: Vector2):
	if emergency_platform and is_instance_valid(emergency_platform):
		return

	emergency_platform = EMERGENCY_PLATFORM_SCENE.instantiate()
	emergency_platform.global_position = pos + Vector2(0, -120)

	var scene := get_tree().current_scene
	if scene == null:
		return

	var ysort := scene.get_node_or_null("YSort")
	if ysort == null:
		return

	ysort.add_child(emergency_platform)

	last_safe_platform = emergency_platform
	last_safe_position = emergency_platform.global_position

# ─────────── SISTEMA DE BOSS ───────────
func request_boss_entry(room_data: Dictionary) -> void:
	current_room_data = room_data
	return_position = last_safe_position
	contando = false
	boss_entry_score = ScoreManager.itens
	boss_entry_lives = Global.lives
	Global.last_boss_entry_height = float(ScoreManager.altura)

	Global.saved_run_time = tempo_partida
	Global.coming_from_boss = true

	var player := get_tree().get_first_node_in_group("Player")
	if player and "can_control" in player:
		player.can_control = false

	await _play_boss_transition()

func _play_boss_transition():
	await get_tree().process_frame

	if screen_fade:
		screen_fade.fade_in(0.8)

	await get_tree().create_timer(0.9).timeout
	get_tree().change_scene_to_file(current_room_data["scene"])

# ─────────── VITÓRIA DO BOSS ───────────

func handle_boss_victory():
	print("🏆 Boss derrotado")
	contando = false

	var player := get_tree().get_first_node_in_group("Player")
	if player:
		player.can_control = false

	await _teleport_player_to_safe_platform(player)
	if player and "can_control" in player:
		player.can_control = true
	await _apply_boss_rewards()
	await _play_victory_sequence(player)
	await _return_from_special_room()


func _return_from_special_room() -> void:

	Global.coming_from_boss = true
	Global.boss_key_spawned_this_run = false

	await get_tree().create_timer(2.0).timeout

	if screen_fade:
		screen_fade.fade_in(0.8)
		await get_tree().create_timer(0.9).timeout

	get_tree().change_scene_to_file("res://scenes/rooms/sala_01.tscn")

	await get_tree().process_frame
	await get_tree().process_frame

	if screen_fade:
		screen_fade.fade_out(0.8)

	contando = true



func _teleport_player_to_safe_platform(player):
	if player == null:
		return

	if last_safe_platform == null or not is_instance_valid(last_safe_platform):
		spawn_emergency_platform(return_position)
		await get_tree().process_frame

	player.global_position = last_safe_platform.global_position + Vector2(0, -22)
	if "velocity" in player:
		player.velocity = Vector2.ZERO
	await get_tree().process_frame

func _play_victory_sequence(player):
	if player and player.has_method("play_victory"):
		player.play_victory()

	await get_tree().create_timer(2.0).timeout

func _apply_boss_rewards():
	var reward: int = current_room_data.get("reward", 0)
	var seal: String = current_room_data.get("seal", "")

	ScoreManager.itens += reward
	Global.add_xp(roundi(reward / 2.0))

	if seal != "":
		Global.unlock_seal(seal)
	if not Global.boss_seals_gained.has(seal):
		Global.boss_seals_gained.append(seal)

	await get_tree().create_timer(2.0).timeout

func _return_from_boss_room():
	if screen_fade:
		screen_fade.fade_in(0.8)

	await get_tree().create_timer(1.0).timeout

	get_tree().call_deferred(
		"change_scene_to_file",
		"res://scenes/rooms/sala_01.tscn"
	)
	
	await get_tree().process_frame

	if screen_fade:
		screen_fade.fade_out(0.8)

	contando = true

# ─────────── SISTEMA / UTIL ───────────
func request_pause():
	emit_signal("pause_requested")

func teclado_show():
	emit_signal("show_teclado")

func toggle_fullscreen():
	if DisplayServer.window_get_mode() != DisplayServer.WINDOW_MODE_FULLSCREEN:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)


func formatar_tempo(segundos: float) -> String:
	var total := int(segundos)
	var minutes := int(total / 60.0)
	var sec := total % 60
	return "%02d:%02d" % [minutes, sec]


func on_player_morreu() -> void:
	_on_player_morreu()


func _ensure_player_death_connection() -> void:
	var player := get_tree().get_first_node_in_group("Player")
	if player == null:
		return

	if tracked_player == player:
		return

	if tracked_player and is_instance_valid(tracked_player):
		if tracked_player.has_signal("morreu"):
			if tracked_player.morreu.is_connected(_on_player_morreu):
				tracked_player.morreu.disconnect(_on_player_morreu)

	tracked_player = player
	if tracked_player.has_signal("morreu"):
		if not tracked_player.morreu.is_connected(_on_player_morreu):
			tracked_player.morreu.connect(_on_player_morreu)


func restart_from_game_over() -> void:
	_restart_from_game_over()



func find_nearest_platform_above(pos: Vector2) -> Node2D:
	var scene := get_tree().current_scene
	if scene == null:
		return null

	var ysort := scene.get_node_or_null("YSort")
	if ysort == null:
		return null

	var closest: Node2D = null
	var closest_dist := INF

	for child in ysort.get_children():
		if not child is Node2D:
			continue

		# apenas plataformas seguras
		if not child.has_method("register_as_safe"):
			continue

		# precisa estar acima do ponto
		if child.global_position.y >= pos.y:
			continue

		var dist: float = pos.y - child.global_position.y
		if dist < closest_dist:
			closest_dist = dist
			closest = child

	return closest


func fail_special_room() -> void:
	print("❌ Falha na sala especial")

	contando = false

	# Se havia vida de reserva antes da sala, retorna para a run
	var can_return_to_run := boss_entry_lives > 20
	if can_return_to_run:
		ScoreManager.itens = boss_entry_score
		Global.lives = max(boss_entry_lives - 20, 20)
		Global.coming_from_boss = true
		Global.boss_key_spawned_this_run = false

		if screen_fade:
			screen_fade.fade_in(0.8)
			await screen_fade.fade_finished

		get_tree().change_scene_to_file("res://scenes/rooms/sala_01.tscn")
		await get_tree().process_frame
		await get_tree().process_frame

		if screen_fade:
			screen_fade.fade_out(0.8)

		state = GameState.PLAYING
		contando = true
		return

	state = GameState.GAME_OVER
	Global.boss_key_spawned_this_run = false

	# Fade IN (fecha a tela)
	if screen_fade:
		screen_fade.fade_in(0.8)
		await screen_fade.fade_finished

	# Troca de cena
	get_tree().change_scene_to_file(
		"res://scenes/UI/game_over.tscn"
	)

	await get_tree().process_frame

	# Fade OUT (abre a tela no game over)
	if screen_fade:
		screen_fade.fade_out(0.8)

func _restart_from_game_over():
	reset_run()
	state = GameState.PLAYING
	get_tree().change_scene_to_file("res://scenes/system/loading_screen.tscn")
	await get_tree().process_frame
	world = get_tree().current_scene

func _on_key_collected(_boss_id):
	request_boss_entry(
		BossRoomManager.pick_room_by_level(Global.player_level)
	)
