extends OmniLight

# class member variables go here, for example:
# var a = 2
# var b = "textvar"

var base = 0
export (float) var flux = 0.25
export (float) var flicker_rate = 0.6

func _ready():
	base = light_energy
	set_process(true)

func _process(delta):
	light_energy = lerp(light_energy, base + (randf()-0.5)*(flux), flicker_rate)