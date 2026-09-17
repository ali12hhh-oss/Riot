extends Control
## CharacterSelectScreen
## شاشة بداية اللعبة: اختيار اللعب بشخصية Zade أو Nyra قبل الدخول للمدينة.

@onready var zade_button: Button = $CenterContainer/VBoxContainer/ZadeButton
@onready var nyra_button: Button = $CenterContainer/VBoxContainer/NyraButton
@onready var info_label: Label = $CenterContainer/VBoxContainer/InfoLabel

const MAIN_SCENE_PATH: String = "res://scenes/main.tscn"


func _ready() -> void:
	zade_button.pressed.connect(func(): _select_and_start("zade"))
	nyra_button.pressed.connect(func(): _select_and_start("nyra"))
	zade_button.mouse_entered.connect(func(): _show_info("zade"))
	nyra_button.mouse_entered.connect(func(): _show_info("nyra"))


func _show_info(character_id: String) -> void:
	var data: Dictionary = CharacterSelect.CHARACTERS[character_id]
	var text := "%s\n" % data["display_name"]
	if data["speed_multiplier"] != 1.0:
		text += "سرعة حركة: x%.2f\n" % data["speed_multiplier"]
	if data["health_bonus"] > 0.0:
		text += "صحة إضافية: +%d\n" % int(data["health_bonus"])
	if data["stealth_bonus"] > 0.0:
		text += "تخفّ إضافي: +%d%%\n" % int(data["stealth_bonus"] * 100)
	info_label.text = text


func _select_and_start(character_id: String) -> void:
	CharacterSelect.select_character(character_id)
	get_tree().change_scene_to_file(MAIN_SCENE_PATH)
