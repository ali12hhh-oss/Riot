extends VehicleBody3D
## TrafficCar
## سيارة NPC بتسوق تلقائياً بين نقاط مسار محددة (Waypoints) بسرعة ثابتة معقولة.

@export var waypoints: Array[Vector3] = []
@export var max_engine_force: float = 90.0
@export var max_steer_angle: float = 0.5
@export var arrival_distance: float = 4.0

var _current_index: int = 0


func _ready() -> void:
	contact_monitor = true
	max_contacts_reported = 6
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node) -> void:
	if body.is_in_group("pedestrians") and body.has_method("take_collision_damage"):
		body.take_collision_damage(linear_velocity.length() * 3.6, false)


func _physics_process(_delta: float) -> void:
	if waypoints.is_empty():
		return

	var target: Vector3 = waypoints[_current_index]
	var to_target: Vector3 = target - global_position
	to_target.y = 0

	if to_target.length() < arrival_distance:
		_current_index = (_current_index + 1) % waypoints.size()
		return

	var local_target: Vector3 = global_transform.basis.inverse() * to_target.normalized()
	steering = clamp(-local_target.x * 2.0, -1.0, 1.0) * max_steer_angle
	engine_force = max_engine_force
	brake = 0.0


func set_waypoints(points: Array[Vector3]) -> void:
	waypoints = points
	_current_index = 0
