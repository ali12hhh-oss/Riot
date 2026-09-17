extends Node3D
## SeaFish
## سمكة حقيقية تسبح بحرية بمنطقة البحر - حركة عائمة بسيطة تحت سطح الماء
## بمسار دائري عشوائي، عشان يصير فيه إحساس حياة بحرية حقيقية.

@export var model_path: String = ""
@export var swim_speed: float = 1.5
@export var swim_radius: float = 12.0
@export var depth: float = -2.0
@export var model_scale: float = 1.0

var _center: Vector3
var _angle: float = 0.0
var _vertical_offset: float = 0.0


func _ready() -> void:
	_center = global_position
	_angle = randf_range(0, TAU)
	_vertical_offset = randf_range(-0.5, 0.5)

	if model_path != "" and ResourceLoader.exists(model_path):
		var scene: PackedScene = load(model_path)
		if scene:
			var instance := scene.instantiate()
			instance.scale = Vector3.ONE * model_scale
			add_child(instance)


func _process(delta: float) -> void:
	_angle += (swim_speed / swim_radius) * delta
	var offset := Vector3(cos(_angle) * swim_radius, depth + sin(_angle * 0.5) * _vertical_offset, sin(_angle) * swim_radius)
	global_position = _center + offset
	look_at(global_position + Vector3(-sin(_angle), 0, cos(_angle)), Vector3.UP)
