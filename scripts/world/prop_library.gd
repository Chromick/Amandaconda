extends RefCounted
class_name PropLibrary
## Carrega GLB/GLTF de `assets/props` e `assets/characters` (Kenney / Quaternius CC0).

const PROPS := "res://assets/props/"
const CHARS := "res://assets/characters/"

static func load_scene(path: String) -> PackedScene:
	if not ResourceLoader.exists(path):
		push_warning("PropLibrary: missing %s" % path)
		return null
	return load(path) as PackedScene


static func prop(name: String) -> PackedScene:
	return load_scene(PROPS + name)


static func city(name: String) -> PackedScene:
	return load_scene(PROPS + "city/" + name)


static func character(name: String) -> PackedScene:
	return load_scene(CHARS + name)


static func instance_at(
	parent: Node3D,
	packed: PackedScene,
	pos: Vector3,
	rot_y_deg: float = 0.0,
	scale_uniform: float = 1.0
) -> Node3D:
	if packed == null:
		return null
	var n := packed.instantiate() as Node3D
	if n == null:
		return null
	parent.add_child(n)
	n.global_position = pos
	n.rotation_degrees.y = rot_y_deg
	if not is_equal_approx(scale_uniform, 1.0):
		n.scale = Vector3.ONE * scale_uniform
	return n
