extends CharacterBody3D
## Jogador 3D — movimento, roll com i-frames, melee (teclado) ou vírus, vigor/vida.

signal health_changed(current: float, maximum: float)
signal stamina_changed(current: float, maximum: float)
signal weapon_changed(weapon_id: String)
signal drinks_changed(current: int, maximum: int)
signal died

const VIRUS_SCENE := preload("res://scenes/virus_projectile.tscn")
const PUDDLE_SCENE := preload("res://scenes/bosses/caramel_puddle.tscn")
const POPUP_SCENE := preload("res://scenes/damage_popup.tscn")
const CharacterVisualScript := preload("res://scripts/world/character_visual.gd")
const AttackTelegraphScript := preload("res://scripts/combat/attack_telegraph.gd")
const SceneUtil := preload("res://scripts/combat/scene_util.gd")

enum State { MOVE, ROLL, ATTACK_LIGHT, ATTACK_HEAVY, HIT, HEALING, DEAD }

@onready var mesh: MeshInstance3D = $Mesh
@onready var attack_area: Area3D = $AttackHitbox
@onready var attack_shape: CollisionShape3D = $AttackHitbox/Shape
@onready var lock_sensor: Area3D = $LockSensor
@onready var weapon_visual: MeshInstance3D = $WeaponVisual

var _visual = null
var _atk_telegraph: MeshInstance3D
var _lock_marker: MeshInstance3D
var _roll_ghost_timer: float = 0.0

var state: State = State.MOVE
var health: float = 100.0
var max_health: float = 100.0
var stamina: float = 100.0
var max_stamina: float = 100.0
var stamina_regen_timer: float = 0.0

var coyote_timer: float = 0.0
var jump_buffer_timer: float = 0.0
var invuln_timer: float = 0.0
var action_timer: float = 0.0
var roll_timer: float = 0.0
var roll_dir: Vector3 = Vector3.FORWARD
var heavy_held: float = 0.0
var heavy_charging: bool = false
var facing: Vector3 = Vector3.FORWARD
var lock_target: Node3D = null
var _hit_targets: Array[Node] = []
var _charge_ratio: float = 0.0

var _cfg: Dictionary = {}
var _roll: Dictionary = {}
var _light: Dictionary = {}
var _heavy: Dictionary = {}
var _default_color := Color(0.85, 0.85, 0.9)
var speed_mult: float = 1.0
var _ground_slow: float = 1.0
var _mark_timer: float = 0.0
var _mark_mult: float = 1.0
var _heal_timer: float = 0.0
var _spawn_pos: Vector3
var _ability_cd: float = 0.0
var _eco_pending: bool = false
var _eco_pos: Vector3 = Vector3.ZERO
var _eco_timer: float = 0.0
var _eco_telegraph: MeshInstance3D = null
var _combo_step: int = 0
var _combo_window: float = 0.0
var _queued_combo: bool = false
var _sprint_attack: bool = false
var _was_sprinting: bool = false
var _roll_attack_queued: bool = false


func _ready() -> void:
	add_to_group("player")
	_spawn_pos = global_position
	attack_area.monitoring = false
	attack_area.body_entered.connect(_on_attack_body_entered)
	attack_area.area_entered.connect(_on_attack_area_entered)
	Balance.reloaded.connect(_apply_balance)
	died.connect(_on_died)
	GameState.patches_changed.connect(refresh_progression)
	_setup_character_visual()
	_setup_combat_fx()
	_apply_balance()
	refresh_progression()
	_refresh_weapon_visual()
	health_changed.emit(health, max_health)
	stamina_changed.emit(stamina, max_stamina)
	weapon_changed.emit(GameState.weapon_id())
	drinks_changed.emit(GameState.heals, GameState.max_heals)


func _setup_combat_fx() -> void:
	_atk_telegraph = AttackTelegraphScript.make_box(
		self,
		Vector3(0.7, 1.1, 1.3),
		Vector3(0, 0.9, 0.7),
		Color(1.0, 0.9, 0.35, 0.28)
	)
	_lock_marker = MeshInstance3D.new()
	_lock_marker.name = "LockMarker"
	var torus := TorusMesh.new()
	torus.inner_radius = 0.35
	torus.outer_radius = 0.48
	torus.rings = 12
	torus.ring_segments = 16
	_lock_marker.mesh = torus
	var mat := StandardMaterial3D.new()
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = Color(1.0, 0.35, 0.35, 0.75)
	mat.emission_enabled = true
	mat.emission = Color(1.0, 0.25, 0.25)
	mat.emission_energy_multiplier = 2.2
	_lock_marker.material_override = mat
	_lock_marker.visible = false
	add_child(_lock_marker)


func _setup_character_visual() -> void:
	_visual = CharacterVisualScript.attach(self, "Characters_Matt.gltf", {
		"scale": 1.0,
		"hide_mesh": mesh,
		"yaw_deg": 180.0,
	})
	if has_node("FaceMarker"):
		$FaceMarker.visible = false


func _update_character_anim() -> void:
	if _visual == null:
		return
	match state:
		State.DEAD:
			_visual.play("Death")
		State.HIT:
			_visual.play("HitReact")
		State.ROLL:
			_visual.play("Duck")
		State.HEALING:
			_visual.play("Idle")
		State.ATTACK_LIGHT:
			_visual.play("Punch" if _combo_step >= 1 else "Slash")
		State.ATTACK_HEAVY:
			_visual.play("Stab" if not _is_ranged() else "Slash")
		State.MOVE:
			if not is_on_floor():
				if velocity.y > 0.5:
					_visual.play("Jump")
				else:
					_visual.play("Jump_Idle")
			else:
				var spd := Vector3(velocity.x, 0.0, velocity.z).length()
				var run_th := float(_cfg.get("run_speed", 7.0)) * 0.72
				_visual.play_locomotion(spd, run_th)


func _apply_balance() -> void:
	_cfg = Balance.player()
	_roll = _cfg.get("rolamento", {})
	var arma: Dictionary = Balance.arma(GameState.weapon_id())
	_light = arma.get("ataque_leve", {})
	_heavy = arma.get("ataque_pesado", {})

	max_health = float(_cfg.get("max_health", 100)) + GameState.bonus_max_health()
	max_stamina = float(_cfg.get("max_stamina", 100)) + GameState.bonus_max_stamina()
	health = minf(health, max_health)
	stamina = minf(stamina, max_stamina)

	var radius := float(_cfg.get("capsule_radius", 0.35))
	var height := float(_cfg.get("capsule_height", 1.8))
	var col := $CollisionShape3D
	if col.shape is CapsuleShape3D:
		var cap := col.shape as CapsuleShape3D
		cap.radius = radius
		cap.height = height
	if mesh.mesh is CapsuleMesh:
		var cm := mesh.mesh as CapsuleMesh
		cm.radius = radius
		cm.height = height

	if _is_ranged():
		_update_attack_shape(0.4, 0.4)
	else:
		_update_attack_shape(float(_light.get("alcance", 1.3)), float(_light.get("altura", 1.1)))

	_refresh_weapon_visual()
	health_changed.emit(health, max_health)
	stamina_changed.emit(stamina, max_stamina)
	weapon_changed.emit(GameState.weapon_id())


func _is_ranged() -> bool:
	return GameState.weapon_id() == "virus"


func _physics_process(delta: float) -> void:
	if state == State.DEAD:
		return

	_tick_timers(delta)
	_apply_gravity(delta)
	_refresh_speed_mult()
	_tick_ability(delta)

	match state:
		State.MOVE:
			_process_move(delta)
		State.ROLL:
			_process_roll(delta)
		State.ATTACK_LIGHT, State.ATTACK_HEAVY:
			_process_attack(delta)
		State.HIT:
			_process_hit(delta)
		State.HEALING:
			_process_healing(delta)

	move_and_slide()
	_update_mesh_facing(delta)
	_update_roll_visual()
	_update_lock_marker(delta)
	_update_character_anim()
	if _roll_ghost_timer > 0.0:
		_roll_ghost_timer -= delta


func _update_lock_marker(delta: float) -> void:
	if _lock_marker == null:
		return
	if lock_target and is_instance_valid(lock_target):
		if lock_target.has_method("is_alive") and not lock_target.is_alive():
			lock_target = null
		elif "health" in lock_target and float(lock_target.health) <= 0.0:
			lock_target = null
	if lock_target and is_instance_valid(lock_target):
		# top_level evita o marker herdar yaw do player e "orbita" errado
		_lock_marker.top_level = true
		_lock_marker.visible = true
		_lock_marker.global_position = lock_target.global_position + Vector3.UP * 2.35
		_lock_marker.rotate_y(delta * 2.8)
	else:
		if lock_target != null and not is_instance_valid(lock_target):
			lock_target = null
		_lock_marker.visible = false
		_lock_marker.top_level = false


func _tick_timers(delta: float) -> void:
	if invuln_timer > 0.0:
		invuln_timer -= delta
	if coyote_timer > 0.0:
		coyote_timer -= delta
	if jump_buffer_timer > 0.0:
		jump_buffer_timer -= delta
	if _combo_window > 0.0:
		_combo_window -= delta
		if _combo_window <= 0.0 and state == State.MOVE:
			_combo_step = 0
			_queued_combo = false
	if _mark_timer > 0.0:
		_mark_timer -= delta
		if _mark_timer <= 0.0:
			_mark_mult = 1.0
			if state == State.MOVE:
				_set_mesh_color(_default_color)
	if stamina_regen_timer > 0.0:
		stamina_regen_timer -= delta
	elif state == State.MOVE:
		var regen := float(_cfg.get("stamina_regen", 40))
		var before := stamina
		stamina = minf(max_stamina, stamina + regen * delta)
		if stamina != before:
			stamina_changed.emit(stamina, max_stamina)

	if is_on_floor():
		coyote_timer = float(_cfg.get("coyote_time", 0.1))


func _refresh_speed_mult() -> void:
	speed_mult = _ground_slow * _mark_mult


func _apply_gravity(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= float(_cfg.get("gravity", 22.0)) * delta
		velocity.y = maxf(velocity.y, -float(_cfg.get("max_fall_speed", 28.0)))


func _input_dir() -> Vector3:
	var raw := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	if GameState.controls_inverted:
		raw = -raw
	var cam := get_viewport().get_camera_3d()
	var basis_yaw := Vector3.FORWARD
	if cam:
		var flat := -cam.global_transform.basis.z
		flat.y = 0.0
		if flat.length_squared() > 0.001:
			basis_yaw = flat.normalized()
	var right := basis_yaw.cross(Vector3.UP).normalized()
	var dir := (basis_yaw * -raw.y + right * raw.x)
	if dir.length_squared() > 1.0:
		dir = dir.normalized()
	return dir


func _aim_dir() -> Vector3:
	if lock_target and is_instance_valid(lock_target):
		var to := lock_target.global_position - global_position
		to.y = 0.0
		if to.length_squared() > 0.01:
			return to.normalized()
	return facing


func _process_move(delta: float) -> void:
	if Input.is_action_just_pressed("jump"):
		jump_buffer_timer = float(_cfg.get("jump_buffer", 0.12))
	if Input.is_action_just_released("jump") and velocity.y > 0.0:
		velocity.y *= float(_cfg.get("jump_cut_multiplier", 0.45))

	if jump_buffer_timer > 0.0 and coyote_timer > 0.0:
		velocity.y = float(_cfg.get("jump_velocity", 8.5))
		jump_buffer_timer = 0.0
		coyote_timer = 0.0

	var dir := _input_dir()
	var sprinting := Input.is_action_pressed("sprint") and dir.length_squared() > 0.01
	_was_sprinting = sprinting
	var target_speed := float(_cfg.get("run_speed", 8.8) if sprinting else _cfg.get("walk_speed", 5.3))
	target_speed *= speed_mult
	var accel := float(_cfg.get("ground_accel", 22.0) if is_on_floor() else _cfg.get("air_accel", 14.0))
	var friction := float(_cfg.get("ground_friction", 28.0) if is_on_floor() else _cfg.get("air_friction", 4.0))

	var horizontal := Vector3(velocity.x, 0.0, velocity.z)
	if dir.length_squared() > 0.01:
		facing = dir.normalized()
		# Acelera como o template melee (lerp suave, não snap).
		horizontal = horizontal.lerp(facing * target_speed, clampf(accel * delta / maxf(target_speed, 0.01), 0.0, 1.0))
	else:
		horizontal = horizontal.lerp(Vector3.ZERO, clampf(friction * delta / maxf(target_speed, 1.0), 0.0, 1.0))

	velocity.x = horizontal.x
	velocity.z = horizontal.z

	if Input.is_action_just_pressed("lock_on"):
		_toggle_lock_on()

	if Input.is_action_just_pressed("heal"):
		_try_heal()
		return
	if Input.is_action_just_pressed("ability"):
		_try_ability()
		return
	if Input.is_action_just_pressed("cycle_ability"):
		GameState.cycle_ability()
		return
	if Input.is_action_just_pressed("roll"):
		heavy_charging = false
		_try_roll(dir)
		return
	if Input.is_action_just_pressed("attack_light"):
		heavy_charging = false
		if sprinting:
			_try_sprint_attack(dir)
		else:
			_try_light()
		return
	if Input.is_action_just_pressed("attack_heavy"):
		heavy_charging = true
		heavy_held = 0.0
		_set_mesh_color(Color(1.0, 0.7, 0.35))
		return
	if heavy_charging:
		if Input.is_action_pressed("attack_heavy"):
			heavy_held += delta
			var max_c := float(_heavy.get("carga_maxima", 0.7))
			var t := clampf(heavy_held / max_c, 0.0, 1.0)
			_set_mesh_color(Color(1.0, 0.7 - t * 0.35, 0.35 - t * 0.2))
			if not _is_ranged():
				_sync_charge_telegraph(t)
		else:
			heavy_charging = false
			_sync_atk_telegraph(false, false)
			_try_heavy(heavy_held)
			return


func _try_sprint_attack(dir: Vector3) -> void:
	## Sprint + leve = “big attack” do template: dash + golpe pesado rápido.
	var cost := float(_heavy.get("vigor", 32)) * 0.85
	if not _require_stamina(cost):
		_try_light()
		return
	_spend_stamina(cost)
	_sprint_attack = true
	_combo_step = 0
	_queued_combo = false
	if dir.length_squared() > 0.01:
		facing = dir.normalized()
	state = State.ATTACK_HEAVY
	_charge_ratio = 0.55
	_hit_targets.clear()
	attack_area.monitoring = false
	_clear_attack_meta()
	var dash := float(_cfg.get("sprint_attack_dash", 10.5))
	velocity.x = facing.x * dash
	velocity.z = facing.z * dash
	if not _is_ranged():
		_update_attack_shape(float(_heavy.get("alcance", 1.6)), float(_heavy.get("altura", 1.3)))
	_set_mesh_color(Color(1.0, 0.4, 0.2))
	_pulse_weapon(Color(1.0, 0.35, 0.15))


func _try_roll(dir: Vector3) -> void:
	var cost := float(_roll.get("vigor", 25))
	if not _require_stamina(cost):
		return
	_spend_stamina(cost)
	heavy_charging = false
	_sync_atk_telegraph(false, false)
	_clear_attack_meta()
	attack_area.monitoring = false
	state = State.ROLL
	roll_timer = float(_roll.get("duracao", 0.42))
	roll_dir = dir.normalized() if dir.length_squared() > 0.01 else facing
	facing = roll_dir
	_set_mesh_color(Color(0.55, 0.75, 1.0))


func _process_roll(delta: float) -> void:
	roll_timer -= delta
	var spd := float(_roll.get("velocidade", 11.7)) * speed_mult
	velocity.x = roll_dir.x * spd
	velocity.z = roll_dir.z * spd

	# Roll → ataque (template melee “rollattack”)
	if Input.is_action_just_pressed("attack_light"):
		_roll_attack_queued = true

	if roll_timer <= 0.0:
		state = State.MOVE
		_set_mesh_color(_default_color)
		if _roll_attack_queued:
			_roll_attack_queued = false
			_try_sprint_attack(roll_dir)


func _try_light() -> void:
	# Combo durante o golpe atual (janela no active/recover)
	if state == State.ATTACK_LIGHT:
		var max_c := int(_cfg.get("combo_max", 2))
		if _combo_step + 1 < max_c:
			_queued_combo = true
		return

	var cost := float(_light.get("vigor", 16))
	if not _require_stamina(cost):
		return
	_spend_stamina(cost)
	_sprint_attack = false
	state = State.ATTACK_LIGHT
	_hit_targets.clear()
	_charge_ratio = 0.0
	attack_area.monitoring = false
	_clear_attack_meta()
	if not _is_ranged():
		_update_attack_shape(float(_light.get("alcance", 1.3)), float(_light.get("altura", 1.1)))
	_set_mesh_color(Color(1.0, 0.85, 0.4) if _combo_step == 0 else Color(1.0, 0.7, 0.35))
	_pulse_weapon(Color(1.0, 0.95, 0.5))
	_combo_window = float(_cfg.get("combo_janela", 0.45))


func _try_heavy(held: float) -> void:
	var cost := float(_heavy.get("vigor", 32))
	if not _require_stamina(cost):
		_set_mesh_color(_default_color)
		_sync_atk_telegraph(false, false)
		return
	_spend_stamina(cost)
	_sprint_attack = false
	_combo_step = 0
	_queued_combo = false
	state = State.ATTACK_HEAVY
	_charge_ratio = clampf(held / float(_heavy.get("carga_maxima", 0.7)), 0.0, 1.0)
	_hit_targets.clear()
	attack_area.monitoring = false
	_clear_attack_meta()
	if not _is_ranged():
		_update_attack_shape(float(_heavy.get("alcance", 1.6)), float(_heavy.get("altura", 1.3)))
	_set_mesh_color(Color(1.0, 0.45, 0.25))
	_pulse_weapon(Color(1.0, 0.4, 0.2))


func _process_attack(delta: float) -> void:
	var cfg := _light if state == State.ATTACK_LIGHT else _heavy
	if not has_meta("_atk_phase"):
		var prep := float(cfg.get("preparacao", 0.1))
		if state == State.ATTACK_HEAVY:
			prep += _charge_ratio * 0.12
			if _sprint_attack:
				prep *= 0.65
		elif _combo_step >= 1:
			prep *= 0.7
		set_meta("_atk_phase", "windup")
		set_meta("_atk_phase_t", prep)

	# Buffer de combo no meio do golpe
	if state == State.ATTACK_LIGHT and Input.is_action_just_pressed("attack_light"):
		var max_c := int(_cfg.get("combo_max", 2))
		if _combo_step + 1 < max_c:
			_queued_combo = true

	var phase: String = str(get_meta("_atk_phase"))
	var phase_t: float = float(get_meta("_atk_phase_t")) - delta
	set_meta("_atk_phase_t", phase_t)

	var avanco := float(cfg.get("avanco", 0.0))
	if _sprint_attack:
		avanco = maxf(avanco, float(_cfg.get("sprint_attack_dash", 10.5)) * 0.35)
	var push := 0.0
	if phase == "windup":
		push = avanco * (0.55 if _sprint_attack else 0.35)
	elif phase == "active":
		push = avanco * (0.7 if _sprint_attack else 0.55)
	# Quase trava o movimento livre durante ataque (feel do template)
	var move_mult := float(_cfg.get("attack_move_mult", 0.08))
	var steer := _input_dir() * move_mult * float(_cfg.get("walk_speed", 5.3))
	velocity.x = facing.x * push + steer.x
	velocity.z = facing.z * push + steer.z

	if phase == "windup":
		facing = _aim_dir()
		if not _is_ranged():
			_sync_atk_telegraph(true, false)

	if phase_t > 0.0:
		return

	match phase:
		"windup":
			set_meta("_atk_phase", "active")
			var hit_t := float(cfg.get("acerto", 0.08))
			if _combo_step >= 1:
				hit_t *= 0.85
			set_meta("_atk_phase_t", hit_t)
			if _is_ranged():
				_spawn_virus(cfg)
			else:
				attack_area.monitoring = true
				_place_hitbox()
				_sync_atk_telegraph(true, true)
		"active":
			set_meta("_atk_phase", "recover")
			var rec := float(cfg.get("recuperacao", 0.25))
			if _combo_step >= 1:
				rec *= 0.8
			set_meta("_atk_phase_t", rec)
			attack_area.monitoring = false
			_sync_atk_telegraph(false, false)
		"recover":
			_clear_attack_meta()
			_sprint_attack = false
			_sync_atk_telegraph(false, false)
			if state == State.ATTACK_LIGHT and _queued_combo:
				_queued_combo = false
				_combo_step += 1
				_combo_window = float(_cfg.get("combo_janela", 0.45))
				state = State.MOVE
				_try_light()
			else:
				if state == State.ATTACK_LIGHT:
					_combo_window = float(_cfg.get("combo_janela", 0.45))
				else:
					_combo_step = 0
				state = State.MOVE
				_set_mesh_color(_default_color)
				_refresh_weapon_visual()


func _roll_invulnerable() -> bool:
	if state != State.ROLL:
		return false
	var dur := float(_roll.get("duracao", 0.42))
	var elapsed := dur - roll_timer
	var inv_start := float(_roll.get("inv_inicio", 0.05))
	var inv_dur := float(_roll.get("inv_duracao", 0.26))
	return elapsed >= inv_start and elapsed <= inv_start + inv_dur


func _update_roll_visual() -> void:
	if state != State.ROLL:
		if _visual and _visual.root:
			_visual.root.scale = Vector3.ONE
		return
	# Feedback visual só durante a janela real de i-frame.
	if _roll_invulnerable():
		_set_mesh_color(Color(0.75, 0.95, 1.0))
		_roll_ghost_timer = 0.12
		if _visual and _visual.root:
			_visual.root.scale = Vector3(1.08, 0.92, 1.08)
	else:
		_set_mesh_color(Color(0.45, 0.55, 0.75))
		if _visual and _visual.root:
			_visual.root.scale = Vector3.ONE



func _spawn_virus(cfg: Dictionary) -> void:
	var proj := VIRUS_SCENE.instantiate()
	var dir := _aim_dir()
	facing = dir
	var spawn_pos := global_position + Vector3.UP * 1.1 + dir * 0.7
	if not SceneUtil.add_to_world(proj, self, spawn_pos):
		return
	var shot_cfg := cfg.duplicate()
	if state == State.ATTACK_HEAVY:
		var base := float(_heavy.get("dano", 18))
		var charged := float(_heavy.get("dano_carregado", 32))
		shot_cfg["dano"] = lerpf(base, charged, _charge_ratio)
		shot_cfg["raio"] = float(_heavy.get("raio", 0.4))
		shot_cfg["quique"] = float(_heavy.get("quique", 0.55))
	else:
		shot_cfg["quique"] = float(_light.get("quique", 0.35))
	shot_cfg["dano"] = float(shot_cfg.get("dano", cfg.get("dano", 9))) * GameState.damage_multiplier()
	proj.setup(shot_cfg, dir, self)
	HitFeel.punch(0.03)


func _process_hit(delta: float) -> void:
	action_timer -= delta
	velocity.x = move_toward(velocity.x, 0.0, 20.0 * delta)
	velocity.z = move_toward(velocity.z, 0.0, 20.0 * delta)
	if action_timer <= 0.0:
		state = State.MOVE
		_set_mesh_color(_default_color)


func _place_hitbox() -> void:
	var alcance := float((_light if state == State.ATTACK_LIGHT else _heavy).get("alcance", 1.3))
	attack_area.position = Vector3(0.0, 0.9, 0.0) + facing * (alcance * 0.55)
	var look := global_position + facing + Vector3.UP * 0.9
	if attack_area.global_position.distance_squared_to(look) > 0.001:
		attack_area.look_at(look, Vector3.UP)


func _sync_atk_telegraph(active: bool, flash: bool) -> void:
	if _atk_telegraph == null or _is_ranged():
		AttackTelegraphScript.set_active(_atk_telegraph, false)
		return
	var cfg := _heavy if state == State.ATTACK_HEAVY or heavy_charging else _light
	var alcance := float(cfg.get("alcance", 1.3))
	var altura := float(cfg.get("altura", 1.1))
	if _atk_telegraph.mesh is BoxMesh:
		(_atk_telegraph.mesh as BoxMesh).size = Vector3(0.7, altura, maxf(alcance, 0.3))
	_atk_telegraph.position = Vector3(0.0, 0.9, 0.0) + facing * (alcance * 0.55)
	AttackTelegraphScript.set_active(_atk_telegraph, active, flash)


func _sync_charge_telegraph(charge_t: float) -> void:
	## Durante carga do pesado: fantasma cresce e pisca perto do máximo.
	if _atk_telegraph == null or _is_ranged():
		return
	facing = _aim_dir()
	var alcance := float(_heavy.get("alcance", 1.6)) * lerpf(0.55, 1.0, charge_t)
	var altura := float(_heavy.get("altura", 1.3))
	if _atk_telegraph.mesh is BoxMesh:
		(_atk_telegraph.mesh as BoxMesh).size = Vector3(0.7, altura, maxf(alcance, 0.3))
	_atk_telegraph.position = Vector3(0.0, 0.9, 0.0) + facing * (alcance * 0.55)
	AttackTelegraphScript.set_active(_atk_telegraph, true, charge_t >= 0.85)


func _update_attack_shape(alcance: float, altura: float) -> void:
	if attack_shape.shape is BoxShape3D:
		var box := attack_shape.shape as BoxShape3D
		box.size = Vector3(0.7, altura, maxf(alcance, 0.3))


func _on_attack_body_entered(body: Node3D) -> void:
	_try_damage_target(body)


func _on_attack_area_entered(area: Area3D) -> void:
	_try_damage_target(area.get_parent())


func _try_damage_target(target: Node) -> void:
	if target == null or target == self or target in _hit_targets:
		return
	if not target.has_method("take_damage"):
		return
	_hit_targets.append(target)
	var cfg := _light if state == State.ATTACK_LIGHT else _heavy
	var dmg := float(cfg.get("dano", 12))
	if state == State.ATTACK_HEAVY:
		var base := float(_heavy.get("dano", 26))
		var charged := float(_heavy.get("dano_carregado", 45))
		dmg = lerpf(base, charged, _charge_ratio)
	dmg *= GameState.damage_multiplier()
	var knock := facing * float(Balance.get_path_value("impacto.empurrao_no_alvo", 3.5))
	target.take_damage(dmg, knock, self)
	var killed := false
	if "health" in target:
		killed = float(target.health) <= 0.0
	if killed:
		HitFeel.kill_punch()
		HitFeel.spark_at(target.global_position + Vector3.UP * 1.2, Color(1.0, 0.55, 0.2), 1.35)
	else:
		HitFeel.punch()
		HitFeel.spark_at(target.global_position + Vector3.UP * 1.1, Color(1.0, 0.9, 0.4), 1.0)
	_pulse_weapon(Color(1.0, 1.0, 0.7))


func refresh_progression() -> void:
	var base_hp := float(Balance.player().get("max_health", 100))
	var base_st := float(Balance.player().get("max_stamina", 100))
	var old_max_hp := max_health
	max_health = base_hp + GameState.bonus_max_health()
	max_stamina = base_st + GameState.bonus_max_stamina()
	if max_health > old_max_hp:
		health += max_health - old_max_hp
	health = minf(health, max_health)
	stamina = minf(stamina, max_stamina)
	health_changed.emit(health, max_health)
	stamina_changed.emit(stamina, max_stamina)
	drinks_changed.emit(GameState.heals, GameState.max_heals)


func heal(amount: float) -> void:
	if state == State.DEAD:
		return
	var before := health
	health = minf(max_health, health + amount)
	if health != before:
		health_changed.emit(health, max_health)
		# Só popup em cura “de lata” (>=1); safezone drip é fracionária.
		if amount >= 1.0:
			var pop := POPUP_SCENE.instantiate()
			pop.amount = health - before
			pop.color = Color(0.45, 1.0, 0.55)
			SceneUtil.add_to_world(pop, self, global_position + Vector3(0, 1.8, 0))
			HitFeel.spark_at(global_position + Vector3.UP * 1.2, Color(0.4, 1.0, 0.5), 0.7)


func apply_mark(duration: float, mult: float) -> void:
	var was_clear := _mark_timer <= 0.0
	_mark_timer = maxf(_mark_timer, duration)
	_mark_mult = mult
	_set_mesh_color(Color(0.75, 0.45, 1.0))
	if was_clear:
		GameState.show_toast("MARCADO · velocidade reduzida")
		HitFeel.shake(0.15)
		HitFeel.spark_at(global_position + Vector3.UP * 1.3, Color(0.85, 0.35, 1.0), 0.95)


func is_marked() -> bool:
	return _mark_timer > 0.0


func mark_remaining() -> float:
	return maxf(0.0, _mark_timer)


func set_ground_slow(mult: float) -> void:
	_ground_slow = mult


func clear_ground_slow() -> void:
	_ground_slow = 1.0


func _try_heal() -> void:
	if state != State.MOVE:
		return
	if health >= max_health - 0.5:
		GameState.show_toast("Vida cheia")
		return
	if GameState.heals <= 0:
		GameState.show_toast("Sem latas")
		return
	if not GameState.try_consume_heal():
		return
	state = State.HEALING
	heavy_charging = false
	_heal_timer = float(Balance.data.get("cura", {}).get("tempo_uso", 1.15))
	velocity.x = 0.0
	velocity.z = 0.0
	_set_mesh_color(Color(0.45, 1.0, 0.55))
	drinks_changed.emit(GameState.heals, GameState.max_heals)
	GameState.show_toast("Bebendo lata…")


func _process_healing(delta: float) -> void:
	_heal_timer -= delta
	velocity.x = 0.0
	velocity.z = 0.0
	if _heal_timer <= 0.0:
		var amount := float(Balance.data.get("cura", {}).get("cura", 45))
		heal(amount)
		state = State.MOVE
		_set_mesh_color(_default_color)
		var hud := get_tree().get_first_node_in_group("hud")
		if hud and hud.has_method("pulse_heal"):
			hud.pulse_heal()
		HitFeel.shake(0.18)


func _on_died() -> void:
	HitFeel.shake(0.7)
	GameState.show_toast("Você caiu… voltando à entrada")
	var hud := get_tree().get_first_node_in_group("hud")
	if hud and hud.has_method("play_death_fade"):
		await hud.play_death_fade()
	else:
		await get_tree().create_timer(1.6).timeout
	_respawn()


func _respawn() -> void:
	state = State.MOVE
	health = max_health
	stamina = max_stamina
	invuln_timer = 1.0
	_mark_timer = 0.0
	_mark_mult = 1.0
	_ground_slow = 1.0
	_eco_pending = false
	_clear_eco_telegraph()
	_clear_attack_meta()
	attack_area.monitoring = false
	heavy_charging = false
	if typeof(HitFeel) != TYPE_NIL and HitFeel.has_method("cancel"):
		HitFeel.cancel()
	global_position = GameState.safezone_position
	velocity = Vector3.ZERO
	_set_mesh_color(_default_color)
	health_changed.emit(health, max_health)
	stamina_changed.emit(stamina, max_stamina)
	GameState.refill_heals()
	GameState.clear_hacks()
	drinks_changed.emit(GameState.heals, GameState.max_heals)
	GameState.show_toast("Safezone · latas restauradas")


func _tick_ability(delta: float) -> void:
	if _ability_cd > 0.0:
		_ability_cd -= delta
	if _eco_pending:
		_eco_timer -= delta
		if _eco_telegraph != null and is_instance_valid(_eco_telegraph):
			AttackTelegraphScript.set_active(_eco_telegraph, true, _eco_timer < 0.2)
		if _eco_timer <= 0.0:
			_eco_pending = false
			_resolve_eco()


func _try_ability() -> void:
	if state != State.MOVE and state != State.ROLL:
		return
	if GameState.equipped_ability.is_empty():
		GameState.show_toast("Sem habilidade equipada")
		return
	if _ability_cd > 0.0:
		GameState.show_toast("%s em recarga · %.1fs" % [GameState.ability_label(), _ability_cd])
		return
	match GameState.equipped_ability:
		GameState.ABILITY_CARAMELO:
			_cast_caramelo()
		GameState.ABILITY_ECO:
			_cast_eco()
		GameState.ABILITY_ESPELHO:
			GameState.show_toast("Espelho: role através do golpe")
			_ability_cd = 0.4
		_:
			pass


func _cast_caramelo() -> void:
	var cost := 20.0
	if stamina < cost:
		GameState.show_toast("Vigor insuficiente")
		return
	_spend_stamina(cost)
	_ability_cd = 6.0
	var puddle := PUDDLE_SCENE.instantiate()
	var pos := global_position + facing * 1.2 + Vector3(0, 0.05, 0)
	if not SceneUtil.add_to_world(puddle, self, pos):
		return
	puddle.setup(2.4, 5.5, 0.4)
	_set_mesh_color(Color(0.85, 0.55, 0.2))
	GameState.show_toast("Caramelo!")


func _cast_eco() -> void:
	var cost := 22.0
	if stamina < cost:
		GameState.show_toast("Vigor insuficiente")
		return
	_spend_stamina(cost)
	_ability_cd = 5.0
	_eco_pending = true
	_eco_timer = 0.55
	_eco_pos = global_position + facing * 2.2
	if lock_target and is_instance_valid(lock_target):
		_eco_pos = lock_target.global_position
	_set_mesh_color(Color(0.55, 0.85, 1.0))
	_spawn_eco_telegraph()
	GameState.show_toast("Eco…")


func _spawn_eco_telegraph() -> void:
	_clear_eco_telegraph()
	var host := get_tree().current_scene
	if host == null:
		host = self
	_eco_telegraph = AttackTelegraphScript.make_sphere(
		host,
		2.1,
		Vector3.ZERO,
		Color(0.45, 0.85, 1.0, 0.32)
	)
	_eco_telegraph.top_level = true
	_eco_telegraph.global_position = _eco_pos + Vector3(0, 0.4, 0)
	AttackTelegraphScript.set_active(_eco_telegraph, true, false)


func _clear_eco_telegraph() -> void:
	if _eco_telegraph != null and is_instance_valid(_eco_telegraph):
		_eco_telegraph.queue_free()
	_eco_telegraph = null


func ability_cooldown_remaining() -> float:
	return maxf(_ability_cd, 0.0)


func _resolve_eco() -> void:
	_set_mesh_color(_default_color)
	_clear_eco_telegraph()
	var dmg := 22.0 * GameState.damage_multiplier()
	for node in get_tree().get_nodes_in_group("enemy"):
		if node == null or not is_instance_valid(node):
			continue
		if not node.has_method("take_damage"):
			continue
		if node.global_position.distance_to(_eco_pos) <= 2.0:
			var away: Vector3 = node.global_position - _eco_pos
			away.y = 0.0
			if away.length_squared() < 0.01:
				away = facing
			node.take_damage(dmg, away.normalized() * 4.0, self)
	for node in get_tree().get_nodes_in_group("boss"):
		if node == null or not is_instance_valid(node):
			continue
		if not node.has_method("take_damage"):
			continue
		if node.global_position.distance_to(_eco_pos) <= 2.2:
			node.take_damage(dmg, facing * 4.0, self)
	if typeof(HitFeel) != TYPE_NIL:
		HitFeel.spark_at(_eco_pos + Vector3.UP * 0.6, Color(0.5, 0.9, 1.0), 1.35)
		HitFeel.punch()


func take_damage(amount: float, knockback: Vector3 = Vector3.ZERO, source: Node = null) -> void:
	if state == State.DEAD:
		return
	# Espelho: rolar através do ataque = contra-golpe.
	if _roll_invulnerable() and GameState.equipped_ability == GameState.ABILITY_ESPELHO:
		if source != null and source.has_method("take_damage"):
			source.take_damage(amount * 1.35 * GameState.damage_multiplier(), -knockback, self)
			HitFeel.punch()
			GameState.show_toast("Espelho!")
			_ability_cd = maxf(_ability_cd, 1.2)
		return
	if is_invulnerable():
		return
	if state == State.HEALING:
		_heal_timer = 0.0
	health = maxf(0.0, health - amount)
	health_changed.emit(health, max_health)
	_spawn_hurt_popup(amount)
	var dmg_cfg: Dictionary = _cfg.get("dano_recebido", {})
	invuln_timer = float(dmg_cfg.get("invencibilidade", 0.7))
	heavy_charging = false
	_clear_attack_meta()
	attack_area.monitoring = false
	if health <= 0.0:
		state = State.DEAD
		died.emit()
		_set_mesh_color(Color(0.3, 0.3, 0.35))
		return
	state = State.HIT
	action_timer = float(dmg_cfg.get("travado", 0.28))
	velocity += knockback
	_set_mesh_color(Color(1.0, 0.3, 0.3))
	HitFeel.shake()
	HitFeel.punch(0.045)
	HitFeel.spark_at(global_position + Vector3.UP * 1.1, Color(1.0, 0.35, 0.3), 1.1)
	var hud := get_tree().get_first_node_in_group("hud")
	if hud and hud.has_method("flash_hurt"):
		hud.flash_hurt()


func _spawn_hurt_popup(amount: float) -> void:
	var pop := POPUP_SCENE.instantiate()
	pop.amount = amount
	pop.color = Color(1.0, 0.35, 0.4)
	SceneUtil.add_to_world(
		pop,
		self,
		global_position + Vector3(randf_range(-0.15, 0.15), 1.7, randf_range(-0.15, 0.15))
	)


func is_invulnerable() -> bool:
	if state == State.DEAD:
		return true
	if _roll_invulnerable():
		return true
	return invuln_timer > 0.0


func _spend_stamina(cost: float) -> void:
	stamina = maxf(0.0, stamina - cost)
	stamina_regen_timer = float(_cfg.get("stamina_regen_delay", 0.7))
	stamina_changed.emit(stamina, max_stamina)


func _require_stamina(cost: float) -> bool:
	if stamina >= cost:
		return true
	var hud := get_tree().get_first_node_in_group("hud")
	if hud and hud.has_method("flash_stamina"):
		hud.flash_stamina()
	return false


func _toggle_lock_on() -> void:
	if lock_target and is_instance_valid(lock_target):
		lock_target = null
		GameState.show_toast("Lock off")
		return
	var best: Node3D = null
	var best_d := float(Balance.camera().get("lock_on_distance", 18.0))
	for body in lock_sensor.get_overlapping_bodies():
		if body == self or not body.is_in_group("lockable"):
			continue
		var d := global_position.distance_to(body.global_position)
		if d < best_d:
			best_d = d
			best = body
	lock_target = best
	if lock_target:
		GameState.show_toast("Lock on")
	else:
		GameState.show_toast("Sem alvo no alcance")
		var hud := get_tree().get_first_node_in_group("hud")
		if hud and hud.has_method("flash_stamina"):
			hud.flash_stamina()

func _update_mesh_facing(delta: float) -> void:
	if facing.length_squared() < 0.001:
		return
	# Godot: -Z é a frente do CharacterBody3D. atan2(x, z) fica 180° errado e
	# com auto-yaw da câmera vira giro no lugar ao andar pra frente.
	var target_yaw := atan2(-facing.x, -facing.z)
	var turn := float(_cfg.get("turn_speed", 12.0))
	rotation.y = lerp_angle(rotation.y, target_yaw, clampf(turn * delta, 0.0, 1.0))


func _clear_attack_meta() -> void:
	if has_meta("_atk_phase"):
		remove_meta("_atk_phase")
	if has_meta("_atk_phase_t"):
		remove_meta("_atk_phase_t")


func _refresh_weapon_visual() -> void:
	if weapon_visual == null:
		return
	var mat := StandardMaterial3D.new()
	if _is_ranged():
		_default_color = Color(0.72, 0.9, 0.78)
		mat.albedo_color = Color(0.35, 1.0, 0.45)
		mat.emission_enabled = true
		mat.emission = Color(0.2, 0.8, 0.35)
		mat.emission_energy_multiplier = 1.4
		if weapon_visual.mesh is BoxMesh:
			(weapon_visual.mesh as BoxMesh).size = Vector3(0.28, 0.28, 0.28)
		weapon_visual.position = Vector3(0.35, 1.15, 0.25)
	else:
		_default_color = Color(0.85, 0.85, 0.9)
		mat.albedo_color = Color(0.2, 0.2, 0.22)
		if weapon_visual.mesh is BoxMesh:
			(weapon_visual.mesh as BoxMesh).size = Vector3(0.55, 0.12, 0.28)
		weapon_visual.position = Vector3(0.45, 1.05, 0.35)
	weapon_visual.material_override = mat
	if state == State.MOVE:
		_set_mesh_color(_default_color)


func _pulse_weapon(c: Color) -> void:
	if weapon_visual == null:
		return
	var mat := weapon_visual.material_override as StandardMaterial3D
	if mat == null:
		mat = StandardMaterial3D.new()
		weapon_visual.material_override = mat
	mat.albedo_color = c
	mat.emission_enabled = true
	mat.emission = c
	mat.emission_energy_multiplier = 2.0


func _set_mesh_color(c: Color) -> void:
	var mat := mesh.material_override as StandardMaterial3D
	if mat == null:
		mat = StandardMaterial3D.new()
		mesh.material_override = mat
	mat.albedo_color = c
	if _visual == null:
		return
	var flash := c.r > 0.95 and c.g > 0.95 and c.b > 0.95
	var hit := c.r > 0.75 and c.g < 0.45 and c.b < 0.45
	_visual.set_flash(flash or hit, c)
