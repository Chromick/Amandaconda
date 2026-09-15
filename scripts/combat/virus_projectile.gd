extends Area3D
## Projétil da escola Especial (vírus).

var velocity: Vector3 = Vector3.FORWARD
var damage: float = 9.0
var lifetime: float = 1.1
var bounce: float = 0.35
var knock_strength: float = 2.0
var source: Node = null

var _bounces_left: int = 2
var _trail_cd: float = 0.0
var _light: OmniLight3D
var _spent: bool = false


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)


func setup(cfg: Dictionary, dir: Vector3, from: Node) -> void:
	source = from
	damage = float(cfg.get("dano", 9))
	lifetime = float(cfg.get("tempo_de_vida", 1.1))
	bounce = float(cfg.get("quique", 0.35))
	var spd := float(cfg.get("velocidade", 12.0))
	velocity = dir.normalized() * spd
	var r := float(cfg.get("raio", 0.25))
	var shape := $CollisionShape3D.shape as SphereShape3D
	if shape:
		shape.radius = r
	var mesh := $Mesh as MeshInstance3D
	if mesh and mesh.mesh is SphereMesh:
		(mesh.mesh as SphereMesh).radius = r
		(mesh.mesh as SphereMesh).height = r * 2.0
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = Color(0.35, 1.0, 0.55)
	mat.emission_enabled = true
	mat.emission = Color(0.3, 1.0, 0.5)
	mat.emission_energy_multiplier = 3.2
	if mesh:
		mesh.material_override = mat
	_light = OmniLight3D.new()
	_light.light_color = Color(0.4, 1.0, 0.55)
	_light.light_energy = 2.6
	_light.omni_range = 4.0
	add_child(_light)


func _physics_process(delta: float) -> void:
	lifetime -= delta
	if lifetime <= 0.0:
		queue_free()
		return
	global_position += velocity * delta
	if velocity.length_squared() > 0.01:
		var tip := global_position + velocity.normalized()
		if absf(velocity.normalized().dot(Vector3.UP)) < 0.98:
			look_at(tip, Vector3.UP)
	_trail_cd -= delta
	if _trail_cd <= 0.0:
		_trail_cd = 0.022
		_spawn_trail()
	if _light:
		_light.light_energy = lerpf(_light.light_energy, 2.8, clampf(6.0 * delta, 0.0, 1.0))


func _spawn_trail() -> void:
	var host := get_tree().current_scene
	if host == null:
		return
	var p := MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = 0.095
	sm.height = 0.19
	p.mesh = sm
	var mat := StandardMaterial3D.new()
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = Color(0.4, 1.0, 0.55, 0.7)
	mat.emission_enabled = true
	mat.emission = Color(0.35, 1.0, 0.5)
	mat.emission_energy_multiplier = 2.2
	p.material_override = mat
	host.add_child(p)
	p.global_position = global_position
	var tw := create_tween()
	tw.tween_property(mat, "albedo_color:a", 0.0, 0.32)
	tw.parallel().tween_property(p, "scale", Vector3.ONE * 0.12, 0.32)
	tw.tween_callback(p.queue_free)


func _on_body_entered(body: Node3D) -> void:
	if _spent or body == source:
		return
	if body.is_in_group("player"):
		return
	if body.has_method("take_damage"):
		_spent = true
		var knock := velocity.normalized() * knock_strength
		body.take_damage(damage, knock, source)
		if typeof(HitFeel) != TYPE_NIL:
			HitFeel.spark_at(global_position, Color(0.45, 1.0, 0.55), 0.85)
			HitFeel.punch(0.04)
		if _light:
			_light.light_energy = 5.5
		queue_free()
		return
	_try_bounce(body)


func _on_area_entered(area: Area3D) -> void:
	if _spent:
		return
	var parent := area.get_parent()
	if parent and parent.has_method("take_damage") and parent != source:
		_spent = true
		parent.take_damage(damage, velocity.normalized() * knock_strength, source)
		if typeof(HitFeel) != TYPE_NIL:
			HitFeel.spark_at(global_position, Color(0.45, 1.0, 0.55), 0.7)
			HitFeel.punch(0.035)
		queue_free()


func _try_bounce(_body: Node3D) -> void:
	if _bounces_left <= 0 or bounce <= 0.0:
		queue_free()
		return
	_bounces_left -= 1
	if absf(velocity.x) > absf(velocity.z):
		velocity.x = -velocity.x * bounce
	else:
		velocity.z = -velocity.z * bounce
	velocity.y = absf(velocity.y) * 0.2
	lifetime = maxf(lifetime, 0.35)
	if typeof(HitFeel) != TYPE_NIL:
		HitFeel.spark_at(global_position, Color(0.5, 1.0, 0.6), 0.45)
	if _light:
		_light.light_energy = 3.5
