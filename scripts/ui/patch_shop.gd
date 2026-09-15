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
		info.text = "%d KB · slots %d/%d · Fis%d Esp%d" % [
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
		btn.pressed.connect(_buy.bind(pid))
		list.add_child(btn)


func _buy(pid: String) -> void:
	if GameState.buy_patch(pid):
		var player := get_tree().get_first_node_in_group("player")
		if player and player.has_method("refresh_progression"):
			player.refresh_progression()
		GameState.show_toast("Patch instalado · %s" % _patch_name(pid))
		if typeof(HitFeel) != TYPE_NIL:
			HitFeel.shake(0.1)
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
