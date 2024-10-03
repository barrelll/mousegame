extends CanvasLayer

@onready
var Character_Name: Label = $MarginContainer/Panel/MarginContainer/Panel/HBoxContainer/VBoxContainer/Name
@onready
var Dialogue: Label = $MarginContainer/Panel/MarginContainer/Panel/HBoxContainer/VBoxContainer/HBoxContainer/MarginContainer/VBoxContainer/Dialogue
@onready var Dialogue_Container: MarginContainer = $MarginContainer
@onready var choice_packed_scene: PackedScene = preload(
	"res://Dialogue/Choice.tscn"
)

@export_group("Settings")
@export var text_display_speed: float = 0.01

var game_state_path = "res://game_state.res"
var game_state: PackedDataContainer
var game_state_dict: Dictionary
var dialogue_tween: Tween
var container_modulate_tween: Tween
var container_bounce_tween: Tween
var is_active: bool = false
var current_character: String

signal action_node(action: String)


func _ready() -> void:
	game_state = load(game_state_path)
	for key in game_state:
		game_state_dict[key] = game_state[key]


func start_conversation(character_context: String) -> void:
	current_character = character_context
	if current_character in game_state_dict:
		Character_Name.text = current_character
		var first = get_first_dialogue()
		next_dialogue(first)
	else:
		printerr(
			(
				"Character context not found : %s, ignoring"
				% character_context
			)
		)


func next_dialogue(jump_to: int) -> void:
	# clear out the dialogue first
	Dialogue.text = ""
	# delete the choices
	for child in Dialogue.get_parent().get_children():
		if child is Button:
			child.queue_free()

	# if we have no choices add a continue choice
	if game_state_dict[current_character][jump_to]["type"] == "Dialogue":
		set_dialogue(game_state_dict[current_character][jump_to]["text"])
		handle_dialogue_node(jump_to)
	elif game_state_dict[current_character][jump_to]["type"] == "Action":
		action_node.emit(
			game_state_dict[current_character][jump_to]["text"]
		)
		if game_state_dict[current_character][jump_to]["jump_to"] is int:
			print(game_state_dict[current_character][jump_to]["type"])
			print(game_state_dict[current_character][jump_to]["jump_to"])
			jump_to = game_state_dict[current_character][jump_to]["jump_to"]
			next_dialogue(jump_to)


func handle_dialogue_node(jump_to: int) -> void:
	if not game_state_dict[current_character][jump_to]["choices"].size():
		var choice = choice_packed_scene.instantiate()
		choice.dialogue_id = jump_to
		choice.is_continue = true
		choice.id = 0
		choice.text = "<Continue>"
		choice.choice_selected.connect(_on_choice_pressed)
		Dialogue.get_parent().add_child(choice)
	# loop through our choices and set them up
	for item in game_state_dict[current_character][jump_to]["choices"]:
		var choice = choice_packed_scene.instantiate()
		choice.dialogue_id = jump_to
		choice.id = item["id"]
		choice.text = item["text"]
		choice.choice_selected.connect(_on_choice_pressed)
		Dialogue.get_parent().add_child(choice)


func set_dialogue(text: String) -> void:
	animate_in()
	# tween the dialogue box
	if dialogue_tween and dialogue_tween.is_running():
		dialogue_tween.kill()
	Dialogue["visible_ratio"] = 0.0
	Dialogue.text = text
	dialogue_tween = create_tween()
	dialogue_tween.set_trans(Tween.TRANS_LINEAR).tween_property(
		Dialogue, "visible_ratio", 1.0, len(text) * text_display_speed
	)


func interrupt_conversation() -> void:
	if dialogue_tween and dialogue_tween.is_running():
		dialogue_tween.kill()
		Dialogue["visible_ratio"] = 1.0


func animate_in() -> void:
	if not is_active:
		# kill both tweens
		if (
			container_modulate_tween
			and container_modulate_tween.is_running()
		):
			container_modulate_tween.kill()
		if container_bounce_tween and container_bounce_tween.is_running():
			container_bounce_tween.kill()

		is_active = true
		# animate the alpha in
		container_modulate_tween = create_tween()
		(
			container_modulate_tween
			. set_trans(Tween.TRANS_LINEAR)
			. tween_property(
				Dialogue_Container, "modulate", Color.WHITE, .2
			)
		)
		# animate the location y in and do a bit of a bounce
		container_bounce_tween = create_tween()
		(
			container_bounce_tween
			. set_trans(Tween.TRANS_BACK)
			. set_ease(Tween.EASE_OUT)
			. tween_property(
				Dialogue_Container, "position", Vector2(0, 445), .2
			)
		)


func animate_out() -> void:
	if is_active:
		# kill both tweens
		if (
			container_modulate_tween
			and container_modulate_tween.is_running()
		):
			container_modulate_tween.kill()
		if container_bounce_tween and container_bounce_tween.is_running():
			container_bounce_tween.kill()

		# kill the dialogue if it's playing
		interrupt_conversation()

		is_active = false
		# animate the alpha in
		container_modulate_tween = create_tween()
		# make sure we clear out the text and images when we're done
		container_modulate_tween.finished.connect(
			_animate_out_on_tween_finished
		)
		(
			container_modulate_tween
			. set_trans(Tween.TRANS_LINEAR)
			. tween_property(
				Dialogue_Container, "modulate", Color.TRANSPARENT, .2
			)
		)
		# animate the location y in and do a bit of a bounce
		container_bounce_tween = create_tween()
		(
			container_bounce_tween
			. set_trans(Tween.TRANS_LINEAR)
			. set_ease(Tween.EASE_OUT)
			. tween_property(
				Dialogue_Container, "position", Vector2(0, 496), .2
			)
		)


func _animate_out_on_tween_finished() -> void:
	#clear everything out
	Character_Name.text = ""
	Dialogue.text = ""
	# delete the choices
	for child in Dialogue.get_parent().get_children():
		if child is Button:
			child.queue_free()


func _on_choice_pressed(b: Choice) -> void:
	var jump_to
	if not b.is_continue:
		jump_to = game_state_dict[current_character][b.dialogue_id]["choices"][
			b.id
		]["jump_to"]
	else:
		jump_to = game_state_dict[current_character][b.dialogue_id]["jump_to"]
	next_dialogue(jump_to)


func get_first_dialogue() -> int:
	var ret: int = 0
	for i in game_state_dict[current_character].size():
		if game_state_dict[current_character][i]["type"] == "Dialogue":
			if game_state_dict[current_character][i]["default"] == true:
				ret = i
	return ret
