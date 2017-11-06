extends Node2D

var active = false

var start_pos = Vector2(0,0)
var drag = Vector2(0,0)

func _ready():
	set_process(true)

func _process(delta):
	active = Input.is_action_pressed("player_action_left")
	
	if active:
		if Input.is_action_just_pressed("player_action_left"):
			start_pos = get_viewport().get_mouse_position()
		
		drag = get_viewport().get_mouse_position() - start_pos
	
	else:
		drag = Vector2(0,0)
	
	update()

func set_on_screen(v):
	start_pos = v

func _draw():
	draw_circle(start_pos, drag.length(), Color(0.8,0.8,0.8,0.2))
	draw_circle(start_pos, 6 if drag.length() > 0 else 0, Color(0.2,0.2,0.2,0.4))
	draw_line(start_pos, start_pos + drag, Color(1,1,1,1), 1.4, true)