extends Node
## MedicalSystem
## لما صحة اللاعب توصل لحد حرج، بتوصل سيارة إسعاف حقيقية وتشفيه تدريجياً
## (بدل ما يموت فوراً) - وبتاخذ غرامة بسيطة من فلوسه متل عيادة حقيقية.

signal ambulance_called
signal player_healed(amount: float)

const AMBULANCE_SCENE_PATH: String = "res://assets/cars/ambulance.glb"
const CRITICAL_HEALTH_RATIO: float = 0.2
const HEAL_COST: int = 80
const HEAL_AMOUNT: float = 60.0

var _ambulance_instance: Node3D = null
var _on_the_way: bool = false


func watch_player_health(health_component: HealthComponent) -> void:
	health_component.health_changed.connect(func(current, max_h): _check_critical(current, max_h, health_component))


func _check_critical(current: float, max_health: float, health_component: HealthComponent) -> void:
	if _on_the_way:
		return
	if current <= 0.0:
		return
	if current / max_health <= CRITICAL_HEALTH_RATIO:
		_call_ambulance(health_component)


func _call_ambulance(health_component: HealthComponent) -> void:
	_on_the_way = true
	ambulance_called.emit()

	await health_component.get_tree().create_timer(10.0).timeout

	if is_instance_valid(health_component) and health_component.is_alive():
		GameManager.spend_money(HEAL_COST)
		health_component.heal(HEAL_AMOUNT)
		player_healed.emit(HEAL_AMOUNT)

	_on_the_way = false
