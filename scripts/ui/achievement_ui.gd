extends CanvasLayer

var achievements: Array = []
var is_open: bool = false

var bg: ColorRect
var title: Label
var list: ItemList
var close_btn: Button

func _ready():
	# 手动创建 UI 节点
	bg = ColorRect.new()
	bg.color = Color(0.12, 0.12, 0.16, 0.92)
	bg.anchor_right = 1.0
	bg.anchor_bottom = 1.0
	add_child(bg)
	
	title = Label.new()
	title.text = "🏆 Achievements"
	title.add_theme_font_size_override("font_size", 20)
	title.add_theme_color_override("font_color", Color("#ffd700"))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.position = Vector2(250, 90)
	title.size = Vector2(300, 30)
	add_child(title)
	
	list = ItemList.new()
	list.position = Vector2(170, 130)
	list.size = Vector2(460, 350)
	list.fixed_icon_size = Vector2(32, 32)
	list.add_theme_color_override("font_color", Color(1, 1, 1, 0.8))
	list.add_theme_color_override("selection_color", Color(0.3, 0.5, 0.3, 0.4))
	add_child(list)
	
	close_btn = Button.new()
	close_btn.text = "Close"
	close_btn.position = Vector2(320, 540)
	close_btn.size = Vector2(160, 28)
	close_btn.pressed.connect(_close)
	add_child(close_btn)
	
	hide()
	_build_list()

func open():
	if is_open: return
	is_open = true
	_build_list()
	show()

func _close():
	is_open = false
	hide()

func unlock(achievement_id: String) -> void:
	for a in achievements:
		if a.id == achievement_id:
			if a.unlocked: return
			a.unlocked = true
			if is_open: _build_list()
			_show_notification(a.title)
			return

func _build_list():
	list.clear()
	for a in achievements:
		var icon = _get_icon(a.unlocked)
		var txt = ("✅ " if a.unlocked else "🔒 ") + a.title + "\n  " + a.desc
		list.add_item(txt, icon)

func _get_icon(unlocked: bool) -> ImageTexture:
	if unlocked:
		var img = Image.create(32, 32, false, Image.FORMAT_RGBA8)
		img.fill(Color(1, 0.84, 0, 0.3))
		return ImageTexture.create_from_image(img)
	return ImageTexture.create_from_image(Image.create(32, 32, false, Image.FORMAT_RGBA8))

func _show_notification(text: String):
	var label = Label.new()
	label.text = "🏆 " + text
	label.add_theme_font_size_override("font_size", 16)
	label.add_theme_color_override("font_color", Color("#ffd700"))
	label.position = Vector2(200, 300)
	label.z_index = 100
	get_tree().current_scene.add_child(label)
	get_tree().create_timer(2.5).timeout.connect(func():
		if is_instance_valid(label): label.queue_free()
	)
