extends Node
## أداة تصوير شاشة للاختبار البصري المحلي.
## Autoload: ScreenshotCapture
##
## تضغط مفتاح F12 (أو الحدث المخصص "debug_screenshot" إن وُجد بخريطة الإدخال)
## فتُحفظ لقطة شاشة فورية داخل مجلد المستخدم المحلي، بترتيب زمني،
## عشان تصير مرجع لاختبار الميزات الجديدة (متل أزرار الحفظ/التحميل) بدون
## أدوات خارجية.

const SCREENSHOT_DIR: String = "user://screenshots/"

func _ready() -> void:
	# تأكد أن مجلد اللقطات موجود.
	if not DirAccess.dir_exists_absolute(SCREENSHOT_DIR):
		DirAccess.make_dir_recursive_absolute(SCREENSHOT_DIR)

func _unhandled_input(event: InputEvent) -> void:
	var pressed := false
	if InputMap.has_action("debug_screenshot") and event.is_action_pressed("debug_screenshot"):
		pressed = true
	elif event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_F12:
		pressed = true

	if pressed:
		capture()

## يلتقط الشاشة الحالية ويحفظها كملف PNG، ويرجع المسار الكامل.
func capture() -> String:
	var image: Image = get_viewport().get_texture().get_image()
	var timestamp := Time.get_datetime_string_from_system().replace(":", "-").replace(" ", "_")
	var file_path := SCREENSHOT_DIR + "screenshot_%s.png" % timestamp
	var err := image.save_png(file_path)
	if err == OK:
		print("[ScreenshotCapture] تم حفظ لقطة الشاشة: " + ProjectSettings.globalize_path(file_path))
	else:
		push_error("[ScreenshotCapture] فشل حفظ لقطة الشاشة (كود الخطأ: %d)" % err)
	return file_path
