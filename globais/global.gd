#Global - Updated 12-01-26
extends Node

# ─────────── VARIAVEIS LOCAIS ───────────

#----CONFIG PLAYER
var lives: int = 3  #quantidade inicial de vidas
var vives_limit: int = 5 #limite maximo de vidas #inplementar

#----LOOTs
var coin_value: int = 1 #moeda
var gem_value: int = 100 #gemas
var life_value: int = 50 #vida - Inplementar

# ─────────── Configurações das Plataformas ───────────
const visibility = 400

# ─────────── Configurações dos Spawns ───────────
# -------- COINS --------
@export var max_coins: int = 5
@export var coin_spawn_chance: float = 0.5
@export var coin_spacing: int = 16

# -------- GEM --------
@export var gem_spawn_chance: float = 0.08  # 8%
@export var special_height_offset: int = -32

# -------- LIFE --------
@export var life_spawn_chance: float = 0.07 # 8%
@export var life_height_offset: int = -32

# ======================================================
# VISIBILIDADE / LIMPEZA
# ======================================================
#const VISIBILITY: int = 1200

# ======================================================
# MOEDAS
# ======================================================
const MAX_COINS: int = 5
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
		"chance": 0.1
	},
	{
		"id": "life",
		"type": "life",
		"scene": preload("res://scenes/coletaveis/life.tscn"),
		"chance": 0.05
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



#----SISTEMA


# ─────────── SINAIS ───────────



# ─────────── 00 ───────────
# ─────────── 00 ───────────
# ─────────── 00 ───────────
# ─────────── 00 ───────────
# ─────────── 00 ───────────
