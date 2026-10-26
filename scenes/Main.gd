extends Control

@onready var adaptive_root: Control = $AdaptiveRoot
@onready var phone_container: Panel = $AdaptiveRoot/PhoneContainer
@onready var phone_vbox: VBoxContainer = $AdaptiveRoot/PhoneContainer/PhoneVBox
@onready var chat_list: Control = $AdaptiveRoot/PhoneContainer/PhoneVBox/Content/ChatList
@onready var gallery: Control = $AdaptiveRoot/PhoneContainer/PhoneVBox/Content/Gallery
@onready var chat_view: Control = $AdaptiveRoot/PhoneContainer/PhoneVBox/Content/ChatView
@onready var bottom_nav: Panel = $AdaptiveRoot/PhoneContainer/PhoneVBox/BottomNav
@onready var chats_btn: Button = $AdaptiveRoot/PhoneContainer/PhoneVBox/BottomNav/NavHBox/ChatsBtn
@onready var gallery_btn: Button = $AdaptiveRoot/PhoneContainer/PhoneVBox/BottomNav/NavHBox/GalleryBtn
@onready var bg_rect: ColorRect = $Bg
@onready var bg_gradient: ColorRect = $BgGradient

# Используем int для экрана чтобы не зависеть от порядка компиляции автозагрузок
var _active_screen: int = 0 # 0=CHATS, 1=GALLERY, 2=CHAT_VIEW

# Адаптив
const MAX_PHONE_WIDTH: int = 560
const TABLET_BREAKPOINT: int = 720
var _is_desktop_mode: bool = false

func _ready() -> void:
	_setup_font()
	_style_nav()
	_style_nav_buttons()
	_style_phone_container()

	# Подключаемся к автозагрузкам через глобальные имена (работает в рантайме)
	var gm = get_node_or_null("/root/GameManager")
	if gm:
		gm.screen_changed.connect(_on_screen_changed)
	var gal = get_node_or_null("/root/GalleryManager")
	if gal:
		gal.gallery_updated.connect(_update_gallery_button)
	var cd = get_node_or_null("/root/ChatData")
	if cd:
		cd.chat_updated.connect(_update_gallery_button)

	chats_btn.pressed.connect(func():
		var gm2 = get_node_or_null("/root/GameManager")
		if gm2: gm2.go_to(0)
	)
	gallery_btn.pressed.connect(func():
		var gm2 = get_node_or_null("/root/GameManager")
		if gm2: gm2.go_to(1)
	)

	_update_gallery_button()
	_apply_screen(0)

	# для веба - хэндлим кнопку назад браузера
	if OS.has_feature("web"):
		_setup_web_back()

	# Адаптивная верстка
	get_viewport().size_changed.connect(_update_layout)
	_update_layout()
	# Делаем так чтобы на старте лэйаут был корректным даже после небольшого дилэя (HTML лоадер)
	await get_tree().create_timer(0.1).timeout
	_update_layout()

func _setup_font() -> void:
	# Подгружаем шрифт динамически без .import (через FontFile.load_dynamic_font)
	# Это убирает ошибку add_theme_font_override: p_font is null и даёт кириллицу на всех платформах
	var font_path := "res://assets/fonts/Inter-Variable.ttf"
	if not FileAccess.file_exists(font_path):
		# Фолбэк: используем встроенный шрифт Godot
		return
	var font_file := FontFile.new()
	var err := font_file.load_dynamic_font(font_path)
	if err != OK or font_file == null:
		return
	# Создаём тему с этим шрифтом
	var theme_override: Theme
	if theme != null:
		theme_override = theme.duplicate() as Theme
	else:
		theme_override = load("res://assets/fonts/ThemeWithFont.tres").duplicate() as Theme
	theme_override.default_font = font_file
	# Делаем шрифт чуть больше для телефона/десктопа адаптивно
	theme_override.default_font_size = 14
	theme = theme_override
	# Применяем к руту чтобы наследовалось везде
	if get_tree() and get_tree().root:
		get_tree().root.theme = theme_override

func _style_nav() -> void:
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color("#1E1E24")
	sb.corner_radius_top_left = 0
	sb.corner_radius_top_right = 0
	sb.corner_radius_bottom_right = 0
	sb.corner_radius_bottom_left = 0
	sb.border_color = Color("#2A2A33")
	sb.border_width_top = 1
	bottom_nav.add_theme_stylebox_override("panel", sb)

func _style_phone_container() -> void:
	# Базовый стиль контейнера телефона
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color("#16161A")
	sb.corner_radius_top_left = 0
	sb.corner_radius_top_right = 0
	sb.corner_radius_bottom_right = 0
	sb.corner_radius_bottom_left = 0
	sb.border_color = Color.TRANSPARENT
	phone_container.add_theme_stylebox_override("panel", sb)

func _style_nav_buttons() -> void:
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

	if _active_screen == 0: # CHATS
		chats_btn.add_theme_stylebox_override("normal", active_sb)
		chats_btn.add_theme_stylebox_override("hover", active_sb)
		chats_btn.add_theme_stylebox_override("pressed", active_sb)
		chats_btn.add_theme_color_override("font_color", Color.WHITE)

		gallery_btn.add_theme_stylebox_override("normal", inactive_sb)
		gallery_btn.add_theme_stylebox_override("hover", inactive_sb)
		gallery_btn.add_theme_stylebox_override("pressed", inactive_sb)
		gallery_btn.add_theme_color_override("font_color", Color("#A8A8B5"))
	elif _active_screen == 1: # GALLERY
		gallery_btn.add_theme_stylebox_override("normal", active_sb)
		gallery_btn.add_theme_stylebox_override("hover", active_sb)
		gallery_btn.add_theme_stylebox_override("pressed", active_sb)
		gallery_btn.add_theme_color_override("font_color", Color.WHITE)

		chats_btn.add_theme_stylebox_override("normal", inactive_sb)
		chats_btn.add_theme_stylebox_override("hover", inactive_sb)
		chats_btn.add_theme_stylebox_override("pressed", inactive_sb)
		chats_btn.add_theme_color_override("font_color", Color("#A8A8B5"))
	else:
		chats_btn.add_theme_stylebox_override("normal", inactive_sb)
		chats_btn.add_theme_stylebox_override("hover", inactive_sb)
		chats_btn.add_theme_color_override("font_color", Color("#A8A8B5"))
		gallery_btn.add_theme_stylebox_override("normal", inactive_sb)
		gallery_btn.add_theme_stylebox_override("hover", inactive_sb)
		gallery_btn.add_theme_color_override("font_color", Color("#A8A8B5"))

func _update_layout() -> void:
	# Определяем размер окна/вьюпорта
	var vp_size: Vector2 = get_viewport_rect().size
	# Для HTML может быть точнее DisplayServer
	if DisplayServer.window_get_size() != Vector2i.ZERO:
		# В редакторе window_get_size точнее, в вебе - viewport
		var win_size := Vector2(DisplayServer.window_get_size())
		# Берём максимум для стабильности
		if win_size.x > 0 and win_size.y > 0:
			vp_size = win_size

	var win_w: float = vp_size.x
	var win_h: float = vp_size.y
	var is_desktop: bool = win_w >= 700 or (win_w > win_h and win_w >= 600)

	_is_desktop_mode = is_desktop

	var phone_w: float = win_w
	var phone_h: float = win_h
	var side_margin: float = 0
	var top_margin: float = 0
	var corner_radius: int = 0
	var shadow_enabled: bool = false

	if is_desktop:
		# Десктоп: центрируем телефоноподобное окно
		phone_w = minf(win_w * 0.95, MAX_PHONE_WIDTH)
		# Ограничиваем высоту чтобы был отступ сверху/снизу на больших экранах
		if win_h > 800:
			phone_h = minf(win_h * 0.92, 960)
			top_margin = (win_h - phone_h) / 2.0
			corner_radius = 20
			shadow_enabled = true
		else:
			phone_h = win_h
			corner_radius = 16 if win_w > 800 else 0
			shadow_enabled = true
		side_margin = (win_w - phone_w) / 2.0
		# Фон для десктопа темнее с градиентом
		bg_rect.color = Color("#0A0A0F")
		bg_gradient.visible = true
		bg_gradient.color = Color(0.12, 0.08, 0.25, 0.18)
	else:
		# Мобилка: на весь экран без отступов
		phone_w = win_w
		phone_h = win_h
		side_margin = 0
		top_margin = 0
		corner_radius = 0
		shadow_enabled = false
		bg_rect.color = Color("#16161A")
		bg_gradient.visible = false

	# Применяем позицию/размер к контейнеру телефона
	# Используем offsets (так как anchor 0-1)
	phone_container.position = Vector2(side_margin, top_margin)
	phone_container.size = Vector2(phone_w, phone_h)

	# Стиль контейнера с учётом режима
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color("#16161A")
	sb.corner_radius_top_left = corner_radius
	sb.corner_radius_top_right = corner_radius
	sb.corner_radius_bottom_right = corner_radius
	sb.corner_radius_bottom_left = corner_radius
	if shadow_enabled:
		sb.shadow_color = Color(0, 0, 0, 0.5)
		sb.shadow_size = 24
		sb.border_color = Color("#2A2A33")
		sb.border_width_left = 1
		sb.border_width_top = 1
		sb.border_width_right = 1
		sb.border_width_bottom = 1
	else:
		sb.border_color = Color.TRANSPARENT
		sb.shadow_size = 0
	phone_container.add_theme_stylebox_override("panel", sb)

	# Обновляем галерею колонки в зависимости от ширины
	_update_gallery_columns(phone_w)

func _update_gallery_columns(phone_width: float) -> void:
	# Находим галерею и меняем колонки
	var gal_grid: GridContainer = get_node_or_null("AdaptiveRoot/PhoneContainer/PhoneVBox/Content/Gallery/VBox/Scroll/Grid")
	if gal_grid:
		if phone_width >= 500:
			gal_grid.columns = 3
		elif phone_width >= 360:
			gal_grid.columns = 2
		else:
			gal_grid.columns = 2

func _update_gallery_button() -> void:
	var gallery_mgr = get_node_or_null("/root/GalleryManager")
	var chat_data = get_node_or_null("/root/ChatData")
	var unlocked: int = 0
	var total: int = 5
	var unread: int = 0
	if gallery_mgr:
		unlocked = gallery_mgr.get_unlocked_count()
		total = gallery_mgr.get_total_count()
	if chat_data:
		unread = chat_data.get_total_unread()
	gallery_btn.text = "🖼️ Галерея • %d/%d" % [unlocked, total]
	if unread > 0 and _active_screen != 0:
		chats_btn.text = "💬 Чаты • %d" % unread
	else:
		chats_btn.text = "💬 Чаты"
		if unread > 0 and _active_screen != 0:
			chats_btn.add_theme_color_override("font_color", Color("#FF6B8A"))

func _on_screen_changed(new_screen: int, payload: Variant) -> void:
	_apply_screen(new_screen, payload)

func _apply_screen(screen: int, payload: Variant = null) -> void:
	_active_screen = screen
	chat_list.visible = false
	gallery.visible = false
	chat_view.visible = false
	bottom_nav.visible = true

	match screen:
		0: # CHATS
			chat_list.visible = true
		1: # GALLERY
			gallery.visible = true
		2: # CHAT_VIEW
			chat_view.visible = true
			bottom_nav.visible = false
			if payload is String:
				chat_view.call_deferred("setup", payload)
			chat_view.position.x = 40
			chat_view.modulate.a = 0.0
			var tween := create_tween()
			tween.tween_property(chat_view, "position:x", 0, 0.2).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
			tween.parallel().tween_property(chat_view, "modulate:a", 1.0, 0.2)

	_update_nav_visuals()
	_update_gallery_button()

	var gm = get_node_or_null("/root/GameManager")
	if gm and gm.is_yandex_env and OS.has_feature("web") and Engine.has_singleton("JavaScriptBridge"):
		var js = Engine.get_singleton("JavaScriptBridge")
		js.eval("if(window.ysdk) window.ysdk.features.LoadingAPI && window.ysdk.features.LoadingAPI.ready();", true)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_back") or (event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE):
		if _active_screen == 2:
			var gm = get_node_or_null("/root/GameManager")
			if gm: gm.go_back_to_chats()
			get_viewport().set_input_as_handled()

func _setup_web_back() -> void:
	pass
