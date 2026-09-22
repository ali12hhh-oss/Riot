extends CanvasLayer
## PUBG-style mobile controls: left virtual joystick, contextual right actions.
## Controls are generated at runtime so they remain usable on different phone sizes.

const JOYSTICK_RADIUS := 88.0
const JOYSTICK_DEADZONE := 0.12
const JOYSTICK_KNOB_LIMIT := 1.0

var _visual: Control
var _player: Node = null
var _car: Node = null
@export var car_path: NodePath
var _joystick_touch_id := -1
var _sprint_touch_id := -1
var _action_touches: Dictionary = {}
var _sprint_locked := false
var _last_size := Vector2.ZERO

func _ready() -> void:
	add_to_group("touch_controls")
	_visual = load("res://scripts/ui/mobile_controls_visual.gd").new()
	_visual.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_visual)
	_refresh_targets()
	_update_actions()
	set_process(true)

func _refresh_targets() -> void:
	_player = get_tree().get_first_node_in_group("player")
	if car_path != NodePath() and has_node(car_path):
		_car = get_node(car_path)
	else:
		_car = null
		for candidate in get_tree().get_nodes_in_group("vehicle"):
			if candidate.has_method("set_touch_input"):
				_car = candidate
				break

func _process(_delta: float) -> void:
	if _player == null or not is_instance_valid(_player):
		_refresh_targets()
	if _car == null or not is_instance_valid(_car):
		_refresh_targets()
	_update_actions()
	if _visual and _last_size != get_viewport().get_visible_rect().size:
		_last_size = get_viewport().get_visible_rect().size
		_visual.queue_redraw()

func _screen_size() -> Vector2:
	return get_viewport().get_visible_rect().size

func _joystick_center() -> Vector2:
	var s := _screen_size()
	return Vector2(112.0, s.y - 118.0)

func _right_base() -> Vector2:
	var s := _screen_size()
	return Vector2(s.x - 112.0, s.y - 112.0)

func _action_position(action: String) -> Vector2:
	var b := _right_base()
	var s := _screen_size()
	match action:
		"fire": return b + Vector2(-128,-72)
		"melee": return b + Vector2(-58,-142)
		"crouch": return b + Vector2(10,-74)
		"jump": return b + Vector2(0,-155)
		"interact": return b + Vector2(-205,-8)
		"brake": return b + Vector2(-126,8)
		"accelerate": return b + Vector2(0,8)
		"exit": return b + Vector2(-68,-212)
		"sprint": return _joystick_center() + Vector2(0,-102)
	return Vector2(s.x * 0.5, s.y * 0.5)

func _action_radius(action: String) -> float:
	return 44.0 if action in ["fire","melee"] else 38.0

func _update_actions() -> void:
	if _visual == null:
		return
	var car_mode := _car != null and is_instance_valid(_car) and bool(_car.get("is_player_driving"))
	var player_mode := _player != null and is_instance_valid(_player) and not car_mode
	var weapon: bool = player_mode and _player.has_method("has_equipped_weapon") and bool(_player.has_equipped_weapon())
	var interact: bool = player_mode and _player.has_method("has_interactable_vehicle") and bool(_player.has_interactable_vehicle())
	_visual.car_mode = car_mode
	_visual.visible_actions = {
		"fire": weapon,
		"melee": player_mode,
		"crouch": player_mode,
		"jump": false,
		"interact": interact,
		"sprint": player_mode,
		"brake": car_mode,
		"accelerate": car_mode,
		"exit": car_mode
	}
	_visual.queue_redraw()

func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		_handle_touch(event.index, event.position, event.pressed)
	elif event is InputEventScreenDrag:
		_handle_drag(event.index, event.position)

func _handle_touch(id: int, pos: Vector2, pressed: bool) -> void:
	if pressed:
		if _joystick_touch_id == -1 and pos.distance_to(_joystick_center()) <= JOYSTICK_RADIUS:
			_joystick_touch_id = id
			_set_joystick(pos)
			return
		if _hit_action("sprint", pos):
			if _sprint_locked:
				_sprint_locked = false
				_sprint_touch_id = -1
			else:
				_sprint_locked = true
				_sprint_touch_id = id
			_apply_sprint()
			return
		for action in ["fire","melee","crouch","interact","brake","accelerate","exit"]:
			if _hit_action(action, pos):
				_action_touches[id] = action
				_press_action(action)
				return
	else:
		if id == _joystick_touch_id:
			_joystick_touch_id = -1
			if _player and _player.has_method("set_touch_movement"):
				_player.set_touch_movement(Vector2.ZERO)
			_visual.joystick = Vector2.ZERO
		if _action_touches.has(id):
			var action: String = _action_touches[id]
			_action_touches.erase(id)
			_release_action(action)
		if id == _sprint_touch_id and not _sprint_locked:
			_sprint_touch_id = -1
			_apply_sprint()
		_visual.queue_redraw()

func _handle_drag(id: int, pos: Vector2) -> void:
	if id == _joystick_touch_id:
		_set_joystick(pos)

func _set_joystick(pos: Vector2) -> void:
	var delta := pos - _joystick_center()
	var value := delta / JOYSTICK_RADIUS
	if value.length() > JOYSTICK_KNOB_LIMIT:
		value = value.normalized()
	if value.length() < JOYSTICK_DEADZONE:
		value = Vector2.ZERO
	_visual.joystick = value
	# On foot: X/Y move the character. In a car: X steers and Y throttles.
	if _car != null and is_instance_valid(_car) and bool(_car.get("is_player_driving")):
		if _car.has_method("set_touch_input"):
			_car.set_touch_input(-value.y, value.x, false)
	else:
		var move := Vector2(value.x, -value.y)
		if _player and _player.has_method("set_touch_movement"):
			_player.set_touch_movement(move)

	# Pushing the stick past the forward ring automatically enables sprint.
	if value.y < -0.72 and value.length() > 0.72:
		_sprint_locked = true
	_apply_sprint()
	_visual.queue_redraw()

func _apply_sprint() -> void:
	var active := _sprint_locked or _sprint_touch_id != -1
	if _player and _player.has_method("set_touch_sprint"):
		_player.set_touch_sprint(active)
	_visual.sprint = active

func is_camera_pan_position(pos: Vector2) -> bool:
	var s := _screen_size()
	if pos.y >= s.y - 250.0:
		return false
	if pos.x <= 270.0 and pos.y >= s.y - 300.0:
		return false
	return true

func _hit_action(action: String, pos: Vector2) -> bool:
	if not _visual.visible_actions.get(action, false):
		return false
	return pos.distance_to(_action_position(action)) <= _action_radius(action)

func _press_action(action: String) -> void:
	if _player == null or not is_instance_valid(_player):
		return
	match action:
		"fire":
			if _player.has_method("touch_fire"):
				_player.touch_fire()
		"melee":
			# The current combat module exposes one fire hook; keep this button
			# separate so a dedicated melee system can be plugged in later.
			if _player.has_method("touch_fire"):
				_player.touch_fire()
		"crouch":
			if _player.has_method("touch_toggle_crouch"):
				_player.touch_toggle_crouch()
		"interact":
			if _player.has_method("touch_interact"):
				_player.touch_interact()
		"brake":
			if _car and _car.has_method("set_touch_input"):
				_car.set_touch_input(0.0, 0.0, true)
		"accelerate":
			if _car and _car.has_method("set_touch_input"):
				_car.set_touch_input(1.0, 0.0, false)
		"exit":
			if _car and _car.has_method("exit_vehicle"):
				_car.exit_vehicle()

func _release_action(action: String) -> void:
	if action in ["brake","accelerate"] and _car and _car.has_method("set_touch_input"):
		_car.set_touch_input(0.0, 0.0, false)
