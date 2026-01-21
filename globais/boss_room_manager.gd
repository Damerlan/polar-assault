extends Node

# ===============================
# BIBLIOTECA DE SALAS
# ===============================
# Cada sala define:
# - tipo: "boss" ou "bonus"
# - nível mínimo
# - nível máximo
# - peso (chance relativa)
# - recompensa base
# ===============================

const ROOMS := [
	{
		"id": "boss_easy_01",
		"scene": "res://scenes/boss_rooms/boss_room_01.tscn",
		"type": "boss",
		"min_level": 1,
		"max_level": 3,
		"weight": 1.0,
		"reward": 500
	},
	{
		"id": "boss_medium_01",
		"scene": "res://scenes/boss_rooms/boss_room_01.tscn",
		"type": "boss",
		"min_level": 3,
		"max_level": 6,
		"weight": 1.0,
		"reward": 1200
	},
	{
		"id": "bonus_easy",
		"scene": "res://scenes/boss_rooms/boss_room_01.tscn",
		"type": "bonus",
		"min_level": 1,
		"max_level": 99,
		"weight": 0.7,
		"reward": 300
	}
]




func pick_room_by_level(level: int) -> Dictionary:
	var candidates := []

	for room in ROOMS:
		if level >= room.min_level and level <= room.max_level:
			candidates.append(room)

	if candidates.is_empty():
		return ROOMS[0]

	return _pick_weighted(candidates)


func _pick_weighted(list: Array) -> Dictionary:
	var total := 0.0
	for r in list:
		total += r.weight

	var roll := randf() * total
	var acc := 0.0

	for r in list:
		acc += r.weight
		if roll <= acc:
			return r

	return list[0]
