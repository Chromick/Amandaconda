extends Area3D
## Pickup de Bytes (KB).

@export var amount_min: int = 16
@export var amount_max: int = 32

@onready var label: Label3D = $Label3D

var _spin: float = 0.0


func _ready() -> void:
	body_entered.connect(_on_body)
	label.text = "%d–%d KB" % [amount_min, amount_max]


func _process(delta: float) -> void:
	_spin += delta
	rotation.y = _spin * 1.6
	position.y = 0.85 + sin(_spin * 3.0) * 0.08


func _on_body(body: Node3D) -> void:
	if body == null or not body.is_in_group("player"):
		return
	var got := randi_range(amount_min, amount_max)
	GameState.add_bytes(got)
	GameState.show_toast("+%d KB" % got)
	if typeof(HitFeel) != TYPE_NIL:
		HitFeel.spark_at(global_position + Vector3.UP * 0.4, Color(0.95, 0.85, 0.35), 0.9)
	queue_free()
