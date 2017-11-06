tool
extends Position3D

export(NodePath) var ik = null

func _ready():
	set_process(true)

func _process(delta):
	if ik != null:
		get_node(ik).global_transform = global_transform