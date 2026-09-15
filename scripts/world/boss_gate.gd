extends StaticBody3D
## Portão que abre quando a condição do campus é cumprida.

@export var gate_id: String = "servers" # servers | door
@export var title: String = "PORTÃO"

@onready var label: Label3D = $Label3D
@onready var mesh: MeshInstance3D = $Mesh
@onready var col: CollisionShape3D = $CollisionShape3D
var _open_light: OmniLight3D


func _ready() -> void:
	add_to_group("boss_gate")
	GameState.gates_changed.connect(_refresh)
	_open_light = OmniLight3D.new()
	_open_light.light_color = Color(0.45, 1.0, 0.65)
	_open_light.light_energy = 0.0
	_open_light.omni_range = 5.0
	_open_light.position = Vector3(0, 2.0, 0)
	add_child(_open_light)
	_refresh()


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
	# Mantém o label visível mesmo aberto, sumido o bloqueio.
	if open:
		label.modulate = Color(0.5, 1.0, 0.6)
		label.text = label.text.split("\n")[0] + "\npassagem livre"
		if _open_light:
			_open_light.light_energy = 2.2
		if not was_open:
			GameState.show_toast("%s · liberado" % (label.text.split("\n")[0]))
			if typeof(HitFeel) != TYPE_NIL:
				HitFeel.spark_at(global_position + Vector3.UP * 1.5, Color(0.45, 1.0, 0.6), 1.2)
				HitFeel.shake(0.15)
			_fade_mesh_out()
		else:
			mesh.visible = false
	else:
		mesh.visible = true
		if _open_light:
			_open_light.light_energy = 0.0
		var progress := 0.0
		if gate_id == "servers":
			progress = float(GameState.base_bosses_cleared()) / 3.0
		label.modulate = Color(1.0, 0.55, 0.45).lerp(Color(1.0, 0.85, 0.4), progress)
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
	tw.tween_property(mat, "albedo_color:a", 0.0, 0.55)
	tw.tween_callback(func():
		if is_instance_valid(mesh):
			mesh.visible = false
	)
