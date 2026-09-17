extends Node
## MissionManager
## نظام مهام متسلسل بأسلوب GTA: كل مهمة بتفتح التالية، والصعوبة (وقت أقل/أعداء أكتر)
## بتزيد تدريجياً. إكمال كل مهمة بيفحص فتح أسلحة جديدة عبر WeaponSystem.

signal mission_started(mission: Dictionary)
signal mission_completed(mission: Dictionary)
signal mission_failed(mission: Dictionary)
signal objective_updated(text: String)
signal chapter_advanced(chapter_index: int)

enum ObjectiveType { REACH_LOCATION, DELIVER_CAR, ELIMINATE_TIMER, FOLLOW_ROUTE, ELIMINATE_TARGETS, STEAL_CAR }

var missions: Array[Dictionary] = []
var current_mission_index: int = -1
var completed_count: int = 0
var current_mission: Dictionary = {}
var active: bool = false

var _time_left: float = 0.0


func _ready() -> void:
	set_process(false)
	_define_story_missions()


func _define_story_missions() -> void:
	missions = [
		{"id": "intro_01", "title": "أول توصيلة", "description": "وصّل الطرد للعنوان المحدد قبل ما ينتهي الوقت.", "type": ObjectiveType.REACH_LOCATION, "target_position": Vector3(40, 0, 20), "time_limit": 90.0, "reward_money": 150, "enemy_count": 0},
		{"id": "chase_01", "title": "هروب من الشرطة", "description": "خبّي من نظر الشرطة لمدة 45 ثانية.", "type": ObjectiveType.ELIMINATE_TIMER, "time_limit": 45.0, "reward_money": 300, "enemy_count": 0},
		{"id": "intro_02", "title": "لقاء العصابة", "description": "وصّل الطرد الثاني لمقر العصابة وابدأ التعامل معهم.", "type": ObjectiveType.REACH_LOCATION, "target_position": Vector3(-25, 0, 35), "time_limit": 80.0, "reward_money": 220, "enemy_count": 0},
		{"id": "steal_01", "title": "سرقة سيارة فاخرة", "description": "اسرق السيارة المحددة ووصّلها لنقطة التسليم قبل ما تنكشف.", "type": ObjectiveType.STEAL_CAR, "target_position": Vector3(-30, 0, 15), "time_limit": 75.0, "reward_money": 450, "enemy_count": 0},
		{"id": "gang_fight_01", "title": "تصفية حساب", "description": "صفّي أعضاء العصابة المنافسة بالمنطقة المحددة.", "type": ObjectiveType.ELIMINATE_TARGETS, "target_position": Vector3(10, 0, -40), "time_limit": 120.0, "reward_money": 600, "enemy_count": 3},
		{"id": "heist_01", "title": "اقتحام المستودع", "description": "ادخل المستودع، صفّي الحراسة، واهرب بالغنيمة.", "type": ObjectiveType.ELIMINATE_TARGETS, "target_position": Vector3(60, 0, -60), "time_limit": 110.0, "reward_money": 900, "enemy_count": 5},
		{"id": "gang_fight_02", "title": "حرب العصابات", "description": "اصمد وصفّي موجات العصابة المهاجمة.", "type": ObjectiveType.ELIMINATE_TARGETS, "target_position": Vector3(-60, 0, 40), "time_limit": 100.0, "reward_money": 1100, "enemy_count": 7},
		{"id": "heist_02", "title": "سطو البنك", "description": "اقتحم البنك، صفّي كل مقاومة، واهرب قبل وصول تعزيزات الشرطة.", "type": ObjectiveType.ELIMINATE_TARGETS, "target_position": Vector3(0, 0, 90), "time_limit": 90.0, "reward_money": 1600, "enemy_count": 9},
		{"id": "chase_02", "title": "مطاردة على الطريق السريع", "description": "اهرب من 3 سيارات شرطة بنفس الوقت لمدة 50 ثانية.", "type": ObjectiveType.ELIMINATE_TIMER, "time_limit": 50.0, "reward_money": 700, "enemy_count": 0},
		{"id": "steal_02", "title": "سرقة شاحنة مصفّحة", "description": "اعترض الشاحنة المصفّحة وسرّبها قبل ما توصل نقطة التسليم.", "type": ObjectiveType.STEAL_CAR, "target_position": Vector3(-70, 0, -20), "time_limit": 70.0, "reward_money": 850, "enemy_count": 2},
		{"id": "gang_fight_03", "title": "الانتقام", "description": "هاجم معقل العصابة المنافسة وصفّي قيادتها.", "type": ObjectiveType.ELIMINATE_TARGETS, "target_position": Vector3(45, 0, 65), "time_limit": 95.0, "reward_money": 1300, "enemy_count": 8},
		{"id": "infiltration_01", "title": "تسلل هادئ", "description": "ادخل المبنى بدون ما تنكشف وسرق الملفات السرية.", "type": ObjectiveType.REACH_LOCATION, "target_position": Vector3(-40, 0, -80), "time_limit": 100.0, "reward_money": 1000, "enemy_count": 4},
		{"id": "chase_03", "title": "مطاردة النخبة", "description": "اهرب من وحدة الشرطة الخاصة (نجوم قصوى) لمدة 70 ثانية.", "type": ObjectiveType.ELIMINATE_TIMER, "time_limit": 70.0, "reward_money": 1400, "enemy_count": 0},
		{"id": "heist_03", "title": "سرقة المجوهرات", "description": "اقتحم المحل، افتح الخزنة، واهرب بالغنيمة قبل انتهاء الوقت.", "type": ObjectiveType.ELIMINATE_TARGETS, "target_position": Vector3(80, 0, 10), "time_limit": 85.0, "reward_money": 1900, "enemy_count": 6},
		{"id": "gang_fight_04", "title": "الدفاع عن الحي", "description": "دافع عن منطقتك من هجوم عصابة منافسة بموجات متتالية.", "type": ObjectiveType.ELIMINATE_TARGETS, "target_position": Vector3(-90, 0, 50), "time_limit": 130.0, "reward_money": 1700, "enemy_count": 10},
		{"id": "steal_03", "title": "سباق سيارات مسروقة", "description": "اسرق 3 سيارات فاخرة ووصّلها لنفس النقطة بأقل وقت ممكن.", "type": ObjectiveType.STEAL_CAR, "target_position": Vector3(0, 0, -100), "time_limit": 120.0, "reward_money": 1500, "enemy_count": 3},
		{"id": "heist_04", "title": "اقتحام برج الأعمال", "description": "اصعد للطابق الأخير، صفّي الحراسة، وسيطر على الطابق.", "type": ObjectiveType.ELIMINATE_TARGETS, "target_position": Vector3(100, 0, 100), "time_limit": 140.0, "reward_money": 2200, "enemy_count": 11},
		{"id": "chase_04", "title": "الهروب الأخير من المدينة", "description": "اهرب من كل قوة الشرطة (5 نجوم) واخرج من حدود المدينة.", "type": ObjectiveType.ELIMINATE_TIMER, "time_limit": 90.0, "reward_money": 2000, "enemy_count": 0},
		{"id": "gang_fight_05", "title": "الحرب الكبرى", "description": "معركة حاسمة ضد كل قادة العصابة المنافسة بمكان واحد.", "type": ObjectiveType.ELIMINATE_TARGETS, "target_position": Vector3(-100, 0, -100), "time_limit": 150.0, "reward_money": 2600, "enemy_count": 13},
		{"id": "finale_01", "title": "المواجهة الأخيرة", "description": "المهمة الأخيرة: اقتحم القلعة الرئيسية وأنهِ القصة.", "type": ObjectiveType.ELIMINATE_TARGETS, "target_position": Vector3(0, 0, 150), "time_limit": 180.0, "reward_money": 5000, "enemy_count": 15},
	]


func start_mission_by_index(index: int) -> void:
	if index < 0 or index >= missions.size():
		return
	current_mission_index = index
	current_mission = missions[index]
	active = true
	_time_left = current_mission.get("time_limit", 0.0)
	set_process(_time_left > 0.0)
	mission_started.emit(current_mission)
	objective_updated.emit(current_mission["description"])


func start_next_mission() -> void:
	start_mission_by_index(current_mission_index + 1)


func start_mission(mission_id: String) -> void:
	for i in range(missions.size()):
		if missions[i]["id"] == mission_id:
			start_mission_by_index(i)
			return
	push_warning("Mission not found: %s" % mission_id)


func _process(delta: float) -> void:
	if not active:
		return
	_time_left -= delta
	if _time_left <= 0.0:
		fail_current_mission()


func complete_current_mission() -> void:
	if not active:
		return
	active = false
	set_process(false)
	GameManager.add_money(current_mission.get("reward_money", 0))
	completed_count += 1
	mission_completed.emit(current_mission)
	WeaponSystem.check_unlocks_for_mission_count(completed_count)
	chapter_advanced.emit(completed_count)
	current_mission = {}
	if current_mission_index + 1 < missions.size():
		start_next_mission()


func fail_current_mission() -> void:
	if not active:
		return
	active = false
	set_process(false)
	mission_failed.emit(current_mission)
	current_mission = {}


func get_time_left() -> float:
	return _time_left


func get_current_difficulty_scale() -> float:
	return 1.0 + (completed_count * 0.15)
