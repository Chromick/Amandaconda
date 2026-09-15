extends Area3D
## Servidor de backup — compra Patches com Bytes (E).

signal opened

@onready var label: Label3D = $Label3D
var _player_near: bool = false


func _ready() -> void:
	add_to_group("patch_terminal")
	body_entered.connect(_on_enter)
	body_exited.connect(_on_exit)
	label.text = "SERVIDOR DE BACKUP\n[E] Patches"


func _on_enter(body: Node3D) -> void:
	if body.is_in_group("player"):
		_player_near = true
		label.modulate = Color(0.6, 1.0, 0.75)


func _on_exit(body: Node3D) -> void:
	if body.is_in_group("player"):
		_player_near = false
		label.modulate = Color.WHITE


func _unhandled_input(event: InputEvent) -> void:
	if not _player_near:
		return
	if event.is_action_pressed("interact"):
		opened.emit()
		get_viewport().set_input_as_handled()
