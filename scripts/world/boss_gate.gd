extends StaticBody3D
## Portão que abre quando a condição do campus é cumprida.

@export var gate_id: String = "servers" # servers | door
@export var title: String = "PORTÃO"

@onready var label: Label3D = $Label3D
@onready var mesh: MeshInstance3D = $Mesh
@onready var col: CollisionShape3D = $CollisionShape3D
var _open_light: OmniLight3D
var _progress: float = 0.0
var _is_open: bool = false


func _ready() -> void:
	add_to_group("boss_gate")
	GameState.gates_changed.connect(_refresh)
	if label:
		label.outline_size = 8
		label.outline_modulate = Color(0, 0, 0, 0.85)
	_open_light = OmniLight3D.new()
	_open_light.light_color = Color(0.45, 1.0, 0.65)
	_open_light.light_energy = 0.0
	_open_light.omni_range = 5.0
	_open_light.position = Vector3(0, 2.0, 0)
	add_child(_open_light)
	_refresh()


func _process(_delta: float) -> void:
	if _open_light == null or _is_open:
		return
	if _progress <= 0.0:
		_open_light.light_energy = 0.0
		return
	var pulse := 0.55 + 0.45 * absf(sin(Time.get_ticks_msec() * 0.004))
	_open_light.light_color = Color(1.0, 0.7, 0.35).lerp(Color(0.55, 1.0, 0.6), _progress)
	_open_light.light_energy = (0.35 + _progress * 1.4) * pulse


func _refresh() -> void:
	var was_open := col.disabled
	var open := false
	match gate_id:
		"servers":
			open = GameState.can_enter_servers()
			var n := GameState.base_bosses_cleared()
			label.text = "SERVIDORES\n%s" % ("ABERTO" if open else "precisa 3 chefes-base (%d/3)" % n)
		"door":
			open = GameState.can_enter_door()
			label.text = "A PORTA\n%s" % ("ABERTA" if open else "derrote o Marlombólico")
		_:
			label.text = title
	col.disabled = open
	_is_open = open
	# Mantém o label visível mesmo aberto, sumido o bloqueio.
	if open:
		label.modulate = Color(0.5, 1.0, 0.6)
		label.text = label.text.split("\n")[0] + "\npassagem livre"
		if _open_light:
			_open_light.light_color = Color(0.45, 1.0, 0.65)
			_open_light.light_energy = 2.2
		if not was_open:
			GameState.show_toast("%s · liberado" % (label.text.split("\n")[0]))
			if typeof(HitFeel) != TYPE_NIL:
				HitFeel.spark_at(global_position + Vector3.UP * 1.5, Color(0.45, 1.0, 0.6), 1.2)
				HitFeel.shake(0.15)
				HitFeel.kick_fov(4.0, 0.18)
			_fade_mesh_out()
		else:
			mesh.visible = false
	else:
		mesh.visible = true
		_progress = 0.0
		if gate_id == "servers":
			_progress = float(GameState.base_bosses_cleared()) / 3.0
		elif gate_id == "door":
			_progress = 1.0 if GameState.can_enter_door() else 0.0
		if _open_light and _progress <= 0.0:
			_open_light.light_energy = 0.0
		label.modulate = Color(1.0, 0.55, 0.45).lerp(Color(1.0, 0.85, 0.4), _progress)
		if mesh and mesh.material_override is StandardMaterial3D:
			(mesh.material_override as StandardMaterial3D).albedo_color.a = 1.0


func _fade_mesh_out() -> void:
	if mesh == null:
		return
	mesh.visible = true
	var mat := mesh.material_override as StandardMaterial3D
	if mat == null:
		mat = StandardMaterial3D.new()
		mat.albedo_color = Color(0.4, 0.4, 0.45, 1.0)
		mesh.material_override = mat
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.albedo_color.a = 1.0
	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(mat, "albedo_color:a", 0.0, 0.55)
	tw.tween_property(mesh, "scale", Vector3(1.05, 0.05, 1.05), 0.55)
	tw.chain().tween_callback(func():
		if is_instance_valid(mesh):
			mesh.visible = false
			mesh.scale = Vector3.ONE
	)
