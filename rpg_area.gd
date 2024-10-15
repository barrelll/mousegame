extends Node2D

const SPEED = 300.0

@export var Conversation: CanvasLayer
@export var player_character: CharacterBody2D
var context : String = "Hub"

func _ready() -> void:
	print(GameStateManager.game_state)

func _physics_process(_delta: float) -> void:
	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var direction := Input.get_vector(
		"ui_left", "ui_right", "ui_up", "ui_down"
	)
	if direction:
		player_character.velocity = direction * SPEED
	else:
		player_character.velocity.x = move_toward(
			player_character.velocity.x, 0, SPEED
		)
		player_character.velocity.y = move_toward(
			player_character.velocity.y, 0, SPEED
		)

	player_character.move_and_slide()


func _on_player_context_selection(object: Object) -> void:
	if Conversation.is_active:
		Conversation.interrupt_conversation()
	else:
		Conversation.start_conversation(object.name, context)


func _on_conversation_box_action_node(action: String) -> void:
	match action:
		"End":
			$ConversationBox.animate_out()
		"Fight":
			$ConversationBox.animate_out()
		_:
			pass
