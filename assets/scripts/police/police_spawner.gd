extends Node3D
## PoliceSpawner
## يستمع لإشارة WantedSystem ويولّد سيارات شرطة حقيقية بالمشهد حوالين اللاعب.

const POLICE_SCENE: PackedScene = preload("res://scenes/cars/police_car.tscn")
const SPAWN_DISTANCE: float = 25.0

var _active_units: Array[Node3D] = []


func _ready() -> void:
	WantedSystem.police_should_spawn.connect(_on_police_should_spawn)
	WantedSystem.wanted_level_changed.connect(_on_wanted_level_changed)


func _on_police_should_spawn(count: int, difficulty: float) -> void:
	var needed: int = count - _active_units.size()
	for i in range(max(needed, 0)):
		_spawn_unit(difficulty)


func _on_wanted_level_changed(stars: int) -> void:
	if stars == 0:
		for unit in _active_units:
			if is_instance_valid(unit):
				unit.queue_free()
		_active_units.clear()


func _spawn_unit(difficulty: float) -> void:
	if GameManager.player_ref == null:
		return
	var unit := POLICE_SCENE.instantiate()
	add_child(unit)
	unit.add_to_group("police_units")
	var angle: float = randf() * TAU
	var offset := Vector3(cos(angle), 0, sin(angle)) * SPAWN_DISTANCE
	unit.global_position = GameManager.player_ref.global_position + offset + Vector3.UP * 1.0
	if unit.has_method("set_difficulty"):
		unit.set_difficulty(difficulty)
	_active_units.append(unit)
