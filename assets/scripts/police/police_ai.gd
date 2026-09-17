extends VehicleBody3D
## PoliceAI
## سيارة شرطة تطارد هدف (اللاعب) تلقائياً.

@export var max_engine_force: float = 140.0
@export var max_steer_angle: float = 0.55
@export var detection_radius: float = 35.0
@export var difficulty: float = 1.0

@onready var _wheels: Array[VehicleWheel3D] = [
	$WheelFrontLeft, $WheelFrontRight, $WheelBackLeft, $WheelBackRight
]

var target: Node3D = null
var _has_spotted_target: bool = false


func _ready() -> void:
	target = GameManager.player_ref
	if WantedSystem:
		WantedSystem.player_escaped.connect(_on_player_escaped)
	contact_monitor = true
	max_contacts_reported = 6
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node) -> void:
	if body.is_in_group("pedestrians") and body.has_method("take_collision_damage"):
		body.take_collision_damage(linear_velocity.length() * 3.6, false)


func _physics_process(_delta: float) -> void:
	target = GameManager.player_ref
	if target == null:
		return

	var to_target: Vector3 = target.global_position - global_position
	var distance: float = to_target.length()

	var effective_detection: float = detection_radius
	if target.has_method("get_total_stealth"):
		effective_detection *= (1.0 - target.get_total_stealth())

	var in_range: bool = distance <= effective_detection
	if in_range and not _has_spotted_target:
		_has_spotted_target = true
		WantedSystem.set_player_spotted(true)
	elif not in_range and _has_spotted_target:
		_has_spotted_target = false
		WantedSystem.set_player_spotted(false)

	var local_target: Vector3 = global_transform.basis.inverse() * to_target.normalized()
	var steer_dir: float = clamp(-local_target.x * 2.0, -1.0, 1.0)
	steering = steer_dir * max_steer_angle

	engine_force = max_engine_force * difficulty
	brake = 0.0


func _on_player_escaped() -> void:
	pass


func set_difficulty(value: float) -> void:
	difficulty = value
