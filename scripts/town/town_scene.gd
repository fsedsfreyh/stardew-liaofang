# TownScene —— 小镇场景（5x25，星露谷田园风格）


const MAP_W = 55
const MAP_H = 50
const TILE_SIZE = 32
const ZOOM = 1.5

var map_data: Array = []
var player: Node = null

func _ready():
	
	_generate_map()
	_setup_players_and_npcs()
	_setup_town_hud()
	_setup_town_exit()
	
	# 浠诲姟鏍囪
	if Engine.has_singleton("QuestManager"):
		get_node("/root/QuestManager").set_flag(5)  # VISITED_TOWN
	
	if Global.player_pos != Vector2.ZERO:
		for child in $Entities.get_children():
			if child is CharacterBody2D and child.has_method("set_movement"):
				child.global_position = Global.player_pos

# 鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€
# 馃彉锔"灏忛晣鍦板浘鐢熸垚锛"5脳25锛"#   tile types: 0=grass, 1=dirt, 2=water, 3=tree, 4=flowers,
#   5=fence, 6=wall, 7=door, 8=path, 9=house_roof
# 鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€
func _generate_map():
	map_data.clear()
	for y in range(MAP_H):
		map_data.append([])
		for x in range(MAP_W):
			var tile = 0
			
			# Border fence
			if x < 1 or x >= MAP_W - 1 or y < 1 or y >= MAP_H - 1:
				tile = 5
			# Bottom exit to farm (center)
			elif y == MAP_H - 2 and x >= 24 and x < 30:
				tile = 8
			# Top exit (bus stop / mountain)
			elif y == 1 and x >= 24 and x < 30:
				tile = 8
			# Right exit to forest
			elif x == MAP_W - 2 and y >= 24 and y < 28:
				tile = 8
			
			# == MAIN PLAZA (center: 25-32, 20-28) ==
			# Fountain (center of plaza: 27-31, 23-27)
			elif x >= 27 and x < 31 and y >= 23 and y < 27:
				if x == 28 and y == 24:
					tile = 2  # water fountain
				elif x >= 28 and x < 30 and y >= 24 and y < 26:
					tile = 2
				else:
					tile = 8  # fountain base
			
			# Plaza paths (around fountain)
			elif y == 28 and x >= 22 and x < 34:
				tile = 8
			elif y == 22 and x >= 22 and x < 34:
				tile = 8
			elif x == 22 and y >= 23 and y < 28:
				tile = 8
			elif x == 33 and y >= 23 and y < 28:
				tile = 8
			
			# == GENERAL STORE (Bill's Shop, top-right area: 34-42, 10-18) ==
			elif x >= 34 and x < 42 and y >= 10 and y < 18:
				if x >= 35 and x < 41 and y >= 11 and y < 17:
					tile = 6  # walls
					if x >= 37 and x < 39 and y == 16:
						tile = 7  # door
				elif y == 10:
					tile = 9  # roof
				else:
					tile = 6
			
			# Path to store
			elif x >= 37 and x < 39 and y >= 18 and y < 22:
				tile = 8
			
			# == CLINIC (left of plaza: 12-19, 8-18) ==
			elif x >= 12 and x < 19 and y >= 8 and y < 18:
				if x >= 13 and x < 18 and y >= 9 and y < 17:
					tile = 6
					if x >= 14 and x < 16 and y == 16:
						tile = 7  # door
				elif y == 8:
					tile = 9
				else:
					tile = 6
			
			# Path to clinic
			elif y >= 18 and y < 22 and x >= 14 and x < 16:
				tile = 8
			
			# == MUSEUM / LIBRARY (left area: 4-12, 18-28) ==
			elif x >= 4 and x < 12 and y >= 18 and y < 28:
				if x >= 5 and x < 11 and y >= 19 and y < 27:
					tile = 6
					if x >= 6 and x < 8 and y == 26:
						tile = 7  # door
				elif y == 18:
					tile = 9
				else:
					tile = 6
			
			# Path to museum
			elif y >= 28 and y < 30 and x >= 6 and x < 8:
				tile = 8
			
			# == COMMUNITY CENTER (top area: 12-20, 2-10) ==
			elif x >= 12 and x < 20 and y >= 2 and y < 10:
				if x >= 13 and x < 19 and y >= 3 and y < 9:
					tile = 6  # walls
					if x >= 14 and x < 16 and y == 8:
						tile = 7  # door
				elif y == 2:
					tile = 9  # roof
				else:
					tile = 6
			
			# Path to community center
			elif y >= 10 and y < 12 and x >= 14 and x < 16:
				tile = 8
			
			# == RESIDENTIAL HOUSES (scattered) ==
			# House 1 (bottom-left)
			elif x >= 4 and x < 9 and y >= 32 and y < 38:
				if x >= 5 and x < 8 and y >= 33 and y < 37:
					tile = 6
					if x >= 6 and x < 7 and y == 36:
						tile = 7
				elif y == 32:
					tile = 9
			
			# House 2 (bottom-right)
			elif x >= 38 and x < 43 and y >= 34 and y < 40:
				if x >= 39 and x < 42 and y >= 35 and y < 39:
					tile = 6
					if x >= 40 and x < 41 and y == 38:
						tile = 7
				elif y == 34:
					tile = 9
			
			# == MAIN ROAD (vertical, center) ==
			elif x >= 26 and x < 30 and y >= 2 and y < MAP_H - 2:
				tile = 8
			
			# Horizontal road (across center)
			elif y == 30 and x >= 4 and x < 44:
				tile = 8
			
			# Path to bottom houses
			elif x >= 6 and x < 8 and y >= 38 and y < 45:
				tile = 8
			elif x >= 40 and x < 42 and y >= 40 and y < 45:
				tile = 8
			
			# == FLOWER BEDS near buildings ==
			# Near clinic
			elif x >= 10 and x < 12 and y >= 10 and y < 14:
				tile = 4
			# Near store
			elif x >= 42 and x < 44 and y >= 10 and y < 14:
				tile = 4
			# Near fountain
			elif x >= 24 and x < 26 and y >= 24 and y < 28:
				tile = 4
			# Plaza flower beds
			elif x >= 23 and x < 25 and y >= 28 and y < 30:
				tile = 4
			
			# == TREES (scattered around town) ==
			elif tile == 0 and (x * 7 + y * 13) % 17 < 2 and y > 2:
				tile = 3
			# Random flowers in grass
			elif tile == 0 and (x * 7 + y * 13) % 31 < 1:
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
			var tex = _get_tile_texture(t, variant)
			var sprite = Sprite2D.new()
			sprite.texture = tex
			sprite.position = Vector2(x * TILE_SIZE + TILE_SIZE/2, y * TILE_SIZE + TILE_SIZE/2)
			sprite.scale = Vector2(ZOOM, ZOOM)
			sprite.name = "Tile_%d_%d" % [x, y]
			$Tiles.add_child(sprite)
	_setup_collision()
	_setup_decorations()

func _get_tile_texture(tile_type: int, variant: int) -> ImageTexture:
	match tile_type:
		0: return PixelArtist.generate_tile("grass", variant)
		1: return PixelArtist.generate_tile("dirt", variant)
		2: return PixelArtist.generate_tile("water", variant)
		3: return PixelArtist.generate_tile("tree", variant)
		4: return PixelArtist.generate_tile("flower_bed", variant)
		5: return PixelArtist.generate_tile("fence", variant)
		6: return PixelArtist.generate_tile("house_wall", variant)
		7: return PixelArtist.generate_tile("door", variant)
		8: return PixelArtist.generate_tile("path", variant)
		9: return PixelArtist.generate_tile("house_roof", variant)
		_: return PixelArtist.generate_tile("grass", variant)

func _setup_collision():
	for child in $Collision.get_children():
		child.queue_free()
	for y in range(MAP_H):
		for x in range(MAP_W):
			var tile = map_data[y][x]
			if tile in [2, 6, 3, 5]:
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

func _setup_players_and_npcs():
	var p = preload("res://scenes/world/player_scene.tscn").instantiate()
	p.position = Global.player_pos
	$Entities.add_child(p)
	player = p
	
	# 鍟嗗簵 NPC - Bill
	var bill = preload("res://scenes/world/shop_npc_scene.tscn").instantiate()
	bill.position = Vector2(21 * TILE_SIZE * ZOOM, 21 * TILE_SIZE * ZOOM)
	$Entities.add_child(bill)
	
	# 瑁呴グ鎬"NPC 鈥"闅忔満婕鐨勬潙姘"	_spawn_wandering_npcs()
	
	# 寤栬姵鏃ョ▼锛":00-12:00 鍦ㄥ皬闀囪姳鍧"	_spawn_if_liaofang_in_town()

func _spawn_if_liaofang_in_town():
	if not Engine.has_singleton("DayTime"): return
	var hour = DayTime.get_hour()
	if hour >= 6 and hour < 12:
		_spawn_liaofang_town()

func _spawn_liaofang_town():
	var lf = preload("res://scenes/world/liaofang_scene.tscn").instantiate()
	lf.position = Vector2(4 * TILE_SIZE * ZOOM, 8 * TILE_SIZE * ZOOM)
	lf.name = "LiaoFangTown"
	$Entities.add_child(lf)

# 鍑犱釜闅忔満婕鐨勮楗版€"NPC
func _spawn_wandering_npcs():
	var npc_configs = [
		{
			"pos": Vector2(8 * TILE_SIZE * ZOOM, 7 * TILE_SIZE * ZOOM),
			"body": Color("#d06040"),
			"hair": Color("#c0a070"),
			"name": "鍗叺",
			"dialogue_flag": "talked_guard",
			"dialogues": [
				["馃洝锔"鍗叺", "鍢匡紝鏂版潵鐨勶紵杩欏皬闀囪櫧鐒跺皬锛屼絾娌诲畨寰堝ソ銆"],
				["馃洝锔"鍗叺", "鍙浣犲埆鍘昏タ杈归偅鐗囧瘑鏋楀氨琛"..閭ｉ噷鐨勯噹鍏藉彲涓嶅弸鍠勩€"],
				["馃挕", "宸︽墜杈规．鏋楀彲浠ラ噰闆嗛噹鑺卞拰铇戣弴銆"],
			],
		},
		{
			"pos": Vector2(16 * TILE_SIZE * ZOOM, 16 * TILE_SIZE * ZOOM),
			"body": Color("#4080c0"),
			"hair": Color("#f0e0c0"),
			"name": "鑰佸ザ濂",
			"dialogue_flag": "talked_granny",
			"dialogues": [
				["馃懙 鑰佸ザ濂", "鍝庡憖锛屼綘灏辨槸鏂版潵鐨勫啘鍦轰富鍚э紵骞磋交鐪熷ソ鍟婏綖"],
				["馃懙 鑰佸ザ濂", "鎴戝勾杞荤殑鏃跺€欎篃绉嶈繃鍦帮紝閭ｆ椂鍊欓箞楣曢晣杩樺彧鏈夊嚑鎴蜂汉瀹躲€"],
				["馃懙 鑰佸ザ濂", "瀵逛簡锛屽鏋滆鍒板粬鑺抽偅涓ご锛屾浛鎴戝悜濂归棶濂姐€"],
			],
		},
		{
			"pos": Vector2(6 * TILE_SIZE * ZOOM, 20 * TILE_SIZE * ZOOM),
			"body": Color("#e080a0"),
			"hair": Color("#a06030"),
			"name": "鑺卞晢鑹剧惓",
			"dialogue_flag": "talked_erin",
			"dialogues": [
				["馃尭 鑹剧惓", "娆㈣繋鍏変复鎴戠殑灏忚姳鎽婏綖鍏跺疄鍩烘湰涓婂氨鏄噹鑺辨憳鏉ュ崠鐨勩€"],
				["馃尭 鑹剧惓", "鍚鍐滃満閭ｈ竟鐨勮摑椋庨搩鑺卞紑寰楃壒鍒ソ锛屼笅娆℃垜鍘荤湅鐪嬶紒"],
			],
		},
		{
			"pos": Vector2(20 * TILE_SIZE * ZOOM, 8 * TILE_SIZE * ZOOM),
			"body": Color("#607050"),
			"hair": Color("#d0b090"),
			"name": "閾佸尃鑰侀檲",
			"dialogue_flag": "talked_chen",
			"dialogues": [
				["馃敡 鑰侀檲", "鍝燂紝骞磋交浜猴紒浣犺繖浣撴牸涓嶉敊锛岃涓嶈鏉ラ搧鍖犻摵甯繖锛"],
				["馃敡 鑰侀檲", "鎴戝惉璇村煄鍖楁湁涓簾寮冪熆娲烇紝閲岄潰鏈変笉灏戝ソ鐭跨煶銆"],
				["馃敡 鑰侀檲", "瑕佹槸浣犺兘寮勫埌閲戠熆鐭筹紝鎴戠粰浣犳墦涓€鎶婂ソ閿勫ご锛"],
			],
		},
	]
	for cfg in npc_configs:
		var npc = CharacterBody2D.new()
		npc.name = "WanderingNPC_" + cfg["name"]
		
		var sprite = Sprite2D.new()
		sprite.name = "Sprite2D"
		sprite.texture = _gen_neighbor_sprite(cfg)
		npc.add_child(sprite)
		
		var col = CollisionShape2D.new()
		var rect = RectangleShape2D.new()
		rect.size = Vector2(8, 12)
		col.shape = rect
		npc.add_child(col)
		
		# 浜や簰鍖哄煙
		var interact = Area2D.new()
		interact.name = "InteractArea"
		var ishape = CollisionShape2D.new()
		var irect = RectangleShape2D.new()
		irect.size = Vector2(24, 24)
		ishape.shape = irect
		interact.add_child(ishape)
		npc.add_child(interact)
		
		npc.global_position = cfg["pos"]
		npc.add_to_group("npcs")
		npc.set_meta("npc_id", cfg["name"])
		npc.set_meta("dialogue_flag", cfg["dialogue_flag"])
		npc.set_meta("dialogues", cfg["dialogues"])
		
		# 闅忔満婕閫昏緫
		var wander_timer = Timer.new()
		wander_timer.wait_time = randf_range(2.0, 5.0)
		wander_timer.autostart = true
		wander_timer.timeout.connect(_wander_npc.bind(npc))
		npc.add_child(wander_timer)
		
		npc.set_meta("dir", ["left", "right", "up", "down"][randi() % 4])
		npc.set_meta("speed", randf_range(12.0, 25.0))
		
		$Entities.add_child(npc)
		
		# 浜掑姩淇″彿
		if interact:
			interact.body_entered.connect(_on_npc_interact_enter.bind(npc, cfg["name"]))

func _wander_npc(npc: Node):
	if not is_instance_valid(npc): return
	var dirs = ["left", "right", "up", "down"]
	npc.set_meta("dir", dirs[randi() % 4])
	npc.set_meta("speed", randf_range(12.0, 25.0))
	# 绉诲姩鍒伴殢鏈轰綅缃"	var nx = randf_range(4 * TILE_SIZE * ZOOM, 22 * TILE_SIZE * ZOOM)
	var ny = randf_range(4 * TILE_SIZE * ZOOM, 22 * TILE_SIZE * ZOOM)
	if is_walkable(Vector2(nx, ny)):
		npc.set_meta("target", Vector2(nx, ny))

func _physics_process(delta):
	for child in $Entities.get_children():
		if child.name.begins_with("WanderingNPC"):
			_walk_npc(child, delta)

func _setup_town_hud():
	var hud = CanvasLayer.new()
	hud.name = "TownHUD"
	add_child(hud)
	
	var label = Label.new()
	label.name = "TownLabel"
	label.text = "馃洊 Pelican Town"
	label.position = Vector2(300, 10)
	label.add_theme_color_override("font_color", Color.WHITE)
	label.add_theme_font_size_override("font_size", 14)
	hud.add_child(label)

# 鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€
# 馃巰 瑁呴グ缁嗚妭锛堟嫑鐗屻€佽姳鍧涚簿鐏碉級
# 鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€
func _setup_decorations():
	_setup_bulletin_board()
	# Bill 鍟嗗簵闂ㄧ墝
	var sign_img = PixelArtist.create(12, 8)
	PixelArtist.r(sign_img, 0, 0, 12, 8, Color("#6a4a2a"))
	PixelArtist.r(sign_img, 1, 1, 10, 6, Color("#8a6a3a"))
	PixelArtist.r(sign_img, 4, 2, 4, 1, Color("#ffd700"))
	PixelArtist.p(sign_img, 2, 3, Color("#ffd700"))
	PixelArtist.p(sign_img, 9, 3, Color("#ffd700"))
	PixelArtist.r(sign_img, 4, 4, 4, 1, Color("#ffd700"))
	PixelArtist.r(sign_img, 3, 5, 6, 1, Color("#8a6a3a"))
	var sign_tex = PixelArtist.to_tex(sign_img)
	var sign = Sprite2D.new()
	sign.texture = sign_tex
	sign.position = Vector2(21 * TILE_SIZE * ZOOM, 17 * TILE_SIZE * ZOOM - 16)
	sign.name = "ShopSign"
	$Tiles.add_child(sign)
	
	# 鍟嗗簵闂ㄥ彛灏忚姳鍧"	var fb_positions = [
		Vector2(19 * TILE_SIZE * ZOOM + 8, 22 * TILE_SIZE * ZOOM),
		Vector2(22 * TILE_SIZE * ZOOM - 8, 22 * TILE_SIZE * ZOOM),
	]
	for pos in fb_positions:
		var fb = Sprite2D.new()
		fb.texture = PixelArtist.generate_tile("flower_bed", randi() % 3)
		fb.position = pos
		fb.scale = Vector2(ZOOM, ZOOM)
		fb.name = "ShopFlower_%.0f_%.0f" % [pos.x, pos.y]
		$Tiles.add_child(fb)
	
	# 鍠锋硥瑁呴グ鈥旈《閮ㄥ皬闆曞儚
	if has_node("Tiles"):
		var stat = Sprite2D.new()
		var stat_img = PixelArtist.create(8, 8)
		PixelArtist.r(stat_img, 3, 0, 2, 1, Color("#cca070"))
		PixelArtist.r(stat_img, 2, 1, 4, 4, Color("#cca070"))
		PixelArtist.p(stat_img, 2, 0, Color("#cca070"))
		PixelArtist.p(stat_img, 5, 0, Color("#cca070"))
		PixelArtist.r(stat_img, 2, 5, 4, 1, Color("#8a8a8a"))
		PixelArtist.p(stat_img, 1, 3, Color("#6a6a6a"))
		PixelArtist.p(stat_img, 6, 3, Color("#6a6a6a"))
		PixelArtist.p(stat_img, 3, 2, Color.WHITE)
		PixelArtist.p(stat_img, 4, 2, Color.WHITE)
		stat.texture = PixelArtist.to_tex(stat_img)
		stat.position = Vector2(12 * TILE_SIZE * ZOOM, 11 * TILE_SIZE * ZOOM - 12)
		stat.name = "FountainStatue"
		$Tiles.add_child(stat)
	
	# 璺伅鈥斺€旇矾寰勪袱渚"	var street_light_positions = [
		Vector2(12 * TILE_SIZE * ZOOM, 3 * TILE_SIZE * ZOOM),
		Vector2(12 * TILE_SIZE * ZOOM, 22 * TILE_SIZE * ZOOM),
		Vector2(6 * TILE_SIZE * ZOOM, 7 * TILE_SIZE * ZOOM),
		Vector2(18 * TILE_SIZE * ZOOM, 7 * TILE_SIZE * ZOOM),
	]
	for pos in street_light_positions:
		var lamp = Sprite2D.new()
		var lamp_img = PixelArtist.create(4, 10)
		PixelArtist.r(lamp_img, 1, 3, 2, 7, Color("#6a6a6a"))
		PixelArtist.r(lamp_img, 0, 2, 4, 1, Color("#8a8a8a"))
		PixelArtist.r(lamp_img, 1, 0, 2, 2, Color("#ffd700"))
		lamp.texture = PixelArtist.to_tex(lamp_img)
		lamp.position = pos + Vector2(-8, -4)
		lamp.name = "Lamp_%.0f" % pos.x
		$Tiles.add_child(lamp)

# 鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€
# 馃毆 鍖哄煙瑙﹀彂鈥斺€旀父鎴忓嚭鍙ｅ埌鍐滃満
# 鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€
func _setup_town_exit():
	# Bottom exit to farm (x=27, center of bottom)
	var farm_exit = Area2D.new()
	farm_exit.name = "TownExit"
	var shape = CollisionShape2D.new()
	var rect = RectangleShape2D.new()
	rect.size = Vector2(6 * TILE_SIZE * ZOOM, TILE_SIZE * ZOOM)
	shape.shape = rect
	farm_exit.add_child(shape)
	farm_exit.position = Vector2(27 * TILE_SIZE * ZOOM, (MAP_H - 2) * TILE_SIZE * ZOOM + TILE_SIZE * ZOOM / 2)
	farm_exit.collision_layer = 4
	farm_exit.collision_mask = 4
	farm_exit.body_entered.connect(_on_town_exit_entered)
	add_child(farm_exit)
	
	# Top exit to mountain/bus stop (x=27, center of top)
	var mountain_exit = Area2D.new()
	mountain_exit.name = "MountainExit"
	var shape2 = CollisionShape2D.new()
	var rect2 = RectangleShape2D.new()
	rect2.size = Vector2(6 * TILE_SIZE * ZOOM, TILE_SIZE * ZOOM)
	shape2.shape = rect2
	mountain_exit.add_child(shape2)
	mountain_exit.position = Vector2(27 * TILE_SIZE * ZOOM, TILE_SIZE * ZOOM / 2)
	mountain_exit.collision_layer = 4
	mountain_exit.collision_mask = 4
	mountain_exit.body_entered.connect(_on_mountain_exit_entered)
	add_child(mountain_exit)
	
	# Right exit to forest (x=MAP_W-2, center-right)
	var forest_exit = Area2D.new()
	forest_exit.name = "ForestExit"
	var shape3 = CollisionShape2D.new()
	var rect3 = RectangleShape2D.new()
	rect3.size = Vector2(TILE_SIZE * ZOOM, 6 * TILE_SIZE * ZOOM)
	shape3.shape = rect3
	forest_exit.add_child(shape3)
	forest_exit.position = Vector2((MAP_W - 2) * TILE_SIZE * ZOOM + TILE_SIZE * ZOOM / 2, 30 * TILE_SIZE * ZOOM)
	forest_exit.collision_layer = 4
	forest_exit.collision_mask = 4
	forest_exit.body_entered.connect(_on_forest_exit_entered)
	add_child(forest_exit)
	exit.collision_layer = 4
	exit.collision_mask = 4
	exit.body_entered.connect(_on_exit_entered)
	add_child(exit)

func _on_town_exit_entered(body: Node):
	if body.has_method("set_movement"):
		body.set_movement(false)
		Global.player_pos = Vector2(39 * TILE_SIZE * ZOOM, (MAP_H - 3) * TILE_SIZE * ZOOM)
		get_tree().change_scene_to_file("res://scenes/farm/farm_scene.tscn")

func _on_mountain_exit_entered(body: Node):
	if body.has_method("set_movement"):
		body.set_movement(false)
		Global.player_pos = Vector2.ZERO
		get_tree().change_scene_to_file("res://scenes/mine/mine_scene.tscn")

func _on_forest_exit_entered(body: Node):
	if body.has_method("set_movement"):
		body.set_movement(false)
		Global.player_pos = Vector2.ZERO
		get_tree().change_scene_to_file("res://scenes/forest/forest_scene.tscn")

func _input(event):
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_M:
			_show_minimap = not _show_minimap
			queue_redraw()
	if has_method("_input_base"):
		pass

func _open_shop():
	var shop_ui = get_node_or_null("ShopUI")
	if not shop_ui:
		shop_ui = preload("res://scenes/ui/shop_ui.tscn").instantiate()
		add_child(shop_ui)
	shop_ui.open()

# 鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲
# 馃毝 瑁呴グ鎬"NPC 琛岃蛋
# 鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲
func _walk_npc(npc: Node, delta: float):
	if not is_instance_valid(npc): return
	var target = npc.get_meta("target", Vector2.ZERO)
	if target == Vector2.ZERO:
		return
	var dir_vec = target - npc.global_position
	if dir_vec.length() > 8:
		var speed = npc.get_meta("speed", 20.0)
		npc.global_position += dir_vec.normalized() * speed * delta
		if abs(dir_vec.x) > abs(dir_vec.y):
			npc.set_meta("dir", "left" if dir_vec.x < 0 else "right")
		else:
			npc.set_meta("dir", "up" if dir_vec.y < 0 else "down")
	else:
		npc.set_meta("target", Vector2.ZERO)

static func _gen_neighbor_sprite(cfg: Dictionary) -> ImageTexture:
	return PixelArtist.generate_npc_sprite({
		"body_color": cfg.get("body", Color("#d06040")),
		"body_shadow": cfg.get("body", Color("#d06040")).darkened(0.15),
		"hair_color": cfg.get("hair", Color("#c0a070")),
		"hair_highlight": cfg.get("hair", Color("#c0a070")).lightened(0.2),
		"eye_color": PixelArtist.PALETTE.e_d,
	})

# 鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲
# 馃挰 NPC 浜掑姩瀵硅瘽
# 鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲
func _on_npc_interact_enter(body: Node, npc_node: Node, npc_name: String):
	if not body.is_in_group("player"): return
	var dm = get_node_or_null("/root/DialogueManager")
	if not dm: return
	
	var flag = npc_node.get_meta("dialogue_flag", "")
	var dialogues = npc_node.get_meta("dialogues", [])
	if dialogues.is_empty():
		dialogues = [
			[npc_name, "浣犲ソ鍟婏紒"],
			[npc_name, "浠婂ぉ澶╂皵涓嶉敊锝"],
		]
	
	# 绗簩娆″璇濆彉鐭"	if Global.stats.get(flag, false):
		dialogues = dialogues.slice(0, min(1, dialogues.size()))
		if dialogues.is_empty():
			dialogues = [[npc_name, "鍢匡紝鍙堣闈簡锛"]]
	else:
		Global.stats[flag] = true
	
	dm.show_dialogue(dialogues, npc_name, 0)

# 鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€
# 杈呭姪
# 鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€
func is_walkable(global_pos: Vector2) -> bool:
	var t = global_pos / (TILE_SIZE * ZOOM)
	var x = int(round(t.x))
	var y = int(round(t.y))
	if x < 0 or x >= MAP_W or y < 0 or y >= MAP_H:
		return false
	if map_data[y][x] in [2, 6, 3, 5]:
		return false
	return true



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
	var mm_w = 25 * 4
	var mm_h = 25 * 4
	var mm_x = 10
	var mm_y = 10
	draw_rect(Rect2(mm_x - 2, mm_y - 2, mm_w + 4, mm_h + 4), Color(0.05, 0.05, 0.1, 0.8))
	
	# 绘制简略地图（用方形色块）
	var colors = {1: Color("#5c8f3c"), 2: Color("#8b7355"), 3: Color("#3a7a3a"),
				   4: Color("#a08050"), 5: Color("#887050"), 6: Color("#3870a0")}
	for y in range(MAP_H):
		for x in range(MAP_W):
			var k = 1
			if x < 2 or x >= 25 - 2 or y < 2 or y >= 25 - 2: k = 5
			elif x > 0.6 * 25: k = 3 if x > 0.6 * 25 else 1
			var c = colors.get(k, Color(0.15, 0.12, 0.08))
			draw_rect(Rect2(mm_x + x * 4, mm_y + y * 4, 4, 4), c, false)
	
	# 玩家位置
	var pl = get_node_or_null("Entities/Player")
	if pl:
		var px = mm_x + int(pl.global_position.x / 48) * 4
		var py = mm_y + int(pl.global_position.y / 48) * 4
		draw_circle(Vector2(px, py), 2.5, Color("#ffd700"))
