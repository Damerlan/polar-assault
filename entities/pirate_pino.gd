extends CharacterBody2D

enum State {
	INTRO,
	IDLE,
	CHASE,
	REPOSITION,
	STUN,
	DEAD
}

@export var damage_popup_scene: PackedScene

@export var speed: float = 140.0
@export var push_force: float = 260.0
@export var gravity: float = 900.0
@export var contact_damage := 24

@export var stun_time: float = 0.8

@export var max_life := 1000
@export var life := 1000
@export var head_hit_damage := 50

@export var reposition_time := 0.4
@export var reposition_speed := 90.0

@export var decision_cooldown := 0.5  # tempo entre decisões
var decision_timer := 0.0

@onready var ray_left: RayCast2D = $Detection/LeftEdge
@onready var ray_right: RayCast2D = $Detection/RightEdge
@onready var anim: AnimatedSprite2D = $BossSkin
@onready var dialog_ballom: Marker2D = $Markers/DialogBallom

@onready var hit_efect: AudioStreamPlayer = $HitEfect
@onready var asp_drop_efect: AudioStreamPlayer2D = $Audio/ASPDropEfect
@onready var asp_hit_efect: AudioStreamPlayer2D = $Audio/ASPHitEfect

var state := State.INTRO
var stun_timer: float = 0.0
var player: CharacterBody2D

@export var reposition_cooldown := 0.6
var reposition_cd := 0.0

var reposition_timer := 0.0
var reposition_dir := 0

#avisando a plataforma do empacto
var was_airborne := false
var heavy_landing := false

#sistema de dialogo
@export var dialogue_balloon_scene: PackedScene
var current_balloon: Node2D

#empurrando o player
@export var body_hit_cooldown := 0.2

var can_body_hit := true
var hit_stop_active := false

signal boss_defeated #sinal para quando o boss morre


func _ready() -> void:
	player = get_tree().get_first_node_in_group("Player")
	anim.play("Idle")
	#show_dialogue("Teste de fala")

func _physics_process(delta: float) -> void:
	#stado de introdução
	if state == State.INTRO:
		velocity = Vector2.ZERO
		anim.play("Idle")
		move_and_slide()
		return
	#se moreu
	if state == State.DEAD:
		move_and_slide()
		return
		
	_apply_gravity(delta)#tremor
	
	# Atualiza timer
	decision_timer -= delta
	
	if state == State.CHASE and player:
		var life_ratio := float(life) / float(max(max_life, 1))
		if life_ratio < 0.35:
			speed = 190.0
		elif life_ratio < 0.65:
			speed = 165.0
		else:
			speed = 140.0

		var player_above := player.global_position.y < global_position.y - 12
		var player_falling := player.velocity.y > 0

		if player_above and not player_falling:
			var safe := true

			reposition_dir = sign(global_position.x - player.global_position.x)
			if reposition_dir == 0:
				reposition_dir = -1 if randf() < 0.5 else 1

			if reposition_dir < 0 and not ray_left.is_colliding():
				safe = false
			elif reposition_dir > 0 and not ray_right.is_colliding():
				safe = false

			if safe:
				state = State.REPOSITION
				reposition_timer = reposition_time
			
	match state:
		State.CHASE:
			_chase_player(delta)
			_update_animation()
		State.STUN:
			_update_stun(delta)
		State.REPOSITION:
			_update_reposition(delta)

	# ⚠️ MOVE PRIMEIRO
	move_and_slide()

	# 🛬 AGORA SIM detecta pouso
	if not is_on_floor():
		was_airborne = true

	if is_on_floor() and was_airborne:
		was_airborne = false

		if heavy_landing:
			heavy_landing = false

			var collision := get_last_slide_collision()
			if collision:
				var platform = collision.get_collider()
				if platform and platform.has_method("shake"):
					#print("💥 CHAMANDO SHAKE")
					asp_drop_efect.play()
					platform.shake()
					_camera_impact_shake()

func _apply_gravity(delta):
	if not is_on_floor():
		velocity.y += gravity * delta


func _update_animation() -> void:
	if abs(velocity.x) > 10:
		anim.play("Run")
	else:
		anim.play("Idle")

	# 🔥 SPRITE SEGUE O MOVIMENTO REAL
	anim.flip_h = velocity.x > 0


func _update_reposition(delta):
	reposition_timer -= delta

	# checagem de borda (IGUAL ao chase)
	if reposition_dir < 0 and not ray_left.is_colliding():
		velocity.x = 0
		state = State.CHASE
		return
	if reposition_dir > 0 and not ray_right.is_colliding():
		velocity.x = 0
		state = State.CHASE
		return

	# movimento mais suave
	velocity.x = lerp(
		velocity.x,
		reposition_dir * reposition_speed,
		delta * 4
	)

	if reposition_timer <= 0:
		state = State.CHASE

func show_dialogue(text: String) -> Node2D:
	if current_balloon:
		current_balloon.queue_free()

	current_balloon = dialogue_balloon_scene.instantiate()
	get_tree().current_scene.add_child(current_balloon)

	current_balloon.show_at(dialog_ballom.global_position)
	current_balloon.set_text(text)

	return current_balloon


func _chase_player(_delta):
	if player == null:
		velocity.x = 0
		return

	var dx: float = player.global_position.x - global_position.x

	# zona morta → não vira, não anda
	if abs(dx) < 6.0:
		velocity.x = 0
		return

	var dir: int = sign(dx)

	# proteção contra buracos
	if dir < 0 and not ray_left.is_colliding():
		velocity.x = 0
		return
	if dir > 0 and not ray_right.is_colliding():
		velocity.x = 0
		return

	velocity.x = dir * speed

func clear_dialogue():
	if current_balloon:
		current_balloon.queue_free()
		current_balloon = null

func _update_stun(delta):
	if state == State.DEAD:
		return

	stun_timer -= delta
	velocity.x = lerp(velocity.x, 0.0, delta * 6)

	if stun_timer <= 0:
		state = State.CHASE

#quando o player pula na cabeça do boss
func on_player_jump_on_head(player_hit: CharacterBody2D):
	if state == State.DEAD:
		return
	if state == State.STUN:
		return
	
	# 🔴 CAUSA DANO
	await _hit_stop_frames(player_hit, 3)
	_camera_impact_shake(2.2, 0.10)
	life -= head_hit_damage
	_show_damage(head_hit_damage)
	hit_efect.play()
	print("💀 Boss life:", life)
	asp_hit_efect.play()
	anim.play("Hit")
	
	#entrando em stun
	state = State.STUN
	stun_timer = stun_time
	
	#direção contraria ao player
	var dir = sign(global_position.x - player_hit.global_position.x)
	if dir == 0:
		dir = -1 if randf() < 0.5 else 1
	
	#kinockback no bos
	velocity.x = dir * push_force
	velocity.y = -120
	
	heavy_landing = true   # 💥 ISSO É ESSENCIAL
	
	# 💥 knockback no player
	if player_hit.has_method("unlock_control"):
		player_hit.unlock_control()

	if player_hit.has_method("apply_knockback"):
		player_hit.apply_knockback(-dir)
	else:
		player_hit.velocity.x = -dir * 180
		player_hit.velocity.y = -420
	
	# ☠️ MORTE DO BOSS
	if life <= 0:
		die()


func _show_damage(amount: int):
	if damage_popup_scene == null:
		return

	var popup = damage_popup_scene.instantiate()

	# adiciona no mundo (não como filho do boss)
	get_tree().current_scene.add_child(popup)

	# posição baseada no Marker
	var spawn = $Markers/DamageSpawn.global_position

	# pequeno offset aleatório (vida!)
	spawn.x += randf_range(-6, 6)
	spawn.y += randf_range(-4, 4)

	popup.global_position = spawn
	popup.setup(amount)

func die():
	state = State.DEAD
	velocity = Vector2.ZERO

	anim.play("DeadGround")

	# impacto final
	heavy_landing = true
	velocity.y = -20

	print("☠️ Boss morreu de verdade")
	emit_signal("boss_defeated")
	Global.add_xp(300)
	GameManager.handle_boss_victory()


	await anim.animation_finished
	queue_free()


func _on_heady_body_entered(body: Node2D) -> void:
	if body.is_in_group("Player"):
		on_player_jump_on_head(body)


func _on_body_hit_area_body_entered(body: Node2D) -> void:
	if state == State.DEAD:
		return
	if state == State.STUN:
		return
	if not can_body_hit:
		return
	if not body.is_in_group("Player"):
		return

	_apply_body_knockback(body)
	

func _apply_body_knockback(player_knockback: CharacterBody2D):
	can_body_hit = false

	# direção PARA LONGE do boss
	var dir: int = sign(player_knockback.global_position.x - global_position.x)
	if dir == 0:
		dir = -1 if randf() < 0.5 else 1

	# 💥 contato machuca + knockback no player
	if player_knockback.has_method("take_hit"):
		player_knockback.take_hit(contact_damage, dir)
	else:
		player_knockback.velocity.x = dir * 520
		player_knockback.velocity.y = -180

	_camera_impact_shake(1.6, 0.08)

	# animação de impacto
	# if anim:
	#	anim.play("push")

	# cooldown
	await get_tree().create_timer(body_hit_cooldown).timeout
	can_body_hit = true


func apply_knockback():
	velocity.y = -500
	heavy_landing = true


func _camera_impact_shake(intensity: float = 3.0, duration: float = 0.12) -> void:
	var cam := get_viewport().get_camera_2d()
	if cam == null:
		return

	var original_offset := cam.offset
	cam.offset += Vector2(
		randf_range(-intensity, intensity),
		randf_range(-intensity * 0.7, intensity * 0.7)
	)

	var tween := create_tween()
	tween.tween_property(cam, "offset", original_offset, duration)


func _hit_stop_frames(player_hit: CharacterBody2D, frames: int) -> void:
	if hit_stop_active:
		return

	hit_stop_active = true
	velocity = Vector2.ZERO

	if player_hit:
		player_hit.velocity = Vector2.ZERO
		if player_hit.has_method("lock_control"):
			player_hit.lock_control()

	for i in range(frames):
		await get_tree().process_frame

	hit_stop_active = false
