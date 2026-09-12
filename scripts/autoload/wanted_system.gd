extends Node
## WantedSystem
## نظام نجوم المطاردة بأسلوب GTA: كل ما ترفع مستوى الجريمة، الشرطة بتصير أعنف وأكتر عدد.
## استدعِ WantedSystem.add_crime() لما اللاعب يسرق/يهرب/يعتدي، وينزل تلقائياً مع الوقت
## إذا اختفى اللاعب عن نظر الشرطة.

signal wanted_level_changed(stars: int)
signal police_should_spawn(count: int, difficulty: float)
signal player_escaped

const MAX_STARS: int = 5
const COOLDOWN_TO_LOSE_STAR: float = 12.0  # ثواني بدون جريمة جديدة ولا مطاردة نظر لينزل نجمة

var stars: int = 0
var _cooldown_timer: float = 0.0
var _player_spotted: bool = false


func _process(delta: float) -> void:
	if stars <= 0:
		return
	if _player_spotted:
		_cooldown_timer = 0.0
		return
	_cooldown_timer += delta
	if _cooldown_timer >= COOLDOWN_TO_LOSE_STAR:
		_cooldown_timer = 0.0
		_decrease_star()


## نادِها لما اللاعب يرتكب جريمة (سرقة سيارة، اعتداء، اقتحام...)
func add_crime(severity: int = 1) -> void:
	set_stars(min(stars + severity, MAX_STARS))


## نادِها من منطقة كشف الشرطة (Area3D لمجال رؤيتهم) لما توصل اللاعب لعندهم
func set_player_spotted(spotted: bool) -> void:
	_player_spotted = spotted
	if not spotted:
		player_escaped.emit()


func set_stars(new_stars: int) -> void:
	new_stars = clampi(new_stars, 0, MAX_STARS)
	if new_stars == stars:
		return
	stars = new_stars
	wanted_level_changed.emit(stars)
	if stars > 0:
		var police_count: int = stars + 1
		var difficulty: float = 1.0 + (stars * 0.35)
		police_should_spawn.emit(police_count, difficulty)


func _decrease_star() -> void:
	set_stars(stars - 1)


func clear_wanted() -> void:
	set_stars(0)
