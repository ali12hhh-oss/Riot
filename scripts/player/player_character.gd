extends CharacterBody3D
## PlayerCharacter
## شخصية اللاعب سيراً على الأقدام، تدعم الركوب بالسيارات والتسلّل.

const GRAVITY: float = 18.0
@export var base_speed: float = 5.0
@export var enter_vehicle_range: float = 3.0

@onready var health: HealthComponent = $HealthComponent
@onready var weapon: WeaponBasic = $WeaponBasic
@onready var model_root: Node3D = $ModelRoot
@onready var collision_shape: CollisionShape3D = $CollisionShape3D
@onready var vehicle_detector: Area3D = $VehicleDetector
@onready var camera: Camera3D = get_node_or_null("FollowCamera")

var move_speed: float = 5.0
var stealth_bonus: float = 0.0
var _anim_player: AnimationPlayer = null
var _nearby_vehicles: Array = []
var _current_vehicle: Node = null
var _is_driving: bool = false
var is_crouching: bool = false
var _touch_move := Vector2.ZERO
var _touch_sprint := false

const CROUCH_SPEED_MULTIPLIER: float = 0.45
const CROUCH_STEALTH_BONUS: float = 0.35
const CROUCH_MODEL_SCALE: float = 0.6


func _ready() -> void:
	var data: Dictionary = CharacterSelect.get_selected_data()
	move_speed = base_speed * data.get("speed_multiplier", 1.0)
	health.max_health += data.get("health_bonus", 0.0)
	health.current_health = health.max_health
	stealth_bonus = data.get("stealth_bonus", 0.0)

	_load_character_model(data)
	_ensure_gameplay_camera()

	add_to_group("player")
	GameManager.register_player(self)
	WeaponSystem.weapon_equipped.connect(_on_weapon_equipped)
	_on_weapon_equipped(WeaponSystem.equipped_weapon)
	MedicalSystem.watch_player_health(health)

	if vehicle_detector:
		vehicle_detector.body_entered.connect(_on_vehicle_zone_entered)
		vehicle_detector.body_exited.connect(_on_vehicle_zone_exited)

	health.damaged.connect(_on_damaged)


func _on_damaged(amount: float, _source: Node) -> void:
	if camera and camera.has_method("add_trauma"):
		camera.add_trauma(clamp(amount / 40.0, 0.1, 0.8))


func _load_character_model(data: Dictionary) -> void:
	_anim_player = CharacterModelLoader.load_character(
		model_root,
		data.get("model_path", ""),
		data.get("skin_path", ""),
		data.get("model_color", Color.WHITE),
		["idle", "run", "jump"],
		"res://assets/characters_v2/animations.glb"
	)
	model_root.visible = true
	model_root.scale = Vector3.ONE

func _ensure_gameplay_camera() -> void:
	if camera == null:
		return
	camera.current = true
	camera.position = Vector3(0, 2.2, 4.8)
	camera.look_at(global_position + Vector3(0, 0.9, 0), Vector3.UP)


func _physics_process(delta: float) -> void:
	if _is_driving:
		_touch_move = Vector2.ZERO
		_touch_sprint = false
		return

	if Input.is_action_just_pressed("interact") and not _nearby_vehicles.is_empty():
		var vehicle = _nearby_vehicles[0]
		if vehicle.has_method("enter_vehicle"):
			vehicle.enter_vehicle(self)
			return

	if not health.is_alive():
		return

	if Input.is_action_just_pressed("crouch"):
		is_crouching = not is_crouching
		model_root.scale.y = CROUCH_MODEL_SCALE if is_crouching else 1.0

	var effective_speed: float = move_speed * (CROUCH_SPEED_MULTIPLIER if is_crouching else 1.0) * (1.65 if _touch_sprint and not is_crouching else 1.0)

	var input_dir := _touch_move
	if input_dir.length() <= 0.01:
		input_dir = Vector2(
			Input.get_action_strength("steer_right") - Input.get_action_strength("steer_left"),
			Input.get_action_strength("move_back") - Input.get_action_strength("move_forward")
		)
	var direction := Vector3(input_dir.x, 0, input_dir.y).normalized()

	if direction.length() > 0.01:
		velocity.x = direction.x * effective_speed
		velocity.z = direction.z * effective_speed
		look_at(global_position + direction, Vector3.UP)
		_play_animation("run")
	else:
		velocity.x = move_toward(velocity.x, 0, effective_speed)
		velocity.z = move_toward(velocity.z, 0, effective_speed)
		_play_animation("idle")

	if not is_on_floor():
		velocity.y -= GRAVITY * delta
	else:
		velocity.y = 0.0

	move_and_slide()


func set_touch_movement(value: Vector2) -> void:
	_touch_move = value.limit_length(1.0)

func set_touch_sprint(enabled: bool) -> void:
	_touch_sprint = enabled

func touch_fire() -> void:
	if not _is_driving and health.is_alive() and weapon:
		weapon.try_fire(self)

func has_interactable_vehicle() -> bool:
	return not _nearby_vehicles.is_empty()

func has_equipped_weapon() -> bool:
	return WeaponSystem.equipped_weapon != "fists" and WeaponSystem.owned_weapons.has(WeaponSystem.equipped_weapon)

func touch_interact() -> void:
	if _is_driving:
		return
	if not _nearby_vehicles.is_empty():
		var vehicle = _nearby_vehicles[0]
		if vehicle.has_method("enter_vehicle"):
			vehicle.enter_vehicle(self)

func touch_toggle_crouch() -> void:
	if _is_driving:
		return
	is_crouching = not is_crouching
	model_root.scale.y = CROUCH_MODEL_SCALE if is_crouching else 1.0

func _unhandled_input(event: InputEvent) -> void:
	if _is_driving:
		return
	if event.is_action_pressed("handbrake"):
		weapon.try_fire(self)


func set_hidden_for_driving(hide_it: bool, new_position: Vector3 = Vector3.ZERO) -> void:
	_is_driving = hide_it
	visible = not hide_it
	collision_shape.disabled = hide_it
	if camera:
		camera.current = not hide_it
	if not hide_it and new_position != Vector3.ZERO:
		global_position = new_position
		velocity = Vector3.ZERO


func _on_vehicle_zone_entered(body: Node) -> void:
	if body.is_in_group("vehicle") and not _nearby_vehicles.has(body):
		_nearby_vehicles.append(body)


func _on_vehicle_zone_exited(body: Node) -> void:
	_nearby_vehicles.erase(body)


func _play_animation(anim_name: String) -> void:
	if _anim_player and _anim_player.has_animation(anim_name):
		if _anim_player.current_animation != anim_name:
			_anim_player.play(anim_name)


func _on_weapon_equipped(_weapon_id: String) -> void:
	weapon.apply_stats(WeaponSystem.get_equipped_stats())


func get_total_stealth() -> float:
	return clamp(stealth_bonus + (CROUCH_STEALTH_BONUS if is_crouching else 0.0), 0.0, 0.85)
