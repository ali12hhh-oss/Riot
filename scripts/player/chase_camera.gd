extends Camera3D
## ChaseCamera
## كاميرا تتبع سينمائية: تتبع الهدف بسلاسة، تدوير حر، اهتزاز، وFOV ديناميكي.

@export var target_path: NodePath
@export var follow_distance: float = 5.0
@export var follow_height: float = 2.15
@export var smooth_speed: float = 6.0

@export var base_fov: float = 75.0
@export var max_fov: float = 90.0
@export var max_speed_for_fov: float = 150.0

@export var max_shake_offset: float = 0.4
@export var max_shake_rotation: float = 0.05
@export var shake_decay: float = 2.5

var _target: Node3D = null
var _orbit_yaw: float = 0.0
var _orbit_pitch: float = 0.0
var _dragging: bool = false
var _camera_touch_id: int = -1
var _trauma: float = 0.0
var _current_speed_kmh: float = 0.0


func _ready() -> void:
	if target_path != NodePath():
		_target = get_node(target_path)
	fov = base_fov


func _input(event: InputEvent) -> void:
	if not current:
		return

	if event is InputEventScreenTouch:
		var touch := event as InputEventScreenTouch
		if touch.pressed:
			if _camera_touch_id == -1 and _can_start_camera_touch(touch.position):
				_camera_touch_id = touch.index
				_dragging = true
		elif touch.index == _camera_touch_id:
			_camera_touch_id = -1
			_dragging = false

	elif event is InputEventScreenDrag:
		var drag := event as InputEventScreenDrag
		if _dragging and drag.index == _camera_touch_id:
			var rel: Vector2 = drag.relative
			_orbit_yaw -= rel.x * 0.005
			_orbit_pitch = clamp(_orbit_pitch - rel.y * 0.003, -0.5, 0.6)

	elif event is InputEventMouseButton:
		var mouse := event as InputEventMouseButton
		_dragging = mouse.pressed
	elif event is InputEventMouseMotion and _dragging:
		var rel: Vector2 = event.relative
		_orbit_yaw -= rel.x * 0.005
		_orbit_pitch = clamp(_orbit_pitch - rel.y * 0.003, -0.5, 0.6)


func _can_start_camera_touch(pos: Vector2) -> bool:
	var controls := get_tree().get_first_node_in_group("touch_controls")
	if controls and controls.has_method("is_camera_pan_position"):
		return controls.is_camera_pan_position(pos)
	return true

func _physics_process(delta: float) -> void:
	if _target == null:
		return

	var base_basis: Basis = _target.global_transform.basis
	var orbit_basis: Basis = base_basis.rotated(Vector3.UP, _orbit_yaw)
	var back_dir: Vector3 = orbit_basis.z.normalized()
	var height_offset: float = follow_height + sin(_orbit_pitch) * follow_distance

	var desired_pos: Vector3 = _target.global_position + back_dir * follow_distance * cos(_orbit_pitch) + Vector3.UP * height_offset
	global_position = global_position.lerp(desired_pos, 1.0 - exp(-smooth_speed * delta))
	look_at(_target.global_position + Vector3.UP * 0.8, Vector3.UP)

	if _target.has_method("get_speed_kmh"):
		_current_speed_kmh = _target.get_speed_kmh()
	var speed_ratio: float = clamp(_current_speed_kmh / max_speed_for_fov, 0.0, 1.0)
	fov = lerp(fov, lerp(base_fov, max_fov, speed_ratio), 1.0 - exp(-4.0 * delta))

	if _trauma > 0.0:
		_trauma = max(_trauma - shake_decay * delta, 0.0)
		var shake_amount: float = _trauma * _trauma
		var offset := Vector3(
			randf_range(-1.0, 1.0), randf_range(-1.0, 1.0), randf_range(-1.0, 1.0)
		) * max_shake_offset * shake_amount
		global_position += offset
		rotation.z = randf_range(-1.0, 1.0) * max_shake_rotation * shake_amount
	else:
		rotation.z = 0.0


func add_trauma(amount: float) -> void:
	_trauma = clamp(_trauma + amount, 0.0, 1.0)
