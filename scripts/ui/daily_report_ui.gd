# DailyReport — 农场产值日报面板
extends CanvasLayer

var is_open: bool = false
var report_data: Dictionary = {}

@onready var bg = $Bg
@onready var title = $Title
@onready var text = $ReportText
@onready var close_btn = $CloseBtn

func _ready():
	close_btn.pressed.connect(_close)
	hide()

func show_report(data: Dictionary):
	report_data = data
	var t = ""
	t += "📊 星露乡农场日报\n"
	t += "━━━━━━━━━━━━━━━━━━\n\n"
	t += "🗓️ 季节: %s  第%d天\n" % [DayTime.season_names[DayTime.current_season], DayTime.current_day]
	t += "\n"
	t += "🌾 收获作物: %d 株\n" % data.get("harvested", 0)
	t += "💧 浇水次数: %d 次\n" % data.get("watered", 0)
	t += "🪴 播种数: %d 颗\n" % data.get("planted", 0)
	t += "⛏️ 翻地数: %d 块\n\n" % data.get("tilled", 0)
	t += "💰 今日总收入: %d G\n" % data.get("gold_earned", 0)
	t += "📦 总收入囊中物: %d 件\n\n" % data.get("items_gained", 0)
	t += "♡ 与廖芳好感: %s\n" % Affection.get_heart_display("liaofang")
	t += "⛏ 矿洞探索: %d 层\n" % data.get("mine_floor", 1)
	
	t += "\n━━━━━━━━━━━━━━━━━━\n"
	t += "✨ 明天也要好好经营农场哦！\n"
	
	text.text = t
	show()
	is_open = true

func _close():
	hide()
	is_open = false

func _input(event):
	if not is_open: return
	if event.is_action_pressed("player_interact"):
		_close()
