extends Camera2D

var target: Node2D #declarando o alvo
@export var base_resolution := Vector2i(480, 270)

#função quando o no é criado
func _ready() -> void:
	get_target()
	#ajustes da resolução
	make_current()
	_update_zoom()


func _process(_delta: float) -> void:
	position = target.position


#função para pegar o no player
func get_target():
	var nodes = get_tree().get_nodes_in_group("Player")
	if nodes.size() == 0:
		push_error("Player não Encontrado!")
		return
		
	target = nodes[0]#pega o primeiro da lista caso aja mais do que 1
	




#ajustes de resolução
func _notification(what):
	if what == NOTIFICATION_WM_SIZE_CHANGED:
		_update_zoom()

func _update_zoom():
	var screen_size = get_viewport_rect().size

	var scale_x = screen_size.x / base_resolution.x
	var scale_y = screen_size.y / base_resolution.y

	var scale := floori(min(scale_x, scale_y))
	scale = max(scale, 1)

	zoom = Vector2(1.0 / scale, 1.0 / scale)
