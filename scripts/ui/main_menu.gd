extends Control
## Menu — escolha de escola e entrada no hub.


func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func _on_fisico_pressed() -> void:
	GameState.start_run(GameState.WeaponSchool.TECLADO)


func _on_especial_pressed() -> void:
	GameState.start_run(GameState.WeaponSchool.VIRUS)


func _on_quit_pressed() -> void:
	get_tree().quit()
