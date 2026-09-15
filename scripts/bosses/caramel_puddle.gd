extends Area3D
## Poça de caramelo — freia player e inimigos.

var slow_mult: float = 0.45
var lifetime: float = 6.0
var _bodies: Array[Node] = []


func setup(radius: float, duration: float, slow: float) -> void:
	lifetime = duration
	slow_mult = slow
	var shape := $CollisionShape3D.shape as CylinderShape3D
	if shape:
		shape.radius = radius
	var mesh := $Mesh
	if mesh and mesh.mesh is CylinderMesh:
		(mesh.mesh as CylinderMesh).top_radius = radius
		(mesh.mesh as CylinderMesh).bottom_radius = radius
	if not body_entered.is_connected(_on_enter):
		body_entered.connect(_on_enter)
	if not body_exited.is_connected(_on_exit):
		body_exited.connect(_on_exit)


func _physics_process(delta: float) -> void:
	lifetime -= delta
	# Limpa refs mortas pra não acumular / crash ao sair
	for i in range(_bodies.size() - 1, -1, -1):
		if _bodies[i] == null or not is_instance_valid(_bodies[i]):
			_bodies.remove_at(i)
	if lifetime <= 0.0:
		for b in _bodies:
			_clear_body(b)
		_bodies.clear()
		queue_free()


func _on_enter(body: Node3D) -> void:
	if body == null:
		return
	if body not in _bodies:
		_bodies.append(body)
	if body.has_method("set_ground_slow"):
		body.set_ground_slow(slow_mult)
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
