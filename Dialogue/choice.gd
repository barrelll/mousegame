extends Button
class_name Choice

var dialogue_id : int
var id : int
var is_continue = false

signal choice_selected(b : Choice)

func _on_pressed() -> void:
	choice_selected.emit(self)
