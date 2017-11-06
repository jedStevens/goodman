tool
extends Position3D

# class member variables go here, for example:
# var a = 2
# var b = "textvar"

var node = ""

export(int) var iterations = 24

export(bool) var place_sums = false

var chain = ["../limb2", "../limb"]

func _ready():
	node = "../limb2"

func _process(delta):
	var sum = Vector3(0,0,0)
	var o_chain = []
	for bone in chain:
		bone_look_at(bone, sum)
		o_chain.append(get_node(bone).get_transform())
		sum = Vector3(0,0,0)
		for b in o_chain:
			sum += b.xform(Vector3(0,0,-5))

func bone_look_at(bone_name, last_bone_pos):
	
	var lookat = Transform()
	lookat.origin = last_bone_pos
	lookat = lookat.looking_at(global_transform.origin, Vector3(0,1,0))
	get_node(bone_name).set_transform(lookat)
	
#	var t = get_node(bone_name).get_transform()
#	var offset = sum.origin
#	var direction = global_transform.origin-sum.origin
#	t.origin = sum.origin
#	t = t.looking_at(direction, Vector3(0,1,0))
#	t.origin = sum.xform(Vector3(0,0,-5)) 
#	get_node(bone_name).set_transform(t)

func place_sum(sum):
	print(sum)