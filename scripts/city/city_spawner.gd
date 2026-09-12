extends Node3D
## CitySpawner
## يوزّع مشاة وسيارات حركة مرورية تلقائياً حوالين نقاط محددة بالمدينة،
## عشان يصير فيه إحساس مدينة حية بدل شوارع فاضية.

const PEDESTRIAN_SCENE: PackedScene = preload("res://scenes/city/pedestrian_npc.tscn")
const TRAFFIC_CAR_SCENE: PackedScene = preload("res://scenes/city/traffic_car.tscn")

@export var pedestrian_spawn_points: Array[Vector3] = [
	Vector3(6, 1, 6), Vector3(-6, 1, -6), Vector3(18, 1, -18),
	Vector3(-18, 1, 18), Vector3(3, 1, -25), Vector3(-25, 1, 3),
]

@export var traffic_loop: Array[Vector3] = [
	Vector3(30, 0.5, 0), Vector3(0, 0.5, 30),
	Vector3(-30, 0.5, 0), Vector3(0, 0.5, -30),
]

@export var traffic_car_count: int = 4


func _ready() -> void:
	for point in pedestrian_spawn_points:
		_spawn_pedestrian(point)

	for i in range(traffic_car_count):
		_spawn_traffic_car(i)


func _spawn_pedestrian(point: Vector3) -> void:
	var npc := PEDESTRIAN_SCENE.instantiate()
	add_child(npc)
	npc.global_position = point


func _spawn_traffic_car(index: int) -> void:
	if traffic_loop.is_empty():
		return
	var car := TRAFFIC_CAR_SCENE.instantiate()
	add_child(car)
	var start_index: int = index % traffic_loop.size()
	car.global_position = traffic_loop[start_index] + Vector3.UP
	if car.has_method("set_waypoints"):
		car.set_waypoints(traffic_loop)
