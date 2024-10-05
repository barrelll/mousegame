@tool
extends GraphNode

const type: String = "Action"
var id = 0


func save() -> Dictionary:
	var save_dict = {
		"filename": get_scene_file_path(),
		"node_name": "Action_Node_{id}".format({"id": id}),
		"id": id,
		"type": type,
		"parent": get_parent().get_path(),
		"pos_x": get_position_offset().x,  # Vector2 is not supported by JSON
		"pos_y": get_position_offset().y,
		"size.x": size.x,
		"size.y": size.y,
		"text": $LineEdit.get_text(),
	}
	return save_dict


func load_data(data: Variant) -> void:
	set_position_offset(Vector2(data["pos_x"], data["pos_y"]))
	size.x = data["size.x"]
	size.y = data["size.y"]
	id = data["id"]
	$LineEdit.set_text(data["text"])
