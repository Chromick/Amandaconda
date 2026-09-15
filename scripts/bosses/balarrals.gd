extends "res://scripts/enemies/enemy_base.gd"
## Balarrals — espelho: leve/pesado/roll + cadeira e aura (arte Balarrals3D).

enum Phase { IDLE, WINDUP, ACTIVE, RECOVER, ROLL }

const AttackTelegraphScript := preload("res://scripts/combat/attack_telegraph.gd")

var _phase: Phase = Phase.IDLE
var _phase_t: float = 0.0
var _cooldown: float = 0.8
var _heavy: bool = false
var _hitbox: Area3D
var _hit_done: bool = false
var _roll_dir: Vector3 = Vector3.FORWARD
var _base_color := Color(0.22, 0.22, 0.24)
var _telegraph: MeshInstance3D
var _slam_ring: MeshInstance3D
var _aura: Node3D
var _chair: Node3D
var _aura_pulse: float = 0.0


func _ready() -> void:
	balance_key = ""
	_hitbox = $AttackHitbox
	_hitbox.monitoring = false
	_hitbox.body_entered.connect(_on_hit)
	add_to_group("boss")
	super._ready()
	_cfg = Balance.data.get("chefes", {}).get("balarrals", {}).duplicate()
	_cfg["nome"] = str(_cfg.get("nome", "BALARRALS"))
	_cfg["intervalo"] = float(_cfg.get("intervalo", 1.3))
	_cfg["alcance"] = float(_cfg.get("alcance", 1.7))
	_cfg["preparacao_leve"] = 0.12
	_cfg["acerto_leve"] = 0.08
	_cfg["recuperacao_leve"] = 0.22
	_cfg["preparacao_pesado"] = 0.32
	_cfg["acerto_pesado"] = 0.1
	_cfg["recuperacao_pesado"] = 0.4
	max_health = float(_cfg.get("vida", 220))
	health = max_health
	_update_label()
	var alcance := float(_cfg.get("alcance", 1.7))
	_telegraph = AttackTelegraphScript.make_box(
		self,
		Vector3(1.15, 1.5, alcance),
		Vector3(0, 1.0, alcance * 0.45),
		Color(1.0, 0.45, 0.18, 0.34)
	)
	_slam_ring = AttackTelegraphScript.make_sphere(
		self,
		1.1,
		Vector3(0, 0.15, 0.9),
		Color(1.0, 0.35, 0.12, 0.28)
	)
	_build_shadow_aura()
	_attach_chair()


func _build_shadow_aura() -> void:
	_aura = Node3D.new()
	_aura.name = "ShadowAura"
	add_child(_aura)
	_aura.position = Vector3(-0.35, 1.1, 0.35)
	for i in 5:
		var wisp := MeshInstance3D.new()
		var sm := SphereMesh.new()
		sm.radius = 0.22 + i * 0.05
		sm.height = sm.radius * 2.4
		wisp.mesh = sm
		var mat := StandardMaterial3D.new()
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		mat.albedo_color = Color(0.05, 0.04, 0.06, 0.45 - i * 0.05)
		mat.emission_enabled = true
		mat.emission = Color(0.12, 0.05, 0.08)
		mat.emission_energy_multiplier = 0.8
		wisp.material_override = mat
		wisp.position = Vector3(
			sin(i * 1.1) * 0.25,
			i * 0.28,
			cos(i * 0.9) * 0.2
		)
		_aura.add_child(wisp)


func _attach_chair() -> void:
	var packed := PropLibrary.prop("chair.glb")
	if packed == null:
		return
	_chair = packed.instantiate() as Node3D
	if _chair == null:
		return
	add_child(_chair)
	# Segura pela perna, como na arte
	_chair.position = Vector3(0.55, 0.85, -0.15)
	_chair.rotation_degrees = Vector3(25.0, 90.0, -110.0)
	_chair.scale = Vector3.ONE * 0.95


func _apply_balance() -> void:
	var boss: Dictionary = Balance.data.get("chefes", {}).get("balarrals", {})
	for k in boss.keys():
		_cfg[k] = boss[k]
	max_health = float(_cfg.get("vida", 220))
	if not _dead:
		health = minf(health, max_health)
	_update_label()
	_on_balance_applied()


func _on_balance_applied() -> void:
	_base_color = Color(0.22, 0.22, 0.24)
	if not _dead:
		_restore_color()
	if _hitbox == null:
		return
	var alcance := float(_cfg.get("alcance", 1.7))
	var shape := _hitbox.get_node_or_null("Shape") as CollisionShape3D
	if shape and shape.shape is BoxShape3D:
		(shape.shape as BoxShape3D).size = Vector3(1.2, 1.5, alcance)
	_hitbox.position = Vector3(0, 1.0, alcance * 0.45)
	if _telegraph and _telegraph.mesh is BoxMesh:
		(_telegraph.mesh as BoxMesh).size = Vector3(1.15, 1.5, alcance)
		_telegraph.position = Vector3(0, 1.0, alcance * 0.45)


func _restore_color() -> void:
	_set_color(_base_color)


func _visual_action() -> String:
	match _phase:
		Phase.WINDUP:
			return "Idle"
		Phase.ACTIVE:
			return "Punch"
		Phase.ROLL:
			return "Duck"
		Phase.RECOVER:
			return "Idle"
		_:
			return ""


func _update_label() -> void:
	if label:
		label.text = "%s %d/%d" % [str(_cfg.get("nome", "BALARRALS")), int(health), int(max_health)]


func _die() -> void:
	_dead = true
	died.emit()
	_drop_bytes(false)
	GameState.mark_boss_defeated("balarrals")
	_set_color(Color(0.12, 0.12, 0.14))
	if label:
		label.text = "BALARRALS DERROTADO"
	$CollisionShape3D.disabled = true
	_hitbox.monitoring = false
	AttackTelegraphScript.set_active(_telegraph, false)
	AttackTelegraphScript.set_active(_slam_ring, false)
	if _aura:
		_aura.visible = false
	HitFeel.kill_punch()
	HitFeel.spark_at(global_position + Vector3.UP * 1.2, Color(1.0, 0.4, 0.15), 1.5)


func _physics_process(delta: float) -> void:
	if _dead:
		velocity = Vector3.ZERO
		return
	_apply_gravity(delta)
	_pulse_aura(delta)
	match _phase:
		Phase.IDLE:
			_ai(delta)
		Phase.ROLL:
			_phase_t -= delta
			velocity.x = _roll_dir.x * 11.0
			velocity.z = _roll_dir.z * 11.0
			_set_color(Color(0.08, 0.08, 0.12))
			if _phase_t <= 0.0:
				_phase = Phase.IDLE
				_cooldown = 0.45
				_restore_color()
		Phase.WINDUP:
			_phase_t -= delta
			velocity = Vector3.ZERO
			_set_color(Color(1.0, 0.4, 0.15) if _heavy else Color(0.95, 0.7, 0.35))
			AttackTelegraphScript.set_active(_telegraph, true, false)
			AttackTelegraphScript.set_active(_slam_ring, _heavy, false)
			_grow_slam_preview()
			if _phase_t <= 0.0:
				_phase = Phase.ACTIVE
				_phase_t = float(_cfg.get("acerto_pesado" if _heavy else "acerto_leve", 0.1))
				_hit_done = false
				_hitbox.monitoring = true
				AttackTelegraphScript.set_active(_telegraph, true, true)
				AttackTelegraphScript.set_active(_slam_ring, _heavy, true)
				if _heavy:
					HitFeel.shake(0.22)
					HitFeel.spark_at(global_position + Vector3(0, 0.2, 0.8), Color(1.0, 0.45, 0.12), 1.2)
		Phase.ACTIVE:
			_phase_t -= delta
			var forward := -global_transform.basis.z
			var push := 4.0 if _heavy else 2.5
			velocity.x = forward.x * push
			velocity.z = forward.z * push
			if _phase_t <= 0.0:
				_phase = Phase.RECOVER
				_phase_t = float(_cfg.get("recuperacao_pesado" if _heavy else "recuperacao_leve", 0.3))
				_hitbox.monitoring = false
				AttackTelegraphScript.set_active(_telegraph, false)
				AttackTelegraphScript.set_active(_slam_ring, false)
				_restore_color()
		Phase.RECOVER:
			_phase_t -= delta
			velocity.x = move_toward(velocity.x, 0.0, 14.0 * delta)
			velocity.z = move_toward(velocity.z, 0.0, 14.0 * delta)
			if _phase_t <= 0.0:
				_phase = Phase.IDLE
				_cooldown = float(_cfg.get("intervalo", 1.3))
	move_and_slide()
	_clamp_to_arena()


func _pulse_aura(delta: float) -> void:
	if _aura == null:
		return
	_aura_pulse += delta
	var engaged: bool = _arena != null and _arena.has_method("is_engaged") and bool(_arena.is_engaged())
	_aura.visible = engaged or _phase != Phase.IDLE
	var amp := 1.15 if _heavy and _phase == Phase.WINDUP else 1.0
	_aura.scale = Vector3.ONE * (amp + 0.08 * sin(_aura_pulse * 5.5))
	_aura.rotation.y += delta * 1.4


func _grow_slam_preview() -> void:
	if not _heavy or _slam_ring == null or not (_slam_ring.mesh is SphereMesh):
		return
	var prep := float(_cfg.get("preparacao_pesado", 0.32))
	var t := 1.0 - clampf(_phase_t / maxf(prep, 0.01), 0.0, 1.0)
	var r := lerpf(0.6, 1.55, t)
	var sm := _slam_ring.mesh as SphereMesh
	sm.radius = r
	sm.height = r * 0.35
	_slam_ring.position = Vector3(0, 0.12, float(_cfg.get("alcance", 1.7)) * 0.35)


func _ai(delta: float) -> void:
	var player := _wants_player_combat()
	if player == null:
		velocity.x = 0.0
		velocity.z = 0.0
		return
	var to: Vector3 = player.global_position - global_position
	to.y = 0.0
	var dist := to.length()
	var spd := float(_cfg.get("velocidade", 5.8)) * move_scale()
	if dist > 0.05:
		var dir := to.normalized()
		# Espelho: arma na mão trocada — gira um pouco “errado”.
		var skewed := dir.rotated(Vector3.UP, 0.35)
		_face_flat(skewed)
		if dist > float(_cfg.get("alcance", 1.7)) + 0.2:
			velocity.x = dir.x * spd
			velocity.z = dir.z * spd
		else:
			velocity.x = 0.0
			velocity.z = 0.0
	_cooldown -= delta
	if _cooldown > 0.0:
		return
	# Às vezes rola atravessando o player (espelho do roll).
	if dist < 4.5 and randf() < 0.28:
		_phase = Phase.ROLL
		_phase_t = 0.42
		_roll_dir = to.normalized() if dist > 0.01 else -global_transform.basis.z
		return
	if dist <= float(_cfg.get("alcance", 1.7)) + 0.4:
		_heavy = randf() > 0.55
		_phase = Phase.WINDUP
		_phase_t = float(_cfg.get("preparacao_pesado" if _heavy else "preparacao_leve", 0.2))
		velocity = Vector3.ZERO
		AttackTelegraphScript.set_active(_telegraph, true, false)
		AttackTelegraphScript.set_active(_slam_ring, _heavy, false)


func _on_hit(body: Node3D) -> void:
	if _phase != Phase.ACTIVE or _hit_done:
		return
	if body == null or not body.is_in_group("player"):
		return
	if body.has_method("take_damage"):
		_hit_done = true
		var dmg := float(_cfg.get("dano_pesado" if _heavy else "dano_leve", 14))
		var kb := 7.0 if _heavy else 5.0
		body.take_damage(dmg, -global_transform.basis.z * kb, self)
		HitFeel.punch(0.05 if _heavy else 0.03)
		HitFeel.shake(0.42 if _heavy else 0.25)
		HitFeel.spark_at(
			body.global_position + Vector3.UP * 1.1,
			Color(1.0, 0.4, 0.12) if _heavy else Color(1.0, 0.75, 0.35),
			1.35 if _heavy else 1.0
		)


func is_invulnerable() -> bool:
	return _phase == Phase.ROLL or _dead
