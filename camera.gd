extends Spatial

const PIXELS_PER_RADIAN_X = 250
const PIXELS_PER_RADIAN_Y = 250

var control = false
var start_point = null

var velocity = Vector2(0,0)

export(NodePath) var player = null

func _ready():
	set_process(true)

func _process(delta):
	if player != null:
		global_transform.origin = get_node(player).global_transform.origin
	if Input.is_action_just_pressed("camera_pan"):
		control = true
		start_point = get_viewport().get_mouse_position()
	
	if Input.is_action_pressed("camera_pan") and control:
		var motion = start_point - get_viewport().get_mouse_position()
		velocity.x = motion.x / PIXELS_PER_RADIAN_X
		velocity.y = motion.y / PIXELS_PER_RADIAN_Y
	
	rotation.y -= velocity.x *  delta
	get_node("arm").rotate_x(velocity.y * delta)
	velocity *= 0.9
	