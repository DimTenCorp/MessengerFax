extends Control

@onready var header: Panel = $VBox/Header
@onready var avatar_panel: Panel = $VBox/Header/HBox/Avatar
@onready var avatar_label: Label = $VBox/Header/HBox/Avatar/AvatarLabel
@onready var name_label: Label = $VBox/Header/HBox/NameVBox/NameLabel
@onready var status_label: Label = $VBox/Header/HBox/NameVBox/StatusLabel
@onready var back_btn: Button = $VBox/Header/HBox/BackBtn
@onready var input_bar: Panel = $VBox/InputBar
@onready var input_field: LineEdit = $VBox/InputBar/InputHBox/InputField
@onready var send_btn: Button = $VBox/InputBar/InputHBox/SendBtn
@onready var messages_vbox: VBoxContainer = $VBox/MessagesScroll/MessagesVBox

var chat_id: String = ""

func _ready() -> void:
	_style_header()
	_style_input()
	_style_avatar()
	back_btn.pressed.connect(_on_back)
	send_btn.pressed.connect(_on_send_pressed)
	# если открыли без id - берём из GameManager
	if chat_id == "":
		chat_id = GameManager.current_chat_id
	_load_chat(chat_id)

func setup(id: String) -> void:
	chat_id = id
	if is_node_ready():
		_load_chat(id)

func _style_header() -> void:
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color("#1E1E24")
	sb.corner_radius_top_left = 0
	sb.corner_radius_top_right = 0
	sb.corner_radius_bottom_right = 0
	sb.corner_radius_bottom_left = 0
	sb.border_color = Color("#2A2A33")
	sb.border_width_bottom = 1
	header.add_theme_stylebox_override("panel", sb)

	back_btn.add_theme_font_size_override("font_size", 22)
	back_btn.add_theme_color_override("font_color", Color("#7B61FF"))

func _style_input() -> void:
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color("#1E1E24")
	sb.border_color = Color("#2A2A33")
	sb.border_width_top = 1
	input_bar.add_theme_stylebox_override("panel", sb)

	var input_sb := StyleBoxFlat.new()
	input_sb.bg_color = Color("#2A2A33")
	input_sb.corner_radius_top_left = 20
	input_sb.corner_radius_top_right = 20
	input_sb.corner_radius_bottom_right = 20
	input_sb.corner_radius_bottom_left = 20
	input_field.add_theme_stylebox_override("normal", input_sb)
	input_field.add_theme_stylebox_override("read_only", input_sb)
	input_field.add_theme_stylebox_override("focus", input_sb)

	var send_sb := StyleBoxFlat.new()
	send_sb.bg_color = Color("#7B61FF")
	send_sb.corner_radius_top_left = 20
	send_sb.corner_radius_top_right = 20
	send_sb.corner_radius_bottom_right = 20
	send_sb.corner_radius_bottom_left = 20
	send_btn.add_theme_stylebox_override("normal", send_sb)
	send_btn.add_theme_stylebox_override("hover", send_sb)
	send_btn.add_theme_stylebox_override("pressed", send_sb)
	send_btn.add_theme_color_override("font_color", Color.WHITE)
	send_btn.add_theme_font_size_override("font_size", 16)

func _style_avatar() -> void:
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color("#FF6B8A")
	sb.corner_radius_top_left = 18
	sb.corner_radius_top_right = 18
	sb.corner_radius_bottom_right = 18
	sb.corner_radius_bottom_left = 18
	avatar_panel.add_theme_stylebox_override("panel", sb)

func _load_chat(id: String) -> void:
	var data := ChatData.get_chat_by_id(id)
	if data.is_empty():
		name_label.text = "Чат"
		status_label.text = "не в сети"
		return
	name_label.text = data.get("name", "???")
	avatar_label.text = data.get("initials", "?")
	var col: Color = data.get("color", Color("#7B61FF"))
	var sb := StyleBoxFlat.new()
	sb.bg_color = col
	sb.corner_radius_top_left = 18
	sb.corner_radius_top_right = 18
	sb.corner_radius_bottom_right = 18
	sb.corner_radius_bottom_left = 18
	avatar_panel.add_theme_stylebox_override("panel", sb)

	var is_online: bool = data.get("is_online", false)
	var is_typing: bool = data.get("is_typing", false)
	if is_typing:
		status_label.text = "печатает..."
		status_label.add_theme_color_override("font_color", Color("#7B61FF"))
	elif is_online:
		status_label.text = "в сети"
		status_label.add_theme_color_override("font_color", Color("#00D68F"))
	else:
		status_label.text = "была в сети недавно"
		status_label.add_theme_color_override("font_color", Color("#7A7A8A"))

	# демо-сообщения - плейсхолдеры
	_clear_demo_messages()
	_add_demo_bubbles(data)

func _clear_demo_messages() -> void:
	for child in messages_vbox.get_children():
		if child.name != "Hint":
			child.queue_free()

func _add_demo_bubbles(data: Dictionary) -> void:
	# Входящее сообщение плейсхолдер
	var bubble_in := _create_bubble(data.get("last_message", "Привет!"), false, data.get("color", Color("#7B61FF")))
	messages_vbox.add_child(bubble_in)

	var bubble_out := _create_bubble("Привет! Как дела? 😊", true, Color.TRANSPARENT)
	messages_vbox.add_child(bubble_out)

	if data.get("unread", 0) > 0:
		var typing := _create_bubble("печатает...", false, data.get("color", Color("#7B61FF")), true)
		messages_vbox.add_child(typing)

func _create_bubble(text: String, is_outgoing: bool, accent: Color, is_typing_hint: bool = false) -> Control:
	var container := HBoxContainer.new()
	container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	container.alignment = BoxContainer.ALIGNMENT_END if is_outgoing else BoxContainer.ALIGNMENT_BEGIN

	if not is_outgoing:
		var spacer_left := Control.new()
		spacer_left.custom_minimum_size = Vector2(8, 0)
		container.add_child(spacer_left)

	var panel := PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN

	var sb := StyleBoxFlat.new()
	if is_outgoing:
		sb.bg_color = Color("#7B61FF")
		sb.corner_radius_top_left = 18
		sb.corner_radius_top_right = 6
		sb.corner_radius_bottom_right = 6
		sb.corner_radius_bottom_left = 18
	else:
		sb.bg_color = Color("#22222A")
		sb.border_color = Color("#2A2A33")
		sb.border_width_left = 1
		sb.border_width_top = 1
		sb.border_width_right = 1
		sb.border_width_bottom = 1
		sb.corner_radius_top_left = 6
		sb.corner_radius_top_right = 18
		sb.corner_radius_bottom_right = 18
		sb.corner_radius_bottom_left = 18
	sb.content_margin_left = 14
	sb.content_margin_top = 10
	sb.content_margin_right = 14
	sb.content_margin_bottom = 10
	panel.add_theme_stylebox_override("panel", sb)

	var lbl := Label.new()
	lbl.text = text
	lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lbl.custom_minimum_size = Vector2(160, 0)
	lbl.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	lbl.add_theme_font_size_override("font_size", 14)
	if is_outgoing:
		lbl.add_theme_color_override("font_color", Color.WHITE)
	else:
		if is_typing_hint:
			lbl.add_theme_color_override("font_color", Color("#7B61FF"))
		else:
			lbl.add_theme_color_override("font_color", Color("#ECECF1"))
	panel.add_child(lbl)
	container.add_child(panel)

	if is_outgoing:
		var spacer_right := Control.new()
		spacer_right.custom_minimum_size = Vector2(8, 0)
		container.add_child(spacer_right)

	# анимация
	container.modulate.a = 0.0
	container.position.y += 6
	var tween := create_tween()
	tween.tween_property(container, "modulate:a", 1.0, 0.22)
	tween.parallel().tween_property(container, "position:y", container.position.y - 6, 0.22).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

	return container

func _on_back() -> void:
	GameManager.go_back_to_chats()

func _on_send_pressed() -> void:
	# заглушка пока
	var txt := input_field.text.strip_edges()
	if txt != "":
		var bubble := _create_bubble(txt, true, Color.TRANSPARENT)
		messages_vbox.add_child(bubble)
		input_field.text = ""
		await get_tree().create_timer(0.6).timeout
		var chat_data := ChatData.get_chat_by_id(chat_id)
		var reply := _create_bubble("Пока это заглушка, скоро тут будет живой диалог ✨", false, chat_data.get("color", Color("#7B61FF")))
		messages_vbox.add_child(reply)
