extends Node
## Feel de combate compartilhado (hitstop + shake + spark).

const SPARK_SCRIPT := preload("res://scripts/combat/hit_spark.gd")
const SceneUtil := preload("res://scripts/combat/scene_util.gd")

var _hitstop_token: int = 0


func cancel() -> void:
	## Cancela hitstop pendente e garante time_scale normal (pause/morte/menu).
	_hitstop_token += 1
	Engine.time_scale = 1.0


func punch(duration: float = -1.0, fov_kick: float = 5.0) -> void:
	if duration < 0.0:
		duration = float(Balance.get_path_value("impacto.pausa_no_acerto", 0.07))
	if duration <= 0.0:
		return
	_hitstop_token += 1
	var token := _hitstop_token
	Engine.time_scale = 0.12
	if fov_kick != 0.0:
		kick_fov(fov_kick, 0.12)
	await get_tree().create_timer(duration, true, false, true).timeout
	if token == _hitstop_token:
		Engine.time_scale = 1.0


func kill_punch(duration: float = -1.0) -> void:
	if duration < 0.0:
		duration = float(Balance.get_path_value("impacto.pausa_ao_matar", 0.22))
	shake(0.55)
	await punch(duration, 7.5)


func shake(amount: float = -1.0) -> void:
	if amount < 0.0:
		amount = float(Balance.get_path_value("impacto.shake_on_hit", 0.38))
	for node in get_tree().get_nodes_in_group("player_camera"):
		if node and node.has_method("add_trauma"):
			node.add_trauma(amount)


func kick_fov(degrees: float = 5.0, _duration: float = 0.12) -> void:
	for node in get_tree().get_nodes_in_group("player_camera"):
		if node and node.has_method("punch_fov"):
			node.punch_fov(degrees)


func spark_at(pos: Vector3, color: Color = Color(1.0, 0.85, 0.35), scale_u: float = 1.0) -> void:
	var spark := Node3D.new()
	spark.set_script(SPARK_SCRIPT)
	if not SceneUtil.add_to_world(spark, self, pos):
		return
	if spark.has_method("setup"):
		spark.call("setup", color, scale_u)
