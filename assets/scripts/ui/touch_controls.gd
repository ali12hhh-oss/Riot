extends CanvasLayer
## TouchControls
## أزرار تحكم لمسية للموبايل.

@export var car_path: NodePath

const LAYOUT_PATH: String = "user://control_layout.cfg"
const MIN_SCALE: float = 0.5
const MAX_SCALE: float = 2.0
const DRAG_THRESHOLD: float = 6.0

const DEFAULT_POSITIONS: Dictionary = {
	"ThrottleButton": Vector2(1050, 500),
	"BrakeButton": Vector2(870, 560),
	"HandbrakeButton": Vector2(1050, 350),
	"LeftButton": Vector2(80, 560),
	"RightButton": Vector2(220, 560),
	"InteractButton": Vector2(1050, 200),
	"CrouchButton": Vector2(920, 200),
}
const BASE_RADIUS: Dictionary = {
	"ThrottleButton": 70.0, "BrakeButton": 55.0, "HandbrakeButton": 45.0,
	"LeftButton": 60.0, "RightButton": 60.0, "InteractButton": 50.0, "CrouchButton": 45.0,
}

var _car: Node = null
var _steer_left_pressed := false
var _steer_right_pressed := false
var _throttle_pressed := false
var _brake_pressed := false
var _handbrake_pressed := false

var _buttons: Dictionary = {}
var _button_scale: Dictionary = {}
var edit_mode: bool = false
var _dragging_button: TouchScreenButton = null
var _drag_start_pos: Vector2 = Vector2.ZERO
var _has_dragged: bool = false
var _selected_button_name: String = ""

var _resize_overlay: Control = null
var _resize_label: Label = null


func _ready() -> void:
	if car_path != NodePath():
		_car = get_node(car_path)
	add_to_group("touch_controls")
	var saved: Dictionary = _load_layout()
	_build_ui(saved["positions"])
	_button_scale = saved["scales"]
	for key in _buttons.keys():
		_apply_scale(key)
	_build_resize_overlay()


func _load_layout() -> Dictionary:
	var config := ConfigFile.new()
	var positions: Dictionary = DEFAULT_POSITIONS.duplicate()
	var scales: Dictionary = {}
	for key in DEFAULT_POSITIONS.keys():
		scales[key] = 1.0
	if config.load(LAYOUT_PATH) == OK:
		for key in DEFAULT_POSITIONS.keys():
			if config.has_section_key("layout", key):
				positions[key] = config.get_value("layout", key)
			if config.has_section_key("scale", key):
				scales[key] = config.get_value("scale", key)
	return {"positions": positions, "scales": scales}


func save_layout() -> void:
	var config := ConfigFile.new()
	for key in _buttons.keys():
		config.set_value("layout", key, _buttons[key].position)
		config.set_value("scale", key, _button_scale.get(key, 1.0))
	config.save(LAYOUT_PATH)


func reset_layout() -> void:
	for key in _buttons.keys():
		_buttons[key].position = DEFAULT_POSITIONS[key]
		_button_scale[key] = 1.0
		_apply_scale(key)
	_selected_button_name = ""
	_update_resize_overlay()
	save_layout()


func set_edit_mode(enabled: bool) -> void:
	edit_mode = enabled
	_dragging_button = null
	_selected_button_name = ""
	_update_resize_overlay()


func _apply_scale(btn_name: String) -> void:
	var btn: TouchScreenButton = _buttons[btn_name]
	var scale: float = _button_scale.get(btn_name, 1.0)
	var circle := CircleShape2D.new()
	circle.radius = BASE_RADIUS[btn_name] * scale
	btn.shape = circle


func _build_ui(positions: Dictionary) -> void:
	_add_button("ThrottleButton", positions, func(): _throttle_pressed = true, func(): _throttle_pressed = false)
	_add_button("BrakeButton", positions, func(): _brake_pressed = true, func(): _brake_pressed = false)
	_add_button("HandbrakeButton", positions, func(): _handbrake_pressed = true, func(): _handbrake_pressed = false)
	_add_button("LeftButton", positions, func(): _steer_left_pressed = true, func(): _steer_left_pressed = false)
	_add_button("RightButton", positions, func(): _steer_right_pressed = true, func(): _steer_right_pressed = false)

	var interact_btn := TouchScreenButton.new()
	interact_btn.name = "InteractButton"
	interact_btn.position = positions["InteractButton"]
	interact_btn.action = "interact"
	add_child(interact_btn)
	_buttons["InteractButton"] = interact_btn

	var crouch_btn := TouchScreenButton.new()
	crouch_btn.name = "CrouchButton"
	crouch_btn.position = positions["CrouchButton"]
	crouch_btn.action = "crouch"
	add_child(crouch_btn)
	_buttons["CrouchButton"] = crouch_btn


func _add_button(btn_name: String, positions: Dictionary, on_press: Callable, on_release: Callable) -> void:
	var btn := TouchScreenButton.new()
	btn.name = btn_name
	btn.position = positions[btn_name]
	add_child(btn)
	btn.pressed.connect(on_press)
	btn.released.connect(on_release)
	_buttons[btn_name] = btn


func _build_resize_overlay() -> void:
	_resize_overlay = Control.new()
	_resize_overlay.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	_resize_overlay.position = Vector2(-100, -160)
	_resize_overlay.visible = false
	add_child(_resize_overlay)

	var box := HBoxContainer.new()
	box.add_theme_constant_override("separation", 10)
	_resize_overlay.add_child(box)

	var minus_btn := Button.new()
	minus_btn.text = "－"
	minus_btn.custom_minimum_size = Vector2(50, 50)
	minus_btn.pressed.connect(func(): _resize_selected(-0.1))
	box.add_child(minus_btn)

	_resize_label = Label.new()
	_resize_label.custom_minimum_size = Vector2(90, 50)
	_resize_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_resize_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	box.add_child(_resize_label)

	var plus_btn := Button.new()
	plus_btn.text = "＋"
	plus_btn.custom_minimum_size = Vector2(50, 50)
	plus_btn.pressed.connect(func(): _resize_selected(0.1))
	box.add_child(plus_btn)


func _resize_selected(delta: float) -> void:
	if _selected_button_name == "":
		return
	var new_scale: float = clamp(_button_scale.get(_selected_button_name, 1.0) + delta, MIN_SCALE, MAX_SCALE)
	_button_scale[_selected_button_name] = new_scale
	_apply_scale(_selected_button_name)
	_update_resize_overlay()
	save_layout()


func _update_resize_overlay() -> void:
	if _resize_overlay == null:
		return
	_resize_overlay.visible = edit_mode and _selected_button_name != ""
	if _resize_overlay.visible:
		_resize_label.text = "الحجم %d%%" % int(_button_scale.get(_selected_button_name, 1.0) * 100)


func _input(event: InputEvent) -> void:
	if not edit_mode:
		return

	if event is InputEventScreenTouch or event is InputEventMouseButton:
		var pos: Vector2 = event.position
		var pressed: bool = event.pressed if event is InputEventScreenTouch else (event as InputEventMouseButton).pressed
		if pressed:
			_drag_start_pos = pos
			_has_dragged = false
			for key in _buttons.keys():
				var btn: TouchScreenButton = _buttons[key]
				var radius: float = BASE_RADIUS[key] * _button_scale.get(key, 1.0)
				if pos.distance_to(btn.position) <= radius:
					_dragging_button = btn
					break
		else:
			if _dragging_button:
				if _has_dragged:
					save_layout()
				else:
					_selected_button_name = _dragging_button.name
					_update_resize_overlay()
			_dragging_button = null
		get_viewport().set_input_as_handled()

	elif (event is InputEventScreenDrag or event is InputEventMouseMotion) and _dragging_button:
		if event.position.distance_to(_drag_start_pos) > DRAG_THRESHOLD:
			_has_dragged = true
			_dragging_button.position = event.position
			if _selected_button_name != "":
				_selected_button_name = ""
				_update_resize_overlay()
		get_viewport().set_input_as_handled()


func _process(_delta: float) -> void:
	if edit_mode or _car == null:
		return
	var throttle := 0.0
	if _throttle_pressed:
		throttle = 1.0
	elif _brake_pressed:
		throttle = -1.0

	var steer := 0.0
	if _steer_left_pressed:
		steer = -1.0
	elif _steer_right_pressed:
		steer = 1.0

	if _car.has_method("set_touch_input"):
		_car.set_touch_input(throttle, steer, _handbrake_pressed)
