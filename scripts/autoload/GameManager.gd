class_name GameManagerClass
extends Node
## Глобальный менеджер навигации и сохранения

enum Screen { CHATS, GALLERY, CHAT_VIEW }

signal screen_changed(new_screen: int, payload)

var current_screen: int = Screen.CHATS
var current_chat_id: String = ""

# Для Яндекс.Игр - заглушка под SDK
var is_yandex_env: bool = false

func _ready() -> void:
	_check_yandex_env()

func _check_yandex_env() -> void:
	if OS.has_feature("web"):
		is_yandex_env = false

func go_to(screen: int, payload: Variant = null) -> void:
	current_screen = screen
	if screen == Screen.CHAT_VIEW and payload is String:
		current_chat_id = payload
	screen_changed.emit(screen, payload)

func go_back_to_chats() -> void:
	go_to(Screen.CHATS)

func save_progress() -> void:
	var gallery_mgr = get_node_or_null("/root/GalleryManager")
	var chat_data = get_node_or_null("/root/ChatData")
	if gallery_mgr == null or chat_data == null:
		return
	var data := {
		"photos": gallery_mgr.photos,
		"chats": chat_data.chats,
	}
	var json := JSON.stringify(data)
	if OS.has_feature("web") and Engine.has_singleton("JavaScriptBridge"):
		var js = Engine.get_singleton("JavaScriptBridge")
		js.eval("localStorage.setItem('messengerfax_save', `%s`);" % json.replace("`", "\\`"), true)
	else:
		var file := FileAccess.open("user://save.json", FileAccess.WRITE)
		if file:
			file.store_string(json)

func load_progress() -> void:
	var gallery_mgr = get_node_or_null("/root/GalleryManager")
	var chat_data = get_node_or_null("/root/ChatData")
	var json_text := ""
	if OS.has_feature("web") and Engine.has_singleton("JavaScriptBridge"):
		var js = Engine.get_singleton("JavaScriptBridge")
		var result = js.eval("localStorage.getItem('messengerfax_save') || '';", true)
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
		if data.has("photos") and gallery_mgr != null:
			gallery_mgr.photos = data["photos"]
			gallery_mgr.gallery_updated.emit()
		if data.has("chats") and chat_data != null:
			chat_data.chats = data["chats"]
			chat_data.chat_updated.emit()
