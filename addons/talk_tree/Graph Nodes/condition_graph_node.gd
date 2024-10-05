@tool
extends GraphNode

@onready var condition_packed_scene: PackedScene = preload(
	"res://addons/talk_tree/Graph Nodes/condition.tscn"
)
@onready var spinbox_current_value: int = 0

const type: String = "Condition"
const condition_node_name: String = "Condition_{id}"
@onready var spinbox: SpinBox = $HBoxContainer/SpinBox
@onready var is_top: CheckBox = $HBoxContainer/is_top
var id = 0


func _ready() -> void:
	TalkTreeGlobals.updated.connect(update_err_text)
	update_err_text()


func update_err_text() -> void:
	if not TalkTreeGlobals.save_dict["Global_Vars"].has($If/Left.text):
		$ErrorText.text = (
			"Save dictionary does not have text: %s" % $If/Left.text
		)
		$ErrorText.show()
	else:
		$ErrorText.hide()

	check_conditions()


func check_conditions() -> void:
	for child in get_children():
		if child is BoxContainer:
			if child.has_method("save"):
				if not TalkTreeGlobals.save_dict["Global_Vars"].has(
					child.left.text
				):
					$ErrorText.text = (
						"Save dictionary does not have text: %s"
						% child.left.text
					)
					$ErrorText.show()
				else:
					$ErrorText.hide()


func save() -> Dictionary:
	var condition_data = {}
	for child in get_children():
		if child is BoxContainer:
			if child.has_method("save"):
				condition_data[child.name] = child.save()

	var save_dict = {
		"filename": get_scene_file_path(),
		"node_name": "Condition_Node_{id}".format({"id": id}),
		"id": id,
		"type": type,
		"parent": get_parent().get_path(),
		"pos_x": get_position_offset().x,  # Vector2 is not supported by JSON
		"pos_y": get_position_offset().y,
		"size.x": size.x,
		"size.y": size.y,
		"is_top": is_top.button_pressed,
		"if_condition": get_if_condition_data(),
		"condition_count": spinbox.value,
		"conditions": condition_data
	}
	return save_dict


func get_if_condition_data() -> Dictionary:
	return {"left": $If/Left.text, "selected_right": $If/Right.selected}


func load_if_data(data: Dictionary) -> void:
	$If/Left.text = data["left"]
	$If/Right.selected = data["selected_right"]


func load_data(data: Variant) -> void:
	set_position_offset(Vector2(data["pos_x"], data["pos_y"]))
	is_top.button_pressed = data["is_top"]
	load_if_data(data["if_condition"])
	spinbox.value = data["condition_count"]
	size.x = data["size.x"]
	size.y = data["size.y"]
	id = data["id"]
	for key in data["conditions"].keys():
		find_child(key, false, false).load_data(data["conditions"][key])


func _on_spin_box_value_changed(value: float) -> void:
	if value > spinbox_current_value:
		for i in value - spinbox_current_value:
			add_condition(spinbox_current_value + i + 1)
	elif value < spinbox_current_value:
		for i in spinbox_current_value - value:
			remove_condition(spinbox_current_value - i)
	spinbox_current_value = value


func add_condition(value: float) -> void:
	# add the dialogue choice
	var condition = condition_packed_scene.instantiate()
	condition.name = condition_node_name.format({"id": value})
	add_child(condition)
	condition.left.text_changed.connect(_on_right_text_changed)
	move_child(condition, value)
	# set the slot right as active for that slot...
	set_slot_enabled_right(value, false)
	set_slot_enabled_right(value + 1, true)


func remove_condition(value: float) -> void:
	set_slot_enabled_right(value, true)
	set_slot_enabled_right(value + 1, false)
	get_child(value).queue_free()


func _on_is_top_toggled(toggled_on: bool) -> void:
	set_slot_enabled_left(0, !toggled_on)



func _on_right_text_changed(new_text: String) -> void:
	if not TalkTreeGlobals.save_dict["Global_Vars"].has(new_text):
		$ErrorText.text = (
			"Save dictionary does not have text: %s" % new_text
		)
		$ErrorText.show()
	else:
		$ErrorText.hide()
