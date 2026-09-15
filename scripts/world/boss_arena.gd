extends Area3D
## Arena de chefe estilo Souls: entra → trava a porta; boss morto / você morre → abre.
class_name BossArena

var boss_id: String = ""
var _boss: Node = null
var _engaged: bool = false
var _center: Vector3 = Vector3.ZERO
var _half: Vector3 = Vector3.ONE
var _seals: Array[StaticBody3D] = []
var _fog_label: Label3D
var _seal_pulse: float = 0.0


func configure(
	center: Vector3,
	size: Vector3,
	boss: Node,
	id: String,
	door_gaps: Array
) -> void:
	boss_id = id
	_boss = boss
	_center = center
	_half = Vector3(size.x * 0.5, size.y * 0.5, size.z * 0.5)
	collision_layer = 0
	collision_mask = 2
	monitoring = true
	monitorable = false
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	# Volume interno um pouco menor que a sala.
	box.size = Vector3(maxf(size.x - 2.0, 4.0), maxf(size.y, 3.0), maxf(size.z - 2.0, 4.0))
	shape.shape = box
	add_child(shape)
	global_position = center + Vector3(0, size.y * 0.45, 0)

	for gap in door_gaps:
		_seals.append(_make_seal(gap.get("pos", center) as Vector3, gap.get("size", Vector3(3.5, 3.5, 0.5)) as Vector3))

	_fog_label = Label3D.new()
	_fog_label.text = ""
	_fog_label.font_size = 48
	_fog_label.modulate = Color(1.0, 0.45, 0.4)
	_fog_label.position = Vector3(0, 2.4, 0)
	add_child(_fog_label)

	body_entered.connect(_on_body_entered)
	if _boss and _boss.has_signal("died"):
		_boss.died.connect(_on_boss_died)
	if _boss and _boss.has_method("bind_arena"):
		_boss.bind_arena(self)
	call_deferred("_hook_player")


func is_engaged() -> bool:
	return _engaged


func _process(delta: float) -> void:
	if not _engaged:
		return
	_seal_pulse += delta
	var e := 2.0 + sin(_seal_pulse * 4.5) * 0.55
	for seal in _seals:
		if not is_instance_valid(seal) or not seal.visible:
			continue
		for c in seal.get_children():
			if c is MeshInstance3D:
				var mat := (c as MeshInstance3D).material_override as StandardMaterial3D
				if mat:
					mat.emission_energy_multiplier = e
				break
	if _fog_label and not _fog_label.text.is_empty():
		var a := 0.7 + 0.3 * absf(sin(_seal_pulse * 3.2))
		_fog_label.modulate = Color(1.0, 0.4 + 0.15 * a, 0.35, a)


func clamp_xz(pos: Vector3) -> Vector3:
	var m := 1.35
	pos.x = clampf(pos.x, _center.x - _half.x + m, _center.x + _half.x - m)
	pos.z = clampf(pos.z, _center.z - _half.z + m, _center.z + _half.z - m)
	return pos


func contains_xz(pos: Vector3) -> bool:
	return (
		absf(pos.x - _center.x) <= _half.x - 0.5
		and absf(pos.z - _center.z) <= _half.z - 0.5
	)


func try_start_fight() -> void:
	if _engaged:
		return
	if _boss == null or not is_instance_valid(_boss):
		return
	if _boss.has_method("is_alive") and not _boss.is_alive():
		return
	_engaged = true
	_set_seals(true)
	var title := _boss_title()
	_fog_label.text = "%s\nporta selada" % title
	if typeof(GameState) != TYPE_NIL:
		GameState.show_toast("%s · a névoa fecha" % title)
	# Flash vermelho breve na HUD
	var hud := get_tree().get_first_node_in_group("hud")
	if hud and hud.has_method("flash_danger"):
		hud.flash_danger()
	if typeof(HitFeel) != TYPE_NIL:
		HitFeel.shake(0.35)
		HitFeel.spark_at(global_position + Vector3.UP * 1.5, Color(0.95, 0.25, 0.35), 1.1)


func _boss_title() -> String:
	match boss_id:
		"luanevil":
			return "LUANEVIL · BANDEJÃO"
		"renanligno":
			return "RENANLIGNO · LAB"
		"balarrals":
			return "BALARRALS · PÁTIO"
		"marlombolico":
			return "MARLOMBÓLICO · SERVIDORES"
		"amandaconda":
			return "AMANDACONDA · A PORTA"
		_:
			return "CHEFE"


func end_fight() -> void:
	if not _engaged:
		_set_seals(false)
		return
	_engaged = false
	_dissolve_seals()
	_fog_label.text = ""


func _dissolve_seals() -> void:
	for seal in _seals:
		if not is_instance_valid(seal):
			continue
		var col := seal.get_node_or_null("CollisionShape3D") as CollisionShape3D
		if col:
			col.disabled = true
		var mesh := seal.get_node_or_null("MeshInstance3D") as MeshInstance3D
		if mesh == null:
			# First MeshInstance3D child
			for c in seal.get_children():
				if c is MeshInstance3D:
					mesh = c
					break
		var mat := mesh.material_override as StandardMaterial3D if mesh else null
		if mat == null:
			seal.visible = false
			continue
		var tw := create_tween()
		tw.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
		tw.tween_property(mat, "albedo_color:a", 0.0, 0.55)
		tw.parallel().tween_property(mat, "emission_energy_multiplier", 0.1, 0.55)
		tw.tween_callback(func():
			if is_instance_valid(seal):
				seal.visible = false
		)


func _hook_player() -> void:
	var p := get_tree().get_first_node_in_group("player")
	if p and p.has_signal("died") and not p.died.is_connected(_on_player_died):
		p.died.connect(_on_player_died)


func _on_body_entered(body: Node3D) -> void:
	if body == null or not body.is_in_group("player"):
		return
	try_start_fight()
	if _boss and _boss.has_method("on_arena_engaged"):
		_boss.on_arena_engaged()


func _on_boss_died() -> void:
	end_fight()
	_fog_label.text = "arena liberada"
	_fog_label.modulate = Color(0.45, 1.0, 0.6)
	if typeof(GameState) != TYPE_NIL:
		GameState.show_toast("%s · névoa dissipada" % _boss_title())
	if typeof(HitFeel) != TYPE_NIL:
		HitFeel.spark_at(global_position + Vector3.UP * 1.2, Color(0.55, 1.0, 0.65), 1.2)
		HitFeel.shake(0.2)
	for cam in get_tree().get_nodes_in_group("player_camera"):
		if cam and cam.has_method("punch_fov"):
			cam.punch_fov(5.0)
			break
	var hud := get_tree().get_first_node_in_group("hud")
	if hud and hud.has_method("pulse_heal"):
		hud.pulse_heal()


func _on_player_died() -> void:
	end_fight()
	if _fog_label:
		_fog_label.text = ""


func _set_seals(locked: bool) -> void:
	for seal in _seals:
		if not is_instance_valid(seal):
			continue
		seal.visible = locked
		var col := seal.get_node_or_null("CollisionShape3D") as CollisionShape3D
		if col:
			col.disabled = not locked
		if locked:
			for c in seal.get_children():
				if c is MeshInstance3D:
					var mat := (c as MeshInstance3D).material_override as StandardMaterial3D
					if mat:
						mat.albedo_color.a = 0.62
						mat.emission_energy_multiplier = 2.4
					break


func _make_seal(pos: Vector3, size: Vector3) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.collision_layer = 1
	body.collision_mask = 0
	var col := CollisionShape3D.new()
	col.name = "CollisionShape3D"
	var shape := BoxShape3D.new()
	shape.size = size
	col.shape = shape
	col.disabled = true
	body.add_child(col)
	var mesh := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = size
	mesh.mesh = bm
	var mat := StandardMaterial3D.new()
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.albedo_color = Color(0.55, 0.08, 0.12, 0.62)
	mat.emission_enabled = true
	mat.emission = Color(0.95, 0.15, 0.22)
	mat.emission_energy_multiplier = 2.4
	mesh.material_override = mat
	body.add_child(mesh)
	var lab := Label3D.new()
	lab.text = "NÉVOA DO CHEFE"
	lab.font_size = 40
	lab.position = Vector3(0, size.y * 0.35, 0)
	lab.modulate = Color(1.0, 0.55, 0.5)
	body.add_child(lab)
	body.visible = false
	# Parent to arena's parent (rooms) so transform is world-stable.
	var host := get_parent()
	if host:
		host.add_child(body)
	else:
		add_child(body)
	body.global_position = pos
	return body
