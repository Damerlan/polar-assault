#GameManager - Updated 12-01-26
extends Node

# ─────────── VARIÁVEIS ───────────

#----controles da partida
var tempo_partida: float = 0.0
var contando: bool = false
var emergency_offset := Vector2(0, 64) 

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
	#Global.connect("morreu", _on_player_morreu)
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


func iniciar_partida():
	tempo_partida = 0.0
	contando = true


func finalizar_partida():
	contando = false
	emit_signal("partida_finalizada", tempo_partida)


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
	Global.reset_run()
	state = GameState.PLAYING
	get_tree().change_scene_to_file("res://scenes/" + next_scene + ".tscn")
	await get_tree().process_frame
	world = get_tree().current_scene

func _restart_from_game_over():
	Global.reset_run()
	state = GameState.PLAYING
	get_tree().change_scene_to_file("res://scenes/" + next_scene + ".tscn")
	await get_tree().process_frame
	world = get_tree().current_scene
	
#----Verificação da Safe na Sala-1
func is_safe_valid() -> bool:
	if Global.last_safe_platform == null:
		return false
	
	if not is_instance_valid(Global.last_safe_platform):
		return false
	
	return true


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
	
	Global.last_safe_platform = emergency_platform
	Global.last_safe_position = emergency_platform.global_position


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
