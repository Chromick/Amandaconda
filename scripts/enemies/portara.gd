extends "res://scripts/enemies/enemy_base.gd"
## Portara — muro lento que aproxima e golpeia em melee.

enum Phase { IDLE, WINDUP, ACTIVE, RECOVER }

const AttackTelegraphScript := preload("res://scripts/combat/attack_telegraph.gd")

var _phase: Phase = Phase.IDLE
var _phase_t: float = 0.0
var _cooldown: float = 0.8
var _hitbox: Area3D
var _hit_done: bool = false
var _base_color := Color(0.55, 0.48, 0.42)
var _telegraph: MeshInstance3D
var _enraged: bool = false


func _ready() -> void:
	balance_key = "portara"
	_hitbox = $AttackHitbox
	_hitbox.monitoring = false
	_hitbox.body_entered.connect(_on_hit_body)
	super._ready()
	_ensure_telegraph()


func _ensure_telegraph() -> void:
	if _telegraph != null or _hitbox == null:
		return
	var alcance := float(_cfg.get("alcance", 1.4))
	var altura := float(_cfg.get("altura", 1.6))
	# Porta/madeira — tom da arte Portara3D
	_telegraph = AttackTelegraphScript.make_box(
		self,
		Vector3(1.15, altura, alcance),
		Vector3(0.0, 1.0, alcance * 0.45),
		Color(0.72, 0.48, 0.28, 0.34)
	)


func _on_balance_applied() -> void:
	_base_color = Color(0.55, 0.48, 0.42)
	if not _dead:
		_restore_color()
	if _hitbox == null:
		return
	var alcance := float(_cfg.get("alcance", 1.4))
	var altura := float(_cfg.get("altura", 1.6))
	var shape_node := _hitbox.get_node_or_null("Shape") as CollisionShape3D
	if shape_node and shape_node.shape is BoxShape3D:
		(shape_node.shape as BoxShape3D).size = Vector3(1.2, altura, alcance)
	_hitbox.position = Vector3(0.0, 1.0, alcance * 0.45)
	if _telegraph:
		if _telegraph.mesh is BoxMesh:
			(_telegraph.mesh as BoxMesh).size = Vector3(1.15, altura, alcance)
		_telegraph.position = Vector3(0.0, 1.0, alcance * 0.45)


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
			_ai_chase(delta)
		Phase.WINDUP:
			_phase_t -= delta
			velocity.x = move_toward(velocity.x, 0.0, 10.0 * delta)
			velocity.z = move_toward(velocity.z, 0.0, 10.0 * delta)
			_set_color(Color(0.95, 0.55, 0.25))
			AttackTelegraphScript.set_active(_telegraph, true, false)
			_tint_telegraph(false)
			if _phase_t <= 0.0:
				_phase = Phase.ACTIVE
				_phase_t = float(_cfg.get("acerto", 0.14))
				_hit_done = false
				_hitbox.monitoring = true
				AttackTelegraphScript.set_active(_telegraph, true, true)
				_tint_telegraph(true)
		Phase.ACTIVE:
			_phase_t -= delta
			velocity = Vector3.ZERO
			var forward := -global_transform.basis.z
			velocity.x = forward.x * 2.5
			velocity.z = forward.z * 2.5
			if _phase_t <= 0.0:
				_phase = Phase.RECOVER
				_phase_t = float(_cfg.get("recuperacao", 0.7))
				_hitbox.monitoring = false
				AttackTelegraphScript.set_active(_telegraph, false)
				_restore_color()
		Phase.RECOVER:
			_phase_t -= delta
			velocity.x = move_toward(velocity.x, 0.0, 12.0 * delta)
			velocity.z = move_toward(velocity.z, 0.0, 12.0 * delta)
			if _phase_t <= 0.0:
				_phase = Phase.IDLE
				_cooldown = float(_cfg.get("intervalo", 1.8)) * (0.65 if _enraged else 1.0)
	move_and_slide()
	_check_enrage()


func _check_enrage() -> void:
	if _enraged or _dead:
		return
	if health <= max_health * 0.5:
		_enraged = true
		_base_color = Color(0.75, 0.35, 0.22)
		_restore_color()
		GameState.show_toast("PORTARA · tranca furiosa")
		if typeof(HitFeel) != TYPE_NIL:
			HitFeel.shake(0.32)
			HitFeel.spark_at(global_position + Vector3.UP * 1.2, Color(0.9, 0.4, 0.2), 1.4)
			HitFeel.kick_fov(6.0, 0.2)
		scale = Vector3(1.14, 0.92, 1.14)
		var tw := create_tween()
		tw.tween_property(self, "scale", Vector3.ONE, 0.16).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _ai_chase(delta: float) -> void:
	var player := _wants_player_combat()
	if player == null:
		_idle_or_home(delta, 1.8)
		return
	var to := player.global_position - global_position
	to.y = 0.0
	var dist := to.length()
	var alcance := float(_cfg.get("alcance", 1.4))
	var spd := float(_cfg.get("velocidade", 2.0)) * move_scale()
	if _enraged:
		spd *= 1.25
	if dist > 0.05:
		var dir := to.normalized()
		_face_flat(dir)
		if dist > alcance * 0.85:
			velocity.x = dir.x * spd
			velocity.z = dir.z * spd
		elif dist < alcance * 0.4:
			velocity.x = -dir.x * spd * 0.7
			velocity.z = -dir.z * spd * 0.7
		else:
			var side := Vector3(-dir.z, 0.0, dir.x)
			velocity.x = side.x * spd * 0.45
			velocity.z = side.z * spd * 0.45

	_cooldown -= delta
	if _cooldown <= 0.0 and dist <= alcance + 0.35:
		if randf() <= 0.3 and dist < alcance:
			velocity.x = -to.normalized().x * spd
			velocity.z = -to.normalized().z * spd
			_cooldown = 0.45
			return
		_phase = Phase.WINDUP
		_phase_t = float(_cfg.get("preparacao", 0.5)) * (0.7 if _enraged else 1.0)
		velocity = Vector3.ZERO
		AttackTelegraphScript.set_active(_telegraph, true, false)
		_tint_telegraph(false)
		if typeof(HitFeel) != TYPE_NIL:
			HitFeel.shake(0.08)


func _tint_telegraph(flash: bool) -> void:
	if _telegraph == null or not _enraged:
		return
	var mat := _telegraph.material_override as StandardMaterial3D
	if mat == null:
		return
	mat.albedo_color = Color(1.0, 0.25, 0.15, 0.6 if flash else 0.4)
	mat.emission = Color(1.0, 0.3, 0.1)
	mat.emission_energy_multiplier = 3.0 if flash else 2.0


func _on_hit_body(body: Node3D) -> void:
	if _phase != Phase.ACTIVE or _hit_done:
		return
	if body == null or not body.is_in_group("player"):
		return
	if body.has_method("take_damage"):
		_hit_done = true
		var forward := -global_transform.basis.z
		var dmg := float(_cfg.get("dano", 16)) * (1.15 if _enraged else 1.0)
		body.take_damage(dmg, forward * (5.5 if _enraged else 5.0), self)
		HitFeel.punch(0.035)
		HitFeel.shake(0.28)
		HitFeel.spark_at(body.global_position + Vector3.UP * 1.1, Color(0.85, 0.55, 0.3), 1.1)
