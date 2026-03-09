extends CharacterBody2D

# =====================================================
# ENUM
# =====================================================

enum State { IDLE, RUN, AIR, HIT, DEATH }

var state: State = State.IDLE

# =====================================================
# CONFIG
# =====================================================

@export var move_speed := 160.0
@export var max_speed := 250.0
@export var acceleration := 900.0
@export var deceleration := 1400.0
@export var air_control := 0.6

@export var jump_force := -600.0
@export var soft_jump_factor := 0.55

# Momentum
@export var max_momentum := 500.0
@export var momentum_gain := 450.0
@export var momentum_decay := 80.0
@export var momentum_jump_multiplier := 0.4
@export var momentum_speed_multiplier := 0.15

#sistema de gravidade
@export var fall_gravity_multiplier := 1.3
@export var low_jump_multiplier := 1.8

#sistema do coyoute time
@export var coyote_time := 0.12
var coyote_timer := 0.0

#jump bufer
@export var jump_buffer_time := 0.12
var jump_buffer_timer := 0.0

#controle de momentum
var was_on_floor := false

#ajuste no sistema de jump
var buffered_jump_is_soft := false

#sistema de ui de jump
@onready var jump_ui: Node2D = $JumpPouwerUi
@onready var jump_fill: ColorRect = $JumpPouwerUi/Fill

@export var jump_ui_height := 12.0
@export var jump_ui_fade_speed := 20.0
@export var ice_accel_multiplier := 0.55
@export var ice_decel_multiplier := 0.12

#save plataform
var last_safe_position : Vector2 = Vector2.ZERO
# ===============================
# VIDA / STATUS
# ===============================

@export var base_max_health := 100
@export var base_damage := 10

var max_health : int
var current_health : int

signal health_changed
signal morreu

# =====================================================
# RUNTIME
# =====================================================

var input_dir := 0.0
var momentum := 0.0
var can_control := true
var on_ice := false

# =====================================================
# READY
# =====================================================

func _ready():
	update_stats_from_level()
	current_health = max_health
	_sync_global_health(true)
	emit_signal("health_changed")
	change_state(State.IDLE)
	#jump ui
	jump_ui.position = Vector2(9, -7)

# =====================================================
# PHYSICS LOOP
# =====================================================

func _physics_process(delta):

	if not can_control:
		velocity = Vector2.ZERO
		move_and_slide()
		return

	read_input()
	apply_gravity(delta)
	update_momentum(delta)
	apply_horizontal_movement(delta)

	move_and_slide()
	GameManager.update_autura(global_position.y)

	# 👇 AGORA a física está correta
	update_coyote(delta)
	update_jump_buffer(delta)
	update_state()

	handle_landing()
	update_jump_ui()



#estado simplificado
func update_state():

	if state == State.HIT or state == State.DEATH:
		return

	if not is_on_floor():
		if state != State.AIR:
			change_state(State.AIR)
		else:
			update_air_animation()
		return

	if abs(velocity.x) > 10:
		change_state(State.RUN)
	else:
		change_state(State.IDLE)

#troca de estado unificada
func change_state(new_state: State):
	if state == new_state:
		return
	
	state = new_state
	
	match state:
		State.IDLE:
			$Skin.play("idle")
		State.RUN:
			$Skin.play("run")
		State.AIR:
			if velocity.y < 0:
				$Skin.play("jump")
			else:
				$Skin.play("fall")
		State.HIT:
			$Skin.play("hit")
		State.DEATH:
			if $Skin.sprite_frames and $Skin.sprite_frames.has_animation("death"):
				$Skin.play("death")
			elif $Skin.sprite_frames and $Skin.sprite_frames.has_animation("hit"):
				$Skin.play("hit")
			else:
				$Skin.play("fall")

#input unificado
func read_input():
	input_dir = Input.get_axis("move_left", "move_right")

	if Input.is_action_just_pressed("jump"):
		jump_buffer_timer = jump_buffer_time
		buffered_jump_is_soft = false

	if Input.is_action_just_pressed("jump_soft"):
		jump_buffer_timer = jump_buffer_time
		buffered_jump_is_soft = true


#jump unificado
func do_jump(is_soft: bool):

	if coyote_timer <= 0:
		return

	var jump_strength = jump_force
	
	if is_soft:
		jump_strength *= soft_jump_factor
	
	var extra_force = momentum * momentum_jump_multiplier
	velocity.y = jump_strength - extra_force
	
	coyote_timer = 0
	change_state(State.AIR)

	# 🔊 TOCA SOM AQUI — somente quando o pulo é válido
	var sfx = $Souds/ASPShortJump

	if sfx.playing:
		sfx.stop()

	sfx.play()



#movimento horisontal limpo
func apply_horizontal_movement(delta):

	var target_speed = input_dir * move_speed
	
	# Momentum influencia velocidade final
	target_speed += input_dir * momentum * momentum_speed_multiplier
	target_speed = clamp(target_speed, -max_speed, max_speed)

	var accel = acceleration if input_dir != 0 else deceleration
	if on_ice:
		if input_dir != 0:
			accel *= ice_accel_multiplier
		else:
			accel *= ice_decel_multiplier

	if not is_on_floor():
		accel *= air_control

	velocity.x = move_toward(velocity.x, target_speed, accel * delta)

	# Flip visual
	if input_dir != 0:
		$Skin.flip_h = input_dir < 0

#sistema de momentum isolado
func update_momentum(delta):

	if not is_on_floor():
		momentum = max(momentum - momentum_decay * delta, 0)
		return

	if abs(velocity.x) > 20 and input_dir != 0:
		momentum += momentum_gain * delta
	else:
		momentum -= momentum_decay * delta

	momentum = clamp(momentum, 0, max_momentum)



#função de gravidade
func apply_gravity(delta):

	if is_on_floor() and velocity.y >= 0:
		velocity.y = 0
		return

	var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

	if velocity.y < 0:
		if not Input.is_action_pressed("jump"):
			velocity.y += gravity * low_jump_multiplier * delta
		else:
			velocity.y += gravity * delta
	else:
		velocity.y += gravity * fall_gravity_multiplier * delta



#função do coyote
func update_coyote(delta):
	if is_on_floor():
		coyote_timer = coyote_time
	else:
		coyote_timer -= delta

#funçao do jump buffer
func update_jump_buffer(delta):
	jump_buffer_timer -= delta

	if jump_buffer_timer > 0 and coyote_timer > 0:
		do_jump(buffered_jump_is_soft)
		jump_buffer_timer = 0

#reset do momentum
func on_landed():
	# opção A – reset total
	# momentum = 0
	
	# opção B – reduz parcialmente (mais interessante)
	momentum *= 0.5

#atualizando as transiçoes
func update_air_animation():
	if velocity.y < 0:
		if $Skin.animation != "jump":
			$Skin.play("jump")
	else:
		if $Skin.animation != "fall":
			$Skin.play("fall")

#Funçao de organização
func handle_landing():
	var just_landed = not was_on_floor and is_on_floor()

	if just_landed:
		on_landed()
		register_safe_position()

	was_on_floor = is_on_floor()
	

#jump ui
func update_jump_ui():

	var ratio := momentum / max_momentum
	ratio = clamp(ratio, 0.0, 1.0)

	# Atualiza altura da barra
	jump_fill.size.y = jump_ui_height * ratio
	jump_fill.position.y = jump_ui_height - jump_fill.size.y

	# Mostrar só no chão e com momentum relevante
	var should_show := is_on_floor() and ratio >= 0.5

	var target_alpha := 1.0 if should_show else 0.0

	jump_ui.modulate.a = lerp(
		jump_ui.modulate.a,
		target_alpha,
		jump_ui_fade_speed * get_physics_process_delta_time()
	)

#Escalonamento por Level (melhorado)
func update_stats_from_level():

	var previous_max_health := max_health
	var level_mult := Global.get_level_multiplier()

	max_health = int(base_max_health * level_mult)
	max_health = min(max_health, Global.MAX_ACCUMULATED_LIVES)

	# mantém proporção atual
	if current_health > 0:
		var health_base := previous_max_health if previous_max_health > 0 else max_health
		var ratio := float(current_health) / float(health_base)
		current_health = int(max_health * ratio)
	else:
		current_health = max_health

	_sync_global_health()
	emit_signal("health_changed")


func _sync_global_health(force_emit_lives_changed: bool = false):
	Global.lives_limit = max_health
	Global.lives = clamp(current_health, 0, max_health)

	if force_emit_lives_changed:
		ScoreManager.emit_signal("lives_changed")

#sistema de dano
func take_hit(damage: int = 20, knockback_dir: float = 0.0):

	if state == State.HIT or state == State.DEATH:
		return

	current_health -= damage
	current_health = clamp(current_health, 0, max_health)

	_sync_global_health(true)
	emit_signal("health_changed")

	if is_zero_approx(knockback_dir):
		knockback_dir = -1.0 if $Skin.flip_h else 1.0

	apply_knockback(knockback_dir)

	change_state(State.HIT)

	if current_health <= 0:
		die()
	else:
		await get_tree().create_timer(0.25).timeout
		change_state(State.IDLE)

#knockback melhorado
func apply_knockback(dir: float):

	if not is_on_floor():
		return

	velocity.x = dir * 220
	velocity.y = -450

#função morreu
func die():
	change_state(State.DEATH)
	can_control = false
	emit_signal("morreu")

#sistema de lock unlock de controle	
func lock_control():
	can_control = false
	velocity = Vector2.ZERO

func unlock_control():
	can_control = true


func enter_ice(accel_mult: float, decel_mult: float):
	on_ice = true
	ice_accel_multiplier = accel_mult
	ice_decel_multiplier = decel_mult


func exit_ice():
	on_ice = false
	ice_accel_multiplier = 0.55
	ice_decel_multiplier = 0.12

#registrando safe position
func register_safe_position():
	if is_on_floor():
		last_safe_position = global_position

#função de respawn
func respawn():

	if last_safe_position == Vector2.ZERO:
		return

	lock_control()

	global_position = last_safe_position + Vector2(0, -40)
	velocity = Vector2.ZERO

	change_state(State.HIT)

	await get_tree().create_timer(0.25).timeout

	unlock_control()
	change_state(State.IDLE)

#funçao de dependencia do plataform spawner
func get_max_jump_height() -> float:

	var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

	# altura máxima considerando jump normal (botão segurado)
	var jump_velocity = abs(jump_force)

	# fórmula física:
	# h = v² / (2g)
	var height = (jump_velocity * jump_velocity) / (2.0 * gravity)

	return height

func get_max_jump_distance() -> float:

	var jump_time = get_jump_time()
	var max_speed_possible = max_speed

	return max_speed_possible * jump_time
	
func get_jump_time() -> float:

	var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")
	var jump_velocity = abs(jump_force)

	# tempo até o pico
	return jump_velocity / gravity

func take_fall_damage(damage: int):

	if state == State.DEATH:
		return

	current_health -= damage
	current_health = clamp(current_health, 0, max_health)

	_sync_global_health(true)
	emit_signal("health_changed")

	if current_health <= 0:
		die()
		return

	respawn()


func heal(amount: int):
	if state == State.DEATH:
		return

	if amount <= 0:
		return

	current_health = clamp(current_health + amount, 0, max_health)
	_sync_global_health(true)
	emit_signal("health_changed")
