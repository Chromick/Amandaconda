extends Area3D
## Servidor de backup — compra Patches com Bytes (E).

signal opened

@onready var label: Label3D = $Label3D
@onready var mesh: MeshInstance3D = get_node_or_null("Mesh")
var _player_near: bool = false
var _spin: float = 0.0
var _light: OmniLight3D


func _ready() -> void:
	add_to_group("patch_terminal")
	body_entered.connect(_on_enter)
	body_exited.connect(_on_exit)
	label.text = "SERVIDOR DE BACKUP\n[E] Patches"
	if label:
		label.outline_size = 8
		label.outline_modulate = Color(0, 0, 0, 0.85)
	if mesh:
		var mat := StandardMaterial3D.new()
		mat.albedo_color = Color(0.35, 0.55, 0.45)
		mat.emission_enabled = true
		mat.emission = Color(0.25, 0.85, 0.55)
		mat.emission_energy_multiplier = 0.9
		mesh.material_override = mat
	_light = OmniLight3D.new()
	_light.light_color = Color(0.35, 1.0, 0.65)
	_light.light_energy = 0.7
	_light.omni_range = 4.0
	_light.position = Vector3(0, 1.4, 0)
	add_child(_light)


func _process(delta: float) -> void:
	_spin += delta
	if mesh:
		mesh.rotation.y = _spin * (1.6 if _player_near else 0.7)
		mesh.position.y = 1.0 + sin(_spin * 2.4) * (0.08 if _player_near else 0.03)
		var s := 1.08 if _player_near else 1.0
		mesh.scale = mesh.scale.lerp(Vector3(s, s, s), clampf(5.0 * delta, 0.0, 1.0))
	if label:
		label.modulate = Color(0.55, 1.0, 0.7) if _player_near else Color.WHITE
	if _light:
		var target := 2.2 if _player_near else 0.65
		_light.light_energy = lerpf(_light.light_energy, target + sin(_spin * 4.0) * 0.15, clampf(5.0 * delta, 0.0, 1.0))


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
		if typeof(HitFeel) != TYPE_NIL:
			HitFeel.spark_at(global_position + Vector3.UP * 1.2, Color(0.4, 1.0, 0.65), 0.75)
			HitFeel.kick_fov(2.0, 0.1)
		get_viewport().set_input_as_handled()
