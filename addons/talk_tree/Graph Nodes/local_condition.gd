@tool
extends HBoxContainer


func save() -> Dictionary:
	return {
		"selected_type": $Type.selected,
		"right": $Right.text,
		"selected_left": $Left.selected
	}


func _load(data: Dictionary) -> void:
	$Type.selected = data["selected_type"]
	$Right.text = data["right"]
	$Left.selected = data["selected_left"]
