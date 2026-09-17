extends CharacterBody3D
## IslandNative
## من سكان الجزر (Solace Isle / Raven Isle) - نموذج بشري حقيقي
## بس بجلد مختلف يميزهم عن سكان المدينة، ويتجولوا بمنطقة الجزيرة بس.

const GRAVITY: float = 18.0
@export var walk_speed: float = 1.5
@export var wander_radius: float = 8.0

@onready var model_root: Node3D = $ModelRoot

var _home_position: Vector3
var _target_position: Vector3
var _anim_player: AnimationPlayer = null
var _wait_timer: float = 0.0

const MODEL_PATHS: Array[String] = [
	"res://assets/characters_v2/base/Superhero_Male_FullBody.gltf",
	"res://assets/characters_v2/base/Superhero_Female_FullBody.gltf",
]
const ANIM_LIBRARY_PATH: String = "res://assets/characters_v2/animations.glb"


func _ready() -> void:
	_home_position = global_position
	_pick_new_target()
	_load_model()


func _load_model() -> void:
	var model_path: String = MODEL_PATHS[randi() % MODEL_PATHS.size()]
	_anim_player = CharacterModelLoader.load_character(
		model_root, model_path, "", Color(0.6, 0.5, 0.3), ["idle", "run", "jump"], ANIM_LIBRARY_PATH
	)


func _pick_new_target() -> void:
	var offset := Vector3(randf_range(-wander_radius, wander_radius), 0, randf_range(-wander_radius, wander_radius))
	_target_position = _home_position + offset


func _physics_process(delta: float) -> void:
	var to_target: Vector3 = _target_position - global_position
	to_target.y = 0
	var distance: float = to_target.length()

	if distance < 0.6:
		_wait_timer -= delta
		velocity.x = 0
		velocity.z = 0
		_play_anim("idle")
		if _wait_timer <= 0.0:
			_wait_timer = randf_range(3.0, 6.0)
			_pick_new_target()
	else:
		var dir := to_target.normalized()
		velocity.x = dir.x * walk_speed
		velocity.z = dir.z * walk_speed
		look_at(global_position + dir, Vector3.UP)
		_play_anim("run")

	if not is_on_floor():
		velocity.y -= GRAVITY * delta
	else:
		velocity.y = 0.0

	move_and_slide()


func _play_anim(anim_name: String) -> void:
	if _anim_player and _anim_player.has_animation(anim_name):
		if _anim_player.current_animation != anim_name:
			_anim_player.play(anim_name)
