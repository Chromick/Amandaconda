extends CharacterBody3D
## Boneco de treino — hit react, popup de dano, revida.

signal health_changed(current: float, maximum: float)

const POPUP_SCENE := preload("res://scenes/damage_popup.tscn")
const SceneUtil := preload("res://scripts/combat/scene_util.gd")

@onready var mesh: MeshInstance3D = $Mesh
@onready var label: Label3D = $Label3D

var health: float = 200.0
var max_health: float = 200.0
var _revive_timer: float = -1.0
var _flash_timer: float = 0.0
var _stagger_timer: float = 0.0
var _base_scale: Vector3 = Vector3.ONE


func _ready() -> void:
	add_to_group("lockable")
	add_to_group("enemy")
	_base_scale = scale
	Balance.reloaded.connect(_apply_balance)
	_apply_balance()


func _apply_balance() -> void:
	var b: Dictionary = Balance.data.get("boneco", {})
	max_health = float(b.get("vida", 200))
	if health > 0.0:
		health = max_health
	_update_label()
	health_changed.emit(health, max_health)


func _process(delta: float) -> void:
	if _flash_timer > 0.0:
		_flash_timer -= delta
		if _flash_timer <= 0.0 and health > 0.0:
			_set_color(Color(0.75, 0.55, 0.35))
	if _stagger_timer > 0.0:
		_stagger_timer -= delta
		var t := clampf(_stagger_timer / 0.18, 0.0, 1.0)
		scale = _base_scale.lerp(_base_scale * Vector3(1.08, 0.92, 1.08), t)
		if _stagger_timer <= 0.0:
			scale = _base_scale
	if _revive_timer >= 0.0:
		_revive_timer -= delta
		if _revive_timer <= 0.0:
			_revive()


func take_damage(amount: float, knockback: Vector3 = Vector3.ZERO, _source: Node = null) -> void:
	if health <= 0.0:
		return
	health = maxf(0.0, health - amount)
	health_changed.emit(health, max_health)
	_flash_timer = 0.14
	_stagger_timer = 0.18
	_set_color(Color(1.0, 0.25, 0.2))
	velocity += knockback
	_spawn_popup(amount)
	_update_label()
	if health <= 0.0:
		var b: Dictionary = Balance.data.get("boneco", {})
		if bool(b.get("revida", true)):
			_revive_timer = float(b.get("renascer_em", 2.0))
		_set_color(Color(0.25, 0.25, 0.28))
		label.text = "KO"


func _spawn_popup(amount: float) -> void:
	var pop := POPUP_SCENE.instantiate()
	pop.amount = amount
	pop.color = Color(1.0, 0.9, 0.35) if amount < 30.0 else Color(1.0, 0.45, 0.2)
	var pos := global_position + Vector3(randf_range(-0.2, 0.2), 2.0, randf_range(-0.2, 0.2))
	SceneUtil.add_to_world(pop, self, pos)


func _revive() -> void:
	health = max_health
	_revive_timer = -1.0
	scale = _base_scale
	_set_color(Color(0.75, 0.55, 0.35))
	_update_label()
	health_changed.emit(health, max_health)


func _update_label() -> void:
	label.text = "Boneco %d/%d" % [int(health), int(max_health)]


func _set_color(c: Color) -> void:
	var mat := mesh.material_override as StandardMaterial3D
	if mat == null:
		mat = StandardMaterial3D.new()
		mesh.material_override = mat
	mat.albedo_color = c


func _physics_process(delta: float) -> void:
	velocity.x = move_toward(velocity.x, 0.0, 14.0 * delta)
	velocity.z = move_toward(velocity.z, 0.0, 14.0 * delta)
	if not is_on_floor():
		velocity.y -= 20.0 * delta
	move_and_slide()
