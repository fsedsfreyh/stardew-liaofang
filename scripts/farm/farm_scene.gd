# FarmScene - farm scene with visual farming overlay, tool cooldown & harvest particles
extends Node2D

const MAP_W = 80
const MAP_H = 65
const TILE_SIZE = 32
const ZOOM = 1.5

# tile types: 0=grass, 1=dirt/farmland, 2=water, 3=tree, 4=flowers, 5=fence, 6=wall, 7=door, 8=path
var map_data: Array = []

var player: Node = null
var current_tool: int = 0
var farm: Node = null

var tool_cooldown: bool = false
const TOOL_COOLDOWN_TIME: float = 0.3

# 新手引导
var _guide_step: int = -1
const GUIDE_STEPS = [
	"🌾 欢迎来到星露乡！\n\n按 WASD 或方向键\n移动你的角色",
	"🤝 靠近廖芳按 E\n和她聊聊天吧\n（她在农场里散步）",
	"🛠️ 按 Q/E 切换工具\n左键点击耕地区\n使用锄头松土",
	"💧 选中水壶工具\n点击耕地浇水\n作物需要每天浇水",
	"🌱 选择种子工具\n在耕地上点击\n种下你的第一颗种子",
	"🌿 等待作物成熟\n成熟后选择镰刀\n左键收获作物",
	"🏘️ 去左下角出口\n按 E 进入小镇\n找 Bill 买东西",
]
var _hud_setup_done: bool = false

func _ready():
	# 延迟一帧初始化，确保 PixelArtist Autoload 完全就绪
	call_deferred("_deferred_init")

func _deferred_init():
	_generate_map()
	_setup_players_and_npcs()
	_setup_farm_core()
	_setup_ui()
	_setup_connections()
	_setup_farm_exit()
	_sync_all_crop_sprites()
	_sync_all_state_overlays()

	if Global.player_pos != Vector2.ZERO:
		for child in $Entities.get_children():
			if child is CharacterBody2D and child.has_method("set_movement"):
				child.global_position = Global.player_pos

	if DayTime.current_day == 1 and DayTime.current_season == 0:
		call_deferred("_start_guide")
	call_deferred("_check_mail")

func _setup_farm_core():
	farm = load("res://scripts/farm/farm_core.gd").new()
	add_child(farm)
	farm.tile_changed.connect(_on_farm_tile_changed)
	farm.crop_harvested.connect(_on_crop_harvested)

func _setup_connections():
	DayTime.time_changed.connect(_on_time_changed)
	_on_time_changed(DayTime.get_hour(), DayTime.get_minute(), DayTime.current_day, DayTime.current_season, DayTime.current_year)
	_update_affection_display()
	Inventory.inventory_changed.connect(_update_affection_display)
	DayTime.time_changed.connect(func(h,m,d,s,y): _update_stamina_display())
	
	# 工具和作物系统
	if ToolManager:
		ToolManager.tool_used.connect(_on_tool_used)
	if CropManager:
		CropManager.plot_tilled.connect(_on_plot_tilled)
		CropManager.plot_watered.connect(_on_plot_watered)

func _setup_ui():
	var hud = CanvasLayer.new()
	hud.name = "HUD"
	add_child(hud)

	var time_label = Label.new()
	time_label.name = "TimeDisplay"
	time_label.position = Vector2(10, 10)
	time_label.add_theme_color_override("font_color", Color.WHITE)
	time_label.add_theme_font_size_override("font_size", 16)
	hud.add_child(time_label)

	var season_label = Label.new()
	season_label.name = "SeasonDisplay"
	season_label.position = Vector2(160, 10)
	season_label.add_theme_color_override("font_color", Color("#a0d0ff"))
	season_label.add_theme_font_size_override("font_size", 14)
	hud.add_child(season_label)

	var weather_label = Label.new()
	weather_label.name = "WeatherDisplay"
	weather_label.position = Vector2(310, 10)
	weather_label.add_theme_color_override("font_color", Color("#b0b0ff"))
	weather_label.add_theme_font_size_override("font_size", 12)
	hud.add_child(weather_label)

	var aff_label = Label.new()
	aff_label.name = "AffectionDisplay"
	aff_label.position = Vector2(10, 30)
	aff_label.add_theme_color_override("font_color", Color("#ff6b8a"))
	aff_label.add_theme_font_size_override("font_size", 14)
	hud.add_child(aff_label)

	var gold_label = Label.new()
	gold_label.name = "GoldDisplay"
	gold_label.position = Vector2(10, 50)
	gold_label.add_theme_color_override("font_color", Color("#ffd700"))
	gold_label.add_theme_font_size_override("font_size", 14)
	gold_label.text = "M: " + str(Inventory.gold) + " G"
	hud.add_child(gold_label)
	Inventory.inventory_changed.connect(func(): gold_label.text = "M: " + str(Inventory.gold) + " G")



	# 体力条
	var st_bar_bg = Panel.new()
	st_bar_bg.name = "StaminaBarBg"
	st_bar_bg.position = Vector2(10, 68)
	st_bar_bg.size = Vector2(120, 12)
	st_bar_bg.modulate = Color(0.2, 0.2, 0.2, 0.6)
	hud.add_child(st_bar_bg)

	var st_bar = Panel.new()
	st_bar.name = "StaminaBar"
	st_bar.position = Vector2(12, 70)
	st_bar.size = Vector2(116, 8)
	st_bar.modulate = Color(0.2, 0.8, 0.2, 0.9)
	hud.add_child(st_bar)

	var st_label = Label.new()
	st_label.name = "StaminaLabel"
	st_label.position = Vector2(10, 82)
	st_label.add_theme_color_override("font_color", Color("#60c060"))
	st_label.add_theme_font_size_override("font_size", 11)
	st_label.text = "体力: 100/100"
	hud.add_child(st_label)

	var tool_panel = Panel.new()
	tool_panel.name = "ToolPanel"
	tool_panel.position = Vector2(240, 680)
	tool_panel.size = Vector2(320, 36)
	hud.add_child(tool_panel)
	
	var tools = ["Hoe", "Water", "Seed", "Harvest"]
	for i in 4:
		var btn = Button.new()
		btn.name = "ToolBtn" + str(i)
		btn.position = Vector2(4 + i * 78, 4)
		btn.size = Vector2(74, 28)
		btn.text = tools[i]
		btn.add_theme_font_size_override("font_size", 14)
		btn.pressed.connect(_select_tool.bind(i))
		tool_panel.add_child(btn)
		
	var hint = Label.new()
	hint.name = "HintLabel"
	hint.position = Vector2(10, 700)
	hint.add_theme_color_override("font_color", Color("#ffd700"))
	hint.add_theme_font_size_override("font_size", 12)
	hint.text = "Q/E switch tool | Click use | E talk"
	hud.add_child(hint)

	var quest_label = Label.new()
	quest_label.name = "QuestHint"
	quest_label.position = Vector2(10, 700)
	quest_label.add_theme_color_override("font_color", Color("#6a9c5f"))
	quest_label.add_theme_font_size_override("font_size", 10)
	quest_label.text = ""
	hud.add_child(quest_label)

	_update_tool_highlight()

	var quest_timer = Timer.new()
	quest_timer.wait_time = 1.0
	quest_timer.autostart = true
	quest_timer.timeout.connect(_refresh_quest_hint)
	add_child(quest_timer)

	var mail_btn = Button.new()
	mail_btn.name = "MailBtn"
	mail_btn.position = Vector2(740, 10)
	mail_btn.size = Vector2(60, 28)
	mail_btn.text = "📬"
	mail_btn.add_theme_font_size_override("font_size", 14)
	mail_btn.pressed.connect(_open_mail)
	hud.add_child(mail_btn)

	var mail_timer = Timer.new()
	mail_timer.wait_time = 5.0
	mail_timer.autostart = true
	mail_timer.timeout.connect(_check_mail)
	add_child(mail_timer)

	var inv_panel = Panel.new()
	inv_panel.name = "InvPanel"
	inv_panel.position = Vector2(740, 50)
	inv_panel.size = Vector2(60, 180)
	hud.add_child(inv_panel)

	for i in range(4):
		var item_label = Label.new()
		item_label.name = "InvItem_%d" % i
		item_label.position = Vector2(4, 4 + i * 44)
		item_label.size = Vector2(52, 40)
		item_label.add_theme_font_size_override("font_size", 9)
		item_label.add_theme_color_override("font_color", Color.WHITE)
		item_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		inv_panel.add_child(item_label)

	_refresh_inv_panel()
	Inventory.inventory_changed.connect(_refresh_inv_panel)

	var briefing = Panel.new()
	briefing.name = "BriefingPanel"
	briefing.position = Vector2(200, 160)
	briefing.size = Vector2(400, 260)
	briefing.modulate = Color(1, 1, 1, 0.0)
	briefing.visible = false
	hud.add_child(briefing)

	var briefing_title = Label.new()
	briefing_title.name = "BriefTitle"
	briefing_title.position = Vector2(20, 20)
	briefing_title.size = Vector2(360, 30)
	briefing_title.add_theme_font_size_override("font_size", 18)
	briefing_title.add_theme_color_override("font_color", Color("#ffd700"))
	briefing_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	briefing.add_child(briefing_title)

	var briefing_body = RichTextLabel.new()
	briefing_body.name = "BriefBody"
	briefing_body.position = Vector2(20, 60)
	briefing_body.size = Vector2(360, 150)
	briefing_body.add_theme_font_size_override("font_size", 13)
	briefing_body.add_theme_color_override("font_color", Color("#2a1a0a"))
	briefing_body.fit_content = true
	briefing.add_child(briefing_body)

	var briefing_btn = Button.new()
	briefing_btn.name = "BriefBtn"
	briefing_btn.position = Vector2(150, 220)
	briefing_btn.size = Vector2(100, 28)
	briefing_btn.text = "新的一天！"
	briefing_btn.add_theme_font_size_override("font_size", 14)
	briefing_btn.pressed.connect(_close_briefing)
	briefing.add_child(briefing_btn)

	DayTime.morning_briefing.connect(_on_morning_briefing)

	var guide = Panel.new()
	guide.name = "GuidePanel"
	guide.position = Vector2(300, 250)
	guide.size = Vector2(200, 140)
	guide.modulate = Color(1, 1, 1, 0.95)
	guide.visible = false
	hud.add_child(guide)

	var guide_label = Label.new()
	guide_label.name = "GuideLabel"
	guide_label.position = Vector2(8, 8)
	guide_label.size = Vector2(184, 100)
	guide_label.add_theme_color_override("font_color", Color("#2a1a0a"))
	guide_label.add_theme_font_size_override("font_size", 13)
	guide_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	guide_label.text = ""
	guide.add_child(guide_label)

	var guide_next = Button.new()
	guide_next.name = "GuideNextBtn"
	guide_next.position = Vector2(60, 112)
	guide_next.size = Vector2(80, 24)
	guide_next.text = "继续 ▶"
	guide_next.add_theme_font_size_override("font_size", 11)
	guide_next.pressed.connect(_advance_guide)
	guide.add_child(guide_next)

	var guide_skip = Button.new()
	guide_skip.name = "GuideSkipBtn"
	guide_skip.position = Vector2(145, 112)
	guide_skip.size = Vector2(45, 24)
	guide_skip.text = "璺宠繃"
	guide_skip.add_theme_font_size_override("font_size", 10)
	guide_skip.pressed.connect(_skip_guide)
	guide.add_child(guide_skip)

	_hud_setup_done = true

func _select_tool(index: int):
	current_tool = clampi(index, 0, 3)
	_update_tool_highlight()

func _update_tool_highlight():
	var panel = get_node_or_null("HUD/ToolPanel")
	if not panel: return
	for i in 4:
		var btn = panel.get_node_or_null("ToolBtn" + str(i))
		if btn:
			if i == current_tool:
				btn.add_theme_color_override("font_color", Color("#ffd700"))
			else:
				btn.add_theme_color_override("font_color", Color.WHITE)

func _unhandled_input(event):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var dm = get_node_or_null("/root/DialogueManager")
		if dm and dm.is_active:
			return
		_use_tool()

func _input(event):
	var dm = get_node_or_null("/root/DialogueManager")
	if event is InputEventKey and event.pressed and not (dm and dm.is_active):
		match event.keycode:
			KEY_Q: _select_tool(maxi(0, current_tool - 1))
			KEY_E: _select_tool(mini(3, current_tool + 1))
			KEY_1: _select_tool(0)
			KEY_2: _select_tool(1)
			KEY_3: _select_tool(2)
			KEY_4: _select_tool(3)
			KEY_C: _toggle_crafting()
			KEY_K: _toggle_cooking()
			KEY_V: _toggle_achievement()
			KEY_J: _toggle_fish_album()

func _toggle_crafting():
	var craft_ui = get_node_or_null("HUD/CraftingUI")
	if not craft_ui:
		craft_ui = preload("res://scenes/ui/crafting_ui.tscn").instantiate()
		get_node("HUD").add_child(craft_ui)
	if craft_ui.is_open:
		craft_ui._close()
	else:
		craft_ui.open()

func _toggle_cooking():
	if HouseUpgrade.current_level < HouseUpgrade.HouseLevel.RUSTIC:
		_show_notice("需要先升级房屋！")
		return
	var cook_ui = get_node_or_null("HUD/CookingUI")
	if not cook_ui:
		cook_ui = preload("res://scenes/ui/cooking_ui.tscn").instantiate()
		get_node("HUD").add_child(cook_ui)
	if cook_ui.is_open:
		cook_ui._close()
	else:
		cook_ui.open()


func _toggle_achievement():
	var aui = get_node_or_null("/root/AchievementUI")
	if aui:
		if aui.is_open:
			aui._close()
		else:
			aui.open()

func _toggle_fish_album():
	var album = get_node_or_null("HUD/FishAlbumUI")
	if not album:
		album = preload("res://scenes/ui/fish_album_ui.tscn").instantiate()
		get_node("HUD").add_child(album)
	if album.is_open:
		album._close()
	else:
		album.open()

func _use_tool():
	if tool_cooldown or not player:
		return
	var world_pos = get_global_mouse_position()
	var tile_pos = _world_to_tile(world_pos)
	_trigger_tool_cooldown()
	match current_tool:
		0: _use_hoe(tile_pos)
		1: _use_watering_can(tile_pos)
		2: _use_seed(tile_pos)
		3: _harvest(tile_pos)

func _trigger_tool_cooldown():
	tool_cooldown = true
	get_tree().create_timer(TOOL_COOLDOWN_TIME).timeout.connect(func():
		tool_cooldown = false
	)

func _use_hoe(tile_pos: Vector2i):
	if tile_pos.x < 0 or tile_pos.x >= MAP_W or tile_pos.y < 0 or tile_pos.y >= MAP_H:
		return
	if not _try_consume_stamina(3):
		_show_floating_text(tile_pos, "Too tired!")
		return
	var tile = map_data[tile_pos.y][tile_pos.x]
	if tile == 0 or tile == 1:
		map_data[tile_pos.y][tile_pos.x] = 1
		_replace_tile(tile_pos, 1)
		Global.total_tiles_tilled += 1
		Global.stats["tiles_tilled"] = Global.total_tiles_tilled
		if farm:
			farm.use_hoe(tile_pos, null)
		_show_floating_text(tile_pos, "Tilled!")

func _use_watering_can(tile_pos: Vector2i):
	if not farm: return
	if not _try_consume_stamina(2):
		_show_floating_text(tile_pos, "Too tired!")
		return
	if farm.use_watering_can(tile_pos):
		_show_floating_text(tile_pos, "Watered!")
		_update_state_overlay(tile_pos)
	else:
		_show_floating_text(tile_pos, "Not needed")

func _use_seed(tile_pos: Vector2i):
	if not farm: return
	if not _try_consume_stamina(1):
		_show_floating_text(tile_pos, "Too tired!")
		return
	var seed_id = _get_available_seed()
	if seed_id == "":
		_show_floating_text(tile_pos, "No seeds!")
		return
	if farm.use_seed(tile_pos, seed_id):
		_show_floating_text(tile_pos, "Planted!")
		_update_crop_sprite(tile_pos)
		Inventory.remove_item(seed_id + "_seed", 1)
		Global.stats["crops_planted"] = Global.stats.get("crops_planted", 0) + 1
		if Engine.has_singleton("QuestManager"):
			get_node("/root/QuestManager").set_flag(1)
	else:
		_show_floating_text(tile_pos, "Can't plant here")

func _harvest(tile_pos: Vector2i):
	if not farm: return
	if not _try_consume_stamina(2):
		_show_floating_text(tile_pos, "Too tired!")
		return
	if farm.harvest(tile_pos):
		_show_floating_text(tile_pos, "Harvested!")
		_remove_crop_sprite(tile_pos)
		_remove_state_overlay(tile_pos)
		_spawn_harvest_particles(tile_pos)
		var crop_id = farm.get_crop_at(tile_pos)
		if crop_id:
			Inventory.add_item(crop_id.crop_id, 1)
			if randf() < 0.2:
				Inventory.add_item(crop_id.crop_id + "_seed", 1)
		if Engine.has_singleton("QuestManager"):
			get_node("/root/QuestManager").set_flag(2)
	else:
		_show_floating_text(tile_pos, "Not ready")

func _get_available_seed() -> String:
	for item_id in Inventory.inventory.keys():
		if item_id.ends_with("_seed"):
			return item_id.replace("_seed", "")
	if not Inventory.has_item("bluebell_seed"):
		Inventory.add_item("bluebell_seed", 5)
		_show_floating_text(Vector2i(18, 22), "Got 5 bluebell seeds!")
	return "bluebell"

func _try_consume_stamina(amount: int) -> bool:
	if not player or not player.has_method("consume_stamina"):
		return true
	return player.consume_stamina(amount)

func _update_stamina_display():
	var st_bar = get_node_or_null("HUD/StaminaBar")
	var st_label = get_node_or_null("HUD/StaminaLabel")
	if not st_bar or not st_label: return
	if not player or not ("stamina" in player): return
	var st = player.stamina
	var max_st = player.MAX_STAMINA
	var ratio = float(st) / float(max_st)
	st_bar.size = Vector2(116 * ratio, 8)
	if ratio > 0.5: st_bar.modulate = Color(0.2, 0.8, 0.2, 0.9)
	elif ratio > 0.25: st_bar.modulate = Color(0.9, 0.7, 0.1, 0.9)
	else: st_bar.modulate = Color(0.9, 0.2, 0.2, 0.9)
	st_label.text = "体力: %d/%d" % [st, max_st]

func _update_affection_display():
	var aff_label = get_node_or_null("HUD/AffectionDisplay")
	if not aff_label: return
	if not Engine.has_singleton("Affection"): return
	var hearts = get_node("/root/Affection").get_heart_level("liaofang")
	aff_label.text = "[H " + str(hearts) + "/10] LiaoFang"

func _spawn_harvest_particles(tile_pos: Vector2i):
	var colors = [Color("#ffd700"), Color("#ff6b8a"), Color("#6a9c5f"), Color("#ffa500"), Color("#87ceeb")]
	var center = _tile_center(tile_pos)
	for i in 8:
		var particle = ColorRect.new()
		particle.size = Vector2(4, 4)
		particle.color = colors[i % colors.size()]
		particle.position = center + Vector2(randf_range(-8, 8), randf_range(-8, 8))
		particle.z_index = 10
		add_child(particle)
		var tween = create_tween()
		var target = center + Vector2(randf_range(-40, 40), randf_range(-40, 40))
		tween.tween_property(particle, "position", target, 0.5)
		tween.parallel().tween_property(particle, "modulate:a", 0.0, 0.5)
		tween.tween_callback(func(): if is_instance_valid(particle): particle.queue_free())

func _generate_map():
	map_data.clear()
	for y in range(MAP_H):
		map_data.append([])
		for x in range(MAP_W):
			var tile = 0
			# Border fence
			if x < 1 or x >= MAP_W - 1 or y < 1 or y >= MAP_H - 1:
				tile = 5
			# Farmhouse area (col 34-42, row 2-8)
			elif x >= 34 and x < 42 and y >= 2 and y < 8:
				if x >= 35 and x < 41 and y >= 3 and y < 7:
					tile = 6  # house wall
			elif x >= 36 and x < 40 and y == 8:
				tile = 7  # house door
			# Porch path
			elif x >= 36 and x < 40 and y == 9:
				tile = 8
			# Walkway from house to south
			elif x >= 36 and x < 40 and y >= 10 and y < 14:
				tile = 8
			# Greenhouse (col 44-51, row 3-8)
			elif x >= 44 and x < 51 and y >= 3 and y < 8:
				if x >= 45 and x < 50 and y >= 4 and y < 7:
					tile = 6  # greenhouse walls
			elif x >= 46 and x < 49 and y == 8:
				tile = 7  # greenhouse door
			# Well (col 28-30, row 6-8)
			elif x >= 28 and x < 31 and y >= 6 and y < 9:
				tile = 2  # water/well
			# Fence around house area
			elif y == 10 and x >= 32 and x < 44:
				tile = 5
			elif y == 11 and x >= 32 and x < 44:
				tile = 0
			# Large fence ring around farmland
			elif y == 14 and x >= 8 and x < 56:
				tile = 5
			elif y == 45 and x >= 8 and x < 56:
				tile = 5
			elif x == 8 and y >= 14 and y < 45:
				tile = 5
			elif x == 55 and y >= 14 and y < 45:
				tile = 5
			# Farmland (plowed dirt)
			elif y >= 15 and y < 45 and x >= 9 and x < 55:
				if y >= 30 and y < 34 and x >= 33 and x < 37:
					tile = 0  # small pond in farmland
				elif y >= 15 and y < 18 and x >= 9 and x < 55:
					tile = 1  # top rows farmed
				elif y >= 40 and y < 45 and x >= 9 and x < 55:
					tile = 1  # bottom rows farmed
				else:
					var r = (x * 7 + y * 13) % 10
					if r < 5:
						tile = 1  # farmland
					else:
						tile = 0  # grass
			# Path from house to south exit
			elif x >= 37 and x < 41 and y >= 46 and y < 62:
				tile = 8  # main path
			# South exit (gate)
			elif y >= 62 and y < 64 and x >= 36 and x < 42:
				tile = 8
			# Bottom-right pond
			elif x > MAP_W - 10 and x < MAP_W - 2 and y > MAP_H - 10 and y < MAP_H - 2:
				tile = 2  # pond
			# Trees around edges
			elif (x < 8 or x > 55) and y < 14:
				if (x * 7 + y * 13) % 5 < 3:
					tile = 3
			elif (x < 8 or x > 55) and y > 45:
				if (x * 7 + y * 13) % 5 < 3:
					tile = 3
			# Flowers in front of house
			elif x >= 32 and x < 36 and y >= 12 and y < 14:
				tile = 4
			elif x >= 44 and x < 48 and y >= 12 and y < 14:
				tile = 4
			# Random flowers
			elif tile == 0 and (x * 7 + y * 13) % 37 < 1:
				tile = 4
			# Scatter some trees in open grass
			elif tile == 0 and (x * 7 + y * 13) % 23 < 1 and y > 12:
				tile = 3
			map_data[y].append(tile)
	_draw_tiles()

func _draw_tiles():
	for child in $Tiles.get_children(): child.queue_free()
	for y in range(MAP_H):
		for x in range(MAP_W):
			var t = map_data[y][x]
			var variant = (x * 7 + y * 13 + DayTime.current_day) % 8
			var sprite = Sprite2D.new()
			sprite.texture = _get_tile_texture(t, variant)
			sprite.position = Vector2(x * TILE_SIZE + TILE_SIZE/2, y * TILE_SIZE + TILE_SIZE/2)
			sprite.scale = Vector2(ZOOM, ZOOM)
			sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
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
		6: return PixelArtist.generate_tile("house_wall", variant)
		7: return PixelArtist.generate_tile("door", variant)
		8: return PixelArtist.generate_tile("path", variant)
		_: return PixelArtist.generate_tile("grass", variant)

func _setup_collision():
	for child in $Collision.get_children(): child.queue_free()
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

func _replace_tile(tile_pos: Vector2i, new_tile: int):
	var variant = (tile_pos.x * 7 + tile_pos.y * 13 + DayTime.current_day) % 8
	var old_name = "Tile_%d_%d" % [tile_pos.x, tile_pos.y]
	for child in $Tiles.get_children():
		if child.name == old_name:
			var sprite = child as Sprite2D
			if sprite:
				sprite.texture = _get_tile_texture(new_tile, variant)
				sprite.scale = Vector2(ZOOM, ZOOM)
			break

func _setup_players_and_npcs():
	# Inline player creation (player_scene.tscn instantiate causes gray screen on AMD+OpenGL3)
	var p = CharacterBody2D.new()
	p.name = "Player"
	p.collision_layer = 1
	p.collision_mask = 2
	$Entities.add_child(p)
	player = p
	
	# Sprite — 先创建并放一个明确颜色的备选精灵
	var spr := Sprite2D.new()
	spr.name = "Sprite2D"
	# 用一个明确的备选纹理确保可见：16x32 蓝色方块
	var fallback_img := Image.create(16, 32, false, Image.FORMAT_RGBA8)
	fallback_img.fill(Color("#4888d0"))
	spr.texture = ImageTexture.create_from_image(fallback_img)
	spr.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	spr.centered = true
	spr.z_index = 2
	spr.scale = Vector2(2.0, 2.0)
	p.add_child(spr)
	
	# Collision
	var col = CollisionShape2D.new()
	var col_r = RectangleShape2D.new()
	col_r.size = Vector2(10, 16)
	col.shape = col_r
	p.add_child(col)
	
	# Interaction area
	var ia = Area2D.new()
	ia.name = "InteractArea"
	ia.collision_layer = 0
	ia.collision_mask = 4
	var ia_shape = CollisionShape2D.new()
	var ia_r = RectangleShape2D.new()
	ia_r.size = Vector2(40, 32)
	ia_shape.shape = ia_r
	ia.add_child(ia_shape)
	p.add_child(ia)
	
	# Camera — 从 player 独立出来，实现平滑跟随
	var cam = Camera2D.new()
	cam.name = "GameCamera"
	cam.anchor_mode = 0
	cam.zoom = Vector2(1.5, 1.5)
	cam.position_smoothing_enabled = true
	cam.position_smoothing_speed = 6.0
	add_child(cam)
	
	# Extra modules
	p.set_script(load("res://scripts/player/player.gd"))
	p.stamina = 270
	
	# Position
	if Global.player_pos != Vector2.ZERO:
		p.global_position = Global.player_pos
	else:
		p.global_position = Vector2(480, 960)
	
	# Pet
	var pet_scene = preload("res://scenes/world/pet_scene.tscn")
	if pet_scene:
		var pet = pet_scene.instantiate()
		pet.name = "Pet"
		pet.position = p.position + Vector2(30, 0)
		pet.set_target(p)
		$Entities.add_child(pet)

func _on_time_changed(hour, minute, day, season, year):
	var hud = get_node_or_null("HUD/TimeDisplay")
	if hud:
		hud.text = DayTime.get_full_date_string() + " | " + DayTime.get_time_string()
	var season_label = get_node_or_null("HUD/SeasonDisplay")
	if season_label:
		var sname = DayTime.season_names[season]
		var weather_icons = ["☀️", "🌧️", "🌨️", "🌤️"]
		var wi = clampi(DayTime.current_weather, 0, weather_icons.size() - 1)
		season_label.text = "%s %s 第%d天" % [weather_icons[wi], sname, day]
	var weather_label = get_node_or_null("HUD/WeatherDisplay")
	if weather_label:
		var wnames = ["晴天", "雨天", "雪天", "阴天"]
		var wn = wnames[clampi(DayTime.current_weather, 0, wnames.size() - 1)]
		weather_label.text = "第%d年 %s" % [year, wn]
	_seasonal_distractions(season, hour)
	_sync_all_crop_sprites()
	# 姣忔棩 6:00 鍔ㄧ墿浜у嚭
	if hour == 6 and minute == 0:
		_produce_animal_goods()
	# 每 日 20:00 日报
	if hour == 20 and minute == 0:
		_show_daily_report()
	# 廖芳日程：12:00-18:00 在农场
	_update_liaofang_presence(hour)
	# 天气效果
	_update_weather_effects()

func _seasonal_distractions(season, hour):
	# 季节色调覆盖层
	var overlay = get_node_or_null("SeasonOverlay")
	if not overlay:
		overlay = ColorRect.new()
		overlay.name = "SeasonOverlay"
		overlay.size = Vector2(MAP_W * TILE_SIZE * ZOOM, MAP_H * TILE_SIZE * ZOOM)
		overlay.z_index = 100
		overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(overlay)
	match season:
		0: # 春 - 淡粉
			overlay.color = Color(1.0, 0.9, 0.95, 0.03)
		1: # 夏 - 淡金
			overlay.color = Color(1.0, 1.0, 0.8, 0.03)
		2: # 秋 - 淡橙
			overlay.color = Color(1.0, 0.8, 0.6, 0.04)
		3: # 冬 - 淡蓝/白
			overlay.color = Color(0.9, 0.95, 1.0, 0.06)

	# 温室覆盖层：冬季且房屋等级>=2时显示淡蓝色覆盖
	_update_greenhouse_overlay()

func _update_greenhouse_overlay():
	var gh = get_node_or_null("GreenhouseOverlay")
	if not gh:
		gh = ColorRect.new()
		gh.name = "GreenhouseOverlay"
		gh.size = Vector2(MAP_W * TILE_SIZE * ZOOM, MAP_H * TILE_SIZE * ZOOM)
		gh.z_index = 99
		gh.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(gh)

	var is_winter = DayTime.current_season == 3  # winter
	var house_level = Global.stats.get("house_level", 1)
	if is_winter and house_level >= 2:
		gh.color = Color(0.5, 0.7, 1.0, 0.08)
		gh.visible = true
	else:
		gh.visible = false

func _on_farm_tile_changed(tile_pos: Vector2i):
	_update_state_overlay(tile_pos)

func _on_crop_harvested(tile_pos: Vector2i):
	_spawn_harvest_particles(tile_pos)
	Global.stats["crops_harvested"] = Global.stats.get("crops_harvested", 0) + 1

func _sync_all_crop_sprites():
	for child in $Entities.get_children():
		if child.name.begins_with("Crop_"): child.queue_free()
	if not farm: return
	for tile_pos in farm.crops:
		_update_crop_sprite(tile_pos)

func _sync_all_state_overlays():
	for child in $Entities.get_children():
		if child.name.begins_with("Overlay_"): child.queue_free()
	if not farm: return
	for tile_pos in farm.crops:
		_update_state_overlay(tile_pos)

func _update_crop_sprite(tile_pos: Vector2i):
	if not farm: return
	var crop = farm.get_crop_at(tile_pos)
	if not crop:
		_remove_crop_sprite(tile_pos)
		return
	_remove_named_child("Crop_" + str(tile_pos.x) + "_" + str(tile_pos.y))
	if crop.state == 0: return
	var stage = crop.growth_stage
	var crop_type = crop.crop_id if crop.crop_id != "" else "bluebell"
	var sprite = Sprite2D.new()
	sprite.texture = PixelArtist.generate_crop_sprite(stage, crop_type)
	sprite.position = _tile_center(tile_pos)
	sprite.scale = Vector2(ZOOM, ZOOM)
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sprite.z_index = 3
	sprite.name = "Crop_%d_%d" % [tile_pos.x, tile_pos.y]
	$Entities.add_child(sprite)

func _remove_crop_sprite(tile_pos: Vector2i):
	_remove_named_child("Crop_%d_%d" % [tile_pos.x, tile_pos.y])

func _update_state_overlay(tile_pos: Vector2i):
	_remove_named_child("Overlay_%d_%d" % [tile_pos.x, tile_pos.y])
	if not farm: return
	var crop = farm.get_crop_at(tile_pos)
	if not crop: return
	var color: Color
	match crop.state:
		1: color = Color("#8a6a3a")
		2: color = Color("#4080c0")
		3: color = Color("#ffd700")
		_: return
	var rect = ColorRect.new()
	rect.size = Vector2(TILE_SIZE * ZOOM - 2, TILE_SIZE * ZOOM - 2)
	rect.color = color
	rect.modulate = Color(1, 1, 1, 0.3)
	rect.position = _tile_top_left(tile_pos)
	rect.z_index = 0
	rect.name = "Overlay_%d_%d" % [tile_pos.x, tile_pos.y]
	$Entities.add_child(rect)

func _remove_state_overlay(tile_pos: Vector2i):
	_remove_named_child("Overlay_%d_%d" % [tile_pos.x, tile_pos.y])

func _show_floating_text(tile_pos: Vector2i, text: String):
	var label = Label.new()
	label.text = text
	label.add_theme_color_override("font_color", Color("#ffd700"))
	label.add_theme_font_size_override("font_size", 10)
	label.position = _tile_center(tile_pos) - Vector2(20, 16)
	label.z_index = 20
	add_child(label)
	get_tree().create_timer(0.8).timeout.connect(func():
		if is_instance_valid(label): label.queue_free()
	)

func _world_to_tile(world_pos: Vector2) -> Vector2i:
	return Vector2i(
		int(round(world_pos.x / (TILE_SIZE * ZOOM))),
		int(round(world_pos.y / (TILE_SIZE * ZOOM)))
	)

func _tile_top_left(tile_pos: Vector2i) -> Vector2:
	return Vector2(tile_pos.x * TILE_SIZE * ZOOM + 1, tile_pos.y * TILE_SIZE * ZOOM + 1)

func _tile_center(tile_pos: Vector2i) -> Vector2:
	return Vector2(
		tile_pos.x * TILE_SIZE * ZOOM + TILE_SIZE * ZOOM / 2,
		tile_pos.y * TILE_SIZE * ZOOM + TILE_SIZE * ZOOM / 2
	)

func _remove_named_child(name: String):
	for child in $Entities.get_children():
		if child.name == name:
			child.queue_free()
			break

# 新手引导
func _start_guide():
	if not _hud_setup_done:
		call_deferred("_start_guide")
		return
	_guide_step = 0
	_show_guide_step()

func _show_guide_step():
	var panel = get_node_or_null("HUD/GuidePanel")
	var label = get_node_or_null("HUD/GuideLabel")
	if not panel or not label: return
	if _guide_step < 0 or _guide_step >= GUIDE_STEPS.size():
		panel.visible = false
		return
	label.text = GUIDE_STEPS[_guide_step] + "\n\n\n" + str(_guide_step + 1) + "/" + str(GUIDE_STEPS.size())

	panel.visible = true

func _advance_guide():
	_guide_step += 1
	if _guide_step >= GUIDE_STEPS.size():
		_hide_guide()
		return
	_show_guide_step()

func _skip_guide():
	_guide_step = -1
	_hide_guide()

func _hide_guide():
	var panel = get_node_or_null("HUD/GuidePanel")
	if panel:
		panel.visible = false
	_guide_step = -1

# 邮件系统
func _check_mail():
	if not Engine.has_singleton("MailManager"): return
	var mm = get_node("/root/MailManager")
	mm.check_for_new_mail()
	var unread = mm.get_unread_count()
	var btn = get_node_or_null("HUD/MailBtn")
	if btn:
		btn.text = "📬" if unread == 0 else "📬 [%d]" % unread

func _open_mail():
	_check_mail()
	var mail_ui_scene = load("res://scenes/ui/mail_ui.tscn")
	if mail_ui_scene == null:
		print("ERROR: failed to load mail_ui.tscn")
		return
	var mail_ui = mail_ui_scene.instantiate()
	add_child(mail_ui)
	mail_ui.open()

func _refresh_inv_panel():
# 物品侧边栏 & 晨间简报
	var items = []
	for item_id in Inventory.inventory:
		var cnt = Inventory.get_item_count(item_id)
		if cnt <= 0: continue
		var info = Inventory.get_item_info(item_id)
		var name = info.get("name", item_id)
		if len(name) > 5: name = name.left(4) + "."
		items.append("%s x%d" % [name, cnt])
	while items.size() < 4: items.append("")
	for i in 4:
		var label = get_node_or_null("HUD/InvPanel/InvItem_%d" % i)
		if label:
			label.text = items[i] if i < items.size() else ""

func _on_morning_briefing(day: int, season: int, weather: int):
	var panel = get_node_or_null("HUD/BriefingPanel")
	if not panel: return
	var title = panel.get_node_or_null("BriefTitle")
	var body = panel.get_node_or_null("BriefBody")
	if not title or not body: return
	var season_names = ["春", "夏", "秋", "冬"]
	var w_names = ["☀️ 晴", "🌤️ 阴", "🌧️ 雨", "❄️ 雪"]
	title.text = "📋 第%d天 · %s季" % [day, season_names[season]]
	body.text = "今天天气：%s\n\n" % w_names[weather]
	if Engine.has_singleton("MailManager"):
		var unread = get_node("/root/MailManager").get_unread_count()
		if unread > 0: body.text += "📬 你有 %d 封未读邮件！\n" % unread
	var heart = Affection.get_heart_level("liaofang")
	body.text += "💰 廖芳好感：%d❤️\n" % heart
	if weather == 2: body.text += "\n🌧️ 雨天提示：作物今天自动浇水！"
	elif weather == 3: body.text += "\n❄️ 雪天提示：今天不能耕作！"
	panel.modulate = Color(1, 1, 1, 0.95)
	panel.visible = true

func _close_briefing():
	var panel = get_node_or_null("HUD/BriefingPanel")
	if panel:
		panel.visible = false
		panel.modulate = Color(1, 1, 1, 0.0)

# 农场出口 → 小镇
func _setup_farm_exit():
	# 底部中央出口→小镇（对应 map 中 gate 位置 x=36~42, y=62~64）
	var town_exit = Area2D.new()
	town_exit.name = "TownExit"
	var shape1 = CollisionShape2D.new()
	var rect1 = RectangleShape2D.new()
	rect1.size = Vector2(6 * TILE_SIZE * ZOOM, TILE_SIZE * ZOOM)
	shape1.shape = rect1
	town_exit.add_child(shape1)
	town_exit.position = Vector2(39 * TILE_SIZE * ZOOM, (MAP_H - 1) * TILE_SIZE * ZOOM + TILE_SIZE * ZOOM / 2)
	town_exit.body_entered.connect(_on_town_exit_entered)
	$Entities.add_child(town_exit)

	# 右上出口→森林（顶部）
	var forest_exit = Area2D.new()
	forest_exit.name = "ForestExit"
	var shape2 = CollisionShape2D.new()
	var rect2 = RectangleShape2D.new()
	rect2.size = Vector2(6 * TILE_SIZE * ZOOM, TILE_SIZE * ZOOM)
	shape2.shape = rect2
	forest_exit.add_child(shape2)
	forest_exit.position = Vector2((MAP_W - 4) * TILE_SIZE * ZOOM, TILE_SIZE * ZOOM / 2)
	forest_exit.body_entered.connect(_on_forest_exit_entered)
	$Entities.add_child(forest_exit)

	# 钓鱼点（池塘边）
	_setup_fishing_spot()

	# 右上矿洞出口（如果已解锁）

func _setup_fishing_spot():
	var spot = Area2D.new()
	spot.name = "FishingSpot"
	var shape = CollisionShape2D.new()
	var rect = RectangleShape2D.new()
	rect.size = Vector2(4 * TILE_SIZE * ZOOM, 4 * TILE_SIZE * ZOOM)
	shape.shape = rect
	spot.add_child(shape)
	spot.position = Vector2((MAP_W - 4) * TILE_SIZE * ZOOM, (MAP_H - 4) * TILE_SIZE * ZOOM)
	spot.body_entered.connect(_on_fishing_spot_entered)
	$Entities.add_child(spot)

	# 娴爣鎻愮ず
	var hint_sprite = Sprite2D.new()
	var hint_img = Image.create(4, 4, false, Image.FORMAT_RGBA8)
	PixelArtist.p(hint_img, 1, 1, Color("#e0e0e0"))
	PixelArtist.p(hint_img, 2, 1, Color("#e0e0e0"))
	PixelArtist.p(hint_img, 1, 2, Color("#e0e0e0"))
	PixelArtist.p(hint_img, 2, 2, Color("#e0e0e0"))
	PixelArtist.p(hint_img, 2, 0, Color("#ff4444"))
	hint_sprite.texture = PixelArtist.to_tex(hint_img)
	hint_sprite.position = spot.position
	hint_sprite.position.y -= 24
	hint_sprite.z_index = 5
	hint_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	$Entities.add_child(hint_sprite)

func _on_fishing_spot_entered(body: Node):
	if not body.is_in_group("player"):
		return
	if not body.has_method("set_movement"):
		return
	# 弹出钓鱼小游戏
	var fish_game = null
	if not fish_game:
		fish_game = preload("res://scenes/ui/fish_game.tscn").instantiate()
		get_node("HUD").add_child(fish_game)
	fish_game.open()

func _on_town_exit_entered(body: Node):
	if body.has_method("set_movement"):
		body.set_movement(false)
		Global.player_pos = Vector2(3 * TILE_SIZE * ZOOM, (25 - 2) * TILE_SIZE * ZOOM)
		get_tree().change_scene_to_file("res://scenes/town/town_scene.tscn")

func _on_forest_exit_entered(body: Node):
	if body.has_method("set_movement"):
		body.set_movement(false)
		Global.player_pos = Vector2(4 * TILE_SIZE * ZOOM, 4 * TILE_SIZE * ZOOM)
		get_tree().change_scene_to_file("res://scenes/forest/forest_scene.tscn")

func _setup_mine_exit():
	var mine_exit = Area2D.new()
	mine_exit.name = "MineExit"
	var shape = CollisionShape2D.new()
	var rect = RectangleShape2D.new()
	rect.size = Vector2(4 * TILE_SIZE * ZOOM, TILE_SIZE * ZOOM)
	shape.shape = rect
	mine_exit.add_child(shape)
	mine_exit.position = Vector2((MAP_W - 1) * TILE_SIZE * ZOOM, 4 * TILE_SIZE * ZOOM)
	mine_exit.body_entered.connect(_on_mine_exit_entered)
	$Entities.add_child(mine_exit)

	# 鐭挎礊鍏ュ彛鎸囩ず
	if not Global.stats.get("mine_unlocked", false):
		var lock = Label.new()
		lock.text = "⛏ 城北矿洞（需在商店购买入场券）"
		lock.add_theme_color_override("font_color", Color("#ff6b6b"))
		lock.add_theme_font_size_override("font_size", 10)
		lock.position = Vector2((MAP_W - 6) * TILE_SIZE * ZOOM, 2 * TILE_SIZE * ZOOM)
		lock.z_index = 5
		$Entities.add_child(lock)

func _on_mine_exit_entered(body: Node):
	if not Global.stats.get("mine_unlocked", false):
		return
	if body.has_method("set_movement"):
		body.set_movement(false)
		Global.player_pos = Vector2(2 * TILE_SIZE * ZOOM, (MAP_H - 3) * TILE_SIZE * ZOOM)
		Global.current_scene = "mine"
		get_tree().change_scene_to_file("res://scenes/mine/mine_scene.tscn")

func is_walkable(global_pos: Vector2) -> bool:
	var tile_pos = global_pos / (TILE_SIZE * ZOOM)
	var x = int(round(tile_pos.x))
	var y = int(round(tile_pos.y))
	if x < 0 or x >= MAP_W or y < 0 or y >= MAP_H: return false
	if map_data[y][x] in [2, 6, 3, 5]: return false
	return true

func _refresh_quest_hint():
	if not Engine.has_singleton("QuestManager"): return
	var qm = get_node("/root/QuestManager")
	var hint = qm.get_hint()
	var label = get_node_or_null("HUD/QuestHint")
	if label: label.text = hint

func _produce_animal_goods():
	if Global.stats.get("has_coop", false):
		Inventory.add_item("egg", 2)
		_show_notice("🐔 鸡舍产出 2 个鸡蛋！")
	if Global.stats.get("has_barn", false):
		Inventory.add_item("milk", 2)
		_show_notice("🐄 牛栏产出 2 瓶牛奶！")

func _show_daily_report():
	var report = get_node_or_null("HUD/DailyReport")
	if not report:
		report = preload("res://scenes/ui/daily_report_ui.tscn").instantiate()
		get_node("HUD").add_child(report)
	report.show_report({
		"harvested": Global.stats.get("crops_harvested", 0),
		"watered": Global.stats.get("crops_watered", 0),
		"planted": Global.stats.get("crops_planted", 0),
		"tilled": Global.stats.get("tiles_tilled", 0),
		"gold_earned": Global.stats.get("gold_earned", 0),
		"items_gained": Inventory.get_item_count("bluebell") + Inventory.get_item_count("tomato") + Inventory.get_item_count("wheat"),
		"mine_floor": Global.stats.get("mine_max_floor", 1),
	})

func _show_daily_costs():
	# 检查今天是否已扣过
	if Global.stats.get("last_cost_day", 0) == DayTime.current_day:
		return

	var costs = Global._calculate_daily_costs()
	var can_afford = Global._apply_daily_costs()

	var cost_panel = Panel.new()
	cost_panel.name = "CostPanel"
	cost_panel.position = Vector2(250, 180)
	cost_panel.size = Vector2(300, 260)
	cost_panel.modulate = Color(1, 1, 1, 0.95)
	get_node("HUD").add_child(cost_panel)

	var title = Label.new()
	title.text = "💰 每日运营成本"
	title.position = Vector2(20, 15)
	title.size = Vector2(260, 25)
	title.add_theme_font_size_override("font_size", 16)
	title.add_theme_color_override("font_color", Color("#8b4513"))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	cost_panel.add_child(title)

	var body = RichTextLabel.new()
	body.position = Vector2(20, 50)
	body.size = Vector2(260, 130)
	body.add_theme_font_size_override("font_size", 13)
	body.add_theme_color_override("font_color", Color("#2a1a0a"))
	body.fit_content = true
	cost_panel.add_child(body)

	var cost_text = ""
	cost_text += "🏛️ 税收：%d G\n" % costs["tax"]
	cost_text += "⚡ 电费：%d G\n" % costs["electricity"]
	cost_text += "🔧 维护：%d G\n" % costs["maintenance"]
	cost_text += "----------\n"
	if can_afford:
		cost_text += "💳 总计支出：%d G" % costs["total"]
	else:
		cost_text += "[color=red]💳 总计支出：%d G（金币不足！）[/color]" % costs["total"]
	cost_text += "\n🏦 余额：%d G" % Inventory.gold
	body.text = cost_text

	var close_btn = Button.new()
	close_btn.position = Vector2(100, 200)
	close_btn.size = Vector2(100, 28)
	close_btn.text = "知道了"
	close_btn.add_theme_font_size_override("font_size", 14)
	close_btn.pressed.connect(func():
		if is_instance_valid(cost_panel):
			cost_panel.queue_free()
		# 金币不足时显示红色闪烁
		if not can_afford:
			_show_insufficient_gold_warning()
	)
	cost_panel.add_child(close_btn)

func _show_insufficient_gold_warning():
	var gold_label = get_node_or_null("HUD/GoldDisplay")
	if not gold_label: return
	# 红色闪烁效果
	gold_label.add_theme_color_override("font_color", Color.RED)
	var tween = create_tween()
	tween.set_loops(6)
	tween.tween_property(gold_label, "modulate:a", 0.3, 0.2)
	tween.tween_property(gold_label, "modulate:a", 1.0, 0.2)
	tween.tween_callback(func():
		if is_instance_valid(gold_label):
			gold_label.add_theme_color_override("font_color", Color("#ffd700"))
			gold_label.modulate = Color(1, 1, 1, 1)
	)

func _check_festival():
	if not Engine.has_singleton("FestivalManager"):
		return
	var fm = get_node("/root/FestivalManager")
	var fid = fm.get_today_festival()
	if fid == "":
		return
	var finfo = fm.get_festival_info(fid)
	if finfo.is_empty():
		return

	# 显示节日通知
	var festival_panel = Panel.new()
	festival_panel.name = "FestivalBanner"
	festival_panel.position = Vector2(280, 120)
	festival_panel.size = Vector2(240, 180)
	festival_panel.modulate = Color(1, 1, 1, 0.95)
	get_node("HUD").add_child(festival_panel)

	var title = Label.new()
	title.text = "🎉 " + finfo["name"]
	title.position = Vector2(10, 15)
	title.size = Vector2(220, 30)
	title.add_theme_font_size_override("font_size", 18)
	title.add_theme_color_override("font_color", Color("#ff6b8a"))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	festival_panel.add_child(title)

	var body = RichTextLabel.new()
	body.position = Vector2(10, 50)
	body.size = Vector2(220, 80)
	body.add_theme_font_size_override("font_size", 12)
	body.add_theme_color_override("font_color", Color("#2a1a0a"))
	body.fit_content = true
	body.text = finfo["description"] + "\n\n去节日地点参加吧！"
	festival_panel.add_child(body)

	var join_btn = Button.new()
	join_btn.position = Vector2(20, 140)
	join_btn.size = Vector2(90, 28)
	join_btn.text = "参加！"
	join_btn.add_theme_font_size_override("font_size", 14)
	join_btn.pressed.connect(func():
		if is_instance_valid(festival_panel):
			festival_panel.queue_free()
		_execute_festival(fid)
	)
	festival_panel.add_child(join_btn)

	var skip_btn = Button.new()
	skip_btn.position = Vector2(130, 140)
	skip_btn.size = Vector2(90, 28)
	skip_btn.text = "跳过"
	skip_btn.add_theme_font_size_override("font_size", 14)
	skip_btn.pressed.connect(func():
		if is_instance_valid(festival_panel):
			festival_panel.queue_free()
		_show_notice("你错过了" + finfo["name"] + "……")
	)
	festival_panel.add_child(skip_btn)

func _execute_festival(fid: String):
	if not Engine.has_singleton("FestivalManager"):
		return
	var fm = get_node("/root/FestivalManager")
	var result = fm.execute_today_festival()

	var result_panel = Panel.new()
	result_panel.name = "FestivalResult"
	result_panel.position = Vector2(250, 200)
	result_panel.size = Vector2(300, 160)
	result_panel.modulate = Color(1, 1, 1, 0.95)
	get_node("HUD").add_child(result_panel)

	var body = RichTextLabel.new()
	body.position = Vector2(15, 20)
	body.size = Vector2(270, 100)
	body.add_theme_font_size_override("font_size", 13)
	body.add_theme_color_override("font_color", Color("#2a1a0a"))
	body.fit_content = true
	body.text = result.get("message", "节日结束！")
	result_panel.add_child(body)

	var close_btn = Button.new()
	close_btn.position = Vector2(100, 120)
	close_btn.size = Vector2(100, 28)
	close_btn.text = "太好了！"
	close_btn.add_theme_font_size_override("font_size", 14)
	close_btn.pressed.connect(func():
		if is_instance_valid(result_panel):
			result_panel.queue_free()
	)
	result_panel.add_child(close_btn)

func _show_notice(text: String):
	var label = Label.new()
	label.text = text
	label.add_theme_color_override("font_color", Color("#ffd700"))
	label.add_theme_font_size_override("font_size", 12)
	label.position = Vector2(200, 200)
	label.z_index = 100
	add_child(label)
	get_tree().create_timer(2.5).timeout.connect(func():
		if is_instance_valid(label): label.queue_free()
	)

func _update_liaofang_presence(hour: int):
	var existing = get_node_or_null("Entities/LiaoFang")
	var should_be_here = hour >= 6 and hour < 18
	if should_be_here and not existing:
		var lf = preload("res://scenes/world/liaofang_scene.tscn").instantiate()
		lf.name = "LiaoFang"
		lf.position = Vector2(480, 960) + Vector2(randf_range(-60, 60), randf_range(-60, 60))
		$Entities.add_child(lf)
	elif not should_be_here and existing:
		existing.queue_free()

# 鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲
# 🌤️ 天气效果
# 鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲
func _update_weather_effects():
	var weather_layer = get_node_or_null("WeatherLayer")
	if not weather_layer:
		weather_layer = Node2D.new()
		weather_layer.name = "WeatherLayer"
		weather_layer.z_index = 200
		add_child(weather_layer)

	# 清除旧粒子（安全检查）
	if is_instance_valid(weather_layer):
		for c in weather_layer.get_children():
			if is_instance_valid(c):
				c.queue_free()

	var w = DayTime.current_weather
	if w == DayTime.Weather.RAINY:
		_spawn_rain(weather_layer)
	elif w == DayTime.Weather.SNOWY:
		_spawn_snow(weather_layer)

func _spawn_rain(parent: Node):
	if not is_instance_valid(parent) or not is_inside_tree():
		return
	for i in range(60):
		var drop = ColorRect.new()
		drop.size = Vector2(1, 6)
		drop.color = Color(0.6, 0.7, 0.9, 0.4)
		drop.position = Vector2(randf() * MAP_W * TILE_SIZE * ZOOM, randf() * MAP_H * TILE_SIZE * ZOOM)
		drop.z_index = 200
		drop.set_meta("speed", randf_range(80, 150))
		drop.set_meta("wind", randf_range(-20, 10))
		if is_instance_valid(parent):
			parent.add_child(drop)
		# 随机延迟启动
		var tween = create_tween()
		tween.tween_property(drop, "color:a", 0.5, 0.1)
		tween.set_loops()
		tween.tween_interval(0.05)

	# 持续下落循环
	_rain_loop(parent)

func _rain_loop(parent: Node):
	if not is_instance_valid(parent) or not is_inside_tree():
		return
	if parent.get_child_count() == 0:
		return
	for child in parent.get_children():
		if not is_instance_valid(child): continue
		child.position += Vector2(child.get_meta("wind"), child.get_meta("speed")) * 0.05
		if child.position.y > MAP_H * TILE_SIZE * ZOOM:
			child.position.y = -10
			child.position.x = randf() * MAP_W * TILE_SIZE * ZOOM
	await get_tree().create_timer(0.05).timeout
	_rain_loop(parent)

func _spawn_snow(parent: Node):
	if not is_instance_valid(parent) or not is_inside_tree():
		return
	for i in range(40):
		var flake = ColorRect.new()
		flake.size = Vector2(3, 3)
		flake.color = Color(1, 1, 1, 0.6)
		flake.position = Vector2(randf() * MAP_W * TILE_SIZE * ZOOM, randf() * MAP_H * TILE_SIZE * ZOOM)
		flake.z_index = 200
		flake.set_meta("speed", randf_range(20, 50))
		flake.set_meta("sway", randf_range(0, 6.28))
		if is_instance_valid(parent):
			parent.add_child(flake)
	_snow_loop(parent)

func _snow_loop(parent: Node):
	if not is_instance_valid(parent) or not is_inside_tree():
		return
	if parent.get_child_count() == 0:
		return
	var t = Time.get_ticks_msec() / 1000.0
	for child in parent.get_children():
		if not is_instance_valid(child): continue
		var sway = child.get_meta("sway")
		child.position += Vector2(sin(t * 2 + sway) * 0.5, child.get_meta("speed")) * 0.1
		if child.position.y > MAP_H * TILE_SIZE * ZOOM:
			child.position.y = -5
			child.position.x = randf() * MAP_W * TILE_SIZE * ZOOM
	await get_tree().create_timer(0.05).timeout
	_snow_loop(parent)

# ─── 相机平滑跟随 ─────────────────────────────────

# 工具使用和作物视觉反馈
func _on_tool_used(tool_type: int, tile_pos: Vector2i) -> void:
	pass

func _on_plot_tilled(pos: Vector2i) -> void:
	var tile_size: float = 48.0
	var sprite := Sprite2D.new()
	sprite.texture = _get_tile_texture(1, 0)
	sprite.scale = Vector2(1.5, 1.5)
	sprite.z_index = 1
	sprite.position = Vector2(pos.x * tile_size + tile_size/2, pos.y * tile_size + tile_size/2)
	if has_node("Tiles"):
		$Tiles.add_child(sprite)

func _on_plot_watered(pos: Vector2i) -> void:
	# 加水湿润标记（让土块颜色更暗）
	pass

func _process(_delta: float) -> void:
	"""让相机平滑跟随玩家"""
	var cam := get_node_or_null("GameCamera") as Camera2D
	var p := get_node_or_null("Entities/Player") as Node2D
	if cam and p and is_instance_valid(p):
		cam.global_position = p.global_position