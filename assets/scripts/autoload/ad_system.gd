extends Node
## AdSystem
## نظام إعلانات مكافئة (Rewarded Ads) - المستخدم يشاهد "إعلان" فيحصل على عنصر
## مجاني بالمتجر بدل الشراء بالفلوس.
##
## ⚠️ ملاحظة صادقة مهمة: هذا حالياً **محاكاة وظيفية** لتدفق الإعلان (عد تنازلي
## يمثّل مدة مشاهدة إعلان حقيقي) - مش شبكة إعلانات فعلية زي Google AdMob.
## لازم قبل النشر الفعلي تربط شبكة إعلانات حقيقية (تسجيل حساب AdMob، مفاتيح API،
## SDK خاص بأندرويد) - هاي خطوة خارج نطاق ملفات نصية/أصول CC0 اللي نشتغل فيها،
## ومحتاجة مطور يسجّل حساب ناشر فعلي. المنطق والواجهة هون جاهزين بالكامل،
## بس مصدر الإعلان نفسه لسا محاكاة.

signal ad_started
signal ad_progress(seconds_left: float)
signal ad_completed(category: String, item_id: String)

const AD_DURATION: float = 3.0  # محاكاة مدة إعلان قصير

var is_watching: bool = false


func watch_ad_for_item(category: String, item_id: String) -> void:
	if is_watching:
		return
	is_watching = true
	ad_started.emit()

	var remaining: float = AD_DURATION
	while remaining > 0.0:
		ad_progress.emit(remaining)
		await get_tree().create_timer(0.2).timeout
		remaining -= 0.2

	is_watching = false
	StoreSystem.grant_free_item(category, item_id)
	ad_completed.emit(category, item_id)
