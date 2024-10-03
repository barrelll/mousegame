@tool
extends GraphNode

@onready var text: TextEdit = $MarginContainer/VBoxContainer/TextEdit
@onready var spinbox: SpinBox = $HBoxContainer/SpinBox
@onready var is_top: CheckBox = $HBoxContainer/is_top

@onready var dialogue_choice_packed_scene: PackedScene = preload(
	"res://addons/talk_tree/Graph Nodes/choice.tscn"
)
const dialogue_choice_node_name: String = "Choice_{id}"
@onready var spinbox_current_value: int = 0

const type: String = "Dialogue"


func save() -> Dictionary:
	var choice_text: Dictionary = {}
	for i in spinbox.value:
		var choice = get_child(i + 1)
		choice_text[choice.name] = choice.text

	var save_dict = {
		"filename": get_scene_file_path(),
		"node_name": name,
		"parent": get_parent().get_path(),
		"pos_x": get_position_offset().x,  # Vector2 is not supported by JSON
		"pos_y": get_position_offset().y,
		"size.x": size.x,
		"size.y": size.y,
		"text": get_text(),
		"is_top": is_top.button_pressed,
		"choice_count": spinbox.value,
		"choice_text": choice_text
	}
	return save_dict


func load_data(data: Variant) -> void:
	set_position_offset(Vector2(data["pos_x"], data["pos_y"]))
	set_text(data["text"])
	is_top.button_pressed = data["is_top"]
	spinbox.value = data["choice_count"]
	for key in data["choice_text"].keys():
		find_child(key, false, false).text = data["choice_text"][key]


func get_text() -> String:
	return text.get_text()


func set_text(t: String):
	text.set_text(t)


func _on_spin_box_value_changed(value: float) -> void:
	set_slot_enabled_right(0, value < 1)
	if value > spinbox_current_value:
		for i in value - spinbox_current_value:
			add_choice(spinbox_current_value + i + 1)
	elif value < spinbox_current_value:
		for i in spinbox_current_value - value:
			remove_choice(spinbox_current_value - i)
	spinbox_current_value = value


func add_choice(value: float) -> void:
	# add the dialogue choice
	var dialogue_choice = dialogue_choice_packed_scene.instantiate()
	dialogue_choice.name = dialogue_choice_node_name.format(
		{"id": value}
	)
	add_child(dialogue_choice)
	move_child(dialogue_choice, value)
	# set the slot right as active for that slot...
	set_slot_enabled_right(value, true)


func remove_choice(value: float) -> void:
	set_slot_enabled_right(value, false)
	get_child(value).queue_free()


func _on_is_top_toggled(toggled_on: bool) -> void:
	set_slot_enabled_left(0, !toggled_on)


func export() -> Dictionary:
	var choices = collect_choices()
	var export_dict = {
		"name": name,
		"text": text.text,
		"type": type,
		"jump_to": "NA",
		"choices": choices,
		"default": is_top.button_pressed
	}
	return export_dict


func collect_choices() -> Array:
	var choices_list: Array = []
	for node in get_children():
		var choice_dict = {}
		if node is LineEdit:
			choice_dict["id"] = node.get_index() - 1
			choice_dict["text"] = node.get_text()
			choices_list.push_back(choice_dict)
	return choices_list
