extends Spatial

export(bool) var active = false 
export(String) var bone_name = ""
export(NodePath) var skeleton = ".."

var accum =0 

func _ready():
	set_process(true)

func _process(delta):
	if active:
		bone_look_at(bone_name)

func bone_look_at(bone_name):
	var ik_t  = get_transform()
	var bone  = get_node(skeleton).find_bone(bone_name)
	var bone_t= get_node(skeleton).get_bone_transform(bone)
	var bone_pos = bone_t.origin
	var direction = ik_t.origin
	var rotation_t = Transform(Vector3(1,0,0), Vector3(0,1,0), Vector3(0,0,1), Vector3(0,0,1)).looking_at(direction, Vector3(0,1,0))
	var basis_rot = Quat(rotation_t.basis)
	
	get_node(skeleton).set_bone_pose(bone,Transform(basis_rot, bone_pos).orthonormalized())
	
	get_node("marker").set_transform(Transform(basis_rot, bone_pos).orthonormalized())