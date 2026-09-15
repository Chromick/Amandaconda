extends RefCounted
class_name AttackTelegraph
## Fantasma de alcance no windup (Souls-style telegraph).


static func make_box(host: Node3D, size: Vector3, local_pos: Vector3, color: Color = Color(1.0, 0.75, 0.2, 0.35)) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.name = "AttackTelegraph"
	var bm := BoxMesh.new()
	bm.size = size
	mi.mesh = bm
	var mat := StandardMaterial3D.new()
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = color
	mat.emission_enabled = true
	mat.emission = Color(color.r, color.g, color.b)
	mat.emission_energy_multiplier = 1.6
	mi.material_override = mat
	mi.position = local_pos
	mi.visible = false
	host.add_child(mi)
	return mi


static func make_sphere(host: Node3D, radius: float, local_pos: Vector3, color: Color = Color(1.0, 0.9, 0.25, 0.3)) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.name = "AttackTelegraph"
	var sm := SphereMesh.new()
	sm.radius = radius
	sm.height = radius * 2.0
	mi.mesh = sm
	var mat := StandardMaterial3D.new()
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = color
	mat.emission_enabled = true
	mat.emission = Color(color.r, color.g, color.b)
	mat.emission_energy_multiplier = 1.4
	mi.material_override = mat
	mi.position = local_pos
	mi.visible = false
	host.add_child(mi)
	return mi


static func set_active(mi: MeshInstance3D, active: bool, flash: bool = false) -> void:
	if mi == null:
		return
	mi.visible = active
	var mat := mi.material_override as StandardMaterial3D
	if mat == null:
		return
	if flash:
		mat.albedo_color.a = 0.8
		mat.emission_energy_multiplier = 4.2
	elif active:
		var pulse := 0.28 + 0.14 * absf(sin(Time.get_ticks_msec() * 0.014))
		mat.albedo_color.a = pulse
		mat.emission_energy_multiplier = 1.5 + pulse
