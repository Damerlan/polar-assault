#ScoreManager - Updated 12-01-26
extends Node

# ─────────── PONTUAÇÃO PARTIDA Estatisticas ───────────
var altura := 0
var itens := 0
var tempo := 0.0

# ─────────── PONTUAÇÃO PARTIDA ───────────
var total_boss_death: int = 0 #inplementar


const PESO_SUBIDA = 1.2
const PONTOS_ITEM = 70
const PESO_TEMPO = 1.0
const PESO_EFICIENCIA = 45

signal collect_coin(value)
signal lives_changed
signal morreu

func add_coin(value: int):
	itens += value
	emit_signal("collect_coin")


func add_life(): #add +1 vida
	Global.lives += 1
	itens += Global.life_value #adiciona a pontuação de vida ao score
	emit_signal("lives_changed")


func remove_life():
	Global.lives -= 1
	emit_signal("lives_changed")

	if Global.lives <= 0:
		Global.lives = 0
		emit_signal("morreu")


func get_score() -> int:
	var pontos_subida = altura * PESO_SUBIDA
	var pontos_coleta = itens * PONTOS_ITEM
	var bonus_ef = (altura / max(tempo, 1)) * PESO_EFICIENCIA
	var penalidade = tempo * PESO_TEMPO
	
	return int(pontos_subida + pontos_coleta + bonus_ef - penalidade)

func get_gem_chance_by_height(height): #REVIZAR
	if height < 800:
		return 0.02
	elif height < 2000:
		return 0.05
	else:
		return 0.08
