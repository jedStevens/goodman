tool
extends GridMap

var Peak = preload("res://peak.tscn")

var chunk_timer=1.0
var chunk_delay=0.2

var flood_points=[[]]

# North 0,0,-1
# East 1,0,0
# South 0,0,1
# West -1,0,0
enum DIRECITIONS {NORTH=0,EAST=22,SOUTH=10,WEST=16}
const DMAP = [NORTH, EAST, SOUTH, WEST]

export(String, "NONE", "Clear","Create Chunk","Generate") var command = "NONE" setget action

func action(a):
	if a == "Clear":
		clear()
	elif a == "Create Chunk":
		flood(0, 7)
	elif a == "Generate":
		generate()

func clear_and_generate():
	clear()
	
	call_deferred("generate")

func generate():
	seed(OS.get_ticks_msec())
	var running = true
	var levels = 20
	flood_points = []
	for i in range(levels*2):
		flood_points.append([])
	set_as_flood_point(0,0,0)
	var b = 4
	var i = 0
	for l in range(levels):
		i = 0
		if l % 3 == 0:
			b = 6
		else:
			b=4
		while i < b:
			flood(l,(13-l)*5)
			i+=1
		clean(l)

func clean(level=0):
	
	for point in flood_points[level]:
		set_cell_item(point.x, point.y, point.z, -1)
	
	flood_points[level] = []


func flood(level=-1, area=-1):
	if area == -1:
		area = get_node("debug/flood_points/area/HSlider").value
	if level==-1:
		level = get_node("debug/flood_points/level/HSlider").value
	
	if flood_points[level].size() == 0:
		level = get_node("debug/flood_points/level/HSlider").set_value(get_node("debug/flood_points/level/HSlider").value+1)
		print("No flood points on this layer")
		return
	
	var i = int(flood_points[level].size() * randf())
	
	var p = flood_points[level][i]
	flood_points[level].erase(p)
	var a = 0
	var cells=[]
	var open_cells = [p]
	var flood_dirs = [Vector3(-1,0,0),Vector3(1,0,0),Vector3(0,0,1),Vector3(0,0,-1)]
	var neighbors = []
	
	set_cell_item(p.x,p.y,p.z,0)
	
	set_cell_item(p.x,p.y+1,p.z,2,get_parent_direction(p))
	
	while cells.size() + open_cells.size() < area and open_cells.size() > 0:
		# Fill a given area with cells
		var to_add   = []
		var to_remove= []
		for c in open_cells:
			# For each cell get its neighbors
			var can_close =true
			for d in flood_dirs:
				var new_c = c+d
				if not new_c in cells and not new_c in open_cells and not has_cell_above(new_c):
					to_add.append(c+d)
					can_close = false
			if can_close:
				to_remove.append(c)
		
		for c in to_remove:
			open_cells.erase(c)
			cells.append(c)
			
		
		var added = 0
		for x in to_add:
			if get_cell_item(x.x, -level, x.z) < 0 or get_cell_item(x.x,-level,x.z) == 9:
				var cell = Vector3(x.x, -level, x.z)
				if not cell in cells and not cell in open_cells:
					open_cells.append(cell)
					added += 1
				
					set_cell_item(x.x, -level, x.z, 0)
			if cells.size() + open_cells.size() >= area or open_cells.size() == 0:
				break
		if added == 0:
			return
	
		
	for cell in open_cells:
		cells.append(cell)
	
	if cells.size() < area:
		for cell in cells:
			set_cell_item(cell.x,cell.y,cell.z,-1)
		return
	for cell in cells:
		set_flood_points_for(cell)
	
	var remove_list = []
	for point in flood_points[level]:
		if get_cell_item(point.x, point.y, point.z) != 9:
			remove_list.append(point)
	
	for point in remove_list:
		flood_points[level].erase(point)
	
	for i in range(level, flood_points.size()):
		remove_list = []
		for point in flood_points[i]:
			if has_cell_above(point):
				remove_list.append(point)
		
		for point in remove_list:
			flood_points[level].erase(point)

func print_flood_points():
	return
	print("--- Flood Points ---")
	for p in flood_points:
		print(p)
	print("--------------------")

func get_parent_direction(cell):
	var dirs = [Vector3(0,1,-1),Vector3(1,1,0),Vector3(0,1,1),Vector3(-1,1,0)]
	
	for d in dirs:
		var fp = d+cell
		if get_cell_item(fp.x,fp.y,fp.z) == 0:
			return DMAP[dirs.find(d)]
	return false

func set_flood_points_for(cell):
	var dirs = [Vector3(-1,-1,0),Vector3(1,-1,0),Vector3(0,-1,1),Vector3(0,-1,-1)]
	var rdirs = []
	rdirs.append(dirs[randi() % dirs.size()])
	rdirs.append(dirs[randi() % dirs.size()])
	for d in rdirs:
		var fp = d+cell
		set_as_flood_point(fp.x,fp.y,fp.z)

func set_as_flood_point(x,y,z,wall_depth=20):
	if flood_points.size() <= -y:
		for i in range(-y-flood_points.size()+1):
			flood_points.append([])

	var p = Vector3(x,y,z)
	
	if has_cell_above(p):
		return
	
	if not (p in flood_points[-y]):
		flood_points[-y].append(p)
		set_cell_item(x,y,z,9)
	
	for h in range(1,wall_depth):
		set_cell_item(x,y-h,z,7)

func has_cell_above(cell, search_height=30):
	for h in range(1,search_height):
		if get_cell_item(cell.x,cell.y+h,cell.z) >= 0:
			return true
	return false
func has_cell_below(cell, search_height=30):
	for h in range(1,search_height):
		if get_cell_item(cell.x,cell.y-h,cell.z) >= 0:
			return true
	return false

func calculate_flooding_points():
	pass

func empty_map():
	clear()
	flood_points = []
	set_as_flood_point(0,0,0)
	print("Reset Flood Points", flood_points)


func create_chunk():
	flood()