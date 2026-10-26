@tool
extends Control
## Главный контроллер интерфейса. Адаптивный + редактируемый в редакторе.
## Как двигать интерфейс в движке:
## 1. Выбери узел Main в сцене — в Инспекторе есть группы:
##    - Manual Layout → включи manual_layout=true чтобы отключить авто-позиционирование и двигать PhoneContainer вручную мышкой/якорями.
##    - Adaptive Layout → настройки ширин/фонов/скруглений (меняются и в редакторе, и в игре).
## 2. Чтобы двигать отдельные элементы (шапку, список чатов, кнопки):
##    - Открой сцены сцены: scenes/main_menu/ChatList.tscn, scenes/gallery/Gallery.tscn, scenes/chat/ChatView.tscn
##    - Или раскрой LayoutCenter/PhoneContainer в Main и двигай Header/BottomNav/Rect напрямую.
## 3. Чтобы менять положение всего окна чата на экране: выбери LayoutCenter/PhoneContainer и меняй anchors/offset'ы,
##    но оставь manual_layout=false чтобы адаптив не перетирал твои правки при ресайзе (включи manual).

@onready var layout_center: CenterContainer = $LayoutCenter
@onready var phone_container: Panel = $LayoutCenter/PhoneContainer
@onready var phone_vbox: VBoxContainer = $LayoutCenter/PhoneContainer/PhoneVBox
@onready var chat_list: Control = $LayoutCenter/PhoneContainer/PhoneVBox/Content/ChatList
@onready var gallery: Control = $LayoutCenter/PhoneContainer/PhoneVBox/Content/Gallery
@onready var chat_view: Control = $LayoutCenter/PhoneContainer/PhoneVBox/Content/ChatView
@onready var bottom_nav: Panel = $LayoutCenter/PhoneContainer/PhoneVBox/BottomNav
@onready var chats_btn: Button = $LayoutCenter/PhoneContainer/PhoneVBox/BottomNav/NavHBox/ChatsBtn
@onready var gallery_btn: Button = $LayoutCenter/PhoneContainer/PhoneVBox/BottomNav/NavHBox/GalleryBtn
@onready var bg_rect: ColorRect = $Bg
@onready var bg_gradient: ColorRect = $BgGradient

var _active_screen: int = 0 # 0=CHATS, 1=GALLERY, 2=CHAT_VIEW
var _is_desktop_mode: bool = false

# ──────────────────────────────────────────────────────────────────────────────
# Настройки, которые можно крутить в инспекторе прямо в движке
# ──────────────────────────────────────────────────────────────────────────────
@export_group("Adaptive Layout")
@export var enable_adaptive: bool = true:
	set(v):
		enable_adaptive = v
		if is_inside_tree():
			_update_layout()
@export var max_phone_width_desktop: int = 980:
	set(v):
		max_phone_width_desktop = v
		if is_inside_tree(): _update_layout()
@export var max_phone_width_tablet: int = 720:
	set(v):
		max_phone_width_tablet = v
		if is_inside_tree(): _update_layout()
@export var max_phone_height: int = 960:
	set(v):
		max_phone_height = v
		if is_inside_tree(): _update_layout()
@export_range(0.5, 1.0, 0.01) var desktop_width_factor_large: float = 0.65:
	set(v):
		desktop_width_factor_large = v
		if is_inside_tree(): _update_layout()
@export_range(0.5, 1.0, 0.01) var desktop_width_factor_mid: float = 0.75:
	set(v):
		desktop_width_factor_mid = v
		if is_inside_tree(): _update_layout()

@export_group("Manual Layout")
## Включи чтобы двигать PhoneContainer вручную в редакторе/игре без авто-перетирания
@export var manual_layout: bool = false:
	set(v):
		manual_layout = v
		notify_property_list_changed()
		if is_inside_tree():
			_update_layout()
## Если manual_layout включен — можно задать ручное смещение (для позиционирования окна)
@export var manual_offset: Vector2 = Vector2.ZERO:
	set(v):
		manual_offset = v
		if manual_layout and is_inside_tree():
			_update_layout()
@export var manual_size: Vector2 = Vector2(560, 960):
	set(v):
		manual_size = v
		if manual_layout and is_inside_tree():
			_update_layout()

@export_group("BG Color")
@export var bg_color_mobile: Color = Color("#16161A"):
	set(v):
		bg_color_mobile = v
		if is_inside_tree(): _update_layout()
@export var bg_color_desktop: Color = Color("#08080E"):
	set(v):
		bg_color_desktop = v
		if is_inside_tree(): _update_layout()
@export var bg_gradient_desktop: Color = Color(0.14, 0.10, 0.32, 0.22):
	set(v):
		bg_gradient_desktop = v
		if is_inside_tree(): _update_layout()

func _ready() -> void:
	_setup_font()
	_style_nav()
	_style_nav_buttons()
	_style_phone_container()

	if not Engine.is_editor_hint():
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

		if OS.has_feature("web"):
			_setup_web_back()

		get_viewport().size_changed.connect(_update_layout)
		_update_layout()
		await get_tree().create_timer(0.1).timeout
		_update_layout()
	else:
		# В редакторе тоже показываем адаптив
		_update_layout()

func _process(_delta: float) -> void:
	# В редакторе обновляем при изменении размера вьюпорта (чтобы ресайз окна редактора был виден)
	if Engine.is_editor_hint() and enable_adaptive and not manual_layout:
		# Легкий троттлинг - проверяем каждый кадр но не тяжело
		pass

func _validate_property(property: Dictionary) -> void:
	if property.name == "manual_offset" or property.name == "manual_size":
		if not manual_layout:
			property.usage |= PROPERTY_USAGE_READ_ONLY

func _setup_font() -> void:
	var font_path := "res://assets/fonts/Inter-Variable.ttf"
	var font_file := FontFile.new()
	var err := font_file.load_dynamic_font(font_path)
	var theme_override: Theme
	if err == OK and font_file != null:
		if theme != null:
			theme_override = theme.duplicate() as Theme
		else:
			theme_override = Theme.new()
		theme_override.default_font = font_file
		theme_override.default_font_size = 14
		theme = theme_override
	else:
		if theme != null and theme.default_font == null:
			theme = null

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
		if not is_instance_valid(btn):
			continue
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
	# Если включен ручной режим — не трогаем позиции, можно двигать в редакторе свободно
	if manual_layout:
		# Применяем ручной размер/смещение если заданы
		if manual_size != Vector2.ZERO:
			phone_container.custom_minimum_size = manual_size
			# Для CenterContainer: custom_minimum_size определяет размер, центрирование делает сам контейнер
		if manual_offset != Vector2.ZERO:
			# Смещение через позицию не работает напрямую в CenterContainer, 
			# но можем добавить патч через дополнительный Margin
			phone_container.position += manual_offset
		# Фон всё равно обновим по размеру окна
		var vp_size_m := get_viewport_rect().size
		if DisplayServer.window_get_size() != Vector2i.ZERO:
			var ws_m := Vector2(DisplayServer.window_get_size())
			if ws_m.x > 0 and ws_m.y > 0:
				vp_size_m = ws_m
		_is_desktop_mode = vp_size_m.x >= 800 or (vp_size_m.x > vp_size_m.y and vp_size_m.x >= 650)
		var sb_m := StyleBoxFlat.new()
		sb_m.bg_color = Color("#16161A")
		sb_m.border_color = Color("#2A2A33") if _is_desktop_mode else Color.TRANSPARENT
		sb_m.border_width_left = 1 if _is_desktop_mode else 0
		sb_m.border_width_top = 1 if _is_desktop_mode else 0
		sb_m.border_width_right = 1 if _is_desktop_mode else 0
		sb_m.border_width_bottom = 1 if _is_desktop_mode else 0
		sb_m.corner_radius_top_left = 16 if _is_desktop_mode else 0
		sb_m.corner_radius_top_right = 16 if _is_desktop_mode else 0
		sb_m.corner_radius_bottom_right = 16 if _is_desktop_mode else 0
		sb_m.corner_radius_bottom_left = 16 if _is_desktop_mode else 0
		if _is_desktop_mode:
			sb_m.shadow_color = Color(0, 0, 0, 0.55)
			sb_m.shadow_size = 28
		phone_container.add_theme_stylebox_override("panel", sb_m)
		return

	if not enable_adaptive:
		# Адаптив выключен — используем как есть в сцене, только фон подстроим
		phone_container.custom_minimum_size = Vector2(max_phone_width_desktop, max_phone_height)
		return

	var vp_size: Vector2 = get_viewport_rect().size
	# В рантайме на вебе точнее window size
	if not Engine.is_editor_hint() and DisplayServer.window_get_size() != Vector2i.ZERO:
		var win_size := Vector2(DisplayServer.window_get_size())
		if win_size.x > 0 and win_size.y > 0:
			vp_size = win_size
	# В редакторе viewport_rect уже корректен

	var win_w: float = vp_size.x
	var win_h: float = vp_size.y
	var is_desktop: bool = win_w >= 800 or (win_w > win_h and win_w >= 650)
	_is_desktop_mode = is_desktop

	var phone_w: float = win_w
	var phone_h: float = win_h
	var corner_radius: int = 0
	var shadow_enabled: bool = false

	if is_desktop:
		if win_w >= 1200:
			phone_w = minf(win_w * desktop_width_factor_large, max_phone_width_desktop)
		elif win_w >= 900:
			phone_w = minf(win_w * desktop_width_factor_mid, max_phone_width_desktop)
		else:
			phone_w = minf(win_w * 0.85, max_phone_width_tablet)
		if win_h > 850:
			phone_h = minf(win_h * 0.88, max_phone_height)
			corner_radius = 20
			shadow_enabled = true
		else:
			phone_h = win_h
			corner_radius = 16 if win_w > 900 else 0
			shadow_enabled = true
		bg_rect.color = bg_color_desktop
		bg_gradient.visible = true
		bg_gradient.color = bg_gradient_desktop
	else:
		phone_w = win_w
		phone_h = win_h
		corner_radius = 0
		shadow_enabled = false
		bg_rect.color = bg_color_mobile
		bg_gradient.visible = false

	# Теперь используем CenterContainer логику: размер через custom_minimum_size, центрирование делает контейнер
	# Это позволяет двигать в редакторе через LayoutCenter аллайн, и не ломает ручной режим
	phone_container.custom_minimum_size = Vector2(phone_w, phone_h)
	# На всякий случай сбрасываем позицию если была сдвинута manual
	if not Engine.is_editor_hint():
		phone_container.position = Vector2.ZERO

	var sb := StyleBoxFlat.new()
	sb.bg_color = Color("#16161A")
	sb.corner_radius_top_left = corner_radius
	sb.corner_radius_top_right = corner_radius
	sb.corner_radius_bottom_right = corner_radius
	sb.corner_radius_bottom_left = corner_radius
	if shadow_enabled:
		sb.shadow_color = Color(0, 0, 0, 0.55)
		sb.shadow_size = 28
		sb.border_color = Color("#2A2A33")
		sb.border_width_left = 1
		sb.border_width_top = 1
		sb.border_width_right = 1
		sb.border_width_bottom = 1
	else:
		sb.border_color = Color.TRANSPARENT
		sb.shadow_size = 0
	phone_container.add_theme_stylebox_override("panel", sb)

	_update_gallery_columns(phone_w)

func _update_gallery_columns(phone_width: float) -> void:
	var gal_grid: GridContainer = get_node_or_null("LayoutCenter/PhoneContainer/PhoneVBox/Content/Gallery/VBox/Scroll/Grid")
	if gal_grid:
		if phone_width >= 860:
			gal_grid.columns = 4
		elif phone_width >= 620:
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
	if is_instance_valid(gallery_btn):
		gallery_btn.text = "🖼️ Галерея • %d/%d" % [unlocked, total]
	if is_instance_valid(chats_btn):
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
	if is_instance_valid(chat_list): chat_list.visible = false
	if is_instance_valid(gallery): gallery.visible = false
	if is_instance_valid(chat_view): chat_view.visible = false
	if is_instance_valid(bottom_nav): bottom_nav.visible = true

	match screen:
		0: # CHATS
			if is_instance_valid(chat_list): chat_list.visible = true
		1: # GALLERY
			if is_instance_valid(gallery): gallery.visible = true
		2: # CHAT_VIEW
			if is_instance_valid(chat_view):
				chat_view.visible = true
			if is_instance_valid(bottom_nav): bottom_nav.visible = false
			if payload is String and is_instance_valid(chat_view):
				chat_view.call_deferred("setup", payload)
			if is_instance_valid(chat_view):
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
