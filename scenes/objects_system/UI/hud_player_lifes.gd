extends CanvasLayer

@onready var hearts_container: HBoxContainer = $Control/HeartsContainer
@onready var heart_tamplate: TextureRect = $Control/HeartsContainer/HeartIcon
var current_hearts := 0
var update_version := 0


func _ready() -> void:
	heart_tamplate.visible = false #o tamplate sempre fica escondido
	heart_tamplate.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	heart_tamplate.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	heart_tamplate.custom_minimum_size = Vector2.ZERO
	hearts_container.add_theme_constant_override("separation", 6)
	
	ScoreManager.lives_changed.connect(update_hearts)
	
	update_hearts()
	

func update_hearts():
	update_version += 1
	var local_version := update_version

	#cada coração representa 20 de vida
	var heart_unit := 20
	var hearts_count := int(ceil(float(Global.lives) / float(heart_unit)))
	hearts_count = max(hearts_count, 0)

	if hearts_count > current_hearts:
		_add_hearts(hearts_count - current_hearts, local_version)
	elif hearts_count < current_hearts:
		_remove_hearts(current_hearts - hearts_count, local_version)

	current_hearts = hearts_count


func _add_hearts(amount: int, local_version: int) -> void:
	for i in range(amount):
		if local_version != update_version:
			return

		var heart := _create_heart_instance()
		heart.modulate.a = 0.0
		heart.scale = Vector2(0.6, 0.6)
		hearts_container.add_child(heart)

		var tween := create_tween()
		tween.set_parallel(true)
		tween.tween_property(heart, "modulate:a", 1.0, 0.15)
		tween.tween_property(heart, "scale", Vector2.ONE, 0.2)


func _remove_hearts(amount: int, local_version: int) -> void:
	for i in range(amount):
		if local_version != update_version:
			return

		var heart := _get_last_heart()
		if heart == null:
			return

		var tween := create_tween()
		tween.set_parallel(true)
		tween.tween_property(heart, "modulate:a", 0.0, 0.12)
		tween.tween_property(heart, "scale", Vector2(0.7, 0.7), 0.12)
		await tween.finished

		if local_version != update_version:
			return
		if is_instance_valid(heart) and not heart.is_queued_for_deletion():
			heart.queue_free()


func _create_heart_instance() -> TextureRect:
	var heart := heart_tamplate.duplicate() as TextureRect
	heart.visible = true
	heart.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	heart.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	heart.custom_minimum_size = Vector2(22, 22)
	return heart


func _get_last_heart() -> TextureRect:
	for i in range(hearts_container.get_child_count() - 1, -1, -1):
		var child := hearts_container.get_child(i)
		if child != heart_tamplate and child is TextureRect:
			return child
	return null
