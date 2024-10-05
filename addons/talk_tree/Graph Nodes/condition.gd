@tool
extends HBoxContainer

@onready var left : LineEdit = $Left

func save() -> Dictionary:
	return {
		"selected_type": $Type.selected,
		"left": $Left.text,
		"selected_right": $Right.selected
	}


func load_data(data: Dictionary) -> void:
	$Type.selected = data["selected_type"]
	$Left.text = data["left"]
	$Right.selected = data["selected_right"]
