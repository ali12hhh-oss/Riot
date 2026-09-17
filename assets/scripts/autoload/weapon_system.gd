extends Node
## WeaponSystem
## قاعدة بيانات أسلحة قابلة للتوسع + نظام شراء وفتح تدريجي مرتبط بتقدم المهام.
## كل سلاح إله سعر وضرر ومدى وسرعة إطلاق - تقدر تزيد أسلحة جديدة بسهولة بالقاموس تحت.

signal weapon_unlocked(weapon_id: String)
signal weapon_purchased(weapon_id: String)
signal weapon_equipped(weapon_id: String)
signal purchase_failed(weapon_id: String, reason: String)

const WEAPONS: Dictionary = {
	"fists": {
		"display_name": "قبضة اليد",
		"price": 0,
		"damage": 8.0,
		"range": 1.5,
		"fire_cooldown": 0.5,
		"unlock_mission_index": 0,
	},
	"pistol": {
		"display_name": "مسدس",
		"price": 200,
		"damage": 18.0,
		"range": 40.0,
		"fire_cooldown": 0.3,
		"unlock_mission_index": 0,
	},
	"smg": {
		"display_name": "رشاش خفيف (SMG)",
		"price": 650,
		"damage": 14.0,
		"range": 30.0,
		"fire_cooldown": 0.1,
		"unlock_mission_index": 2,
	},
	"shotgun": {
		"display_name": "شوزن",
		"price": 900,
		"damage": 55.0,
		"range": 12.0,
		"fire_cooldown": 0.8,
		"unlock_mission_index": 3,
	},
	"rifle": {
		"display_name": "بندقية آلية",
		"price": 1800,
		"damage": 28.0,
		"range": 60.0,
		"fire_cooldown": 0.12,
		"unlock_mission_index": 5,
	},
	"sniper": {
		"display_name": "قناصة",
		"price": 3000,
		"damage": 100.0,
		"range": 120.0,
		"fire_cooldown": 1.4,
		"unlock_mission_index": 7,
	},
}

var unlocked_weapons: Array[String] = ["fists", "pistol"]
var owned_weapons: Array[String] = ["fists"]
var equipped_weapon: String = "fists"


func check_unlocks_for_mission_count(completed_missions: int) -> void:
	for weapon_id in WEAPONS.keys():
		if unlocked_weapons.has(weapon_id):
			continue
		var req: int = WEAPONS[weapon_id].get("unlock_mission_index", 0)
		if completed_missions >= req:
			unlocked_weapons.append(weapon_id)
			weapon_unlocked.emit(weapon_id)


func purchase_weapon(weapon_id: String) -> bool:
	if not WEAPONS.has(weapon_id):
		purchase_failed.emit(weapon_id, "غير موجود")
		return false
	if not unlocked_weapons.has(weapon_id):
		purchase_failed.emit(weapon_id, "لسا ما انفتح - كمّل مهام أكتر")
		return false
	if owned_weapons.has(weapon_id):
		purchase_failed.emit(weapon_id, "عندك هالسلاح أصلاً")
		return false

	var price: int = WEAPONS[weapon_id].get("price", 0)
	if not GameManager.spend_money(price):
		purchase_failed.emit(weapon_id, "مصاري مش كافية")
		return false

	owned_weapons.append(weapon_id)
	weapon_purchased.emit(weapon_id)
	return true


func equip_weapon(weapon_id: String) -> bool:
	if not owned_weapons.has(weapon_id):
		return false
	equipped_weapon = weapon_id
	weapon_equipped.emit(weapon_id)
	return true


func get_equipped_stats() -> Dictionary:
	return WEAPONS.get(equipped_weapon, WEAPONS["fists"])


func get_weapon_info(weapon_id: String) -> Dictionary:
	return WEAPONS.get(weapon_id, {})
