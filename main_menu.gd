extends ColorRect

func _on_new_game_pressed() -> void:
	GameStateManager.load_initial_state()
	# resource loader will load the scene on another thread, we can use this for a 
	# load screen! hurray
	#ResourceLoader.load_threaded_request("res://Tests/test_dialogue.tscn")
	#ResourceLoader
	get_tree().change_scene_to_packed(load("res://Tests/test_dialogue.tscn"))
