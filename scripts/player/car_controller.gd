extends VehicleBody3D
## CarController
## تحكم واقعي بالسيارة باستخدام محرك الفيزياء المدمج بـ Godot (VehicleBody3D).

@export var max_engine_force: float = 150.0
@export var max_reverse_force: float = 60.0
@export var max_steer_angle: float = 0.6
@export var brake_force: float = 40.0
@export var exit_offset: Vector3 = Vector3(2.2, 0.0, 0.0)

var touch_throttle: float = 0.0
var touch_steer: float = 0.0
var touch_handbrake: bool = false

@onready var wheel_front_left: VehicleWheel3D = $WheelFrontLeft
@onready var wheel_front_right: VehicleWheel3D = $WheelFrontRight
@onready var wheel_back_left: VehicleWheel3D = $WheelBackLeft
@onready var wheel_back_right: VehicleWheel3D = $WheelBackRight
@onready var chase_camera: Camera3D = get_node_or_null("ChaseCamera")

var speed_kmh: float = 0.0
var is_player_driving: bool = false
var _driver: Node3D = null
var _previous_speed_kmh: float = 0.0


func _ready() -> void:
	add_to_group("vehicle")
	if chase_camera:
		chase_camera.current = false
	contact_monitor = true
	max_contacts_reported = 6
	body_entered.connect(_on_body_entered)


func _physics_process(delta: float) -> void:
	if not is_player_driving:
		engine_force = 0.0
		steering = 0.0
		brake = brake_force
		speed_kmh = linear_velocity.length() * 3.6
		return

	var throttle_input := touch_throttle
	var steer_input := touch_steer
	var handbrake_input := touch_handbrake

	if Input.is_action_pressed("move_forward"):
		throttle_input = 1.0
	elif Input.is_action_pressed("move_back"):
		throttle_input = -1.0

	if Input.is_action_pressed("steer_left"):
		steer_input = -1.0
	elif Input.is_action_pressed("steer_right"):
		steer_input = 1.0

	if Input.is_action_pressed("handbrake"):
		handbrake_input = true

	if Input.is_action_just_pressed("interact"):
		exit_vehicle()
		return

	if throttle_input > 0.0:
		engine_force = throttle_input * max_engine_force
		brake = 0.0
	elif throttle_input < 0.0:
		engine_force = throttle_input * max_reverse_force
		brake = 0.0
	else:
		engine_force = 0.0
		brake = brake_force * 0.1

	if handbrake_input:
		brake = brake_force

	var speed_factor: float = clamp(1.0 - (speed_kmh / 180.0), 0.3, 1.0)
	steering = -steer_input * max_steer_angle * speed_factor

	speed_kmh = linear_velocity.length() * 3.6
	_check_collision_shake()


func _check_collision_shake() -> void:
	var speed_drop: float = _previous_speed_kmh - speed_kmh
	if is_player_driving and speed_drop > 25.0 and chase_camera and chase_camera.has_method("add_trauma"):
		var trauma: float = clamp(speed_drop / 100.0, 0.0, 1.0)
		chase_camera.add_trauma(trauma)
	_previous_speed_kmh = speed_kmh


func _on_body_entered(body: Node) -> void:
	if not is_player_driving:
		return
	if body.is_in_group("pedestrians") and body.has_method("take_collision_damage"):
		body.take_collision_damage(speed_kmh, true)


func enter_vehicle(driver: Node3D) -> void:
	if is_player_driving:
		return
	is_player_driving = true
	_driver = driver

	if driver.has_method("set_hidden_for_driving"):
		driver.set_hidden_for_driving(true)

	if chase_camera:
		chase_camera.current = true

	GameManager.register_player(self)


func exit_vehicle() -> void:
	if not is_player_driving or _driver == null:
		return
	is_player_driving = false

	var exit_pos: Vector3 = global_position + global_transform.basis * exit_offset
	if _driver.has_method("set_hidden_for_driving"):
		_driver.set_hidden_for_driving(false, exit_pos)

	if chase_camera:
		chase_camera.current = false

	GameManager.register_player(_driver)
	_driver = null


func set_touch_input(throttle: float, steer: float, handbrake: bool) -> void:
	touch_throttle = throttle
	touch_steer = steer
	touch_handbrake = handbrake


func get_speed_kmh() -> float:
	return speed_kmh
