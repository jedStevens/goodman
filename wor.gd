extends Node

const SETTINGS_PATH = "user://settings.wor"

var settings = {}

var music_volume = 0.0

signal music_volume_changed

func load_settings():
	# Returns any changes saved
	var g_settings = File.new()
	if !g_settings.file_exists("user://settings.wor"):
		return {}
	
	g_settings.open("user://settings.wor", File.READ)
	
	var current_line = {}
	
	current_line = parse_json(g_settings.get_line())
	while (!g_settings.eof_reached()):
		if "music_vol" in current_line.keys():
			set_music_vol(float(current_line["music_vol"]))
			emit_signal("music_volume_changed")
		print("Current Line: ", current_line)
		current_line = parse_json(g_settings.get_line())
	
	g_settings.close()

func get_music_vol_as_db():
	return float2db(music_volume)

func set_music_vol_as_db(v):
	set_music_vol(db2float(v))

func set_music_vol(v):
	music_volume = v
	settings["music_vol"] = music_volume
	write_settings()
	emit_signal("music_volume_changed")

func write_settings():
	var g_settings = File.new()
	g_settings.open("user://settings.wor", File.WRITE)
	g_settings.store_line(to_json(settings))
	g_settings.close()

func get_music_vol():
	return music_volume

func float2db(v):
	return 80 * v - 80

func db2float(v):
	return (v + 80) / 80