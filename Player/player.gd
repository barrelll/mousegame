extends CharacterBody2D

@onready var context_picker: RayCast2D = $ContextPicker
signal context_selection(object: Object)


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"):
		var collider = context_picker.get_collider()
		if is_instance_valid(collider):
			context_selection.emit(collider.get_parent())
