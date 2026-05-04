# Global - 全局数据单例
extends Node

var player_name: String = "玩家"
var player_pos: Vector2 = Vector2(480, 960)
var current_scene: String = "farm"
var farm_data: Dictionary = {}  # {"0_0": {"crop": "bluebell", "stage": 0, "watered": false}}
var __shop_available: bool = false  # 商店是否对话后可打开
var stats: Dictionary = {
	"total_steps": 0,
	"days_played": 0,
	"gold_earned": 0,
	"crops_harvested": 0,
	"crops_watered": 0,
	"crops_planted": 0,
	"tiles_tilled": 0,
	"fish_caught": 0,
	"mines_cleared": 0,
	"mine_max_floor": 1,
	"total_tax_paid": 0,
	"house_level": 1,
	"chicken_coop_level": 0,
	"barn_level": 0,
	"last_cost_day": 0,
	"has_coop": false,
	"has_barn": false,
}

# 统计快捷访问（防止字典键名拼错）
var total_tiles_tilled: int:
	get: return stats.get("tiles_tilled", 0)
	set(v): stats["tiles_tilled"] = v
var total_crops_watered: int:
	get: return stats.get("crops_watered", 0)
	set(v): stats["crops_watered"] = v
var total_crops_harvested: int:
	get: return stats.get("crops_harvested", 0)
	set(v): stats["crops_harvested"] = v

# 初始化所有 Autoload
func _ready():
	_setup_input_map()
	print("《星露乡物语》已启动 🌻")

func _setup_input_map():
	# 确保所有按键映射已注册（防止第一次运行时没有默认键）
	var actions = {
		"player_left": [KEY_A, KEY_LEFT],
		"player_right": [KEY_D, KEY_RIGHT],
		"player_up": [KEY_W, KEY_UP],
		"player_down": [KEY_S, KEY_DOWN],
		"player_interact": [KEY_E, KEY_SPACE],
		"player_use_item": [KEY_F],
		"player_achievement": [KEY_V],
	}
	for action_name in actions:
		if not InputMap.has_action(action_name):
			InputMap.add_action(action_name)
		for keycode in actions[action_name]:
			var has_key = false
			for existing in InputMap.action_get_events(action_name):
				if existing is InputEventKey and existing.keycode == keycode:
					has_key = true
					break
			if not has_key:
				var ev = InputEventKey.new()
				ev.keycode = keycode
				InputMap.action_add_event(action_name, ev)

# ============ 每日运营成本系统 ============

# 计算每日运营成本，返回 {tax, electricity, maintenance, total}
func _calculate_daily_costs() -> Dictionary:
	var house_lv = stats.get("house_level", 1)
	var coop_lv = stats.get("chicken_coop_level", 0)
	var barn_lv = stats.get("barn_level", 0)

	var tax = 10 + house_lv * 5
	var electricity = 5 + coop_lv * 3
	var maintenance = 3 + barn_lv * 2
	var total = tax + electricity + maintenance

	return {"tax": tax, "electricity": electricity, "maintenance": maintenance, "total": total}

# 执行每日扣款，返回是否足够支付
func _apply_daily_costs() -> bool:
	var costs = _calculate_daily_costs()
	var total = costs["total"]

	if Inventory.gold >= total:
		Inventory.spend_gold(total)
		stats["total_tax_paid"] = stats.get("total_tax_paid", 0) + total
		stats["last_cost_day"] = DayTime.current_day
		return true
	else:
		# 金币不足，扣到0为止
		var paid = min(Inventory.gold, total)
		Inventory.spend_gold(paid)
		stats["total_tax_paid"] = stats.get("total_tax_paid", 0) + paid
		stats["last_cost_day"] = DayTime.current_day
		return false
