extends MeshInstance

# class member variables go here, for example:
# var a = 2
# var b = "textvar"

func _ready():
	var s = global_transform.basis.get_scale()
	$Particles.global_transform.basis = Basis().scaled(s)
