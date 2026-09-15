extends Node3D
## Campus Univassouras · Maricá — fachada real + hub Souls (salas de chefe).

const CHATANA := preload("res://scenes/enemies/chatana.tscn")
const PORTARA := preload("res://scenes/enemies/portara.tscn")
const NET := preload("res://scenes/enemies/net.tscn")
const BYTES := preload("res://scenes/bytes_pickup.tscn")
const LUAN := preload("res://scenes/bosses/luanevil.tscn")
const RENAN := preload("res://scenes/bosses/renanligno.tscn")
const BALAR := preload("res://scenes/bosses/balarrals.tscn")
const MARLON := preload("res://scenes/bosses/marlombolico.tscn")
const AMANDA := preload("res://scenes/bosses/amandaconda.tscn")
const PENDRIVE := preload("res://scenes/pendrive_pickup.tscn")
const TERMINAL := preload("res://scenes/patch_terminal.tscn")
const GATE := preload("res://scenes/boss_gate.tscn")
const SAFEZONE_SCRIPT := preload("res://scripts/world/safezone.gd")
const BOSS_ARENA_SCRIPT := preload("res://scripts/world/boss_arena.gd")

# Paleta da fachada (foto referência)
const C_MAROON := Color(0.43, 0.09, 0.15)
const C_WHITE := Color(0.95, 0.95, 0.94)
const C_BEIGE := Color(0.86, 0.82, 0.74)
const C_GLASS := Color(0.42, 0.58, 0.62, 0.38)
const C_RAIL := Color(0.78, 0.8, 0.82)
const C_ASPHALT := Color(0.52, 0.53, 0.55)
const C_WALK := Color(0.62, 0.63, 0.65)
const C_GRASS := Color(0.28, 0.42, 0.26)
const C_FLOOR_IN := Color(0.72, 0.7, 0.66)

# Salas de chefe (centros)
const ROOM_BANDEJAO := Vector3(-28, 0, -2)
const ROOM_LAB := Vector3(26, 0, 0)
const ROOM_PATIO := Vector3(-26, 0, -22)
const ROOM_SERV := Vector3(26, 0, -20)
const ROOM_PORTA := Vector3(0, 0, -36)
const ROOM_SIZE := Vector3(14, 3.6, 12)
const ROOM_PORTA_SIZE := Vector3(12, 3.6, 12)

@onready var rooms_root: Node3D = $Rooms
@onready var spawns_root: Node3D = $Spawns


func _ready() -> void:
	_build_grounds()
	_build_facade_univassouras()
	_build_interior_hub()
	_dress_campus()
	_spawn_gameplay()
	GameState.safezone_position = Vector3(0, 1, 22)


func _build_grounds() -> void:
	# Estacionamento (sul) + calçada de entrada
	_box(Vector3(0, 0.02, 28), Vector3(70, 0.04, 28), C_ASPHALT)
	_box(Vector3(0, 0.03, 16), Vector3(10, 0.05, 8), C_WALK)
	# Gramado laterais
	_box(Vector3(-28, 0.02, 20), Vector3(18, 0.04, 12), C_GRASS)
	_box(Vector3(28, 0.02, 20), Vector3(18, 0.04, 12), C_GRASS)
	# Pátio interno
	_box(Vector3(0, 0.02, -8), Vector3(18, 0.04, 36), C_WALK.darkened(0.08))
	_build_white_fence()
	# Carros-proxy no estacionamento
	_car(Vector3(-10, 0.4, 30), Color(0.75, 0.15, 0.12), 15.0)
	_car(Vector3(-16, 0.4, 31), Color(0.7, 0.72, 0.75), -8.0)
	_car(Vector3(12, 0.4, 30), Color(0.2, 0.22, 0.28), 5.0)
	_car(Vector3(18, 0.4, 29.5), Color(0.85, 0.85, 0.82), -12.0)


func _build_white_fence() -> void:
	## Grade branca na frente do campus + portão central.
	var z := 14.0
	for side_i in 2:
		var side := -1.0 if side_i == 0 else 1.0
		var x0 := 4.0 * side
		var step := 0.55 * side
		for i in 42:
			var x := x0 + step * float(i)
			if absf(x) > 40.0:
				break
			_box(Vector3(x, 1.0, z), Vector3(0.08, 2.0, 0.08), C_WHITE, true)
		# Travessa superior
		var mid := (4.0 + 22.0) * 0.5 * side
		_box(Vector3(mid, 2.05, z), Vector3(20.0, 0.08, 0.08), C_WHITE, true)
	# Portão (vão central) — folhas abertas / moldura
	_box(Vector3(-3.4, 1.3, z), Vector3(0.2, 2.6, 0.15), C_WHITE, true)
	_box(Vector3(3.4, 1.3, z), Vector3(0.2, 2.6, 0.15), C_WHITE, true)
	_box(Vector3(0, 2.55, z), Vector3(7.0, 0.12, 0.12), C_WHITE, true)
	var lab := Label3D.new()
	lab.text = "UNIVASSOURAS\nCAMPUS MARICÁ"
	lab.font_size = 48
	lab.modulate = C_MAROON
	lab.outline_size = 10
	lab.outline_modulate = Color(0, 0, 0, 0.9)
	lab.position = Vector3(0, 3.4, z + 0.2)
	rooms_root.add_child(lab)
	_add_room_light(Vector3(0, 3.2, z + 0.5), Color(0.85, 0.35, 0.4), 2.2, 6.0)


func _build_facade_univassouras() -> void:
	## Bloco esquerdo (torre vinho + galeria 4 andares) e bloco direito (2 andares).
	# Torre vinho (extremidade oeste da ala principal)
	_build_maroon_tower(Vector3(-36, 0, 2), Vector3(8, 16, 16))
	# Galeria principal 4 pavimentos (ala esquerda / centro-esquerda)
	_build_gallery_wing(
		Vector3(-18, 0, 2),
		24.0, # width X
		14.0, # depth Z
		4, # floors
		true # sign on top
	)
	# Ala direita 2 pavimentos
	_build_gallery_wing(
		Vector3(20, 0, 4),
		22.0,
		12.0,
		2,
		false
	)
	# Ligação / fundo norte (bloco de serviços + Porta)
	_build_north_block()
	# Colinas / contexto ao fundo (silhueta)
	_box(Vector3(-50, 4, -55), Vector3(40, 10, 12), Color(0.22, 0.35, 0.2))
	_box(Vector3(45, 5, -52), Vector3(36, 12, 14), Color(0.2, 0.32, 0.18))
	_box(Vector3(0, 3, -60), Vector3(80, 8, 10), Color(0.25, 0.38, 0.22))


func _build_maroon_tower(center: Vector3, size: Vector3) -> void:
	_box(center + Vector3(0, size.y * 0.5, 0), size, C_MAROON, true)
	# Janelas acesas (noite)
	var face_z := center.z + size.z * 0.5 + 0.06
	for i in 5:
		var y := 2.5 + float(i) * 2.4
		_emissive_box(
			Vector3(center.x, y, face_z),
			Vector3(size.x * 0.55, 0.55, 0.12),
			Color(1.0, 0.78, 0.35, 1),
			Color(1.0, 0.65, 0.2),
			2.8
		)
	# Branding
	var brand := Label3D.new()
	brand.text = "UNIVASSOURAS\nCAMPUS UNIVERSITÁRIO\nDE MARICÁ"
	brand.font_size = 42
	brand.modulate = Color(1, 1, 1)
	brand.position = center + Vector3(0, size.y * 0.72, size.z * 0.5 + 0.2)
	rooms_root.add_child(brand)


func _build_gallery_wing(center: Vector3, width: float, depth: float, floors: int, with_sign: bool) -> void:
	var floor_h := 3.2
	var total_h := float(floors) * floor_h
	# Parede de fundo (beige) — salas atrás da galeria
	var back_z := center.z - depth * 0.35
	_box(
		Vector3(center.x, total_h * 0.5, back_z),
		Vector3(width - 0.4, total_h, depth * 0.45),
		C_BEIGE,
		true
	)
	# Lajes + pilares + guarda-corpo de vidro em cada andar (face sul)
	var front_z := center.z + depth * 0.45
	var x0 := center.x - width * 0.5 + 1.0
	var x1 := center.x + width * 0.5 - 1.0
	var pillar_step := 3.2
	for f in floors:
		var y_slab := float(f) * floor_h
		# Laje / teto do corredor
		_box(
			Vector3(center.x, y_slab + 0.12, front_z - 1.2),
			Vector3(width, 0.24, 4.2),
			C_WHITE,
			true
		)
		# Piso do corredor
		_box(
			Vector3(center.x, y_slab + 0.05, front_z - 1.0),
			Vector3(width - 0.2, 0.1, 3.6),
			C_FLOOR_IN
		)
		# Pilares brancos
		var x := x0
		while x <= x1 + 0.01:
			_box(Vector3(x, y_slab + floor_h * 0.5, front_z - 0.15), Vector3(0.28, floor_h - 0.1, 0.28), C_WHITE, true)
			x += pillar_step
		# Guarda-corpo de vidro
		_glass(
			Vector3(center.x, y_slab + 1.05, front_z + 0.05),
			Vector3(width - 0.6, 1.1, 0.08)
		)
		_box(Vector3(center.x, y_slab + 1.6, front_z + 0.05), Vector3(width - 0.5, 0.06, 0.06), C_RAIL)
		# Luzes de corredor na galeria (noite)
		_add_room_light(Vector3(center.x - width * 0.25, y_slab + 2.4, front_z - 1.0), Color(1.0, 0.85, 0.55), 3.5, 8.0)
		_add_room_light(Vector3(center.x + width * 0.25, y_slab + 2.4, front_z - 1.0), Color(1.0, 0.85, 0.55), 3.5, 8.0)
	# Platibanda / topo
	_box(Vector3(center.x, total_h + 0.25, front_z - 1.0), Vector3(width + 0.4, 0.5, 4.4), C_WHITE, true)
	if with_sign:
		var sign := Label3D.new()
		sign.text = "CAMPUS UNIVERSITÁRIO DE MARICÁ"
		sign.font_size = 56
		sign.modulate = Color(1, 1, 1)
		sign.position = Vector3(center.x, total_h + 0.9, front_z + 0.15)
		rooms_root.add_child(sign)
	# Arbustos na base (proxy)
	for i in 5:
		var bx := center.x - width * 0.4 + float(i) * (width * 0.2)
		_box(Vector3(bx, 0.45, front_z + 1.15), Vector3(0.9, 0.9, 0.9), Color(0.2, 0.45, 0.22))


func _build_north_block() -> void:
	# Corpo norte ligando as alas (acesso à Porta)
	_box(Vector3(0, 4, -28), Vector3(20, 8, 10), C_BEIGE.darkened(0.05), true)
	_box(Vector3(0, 8.3, -28), Vector3(20.4, 0.5, 10.4), C_WHITE, true)
	# Abertura central do corredor norte
	_box(Vector3(0, 0.05, -22), Vector3(6, 0.1, 16), C_WALK)


func _build_interior_hub() -> void:
	## Salas de chefe + corredores internos (gameplay Souls).
	var gaps_bandejao := _build_room(ROOM_BANDEJAO, ROOM_SIZE, C_BEIGE.darkened(0.12), "BANDEJÃO · LuanEvil")
	var gaps_lab := _build_room(ROOM_LAB, ROOM_SIZE, Color(0.75, 0.8, 0.85), "LAB · Renanligno")
	var gaps_patio := _build_room(ROOM_PATIO, ROOM_SIZE, Color(0.7, 0.72, 0.7), "PÁTIO · Balarrals")
	var gaps_serv := _build_room(ROOM_SERV, ROOM_SIZE, Color(0.55, 0.65, 0.58), "SERVIDORES · Marlon")
	var gaps_porta := _build_room(ROOM_PORTA, ROOM_PORTA_SIZE, C_MAROON.lightened(0.15), "A PORTA · Amandaconda")

	# Corredor central (entrada → pátio → porta)
	_build_corridor(Vector3(0, 0, 4), Vector3(7, 3.2, 18))
	_build_corridor(Vector3(0, 0, -14), Vector3(7, 3.2, 16))
	# Ramais para alas
	_build_corridor(Vector3(-14, 0, -2), Vector3(16, 3.2, 5.5))
	_build_corridor(Vector3(14, 0, 0), Vector3(16, 3.2, 5.5))
	_build_corridor(Vector3(-14, 0, -20), Vector3(14, 3.2, 5.5))
	_build_corridor(Vector3(14, 0, -18), Vector3(14, 3.2, 5.5))

	_make_safezone(Vector3(0, 0.55, 22), Vector3(12, 0.12, 10))
	_street_lamp(Vector3(-7, 0, 20))
	_street_lamp(Vector3(7, 0, 20))
	_street_lamp(Vector3(0, 0, 16))
	_street_lamp(Vector3(-5, 0, 12))
	_street_lamp(Vector3(5, 0, 12))
	_street_lamp(Vector3(-12, 0, -2))
	_street_lamp(Vector3(12, 0, -2))
	_street_lamp(Vector3(-12, 0, -18))
	_street_lamp(Vector3(12, 0, -18))
	_street_lamp(Vector3(0, 0, -28))
	_street_lamp(Vector3(0, 0, 4))
	_street_lamp(Vector3(-14, 0, -2))
	_street_lamp(Vector3(14, 0, 0))
	_street_lamp(Vector3(-8, 0, -8))
	_street_lamp(Vector3(8, 0, -8))
	_street_lamp(Vector3(0, 0, -10))
	_street_lamp(Vector3(-10, 0, -24))
	_street_lamp(Vector3(10, 0, -24))
	# Placas de direção (Souls hub)
	_way_sign(Vector3(-6, 2.2, 2), "← BANDEJÃO\nLuanEvil", Color(1.0, 0.55, 0.25))
	_way_sign(Vector3(6, 2.2, 2), "LAB →\nRenanligno", Color(0.45, 0.75, 1.0))
	_way_sign(Vector3(-6, 2.2, -14), "← PÁTIO\nBalarrals", Color(0.85, 0.85, 0.95))
	_way_sign(Vector3(6, 2.2, -14), "SERVIDORES →\nMarlon", Color(0.4, 1.0, 0.55))
	_way_sign(Vector3(0, 2.4, -24), "↑ A PORTA\nAmandaconda", Color(1.0, 0.35, 0.45))
	_way_sign(Vector3(0, 2.2, 16), "↓ SAFEZONE\nlatas · T skill", Color(0.45, 1.0, 0.65))
	_way_sign(Vector3(4.5, 2.0, 20), "PATCHES →\nservidor [E]", Color(0.55, 1.0, 0.75))
	_way_sign(Vector3(-4.5, 2.0, 18), "T · skill\nna safezone", Color(0.65, 0.95, 1.0))
	_way_sign(Vector3(-14, 2.0, 6), "← ALA OESTE\nChatana · Portara", Color(0.75, 0.9, 1.0))
	_way_sign(Vector3(14, 2.0, 4), "ALA LESTE →\nNet · KB", Color(0.85, 0.7, 1.0))
	_street_lamp(Vector3(-20, 0, 6))
	_street_lamp(Vector3(20, 0, 4))

	# Guarda gaps para spawn (via meta no builder)
	set_meta("gaps_bandejao", gaps_bandejao)
	set_meta("gaps_lab", gaps_lab)
	set_meta("gaps_patio", gaps_patio)
	set_meta("gaps_serv", gaps_serv)
	set_meta("gaps_porta", gaps_porta)


func _spawn_gameplay() -> void:
	var gaps_bandejao: Array = get_meta("gaps_bandejao")
	var gaps_lab: Array = get_meta("gaps_lab")
	var gaps_patio: Array = get_meta("gaps_patio")
	var gaps_serv: Array = get_meta("gaps_serv")
	var gaps_porta: Array = get_meta("gaps_porta")

	# Inimigos nos corredores / galerias (packs locais, visual modular)
	_spawn_enemy(CHATANA, Vector3(-8, 1, 2), "modular/Casual_2.gltf", 1.05, Color(0.45, 0.95, 1, 1))
	_spawn_enemy(CHATANA, Vector3(10, 1, -6), "modular/Punk.gltf", 1.08, Color(0.7, 0.85, 1, 1))
	_spawn_enemy(CHATANA, Vector3(-20, 1, -10), "modular/Farmer.gltf", 1.05, Color(0.55, 0.9, 0.95, 1))
	_spawn_enemy(CHATANA, Vector3(6, 1, -18), "modular/Beach.gltf", 1.05, Color(0.5, 0.95, 0.9, 1))
	_spawn_enemy(PORTARA, Vector3(-12, 1, -12), "modular/Worker.gltf", 1.28, Color(0.85, 0.7, 0.55, 1))
	_spawn_enemy(PORTARA, Vector3(12, 1, 6), "modular/Adventurer.gltf", 1.22, Color(0.75, 0.65, 0.55, 1))
	_spawn_enemy(PORTARA, Vector3(18, 1, -8), "modular/King.gltf", 1.15, Color(0.7, 0.6, 0.5, 1))
	_spawn_enemy(PORTARA, Vector3(22, 1, -14), "modular/Suit.gltf", 1.18, Color(0.65, 0.55, 0.5, 1))
	_spawn_enemy(NET, Vector3(0, 1, -8), "modular/Swat.gltf", 1.1, Color(0.85, 0.45, 1, 1))
	_spawn_enemy(NET, Vector3(-18, 1, 4), "modular/Spacesuit.gltf", 1.05, Color(0.75, 0.4, 0.95, 1))
	_spawn_enemy(NET, Vector3(8, 1, -22), "modular/Casual_Hoodie.gltf", 1.08, Color(0.8, 0.5, 1, 1))
	_spawn_enemy(CHATANA, Vector3(-4, 1, -26), "modular/Casual_2.gltf", 1.05, Color(0.6, 0.95, 1, 1))
	_spawn_enemy(PORTARA, Vector3(16, 1, -24), "modular/Worker.gltf", 1.2, Color(0.8, 0.68, 0.5, 1))
	_spawn_enemy(NET, Vector3(-22, 1, -22), "modular/Punk.gltf", 1.06, Color(0.9, 0.45, 1, 1))
	_spawn_enemy(CHATANA, Vector3(20, 1, 2), "modular/Beach.gltf", 1.04, Color(0.55, 0.9, 1, 1))
	_spawn_enemy(PORTARA, Vector3(-26, 1, 8), "modular/Suit.gltf", 1.16, Color(0.7, 0.58, 0.48, 1))
	_spawn_enemy(NET, Vector3(24, 1, -6), "modular/Swat.gltf", 1.07, Color(0.88, 0.5, 1, 1))
	_spawn_enemy(CHATANA, Vector3(-14, 1, 10), "modular/Farmer.gltf", 1.03, Color(0.5, 0.92, 0.95, 1))
	_spawn(BYTES, Vector3(-3, 0.6, 18))
	_spawn(BYTES, Vector3(4, 0.6, 8))
	_spawn(BYTES, Vector3(0, 0.6, 14))
	_spawn(BYTES, Vector3(-20, 0.6, -8))
	_spawn(BYTES, Vector3(8, 0.6, -16))
	_spawn(BYTES, Vector3(-26, 0.6, -20))
	_spawn(BYTES, Vector3(24, 0.6, -2))
	_spawn(BYTES, Vector3(0, 0.6, -30))
	_spawn(BYTES, Vector3(6, 0.6, -18))
	_spawn(BYTES, Vector3(-8, 0.6, 2))
	_spawn(BYTES, Vector3(22, 0.6, -14))
	_spawn(BYTES, Vector3(8, 0.6, -22))
	_spawn(BYTES, Vector3(-14, 0.6, -2))
	_spawn(BYTES, Vector3(14, 0.6, 0))
	_spawn(BYTES, Vector3(0, 0.6, -20))
	_spawn(BYTES, Vector3(-6, 0.6, 10))
	_spawn(BYTES, Vector3(-10, 0.6, -16))
	_spawn(BYTES, Vector3(10, 0.6, -12))
	_spawn(BYTES, Vector3(-16, 0.6, 8))
	_spawn(BYTES, Vector3(18, 0.6, -20))
	_spawn(BYTES, Vector3(-24, 0.6, 6))
	_spawn(BYTES, Vector3(26, 0.6, -8))
	_spawn(BYTES, Vector3(0, 0.6, -14))

	var luan := _spawn_node(LUAN, ROOM_BANDEJAO + Vector3(0, 1, 0))
	var renan := _spawn_node(RENAN, ROOM_LAB + Vector3(0, 1, 0))
	var balar := _spawn_node(BALAR, ROOM_PATIO + Vector3(0, 1, 0))
	var marlon := _spawn_node(MARLON, ROOM_SERV + Vector3(0, 1, 0))
	var amanda := _spawn_node(AMANDA, ROOM_PORTA + Vector3(0, 1, 0))
	_make_boss_arena(ROOM_BANDEJAO, ROOM_SIZE, luan, "luanevil", gaps_bandejao)
	_make_boss_arena(ROOM_LAB, ROOM_SIZE, renan, "renanligno", gaps_lab)
	_make_boss_arena(ROOM_PATIO, ROOM_SIZE, balar, "balarrals", gaps_patio)
	_make_boss_arena(ROOM_SERV, ROOM_SIZE, marlon, "marlombolico", gaps_serv)
	_make_boss_arena(ROOM_PORTA, ROOM_PORTA_SIZE, amanda, "amandaconda", gaps_porta)

	var pen_f := PENDRIVE.instantiate()
	pen_f.kind = "fisico"
	spawns_root.add_child(pen_f)
	pen_f.global_position = Vector3(-5, 0.5, 20)
	var pen_e := PENDRIVE.instantiate()
	pen_e.kind = "especial"
	spawns_root.add_child(pen_e)
	pen_e.global_position = Vector3(5, 0.5, 20)
	var pen_f2 := PENDRIVE.instantiate()
	pen_f2.kind = "fisico"
	spawns_root.add_child(pen_f2)
	pen_f2.global_position = Vector3(-18, 0.5, -6)
	var pen_e2 := PENDRIVE.instantiate()
	pen_e2.kind = "especial"
	spawns_root.add_child(pen_e2)
	pen_e2.global_position = Vector3(18, 0.5, -10)
	_spawn(TERMINAL, Vector3(0, 0, 20))

	var g_serv := GATE.instantiate()
	g_serv.gate_id = "servers"
	spawns_root.add_child(g_serv)
	g_serv.global_position = Vector3(16, 0, -18)

	var g_door := GATE.instantiate()
	g_door.gate_id = "door"
	spawns_root.add_child(g_door)
	g_door.global_position = Vector3(0, 0, -28)


func _dress_campus() -> void:
	var props := Node3D.new()
	props.name = "Props"
	rooms_root.add_child(props)
	_dress_entry(props)
	_dress_bandejao(props)
	_dress_lab(props)
	_dress_servers(props)
	_dress_patio(props)
	_dress_porta(props)
	_add_night_lights()
	_spawn_night_stars()
	_spawn_dust_motes()


func _add_night_lights() -> void:
	## Iluminação noturna: fachada + estacionamento + salas.
	# Postes / entrada
	_add_room_light(Vector3(-6, 5.5, 18), Color(1.0, 0.82, 0.55), 10.0, 18.0)
	_add_room_light(Vector3(6, 5.5, 18), Color(1.0, 0.82, 0.55), 10.0, 18.0)
	_add_room_light(Vector3(0, 4.5, 24), Color(1.0, 0.88, 0.65), 7.0, 14.0)
	# Galeria / fachada (wash quente + frio)
	_add_room_light(Vector3(-18, 8, 10), Color(1.0, 0.75, 0.45), 12.0, 22.0)
	_add_room_light(Vector3(-32, 10, 8), Color(1.0, 0.45, 0.35), 9.0, 16.0)
	_add_room_light(Vector3(18, 6, 10), Color(0.75, 0.85, 1.0), 9.0, 18.0)
	# Corredor interno
	_add_room_light(Vector3(0, 3.5, 4), Color(1.0, 0.9, 0.7), 6.5, 12.0)
	_add_room_light(Vector3(0, 3.5, -12), Color(0.85, 0.8, 1.0), 5.5, 12.0)
	_add_room_light(Vector3(-10, 3.2, -2), Color(1.0, 0.75, 0.55), 5.0, 11.0)
	_add_room_light(Vector3(10, 3.2, -2), Color(0.7, 0.85, 1.0), 5.0, 11.0)
	_add_room_light(Vector3(-10, 3.2, -18), Color(1.0, 0.55, 0.4), 5.0, 11.0)
	_add_room_light(Vector3(10, 3.2, -18), Color(0.45, 1.0, 0.6), 5.0, 11.0)
	# Salas de chefe
	_add_room_light(ROOM_BANDEJAO + Vector3(0, 3.2, 0), Color(1.0, 0.5, 0.28), 11.0, 16.0)
	_add_room_light(ROOM_LAB + Vector3(0, 3.2, 0), Color(0.45, 0.7, 1.0), 11.0, 16.0)
	_add_room_light(ROOM_PATIO + Vector3(0, 3.2, 0), Color(1.0, 0.45, 0.28), 10.0, 15.0)
	_add_room_light(ROOM_SERV + Vector3(0, 3.2, 0), Color(0.35, 1.0, 0.5), 11.0, 16.0)
	_add_room_light(ROOM_PORTA + Vector3(0, 3.2, 0), Color(1.0, 0.25, 0.4), 13.0, 18.0)
	# Foguinho da safezone (bonfire feel)
	_emissive_box(Vector3(0, 0.35, 22), Vector3(0.9, 0.35, 0.9), Color(1.0, 0.55, 0.2), Color(1.0, 0.4, 0.1), 5.0)
	_add_room_light(Vector3(0, 1.2, 22), Color(1.0, 0.55, 0.25), 8.0, 10.0)


func _dress_entry(root: Node3D) -> void:
	_prop(root, "bench.glb", Vector3(-4, 0, 18), 90.0)
	_prop(root, "bench.glb", Vector3(4, 0, 18), -90.0)
	_prop(root, "pottedPlant.glb", Vector3(-6, 0, 15), 10.0)
	_prop(root, "pottedPlant.glb", Vector3(6, 0, 15), -10.0)
	_prop(root, "trashcan.glb", Vector3(5, 0, 21), 0.0)
	_prop(root, "trashcan.glb", Vector3(-5, 0, 21), 20.0)
	_prop(root, "trashcan.glb", Vector3(-8, 0, 8), -15.0)
	_prop(root, "trashcan.glb", Vector3(8, 0, -4), 40.0)
	_prop(root, "pottedPlant.glb", Vector3(-2, 0, -12), 55.0)
	_prop(root, "pottedPlant.glb", Vector3(2, 0, -12), -55.0)
	_prop(root, "loungeSofa.glb", Vector3(-3, 0, 11), 180.0)
	_prop(root, "loungeSofa.glb", Vector3(3, 0, 11), 180.0)
	_prop(root, "televisionModern.glb", Vector3(0, 0, 9.5), 0.0)
	_prop(root, "pottedPlant.glb", Vector3(-3.5, 0, 4), 25.0)
	_prop(root, "pottedPlant.glb", Vector3(3.5, 0, 4), -25.0)
	_prop(root, "bench.glb", Vector3(-5.5, 0, 8), 90.0)
	_prop(root, "bench.glb", Vector3(5.5, 0, 8), -90.0)
	_prop(root, "trashcan.glb", Vector3(0, 0, 14.5), 0.0)
	_prop(root, "bench.glb", Vector3(0, 0, -6), 0.0)
	_prop(root, "pottedPlant.glb", Vector3(-7, 0, -8), 70.0)
	_prop(root, "pottedPlant.glb", Vector3(7, 0, -8), -70.0)
	_prop(root, "trashcan.glb", Vector3(-2.5, 0, -20), 10.0)
	_prop(root, "trashcan.glb", Vector3(2.5, 0, -20), -10.0)


func _dress_bandejao(root: Node3D) -> void:
	var center := ROOM_BANDEJAO
	for i in 3:
		for j in 2:
			var tpos := center + Vector3((i - 1) * 3.0, 0, (j - 0.5) * 3.2)
			_prop(root, "table.glb", tpos, 0.0)
			_prop(root, "chair.glb", tpos + Vector3(0, 0, 1.0), 180.0)
			_prop(root, "chair.glb", tpos + Vector3(0, 0, -1.0), 0.0)
	_prop(root, "kitchenCoffeeMachine.glb", center + Vector3(-4.5, 0, -4.0), 90.0)
	_prop(root, "trashcan.glb", center + Vector3(4.5, 0, -4.5), 0.0)
	_prop(root, "trashcan.glb", center + Vector3(-4.8, 0, 3.5), 25.0)
	_prop(root, "pottedPlant.glb", center + Vector3(4.8, 0, 3.2), -30.0)
	_prop(root, "pottedPlant.glb", center + Vector3(-5.0, 0, 0.5), 15.0)
	var fan := _prop(root, "ceilingFan.glb", center + Vector3(0, 3.1, 0), 0.0)
	if fan:
		fan.set_script(preload("res://scripts/world/spin_y.gd"))
	_emissive_box(center + Vector3(-1.5, 0.05, 2.0), Vector3(1.2, 0.05, 1.0), Color(0.45, 0.22, 0.08), Color(1.0, 0.4, 0.1), 1.8)
	_emissive_box(center + Vector3(2.2, 0.05, -1.5), Vector3(0.9, 0.05, 0.8), Color(0.4, 0.2, 0.08), Color(0.95, 0.35, 0.08), 1.4)
	_emissive_box(center + Vector3(0, 0.05, -3.5), Vector3(1.1, 0.05, 0.9), Color(0.42, 0.2, 0.08), Color(1.0, 0.38, 0.1), 1.5)
	_prop(root, "kitchenCoffeeMachine.glb", center + Vector3(4.5, 0, -4.0), -90.0)
	_prop(root, "bench.glb", center + Vector3(0, 0, 4.5), 0.0)
	_add_room_light(center + Vector3(0, 2.2, 2.5), Color(1.0, 0.5, 0.2), 5.5, 9.0)
	_add_room_light(center + Vector3(-3.5, 2.0, -2.5), Color(1.0, 0.55, 0.25), 3.5, 7.0)
	_add_room_light(center + Vector3(3.2, 2.0, 1.5), Color(0.95, 0.4, 0.2), 3.2, 6.5)


func _dress_lab(root: Node3D) -> void:
	var center := ROOM_LAB
	for i in 3:
		var z := -3.5 + i * 3.0
		_prop(root, "desk.glb", center + Vector3(-3.0, 0, z), 90.0)
		_prop(root, "chairDesk.glb", center + Vector3(-1.8, 0, z), -90.0)
		_prop(root, "computerScreen.glb", center + Vector3(-3.0, 0.85, z), 90.0)
		_prop(root, "desk.glb", center + Vector3(3.0, 0, z), -90.0)
		_prop(root, "laptop.glb", center + Vector3(3.0, 0.78, z), -90.0)
		_add_room_light(center + Vector3(-2.6, 1.1, z), Color(0.35, 0.85, 1.0), 1.4, 3.2)
		_add_room_light(center + Vector3(2.6, 1.05, z), Color(0.4, 0.9, 0.7), 1.1, 2.8)
	_prop(root, "bookcaseOpen.glb", center + Vector3(0, 0, -5.0), 0.0)
	_prop(root, "trashcan.glb", center + Vector3(4.5, 0, 4.5), 10.0)
	_prop(root, "pottedPlant.glb", center + Vector3(-4.5, 0, 4.2), 40.0)
	_prop(root, "computerScreen.glb", center + Vector3(0, 0.85, -4.6), 0.0)
	_emissive_box(center + Vector3(0, 0.08, 0), Vector3(0.4, 0.06, 3.5), Color(0.08, 0.1, 0.14), Color(0.4, 0.7, 1.0), 1.6)
	_add_room_light(center + Vector3(-2, 2.5, 0), Color(0.45, 0.75, 1.0), 5.0, 10.0)
	_add_room_light(center + Vector3(2, 2.2, 1), Color(0.7, 0.35, 0.9), 3.5, 8.0)
	var fan := _prop(root, "ceilingFan.glb", center + Vector3(0, 3.1, 0), 0.0)
	if fan:
		fan.set_script(preload("res://scripts/world/spin_y.gd"))


func _dress_servers(root: Node3D) -> void:
	var center := ROOM_SERV
	for i in 3:
		_prop(root, "box-long.glb", center + Vector3(-3.5 + i * 2.2, 0, -3.5), 0.0, 1.1)
		_prop(root, "pipe-large.glb", center + Vector3(-4.5, 1.2, -2.5 + i * 2.2), 90.0, 0.8)
	_prop(root, "machine-connection-pipe.glb", center + Vector3(4.0, 0, 0), -90.0)
	_prop(root, "column.glb", center + Vector3(-4.5, 0, 4.0), 0.0)
	_prop(root, "column.glb", center + Vector3(4.5, 0, 4.0), 0.0)
	_emissive_box(center + Vector3(0, 0.1, 0), Vector3(2.5, 0.08, 2.5), Color(0.05, 0.12, 0.06), Color(0.2, 1.0, 0.35), 2.0)
	_add_room_light(center + Vector3(0, 2.8, 0), Color(0.25, 1.0, 0.4), 7.0, 12.0)
	_add_room_light(center + Vector3(-3.2, 1.6, -2.0), Color(0.2, 0.9, 0.45), 2.2, 5.0)
	_add_room_light(center + Vector3(3.0, 1.5, 2.2), Color(0.15, 0.85, 1.0), 2.0, 4.5)
	_prop(root, "trashcan.glb", center + Vector3(-4.2, 0, 3.5), 15.0)
	_prop(root, "box-long.glb", center + Vector3(2.5, 0, 3.8), 90.0, 0.95)
	_prop(root, "pipe-large.glb", center + Vector3(3.8, 1.0, -3.5), 0.0, 0.85)
	_prop(root, "box-long.glb", center + Vector3(-2.0, 0, 3.2), 45.0, 0.9)


func _dress_patio(root: Node3D) -> void:
	var center := ROOM_PATIO
	_prop(root, "bench.glb", center + Vector3(-3, 0, 0), 90.0)
	_prop(root, "bench.glb", center + Vector3(3, 0, 0), -90.0)
	_prop(root, "tableRound.glb", center + Vector3(0, 0, -3), 0.0)
	_prop(root, "pottedPlant.glb", center + Vector3(-4.5, 0, -4), 0.0)
	_prop(root, "pottedPlant.glb", center + Vector3(4.5, 0, 4), 40.0)
	# Cadeiras espalhadas — leitmotif do Balarrals
	_prop(root, "chair.glb", center + Vector3(-2.2, 0, 2.5), 35.0)
	_prop(root, "chair.glb", center + Vector3(2.8, 0, 1.8), -50.0)
	_prop(root, "chair.glb", center + Vector3(-1.5, 0, -4.2), 160.0)
	_prop(root, "chair.glb", center + Vector3(4.0, 0, -1.5), 95.0)
	_prop(root, "trashcan.glb", center + Vector3(4.6, 0, 3.5), 20.0)
	_prop(root, "bench.glb", center + Vector3(0, 0, 4.2), 0.0)
	_prop(root, "pottedPlant.glb", center + Vector3(-5.2, 0, 1.5), 70.0)
	_prop(root, "pottedPlant.glb", center + Vector3(5.0, 0, -2.8), -25.0)
	_prop(root, "chair.glb", center + Vector3(0.8, 0, 3.6), -20.0)
	_prop(root, "chair.glb", center + Vector3(-3.5, 0, -1.2), 110.0)
	_prop(root, "chair.glb", center + Vector3(3.2, 0, -3.8), -140.0)
	_prop(root, "tableRound.glb", center + Vector3(-3.8, 0, 3.2), 25.0)
	# Brasa no chão / sombra do pátio
	_emissive_box(center + Vector3(0, 0.08, 1.5), Vector3(1.4, 0.06, 1.4), Color(0.15, 0.08, 0.05), Color(1.0, 0.35, 0.1), 2.2)
	_emissive_box(center + Vector3(-2.5, 0.06, -2.0), Vector3(0.9, 0.05, 0.9), Color(0.12, 0.06, 0.04), Color(0.95, 0.3, 0.08), 1.6)
	_add_room_light(center + Vector3(-2.5, 2.4, 2.0), Color(1.0, 0.4, 0.18), 6.0, 10.0)
	_add_room_light(center + Vector3(2.5, 2.2, -1.5), Color(0.35, 0.4, 0.55), 4.5, 9.0)
	_add_room_light(center + Vector3(0, 2.6, 0), Color(1.0, 0.55, 0.3), 3.5, 8.0)
	var fan := _prop(root, "ceilingFan.glb", center + Vector3(0, 3.1, 0), 0.0)
	if fan:
		fan.set_script(preload("res://scripts/world/spin_y.gd"))


func _dress_porta(root: Node3D) -> void:
	var center := ROOM_PORTA
	_prop(root, "doorwayOpen.glb", center + Vector3(0, 0, -4), 0.0, 1.3)
	_prop(root, "column.glb", center + Vector3(-4, 0, 3), 0.0)
	_prop(root, "column.glb", center + Vector3(4, 0, 3), 0.0)
	_prop(root, "barricade-doorway-a.glb", center + Vector3(-3, 0, -2), 10.0, 1.05)
	_prop(root, "barricade-doorway-a.glb", center + Vector3(3, 0, -1.5), -12.0, 1.0)
	_prop(root, "column.glb", center + Vector3(-4, 0, -3.5), 0.0)
	_prop(root, "column.glb", center + Vector3(4, 0, -3.5), 0.0)
	_prop(root, "trashcan.glb", center + Vector3(4.5, 0, 3.5), 20.0)
	_prop(root, "pottedPlant.glb", center + Vector3(-4.5, 0, 2.5), 35.0)
	_prop(root, "loungeSofa.glb", center + Vector3(0, 0, 3.5), 180.0)
	_emissive_box(center + Vector3(0, 0.08, 1.0), Vector3(2.0, 0.06, 2.0), Color(0.15, 0.08, 0.1), Color(0.9, 0.25, 0.4), 1.8)
	_add_room_light(center + Vector3(-2, 2.5, 0), Color(0.25, 0.7, 0.4), 5.0, 10.0)
	_add_room_light(center + Vector3(2, 2.5, 0), Color(1.0, 0.3, 0.45), 5.5, 10.0)


func _car(pos: Vector3, color: Color, rot_y: float) -> void:
	var body := Node3D.new()
	rooms_root.add_child(body)
	body.global_position = pos
	body.rotation_degrees.y = rot_y
	_box_local(body, Vector3(0, 0.35, 0), Vector3(1.8, 0.7, 4.2), color)
	_box_local(body, Vector3(0, 0.85, -0.2), Vector3(1.6, 0.55, 2.2), color.lightened(0.08))
	for xz in [Vector3(-0.85, 0.25, 1.3), Vector3(0.85, 0.25, 1.3), Vector3(-0.85, 0.25, -1.3), Vector3(0.85, 0.25, -1.3)]:
		_box_local(body, xz, Vector3(0.28, 0.5, 0.5), Color(0.1, 0.1, 0.1))


func _box_local(parent: Node3D, pos: Vector3, size: Vector3, color: Color) -> void:
	var mesh := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = size
	mesh.mesh = bm
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mesh.material_override = mat
	parent.add_child(mesh)
	mesh.position = pos


func _city(parent: Node3D, file_name: String, pos: Vector3, rot_y: float = 0.0, scale_u: float = 1.0) -> void:
	PropLibrary.instance_at(parent, PropLibrary.city(file_name), pos, rot_y, scale_u)


func _prop(parent: Node3D, file_name: String, pos: Vector3, rot_y: float = 0.0, scale_u: float = 1.0) -> Node3D:
	var n := PropLibrary.instance_at(parent, PropLibrary.prop(file_name), pos, rot_y, scale_u)
	return n as Node3D


func _add_room_light(pos: Vector3, color: Color, energy: float, omni_range: float = 14.0) -> void:
	var light := OmniLight3D.new()
	light.set_script(preload("res://scripts/world/light_flicker.gd"))
	light.light_color = color
	light.light_energy = energy
	light.omni_range = omni_range
	light.shadow_enabled = false
	rooms_root.add_child(light)
	light.global_position = pos


func _spawn_night_stars() -> void:
	var stars := Node3D.new()
	stars.name = "NightStars"
	stars.set_script(preload("res://scripts/world/star_field.gd"))
	rooms_root.add_child(stars)
	for i in 110:
		var star := MeshInstance3D.new()
		var sm := SphereMesh.new()
		sm.radius = randf_range(0.08, 0.22)
		sm.height = sm.radius * 2.0
		star.mesh = sm
		var mat := StandardMaterial3D.new()
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		mat.albedo_color = Color(0.85, 0.9, 1.0)
		mat.emission_enabled = true
		mat.emission = Color(0.8, 0.85, 1.0)
		mat.emission_energy_multiplier = randf_range(1.5, 3.5)
		star.material_override = mat
		stars.add_child(star)
		star.global_position = Vector3(
			randf_range(-70.0, 70.0),
			randf_range(28.0, 55.0),
			randf_range(-70.0, 70.0)
		)


func _spawn_dust_motes() -> void:
	var motes := Node3D.new()
	motes.name = "DustMotes"
	motes.set_script(preload("res://scripts/world/dust_motes.gd"))
	rooms_root.add_child(motes)


func _spawn(packed: PackedScene, pos: Vector3) -> void:
	_spawn_node(packed, pos)


func _spawn_enemy(
	packed: PackedScene,
	pos: Vector3,
	gltf: String,
	scale_u: float = 1.0,
	tint: Color = Color(1, 1, 1, 1)
) -> Node:
	var n := packed.instantiate()
	n.set("visual_gltf", gltf)
	n.set("visual_scale", scale_u)
	n.set("visual_tint", tint)
	spawns_root.add_child(n)
	n.global_position = pos
	return n


func _spawn_node(packed: PackedScene, pos: Vector3) -> Node:
	var n := packed.instantiate()
	spawns_root.add_child(n)
	n.global_position = pos
	return n


func _street_lamp(pos: Vector3) -> void:
	_box(pos + Vector3(0, 2.0, 0), Vector3(0.12, 4.0, 0.12), Color(0.25, 0.25, 0.28), true)
	_emissive_box(pos + Vector3(0, 4.15, 0), Vector3(0.55, 0.25, 0.55), Color(1.0, 0.9, 0.65), Color(1.0, 0.8, 0.4), 4.0)
	_add_room_light(pos + Vector3(0, 4.0, 0), Color(1.0, 0.85, 0.55), 7.0, 12.0)


func _way_sign(pos: Vector3, text: String, color: Color) -> void:
	_box(pos + Vector3(0, -0.6, 0), Vector3(0.12, 1.4, 0.12), Color(0.3, 0.3, 0.32), true)
	_box(pos, Vector3(1.8, 0.9, 0.08), Color(0.12, 0.12, 0.14), true)
	var lab := Label3D.new()
	lab.text = text
	lab.font_size = 36
	lab.modulate = color
	lab.outline_size = 8
	lab.outline_modulate = Color(0, 0, 0, 0.85)
	lab.position = pos + Vector3(0, 0, 0.08)
	rooms_root.add_child(lab)
	var light := OmniLight3D.new()
	light.set_script(preload("res://scripts/world/light_flicker.gd"))
	light.light_color = color
	light.light_energy = 0.85
	light.omni_range = 3.5
	light.position = pos + Vector3(0, 0.2, 0.3)
	rooms_root.add_child(light)


func _emissive_box(pos: Vector3, size: Vector3, albedo: Color, emission: Color, energy: float) -> void:
	var mesh := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = size
	mesh.mesh = bm
	var mat := StandardMaterial3D.new()
	mat.albedo_color = albedo
	mat.emission_enabled = true
	mat.emission = emission
	mat.emission_energy_multiplier = energy
	mesh.material_override = mat
	rooms_root.add_child(mesh)
	mesh.global_position = pos


func _make_boss_arena(center: Vector3, size: Vector3, boss: Node, boss_id: String, gaps: Array) -> void:
	var arena := Area3D.new()
	arena.set_script(BOSS_ARENA_SCRIPT)
	arena.name = "Arena_%s" % boss_id
	rooms_root.add_child(arena)
	arena.configure(center, size, boss, boss_id, gaps)


func _make_safezone(pos: Vector3, size: Vector3) -> void:
	var area := Area3D.new()
	area.collision_layer = 0
	area.collision_mask = 2
	area.monitoring = true
	area.set_script(SAFEZONE_SCRIPT)
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = size
	shape.shape = box
	area.add_child(shape)
	var mesh := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = size
	mesh.mesh = bm
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.35, 0.55, 0.4, 1)
	mesh.material_override = mat
	area.add_child(mesh)
	var lab := Label3D.new()
	lab.text = "SAFEZONE · ENTRADA"
	lab.font_size = 68
	lab.outline_size = 12
	lab.outline_modulate = Color(0, 0, 0, 0.85)
	lab.modulate = Color(0.55, 1.0, 0.7)
	lab.position = Vector3(0, 1.2, 0)
	area.add_child(lab)
	rooms_root.add_child(area)
	area.global_position = pos
	# Anéis emissivos (visual dual-ring)
	_emissive_box(pos + Vector3(0, 0.02, 0), Vector3(size.x + 0.6, 0.04, size.z + 0.6), Color(0.15, 0.35, 0.22), Color(0.35, 1.0, 0.55), 1.4)
	_emissive_box(pos + Vector3(0, 0.04, 0), Vector3(size.x - 1.2, 0.03, size.z - 1.0), Color(0.12, 0.28, 0.18), Color(0.55, 1.0, 0.7), 2.0)


func _build_room(center: Vector3, size: Vector3, color: Color, title: String) -> Array:
	_box(center + Vector3(0, 0.52, 0), Vector3(size.x - 1.0, 0.1, size.z - 1.0), color.darkened(0.12))
	var h := size.y
	var w := size.x
	var d := size.z
	var to_origin: Vector3 = -center
	to_origin.y = 0.0
	var open_dir := Vector3.FORWARD
	if to_origin.length_squared() > 0.01:
		open_dir = to_origin.normalized()
	_wall_with_door(center, Vector3(0, h * 0.5, -d * 0.5), Vector3(w, h, 0.4), color, open_dir, Vector3(0, 0, -1))
	_wall_with_door(center, Vector3(0, h * 0.5, d * 0.5), Vector3(w, h, 0.4), color, open_dir, Vector3(0, 0, 1))
	_wall_with_door(center, Vector3(-w * 0.5, h * 0.5, 0), Vector3(0.4, h, d), color, open_dir, Vector3(-1, 0, 0))
	_wall_with_door(center, Vector3(w * 0.5, h * 0.5, 0), Vector3(0.4, h, d), color, open_dir, Vector3(1, 0, 0))
	var lab := Label3D.new()
	lab.text = title
	lab.font_size = 56
	lab.modulate = color.lightened(0.25)
	lab.outline_size = 10
	lab.outline_modulate = Color(0, 0, 0, 0.85)
	rooms_root.add_child(lab)
	lab.global_position = center + Vector3(0, 3.2, 0)
	return _door_gaps(center, size)


func _door_gaps(center: Vector3, size: Vector3) -> Array:
	var gaps: Array = []
	var h := size.y
	var w := size.x
	var d := size.z
	var to_origin: Vector3 = -center
	to_origin.y = 0.0
	var open_dir := Vector3.FORWARD
	if to_origin.length_squared() > 0.01:
		open_dir = to_origin.normalized()
	var walls: Array = [
		{"off": Vector3(0, h * 0.5, -d * 0.5), "size": Vector3(w, h, 0.45), "out": Vector3(0, 0, -1)},
		{"off": Vector3(0, h * 0.5, d * 0.5), "size": Vector3(w, h, 0.45), "out": Vector3(0, 0, 1)},
		{"off": Vector3(-w * 0.5, h * 0.5, 0), "size": Vector3(0.45, h, d), "out": Vector3(-1, 0, 0)},
		{"off": Vector3(w * 0.5, h * 0.5, 0), "size": Vector3(0.45, h, d), "out": Vector3(1, 0, 0)},
	]
	for wall in walls:
		var wall_out: Vector3 = wall["out"]
		if wall_out.normalized().dot(open_dir) <= 0.55:
			continue
		var pos: Vector3 = center + wall["off"]
		var wsz: Vector3 = wall["size"]
		if absf(wsz.x) >= absf(wsz.z):
			gaps.append({"pos": pos, "size": Vector3(3.6, h, 0.55)})
		else:
			gaps.append({"pos": pos, "size": Vector3(0.55, h, 3.6)})
	return gaps


func _wall_with_door(center: Vector3, local_offset: Vector3, size: Vector3, color: Color, open_dir: Vector3, wall_out: Vector3) -> void:
	var facing_out := wall_out.normalized().dot(open_dir) > 0.55
	var pos := center + local_offset
	if not facing_out:
		_wall(pos, size, color)
		return
	if absf(size.x) >= absf(size.z):
		var half := (size.x - 3.5) * 0.5
		if half > 0.5:
			_wall(pos + Vector3(-(size.x - half) * 0.5, 0, 0), Vector3(half, size.y, size.z), color)
			_wall(pos + Vector3((size.x - half) * 0.5, 0, 0), Vector3(half, size.y, size.z), color)
	else:
		var halfz := (size.z - 3.5) * 0.5
		if halfz > 0.5:
			_wall(pos + Vector3(0, 0, -(size.z - halfz) * 0.5), Vector3(size.x, size.y, halfz), color)
			_wall(pos + Vector3(0, 0, (size.z - halfz) * 0.5), Vector3(size.x, size.y, halfz), color)


func _build_corridor(center: Vector3, size: Vector3) -> void:
	_box(center + Vector3(0, 0.51, 0), Vector3(size.x, 0.08, size.z), C_FLOOR_IN.darkened(0.05))
	if size.x > size.z:
		_wall(center + Vector3(0, size.y * 0.5, -size.z * 0.5), Vector3(size.x, size.y, 0.3), C_BEIGE)
		_wall(center + Vector3(0, size.y * 0.5, size.z * 0.5), Vector3(size.x, size.y, 0.3), C_BEIGE)
	else:
		_wall(center + Vector3(-size.x * 0.5, size.y * 0.5, 0), Vector3(0.3, size.y, size.z), C_BEIGE)
		_wall(center + Vector3(size.x * 0.5, size.y * 0.5, 0), Vector3(0.3, size.y, size.z), C_BEIGE)


func _wall(pos: Vector3, size: Vector3, color: Color) -> void:
	_box(pos, size, color, true)


func _glass(pos: Vector3, size: Vector3) -> void:
	var mesh := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = size
	mesh.mesh = bm
	var mat := StandardMaterial3D.new()
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.albedo_color = C_GLASS
	mat.roughness = 0.08
	mat.metallic = 0.15
	mesh.material_override = mat
	rooms_root.add_child(mesh)
	mesh.global_position = pos


func _box(pos: Vector3, size: Vector3, color: Color, collide: bool = false) -> void:
	if collide:
		var body := StaticBody3D.new()
		body.collision_layer = 1
		var col := CollisionShape3D.new()
		var shape := BoxShape3D.new()
		shape.size = size
		col.shape = shape
		body.add_child(col)
		var mesh := MeshInstance3D.new()
		var bm := BoxMesh.new()
		bm.size = size
		mesh.mesh = bm
		var mat := StandardMaterial3D.new()
		mat.albedo_color = color
		mesh.material_override = mat
		body.add_child(mesh)
		rooms_root.add_child(body)
		body.global_position = pos
	else:
		var mesh := MeshInstance3D.new()
		var bm := BoxMesh.new()
		bm.size = size
		mesh.mesh = bm
		var mat := StandardMaterial3D.new()
		mat.albedo_color = color
		mesh.material_override = mat
		rooms_root.add_child(mesh)
		mesh.global_position = pos
