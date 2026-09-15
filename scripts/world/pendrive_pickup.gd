extends Area3D
## Pendrive no chão — escolha Físico (+vida) ou Especial (+dano).

@export var kind: String = "fisico" # fisico | especial
@export var magnet_radius: float = 5.2
@export var magnet_speed: float = 11.0

@onready var label: Label3D = $Label3D
@onready var mesh: MeshInstance3D = $Mesh

var _spin: float = 0.0
var _magnet_on: bool = false


func _ready() -> void:
	body_entered.connect(_on_body)
	_refresh_visual()
	if label:
		label.outline_size = 6
		label.outline_modulate = Color(0, 0, 0, 0.85)
	var light := OmniLight3D.new()
	light.light_color = Color(0.95, 0.8, 0.4) if kind != "especial" else Color(0.45, 1.0, 0.55)
	light.light_energy = 1.5
	light.omni_range = 3.2
	light.position = Vector3(0, 0.4, 0)
	add_child(light)


func _process(delta: float) -> void:
	_spin += delta
	rotation.y = _spin * 2.2
	var player := get_tree().get_first_node_in_group("player") as Node3D
	if player != null and is_instance_valid(player):
		var to_p := player.global_position - global_position
		to_p.y = 0.0
		var dist := to_p.length()
		if dist <= magnet_radius * GameState.magnet_mult():
			_magnet_on = true
		if _magnet_on and dist > 0.08:
			var step := minf(magnet_speed * GameState.magnet_mult() * delta * (1.0 + (magnet_radius - dist) * 0.12), dist)
			global_position += to_p.normalized() * step
			global_position.y = player.global_position.y + 0.95 + sin(_spin * 5.0) * 0.05
			if mesh:
				mesh.position.y = 0.15
		elif mesh:
			mesh.position.y = 0.15 + sin(_spin * 3.5) * 0.06
	elif mesh:
		mesh.position.y = 0.15 + sin(_spin * 3.5) * 0.06
	var light := get_node_or_null("OmniLight3D") as OmniLight3D
	if light == null:
		for c in get_children():
			if c is OmniLight3D:
				light = c
				break
	if light:
		light.light_energy = 1.35 + sin(_spin * 4.0) * 0.35


func _refresh_visual() -> void:
	if kind == "especial":
		label.text = "PENDRIVE ESPECIAL\n+dano"
		_set_color(Color(0.45, 1.0, 0.55))
	else:
		label.text = "PENDRIVE FÍSICO\n+vida"
		_set_color(Color(0.95, 0.75, 0.35))


func _set_color(c: Color) -> void:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = c
	mat.emission_enabled = true
	mat.emission = c
	mat.emission_energy_multiplier = 1.8
	mesh.material_override = mat


func _on_body(body: Node3D) -> void:
	if body == null or not body.is_in_group("player"):
		return
	set_deferred("monitoring", false)
	GameState.add_pendrive(kind)
	if body.has_method("refresh_progression"):
		body.refresh_progression()
	var msg := "Pendrive Especial · Esp%d" % GameState.especial_level if kind == "especial" else "Pendrive Físico · Fis%d" % GameState.fisico_level
	GameState.show_toast(msg)
	if typeof(HitFeel) != TYPE_NIL:
		HitFeel.spark_at(global_position + Vector3.UP * 0.5, Color(0.45, 1.0, 0.55) if kind == "especial" else Color(1.0, 0.8, 0.35), 1.1)
		HitFeel.shake(0.12)
		HitFeel.kick_fov(3.0, 0.12)
	queue_free()
