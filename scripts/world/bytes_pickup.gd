extends Area3D
## Pickup de Bytes (KB).

@export var amount_min: int = 16
@export var amount_max: int = 32

@onready var label: Label3D = $Label3D


func _ready() -> void:
	body_entered.connect(_on_body)
	label.text = "%d–%d KB" % [amount_min, amount_max]


func _on_body(body: Node3D) -> void:
	if body == null or not body.is_in_group("player"):
		return
	GameState.add_bytes(randi_range(amount_min, amount_max))
	queue_free()
