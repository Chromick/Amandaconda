extends Node3D
## Hub campus — HUD + builder + shop.

@onready var builder: Node3D = $CampusBuilder
@onready var patch_shop = $PatchShop


func _ready() -> void:
	var hud := $UI/HUD
	var player := $Player
	if player:
		player.global_position = Vector3(0, 1, 26)
	if hud and player and hud.has_method("bind_player"):
		hud.bind_player(player)
	GameState.safezone_position = Vector3(0, 1, 22)
	# Liga terminal(s) ao shop.
	await get_tree().process_frame
	for t in get_tree().get_nodes_in_group("patch_terminal"):
		if t.has_signal("opened"):
			t.opened.connect(_on_terminal_opened)
	# Terminal ainda não está no grupo — conecta pelo sinal depois do builder.
	_connect_terminals()


func _connect_terminals() -> void:
	if builder == null:
		return
	for child in builder.get_node("Spawns").get_children():
		if child.has_signal("opened"):
			if not child.opened.is_connected(_on_terminal_opened):
				child.opened.connect(_on_terminal_opened)


func _on_terminal_opened() -> void:
	if patch_shop and patch_shop.has_method("open_menu"):
		patch_shop.open_menu()
