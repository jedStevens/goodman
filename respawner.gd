extends RigidBody

# class member variables go here, for example:
# var a = 2
# var b = "textvar"

func _ready():
	# Called every time the node is added to the scene.
	# Initialization here
	set_fixed_process(true)

func _fixed_process(delta):
	for b in get_colliding_bodies():
		print(b.get_name())
		if b.is_in_group("player"):
			respawn(b)

func respawn(player):
	player.translation = get_node("spawns/diving_board").translation