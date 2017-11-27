extends RigidBody

var selected_mat = preload("res://selected.tres")

var selected = false

var __mat = null

var being_held = false

func set_selected(b):
	if b and not selected:
		selected = true
		stash_mat()
		
	elif not b:
		selected = false
		restore_stash_mat()

func get_last_pass():
	var p = $MeshInstance.material_override
	while p.next_pass != null:
		p = p.next_pass
	
	return p

func remove_last_pass():
	var p = $MeshInstance.material_override
	while p.next_pass.resource_path != "res://selected.tres":
		p = p.next_pass
	if p != null:
		p.next_pass = null

func stash_mat():
 	$MeshInstance.get_surface_material(0).next_pass = selected_mat
func restore_stash_mat():
	$MeshInstance.get_surface_material(0).next_pass = null

func become_equipped(bone_attachment):
	being_held = true
	get_parent().remove_child(self)
	bone_attachment.add_child(self)
	set_mode(RigidBody.MODE_KINEMATIC)
	$CollisionShape.disabled = true
	global_transform.basis = Basis()

func become_unequipped(new_p):
	being_held = false
	get_parent().remove_child(self)
	new_p.add_child(self)
	set_mode(RigidBody.MODE_RIGID)
	set_sleeping( false)
	$CollisionShape.disabled = false
	global_transform.basis = Basis()
	linear_velocity = Vector3()

func get_actions():
	if being_held:
		return {"drop":Vector3(90, 200, 32),"throw": Vector3(270, 200, 64)}
	else:
		return {"hold":Vector3(90, 200, 32),"kick":Vector3(270,300,120) }