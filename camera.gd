extends Spatial

const PIXELS_PER_RADIAN_X = 2
const PIXELS_PER_RADIAN_Y = 2

var control = false
var start_point = null

var velocity = Vector2(0,0)

export(Vector3) var offset = Vector3(0,1,0)

export(NodePath) var player = null

var to = Vector3(0,0,0)
var from = Vector3(0,0,0)

var far_plane = 1000

var contact = Vector3(0,0,0)
var collider = null

var zoom = 6

export(float) var camera_speed = 14

func _ready():
	set_fixed_process(true)

func get_world_point(force=false,tags=["floor"]):
	var ds = PhysicsServer.space_get_direct_state(get_world().get_space())
	if Input.is_action_just_pressed("player_retarget_tactical") or force:
		from = get_camera().project_ray_origin(get_viewport().get_mouse_position())
		to = from + get_camera().project_ray_normal(get_viewport().get_mouse_position())*far_plane
		var col = ds.intersect_ray(from, to)
		
		if("collider" in col.keys()):
			for tag in tags:
				if col["collider"].is_in_group(tag):
					collider = col["collider"]
					contact = col["position"]
					return

func _fixed_process(delta):
	get_world_point()
	var new_position = global_transform.origin
	if player != null:
		new_position = get_node(player).global_transform.origin + offset
	if get_node(player).mode == get_node(player).TACTICAL:
		new_position = (contact - get_node(player).global_transform.origin)/4  +get_node(player).global_transform.origin
	if Input.is_action_just_pressed("camera_pan"):
		control = true
		start_point = get_viewport().get_mouse_position()
	global_transform.origin = global_transform.origin.linear_interpolate(new_position, delta * camera_speed)
	
	if Input.is_action_pressed("camera_pan") and control:
		var motion = start_point - get_viewport().get_mouse_position()
		start_point = get_viewport().get_mouse_position()
		velocity.x = motion.x / PIXELS_PER_RADIAN_X
		velocity.y = motion.y / PIXELS_PER_RADIAN_Y
	
	if Input.is_action_just_pressed("camera_to_behind_player") and player != null:
		rotation.y = get_node(player).rotation.y + PI
	else:
		rotation.y -= velocity.x *  delta
	
	if Input.is_action_pressed("zoom_in"):
		print("Zooming In:")
		zoom = max(zoom - delta, 0)
	if Input.is_action_pressed("zoom_out"):
		zoom = min(zoom + delta, 10)
	
	get_node("arm").rotate_x(velocity.y * delta)
	get_node("arm").rotation.x = min(max(get_node("arm").rotation.x, deg2rad(-90)), deg2rad(-15))
	get_node("arm/cam").translation.z = zoom
	velocity *= 0.9

func get_camera():
	return get_node("arm/cam")