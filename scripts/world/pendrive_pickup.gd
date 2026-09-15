extends Area3D
## Pendrive no chão — escolha Físico (+vida) ou Especial (+dano).

@export var kind: String = "fisico" # fisico | especial

@onready var label: Label3D = $Label3D
@onready var mesh: MeshInstance3D = $Mesh


func _ready() -> void:
	body_entered.connect(_on_body)
	_refresh_visual()


func _refresh_visual() -> void:
	if kind == "especial":
		label.text = "PENDRIVE ESPECIAL"
		_set_color(Color(0.45, 1.0, 0.55))
	else:
		label.text = "PENDRIVE FÍSICO"
		_set_color(Color(0.95, 0.75, 0.35))


func _set_color(c: Color) -> void:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = c
	mat.emission_enabled = true
	mat.emission = c
	mat.emission_energy_multiplier = 1.2
	mesh.material_override = mat


func _on_body(body: Node3D) -> void:
	if body == null or not body.is_in_group("player"):
		return
	GameState.add_pendrive(kind)
	if body.has_method("refresh_progression"):
		body.refresh_progression()
	queue_free()
