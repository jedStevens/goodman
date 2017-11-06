extends Position3D

# class member variables go here, for example:
# var a = 2
# var b = "textvar"
var accum = 0

func _ready():
	set_process(true)

func _process(delta):
	accum += delta
	#translate(Vector3(0,0,sin(accum)/10))