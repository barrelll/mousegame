extends Node

var game_state_path: String = "res://initial_game_state.res"
var game_state : Dictionary = {}


func load_initial_state() -> void:
	var initial_game_state = load(game_state_path)
	var res: Dictionary = {}
	for key in initial_game_state:
		res[key] = {}
		for key1 in initial_game_state[key]:
			res[key][key1] = {}
			for key2 in initial_game_state[key][key1]:
				res[key][key1][key2] = {}
				for key3 in initial_game_state[key][key1][key2]:
					res[key][key1][key2][key3] = initial_game_state[key][key1][key2][key3]
	game_state = res
