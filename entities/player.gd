#Player - Updated 13-01-26
extends CharacterBody2D

#---------------------------------------------
# ENUM – Estados
#---------------------------------------------
enum PlayerState{
	idle,
	run,
	jump,
	hit,
	fall,
	death
}

@onready var fx_jump: AudioStreamPlayer = $Souds/fx_jump
@onready var fx_damage: AudioStreamPlayer = $Souds/fx_damage
@onready var fx_teleport: AudioStreamPlayer = $Souds/fx_teleport
@onready var dialog_ballom: Marker2D = $DialogBallom

#---------------------------------------------
# Nodes
#---------------------------------------------
@onready var anim: AnimatedSprite2D = $Skin
@onready var jump_ui: Node2D = $JumpPouwerUi
@onready var jump_fill: ColorRect = $JumpPouwerUi/Fill
@onready var dust_particles: GPUParticles2D = $DustParticles

@export var jump_ui_height := 12.0
@export var jump_ui_fade_speed := 20.0
#---------------------------------------------
# Variáveis exportáveis
#---------------------------------------------
@export var momentum_move_multiplier := 0.15 # antes era 0.3

@export var max_speed = 250
@export var move_speed := 160.0
@export var acceleration := 600.0
@export var deceleration := 1200.0
@export var jump_force := -600.0

@export var soft_jump_multiplier := 0.55

# --- Modificadores de sala ---
var base_jump_force: float
var base_soft_jump_multiplier: float
var base_momentum_jump_multiplier := 0.4

@export var min_accel_factor := 0.5 #movimento 

#sistema de baloes de dialogo
@export var dialogue_balloon_scene: PackedScene
var current_balloon: Node2D
#---------------------------------------------
# Sinais
#---------------------------------------------
signal morreu

#---------------------------------------------
# Internas
#---------------------------------------------
var can_control := true #trava de controle para boss fight

# ---------------------------------------------
# Plataforma escorregadia (ICE)
# ---------------------------------------------
var on_ice: bool = false

@export var ice_accel_multiplier: float = 0.6   # menos resposta ao input
@export var ice_decel_multiplier: float = 0.05    # demora pra parar

# Gelo
#ice_accel_multiplier = 0.6   # responde melhor ao input
#ice_decel_multiplier = 0.05 # demora MUITO pra parar
var status: PlayerState	#variável de status
@export var input_dir := 0.0

var JUMP_VELOCITY = -600.0
var SPEED = 80.0

#adicionando a mecanica do momentum
@export var run_momentum := 0.0     # aumenta enquanto corre
@export var max_momentum := 500.0   # limite do momentum
@export var momentum_gain := 450.0
@export var momentum_decay := 60.0

#-----------funçoes do sistema e fisica------------------#
func _ready() -> void:
	#criando bkp das mecanicas de pulo
	base_jump_force = jump_force
	base_soft_jump_multiplier = soft_jump_multiplier
	base_momentum_jump_multiplier = 0.4
	
	#can_control = false # teste
	go_to_idle_state()	#coloca o player em idle state
	jump_ui.position = Vector2(9, -7)
	#show_dialogue("Teste funcionando")
	#show_dialogue("Teste de fala")
	if OS.has_feature("web") or OS.has_feature("mobile"):
		if dust_particles:
			dust_particles.queue_free()
   

func _physics_process(delta: float) -> void:	#processo de fisica
	#mecanica de controle das salas de boss
	if not can_control:
		velocity = Vector2.ZERO
		move_and_slide()
		return
	#-----
	read_input()
	#gravidade
	if not is_on_floor():	#se o player nao está no chão
		velocity += get_gravity() * delta	#aplica o efeito de gravidade
	
	var is_moving = abs(velocity.x) > 10
	var on_ground = is_on_floor()
	
	#dust_particles.emitting = is_moving and on_ground
	if dust_particles:
		dust_particles.emitting = is_moving and on_ground
	#if is_on_floor(): #se estiver na plataforma
	#	Global.last_safe_position = global_position
	
	if is_on_floor(): #registrando a plataforma
		var normal = get_floor_normal()
		# Garante que o player pousou no topo plano da plataforma
		if normal.is_equal_approx(Vector2.UP):
			# Pegamos a plataforma pela última colisão do slide
			var collision = get_last_slide_collision()
			
			if collision:
				var obj = collision.get_collider()

				if obj:#verifica se está no gelo
					# Se a plataforma TEM gelo
					if obj.has_method("is_ice") and obj.is_ice():
						enter_ice(
							obj.ice_accel_multiplier,
							obj.ice_decel_multiplier
						)
					else:
						exit_ice()

				if obj and obj.has_method("register_as_safe"):
					obj.register_as_safe()
		#else:
			# Aqui evitamos registrar plataformas onde o player
			# pousou na quina ou numa lateral
		#print("Ignorado: pousou na quina / lateral.")
	# Saiu do chão? NÃO pode continuar no gelo
	
	#detecta se o player esta no jelo
	if not is_on_floor() and on_ice:
		exit_ice()
	# --- State Machine ---
	match status:
		PlayerState.idle:
			idle_state(delta)
		PlayerState.run:
			run_state(delta)
		PlayerState.jump:
			jump_state(delta)
		PlayerState.hit:
			hit_state(delta)
		PlayerState.fall:
			fall_state(delta)
		PlayerState.death:
			death_state(delta)
	#fim do Switch
	update_jump_ui()#jump UI
	move_and_slide()#calcula a posição do player com base no movimento
 	#debug
	#if on_ice:
	#print("🧊 ICE ATIVO")

#balao de dialogo
func show_dialogue(text: String) -> Node2D:
	if current_balloon:
		current_balloon.queue_free()

	current_balloon = dialogue_balloon_scene.instantiate()
	get_tree().current_scene.add_child(current_balloon)

	current_balloon.show_at(dialog_ballom.global_position)
	current_balloon.set_text(text)

	return current_balloon



func clear_dialogue():
	if current_balloon:
		current_balloon.queue_free()
		current_balloon = null	
	

func enter_ice(accel_mult: float, decel_mult: float):
	on_ice = true
	ice_accel_multiplier = accel_mult
	ice_decel_multiplier = decel_mult

func exit_ice():
	on_ice = false
	ice_accel_multiplier = 1.0
	ice_decel_multiplier = 1.0
#---#funçoes de preparação para o status do player-------#


func go_to_idle_state():#entrada idle state
	status = PlayerState.idle	 #define o estado
	anim.play("idle")	#define a animação

func go_to_run_state():#entrada run state (Caminhada)
	status = PlayerState.run
	anim.play("run")

func go_to_jump_state():
	status = PlayerState.jump
	fx_jump.play()
	anim.play("jump")
	#velocity.y = JUMP_VELOCITY	#aplica a ação do pulo

func go_to_fall_state():
	status = PlayerState.fall
	anim.play("fall")

func go_to_hit_state():
	status = PlayerState.hit
	anim.play("hit")
	fx_damage.play()

func go_to_death_state():
	status = PlayerState.death
	#anim.play("death")
	

#------#funções de estado#------------------#

func idle_state(delta):
	apply_movement(delta)
	GameManager.update_autura(global_position.y) 	#calcula a pontuação
	#decai o momentum
	run_momentum = max(run_momentum - momentum_decay * delta, 0)
	if Input.is_action_just_pressed("jump"):
		jump()
	elif  Input.is_action_just_pressed("jump_soft"):
		soft_jump()
		
	if input_dir != 0:
		go_to_run_state()
		return


func run_state(delta):
	apply_movement(delta)
	
	# acumula momentum enquanto corre
	var is_actually_moving: bool = abs(velocity.x) > 5.0
	
	if input_dir != 0 and is_actually_moving:
		run_momentum += momentum_gain * delta
	else:
		run_momentum -= momentum_decay * delta
	
	run_momentum = clamp(run_momentum, 0, max_momentum)
	
	if input_dir == 0:
		go_to_idle_state()
		return
	
	if Input.is_action_just_pressed("jump"):	#se o player apertou jump
		jump()	#coloca o player no estado de jump
		return
	elif Input.is_action_just_pressed("jump_soft"):
		soft_jump()
		return


func jump_state(delta):
	apply_movement(delta)
	
	# se começou a cair → entra em fall
	if velocity.y > 0:
		go_to_fall_state()
		return
		
	# ao tocar no chão
	if is_on_floor():
		if input_dir == 0:
			go_to_idle_state()
		else:
			go_to_run_state()


func fall_state(delta):
	apply_movement(delta)
	
	# momentum perde força no ar
	run_momentum = max(run_momentum - momentum_decay * delta, 0)

	if is_on_floor():
		run_momentum = 0   # reset momentum ao pousar
		if input_dir == 0:
			go_to_idle_state()
		else:
			go_to_run_state()
	

func hit_state(delta):
	# Player não mexe horizontalmente enquanto leva dano
	velocity.x = move_toward(velocity.x, 0, 30 * delta)
	

func death_state(_delta):
	pass

#----------#Funçoes auxiliares do sistema#-----------------#




func aply_gravity(_delta):
	pass


func aplyca_gravity(_delta):
	pass


func update_direction():
	pass


func apply_movement(delta):
	var accel := acceleration * ice_accel_multiplier
	var decel := deceleration * ice_decel_multiplier

	# 🔒 REDUZ aceleração conforme momentum cresce
	if not on_ice:
		var momentum_ratio: float = float(run_momentum) / float(max_momentum)
		var accel_factor: float = lerp(1.0, min_accel_factor, momentum_ratio)
		accel *= accel_factor

	if input_dir != 0:
		var speed_with_momentum = move_speed + (run_momentum * momentum_move_multiplier)
		speed_with_momentum = min(speed_with_momentum, max_speed)

		velocity.x = move_toward(
			velocity.x,
			input_dir * speed_with_momentum,
			accel * delta
		)
	else:
		velocity.x = move_toward(
			velocity.x,
			0,
			decel * delta
		)

	# trava final de segurança
	velocity.x = clamp(velocity.x, -max_speed, max_speed)

	if input_dir < 0:
		anim.flip_h = true
	elif input_dir > 0:
		anim.flip_h = false




func read_input():
	input_dir = Input.get_axis("move_left", "move_right")

func jump_old():#Jump antigo
	#velocity.y = jump_force
	var extra_force = run_momentum * 0.4    # 40% do momentum vira força no pulo
	velocity.y = jump_force - extra_force
	go_to_jump_state()
	#change_state(PlayerState.jump)

func jump(): #novo Jump
	var extra_force = run_momentum * base_momentum_jump_multiplier
	velocity.y = jump_force - extra_force
	go_to_jump_state()	
	
func soft_jump_old():#soft antigo
	if not is_on_floor():
		return
		
	var extra_force = run_momentum * 0.2 #menos influencia do momentum
	velocity.y = (jump_force * soft_jump_multiplier) - extra_force
	go_to_jump_state()


func soft_jump():#soft jump novo
	if not is_on_floor():
		return

	var extra_force = run_momentum * (base_momentum_jump_multiplier * 0.5)
	velocity.y = (jump_force * soft_jump_multiplier) - extra_force
	go_to_jump_state()


func apply_knockback(dir) -> void:
	if not is_on_floor():
		return
	
	velocity.x = dir * 180
	velocity.y = -420
#-----------------------------------------#

func update_jump_ui():
	var ratio := run_momentum / max_momentum
	ratio = clamp(ratio, 0.0, 1.0)

	# Atualiza tamanho da barra
	jump_fill.size.y = jump_ui_height * ratio
	jump_fill.position.y = jump_ui_height - jump_fill.size.y

	# Condição de exibição
	var should_show := is_on_floor() and ratio >= 0.5

	# Fade suave (GDScript correto)
	var target_alpha := 1.0 if should_show else 0.0

	jump_ui.modulate.a = lerp(
		jump_ui.modulate.a,
		target_alpha,
		jump_ui_fade_speed * get_physics_process_delta_time()
	)
	

#---------------------------------------------
# SISTEMA DE DANO + RESPAWN
#---------------------------------------------
func take_hit():
	# evita reentrar
	if status == PlayerState.hit or status == PlayerState.death:
		return

	# remove vida
	ScoreManager.remove_life()

	# sempre mostra feedback
	go_to_hit_state()
	velocity = Vector2.ZERO

	# MORTE
	if Global.lives <= 0:
		call_deferred("_die")
		return

	# AINDA VIVO
	call_deferred("_do_respawn")
	
	#elif Nglobal.lives == 0:
	#	morrer()
func _die():
	go_to_death_state()
	emit_signal("morreu")
	game_over()

func game_over():
	print("GAME OVER")
	get_tree().change_scene_to_file("res://huds/game_over.tscn")
#


func _do_respawn():
	#  Se não existir plataforma safe válida, pede spawn emergencial
	var gm = get_tree().get_first_node_in_group("GameManager")

	# tenta plataforma segura registrada 
	if GameManager.last_safe_platform == null or !is_instance_valid(GameManager.last_safe_platform):
		if gm:
			var nearest = gm.find_nearest_platform_above(global_position)
			if nearest:
				GameManager.last_safe_platform = nearest
				GameManager.last_safe_position = nearest.global_position
			else:
				# 2️⃣ se não achou nenhuma, cria emergencial ACIMA
				gm.spawn_emergency_platform(global_position + Vector2(0, -120))
				await get_tree().process_frame

	#  Ainda não tem posição segura? cancela (failsafe)
	if GameManager.last_safe_position == Vector2.ZERO:
		return

	# Teleporte
	fx_teleport.play()
	global_position = GameManager.last_safe_position + Vector2(0, -40)
	velocity = Vector2.ZERO

	# Invulnerável por 0.2s
	status = PlayerState.hit
	await get_tree().create_timer(0.2).timeout
	
	go_to_idle_state()

# ===============================
# CONTROLE DE MECÂNICA POR SALA
# ===============================
func apply_boss_room_jump(
	new_jump_force: float,
	new_soft_multiplier: float,
	new_momentum_multiplier: float
) -> void:
	jump_force = new_jump_force
	soft_jump_multiplier = new_soft_multiplier
	base_momentum_jump_multiplier = new_momentum_multiplier


func restore_default_jump() -> void:
	jump_force = base_jump_force
	soft_jump_multiplier = base_soft_jump_multiplier
	base_momentum_jump_multiplier = 0.4
