extends CanvasLayer

signal fade_finished

@onready var rect: ColorRect = $FadeRect
var tween: Tween

func _ready():
	rect.modulate.a = 0.0
	hide()

func fade_in(duration := 0.6) -> void:
	show()
	_kill_tween()

	tween = create_tween()
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_IN)

	tween.tween_property(
		rect,
		"modulate:a",
		1.0,
		duration
	)

	await tween.finished
	emit_signal("fade_finished")

func fade_out(duration := 0.6) -> void:
	show()
	_kill_tween()

	tween = create_tween()
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_OUT)

	tween.tween_property(
		rect,
		"modulate:a",
		0.0,
		duration
	)

	await tween.finished
	hide()
	emit_signal("fade_finished")

func _kill_tween():
	if tween and tween.is_running():
		tween.kill()
