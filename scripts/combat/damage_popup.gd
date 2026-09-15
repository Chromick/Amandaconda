extends Node3D
## Número de dano flutuante simples.

@onready var label: Label3D = $Label3D

var amount: float = 0.0
var color: Color = Color(1, 0.85, 0.35)
var _vel: Vector3 = Vector3(0, 1.8, 0)
var _life: float = 0.7


func _ready() -> void:
	label.text = str(int(round(amount)))
	label.modulate = color


func _process(delta: float) -> void:
	global_position += _vel * delta
	_vel.y = move_toward(_vel.y, 0.4, 3.0 * delta)
	_life -= delta
	label.modulate.a = clampf(_life / 0.7, 0.0, 1.0)
	if _life <= 0.0:
		queue_free()
