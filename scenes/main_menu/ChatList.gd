extends Control

@export var chat_item_scene: PackedScene

@onready var header_panel: Panel = $MainVBox/Header
@onready var search_bar: Panel = $MainVBox/Header/HeaderMargin/VBox/SearchBar
@onready var search_input: LineEdit = $MainVBox/Header/HeaderMargin/VBox/SearchBar/SearchMargin/HBox/SearchInput
@onready var chats_vbox: VBoxContainer = $MainVBox/Scroll/ChatsVBox
@onready var scroll: ScrollContainer = $MainVBox/Scroll
@onready var online_label: Label = $MainVBox/Header/HeaderMargin/VBox/Subtitle/OnlineLabel
@onready var unread_badge: Panel = $MainVBox/Header/HeaderMargin/VBox/Subtitle/UnreadBadge
@onready var unread_label: Label = $MainVBox/Header/HeaderMargin/VBox/Subtitle/UnreadBadge/UnreadLabel
@onready var hint_panel: Panel = $MainVBox/Hint

var _chat_items: Array = []

func _ready() -> void:
	_style_header()
	_style_search_bar()
	_style_unread_badge()
	_style_hint()
	search_input.text_changed.connect(_on_search_changed)
	_populate_chats(ChatData.chats)
	ChatData.chat_updated.connect(func(): _populate_chats(ChatData.chats))
	_update_header_stats()
	# небольшая анимация появления
	_animate_in()

func _style_header() -> void:
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color("#1E1E24")
	sb.corner_radius_top_left = 0
	sb.corner_radius_top_right = 0
	sb.corner_radius_bottom_right = 16
	sb.corner_radius_bottom_left = 16
	sb.content_margin_left = 0
	sb.content_margin_top = 0
	sb.content_margin_right = 0
	sb.content_margin_bottom = 0
	header_panel.add_theme_stylebox_override("panel", sb)

func _style_search_bar() -> void:
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color("#2A2A33")
	sb.corner_radius_top_left = 12
	sb.corner_radius_top_right = 12
	sb.corner_radius_bottom_right = 12
	sb.corner_radius_bottom_left = 12
	search_bar.add_theme_stylebox_override("panel", sb)

func _style_unread_badge() -> void:
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color("#7B61FF")
	sb.corner_radius_top_left = 10
	sb.corner_radius_top_right = 10
	sb.corner_radius_bottom_right = 10
	sb.corner_radius_bottom_left = 10
	unread_badge.add_theme_stylebox_override("panel", sb)

func _style_hint() -> void:
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color.TRANSPARENT
	hint_panel.add_theme_stylebox_override("panel", sb)

func _populate_chats(chats: Array) -> void:
	# очищаем
	for child in chats_vbox.get_children():
		child.queue_free()
	_chat_items.clear()

	for data in chats:
		var item := preload("res://scenes/components/ChatItem.tscn").instantiate()
		chats_vbox.add_child(item)
		# setup после добавления в дерево (ready)
		item.call_deferred("setup", data)
		item.chat_pressed.connect(_on_chat_pressed)
		_chat_items.append(item)

	# отступ сверху/снизу для списка
	chats_vbox.add_theme_constant_override("separation", 8)
	# паддинг контейнера через Margin
	var margin_top := 12
	# добавим внутренний отступ скроллу
	scroll.add_theme_constant_override("scrollbar_margin_top", 0)

	_update_header_stats()

func _on_chat_pressed(chat_id: String) -> void:
	# эффект и переход
	GameManager.go_to(GameManager.Screen.CHAT_VIEW, chat_id)
	ChatData.mark_as_read(chat_id)

func _on_search_changed(new_text: String) -> void:
	var query := new_text.strip_edges().to_lower()
	if query == "":
		_populate_chats(ChatData.chats)
		return
	var filtered: Array[Dictionary] = []
	for c in ChatData.chats:
		if c["name"].to_lower().contains(query) or c["last_message"].to_lower().contains(query):
			filtered.append(c)
	_populate_chats(filtered)

func _update_header_stats() -> void:
	var total := ChatData.chats.size()
	var online := 0
	for c in ChatData.chats:
		if c["is_online"]:
			online += 1
	online_label.text = "%d чатов • %d онлайн" % [total, online]

	var unread := ChatData.get_total_unread()
	if unread > 0:
		unread_badge.visible = true
		unread_label.text = str(unread)
	else:
		unread_badge.visible = false

func _animate_in() -> void:
	chats_vbox.modulate.a = 0.0
	var tween := create_tween()
	tween.tween_property(chats_vbox, "modulate:a", 1.0, 0.25).set_ease(Tween.EASE_OUT)
	# лёгкий slide
	chats_vbox.position.y += 12
	tween.parallel().tween_property(chats_vbox, "position:y", chats_vbox.position.y - 12, 0.28).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
