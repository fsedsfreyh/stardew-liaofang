# ShopUI — 商店买卖界面 + 建筑升级
extends CanvasLayer

var shop_items: Array = []
var is_open: bool = false
var current_tab: int = 0  # 0=buy, 1=sell, 2=upgrades

var _sell_item_ids: Array = []

const UPGRADES = [
	{
		"id": "mine_ticket",
		"name": "⛏ 矿洞入场券",
		"desc": "解锁城北矿洞，可以采集矿石和战斗",
		"price": 500,
		"flag": "mine_unlocked",
		"once": true,
		"icon": "gold",
	},
	{
		"id": "house_lv2",
		"name": "🏠 房屋扩建 Lv.2",
		"desc": "扩大农场房屋，解锁厨房可以烹饪",
		"price": 2000,
		"flag": "house_level",
		"once": true,
		"icon": "cake",
	},
	{
		"id": "coop",
		"name": "🐔 鸡舍",
		"desc": "养鸡可以每天收鸡蛋！",
		"price": 1500,
		"flag": "has_coop",
		"once": true,
		"icon": "egg",
	},
	{
		"id": "barn",
		"name": "🐄 牛棚",
		"desc": "养牛每天产奶！",
		"price": 3000,
		"flag": "has_barn",
		"once": true,
		"icon": "milk",
	},
	{
		"id": "pet_dog",
		"name": "🐕 领养小狗",
		"desc": "一只忠实的狗狗会跟着你到处跑",
		"price": 200,
		"flag": "has_pet_dog",
		"once": true,
		"icon": "gold",
	},
	{
		"id": "pet_cat",
		"name": "🐈 领养小猫",
		"desc": "一只可爱的猫咪会陪你散步",
		"price": 200,
		"flag": "has_pet_cat",
		"once": true,
		"icon": "gold",
	},
]

@onready var buy_list = $BuyPanel/BuyList
@onready var sell_list = $SellPanel/SellList
@onready var upgrade_list = $UpgradePanel/UpgradeList
@onready var buy_btn = $BuyPanel/BuyButton
@onready var sell_btn = $SellPanel/SellButton
@onready var upgrade_btn = $UpgradePanel/UpgradeButton
@onready var close_btn = $CloseBtn
@onready var total_gold = $TotalGold
@onready var buy_panel = $BuyPanel
@onready var sell_panel = $SellPanel
@onready var upgrade_panel = $UpgradePanel
@onready var tab_buy = $TabBuy
@onready var tab_sell = $TabSell
@onready var tab_upgrade = $TabUpgrade

func _ready():
	close_btn.pressed.connect(_close)
	buy_btn.pressed.connect(_do_buy)
	sell_btn.pressed.connect(_do_sell)
	upgrade_btn.pressed.connect(_do_upgrade)
	tab_buy.pressed.connect(_switch_tab.bind(0))
	tab_sell.pressed.connect(_switch_tab.bind(1))
	tab_upgrade.pressed.connect(_switch_tab.bind(2))
	hide()

func open():
	shop_items = _get_shop_stock()
	_switch_tab(0)
	_refresh_lists()
	_update_gold()
	_refresh_upgrade_list()
	show()
	is_open = true

func _switch_tab(tab: int):
	current_tab = tab
	buy_panel.visible = tab == 0
	sell_panel.visible = tab == 1
	upgrade_panel.visible = tab == 2
	tab_buy.add_theme_color_override("font_color", Color.WHITE if tab == 0 else Color(0.7,0.7,0.7))
	tab_sell.add_theme_color_override("font_color", Color.WHITE if tab == 1 else Color(0.7,0.7,0.7))
	tab_upgrade.add_theme_color_override("font_color", Color.WHITE if tab == 2 else Color(0.7,0.7,0.7))

func _get_shop_stock() -> Array:
	# 按季节过滤种子
	var season_map = ["spring", "summer", "autumn", "winter"]
	var current_season = season_map[DayTime.current_season]
	
	var stock = [
		{"id": "coal", "price": 50, "name": "煤炭"},
		{"id": "milk", "price": 40, "name": "牛奶"},
		{"id": "cake", "price": 200, "name": "草莓蛋糕"},
		{"id": "diamond", "price": 500, "name": "钻石"},
	]
	
	# 按季节加作物种子
	var seed_map = {
		"spring": [
			{"id": "bluebell_seed", "price": 25, "name": "蓝风铃花种子（春）"},
		],
		"summer": [
			{"id": "bluebell_seed", "price": 25, "name": "蓝风铃花种子（春夏）"},
			{"id": "tomato_seed", "price": 15, "name": "番茄种子（夏）"},
			{"id": "sunflower_seed", "price": 30, "name": "向日葵种子（夏）"},
		],
		"autumn": [
			{"id": "wheat_seed", "price": 10, "name": "小麦种子（春秋冬）"},
			{"id": "pumpkin_seed", "price": 60, "name": "南瓜种子（秋）"},
		],
		"winter": [
			{"id": "wheat_seed", "price": 10, "name": "小麦种子（春秋冬）"},
			{"id": "cactus_seed", "price": 80, "name": "仙人掌种子（冬·温室）"},
		],
	}
	
	for s in seed_map.get(current_season, []):
		stock.append(s)
	
	return stock

func _refresh_lists():
	buy_list.clear()
	sell_list.clear()
	_sell_item_ids.clear()
	
	# 购买
	for item in shop_items:
		var icon_id = item["id"].replace("_seed", "")
		var icon = PixelArtist.generate_item_icon(icon_id, 0)
		var owned = Inventory.get_item_count(item["id"])
		var has_text = "（持有 %d）" % owned if owned > 0 else ""
		var text = "%s %s — %d G" % [item["name"], has_text, item["price"]]
		buy_list.add_item(text, icon)
	
	# 出售
	for item_id in Inventory.inventory:
		var count = Inventory.get_item_count(item_id)
		if count <= 0:
			continue
		var info = Inventory.get_item_info(item_id)
		var price = info.get("sell_price", 0)
		if price <= 0:
			continue
		var icon_type = info.get("icon_type", item_id)
		var variant = info.get("variant", 0)
		var icon = PixelArtist.generate_item_icon(icon_type, variant)
		var text = "%s x%d  —  %d G" % [info.get("name", item_id), count, price]
		sell_list.add_item(text, icon)
		_sell_item_ids.append(item_id)

func _refresh_upgrade_list():
	upgrade_list.clear()
	for u in UPGRADES:
		var bought = _is_upgrade_bought(u)
		var can_buy = not bought and Inventory.gold >= u.price
		var icon = PixelArtist.generate_item_icon(u.icon, 0)
		var price_text = "已拥有 ✅" if bought else "%d G" % u.price
		var text = "%s — %s\n  %s" % [u.name, price_text, u.desc]
		upgrade_list.add_item(text, icon)

func _is_upgrade_bought(u: Dictionary) -> bool:
	if u.id == "mine_ticket":
		return Global.stats.get("mine_unlocked", false)
	if u.id == "house_lv2":
		return HouseUpgrade.current_level >= HouseUpgrade.HouseLevel.RUSTIC
	if u.id == "coop":
		return Global.stats.get("has_coop", false)
	if u.id == "barn":
		return Global.stats.get("has_barn", false)
	if u.id == "pet_dog":
		return Global.stats.get("has_pet_dog", false)
	if u.id == "pet_cat":
		return Global.stats.get("has_pet_cat", false)
	return false

func _update_gold():
	total_gold.text = "💰 %d G" % Inventory.gold

func _do_buy():
	var selected = buy_list.get_selected_items()
	if selected.size() == 0:
		return
	var idx = selected[0]
	if idx < 0 or idx >= shop_items.size():
		return
	var item = shop_items[idx]
	if Inventory.spend_gold(item["price"]):
		Inventory.add_item(item["id"], 1)
		_refresh_lists()
		_update_gold()
	else:
		_show_notice("金币不足！")

func _do_sell():
	var selected = sell_list.get_selected_items()
	if selected.size() == 0:
		return
	var idx = selected[0]
	if idx < 0 or idx >= _sell_item_ids.size():
		return
	var item_id = _sell_item_ids[idx]
	var count = Inventory.get_item_count(item_id)
	if count <= 0:
		return
	var info = Inventory.get_item_info(item_id)
	var price = info.get("sell_price", 0)
	if price <= 0:
		return
	Inventory.remove_item(item_id, 1)
	Inventory.add_gold(price)
	_refresh_lists()
	_update_gold()
	_show_notice("售出 1 个 %s！" % info.get("name", item_id))

func _do_upgrade():
	var selected = upgrade_list.get_selected_items()
	if selected.size() == 0:
		return
	var idx = selected[0]
	if idx < 0 or idx >= UPGRADES.size():
		return
	var u = UPGRADES[idx]
	if _is_upgrade_bought(u):
		_show_notice("已经拥有！")
		return
	
	# 房屋升级用 HouseUpgrade 系统，自管理扣费
	if u.id == "house_lv2":
		if HouseUpgrade.can_upgrade():
			HouseUpgrade.do_upgrade()
			_show_notice("✅ " + HouseUpgrade.get_level_name() + "已解锁！")
		else:
			_show_notice("金币不足！需要 %d G" % HouseUpgrade.get_upgrade_cost())
		_refresh_upgrade_list()
		_update_gold()
		return
	
	if not Inventory.spend_gold(u.price):
		_show_notice("金币不足！需要 %d G" % u.price)
		return
	
	# 应用升级
	if u.id == "mine_ticket":
		Global.stats["mine_unlocked"] = true
		_show_notice("✅ 矿洞已解锁！去小镇右上角进入矿洞！")
	elif u.id == "house_lv2":
		if HouseUpgrade.do_upgrade():
			_show_notice("✅ " + HouseUpgrade.get_level_name() + "已解锁！")
		else:
			_show_notice("升级失败！")
	elif u.id == "coop":
		Global.stats["has_coop"] = true
		Inventory.add_item("egg", 3)
		_show_notice("✅ 鸡舍已造好！每天收鸡蛋！")
	elif u.id == "barn":
		Global.stats["has_barn"] = true
		Inventory.add_item("milk", 3)
		_show_notice("✅ 牛棚已造好！每天产牛奶！")
	elif u.id == "pet_dog":
		Global.stats["has_pet_dog"] = true
		_spawn_pet(0)
		_show_notice("✅ 小狗来啦！它会在农场跟着你！")
	elif u.id == "pet_cat":
		Global.stats["has_pet_cat"] = true
		_spawn_pet(1)
		_show_notice("✅ 小猫来啦！它会在农场跟着你！")
	
	_refresh_upgrade_list()
	_update_gold()

func _spawn_pet(pet_type: int):
	var farm = get_node_or_null("/root/FarmScene")
	if not farm:
		farm = get_tree().current_scene
	if not farm or not farm.has_node("Entities"):
		return
	var pet_scene = preload("res://scenes/world/pet_scene.tscn")
	if not pet_scene:
		return
	var pet = pet_scene.instantiate()
	pet.name = "Pet"
	pet.pet_type = pet_type
	if pet_type == 0:
		pet.pet_name = "小黄"
	else:
		pet.pet_name = "小花"
	var player = farm.get_node_or_null("Entities/Player")
	if player:
		pet.position = player.position + Vector2(30, 0)
		pet.set_target(player)
	else:
		pet.position = Vector2(480, 960)
	farm.get_node("Entities").add_child(pet)

func _show_notice(text: String):
	var label = Label.new()
	label.text = text
	label.add_theme_color_override("font_color", Color("#ffd700"))
	label.add_theme_font_size_override("font_size", 12)
	label.position = Vector2(150, 300)
	label.z_index = 100
	add_child(label)
	get_tree().create_timer(2.0).timeout.connect(func():
		if is_instance_valid(label): label.queue_free()
	)

func _close():
	hide()
	is_open = false
	# 恢复鼠标准
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	var npc = _find_npc("bill")
	if npc and npc.has_method("end_interaction"):
		npc.end_interaction()

func _find_npc(npc_id: String) -> Node:
	for npc in get_tree().get_nodes_in_group("npcs"):
		if npc.has_method("get_npc_id") and npc.get_npc_id() == npc_id:
			return npc
	return null

func _input(event):
	if not is_open:
		return
	if event.is_action_pressed("player_interact"):
		_close()
