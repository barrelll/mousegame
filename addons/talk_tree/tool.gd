@tool
extends EditorPlugin

var talk_tree_packed_scene = load("res://addons/talk_tree/base.tscn")
var talk_tree


func _enter_tree() -> void:
	# Add a custom button to the toolbar
	talk_tree = talk_tree_packed_scene.instantiate()
	get_editor_interface().get_editor_main_screen().add_child(talk_tree)

	_make_visible(false)


func _exit_tree() -> void:
	if talk_tree:
		talk_tree.queue_free()


func _get_plugin_icon() -> Texture2D:
	return EditorInterface.get_editor_theme().get_icon(
		"GraphEdit", "EditorIcons"
	)


func _has_main_screen() -> bool:
	return true


func _init() -> void:
	self.name = "TalkTree"


func _get_plugin_name() -> String:
	return "TalkTree"


func _make_visible(visible) -> void:
	if not talk_tree:
		return

	if visible:
		get_editor_interface().set_main_screen_editor(self.name)
		talk_tree.show()
		talk_tree.grab_focus()
	else:
		talk_tree.hide()
