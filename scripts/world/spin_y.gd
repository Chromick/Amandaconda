extends Node3D
## Rotação contínua no eixo Y (ventilador etc.).

@export var speed: float = 2.2


func _process(delta: float) -> void:
	rotate_y(speed * delta)
