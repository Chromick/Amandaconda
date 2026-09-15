extends "res://scripts/enemies/enemy_base.gd"
## Marlombólico — hackeia controles e mente na HUD.

enum Phase { IDLE, WINDUP, ACTIVE, RECOVER, HACK }

const AttackTelegraphScript := preload("res://scripts/combat/attack_telegraph.gd")

var _phase: Phase = Phase.IDLE
var _phase_t: float = 0.0
var _cooldown: float = 1.0
var _hack_cd: float = 2.0
var _hitbox: Area3D
var _hit_done: bool = false
var _base_color := Color(0.35, 0.85, 0.45)
var _telegraph: MeshInstance3D
var _hack_fx: MeshInstance3D
var _eyes: Node3D
var _eye_pulse: float = 0.0


func _ready() -> void:
	balance_key = ""
	_hitbox = $AttackHitbox
	_hitbox.monitoring = false
	_hitbox.body_entered.connect(_on_hit)
	add_to_group("boss")
	super._ready()
	_cfg = Balance.data.get("chefes", {}).get("marlombolico", {}).duplicate()
	max_health = float(_cfg.get("vida", 300))
	health = max_health
	_update_label()
	var alcance := float(_cfg.get("alcance", 1.8))
	_telegraph = AttackTelegraphScript.make_box(
		self,
		Vector3(1.25, 1.6, alcance),
		Vector3(0, 1.0, alcance * 0.45),
		Color(0.25, 1.0, 0.4, 0.35)
	)
	_hack_fx = AttackTelegraphScript.make_sphere(
		self,
		3.2,
		Vector3(0, 1.2, 0),
		Color(0.15, 1.0, 0.4, 0.22)
	)
	_build_matrix_eyes()


func _build_matrix_eyes() -> void:
	_eyes = Node3D.new()
	_eyes.name = "MatrixEyes"
	add_child(_eyes)
	_eyes.position = Vector3(0, 1.65, 0.28)
	for x in [-0.12, 0.12]:
		var disc := MeshInstance3D.new()
		var sm := SphereMesh.new()
		sm.radius = 0.09
		sm.height = 0.05
		disc.mesh = sm
		var mat := StandardMaterial3D.new()
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		mat.albedo_color = Color(0.35, 1.0, 0.45, 0.75)
		mat.emission_enabled = true
		mat.emission = Color(0.2, 1.0, 0.35)
		mat.emission_energy_multiplier = 3.5
		disc.material_override = mat
		disc.position = Vector3(x, 0, 0)
		_eyes.add_child(disc)


func _apply_balance() -> void:
	_cfg = Balance.data.get("chefes", {}).get("marlombolico", {}).duplicate()
	max_health = float(_cfg.get("vida", 300))
	if not _dead:
		health = minf(health, max_health)
	_update_label()
	_on_balance_applied()


func _on_balance_applied() -> void:
	_base_color = Color(0.45, 0.95, 0.55)
	if not _dead:
		_restore_color()
	if _hitbox == null:
		return
	var alcance := float(_cfg.get("alcance", 1.8))
	var shape := _hitbox.get_node_or_null("Shape") as CollisionShape3D
	if shape and shape.shape is BoxShape3D:
		(shape.shape as BoxShape3D).size = Vector3(1.3, 1.6, alcance)
	_hitbox.position = Vector3(0, 1.0, alcance * 0.45)


func _restore_color() -> void:
	_set_color(_base_color)


func _visual_action() -> String:
	match _phase:
		Phase.WINDUP, Phase.HACK:
			return "Idle"
		Phase.ACTIVE:
			return "Run"
		Phase.RECOVER:
			return "Idle"
		_:
			return ""


func _update_label() -> void:
	if label:
		label.text = "%s %d/%d" % [str(_cfg.get("nome", "MARLOMBÓLICO")), int(health), int(max_health)]


func _die() -> void:
	_dead = true
	died.emit()
	GameState.mark_boss_defeated("marlombolico")
	GameState.clear_hacks()
	_set_color(Color(0.25, 0.25, 0.28))
	if label:
		label.text = "MARLOMBÓLICO DERROTADO"
	$CollisionShape3D.disabled = true
	_hitbox.monitoring = false
	AttackTelegraphScript.set_active(_telegraph, false)
	AttackTelegraphScript.set_active(_hack_fx, false)
	if _eyes:
		_eyes.visible = false
	HitFeel.kill_punch()
	HitFeel.spark_at(global_position + Vector3.UP * 1.2, Color(0.3, 1.0, 0.45), 1.45)


func _physics_process(delta: float) -> void:
	if _dead:
		velocity = Vector3.ZERO
		return
	_apply_gravity(delta)
	_hack_cd -= delta
	_eye_pulse += delta
	if _eyes:
		var s := 1.0 + 0.12 * sin(_eye_pulse * 6.0)
		_eyes.scale = Vector3(s, s, s)
	match _phase:
		Phase.IDLE:
			_ai(delta)
		Phase.HACK:
			_phase_t -= delta
			velocity = Vector3.ZERO
			_set_color(Color(0.15, 1.0, 0.35))
			AttackTelegraphScript.set_active(_hack_fx, true, true)
			if _hack_fx and _hack_fx.mesh is SphereMesh:
				var t := 1.0 - clampf(_phase_t / 0.55, 0.0, 1.0)
				var r := lerpf(1.2, 3.6, t)
				(_hack_fx.mesh as SphereMesh).radius = r
				(_hack_fx.mesh as SphereMesh).height = r * 2.0
			if _phase_t <= 0.0:
				_phase = Phase.IDLE
				_cooldown = 0.6
				AttackTelegraphScript.set_active(_hack_fx, false)
				_restore_color()
				_update_label()
		Phase.WINDUP:
			_phase_t -= delta
			velocity = Vector3.ZERO
			_set_color(Color(0.75, 1.0, 0.35))
			AttackTelegraphScript.set_active(_telegraph, true, false)
			if _phase_t <= 0.0:
				_phase = Phase.ACTIVE
				_phase_t = float(_cfg.get("acerto", 0.12))
				_hit_done = false
				_hitbox.monitoring = true
				AttackTelegraphScript.set_active(_telegraph, true, true)
		Phase.ACTIVE:
			_phase_t -= delta
			var forward := -global_transform.basis.z
			velocity.x = forward.x * 3.0
			velocity.z = forward.z * 3.0
			if _phase_t <= 0.0:
				_phase = Phase.RECOVER
				_phase_t = float(_cfg.get("recuperacao", 0.55))
				_hitbox.monitoring = false
				AttackTelegraphScript.set_active(_telegraph, false)
				_restore_color()
		Phase.RECOVER:
			_phase_t -= delta
			velocity = Vector3.ZERO
			if _phase_t <= 0.0:
				_phase = Phase.IDLE
				_cooldown = float(_cfg.get("intervalo", 1.5))
	move_and_slide()
	_clamp_to_arena()


func _ai(delta: float) -> void:
	var player := _wants_player_combat()
	if player == null:
		velocity.x = 0.0
		velocity.z = 0.0
		return
	var to: Vector3 = player.global_position - global_position
	to.y = 0.0
	var dist := to.length()
	var spd := float(_cfg.get("velocidade", 3.8)) * move_scale()
	if dist > 0.05:
		var dir := to.normalized()
		_face_flat(dir)
		if dist > float(_cfg.get("alcance", 1.8)):
			velocity.x = dir.x * spd
			velocity.z = dir.z * spd
		else:
			velocity.x = 0.0
			velocity.z = 0.0

	if _hack_cd <= 0.0 and dist < 14.0:
		_cast_hack()
		return

	_cooldown -= delta
	if _cooldown <= 0.0 and dist <= float(_cfg.get("alcance", 1.8)) + 0.4:
		_phase = Phase.WINDUP
		_phase_t = float(_cfg.get("preparacao", 0.4))
		velocity = Vector3.ZERO
		AttackTelegraphScript.set_active(_telegraph, true, false)


func _cast_hack() -> void:
	_phase = Phase.HACK
	_phase_t = 0.55
	_hack_cd = float(_cfg.get("hack_cooldown", 4.5))
	AttackTelegraphScript.set_active(_hack_fx, true, true)
	HitFeel.shake(0.28)
	HitFeel.spark_at(global_position + Vector3.UP * 1.4, Color(0.25, 1.0, 0.4), 1.3)
	var hud := get_tree().get_first_node_in_group("hud")
	if hud and hud.has_method("flash_danger"):
		hud.flash_danger()
	var duration := float(_cfg.get("hack_duration", 5.0))
	if randf() > 0.5:
		GameState.set_controls_inverted(true)
		GameState.show_toast("sudo invert · controles invertidos")
		get_tree().create_timer(duration).timeout.connect(func ():
			if not _dead:
				GameState.set_controls_inverted(false)
		, CONNECT_ONE_SHOT)
		if label:
			label.text = "sudo invert"
	else:
		GameState.set_hud_lying(true)
		GameState.show_toast("HUD_FAKE=1 · a barra mente")
		get_tree().create_timer(duration).timeout.connect(func ():
			if not _dead:
				GameState.set_hud_lying(false)
		, CONNECT_ONE_SHOT)
		if label:
			label.text = "HUD_FAKE=1"


func _on_hit(body: Node3D) -> void:
	if _phase != Phase.ACTIVE or _hit_done:
		return
	if body == null or not body.is_in_group("player"):
		return
	if body.has_method("take_damage"):
		_hit_done = true
		body.take_damage(float(_cfg.get("dano", 15)), -global_transform.basis.z * 4.5, self)
		HitFeel.punch(0.035)
		HitFeel.spark_at(body.global_position + Vector3.UP * 1.1, Color(0.35, 1.0, 0.45), 1.05)
