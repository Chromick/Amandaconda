extends Control
## Menu — escolha de escola e entrada no hub.

var _title_pulse: float = 0.0


func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	if typeof(HitFeel) != TYPE_NIL and HitFeel.has_method("cancel"):
		HitFeel.cancel()
	_style_night()
	_fill_version()
	_style_buttons()


func _process(delta: float) -> void:
	_title_pulse += delta
	var title := get_node_or_null("Center/Title") as Label
	if title:
		var a := 0.88 + sin(_title_pulse * 1.6) * 0.12
		title.modulate = Color(a, a, 1.0)
	var sub := get_node_or_null("Center/Subtitle") as Label
	if sub:
		sub.modulate.a = 0.75 + sin(_title_pulse * 1.1) * 0.15


func _style_night() -> void:
	var bg := get_node_or_null("Bg") as ColorRect
	if bg:
		bg.visible = true
		bg.color = Color(0.06, 0.07, 0.1, 1.0)
	for path in ["Center/Title", "Center/Subtitle", "Center/SchoolPrompt", "Footer"]:
		var lab := get_node_or_null(path) as Label
		if lab == null:
			continue
		lab.add_theme_color_override("font_color", Color(0.92, 0.93, 0.96))
		lab.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.85))
		lab.add_theme_constant_override("outline_size", 6)


func _style_buttons() -> void:
	for path in ["Center/Fisico", "Center/Especial", "Center/Quit"]:
		var btn := get_node_or_null(path) as Button
		if btn == null:
			continue
		btn.add_theme_color_override("font_color", Color(0.9, 0.95, 0.92))
		btn.add_theme_color_override("font_hover_color", Color(0.55, 1.0, 0.75))
		btn.add_theme_color_override("font_pressed_color", Color(0.35, 0.85, 0.6))


func _fill_version() -> void:
	var footer := get_node_or_null("Footer") as Label
	if footer == null:
		return
	var ver := str(ProjectSettings.get_setting("application/config/version", "0.4.0"))
	footer.text = "Godot 4.7 · v%s · campus noturno · Esc no hub pausa" % ver


func _on_fisico_pressed() -> void:
	_flash_school_pick("Físico · Teclado")
	GameState.start_run(GameState.WeaponSchool.TECLADO)


func _on_especial_pressed() -> void:
	_flash_school_pick("Especial · Vírus")
	GameState.start_run(GameState.WeaponSchool.VIRUS)


func _flash_school_pick(name: String) -> void:
	var prompt := get_node_or_null("Center/SchoolPrompt") as Label
	if prompt:
		prompt.text = "Entrando · %s" % name
		prompt.modulate = Color(0.55, 1.0, 0.75)


func _on_quit_pressed() -> void:
	get_tree().quit()
