extends Node
## Carrega e expõe data/balance.json. F5 recarrega em runtime.

const PATH := "res://data/balance.json"

var data: Dictionary = {}

signal reloaded


func _ready() -> void:
	reload()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("reload_balance"):
		reload()
		get_viewport().set_input_as_handled()


func reload() -> void:
	if not FileAccess.file_exists(PATH):
		push_error("Balance: arquivo não encontrado: %s" % PATH)
		data = {}
		return
	var raw := FileAccess.get_file_as_string(PATH)
	var parsed: Variant = JSON.parse_string(raw)
	if typeof(parsed) != TYPE_DICTIONARY:
		push_error("Balance: JSON inválido em %s" % PATH)
		return
	data = parsed
	reloaded.emit()
	print("Balance: recarregado (%s)" % PATH)
	if typeof(GameState) != TYPE_NIL and GameState.has_method("show_toast"):
		GameState.show_toast("Balance F5 · recarregado")


func player() -> Dictionary:
	return data.get("player", {})


func camera() -> Dictionary:
	return data.get("camera", {})


func arma(nome: String = "") -> Dictionary:
	var p := player()
	var armas: Dictionary = p.get("armas", {})
	var key := nome if not nome.is_empty() else str(p.get("arma_inicial", "teclado"))
	return armas.get(key, {})


func get_path_value(path: String, default: Variant = null) -> Variant:
	var cur: Variant = data
	for part in path.split("."):
		if typeof(cur) != TYPE_DICTIONARY or not cur.has(part):
			return default
		cur = cur[part]
	return cur
