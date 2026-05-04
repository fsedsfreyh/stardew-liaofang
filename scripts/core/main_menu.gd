extends Control

const _PaletteDemo = preload("res://scripts/core/palette_demo.gd")

func _ready():
	size = Vector2(1280, 720)
	# 主菜单启动时输出调色板验证图（在 Godot 控制台可看到）
	_PaletteDemo.run()
	
	call_deferred("_deferred_init")

func _deferred_init():
	if AudioManager: AudioManager.on_scene_changed("menu")
	_generate_background()
	
	var new_btn = _make_button("Start New Farm", 490, 340)
	new_btn.pressed.connect(_on_new_game)
	add_child(new_btn)

	var ver = Label.new()
	ver.position = Vector2(0, 690)
	ver.size = Vector2(1280, 30)
	ver.add_theme_font_size_override("font_size", 10)
	ver.add_theme_color_override("font_color", Color(1, 1, 1, 0.2))
	ver.text = "Stardew-Liaofang v0.2"
	ver.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(ver)
	
	call_deferred("_queue_draw")
	get_tree().create_timer(1.5).timeout.connect(_on_new_game)

func _queue_draw():
	queue_redraw()

func _make_button(text: String, x: int, y: int) -> Button:
	var btn = Button.new()
	btn.position = Vector2(x, y)
	btn.size = Vector2(220, 48)
	btn.add_theme_font_size_override("font_size", 18)
	btn.add_theme_color_override("font_color", Color.WHITE)
	btn.add_theme_stylebox_override("normal", _style(Color("#3a5a3a")))
	return btn

func _style(bg: Color) -> StyleBoxFlat:
	var sb = StyleBoxFlat.new()
	sb.bg_color = bg
	sb.corner_radius_top_left = 6
	sb.corner_radius_top_right = 6
	sb.corner_radius_bottom_left = 6
	sb.corner_radius_bottom_right = 6
	sb.content_margin_left = 12
	sb.content_margin_right = 12
	sb.content_margin_top = 4
	sb.content_margin_bottom = 4
	return sb

func _generate_background():
	for x in range(26):
		for y in range(23):
			var sprite = Sprite2D.new()
			sprite.position = Vector2(x * 32 + 16, y * 32 + 16)
			var v = (x * 7 + y * 13) % 100
			var tile_type = "grass"
			if x < 2 or x >= 24 or y < 1 or y >= 22: tile_type = "water"
			elif (x == 3 or x == 22) and y > 2 and y < 20: tile_type = "fence"
			elif (x >= 6 and x <= 8) and (y >= 4 and y <= 6): tile_type = "house_wall"
			elif (x >= 6 and x <= 8) and y == 3: tile_type = "house_roof"
			elif (x == 7 and y == 7): tile_type = "door"
			elif x >= 10 and x <= 12 and (y in [8, 12]): tile_type = "path"
			elif x >= 10 and x <= 12 and y >= 9 and y <= 11: tile_type = "water" if y % 2 == 0 else "flower_bed"
			elif x >= 16 and x <= 18 and (y >= 4 and y <= 6): tile_type = "house_wall"
			elif (x >= 16 and x <= 18) and y == 3: tile_type = "house_roof"
			elif x == 17 and y == 7: tile_type = "door"
			elif x == 21 and y == 18: tile_type = "tree"
			elif x == 4 and y == 14: tile_type = "tree"
			elif v > 90: tile_type = "flower_bed"
			sprite.texture = PixelArtist.generate_tile(tile_type, v)
			sprite.scale = Vector2(0.5, 0.5)
			sprite.modulate = Color(1, 1, 1, 0.05)
			add_child(sprite)

func _draw():
	var cx = size.x / 2.0
	draw_rect(Rect2(0, 0, size.x, size.y), Color(0.165, 0.102, 0.039))
	draw_rect(Rect2(cx - 260, 60, 520, 120), Color("#d4af5a"), true)
	draw_rect(Rect2(cx - 200, 145, 400, 30), Color("#d4af5a"), true)
	draw_rect(Rect2(cx - 120, 280, 240, 40), Color("#d4af5a"), true)

func _on_new_game():
	DayTime.set_time(6, 0)
	DayTime.current_day = 1
	DayTime.current_season = 0
	DayTime.current_year = 1
	Global.player_pos = Vector2(480, 960)
	Global.current_scene = "farm"
	
	var root = get_tree().root
	var farm_packed = preload("res://scenes/farm/farm_scene.tscn")
	var farm = farm_packed.instantiate()
	root.add_child(farm)
	queue_free()