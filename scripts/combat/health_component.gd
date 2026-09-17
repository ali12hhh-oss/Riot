extends Node
class_name HealthComponent
## HealthComponent
## مكوّن صحة عام تحطه على أي شخصية (Zade، عضو عصابة، شرطي).

signal health_changed(current: float, max_health: float)
signal died
signal damaged(amount: float, source: Node)

@export var max_health: float = 100.0
var current_health: float


func _ready() -> void:
	current_health = max_health


func take_damage(amount: float, source: Node = null) -> void:
	if current_health <= 0.0:
		return
	var reduction: float = StoreSystem.get_current_damage_reduction()
	var final_amount: float = amount * (1.0 - reduction)
	current_health = max(current_health - final_amount, 0.0)
	damaged.emit(final_amount, source)
	health_changed.emit(current_health, max_health)
	if current_health <= 0.0:
		died.emit()


func heal(amount: float) -> void:
	current_health = min(current_health + amount, max_health)
	health_changed.emit(current_health, max_health)


func is_alive() -> bool:
	return current_health > 0.0
