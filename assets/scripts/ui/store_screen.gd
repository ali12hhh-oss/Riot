extends Control
## StoreScreen
## متجر موحّد واحد: أسلحة نارية، ملابس/تسريحات، دروع، سيوف، سيارات حديثة.

@onready var tab_weapons: Button = $Panel/VBoxContainer/Tabs/WeaponsTab
@onready var tab_clothing: Button = $Panel/VBoxContainer/Tabs/ClothingTab
@onready var tab_armor: Button = $Panel/VBoxContainer/Tabs/ArmorTab
@onready var tab_melee: Button = $Panel/VBoxContainer/Tabs/MeleeTab
@onready var tab_vehicles: Button = $Panel/VBoxContainer/Tabs/VehiclesTab

@onready var money_label: Label = $Panel/VBoxContainer/MoneyLabel
@onready var list_container: VBoxContainer = $Panel/VBoxContainer/ScrollContainer/ListContainer
@onready var close_button: Button = $Panel/VBoxContainer/CloseButton
@onready var ad_overlay: Panel = $AdOverlay
@onready var ad_label: Label = $AdOverlay/AdLabel

var _current_category: String = "weapon"


func _ready() -> void:
	tab_weapons.pressed.connect(func(): _switch_category("weapon"))
	tab_clothing.pressed.connect(func(): _switch_category("clothing"))
	tab_armor.pressed.connect(func(): _switch_category("armor"))
	tab_melee.pressed.connect(func(): _switch_category("melee"))
	tab_vehicles.pressed.connect(func(): _switch_category("vehicle"))
	close_button.pressed.connect(func(): hide())

	GameManager.money_changed.connect(func(_amount): _refresh())
	StoreSystem.item_purchased.connect(func(_c, _i): _refresh())
	StoreSystem.item_equipped.connect(func(_c, _i): _refresh())
	StoreSystem.locker_item_granted.connect(func(_c, _i): _refresh())
	WeaponSystem.weapon_purchased.connect(func(_i): _refresh())
	WeaponSystem.weapon_equipped.connect(func(_i): _refresh())
	WeaponSystem.weapon_unlocked.connect(func(_i): _refresh())

	AdSystem.ad_started.connect(_on_ad_started)
	AdSystem.ad_progress.connect(_on_ad_progress)
	AdSystem.ad_completed.connect(_on_ad_completed)

	ad_overlay.visible = false
	_switch_category("weapon")


func _switch_category(category: String) -> void:
	_current_category = category
	_refresh()


func _refresh() -> void:
	money_label.text = "💰 %d$" % GameManager.player_money
	for child in list_container.get_children():
		child.queue_free()

	if _current_category == "weapon":
		for weapon_id in WeaponSystem.WEAPONS.keys():
			if not WeaponSystem.unlocked_weapons.has(weapon_id):
				continue
			_add_weapon_row(weapon_id)
	else:
		var catalog: Dictionary = StoreSystem._get_catalog(_current_category)
		var owned_list: Array = StoreSystem._get_owned_list(_current_category)
		for item_id in catalog.keys():
			_add_item_row(item_id, catalog[item_id], owned_list)


func _add_weapon_row(weapon_id: String) -> void:
	var info: Dictionary = WeaponSystem.get_weapon_info(weapon_id)
	var owned: bool = WeaponSystem.owned_weapons.has(weapon_id)
	_build_row(
		"weapon", weapon_id, info.get("display_name", weapon_id),
		" (💥%d 🎯%dم)" % [int(info.get("damage", 0)), int(info.get("range", 0))],
		owned, info.get("price", 0), false,
		WeaponSystem.equipped_weapon == weapon_id,
		func(): WeaponSystem.purchase_weapon(weapon_id),
		func(): WeaponSystem.equip_weapon(weapon_id)
	)


func _add_item_row(item_id: String, info: Dictionary, owned_list: Array) -> void:
	var owned: bool = owned_list.has(item_id)
	var stat_text: String = ""
	if info.has("damage"):
		stat_text = " (💥%d)" % int(info["damage"])
	elif info.has("damage_reduction") and info["damage_reduction"] > 0.0:
		stat_text = " (🛡️-%d%%)" % int(info["damage_reduction"] * 100)

	_build_row(
		_current_category, item_id, info.get("display_name", item_id), stat_text,
		owned, info.get("price", 0), info.get("free_via_ad", false),
		_is_currently_equipped(item_id),
		func(): StoreSystem.purchase_item(_current_category, item_id),
		func(): _equip(item_id)
	)


func _build_row(category: String, item_id: String, display_name: String, stat_text: String,
		owned: bool, price: int, free_via_ad: bool, is_equipped: bool,
		buy_callable: Callable, equip_callable: Callable) -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)

	var name_label := Label.new()
	name_label.text = display_name + stat_text + ("  🎁" if owned and price > 0 else "")
	name_label.custom_minimum_size = Vector2(220, 0)
	row.add_child(name_label)

	if owned:
		var equip_button := Button.new()
		equip_button.text = "مجهّز ✅" if is_equipped else "تجهيز"
		equip_button.disabled = is_equipped
		equip_button.pressed.connect(equip_callable)
		row.add_child(equip_button)
	else:
		var buy_button := Button.new()
		buy_button.text = "شراء %d$" % price
		buy_button.pressed.connect(buy_callable)
		row.add_child(buy_button)

		if free_via_ad:
			var ad_button := Button.new()
			ad_button.text = "📺 مجاناً"
			ad_button.pressed.connect(func(): AdSystem.watch_ad_for_item(category, item_id))
			row.add_child(ad_button)

	list_container.add_child(row)


func _is_currently_equipped(item_id: String) -> bool:
	match _current_category:
		"clothing": return StoreSystem.equipped_clothing.has(item_id)
		"armor": return StoreSystem.equipped_armor == item_id
		"melee": return StoreSystem.equipped_melee == item_id
		"vehicle": return GameManager.current_car_id == item_id
		_: return false


func _equip(item_id: String) -> void:
	match _current_category:
		"clothing":
			if StoreSystem.equipped_clothing.has(item_id):
				StoreSystem.equipped_clothing.erase(item_id)
			else:
				StoreSystem.equipped_clothing.append(item_id)
			StoreSystem.item_equipped.emit("clothing", item_id)
		"armor": StoreSystem.equip_armor(item_id)
		"melee": StoreSystem.equip_melee(item_id)
		"vehicle": StoreSystem.equip_vehicle(item_id)


func _on_ad_started() -> void:
	ad_overlay.visible = true


func _on_ad_progress(seconds_left: float) -> void:
	ad_label.text = "📺 جاري عرض الإعلان... %d" % ceili(seconds_left)


func _on_ad_completed(_category: String, _item_id: String) -> void:
	ad_overlay.visible = false
