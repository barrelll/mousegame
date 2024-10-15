@tool
@icon(
	"res://addons/talk_tree/icons/export_notes_24dp_5F6368_FILL0_wght400_GRAD0_opsz24.svg"
)
extends Node
class_name Exporter

@export var export_save_path: String = "res://initial_game_state.res"
@export var exported_packed_data: PackedDataContainer


func export() -> void:
	var export_data = read_save_file()
	print(export_data)
	exported_packed_data.pack(export_data)
	export_global_vars()
	ResourceSaver.save(exported_packed_data, export_save_path)


func export_global_vars() -> void:
	var path = "res://global_vars.txt"
	var save_file = TalkTreeGlobals.load_save_file()
	var export_save_file = FileAccess.open(
			path, FileAccess.WRITE
		)
	for global_var in save_file["Global_Vars"]:
		var val = save_file["Global_Vars"][global_var]
		var line = "var %s: bool = %s" % [global_var, val]
		export_save_file.store_line(line)
		export_save_file.seek_end()
	export_save_file.close()


func read_save_file() -> Dictionary:
	var ret_dict = {}
	var save_file = TalkTreeGlobals.load_save_file()
	for character in save_file["Characters"]:
		ret_dict[character] = read_characters(
			save_file["Characters"][character]
		)
	return ret_dict


func read_characters(character: Dictionary) -> Dictionary:
	var ret_dict = {}
	for context in character:
		ret_dict[context] = read_character_contexts(character[context])
	return ret_dict


func read_character_contexts(context: Dictionary) -> Dictionary:
	var ret_dict = {}
	var connections = context["connections"]
	var nodes = context["nodes"]
	for node in nodes:
		ret_dict[node.node_name] = node(
			node, get_connections_for_node(node, connections)
		)
	return ret_dict


func get_connections_for_node(
	node: Dictionary, connections: Array
) -> Array:
	var ret_array = []
	for conn in connections:
		# if the from node is the name of the node
		# then this connection belongs to that node
		if conn.from_node == node.node_name:
			ret_array.push_back(conn)
	return ret_array


func node(node: Dictionary, connections: Array) -> Dictionary:
	match node.type:
		"Dialogue":
			return dialogue_node(node, connections)
		"Action":
			return action_node(node, connections)
		"Condition":
			return condition_node(node, connections)
		_:
			printerr("Node not recognized... %s" % node)
			return {}


func dialogue_node(node: Dictionary, connections: Array) -> Dictionary:
	var ret_dict = {
		"id": node.node_name,
		"type": "Dialogue",
		"text": node.text,
		"is_root": node.is_top,
		"jump_to": "N/A",
		"choices": {}
	}

	if connections.size() == 0:
		printerr("There are no connections on node: %s" % node.node_name)
		return ret_dict

	# if we have choices we want to loop through them
	# and add the correct jump_to's
	if node["choice_count"] > 0:
		var i = 0
		for conn in connections:
			var choice = {"jump_to": conn.to_node}
			ret_dict["choices"][i] = choice
			i += 1
	# else we want to just change the base jump_to
	else:
		ret_dict["jump_to"] = connections[0].to_node
	return ret_dict


func action_node(node: Dictionary, connections: Array) -> Dictionary:
	var ret_dict = {
		"id": node.node_name,
		"type": "Action",
		"jump_to": "N/A",
		"action": node.text
	}

	if connections.size() == 0:
		printerr("There are no connections on node: %s" % node.node_name)
		return ret_dict

	ret_dict["jump_to"] = connections[0].to_node
	return ret_dict


func condition_node(node: Dictionary, connections: Array) -> Dictionary:
	var ret_dict = {
		"id": node.node_name,
		"type": "Condition",
		"is_root": node.is_top,
		"if": {},
		"else": {}
	}
	# set connections
	ret_dict["if"]["jump_to"] = connections[0].to_node
	ret_dict["else"]["jump_to"] = connections[1].to_node
	ret_dict["if"]["conditions"] = get_conditions(node)
	return ret_dict


func get_conditions(node: Dictionary) -> Array:
	var ret_array = []
	var selected_right = get_selected_right(node["if_condition"])

	# this node should always have at least one if condition
	var if_condition = {
		"left_selected": "if",
		"global_var_name": node["if_condition"]["left"],
		"right_selected": selected_right
	}
	ret_array.push_back(if_condition)
	for cond in node["conditions"]:
		var condition = {
			"left_selected": get_selected_left(node["conditions"][cond]),
			"global_var_name": node["if_condition"]["left"],
			"right_selected": get_selected_right(node["conditions"][cond])
		}
		ret_array.push_back(condition)
	return ret_array


func get_selected_left(data: Dictionary) -> String:
	if data["selected_type"] == 0:
		return "and"
	else:
		return "or"


func get_selected_right(data: Dictionary) -> bool:
	if data["selected_right"] == 0:
		return false
	else:
		return true


func _on_talk_tree_export() -> void:
	export()


func _on_export_pressed() -> void:
	export()
