extends Position3D


export(bool)  var  active = false

export(String) var affected_bone = ""

var skeleton = null

var chain = []
var lengths=[]

var chain_length = 3

var move_speed = 20

var bone_base = Transform()

func _ready():
	skeleton = get_node("..")
	
	chain = get_chain()
	lengths = get_lengths()
	print(chain)
	print(lengths)
	print_chain_origins()

func get_chain():
	var tip_bone = skeleton.find_bone(affected_bone)
	var current_bone = tip_bone
	var _out = []
	for i in range(chain_length):
		_out.append(current_bone)
		current_bone = skeleton.get_bone_parent(current_bone)
	_out.invert()
	return _out

func get_lengths():
	var _out = []
	var last = skeleton.get_bone_global_pose(chain[0]).origin
	for i in range(chain.size()):
		if i + 1 == chain.size():
			_out.append(0)
			return _out
		_out.append((skeleton.get_bone_global_pose(chain[i+1]).origin - last).length())
		last = skeleton.get_bone_global_pose(chain[i+1]).origin

func print_chain_origins():
	for bone in chain:
		print(skeleton.get_bone_global_pose(bone).origin)

func ik_solve(delta, _chain):
	# Target is a tip target
	# tip = new_chain[0] = Transform( (old_tip_look_at_affector).basis, affector.origin)
	var ik = bone_base.affine_inverse() * transform
	
	var old_tip_t = Transform()
	for bone in _chain:
		old_tip_t = skeleton.get_bone_pose(bone) * old_tip_t
	
	var new_chain = [Transform(old_tip_t.looking_at(ik.origin,Vector3(0,1,0)), ik.origin)]
	
	for i in range(chain.size()-1,0,-1):
		var reverse_bone_v = (skeleton.chain[i-1].origin-chain[i].origin).normalized()
		var bone_length = lengths[i]
		
		new_chain.append(new_chain[i-1] + reverse_bone_v * bone_length)
	
	new_chain.invert()
	
	for i in range(new_chain.size()):
		skeleton.set_bone_global_pose(i, new_chain[i])
	
	