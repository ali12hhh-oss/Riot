extends Node
## MainMenu
## شاشة رئيسية سينمائية: شخصيتان قابلتان للعب، مدينة وسيارات بالخلفية،
## وحركة كاميرا هادئة بأسلوب شاشات ألعاب الأكشن الحديثة.

const CHARACTER_SELECT_SCENE: String = "res://scenes/ui/character_select.tscn"
const SETTINGS_SCENE: PackedScene = preload("res://scenes/ui/settings_screen.tscn")

@onready var start_button: Button = $UI/RightPanel/PanelMargin/PanelVBox/StartButton
@onready var settings_button: Button = $UI/RightPanel/PanelMargin/PanelVBox/SettingsButton
@onready var quit_button: Button = $UI/RightPanel/PanelMargin/PanelVBox/QuitButton
@onready var zade_model: Node3D = $World3D/CharacterStage/ZadeModel
@onready var nyra_model: Node3D = $World3D/CharacterStage/NyraModel
@onready var title_label: Label = $UI/Brand/Title

var _settings_instance: Control = null
var _time: float = 0.0
var _zade_base_y: float = 0.0
var _nyra_base_y: float = 0.0

func _ready() -> void:
	start_button.pressed.connect(_on_start_pressed)
	settings_button.pressed.connect(_on_settings_pressed)
	quit_button.pressed.connect(_on_quit_pressed)
	_zade_base_y = zade_model.position.y
	_nyra_base_y = nyra_model.position.y
	_play_title_animation()

func _process(delta: float) -> void:
	_time += delta
	zade_model.position.y = _zade_base_y + sin(_time * 1.35) * 0.025
	nyra_model.position.y = _nyra_base_y + sin(_time * 1.35 + 0.8) * 0.025
	zade_model.rotation.y = sin(_time * 0.32) * 0.045
	nyra_model.rotation.y = -sin(_time * 0.32 + 0.4) * 0.045

func _play_title_animation() -> void:
	title_label.modulate.a = 0.0
	title_label.scale = Vector2(0.96, 0.96)
	var tween := create_tween().set_parallel(true)
	tween.tween_property(title_label, "modulate:a", 1.0, 0.75).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(title_label, "scale", Vector2.ONE, 0.75).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

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
