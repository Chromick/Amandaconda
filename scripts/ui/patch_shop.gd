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
	_refresh()


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
	for item in catalog:
		if typeof(item) != TYPE_DICTIONARY:
			continue
		var pid := str(item.get("id", ""))
		var btn := Button.new()
		var owned := pid in GameState.active_patches
		btn.text = "%s — %s (%d KB)%s" % [
			str(item.get("nome", pid)),
			str(item.get("texto", "")),
			int(item.get("custo", 0)),
			" ✓" if owned else "",
		]
		btn.disabled = owned or GameState.bytes < int(item.get("custo", 0))
		btn.pressed.connect(_buy.bind(pid))
		list.add_child(btn)


func _buy(pid: String) -> void:
	if GameState.buy_patch(pid):
		var player := get_tree().get_first_node_in_group("player")
		if player and player.has_method("refresh_progression"):
			player.refresh_progression()
		_refresh()


func _on_close_pressed() -> void:
	close_menu()
