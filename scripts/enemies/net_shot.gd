extends Area3D
## Projétil da Net — marca e causa dano.

var velocity: Vector3 = Vector3.FORWARD
var damage: float = 11.0
var lifetime: float = 2.2
var mark_duration: float = 3.5
var mark_speed: float = 0.72
var source: Node = null


func setup(cfg: Dictionary, dir: Vector3, from: Node) -> void:
	source = from
	damage = float(cfg.get("dano", 11))
	mark_duration = float(cfg.get("mark_duration", 3.5))
	mark_speed = float(cfg.get("mark_speed_mult", 0.72))
	velocity = dir.normalized() * float(cfg.get("proj_speed", 14.0))
	body_entered.connect(_on_body)


func _physics_process(delta: float) -> void:
	lifetime -= delta
	if lifetime <= 0.0:
		queue_free()
		return
	global_position += velocity * delta


func _on_body(body: Node3D) -> void:
	if body == source:
		return
	if body.is_in_group("player") and body.has_method("take_damage"):
		body.take_damage(damage, velocity.normalized() * 2.0, source)
		if body.has_method("apply_mark"):
			body.apply_mark(mark_duration, mark_speed)
		queue_free()
	elif body is StaticBody3D:
		queue_free()
