extends StaticBody3D
## AreaGate
## جدار غير مرئي يمنع الدخول لمنطقة معينة (صحراء/ميناء/غابة) لحد ما اللاعب
## يوصل لعدد مهام مطلوب. لما يتحقق الشرط، البوابة بتختفي وتفتح المنطقة نهائياً.

@export var required_missions_completed: int = 5
@export var zone_name: String = "منطقة جديدة"

signal zone_unlocked(zone_name: String)


func _ready() -> void:
	if MissionManager.completed_count >= required_missions_completed:
		_unlock()
		return
	MissionManager.chapter_advanced.connect(_on_chapter_advanced)


func _on_chapter_advanced(completed_count: int) -> void:
	if completed_count >= required_missions_completed:
		_unlock()


func _unlock() -> void:
	zone_unlocked.emit(zone_name)
	queue_free()
