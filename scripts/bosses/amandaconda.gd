extends "res://scripts/enemies/enemy_base.gd"
## Amandaconda — chefe final, duas fases. Começa "de boa", depois cobra.

enum Phase { IDLE, WINDUP, ACTIVE, RECOVER }

const AttackTelegraphScript := preload("res://scripts/combat/attack_telegraph.gd")

var _phase: Phase = Phase.IDLE
var _phase_t: float = 0.0
var _cooldown: float = 1.5
var _heavy: bool = false
var _phase2: bool = false
var _awakened: bool = false
var _hitbox: Area3D
var _hit_done: bool = false
var _base_color := Color(0.95, 0.45, 0.55)
var _telegraph: MeshInstance3D
var _coil: Node3D
var _slam_ring: MeshInstance3D
var _coil_pulse: float = 0.0


func _ready() -> void:
	balance_key = ""
	_hitbox = $AttackHitbox
	_hitbox.monitoring = false
	_hitbox.body_entered.connect(_on_hit)
	add_to_group("boss")
	super._ready()
	_cfg = Balance.data.get("chefes", {}).get("amandaconda", {}).duplicate()
	max_health = float(_cfg.get("vida", 450))
	health = max_health
	_update_label()
	if label:
		label.text = "AMANDACONDA · café"
	var alcance := float(_cfg.get("alcance", 2.2))
	_telegraph = AttackTelegraphScript.make_box(
		self,
		Vector3(1.7, 2.0, alcance),
		Vector3(0, 1.1, alcance * 0.4),
		Color(1.0, 0.3, 0.45, 0.38)
	)
	_slam_ring = AttackTelegraphScript.make_sphere(
		self, 1.4, Vector3(0, 0.2, 0.6), Color(0.25, 0.7, 0.4, 0.28)
	)
	_build_coil()


func _build_coil() -> void:
	_coil = Node3D.new()
	_coil.name = "SnakeCoil"
	add_child(_coil)
	_coil.position = Vector3(0, 0.15, 0.35)
	for i in 8:
		var seg := MeshInstance3D.new()
		var sm := SphereMesh.new()
		sm.radius = 0.28 - i * 0.018
		sm.height = sm.radius * 1.6
		seg.mesh = sm
		var mat := StandardMaterial3D.new()
		mat.albedo_color = Color(0.12, 0.22, 0.16) if i % 2 == 0 else Color(0.75, 0.68, 0.5)
		mat.metallic = 0.15
		mat.roughness = 0.45
		if i % 2 == 0:
			mat.emission_enabled = true
			mat.emission = Color(0.1, 0.35, 0.2)
			mat.emission_energy_multiplier = 0.5
		seg.material_override = mat
		var ang := i * 0.85
		var r := 0.55 + i * 0.08
		seg.position = Vector3(cos(ang) * r, i * 0.06, sin(ang) * r * 0.7)
		_coil.add_child(seg)


func _apply_balance() -> void:
	_cfg = Balance.data.get("chefes", {}).get("amandaconda", {}).duplicate()
	max_health = float(_cfg.get("vida", 450))
	if not _dead:
		health = minf(health, max_health)
	_update_label()
	_on_balance_applied()


func _on_balance_applied() -> void:
	_base_color = Color(1.0, 0.35, 0.45) if _phase2 else Color(0.95, 0.45, 0.55)
	if not _dead:
		_restore_color()
	if _hitbox == null:
		return
	var alcance := float(_cfg.get("alcance", 2.2))
	var shape := _hitbox.get_node_or_null("Shape") as CollisionShape3D
	if shape and shape.shape is BoxShape3D:
		(shape.shape as BoxShape3D).size = Vector3(1.8, 2.0, alcance)
	_hitbox.position = Vector3(0, 1.1, alcance * 0.4)


func _restore_color() -> void:
	_set_color(_base_color)


func _visual_action() -> String:
	if not _awakened:
		return "Idle"
	match _phase:
		Phase.WINDUP:
			return "Idle"
		Phase.ACTIVE:
			return "Slash" if _phase2 else "Punch"
		Phase.RECOVER:
			return "Idle"
		_:
			return ""


func _update_label() -> void:
	if label == null:
		return
	if not _awakened:
		label.text = "AMANDACONDA · fumando"
	elif _phase2:
		label.text = "AMANDACONDA FASE 2 %d/%d" % [int(health), int(max_health)]
	else:
		label.text = "AMANDACONDA %d/%d" % [int(health), int(max_health)]


func take_damage(amount: float, knockback: Vector3 = Vector3.ZERO, source: Node = null) -> void:
	if _dead:
		return
	if not _awakened:
		_awaken()
	super.take_damage(amount, knockback * 0.25, source)
	if not _phase2 and health <= max_health * float(_cfg.get("fase2_vida", 0.5)):
		_phase2 = true
		_base_color = Color(0.85, 0.2, 0.35)
		_restore_color()
		_cooldown = 0.2
		_update_label()
		HitFeel.shake(0.45)
		GameState.show_toast("AMANDACONDA · fase 2 · coil saturado")
		if _coil:
			_coil.scale = Vector3.ONE * 1.35
		if typeof(HitFeel) != TYPE_NIL:
			HitFeel.spark_at(global_position + Vector3.UP * 1.5, Color(0.95, 0.25, 0.45), 1.5)
		var hud := get_tree().get_first_node_in_group("hud")
		if hud and hud.has_method("flash_danger"):
			hud.flash_danger()
		for cam in get_tree().get_nodes_in_group("player_camera"):
			if cam and cam.has_method("punch_fov"):
				cam.punch_fov(6.0)
				break


func _awaken() -> void:
	_awakened = true
	_cooldown = 0.4
	_update_label()
	_set_color(Color(1.0, 0.55, 0.35))
	HitFeel.shake(0.3)
	GameState.show_toast("AMANDACONDA · sessão aberta")
	if typeof(HitFeel) != TYPE_NIL:
		HitFeel.spark_at(global_position + Vector3.UP * 1.3, Color(0.95, 0.4, 0.5), 1.2)


func _die() -> void:
	_dead = true
	died.emit()
	_drop_bytes(false)
	GameState.mark_boss_defeated("amandaconda")
	_set_color(Color(0.25, 0.25, 0.28))
	if label:
		label.text = "SESSION_CLOSED · saída liberada"
	$CollisionShape3D.disabled = true
	_hitbox.monitoring = false
	AttackTelegraphScript.set_active(_telegraph, false)
	AttackTelegraphScript.set_active(_slam_ring, false)
	if _coil:
		_coil.visible = false
	HitFeel.kill_punch()
	HitFeel.spark_at(global_position + Vector3.UP * 1.3, Color(0.95, 0.35, 0.5), 1.6)


func on_arena_engaged() -> void:
	super.on_arena_engaged()
	if not _awakened:
		_awaken()


func _physics_process(delta: float) -> void:
	if _dead:
		velocity = Vector3.ZERO
		return
	_apply_gravity(delta)
	_coil_pulse += delta
	if _coil:
		_coil.rotation.y += delta * (1.8 if _phase2 else 0.9)
		var amp := 1.25 if _phase2 else 1.0
		_coil.scale = Vector3.ONE * (amp + 0.04 * sin(_coil_pulse * 4.0))
	if not _awakened:
		_idle_smoke(delta)
		move_and_slide()
		_clamp_to_arena()
		return
	match _phase:
		Phase.IDLE:
			_chase(delta)
		Phase.WINDUP:
			_phase_t -= delta
			velocity = Vector3.ZERO
			_set_color(Color(1.0, 0.7, 0.2) if _heavy else Color(1.0, 0.5, 0.4))
			AttackTelegraphScript.set_active(_telegraph, true, false)
			AttackTelegraphScript.set_active(_slam_ring, _heavy and _phase2, false)
			if _heavy and _phase2 and _slam_ring and _slam_ring.mesh is SphereMesh:
				var prep := float(_cfg.get("preparacao_pesado", 0.75))
				var t := 1.0 - clampf(_phase_t / maxf(prep, 0.01), 0.0, 1.0)
				var r := lerpf(0.8, 2.2, t)
				(_slam_ring.mesh as SphereMesh).radius = r
				(_slam_ring.mesh as SphereMesh).height = r * 0.35
			if _phase_t <= 0.0:
				_phase = Phase.ACTIVE
				_phase_t = float(_cfg.get("acerto_pesado" if _heavy else "acerto_leve", 0.12))
				_hit_done = false
				_hitbox.monitoring = true
				AttackTelegraphScript.set_active(_telegraph, true, true)
				AttackTelegraphScript.set_active(_slam_ring, _heavy and _phase2, true)
				if _heavy:
					HitFeel.shake(0.28 if _phase2 else 0.25)
					HitFeel.spark_at(global_position + Vector3(0, 0.2, 0.7), Color(0.3, 0.85, 0.45) if _phase2 else Color(1.0, 0.45, 0.35), 1.2)
					if _phase2 and typeof(HitFeel) != TYPE_NIL:
						HitFeel.spark_at(global_position + Vector3.UP * 0.4, Color(0.95, 0.25, 0.45), 0.9)
		Phase.ACTIVE:
			_phase_t -= delta
			var forward := -global_transform.basis.z
			var push := 5.0 if _heavy else 2.8
			if _phase2:
				push *= 1.2
			velocity.x = forward.x * push
			velocity.z = forward.z * push
			if _phase_t <= 0.0:
				_phase = Phase.RECOVER
				_phase_t = float(_cfg.get("recuperacao_pesado" if _heavy else "recuperacao_leve", 0.45))
				_hitbox.monitoring = false
				AttackTelegraphScript.set_active(_telegraph, false)
				AttackTelegraphScript.set_active(_slam_ring, false)
				_restore_color()
		Phase.RECOVER:
			_phase_t -= delta
			velocity.x = move_toward(velocity.x, 0.0, 12.0 * delta)
			velocity.z = move_toward(velocity.z, 0.0, 12.0 * delta)
			if _phase_t <= 0.0:
				_phase = Phase.IDLE
				_cooldown = float(_cfg.get("intervalo", 1.4)) * (0.7 if _phase2 else 1.0)
	move_and_slide()
	_clamp_to_arena()


func _idle_smoke(delta: float) -> void:
	velocity = Vector3.ZERO
	if _arena != null and is_instance_valid(_arena) and _arena.has_method("is_engaged") and _arena.is_engaged():
		_awaken()
		return
	var player := _get_player()
	if player and global_position.distance_to(player.global_position) < 6.0:
		if _arena != null and is_instance_valid(_arena) and _arena.has_method("try_start_fight"):
			_arena.try_start_fight()
		_awaken()


func _chase(delta: float) -> void:
	var player := _wants_player_combat()
	if player == null:
		velocity.x = 0.0
		velocity.z = 0.0
		return
	var to: Vector3 = player.global_position - global_position
	to.y = 0.0
	var dist := to.length()
	var spd := float(_cfg.get("velocidade", 3.6))
	if _phase2:
		spd *= float(_cfg.get("fase2_speed_mult", 1.25))
	spd *= move_scale()
	if dist > 0.05:
		var dir := to.normalized()
		_face_flat(dir)
		if dist > float(_cfg.get("alcance", 2.2)) * 0.9:
			velocity.x = dir.x * spd
			velocity.z = dir.z * spd
		else:
			velocity.x = 0.0
			velocity.z = 0.0
	_cooldown -= delta
	if _cooldown <= 0.0 and dist <= float(_cfg.get("alcance", 2.2)) + 0.5:
		_heavy = _phase2 or randf() > 0.5
		_phase = Phase.WINDUP
		var prep := float(_cfg.get("preparacao_pesado" if _heavy else "preparacao_leve", 0.4))
		_phase_t = prep * (0.75 if _phase2 else 1.0)
		velocity = Vector3.ZERO
		AttackTelegraphScript.set_active(_telegraph, true, false)
		if typeof(HitFeel) != TYPE_NIL:
			HitFeel.shake(0.12 if _heavy else 0.07)


func _on_hit(body: Node3D) -> void:
	if _phase != Phase.ACTIVE or _hit_done:
		return
	if body == null or not body.is_in_group("player"):
		return
	if body.has_method("take_damage"):
		_hit_done = true
		var dmg := float(_cfg.get("dano_pesado" if _heavy else "dano_leve", 18))
		if _phase2:
			dmg *= 1.15
		body.take_damage(dmg, -global_transform.basis.z * 7.0, self)
		HitFeel.punch(0.05 if _heavy else 0.03)
		HitFeel.shake(0.4 if _heavy else 0.25)
		HitFeel.spark_at(
			body.global_position + Vector3.UP * 1.15,
			Color(0.35, 0.9, 0.5) if _phase2 else Color(1.0, 0.4, 0.5),
			1.25 if _heavy else 1.0
		)
