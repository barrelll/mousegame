@tool
extends GraphEdit

const save_path: String = "res://addons/talk_tree/Save/savegame.save"
@export var export_save_path: String = "res://game_state.res"
@export var exported_packed_data: PackedDataContainer
@onready var right_click_context_menu: PopupMenu = $PopupMenu
@onready var dialogue_packed_scene: PackedScene = preload(
	"res://addons/talk_tree/Graph Nodes/dialogue_graph_node.tscn"
)
@onready var action_packed_scene: PackedScene = preload(
	"res://addons/talk_tree/Graph Nodes/action_graph_node.tscn"
)
@onready var condition_packed_scene: PackedScene = preload(
	"res://addons/talk_tree/Graph Nodes/local_condition_graph_node.tscn"
)
var node_id: int = 0


func _ready() -> void:
	right_click_context_menu.add_submenu_node_item(
		"Add Node", $PopupMenu/Add_Node_Popup_Submenu, 0
	)
	right_click_context_menu.add_item("Export", 1)
	right_click_context_menu.add_separator()
	right_click_context_menu.add_item("Save", 2)
	add_valid_right_disconnect_type(0)
	_load()


func _gui_input(event: InputEvent) -> void:
	if (
		event is InputEventMouseButton
		and event.button_index == MOUSE_BUTTON_RIGHT
	):
		var mouse_position = get_global_mouse_position()
		right_click_context_menu.popup(
			Rect2i(
				mouse_position.x,
				mouse_position.y,
				right_click_context_menu.size.x,
				0
			)
		)
	if event.is_action_pressed("ui_filedialog_refresh"):
		_save()


func _on_add_node_popup_submenu_id_pressed(id: int) -> void:
	match id:
		0:
			var node: GraphNode = dialogue_packed_scene.instantiate()
			node.set_position_offset(
				(get_local_mouse_position() + scroll_offset) / zoom
			)
			node.add_to_group("Persist")
			node.set_name("Dialogue_Node_{id}".format({"id": node_id}))
			node_id += 1
			add_child(node)
		1:
			var node: GraphNode = action_packed_scene.instantiate()
			node.set_position_offset(
				(get_local_mouse_position() + scroll_offset) / zoom
			)
			node.add_to_group("Persist")
			node.set_name("Action_Node_{id}".format({"id": node_id}))
			node_id += 1
			add_child(node)
		2:
			var node: GraphNode = condition_packed_scene.instantiate()
			node.set_position_offset(
				(get_local_mouse_position() + scroll_offset) / zoom
			)
			node.add_to_group("Persist")
			node.set_name("Condition_Node_{id}".format({"id": node_id}))
			node_id += 1
			add_child(node)
		_:
			pass


func _on_connection_request(
	from_node: StringName,
	from_port: int,
	to_node: StringName,
	to_port: int
) -> void:
	connect_node(from_node, from_port, to_node, to_port)


func _on_delete_nodes_request(nodes: Array[StringName]) -> void:
	for child in get_children():
		if child is GraphNode and child.is_selected():
			child.queue_free()


func _save() -> void:
	var save_file = FileAccess.open(save_path, FileAccess.WRITE)
	var save_data: Dictionary = {}
	var node_data: Array = []
	for node in get_tree().get_nodes_in_group("Persist"):
		# Check the node is an instanced scene so it can be instanced again during load.
		if node.scene_file_path.is_empty():
			print(
				(
					"persistent node '%s' is not an instanced scene, skipped"
					% node.name
				)
			)
			continue

		# Check the node has a save function.
		if !node.has_method("save"):
			print(
				(
					"persistent node '%s' is missing a save() function, skipped"
					% node.name
				)
			)
			continue
		# call the nodes save function
		node_data.push_back(node.call("save"))

	save_data["id"] = node_id
	save_data["nodes"] = node_data
	save_data["connections"] = get_connection_list()
	save_file.store_line(JSON.stringify(save_data))
	save_file.close()


func _load() -> void:
	if not FileAccess.file_exists(save_path):
		return  # Error! We don't have a save to load.

	var save_file = FileAccess.open(save_path, FileAccess.READ)
	while save_file.get_position() < save_file.get_length():
		var json_string = save_file.get_line()

		# Creates the helper class to interact with JSON
		var json = JSON.new()

		# Check if there is any error while parsing the JSON string, skip in case of failure
		var parse_result = json.parse(json_string)
		if not parse_result == OK:
			print(
				"JSON Parse Error: ",
				json.get_error_message(),
				" in ",
				json_string,
				" at line ",
				json.get_error_line()
			)
			continue

		# Get the data from the JSON object
		var node_data = json.get_data()
		node_id = node_data["id"]
		# Firstly, we need to create the object and add it to the tree and set its position.
		for object in node_data["nodes"]:
			var new_object = load(object["filename"]).instantiate()
			new_object.name = object["node_name"]
			get_node(object["parent"]).add_child(new_object)
			new_object.add_to_group("Persist")
			if !new_object.has_method("load_data"):
				print(
					(
						"persistent node '%s' is missing a load_data() function, skipped"
						% new_object.name
					)
				)
				continue
			new_object.load_data(object)

		for object in node_data["connections"]:
			connect_node(
				object["from_node"],
				object["from_port"],
				object["to_node"],
				object["to_port"]
			)


func _on_timer_timeout() -> void:
	_save()


func _on_disconnection_request(
	from_node: StringName,
	from_port: int,
	to_node: StringName,
	to_port: int
) -> void:
	disconnect_node(from_node, from_port, to_node, to_port)


func _on_popup_menu_id_pressed(id: int) -> void:
	match id:
		1:
			_export()
		2:
			_save()
		_:
			pass


func _export() -> void:
	var data: Dictionary = {}
	data["First Blind Mouse"] = collect_nodes_for_character(
		"First Blind Mouse"
	)
	data["First Blind Mouse"] = sort_choice_jumps(
		data["First Blind Mouse"]
	)
	exported_packed_data.pack(data)
	print(data)
	ResourceSaver.save(exported_packed_data, export_save_path)


func sort_choice_jumps(data: Array) -> Array:
	var ret = data
	for i in ret.size():
		var node = ret[i]
		if "choices" in node and node["choices"].size() > 0:
			for choice in node["choices"]:
				var jump_to = choice["jump_to"]
				for j in ret.size():
					if ret[j]["name"] == jump_to:
						choice["jump_to"] = j
		else:
			var jump_to = ret[i]["jump_to"]
			for j in ret.size():
				if ret[j]["name"] == jump_to:
					ret[i]["jump_to"] = j
	return ret


func collect_nodes_for_character(character_name: String) -> Array:
	var data: Array = []
	for node in get_tree().get_nodes_in_group("Persist"):
		if !node.has_method("export"):
			print(
				(
					"persistent node '%s' is missing a export() function, skipped"
					% node.name
				)
			)
			continue
		var export_data = node.call("export")
		if node.type == "Dialogue":
			export_data = dialogue_export(export_data)
			data.push_back(export_data)
		elif node.type == "Action":
			export_data = action_export(export_data)
			data.push_back(export_data)
	return data


func dialogue_export(export_data: Dictionary) -> Dictionary:
	var connections = get_connections(export_data["name"])
	if export_data["choices"].size() > 0:
		for choice in export_data["choices"]:
			for conn in connections:
				if choice["id"] == conn["from_port"]:
					choice["jump_to"] = conn["to_node"]
	else:
		if connections.size() > 1:
			printerr(
				"How did we get here? It's not possible to add mutliple connections without choices..."
			)
		elif connections.size() == 0:
			printerr("No connection for Node %s" % export_data["name"])
		else:
			for conn in connections:
				export_data["jump_to"] = conn["to_node"]
	return export_data


func action_export(export_data: Dictionary) -> Dictionary:
	var connections = get_connections(export_data["name"])
	if connections.size() > 1:
		printerr(
			"How did we get here? It's not possible to add mutliple connections without choices..."
		)
	elif connections.size() == 0:
		printerr("No connection for Node %s" % export_data["name"])
	else:
		for conn in connections:
			export_data["jump_to"] = conn["to_node"]
	return export_data


func get_connections(name: String) -> Array:
	var conn_list: Array = []
	for conn in get_connection_list():
		if name == conn["from_node"]:
			conn_list.push_back(conn)
	return conn_list
