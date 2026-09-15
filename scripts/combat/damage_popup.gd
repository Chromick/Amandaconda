extends Node3D
## Número de dano flutuante simples.

@onready var label: Label3D = $Label3D

var amount: float = 0.0
var color: Color = Color(1, 0.85, 0.35)
var _vel: Vector3 = Vector3(0, 1.8, 0)
var _life: float = 0.75
var _life_max: float = 0.75
var _scale_punch: float = 1.35


func _ready() -> void:
	label.text = str(int(round(amount)))
	label.modulate = color
	label.outline_modulate = Color(0, 0, 0, 0.9)
	label.outline_size = 8
	# Hits maiores: sobem mais, vivem mais, punch maior.
	var big := clampf((amount - 12.0) / 40.0, 0.0, 1.0)
	_scale_punch = lerpf(1.25, 1.7, big)
	_life_max = lerpf(0.7, 1.05, big)
	_life = _life_max
	_vel = Vector3(randf_range(-0.45, 0.45), randf_range(1.55, 2.35) + big * 0.45, randf_range(-0.2, 0.2))
	scale = Vector3.ONE * _scale_punch
	if big > 0.55:
		label.text = str(int(round(amount))) + "!"


func _process(delta: float) -> void:
	global_position += _vel * delta
	_vel.y = move_toward(_vel.y, 0.35, 3.2 * delta)
	_life -= delta
	var a := clampf(_life / _life_max, 0.0, 1.0)
	label.modulate.a = a
	var s := lerpf(0.85, _scale_punch, a)
	scale = Vector3.ONE * s
	if _life <= 0.0:
		queue_free()
