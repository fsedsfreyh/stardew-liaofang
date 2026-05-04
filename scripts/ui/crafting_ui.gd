# CraftingUI — 合成制作面板
extends Control

@onready var recipe_list: VBoxContainer = $Panel/RecipeContainer
@onready var detail_name: Label = $Panel/DetailPanel/RecipeName
@onready var detail_desc: Label = $Panel/DetailPanel/RecipeDesc
@onready var detail_mats: Label = $Panel/DetailPanel/Materials
@onready var detail_btn: Button = $Panel/DetailPanel/CraftBtn
@onready var close_btn: Button = $Panel/CloseBtn

var selected_recipe: Dictionary = {}
var is_open: bool = false

const RECIPES = [
	# 冶炼
	{
		"name": "铁锭",
		"id": "iron_ingot",
		"description": "基础金属材料，武器升级和建筑必备",
		"materials": {"coal": 3, "gold_ore": 2},
		"result": "iron_ingot",
		"result_count": 1,
		"icon_type": "diamond",
		"category": "冶炼",
	},
	{
		"name": "金锭",
		"id": "gold_ingot",
		"description": "珍贵金属，高级装备和建筑所需",
		"materials": {"diamond": 1, "gold_ore": 3},
		"result": "gold_ingot",
		"result_count": 1,
		"icon_type": "gold",
		"category": "冶炼",
	},
	# 工具
	{
		"name": "稻草人",
		"id": "scarecrow",
		"description": "放在农场上驱赶乌鸦，保护作物",
		"materials": {"coal": 2, "bluebell": 3},
		"result": "scarecrow",
		"result_count": 1,
		"icon_type": "bluebell",
		"category": "工具",
	},
	{
		"name": "肥料",
		"id": "fertilizer",
		"description": "促进作物生长，缩短25%生长周期",
		"materials": {"wheat": 2, "tomato": 1},
		"result": "fertilizer",
		"result_count": 5,
		"icon_type": "wheat",
		"category": "工具",
	},
	# 礼物
	{
		"name": "廖芳的礼物盒",
		"id": "gift_box",
		"description": "送给廖芳的精致礼物！好感+3❤",
		"materials": {"bluebell": 3, "cake": 1, "diamond": 1},
		"result": "gift_box",
		"result_count": 1,
		"icon_type": "cake",
		"category": "礼物",
	},
	# 烹饪（需要房屋Lv2或以上解锁）
	{
		"name": "培根蛋堡",
		"id": "bacon_egg_burger",
		"description": "恢复 40 体力！（需要厨房）",
		"materials": {"egg": 2, "milk": 1},
		"result": "bacon_egg_burger",
		"result_count": 1,
		"icon_type": "cake",
		"category": "烹饪",
		"require_kitchen": true,
	},
	{
		"name": "草莓蛋糕",
		"id": "cake",
		"description": "恢复 60 体力！（需要厨房）",
		"materials": {"egg": 2, "milk": 2, "wheat": 3},
		"result": "cake",
		"result_count": 1,
		"icon_type": "cake",
		"category": "烹饪",
		"require_kitchen": true,
	},
	{
		"name": "蘑菇浓汤",
		"id": "mushroom_soup",
		"description": "恢复 25 体力！（需要厨房）",
		"materials": {"mushroom": 3, "milk": 1},
		"result": "mushroom_soup",
		"result_count": 1,
		"icon_type": "wheat",
		"category": "烹饪",
		"require_kitchen": true,
	},
	{
		"name": "烤鱼",
		"id": "grilled_fish",
		"description": "恢复 35 体力！（需要厨房）",
		"materials": {"fish_common": 2, "coal": 1},
		"result": "grilled_fish",
		"result_count": 1,
		"icon_type": "fish",
		"category": "烹饪",
		"require_kitchen": true,
	},
]

func _ready():
	close_btn.pressed.connect(_close)
	detail_btn.pressed.connect(_craft_selected)
	_refresh_recipes()
	hide()

func open():
	selected_recipe = {}
	_refresh_recipes()
	_update_detail({})
	show()
	is_open = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func _close():
	hide()
	is_open = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _refresh_recipes():
	for child in recipe_list.get_children():
		child.queue_free()
	
	# 分类标题
	var categories = ["冶炼", "工具", "礼物", "烹饪"]
	var has_kitchen = Global.stats.get("house_level", 0) >= 2
	
	for cat in categories:
		var cat_recipes = []
		for r in RECIPES:
			if r.category != cat: continue
			if r.get("require_kitchen", false) and not has_kitchen: continue
			cat_recipes.append(r)
		if cat_recipes.is_empty(): continue
		
		# 分类标签
		var cat_label = Label.new()
		cat_label.text = "── %s ──" % cat
		cat_label.add_theme_color_override("font_color", Color("#ffd700"))
		cat_label.add_theme_font_size_override("font_size", 10)
		cat_label.size = Vector2(0, 20)
		recipe_list.add_child(cat_label)
		
		for r in cat_recipes:
			var btn = Button.new()
			btn.name = "Recipe_" + r.id
			btn.size = Vector2(0, 28)
			btn.text = r.name
			btn.add_theme_font_size_override("font_size", 12)
			btn.tooltip_text = _get_material_string(r)
			
			# 用颜色标记是否可制作
			if _can_craft(r):
				btn.add_theme_color_override("font_color", Color("#a0e0a0"))
			else:
				btn.add_theme_color_override("font_color", Color("#808080"))
			
			btn.pressed.connect(_select_recipe.bind(r))
			recipe_list.add_child(btn)

func _select_recipe(recipe: Dictionary):
	selected_recipe = recipe
	_update_detail(recipe)

func _update_detail(recipe: Dictionary):
	if recipe.is_empty():
		detail_name.text = "选择一个配方"
		detail_desc.text = ""
		detail_mats.text = ""
		detail_btn.disabled = true
		return
	
	detail_name.text = "📋 " + recipe.name
	detail_desc.text = recipe.description
	detail_mats.text = "材料需求：\n" + _get_material_string(recipe)
	detail_btn.disabled = not _can_craft(recipe)
	if not detail_btn.disabled:
		detail_btn.text = "制作 x%d" % recipe.result_count
	else:
		detail_btn.text = "材料不足"

func _get_material_string(recipe: Dictionary) -> String:
	var parts = []
	for mat_id in recipe.materials:
		var cnt = recipe.materials[mat_id]
		var info = Inventory.get_item_info(mat_id)
		var name = info.get("name", mat_id)
		var owned = Inventory.get_item_count(mat_id)
		parts.append("%s %d/%d" % [name, owned, cnt])
	return "\n".join(parts)

func _can_craft(recipe: Dictionary) -> bool:
	for mat_id in recipe.materials:
		var cnt = recipe.materials[mat_id]
		if not Inventory.has_item(mat_id, cnt):
			return false
	# 消耗体力
	if recipe.result_count > 0:
		return true
	return true

func _craft_selected():
	if selected_recipe.is_empty(): return
	var r = selected_recipe
	
	# 扣材料
	for mat_id in r.materials:
		var cnt = r.materials[mat_id]
		if not Inventory.has_item(mat_id, cnt):
			return
	for mat_id in r.materials:
		var cnt = r.materials[mat_id]
		Inventory.remove_item(mat_id, cnt)
	
	# 给产物（如果产物不在 ITEM_DB，动态注册）
	if not Inventory.get_item_info(r.result).is_empty():
		Inventory.add_item(r.result, r.result_count)
	else:
		# 产物是可食用食物
		Inventory.add_item(r.result, r.result_count)
	
	_refresh_recipes()
	selected_recipe = {}
	_update_detail({})
	
	# 提示
	var hint = get_node_or_null("CraftHint")
	if not hint:
		hint = Label.new()
		hint.name = "CraftHint"
		hint.add_theme_color_override("font_color", Color("#ffd700"))
		hint.add_theme_font_size_override("font_size", 14)
		hint.position = Vector2(180, 300)
		hint.z_index = 50
		add_child(hint)
	hint.text = "✅ 制作成功！获得 %s x%d" % [r.name, r.result_count]
	get_tree().create_timer(1.5).timeout.connect(func():
		if is_instance_valid(hint): hint.queue_free()
	)

# 键鼠输入
func _input(event):
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_C and not is_open:
			open()
		elif event.keycode == KEY_ESCAPE and is_open:
			_close()
