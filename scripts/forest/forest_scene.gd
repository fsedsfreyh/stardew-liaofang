# ForestScene —— 森林采集场景（8x28）


const MAP_W = 65
const MAP_H = 60
const TILE_SIZE = 32
const ZOOM = 1.5

# tile types: 0=grass, 1=dirt, 2=water, 3=tree, 4=flowers, 5=fence, 6=wall, 7=door, 8=path
var map_data: Array = []
var player: Node = null

# 鍙噰闆嗚祫婧" {global_position: {type: "flower"/"berry"/"mushroom"/"wood", count: int, spawn_id: int}}
var resource_spots: Dictionary = {}
var _respawn_timer: Timer = null

# 閲囬泦鍐峰嵈
var _harvest_cooldown: bool = false
const HARVEST_CD: float = 0.4

signal resource_collected(resource_type: String, count: int)

func _ready():
	
	_generate_map()
	_setup_players()
	_setup_hud()
	_setup_exits()
	_spawn_resources()
	
	_respawn_timer = Timer.new()
	_respawn_timer.wait_time = 300.0  # 5鍒嗛挓鍒锋柊
	_respawn_timer.autostart = true
	_respawn_timer.timeout.connect(_respawn_resources)
	add_child(_respawn_timer)
	
	# 瀛ｈ妭瑕嗙洊
	_apply_seasonal_overlay()
	# 澶╂皵鏁堟灉
	_update_weather_effects()
	DayTime.time_changed.connect(_on_weather_check)

func _on_weather_check(hour, minute, day, season, year):
	if minute == 0:
		_update_weather_effects()
func _generate_map():
	map_data.clear()
	for y in range(MAP_H):
		map_data.append([])
		for x in range(MAP_W):
			var tile = 0
			
			# Border fence (exits left open)
			if x < 1 or x >= MAP_W - 1 or y < 1 or y >= MAP_H - 1:
				tile = 5
			# Top exit to farm
			elif y == 1 and x >= 30 and x < 36:
				tile = 8
			# Right exit to town
			elif x == MAP_W - 2 and y >= 28 and y < 32:
				tile = 8
			# Bottom exit to secret woods / beach
			elif y == MAP_H - 2 and x >= 10 and x < 14:
				tile = 8
			
			# == MAIN POND (center area: 28-38, 30-42) ==
			elif x >= 28 and x < 38 and y >= 30 and y < 42:
				if x >= 29 and x < 37 and y >= 31 and y < 41:
					tile = 2  # water
				else:
					tile = 1  # muddy shore
			
			# Path around pond
			elif y == 42 and x >= 28 and x < 38:
				tile = 8
			elif y == 29 and x >= 28 and x < 38:
				tile = 8
			elif x == 28 and y >= 30 and y < 42:
				tile = 8
			elif x == 37 and y >= 30 and y < 42:
				tile = 8
			
			# == WIZARD TOWER AREA (top-right: 42-52, 4-16) ==
			elif x >= 42 and x < 52 and y >= 4 and y < 16:
				if x >= 44 and x < 50 and y >= 5 and y < 14:
					tile = 6  # tower wall
					if x >= 46 and x < 48 and y == 14:
						tile = 7  # door
				elif y == 4:
					tile = 9  # roof
				else:
					tile = 6
			
			# Path to wizard tower
			elif x >= 46 and x < 48 and y >= 16 and y < 18:
				tile = 8
			elif y == 18 and x >= 42 and x < 48:
				tile = 8
			
			# == DENSE FOREST AREA (left side: 2-12, 4-28) ==
			elif x >= 2 and x < 12 and y >= 4 and y < 28:
				if (x * 7 + y * 13) % 5 < 4:
					tile = 3  # mostly trees
				else:
					tile = 0
			
			# == DENSE FOREST (bottom area: 2-28, 44-58) ==
			elif x >= 2 and x < 28 and y >= 44 and y < 58:
				if (x * 7 + y * 13) % 7 < 5:
					tile = 3
				else:
					tile = 0
			
			# == FORAGE AREA (open grass fields: 12-28, 4-28) ==
			elif x >= 12 and x < 28 and y >= 4 and y < 28:
				if (x * 7 + y * 13) % 10 < 2:
					tile = 3  # sparse trees
				elif (x * 7 + y * 13) % 15 < 1:
					tile = 4  # flowers
				else:
					tile = 0  # grass
			
			# == OPEN MEADOW (right area: 38-55, 20-30) ==
			elif x >= 38 and x < 55 and y >= 20 and y < 30:
				if (x * 7 + y * 13) % 10 < 2:
					tile = 3
				elif (x * 7 + y * 13) % 12 < 1:
					tile = 4
				else:
					tile = 0
			
			# == STUMP / HARDWOOD AREA (near pond, left side: 20-28, 30-42) ==
			elif x >= 20 and x < 28 and y >= 30 and y < 42:
				tile = 0  # grass with hardwood stumps added separately
				if (x * 7 + y * 13) % 8 < 1:
					tile = 3  # big tree stump
			
			# == FLOWER BEDS near paths ==
			elif x >= 28 and x < 30 and y >= 20 and y < 22:
				tile = 4
			elif x >= 38 and x < 40 and y >= 30 and y < 32:
				tile = 4
			elif x >= 12 and x < 14 and y >= 28 and y < 30:
				tile = 4
			
			# Random trees everywhere
			elif tile == 0 and (x * 7 + y * 13) % 15 < 1:
				tile = 3
			# Random flowers
			elif tile == 0 and (x * 7 + y * 13) % 25 < 1:
				tile = 4
			
			map_data[y].append(tile)
	_draw_tiles()

func _draw_tiles():
	for child in $Tiles.get_children():
		child.queue_free()
	for y in range(MAP_H):
		for x in range(MAP_W):
			var t = map_data[y][x]
			var variant = (x * 7 + y * 13) % 5
			var sprite = Sprite2D.new()
			sprite.texture = _get_tile_texture(t, variant)
			sprite.position = Vector2(x * TILE_SIZE + TILE_SIZE/2, y * TILE_SIZE + TILE_SIZE/2)
			sprite.scale = Vector2(ZOOM, ZOOM)
			sprite.name = "Tile_%d_%d" % [x, y]
			$Tiles.add_child(sprite)
	_setup_collision()

func _get_tile_texture(tile_type: int, variant: int) -> ImageTexture:
	match tile_type:
		0: return PixelArtist.generate_tile("grass", variant)
		1: return PixelArtist.generate_tile("dirt", variant)
		2: return PixelArtist.generate_tile("water", variant)
		3: return PixelArtist.generate_tile("tree", variant)
		4: return PixelArtist.generate_tile("flower_bed", variant)
		5: return PixelArtist.generate_tile("fence", variant)
		8: return PixelArtist.generate_tile("path", variant)
		_: return PixelArtist.generate_tile("grass", variant)

func _setup_collision():
	for child in $Collision.get_children():
		child.queue_free()
	for y in range(MAP_H):
		for x in range(MAP_W):
			var tile = map_data[y][x]
			if tile in [2, 3, 5]:
				var area = Area2D.new()
				var shape = CollisionShape2D.new()
				var rect = RectangleShape2D.new()
				rect.size = Vector2(TILE_SIZE * ZOOM, TILE_SIZE * ZOOM)
				shape.shape = rect
				area.add_child(shape)
				area.position = Vector2(x * TILE_SIZE + TILE_SIZE/2, y * TILE_SIZE + TILE_SIZE/2)
				area.collision_layer = 0
				area.collision_mask = 1
				$Collision.add_child(area)

func _setup_players():
	var p = preload("res://scenes/world/player_scene.tscn").instantiate()
	$Entities.add_child(p)
	player = p
	if Global.player_pos != Vector2.ZERO:
		p.global_position = Global.player_pos

func _setup_hud():
	var hud = CanvasLayer.new()
	hud.name = "ForestHUD"
	add_child(hud)
	
	var label = Label.new()
	label.name = "ForestLabel"
	label.text = "馃尣 绉樺瘑妫灄"
	label.position = Vector2(300, 10)
	label.add_theme_color_override("font_color", Color("#a0d080"))
	label.add_theme_font_size_override("font_size", 14)
	hud.add_child(label)
	
	var hint = Label.new()
	hint.name = "HintLabel"
	hint.text = "宸﹂敭閲囬泦璧勬簮 | 鎸"E 浜や簰"
	hint.position = Vector2(10, 690)
	hint.add_theme_color_override("font_color", Color("#c0e0a0"))
	hint.add_theme_font_size_override("font_size", 10)
	hud.add_child(hint)

# 鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€
# 馃尶 鍙噰闆嗚祫婧愮敓鎴"# 鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€
func _spawn_resources():
	# 娓呴櫎鏃ц祫婧"	for child in $Resources.get_children():
		child.queue_free()
	resource_spots.clear()
	
	var spot_id = 0
	var rng = RandomNumberGenerator.new()
	rng.randomize()
	
	# 鑺变笡锛堢敓鎴愬湪鑽夊湴/鑺辩爾涓婏級
	for i in range(12):
		for attempt in 20:
			var x = rng.randi_range(2, MAP_W - 3)
			var y = rng.randi_range(2, MAP_H - 3)
			if map_data[y][x] not in [0, 4]: continue
			var pos = Vector2(x * TILE_SIZE * ZOOM + TILE_SIZE * ZOOM / 2, y * TILE_SIZE * ZOOM + TILE_SIZE * ZOOM / 2)
			if not _position_taken(pos, 48):
				var types = ["flower_pink", "flower_yellow", "flower_blue"]
				var ftype = types[rng.randi() % types.size()]
				_place_resource_sprite(pos, ftype)
				resource_spots[pos] = {"type": "flower", "crop": ftype, "count": rng.randi_range(1, 3), "id": spot_id}
				spot_id += 1
				break
	
	# 娴嗘灉涓"	for i in range(8):
		for attempt in 20:
			var x = rng.randi_range(3, MAP_W - 4)
			var y = rng.randi_range(3, MAP_H - 4)
			if map_data[y][x] not in [0]: continue
			var pos = Vector2(x * TILE_SIZE * ZOOM + TILE_SIZE * ZOOM / 2, y * TILE_SIZE * ZOOM + TILE_SIZE * ZOOM / 2)
			if not _position_taken(pos, 48):
				_place_resource_sprite(pos, "berry")
				resource_spots[pos] = {"type": "berry", "crop": "tomato", "count": rng.randi_range(2, 5), "id": spot_id}
				spot_id += 1
				break
	
	# 铇戣弴
	for i in range(6):
		for attempt in 20:
			var x = rng.randi_range(5, MAP_W - 6)
			var y = rng.randi_range(5, MAP_H - 6)
			if map_data[y][x] not in [0, 3]: continue
			var pos = Vector2(x * TILE_SIZE * ZOOM + TILE_SIZE * ZOOM / 2, y * TILE_SIZE * ZOOM + TILE_SIZE * ZOOM / 2)
			if not _position_taken(pos, 48):
				_place_resource_sprite(pos, "mushroom")
				resource_spots[pos] = {"type": "mushroom", "crop": "mushroom", "count": rng.randi_range(1, 3), "id": spot_id}
				spot_id += 1
				break

func _place_resource_sprite(pos: Vector2, type_: String):
	var sprite = Sprite2D.new()
	var img = PixelArtist.create(12, 12)
	match type_:
		"flower_pink": _draw_flower_sprite(img, Color("#ff6b8a"), Color("#ffa0b8"))
		"flower_yellow": _draw_flower_sprite(img, Color("#ffd700"), Color("#ffe04e"))
		"flower_blue": _draw_flower_sprite(img, Color("#6090ff"), Color("#90b0ff"))
		"berry": _draw_berry_sprite(img)
		"mushroom": _draw_mushroom_sprite(img)
	sprite.texture = PixelArtist.to_tex(img)
	sprite.position = pos
	sprite.position.y += 4  # 涓嬫矇涓€鐐硅鏍硅创鍦"	sprite.z_index = 2
	sprite.name = "Resource_%d_%d" % [pos.x, pos.y]
	$Resources.add_child(sprite)

func _draw_flower_sprite(img: Image, petal_color: Color, center_color: Color):
	# 5鐡ｅ皬鑺"	PixelArtist.p(img, 6, 0, center_color)
	PixelArtist.p(img, 6, 1, petal_color)
	PixelArtist.p(img, 5, 1, petal_color)
	PixelArtist.p(img, 7, 1, petal_color)
	PixelArtist.p(img, 4, 2, petal_color)
	PixelArtist.p(img, 6, 2, petal_color)
	PixelArtist.p(img, 8, 2, petal_color)
	PixelArtist.r(img, 5, 3, 1, 2, Color("#4a6a3a"))
	PixelArtist.r(img, 7, 3, 1, 2, Color("#4a6a3a"))

func _draw_berry_sprite(img: Image):
	# 绾㈣壊娴嗘灉涓"	PixelArtist.r(img, 4, 2, 4, 4, Color("#3a5a2a"))
	for i in 6:
		var bx = 3 + (i % 4)
		var by = 1 + (i / 2)
		PixelArtist.p(img, bx, by, Color("#ff3040"))
		PixelArtist.p(img, bx, by - 1, Color("#ff5060"))

func _draw_mushroom_sprite(img: Image):
	# 妫曡壊灏忚槕鑿"	PixelArtist.r(img, 4, 1, 4, 3, Color("#c0a070"))
	PixelArtist.r(img, 5, 4, 2, 3, Color("#e0d0b0"))
	PixelArtist.p(img, 3, 1, Color("#d0b080"))
	PixelArtist.p(img, 7, 1, Color("#d0b080"))
	PixelArtist.r(img, 5, 3, 2, 1, Color("#8a6a3a"))

func _position_taken(pos: Vector2, min_dist: float) -> bool:
	for existing in resource_spots:
		if existing.distance_to(pos) < min_dist:
			return true
	# 涔熼伩寮€姘"鏍"fence
	var t = pos / (TILE_SIZE * ZOOM)
	var x = int(round(t.x))
	var y = int(round(t.y))
	if x >= 0 and x < MAP_W and y >= 0 and y < MAP_H:
		if map_data[y][x] in [2, 3, 5]:
			return true
	return false

func _respawn_resources():
	_spawn_resources()

# 鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€
# 馃帲 閲囬泦浜や簰
# 鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€
func _input(event):
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_M:
			_show_minimap = not _show_minimap
			queue_redraw()
	if has_method("_input_base"):
		pass

func _toggle_fish_album_f():
	var album = get_node_or_null("ForestHUD/FishAlbumUI")
	if not album:
		album = preload("res://scenes/ui/fish_album_ui.tscn").instantiate()
		get_node("ForestHUD").add_child(album)
	if album.is_open:
		album._close()
	else:
		album.open()

func _unhandled_input(event):
	if not (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT):
		return
	if _harvest_cooldown:
		return
	_harvest_cooldown = true
	get_tree().create_timer(HARVEST_CD).timeout.connect(func(): _harvest_cooldown = false)
	
	var mp = get_global_mouse_position()
	var closest_pos = Vector2.ZERO
	var closest_dist = 9999.0
	for pos in resource_spots:
		var dist = mp.distance_to(pos)
		if dist < 40 and dist < closest_dist and resource_spots[pos].count > 0:
			closest_dist = dist
			closest_pos = pos
	
	if closest_pos == Vector2.ZERO:
		return
	var spot = resource_spots[closest_pos]
	if spot.count <= 0:
		return
	
	# 娑堣€椾綋鍔"	if player and player.has_method("consume_stamina"):
		if not player.consume_stamina(2):
			_show_floating_text(mp, "Too tired!")
			return
	
	var item_id = spot.crop
	var count = spot.count
	Inventory.add_item(item_id, count)
	if AudioManager: AudioManager.play_sfx(AudioManager.Sfx.PICKUP, global_position)
	_show_pickup_text("获得 " + str(qty) + " 个")
	spot.count = 0
	resource_collected.emit(spot.type, count)
	_show_floating_text(closest_pos, "+%d %s" % [count, spot.type])
	# 绉婚櫎绮剧伒
	var res_sprite = get_node_or_null("Resources/Resource_%d_%d" % [closest_pos.x, closest_pos.y])
	if res_sprite:
		# 娣″嚭鍔ㄧ敾
		var tween = create_tween()
		tween.tween_property(res_sprite, "modulate:a", 0.0, 0.3)
		tween.tween_callback(func(): if is_instance_valid(res_sprite): res_sprite.queue_free())

# 鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€
# 馃毆 鍑哄彛
# 鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€
func _setup_exits():
	# Top exit to farm (x=33, center area)
	var farm_exit = Area2D.new()
	farm_exit.name = "FarmExit"
	var shape1 = CollisionShape2D.new()
	var rect1 = RectangleShape2D.new()
	rect1.size = Vector2(6 * TILE_SIZE * ZOOM, TILE_SIZE * ZOOM)
	shape1.shape = rect1
	farm_exit.add_child(shape1)
	farm_exit.position = Vector2(33 * TILE_SIZE * ZOOM, TILE_SIZE * ZOOM / 2)
	farm_exit.body_entered.connect(_on_farm_exit)
	$Entities.add_child(farm_exit)
	
	# Right exit to town (x=MAP_W-2, y=30)
	var town_exit = Area2D.new()
	town_exit.name = "TownExit"
	var shape_town = CollisionShape2D.new()
	var rect_town = RectangleShape2D.new()
	rect_town.size = Vector2(TILE_SIZE * ZOOM, 6 * TILE_SIZE * ZOOM)
	shape_town.shape = rect_town
	town_exit.add_child(shape_town)
	town_exit.position = Vector2((MAP_W - 2) * TILE_SIZE * ZOOM + TILE_SIZE * ZOOM / 2, 30 * TILE_SIZE * ZOOM)
	town_exit.body_entered.connect(_on_town_exit)
	$Entities.add_child(town_exit)
	
	# Fishing spot by the pond
	_setup_fishing_spot()
	
	# 姹犲閽撻奔鐐癸紙妫灄姹犲涓績浣嶇疆锛"	_setup_fishing_spot()

func _on_farm_exit(body: Node):
	if body.has_method("set_movement"):
		body.set_movement(false)
		Global.player_pos = Vector2(4 * TILE_SIZE * ZOOM, (MAP_H - 3) * TILE_SIZE * ZOOM)
		get_tree().change_scene_to_file("res://scenes/farm/farm_scene.tscn")

func _on_town_exit(body: Node):
	if body.has_method("set_movement"):
		body.set_movement(false)
		Global.player_pos = Vector2(4 * TILE_SIZE * ZOOM, 4 * TILE_SIZE * ZOOM)
		get_tree().change_scene_to_file("res://scenes/town/town_scene.tscn")

# 鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€
# 馃敡 杈呭姪
# 鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€
func _show_floating_text(pos: Vector2, text: String):
	var label = Label.new()
	label.text = text
	label.add_theme_color_override("font_color", Color("#a0d080"))
	label.add_theme_font_size_override("font_size", 10)
	label.position = pos - Vector2(20, 10)
	label.z_index = 20
	add_child(label)
	get_tree().create_timer(0.8).timeout.connect(func():
		if is_instance_valid(label): label.queue_free()
	)

func is_walkable(global_pos: Vector2) -> bool:
	var t = global_pos / (TILE_SIZE * ZOOM)
	var x = int(round(t.x))
	var y = int(round(t.y))
	if x < 0 or x >= MAP_W or y < 0 or y >= MAP_H: return false
	if map_data[y][x] in [2, 3, 5]: return false
	return true

func _apply_seasonal_overlay():
	var overlay = ColorRect.new()
	overlay.name = "SeasonOverlay"
	overlay.size = Vector2(MAP_W * TILE_SIZE * ZOOM, MAP_H * TILE_SIZE * ZOOM)
	overlay.z_index = 100
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	match DayTime.current_season:
		0: overlay.color = Color(1.0, 0.9, 0.95, 0.03)
		1: overlay.color = Color(1.0, 1.0, 0.8, 0.03)
		2: overlay.color = Color(1.0, 0.8, 0.6, 0.04)
		3: overlay.color = Color(0.9, 0.95, 1.0, 0.06)
	add_child(overlay)
	
	# 鐩戝惉瀛ｈ妭鍙樺寲
	if Engine.has_singleton("DayTime"):
		DayTime.time_changed.connect(_check_season_change)

func _check_season_change(hour, minute, day, season, year):
	var overlay = get_node_or_null("SeasonOverlay")
	if not overlay: return
	match season:
		0: overlay.color = Color(1.0, 0.9, 0.95, 0.03)
		1: overlay.color = Color(1.0, 1.0, 0.8, 0.03)
		2: overlay.color = Color(1.0, 0.8, 0.6, 0.04)
		3: overlay.color = Color(0.9, 0.95, 1.0, 0.06)

func _setup_fishing_spot():
	var spot = Area2D.new()
	spot.name = "FishingSpot"
	spot.collision_layer = 3
	spot.collision_mask = 1
	var shape = CollisionShape2D.new()
	var rect = RectangleShape2D.new()
	rect.size = Vector2(4 * TILE_SIZE * ZOOM, 4 * TILE_SIZE * ZOOM)
	shape.shape = rect
	spot.add_child(shape)
	spot.position = Vector2(13 * TILE_SIZE * ZOOM, 21 * TILE_SIZE * ZOOM)
	spot.body_entered.connect(_on_fishing_spot_entered)
	$Entities.add_child(spot)
	
	var hint_img = PixelArtist.create(4, 4)
	PixelArtist.p(hint_img, 1, 1, Color("#e0e0e0"))
	PixelArtist.p(hint_img, 2, 1, Color("#e0e0e0"))
	PixelArtist.p(hint_img, 1, 2, Color("#e0e0e0"))
	PixelArtist.p(hint_img, 2, 2, Color("#e0e0e0"))
	PixelArtist.p(hint_img, 2, 0, Color("#ff4444"))
	var hint = Sprite2D.new()
	hint.texture = PixelArtist.to_tex(hint_img)
	hint.position = spot.position
	hint.position.y -= 24
	hint.z_index = 5
	$Entities.add_child(hint)

func _on_fishing_spot_entered(body: Node):
	if not body.is_in_group("player"): return
	var fish_game = get_node_or_null("ForestHUD/FishGame")
	if not fish_game:
		fish_game = preload("res://scenes/ui/fish_game.tscn").instantiate()
		get_node("ForestHUD").add_child(fish_game)
	fish_game.open()

# 鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲
# 馃對锔"澶╂皵鏁堟灉
# 鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲
func _update_weather_effects():
	var weather_layer = get_node_or_null("WeatherLayer")
	if not weather_layer:
		weather_layer = Node2D.new()
		weather_layer.name = "WeatherLayer"
		weather_layer.z_index = 200
		add_child(weather_layer)
	for c in weather_layer.get_children():
		c.queue_free()
	var w = DayTime.current_weather
	if w == DayTime.Weather.RAINY:
		_spawn_rain_f(weather_layer)
	elif w == DayTime.Weather.SNOWY:
		_spawn_snow_f(weather_layer)

func _spawn_rain_f(parent: Node):
	for i in range(40):
		var drop = ColorRect.new()
		drop.size = Vector2(1, 5)
		drop.color = Color(0.6, 0.7, 0.9, 0.35)
		drop.position = Vector2(randf() * MAP_W * TILE_SIZE * ZOOM, randf() * MAP_H * TILE_SIZE * ZOOM)
		drop.z_index = 200
		drop.set_meta("speed", randf_range(80, 150))
		drop.set_meta("wind", randf_range(-20, 10))
		parent.add_child(drop)
	_rain_loop_f(parent)

func _rain_loop_f(parent: Node):
	if not is_instance_valid(parent) or not is_inside_tree(): return
	for child in parent.get_children():
		if not is_instance_valid(child): continue
		child.position += Vector2(child.get_meta("wind"), child.get_meta("speed")) * 0.05
		if child.position.y > MAP_H * TILE_SIZE * ZOOM:
			child.position.y = -10
			child.position.x = randf() * MAP_W * TILE_SIZE * ZOOM
	await get_tree().create_timer(0.05).timeout
	_rain_loop_f(parent)

func _spawn_snow_f(parent: Node):
	for i in range(30):
		var flake = ColorRect.new()
		flake.size = Vector2(2, 2)
		flake.color = Color(1, 1, 1, 0.5)
		flake.position = Vector2(randf() * MAP_W * TILE_SIZE * ZOOM, randf() * MAP_H * TILE_SIZE * ZOOM)
		flake.z_index = 200
		flake.set_meta("speed", randf_range(20, 50))
		flake.set_meta("sway", randf_range(0, 6.28))
		parent.add_child(flake)
	_snow_loop_f(parent)

func _snow_loop_f(parent: Node):
	if not is_instance_valid(parent) or not is_inside_tree(): return
	var t = Time.get_ticks_msec() / 1000.0
	for child in parent.get_children():
		if not is_instance_valid(child): continue
		var sway = child.get_meta("sway")
		child.position += Vector2(sin(t * 2 + sway) * 0.5, child.get_meta("speed")) * 0.1
		if child.position.y > MAP_H * TILE_SIZE * ZOOM:
			child.position.y = -5
			child.position.x = randf() * MAP_W * TILE_SIZE * ZOOM
	await get_tree().create_timer(0.05).timeout
	_snow_loop_f(parent)


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
	var mm_w = MAP_W * 4
	var mm_h = MAP_H * 4
	var mm_x = 10
	var mm_y = 10
	draw_rect(Rect2(mm_x - 2, mm_y - 2, mm_w + 4, mm_h + 4), Color(0.05, 0.05, 0.1, 0.8))
	
	var colors = {1: Color("#5c8f3c"), 2: Color("#8b7355"), 3: Color("#3a7a3a"),
				   4: Color("#a08050"), 5: Color("#887050"), 6: Color("#3870a0")}
	for y in range(MAP_H):
		for x in range(MAP_W):
			var k = map_data[y][x]
			var c = colors.get(k, Color(0.15, 0.12, 0.08))
			draw_rect(Rect2(mm_x + x * 4, mm_y + y * 4, 4, 4), c, false)
	
	var pl = get_node_or_null("Entities/Player")
	if pl:
		var px = mm_x + int(pl.global_position.x / (TILE_SIZE * ZOOM)) * 4
		var py = mm_y + int(pl.global_position.y / (TILE_SIZE * ZOOM)) * 4
		draw_circle(Vector2(px, py), 2.5, Color("#ffd700"))
