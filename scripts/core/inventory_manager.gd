# InventoryManager - 背包/物品管理
extends Node

signal inventory_changed()
signal item_added(item_id: String, count: int)
signal item_removed(item_id: String, count: int)

# 物品数据库
const ITEM_DB = {
	# 作物
	"bluebell": {"name": "蓝风铃花", "type": "crop", "description": "廖芳最爱的花，淡蓝色的风铃状花朵", "sell_price": 80, "edible": false, "icon_type": "bluebell"},
	"tomato": {"name": "番茄", "type": "crop", "description": "红彤彤的番茄，口感酸甜", "sell_price": 35, "edible": true, "heal": 20, "icon_type": "tomato"},
	"wheat": {"name": "小麦", "type": "crop", "description": "金黄色的麦穗", "sell_price": 25, "edible": false, "icon_type": "wheat"},
	"sunflower": {"name": "向日葵", "type": "crop", "description": "永远朝向太阳的向日葵", "sell_price": 50, "edible": false, "icon_type": "flower", "variant": 1},
	"pumpkin": {"name": "南瓜", "type": "crop", "description": "金色的大南瓜，可以做南瓜灯", "sell_price": 80, "edible": true, "heal": 25, "icon_type": "wheat"},
	"cactus": {"name": "仙人掌果", "type": "crop", "description": "冬季温室中结出的红果实", "sell_price": 100, "edible": true, "heal": 20, "icon_type": "diamond"},
	
	# 花卉
	"flower_pink": {"name": "粉玫瑰", "type": "flower", "description": "娇艳的粉色玫瑰", "sell_price": 40, "edible": false, "icon_type": "flower", "variant": 0},
	"flower_yellow": {"name": "向日葵", "type": "flower", "description": "永远朝向阳光", "sell_price": 35, "edible": false, "icon_type": "flower", "variant": 1},
	"flower_blue": {"name": "蓝玫瑰", "type": "flower", "description": "罕见的蓝色玫瑰", "sell_price": 60, "edible": false, "icon_type": "flower", "variant": 2},
	
	# 动物产品
	"milk": {"name": "牛奶", "type": "animal", "description": "新鲜的牛奶", "sell_price": 30, "edible": true, "heal": 15, "icon_type": "milk"},
	"egg": {"name": "鸡蛋", "type": "animal", "description": "农场散养鸡蛋", "sell_price": 25, "edible": true, "heal": 10, "icon_type": "egg"},
	
	# 料理
	"cake": {"name": "草莓蛋糕", "type": "food", "description": "香甜松软的草莓蛋糕", "sell_price": 150, "edible": true, "heal": 60, "icon_type": "cake"},
	"salad": {"name": "蔬菜沙拉", "type": "food", "description": "清爽的农场沙拉，恢复体力+25", "sell_price": 50, "edible": true, "heal": 25, "icon_type": "cake"},
	"bread": {"name": "面包", "type": "food", "description": "松软的手工面包，恢复体力+40", "sell_price": 60, "edible": true, "heal": 40, "icon_type": "wheat"},
	"tomato_soup": {"name": "番茄浓汤", "type": "food", "description": "暖胃的番茄汤，恢复体力+60", "sell_price": 80, "edible": true, "heal": 60, "icon_type": "diamond"},
	"pumpkin_pie": {"name": "南瓜派", "type": "food", "description": "香甜的南瓜派，恢复体力+100", "sell_price": 200, "edible": true, "heal": 100, "icon_type": "wheat"},
	"sunny_omelette": {"name": "太阳蛋卷", "type": "food", "description": "金黄色的蛋卷，恢复体力+75", "sell_price": 120, "edible": true, "heal": 75, "icon_type": "egg"},
	"milk_toast": {"name": "牛奶吐司", "type": "food", "description": "香浓牛奶吐司，恢复体力+50", "sell_price": 70, "edible": true, "heal": 50, "icon_type": "milk"},
	
	# 矿物
	"diamond": {"name": "钻石", "type": "mineral", "description": "纯净璀璨的钻石，价值不菲", "sell_price": 300, "edible": false, "icon_type": "diamond"},
	"gold_ore": {"name": "金矿", "type": "mineral", "description": "未经冶炼的金矿石", "sell_price": 100, "edible": false, "icon_type": "gold"},
	"coal": {"name": "煤炭", "type": "mineral", "description": "普通但有用的燃料", "sell_price": 15, "edible": false, "icon_type": "coal"},
	
	# 鱼
	"fish_common": {"name": "普通鱼", "type": "fish", "description": "一条普通的鱼", "sell_price": 30, "edible": true, "heal": 15, "icon_type": "fish"},
	
	# 野生采集
	"mushroom": {"name": "蘑菇", "type": "forage", "description": "森林里采的野蘑菇，可以吃", "sell_price": 20, "edible": true, "heal": 12, "icon_type": "wheat"},
	
	# 制造品
	"iron_ingot": {"name": "铁锭", "type": "material", "description": "冶炼好的铁锭", "sell_price": 80, "edible": false, "icon_type": "diamond"},
	"scarecrow": {"name": "稻草人", "type": "tool", "description": "放在农场上驱赶乌鸦", "sell_price": 50, "edible": false, "icon_type": "bluebell"},
	"fertilizer": {"name": "肥料", "type": "tool", "description": "缩短作物生长周期", "sell_price": 10, "edible": false, "icon_type": "wheat"},
	"bacon_egg_burger": {"name": "培根蛋堡", "type": "food", "description": "培根煎蛋汉堡，恢复 40 体力！", "sell_price": 100, "edible": true, "heal": 40, "icon_type": "cake"},
	"mushroom_soup": {"name": "蘑菇浓汤", "type": "food", "description": "鲜美的野蘑菇浓汤，恢复 25 体力", "sell_price": 60, "edible": true, "heal": 25, "icon_type": "wheat"},
	"grilled_fish": {"name": "烤鱼", "type": "food", "description": "炭火烤鱼，外酥里嫩，恢复 35 体力", "sell_price": 80, "edible": true, "heal": 35, "icon_type": "fish"},
	"gold_ingot": {"name": "金锭", "type": "material", "description": "冶炼好的金锭", "sell_price": 200, "edible": false, "icon_type": "gold"},
	"gift_box": {"name": "廖芳的礼物盒", "type": "gift", "description": "精致礼盒，送给廖芳好感+3", "sell_price": 0, "edible": false, "icon_type": "cake", "affection": 3},
	
	# 武器
	"sword_basic": {"name": "铁剑", "type": "weapon", "description": "普通的铁质长剑，攻击+5", "sell_price": 100, "edible": false, "icon_type": "sword", "attack": 5},
	
	# 种子
	"bluebell_seed": {"name": "蓝风铃花种子", "type": "seed", "description": "种出美丽的蓝风铃花（春/夏）", "sell_price": 20, "edible": false, "icon_type": "bluebell"},
	"tomato_seed": {"name": "番茄种子", "type": "seed", "description": "种出新鲜番茄（夏）", "sell_price": 10, "edible": false, "icon_type": "tomato"},
	"wheat_seed": {"name": "小麦种子", "type": "seed", "description": "种出金灿灿的小麦（春/秋/冬）", "sell_price": 5, "edible": false, "icon_type": "wheat"},
	"sunflower_seed": {"name": "向日葵种子", "type": "seed", "description": "种出向阳的向日葵（夏）", "sell_price": 20, "edible": false, "icon_type": "wheat"},
	"pumpkin_seed": {"name": "南瓜种子", "type": "seed", "description": "种出大南瓜（秋）", "sell_price": 40, "edible": false, "icon_type": "wheat"},
	"cactus_seed": {"name": "仙人掌种子", "type": "seed", "description": "种出仙人掌果（冬·温室）", "sell_price": 50, "edible": false, "icon_type": "diamond"},

	# 节日物品
	"flower_crown": {"name": "花冠", "type": "decor", "description": "春之花节的冠军头饰，绚丽多彩", "sell_price": 0, "edible": false, "icon_type": "flower"},
	"pearl": {"name": "珍珠", "type": "mineral", "description": "夏之海节的战利品，海中珍宝", "sell_price": 150, "edible": false, "icon_type": "diamond"},
	"star_shard": {"name": "星之碎片", "type": "mineral", "description": "冬之星节的馈赠，闪烁着神秘光芒", "sell_price": 300, "edible": false, "icon_type": "diamond"},

}

var inventory: Dictionary = {}  # {item_id: count}
var gold: int = 500

func add_item(item_id: String, count: int = 1):
	if not inventory.has(item_id):
		inventory[item_id] = 0
	inventory[item_id] += count
	item_added.emit(item_id, count)
	inventory_changed.emit()

func remove_item(item_id: String, count: int = 1) -> bool:
	if inventory.get(item_id, 0) >= count:
		inventory[item_id] -= count
		if inventory[item_id] <= 0:
			inventory.erase(item_id)
		item_removed.emit(item_id, count)
		inventory_changed.emit()
		return true
	return false

func get_item_count(item_id: String) -> int:
	return inventory.get(item_id, 0)

func has_item(item_id: String, count: int = 1) -> bool:
	return inventory.get(item_id, 0) >= count

func get_item_info(item_id: String) -> Dictionary:
	return ITEM_DB.get(item_id, {})

func add_gold(amount: int):
	gold += amount

func spend_gold(amount: int) -> bool:
	if gold >= amount:
		gold -= amount
		return true
	return false

func get_sorted_inventory() -> Array:
	var items = []
	for item_id in inventory:
		var info = ITEM_DB[item_id]
		items.append({
			"id": item_id,
			"name": info.name,
			"type": info.type,
			"count": inventory[item_id],
			"info": info
		})
	items.sort_custom(func(a, b): return a.type < b.type)
	return items

func save_data() -> Dictionary:
	return {
		"inventory": inventory.duplicate(),
		"gold": gold
	}

func load_data(data: Dictionary):
	inventory = data.get("inventory", {})
	gold = data.get("gold", 500)
	inventory_changed.emit()