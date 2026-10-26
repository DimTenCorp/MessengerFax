extends Node
## Глобальный менеджер навигации и сохранения

enum Screen { CHATS, GALLERY, CHAT_VIEW }

signal screen_changed(new_screen: Screen, payload)

var current_screen: Screen = Screen.CHATS
var current_chat_id: String = ""

# Для Яндекс.Игр - заглушка под SDK
var is_yandex_env: bool = false

func _ready() -> void:
	_check_yandex_env()

func _check_yandex_env() -> void:
	if OS.has_feature("web"):
		# В реальном билде здесь будет проверка YaGames.init
		is_yandex_env = false

func go_to(screen: Screen, payload: Variant = null) -> void:
	current_screen = screen
	if screen == Screen.CHAT_VIEW and payload is String:
		current_chat_id = payload
	screen_changed.emit(screen, payload)

func go_back_to_chats() -> void:
	go_to(Screen.CHATS)

func save_progress() -> void:
	var data := {
		"photos": GalleryManager.photos,
		"chats": ChatData.chats,
	}
	var json := JSON.stringify(data)
	# Для веба можно сохранять в localStorage через JavaScriptBridge
	if OS.has_feature("web") and JavaScriptBridge:
		JavaScriptBridge.eval("localStorage.setItem('messengerfax_save', `%s`);" % json.replace("`", "\\`"), true)
	else:
		var file := FileAccess.open("user://save.json", FileAccess.WRITE)
		if file:
			file.store_string(json)

func load_progress() -> void:
	var json_text := ""
	if OS.has_feature("web") and JavaScriptBridge:
		var result = JavaScriptBridge.eval("localStorage.getItem('messengerfax_save') || '';", true)
		if result != null:
			json_text = str(result)
	else:
		if FileAccess.file_exists("user://save.json"):
			var file := FileAccess.open("user://save.json", FileAccess.READ)
			if file:
				json_text = file.get_as_text()
	if json_text == "":
		return
	var data = JSON.parse_string(json_text)
	if data is Dictionary:
		if data.has("photos"):
			GalleryManager.photos = data["photos"]
			GalleryManager.gallery_updated.emit()
		if data.has("chats"):
			ChatData.chats = data["chats"]
			ChatData.chat_updated.emit()
