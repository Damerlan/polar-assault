extends Node2D

@export var ranking_font: FontFile
@export var font_score: FontFile
@export var font_nome: FontFile
@export var font_posicao: FontFile
#font_score)font_nome)font_posicao
#enum GameState {
#	LOBBY,
#	PLAYING,
#	RANKING,
#	GAME_OVER
#	}
	
@onready var vbox_ranking: VBoxContainer = $Ranking/Panel/BoxContainer/VBoxContainer/VBoxRanking
@onready var ui_efect: AudioStreamPlayer = $Audio/ASPUiEfect


func _ready() -> void:
	var gm = get_tree().get_first_node_in_group("GameManager")
	if gm:
		gm.state = GameManager.GameState.RANKING
	update_ranking()


func update_rankingOLD():
	for child in vbox_ranking.get_children():
		child.queue_free()

	var pos := 1
	for entry in SaveManager.ranking:
		var lbl = Label.new()
		lbl.text = "%dº  %s  -  %d" % [pos, entry.nome, entry.score]
		lbl.add_theme_font_override("font", ranking_font)
		lbl.add_theme_font_size_override("font_size", 10)
		vbox_ranking.add_child(lbl)
		pos += 1


func update_ranking():
	for child in vbox_ranking.get_children():
		child.queue_free()

	var pos := 1

	for entry in SaveManager.ranking:
		var cor_posicao = Color(0.212, 0.576, 0.846, 1.0)
		var cor_nome = Color(0.90, 0.93, 0.96)
		var cor_score = Color(0.212, 0.576, 0.846, 1.0)

		var row = HBoxContainer.new()
		row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_theme_constant_override("separation", 8)

		# ───── POSIÇÃO ─────
		var lbl_pos = Label.new()
		lbl_pos.text = "%dº" % pos
		lbl_pos.add_theme_font_override("font", font_posicao)
		lbl_pos.add_theme_font_size_override("font_size", 12)
		lbl_pos.add_theme_color_override("font_color", cor_posicao)
		#lbl_pos.add_theme_color_override("font_color", Color.GOLD)

		# ───── NOME ─────
		var lbl_nome = Label.new()
		lbl_nome.text = entry.nome
		lbl_nome.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		lbl_nome.add_theme_font_override("font", font_nome)
		lbl_nome.add_theme_font_size_override("font_size", 12)
		lbl_nome.add_theme_color_override("font_color", cor_nome)
		#lbl_nome.add_theme_color_override("font_color", Color.WHITE)

		# ───── SCORE ─────
		var lbl_score = Label.new()
		lbl_score.text = str(int(entry.score))
		lbl_score.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		lbl_score.add_theme_font_override("font", font_score)
		lbl_score.add_theme_font_size_override("font_size", 14)
		lbl_score.add_theme_color_override("font_color", cor_score)
		#lbl_score.add_theme_color_override("font_color", Color.AQUA)
		
		


		
		if pos == 1:
			lbl_nome.add_theme_color_override("font_color", Color(1.0, 0.253, 0.419, 1.0))
			lbl_score.add_theme_color_override("font_color", Color(0.816, 0.68, 0.143, 1.0))
			#lbl_nome.add_theme_color_override("font_color", Color.YELLOW)
			#lbl_score.add_theme_color_override("font_color", Color.ORANGE)
			lbl_nome.add_theme_font_size_override("font_size", 12)

		row.add_child(lbl_pos)
		row.add_child(lbl_nome)
		row.add_child(lbl_score)

		vbox_ranking.add_child(row)
		pos += 1

func _on_btn_return_pressed() -> void:
	ui_efx()
	get_tree().change_scene_to_file("res://scenes/system/loby_01.tscn")


func ui_efx():
	ui_efect.play()
