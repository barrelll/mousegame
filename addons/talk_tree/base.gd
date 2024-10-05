@tool
extends HBoxContainer

@onready var TalkTree = $TalkTree
@onready var tabcontainer: TabContainer = $Panel/TabContainer
@onready var char_tree: Tree = $Panel/TabContainer/Characters/Char_Tree
var char_tree_root: TreeItem
@onready
var global_var_tree: Tree = $"Panel/TabContainer/Global Vars/Global_Var_Tree"
var global_var_tree_root: TreeItem


func _ready() -> void:
	# set tab container icons
	(
		tabcontainer
		. set_tab_icon(
			0,
			load(
				"res://addons/talk_tree/icons/recent_actors_24dp_5F6368_FILL0_wght400_GRAD0_opsz24.svg"
			)
		)
	)
	(
		tabcontainer
		. set_tab_icon(
			1,
			load(
				"res://addons/talk_tree/icons/check_circle_24dp_5F6368_FILL0_wght400_GRAD0_opsz24.svg"
			)
		)
	)
	# create tree roots
	char_tree_root = char_tree.create_item()
	global_var_tree_root = global_var_tree.create_item()
	TalkTreeGlobals.save_dict = TalkTreeGlobals.load_save_file()
	#now organize the trees with what we got from the load_save_dict
	set_up_char_tree()
	set_up_global_var_tree()


func set_up_global_var_tree() -> void:
	for val in TalkTreeGlobals.save_dict["Global_Vars"]:
		var name = val
		var is_checked = TalkTreeGlobals.save_dict["Global_Vars"][val]
		var char = add_global_variable(name, is_checked)


func set_up_char_tree() -> void:
	for character_name in TalkTreeGlobals.save_dict["Characters"]:
		var char = add_character(character_name)
		for context in (
			TalkTreeGlobals.save_dict["Characters"][character_name]
		):
			add_context_to_character(char, context)


func _on_tree_cell_selected() -> void:
	# only want to run on character keys not local variables
	var tree_item: TreeItem = char_tree.get_selected()
	if tree_item and tree_item.get_parent() == char_tree_root:
		# disable saving if we're selecting a character key
		disable_save(true)
		# enable add context
		disable_add_context(false)
	else:
		# re-enable saving and load the character context
		disable_save(false)
		# disable add context
		disable_add_context(true)
		await TalkTree.clear_all()
		TalkTree.character_name = tree_item.get_parent().get_text(0)
		TalkTree.context = tree_item.get_text(0)
		TalkTree.load_character_context(
			TalkTreeGlobals.save_dict["Characters"]
		)
		TalkTreeGlobals.updated.emit()


func disable_add_context(val: bool) -> void:
	$Panel/TabContainer/Characters/character_tool_bar/add_context.disabled = val


func disable_save(val: bool) -> void:
	$Panel/TabContainer/Characters/character_tool_bar/save_all.disabled = val
	$"Panel/TabContainer/Global Vars/global_var_tool_bar/save_all".disabled = val


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_text_caret_word_right"):
		$Panel.hide()
	elif event.is_action_pressed("ui_text_caret_word_left"):
		$Panel.show()


func save_char_tree() -> void:
	if char_tree.get_selected():
		var save_file = FileAccess.open(
			TalkTreeGlobals.save_path, FileAccess.WRITE
		)
		var selected = char_tree.get_selected()
		var character_name = selected.get_parent().get_text(0)
		TalkTreeGlobals.save_dict["Characters"][character_name][selected.get_text(0)] = (
			TalkTree.save_character_context()
		)
		var json_string = JSON.stringify(TalkTreeGlobals.save_dict)
		save_file.store_line(json_string)
		save_file.close()
	else:
		printerr("No character selected, skipping save character save")


func save_global_vars() -> void:
	var save_file = FileAccess.open(
		TalkTreeGlobals.save_path, FileAccess.WRITE
	)
	var variable_dict = {}
	for child in global_var_tree_root.get_children():
		TalkTreeGlobals.save_dict["Global_Vars"][child.get_text(0)] = (
			child.is_checked(0)
		)
	var json_string = JSON.stringify(TalkTreeGlobals.save_dict)
	save_file.store_line(json_string)
	save_file.close()


func _on_save_all_pressed() -> void:
	save_global_vars()
	save_char_tree()


func _on_add_char_pressed() -> void:
	$add_char_popup_menu.popup()


func _on_line_edit_text_submitted(new_text: String) -> void:
	$add_char_popup_menu.hide()
	# get text and clear it
	var name = $add_char_popup_menu/LineEdit.text.strip_edges(true, true)
	$add_char_popup_menu/LineEdit.text = ""
	# insert the character into the tree
	for child in char_tree_root.get_children():
		if child.get_text(0) == name:
			printerr("Character tree root has child: %s, returning" % name)
			return
	add_character(name)


func add_character(name: String) -> TreeItem:
	var character = char_tree.create_item(char_tree_root)
	character.set_text(0, name)
	character.set_icon_max_width(0, 16)
	(
		character
		. set_icon(
			0,
			load(
				"res://addons/talk_tree/icons/key_24dp_5F6368_FILL0_wght400_GRAD0_opsz24.svg"
			)
		)
	)
	char_tree_root.add_child(character)
	if not TalkTreeGlobals.save_dict["Characters"].has(name):
		TalkTreeGlobals.save_dict["Characters"][name] = {}

	return character


func _on_delete_char_pressed() -> void:
	var tree_item: TreeItem = char_tree.get_selected()
	# erase a character
	if tree_item and tree_item.get_parent() == char_tree_root:
		TalkTreeGlobals.save_dict["Characters"].erase(
			tree_item.get_text(0)
		)
		tree_item.free()
	# erase a context
	else:
		var character_name = tree_item.get_parent().get_text(0)
		TalkTreeGlobals.save_dict["Characters"][character_name].erase(
			tree_item.get_text(0)
		)
		tree_item.free()


func _on_talk_tree_save() -> void:
	save_char_tree()


func _on_variable_line_edit_text_submitted(new_text: String) -> void:
	$add_global_var_popup_menu.hide()
	# get text and clear it
	var name = $add_global_var_popup_menu/LineEdit.text.strip_edges(
		true, true
	)
	$add_global_var_popup_menu/LineEdit.text = ""
	# insert the character into the tree
	for child in global_var_tree_root.get_children():
		if child.get_text(0) == name:
			printerr("Variable tree root has child: %s, returning" % name)
			return
	add_global_variable(name)


func add_global_variable(
	name: String, is_checked: bool = false
) -> TreeItem:
	var global_var = global_var_tree.create_item(global_var_tree_root)
	global_var.set_editable(0, true)
	global_var.set_cell_mode(0, TreeItem.CELL_MODE_CHECK)
	global_var.set_checked(0, is_checked)
	global_var.set_text(0, name)
	global_var_tree_root.add_child(global_var)
	TalkTreeGlobals.save_dict["Global_Vars"][global_var.get_text(0)] = (
		global_var.is_checked(0)
	)
	TalkTreeGlobals.updated.emit()
	return global_var


func _on_add_global_var_pressed() -> void:
	$add_global_var_popup_menu.popup()


func _on_delete_global_var_pressed() -> void:
	var tree_item: TreeItem = global_var_tree.get_selected()
	if tree_item and tree_item.get_parent() == global_var_tree_root:
		TalkTreeGlobals.save_dict["Global_Vars"].erase(
			tree_item.get_text(0)
		)
		TalkTreeGlobals.updated.emit()
		tree_item.free()


func _on_add_context_pressed() -> void:
	var tree_item: TreeItem = char_tree.get_selected()
	if tree_item and tree_item.get_parent() == char_tree_root:
		$add_char_context_popup_menu.popup()
	else:
		printerr("Tree item is not an immediate child of root, ignoring")


func _on_context_line_edit_text_submitted(new_text: String) -> void:
	$add_char_context_popup_menu.hide()
	# get text and clear it
	var name = $add_char_context_popup_menu/LineEdit.text.strip_edges(
		true, true
	)
	$add_char_context_popup_menu/LineEdit.text = ""
	# insert the character into the tree
	var selected = char_tree.get_selected()
	for child in selected.get_children():
		if child.get_text(0) == name:
			printerr(
				(
					"Tree item %s has child: %s, returning"
					% [selected.get_text(0), name]
				)
			)
			return
	add_context_to_character(selected, name)


func add_context_to_character(char: TreeItem, name: String) -> TreeItem:
	var context = char_tree.create_item(char)
	context.set_text(0, name)
	context.set_icon_max_width(0, 16)
	(
		context
		. set_icon(
			0,
			load(
				"res://addons/talk_tree/icons/location_on_24dp_5F6368_FILL0_wght400_GRAD0_opsz24.svg"
			)
		)
	)
	char.add_child(context)
	return context
