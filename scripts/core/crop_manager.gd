# crop_manager.gd — 作物种植系统
# 管理：耕地状态、播种、生长、浇水、收获
# 为什么独立模块：农场场景只负责渲染，作物逻辑全部在这里

extends Node

# ─── 常量 ─────────────────────────────────────────
const MAX_GROWTH_STAGE: int = 4       # 最大生长阶段（0=种子, 4=成熟）
const GROW_TIME_MIN: float = 30.0     # 最短生长时间（秒/阶段）
const GROW_TIME_MAX: float = 60.0     # 最长生长时间（秒/阶段）
const WATER_DURATION: float = 120.0   # 浇水后持续有效时间（秒，模拟一天）

# ─── 作物数据类 ──────────────────────────────────
class CropPlot:
	var tile_pos: Vector2i        # 地图坐标
	var is_tilled: bool = false   # 是否已翻土
	var is_watered: bool = false  # 是否已浇水
	var seed_type: String = ""    # 种子类型（""=未播种）
	var growth_stage: int = 0     # 0=种子, 1-3=生长中, 4=成熟
	var growth_timer: float = 0.0
	var water_timer: float = 0.0
	var harvested: bool = false   # 是否已收获
	
	func _init(pos: Vector2i):
		tile_pos = pos

# ─── 状态 ─────────────────────────────────────────
var plots: Dictionary = {}  # key: "x,y" → CropPlot
var current_season: int = 0
var _growth_check_timer: float = 0.0

# ─── 信号 ─────────────────────────────────────────
signal plot_tilled(pos: Vector2i)
signal plot_watered(pos: Vector2i)
signal seed_planted(pos: Vector2i, seed_type: String)
signal crop_grew(pos: Vector2i, stage: int)
signal crop_harvested(pos: Vector2i, crop_type: String)

func _process(delta: float) -> void:
	"""定期检查生长进度"""
	_growth_check_timer += delta
	if _growth_check_timer >= 3.0:  # 每3秒检查一次
		_growth_check_timer = 0.0
		_update_growth(delta * 3)

func till_soil(pos: Vector2i) -> bool:
	"""翻土（锄头）"""
	var key := "%d,%d" % [pos.x, pos.y]
	if key in plots and plots[key].is_tilled:
		return false  # 已翻过
	var plot := CropPlot.new(pos)
	plot.is_tilled = true
	plot.is_watered = false
	plots[key] = plot
	plot_tilled.emit(pos)
	return true

func water_soil(pos: Vector2i) -> bool:
	"""浇水"""
	var key := "%d,%d" % [pos.x, pos.y]
	var plot: CropPlot = plots.get(key, null)
	if not plot or not plot.is_tilled:
		return false
	plot.is_watered = true
	plot.water_timer = WATER_DURATION
	plot_watered.emit(pos)
	return true

func plant_seed(pos: Vector2i, seed_type: String) -> bool:
	"""播种"""
	var key := "%d,%d" % [pos.x, pos.y]
	var plot: CropPlot = plots.get(key, null)
	if not plot or not plot.is_tilled:
		return false
	if plot.seed_type != "":
		return false  # 已有作物
	plot.seed_type = seed_type
	plot.growth_stage = 0
	plot.growth_timer = 0.0
	plot.harvested = false
	seed_planted.emit(pos, seed_type)
	return true

func harvest(pos: Vector2i) -> String:
	"""收获作物，返回作物类型"""
	var key := "%d,%d" % [pos.x, pos.y]
	var plot: CropPlot = plots.get(key, null)
	if not plot or not plot.seed_type or plot.growth_stage < MAX_GROWTH_STAGE:
		return ""
	if plot.harvested:
		return ""
	plot.harvested = true
	plot.seed_type = ""
	plot.growth_stage = 0
	var crop = plot.seed_type  # 保存收获前的类型
	crop_harvested.emit(pos, crop)
	return crop

func get_plot(pos: Vector2i) -> CropPlot:
	return plots.get("%d,%d" % [pos.x, pos.y], null)

func _update_growth(delta: float) -> void:
	"""更新所有已浇水作物的生长进度"""
	for key in plots:
		var plot: CropPlot = plots[key]
		if not plot.seed_type or plot.harvested:
			continue
		if plot.growth_stage >= MAX_GROWTH_STAGE:
			continue  # 已成熟
		if not plot.is_watered:
			continue  # 未浇水不生长
		
		plot.growth_timer += delta
		var need_time := lerpf(GROW_TIME_MIN, GROW_TIME_MAX, randf())
		if plot.growth_timer >= need_time:
			plot.growth_timer = 0.0
			plot.growth_stage += 1
			if plot.growth_stage > MAX_GROWTH_STAGE:
				plot.growth_stage = MAX_GROWTH_STAGE
			crop_grew.emit(plot.tile_pos, plot.growth_stage)
		
		# 浇水计时
		plot.water_timer -= delta
		if plot.water_timer <= 0.0:
			plot.is_watered = false
