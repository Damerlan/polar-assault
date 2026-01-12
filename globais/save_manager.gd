#SaveManager - Updated 12-01-26
extends Node

const SAVE_PATH = "user://penguin_save_score.json"

const MAX_RECORDS := 5


var ranking:Array = []

func _ready():
	load_ranking()

func load_ranking():
	if not FileAccess.file_exists(SAVE_PATH):
		ranking = []
		return

	var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
	var data = JSON.parse_string(file.get_as_text())

	if typeof(data) == TYPE_ARRAY:
		ranking = data
	else:
		ranking = []

func save_ranking():
	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	file.store_string(JSON.stringify(ranking))

func is_new_record(score:int) -> bool:
	if ranking.size() < MAX_RECORDS:
		return true
	return score > ranking[-1].score

func add_record(nome:String, score:int):
	ranking.append({
		"nome": nome,
		"score": score
	})
	ranking.sort_custom(func(a, b): return a.score > b.score)
	ranking = ranking.slice(0, MAX_RECORDS)
	save_ranking()
