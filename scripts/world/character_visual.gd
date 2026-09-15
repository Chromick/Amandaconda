extends RefCounted
class_name CharacterVisual
## Anexa um glTF Quaternius a um CharacterBody3D e controla AnimationPlayer.

var root: Node3D = null
var anim: AnimationPlayer = null
var meshes: Array[MeshInstance3D] = []
var _overlay: StandardMaterial3D = null
var _current: String = ""
var _death_locked: bool = false
var _tint: Color = Color.WHITE


static func attach(
	host: Node3D,
	file_name: String,
	opts: Dictionary = {}
) -> CharacterVisual:
	var packed := PropLibrary.character(file_name)
	if packed == null:
		return null
	var inst := packed.instantiate() as Node3D
	if inst == null:
		return null
	var cv := CharacterVisual.new()
	cv.root = inst
	inst.name = str(opts.get("node_name", "CharacterVisual"))
	var sc := float(opts.get("scale", 1.0))
	inst.scale = Vector3.ONE * sc
	inst.position = opts.get("position", Vector3.ZERO) as Vector3
	inst.rotation_degrees.y = float(opts.get("yaw_deg", 180.0))
	host.add_child(inst)
	cv.anim = cv._find_anim_player(inst)
	cv._collect_meshes(inst, cv.meshes)
	var hide_mesh: MeshInstance3D = opts.get("hide_mesh", null) as MeshInstance3D
	if hide_mesh:
		hide_mesh.visible = false
	if cv.anim:
		cv.anim.active = true
		cv.play("Idle", true)
	var tint: Color = opts.get("tint", Color.WHITE)
	if tint.r < 0.98 or tint.g < 0.98 or tint.b < 0.98:
		cv.apply_tint(tint)
	return cv


func apply_tint(c: Color) -> void:
	## Recolor leve (bosses) sem destruir textura base.
	_tint = c
	if _overlay == null:
		_overlay = StandardMaterial3D.new()
		_overlay.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		_overlay.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_overlay.albedo_color = Color(c.r, c.g, c.b, 0.28)
	for mi in meshes:
		mi.material_overlay = _overlay


func play(clip: String, force: bool = false) -> bool:
	if anim == null or clip.is_empty():
		return false
	if _death_locked:
		return clip == "Death"
	if not force and _current == clip and anim.is_playing():
		return true
	var resolved := _resolve_clip(clip)
	if resolved.is_empty():
		return false
	anim.play(resolved)
	_current = clip
	if clip == "Death":
		_death_locked = true
	return true


func play_locomotion(horizontal_speed: float, run_threshold: float = 4.2) -> void:
	if _death_locked:
		return
	if horizontal_speed < 0.35:
		play("Idle")
	elif horizontal_speed < run_threshold:
		play("Walk")
	else:
		play("Run")


func set_flash(active: bool, color: Color = Color(1.0, 0.3, 0.25)) -> void:
	if active:
		if _overlay == null:
			_overlay = StandardMaterial3D.new()
			_overlay.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			_overlay.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		_overlay.albedo_color = Color(color.r, color.g, color.b, 0.45)
		_overlay.emission_enabled = true
		_overlay.emission = color
		_overlay.emission_energy_multiplier = 2.4
		for mi in meshes:
			mi.material_overlay = _overlay
	else:
		if _overlay:
			_overlay.emission_enabled = false
			_overlay.emission_energy_multiplier = 1.0
		if _tint.r < 0.98 or _tint.g < 0.98 or _tint.b < 0.98:
			apply_tint(_tint)
		else:
			for mi in meshes:
				mi.material_overlay = null


func reset_death() -> void:
	_death_locked = false
	_current = ""
	play("Idle", true)


func _resolve_clip(clip: String) -> String:
	# Aliases Quaternius + Mixamo-style
	var aliases := {
		"Idle": ["Idle", "idle", "Idle_Normal", "Breathing Idle"],
		"Walk": ["Walk", "walk", "Walking", "WalkForward"],
		"Run": ["Run", "run", "Running", "Sprint"],
		"Jump": ["Jump", "jump", "Jumping"],
		"Death": ["Death", "death", "Dying", "Die"],
		"HitReact": ["HitReact", "Hit", "hit", "Impact", "Reaction"],
		"Punch": ["Punch", "Attack", "attack", "Punching", "Melee"],
		"Slash": ["Slash", "SwordSlash", "Attack1", "Swing"],
		"Stab": ["Stab", "Attack2", "Thrust"],
		"Duck": ["Duck", "Roll", "Dodge", "Crouch"],
		"Idle_Attack": ["Idle_Attack", "CombatIdle", "Idle Fighting"],
	}
	var candidates: Array = aliases.get(clip, [clip])
	if clip not in candidates:
		candidates.insert(0, clip)
	for cand in candidates:
		if anim.has_animation(cand):
			return cand
		for lib in anim.get_animation_library_list():
			var path := "%s/%s" % [lib, cand]
			if anim.has_animation(path):
				return path
	# Fuzzy
	for aname in anim.get_animation_list():
		var leaf := String(aname).get_file().to_lower()
		if leaf == clip.to_lower() or clip.to_lower() in leaf:
			return aname
	return ""


func _find_anim_player(n: Node) -> AnimationPlayer:
	if n is AnimationPlayer:
		return n as AnimationPlayer
	for c in n.get_children():
		var found := _find_anim_player(c)
		if found:
			return found
	return null


func _collect_meshes(n: Node, out: Array[MeshInstance3D]) -> void:
	if n is MeshInstance3D:
		out.append(n as MeshInstance3D)
	for c in n.get_children():
		_collect_meshes(c, out)
