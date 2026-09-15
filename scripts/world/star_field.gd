extends Node3D
## Céu estrelado com cintilação leve.


func _process(_delta: float) -> void:
	var t := Time.get_ticks_msec() * 0.001
	for c in get_children():
		if not (c is MeshInstance3D):
			continue
		var mat := (c as MeshInstance3D).material_override as StandardMaterial3D
		if mat == null:
			continue
		var ph := c.global_position.x * 0.13 + c.global_position.z * 0.09
		mat.emission_energy_multiplier = 1.4 + 1.4 * absf(sin(t * 1.7 + ph))
