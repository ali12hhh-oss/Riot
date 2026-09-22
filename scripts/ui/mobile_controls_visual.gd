extends Control
## Professional mobile control visuals.
## Input hit areas remain in touch_controls.gd; this script only draws the UI.

var joystick := Vector2.ZERO
var sprint := false
var visible_actions: Dictionary = {}
var car_mode := false

const ACCENT := Color(1.0, 0.42, 0.24, 0.92)
const WHITE := Color(1, 1, 1, 0.94)
const PANEL := Color(0.035, 0.045, 0.065, 0.78)
const PANEL_SOFT := Color(0.06, 0.07, 0.09, 0.56)

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_process(true)
	queue_redraw()

func _process(_delta: float) -> void:
	queue_redraw()

func _draw() -> void:
	var size := get_viewport_rect().size
	var center := Vector2(112.0, size.y - 118.0)
	_draw_joystick(center)
	_draw_sprint(center + Vector2(0, -102), sprint)

	var base := Vector2(size.x - 112.0, size.y - 112.0)
	var positions := {
		"fire": base + Vector2(0, 0),
		"melee": base + Vector2(-96, 56),
		"crouch": base + Vector2(-86, -92),
		"jump": base + Vector2(-8, -152),
		"interact": base + Vector2(-198, -12),
		"sprint": center + Vector2(0, -102),
		"brake": base + Vector2(-94, 4),
		"accelerate": base + Vector2(0, 4),
		"exit": base + Vector2(-44, -148)
	}
	for key in visible_actions.keys():
		if not visible_actions[key] or key == "sprint":
			continue
		if not positions.has(key):
			continue
		var radius := 48.0 if key == "fire" else (45.0 if key == "melee" else 40.0)
		_draw_action(positions[key], radius, str(key))

func _draw_joystick(center: Vector2) -> void:
	# Shadow + outer ring + inner ring give the stick a layered gamepad look.
	draw_circle(center + Vector2(0, 5), 88.0, Color(0, 0, 0, 0.30))
	draw_circle(center, 84.0, PANEL)
	draw_arc(center, 84.0, 0.0, TAU, 72, Color(1, 1, 1, 0.28), 2.0, true)
	draw_arc(center, 72.0, 0.0, TAU, 72, Color(1, 1, 1, 0.10), 1.0, true)

	var knob := center + joystick * 48.0
	draw_circle(knob + Vector2(0, 3), 33.0, Color(0, 0, 0, 0.28))
	draw_circle(knob, 31.0, Color(0.12, 0.14, 0.18, 0.92))
	draw_arc(knob, 31.0, 0.0, TAU, 48, Color(1, 1, 1, 0.52), 2.0, true)
	draw_circle(knob, 5.0, ACCENT)

func _draw_sprint(center: Vector2, active: bool) -> void:
	var fill := ACCENT if active else PANEL_SOFT
	draw_circle(center + Vector2(0, 3), 31.0, Color(0, 0, 0, 0.28))
	draw_circle(center, 29.0, fill)
	draw_arc(center, 29.0, 0.0, TAU, 48, Color(1, 1, 1, 0.50), 2.0, true)
	_draw_icon(center, "⚡", 22)

func _draw_action(center: Vector2, radius: float, action: String) -> void:
	draw_circle(center + Vector2(0, 3), radius + 1.0, Color(0, 0, 0, 0.26))
	draw_circle(center, radius, PANEL)
	draw_arc(center, radius, 0.0, TAU, 56, Color(1, 1, 1, 0.42), 2.0, true)
	draw_arc(center, radius - 5.0, -2.7, -0.4, 28, ACCENT, 2.5, true)
	_draw_icon(center, _icon_for(action), 22)

func _icon_for(action: String) -> String:
	match action:
		"fire": return "•"
		"melee": return "✦"
		"crouch": return "⌄"
		"jump": return "↑"
		"interact": return "↗"
		"brake": return "■"
		"accelerate": return "▲"
		"exit": return "↩"
	return "·"

func _draw_icon(center: Vector2, icon: String, font_size: int) -> void:
	var font := ThemeDB.fallback_font
	font.draw_string(self.get_canvas_item(), center + Vector2(-18, 8), icon, HORIZONTAL_ALIGNMENT_CENTER, 36, font_size, WHITE)
