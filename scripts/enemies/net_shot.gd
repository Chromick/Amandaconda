extends Area3D
## Projétil da Net — marca e causa dano.

var velocity: Vector3 = Vector3.FORWARD
var damage: float = 11.0
var lifetime: float = 2.2
var mark_duration: float = 3.5
var mark_speed: float = 0.72
var source: Node = null
var _spin: float = 0.0
var _trail_cd: float = 0.0


func setup(cfg: Dictionary, dir: Vector3, from: Node) -> void:
	source = from
	damage = float(cfg.get("dano", 11))
	mark_duration = float(cfg.get("mark_duration", 3.5))
	mark_speed = float(cfg.get("mark_speed_mult", 0.72))
	velocity = dir.normalized() * float(cfg.get("proj_speed", 14.0))
	body_entered.connect(_on_body)
	var mesh := get_node_or_null("Mesh") as MeshInstance3D
	if mesh:
		var mat := StandardMaterial3D.new()
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		mat.albedo_color = Color(0.95, 0.3, 0.9)
		mat.emission_enabled = true
		mat.emission = Color(0.9, 0.2, 0.85)
		mat.emission_energy_multiplier = 2.6
		mesh.material_override = mat
	var light := OmniLight3D.new()
	light.light_color = Color(0.95, 0.35, 0.9)
	light.light_energy = 1.8
	light.omni_range = 3.0
	add_child(light)


func _physics_process(delta: float) -> void:
	lifetime -= delta
	if lifetime <= 0.0:
		queue_free()
		return
	global_position += velocity * delta
	_spin += delta * 10.0
	rotation.y = _spin
	if velocity.length_squared() > 0.01:
		var tip := global_position + velocity.normalized()
		if absf(velocity.normalized().dot(Vector3.UP)) < 0.98:
			look_at(tip, Vector3.UP)
	_trail_cd -= delta
	if _trail_cd <= 0.0:
		_trail_cd = 0.045
		_spawn_trail()


func _spawn_trail() -> void:
	var host := get_tree().current_scene
	if host == null:
		return
	var p := MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = 0.07
	sm.height = 0.14
	p.mesh = sm
	var mat := StandardMaterial3D.new()
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = Color(0.95, 0.35, 0.9, 0.5)
	mat.emission_enabled = true
	mat.emission = Color(0.9, 0.25, 0.85)
	mat.emission_energy_multiplier = 1.5
	p.material_override = mat
	host.add_child(p)
	p.global_position = global_position
	var tw := create_tween()
	tw.tween_property(mat, "albedo_color:a", 0.0, 0.2)
	tw.parallel().tween_property(p, "scale", Vector3.ONE * 0.2, 0.2)
	tw.tween_callback(p.queue_free)


func _on_body(body: Node3D) -> void:
	if body == source:
		return
	if body.is_in_group("player") and body.has_method("take_damage"):
		body.take_damage(damage, velocity.normalized() * 2.0, source)
		if body.has_method("apply_mark"):
			body.apply_mark(mark_duration, mark_speed)
		if typeof(HitFeel) != TYPE_NIL:
			HitFeel.spark_at(global_position, Color(0.95, 0.3, 0.9), 1.0)
		queue_free()
	elif body is StaticBody3D:
		if typeof(HitFeel) != TYPE_NIL:
			HitFeel.spark_at(global_position, Color(0.8, 0.25, 0.75), 0.5)
		queue_free()
