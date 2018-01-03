extends KinematicBody
export(float) var GRAVITY = -34.8
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
export(float) var wall_hang_jump_velocity = 24
var velocity = Vector3(0,0,0)

export(NodePath) var camera_rig = null

var impact=0
# Lerped leaning
var lean_amount = 0
var target_lean_amount = 0

const ADVENTURE = 0
const TACTICAL = 1

var mode = ADVENTURE
# X = A,D
# Y = Jump, Crouch
# Z = W,S
var deaccel_accum = 0

# For Hand IK
var best_grab_points =[Vector3(), Vector3()]

var target_object = null

## Should I separate movement into Kinematic and blends/animation into char?
## probabaly.

func _ready():
	set_physics_process(true)
	set_process(true)
	$floor_lock.add_exception_rid(get_rid())

func toggle_camera_tactical():
	if mode != TACTICAL:
		mode=TACTICAL
	else:
		 mode=ADVENTURE

func set_camera_tactical(b):
	if b:
		mode=TACTICAL
		get_node(camera_rig).get_world_point(["floor", "hold"])
	else:
		 mode=ADVENTURE

func get_unit_movement():
	# Return input unit vector
	# May be (0,0,0) if no input from player
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
	return movement

func camera_transform(movement):
	if mode == ADVENTURE:
		movement = get_node("../cam_rig").global_transform.basis * movement
		get_node("char/anim_tree").blend2_node_set_amount("strafe_blend", 0)
	elif mode == TACTICAL:
		var offset = get_selection_target()
		if offset == null:
			mode = ADVENTURE
		var diff = get_node(camera_rig).contact - global_transform.origin
		
		if diff.length() > 40 or (diff.length() < 1 and not is_selecting_object()):
			mode = ADVENTURE
		
		movement = get_node("../cam_rig").global_transform.basis * movement
		
		diff = diff.normalized()
		var theta = diff.angle_to(movement)
		get_node("char/anim_tree").blend2_node_set_amount("strafe_blend", max(min(abs(theta / (PI/2)), 1),0))
	return movement

func get_target_movement(movement):
	var limit_speed =  max_speed * SPRINT_MOD if Input.is_key_pressed(KEY_SHIFT)  else max_speed 
	limit_speed = max_speed * CROUCH_MOD if Input.is_key_pressed(KEY_CONTROL) and is_touching_floor() else limit_speed
	
	return movement*limit_speed

func _physics_process(delta):
	if not is_on_floor():
		velocity.y += GRAVITY * delta
	if Input.is_action_just_pressed("player_action_left"):
		set_camera_tactical(true)
	elif Input.is_action_just_pressed("player_toggle_tactical") and mode == TACTICAL:
		toggle_camera_tactical()
	
	if camera_rig != null and mode == TACTICAL:
		var offset=get_selection_target()
		if offset==null:
			mode = ADVENTURE
		else:
			get_node("input_cirlce_L").set_on_screen(get_node(camera_rig).get_camera().unproject_position(offset))
			if is_selecting_object():
				if target_object != null:
					target_object.set_selected(false)
				target_object = get_selected_object()
				target_object.set_selected(true)
				
				if target_object.has_method("get_actions"):
					var a = target_object.get_actions()
					for k in a.keys():
						if k == "kick":
							var p1 = get_node(camera_rig).get_camera().unproject_position(global_transform.origin-Vector3(0,0.7,0))
							var p2 = get_node(camera_rig).get_camera().unproject_position(target_object.global_transform.origin)
							a[k].x = rad2deg((p2-p1).angle())
						$input_cirlce_L.set_section(k, a[k])
				
				for c in $char/skin/Skeleton/left_hand_attach.get_children():
					if c.has_method("get_actions"):
						var weapon_actions = c.get_actions()
						for k in weapon_actions:
							$input_cirlce_L.set_section(k,weapon_actions[k])
	
	if target_object != null and not is_selecting_object():
		target_object.set_selected(false)
		target_object = null
	
	var movement = get_unit_movement()
	
	movement = camera_transform(movement)
	
	var target = get_target_movement(movement)
	
	var hvel = velocity
	
	hvel.y = 0
	
	var accel = 0
	if (movement.dot(hvel) > 0):
		accel = ACCEL
		
		deaccel_accum = 0
		
	else:
		accel = DEACCEL
		
		if hvel.length() > 0.75:
			deaccel_accum += delta * 24
		else:
			deaccel_accum = lerp(deaccel_accum, 0, delta * 10)
	
	var on_floor = false
	var in_air = false
	var on_wall = false
	
	## BLEND
	var old_stop_blend = get_node("char/anim_tree").blend2_node_get_amount("stop_b_run")
	var new_stop_blend = min(deaccel_accum, 0.95)
	get_node("char/anim_tree").blend2_node_set_amount("stop_b_run", lerp(old_stop_blend, new_stop_blend, delta * 10))
	########
	
	hvel = hvel.linear_interpolate(target, accel * delta)
	
	if is_wall_hanging():
		hvel *= 0.64
	
	velocity.x = hvel.x
	velocity.z = hvel.z
	
	var air = not is_touching_floor()
	var air_mod = 1
	
	## BLEND
	var old_fall_blend = get_node("char/anim_tree").blend2_node_get_amount("fall_blend")
	var new_fall_blend = old_fall_blend
	
	
	var fall_blend_lerp_time = 0
	
	if is_touching_floor():
		new_fall_blend = 0
		fall_blend_lerp_time = fall_recover_time
		
	else:
		new_fall_blend = 0.5
		fall_blend_lerp_time = fall_time
		
	get_node("char/anim_tree").blend2_node_set_amount("fall_blend", lerp(old_fall_blend, new_fall_blend, delta * (1/fall_blend_lerp_time)))
	########
	
	velocity = move_and_slide(velocity, Vector3(0,1,0),0.1,5,deg2rad(30))
	
	var col_count = get_slide_count()
	for i in range(col_count):
		var col = get_slide_collision(i)
		if col.collider.is_in_group("player_physics"):
			col.collider.apply_impulse(Vector3(), -col.normal  * velocity.length())
			break
	
	detect_impact(delta)
	
	
	if not is_touching_floor() and not is_wall_hanging():
		air_mod = 0.05  if fmod(get_node("char/wheel").rotation.x, PI/2) >  PI / 3 else 1.25
	
	var crouch_recover = crouch_time
	if impact < 0:
		crouch_recover = impact_time
	
	var old_crouch_blend = get_node("char/anim_tree").blend2_node_get_amount("crouch_b")
	var new_crouch_blend = (0.46 if Input.is_key_pressed(KEY_CONTROL) else 0) - (0.25 * impact if is_touching_floor() else 0)
	
	if -impact < 0.01:
		impact = 0
	get_node("char/anim_tree").blend2_node_set_amount("crouch_b", lerp(old_crouch_blend, min(1,new_crouch_blend), delta * (1/crouch_recover)))
	impact = lerp(impact, 0, delta * (1/crouch_recover))
	
	
	get_node("hang_shape").disabled = (not is_wall_hanging()) or (is_touching_floor()) or (not get_hang_normal())
		
	
	set_y_rotation(hvel,delta)
	
	target_lean_amount = (hvel.length() / (max_speed * (SPRINT_MOD if not air else 1))) * 0.3 * (1 if not air else -0.6)
	lean_amount = lerp(lean_amount, target_lean_amount, delta * 10)
	get_node("char").rotation.x = lean_amount 
	
	stride_length = 0.62 if Input.is_key_pressed(KEY_SHIFT) else 0.56
	stride_length = 0.16 if Input.is_key_pressed(KEY_CONTROL) else stride_length
	var wheel_vel = velocity
#	wheel_vel.y = 0
	get_node("char/wheel").rotate_x((wheel_vel.length() /  (2 * PI * stride_length + (abs(impact) / 16)) / 4 / PI) * air_mod)
	get_node("char/anim_tree").timeseek_node_seek("run_seek", (get_node("char/wheel").rotation.x+PI) / (2*PI))
	
	get_node("char/anim_tree").blend2_node_set_amount("idle_b_run", min(max(0,1 - pow((hvel.length() / max_speed),0.5)), 1))
	
	if Input.is_action_just_pressed("player_jump"):
		if is_touching_floor():
			velocity.y = jump_velocity *  (0.6 if Input.is_key_pressed(KEY_CONTROL) else 1)
		elif is_wall_hanging():
			velocity.y = wall_hang_jump_velocity
	
	var old_hang_blend = get_node("char/anim_tree").blend2_node_get_amount("hang_blend")
	var new_hang_blend = lerp(old_hang_blend, 1, delta * 23) if (is_wall_hanging() and not is_touching_floor()) else lerp(old_hang_blend, 0, delta * 25)
	get_node("char/anim_tree").blend2_node_set_amount("hang_blend", new_hang_blend)

func get_hang_normal():
	return false
	if not is_wall_hanging():
		return false
	
	var good_hang = false
	if $wall_grab_R.is_colliding():
		if $wall_grab_R.get_collision_normal().angle_to(Vector3(0,1,0)) < deg2rad(15):
			good_hang = true
	if $wall_grab_L.is_colliding():
		if $wall_grab_L.get_collision_normal().angle_to(Vector3(0,1,0)) < deg2rad(15):
			good_hang = true
	return good_hang

func _process(delta):
	apply_ik(delta)

func apply_ik(delta):
	if get_node("wall_grab_L").is_colliding():
		best_grab_points[0] = get_node("wall_grab_L").get_collision_point()
	elif get_node("input_cirlce_L").active:
		var drag = -get_node("input_cirlce_L").drag
		var l_hand = get_node("char/skin/Skeleton/left_rest").transform
		var target_l_hand = l_hand.translated(Vector3(drag.x,drag.y, 64-drag.length()) / 32)
		get_node("char/skin/Skeleton/left_hand").transform = get_node("char/skin/Skeleton/left_hand").transform.interpolate_with(target_l_hand, delta)
		get_node("char/skin/Skeleton/left_hand").solve(delta)
	
	if get_node("wall_grab_R").is_colliding():
		best_grab_points[1] = get_node("wall_grab_R").get_collision_point()
	elif get_node("input_cirlce_R").active:
		var drag = -get_node("input_cirlce_R").drag
		get_node("char/skin/Skeleton/right_hand").transform.origin = Vector3(drag.x,drag.y, 64-drag.length()) / 32 + get_node("char/skin/Skeleton/right_rest").translation
		get_node("char/skin/Skeleton/right_hand").solve(delta)
	
	if is_wall_hanging():
		get_node("char/skin/Skeleton/right_hand").solve(delta)
		get_node("char/skin/Skeleton/left_hand").solve(delta)
		
		get_node("char/skin/Skeleton/right_hand").global_transform.origin = best_grab_points[1]
		get_node("char/skin/Skeleton/left_hand").global_transform.origin = best_grab_points[0]

	var floor_p = get_node("floor_lock").get_collision_point()

func set_y_rotation(hvel,delta):
	var old_rotation = Vector2(cos(rotation.y),sin(rotation.y))
	var new_rotation = old_rotation.linear_interpolate(Vector2(hvel.z, hvel.x), TURN_RATE / 10 * delta)
	if mode == ADVENTURE:
		if is_touching_floor():
			new_rotation = old_rotation.linear_interpolate(Vector2(velocity.z, velocity.x), TURN_RATE * delta)
		elif is_wall_hanging():
			if get_node("wall_grab_R").is_colliding() and not get_node("wall_grab_L").is_colliding():
				new_rotation = old_rotation.rotated(-5 * delta)
			elif not get_node("wall_grab_R").is_colliding() and get_node("wall_grab_L").is_colliding():
				new_rotation = old_rotation.rotated(5 * delta)
		
	elif mode == TACTICAL:
		if is_wall_hanging():
			if get_node("wall_grab_R").is_colliding() and not get_node("wall_grab_L").is_colliding():
				new_rotation = old_rotation.rotated(-5 * delta)
			elif not get_node("wall_grab_R").is_colliding() and get_node("wall_grab_L").is_colliding():
				new_rotation = old_rotation.rotated(5 * delta)
		else:
			var world_point = get_selection_target()
			var mouse_proj_diff =   world_point - global_transform.origin
			new_rotation = old_rotation.linear_interpolate(Vector2(mouse_proj_diff.z, mouse_proj_diff.x), TURN_RATE * delta)
	rotation.y = new_rotation.angle()

## Awkward function name, but needed
func get_cam_contact():
	return get_node(camera_rig).contact

func is_touching_floor():
	get_node("floor_lock").force_raycast_update()
	if get_node("floor_lock").is_colliding():
		return true
	return false

func is_wall_hanging():
	return false
	if (get_node("wall_grab_L").is_colliding() or get_node("wall_grab_R").is_colliding()) and not is_touching_floor():
		return true
	return false

func detect_impact(delta):
	if velocity.y < -0.4:
		impact = velocity.y * 0.6

func is_selecting_object(tags=["interact"]):
	if get_node(camera_rig).collider != null:
		var groups = get_node(camera_rig).collider.get_groups()
		for g in groups:
			if g == "floor":
				continue
			if get_node(camera_rig).collider.is_in_group(g):
				return true
	return false

func get_selected_object():
	return get_node(camera_rig).collider

func get_selection_target():
	var offset=get_node(camera_rig).contact
	if is_selecting_object():
		offset=get_selected_object().global_transform.origin
	return offset

func _on_input_cirlce_L_action(action_name, action_v, drag_v):
	if target_object != null:
		print("[Player]: ", action_name, " on ", target_object.get_name())
	if target_object == null:
		# Probably trying to use a weapon
		
		if action_name == "hold":
			# We really meant drop
			if $char/skin/Skeleton/left_hand_attach.get_child_count() > 0:
				for c in $char/skin/Skeleton/left_hand_attach.get_children():
					c.become_unequipped(get_parent())
					c.global_transform.origin = $char/skin/Skeleton/left_hand_attach.global_transform.origin
		
		elif action_name == "throw":
			# We really meant drop
			if $char/skin/Skeleton/left_hand_attach.get_child_count() > 0:
				for c in $char/skin/Skeleton/left_hand_attach.get_children():
					c.become_unequipped(get_parent())
					c.global_transform.origin = $char/skin/Skeleton/left_hand_attach.global_transform.origin
					c.linear_velocity = Vector3(0,0,10)
		return
		
		
	if action_name == "kick" and global_transform.origin.distance_to(target_object.global_transform.origin) < 2:
		target_object.apply_impulse(Vector3(), Vector3(0,0,1).rotated(Vector3(0,1,0), rotation.y) * 20)
	elif action_name=="hold":
		if $char/skin/Skeleton/left_hand_attach.get_child_count() > 0:
			for c in $char/skin/Skeleton/left_hand_attach.get_children():
				c.become_unequipped(get_parent())
				c.global_transform.origin = $char/skin/Skeleton/left_hand_attach.global_transform.origin
		if global_transform.origin.distance_to(target_object.global_transform.origin) < 2:
			target_object.become_equipped($char/skin/Skeleton/left_hand_attach)
			target_object.transform.origin  = Vector3()
			mode = ADVENTURE

func _on_input_cirlce_R_action(action_name, action_v, drag_v):
	if target_object != null:
		print("[Player]: ", action_name, " on ", target_object.get_name())
	if target_object == null:
		# Probably trying to use a weapon
		
		if action_name == "hold":
			# We really meant drop
			if $char/skin/Skeleton/left_hand_attach.get_child_count() > 0:
				for c in $char/skin/Skeleton/left_hand_attach.get_children():
					c.become_unequipped(get_parent())
					c.global_transform.origin = $char/skin/Skeleton/left_hand_attach.global_transform.origin
		
		elif action_name == "throw":
			# We really meant drop
			if $char/skin/Skeleton/left_hand_attach.get_child_count() > 0:
				for c in $char/skin/Skeleton/left_hand_attach.get_children():
					c.become_unequipped(get_parent())
					c.global_transform.origin = $char/skin/Skeleton/left_hand_attach.global_transform.origin
					c.linear_velocity = Vector3(0,0,10)
		return
		
		
	if action_name == "kick" and global_transform.origin.distance_to(target_object.global_transform.origin) < 2:
		target_object.apply_impulse(Vector3(), Vector3(0,0,1).rotated(Vector3(0,1,0), rotation.y) * 20)
	elif action_name=="hold":
		if $char/skin/Skeleton/left_hand_attach.get_child_count() > 0:
			for c in $char/skin/Skeleton/left_hand_attach.get_children():
				c.become_unequipped(get_parent())
				c.global_transform.origin = $char/skin/Skeleton/left_hand_attach.global_transform.origin
		if global_transform.origin.distance_to(target_object.global_transform.origin) < 2:
			target_object.become_equipped($char/skin/Skeleton/left_hand_attach)
			target_object.transform.origin  = Vector3()
			mode = ADVENTURE

func get_target():
	if target_object != null:
		return target_object
	else:
		return false
