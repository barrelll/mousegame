@tool
extends HBoxContainer

@onready var tree: Tree = $Panel/TabContainer/Characters
var root: TreeItem


func _ready() -> void:
	root = tree.create_item()
	var one = tree.create_item(root)
	one.set_text(0, "First Blind Mouse")
	var child = one.create_child()
	child.set_text(0, "Text!")


func _on_tree_cell_selected() -> void:
	print("dsada")
	
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_text_caret_word_right.macos"):
		$Panel.hide()
	elif event.is_action_pressed("ui_text_caret_word_left.macos"):
		$Panel.show()
