extends "res://scripts/enemies/enemy_base.gd"
## Net — antena que marca o jogador e dispara projétil.

enum Phase { IDLE, WINDUP, ACTIVE, RECOVER }

const SHOT_SCENE := preload("res://scenes/enemies/net_shot.tscn")
const AttackTelegraphScript := preload("res://scripts/combat/attack_telegraph.gd")

var _phase: Phase = Phase.IDLE
var _phase_t: float = 0.0
var _windup_total: float = 0.55
var _cooldown: float = 1.2
var _base_color := Color(0.55, 0.4, 0.95)
var _beam: MeshInstance3D
var _aim_dir: Vector3 = Vector3.FORWARD


func _ready() -> void:
	balance_key = "net"
	super._ready()
	# Feixe magenta da ponta da antena (arte Net3D)
	_beam = AttackTelegraphScript.make_box(
		self,
		Vector3(0.18, 0.18, 1.0),
		Vector3(0, 1.4, -0.5),
		Color(0.95, 0.25, 0.85, 0.42)
	)


func _on_balance_applied() -> void:
	_base_color = Color(0.55, 0.4, 0.95)
	if not _dead:
		_restore_color()


func _restore_color() -> void:
	_set_color(_base_color)


func _visual_action() -> String:
	match _phase:
		Phase.WINDUP, Phase.ACTIVE:
			return "Idle_Attack"
		Phase.RECOVER:
			return "Idle"
		_:
			return ""


func _physics_process(delta: float) -> void:
	if _dead:
		velocity = Vector3.ZERO
		return
	_apply_gravity(delta)
	match _phase:
		Phase.IDLE:
			_ai_idle(delta)
		Phase.WINDUP:
			_phase_t -= delta
			velocity = Vector3.ZERO
			_set_color(Color(1.0, 0.45, 0.95))
			_update_beam_telegraph(true, false)
			if _phase_t <= 0.0:
				_phase = Phase.ACTIVE
				_phase_t = float(_cfg.get("acerto", 0.1))
				_update_beam_telegraph(true, true)
				_fire()
		Phase.ACTIVE:
			_phase_t -= delta
			_update_beam_telegraph(true, true)
			if _phase_t <= 0.0:
				_phase = Phase.RECOVER
				_phase_t = float(_cfg.get("recuperacao", 0.7))
				_update_beam_telegraph(false, false)
				_restore_color()
		Phase.RECOVER:
			_phase_t -= delta
			if _phase_t <= 0.0:
				_phase = Phase.IDLE
				_cooldown = float(_cfg.get("intervalo", 2.4))
	move_and_slide()


func _update_beam_telegraph(active: bool, flash: bool) -> void:
	if _beam == null:
		return
	AttackTelegraphScript.set_active(_beam, active, flash)
	if not active:
		return
	var player := _get_player()
	if player:
		_aim_dir = player.global_position + Vector3.UP * 1.0 - (global_position + Vector3.UP * 1.4)
		_aim_dir.y = 0.0
		if _aim_dir.length_squared() < 0.01:
			_aim_dir = -global_transform.basis.z
		else:
			_aim_dir = _aim_dir.normalized()
	var t := 1.0
	if _windup_total > 0.001 and _phase == Phase.WINDUP:
		t = 1.0 - clampf(_phase_t / _windup_total, 0.0, 1.0)
	var len := lerpf(2.0, 10.0, t)
	if _beam.mesh is BoxMesh:
		(_beam.mesh as BoxMesh).size = Vector3(0.16, 0.16, len)
	_beam.position = Vector3(0, 1.4, 0) + (-global_transform.basis.z) * (len * 0.5)
	# Alinha o feixe com a mira plana
	if _aim_dir.length_squared() > 0.01:
		var look := global_position + Vector3.UP * 1.4 + _aim_dir
		_beam.look_at(look, Vector3.UP)


func _ai_idle(delta: float) -> void:
	var player := _wants_player_combat()
	if player == null:
		_idle_or_home(delta, 1.2)
		return
	var to: Vector3 = player.global_position - global_position
	to.y = 0.0
	var dist := to.length()
	var prefer := float(_cfg.get("prefer_distance", 9.0))
	var spd := float(_cfg.get("velocidade", 1.4)) * move_scale()
	if dist > 0.01:
		var dir := to.normalized()
		_face_flat(dir)
		if dist > prefer + 1.0:
			velocity.x = dir.x * spd
			velocity.z = dir.z * spd
		elif dist < prefer - 1.5:
			velocity.x = -dir.x * spd
			velocity.z = -dir.z * spd
		else:
			velocity.x = 0.0
			velocity.z = 0.0
	_cooldown -= delta
	if _cooldown <= 0.0 and dist < prefer + 4.0:
		_phase = Phase.WINDUP
		_windup_total = float(_cfg.get("preparacao", 0.55))
		_phase_t = _windup_total
		velocity = Vector3.ZERO
		_update_beam_telegraph(true, false)


func _fire() -> void:
	var player := _get_player()
	if player == null:
		return
	var shot := SHOT_SCENE.instantiate()
	var dir: Vector3 = player.global_position + Vector3.UP * 1.0 - (global_position + Vector3.UP * 1.4)
	if dir.length_squared() < 0.01:
		dir = -global_transform.basis.z
	var spawn_pos := global_position + Vector3.UP * 1.4
	if not SceneUtil.add_to_world(shot, self, spawn_pos):
		return
	shot.setup(_cfg, dir.normalized(), self)
