extends OmniLight3D
## Tremor leve de poste/luz noturna.


func _ready() -> void:
	set_process(true)
	set_meta("base_energy", light_energy)


func _process(delta: float) -> void:
	var base := float(get_meta("base_energy", light_energy))
	var t := Time.get_ticks_msec() * 0.001 + global_position.x * 0.17
	var flicker := 0.88 + 0.12 * sin(t * 3.1) + 0.04 * sin(t * 11.0)
	# Pico raro tipo lâmpada instável
	if fmod(t * 0.37 + global_position.z * 0.05, 1.0) > 0.985:
		flicker *= 0.55
	light_energy = base * flicker
