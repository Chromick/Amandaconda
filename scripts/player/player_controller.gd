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
var _virus_charge_fx: MeshInstance3D
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
var _ability_cd_toast_cd: float = 0.0
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
var _was_on_floor: bool = true
var _land_dust_cd: float = 0.0
var _stamina_toast_cd: float = 0.0
var _air_vy: float = 0.0
var _sprint_empty_toasted: bool = false


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
	mat.albedo_color = Color(0.45, 0.95, 1.0, 0.8)
	mat.emission_enabled = true
	mat.emission = Color(0.35, 0.9, 1.0)
	mat.emission_energy_multiplier = 2.4
	_lock_marker.material_override = mat
	_lock_marker.visible = false
	add_child(_lock_marker)
	var lock_light := OmniLight3D.new()
	lock_light.name = "LockLight"
	lock_light.light_color = Color(0.45, 0.95, 1.0)
	lock_light.light_energy = 1.4
	lock_light.omni_range = 2.2
	_lock_marker.add_child(lock_light)


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
	_update_land_fx()
	_update_invuln_blink()
	_update_mesh_facing(delta)
	_update_roll_visual()
	_update_lock_marker(delta)
	_update_character_anim()
	_tick_roll_ghosts(delta)
	if _land_dust_cd > 0.0:
		_land_dust_cd -= delta
	if _stamina_toast_cd > 0.0:
		_stamina_toast_cd -= delta


func _update_land_fx() -> void:
	var on_floor := is_on_floor()
	if not on_floor:
		_air_vy = velocity.y
	if on_floor and not _was_on_floor and _land_dust_cd <= 0.0:
		_land_dust_cd = 0.2
		_spawn_land_dust()
		var impact := absf(_air_vy)
		if typeof(HitFeel) != TYPE_NIL and impact > 4.5:
			HitFeel.shake(clampf(impact * 0.018, 0.06, 0.32))
			for cam in get_tree().get_nodes_in_group("player_camera"):
				if cam and cam.has_method("punch_fov"):
					cam.punch_fov(clampf(impact * 0.28, 1.5, 5.0))
					break
	_was_on_floor = on_floor


func _update_invuln_blink() -> void:
	if state == State.DEAD or state == State.ROLL or state == State.HIT:
		return
	if invuln_timer > 0.0 and state == State.MOVE:
		var on := fmod(Time.get_ticks_msec() * 0.02, 1.0) > 0.45
		_set_mesh_color(_default_color if on else Color(0.55, 0.7, 1.0))
	elif state == State.MOVE and _mark_timer <= 0.0:
		_set_mesh_color(_default_color)


func _spawn_land_dust() -> void:
	var host := get_tree().current_scene
	if host == null:
		return
	var impact := clampf(absf(_air_vy) / 14.0, 0.55, 1.6)
	var count := 4 if impact < 1.1 else 7
	for i in count:
		var p := MeshInstance3D.new()
		var sm := SphereMesh.new()
		sm.radius = 0.06 * impact
		sm.height = 0.12 * impact
		p.mesh = sm
		var mat := StandardMaterial3D.new()
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		mat.albedo_color = Color(0.75, 0.72, 0.65, 0.55)
		p.material_override = mat
		host.add_child(p)
		var ang := TAU * float(i) / float(count) + randf() * 0.35
		var dir := Vector3(cos(ang), 0.12 + randf() * 0.12, sin(ang))
		p.global_position = global_position + Vector3(0, 0.08, 0) + dir * 0.15
		var tw := create_tween()
		tw.tween_property(p, "global_position", p.global_position + dir * (0.55 * impact) + Vector3.UP * 0.22, 0.3)
		tw.parallel().tween_property(mat, "albedo_color:a", 0.0, 0.3)
		tw.tween_callback(p.queue_free)


func _spawn_sprint_dust() -> void:
	var host := get_tree().current_scene
	if host == null:
		return
	var p := MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = 0.05
	sm.height = 0.1
	p.mesh = sm
	var mat := StandardMaterial3D.new()
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = Color(0.7, 0.68, 0.6, 0.4)
	p.material_override = mat
	host.add_child(p)
	var back := -facing
	back.y = 0.0
	if back.length_squared() < 0.01:
		back = Vector3.BACK
	else:
		back = back.normalized()
	p.global_position = global_position + Vector3(0, 0.06, 0) + back * 0.25
	var tw := create_tween()
	tw.tween_property(p, "global_position", p.global_position + back * 0.4 + Vector3.UP * 0.15, 0.22)
	tw.parallel().tween_property(mat, "albedo_color:a", 0.0, 0.22)
	tw.tween_callback(p.queue_free)


func _spawn_jump_dust() -> void:
	_spawn_land_dust()


func _update_lock_marker(delta: float) -> void:
	if _lock_marker == null:
		return
	if lock_target and is_instance_valid(lock_target):
		if lock_target.has_method("is_alive") and not lock_target.is_alive():
			lock_target = null
			_try_auto_relock()
		elif "health" in lock_target and float(lock_target.health) <= 0.0:
			lock_target = null
			_try_auto_relock()
	if lock_target and is_instance_valid(lock_target):
		# top_level evita o marker herdar yaw do player e "orbita" errado
		_lock_marker.top_level = true
		_lock_marker.visible = true
		var bob := sin(Time.get_ticks_msec() * 0.006) * 0.12
		_lock_marker.global_position = lock_target.global_position + Vector3.UP * (2.35 + bob)
		_lock_marker.rotate_y(delta * 2.8)
		var pulse := 1.0 + sin(Time.get_ticks_msec() * 0.01) * 0.12
		_lock_marker.scale = Vector3(pulse, pulse, pulse)
		var mat := _lock_marker.material_override as StandardMaterial3D
		if mat:
			mat.emission_energy_multiplier = 1.8 + sin(Time.get_ticks_msec() * 0.01) * 0.9
			mat.albedo_color.a = 0.55 + sin(Time.get_ticks_msec() * 0.008) * 0.25
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
			_refresh_speed_mult()
			if state == State.MOVE:
				_set_mesh_color(_default_color)
			GameState.show_toast("Marca dissipada")
			if typeof(HitFeel) != TYPE_NIL:
				HitFeel.spark_at(global_position + Vector3.UP * 1.2, Color(0.85, 0.55, 1.0), 0.6)
			for cam in get_tree().get_nodes_in_group("player_camera"):
				if cam and cam.has_method("punch_fov"):
					cam.punch_fov(-2.0)
					break
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
		_spawn_jump_dust()
		for cam in get_tree().get_nodes_in_group("player_camera"):
			if cam and cam.has_method("punch_fov"):
				cam.punch_fov(1.8)
				break

	var dir := _input_dir()
	var wants_sprint := Input.is_action_pressed("sprint") and dir.length_squared() > 0.01 and stamina > 1.0
	var sprinting := wants_sprint
	if sprinting and is_on_floor():
		var drain := float(_cfg.get("sprint_stamina_drain", 7.5))
		stamina = maxf(0.0, stamina - drain * delta)
		stamina_changed.emit(stamina, max_stamina)
		stamina_regen_timer = maxf(stamina_regen_timer, 0.35)
		if stamina <= 0.5:
			sprinting = false
			if not _sprint_empty_toasted and _stamina_toast_cd <= 0.0:
				_sprint_empty_toasted = true
				GameState.show_toast("Vigor baixo · caminhando")
				_stamina_toast_cd = 1.2
	elif stamina > 15.0:
		_sprint_empty_toasted = false
	if sprinting and not _was_sprinting and is_on_floor():
		for cam in get_tree().get_nodes_in_group("player_camera"):
			if cam and cam.has_method("punch_fov"):
				cam.punch_fov(2.2)
				break
	_was_sprinting = sprinting
	var target_speed := float(_cfg.get("run_speed", 8.8) if sprinting else _cfg.get("walk_speed", 5.3))
	target_speed *= speed_mult
	var accel := float(_cfg.get("ground_accel", 22.0) if is_on_floor() else _cfg.get("air_accel", 14.0))
	var friction := float(_cfg.get("ground_friction", 28.0) if is_on_floor() else _cfg.get("air_friction", 4.0))

	if is_on_floor() and dir.length_squared() > 0.01 and _land_dust_cd <= 0.0:
		if sprinting:
			_land_dust_cd = 0.12
			_spawn_sprint_dust()
		elif Vector3(velocity.x, 0.0, velocity.z).length() > 2.5:
			_land_dust_cd = 0.28
			_spawn_sprint_dust()

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
		if has_meta("_charge_ready_fx"):
			remove_meta("_charge_ready_fx")
		_set_mesh_color(Color(1.0, 0.7, 0.35))
		return
	if heavy_charging:
		if Input.is_action_pressed("attack_heavy"):
			heavy_held += delta
			var max_c := float(_heavy.get("carga_maxima", 0.7))
			var t := clampf(heavy_held / max_c, 0.0, 1.0)
			_set_mesh_color(Color(1.0, 0.7 - t * 0.35, 0.35 - t * 0.2))
			if _is_ranged():
				_sync_virus_charge_telegraph(t)
			else:
				_sync_charge_telegraph(t)
			if t >= 0.95 and not has_meta("_charge_ready_fx"):
				set_meta("_charge_ready_fx", true)
				HitFeel.spark_at(global_position + Vector3.UP * 1.2, Color(1.0, 0.55, 0.25), 0.55)
				HitFeel.shake(0.06)
		else:
			if has_meta("_charge_ready_fx"):
				remove_meta("_charge_ready_fx")
			heavy_charging = false
			_sync_atk_telegraph(false, false)
			_clear_virus_charge_telegraph()
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
	if typeof(HitFeel) != TYPE_NIL:
		HitFeel.spark_at(global_position + Vector3.UP * 0.4 + facing * 0.5, Color(1.0, 0.55, 0.25), 0.75)
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
	GameState.show_toast("Investida!")
	for cam in get_tree().get_nodes_in_group("player_camera"):
		if cam and cam.has_method("punch_fov"):
			cam.punch_fov(3.5)
			break
	_pulse_weapon(Color(1.0, 0.35, 0.15))
	for cam in get_tree().get_nodes_in_group("player_camera"):
		if cam and cam.has_method("punch_fov"):
			cam.punch_fov(4.0)
			break


func _try_roll(dir: Vector3) -> void:
	var cost := float(_roll.get("vigor", 25))
	if not _require_stamina(cost):
		return
	_spend_stamina(cost)
	heavy_charging = false
	_sync_atk_telegraph(false, false)
	_clear_virus_charge_telegraph()
	_clear_attack_meta()
	attack_area.monitoring = false
	state = State.ROLL
	roll_timer = float(_roll.get("duracao", 0.42))
	roll_dir = dir.normalized() if dir.length_squared() > 0.01 else facing
	facing = roll_dir
	_set_mesh_color(Color(0.55, 0.75, 1.0))
	for cam in get_tree().get_nodes_in_group("player_camera"):
		if cam and cam.has_method("punch_fov"):
			cam.punch_fov(2.2)
			break
	if typeof(HitFeel) != TYPE_NIL:
		HitFeel.shake(0.05)


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
		var max_c := int(_cfg.get("combo_max", 3))
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
		_clear_virus_charge_telegraph()
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
	_clear_virus_charge_telegraph()
	if not _is_ranged():
		_update_attack_shape(float(_heavy.get("alcance", 1.6)), float(_heavy.get("altura", 1.3)))
	_set_mesh_color(Color(1.0, 0.45, 0.25))
	_pulse_weapon(Color(1.0, 0.4, 0.2))
	if _charge_ratio >= 0.7:
		for cam in get_tree().get_nodes_in_group("player_camera"):
			if cam and cam.has_method("punch_fov"):
				cam.punch_fov(3.0 + _charge_ratio * 4.0)
				break
		if typeof(HitFeel) != TYPE_NIL:
			HitFeel.shake(0.08 + _charge_ratio * 0.12)


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
		var max_c := int(_cfg.get("combo_max", 3))
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
	elif phase == "active" and not _is_ranged() and Engine.get_physics_frames() % 2 == 0:
		_spawn_weapon_trail()

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
				if _combo_step >= 1:
					var max_c := int(_cfg.get("combo_max", 3))
					var finisher := _combo_step + 1 >= max_c
					GameState.show_toast("Combo %d%s" % [_combo_step + 1, "!" if finisher else ""])
					HitFeel.spark_at(global_position + Vector3.UP * 1.1 + facing * 0.6, Color(1.0, 0.85, 0.4), 0.7 if not finisher else 1.15)
					if finisher and typeof(HitFeel) != TYPE_NIL:
						HitFeel.shake(0.12)
					for cam in get_tree().get_nodes_in_group("player_camera"):
						if cam and cam.has_method("punch_fov"):
							cam.punch_fov(4.0 if finisher else 2.5)
							break
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
		if _visual and _visual.root:
			_visual.root.scale = Vector3(1.08, 0.92, 1.08)
	else:
		_set_mesh_color(Color(0.45, 0.55, 0.75))
		if _visual and _visual.root:
			_visual.root.scale = Vector3.ONE


func _tick_roll_ghosts(delta: float) -> void:
	if _roll_ghost_timer > 0.0:
		_roll_ghost_timer -= delta
	if state != State.ROLL or not _roll_invulnerable():
		return
	if _roll_ghost_timer > 0.0:
		return
	_roll_ghost_timer = 0.05
	_spawn_roll_ghost()


func _spawn_roll_ghost() -> void:
	var ghost := MeshInstance3D.new()
	ghost.top_level = true
	if mesh and mesh.mesh:
		ghost.mesh = mesh.mesh.duplicate()
	else:
		var cap := CapsuleMesh.new()
		cap.radius = 0.35
		cap.height = 1.5
		ghost.mesh = cap
	var mat := StandardMaterial3D.new()
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = Color(0.55, 0.85, 1.0, 0.5)
	mat.emission_enabled = true
	mat.emission = Color(0.4, 0.75, 1.0)
	mat.emission_energy_multiplier = 1.55
	ghost.material_override = mat
	var host := get_tree().current_scene
	if host == null:
		host = self
	host.add_child(ghost)
	ghost.global_transform = global_transform
	ghost.global_position = global_position + Vector3.UP * 0.05
	var tw := create_tween()
	tw.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tw.tween_property(mat, "albedo_color:a", 0.0, 0.32)
	tw.parallel().tween_property(mat, "emission_energy_multiplier", 0.15, 0.32)
	tw.tween_callback(ghost.queue_free)



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


func _sync_virus_charge_telegraph(charge_t: float) -> void:
	facing = _aim_dir()
	if _virus_charge_fx == null:
		_virus_charge_fx = AttackTelegraphScript.make_sphere(
			self, 0.35, Vector3(0, 1.15, 0.55), Color(0.4, 1.0, 0.55, 0.4)
		)
	var r := lerpf(0.28, 0.55, charge_t)
	if _virus_charge_fx.mesh is SphereMesh:
		(_virus_charge_fx.mesh as SphereMesh).radius = r
		(_virus_charge_fx.mesh as SphereMesh).height = r * 2.0
	_virus_charge_fx.position = Vector3(0, 1.15, 0) + facing * 0.7
	AttackTelegraphScript.set_active(_virus_charge_fx, true, charge_t >= 0.85)


func _clear_virus_charge_telegraph() -> void:
	AttackTelegraphScript.set_active(_virus_charge_fx, false)


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
	if state == State.ATTACK_LIGHT and _combo_step > 0:
		dmg *= 1.0 + float(_combo_step) * 0.1
	if _sprint_attack:
		dmg *= 1.15
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
		var spark_c := Color(1.0, 0.55, 0.25) if state == State.ATTACK_HEAVY else Color(1.0, 0.9, 0.4)
		var spark_s := 1.2 if state == State.ATTACK_HEAVY else 1.0
		HitFeel.spark_at(target.global_position + Vector3.UP * 1.1, spark_c, spark_s)
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
	_refresh_speed_mult()
	_set_mesh_color(Color(0.75, 0.45, 1.0))
	if was_clear:
		GameState.show_toast("MARCADO · velocidade reduzida")
		HitFeel.shake(0.15)
		HitFeel.spark_at(global_position + Vector3.UP * 1.3, Color(0.85, 0.35, 1.0), 0.95)
		var hud := get_tree().get_first_node_in_group("hud")
		if hud and hud.has_method("flash_mark"):
			hud.flash_mark()


func is_marked() -> bool:
	return _mark_timer > 0.0


func mark_remaining() -> float:
	return maxf(0.0, _mark_timer)


func set_ground_slow(mult: float) -> void:
	_ground_slow = mult
	_refresh_speed_mult()


func clear_ground_slow() -> void:
	_ground_slow = 1.0
	_refresh_speed_mult()


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
	if typeof(HitFeel) != TYPE_NIL:
		HitFeel.spark_at(global_position + Vector3.UP * 1.15, Color(0.5, 1.0, 0.6), 0.55)
		HitFeel.shake(0.05)


func _process_healing(delta: float) -> void:
	_heal_timer -= delta
	velocity.x = 0.0
	velocity.z = 0.0
	# Ping visual enquanto bebe.
	if fmod(_heal_timer, 0.28) < delta and typeof(HitFeel) != TYPE_NIL:
		HitFeel.spark_at(global_position + Vector3.UP * (1.0 + randf() * 0.4), Color(0.45, 1.0, 0.55), 0.35)
	if _heal_timer <= 0.0:
		var amount := float(Balance.data.get("cura", {}).get("cura", 45))
		heal(amount)
		state = State.MOVE
		_set_mesh_color(_default_color)
		var hud := get_tree().get_first_node_in_group("hud")
		if hud and hud.has_method("pulse_heal"):
			hud.pulse_heal()
		HitFeel.shake(0.18)
		HitFeel.spark_at(global_position + Vector3.UP * 1.1, Color(0.45, 1.0, 0.55), 1.0)
		for cam in get_tree().get_nodes_in_group("player_camera"):
			if cam and cam.has_method("punch_fov"):
				cam.punch_fov(2.5)
				break


func _on_died() -> void:
	HitFeel.shake(0.7)
	HitFeel.spark_at(global_position + Vector3.UP * 1.0, Color(0.7, 0.15, 0.2), 1.6)
	for cam in get_tree().get_nodes_in_group("player_camera"):
		if cam and cam.has_method("punch_fov"):
			cam.punch_fov(8.0)
			break
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
	_clear_virus_charge_telegraph()
	_sync_atk_telegraph(false, false)
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
	GameState.show_toast("De novo · safezone · latas cheias")
	if typeof(HitFeel) != TYPE_NIL:
		HitFeel.spark_at(global_position + Vector3.UP * 1.1, Color(0.5, 1.0, 0.65), 1.0)
		HitFeel.shake(0.12)
	for cam in get_tree().get_nodes_in_group("player_camera"):
		if cam and cam.has_method("punch_fov"):
			cam.punch_fov(3.0)
			break


func _tick_ability(delta: float) -> void:
	if _ability_cd > 0.0:
		_ability_cd -= delta
	if _ability_cd_toast_cd > 0.0:
		_ability_cd_toast_cd -= delta
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
		if _ability_cd_toast_cd <= 0.0:
			GameState.show_toast("%s em recarga · %.1fs" % [GameState.ability_label(), _ability_cd])
			_ability_cd_toast_cd = 0.85
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
			GameState.show_toast("Sem habilidade · mate um chefe-base")


func _cast_caramelo() -> void:
	if not _require_stamina(20.0):
		return
	_spend_stamina(20.0)
	_ability_cd = 6.0
	var puddle := PUDDLE_SCENE.instantiate()
	var pos := global_position + facing * 1.2 + Vector3(0, 0.05, 0)
	if not SceneUtil.add_to_world(puddle, self, pos):
		return
	puddle.setup(2.4, 5.5, 0.4)
	_set_mesh_color(Color(0.85, 0.55, 0.2))
	HitFeel.spark_at(pos + Vector3(0, 0.4, 0), Color(1.0, 0.7, 0.25))
	for cam in get_tree().get_nodes_in_group("player_camera"):
		if cam and cam.has_method("punch_fov"):
			cam.punch_fov(4.0)
	GameState.show_toast("Caramelo!")


func _cast_eco() -> void:
	if not _require_stamina(22.0):
		return
	_spend_stamina(22.0)
	_ability_cd = 5.0
	_eco_pending = true
	_eco_timer = 0.55
	_eco_pos = global_position + facing * 2.2
	if lock_target and is_instance_valid(lock_target):
		_eco_pos = lock_target.global_position
	_set_mesh_color(Color(0.55, 0.85, 1.0))
	_spawn_eco_telegraph()
	HitFeel.spark_at(_eco_pos + Vector3(0, 0.5, 0), Color(0.5, 0.9, 1.0))
	for cam in get_tree().get_nodes_in_group("player_camera"):
		if cam and cam.has_method("punch_fov"):
			cam.punch_fov(3.5)
	GameState.show_toast("Eco…")


func _spawn_eco_telegraph() -> void:
	_clear_eco_telegraph()
	var host := get_tree().current_scene
	if host == null:
		host = self
	_eco_telegraph = AttackTelegraphScript.make_sphere(
		host,
		2.2,
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
	var hit: Dictionary = {}
	for node in get_tree().get_nodes_in_group("enemy"):
		if node == null or not is_instance_valid(node):
			continue
		if not node.has_method("take_damage"):
			continue
		if node.global_position.distance_to(_eco_pos) > 2.2:
			continue
		var away: Vector3 = node.global_position - _eco_pos
		away.y = 0.0
		if away.length_squared() < 0.01:
			away = facing
		node.take_damage(dmg, away.normalized() * 4.0, self)
		hit[node.get_instance_id()] = true
	for node in get_tree().get_nodes_in_group("boss"):
		if node == null or not is_instance_valid(node):
			continue
		if hit.has(node.get_instance_id()):
			continue
		if not node.has_method("take_damage"):
			continue
		if node.global_position.distance_to(_eco_pos) > 2.2:
			continue
		var away_b: Vector3 = node.global_position - _eco_pos
		away_b.y = 0.0
		if away_b.length_squared() < 0.01:
			away_b = facing
		node.take_damage(dmg, away_b.normalized() * 4.0, self)
	if typeof(HitFeel) != TYPE_NIL:
		HitFeel.spark_at(_eco_pos + Vector3.UP * 0.6, Color(0.5, 0.9, 1.0), 1.35)
		HitFeel.punch()
	for cam in get_tree().get_nodes_in_group("player_camera"):
		if cam and cam.has_method("punch_fov"):
			cam.punch_fov(4.0)
			break


func take_damage(amount: float, knockback: Vector3 = Vector3.ZERO, source: Node = null) -> void:
	if state == State.DEAD:
		return
	# Espelho: rolar através do ataque = contra-golpe.
	if _roll_invulnerable() and GameState.equipped_ability == GameState.ABILITY_ESPELHO:
		if source != null and source.has_method("take_damage"):
			source.take_damage(amount * 1.35 * GameState.damage_multiplier(), -knockback, self)
			HitFeel.punch()
			HitFeel.spark_at(global_position + Vector3.UP * 1.1, Color(1.0, 0.85, 0.35), 1.4)
			HitFeel.spark_at(source.global_position + Vector3.UP * 1.1, Color(1.0, 0.5, 0.2), 1.1)
			HitFeel.shake(0.22)
			GameState.show_toast("Espelho!")
			_ability_cd = maxf(_ability_cd, 1.2)
			for cam in get_tree().get_nodes_in_group("player_camera"):
				if cam and cam.has_method("punch_fov"):
					cam.punch_fov(5.0)
					break
		return
	if is_invulnerable():
		return
	if state == State.HEALING:
		_heal_timer = 0.0
		GameState.show_toast("Cura interrompida")
		HitFeel.shake(0.12)
		HitFeel.spark_at(global_position + Vector3.UP * 1.0, Color(0.9, 0.35, 0.35), 0.7)
	health = maxf(0.0, health - amount)
	health_changed.emit(health, max_health)
	_spawn_hurt_popup(amount)
	var dmg_cfg: Dictionary = _cfg.get("dano_recebido", {})
	invuln_timer = float(dmg_cfg.get("invencibilidade", 0.7))
	heavy_charging = false
	_clear_virus_charge_telegraph()
	_sync_atk_telegraph(false, false)
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
	for cam in get_tree().get_nodes_in_group("player_camera"):
		if cam and cam.has_method("punch_fov"):
			cam.punch_fov(3.5)
			break
	var cam := get_tree().get_first_node_in_group("player_camera")
	if cam and cam.has_method("punch_fov"):
		cam.punch_fov(7.0)
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
	if _stamina_toast_cd <= 0.0:
		GameState.show_toast("Vigor insuficiente")
		_stamina_toast_cd = 0.9
	return false


func _find_lock_target() -> Node3D:
	var best: Node3D = null
	var best_score := INF
	var max_d := float(Balance.camera().get("lock_on_distance", 18.0))
	if lock_sensor == null:
		return null
	for body in lock_sensor.get_overlapping_bodies():
		if body == self or not body.is_in_group("lockable"):
			continue
		if body.has_method("is_alive") and not body.is_alive():
			continue
		if "health" in body and float(body.health) <= 0.0:
			continue
		var to := body.global_position - global_position
		var d := to.length()
		if d > max_d or d < 0.01:
			continue
		var dir := to / d
		var front := facing.dot(dir)
		if front < -0.15:
			continue
		var score := d / maxf(0.25 + front, 0.2)
		if score < best_score:
			best_score = score
			best = body
	return best


func _try_auto_relock() -> void:
	var next := _find_lock_target()
	if next:
		lock_target = next
		if typeof(HitFeel) != TYPE_NIL:
			HitFeel.spark_at(next.global_position + Vector3.UP * 1.5, Color(0.55, 0.95, 1.0), 0.4)


func _toggle_lock_on() -> void:
	if lock_target and is_instance_valid(lock_target):
		lock_target = null
		GameState.show_toast("Lock off")
		return
	lock_target = _find_lock_target()
	if lock_target:
		GameState.show_toast("Lock on")
		HitFeel.spark_at(lock_target.global_position + Vector3.UP * 1.5, Color(0.55, 0.95, 1.0), 0.55)
		for cam in get_tree().get_nodes_in_group("player_camera"):
			if cam and cam.has_method("punch_fov"):
				cam.punch_fov(-3.0)
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


func _spawn_weapon_trail() -> void:
	var host := get_tree().current_scene
	if host == null or weapon_visual == null:
		return
	var p := MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = 0.07 if state == State.ATTACK_HEAVY else 0.055
	sm.height = sm.radius * 2.0
	p.mesh = sm
	var mat := StandardMaterial3D.new()
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	var col := Color(1.0, 0.55, 0.25, 0.6) if state == State.ATTACK_HEAVY else Color(1.0, 0.9, 0.45, 0.55)
	mat.albedo_color = col
	mat.emission_enabled = true
	mat.emission = Color(col.r, col.g, col.b)
	mat.emission_energy_multiplier = 1.8 if state == State.ATTACK_HEAVY else 1.5
	p.material_override = mat
	host.add_child(p)
	p.global_position = weapon_visual.global_position
	var tw := create_tween()
	tw.tween_property(mat, "albedo_color:a", 0.0, 0.18 if state == State.ATTACK_HEAVY else 0.16)
	tw.parallel().tween_property(p, "scale", Vector3.ONE * 0.2, 0.18 if state == State.ATTACK_HEAVY else 0.16)
	tw.tween_callback(p.queue_free)


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
