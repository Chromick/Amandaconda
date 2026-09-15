extends CharacterBody3D
## Base compartilhada de inimigo comum (vida, i-frames leves, popup, respawn).

signal health_changed(current: float, maximum: float)
signal died

const POPUP_SCENE := preload("res://scenes/damage_popup.tscn")
const CharacterVisualScript := preload("res://scripts/world/character_visual.gd")
const SceneUtil := preload("res://scripts/combat/scene_util.gd")

@export var balance_key: String = ""

var health: float = 10.0
var max_health: float = 10.0
var _flash_timer: float = 0.0
var _revive_timer: float = -1.0
var _dead: bool = false
var _spawn_pos: Vector3
var _cfg: Dictionary = {}

@onready var mesh: MeshInstance3D = $Mesh
@onready var label: Label3D = get_node_or_null("Label3D")

@export var visual_gltf: String = ""
@export var visual_scale: float = 1.0
@export var visual_tint: Color = Color(1, 1, 1, 1)

var _visual = null
var _overlay: StandardMaterial3D = null
var _aggroed: bool = false
var _arena: Node = null


func _ready() -> void:
	add_to_group("enemy")
	add_to_group("lockable")
	_spawn_pos = global_position
	Balance.reloaded.connect(_apply_balance)
	_attach_visual()
	_apply_balance()


func bind_arena(arena: Node) -> void:
	_arena = arena


func on_arena_engaged() -> void:
	## Bosses podem sobrescrever (ex.: Amanda acordar).
	_aggroed = true


func _wants_player_combat() -> Node3D:
	## null = patrulha / fica na sala; senão persegue o jogador.
	var player := _get_player()
	if player == null:
		return null
	if is_in_group("boss"):
		if _arena != null and is_instance_valid(_arena):
			if _arena.has_method("is_engaged") and _arena.is_engaged():
				return player
			return null
		# Fallback sem arena: só reage perto do spawn.
		var near := global_position.distance_to(player.global_position) <= float(_cfg.get("aggro", 8.0))
		return player if near or _aggroed else null
	_update_trash_aggro(player)
	return player if _aggroed else null


func _update_trash_aggro(player: Node3D) -> void:
	var flat_p := Vector3(player.global_position.x - global_position.x, 0.0, player.global_position.z - global_position.z)
	var flat_h := Vector3(_spawn_pos.x - global_position.x, 0.0, _spawn_pos.z - global_position.z)
	var dist_p := flat_p.length()
	var dist_h := flat_h.length()
	var aggro := float(_cfg.get("aggro", 10.0))
	var leash := float(_cfg.get("leash", 16.0))
	var deaggro := float(_cfg.get("deaggro", 22.0))
	if _aggroed:
		if dist_h > leash or dist_p > deaggro:
			_aggroed = false
	elif dist_p <= aggro:
		_aggroed = true


func _idle_or_home(delta: float, spd: float = 2.6) -> void:
	var to := _spawn_pos - global_position
	to.y = 0.0
	if to.length() < 0.4:
		velocity.x = move_toward(velocity.x, 0.0, 12.0 * delta)
		velocity.z = move_toward(velocity.z, 0.0, 12.0 * delta)
		return
	var dir := to.normalized()
	_face_flat(dir)
	var s := spd * move_scale()
	velocity.x = dir.x * s
	velocity.z = dir.z * s


func _face_flat(dir: Vector3) -> void:
	## look_at seguro no plano XZ (evita erro com dir ~0 ou paralelo a UP).
	dir.y = 0.0
	if dir.length_squared() < 0.0001:
		return
	look_at(global_position + dir.normalized(), Vector3.UP)


func _clamp_to_arena() -> void:
	if _arena == null or not is_instance_valid(_arena):
		return
	if _arena.has_method("clamp_xz"):
		global_position = _arena.clamp_xz(global_position)


func _attach_visual() -> void:
	if visual_gltf.is_empty():
		return
	_visual = CharacterVisualScript.attach(self, visual_gltf, {
		"scale": visual_scale,
		"hide_mesh": mesh,
		"yaw_deg": 180.0,
		"tint": visual_tint,
	})


func _visual_action() -> String:
	## Subclasses: retorne clip de ataque/estado; vazio = locomoção.
	return ""


func _update_visual() -> void:
	if _visual == null:
		return
	if _dead:
		_visual.play("Death")
		return
	var action := _visual_action()
	if not action.is_empty():
		_visual.play(action)
	else:
		var spd := Vector3(velocity.x, 0.0, velocity.z).length()
		_visual.play_locomotion(spd, 3.8)


func _apply_balance() -> void:
	_cfg = Balance.data.get(balance_key, {}) if not balance_key.is_empty() else {}
	var prev_max := max_health
	max_health = float(_cfg.get("vida", max_health))
	# Não cura no meio da luta quando o balance recarrega — só ajusta o teto.
	if _dead:
		pass
	elif health >= prev_max - 0.01 or prev_max <= 0.0:
		health = max_health
	else:
		health = minf(health, max_health)
	_update_label()
	health_changed.emit(health, max_health)
	_on_balance_applied()


func _on_balance_applied() -> void:
	pass


func _process(delta: float) -> void:
	if _flash_timer > 0.0:
		_flash_timer -= delta
		if _flash_timer <= 0.0 and not _dead:
			_restore_color()
	if _revive_timer >= 0.0:
		_revive_timer -= delta
		if _revive_timer <= 0.0:
			_revive()
	_update_visual()


func take_damage(amount: float, knockback: Vector3 = Vector3.ZERO, _source: Node = null) -> void:
	if _dead:
		return
	_aggroed = true
	if _arena != null and is_instance_valid(_arena) and _arena.has_method("try_start_fight"):
		_arena.try_start_fight()
	health = maxf(0.0, health - amount)
	health_changed.emit(health, max_health)
	_flash_timer = 0.12
	_set_color(Color(1.0, 0.25, 0.2))
	velocity += knockback
	_spawn_popup(amount)
	_update_label()
	if health <= 0.0:
		_die()


func _die() -> void:
	_dead = true
	died.emit()
	_drop_bytes()
	_set_color(Color(0.2, 0.2, 0.22))
	if label:
		label.text = "KO"
	visible = true
	# Desliga colisão enquanto morto.
	$CollisionShape3D.disabled = true
	var delay := float(_cfg.get("renascer_em", 0.0))
	if delay > 0.0:
		_revive_timer = delay
	else:
		queue_free()


func _drop_bytes(announce: bool = true) -> void:
	var rng: Variant = _cfg.get("bytes", null)
	if typeof(rng) != TYPE_ARRAY or rng.size() < 2:
		return
	var got := int(randi_range(int(rng[0]), int(rng[1])))
	if got <= 0:
		return
	GameState.add_bytes(got)
	if announce:
		GameState.show_toast("+%d KB" % got)
	if typeof(HitFeel) != TYPE_NIL:
		HitFeel.spark_at(global_position + Vector3.UP * 0.85, Color(0.95, 0.85, 0.35), 1.05)
		HitFeel.shake(0.08)


func _revive() -> void:
	_dead = false
	_revive_timer = -1.0
	_aggroed = false
	health = max_health
	global_position = _spawn_pos
	velocity = Vector3.ZERO
	$CollisionShape3D.disabled = false
	if _visual:
		_visual.reset_death()
	_restore_color()
	_update_label()
	health_changed.emit(health, max_health)


func is_alive() -> bool:
	return not _dead


func move_scale() -> float:
	if has_meta("ground_slow"):
		return float(get_meta("ground_slow"))
	return 1.0


func _get_player() -> Node3D:
	var p := get_tree().get_first_node_in_group("player")
	return p as Node3D


func _spawn_popup(amount: float) -> void:
	var pop := POPUP_SCENE.instantiate()
	pop.amount = amount
	if not SceneUtil.add_to_world(pop, self, global_position + Vector3(0, 1.6, 0)):
		return


func _update_label() -> void:
	if label:
		label.text = "%s %d/%d" % [balance_key.capitalize(), int(health), int(max_health)]


func _set_color(c: Color) -> void:
	if mesh and mesh.visible:
		var mat := mesh.material_override as StandardMaterial3D
		if mat == null:
			mat = StandardMaterial3D.new()
			mesh.material_override = mat
		mat.albedo_color = c
	if _visual:
		var flash := c.r > 0.9 and c.g > 0.9 and c.b > 0.85
		var hit := c.r > 0.7 and c.g < 0.5
		var windup := c.g > 0.85 and c.r > 0.85 and c.b < 0.6
		_visual.set_flash(flash or hit or windup, c)


func _restore_color() -> void:
	# Default: volta ao tint do visual / cor neutra do mesh.
	if _visual:
		_visual.set_flash(false, visual_tint)
		if visual_tint.r < 0.98 or visual_tint.g < 0.98 or visual_tint.b < 0.98:
			_visual.apply_tint(visual_tint)
	elif mesh and mesh.visible:
		var mat := mesh.material_override as StandardMaterial3D
		if mat:
			mat.albedo_color = visual_tint if visual_tint.a > 0.0 else Color(0.7, 0.7, 0.75)


func _apply_gravity(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= 20.0 * delta
