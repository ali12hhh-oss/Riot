extends Camera3D
## OrbitCamera
## كاميرا تدور ببطء حول نقطة مركزية.

@export var pivot: Vector3 = Vector3(0, 3, 0)
@export var radius: float = 22.0
@export var height: float = 9.0
@export var angular_speed: float = 0.06

var _angle: float = 0.0


func _process(delta: float) -> void:
	_angle += angular_speed * delta
	var pos := Vector3(cos(_angle) * radius, height, sin(_angle) * radius) + pivot
	global_position = pos
	look_at(pivot, Vector3.UP)
