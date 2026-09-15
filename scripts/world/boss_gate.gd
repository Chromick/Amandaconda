extends StaticBody3D
## Portão que abre quando a condição do campus é cumprida.

@export var gate_id: String = "servers" # servers | door
@export var title: String = "PORTÃO"

@onready var label: Label3D = $Label3D
@onready var mesh: MeshInstance3D = $Mesh
@onready var col: CollisionShape3D = $CollisionShape3D


func _ready() -> void:
	add_to_group("boss_gate")
	GameState.gates_changed.connect(_refresh)
	_refresh()


func _refresh() -> void:
	var was_open := col.disabled
	var open := false
	match gate_id:
		"servers":
			open = GameState.can_enter_servers()
			label.text = "SERVIDORES\n%s" % ("ABERTO" if open else "precisa 3 chefes-base")
		"door":
			open = GameState.can_enter_door()
			label.text = "A PORTA\n%s" % ("ABERTA" if open else "derrote o Marlombólico")
		_:
			label.text = title
	col.disabled = open
	mesh.visible = not open
	# Mantém o label visível mesmo aberto, sumido o bloqueio.
	if open:
		label.modulate = Color(0.5, 1.0, 0.6)
		label.text = label.text.split("\n")[0] + "\npassagem livre"
		if not was_open:
			GameState.show_toast("%s · liberado" % (label.text.split("\n")[0]))
			if typeof(HitFeel) != TYPE_NIL:
				HitFeel.spark_at(global_position + Vector3.UP * 1.5, Color(0.45, 1.0, 0.6), 1.2)
				HitFeel.shake(0.15)
	else:
		label.modulate = Color(1.0, 0.55, 0.45)
