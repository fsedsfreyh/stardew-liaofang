# MineScene —— 矿洞场景（战斗 + 矿石采集原型）


const MAP_W = 30
const MAP_H = 30
const TILE_SIZE = 32
const ZOOM = 1.5

# wall:0 floor:1 ore:2 enemy:3 exit:4 ladder:5
var map_data: Array = []
var player: Node = null
var current_floor: int = 1
var monsters: Array = []
var ore_nodes: Array = []

func _ready():
	
	_generate_floor()
	_setup_player()
	_setup_hud()
	_setup_connections()

func _generate_floor():
	map_data.clear()
	# 娓呯┖鏃ц妭鐐"	for c in $Entities.get_children():
		c.queue_free()
	for c in $Tiles.get_children():
		c.queue_free()
	
	# 鍩虹锛氬洓鍛ㄥ澹"+ 鍐呴儴闅忔満
	for y in range(MAP_H):
		var row = []
		for x in range(MAP_W):
			if x == 0 or x == MAP_W-1 or y == 0 or y == MAP_H-1:
				row.append(0)  # wall
			elif randf() < 0.2:
				row.append(0)  # occasional inner wall
			else:
				row.append(1)  # floor
		map_data.append(row)
	
	# 鐭跨煶锛"-8涓級
	var ore_count = randi_range(5, 8)
	for i in range(ore_count):
		_place_random(2)
	
	# 鎬墿锛"-5涓級
	var mob_count = 2 + current_floor / 2
	for i in range(mob_count):
		_place_random(3)
	
	# 鍑哄彛锛堝乏涓婏級
	map_data[1][1] = 4
	# 妤兼锛堝彸涓嬶級
	_place_ladder()
	
	# 娓叉煋
	for y in range(MAP_H):
		for x in range(MAP_W):
			var t = map_data[y][x]
			var tile_type = "stone_wall" if t == 0 else "stone_floor"
			if t == 2: tile_type = "ore_rock"
			elif t == 3: tile_type = "stone_floor"
			elif t == 4: tile_type = "stone_floor"
			
			var sprite = Sprite2D.new()
			sprite.position = Vector2(x * TILE_SIZE * ZOOM, y * TILE_SIZE * ZOOM)
			sprite.texture = _get_tile_tex(tile_type)
			$Tiles.add_child(sprite)
	
	# 鐭跨煶绮剧伒
	ore_nodes.clear()
	for y in range(MAP_H):
		for x in range(MAP_W):
			if map_data[y][x] == 2:
				var ore_sprite = Sprite2D.new()
				ore_sprite.name = "Ore_%d_%d" % [x, y]
				ore_sprite.position = Vector2(x * TILE_SIZE * ZOOM, y * TILE_SIZE * ZOOM) + Vector2(16 * ZOOM, 16 * ZOOM)
				ore_sprite.texture = _get_tile_tex("ore_node")
				ore_sprite.z_index = 2
				$Entities.add_child(ore_sprite)
				ore_nodes.append(ore_sprite)
	
	# 鏁屼汉
	for child in $Entities.get_children():
		if child.name.begins_with("Slime"): child.queue_free()
	
	monsters.clear()
	for y in range(MAP_H):
		for x in range(MAP_W):
			if map_data[y][x] == 3:
				var slime = CharacterBody2D.new()
				slime.name = "Slime_%d_%d" % [x, y]
				slime.position = Vector2(x * TILE_SIZE * ZOOM, y * TILE_SIZE * ZOOM) + Vector2(16 * ZOOM, 16 * ZOOM)
				slime.z_index = 1
				
				var sprite = Sprite2D.new()
				sprite.name = "Sprite2D"
				sprite.texture = _make_slime_sprite()
				slime.add_child(sprite)
				
				var col = CollisionShape2D.new()
				var rect = RectangleShape2D.new()
				rect.size = Vector2(12 * ZOOM, 10 * ZOOM)
				col.shape = rect
				slime.add_child(col)
				
				slime.set_meta("hp", 2 + current_floor)
				slime.set_meta("speed", randf_range(15.0, 30.0))
				slime.set_meta("dir", Vector2(randf_range(-1,1), randf_range(-1,1)).normalized())
				slime.set_meta("aggro_range", 80.0)
				slime.add_to_group("enemies")
				$Entities.add_child(slime)
				monsters.append(slime)

func _place_random(tile: int):
	for attempt in range(50):
		var x = randi_range(2, MAP_W-3)
		var y = randi_range(2, MAP_H-3)
		if map_data[y][x] == 1:
			map_data[y][x] = tile
			return

func _place_ladder():
	for y in range(MAP_H-2, 1, -1):
		for x in range(MAP_W-2, 1, -1):
			if map_data[y][x] == 1:
				map_data[y][x] = 5
				var ls = Sprite2D.new()
				ls.name = "Ladder"
				ls.position = Vector2(x * TILE_SIZE * ZOOM, y * TILE_SIZE * ZOOM) + Vector2(16 * ZOOM, 16 * ZOOM)
				ls.texture = _get_tile_tex("ladder")
				ls.z_index = 0
				$Entities.add_child(ls)
				return

func _setup_player():
	var p = preload("res://scenes/world/player_scene.tscn").instantiate()
	p.position = Vector2(1 * TILE_SIZE * ZOOM, 1 * TILE_SIZE * ZOOM) + Vector2(16 * ZOOM, 16 * ZOOM)
	$Entities.add_child(p)
	player = p

func _setup_hud():
	var hud = get_node_or_null("MineHUD")
	if hud: return
	hud = CanvasLayer.new()
	hud.name = "MineHUD"
	add_child(hud)
	
	var floor_label = Label.new()
	floor_label.name = "FloorLabel"
	floor_label.position = Vector2(10, 10)
	floor_label.add_theme_color_override("font_color", Color.WHITE)
	floor_label.add_theme_font_size_override("font_size", 14)
	hud.add_child(floor_label)
	_update_floor_label()
	
	var hp_label = Label.new()
	hp_label.name = "HPLabel"
	hp_label.position = Vector2(10, 30)
	hp_label.add_theme_color_override("font_color", Color("#ff6666"))
	hp_label.add_theme_font_size_override("font_size", 12)
	hp_label.text = "鉂"10/10"
	hud.add_child(hp_label)
	
	var exit_hint = Label.new()
	exit_hint.name = "ExitHint"
	exit_hint.position = Vector2(10, 550)
	exit_hint.add_theme_color_override("font_color", Color("#ffd700"))
	exit_hint.add_theme_font_size_override("font_size", 12)
	exit_hint.text = "馃敊 宸︿笅瑙掑嚭鍙ｅ洖鍐滃満"
	hud.add_child(exit_hint)

func _setup_connections():
	get_tree().create_timer(0.5).timeout.connect(_start_enemy_ai)

func _start_enemy_ai():
	while is_inside_tree():
		for slime in monsters:
			if not is_instance_valid(slime): continue
			_slime_ai(slime)
		await get_tree().create_timer(0.5).timeout

func _slime_ai(slime: Node):
	if not player: return
	if not is_instance_valid(slime): return
	var dist = slime.global_position.distance_to(player.global_position)
	
	if dist < slime.get_meta("aggro_range"):
		# 杩藉嚮鐜╁
		var dir = (player.global_position - slime.global_position).normalized()
		slime.global_position += dir * slime.get_meta("speed") * 0.5
	else:
		# 闅忔満绉诲姩
		var d = slime.get_meta("dir")
		if randf() < 0.1:
			d = Vector2(randf_range(-1,1), randf_range(-1,1)).normalized()
			slime.set_meta("dir", d)
		slime.global_position += d * 15.0 * 0.5

func _process(_delta):
	if not player or not is_instance_valid(player): return
	# 妫€鏌ユゼ姊氦浜"	if Input.is_action_just_pressed("player_interact"):
		_check_ladder()
	
	# 宸﹂敭鏀诲嚮
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		_attack_nearby()

	var hp_label = get_node_or_null("MineHUD/HPLabel")
	if hp_label and is_instance_valid(player) and player.has_method("get"):
		hp_label.text = "鉂"%d/10" % player.get("hp", 10)
	else:
		Global.current_scene = "farm"
		get_tree().change_scene_to_file("res://scenes/farm/farm_scene.tscn")
		return

func _check_ladder():
	var pos = player.global_position
	for child in $Entities.get_children():
		if child.name == "Ladder" and is_instance_valid(child):
			if pos.distance_to(child.global_position) < 30 * ZOOM:
				current_floor += 1
				if current_floor > Global.stats.get("mine_max_floor", 1):
					Global.stats["mine_max_floor"] = current_floor
				_generate_floor()
				player.position = Vector2(1 * TILE_SIZE * ZOOM, 1 * TILE_SIZE * ZOOM) + Vector2(16 * ZOOM, 16 * ZOOM)
				_update_floor_label()
				return
	
	# 鍑哄彛 鈫"鍥炲啘鍦"	for y in range(MAP_H):
		for x in range(MAP_W):
			if map_data[y][x] == 4:
				var exit_pos = Vector2(x * TILE_SIZE * ZOOM, y * TILE_SIZE * ZOOM) + Vector2(16 * ZOOM, 16 * ZOOM)
				if pos.distance_to(exit_pos) < 30 * ZOOM:
					Global.player_pos = Vector2(480, 400)
					Global.current_scene = "farm"
					get_tree().change_scene_to_file("res://scenes/farm/farm_scene.tscn")
					return

func _attack_nearby():
	if not player: return
	var pos = player.global_position
	for slime in monsters:
		if not is_instance_valid(slime): continue
		if pos.distance_to(slime.global_position) < 25 * ZOOM:
			var hp = slime.get_meta("hp") - 1
			slime.set_meta("hp", hp)
			# 鍑婚€€
			var kb_dir = (slime.global_position - pos).normalized()
			slime.global_position += kb_dir * 10.0
			
			if hp <= 0:
				_on_slime_killed(slime)
			break

func _on_slime_killed(slime: Node):
	# 鎺夎惤
	var drops = ["coal", "gold_ore", "diamond", "mushroom"]
	var drop = drops[randi() % drops.size()]
	Inventory.add_item(drop, randi_range(1, 3))
	
	var hint = Label.new()
	hint.text = "馃拃 +%s" % drop
	hint.position = slime.global_position - Vector2(20, 10)
	hint.add_theme_color_override("font_color", Color("#ffd700"))
	hint.add_theme_font_size_override("font_size", 10)
	hint.z_index = 10
	add_child(hint)
	get_tree().create_timer(0.8).timeout.connect(func():
		if is_instance_valid(hint): hint.queue_free()
	)
	
	slime.queue_free()
	monsters.erase(slime)

func _update_floor_label():
	var fl = get_node_or_null("MineHUD/FloorLabel")
	if fl: fl.text = "⛏ 矿洞 %d层"灞" % current_floor

func _get_tile_tex(type: String) -> ImageTexture:
	var img = PixelArtist.create(16, 16)
	match type:
		"stone_wall":
			PixelArtist.r(img, 0, 0, 16, 16, Color("#4a4a5a"))
			PixelArtist.r(img, 0, 0, 16, 2, Color("#5a5a6a"))
			_ore_dots(img)
		"stone_floor":
			PixelArtist.r(img, 0, 0, 16, 16, Color("#555560"))
			for i in range(8):
				var sx = randf_range(1, 14)
				var sy = randf_range(1, 14)
				PixelArtist.p(img, sx, sy, Color("#606070"))
				PixelArtist.p(img, sx+1, sy, Color("#4a4a5a"))
		"ore_rock":
			PixelArtist.r(img, 0, 0, 16, 16, Color("#5a5a4a"))
			PixelArtist.r(img, 1, 1, 14, 14, Color("#4a4a3a"))
			_ore_dots(img)
		"ore_node":
			PixelArtist.r(img, 0, 0, 8, 8, Color("#7a7a6a"))
			var oc = [Color("#b0a030"), Color("#c0b040"), Color("#d0c050")]
			for i in range(3):
				var ox = randi() % 6 + 1
				var oy = randi() % 6 + 1
				PixelArtist.p(img, ox, oy, oc[i])
				PixelArtist.p(img, ox+1, oy, oc[i])
		"ladder":
			PixelArtist.r(img, 5, 0, 6, 16, Color("#8a7050"))
			PixelArtist.r(img, 8, 0, 2, 16, Color("#6a5030"))
			for y in range(0, 16, 4):
				PixelArtist.r(img, 5, y, 6, 2, Color("#9a8060"))
	return PixelArtist.to_tex(img)

func _ore_dots(img: Image):
	var colors = [Color("#8a8a7a"), Color("#7a7a6a"), Color("#6a6a5a")]
	for i in range(5):
		var x = randi() % 14 + 1
		var y = randi() % 14 + 1
		PixelArtist.p(img, x, y, colors[i % 3])

func _make_slime_sprite() -> ImageTexture:
	var img = PixelArtist.create(12, 10)
	var c = Color(0.3 + randf()*0.3, 0.2 + randf()*0.3, 0.5 + randf()*0.3)
	PixelArtist.r(img, 1, 2, 10, 8, c)
	PixelArtist.r(img, 0, 3, 12, 6, c)
	PixelArtist.r(img, 0, 3, 12, 1, Color(1, 1, 1, 0.2))
	PixelArtist.p(img, 3, 5, Color.WHITE)
	PixelArtist.p(img, 8, 5, Color.WHITE)
	PixelArtist.p(img, 3, 5, Color.BLACK)
	PixelArtist.p(img, 8, 5, Color.BLACK)
	return PixelArtist.to_tex(img)

func _unhandled_input(event):
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_ESCAPE:
			Global.player_pos = Vector2(480, 400)
			Global.current_scene = "farm"
			get_tree().change_scene_to_file("res://scenes/farm/farm_scene.tscn")


func _show_scene_tip(text: String):
	if not has_node("HUD"):
		return
	var hud = $HUD
	var label = Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.position = Vector2(300, 100)
	label.add_theme_font_size_override("font_size", 14)
	label.modulate = Color(1, 1, 1, 0)
	label.name = "SceneTip"
	for child in hud.get_children():
		if child.name == "SceneTip":
			child.queue_free()
	hud.add_child(label)
	var tween = create_tween()
	tween.tween_property(label, "modulate", Color(1, 1, 1, 1), 0.5)
	tween.tween_interval(3.0)
	tween.tween_property(label, "modulate", Color(1, 1, 1, 0), 1.0)
	tween.tween_callback(label.queue_free)


func _show_pickup_text(text: String):
	var hud = $HUD
	var label = Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.position = Vector2(200, 200)
	label.add_theme_font_size_override("font_size", 14)
	label.modulate = Color(1, 1, 0.5, 0)
	label.name = "PickupText_" + str(randi())
	hud.add_child(label)
	var tween = create_tween().set_parallel(true)
	tween.tween_property(label, "modulate", Color(1, 1, 0.5, 1), 0.3)
	tween.tween_property(label, "position:y", label.position.y - 30, 1.5)
	tween.tween_property(label, "modulate:a", 0, 1.5).set_delay(0.3)
	tween.tween_callback(label.queue_free)

var _show_minimap: bool = false

func _input(event):
    if event is InputEventKey and event.pressed and not event.echo:
        if event.keycode == KEY_M:
            _show_minimap = not _show_minimap
            queue_redraw()
    _input_base(event)

func _input_base(event):
    pass

func _draw():
    if _show_minimap:
        _draw_minimap()

func _draw_minimap():
    var mm_w = 20 * 4
    var mm_h = 20 * 4
    var mm_x = 10
    var mm_y = 10
    draw_rect(Rect2(mm_x - 2, mm_y - 2, mm_w + 4, mm_h + 4), Color(0.05, 0.05, 0.1, 0.8))
    
    # 绘制简略地图（用方形色块）
    var colors = {1: Color("#5c8f3c"), 2: Color("#8b7355"), 3: Color("#3a7a3a"),
                   4: Color("#a08050"), 5: Color("#887050"), 6: Color("#3870a0")}
	for y in range(MAP_H):
		for x in range(MAP_W):
            var k = 1
            if x < 2 or x >= 20 - 2 or y < 2 or y >= 20 - 2: k = 5
            elif x > 0.6 * 20: k = 3 if x > 0.6 * 20 else 1
            var c = colors.get(k, Color(0.15, 0.12, 0.08))
            draw_rect(Rect2(mm_x + x * 4, mm_y + y * 4, 4, 4), c, false)
    
    # 玩家位置
    var pl = get_node_or_null("Entities/Player")
    if pl:
        var px = mm_x + int(pl.global_position.x / 48) * 4
        var py = mm_y + int(pl.global_position.y / 48) * 4
        draw_circle(Vector2(px, py), 2.5, Color("#ffd700"))
