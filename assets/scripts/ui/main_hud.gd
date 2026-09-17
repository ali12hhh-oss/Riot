extends CanvasLayer
## MainHUD
## يعرض النقود، عنوان المهمة الحالية، والوقت المتبقي إن وجد.

const SETTINGS_SCENE: PackedScene = preload("res://scenes/ui/settings_screen.tscn")
const STORE_SCENE: PackedScene = preload("res://scenes/ui/store_screen.tscn")

@onready var money_label: Label = $MoneyLabel
@onready var mission_label: Label = $MissionLabel
@onready var timer_label: Label = $TimerLabel
@onready var settings_button: Button = $SettingsButton
@onready var store_button: Button = $StoreButton

var _settings_instance: Control = null
var _store_instance: Control = null


func _ready() -> void:
	GameManager.money_changed.connect(_on_money_changed)
	MissionManager.objective_updated.connect(_on_objective_updated)
	MissionManager.mission_completed.connect(_on_mission_completed)
	MissionManager.mission_failed.connect(_on_mission_failed)
	settings_button.pressed.connect(_toggle_settings)
	store_button.pressed.connect(_toggle_store)
	_on_money_changed(GameManager.player_money)
	mission_label.text = ""
	timer_label.text = ""
	MissionManager.start_mission_by_index(0)


func _toggle_settings() -> void:
	if _settings_instance == null:
		_settings_instance = SETTINGS_SCENE.instantiate()
		add_child(_settings_instance)
	else:
		_settings_instance.visible = not _settings_instance.visible


func _toggle_store() -> void:
	if _store_instance == null:
		_store_instance = STORE_SCENE.instantiate()
		add_child(_store_instance)
	else:
		_store_instance.visible = not _store_instance.visible


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
