extends Control
## HUD — vida, vigor, escola, latas, Bytes, habilidade, toast, boss bar, fade.

@onready var health_bar: ProgressBar = $Margin/VBox/HealthBar
@onready var stamina_bar: ProgressBar = $Margin/VBox/StaminaBar
@onready var weapon_label: Label = $Margin/VBox/WeaponLabel
@onready var meta_label: Label = $Margin/VBox/MetaLabel
@onready var ability_label: Label = get_node_or_null("Margin/VBox/AbilityLabel")
@onready var hint_label: Label = $HintLabel
@onready var hack_label: Label = get_node_or_null("HackLabel")
@onready var toast_label: Label = get_node_or_null("ToastLabel")
@onready var boss_panel: Control = get_node_or_null("BossPanel")
@onready var boss_name: Label = get_node_or_null("BossPanel/BossName")
@onready var boss_bar: ProgressBar = get_node_or_null("BossPanel/BossBar")

const HINTS: PackedStringArray = [
	"WASD move · mouse olha · Ctrl/C rola · Shift corre (gasta vigor) · LMB ataca",
	"Q ou MMB trava alvo · R bebe lata · F habilidade · T na safe",
	"Escola (Teclado/Vírus) escolhida no menu · patches no servidor",
	"Safezone restaura latas · chefs ficam nas salas",
	"Entre na névoa · a porta fecha até o fim",
]

var _player: Node = null
var _real_hp: float = 100.0
var _real_max: float = 100.0
var _toast_timer: float = 0.0
var _fade: ColorRect
var _flash: ColorRect
var _vignette: ColorRect
var _heal_pulse: float = 0.0
var _stamina_flash: float = 0.0
var _meta_flash: float = 0.0
var _hint_timer: float = 0.0
var _hint_index: int = 0
var _ability_was_cd: bool = false


func _ready() -> void:
	add_to_group("hud")
	GameState.bytes_changed.connect(_on_bytes)
	GameState.heals_changed.connect(_on_heals)
	GameState.hacks_changed.connect(_on_hacks)
	GameState.patches_changed.connect(_refresh_meta)
	GameState.abilities_changed.connect(_refresh_ability)
	GameState.toast.connect(_show_toast)
	GameState.ending_reached.connect(_on_ending)
	if GameState.has_signal("gates_changed"):
		GameState.gates_changed.connect(_on_gates)
	if boss_panel:
		boss_panel.visible = false
	if toast_label:
		toast_label.visible = false
	_style_for_night()
	_ensure_fade()
	_ensure_flash()
	_ensure_vignette()
	_refresh_meta()
	_refresh_ability()
	_on_hacks()
	_rotate_hint(true)
	call_deferred("_welcome")


func _process(delta: float) -> void:
	if _toast_timer > 0.0:
		_toast_timer -= delta
		if toast_label:
			if _toast_timer < 0.45:
				toast_label.modulate.a = clampf(_toast_timer / 0.45, 0.0, 1.0)
			else:
				toast_label.modulate.a = 1.0
		if _toast_timer <= 0.0 and toast_label:
			toast_label.visible = false
			toast_label.modulate.a = 1.0
	if _heal_pulse > 0.0:
		_heal_pulse -= delta
		var t := clampf(_heal_pulse / 0.45, 0.0, 1.0)
		health_bar.modulate = Color(0.55, 1.0, 0.65).lerp(Color.WHITE, 1.0 - t)
		if _heal_pulse <= 0.0:
			health_bar.modulate = Color.WHITE
	if _stamina_flash > 0.0:
		_stamina_flash -= delta
		var s := clampf(_stamina_flash / 0.35, 0.0, 1.0)
		stamina_bar.modulate = Color(1.0, 0.35, 0.25).lerp(Color.WHITE, 1.0 - s)
		if _stamina_flash <= 0.0:
			stamina_bar.modulate = Color.WHITE
	if _meta_flash > 0.0 and meta_label:
		_meta_flash -= delta
		var m := clampf(_meta_flash / 0.4, 0.0, 1.0)
		meta_label.modulate = Color(1.0, 0.92, 0.45).lerp(Color.WHITE, 1.0 - m)
		if _meta_flash <= 0.0:
			meta_label.modulate = Color.WHITE
	# Vida crítica: pulso vermelho na barra + vinheta
	if health_bar and _heal_pulse <= 0.0 and _real_max > 0.0 and _real_hp / _real_max < 0.3 and _real_hp > 0.0:
		var pulse := 0.55 + 0.45 * sin(Time.get_ticks_msec() * 0.008)
		health_bar.modulate = Color(1.0, pulse * 0.45, pulse * 0.4)
		if _vignette:
			var ratio := clampf(1.0 - (_real_hp / (_real_max * 0.3)), 0.0, 1.0)
			_vignette.color = Color(0.55, 0.05, 0.08, 1.0)
			_vignette.color.a = (0.08 + 0.14 * pulse) * (0.45 + 0.55 * ratio)
	elif _player and is_instance_valid(_player) and _player.has_method("is_marked") and _player.is_marked():
		if health_bar and _heal_pulse <= 0.0:
			health_bar.modulate = Color.WHITE
		if _vignette:
			var mp := 0.6 + 0.4 * sin(Time.get_ticks_msec() * 0.009)
			_vignette.color = Color(0.45, 0.15, 0.7, (0.06 + 0.08 * mp))
	elif health_bar and _heal_pulse <= 0.0:
		health_bar.modulate = Color.WHITE
		if _vignette:
			_vignette.color.a = lerpf(_vignette.color.a, 0.0, clampf(6.0 * delta, 0.0, 1.0))
	_hint_timer -= delta
	if _hint_timer <= 0.0:
		_rotate_hint(false)
	_update_status_bits()
	_update_boss_bar()
	_refresh_ability()


func _update_status_bits() -> void:
	if hack_label == null:
		return
	var bits: PackedStringArray = []
	if GameState.controls_inverted:
		bits.append("CTRL_INVERT")
	if GameState.hud_lying:
		bits.append("HUD_LIE")
	if _player and is_instance_valid(_player) and _player.has_method("is_marked") and _player.is_marked():
		var rem := 0.0
		if _player.has_method("mark_remaining"):
			rem = float(_player.mark_remaining())
		bits.append("MARCADO %.1fs" % rem)
	hack_label.visible = bits.size() > 0
	if bits.size() > 0:
		hack_label.text = " · ".join(bits)
		var marked := false
		for b in bits:
			if str(b).begins_with("MARCADO"):
				marked = true
				break
		hack_label.modulate = Color(0.85, 0.45, 1.0) if marked else Color(0.45, 1.0, 0.55)


func _style_for_night() -> void:
	for lab in [weapon_label, meta_label, ability_label, hint_label, hack_label, toast_label, boss_name]:
		if lab == null:
			continue
		lab.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
		lab.add_theme_constant_override("outline_size", 8)
	_style_bar(health_bar, Color(0.75, 0.18, 0.22), Color(0.08, 0.08, 0.1, 0.85))
	_style_bar(stamina_bar, Color(0.85, 0.75, 0.25), Color(0.08, 0.08, 0.1, 0.85))
	if boss_bar:
		_style_bar(boss_bar, Color(0.85, 0.2, 0.35), Color(0.05, 0.05, 0.08, 0.9))


func _style_bar(bar: ProgressBar, fill: Color, bg: Color) -> void:
	if bar == null:
		return
	var bg_box := StyleBoxFlat.new()
	bg_box.bg_color = bg
	bg_box.set_corner_radius_all(4)
	bg_box.content_margin_left = 2
	bg_box.content_margin_right = 2
	bg_box.content_margin_top = 2
	bg_box.content_margin_bottom = 2
	var fill_box := StyleBoxFlat.new()
	fill_box.bg_color = fill
	fill_box.set_corner_radius_all(3)
	bar.add_theme_stylebox_override("background", bg_box)
	bar.add_theme_stylebox_override("fill", fill_box)


func _ensure_fade() -> void:
	_fade = ColorRect.new()
	_fade.name = "DeathFade"
	_fade.color = Color(0, 0, 0, 0)
	_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fade.set_anchors_preset(Control.PRESET_FULL_RECT)
	_fade.z_index = 80
	add_child(_fade)


func _ensure_flash() -> void:
	_flash = ColorRect.new()
	_flash.name = "ScreenFlash"
	_flash.color = Color(1, 1, 1, 0)
	_flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_flash.set_anchors_preset(Control.PRESET_FULL_RECT)
	_flash.z_index = 70
	add_child(_flash)


func _ensure_vignette() -> void:
	_vignette = ColorRect.new()
	_vignette.name = "LowHpVignette"
	_vignette.color = Color(0.55, 0.05, 0.08, 0)
	_vignette.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_vignette.set_anchors_preset(Control.PRESET_FULL_RECT)
	_vignette.z_index = 60
	add_child(_vignette)


func _welcome() -> void:
	_show_toast("Univassouras · noite no campus · siga as luzes")


func _rotate_hint(reset: bool) -> void:
	if hint_label == null or HINTS.is_empty():
		return
	if not reset:
		_hint_index = (_hint_index + 1) % HINTS.size()
	hint_label.text = HINTS[_hint_index]
	_hint_timer = 7.5 if reset else 9.0


func flash_stamina() -> void:
	_stamina_flash = 0.35
	_pulse_screen(Color(0.95, 0.75, 0.2, 0.22), 0.22)


func flash_hurt() -> void:
	_pulse_screen(Color(0.85, 0.12, 0.15, 0.38), 0.28)


func flash_danger() -> void:
	_pulse_screen(Color(0.75, 0.15, 0.35, 0.42), 0.45)


func flash_hack() -> void:
	_pulse_screen(Color(0.25, 0.95, 0.45, 0.32), 0.4)


func flash_mark() -> void:
	_pulse_screen(Color(0.7, 0.25, 0.95, 0.3), 0.35)


func _pulse_screen(color: Color, duration: float) -> void:
	if _flash == null:
		return
	_flash.color = color
	var tw := create_tween()
	tw.tween_property(_flash, "color:a", 0.0, duration)


func play_death_fade() -> void:
	if _fade == null:
		await get_tree().create_timer(1.6).timeout
		return
	var tw := create_tween()
	tw.tween_property(_fade, "color:a", 0.92, 0.55)
	await tw.finished
	await get_tree().create_timer(0.55).timeout
	var tw2 := create_tween()
	tw2.tween_property(_fade, "color:a", 0.0, 0.7)
	await tw2.finished


func pulse_heal() -> void:
	_heal_pulse = 0.45


func bind_player(player: Node) -> void:
	_player = player
	if player.has_signal("health_changed"):
		player.health_changed.connect(_on_health)
	if player.has_signal("stamina_changed"):
		player.stamina_changed.connect(_on_stamina)
	if player.has_signal("weapon_changed"):
		player.weapon_changed.connect(_on_weapon)
	if player.has_signal("drinks_changed"):
		player.drinks_changed.connect(_on_heals)
	if "health" in player:
		_on_health(player.health, player.max_health)
		_on_stamina(player.stamina, player.max_stamina)
	_on_weapon(GameState.weapon_id())
	_refresh_meta()
	_refresh_ability()


func _on_health(current: float, maximum: float) -> void:
	_real_hp = current
	_real_max = maximum
	_apply_health_display()


func _apply_health_display() -> void:
	health_bar.max_value = _real_max
	if GameState.hud_lying:
		health_bar.value = clampf(_real_max - _real_hp + 10.0, 0.0, _real_max)
	else:
		health_bar.value = _real_hp


func _on_stamina(current: float, maximum: float) -> void:
	stamina_bar.max_value = maximum
	stamina_bar.value = current


func _on_weapon(_weapon_id: String) -> void:
	weapon_label.text = GameState.school_label()


func _on_bytes(_total: int = 0) -> void:
	_refresh_meta()
	_meta_flash = 0.4


func _on_gates() -> void:
	_refresh_meta()
	_meta_flash = 0.55


func _on_heals(_c: int = 0, _m: int = 0) -> void:
	_refresh_meta()


func _on_hacks() -> void:
	_apply_health_display()
	_update_status_bits()


func _refresh_meta(_a: Variant = null) -> void:
	if meta_label:
		meta_label.text = "Latas %d/%d · %d KB · Fis%d Esp%d · Base %d/3" % [
			GameState.heals, GameState.max_heals, GameState.bytes,
			GameState.fisico_level, GameState.especial_level,
			GameState.base_bosses_cleared(),
		]


func _refresh_ability() -> void:
	if ability_label == null:
		return
	var base := "Habilidade: %s  [F] usa · [T] troca na safe" % GameState.ability_label()
	if _player and is_instance_valid(_player) and _player.has_method("ability_cooldown_remaining"):
		var cd: float = float(_player.ability_cooldown_remaining())
		if cd > 0.05:
			ability_label.text = "%s · CD %.1fs" % [base, cd]
			ability_label.modulate = Color(0.75, 0.8, 0.9)
			_ability_was_cd = true
			return
		if _ability_was_cd:
			_ability_was_cd = false
			ability_label.modulate = Color(0.55, 1.0, 0.75)
			var tw := create_tween()
			tw.tween_property(ability_label, "modulate", Color.WHITE, 0.45)
			ability_label.text = base
			return
	ability_label.text = base
	ability_label.modulate = Color.WHITE


func _show_toast(message: String) -> void:
	if toast_label == null:
		return
	toast_label.text = message
	toast_label.visible = true
	toast_label.modulate = Color.WHITE
	if message.find("KB") >= 0 or message.find("carteira") >= 0:
		toast_label.modulate = Color(1.0, 0.92, 0.55)
	elif message.find("Marca") >= 0 or message.find("MARCADO") >= 0 or message.find("invert") >= 0 or message.find("HUD_FAKE") >= 0:
		toast_label.modulate = Color(0.85, 0.55, 1.0)
	elif message.find("liberado") >= 0 or message.find("3/3") >= 0 or message.find("SESSION") >= 0:
		toast_label.modulate = Color(0.55, 1.0, 0.7)
	elif message.find("Cura") >= 0 or message.find("lata") >= 0 or message.find("Safezone") >= 0:
		toast_label.modulate = Color(0.55, 1.0, 0.7)
	elif message.find("Vigor") >= 0 or message.find("recarga") >= 0:
		toast_label.modulate = Color(1.0, 0.75, 0.4)
	toast_label.modulate.a = 1.0
	toast_label.scale = Vector2(1.08, 1.08)
	_toast_timer = 3.2
	var tw := create_tween()
	tw.tween_property(toast_label, "scale", Vector2.ONE, 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _on_ending() -> void:
	_show_toast("FIM · Amandaconda derrotada · SESSION_CLOSED")
	_toast_timer = 6.0
	flash_danger()
	_pulse_screen(Color(0.95, 0.35, 0.55, 0.35), 0.9)
	if typeof(HitFeel) != TYPE_NIL:
		HitFeel.kill_punch(0.35)


func _update_boss_bar() -> void:
	if boss_panel == null or _player == null:
		return
	var target = _player.get("lock_target") if _player else null
	if target == null or not is_instance_valid(target) or not target.is_in_group("boss"):
		boss_panel.visible = false
		return
	boss_panel.visible = true
	if boss_name:
		var nome := "BOSS"
		if "label" in target and target.label:
			nome = str(target.label.text).split(" ")[0]
		elif target.has_method("_update_label"):
			nome = str(target.get("_cfg").get("nome", "BOSS")) if target.get("_cfg") else "BOSS"
		boss_name.text = nome
	if boss_bar and "health" in target and "max_health" in target:
		boss_bar.max_value = target.max_health
		boss_bar.value = target.health
		var mh := float(target.max_health)
		if mh > 0.0 and float(target.health) / mh < 0.3:
			var pulse := 0.55 + 0.45 * sin(Time.get_ticks_msec() * 0.01)
			boss_bar.modulate = Color(1.0, pulse * 0.5, pulse * 0.45)
		else:
			boss_bar.modulate = Color.WHITE
