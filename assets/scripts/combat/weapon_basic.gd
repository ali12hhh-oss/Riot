extends Node3D
class_name WeaponBasic
## WeaponBasic
## سلاح مبسّط بنظام Raycast.

signal fired
signal hit_target(target: Node, damage: float)

@export var damage: float = 18.0
@export var range_meters: float = 40.0
@export var fire_cooldown: float = 0.25

var _cooldown_timer: float = 0.0


func apply_stats(stats: Dictionary) -> void:
	damage = stats.get("damage", damage)
	range_meters = stats.get("range", range_meters)
	fire_cooldown = stats.get("fire_cooldown", fire_cooldown)


func _process(delta: float) -> void:
	if _cooldown_timer > 0.0:
		_cooldown_timer -= delta


func try_fire(from_node: Node3D) -> void:
	if _cooldown_timer > 0.0:
		return
	_cooldown_timer = fire_cooldown
	fired.emit()

	var space_state := from_node.get_world_3d().direct_space_state
	var origin: Vector3 = global_position
	var forward: Vector3 = -global_transform.basis.z
	var target_point: Vector3 = origin + forward * range_meters

	var query := PhysicsRayQueryParameters3D.create(origin, target_point)
	query.exclude = [from_node]
	var result := space_state.intersect_ray(query)

	if result:
		var collider = result.get("collider")
		if collider and collider.has_node("HealthComponent"):
			var health: HealthComponent = collider.get_node("HealthComponent")
			health.take_damage(damage, from_node)
			hit_target.emit(collider, damage)
