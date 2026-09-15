extends Node3D
## Spark curto no ponto de impacto (sem asset externo).


func setup(color: Color = Color(1.0, 0.85, 0.35), scale_u: float = 1.0) -> void:
	var mesh := MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = 0.12 * scale_u
	sm.height = 0.24 * scale_u
	mesh.mesh = sm
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = color
	mat.emission_enabled = true
	mat.emission = color
	mat.emission_energy_multiplier = 5.0
	mesh.material_override = mat
	add_child(mesh)
	var light := OmniLight3D.new()
	light.light_color = color
	light.light_energy = 3.2 * scale_u
	light.omni_range = 3.2 * scale_u
	add_child(light)
	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(mesh, "scale", Vector3.ONE * 2.8, 0.12)
	tw.tween_property(light, "light_energy", 0.0, 0.22)
	# Fragmentos voando pra fora
	for i in 12:
		var shard := MeshInstance3D.new()
		var box := BoxMesh.new()
		box.size = Vector3(0.05, 0.05, 0.22) * scale_u
		shard.mesh = box
		var shard_mat := mat.duplicate() as StandardMaterial3D
		shard.material_override = shard_mat
		var dir := Vector3(randf_range(-1.0, 1.0), randf_range(0.2, 1.0), randf_range(-1.0, 1.0))
		if dir.length_squared() < 0.001:
			dir = Vector3.UP
		else:
			dir = dir.normalized()
		add_child(shard)
		shard.position = dir * 0.08
		# Basis local — evita look_at com nó fora da árvore / coords erradas
		shard.basis = Basis.looking_at(dir, Vector3.UP)
		tw.tween_property(shard, "position", dir * randf_range(0.55, 1.2) * scale_u, 0.22)
		tw.tween_property(shard, "scale", Vector3.ZERO, 0.22)
	tw.chain().tween_callback(queue_free)
