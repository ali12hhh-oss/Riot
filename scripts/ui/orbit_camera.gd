extends Camera3D
## OrbitCamera
## حركة كاميرا سينمائية ناعمة ذهاباً وإياباً حول الشخصيتين،
## بدلاً من دوران كامل سريع يشتت الانتباه.

@export var pivot: Vector3 = Vector3(0, 1.05, 0)
@export var radius: float = 7.4
@export var height: float = 3.0
@export var base_angle: float = 0.0
@export var swing_angle: float = 0.58
@export var angular_speed: float = 0.16
@export var look_height: float = 1.0
@export var camera_bob: float = 0.07
@export var camera_bob_speed: float = 0.42
@export var lens_fov: float = 52.0

var _time: float = 0.0

func _ready() -> void:
	fov = lens_fov
	current = true

func _process(delta: float) -> void:
	_time += delta
	var angle := base_angle + sin(_time * angular_speed) * swing_angle
	var bob := sin(_time * camera_bob_speed) * camera_bob
	var pos := Vector3(cos(angle) * radius, height + bob, sin(angle) * radius) + pivot
	global_position = pos
	look_at(pivot + Vector3(0, look_height, 0), Vector3.UP)
