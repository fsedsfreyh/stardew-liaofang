# CookingUI - 烹饪界面
extends CanvasLayer

var is_open: bool = false

const RECIPES = [
	{
		"id": "salad",
		"name": "蔬菜沙拉",
		"desc": "清爽的农场沙拉，恢复体力+25",
		"energy": 25,
		"ingredients": [{"id": "bluebell", "qty": 2}],
		"icon": "cake",
	},
	{
		"id": "bread",
		"name": "面包",
		"desc": "松软的手工面包，恢复体力+40",
		"energy": 40,
		"ingredients": [{"id": "wheat", "qty": 3}],
		"icon": "cake",
	},
	{
		"id": "tomato_soup",
		"name": "番茄浓汤",
		"desc": "暖胃的番茄汤，恢复体力+60",
		"energy": 60,
		"ingredients": [{"id": "tomato", "qty": 2}],
		"icon": "cake",
	},
	{
		"id": "pumpkin_pie",
		"name": "南瓜派",
		"desc": "香甜的南瓜派，恢复体力+100",
		"energy": 100,
		"ingredients": [{"id": "pumpkin", "qty": 3}, {"id": "wheat", "qty": 2}],
		"icon": "cake",
	},
	{
		"id": "sunny_omelette",
		"name": "太阳蛋卷",
		"desc": "金黄色的蛋卷，恢复体力+75",
		"energy": 75,
		"ingredients": [{"id": "egg", "qty": 2}, {"id": "tomato", "qty": 1}],
		"icon": "egg",
	},
	{
		"id": "milk_toast",
		"name": "牛奶吐司",
		"desc": "香浓牛奶吐司，恢复体力+50",
		"energy": 50,
		"ingredients": [{"id": "milk", "qty": 1}, {"id": "wheat", "qty": 1}],
		"icon": "milk",
	},
]

@onready var recipe_list = $Panel/RecipeList
@onready var cook_btn = $Panel/CookBtn
@onready var close_btn = $Panel/CloseBtn

func _ready():
	cook_btn.pressed.connect(_do_cook)
	close_btn.pressed.connect(_close)
	hide()

func open():
	is_open = true
	_refresh()
	show()

func _refresh():
	recipe_list.clear()
	for r in RECIPES:
		var has_all = true
		for ing in r["ingredients"]:
			if Inventory.get_item_count(ing["id"]) < ing["qty"]:
				has_all = false
				break
		var status = "✅" if has_all else "❌"
		var ing_text = ""
		for i in r["ingredients"]:
			var info = Inventory.get_item_info(i["id"])
			var name = info.get("name", i["id"])
			var have = Inventory.get_item_count(i["id"])
			ing_text += "%s(%d/%d) " % [name, have, i["qty"]]
		recipe_list.add_item("%s %s — %s  %s" % [status, r["name"], r["desc"], ing_text])

func _do_cook():
	var selected = recipe_list.get_selected_items()
	if selected.size() == 0:
		return
	var idx = selected[0]
	if idx < 0 or idx >= RECIPES.size():
		return
	var r = RECIPES[idx]
	
	# 检查材料
	for ing in r["ingredients"]:
		if Inventory.get_item_count(ing["id"]) < ing["qty"]:
			_notice("材料不足！")
			return
	
	# 消耗材料
	for ing in r["ingredients"]:
		Inventory.remove_item(ing["id"], ing["qty"])
	
	# 产出成品
	Inventory.add_item(r["id"], 1)
	_notice("✅ 烹饪成功！制作了 %s" % r["name"])
	_refresh()

func _notice(text: String):
	var lb = Label.new()
	lb.text = text
	lb.add_theme_color_override("font_color", Color("#ffd700"))
	lb.position = Vector2(200, 400)
	add_child(lb)
	get_tree().create_timer(2.0).timeout.connect(func():
		if is_instance_valid(lb): lb.queue_free()
	)

func _close():
	hide()
	is_open = false

func _input(event):
	if not is_open: return
	if event.is_action_pressed("player_interact"):
		_close()