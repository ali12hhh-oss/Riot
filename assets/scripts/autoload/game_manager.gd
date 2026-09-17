extends Node
## GameManager
## Autoload عام يحفظ حالة اللعبة: نقود اللاعب، مستوى القصة، السيارة الحالية.
## استخدمه من أي سكربت عبر: GameManager.add_money(100)

signal money_changed(new_amount: int)
signal story_progress_changed(new_chapter: int)
signal player_car_spawned(car_node: Node3D)

var player_money: int = 500
var story_chapter: int = 1
var unlocked_cars: Array[String] = ["sedan"]
var current_car_id: String = "sedan"

var player_ref: Node3D = null


func add_money(amount: int) -> void:
	player_money += amount
	money_changed.emit(player_money)


func spend_money(amount: int) -> bool:
	if player_money >= amount:
		player_money -= amount
		money_changed.emit(player_money)
		return true
	return false


func unlock_car(car_id: String) -> void:
	if not unlocked_cars.has(car_id):
		unlocked_cars.append(car_id)


func advance_story() -> void:
	story_chapter += 1
	story_progress_changed.emit(story_chapter)


func register_player(car_node: Node3D) -> void:
	player_ref = car_node
	player_car_spawned.emit(car_node)


func save_game() -> void:
	var data := {
		"money": player_money,
		"chapter": story_chapter,
		"unlocked_cars": unlocked_cars,
		"current_car": current_car_id,
	}
	var file := FileAccess.open("user://savegame.json", FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(data))
		file.close()


func load_game() -> void:
	if not FileAccess.file_exists("user://savegame.json"):
		return
	var file := FileAccess.open("user://savegame.json", FileAccess.READ)
	if file:
		var data = JSON.parse_string(file.get_as_text())
		file.close()
		if data:
			player_money = data.get("money", player_money)
			story_chapter = data.get("chapter", story_chapter)
			current_car_id = data.get("current_car", current_car_id)
