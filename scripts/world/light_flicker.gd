extends OmniLight3D
## Tremor leve de poste/luz noturna.


func _ready() -> void:
	set_process(true)
	set_meta("base_energy", light_energy)
	set_meta("base_color", light_color)


func _process(_delta: float) -> void:
	var base := float(get_meta("base_energy", light_energy))
	var base_col: Color = get_meta("base_color", light_color)
	var t := Time.get_ticks_msec() * 0.001 + global_position.x * 0.17
	var flicker := 0.88 + 0.12 * sin(t * 3.1) + 0.04 * sin(t * 11.0)
	# Pico raro tipo lâmpada instável
	if fmod(t * 0.37 + global_position.z * 0.05, 1.0) > 0.985:
		flicker *= 0.55
	light_energy = base * flicker
	# Tom quente oscila um pouco com a energia
	var warm := clampf(0.5 + flicker * 0.5, 0.0, 1.0)
	light_color = base_col.lerp(Color(1.0, 0.78, 0.55), (1.0 - warm) * 0.35)
