extends Node
## StoreSystem
## متجر شامل: ملابس/تسريحات، دروع، سيوف، سيارات حديثة - كل شي بالشراء بالفلوس.
## بالمقابل، فيه "الخزانة الشخصية" (Locker): عناصر تقليدية تُمنح مجاناً كغنيمة
## من مهام محددة وتصير ملك اللاعب تلقائياً بدون شراء - نظامين منفصلين بوضوح.

signal item_purchased(category: String, item_id: String)
signal item_equipped(category: String, item_id: String)
signal locker_item_granted(category: String, item_id: String)
const CLOTHING: Dictionary = {
	"jacket_street": {"display_name": "جاكيت الشارع", "price": 150, "damage_reduction": 0.0, "free_via_ad": true},
	"jacket_leather": {"display_name": "جاكيت جلد", "price": 400, "damage_reduction": 0.05},
	"hair_short": {"display_name": "تسريحة قصيرة", "price": 80, "damage_reduction": 0.0, "free_via_ad": true},
	"hair_ponytail": {"display_name": "تسريحة ذيل حصان", "price": 100, "damage_reduction": 0.0},
	"suit_formal": {"display_name": "بدلة رسمية", "price": 600, "damage_reduction": 0.0},
}

const ARMOR: Dictionary = {
	"vest_light": {"display_name": "سترة واقية خفيفة", "price": 300, "damage_reduction": 0.15, "free_via_ad": true},
	"vest_heavy": {"display_name": "سترة واقية ثقيلة", "price": 900, "damage_reduction": 0.35},
	"riot_armor": {"display_name": "درع مكافحة شغب", "price": 1800, "damage_reduction": 0.5},
}

const MELEE_WEAPONS: Dictionary = {
	"knife": {"display_name": "سكين", "price": 120, "damage": 22.0, "free_via_ad": true},
	"bat": {"display_name": "مضرب بيسبول", "price": 200, "damage": 28.0},
	"sword_steel": {"display_name": "سيف فولاذي", "price": 950, "damage": 55.0},
	"sword_legendary": {"display_name": "سيف أسطوري", "price": 4000, "damage": 95.0},
}

const VEHICLES: Dictionary = {
	"sedan": {"display_name": "سيدان", "price": 0},
	"suv_modern": {"display_name": "دفع رباعي حديث", "price": 2200},
	"sports_modern": {"display_name": "سيارة رياضية حديثة", "price": 5500},
}

const LOCKER_REWARDS: Dictionary = {
	"heist_01": {"category": "clothing", "item_id": "jacket_leather"},
	"gang_fight_02": {"category": "melee", "item_id": "bat"},
	"heist_04": {"category": "armor", "item_id": "vest_heavy"},
	"finale_01": {"category": "melee", "item_id": "sword_legendary"},
}

var owned_clothing: Array[String] = []
var owned_armor: Array[String] = []
var owned_melee: Array[String] = []
var owned_vehicles: Array[String] = ["sedan"]

var equipped_clothing: Array[String] = []
var equipped_armor: String = ""
var equipped_melee: String = ""


func _ready() -> void:
	MissionManager.mission_completed.connect(_on_mission_completed)


func _on_mission_completed(mission: Dictionary) -> void:
	var mission_id: String = mission.get("id", "")
	if not LOCKER_REWARDS.has(mission_id):
		return
	var reward: Dictionary = LOCKER_REWARDS[mission_id]
	_grant_locker_item(reward["category"], reward["item_id"])


func _grant_locker_item(category: String, item_id: String) -> void:
	grant_free_item(category, item_id)


func grant_free_item(category: String, item_id: String) -> void:
	var owned_list: Array = _get_owned_list(category)
	if owned_list != null and not owned_list.has(item_id):
		owned_list.append(item_id)
		locker_item_granted.emit(category, item_id)


func purchase_item(category: String, item_id: String) -> bool:
	var catalog: Dictionary = _get_catalog(category)
	var owned_list: Array = _get_owned_list(category)
	if catalog.is_empty() or owned_list == null or not catalog.has(item_id):
		return false
	if owned_list.has(item_id):
		return false
	var price: int = catalog[item_id].get("price", 0)
	if not GameManager.spend_money(price):
		return false
	owned_list.append(item_id)
	item_purchased.emit(category, item_id)
	return true


func equip_vehicle(item_id: String) -> bool:
	if not owned_vehicles.has(item_id):
		return false
	GameManager.current_car_id = item_id
	item_equipped.emit("vehicle", item_id)
	return true


func equip_melee(item_id: String) -> bool:
	if item_id != "" and not owned_melee.has(item_id):
		return false
	equipped_melee = item_id
	item_equipped.emit("melee", item_id)
	return true


func equip_armor(item_id: String) -> bool:
	if item_id != "" and not owned_armor.has(item_id):
		return false
	equipped_armor = item_id
	item_equipped.emit("armor", item_id)
	return true


func get_current_damage_reduction() -> float:
	if equipped_armor == "" or not ARMOR.has(equipped_armor):
		return 0.0
	return ARMOR[equipped_armor].get("damage_reduction", 0.0)


func _get_catalog(category: String) -> Dictionary:
	match category:
		"clothing": return CLOTHING
		"armor": return ARMOR
		"melee": return MELEE_WEAPONS
		"vehicle": return VEHICLES
		_: return {}


func _get_owned_list(category: String) -> Array:
	match category:
		"clothing": return owned_clothing
		"armor": return owned_armor
		"melee": return owned_melee
		"vehicle": return owned_vehicles
		_: return []
