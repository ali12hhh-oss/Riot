extends Control
## Minimap
## خريطة صغيرة أعلى الشاشة: نقطة اللاعب بالمنتصف دايماً، هدف المهمة الحالية.

@export var player_path: NodePath
@export var map_range: float = 120.0

@onready var _player: Node3D = null


func _ready() -> void:
	if player_path != NodePath():
		_player = get_node(player_path)
	set_process(true)


func _process(_delta: float) -> void:
	if _player == null:
		_player = GameManager.player_ref
	queue_redraw()


func _draw() -> void:
	var size: Vector2 = get_rect().size
	var center: Vector2 = size / 2.0
	var radius: float = min(size.x, size.y) / 2.0 - 4.0

	draw_circle(center, radius, Color(0.05, 0.05, 0.07, 0.75))
	draw_arc(center, radius, 0, TAU, 48, Color(1, 0.42, 0.24, 0.8), 2.0)

	if _player == null:
		return

	draw_circle(center, 5.0, Color.WHITE)

	if MissionManager.active and MissionManager.current_mission.has("target_position"):
		var target: Vector3 = MissionManager.current_mission["target_position"]
		var rel: Vector2 = Vector2(target.x - _player.global_position.x, target.z - _player.global_position.z)
		_draw_blip(center, radius, rel, Color(1.0, 0.85, 0.2))

	for node in get_tree().get_nodes_in_group("police_units"):
		if not is_instance_valid(node):
			continue
		var rel_p: Vector2 = Vector2(
			node.global_position.x - _player.global_position.x,
			node.global_position.z - _player.global_position.z
		)
		_draw_blip(center, radius, rel_p, Color(0.3, 0.55, 1.0))


func _draw_blip(center: Vector2, radius: float, rel: Vector2, color: Color) -> void:
	var scaled: Vector2 = rel / map_range * radius
	if scaled.length() > radius:
		scaled = scaled.normalized() * radius
	draw_circle(center + scaled, 4.0, color)
