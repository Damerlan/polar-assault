extends Control
class_name  VirtualKeyboard

@export var target_input: LineEdit
@export var max_chars := 12


func _ready() -> void:
	GameManager.show_teclado.connect(show)
	
	if OS.has_feature("mobile") or OS.has_feature("web_android") or OS.has_feature("web_ios"):
		return
	hide()

func show_keyboard(input: LineEdit):
	target_input = input
	show()

func hide_keyboard():
	hide()

func _on_key_pressed(_char: String):
	if not target_input:
		return
	if target_input.text.length() < max_chars:
		target_input.text += _char

func _on_backspace():
	if not target_input:
		return
	if target_input.text.length() > 0:
		target_input.text = target_input.text.substr(0, target_input.text.length() - 1)

func _on_confirm():
	hide_keyboard()


#Teclas
func _on_a_pressed() -> void:
	_on_key_pressed("A")


func _on_b_pressed() -> void:
	_on_key_pressed("B")


func _on_c_pressed() -> void:
	_on_key_pressed("C")


func _on_d_pressed() -> void:
	_on_key_pressed("D")


func _on_e_pressed() -> void:
	_on_key_pressed("E")


func _on_f_pressed() -> void:
	_on_key_pressed("F")


func _on_g_pressed() -> void:
	_on_key_pressed("G")


func _on_h_pressed() -> void:
	_on_key_pressed("H")


func _on_i_pressed() -> void:
	_on_key_pressed("I")


func _on_j_pressed() -> void:
	_on_key_pressed("J")


func _on_k_pressed() -> void:
	_on_key_pressed("K")


func _on_l_pressed() -> void:
	_on_key_pressed("L")


func _on_m_pressed() -> void:
	_on_key_pressed("M")


func _on_n_pressed() -> void:
	_on_key_pressed("N")


func _on_o_pressed() -> void:
	_on_key_pressed("O")


func _on_p_pressed() -> void:
	_on_key_pressed("P")


func _on_q_pressed() -> void:
	_on_key_pressed("Q")


func _on_r_pressed() -> void:
	_on_key_pressed("R")


func _on_s_pressed() -> void:
	_on_key_pressed("S")


func _on_t_pressed() -> void:
	_on_key_pressed("T")


func _on_u_pressed() -> void:
	_on_key_pressed("U")


func _on_v_pressed() -> void:
	_on_key_pressed("V")


func _on_x_pressed() -> void:
	_on_key_pressed("X")


func _on_w_pressed() -> void:
	_on_key_pressed("W")


func _on_z_pressed() -> void:
	_on_key_pressed("Z")


func _on_del_pressed() -> void:
	_on_backspace()


func _on_ok_pressed() -> void:
	_on_confirm()


func _on_1_pressed() -> void:
	_on_key_pressed("1")


func _on_2_pressed() -> void:
	_on_key_pressed("2")


func _on_3_pressed() -> void:
	_on_key_pressed("3")


func _on_4_pressed() -> void:
	_on_key_pressed("4")


func _on_5_pressed() -> void:
	_on_key_pressed("5")


func _on_6_pressed() -> void:
	_on_key_pressed("6")


func _on_7_pressed() -> void:
	_on_key_pressed("7")


func _on_8_pressed() -> void:
	_on_key_pressed("8")


func _on_9_pressed() -> void:
	_on_key_pressed("9")


func _on_0_pressed() -> void:
	_on_key_pressed("0")


func _on_y_pressed() -> void:
	_on_key_pressed("Y")


func _on_bar_pressed() -> void:
	_on_key_pressed("-")
