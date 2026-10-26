extends Control

@onready var grid: GridContainer = $VBox/Scroll/Grid
@onready var subtitle: Label = $VBox/Header/Margin/VBox2/Subtitle
@onready var hint: Label = $VBox/Hint

func _ready() -> void:
	GalleryManager.gallery_updated.connect(_refresh)
	_refresh()

func _refresh() -> void:
	for child in grid.get_children():
		child.queue_free()

	var unlocked := GalleryManager.get_unlocked_count()
	var total := GalleryManager.get_total_count()
	subtitle.text = "%d / %d фото получено" % [unlocked, total]

	for char_id in GalleryManager.photos.keys():
		var data: Dictionary = GalleryManager.photos[char_id]
		var item := _create_item(char_id, data)
		grid.add_child(item)

	# отступы для грида
	grid.add_theme_constant_override("h_separation", 12)
	grid.add_theme_constant_override("v_separation", 12)
	# паддинг через контейнер
	var scroll := $VBox/Scroll
	scroll.add_theme_constant_override("scrollbar_margin_left", 0)

func _create_item(char_id: String, data: Dictionary) -> Control:
	var panel := PanelContainer.new()
	var base_sb := StyleBoxFlat.new()
	var is_unlocked: bool = data.get("unlocked", false)
	if is_unlocked:
		base_sb.bg_color = Color("#22222A")
		base_sb.border_color = Color("#7B61FF")
		base_sb.border_width_left = 2
		base_sb.border_width_top = 2
		base_sb.border_width_right = 2
		base_sb.border_width_bottom = 2
	else:
		base_sb.bg_color = Color("#1E1E24")
		base_sb.border_color = Color("#2A2A33")
		base_sb.border_width_left = 1
		base_sb.border_width_top = 1
		base_sb.border_width_right = 1
		base_sb.border_width_bottom = 1
	base_sb.corner_radius_top_left = 16
	base_sb.corner_radius_top_right = 16
	base_sb.corner_radius_bottom_right = 16
	base_sb.corner_radius_bottom_left = 16
	panel.add_theme_stylebox_override("panel", base_sb)
	panel.custom_minimum_size = Vector2(0, 170)
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var vbox := VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	panel.add_child(vbox)

	var wrap := Control.new()
	wrap.custom_minimum_size = Vector2(0, 120)
	wrap.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	wrap.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(wrap)

	var bg := ColorRect.new()
	bg.color = Color("#262631") if is_unlocked else Color("#1C1C22")
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bg.size_flags_vertical = Control.SIZE_EXPAND_FILL
	# скругление через shader? пока без
	wrap.add_child(bg)

	var icon := Label.new()
	icon.set_anchors_preset(Control.PRESET_FULL_RECT)
	icon.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	icon.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	icon.add_theme_font_size_override("font_size", 32 if is_unlocked else 26)
	if is_unlocked:
		# если есть реальная текстура - покажем её, иначе иконку
		var tex_path: String = data.get("texture_path", "")
		var tex := GalleryManager.try_load_texture(tex_path)
		if tex:
			var tr := TextureRect.new()
			tr.texture = tex
			tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
			tr.set_anchors_preset(Control.PRESET_FULL_RECT)
			bg.add_child(tr)
			icon.text = ""
		else:
			icon.text = "🖼️"
			icon.add_theme_color_override("font_color", Color.WHITE)
			bg.add_child(icon)
	else:
		icon.text = "🔒"
		icon.add_theme_color_override("font_color", Color("#7A7A8A"))
		bg.add_child(icon)

	var name_lbl := Label.new()
	name_lbl.text = data.get("character_name", char_id)
	name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_lbl.add_theme_font_size_override("font_size", 13)
	name_lbl.add_theme_color_override("font_color", Color("#ECECF1") if is_unlocked else Color("#A8A8B5"))
	vbox.add_child(name_lbl)

	var status_lbl := Label.new()
	status_lbl.text = "получено ✓" if is_unlocked else "заблокировано"
	status_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status_lbl.add_theme_font_size_override("font_size", 11)
	status_lbl.add_theme_color_override("font_color", Color("#00D68F") if is_unlocked else Color("#6B6B7A"))
	vbox.add_child(status_lbl)

	if is_unlocked:
		panel.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		panel.gui_input.connect(func(event: InputEvent):
			if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
				_on_photo_clicked(char_id)
		)

	# лёгкая анимация появления
	panel.modulate.a = 0.0
	var tween := create_tween()
	tween.tween_property(panel, "modulate:a", 1.0, 0.2)

	return panel

func _on_photo_clicked(char_id: String) -> void:
	# позже откроем полноэкранный просмотр
	var data: Dictionary = GalleryManager.photos.get(char_id, {})
	print("Открыть фото: ", data.get("title", char_id))
