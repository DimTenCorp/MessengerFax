extends Control

@onready var header_panel: Panel = $MainVBox/Header
@onready var chats_vbox: VBoxContainer = $MainVBox/Scroll/ChatsVBox
@onready var scroll: ScrollContainer = $MainVBox/Scroll
@onready var online_label: Label = $MainVBox/Header/HeaderMargin/VBox/Subtitle/OnlineLabel
@onready var unread_badge: Panel = $MainVBox/Header/HeaderMargin/VBox/Subtitle/UnreadBadge
@onready var unread_label: Label = $MainVBox/Header/HeaderMargin/VBox/Subtitle/UnreadBadge/UnreadLabel
@onready var hint_panel: Panel = $MainVBox/Hint

var _chat_items: Array = []

func _ready() -> void:
	_style_header()
	_style_unread_badge()
	_style_hint()
	var cd = get_node_or_null("/root/ChatData")
	if cd:
		_populate_chats(cd.chats)
		cd.chat_updated.connect(func():
			var cd2 = get_node_or_null("/root/ChatData")
			if cd2: _populate_chats(cd2.chats)
		)
	_update_header_stats()
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
	for child in chats_vbox.get_children():
		child.queue_free()
	_chat_items.clear()

	for data in chats:
		var item := preload("res://scenes/components/ChatItem.tscn").instantiate()
		chats_vbox.add_child(item)
		item.call_deferred("setup", data)
		item.chat_pressed.connect(_on_chat_pressed)
		_chat_items.append(item)

	chats_vbox.add_theme_constant_override("separation", 8)
	scroll.add_theme_constant_override("scrollbar_margin_top", 0)

	_update_header_stats()

func _on_chat_pressed(chat_id: String) -> void:
	var gm = get_node_or_null("/root/GameManager")
	var cd = get_node_or_null("/root/ChatData")
	if gm:
		gm.go_to(2, chat_id) # 2 = CHAT_VIEW
	if cd:
		cd.mark_as_read(chat_id)

func _update_header_stats() -> void:
	var cd = get_node_or_null("/root/ChatData")
	if cd == null:
		return
	var total: int = cd.chats.size()
	var online: int = 0
	for c in cd.chats:
		if c["is_online"]:
			online += 1
	online_label.text = "%d чатов • %d онлайн" % [total, online]

	var unread: int = cd.get_total_unread()
	if unread > 0:
		unread_badge.visible = true
		unread_label.text = str(unread)
	else:
		unread_badge.visible = false

func _animate_in() -> void:
	chats_vbox.modulate.a = 0.0
	var tween := create_tween()
	tween.tween_property(chats_vbox, "modulate:a", 1.0, 0.25).set_ease(Tween.EASE_OUT)
	chats_vbox.position.y += 12
	tween.parallel().tween_property(chats_vbox, "position:y", chats_vbox.position.y - 12, 0.28).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
