extends Node
## AudioSettings
## يدير مستوى الصوت العام للعبة (Master Bus) ويحفظه محلياً على الجهاز.
## جاهز للتوسعة لاحقاً بقنوات منفصلة (موسيقى/مؤثرات) لما تنضاف الملفات الصوتية.

const SETTINGS_PATH: String = "user://audio_settings.cfg"

var master_volume: float = 0.8:
	set(value):
		master_volume = clamp(value, 0.0, 1.0)
		_apply_master_volume()

var muted: bool = false:
	set(value):
		muted = value
		_apply_master_volume()


func _ready() -> void:
	load_settings()
	_apply_master_volume()


func _apply_master_volume() -> void:
	var bus_index: int = AudioServer.get_bus_index("Master")
	if bus_index == -1:
		return
	AudioServer.set_bus_mute(bus_index, muted)
	var db: float = linear_to_db(master_volume) if master_volume > 0.0 else -80.0
	AudioServer.set_bus_volume_db(bus_index, db)


func save_settings() -> void:
	var config := ConfigFile.new()
	config.set_value("audio", "master_volume", master_volume)
	config.set_value("audio", "muted", muted)
	config.save(SETTINGS_PATH)


func load_settings() -> void:
	var config := ConfigFile.new()
	if config.load(SETTINGS_PATH) == OK:
		master_volume = config.get_value("audio", "master_volume", 0.8)
		muted = config.get_value("audio", "muted", false)
