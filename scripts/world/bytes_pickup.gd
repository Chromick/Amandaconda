extends Area3D
## Pickup de Bytes (KB).

@export var amount_min: int = 16
@export var amount_max: int = 32

@onready var label: Label3D = $Label3D
@onready var mesh: MeshInstance3D = get_node_or_null("Mesh")

var _spin: float = 0.0


func _ready() -> void:
	body_entered.connect(_on_body)
	label.text = "%d–%d KB" % [amount_min, amount_max]
	if mesh:
		var mat := StandardMaterial3D.new()
		mat.albedo_color = Color(0.95, 0.85, 0.35)
		mat.emission_enabled = true
		mat.emission = Color(1.0, 0.85, 0.3)
		mat.emission_energy_multiplier = 1.6
		mesh.material_override = mat
	var light := OmniLight3D.new()
	light.light_color = Color(1.0, 0.88, 0.4)
	light.light_energy = 1.4
	light.omni_range = 2.8
	add_child(light)


func _process(delta: float) -> void:
	_spin += delta
	rotation.y = _spin * 1.6
	position.y = 0.85 + sin(_spin * 3.0) * 0.08
	for c in get_children():
		if c is OmniLight3D:
			(c as OmniLight3D).light_energy = 1.2 + sin(_spin * 3.5) * 0.35
			break


func _on_body(body: Node3D) -> void:
	if body == null or not body.is_in_group("player"):
		return
	var got := randi_range(amount_min, amount_max)
	GameState.add_bytes(got)
	GameState.show_toast("+%d KB" % got)
	if typeof(HitFeel) != TYPE_NIL:
		HitFeel.spark_at(global_position + Vector3.UP * 0.4, Color(0.95, 0.85, 0.35), 0.9)
		HitFeel.shake(0.08)
	for cam in get_tree().get_nodes_in_group("player_camera"):
		if cam and cam.has_method("punch_fov"):
			cam.punch_fov(2.0)
			break
	queue_free()
