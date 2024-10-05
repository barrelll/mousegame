@tool
extends Node

const save_path: String = "res://addons/talk_tree/Save/initial_game_state.json"
var save_dict: Dictionary = {"Characters": {}, "Global_Vars": {}}

signal updated

func load_save_file() -> Dictionary:
	if not FileAccess.file_exists(TalkTreeGlobals.save_path):
		printerr(
			(
				"Err: Save file does not exist, returning save_dict: %s"
				% TalkTreeGlobals.save_dict
			)
		)
		return TalkTreeGlobals.save_dict  # Error! We don't have a save to load.

	# Load the file line by line and process that dictionary to restore
	# the object it represents.
	var save_file = FileAccess.open(
		TalkTreeGlobals.save_path, FileAccess.READ
	)
	while save_file.get_position() < save_file.get_length():
		var json_string = save_file.get_line()

		# Creates the helper class to interact with JSON.
		var json = JSON.new()

		# Check if there is any error while parsing the JSON string, skip in case of failure.
		var parse_result = json.parse(json_string)
		if not parse_result == OK:
			printerr(
				"JSON Parse Error: ",
				json.get_error_message(),
				" in ",
				json_string,
				" at line ",
				json.get_error_line()
			)
			continue

		return json.data
	printerr(
		"Something went wrong while loading @load_save_dict, returning save_dict: %s",
		%TalkTreeGlobals.save_dict
	)
	return TalkTreeGlobals.save_dict
