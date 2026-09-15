extends Area3D
## Projétil da escola Especial (vírus).

var velocity: Vector3 = Vector3.FORWARD
var damage: float = 9.0
var lifetime: float = 1.1
var bounce: float = 0.35
var knock_strength: float = 2.0
var source: Node = null

var _bounces_left: int = 2


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
	var mesh := $Mesh
	if mesh and mesh.mesh is SphereMesh:
		(mesh.mesh as SphereMesh).radius = r
		(mesh.mesh as SphereMesh).height = r * 2.0


func _physics_process(delta: float) -> void:
	lifetime -= delta
	if lifetime <= 0.0:
		queue_free()
		return
	global_position += velocity * delta
	if velocity.length_squared() > 0.01:
		look_at(global_position + velocity, Vector3.UP)


func _on_body_entered(body: Node3D) -> void:
	if body == source:
		return
	if body.is_in_group("player"):
		return
	if body.has_method("take_damage"):
		var knock := velocity.normalized() * knock_strength
		body.take_damage(damage, knock, source)
		queue_free()
		return
	_try_bounce(body)


func _on_area_entered(area: Area3D) -> void:
	var parent := area.get_parent()
	if parent and parent.has_method("take_damage") and parent != source:
		parent.take_damage(damage, velocity.normalized() * knock_strength, source)
		queue_free()


func _try_bounce(_body: Node3D) -> void:
	if _bounces_left <= 0 or bounce <= 0.0:
		queue_free()
		return
	_bounces_left -= 1
	# Reflexão simples no eixo dominante (bom o bastante pra arena).
	if absf(velocity.x) > absf(velocity.z):
		velocity.x = -velocity.x * bounce
	else:
		velocity.z = -velocity.z * bounce
	velocity.y = absf(velocity.y) * 0.2
