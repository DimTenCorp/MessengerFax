extends Control

@onready var chat_list: Control = $SafeArea/RootVBox/Content/ChatList
@onready var gallery: Control = $SafeArea/RootVBox/Content/Gallery
@onready var chat_view: Control = $SafeArea/RootVBox/Content/ChatView
@onready var bottom_nav: Panel = $SafeArea/RootVBox/BottomNav
@onready var chats_btn: Button = $SafeArea/RootVBox/BottomNav/NavHBox/ChatsBtn
@onready var gallery_btn: Button = $SafeArea/RootVBox/BottomNav/NavHBox/GalleryBtn

var _active_screen: GameManager.Screen = GameManager.Screen.CHATS

func _ready() -> void:
	_style_nav()
	_style_nav_buttons()
	GameManager.screen_changed.connect(_on_screen_changed)
	GalleryManager.gallery_updated.connect(_update_gallery_button)
	ChatData.chat_updated.connect(_update_gallery_button)

	chats_btn.pressed.connect(func(): GameManager.go_to(GameManager.Screen.CHATS))
	gallery_btn.pressed.connect(func(): GameManager.go_to(GameManager.Screen.GALLERY))

	_update_gallery_button()
	_apply_screen(GameManager.Screen.CHATS)

	# для веба - хэндлим кнопку назад браузера
	if OS.has_feature("web"):
		_setup_web_back()

func _style_nav() -> void:
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color("#1E1E24")
	sb.corner_radius_top_left = 16
	sb.corner_radius_top_right = 16
	sb.corner_radius_bottom_right = 0
	sb.corner_radius_bottom_left = 0
	sb.border_color = Color("#2A2A33")
	sb.border_width_top = 1
	bottom_nav.add_theme_stylebox_override("panel", sb)

func _style_nav_buttons() -> void:
	# Активная кнопка - фиолетовая, неактивная - полупрозрачная
	_update_nav_visuals()

func _update_nav_visuals() -> void:
	for btn in [chats_btn, gallery_btn]:
		btn.add_theme_font_size_override("font_size", 14)

	var active_sb := StyleBoxFlat.new()
	active_sb.bg_color = Color("#7B61FF")
	active_sb.corner_radius_top_left = 14
	active_sb.corner_radius_top_right = 14
	active_sb.corner_radius_bottom_right = 14
	active_sb.corner_radius_bottom_left = 14
	active_sb.content_margin_left = 12
	active_sb.content_margin_top = 8
	active_sb.content_margin_right = 12
	active_sb.content_margin_bottom = 8

	var inactive_sb := StyleBoxFlat.new()
	inactive_sb.bg_color = Color("#2A2A33")
	inactive_sb.corner_radius_top_left = 14
	inactive_sb.corner_radius_top_right = 14
	inactive_sb.corner_radius_bottom_right = 14
	inactive_sb.corner_radius_bottom_left = 14
	inactive_sb.content_margin_left = 12
	inactive_sb.content_margin_top = 8
	inactive_sb.content_margin_right = 12
	inactive_sb.content_margin_bottom = 8

	if _active_screen == GameManager.Screen.CHATS:
		chats_btn.add_theme_stylebox_override("normal", active_sb)
		chats_btn.add_theme_stylebox_override("hover", active_sb)
		chats_btn.add_theme_stylebox_override("pressed", active_sb)
		chats_btn.add_theme_color_override("font_color", Color.WHITE)

		gallery_btn.add_theme_stylebox_override("normal", inactive_sb)
		gallery_btn.add_theme_stylebox_override("hover", inactive_sb)
		gallery_btn.add_theme_stylebox_override("pressed", inactive_sb)
		gallery_btn.add_theme_color_override("font_color", Color("#A8A8B5"))
	elif _active_screen == GameManager.Screen.GALLERY:
		gallery_btn.add_theme_stylebox_override("normal", active_sb)
		gallery_btn.add_theme_stylebox_override("hover", active_sb)
		gallery_btn.add_theme_stylebox_override("pressed", active_sb)
		gallery_btn.add_theme_color_override("font_color", Color.WHITE)

		chats_btn.add_theme_stylebox_override("normal", inactive_sb)
		chats_btn.add_theme_stylebox_override("hover", inactive_sb)
		chats_btn.add_theme_stylebox_override("pressed", inactive_sb)
		chats_btn.add_theme_color_override("font_color", Color("#A8A8B5"))
	else:
		# в чате обе неактивны? делаем Чаты активным для ориентации
		chats_btn.add_theme_stylebox_override("normal", inactive_sb)
		chats_btn.add_theme_stylebox_override("hover", inactive_sb)
		chats_btn.add_theme_color_override("font_color", Color("#A8A8B5"))
		gallery_btn.add_theme_stylebox_override("normal", inactive_sb)
		gallery_btn.add_theme_stylebox_override("hover", inactive_sb)
		gallery_btn.add_theme_color_override("font_color", Color("#A8A8B5"))

func _update_gallery_button() -> void:
	var unlocked := GalleryManager.get_unlocked_count()
	var total := GalleryManager.get_total_count()
	var unread := ChatData.get_total_unread()
	gallery_btn.text = "🖼️ Галерея • %d/%d" % [unlocked, total]
	if unread > 0 and _active_screen != GameManager.Screen.CHATS:
		chats_btn.text = "💬 Чаты • %d" % unread
	else:
		chats_btn.text = "💬 Чаты"
		# если есть непрочитанные - подсветим
		if unread > 0 and _active_screen != GameManager.Screen.CHATS:
			chats_btn.add_theme_color_override("font_color", Color("#FF6B8A"))

func _on_screen_changed(new_screen: GameManager.Screen, payload: Variant) -> void:
	_apply_screen(new_screen, payload)

func _apply_screen(screen: GameManager.Screen, payload: Variant = null) -> void:
	_active_screen = screen
	chat_list.visible = false
	gallery.visible = false
	chat_view.visible = false
	bottom_nav.visible = true

	match screen:
		GameManager.Screen.CHATS:
			chat_list.visible = true
		GameManager.Screen.GALLERY:
			gallery.visible = true
		GameManager.Screen.CHAT_VIEW:
			chat_view.visible = true
			bottom_nav.visible = false
			if payload is String:
				chat_view.call_deferred("setup", payload)
			# анимируем вход чата
			chat_view.position.x = 40
			chat_view.modulate.a = 0.0
			var tween := create_tween()
			tween.tween_property(chat_view, "position:x", 0, 0.2).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
			tween.parallel().tween_property(chat_view, "modulate:a", 1.0, 0.2)

	_update_nav_visuals()
	_update_gallery_button()

	# уведомляем Яндекс Игры о смене экрана
	if GameManager.is_yandex_env and JavaScriptBridge:
		JavaScriptBridge.eval("if(window.ysdk) window.ysdk.features.LoadingAPI && window.ysdk.features.LoadingAPI.ready();", true)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_back") or (event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE):
		if _active_screen == GameManager.Screen.CHAT_VIEW:
			GameManager.go_back_to_chats()
			get_viewport().set_input_as_handled()

func _setup_web_back() -> void:
	# Хук для кнопки назад в браузере - пока заглушка
	pass
