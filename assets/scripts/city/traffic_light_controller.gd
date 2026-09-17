extends Node3D
## TrafficLightController
## إشارة مرور حقيقية بتتبدل بين أحمر/أصفر/أخضر بشكل دوري فعلي.

enum LightState { RED, YELLOW, GREEN }

@export var green_duration: float = 6.0
@export var yellow_duration: float = 1.5
@export var red_duration: float = 6.0
@export var phase_offset: float = 0.0

@onready var red_bulb: MeshInstance3D = $Housing/RedBulb
@onready var yellow_bulb: MeshInstance3D = $Housing/YellowBulb
@onready var green_bulb: MeshInstance3D = $Housing/GreenBulb

var current_state: LightState = LightState.RED
var _cycle_timer: float = 0.0
var _total_cycle: float = 0.0


func _ready() -> void:
	_total_cycle = green_duration + yellow_duration + red_duration
	_cycle_timer = fmod(phase_offset, _total_cycle)
	_update_state_from_timer()
	_apply_visual()


func _process(delta: float) -> void:
	_cycle_timer = fmod(_cycle_timer + delta, _total_cycle)
	var previous_state: LightState = current_state
	_update_state_from_timer()
	if current_state != previous_state:
		_apply_visual()


func _update_state_from_timer() -> void:
	if _cycle_timer < green_duration:
		current_state = LightState.GREEN
	elif _cycle_timer < green_duration + yellow_duration:
		current_state = LightState.YELLOW
	else:
		current_state = LightState.RED


func _apply_visual() -> void:
	if red_bulb:
		red_bulb.visible = current_state == LightState.RED
	if yellow_bulb:
		yellow_bulb.visible = current_state == LightState.YELLOW
	if green_bulb:
		green_bulb.visible = current_state == LightState.GREEN


func is_go() -> bool:
	return current_state == LightState.GREEN
