extends Node3D
## MissionEnemySpawner
## يستمع لبداية كل مهمة، وإذا كانت مهمة قتالية (ELIMINATE_TARGETS) وفيها
## enemy_count > 0، بيولّد هالعدد بالضبط من أعداء العصابات حوالين موقع المهمة.

const GANG_MEMBER_SCENE: PackedScene = preload("res://scenes/combat/gang_member.tscn")
const SPAWN_RADIUS: float = 15.0

var _active_enemies: Array = []
var _tracking_mission: bool = false


func _ready() -> void:
	MissionManager.mission_started.connect(_on_mission_started)
	MissionManager.mission_completed.connect(_on_mission_ended)
	MissionManager.mission_failed.connect(_on_mission_ended)


func _on_mission_started(mission: Dictionary) -> void:
	_clear_enemies()

	var enemy_count: int = mission.get("enemy_count", 0)
	var is_combat_mission: bool = mission.get("type") == MissionManager.ObjectiveType.ELIMINATE_TARGETS
	if not is_combat_mission or enemy_count <= 0:
		_tracking_mission = false
		return

	var center: Vector3 = mission.get("target_position", Vector3.ZERO)
	_tracking_mission = true

	for i in range(enemy_count):
		var angle: float = (TAU / enemy_count) * i + randf_range(-0.3, 0.3)
		var radius: float = randf_range(SPAWN_RADIUS * 0.5, SPAWN_RADIUS)
		var offset := Vector3(cos(angle) * radius, 1.0, sin(angle) * radius)
		_spawn_enemy(center + offset)


func _spawn_enemy(spawn_pos: Vector3) -> void:
	var enemy := GANG_MEMBER_SCENE.instantiate()
	get_tree().current_scene.add_child(enemy)
	enemy.global_position = spawn_pos
	enemy.tree_exiting.connect(_on_enemy_died.bind(enemy), CONNECT_ONE_SHOT)
	_active_enemies.append(enemy)


func _on_enemy_died(enemy: Node) -> void:
	_active_enemies.erase(enemy)
	if _tracking_mission and _active_enemies.is_empty():
		_tracking_mission = false
		MissionManager.complete_current_mission()


func _on_mission_ended(_mission: Dictionary) -> void:
	_tracking_mission = false
	_clear_enemies()


func _clear_enemies() -> void:
	for enemy in _active_enemies.duplicate():
		if is_instance_valid(enemy):
			enemy.queue_free()
	_active_enemies.clear()
