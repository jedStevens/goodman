extends Container

# class member variables go here, for example:
# var a = 2
# var b = "textvar"

func _ready():
	wor.connect("music_volume_changed", self, "set_music_vol")
	get_viewport().connect("size_changed", self, "resize")
	resize()
	
	wor.load_settings()

func resize():
	var s = get_viewport().size
	margin_right = s.x
	margin_bottom = s.y


func set_music_vol():
	var music_bus = AudioServer.get_bus_index("Music")
	AudioServer.set_bus_volume_db(music_bus,wor.float2db(wor.music_volume))
	$tabs/settings/music_volume/slider.value = wor.music_volume


func _on_music_volume_value_changed( value ):
	wor.set_music_vol(value)
	print("new volume F: ", value)


func _on_solo_pressed():
	$tabs.current_tab = 1

func _on_fighters_pressed():
	$tabs.current_tab = 2

func _on_settings_pressed():
	$tabs.current_tab = 3

func _on_back_pressed():
	$tabs.current_tab = 0