extends Control
## Visual layer for the mobile PUBG-style controls.

var joystick := Vector2.ZERO
var sprint := false
var visible_actions: Dictionary = {}
var car_mode := false

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_process(true)
	queue_redraw()

func _process(_delta: float) -> void:
	queue_redraw()

func _draw() -> void:
	var size := get_viewport_rect().size
	var center := Vector2(112.0, size.y - 118.0)
	var outer := 78.0
	draw_circle(center, outer, Color(0.04, 0.05, 0.07, 0.34))
	draw_arc(center, outer, 0.0, TAU, 48, Color(1,1,1,0.34), 2.0)
	var knob := center + joystick * 48.0
	draw_circle(knob, 34.0, Color(0.15,0.17,0.20,0.72))
	draw_arc(knob, 34.0, 0.0, TAU, 32, Color(1,1,1,0.45), 2.0)
	if sprint:
		draw_circle(center + Vector2(0,-102), 25.0, Color(0.95,0.75,0.15,0.85))
		draw_string(ThemeDB.fallback_font, center + Vector2(-15,-96), "RUN", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color.WHITE)

	var base := Vector2(size.x - 108.0, size.y - 108.0)
	var positions := {
		"fire": base + Vector2(-128,-72),
		"melee": base + Vector2(-58,-142),
		"crouch": base + Vector2(10,-74),
		"jump": base + Vector2(0,-155),
		"interact": base + Vector2(-205,-8),
		"sprint": center + Vector2(0,-102),
		"brake": base + Vector2(-126,8),
		"accelerate": base + Vector2(0,8),
		"exit": base + Vector2(-68,-212)
	}
	for key in visible_actions.keys():
		if not visible_actions[key]:
			continue
		if not positions.has(key):
			continue
		var p: Vector2 = positions[key]
		var radius := 34.0 if key not in ["fire","melee"] else 42.0
		draw_circle(p, radius, Color(0.05,0.06,0.08,0.62))
		draw_arc(p, radius, 0.0, TAU, 36, Color(1,1,1,0.5), 2.0)
		var label := str(key).to_upper()
		draw_string(ThemeDB.fallback_font, p + Vector2(-radius + 5, 5), label, HORIZONTAL_ALIGNMENT_CENTER, radius*2-10, 12, Color.WHITE)
