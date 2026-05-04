# FarmCore - 农场耕作核心系统
extends Node

# 地块状态
enum TileState { EMPTY, TILLED, PLANTED, WATERED, READY }

# 作物信息
class CropData:
	var pos: Vector2i
	var state: int          # TileState
	var crop_id: String
	var planted_day: int     # 种植时的天数
	var planted_season: int  # 种植时的季节
	var growth_stage: int    # 0~max_stage
	var max_stage: int
	var water_count: int     # 剩余浇水次数
	
	func _init(p: Vector2i, id: String):
		pos = p
		crop_id = id
		state = TileState.EMPTY
		planted_day = -1
		planted_season = -1
		growth_stage = 0
		max_stage = _get_max_stage(id)
		water_count = 0
	
	func _get_max_stage(id: String) -> int:
		match id:
			"bluebell": return 4
			"tomato": return 5
			"wheat": return 3
			"sunflower": return 4
			"pumpkin": return 5
			"cactus": return 3
			_: return 3

# 作物数据库（含季节限定）
const CROP_DB = {
	# 🌸 春季作物
	"bluebell": {
		"name": "蓝风铃花", "seed_name": "蓝风铃花种子",
		"growth_days": 5,
		"water_needed": 2,
		"regrow": false,
		"season": ["spring", "summer"],
		"yield_min": 1, "yield_max": 2,
		"seed_cost": 40,
		"icon": "bluebell",
	},
	# 🌻 夏季作物
	"sunflower": {
		"name": "向日葵", "seed_name": "向日葵种子",
		"growth_days": 6,
		"water_needed": 2,
		"regrow": false,
		"season": ["summer"],
		"yield_min": 1, "yield_max": 2,
		"seed_cost": 30,
		"icon": "flower",
	},
	"tomato": {
		"name": "番茄", "seed_name": "番茄种子",
		"growth_days": 7,
		"water_needed": 3,
		"regrow": true,
		"regrow_yield": 3,
		"season": ["summer"],
		"yield_min": 1, "yield_max": 3,
		"seed_cost": 20,
		"icon": "tomato",
	},
	# 🌾 秋季作物
	"pumpkin": {
		"name": "南瓜", "seed_name": "南瓜种子",
		"growth_days": 8,
		"water_needed": 3,
		"regrow": false,
		"season": ["autumn"],
		"yield_min": 1, "yield_max": 2,
		"seed_cost": 60,
		"icon": "wheat",
	},
	"wheat": {
		"name": "小麦", "seed_name": "小麦种子",
		"growth_days": 4,
		"water_needed": 1,
		"regrow": false,
		"season": ["spring", "summer", "autumn"],
		"yield_min": 1, "yield_max": 2,
		"seed_cost": 10,
		"icon": "wheat",
	},
	# 🌵 冬季作物（温室/室内）
	"cactus": {
		"name": "仙人掌果", "seed_name": "仙人掌种子",
		"growth_days": 6,
		"water_needed": 1,
		"regrow": true,
		"regrow_yield": 4,
		"season": ["winter"],
		"yield_min": 1, "yield_max": 2,
		"seed_cost": 80,
		"icon": "diamond",
	},
}

var crops: Dictionary = {}  # Vector2i -> CropData

signal tile_changed(pos: Vector2i)
signal crop_harvested(pos: Vector2i, item_id: String, count: int)

# ============ 工具操作 ============

# 锄头：翻土（无 TileMap 版本，由 farm_scene 调用）
func use_hoe(tile_pos: Vector2i, _tilemap = null) -> bool:
	if crops.has(tile_pos):
		var c = crops[tile_pos]
		if c.state == TileState.EMPTY and c.crop_id == "":
			c.state = TileState.TILLED
			tile_changed.emit(tile_pos)
			return true
		return false
	
	# 新翻土
	var cd = CropData.new(tile_pos, "")
	cd.state = TileState.TILLED
	cd.crop_id = ""
	crops[tile_pos] = cd
	tile_changed.emit(tile_pos)
	return true

# 种子：播种
func use_seed(tile_pos: Vector2i, crop_id: String) -> bool:
	if not crops.has(tile_pos):
		return false
	var c = crops[tile_pos]
	if c.state != TileState.TILLED:
		return false
	
	# 检查季节（适配 DayTime 返回的枚举值），房屋等级>=2时冬季可种任何作物
	var season_index = DayTime.current_season
	var season_names = ["spring", "summer", "autumn", "winter"]
	var season_name = season_names[season_index] if season_index < season_names.size() else "spring"
	var allowed_seasons = CROP_DB[crop_id]["season"]
	if season_name not in allowed_seasons:
		# 温室条件：冬季且房屋等级>=2
		if not (season_name == "winter" and Global.stats.get("house_level", 1) >= 2):
			return false
	
	c.crop_id = crop_id
	c.state = TileState.PLANTED
	c.planted_day = DayTime.current_day
	c.growth_stage = 0
	c.max_stage = c._get_max_stage(crop_id)
	c.water_count = 0
	tile_changed.emit(tile_pos)
	
	# 消耗种子
	Inventory.remove_item(crop_id + "_seed")
	return true

# 水壶：浇水（翻土后 TILLED 或播种后 PLANTED 均可浇水）
func use_watering_can(tile_pos: Vector2i) -> bool:
	if not crops.has(tile_pos):
		return false
	var c = crops[tile_pos]
	if c.state == TileState.TILLED:
		c.state = TileState.TILLED  # 保持 TILLED
		c.water_count += 1
		Global.total_crops_watered += 1
		tile_changed.emit(tile_pos)
		return true
	if c.state == TileState.PLANTED:
		c.state = TileState.WATERED
		c.water_count += 1
		Global.total_crops_watered += 1
		tile_changed.emit(tile_pos)
		return true
	return false

# 收获
func harvest(tile_pos: Vector2i) -> bool:
	if not crops.has(tile_pos):
		return false
	var c = crops[tile_pos]
	if c.state != TileState.READY:
		return false
	
	var info = CROP_DB[c.crop_id]
	var yield_count = randi() % (info["yield_max"] - info["yield_min"] + 1) + info["yield_min"]
	
	# 收获物
	Inventory.add_item(c.crop_id, yield_count)
	crop_harvested.emit(tile_pos, c.crop_id, yield_count)
	
	# 可再生的作物
	if info.get("regrow", false):
		c.state = TileState.PLANTED
		c.growth_stage = 0
		c.water_count = 0
		c.planted_day = DayTime.current_day
	else:
		crops.erase(tile_pos)
	
	tile_changed.emit(tile_pos)
	return true

# ============ 每日更新 ============

func on_day_start():
	var todays_growth = 0
	
	for pos in crops.keys():
		var c = crops[pos]
		
		if c.state == TileState.WATERED:
			# 浇水后生长
			var days_planted = DayTime.current_day - c.planted_day
			if days_planted >= CROP_DB[c.crop_id]["growth_days"]:
				c.state = TileState.READY
				c.growth_stage = c.max_stage
			else:
				# 计算生长阶段
				var total_stages = c.max_stage - 1  # 不含 READY
				var progress = float(days_planted) / float(CROP_DB[c.crop_id]["growth_days"])
				c.growth_stage = mini(int(progress * total_stages), total_stages)
				c.state = TileState.PLANTED  # 明天需要重新浇水
			
			todays_growth += 1
			tile_changed.emit(pos)
		elif c.state == TileState.PLANTED:
			# 没浇水，不生长
			pass
		elif c.state == TileState.READY:
			# 成熟作物保持不变
			pass
	
	if todays_growth > 0:
		Global.total_crops_harvested += todays_growth

# ============ 辅助方法 ============

func get_crop_at(pos: Vector2i) -> CropData:
	return crops.get(pos, null)
