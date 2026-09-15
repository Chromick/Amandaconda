extends Area3D
## Safezone — regenera vida e recarrega latas.

var _player_inside: Node = null
var _pulse: float = 0.0
var _ring: MeshInstance3D


func _ready() -> void:
	add_to_group("safezone")
	body_entered.connect(_on_enter)
	body_exited.connect(_on_exit)
	GameState.safezone_position = global_position + Vector3(0, 1, 0)
	_ensure_ring()


func _ensure_ring() -> void:
	_ring = MeshInstance3D.new()
	_ring.name = "SafeRing"
	var tor := TorusMesh.new()
	tor.inner_radius = 2.6
	tor.outer_radius = 2.85
	_ring.mesh = tor
	var mat := StandardMaterial3D.new()
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = Color(0.35, 0.95, 0.65, 0.22)
	mat.emission_enabled = true
	mat.emission = Color(0.3, 1.0, 0.55)
	mat.emission_energy_multiplier = 1.2
	_ring.material_override = mat
	_ring.position = Vector3(0, 0.08, 0)
	add_child(_ring)


func _on_enter(body: Node3D) -> void:
	if body.is_in_group("player"):
		_player_inside = body
		GameState.in_safezone = true
		var before := GameState.heals
		GameState.refill_heals()
		GameState.safezone_position = global_position + Vector3(0, 1, 0)
		if GameState.heals > before:
			GameState.show_toast("Safezone · latas cheias")
		else:
			GameState.show_toast("Safezone · em segurança")
		if typeof(HitFeel) != TYPE_NIL:
			HitFeel.spark_at(global_position + Vector3.UP * 0.5, Color(0.4, 1.0, 0.6), 0.8)


func _on_exit(body: Node3D) -> void:
	if body == _player_inside:
		_player_inside = null
		GameState.in_safezone = false


func _physics_process(delta: float) -> void:
	_pulse += delta
	if _ring and _ring.material_override is StandardMaterial3D:
		var mat := _ring.material_override as StandardMaterial3D
		var active := _player_inside != null and is_instance_valid(_player_inside)
		var base_a := 0.38 if active else 0.18
		mat.albedo_color.a = base_a + sin(_pulse * 3.5) * 0.06
		mat.emission_energy_multiplier = (1.8 if active else 1.0) + sin(_pulse * 4.0) * 0.25
		_ring.rotation.y = _pulse * 0.4
	if _player_inside == null or not is_instance_valid(_player_inside):
		return
	if _player_inside.has_method("heal"):
		var rate := float(Balance.data.get("cura", {}).get("safezone_regen", 18.0))
		_player_inside.heal(rate * delta)
