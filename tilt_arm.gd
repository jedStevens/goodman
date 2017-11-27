extends Spatial

# class member variables go here, for example:
# var a = 2
# var b = "textvar"

func _ready():
	set_process(true)

func _process(delta):
	rotation_degrees.y = -(get_viewport().get_mouse_position().x - 1920/2) / 1920 * 5
	rotation_degrees.x = -(get_viewport().get_mouse_position().y - 1080/2) / 1080 * 5