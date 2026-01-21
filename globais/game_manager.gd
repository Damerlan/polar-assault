#GameManager - Updated 12-01-26
extends Node

# ─────────── VARIÁVEIS ───────────

#----controles da partida
var tempo_partida: float = 0.0
var contando: bool = false



#----GAME STATE MACHINE
enum GameState{
	LOBBY,
	PLAYING,
	RANKING,
	GAME_OVER
}

var state: GameState = GameState.LOBBY
var next_scene = ""

#----SISTEMA DE PLATAFORMAS DE EMERGENCIA
var last_safe_position
var last_safe_platform: Node = null

const EMERGENCY_PLATFORM_SCENE := preload("res://scenes/plataforms/plataforma_comum.tscn") #Incluir a sena da plataforma
var world: Node
var emergency_platform: Node = null

#----Onready
@onready var pause_menu: Control = $PauseLayer/PauseMenu

# ---- SISTEMA DE SALAS ESPECIAIS ----
var current_room_data := {}
var return_position := Vector2.ZERO

const PLAYER_SPAWN_MARGIN := 10.0 # margem de segurança

# ─────────── SINAIS ───────────
#sinais da partida
signal tempo_atualizado(tempo: float)
signal partida_finalizada(tempo_final: float)
signal autura_changed(value)

#sinais do sistema
signal pause_requested
signal show_teclado
# ─────────── System ───────────
func _ready():
	ScoreManager.connect("morreu", _on_player_morreu)
	add_to_group("GameManager")
	world = get_tree().current_scene
	print("GameManager ativo, estado:", state)


func _process(delta):
	#contador/relogio
	if contando:
		tempo_partida += delta
		emit_signal("tempo_atualizado", tempo_partida)
	
	#Troca entre tela cheia e modo janela
	if Input.is_action_just_pressed("TogleFullscreen"):
		toggle_fullscreen()

# ─────────── METODOS ───────────
#----CONTROLE DE SCORE


func reset_run():
	Global.lives = 3
	ScoreManager.altura = 0
	ScoreManager.tempo = 0.0
	ScoreManager.itens = 0
	last_safe_position = Vector2.ZERO

func update_autura(player_y):
	ScoreManager.altura = max(ScoreManager.altura, -player_y)
	emit_signal("autura_changed", ScoreManager.altura)
	return

func update_coleta(item):
	ScoreManager.itens = ScoreManager.itens + item
	return

#----CONTROLE 
func _on_player_morreu():
	finalizar_partida()
	state = GameState.GAME_OVER
	print("finalizando partida!")
	game_over()

func game_over():
	print("GAME OVER")
	get_tree().change_scene_to_file("res://scenes/UI/game_over.tscn")
#

func iniciar_partida():
	tempo_partida = 0.0
	contando = true


func finalizar_partida():
	contando = false
	emit_signal("partida_finalizada", tempo_partida)
	print("emitindo sinal partida finalizada!")
	#get_tree().change_scene_to_file("res://scenes/UI/game_over.tscn")
	
	


func formatar_tempo(segundos: float) -> String:
	var total := int(segundos)
	var min := total / 60
	var sec := total % 60
	return "%02d:%02d" % [min, sec]

func start_game():
	match state:
		GameState.LOBBY:
			_start_from_lobby()
		GameState.GAME_OVER:
			_restart_from_game_over()

func _start_from_lobby():
	reset_run()
	state = GameState.PLAYING
	get_tree().change_scene_to_file("res://scenes/system/loading_screen.tscn")
	await get_tree().process_frame
	world = get_tree().current_scene

func _restart_from_game_over():
	reset_run()
	state = GameState.PLAYING
	get_tree().change_scene_to_file("res://scenes/system/loading_screen.tscn")
	await get_tree().process_frame
	world = get_tree().current_scene
	
#----Verificação da Safe na Sala-1
#func is_safe_valid() -> bool:
#	if Global.last_safe_platform == null:
#		return false
	
#	if not is_instance_valid(Global.last_safe_platform):
#		return false
	
#	return true


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
		push_warning("YSort não encontrado na cena atual")
		return

	ysort.add_child(emergency_platform)
	
	GameManager.last_safe_platform = emergency_platform
	GameManager.last_safe_position = emergency_platform.global_position


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

		# só plataformas
		if not child.has_method("register_as_safe"):
			continue

		# precisa estar ACIMA
		if child.global_position.y >= pos.y:
			continue

		var dist: float = pos.y - child.global_position.y
		if dist < closest_dist:
			closest_dist = dist
			closest = child

	return closest

# ─────────── Funçoes de sistema e controle ───────────
func request_pause():#função para ativar o menu no mobile
	emit_signal("pause_requested")

func teclado_show() -> void:
	emit_signal("show_teclado")
	
func toggle_fullscreen():
	if DisplayServer.window_get_mode() != DisplayServer.WINDOW_MODE_FULLSCREEN:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)


# ─────────── Sistema de Salas especiais ───────────
func enter_special_room():
	return_position = last_safe_position

	# pausa o tempo da run
	contando = false

	var level := Global.player_level
	current_room_data = BossRoomManager.pick_room_by_level(level)

	get_tree().change_scene_to_file(current_room_data.scene)


#--- sistema de completa a sala
func complete_special_room():
	var reward: int = current_room_data["reward"]

	ScoreManager.itens += reward
	Global.add_xp(reward / 2)

	if current_room_data.type == "boss":
		ScoreManager.total_boss_death += 1

	_return_to_main_room()
	
func fail_special_room():
	finalizar_partida()
	state = GameState.GAME_OVER
	game_over()
	
func _return_to_main_room():
	get_tree().change_scene_to_file("res://scenes/system/loading_screen.tscn")
	await get_tree().process_frame
	await get_tree().process_frame

	world = get_tree().current_scene
	contando = true

	await get_tree().process_frame
	#restore_player_safe_position()
	
# ─────────── Sistema de Salas Especiais (COMPATÍVEL) ───────────
func start_special_room(room_data: Dictionary) -> void:
	# Salva os dados completos da sala
	current_room_data = room_data

	# Salva posição de retorno
	return_position = last_safe_position

	# Pausa o tempo da run
	contando = false

	# Segurança
	if not room_data.has("scene"):
		push_warning("Sala especial sem cena definida")
		return

	# Troca de cena
	get_tree().change_scene_to_file(room_data["scene"])


#func restore_player_safe_position():
#	var player := get_tree().get_first_node_in_group("Player")
#	if not player:
#		push_warning("Player não encontrado no retorno")
#		return

	# trava controle temporariamente
#	_lock_player(player)

	# espera cena estabilizar
#	await get_tree().process_frame
#	await get_tree().process_frame

	# 🔒 SEMPRE cria uma plataforma segura no retorno
#	spawn_emergency_platform(return_position)
#	await get_tree().process_frame

#	if emergency_platform and is_instance_valid(emergency_platform):
#		player.global_position = emergency_platform.global_position + Vector2(0, -64)
#	else:
		# fallback absoluto
#		player.global_position = return_position + Vector2(0, -64)

#	_unlock_player(player)

#func _lock_player(player: Node) -> void:
#	if player == null:
#		return

#	if player.has_method("lock_control"):
#		player.lock_control()
#	elif "can_control" in player:
#		player.can_control = false


#func _unlock_player(player: Node) -> void:
#	if player == null:
#		return

#	if player.has_method("unlock_control"):
#		player.unlock_control()
#	elif "can_control" in player:
#		player.can_control = true


#func get_spawn_above_platform(platform: Node2D) -> Vector2:
#	var shape_node := platform.get_node_or_null("CollisionShape2D")
#	if shape_node == null:
#		return platform.global_position + Vector2(0, -80)

#	var shape: Shape2D = shape_node.shape
#	var height := 0.0

#	if shape is RectangleShape2D:
#		height = shape.size.y
#	elif shape is CapsuleShape2D:
#		height = shape.height
#	else:
#		height = 64

#	var top_y := platform.global_position.y - (height * 0.5)

#	return Vector2(
#		platform.global_position.x,
#		top_y - PLAYER_SPAWN_MARGIN
#	)



#func spawn_player_on_platform(player: Node2D, platform: Node2D) -> void:
	#_lock_player(player)

#	await get_tree().physics_frame

#	var spawn_pos := get_spawn_above_platform(platform)
#	player.set_deferred("global_position", spawn_pos)

#	await get_tree().physics_frame
#	await get_tree().physics_frame

	#_unlock_player(player)

func exit_boss_room(victory: bool, reward: int = 0):
	if victory:
		ScoreManager.add_score(reward)
		Global.coming_from_boss = true

	get_tree().change_scene_to_file("res://scenes/main_room.tscn")
