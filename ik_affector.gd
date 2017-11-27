extends Position3D

export(String) var bone = "root"
export (int, 0, 10) var chain_length = 2
var sk = null

var lengths = []

var chain = []

func _ready():
	sk = get_node("..")
	chain = init_ids()
	lengths = init_lengths(chain)

func init_ids():
	var out = []
	
	var b = sk.find_bone(bone)
	
	if b == -1:
		ik_error("Affected bone not found in skeleton")
		return
	
	var i = chain_length
	while i > 0 and b!= -1:
		i-=1
		out.append(b)
		b = sk.get_bone_parent(b)
	
	return out

func init_lengths(_ids):
	var b = _ids[0]
	var out = [0]
	for i in range(_ids.size()):
		if i == 0:
			continue
		
		var l = (sk.get_bone_global_pose(b).origin -sk.get_bone_global_pose(_ids[i]).origin).length()
		b = _ids[i]
		out.append(l)
	
	return out

func solve(delta):
	##IK
	
	var new_chain = []
	# Hand IK
	var old_t = sk.get_bone_global_pose(chain[0])
	var target_v = transform.origin - old_t.origin
	
	if target_v.length() < 0.1:
		return
	
	
	var bone_v = sk.get_bone_global_pose(chain[1]).basis[2]
	var axis = target_v.cross(bone_v)
	if axis.length() == 0:
		return
	var target_look_t = old_t
	var new_t = Transform(target_look_t.basis, transform.origin)
	
	new_chain.append(new_t)
	
	# Forearm IK
	
	old_t = sk.get_bone_global_pose(chain[1])
	target_v = new_t.origin - old_t.origin
	bone_v = old_t.basis[2]
	axis = target_v.cross(bone_v)
	if axis.length() == 0:
		return
	target_look_t = old_t.looking_at(new_t.origin, axis)
	var target_origin = new_t.origin + target_look_t.basis[2] * lengths[1]
	new_t = Transform(target_look_t.basis, target_origin)
	
	new_chain.append(new_t)
	
	# Bicep IK
	
	old_t = sk.get_bone_global_pose(chain[2])
	target_v = new_t.origin - old_t.origin
	bone_v = old_t.basis[2]
	axis = target_v.cross(bone_v)
	if axis.length() == 0:
		return
	target_look_t = old_t.looking_at(new_t.origin, axis)
	target_origin = new_t.origin + target_look_t.basis[2] * lengths[2]
	new_t = Transform(target_look_t.basis, target_origin)
	
	new_chain.append(new_t)
	
	## FK
	
	# Bicep FK
	old_t = sk.get_bone_global_pose(chain[2])
	target_v = new_chain[1].origin - old_t.origin
	bone_v = old_t.basis[2]
	var bicep_look_at =  old_t.looking_at(new_chain[1].origin, old_t.basis[1])
	var bicep_t = Transform(bicep_look_at.basis, old_t.origin)
	
	# Forearm FK
	var base_t = bicep_t.origin - bicep_look_at.basis * Vector3(0,0,lengths[2])
	var forearm_t = Transform(Basis(), base_t)
	target_v = new_chain[0].origin - base_t
	bone_v = new_chain[0].origin - new_chain[1].origin
	var forearm_look_at = forearm_t.looking_at(new_chain[0].origin, sk.get_bone_global_pose(chain[1]).basis[1])
	forearm_t.basis = forearm_look_at.basis
	
	# Hand FK
	old_t = sk.get_bone_global_pose(chain[0])
	base_t = forearm_t.origin - forearm_look_at.basis * Vector3(0,0,lengths[1])
	target_v = transform.origin - base_t
	bone_v = forearm_look_at.basis[2]
	var hand_t = Transform(old_t.basis, base_t)
	
	var final_chain = [hand_t, forearm_t, bicep_t]
	sk.set_bone_global_pose(chain[2], final_chain[2])
	sk.set_bone_global_pose(chain[1], final_chain[1])
	sk.set_bone_global_pose(chain[0], final_chain[0])

func ik_error(output):
	print("IK ERROR: ", output)
