extends RigidBody3D
## BoatController
## تحكم قارب مبسّط: يطفو على مستوى ثابت (Y=0)، يتقدم للأمام بقوة محرك ويلتف بدفة.
## يدعم لوحة المفاتيح (نفس مفاتيح السيارة) والتحكم اللمسي مستقبلاً بنفس أسلوب car_controller.

@export var engine_power: float = 12.0
@export var turn_power: float = 1.6
@export var float_height: float = 0.3
@export var float_strength: float = 8.0

var touch_throttle: float = 0.0
var touch_steer: float = 0.0


func _physics_process(_delta: float) -> void:
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

	var height_error: float = float_height - global_position.y
	apply_central_force(Vector3.UP * height_error * float_strength * mass)

	var forward: Vector3 = -global_transform.basis.z
	apply_central_force(forward * throttle * engine_power * mass)

	apply_torque(Vector3.UP * -steer * turn_power * mass)


func set_touch_input(throttle: float, steer: float) -> void:
	touch_throttle = throttle
	touch_steer = steer
