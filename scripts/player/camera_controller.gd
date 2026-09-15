extends Node3D
## Câmera terceira pessoa com orbit + lock-on + auto-yaw + shake.

@export var player_path: NodePath
@onready var pivot: Node3D = $Pivot
@onready var spring: SpringArm3D = $Pivot/SpringArm3D
@onready var camera: Camera3D = $Pivot/SpringArm3D/Camera3D

var _player: Node3D
var yaw: float = 0.0
var pitch: float = -12.0
var _look_idle: float = 0.0
var trauma: float = 0.0
var _base_fov: float = 70.0
var _fov_target: float = 70.0
var _fov_punch: float = 0.0


func _ready() -> void:
	add_to_group("player_camera")
	if player_path:
		_player = get_node_or_null(player_path)
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	Balance.reloaded.connect(_apply_balance)
	_apply_balance()
	if camera:
		_base_fov = camera.fov
		_fov_target = _base_fov


func _apply_balance() -> void:
	var cam := Balance.camera()
	spring.spring_length = float(cam.get("distance", 4.5))
	pivot.position.y = float(cam.get("height", 1.6))
	if camera and cam.has("fov"):
		_base_fov = float(cam.get("fov", camera.fov))
		_fov_target = _base_fov
		camera.fov = _base_fov


func add_trauma(amount: float) -> void:
	trauma = clampf(trauma + amount, 0.0, 1.0)


func punch_fov(amount: float = 8.0) -> void:
	## Kick breve no FOV (hit / impacto). Empilha e decai sem brigar com sprint/lock.
	_fov_punch = amount
	if camera:
		camera.fov = _fov_target + amount


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		else:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		get_viewport().set_input_as_handled()
		return

	if Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
		return

	if event is InputEventMouseMotion:
		var sens := float(Balance.camera().get("sensitivity", 0.12))
		yaw -= event.relative.x * sens * 0.01
		pitch -= event.relative.y * sens * 0.01
		var cam := Balance.camera()
		pitch = clampf(pitch, float(cam.get("min_pitch", -40.0)), float(cam.get("max_pitch", 55.0)))
		_look_idle = float(cam.get("idle_yaw_delay", 1.1))


func _physics_process(delta: float) -> void:
	if _player == null or not is_instance_valid(_player):
		return

	var follow := float(Balance.camera().get("follow_speed", 10.0))
	global_position = global_position.lerp(_player.global_position, clampf(follow * delta, 0.0, 1.0))

	var lock_target: Node3D = null
	if _player.get("lock_target") != null:
		lock_target = _player.lock_target as Node3D

	if lock_target and is_instance_valid(lock_target):
		var bias := float(Balance.camera().get("lock_on_height_bias", 1.2))
		var to := lock_target.global_position + Vector3.UP * bias - global_position
		var target_yaw := atan2(-to.x, -to.z)
		var flat_len := Vector2(to.x, to.z).length()
		var target_pitch := rad_to_deg(atan2(to.y, flat_len))
		yaw = lerp_angle(yaw, target_yaw, clampf(10.5 * delta, 0.0, 1.0))
		pitch = lerpf(pitch, clampf(target_pitch, -30.0, 40.0), clampf(10.5 * delta, 0.0, 1.0))
	else:
		if _look_idle > 0.0:
			_look_idle -= delta
		else:
			var speed_xz := 0.0
			if _player is CharacterBody3D:
				var v := (_player as CharacterBody3D).velocity
				speed_xz = Vector3(v.x, 0.0, v.z).length()
			if speed_xz > 1.2:
				var auto_spd := float(Balance.camera().get("idle_yaw_speed", 3.5))
				yaw = lerp_angle(yaw, _player.rotation.y, clampf(auto_spd * delta, 0.0, 1.0))

	rotation.y = yaw
	pivot.rotation.x = deg_to_rad(pitch)

	# FOV: sprint abre um pouco; lock-on fecha levemente.
	var sprinting := false
	if _player is CharacterBody3D and Input.is_action_pressed("sprint"):
		var v := (_player as CharacterBody3D).velocity
		sprinting = Vector3(v.x, 0.0, v.z).length() > 1.0
	if lock_target and is_instance_valid(lock_target):
		_fov_target = _base_fov - 6.0
		# Aproxima um pouco no lock
		var lock_len := float(Balance.camera().get("distance", 4.5)) * 0.86
		spring.spring_length = lerpf(spring.spring_length, lock_len, clampf(6.0 * delta, 0.0, 1.0))
	elif sprinting:
		_fov_target = _base_fov + 9.0
		var run_len := float(Balance.camera().get("distance", 4.5)) * 1.08
		spring.spring_length = lerpf(spring.spring_length, run_len, clampf(4.5 * delta, 0.0, 1.0))
	else:
		_fov_target = _base_fov
		var base_len := float(Balance.camera().get("distance", 4.5))
		spring.spring_length = lerpf(spring.spring_length, base_len, clampf(4.0 * delta, 0.0, 1.0))
	if _fov_punch != 0.0:
		_fov_punch = move_toward(_fov_punch, 0.0, 48.0 * delta)
	if camera:
		camera.fov = lerpf(camera.fov, _fov_target + _fov_punch, clampf(8.5 * delta, 0.0, 1.0))

	if trauma > 0.0:
		var decay := float(Balance.get_path_value("impacto.shake_decay", 1.7))
		trauma = maxf(0.0, trauma - decay * delta)
		var shake := trauma * trauma
		var amp := float(Balance.get_path_value("impacto.shake_amp", 0.28))
		camera.h_offset = randf_range(-1.0, 1.0) * shake * amp
		camera.v_offset = randf_range(-1.0, 1.0) * shake * amp * 0.75
	else:
		camera.h_offset = 0.0
		camera.v_offset = 0.0
