# FestivalManager - 节日系统
extends Node

signal festival_active(festival_id: String, festival_name: String)
signal festival_completed(festival_id: String, reward: Dictionary)

const FESTIVALS = {
	"spring_flower": {
		"name": "春之花节",
		"season": 0,
		"day": 13,
		"description": "花王评选！谁的花最美丽？",
		"scene_pos": Vector2(11 * 32 * 1.5, 8 * 32 * 1.5),
	},
	"summer_fish": {
		"name": "夏之海节",
		"season": 1,
		"day": 11,
		"description": "钓鱼大赛！看谁钓得最多！",
		"scene_pos": Vector2(25 * 32 * 1.5, 16 * 32 * 1.5),
	},
	"autumn_harvest": {
		"name": "秋之收获节",
		"season": 2,
		"day": 16,
		"description": "农产品展！展示你的劳动成果！",
		"scene_pos": Vector2(11 * 32 * 1.5, 14 * 32 * 1.5),
	},
	"winter_star": {
		"name": "冬之星节",
		"season": 3,
		"day": 25,
		"description": "送礼节！向珍视的人表达心意！",
		"scene_pos": Vector2(11 * 32 * 1.5, 10 * 32 * 1.5),
	},
}

var today_festival: String = ""  # 今天的节日ID
var festival_celebrated: Dictionary = {}  # {season_day: festival_id} 已庆祝的

func _ready():
	if Engine.has_singleton("DayTime"):
		DayTime.time_changed.connect(_on_time_check)

func _on_time_check(hour: int, minute: int, day: int, season: int, year: int):
	if hour == 6 and minute == 0:
		_check_festival_today(day, season)

# 检查今天是否有节日
func _check_festival_today(day: int, season: int) -> bool:
	today_festival = ""
	for fid in FESTIVALS:
		var f = FESTIVALS[fid]
		if f["season"] == season and f["day"] == day:
			# 检查该节日是否已经庆祝过（按 season_day 去重）
			var key = "%d_%d_%d" % [DayTime.current_year, season, day]
			if festival_celebrated.has(key):
				return false
			today_festival = fid
			festival_celebrated[key] = fid
			return true
	return false

# 检查当前场景中是否有节日，返回节日信息
func get_today_festival() -> String:
	return today_festival

func get_festival_info(festival_id: String) -> Dictionary:
	return FESTIVALS.get(festival_id, {})

# 执行春之花节：检查背包中最多的flower类型物品
func _execute_spring_flower_festival() -> Dictionary:
	var best_flower = ""
	var best_count = 0
	
	for item_id in Inventory.inventory:
		var info = Inventory.get_item_info(item_id)
		if info.get("type", "") == "flower":
			var cnt = Inventory.get_item_count(item_id)
			if cnt > best_count:
				best_count = cnt
				best_flower = item_id
	
	if best_flower == "":
		return {"success": false, "message": "你没有携带任何花卉……错过了花王评选。"}
	
	# 奖励
	Inventory.add_gold(200)
	Inventory.add_item("flower_crown", 1)
	return {"success": true, "message": "你的 %s 被评为最美之花！\n获得 200 G 和 [花冠]！" % Inventory.get_item_info(best_flower).get("name", best_flower)}

# 执行夏之海节：钓鱼大赛（简化为检查背包中fish类型物品）
func _execute_summer_fish_festival() -> Dictionary:
	var fish_count = 0
	for item_id in Inventory.inventory:
		var info = Inventory.get_item_info(item_id)
		if info.get("type", "") == "fish":
			fish_count += Inventory.get_item_count(item_id)
	
	if fish_count == 0:
		return {"success": false, "message": "今天没有钓到鱼……错过了钓鱼大赛。"}
	
	Inventory.add_gold(300)
	Inventory.add_item("pearl", 1)
	var msg = "你钓到的鱼中有 %d 条参加了大赛！\n获得 300 G 和 [珍珠]！" % fish_count
	return {"success": true, "message": msg}

# 执行秋之收获节：评估crop/food物品总价值
func _execute_autumn_harvest_festival() -> Dictionary:
	var total_value = 0
	for item_id in Inventory.inventory:
		var info = Inventory.get_item_info(item_id)
		var type_str = info.get("type", "")
		if type_str == "crop" or type_str == "food":
			var val = info.get("sell_price", 0) * Inventory.get_item_count(item_id)
			total_value += val
	
	if total_value == 0:
		return {"success": false, "message": "你没有任何农产品或料理……错过了农展评比。"}
	
	var reward = total_value * 2
	Inventory.add_gold(reward)
	var msg = "你的农产品总价值 %d G！评为本届最佳！\n获得 %d G 奖励！" % [total_value, reward]
	return {"success": true, "message": msg}

# 执行冬之星节：检查好感度
func _execute_winter_star_festival() -> Dictionary:
	if not Engine.has_singleton("Affection"):
		return {"success": false, "message": "好感度系统未加载。"}
	
	var aff = get_node("/root/Affection")
	var heart_lv = aff.get_heart_level("liaofang")
	
	if heart_lv < 6:
		return {"success": false, "message": "你的好感度还不够高（需要6❤以上）……廖芳今天没来参加节日。"}
	
	Inventory.add_gold(500)
	Inventory.add_item("star_shard", 1)
	var msg = "廖芳收到了你的礼物！她感动得热泪盈眶……\n获得 500 G 和 [星之碎片]！"
	
	# 额外增加好感度
	aff.add_affection("liaofang", 50)
	return {"success": true, "message": msg}

# 执行当前节日
func execute_today_festival() -> Dictionary:
	if today_festival == "":
		return {"success": false, "message": "今天没有节日。"}
	
	match today_festival:
		"spring_flower":
			var result = _execute_spring_flower_festival()
			if result["success"]:
				festival_completed.emit(today_festival, result)
			return result
		"summer_fish":
			var result = _execute_summer_fish_festival()
			if result["success"]:
				festival_completed.emit(today_festival, result)
			return result
		"autumn_harvest":
			var result = _execute_autumn_harvest_festival()
			if result["success"]:
				festival_completed.emit(today_festival, result)
			return result
		"winter_star":
			var result = _execute_winter_star_festival()
			if result["success"]:
				festival_completed.emit(today_festival, result)
			return result
	
	return {"success": false, "message": "未知节日。"}
