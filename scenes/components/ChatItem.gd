extends PanelContainer

signal chat_pressed(chat_id: String)

var chat_id: String = ""
var _base_style: StyleBoxFlat
var _hover_style: StyleBoxFlat
var _pressed_style: StyleBoxFlat
var _is_hovered := false

@onready var avatar_bg: Panel = $Margin/HBox/AvatarWrap/AvatarBg
@onready var avatar_label: Label = $Margin/HBox/AvatarWrap/AvatarBg/AvatarLabel
@onready var avatar_texture: TextureRect = $Margin/HBox/AvatarWrap/AvatarBg/AvatarTexture
@onready var online_dot: Panel = $Margin/HBox/AvatarWrap/OnlineDot
@onready var name_label: Label = $Margin/HBox/Center/TopRow/NameLabel
@onready var time_label: Label = $Margin/HBox/Center/TopRow/TimeLabel
@onready var message_label: Label = $Margin/HBox/Center/BottomRow/MessageLabel
@onready var typing_label: Label = $Margin/HBox/Center/BottomRow/TypingLabel
@onready var badge: Panel = $Margin/HBox/Center/BottomRow/Badge
@onready var badge_label: Label = $Margin/HBox/Center/BottomRow/Badge/BadgeLabel

func _ready() -> void:
	mouse_entered.connect(_on_hover_enter)
	mouse_exited.connect(_on_hover_exit)
	gui_input.connect(_on_gui_input)
	_setup_styles()
	_setup_online_dot()
	_setup_badge()

func _setup_styles() -> void:
	# Безопасное получение стиля - чтобы не было null при expand/resize и кастом темах
	var base := get_theme_stylebox("panel")
	if base == null:
		base = StyleBoxFlat.new()
		base.bg_color = Color("#1E1E24")
		base.corner_radius_top_left = 16
		base.corner_radius_top_right = 16
		base.corner_radius_bottom_right = 16
		base.corner_radius_bottom_left = 16
	_base_style = base.duplicate() as StyleBoxFlat
	_hover_style = _base_style.duplicate() as StyleBoxFlat
	_hover_style.bg_color = Color("#22222A")
	_pressed_style = _base_style.duplicate() as StyleBoxFlat
	_pressed_style.bg_color = Color("#2A2A33")

func _setup_online_dot() -> void:
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color("#00D68F")
	sb.corner_radius_top_left = 7
	sb.corner_radius_top_right = 7
	sb.corner_radius_bottom_right = 7
	sb.corner_radius_bottom_left = 7
	sb.border_color = Color("#1A1A1E")
	sb.border_width_left = 2
	sb.border_width_top = 2
	sb.border_width_right = 2
	sb.border_width_bottom = 2
	online_dot.add_theme_stylebox_override("panel", sb)

func _setup_badge() -> void:
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color("#7B61FF")
	sb.corner_radius_top_left = 11
	sb.corner_radius_top_right = 11
	sb.corner_radius_bottom_right = 11
	sb.corner_radius_bottom_left = 11
	badge.add_theme_stylebox_override("panel", sb)

func setup(data: Dictionary) -> void:
	chat_id = data.get("id", "")
	await ready
	name_label.text = data.get("name", "???")
	time_label.text = data.get("time", "")
	avatar_label.text = data.get("initials", "?")

	var col: Color = data.get("color", Color("#7B61FF"))
	var av_sb := StyleBoxFlat.new()
	av_sb.bg_color = col
	av_sb.corner_radius_top_left = 26
	av_sb.corner_radius_top_right = 26
	av_sb.corner_radius_bottom_right = 26
	av_sb.corner_radius_bottom_left = 26
	avatar_bg.add_theme_stylebox_override("panel", av_sb)

	# Если добавишь аватарку - укажи путь в data["avatar"] = "res://assets/avatars/anya.png"
	# Тогда вместо инициалов покажется картинка
	if data.has("avatar") and data["avatar"] != "":
		var path: String = data["avatar"]
		if ResourceLoader.exists(path):
			var tex: Texture2D = load(path)
			if tex:
				avatar_texture.texture = tex
				avatar_texture.visible = true
				avatar_label.visible = false
			else:
				avatar_texture.visible = false
				avatar_label.visible = true
		else:
			avatar_texture.visible = false
			avatar_label.visible = true
	else:
		avatar_texture.visible = false
		avatar_label.visible = true

	var unread: int = data.get("unread", 0)
	var is_typing: bool = data.get("is_typing", false)

	if is_typing:
		message_label.visible = false
		typing_label.visible = true
		badge.visible = false
	else:
		message_label.visible = true
		typing_label.visible = false
		message_label.text = data.get("last_message", "")
		if unread > 0:
			badge.visible = true
			badge_label.text = str(unread)
			message_label.add_theme_color_override("font_color", Color("#ECECF1"))
		else:
			badge.visible = false
			message_label.add_theme_color_override("font_color", Color("#A8A8B5"))

	var is_online: bool = data.get("is_online", false)
	online_dot.visible = is_online

func _on_hover_enter() -> void:
	_is_hovered = true
	add_theme_stylebox_override("panel", _hover_style)

func _on_hover_exit() -> void:
	_is_hovered = false
	add_theme_stylebox_override("panel", _base_style)

func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		add_theme_stylebox_override("panel", _pressed_style)
		chat_pressed.emit(chat_id)
		# haptic for Yandex
		# лёгкая вибрация/звук
		await get_tree().create_timer(0.12).timeout
		if _is_hovered:
			add_theme_stylebox_override("panel", _hover_style)
		else:
			add_theme_stylebox_override("panel", _base_style)
	elif event is InputEventScreenTouch and event.pressed:
		add_theme_stylebox_override("panel", _pressed_style)
		chat_pressed.emit(chat_id)
