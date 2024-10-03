@tool
extends GraphNode

const type: String = "Action"


func save() -> Dictionary:
	var save_dict = {
		"filename": get_scene_file_path(),
		"node_name": name,
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
	$LineEdit.set_text(data["text"])


func export() -> Dictionary:
	var export_dict = {
		"name": name,
		"text": $LineEdit.get_text(),
		"type": type,
		"jump_to": "NA",
	}
	return export_dict
