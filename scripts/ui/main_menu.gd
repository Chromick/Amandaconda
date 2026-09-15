extends Control
## Menu — escolha de escola e entrada no hub.


func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	if typeof(HitFeel) != TYPE_NIL and HitFeel.has_method("cancel"):
		HitFeel.cancel()
	_style_night()
	_fill_version()


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


func _fill_version() -> void:
	var footer := get_node_or_null("Footer") as Label
	if footer == null:
		return
	var ver := str(ProjectSettings.get_setting("application/config/version", "0.4.0"))
	footer.text = "Godot 4.7 · v%s · campus noturno · Esc no hub pausa" % ver


func _on_fisico_pressed() -> void:
	GameState.start_run(GameState.WeaponSchool.TECLADO)


func _on_especial_pressed() -> void:
	GameState.start_run(GameState.WeaponSchool.VIRUS)


func _on_quit_pressed() -> void:
	get_tree().quit()
