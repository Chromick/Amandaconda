extends CanvasLayer
## Pause overlay no hub.

@onready var center: VBoxContainer = $Center


func _ready() -> void:
	visible = false
	process_mode = Node.PROCESS_MODE_ALWAYS
	if center:
		center.offset_left = -200.0
		center.offset_right = 200.0
		center.offset_top = -110.0
		center.offset_bottom = 110.0
	_ensure_controls_hint()


func _ensure_controls_hint() -> void:
	if center == null:
		return
	if center.get_node_or_null("ControlsHint") != null:
		return
	var hint := Label.new()
	hint.name = "ControlsHint"
	hint.text = "Ctrl/C rola · Shift corre · Q/MMB lock · R lata · F skill · E patches · Esc fecha"
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hint.add_theme_font_size_override("font_size", 14)
	hint.add_theme_color_override("font_color", Color(0.75, 0.85, 0.8))
	var title := center.get_node_or_null("Title")
	var idx := 1 if title else 0
	center.add_child(hint)
	center.move_child(hint, idx)
	var ver := Label.new()
	ver.name = "VersionHint"
	ver.text = "v%s · godot-4" % str(ProjectSettings.get_setting("application/config/version", "0.4"))
	ver.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ver.add_theme_font_size_override("font_size", 12)
	ver.add_theme_color_override("font_color", Color(0.55, 0.65, 0.6))
	center.add_child(ver)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		_toggle()
		get_viewport().set_input_as_handled()


func _toggle() -> void:
	visible = not visible
	get_tree().paused = visible
	GameState.paused = visible
	# Hitstop não pode deixar o jogo em 0.12x ao pausar/despausar.
	if typeof(HitFeel) != TYPE_NIL and HitFeel.has_method("cancel"):
		HitFeel.cancel()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE if visible else Input.MOUSE_MODE_CAPTURED
	if visible and center:
		var ver := center.get_node_or_null("VersionHint") as Label
		if ver:
			ver.text = "v%s · godot-4" % str(ProjectSettings.get_setting("application/config/version", "0.4"))
		center.modulate.a = 0.0
		center.scale = Vector2(0.94, 0.94)
		var tw := create_tween()
		tw.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
		tw.set_parallel(true)
		tw.tween_property(center, "modulate:a", 1.0, 0.18)
		tw.tween_property(center, "scale", Vector2.ONE, 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _on_resume_pressed() -> void:
	if visible:
		_toggle()


func _on_menu_pressed() -> void:
	get_tree().paused = false
	GameState.paused = false
	if typeof(HitFeel) != TYPE_NIL and HitFeel.has_method("cancel"):
		HitFeel.cancel()
	GameState.go_to_menu()
