extends KinematicBody
export(float) var GRAVITY = -50.8
export(float) var max_speed = 7
const ACCEL= 10
const DEACCEL= 12
const TURN_RATE = 15
const SPRINT_MOD = 1.4
const CROUCH_MOD = 0.3

var stride_length = 0.56

export(Gradient) var deaccel_pose_map = null

export(float) var fall_time = 0.2
export(float) var fall_recover_time = 0.05

export(float) var impact_time = 0.1
export(float) var crouch_time = 0.15

export(float) var jump_velocity = 12
export(float) var wall_hang_jump_velocity = 5
var velocity = Vector3(0,0,0)

export(NodePath) var camera_rig = null

var impact=0
# Lerped leaning
var lean_amount = 0
var target_lean_amount = 0
var floor_locked = false

const ADVENTURE = 0
const TACTICAL = 1

var mode = ADVENTURE
# X = A,D
# Y = Jump, Crouch
# Z = W,S
var deaccel_accum = 0
func _ready():
	set_fixed_process(true)

func _fixed_process(delta):
	if Input.is_action_just_pressed("player_toggle_tactical"):
		if mode != TACTICAL:
			mode=TACTICAL
			get_node(camera_rig).get_world_point(true)
		else:
			 mode=ADVENTURE
	
	var movement = Vector3(0,0,0)
	if Input.is_key_pressed(KEY_W):
		movement.z-=1
	if Input.is_key_pressed(KEY_S):
		movement.z+=1
	if Input.is_key_pressed(KEY_A):
		movement.x-=1
	if Input.is_key_pressed(KEY_D):
		movement.x+=1
	
	movement.y = 0
	movement = movement.normalized()
	
	if mode == ADVENTURE:
		movement = get_node("../cam_rig").global_transform.basis * movement
		get_node("char/anim_tree").blend2_node_set_amount("strafe_blend", 0)
	elif mode == TACTICAL:
		var diff = get_node(camera_rig).contact - global_transform.origin
		
		if diff.length() > 20 or diff.length() < 1:
			mode = ADVENTURE
		
		movement = get_node("../cam_rig").global_transform.basis * movement
		
		diff = diff.normalized()
		var theta = diff.angle_to(movement)
		get_node("char/anim_tree").blend2_node_set_amount("strafe_blend", max(min(abs(theta / (PI/2)), 1),0))
	
	var hvel = velocity
	
	hvel.y = 0
	
	var limit_speed =  max_speed * SPRINT_MOD if Input.is_key_pressed(KEY_SHIFT)  else max_speed 
	limit_speed = max_speed * CROUCH_MOD if Input.is_key_pressed(KEY_CONTROL) else limit_speed
	var target = movement*limit_speed
	var accel
	if (movement.dot(hvel) > 0):
		accel = ACCEL
		deaccel_accum = 0
	else:
		accel = DEACCEL
		if hvel.length() > 0.75:
			deaccel_accum += delta * 24
		else:
			deaccel_accum = lerp(deaccel_accum, 0, delta * 10)
	
	var old_stop_blend = get_node("char/anim_tree").blend2_node_get_amount("stop_b_run")
	var new_stop_blend = min(deaccel_accum, 0.95)
	get_node("char/anim_tree").blend2_node_set_amount("stop_b_run", lerp(old_stop_blend, new_stop_blend, delta * 10))
	
	
	hvel = hvel.linear_interpolate(target, accel * delta)
	if is_wall_hanging():
		hvel *= 0.64
	velocity.x = hvel.x
	velocity.z = hvel.z
	
	var old_fall_blend = get_node("char/anim_tree").blend2_node_get_amount("fall_blend")
	var new_fall_blend = old_fall_blend
	
	var air = false
	var air_mod = 1
	var fall_blend_lerp_time = 0
	if is_touching_floor():
		new_fall_blend = 0
		fall_blend_lerp_time = fall_recover_time
		
	else:
		air = true
		new_fall_blend = 1
		fall_blend_lerp_time = fall_time
		
	get_node("char/anim_tree").blend2_node_set_amount("fall_blend", lerp(old_fall_blend, new_fall_blend, delta * (1/fall_blend_lerp_time)))
	
	velocity = move_and_slide(velocity, Vector3(0,1,0),0.01,5,1.2)
	for i in range(get_slide_count()):
		var slide = get_slide_collision(i)
		if slide != null and velocity.length()>0:
			velocity = velocity.slide(slide.normal)
			move_and_slide(slide.remainder, Vector3(0,1,0),0.01,5,1.2)
		else:
			break
	
	lock_to_floor(delta)
	
	if not is_touching_floor() and not is_wall_hanging():
		air_mod = 0.05  if fmod(get_node("char/wheel").rotation.x, PI/2) >  PI / 4 else 1.25
		velocity.y += GRAVITY * delta
	
	var crouch_recover = crouch_time
	if impact < 0:
		crouch_recover = impact_time
	
	var old_crouch_blend = get_node("char/anim_tree").blend2_node_get_amount("crouch_b")
	var new_crouch_blend = (0.46 if Input.is_key_pressed(KEY_CONTROL) else 0) - (0.5 * impact if is_touching_floor() else 0)
	
	if -impact < 0.01:
		impact = 0
	get_node("char/anim_tree").blend2_node_set_amount("crouch_b", lerp(old_crouch_blend, min(1,new_crouch_blend), delta * (1/crouch_recover)))
	impact = lerp(impact, 0, delta * (1/crouch_recover))
	
	
	get_node("hang_shape").disabled = not is_wall_hanging()
		
	
	set_y_rotation(hvel,delta)
	
	target_lean_amount = (hvel.length() / (max_speed * (SPRINT_MOD if not air else 1))) * 0.3 * (1 if not air else -0.6)
	lean_amount = lerp(lean_amount, target_lean_amount, delta * 10)
	get_node("char").rotation.x = lean_amount 
	
	stride_length = 0.62 if Input.is_key_pressed(KEY_SHIFT) else 0.56
	stride_length = 0.2 if Input.is_key_pressed(KEY_CONTROL) else stride_length
	var wheel_vel = velocity
	wheel_vel.y = 0
	get_node("char/wheel").rotate_x((wheel_vel.length() /  (2 * PI * stride_length + (abs(impact) / 16)) / 4 / PI) * air_mod)
	
	get_node("char/anim_tree").timeseek_node_seek("run_seek", (get_node("char/wheel").rotation.x+PI) / (2*PI))
	
	get_node("char/anim_tree").blend2_node_set_amount("idle_b_run", min(max(0,1 - pow((hvel.length() / max_speed),0.5)), 1))
	
	if Input.is_action_just_pressed("player_jump"):
		if is_touching_floor():
			velocity.y = jump_velocity
		elif is_wall_hanging():
			velocity.y = wall_hang_jump_velocity
		get_node("char/anim_tree").blend2_node_set_amount("fall_blend", 0.7)
		get_node("char/anim_tree").blend2_node_set_amount("crouch_b", 0.6)
	
	var old_hang_blend = get_node("char/anim_tree").blend2_node_get_amount("hang_blend")
	var new_hang_blend = lerp(old_hang_blend, 1, delta * 23) if is_wall_hanging() else lerp(old_hang_blend, 0, delta * 25)
	get_node("char/anim_tree").blend2_node_set_amount("hang_blend", new_hang_blend)

func set_y_rotation(hvel,delta):
	var old_rotation = Vector2(cos(rotation.y),sin(rotation.y))
	var new_rotation = Vector2(hvel.z, hvel.x)
	if mode == ADVENTURE:
		if is_touching_floor():
			new_rotation = old_rotation.linear_interpolate(Vector2(velocity.z, velocity.x), TURN_RATE * delta)
		if is_on_wall() :
			var col = get_slide_collision(0)
			if col != null:
				new_rotation = Vector2(hvel.z, hvel.x)
		if is_wall_hanging():
			if get_node("wall_grab_R").is_colliding() and not get_node("wall_grab_L").is_colliding():
				new_rotation = old_rotation.rotated(-5 * delta)
			elif not get_node("wall_grab_R").is_colliding() and get_node("wall_grab_L").is_colliding():
				new_rotation = old_rotation.rotated(5 * delta)
			else:
				new_rotation = old_rotation
		
	elif mode == TACTICAL:
		var world_point = get_node(camera_rig).contact
		var mouse_proj_diff =   world_point - global_transform.origin
		new_rotation = old_rotation.linear_interpolate(Vector2(mouse_proj_diff.z, mouse_proj_diff.x), TURN_RATE * delta)
	rotation.y = new_rotation.angle()
	
func get_mouse_world_point():
	return get_node(camera_rig).contact

func is_touching_floor():
	if get_node("floor_lock").is_colliding():
		return true
	return false
func is_wall_hanging():
	if get_node("wall_grab_L").is_colliding() or get_node("wall_grab_R").is_colliding():
		return true
	return false


func lock_to_floor(delta):
	
	if get_node("floor_lock").is_colliding() or is_wall_hanging():
		if (Input.is_action_just_pressed("player_jump")):
			floor_locked = false
		else:
			floor_locked = true
	else:
		if is_touching_floor():
			floor_locked = true
		else:
			floor_locked = false
	
	if floor_locked:
		var col = move_and_collide(Vector3(0,-0.1, 0))
		if col != null:
			velocity = velocity.slide(col.normal)
	elif velocity.y < 0:
		impact = velocity.y