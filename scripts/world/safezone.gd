extends Area3D
## Safezone — regenera vida e recarrega latas.

var _player_inside: Node = null


func _ready() -> void:
	add_to_group("safezone")
	body_entered.connect(_on_enter)
	body_exited.connect(_on_exit)
	GameState.safezone_position = global_position + Vector3(0, 1, 0)


func _on_enter(body: Node3D) -> void:
	if body.is_in_group("player"):
		_player_inside = body
		GameState.in_safezone = true
		GameState.refill_heals()
		GameState.safezone_position = global_position + Vector3(0, 1, 0)


func _on_exit(body: Node3D) -> void:
	if body == _player_inside:
		_player_inside = null
		GameState.in_safezone = false


func _physics_process(delta: float) -> void:
	if _player_inside == null or not is_instance_valid(_player_inside):
		return
	if _player_inside.has_method("heal"):
		var rate := float(Balance.data.get("cura", {}).get("safezone_regen", 18.0))
		_player_inside.heal(rate * delta)
