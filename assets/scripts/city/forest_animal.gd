extends CharacterBody3D
## ForestAnimal
## حيوان بري حقيقي (ذيب/ثعلب/طائر) يتجول بمنطقة الغابة عشوائياً، وبيهرب لو
## اقترب اللاعب منه كتير - إحساس حياة برية واقعية بدل غابة فاضية.

const GRAVITY: float = 18.0
@export var model_path: String = ""
@export var wander_speed: float = 2.0
@export var flee_speed: float = 6.0
@export var wander_radius: float = 15.0
@export var flee_trigger_radius: float = 8.0
@export var model_scale: float = 1.0

@onready var model_root: Node3D = $ModelRoot

var _home_position: Vector3
var _target_position: Vector3
var _wait_timer: float = 0.0
var _fleeing: bool = false


func _ready() -> void:
	_home_position = global_position
	_pick_new_target()
	if model_path != "" and ResourceLoader.exists(model_path):
		var scene: PackedScene = load(model_path)
		if scene:
			var instance := scene.instantiate()
			instance.scale = Vector3.ONE * model_scale
			model_root.add_child(instance)


func _pick_new_target() -> void:
	var offset := Vector3(randf_range(-wander_radius, wander_radius), 0, randf_range(-wander_radius, wander_radius))
	_target_position = _home_position + offset


func _physics_process(delta: float) -> void:
	var player: Node3D = GameManager.player_ref
	if player and global_position.distance_to(player.global_position) < flee_trigger_radius:
		_fleeing = true
		_target_position = global_position + (global_position - player.global_position).normalized() * 10.0
	elif _fleeing:
		_fleeing = false
		_pick_new_target()

	var to_target: Vector3 = _target_position - global_position
	to_target.y = 0
	var distance: float = to_target.length()

	if distance < 1.0 and not _fleeing:
		_wait_timer -= delta
		velocity.x = 0
		velocity.z = 0
		if _wait_timer <= 0.0:
			_wait_timer = randf_range(3.0, 7.0)
			_pick_new_target()
	else:
		var dir := to_target.normalized()
		var speed: float = flee_speed if _fleeing else wander_speed
		velocity.x = dir.x * speed
		velocity.z = dir.z * speed
		if dir.length() > 0.01:
			look_at(global_position + dir, Vector3.UP)

	if not is_on_floor():
		velocity.y -= GRAVITY * delta
	else:
		velocity.y = 0.0

	move_and_slide()
