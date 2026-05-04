# DayTime 时间系统
# 20分钟现实 = 1游戏日
# 1 Tick = 0.83秒现实 = 1分钟游戏
extends Node

signal time_changed(hour, minute, day, season, year)
signal day_changed(day)
signal season_changed(season)
signal weather_changed(weather)
signal morning_briefing(day, season, weather)

enum Season { SPRING, SUMMER, AUTUMN, WINTER }
enum Weather { SUNNY, CLOUDY, RAINY, SNOWY }

const TICKS_PER_HOUR = 60    # 1小时 = 60 Tick
const HOURS_PER_DAY = 24     # 24小时制
const TICKS_PER_DAY = 1440   # 1440 Tick = 1天
const DAYS_PER_SEASON = 28   # 28天一季
const SEASONS_PER_YEAR = 4

const TICK_INTERVAL = 0.833  # 现实秒数 = 游戏1分钟

var tick_timer: Timer
var current_tick: int = 480  # 6:00 AM 开始
var current_day: int = 1
var current_season: int = Season.SPRING
var current_year: int = 1
var current_weather: int = Weather.SUNNY
var is_paused: bool = false

var season_names = ["春", "夏", "秋", "冬"]
var weather_names = ["晴", "阴", "雨", "雪"]

func _ready():
	tick_timer = Timer.new()
	tick_timer.wait_time = TICK_INTERVAL
	tick_timer.timeout.connect(_on_tick)
	add_child(tick_timer)
	tick_timer.start()
	
	# 设置随机初始天气
	_randomize_weather()

func _on_tick():
	if is_paused:
		return
	
	current_tick += 1
	if current_tick >= TICKS_PER_DAY:
		current_tick = 0
		_advance_day()
	
	_emit_time()

func _advance_day():
	current_day += 1
	if current_day > DAYS_PER_SEASON:
		current_day = 1
		_advance_season()
	day_changed.emit(current_day)
	# 清晨 6:00 触发简报
	morning_briefing.emit(current_day, current_season, current_weather)

func _advance_season():
	current_season = (current_season + 1) % SEASONS_PER_YEAR
	if current_season == Season.SPRING:
		current_year += 1
	_randomize_weather()
	season_changed.emit(current_season)

func _randomize_weather():
	var r = randf()
	match current_season:
		Season.SPRING:
			if r < 0.5: current_weather = Weather.SUNNY
			elif r < 0.75: current_weather = Weather.CLOUDY
			else: current_weather = Weather.RAINY
		Season.SUMMER:
			if r < 0.6: current_weather = Weather.SUNNY
			elif r < 0.85: current_weather = Weather.CLOUDY
			else: current_weather = Weather.RAINY
		Season.AUTUMN:
			if r < 0.35: current_weather = Weather.SUNNY
			elif r < 0.55: current_weather = Weather.CLOUDY
			elif r < 0.85: current_weather = Weather.RAINY
			else: current_weather = Weather.SNOWY
		Season.WINTER:
			if r < 0.3: current_weather = Weather.SUNNY
			elif r < 0.5: current_weather = Weather.CLOUDY
			elif r < 0.7: current_weather = Weather.SNOWY
			else: current_weather = Weather.SUNNY

func _emit_time():
	var hour = current_tick / TICKS_PER_HOUR
	var minute = current_tick % TICKS_PER_HOUR
	time_changed.emit(hour, minute, current_day, current_season, current_year)

func get_hour() -> int:
	return current_tick / TICKS_PER_HOUR

func get_minute() -> int:
	return current_tick % TICKS_PER_HOUR

func get_time_string() -> String:
	var h = get_hour()
	var m = get_minute()
	return "%02d:%02d" % [h, m]

func get_season_name() -> String:
	return season_names[current_season]

func get_weather_name() -> String:
	return weather_names[current_weather]

func get_full_date_string() -> String:
	return "第%d年 %s季 %d日" % [current_year, get_season_name(), current_day]

func set_weather(weather: int):
	current_weather = weather
	weather_changed.emit(current_weather)

func set_time(hour: int, minute: int):
	current_tick = hour * TICKS_PER_HOUR + minute
	_emit_time()

func is_night() -> bool:
	var h = get_hour()
	return h < 6 or h >= 20

func is_daytime() -> bool:
	var h = get_hour()
	return h >= 6 and h < 20

func get_time_scale() -> float:
	# 返回时间对视觉的影响（0-1，夜晚接近0）
	var h = get_hour()
	if h >= 6 and h < 18:
		return 1.0  # 白天
	elif h >= 18 and h < 20:
		return 1.0 - (h - 18) * 0.3  # 黄昏渐变
	elif h >= 20 or h < 5:
		return 0.3  # 夜晚
	else:
		return 0.3 + (h - 5) * 0.7  # 黎明渐变
