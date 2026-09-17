extends CharacterBody3D
## GangMember
## عدو أرضي بسيط: يكتشف Zade إذا اقترب، يلاحقه، ويطلق النار إذا وصل مدى السلاح.

@export var move_speed: float = 4.0
@export var detection_radius: float = 20.0
@export var attack_range: float = 15.0

@onready var health: HealthComponent = $HealthComponent
@onready var weapon: WeaponBasic = $WeaponBasic
@onready var model_root: Node3D = $ModelRoot

const MODEL_PATH: String = "res://assets/characters_v2/base/Superhero_Male_FullBody.gltf"
const ANIM_LIBRARY_PATH: String = "res://assets/characters_v2/animations.glb"

var target: Node3D = null
var _anim_player: AnimationPlayer = null


func _ready() -> void:
	health.died.connect(_on_died)
	target = GameManager.player_ref
	_load_model()
	var difficulty: float = MissionManager.get_current_difficulty_scale()
	move_speed *= difficulty
	health.max_health *= difficulty
	weapon.damage *= difficulty


func _load_model() -> void:
	_anim_player = CharacterModelLoader.load_character(
		model_root, MODEL_PATH, "", Color(0.55, 0.1, 0.1), ["idle", "run", "jump"], ANIM_LIBRARY_PATH
	)


func _play_anim(anim_name: String) -> void:
	if _anim_player and _anim_player.has_animation(anim_name):
		if _anim_player.current_animation != anim_name:
			_anim_player.play(anim_name)


func _physics_process(_delta: float) -> void:
	target = GameManager.player_ref
	if target == null:
		return
	if not health.is_alive():
		return

	var to_target: Vector3 = target.global_position - global_position
	var distance: float = to_target.length()

	var effective_detection: float = detection_radius
	if target.has_method("get_total_stealth"):
		effective_detection *= (1.0 - target.get_total_stealth())

	if distance <= effective_detection:
		look_at(target.global_position, Vector3.UP)
		if distance > attack_range:
			velocity = to_target.normalized() * move_speed
			_play_anim("run")
		else:
			velocity = Vector3.ZERO
			weapon.try_fire(self)
			_play_anim("idle")
	else:
		velocity = Vector3.ZERO
		_play_anim("idle")

	move_and_slide()


func _on_died() -> void:
	set_physics_process(false)
	GameManager.add_money(50)
	queue_free()
