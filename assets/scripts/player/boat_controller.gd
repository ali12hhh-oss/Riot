extends RigidBody3D
## BoatController
## قارب يتحرك على سطح ماء مستوٍ (water_level) بدفع واقعي وتوجيه.

@export var water_level: float = 0.0
@export var max_thrust: float = 12.0
@export var turn_speed: float = 1.6
@export var wave_amplitude: float = 0.08
@export var wave_speed: float = 1.2

var touch_throttle: float = 0.0
var touch_steer: float = 0.0

var _time: float = 0.0


func _ready() -> void:
	gravity_scale = 0.0
	linear_damp = 1.2
	angular_damp = 3.0


func _physics_process(delta: float) -> void:
	_time += delta

	var throttle := touch_throttle
	var steer := touch_steer
	if Input.is_action_pressed("move_forward"):
		throttle = 1.0
	elif Input.is_action_pressed("move_back"):
		throttle = -1.0
	if Input.is_action_pressed("steer_left"):
		steer = -1.0
	elif Input.is_action_pressed("steer_right"):
		steer = 1.0

	var forward: Vector3 = -global_transform.basis.z
	apply_central_force(forward * throttle * max_thrust * mass)

	apply_torque(Vector3.UP * -steer * turn_speed * mass)

	var target_y: float = water_level + sin(_time * wave_speed) * wave_amplitude
	var pos: Vector3 = global_position
	pos.y = lerp(pos.y, target_y, 0.15)
	global_position = pos

	var wobble: float = sin(_time * wave_speed * 1.3) * 0.03
	rotation.z = lerp(rotation.z, wobble, 0.1)


func set_touch_input(throttle: float, steer: float, _handbrake: bool = false) -> void:
	touch_throttle = throttle
	touch_steer = steer
