extends Node3D
## Motes de poeira flutuando no campus noturno.

var _pts: Array = []


func _ready() -> void:
	for i in 144:
		var m := MeshInstance3D.new()
		var s := SphereMesh.new()
		s.radius = randf_range(0.025, 0.045)
		s.height = s.radius * 2.0
		m.mesh = s
		var mat := StandardMaterial3D.new()
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		mat.albedo_color = Color(0.85, 0.9, 1.0, randf_range(0.28, 0.42))
		mat.emission_enabled = true
		mat.emission = Color(0.7, 0.8, 1.0)
		mat.emission_energy_multiplier = randf_range(0.6, 1.1)
		m.material_override = mat
		add_child(m)
		m.position = Vector3(randf_range(-35.0, 35.0), randf_range(1.2, 8.0), randf_range(-40.0, 25.0))
		_pts.append({"n": m, "sp": randf_range(0.15, 0.45), "ph": randf() * TAU})


func _process(delta: float) -> void:
	var t := Time.get_ticks_msec() * 0.001
	var player := get_tree().get_first_node_in_group("player") as Node3D
	for p in _pts:
		var n: MeshInstance3D = p.get("n")
		if n == null or not is_instance_valid(n):
			continue
		var sp: float = float(p.get("sp", 0.3))
		var ph: float = float(p.get("ph", 0.0))
		n.position.y += sin(t * sp + ph) * delta * 0.25
		n.position.x += cos(t * sp * 0.7 + ph) * delta * 0.12
		# Mantém um pouco de poeira perto do jogador.
		if player and is_instance_valid(player) and randf() < 0.0004:
			var around := player.global_position + Vector3(randf_range(-8.0, 8.0), randf_range(1.0, 4.0), randf_range(-8.0, 8.0))
			n.global_position = around
