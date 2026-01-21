extends CanvasLayer

@onready var icon_cog: Sprite2D = $TouchRoot/TopControl/IconCog
@onready var icon_button_r: Sprite2D = $TouchRoot/LeftControl/IconButtonR
@onready var icon_button_l: Sprite2D = $TouchRoot/LeftControl/IconButtonL
@onready var icon_jump: Sprite2D = $TouchRoot/RightControl/IconJump
@onready var icon_jump_2: Sprite2D = $TouchRoot/RightControl/IconJump2
@onready var icon_fire: Sprite2D = $TouchRoot/RightControl/IconFire


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	#escondendo os labels, os botões são ocultos na propriedade visibility mode = tochscreen
	if OS.has_feature("mobile") or OS.has_feature("web_android") or OS.has_feature("web_ios"):
		icon_cog.visible = true
		icon_button_l.visible = true
		icon_button_r.visible = true
		icon_jump.visible = true
		icon_jump_2.visible = false
		icon_fire.visible = false



func _on_tsb_menu_pressed() -> void:
	GameManager.request_pause()



func _on_tsb_left_pressed() -> void:
	Input.action_release("move_left")


func _on_tsb_left_released() -> void:
	Input.action_release("move_left")


func _on_tsb_right_pressed() -> void:
	Input.action_press("move_right")


func _on_tsb_right_released() -> void:
	Input.action_press("move_right")


func _on_tsb_jump_pressed() -> void:
	Input.action_press("jump")


func _on_tsb_jump_released() -> void:
	Input.action_press("jump")


func _on_tsb_soft_jump_pressed() -> void:
	Input.action_press("jump_soft")


func _on_tsb_soft_jump_released() -> void:
	Input.action_press("jump_soft")


func _on_tsb_power_pressed() -> void:
	Input.action_press("power_up")


func _on_tsb_power_released() -> void:
	pass # Replace with function body.
