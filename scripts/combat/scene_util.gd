extends RefCounted
## Helpers seguros para anexar nós ao mundo em runtime.


static func host(from: Node = null) -> Node:
	if from != null and is_instance_valid(from):
		var tree := from.get_tree()
		if tree != null:
			if tree.current_scene != null:
				return tree.current_scene
			if tree.root != null:
				return tree.root
	return null


static func add_to_world(node: Node, from: Node, global_pos: Vector3) -> bool:
	var h := host(from)
	if h == null or node == null:
		if node != null and is_instance_valid(node):
			node.free()
		return false
	h.add_child(node)
	if node is Node3D:
		(node as Node3D).global_position = global_pos
	return true
