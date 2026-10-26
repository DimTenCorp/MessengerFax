class_name ChatDataClass
extends Node
## Хранилище данных о чатах. Плейсхолдеры - позже заменишь на реальные аватарки/имена.
## Каждый чат: { id, name, placeholder_initials, color, last_message, time, unread, is_online }

signal chat_updated

var chats: Array[Dictionary] = []

func _ready() -> void:
	_init_placeholder_chats()

func _init_placeholder_chats() -> void:
	chats = [
		{
			"id": "chat_01",
			"name": "Аня",
			"initials": "А",
			"color": Color("#FF6B8A"),
			"last_message": "Привет! Ты тут? Давно не виделись...",
			"time": "14:32",
			"unread": 2,
			"is_online": true,
			"is_typing": false,
		},
		{
			"id": "chat_02",
			"name": "Даша",
			"initials": "Д",
			"color": Color("#7B61FF"),
			"last_message": "Фото: IMG_2024.jpg",
			"time": "13:15",
			"unread": 1,
			"is_online": true,
			"is_typing": true,
		},
		{
			"id": "chat_03",
			"name": "Кира",
			"initials": "К",
			"color": Color("#00C9A7"),
			"last_message": "Хаха, ну ты даёшь 😄",
			"time": "вчера",
			"unread": 0,
			"is_online": false,
			"is_typing": false,
		},
		{
			"id": "chat_04",
			"name": "София",
			"initials": "С",
			"color": Color("#FF9F43"),
			"last_message": "Жду твой ответ 💌",
			"time": "вчера",
			"unread": 0,
			"is_online": false,
			"is_typing": false,
		},
		{
			"id": "chat_05",
			"name": "Лера",
			"initials": "Л",
			"color": Color("#54A0FF"),
			"last_message": "Ты получил моё фото?",
			"time": "понедельник",
			"unread": 3,
			"is_online": false,
			"is_typing": false,
		},
	]

func get_chat_by_id(id: String) -> Dictionary:
	for c in chats:
		if c["id"] == id:
			return c
	return {}

func get_total_unread() -> int:
	var total: int = 0
	for c in chats:
		total += c["unread"]
	return total

func mark_as_read(id: String) -> void:
	for c in chats:
		if c["id"] == id:
			c["unread"] = 0
			chat_updated.emit()
			break
