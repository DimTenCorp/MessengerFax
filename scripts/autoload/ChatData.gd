class_name ChatDataClass
extends Node
## Хранилище данных о чатах. Плейсхолдеры - позже заменишь на реальные аватарки/имена.
## Каждый чат: { id, name, placeholder_initials, color, last_message, time, unread, is_online }

signal chat_updated

var chats: Array[Dictionary] = []

func _ready() -> void:
	_init_placeholder_chats()

func _init_placeholder_chats() -> void:
	# В текущем концепте игрок общается только с одной героиней.
	chats = [
		{
			"id": "chat_01",
			"name": "Аня",
			"initials": "А",
			"color": Color("#FF6B8A"),
			"last_message": "Привет! Рада, что ты заглянул 💌",
			"time": "сейчас",
			"unread": 0,
			"is_online": true,
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
