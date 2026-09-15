extends "res://scripts/enemies/enemy_base.gd"
## Chatana — pulso sônico AOE (arte Chatana3D / alto-falantes).

enum Phase { IDLE, WINDUP, ACTIVE, RECOVER }

const AttackTelegraphScript := preload("res://scripts/combat/attack_telegraph.gd")

var _phase: Phase = Phase.IDLE
var _phase_t: float = 0.0
var _windup_total: float = 0.4
var _cooldown: float = 1.0
var _pulse: Area3D
var _pulse_mesh: MeshInstance3D
var _pulse_mat: StandardMaterial3D
var _base_color := Color(0.55, 0.58, 0.62)
var _pulse_radius: float = 2.4
var _wave_ring: MeshInstance3D
var _enraged: bool = false


func _ready() -> void:
	balance_key = "chatana"
	_pulse = $Pulse
	_pulse_mesh = $Pulse/Mesh
	_pulse.monitoring = false
	_pulse.body_entered.connect(_on_pulse_body)
	_pulse_mat = StandardMaterial3D.new()
	_pulse_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_pulse_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_pulse_mat.albedo_color = Color(1.0, 0.85, 0.35, 0.28)
	_pulse_mat.emission_enabled = true
	_pulse_mat.emission = Color(1.0, 0.75, 0.25)
	_pulse_mat.emission_energy_multiplier = 1.7
	if _pulse_mesh:
		_pulse_mesh.material_override = _pulse_mat
	super._ready()
	_wave_ring = AttackTelegraphScript.make_sphere(
		self, 0.9, Vector3(0, 1.05, 0), Color(1.0, 0.88, 0.4, 0.25)
	)


func _on_balance_applied() -> void:
	_base_color = Color(0.55, 0.58, 0.62)
	if not _dead:
		_restore_color()
	if _pulse == null:
		return
	_pulse_radius = float(_cfg.get("raio", 2.4))
	var shape_node := _pulse.get_node_or_null("Shape") as CollisionShape3D
	if shape_node and shape_node.shape is SphereShape3D:
		(shape_node.shape as SphereShape3D).radius = _pulse_radius
	if _pulse_mesh and _pulse_mesh.mesh is SphereMesh:
		(_pulse_mesh.mesh as SphereMesh).radius = _pulse_radius
		(_pulse_mesh.mesh as SphereMesh).height = _pulse_radius * 2.0
		_pulse_mesh.visible = false


func _restore_color() -> void:
	_set_color(_base_color)


func _visual_action() -> String:
	match _phase:
		Phase.WINDUP:
			return "Idle_Attack"
		Phase.ACTIVE:
			return "Punch"
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
			velocity.x = move_toward(velocity.x, 0.0, 8.0 * delta)
			velocity.z = move_toward(velocity.z, 0.0, 8.0 * delta)
			_set_color(Color(1.0, 0.9, 0.35))
			_update_pulse_telegraph(true, false)
			if _phase_t <= 0.0:
				_phase = Phase.ACTIVE
				_phase_t = float(_cfg.get("acerto", 0.35))
				_pulse.monitoring = true
				_update_pulse_telegraph(true, true)
				HitFeel.shake(0.18)
				_hit_players_in_pulse()
		Phase.ACTIVE:
			_phase_t -= delta
			velocity = Vector3.ZERO
			_update_pulse_telegraph(true, true)
			if _phase_t <= 0.0:
				_phase = Phase.RECOVER
				_phase_t = float(_cfg.get("recuperacao", 0.5))
				_pulse.monitoring = false
				_update_pulse_telegraph(false, false)
				_restore_color()
		Phase.RECOVER:
			_phase_t -= delta
			velocity = Vector3.ZERO
			if _phase_t <= 0.0:
				_phase = Phase.IDLE
				_cooldown = float(_cfg.get("intervalo", 2.0)) * (0.7 if _enraged else 1.0)
	move_and_slide()
	_check_enrage()


func _check_enrage() -> void:
	if _enraged or _dead:
		return
	if health <= max_health * 0.4:
		_enraged = true
		_base_color = Color(0.85, 0.55, 0.25)
		_restore_color()
		_pulse_radius *= 1.12
		GameState.show_toast("CHATANA · feedback alto")
		if typeof(HitFeel) != TYPE_NIL:
			HitFeel.shake(0.22)
			HitFeel.spark_at(global_position + Vector3.UP * 1.1, Color(1.0, 0.85, 0.35), 1.05)


func _update_pulse_telegraph(active: bool, flash: bool) -> void:
	if _pulse_mesh == null or not (_pulse_mesh.mesh is SphereMesh):
		return
	_pulse_mesh.visible = active
	AttackTelegraphScript.set_active(_wave_ring, active, flash)
	if not active:
		return
	var sm := _pulse_mesh.mesh as SphereMesh
	var t := 1.0
	if _windup_total > 0.001 and _phase == Phase.WINDUP:
		t = 1.0 - clampf(_phase_t / _windup_total, 0.0, 1.0)
	var r := _pulse_radius * (0.25 + 0.75 * t) if _phase == Phase.WINDUP else _pulse_radius
	sm.radius = r
	sm.height = r * 2.0
	if _pulse_mat:
		if _enraged:
			_pulse_mat.albedo_color = Color(1.0, 0.55, 0.2, 0.6) if flash else Color(1.0, 0.5, 0.15, 0.28 + 0.22 * t)
			_pulse_mat.emission = Color(1.0, 0.6, 0.2) if flash else Color(1.0, 0.45, 0.1)
			_pulse_mat.emission_energy_multiplier = 3.2 if flash else 1.8 + t
		else:
			_pulse_mat.albedo_color = Color(1.0, 0.95, 0.55, 0.55) if flash else Color(1.0, 0.82, 0.3, 0.22 + 0.22 * t)
			_pulse_mat.emission = Color(1.0, 0.95, 0.6) if flash else Color(1.0, 0.75, 0.25)
			_pulse_mat.emission_energy_multiplier = 2.8 if flash else 1.5 + t
	# Anel de onda um pouco à frente do raio
	if _wave_ring and _wave_ring.mesh is SphereMesh:
		var wr := r * (1.08 if flash else 0.55 + 0.5 * t)
		var wm := _wave_ring.mesh as SphereMesh
		wm.radius = wr
		wm.height = wr * 0.22
		_wave_ring.position = Vector3(0, 1.05, 0)


func _ai_idle(delta: float) -> void:
	var player := _wants_player_combat()
	if player == null:
		_idle_or_home(delta, 2.4)
		return
	var to := player.global_position - global_position
	to.y = 0.0
	var dist := to.length()
	var prefer := float(_cfg.get("prefer_distance", 5.5))
	var spd := float(_cfg.get("velocidade", 3.2)) * move_scale()
	if _enraged:
		spd *= 1.2
	if dist > 0.01:
		var dir := to.normalized()
		_face_flat(dir)
		if dist > prefer + 0.6:
			velocity.x = dir.x * spd
			velocity.z = dir.z * spd
		elif dist < prefer - 0.8:
			velocity.x = -dir.x * spd
			velocity.z = -dir.z * spd
		else:
			var side := Vector3(-dir.z, 0.0, dir.x)
			velocity.x = side.x * spd * 0.55
			velocity.z = side.z * spd * 0.55

	_cooldown -= delta
	if _cooldown <= 0.0 and dist <= prefer + 2.5:
		if randf() <= 0.28:
			var side := Vector3(-to.normalized().z, 0.0, to.normalized().x)
			velocity.x = side.x * spd
			velocity.z = side.z * spd
			_cooldown = 0.4
			return
		_phase = Phase.WINDUP
		_windup_total = float(_cfg.get("preparacao", 0.4)) * (0.75 if _enraged else 1.0)
		_phase_t = _windup_total
		velocity = Vector3.ZERO
		_update_pulse_telegraph(true, false)
		if typeof(HitFeel) != TYPE_NIL:
			HitFeel.shake(0.07)


func _hit_players_in_pulse() -> void:
	for body in _pulse.get_overlapping_bodies():
		_try_damage(body)


func _on_pulse_body(body: Node3D) -> void:
	if _phase == Phase.ACTIVE:
		_try_damage(body)


func _try_damage(body: Node) -> void:
	if body == null or not body.is_in_group("player"):
		return
	if body.has_method("take_damage"):
		var away: Vector3 = body.global_position - global_position
		away.y = 0.0
		if away.length_squared() < 0.01:
			away = Vector3.FORWARD
		var dmg := float(_cfg.get("dano", 8)) * (1.12 if _enraged else 1.0)
		body.take_damage(dmg, away.normalized() * (3.4 if _enraged else 3.0), self)
		HitFeel.spark_at(body.global_position + Vector3.UP * 1.0, Color(1.0, 0.85, 0.35), 0.9)
