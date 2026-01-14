#Global - Updated 12-01-26
extends Node

# ─────────── VARIAVEIS LOCAIS ───────────

#----CONFIG PLAYER
var lives: int = 3  #quantidade inicial de vidas
var lives_limit: int = 5 #limite maximo de vidas #inplementar

#----LOOTs
var coin_value: int = 1 #moeda
var gem_value: int = 100 #gemas
var life_value: int = 50 #vida - Inplementar

# ─────────── Configurações das Plataformas ───────────
@export var visibility = 400

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






#----SISTEMA


# ─────────── SINAIS ───────────



# ─────────── 00 ───────────
# ─────────── 00 ───────────
# ─────────── 00 ───────────
# ─────────── 00 ───────────
# ─────────── 00 ───────────
