extends Node

var resources_to_load := []
var loaded_resources := {}
var current_index := 0
var progress := 0.0
var loading := false

func start_loading(list: Array):
	resources_to_load = list
	loaded_resources.clear()
	current_index = 0
	progress = 0.0
	loading = true
	_load_next()

func _load_next():
	if current_index >= resources_to_load.size():
		loading = false
		return

	var path = resources_to_load[current_index]
	ResourceLoader.load_threaded_request(path)

func update():
	if not loading:
		return

	var path = resources_to_load[current_index]
	var status = ResourceLoader.load_threaded_get_status(path)

	if status == ResourceLoader.THREAD_LOAD_LOADED:
		loaded_resources[path] = ResourceLoader.load_threaded_get(path)
		current_index += 1
		progress = float(current_index) / resources_to_load.size()
		_load_next()
