class_name GalleryManagerClass
extends Node
## Менеджер галереи. Хранит полученные фото.
## Позже сюда будут сохраняться реальные Texture2D от персонажей.

signal gallery_updated
signal photo_unlocked(photo_id: String)

# character_id -> { unlocked: bool, texture_path: String, title: String }
var photos: Dictionary = {}

func _ready() -> void:
	_init_placeholders()

func _init_placeholders() -> void:
	# Пять фото одной героини — галерея больше не показывает других персонажей.
	for i in range(5):
		var photo_id := "anya_photo_%02d" % (i + 1)
		photos[photo_id] = {
			"character_id": "chat_01",
			"character_name": "Аня",
			"display_name": "Аня · фото %d" % (i + 1),
			"unlocked": false,
			# Когда добавишь реальные фото, пропиши путь сюда: res://assets/photos/...
			"texture_path": "",
			"title": "Фото %d от Ани" % (i + 1),
			"description": "Плейсхолдер. Получи фото в чате!",
		}

func is_unlocked(photo_id: String) -> bool:
	if not photos.has(photo_id):
		return false
	return photos[photo_id]["unlocked"]

func unlock_photo(photo_id: String) -> void:
	if photos.has(photo_id) and not photos[photo_id]["unlocked"]:
		photos[photo_id]["unlocked"] = true
		photo_unlocked.emit(photo_id)
		gallery_updated.emit()

func get_unlocked_count() -> int:
	var c: int = 0
	for v in photos.values():
		if v["unlocked"]:
			c += 1
	return c

func get_total_count() -> int:
	return photos.size()

func try_load_texture(path: String) -> Texture2D:
	if path == "" or not ResourceLoader.exists(path):
		return null
	return load(path) as Texture2D
