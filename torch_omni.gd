extends OmniLight

# class member variables go here, for example:
# var a = 2
# var b = "textvar"

func _ready():
	set_process(true)

func _process(delta):
	light_energy -= delta
	light_energy = max(randf(), light_energy)