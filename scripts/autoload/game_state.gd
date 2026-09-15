extends Node
## Estado global da run / sessão.

signal bytes_changed(total: int)
signal heals_changed(current: int, maximum: int)
signal patches_changed
signal hacks_changed
signal abilities_changed
signal toast(message: String)
signal gates_changed
signal ending_reached

enum WeaponSchool { TECLADO, VIRUS }

const ABILITY_CARAMELO := "caramelo"
const ABILITY_ECO := "eco"
const ABILITY_ESPELHO := "espelho"

const BASE_BOSSES := ["luanevil", "renanligno", "balarrals"]

var school: WeaponSchool = WeaponSchool.TECLADO
var bosses_defeated: Array[String] = []
var paused: bool = false
var bytes: int = 0
var heals: int = 3
var max_heals: int = 3
var safezone_position: Vector3 = Vector3(0, 1, 22)
var in_safezone: bool = false

var fisico_level: int = 0
var especial_level: int = 0
var active_patches: Array[String] = []

var unlocked_abilities: Array[String] = []
var equipped_ability: String = ""

var controls_inverted: bool = false
var hud_lying: bool = false


func reset_run() -> void:
	bosses_defeated.clear()
	paused = false
	bytes = 0
	fisico_level = 0
	especial_level = 0
	active_patches.clear()
	unlocked_abilities.clear()
	equipped_ability = ""
	in_safezone = false
	clear_hacks()
	var cura: Dictionary = Balance.data.get("cura", {})
	max_heals = int(cura.get("latas", 3)) + bonus_max_heals()
	heals = max_heals
	bytes_changed.emit(bytes)
	heals_changed.emit(heals, max_heals)
	patches_changed.emit()
	abilities_changed.emit()
	gates_changed.emit()


func set_school(s: WeaponSchool) -> void:
	school = s


func weapon_id() -> String:
	return "virus" if school == WeaponSchool.VIRUS else "teclado"


func school_label() -> String:
	return "Especial · Vírus" if school == WeaponSchool.VIRUS else "Físico · Teclado"


func add_bytes(amount: int) -> void:
	var before := bytes
	bytes += maxi(amount, 0)
	bytes_changed.emit(bytes)
	for milestone in [100, 250, 500, 1000]:
		if before < milestone and bytes >= milestone:
			var msg := "%d KB · carteira engordou" % milestone
			get_tree().create_timer(0.85).timeout.connect(func ():
				show_toast(msg)
				var player := get_tree().get_first_node_in_group("player")
				if player and typeof(HitFeel) != TYPE_NIL:
					HitFeel.spark_at(player.global_position + Vector3.UP * 1.2, Color(0.95, 0.85, 0.35), 1.0)
					HitFeel.shake(0.1)
					HitFeel.kick_fov(3.0, 0.12)
			, CONNECT_ONE_SHOT)
			break


func spend_bytes(amount: int) -> bool:
	if bytes < amount:
		return false
	bytes -= amount
	bytes_changed.emit(bytes)
	return true


func try_consume_heal() -> bool:
	if heals <= 0:
		return false
	heals -= 1
	heals_changed.emit(heals, max_heals)
	return true


func refill_heals() -> void:
	heals = max_heals
	heals_changed.emit(heals, max_heals)


func add_pendrive(kind: String) -> void:
	if kind == "especial":
		especial_level += 1
	else:
		fisico_level += 1
	patches_changed.emit()


func damage_multiplier() -> float:
	var pend: Dictionary = Balance.data.get("pendrives", {})
	var fisico: Dictionary = pend.get("fisico", {})
	var especial: Dictionary = pend.get("especial", {})
	var mult := 1.0
	mult += float(fisico.get("dano_por_nivel", 0.08)) * fisico_level
	mult += float(especial.get("dano_por_nivel", 0.15)) * especial_level
	for pid in active_patches:
		var patch := _find_patch(pid)
		mult += float(patch.get("dano_mult", 0.0))
	return mult


func bonus_max_health() -> float:
	var pend: Dictionary = Balance.data.get("pendrives", {})
	var fisico: Dictionary = pend.get("fisico", {})
	var especial: Dictionary = pend.get("especial", {})
	var bonus := float(fisico.get("vida_por_nivel", 18)) * fisico_level
	bonus += float(especial.get("vida_por_nivel", 8)) * especial_level
	for pid in active_patches:
		var patch := _find_patch(pid)
		bonus += float(patch.get("vida_max", 0.0))
	return bonus


func bonus_max_stamina() -> float:
	var bonus := 0.0
	for pid in active_patches:
		var patch := _find_patch(pid)
		bonus += float(patch.get("vigor_max", 0.0))
	return bonus


func bonus_max_heals() -> int:
	var bonus := 0
	for pid in active_patches:
		var patch := _find_patch(pid)
		bonus += int(patch.get("latas_max", 0))
	return bonus


func refresh_heal_slots() -> void:
	var cura: Dictionary = Balance.data.get("cura", {})
	var base := int(cura.get("latas", 3))
	max_heals = base + bonus_max_heals()
	heals = mini(heals, max_heals)
	heals_changed.emit(heals, max_heals)


func _find_patch(pid: String) -> Dictionary:
	var catalog: Array = Balance.data.get("patches", {}).get("catalogo", [])
	for item in catalog:
		if typeof(item) == TYPE_DICTIONARY and str(item.get("id", "")) == pid:
			return item
	return {}


func buy_patch(pid: String) -> bool:
	if pid in active_patches:
		return false
	var patch := _find_patch(pid)
	if patch.is_empty():
		return false
	var slots := int(Balance.data.get("patches", {}).get("slots", 3))
	if active_patches.size() >= slots:
		return false
	if not spend_bytes(int(patch.get("custo", 0))):
		return false
	active_patches.append(pid)
	refresh_heal_slots()
	patches_changed.emit()
	return true


func ability_label(id: String = "") -> String:
	var key := id if not id.is_empty() else equipped_ability
	match key:
		ABILITY_CARAMELO:
			return "Caramelo"
		ABILITY_ECO:
			return "Eco"
		ABILITY_ESPELHO:
			return "Espelho"
		_:
			return "—"


func unlock_ability(ability_id: String, toast_msg: String = "") -> void:
	if ability_id.is_empty() or ability_id in unlocked_abilities:
		return
	unlocked_abilities.append(ability_id)
	if equipped_ability.is_empty():
		equipped_ability = ability_id
	abilities_changed.emit()
	if not toast_msg.is_empty():
		show_toast(toast_msg)
	else:
		show_toast("Habilidade desbloqueada: %s" % ability_label(ability_id))
	var player := get_tree().get_first_node_in_group("player")
	if player and typeof(HitFeel) != TYPE_NIL:
		HitFeel.spark_at(player.global_position + Vector3.UP * 1.3, Color(0.55, 1.0, 0.75), 1.2)
		HitFeel.shake(0.18)
		HitFeel.kick_fov(4.5, 0.16)
	var hud := get_tree().get_first_node_in_group("hud")
	if hud and hud.has_method("pulse_heal"):
		hud.pulse_heal()


func cycle_ability() -> void:
	if not in_safezone:
		show_toast("Equipe habilidades na safezone")
		return
	if unlocked_abilities.is_empty():
		show_toast("Nenhuma habilidade ainda")
		return
	var idx := unlocked_abilities.find(equipped_ability)
	idx = (idx + 1) % unlocked_abilities.size()
	equipped_ability = unlocked_abilities[idx]
	abilities_changed.emit()
	show_toast("Equipado: %s" % ability_label())
	var player := get_tree().get_first_node_in_group("player")
	if player and typeof(HitFeel) != TYPE_NIL:
		HitFeel.spark_at(player.global_position + Vector3.UP * 1.2, Color(0.55, 0.95, 1.0), 0.65)
		HitFeel.kick_fov(2.0, 0.1)


func set_controls_inverted(v: bool) -> void:
	controls_inverted = v
	hacks_changed.emit()


func set_hud_lying(v: bool) -> void:
	hud_lying = v
	hacks_changed.emit()


func clear_hacks() -> void:
	controls_inverted = false
	hud_lying = false
	hacks_changed.emit()


func base_bosses_cleared() -> int:
	var n := 0
	for b in BASE_BOSSES:
		if b in bosses_defeated:
			n += 1
	return n


func can_enter_servers() -> bool:
	return base_bosses_cleared() >= 3


func can_enter_door() -> bool:
	return "marlombolico" in bosses_defeated


func mark_boss_defeated(boss_id: String) -> void:
	if boss_id not in bosses_defeated:
		bosses_defeated.append(boss_id)
	match boss_id:
		"luanevil":
			unlock_ability(ABILITY_CARAMELO, "Roubou CARAMELO · chefes-base %d/3" % (base_bosses_cleared()))
		"renanligno":
			unlock_ability(ABILITY_ECO, "Roubou ECO · chefes-base %d/3" % (base_bosses_cleared()))
		"balarrals":
			unlock_ability(ABILITY_ESPELHO, "Roubou ESPELHO · chefes-base %d/3" % (base_bosses_cleared()))
		"marlombolico":
			clear_hacks()
			show_toast("Servidores limpos · caminho pra porta aberto")
		"amandaconda":
			show_toast("SESSION_CLOSED · você pode sair")
			ending_reached.emit()
	gates_changed.emit()
	if boss_id in BASE_BOSSES and base_bosses_cleared() >= 3:
		# Adia pra não sobrescrever o toast da habilidade no mesmo frame.
		get_tree().create_timer(1.4).timeout.connect(func ():
			show_toast("3/3 · portão dos servidores liberado")
			var player := get_tree().get_first_node_in_group("player")
			if player and typeof(HitFeel) != TYPE_NIL:
				HitFeel.spark_at(player.global_position + Vector3.UP * 1.2, Color(0.45, 1.0, 0.6), 1.15)
				HitFeel.shake(0.18)
		, CONNECT_ONE_SHOT)
	if boss_id == "marlombolico":
		get_tree().create_timer(0.9).timeout.connect(func ():
			var player := get_tree().get_first_node_in_group("player")
			if player and typeof(HitFeel) != TYPE_NIL:
				HitFeel.spark_at(player.global_position + Vector3.UP * 1.2, Color(0.35, 1.0, 0.5), 1.0)
		, CONNECT_ONE_SHOT)


func show_toast(message: String) -> void:
	toast.emit(message)


func start_run(s: WeaponSchool) -> void:
	reset_run()
	set_school(s)
	if typeof(HitFeel) != TYPE_NIL and HitFeel.has_method("cancel"):
		HitFeel.cancel()
	go_to_hub()


func go_to_hub() -> void:
	paused = false
	if typeof(HitFeel) != TYPE_NIL and HitFeel.has_method("cancel"):
		HitFeel.cancel()
	get_tree().change_scene_to_file("res://scenes/hub_arena.tscn")


func go_to_menu() -> void:
	paused = false
	clear_hacks()
	if typeof(HitFeel) != TYPE_NIL and HitFeel.has_method("cancel"):
		HitFeel.cancel()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
