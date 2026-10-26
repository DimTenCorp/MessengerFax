extends Node
## Менеджер галереи. Хранит полученные фото.
## Позже сюда будут сохраняться реальные Texture2D от персонажей.

signal gallery_updated
signal photo_unlocked(character_id: String)

# character_id -> { unlocked: bool, texture_path: String, title: String }
var photos: Dictionary = {}

func _ready() -> void:
	_init_placeholders()

func _init_placeholders() -> void:
	# Плейсхолдеры - по одному слоту на персонажа
	var ids = ["chat_01", "chat_02", "chat_03", "chat_04", "chat_05"]
	var names = ["Аня", "Даша", "Кира", "София", "Лера"]
	for i in range(ids.size()):
		photos[ids[i]] = {
			"character_name": names[i],
			"unlocked": false,
			# Когда добавишь реальные фото, пропиши путь сюда: res://assets/photos/...
			"texture_path": "",
			"title": "Фото от %s" % names[i],
			"description": "Плейсхолдер. Получи фото в чате!",
		}
	# Для демо разблокируем одно фото чтобы показать как выглядит
	# photos["chat_01"]["unlocked"] = true

func is_unlocked(character_id: String) -> bool:
	if not photos.has(character_id):
		return false
	return photos[character_id]["unlocked"]

func unlock_photo(character_id: String) -> void:
	if photos.has(character_id) and not photos[character_id]["unlocked"]:
		photos[character_id]["unlocked"] = true
		photo_unlocked.emit(character_id)
		gallery_updated.emit()

func get_unlocked_count() -> int:
	var c := 0
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
