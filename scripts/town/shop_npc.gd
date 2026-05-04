# ShopNPC — Bill 商店老板
extends CharacterBody2D

const NPC_ID = "bill"
const SHOP_STOCK = [
	{"id": "bluebell_seed", "price": 25, "name": "蓝风铃花种子"},
	{"id": "tomato_seed", "price": 15, "name": "番茄种子"},
	{"id": "wheat_seed", "price": 10, "name": "小麦种子"},
	{"id": "cake", "price": 200, "name": "草莓蛋糕"},
	{"id": "coal", "price": 50, "name": "煤炭"},
	{"id": "milk", "price": 40, "name": "牛奶"},
]

var is_talking: bool = false

func _ready():
	add_to_group("npcs")
	_sync_sprite()

func _sync_sprite():
	if has_node("Sprite2D"):
		$Sprite2D.texture = _generate_bill_sprite()

static func _generate_bill_sprite() -> ImageTexture:
	return PixelArtist.generate_npc_sprite({
		"body_color": Color("#3a7a30"),
		"body_shadow": Color("#2a6a20"),
		"hair_color": PixelArtist.PALETTE.p_s,
		"hair_highlight": PixelArtist.PALETTE.p_l,
		"skin_color": PixelArtist.PALETTE.s,
		"eye_color": PixelArtist.PALETTE.e_d,
		"has_beard": true,
		"beard_color": Color("#7a6a50"),
	})

func interact():
	if is_talking:
		return
	is_talking = true
	
	var dm = get_node_or_null("/root/DialogueManager")
	if dm:
		var dialogues = [
			["Bill 🧔", "欢迎光临我的小店！"],
			["Bill 🧔", "从种子到工具，我都有...只要你有钱！"],
		]
		# 检查矿洞是否已解锁
		var mine_unlocked = Global.stats.get("mine_unlocked", false)
		if not mine_unlocked and Inventory.gold >= 500:
			dialogues.append(["Bill 🧔", "对了！城北有个废弃矿洞，500G 可以帮你清理入口..."])
			dialogues.append(["💕提示", "如果在商店界面购买 '矿洞入场券'（500G），就可以去探险了！"])
		elif mine_unlocked:
			dialogues.append(["Bill 🧔", "矿洞最近怎么样？听说下层有钻石...💎"])
		
		dialogues.append(["Bill 🧔", "按 B 打开商店看看？"])
		dialogues.append(["💕提示", "按 B 打开商店，可以买卖物品、升级房屋和设施"])
		dm.show_dialogue(dialogues, NPC_ID)
		Global.__shop_available = true

func end_interaction():
	is_talking = false
