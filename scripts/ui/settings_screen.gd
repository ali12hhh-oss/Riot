extends Control
## SettingsScreen
## شاشة إعدادات كاملة: الصوت، تخصيص أزرار التحكم، سياسة الخصوصية، ومعلومات عن اللعبة.

@onready var tab_audio: Button = $Panel/VBoxContainer/Tabs/AudioTab
@onready var tab_controls: Button = $Panel/VBoxContainer/Tabs/ControlsTab
@onready var tab_privacy: Button = $Panel/VBoxContainer/Tabs/PrivacyTab
@onready var tab_about: Button = $Panel/VBoxContainer/Tabs/AboutTab

@onready var panel_audio: Control = $Panel/VBoxContainer/Content/AudioPanel
@onready var panel_controls: Control = $Panel/VBoxContainer/Content/ControlsPanel
@onready var panel_privacy: Control = $Panel/VBoxContainer/Content/PrivacyPanel
@onready var panel_about: Control = $Panel/VBoxContainer/Content/AboutPanel

@onready var volume_slider: HSlider = $Panel/VBoxContainer/Content/AudioPanel/VolumeSlider
@onready var mute_button: CheckButton = $Panel/VBoxContainer/Content/AudioPanel/MuteButton

@onready var edit_toggle_button: Button = $Panel/VBoxContainer/Content/ControlsPanel/EditToggleButton
@onready var reset_button: Button = $Panel/VBoxContainer/Content/ControlsPanel/ResetButton
@onready var controls_hint: Label = $Panel/VBoxContainer/Content/ControlsPanel/HintLabel

@onready var privacy_text: RichTextLabel = $Panel/VBoxContainer/Content/PrivacyPanel/PrivacyText

@onready var close_button: Button = $Panel/VBoxContainer/CloseButton

const PRIVACY_PATH: String = "res://assets/privacy_policy.txt"

var _touch_controls: Node = null


func _ready() -> void:
	tab_audio.pressed.connect(func(): _show_panel(panel_audio))
	tab_controls.pressed.connect(func(): _show_panel(panel_controls))
	tab_privacy.pressed.connect(func(): _show_panel(panel_privacy))
	tab_about.pressed.connect(func(): _show_panel(panel_about))
	close_button.pressed.connect(_on_close)

	volume_slider.value = AudioSettings.master_volume
	volume_slider.value_changed.connect(_on_volume_changed)
	mute_button.button_pressed = AudioSettings.muted
	mute_button.toggled.connect(_on_mute_toggled)

	edit_toggle_button.pressed.connect(_on_toggle_edit)
	reset_button.pressed.connect(_on_reset_layout)

	_load_privacy_text()
	_find_touch_controls()
	_update_controls_hint()
	_show_panel(panel_audio)


func _find_touch_controls() -> void:
	var nodes := get_tree().get_nodes_in_group("touch_controls")
	if not nodes.is_empty():
		_touch_controls = nodes[0]
	else:
		edit_toggle_button.disabled = true
		reset_button.disabled = true


func _show_panel(target: Control) -> void:
	panel_audio.visible = target == panel_audio
	panel_controls.visible = target == panel_controls
	panel_privacy.visible = target == panel_privacy
	panel_about.visible = target == panel_about


func _on_volume_changed(value: float) -> void:
	AudioSettings.master_volume = value
	AudioSettings.save_settings()


func _on_mute_toggled(pressed: bool) -> void:
	AudioSettings.muted = pressed
	AudioSettings.save_settings()


func _on_toggle_edit() -> void:
	if _touch_controls == null:
		return
	_touch_controls.set_edit_mode(not _touch_controls.edit_mode)
	_update_controls_hint()


func _on_reset_layout() -> void:
	if _touch_controls:
		_touch_controls.reset_layout()


func _update_controls_hint() -> void:
	if _touch_controls == null:
		controls_hint.text = "ادخل اللعبة أولاً عشان تقدر تعدّل مواضع أزرار التحكم"
		return
	if _touch_controls.edit_mode:
		edit_toggle_button.text = "إيقاف وضع التعديل"
		controls_hint.text = "اسحب أي زر لتحريكه، أو اضغط عليه ضغطة قصيرة لتحديده وتكبيره/تصغيره بزري ─ و﹣"
	else:
		edit_toggle_button.text = "تعديل مواضع الأزرار"
		controls_hint.text = "فعّل وضع التعديل عشان تسحب الأزرار لمكانها المفضل"


func _load_privacy_text() -> void:
	if ResourceLoader.exists(PRIVACY_PATH) or FileAccess.file_exists(PRIVACY_PATH):
		var file := FileAccess.open(PRIVACY_PATH, FileAccess.READ)
		if file:
			privacy_text.text = file.get_as_text()
			file.close()


func _on_close() -> void:
	if _touch_controls and _touch_controls.edit_mode:
		_touch_controls.set_edit_mode(false)
		_touch_controls.save_layout()
	hide()
