extends Node
## MainMenu
## قائمة رئيسية سينمائية: مشهد 3D حي بالخلفية (مدينة + سيارة رياضية) بكاميرا تدور ببطء.

const CHARACTER_SELECT_SCENE: String = "res://scenes/ui/character_select.tscn"
const SETTINGS_SCENE: PackedScene = preload("res://scenes/ui/settings_screen.tscn")

@onready var logo_label: Label = $UI/CenterContainer/VBoxContainer/LogoLabel
@onready var start_button: Button = $UI/CenterContainer/VBoxContainer/ButtonColumn/StartButton
@onready var settings_button: Button = $UI/CenterContainer/VBoxContainer/ButtonColumn/SettingsButton
@onready var quit_button: Button = $UI/CenterContainer/VBoxContainer/ButtonColumn/QuitButton

var _settings_instance: Control = null


func _ready() -> void:
	start_button.pressed.connect(_on_start_pressed)
	settings_button.pressed.connect(_on_settings_pressed)
	quit_button.pressed.connect(_on_quit_pressed)
	_play_logo_pulse()


func _play_logo_pulse() -> void:
	var tween := create_tween()
	tween.set_loops()
	tween.tween_property(logo_label, "modulate:a", 0.72, 1.6).set_trans(Tween.TRANS_SINE)
	tween.tween_property(logo_label, "modulate:a", 1.0, 1.6).set_trans(Tween.TRANS_SINE)


func _on_start_pressed() -> void:
	get_tree().change_scene_to_file(CHARACTER_SELECT_SCENE)


func _on_settings_pressed() -> void:
	if _settings_instance == null:
		_settings_instance = SETTINGS_SCENE.instantiate()
		add_child(_settings_instance)
	else:
		_settings_instance.visible = not _settings_instance.visible


func _on_quit_pressed() -> void:
	get_tree().quit()
