extends Control

# ─────────────────────────────
# REFERÊNCIAS UI
# ─────────────────────────────
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

@onready var game_over: AudioStreamPlayer = $"../Audio/ASPGamerOverTheme"


@onready var seal_container: HBoxContainer = $Panel/SealContainer

# ─────────────────────────────
# ESTADO
# ─────────────────────────────
var final_score: int = 0
var calculo_finalizado: bool = false


# ─────────────────────────────
# CICLO DE VIDA
# ─────────────────────────────
func _ready():
	if GameManager.screen_fade:
		GameManager.screen_fade.fade_out(0.6)

	game_over_play()

	# Dados base
	var altura: int = ScoreManager.altura
	var itens: int = ScoreManager.itens
	ScoreManager.tempo = GameManager.tempo_partida
	var tempo: float = ScoreManager.tempo

	# Estatísticas brutas
	lbl_altura.text = "Altura Máx: %d m" % altura
	lbl_itens.text = "Itens Coletados: %d" % itens
	lbl_tempo.text = _formatar_tempo(tempo)

	lbl_feedback.text = get_feedback(altura, tempo, itens)

	# Cálculos
	var pontos_altura: float = altura * 1.2
	var pontos_coleta: int = itens * 70
	var bonus_ef: float = (altura / max(tempo, 1)) * 45
	var penalidade: float = tempo * 1.0

	final_score = int(pontos_altura + pontos_coleta + bonus_ef - penalidade)

	# Limpa UI antes da animação
	_reset_labels_calculo()

	# Pausa dramática
	await get_tree().create_timer(0.4).timeout

	# Animações em sequência
	await animate_label_number(lbl_calc_altura, 0, int(pontos_altura), 0.5, "Altura: +")
	await animate_label_number(lbl_calc_coleta, 0, pontos_coleta, 0.5, "Coleta: +")
	await animate_label_number(lbl_calc_ef, 0, int(bonus_ef), 0.5, "Eficiência: +")
	await animate_label_number(lbl_calc_tempo, 0, int(penalidade), 0.4, "Tempo: -")

	await get_tree().create_timer(0.2).timeout
	await animate_label_number(lbl_final_score, 0, final_score, 0.8)


	await get_tree().create_timer(0.3).timeout
	await mostrar_selos_ganhos()

	calculo_finalizado = true
	_mostrar_formulario_recorde()

	# Estado global
	var gm = get_tree().get_first_node_in_group("GameManager")
	if gm:
		gm.state = GameManager.GameState.GAME_OVER


# ─────────────────────────────
# UI / ANIMAÇÃO
# ─────────────────────────────
func _reset_labels_calculo():
	lbl_final_score.text = "0"
	lbl_calc_altura.text = "Altura: +0"
	lbl_calc_coleta.text = "Coleta: +0"
	lbl_calc_ef.text = "Eficiência: +0"
	lbl_calc_tempo.text = "Tempo: -0"

	lbl_novo.visible = false
	input_nome.visible = false
	btn_salvar.visible = false


func animate_label_number(
	label: Label,
	from: int,
	to: int,
	duration := 0.6,
	prefix := "",
	suffix := ""
) -> void:
	label.text = "%s%d%s" % [prefix, from, suffix]

	var tween := create_tween()
	tween.tween_method(
		func(value):
			label.text = "%s%d%s" % [prefix, int(value), suffix],
		from,
		to,
		duration
	)
	await tween.finished


# ─────────────────────────────
# RECORDE
# ─────────────────────────────
func _mostrar_formulario_recorde():
	if not calculo_finalizado:
		return

	if SaveManager.is_new_record(final_score):
		lbl_novo.visible = true
		input_nome.visible = true
		btn_salvar.visible = true

		if OS.has_feature("mobile") or OS.has_feature("web_android") or OS.has_feature("web_ios"):
			input_nome.grab_focus()
	else:
		lbl_novo.visible = false
		input_nome.visible = false
		btn_salvar.visible = false


func _on_button_salvar_pressed() -> void:
	var nome := input_nome.text.strip_edges()
	if nome.is_empty():
		nome = "Jogador"

	SaveManager.add_record(nome, final_score)

	input_nome.visible = false
	btn_salvar.visible = false
	lbl_novo.text = "RECORDE SALVO!"


# ─────────────────────────────
# BOTÕES
# ─────────────────────────────
func _on_button_novo_game_pressed() -> void:
	GameManager._restart_from_game_over()


func _on_button_sair_pressed() -> void:
	clear_instance()
	get_tree().change_scene_to_file("res://scenes/system/loby_01.tscn")


# ─────────────────────────────
# INPUT
# ─────────────────────────────
func _unhandled_input(event):
	if event.is_action_pressed("ui_start"):
		var gm = get_tree().get_first_node_in_group("GameManager")
		if gm:
			gm.start_game()


func _on_line_edit_nome_gui_input(event):
	if (event is InputEventScreenTouch and event.pressed) \
	or (event is InputEventMouseButton and event.pressed):
		input_nome.grab_focus()


# ─────────────────────────────
# UTILIDADES
# ─────────────────────────────
func _formatar_tempo(tempo: float) -> String:
	var t := int(tempo)
	var min := t / 60
	var sec := t % 60
	return "Tempo: %02d:%02d" % [min, sec]


func get_feedback(altura: int, tempo: float, itens: int) -> String:
	if altura <= 200 and itens <= 2:
		return "[FRACO]\nTente subir mais e coletar itens!"

	if altura <= 0 and itens <= 0:
		return "[DERROTA]\nNão desista, tente novamente!"

	if altura > 1800 and tempo < 70:
		return "[EXCELENTE]\nRitmo excelente!"

	if itens > 20 and tempo > 200:
		return "[ATENÇÃO]\nBoa coleta, mas demorou demais"

	if tempo < 60 and altura > 800:
		return "[RÁPIDO]\nSpeedrunner nato!"

	return "[OK]\nBoa tentativa!"


func game_over_play():
	game_over.play()


func clear_instance():
	ScoreManager.altura = 0
	ScoreManager.itens = 0
	ScoreManager.tempo = 0.0
	Global.lives = 3



func mostrar_selos_ganhos():
	if Global.boss_seals_gained.is_empty():
		return

	for seal_id in Global.boss_seals_gained:
		if not Global.SEAL_ICONS.has(seal_id):
			continue

		var icon := TextureRect.new()
		icon.texture = Global.SEAL_ICONS[seal_id]
		icon.custom_minimum_size = Vector2(64, 64)
		icon.expand = true
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.modulate.a = 0.0
		icon.scale = Vector2.ONE * 0.3

		seal_container.add_child(icon)

		await _animar_selo(icon)
		await get_tree().create_timer(0.25).timeout


func _animar_selo(icon: TextureRect) -> void:
	var tween := create_tween()
	tween.set_parallel(true)

	tween.tween_property(icon, "modulate:a", 1.0, 0.3)
	tween.tween_property(icon, "scale", Vector2.ONE, 0.4)\
		.set_trans(Tween.TRANS_BACK)\
		.set_ease(Tween.EASE_OUT)

	await tween.finished
