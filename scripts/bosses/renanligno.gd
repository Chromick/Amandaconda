extends "res://scripts/enemies/enemy_base.gd"
## Renanligno — golpe atrasado: fantasma acerta antes do corpo (arte cabos + tablet).

enum Phase { IDLE, TELEGRAPH, STRIKE, RECOVER }

var _phase: Phase = Phase.IDLE
var _phase_t: float = 0.0
var _cooldown: float = 1.2
var _ghost: MeshInstance3D
var _strike_pos: Vector3 = Vector3.ZERO
var _base_color := Color(0.35, 0.4, 0.48)
var _cables: Node3D
var _tablet: MeshInstance3D
var _ghost_glow: StandardMaterial3D
var _pulse_t: float = 0.0


func _ready() -> void:
	balance_key = ""
	_ghost = $Ghost
	_ghost.visible = false
	add_to_group("boss")
	super._ready()
	_cfg = {
		"vida": float(Balance.data.get("chefes", {}).get("renanligno", {}).get("vida", 240)),
		"nome": "RENANLIGNO",
		"velocidade": 4.2,
		"intervalo": 1.7,
		"telegraph": 0.55,
		"delay_hit": 0.28,
		"acerto": 0.12,
		"recuperacao": 0.5,
		"dano": 18,
		"alcance": 1.8,
		"bytes": Balance.data.get("chefes", {}).get("renanligno", {}).get("bytes", [120, 180]),
	}
	max_health = float(_cfg.get("vida", 240))
	health = max_health
	_update_label()
	_style_ghost()
	_build_cables()
	_attach_tablet()


func _style_ghost() -> void:
	if _ghost == null:
		return
	_ghost_glow = StandardMaterial3D.new()
	_ghost_glow.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_ghost_glow.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_ghost_glow.albedo_color = Color(0.55, 0.75, 1.0, 0.45)
	_ghost_glow.emission_enabled = true
	_ghost_glow.emission = Color(0.4, 0.9, 1.0)
	_ghost_glow.emission_energy_multiplier = 2.2
	_ghost.material_override = _ghost_glow


func _build_cables() -> void:
	_cables = Node3D.new()
	_cables.name = "DarkCables"
	add_child(_cables)
	for i in 6:
		var cable := MeshInstance3D.new()
		var cm := CylinderMesh.new()
		cm.top_radius = 0.04
		cm.bottom_radius = 0.06
		cm.height = 0.7 + i * 0.12
		cable.mesh = cm
		var mat := StandardMaterial3D.new()
		mat.albedo_color = Color(0.08, 0.08, 0.1)
		mat.roughness = 0.85
		cable.material_override = mat
		var ang := i * TAU / 6.0
		cable.position = Vector3(cos(ang) * 0.35, 0.9 + (i % 3) * 0.15, sin(ang) * 0.25)
		cable.rotation_degrees = Vector3(25.0 + i * 8.0, rad_to_deg(ang), 12.0)
		_cables.add_child(cable)


func _attach_tablet() -> void:
	_tablet = MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(0.28, 0.42, 0.05)
	_tablet.mesh = bm
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.12, 0.18, 0.35)
	mat.emission_enabled = true
	mat.emission = Color(0.9, 0.4, 0.85)
	mat.emission_energy_multiplier = 2.5
	_tablet.material_override = mat
	add_child(_tablet)
	_tablet.position = Vector3(-0.55, 1.05, 0.2)
	_tablet.rotation_degrees = Vector3(10.0, 25.0, -15.0)
	# Símbolo rainbow no centro
	var glyph := MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = 0.07
	sm.height = 0.04
	glyph.mesh = sm
	var gm := StandardMaterial3D.new()
	gm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	gm.albedo_color = Color(1.0, 0.6, 0.9)
	gm.emission_enabled = true
	gm.emission = Color(0.6, 1.0, 0.9)
	gm.emission_energy_multiplier = 4.0
	glyph.material_override = gm
	glyph.position = Vector3(0, 0, 0.04)
	_tablet.add_child(glyph)


func _apply_balance() -> void:
	var boss: Dictionary = Balance.data.get("chefes", {}).get("renanligno", {})
	_cfg["vida"] = float(boss.get("vida", 240))
	_cfg["nome"] = str(boss.get("nome", "RENANLIGNO"))
	if boss.has("bytes"):
		_cfg["bytes"] = boss.get("bytes")
	max_health = float(_cfg["vida"])
	if not _dead:
		health = minf(health, max_health)
	_update_label()
	_restore_color()


func _restore_color() -> void:
	_set_color(_base_color)


func _visual_action() -> String:
	match _phase:
		Phase.TELEGRAPH:
			return "Idle"
		Phase.STRIKE:
			return "Slash"
		Phase.RECOVER:
			return "Idle"
		_:
			return ""


func _update_label() -> void:
	if label:
		label.text = "%s %d/%d" % [str(_cfg.get("nome", "RENANLIGNO")), int(health), int(max_health)]


func _die() -> void:
	_dead = true
	died.emit()
	_drop_bytes(false)
	GameState.mark_boss_defeated("renanligno")
	_set_color(Color(0.2, 0.22, 0.25))
	if label:
		label.text = "RENANLIGNO DERROTADO"
	$CollisionShape3D.disabled = true
	_ghost.visible = false
	if _cables:
		_cables.visible = false
	if _tablet:
		_tablet.visible = false
	HitFeel.kill_punch()
	HitFeel.spark_at(global_position + Vector3.UP * 1.2, Color(0.55, 0.9, 1.0), 1.4)


func _physics_process(delta: float) -> void:
	if _dead:
		velocity = Vector3.ZERO
		return
	_apply_gravity(delta)
	_pulse_t += delta
	if _tablet:
		var hue := fmod(_pulse_t * 0.35, 1.0)
		var mat := _tablet.material_override as StandardMaterial3D
		if mat:
			mat.emission = Color.from_hsv(hue, 0.7, 1.0)
	if _cables:
		_cables.rotation.y += delta * 0.6
	match _phase:
		Phase.IDLE:
			_chase(delta)
		Phase.TELEGRAPH:
			_phase_t -= delta
			velocity = Vector3.ZERO
			_ghost.visible = true
			_ghost.global_position = _strike_pos + Vector3(0, 1, 0)
			_set_color(Color(0.55, 0.8, 1.0))
			if _ghost_glow:
				var g := fmod(_pulse_t * 1.2, 1.0)
				_ghost_glow.emission = Color.from_hsv(g, 0.55, 1.0)
				_ghost_glow.emission_energy_multiplier = 2.0 + sin(_pulse_t * 10.0) * 0.8
			if _phase_t <= 0.0:
				_phase = Phase.STRIKE
				_phase_t = float(_cfg.get("acerto", 0.12))
				_do_strike()
		Phase.STRIKE:
			_phase_t -= delta
			var to: Vector3 = _strike_pos - global_position
			to.y = 0.0
			if to.length() > 0.2:
				var dir := to.normalized()
				velocity.x = dir.x * 6.0
				velocity.z = dir.z * 6.0
			else:
				velocity.x = 0.0
				velocity.z = 0.0
			if _phase_t <= 0.0:
				_phase = Phase.RECOVER
				_phase_t = float(_cfg.get("recuperacao", 0.5))
				_ghost.visible = false
				_restore_color()
		Phase.RECOVER:
			_phase_t -= delta
			velocity = Vector3.ZERO
			if _phase_t <= 0.0:
				_phase = Phase.IDLE
				_cooldown = float(_cfg.get("intervalo", 1.7))
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
	var spd := float(_cfg.get("velocidade", 4.2)) * move_scale()
	if dist > 0.05:
		var dir := to.normalized()
		_face_flat(dir)
		if dist > float(_cfg.get("alcance", 1.8)):
			velocity.x = dir.x * spd
			velocity.z = dir.z * spd
		else:
			velocity.x = 0.0
			velocity.z = 0.0
	_cooldown -= delta
	if _cooldown <= 0.0 and dist < 8.0:
		_strike_pos = player.global_position
		_phase = Phase.TELEGRAPH
		_phase_t = float(_cfg.get("telegraph", 0.55))
		get_tree().create_timer(float(_cfg.get("delay_hit", 0.28))).timeout.connect(_ghost_hit, CONNECT_ONE_SHOT)
		velocity = Vector3.ZERO
		HitFeel.shake(0.12)


func _ghost_hit() -> void:
	if _dead or _phase == Phase.IDLE:
		return
	var player := _get_player()
	if player == null:
		return
	if player.global_position.distance_to(_strike_pos) <= float(_cfg.get("alcance", 1.8)) + 0.6:
		if player.has_method("take_damage"):
			var away: Vector3 = player.global_position - _strike_pos
			away.y = 0.0
			if away.length_squared() < 0.01:
				away = Vector3.FORWARD
			player.take_damage(float(_cfg.get("dano", 18)), away.normalized() * 4.0, self)
			HitFeel.punch(0.04)
			HitFeel.spark_at(_strike_pos + Vector3.UP * 1.1, Color(0.7, 0.45, 1.0), 1.2)


func _do_strike() -> void:
	var player := _get_player()
	if player and player.global_position.distance_to(global_position) < 2.2:
		if player.has_method("take_damage"):
			player.take_damage(float(_cfg.get("dano", 18)) * 0.35, -global_transform.basis.z * 3.0, self)
			HitFeel.spark_at(player.global_position + Vector3.UP * 1.0, Color(0.45, 0.85, 1.0), 0.85)
