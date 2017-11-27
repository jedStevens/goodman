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

var hover = Vector3()
var contact = Vector3(0,0,0)
var collider = null

var zoom = 5

export(float) var camera_speed = 14

func _ready():
	set_physics_process(true)
	offset = $offset.transform.origin

func get_world_point(tags=["floor","interact"]):
	var ds = PhysicsServer.space_get_direct_state(get_world().get_space())
	from = get_camera().project_ray_origin(get_viewport().get_mouse_position())
	to = from + get_camera().project_ray_normal(get_viewport().get_mouse_position())*far_plane
	var col = ds.intersect_ray(from, to, [get_node(player)])
	
	if("collider" in col.keys()):
		for tag in tags:
			if col["collider"].is_in_group(tag):
				collider = col["collider"]
				return col["position"]

func _physics_process(delta):
	var p = get_world_point()
	if p != null:
		hover = p
		if Input.is_action_just_pressed("player_action_left"):
			contact=hover
	var new_position = global_transform.origin
	if player != null:
		var target = Vector3()
		if get_node(player).get_target()  and get_node(player).mode == get_node(player).TACTICAL:
			target = (get_node(player).get_target().global_transform.origin-get_node(player).global_transform.origin)
		new_position = (get_node(player).global_transform.origin + target/2) + offset
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
		zoom = max(zoom - 12*delta, 0)
	if Input.is_action_pressed("zoom_out"):
		zoom = min(zoom + 12*delta, 100)
	
	$arm.rotate_x(velocity.y * delta)
	$arm.rotation.x = min(max(get_node("arm").rotation.x, deg2rad(-55)), deg2rad(15))
	var is_tactical = get_node(player).mode == get_node(player).TACTICAL
	var tactical = 0.75 if is_tactical else 1
	get_node("arm/cam").translation.z = lerp(get_node("arm/cam").translation.z,zoom*(tactical), 10 * delta)
	velocity *= 0.9
	
	$arm/cam.get_environment().dof_blur_near_distance =  lerp($arm/cam.get_environment().dof_blur_near_distance ,get_hover_distance() * .25,delta * 2)
	$arm/cam.get_environment().dof_blur_far_distance =  lerp($arm/cam.get_environment().dof_blur_far_distance ,get_hover_distance() * 1.5,delta * 2)

func get_camera():
	return get_node("arm/cam")

func get_contact_distance():
	if contact == null:
		return 20
	return (contact - $arm/cam.global_transform.origin).length()


func get_hover_distance():
	if hover == null:
		return 0
	return (hover - $arm/cam.global_transform.origin).length()

func _on_player_click():
	contact = hover


