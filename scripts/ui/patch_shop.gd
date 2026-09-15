extends CanvasLayer
## UI do servidor de backup — compra patches.

@onready var panel: Control = $Panel
@onready var list: VBoxContainer = $Panel/Center/List
@onready var info: Label = $Panel/Center/Info


func _ready() -> void:
	visible = false
	process_mode = Node.PROCESS_MODE_ALWAYS
	GameState.bytes_changed.connect(_refresh)
	GameState.patches_changed.connect(_refresh)


func open_menu() -> void:
	visible = true
	get_tree().paused = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	if typeof(HitFeel) != TYPE_NIL and HitFeel.has_method("cancel"):
		HitFeel.cancel()
	_refresh()
	GameState.show_toast("Servidor de backup · escolha um patch")
	if panel:
		panel.modulate.a = 0.0
		panel.scale = Vector2(0.94, 0.94)
		var tw := create_tween()
		tw.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
		tw.set_parallel(true)
		tw.tween_property(panel, "modulate:a", 1.0, 0.2)
		tw.tween_property(panel, "scale", Vector2.ONE, 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func close_menu() -> void:
	visible = false
	get_tree().paused = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed("ui_cancel") or event.is_action_pressed("pause"):
		close_menu()
		get_viewport().set_input_as_handled()


func _refresh(_a: Variant = null) -> void:
	if info:
		info.text = "%d KB · slots %d/%d · Fis%d Esp%d · Esc fecha" % [
			GameState.bytes,
			GameState.active_patches.size(),
			int(Balance.data.get("patches", {}).get("slots", 3)),
			GameState.fisico_level,
			GameState.especial_level,
		]
	for c in list.get_children():
		c.queue_free()
	var catalog: Array = Balance.data.get("patches", {}).get("catalogo", [])
	var slots := int(Balance.data.get("patches", {}).get("slots", 3))
	var full := GameState.active_patches.size() >= slots
	for item in catalog:
		if typeof(item) != TYPE_DICTIONARY:
			continue
		var pid := str(item.get("id", ""))
		var btn := Button.new()
		var owned := pid in GameState.active_patches
		var cost := int(item.get("custo", 0))
		var can_afford := GameState.bytes >= cost
		btn.text = "%s — %s (%d KB)%s" % [
			str(item.get("nome", pid)),
			str(item.get("texto", "")),
			cost,
			" ✓" if owned else "",
		]
		btn.disabled = owned or not can_afford or full
		if full and not owned:
			btn.tooltip_text = "Slots cheios"
		elif not can_afford and not owned:
			btn.tooltip_text = "KB insuficiente"
		btn.add_theme_color_override("font_hover_color", Color(0.55, 1.0, 0.7))
		if owned:
			btn.add_theme_color_override("font_color", Color(0.55, 1.0, 0.7))
		elif not can_afford:
			btn.add_theme_color_override("font_color", Color(0.75, 0.45, 0.45))
		elif full:
			btn.add_theme_color_override("font_color", Color(0.7, 0.7, 0.55))
		else:
			btn.add_theme_color_override("font_color", Color(0.9, 0.95, 0.92))
		btn.pressed.connect(_buy.bind(pid))
		btn.mouse_entered.connect(_on_btn_hover.bind(btn))
		btn.mouse_exited.connect(_on_btn_unhover.bind(btn))
		list.add_child(btn)


func _on_btn_hover(btn: Button) -> void:
	if btn == null or not is_instance_valid(btn) or btn.disabled:
		return
	var tw := create_tween()
	tw.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tw.tween_property(btn, "scale", Vector2(1.03, 1.03), 0.1).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)


func _on_btn_unhover(btn: Button) -> void:
	if btn == null or not is_instance_valid(btn):
		return
	var tw := create_tween()
	tw.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tw.tween_property(btn, "scale", Vector2.ONE, 0.08)


func _buy(pid: String) -> void:
	if GameState.buy_patch(pid):
		var player := get_tree().get_first_node_in_group("player")
		if player and player.has_method("refresh_progression"):
			player.refresh_progression()
		GameState.show_toast("Patch instalado · %s" % _patch_name(pid))
		if typeof(HitFeel) != TYPE_NIL:
			HitFeel.shake(0.12)
			HitFeel.kick_fov(3.5, 0.12)
			if player and is_instance_valid(player):
				HitFeel.spark_at(player.global_position + Vector3.UP * 1.2, Color(0.55, 1.0, 0.7), 1.05)
		if panel:
			var flash := create_tween()
			flash.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
			flash.tween_property(panel, "modulate", Color(0.75, 1.0, 0.85), 0.06)
			flash.tween_property(panel, "modulate", Color.WHITE, 0.18)
		_refresh()
	else:
		GameState.show_toast("Não foi possível comprar")


func _patch_name(pid: String) -> String:
	var catalog: Array = Balance.data.get("patches", {}).get("catalogo", [])
	for item in catalog:
		if typeof(item) == TYPE_DICTIONARY and str(item.get("id", "")) == pid:
			return str(item.get("nome", pid))
	return pid


func _on_close_pressed() -> void:
	close_menu()
