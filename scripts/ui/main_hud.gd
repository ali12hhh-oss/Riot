extends CanvasLayer
## MainHUD
## HUD gameplay only: money, current objective, mission timer and minimap.
## Store/settings stay in the main-menu flow and are not shown during gameplay.

@onready var money_label: Label = $MoneyLabel
@onready var mission_label: Label = $MissionLabel
@onready var timer_label: Label = $TimerLabel

func _ready() -> void:
	GameManager.money_changed.connect(_on_money_changed)
	MissionManager.objective_updated.connect(_on_objective_updated)
	MissionManager.mission_completed.connect(_on_mission_completed)
	MissionManager.mission_failed.connect(_on_mission_failed)
	_on_money_changed(GameManager.player_money)
	mission_label.text = ""
	timer_label.text = ""
	MissionManager.start_mission_by_index(0)

func _process(_delta: float) -> void:
	if MissionManager.active:
		var t: float = MissionManager.get_time_left()
		timer_label.text = "%02d:%02d" % [int(t) / 60, int(t) % 60]
	else:
		timer_label.text = ""

func _on_money_changed(amount: int) -> void:
	money_label.text = "💰 %d$" % amount

func _on_objective_updated(text: String) -> void:
	mission_label.text = text

func _on_mission_completed(mission: Dictionary) -> void:
	mission_label.text = "✅ أنجزت: %s" % mission.get("title", "")

func _on_mission_failed(mission: Dictionary) -> void:
	mission_label.text = "❌ فشلت: %s" % mission.get("title", "")
