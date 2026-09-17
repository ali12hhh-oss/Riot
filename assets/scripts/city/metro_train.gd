extends Node3D
## MetroTrain
## قطار حقيقي (نموذج Quaternius) يتحرك فعلياً بين نقاط محطات "The Underline"
## بسرعة ثابتة، ويتوقف لحظات عند كل محطة قبل ما يكمل.

@export var station_points: Array[Vector3] = []
@export var travel_speed: float = 8.0
@export var stop_duration: float = 3.0

var _current_index: int = 0
var _waiting_timer: float = 0.0
var _is_waiting: bool = false


func _physics_process(delta: float) -> void:
	if station_points.size() < 2:
		return

	if _is_waiting:
		_waiting_timer -= delta
		if _waiting_timer <= 0.0:
			_is_waiting = false
			_current_index = (_current_index + 1) % station_points.size()
		return

	var target: Vector3 = station_points[_current_index]
	var to_target: Vector3 = target - global_position
	var distance: float = to_target.length()

	if distance < 1.0:
		_is_waiting = true
		_waiting_timer = stop_duration
		return

	var direction: Vector3 = to_target.normalized()
	global_position += direction * travel_speed * delta
	look_at(global_position + direction, Vector3.UP)
