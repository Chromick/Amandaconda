extends Node3D
## Céu estrelado com cintilação leve.


func _process(_delta: float) -> void:
	var t := Time.get_ticks_msec() * 0.001
	for c in get_children():
		if not (c is MeshInstance3D):
			continue
		var mi := c as MeshInstance3D
		var mat := mi.material_override as StandardMaterial3D
		if mat == null:
			continue
		var ph: float = mi.global_position.x * 0.13 + mi.global_position.z * 0.09
		var pulse := absf(sin(t * 1.7 + ph))
		mat.emission_energy_multiplier = 1.4 + 1.5 * pulse
		var s := 0.92 + 0.18 * pulse
		mi.scale = Vector3(s, s, s)
