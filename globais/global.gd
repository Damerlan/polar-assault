#Global - Updated 12-01-26
extends Node

# ─────────── VARIAVEIS LOCAIS ───────────
var saved_run_time: float = 0.0


#----CONFIG PLAYER
var lives: int = 20  #quantidade inicial de vidas
var lives_limit: int = 100 #limite maximo de vidas #inplementar



#----LOOTs
var coin_value: int = 1 #moeda
var gem_value: int = 100 #gemas
#var life_value: int = 50 #vida - Inplementar

# -------- KEY / BOSS --------

# ---- PROGRESSÃO DO PLAYER ----
var player_xp: int = 0
var player_level: int = 1

#const XP_PER_LEVEL := 100
signal xp_changed

# ======================================================
# SISTEMA DE SELOS (PROGRESSÃO GLOBAL)
# ======================================================

var unlocked_seals: Dictionary = {}

# ─────────── Configurações das Plataformas ───────────
const visibility = 400

# ─────────── Configurações dos Spawns ───────────
# -------- COINS --------
#@export var max_coins: int = 5
@export var coin_spawn_chance: float = 0.5
@export var coin_spacing: int = 16

# -------- GEM --------
@export var gem_spawn_chance: float = 0.88  # 8%
@export var special_height_offset: int = -32

# -------- LIFE --------
@export var life_spawn_chance: float = 0.77 # 8%
@export var life_height_offset: int = -32

# Global.gd
var coming_from_boss := false

signal level_up

var boss_seals_gained: Array[String] = []
# ======================================================
# VISIBILIDADE / LIMPEZA
# ======================================================
#const VISIBILITY: int = 1200

# ======================================================
# MOEDAS
# ======================================================
const MAX_COINS: int = 4
const COIN_SPAWN_CHANCE: float = 0.75
const COIN_SPACING: int = 24

const COIN_VARIANTS: Array[Dictionary] = [
	{
		"id": "copper",
		"scene": preload("res://scenes/coletaveis/coin_coper.tscn"),
		"chance": 0.6,
		"value": 1
	},
	{
		"id": "silver",
		"scene": preload("res://scenes/coletaveis/coin_silver.tscn"),
		"chance": 0.3,
		"value": 3
	},
	{
		"id": "gold",
		"scene": preload("res://scenes/coletaveis/coin_gold.tscn"),
		"chance": 0.1,
		"value": 5
	}
]

# ======================================================
# ESPECIAIS (JOIAS, VIDA, PODERES FUTUROS)
# ======================================================
const BASE_SPECIAL_CHANCE: float = 0.08
const MAX_SPECIAL_CHANCE: float = 0.35
const HEIGHT_FOR_MAX_SPECIAL: float = 6000.0
const SPECIAL_HEIGHT_OFFSET: int = -24

const SPECIAL_VARIANTS: Array[Dictionary] = [
	{
		"id": "gem_ruby",
		"type": "gem",
		"scene": preload("res://scenes/coletaveis/gem_ruby.tscn"),
		"chance": 0.45
	},
	{
		"id": "gem_emerald",
		"type": "gem",
		"scene": preload("res://scenes/coletaveis/gem_emerald.tscn"),
		"chance": 0.25
	},
	{
		"id": "gem_diamond",
		"type": "gem",
		"scene": preload("res://scenes/coletaveis/gem_diamond.tscn"),
		"chance": 0.10
	},
	{
		"id": "life",
		"type": "life",
		"scene": preload("res://scenes/coletaveis/life.tscn"),
		"chance": 0.5
	},
	{
		"id": "bosskey",
		"type": "key",
		"scene": preload("res://scenes/coletaveis/key_boss_room_base.tscn"),
		"chance": 1.05
	}
]

# ======================================================
# UTILITÁRIO — ESCOLHA DE VARIANTE POR PESO
# ======================================================
func pick_variant(variants: Array[Dictionary]) -> Dictionary:
	var total := 0.0
	for v in variants:
		total += v["chance"]

	if total <= 0.0:
		return variants[0]

	var roll := randf() * total
	var acc := 0.0

	for v in variants:
		acc += v["chance"]
		if roll <= acc:
			return v

	return variants[0] # fallback seguro



#----SISTEMA de XP

func add_xpOld(value: int):
	player_xp += value
	print("XP atual:", player_xp)
	
	while player_xp >= get_xp_to_next_level(player_level):
		player_xp -= get_xp_to_next_level(player_level)
		player_level += 1
		print("SUBIU PARA LEVEL", player_level)
		_on_level_up()

func add_xp(value: int):
	player_xp += value
	emit_signal("xp_changed")
	print("XP atual:", player_xp)
	
	while player_xp >= get_xp_to_next_level(player_level):
		player_xp -= get_xp_to_next_level(player_level)
		player_level += 1
		print("SUBIU PARA LEVEL", player_level)
		_on_level_up()
	

func _on_level_up():
	print("LEVEL UP:", player_level)
	emit_signal("level_up")
	
func get_level_multiplier() -> float:
	return 1.0 + (player_level - 1) * 0.08
	
	
# XP necessária para subir de nível
func get_xp_to_next_level(level: int) -> int:
	return int(100 * pow(level, 1.4))




func unlock_seal(seal_id: String) -> void:
	if seal_id.is_empty():
		return

	if unlocked_seals.has(seal_id):
		return # já desbloqueado

	unlocked_seals[seal_id] = true
	print("🔓 Selo desbloqueado:", seal_id)


func has_seal(seal_id: String) -> bool:
	return unlocked_seals.has(seal_id)


# ─────────── SINAIS ───────────
# Global.gd
const SEAL_ICONS := {
	"pirata_derrotado": preload("res://Assets/seals/seal_pirata.png"),
	"capitao_derrotado": preload("res://Assets/seals/seal_capitao.png"),
	"kraken_derrotado": preload("res://Assets/seals/seal_kraken.png")
}


# ─────────── 00 ───────────
# ─────────── 00 ───────────
# ─────────── 00 ───────────
# ─────────── 00 ───────────
# ─────────── 00 ───────────
