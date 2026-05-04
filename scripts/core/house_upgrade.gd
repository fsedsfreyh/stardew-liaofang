# HouseUpgrade - 房屋升级管理器
extends Node

signal house_upgraded(level: int)

enum HouseLevel {
	TINY,       # 初始：小屋
	RUSTIC,     # 升级1：木结构
	COZY,       # 升级2：砖房
	LUXURY      # 升级3：豪宅
}

const LEVEL_NAMES = ["简陋小屋", "木屋", "砖房", "豪宅"]
const LEVEL_COSTS = [0, 2000, 8000, 25000]

var current_level: int = HouseLevel.TINY

func _ready():
	var saved = Global.farm_data.get("house_level", -1)
	if saved >= 0 and saved < LEVEL_NAMES.size():
		current_level = saved

func get_upgrade_cost() -> int:
	var next = current_level + 1
	if next >= HouseLevel.LUXURY:
		return -1
	return LEVEL_COSTS[next]

func can_upgrade() -> bool:
	var cost = get_upgrade_cost()
	return cost > 0 and Inventory.gold >= cost

func do_upgrade() -> bool:
	if not can_upgrade():
		return false
	var cost = get_upgrade_cost()
	Inventory.gold -= cost
	current_level += 1
	Global.farm_data["house_level"] = current_level
	house_upgraded.emit(current_level)
	return true

func get_level_name() -> String:
	return LEVEL_NAMES[current_level]