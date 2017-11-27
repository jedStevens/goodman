extends VBoxContainer

# class member variables go here, for example:
# var a = 2
# var b = "textvar"

func _ready():
	get_viewport().connect("size_changed", self, "resize")
	resize()

func resize():
	var s = get_viewport().size
	margin_right = s.x
	margin_bottom = s.y