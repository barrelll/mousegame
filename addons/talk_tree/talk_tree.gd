@tool
extends GraphEdit

@export var character_name: String = ""
@export var context: String = ""
@onready var right_click_context_menu: PopupMenu = $PopupMenu
@onready var dialogue_packed_scene: PackedScene = preload(
	"res://addons/talk_tree/Graph Nodes/dialogue_graph_node.tscn"
)
@onready var action_packed_scene: PackedScene = preload(
	"res://addons/talk_tree/Graph Nodes/action_graph_node.tscn"
)
@onready var condition_packed_scene: PackedScene = preload(
	"res://addons/talk_tree/Graph Nodes/condition_graph_node.tscn"
)
var node_id: int = 0

signal save
signal export


func _ready() -> void:
	right_click_context_menu.clear(true)
	right_click_context_menu.add_submenu_node_item(
		"Add Node", $PopupMenu/Add_Node_Popup_Submenu, 0
	)
	right_click_context_menu.add_item("Export", 1)
	right_click_context_menu.add_separator()
	right_click_context_menu.add_item("Save", 2)
	add_valid_right_disconnect_type(0)


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
		save.emit()


func _on_add_node_popup_submenu_id_pressed(id: int) -> void:
	match id:
		0:
			var node: GraphNode = dialogue_packed_scene.instantiate()
			node.set_position_offset(
				(get_local_mouse_position() + scroll_offset) / zoom
			)
			node.add_to_group("Persist")
			node.id = node_id
			node.set_name("Dialogue_Node_{id}".format({"id": node_id}))
			node_id += 1
			add_child(node)
		1:
			var node: GraphNode = action_packed_scene.instantiate()
			node.set_position_offset(
				(get_local_mouse_position() + scroll_offset) / zoom
			)
			node.add_to_group("Persist")
			node.id = node_id
			node.set_name("Action_Node_{id}".format({"id": node_id}))
			node_id += 1
			add_child(node)
		2:
			var node: GraphNode = condition_packed_scene.instantiate()
			node.set_position_offset(
				(get_local_mouse_position() + scroll_offset) / zoom
			)
			node.add_to_group("Persist")
			node.id = node_id
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


func save_character_context() -> Dictionary:
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
	return save_data


func clear_all() -> bool:
	clear_connections()
	for child in get_children():
		if child.is_in_group("Persist"):
			child.queue_free()
			await child.tree_exited
	return true


func load_character_context(data: Dictionary) -> void:
	#always set the node_id back to 0 if we have one we'll set it back up later
	node_id = 0
	# Get the data from the JSON object
	if not data.has(character_name):
		printerr("Character name: %s not in save data" % character_name)
		return

	if not data[character_name].has(context):
		printerr("Context: %s not in save data" % context)
		return

	var node_data = data[character_name][context]
	node_id = node_data["id"]
	# Firstly, we need to create the object and add it to the tree and set its position.
	for object in node_data["nodes"]:
		var new_object = load(object["filename"]).instantiate()
		get_node(object["parent"]).add_child(new_object)
		new_object.name = object["node_name"]
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
	var i = 0
	for object in node_data["connections"]:
		connect_node(
			object["from_node"],
			object["from_port"],
			object["to_node"],
			object["to_port"]
		)


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
			export.emit()
		2:
			save.emit()
		_:
			pass
