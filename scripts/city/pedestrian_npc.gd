extends CharacterBody3D
## PedestrianNPC
## مواطن عادي يمشي بالشارع بشكل عشوائي (Wander) بنموذج بشري حقيقي وجلد عشوائي.
## بيبتعد عن اللاعب إذا صار فيه إطلاق نار قريب (إحساس واقعي بمدينة حية).
## بيتضرر فعلياً لو صدمته سيارة بسرعة (نظام تصادم حقيقي) - وهذا بيسجّل جريمة
## على اللاعب لو كان هو السائق (دهس = جريمة حقيقية بأسلوب GTA).

const GRAVITY: float = 18.0
@export var walk_speed: float = 1.8
@export var wander_radius: float = 12.0
@export var flee_radius: float = 10.0

@onready var model_root: Node3D = $ModelRoot
@onready var health: HealthComponent = $HealthComponent

var _home_position: Vector3
var _target_position: Vector3
var _anim_player: AnimationPlayer = null
var _fleeing: bool = false
var _wait_timer: float = 0.0
var _respawn_timer: float = 0.0
var _is_down: bool = false

const MODEL_PATHS: Array[String] = [
	"res://assets/characters_v2/base/Superhero_Male_FullBody.gltf",
	"res://assets/characters_v2/base/Superhero_Female_FullBody.gltf",
]
const ANIM_LIBRARY_PATH: String = "res://assets/characters_v2/animations.glb"


func _ready() -> void:
	_home_position = global_position
	_pick_new_target()
	_load_model()
	add_to_group("pedestrians")
	health.died.connect(_on_hit_down)


func _load_model() -> void:
	var model_path: String = MODEL_PATHS[randi() % MODEL_PATHS.size()]
	_anim_player = CharacterModelLoader.load_character(
		model_root, model_path, "", Color(0.5, 0.5, 0.5), ["idle", "run", "jump"], ANIM_LIBRARY_PATH
	)


func _apply_skin(node: Node, tex: Texture2D) -> void:
	if node is MeshInstance3D:
		var mat := StandardMaterial3D.new()
		mat.albedo_texture = tex
		node.material_override = mat
	for c in node.get_children():
		_apply_skin(c, tex)


func _find_anim_player(node: Node) -> AnimationPlayer:
	if node is AnimationPlayer:
		return node
	for c in node.get_children():
		var r := _find_anim_player(c)
		if r:
			return r
	return null


func _pick_new_target() -> void:
	var offset := Vector3(
		randf_range(-wander_radius, wander_radius), 0,
		randf_range(-wander_radius, wander_radius)
	)
	_target_position = _home_position + offset


func _physics_process(delta: float) -> void:
	if _is_down:
		_respawn_timer -= delta
		if _respawn_timer <= 0.0:
			_respawn()
		return

	var player: Node3D = GameManager.player_ref
	if player and global_position.distance_to(player.global_position) < flee_radius and WantedSystem.stars > 0:
		_fleeing = true
		_target_position = global_position + (global_position - player.global_position).normalized() * 8.0
	elif _fleeing:
		_fleeing = false
		_pick_new_target()

	var to_target: Vector3 = _target_position - global_position
	to_target.y = 0
	var distance: float = to_target.length()

	if distance < 0.6:
		_wait_timer -= delta
		velocity.x = 0
		velocity.z = 0
		_play_anim("idle")
		if _wait_timer <= 0.0:
			_wait_timer = randf_range(2.0, 5.0)
			_pick_new_target()
	else:
		var dir := to_target.normalized()
		var speed: float = walk_speed * (2.2 if _fleeing else 1.0)
		velocity.x = dir.x * speed
		velocity.z = dir.z * speed
		look_at(global_position + dir, Vector3.UP)
		_play_anim("run")

	if not is_on_floor():
		velocity.y -= GRAVITY * delta
	else:
		velocity.y = 0.0

	move_and_slide()


func take_collision_damage(impact_speed_kmh: float, was_player: bool) -> void:
	if _is_down:
		return
	var damage: float = clamp(impact_speed_kmh * 0.8, 0.0, 150.0)
	health.take_damage(damage)
	if was_player and impact_speed_kmh > 15.0:
		WantedSystem.add_crime(2)


func _on_hit_down() -> void:
	_is_down = true
	_respawn_timer = randf_range(8.0, 14.0)
	model_root.rotation.x = deg_to_rad(-90)
	velocity = Vector3.ZERO


func _respawn() -> void:
	_is_down = false
	model_root.rotation.x = 0.0
	health.heal(health.max_health)
	global_position = _home_position
	_pick_new_target()


func _play_anim(anim_name: String) -> void:
	if _anim_player and _anim_player.has_animation(anim_name):
		if _anim_player.current_animation != anim_name:
			_anim_player.play(anim_name)
