extends Area3D
## Poça de caramelo — freia player e inimigos.

var slow_mult: float = 0.45
var lifetime: float = 6.0
var _bodies: Array[Node] = []
var _mesh: MeshInstance3D
var _mat: StandardMaterial3D
var _pulse: float = 0.0


func setup(radius: float, duration: float, slow: float) -> void:
	lifetime = duration
	slow_mult = slow
	var shape := $CollisionShape3D.shape as CylinderShape3D
	if shape:
		shape.radius = radius
	_mesh = $Mesh
	if _mesh and _mesh.mesh is CylinderMesh:
		(_mesh.mesh as CylinderMesh).top_radius = radius
		(_mesh.mesh as CylinderMesh).bottom_radius = radius
	_mat = StandardMaterial3D.new()
	_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_mat.albedo_color = Color(0.85, 0.45, 0.12, 0.55)
	_mat.emission_enabled = true
	_mat.emission = Color(1.0, 0.4, 0.08)
	_mat.emission_energy_multiplier = 1.4
	if _mesh:
		_mesh.material_override = _mat
	if not body_entered.is_connected(_on_enter):
		body_entered.connect(_on_enter)
	if not body_exited.is_connected(_on_exit):
		body_exited.connect(_on_exit)
	if typeof(HitFeel) != TYPE_NIL:
		HitFeel.spark_at(global_position + Vector3.UP * 0.2, Color(1.0, 0.55, 0.15), 0.9)


func _physics_process(delta: float) -> void:
	lifetime -= delta
	_pulse += delta
	if _mat:
		_mat.emission_energy_multiplier = 1.2 + sin(_pulse * 5.0) * 0.35
		_mat.albedo_color.a = 0.4 + sin(_pulse * 3.0) * 0.12
	# Limpa refs mortas pra não acumular / crash ao sair
	for i in range(_bodies.size() - 1, -1, -1):
		if _bodies[i] == null or not is_instance_valid(_bodies[i]):
			_bodies.remove_at(i)
	if lifetime <= 0.0:
		for b in _bodies:
			_clear_body(b)
		_bodies.clear()
		if _mesh and _mat:
			var tw := create_tween()
			tw.set_parallel(true)
			tw.tween_property(_mat, "albedo_color:a", 0.0, 0.35)
			tw.tween_property(_mesh, "scale", Vector3(0.2, 0.2, 0.2), 0.35)
			tw.chain().tween_callback(queue_free)
		else:
			queue_free()


func _on_enter(body: Node3D) -> void:
	if body == null:
		return
	if body not in _bodies:
		_bodies.append(body)
	if body.has_method("set_ground_slow"):
		body.set_ground_slow(slow_mult)
		if body.is_in_group("player"):
			GameState.show_toast("Caramelo · movimento lento")
	elif body.is_in_group("enemy") or body.is_in_group("boss"):
		body.set_meta("ground_slow", slow_mult)


func _on_exit(body: Node3D) -> void:
	_bodies.erase(body)
	_clear_body(body)


func _clear_body(body: Node) -> void:
	if body == null or not is_instance_valid(body):
		return
	if body.has_method("clear_ground_slow"):
		body.clear_ground_slow()
	elif body.has_meta("ground_slow"):
		body.remove_meta("ground_slow")
