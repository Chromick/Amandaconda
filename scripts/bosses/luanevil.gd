extends "res://scripts/enemies/enemy_base.gd"
## LuanEvil — tanque do bandejão; solta caramelo no chão.

enum Phase { IDLE, WINDUP, ACTIVE, RECOVER }

const PUDDLE := preload("res://scenes/bosses/caramel_puddle.tscn")
const AttackTelegraphScript := preload("res://scripts/combat/attack_telegraph.gd")

var _phase: Phase = Phase.IDLE
var _phase_t: float = 0.0
var _cooldown: float = 1.0
var _heavy_next: bool = false
var _hitbox: Area3D
var _hit_done: bool = false
var _base_color := Color(0.92, 0.72, 0.42)
var _phase2: bool = false
var _telegraph: MeshInstance3D
var _bucket: Node3D
var _drip: MeshInstance3D


func _ready() -> void:
	balance_key = ""
	_hitbox = $AttackHitbox
	_hitbox.monitoring = false
	_hitbox.body_entered.connect(_on_hit)
	add_to_group("boss")
	super._ready()
	_cfg = Balance.data.get("chefes", {}).get("luanevil", {})
	max_health = float(_cfg.get("vida", 280))
	health = max_health
	_update_label()
	var alcance := float(_cfg.get("alcance", 2.0))
	_telegraph = AttackTelegraphScript.make_box(
		self,
		Vector3(1.5, 1.8, alcance),
		Vector3(0, 1.0, alcance * 0.4),
		Color(1.0, 0.45, 0.12, 0.36)
	)
	_build_pipocao()


func _build_pipocao() -> void:
	_bucket = Node3D.new()
	_bucket.name = "Pipocao"
	add_child(_bucket)
	_bucket.position = Vector3(0.7, 0.95, 0.15)
	_bucket.rotation_degrees = Vector3(12.0, -20.0, 8.0)
	# Cone listrado improvisado
	var cone := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = 0.55
	cm.bottom_radius = 0.22
	cm.height = 0.95
	cone.mesh = cm
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.85, 0.25, 0.18)
	mat.emission_enabled = true
	mat.emission = Color(0.9, 0.35, 0.1)
	mat.emission_energy_multiplier = 0.6
	cone.material_override = mat
	_bucket.add_child(cone)
	# Pipocas no topo
	for i in 6:
		var puff := MeshInstance3D.new()
		var sm := SphereMesh.new()
		sm.radius = randf_range(0.08, 0.14)
		sm.height = sm.radius * 2.0
		puff.mesh = sm
		var pm := StandardMaterial3D.new()
		pm.albedo_color = Color(0.95, 0.88, 0.7)
		puff.material_override = pm
		puff.position = Vector3(randf_range(-0.25, 0.25), 0.55 + randf_range(0.0, 0.15), randf_range(-0.25, 0.25))
		_bucket.add_child(puff)
	_drip = MeshInstance3D.new()
	var drip_m := SphereMesh.new()
	drip_m.radius = 0.08
	drip_m.height = 0.22
	_drip.mesh = drip_m
	var dm := StandardMaterial3D.new()
	dm.albedo_color = Color(0.75, 0.35, 0.1)
	dm.emission_enabled = true
	dm.emission = Color(1.0, 0.4, 0.1)
	dm.emission_energy_multiplier = 1.4
	_drip.material_override = dm
	_drip.position = Vector3(0.05, -0.35, 0.1)
	_bucket.add_child(_drip)


func _apply_balance() -> void:
	_cfg = Balance.data.get("chefes", {}).get("luanevil", {})
	max_health = float(_cfg.get("vida", 280))
	if not _dead:
		health = minf(health, max_health)
	_update_label()
	_on_balance_applied()


func _on_balance_applied() -> void:
	_base_color = Color(0.92, 0.72, 0.42)
	if not _dead:
		_restore_color()
	if _hitbox == null:
		return
	var alcance := float(_cfg.get("alcance", 2.0))
	var shape := _hitbox.get_node_or_null("Shape") as CollisionShape3D
	if shape and shape.shape is BoxShape3D:
		(shape.shape as BoxShape3D).size = Vector3(1.6, 1.8, alcance)
	_hitbox.position = Vector3(0, 1.0, alcance * 0.4)
	if _telegraph and _telegraph.mesh is BoxMesh:
		(_telegraph.mesh as BoxMesh).size = Vector3(1.5, 1.8, alcance)
		_telegraph.position = Vector3(0, 1.0, alcance * 0.4)


func _restore_color() -> void:
	_set_color(Color(1.0, 0.55, 0.2) if _phase2 else _base_color)


func _visual_action() -> String:
	match _phase:
		Phase.WINDUP:
			return "Idle"
		Phase.ACTIVE:
			return "Slash" if _heavy_next else "Punch"
		Phase.RECOVER:
			return "Idle"
		_:
			return ""


func _update_label() -> void:
	if label:
		var nome := str(_cfg.get("nome", "LUANEVIL"))
		label.text = "%s %d/%d" % [nome, int(health), int(max_health)]


func _die() -> void:
	_dead = true
	died.emit()
	GameState.mark_boss_defeated("luanevil")
	_set_color(Color(0.25, 0.25, 0.28))
	if label:
		label.text = "LUANEVIL DERROTADA"
	$CollisionShape3D.disabled = true
	_hitbox.monitoring = false
	AttackTelegraphScript.set_active(_telegraph, false)
	if _bucket:
		_bucket.visible = false
	HitFeel.kill_punch()
	HitFeel.spark_at(global_position + Vector3.UP * 1.2, Color(1.0, 0.45, 0.12), 1.4)


func take_damage(amount: float, knockback: Vector3 = Vector3.ZERO, source: Node = null) -> void:
	if _dead:
		return
	super.take_damage(amount, knockback * 0.35, source)
	if not _phase2 and health <= max_health * float(_cfg.get("fase2_vida", 0.5)):
		_phase2 = true
		_restore_color()
		_spawn_puddle()
		_spawn_puddle()
		HitFeel.shake(0.35)
		GameState.show_toast("LUANEVIL · caramelo derrete")


func _physics_process(delta: float) -> void:
	if _dead:
		velocity = Vector3.ZERO
		return
	_apply_gravity(delta)
	if _drip:
		_drip.position.y = -0.35 + sin(Time.get_ticks_msec() * 0.008) * 0.06
	match _phase:
		Phase.IDLE:
			_chase(delta)
		Phase.WINDUP:
			_phase_t -= delta
			velocity = Vector3.ZERO
			_set_color(Color(1.0, 0.35, 0.12))
			AttackTelegraphScript.set_active(_telegraph, true, false)
			if _phase_t <= 0.0:
				_phase = Phase.ACTIVE
				_phase_t = float(_cfg.get("acerto_pesado" if _heavy_next else "acerto_leve", 0.12))
				_hit_done = false
				_hitbox.monitoring = true
				AttackTelegraphScript.set_active(_telegraph, true, true)
				if _heavy_next or _phase2:
					_spawn_puddle()
					HitFeel.shake(0.2)
					HitFeel.spark_at(global_position + Vector3(0, 0.15, 0.6), Color(1.0, 0.4, 0.1), 1.1)
		Phase.ACTIVE:
			_phase_t -= delta
			var forward := -global_transform.basis.z
			var push := 3.5 if _heavy_next else 2.2
			velocity.x = forward.x * push
			velocity.z = forward.z * push
			if _phase_t <= 0.0:
				_phase = Phase.RECOVER
				_phase_t = float(_cfg.get("recuperacao_pesado" if _heavy_next else "recuperacao_leve", 0.5))
				_hitbox.monitoring = false
				AttackTelegraphScript.set_active(_telegraph, false)
				_restore_color()
		Phase.RECOVER:
			_phase_t -= delta
			velocity.x = move_toward(velocity.x, 0.0, 10.0 * delta)
			velocity.z = move_toward(velocity.z, 0.0, 10.0 * delta)
			if _phase_t <= 0.0:
				_phase = Phase.IDLE
				_cooldown = float(_cfg.get("intervalo", 1.6)) * (0.75 if _phase2 else 1.0)
	move_and_slide()
	_clamp_to_arena()


func _chase(delta: float) -> void:
	var player := _wants_player_combat()
	if player == null:
		velocity.x = 0.0
		velocity.z = 0.0
		return
	var to: Vector3 = player.global_position - global_position
	to.y = 0.0
	var dist := to.length()
	var alcance := float(_cfg.get("alcance", 2.0))
	var spd := float(_cfg.get("velocidade", 3.4)) * (1.15 if _phase2 else 1.0) * move_scale()
	if dist > 0.05:
		var dir := to.normalized()
		_face_flat(dir)
		if dist > alcance * 0.9:
			velocity.x = dir.x * spd
			velocity.z = dir.z * spd
		else:
			velocity.x = 0.0
			velocity.z = 0.0
	_cooldown -= delta
	if _cooldown <= 0.0 and dist <= alcance + 0.5:
		_heavy_next = _phase2 or randf() > 0.55
		_phase = Phase.WINDUP
		_phase_t = float(_cfg.get("preparacao_pesado" if _heavy_next else "preparacao_leve", 0.35))
		velocity = Vector3.ZERO
		AttackTelegraphScript.set_active(_telegraph, true, false)


func _spawn_puddle() -> void:
	var puddle := PUDDLE.instantiate()
	if not SceneUtil.add_to_world(puddle, self, global_position + Vector3(0, 0.05, 0)):
		return
	puddle.setup(
		float(_cfg.get("caramelo_raio", 2.2)),
		float(_cfg.get("caramelo_duracao", 6.0)),
		float(_cfg.get("caramelo_slow", 0.45))
	)


func _on_hit(body: Node3D) -> void:
	if _phase != Phase.ACTIVE or _hit_done:
		return
	if body == null or not body.is_in_group("player"):
		return
	if body.has_method("take_damage"):
		_hit_done = true
		var dmg := float(_cfg.get("dano_pesado" if _heavy_next else "dano_leve", 16))
		var forward := -global_transform.basis.z
		body.take_damage(dmg, forward * 6.0, self)
		HitFeel.punch(0.04)
		HitFeel.shake(0.35 if _heavy_next else 0.22)
		HitFeel.spark_at(body.global_position + Vector3.UP * 1.1, Color(1.0, 0.5, 0.15), 1.15)
