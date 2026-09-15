extends CanvasLayer
## Pause overlay no hub.


func _ready() -> void:
	visible = false
	process_mode = Node.PROCESS_MODE_ALWAYS


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		_toggle()
		get_viewport().set_input_as_handled()


func _toggle() -> void:
	visible = not visible
	get_tree().paused = visible
	GameState.paused = visible
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE if visible else Input.MOUSE_MODE_CAPTURED


func _on_resume_pressed() -> void:
	if visible:
		_toggle()


func _on_menu_pressed() -> void:
	get_tree().paused = false
	GameState.go_to_menu()
