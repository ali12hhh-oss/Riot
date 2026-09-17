extends Node
## CharacterSelect
## Autoload يحفظ اختيار المستخدم بين شخصيتين قابلتين للعب: Zade (رجل) و Nyra (امرأة).
## كل شخصية إلها إحصائيات بسيطة مختلفة (مو مجرد شكل) عشان الاختيار يأثر فعلياً باللعب.

signal character_selected(character_id: String)

const CHARACTERS: Dictionary = {
	"zade": {
		"display_name": "Zade",
		"gender": "male",
		"speed_multiplier": 1.0,
		"health_bonus": 20.0,       # زيادة صحة - أقوى بالتحمل
		"stealth_bonus": 0.0,
		"model_color": Color(0.2, 0.35, 0.6),  # لون احتياطي إذا فشل تحميل النموذج
		"model_path": "res://assets/characters_v2/base/Superhero_Male_FullBody.gltf",
		"skin_path": "",  # النموذج الجديد جاي بمواده الخاصة (BaseColor/Normal/Roughness) - مو محتاج جلد يدوي
		"outfit_path": "res://assets/characters_v2/outfits/Male_Peasant.gltf",
	},
	"nyra": {
		"display_name": "Nyra",
		"gender": "female",
		"speed_multiplier": 1.15,   # أسرع بالحركة والتسلل
		"health_bonus": 0.0,
		"stealth_bonus": 0.25,      # أصعب اكتشافها من الشرطة/العصابات
		"model_color": Color(0.7, 0.15, 0.3),
		"model_path": "res://assets/characters_v2/base/Superhero_Female_FullBody.gltf",
		"skin_path": "",
		"outfit_path": "res://assets/characters_v2/outfits/Female_Peasant.gltf",
	},
}

var selected_id: String = ""


func select_character(character_id: String) -> void:
	if not CHARACTERS.has(character_id):
		push_warning("Unknown character id: %s" % character_id)
		return
	selected_id = character_id
	character_selected.emit(character_id)


func get_selected_data() -> Dictionary:
	if selected_id == "":
		return CHARACTERS["zade"]  # افتراضي
	return CHARACTERS[selected_id]


func get_all_ids() -> Array:
	return CHARACTERS.keys()
