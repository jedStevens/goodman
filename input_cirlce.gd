extends Node2D

var active = false

var start_pos = Vector2(0,0)
var drag = Vector2(0,0)

export(String)var action = "player_action_left"

export(float) var max_drag_length = 256

var sections = {}

func set_sections(new_sections):
	sections = new_sections
	
signal action (name, v, d)
func _ready():
	set_process(true)
	set_sections({"hold":Vector3(90,200,32), "take":Vector3(180, 256, 12), "kick":Vector3(270, 300, 5)})

func set_section(name, s):
	# Expects a Vector3 describing a Pie shape in a circle
	# x = orientation angle
	# y = height of slice
	# z = radius of slice
	sections[name] = s

func _process(delta):
	active = Input.is_action_pressed(action)
	
	if active:
		if Input.is_action_just_pressed(action):
			start_pos = get_viewport().get_mouse_position()
			drag = Vector2()
		drag = get_viewport().get_mouse_position()-start_pos
		if drag.length() > max_drag_length:
			drag = drag.normalized() * max_drag_length
	elif drag != Vector2():
		for k in sections.keys():
			var s = sections[k]
			if is_in_section(s):
				emit_signal("action", k, s, drag)
		drag = Vector2(0,0)
	
	update()

func set_on_screen(v):
	start_pos = v

func _draw():
	draw_circle(start_pos, drag.length(), Color(0.8,0.8,0.8,0.05))
	draw_circle(start_pos, 6 if drag.length() > 0 else 0, Color(0.2,0.2,0.2,0.4))
	draw_line(start_pos, start_pos + drag, Color(1,1,1,1), 1.4, true)
	
	if active:
		for k in sections.keys():
			var s = sections[k]
			var l = min(s.y, drag.length())
			var b =  is_in_section(s)
			var o = max((l / s.y),0.1) if b else (0.1)
			draw_line(start_pos, start_pos + Vector2(cos(deg2rad(s.x+s.z)), sin(deg2rad(s.x+s.z))) * s.y, Color(1 if b else 0.2,0.5if b else 0.6,0,1 * o), 2.3, true)
			draw_line(start_pos, start_pos + Vector2(cos(deg2rad(s.x-s.z)), sin(deg2rad(s.x-s.z))) * s.y, Color(1 if b else 0.2,0.5if b else 0.6,0,1 * o), 2.3, true)
			var arc_segs = 12
			var gap = 2*s.z / arc_segs
			for i in range(-arc_segs/2, arc_segs/2):
				var p1 = Vector2(cos(deg2rad(s.x+i*gap)), sin(deg2rad(s.x+i*gap))) * s.y
				var p2 = Vector2(cos(deg2rad(s.x+(i+1)*gap)), sin(deg2rad(s.x+(i+1)*gap))) * s.y
				draw_line(start_pos+p1, start_pos + p2, Color(1 if b else 0.2,0.5 if b else 0.6,0,1 * o), 2.3, true)
			
	
	draw_circle(start_pos, drag.length(), Color(1,1,1,0.2))

func is_in_section(s):
	return ((drag.length() < s.y) and abs(drag.angle_to(Vector2(cos(deg2rad(s.x)), sin(deg2rad(s.x))))) < deg2rad(s.z))
	