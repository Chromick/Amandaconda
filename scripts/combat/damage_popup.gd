extends Node3D
## Número de dano flutuante simples.

@onready var label: Label3D = $Label3D

var amount: float = 0.0
var color: Color = Color(1, 0.85, 0.35)
var _vel: Vector3 = Vector3(0, 1.8, 0)
var _life: float = 0.75
var _scale_punch: float = 1.35


func _ready() -> void:
	label.text = str(int(round(amount)))
	label.modulate = color
	_vel = Vector3(randf_range(-0.45, 0.45), randf_range(1.6, 2.2), randf_range(-0.2, 0.2))
	scale = Vector3.ONE * _scale_punch


func _process(delta: float) -> void:
	global_position += _vel * delta
	_vel.y = move_toward(_vel.y, 0.35, 3.2 * delta)
	_life -= delta
	var a := clampf(_life / 0.75, 0.0, 1.0)
	label.modulate.a = a
	var s := lerpf(0.85, _scale_punch, a)
	scale = Vector3.ONE * s
	if _life <= 0.0:
		queue_free()
