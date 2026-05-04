# SaveManager
extends Node

const SAVE_PATH = "user://save/save_data.res"

func save_game():
	var data = {
		"player_name": Global.player_name,
		"time": {
			"tick": DayTime.current_tick,
			"day": DayTime.current_day,
			"season": DayTime.current_season,
			"year": DayTime.current_year,
			"weather": DayTime.current_weather
		},
		"player_pos": {
			"scene": Global.current_scene,
			"x": Global.player_pos.x if Global.player_pos else 0,
			"y": Global.player_pos.y if Global.player_pos else 0
		},
		"inventory": Inventory.save_data(),
		"mail": MailManager.save_data() if Engine.has_singleton("MailManager") else {},
		"affection": {
			"affections": Affection.affections.duplicate(),
			"triggered_events": Affection.triggered_events.duplicate()
		},
		"farm": {
			"plots": Global.farm_data if Global.farm_data else {}
		},
		"stats": Global.stats if Global.stats else {},
		"pet": {
			"has_pet": Global.stats.get("has_pet_dog", false) or Global.stats.get("has_pet_cat", false),
			"pet_type": 0 if Global.stats.get("has_pet_dog", false) else (1 if Global.stats.get("has_pet_cat", false) else -1),
		},
		"house": {
			"level": HouseUpgrade.current_level if Engine.has_singleton("HouseUpgrade") else 0,
		}
	}
	
	var dir = DirAccess.open("user://")
	if not dir.dir_exists("save"):
		dir.make_dir("save")
	
	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	file.store_var(data)
	print("游戏已保存")
	return true

func load_game() -> bool:
	if not FileAccess.file_exists(SAVE_PATH):
		return false
	
	var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
	var data = file.get_var()
	
	Global.player_name = data.get("player_name", "玩家")
	
	var td = data.get("time", {})
	DayTime.set_time(td.get("tick", 480) / 60, td.get("tick", 480) % 60)
	DayTime.current_day = td.get("day", 1)
	DayTime.current_season = td.get("season", 0)
	DayTime.current_year = td.get("year", 1)
	if td.has("weather"):
		DayTime.current_weather = td.get("weather")
	
	var pd = data.get("player_pos", {})
	Global.player_pos = Vector2(pd.get("x", 300), pd.get("y", 300))
	Global.current_scene = pd.get("scene", "farm")
	
	Inventory.load_data(data.get("inventory", {}))
	
	if Engine.has_singleton("MailManager"):
		var md = data.get("mail", {})
		if not md.is_empty():
			get_node("/root/MailManager").load_data(md)
	
	var ad = data.get("affection", {})
	if ad.has("affections"):
		Affection.affections = ad["affections"].duplicate()
	if ad.has("triggered_events"):
		Affection.triggered_events = ad["triggered_events"].duplicate()
	
	Global.farm_data = data.get("farm", {}).get("plots", {})
	Global.stats = data.get("stats", {})
	
	# 恢复宠物数据
	var pet_data = data.get("pet", {})
	if pet_data.get("has_pet", false):
		var pet_type = pet_data.get("pet_type", 0)
		if pet_type == 0:
			Global.stats["has_pet_dog"] = true
		elif pet_type == 1:
			Global.stats["has_pet_cat"] = true
	
	# 恢复房屋数据
	var hd = data.get("house", {})
	if hd.has("level") and Engine.has_singleton("HouseUpgrade"):
		HouseUpgrade.current_level = hd["level"]
	
	print("游戏已加载")
	return true

func has_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH)

func delete_save():
	var dir = DirAccess.open("user://save/")
	if dir:
		dir.remove("save_data.res")
	print("存档已删除")
