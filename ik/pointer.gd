extends Spatial

# class member variables go here, for example:
# var a = 2
# var b = "textvar"


var affector = Transform()

func _ready():
	set_process(true)
func _process(delta):
	affector = get_node("../affector").global_transform
	if get_name().ends_with("1"):
		var a_inv = transform.affine_inverse()
		var p_dir =affector 
		
		var new_t = (a_inv * transform).looking_at(p_dir.origin, Vector3(0,1,0))
		
		var to_move = p_dir.origin - (p_dir.origin.normalized() * get_node("tip").transform.origin.length())
		print("moving:", to_move)
		transform = Transform(new_t.basis, translation)
		
	if get_name().ends_with("2"):
		var a_inv = transform.affine_inverse()
		var p_dir = get_node("../pointer1").transform
		
		var new_t = (a_inv * transform).looking_at(p_dir.origin, Vector3(0,1,0))
		
		transform = new_t