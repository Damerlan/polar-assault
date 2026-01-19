extends Control

@onready var lbl_final_score: Label = $Panel/VBoxContainer/LabelFinalScore
@onready var lbl_altura: Label = $Panel/VBoxContainer/VBoxStats/LabelAltura
@onready var lbl_itens: Label = $Panel/VBoxContainer/VBoxStats/LabelItens
@onready var lbl_tempo: Label = $Panel/VBoxContainer/VBoxStats/LabelTempo
@onready var lbl_calc_altura: Label = $Panel/VBoxContainer/VBoxCalculo/LabelCalcAltura
@onready var lbl_calc_coleta: Label = $Panel/VBoxContainer/VBoxCalculo/LabelCalcColeta
@onready var lbl_calc_ef: Label = $Panel/VBoxContainer/VBoxCalculo/LabelCalcEficiencia
@onready var lbl_calc_tempo: Label = $Panel/VBoxContainer/VBoxCalculo/LabelCalcTempo
@onready var lbl_feedback: Label = $Panel/VBoxContainer/LabelFeedback
@onready var lbl_novo: Label = $Panel/VBoxContainer2/LabelNovoRecord

@onready var input_nome: LineEdit = $Panel/VBoxContainer2/LineEditNome
@onready var btn_salvar: Button = $Panel/VBoxContainer2/ButtonSalvar
@onready var game_over: AudioStreamPlayer = $"../GameOverSound"

#@onready var virtual_keyboard: VirtualKeyboard = $"../VirtualKeyboard"

var final_score := 0

func _ready():
	game_over_play()
	var altura = ScoreManager.altura
	var itens = ScoreManager.itens
	ScoreManager.tempo = GameManager.tempo_partida
	var tempo = ScoreManager.tempo
	
	if OS.has_feature("mobile") or OS.has_feature("web_android") or OS.has_feature("web_ios"):
		input_nome.grab_focus()

	# --- Cálculos ---
	var pontos_altura = altura * 1.2
	var pontos_coleta = itens * 70
	var bonus_ef = (altura / max(tempo, 1)) * 45
	var penalidade = tempo * 1.0

	var total = int(pontos_altura + pontos_coleta + bonus_ef - penalidade)

	# --- Estatísticas brutas ---
	lbl_altura.text = "Altura Máx: %d m" % altura
	lbl_itens.text = "Itens Coletados: %d" % itens
	lbl_tempo.text = "Tempo: %02d:%02d" % [int(tempo) / 60, int(tempo) % 60]

	# --- Quebra do cálculo ---
	lbl_calc_altura.text = "Altura: +%d" % pontos_altura
	lbl_calc_coleta.text = "Coleta: +%d" % pontos_coleta
	lbl_calc_ef.text = "Eficiência: +%d" % bonus_ef
	lbl_calc_tempo.text = "Tempo: -%d" % penalidade

	# --- Score final ---
	lbl_final_score.text = str(total)

	# --- Feedback ---
	lbl_feedback.text = get_feedback(altura, tempo, itens)

	final_score = total #score calculado antes
	
	if SaveManager.is_new_record(final_score):
		lbl_novo.visible = true
		input_nome.visible = true
		btn_salvar.visible = true
		# 👇 ESSENCIAL para mobile/web
		if OS.has_feature("mobile") or OS.has_feature("web_android") or OS.has_feature("web_ios"):
			input_nome.grab_focus() #foca no line edi
			#virtual_keyboard.show_keyboard(input_nome) #mostra o teclado
	else:
		lbl_novo.visible = false
		input_nome.visible = false
		btn_salvar.visible = false
		
	var gm = get_tree().get_first_node_in_group("GameManager")
	if gm:
		gm.state = GameManager.GameState.GAME_OVER


func get_feedback(altura:int, tempo:float, itens:int) -> String:
	# 🟥 Desempenho muito ruim
	if altura <= 200 and itens <= 2:
		return "[FRACO]\nTente subir mais e coletar itens!"

	# 🟥 Zerou praticamente o placar
	if altura <= 0 and itens <= 0:
		return "[DERROTA]\nNão desista, tente novamente!"

	# 🟦 Excelente
	if altura > 1800 and tempo < 70:
		return "[EXCELENTE]\nRitmo excelente!"

	# 🟩 Bom, mas lento
	if itens > 20 and tempo > 200:
		return "[ATENÇÃO]\nBoa coleta, mas demorou demais"

	# 🟩 Muito rápido
	if tempo < 60 and altura > 800:
		return "[RÁPIDO]\nSpeedrunner nato!"

	# 🟨 Mediano
	return "[OK]\nBoa tentativa!"


func game_over_play():
	game_over.play()


func _on_button_salvar_pressed() -> void:
	var nome = input_nome.text.strip_edges()
	if nome == "":
		nome = "Jogador"

	SaveManager.add_record(nome, final_score)
	#virtual_keyboard.hide_keyboard()#esconde o teclado
	input_nome.visible = false
	btn_salvar.visible = false
	lbl_novo.text = "RECORDE SALVO!"


func _on_button_sair_pressed() -> void:
	clear_instance()
	get_tree().change_scene_to_file("res://scenes/system/loby_01.tscn")


func clear_instance():
	ScoreManager.altura = 0
	ScoreManager.itens = 0
	ScoreManager.tempo = 0.0
	Global.lives = 3
	


func _on_button_novo_game_pressed() -> void:
	GameManager._restart_from_game_over()
	#var next_scene = "loading_screen"
	#get_tree().change_scene_to_file("res://scenes/" + next_scene +".tscn")


func _on_line_edit_nome_gui_input(event):
	if (event is InputEventScreenTouch and event.pressed) \
	or (event is InputEventMouseButton and event.pressed):
		input_nome.grab_focus()


func _on_line_edit_nome_focus_entered() -> void:
	#if OS.has_feature("mobile") or OS.has_feature("web_android") or OS.has_feature("web_ios"):
		#Nglobal.teclado_show()
		#virtual_keyboard.show_keyboard(input_nome)
	pass


func _unhandled_input(event):
	if event.is_action_pressed("ui_start"):
		var gm = get_tree().get_first_node_in_group("GameManager")
		if gm:
			gm.start_game()
