extends Area3D
## Pickup de Bytes (KB).

@export var amount_min: int = 16
@export var amount_max: int = 32
@export var magnet_radius: float = 6.8
@export var magnet_speed: float = 15.5

@onready var label: Label3D = $Label3D
@onready var mesh: MeshInstance3D = get_node_or_null("Mesh")

var _spin: float = 0.0
var _magnet_on: bool = false
var _base_y: float = 0.85


func _ready() -> void:
	body_entered.connect(_on_body)
	label.text = "%d–%d KB" % [amount_min, amount_max]
	_base_y = position.y if position.y > 0.1 else 0.85
	if label:
		label.outline_size = 6
		label.outline_modulate = Color(0, 0, 0, 0.85)
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
	var player := get_tree().get_first_node_in_group("player") as Node3D
	if player != null and is_instance_valid(player):
		var to_p := player.global_position - global_position
		to_p.y = 0.0
		var dist := to_p.length()
		if dist <= magnet_radius * GameState.magnet_mult():
			_magnet_on = true
		if _magnet_on and dist > 0.05:
			var step := minf(magnet_speed * GameState.magnet_mult() * delta * (1.0 + (magnet_radius - dist) * 0.15), dist)
			global_position += to_p.normalized() * step
			global_position.y = player.global_position.y + 0.9 + sin(_spin * 6.0) * 0.04
		else:
			position.y = _base_y + sin(_spin * 3.0) * 0.08
	else:
		position.y = _base_y + sin(_spin * 3.0) * 0.08
	for c in get_children():
		if c is OmniLight3D:
			(c as OmniLight3D).light_energy = 1.2 + sin(_spin * 3.5) * 0.35
			break


func _on_body(body: Node3D) -> void:
	if body == null or not body.is_in_group("player"):
		return
	set_deferred("monitoring", false)
	var got := randi_range(amount_min, amount_max)
	GameState.add_bytes(got)
	GameState.show_toast("+%d KB" % got)
	if typeof(HitFeel) != TYPE_NIL:
		HitFeel.spark_at(global_position + Vector3.UP * 0.4, Color(0.95, 0.85, 0.35), 0.9)
		HitFeel.shake(0.08)
		HitFeel.kick_fov(2.0, 0.1)
	queue_free()
