extends MeshInstance

# class member variables go here, for example:
# var a = 2
# var b = "textvar"

var speed = 0.05

func _ready():
	set_process(true)

func _process(delta):
	rotate_y(delta * speed)
