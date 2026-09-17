extends Area3D
## MetroStation
## محطة بمنظومة "The Underline" - لما اللاعب يدخل منطقة المحطة، بعد تأكيد بسيط
## بينتقل لمحطة الوصول المحددة. نظام سفر سريع وظيفي فعلي (مو مجرد ديكور).

@export var station_name: String = "محطة"
@export var destination_path: NodePath
@export var travel_delay: float = 1.5

var _player_inside: bool = false
var _travel_timer: float = 0.0
var _destination: Node3D = null


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	if destination_path != NodePath():
		_destination = get_node(destination_path)


func _on_body_entered(body: Node3D) -> void:
	if body == GameManager.player_ref:
		_player_inside = true
		_travel_timer = 0.0


func _on_body_exited(body: Node3D) -> void:
	if body == GameManager.player_ref:
		_player_inside = false


func _process(delta: float) -> void:
	if not _player_inside or _destination == null:
		return
	_travel_timer += delta
	if _travel_timer >= travel_delay:
		_travel_player()


func _travel_player() -> void:
	var player: Node3D = GameManager.player_ref
	if player == null:
		return
	player.global_position = _destination.global_position + Vector3.UP * 1.0
	if player.has_method("set") and "velocity" in player:
		player.velocity = Vector3.ZERO
	_player_inside = false
	_travel_timer = 0.0
