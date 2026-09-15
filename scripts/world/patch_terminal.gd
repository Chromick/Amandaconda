extends Area3D
## Servidor de backup — compra Patches com Bytes (E).

signal opened

@onready var label: Label3D = $Label3D
@onready var mesh: MeshInstance3D = get_node_or_null("Mesh")
var _player_near: bool = false
var _spin: float = 0.0


func _ready() -> void:
	add_to_group("patch_terminal")
	body_entered.connect(_on_enter)
	body_exited.connect(_on_exit)
	label.text = "SERVIDOR DE BACKUP\n[E] Patches"
	if mesh:
		var mat := StandardMaterial3D.new()
		mat.albedo_color = Color(0.35, 0.55, 0.45)
		mat.emission_enabled = true
		mat.emission = Color(0.25, 0.85, 0.55)
		mat.emission_energy_multiplier = 0.9
		mesh.material_override = mat


func _process(delta: float) -> void:
	_spin += delta
	if mesh:
		mesh.rotation.y = _spin * (1.6 if _player_near else 0.7)
		mesh.position.y = 1.0 + sin(_spin * 2.4) * (0.08 if _player_near else 0.03)
	if label:
		label.modulate = Color(0.55, 1.0, 0.7) if _player_near else Color.WHITE


func _on_enter(body: Node3D) -> void:
	if body.is_in_group("player"):
		_player_near = true
		GameState.show_toast("Servidor de backup · [E]")


func _on_exit(body: Node3D) -> void:
	if body.is_in_group("player"):
		_player_near = false


func _unhandled_input(event: InputEvent) -> void:
	if not _player_near:
		return
	if event.is_action_pressed("interact"):
		opened.emit()
		get_viewport().set_input_as_handled()
