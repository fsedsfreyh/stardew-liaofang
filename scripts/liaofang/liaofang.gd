# 廖芳 - 专属NPC脚本（含礼物赠送系统）
extends CharacterBody2D

const NPC_ID = "liaofang"
const SPEED = 30.0

enum State { IDLE, WALKING, INTERACTING }

var state: int = State.IDLE
var walk_target: Vector2 = Vector2.ZERO
var direction: String = "down"
var anim_frame: int = 0
var anim_counter: int = 0

var walk_timer: float = 0.0
var wait_timer: float = 0.0
const MIN_WALK_TIME = 1.0
const MAX_WALK_TIME = 3.0
const MIN_WAIT_TIME = 2.0
const MAX_WAIT_TIME = 5.0

const FARM_BOUNDS = Rect2(Vector2(200, 200), Vector2(400, 300))

# 🎁 礼物系统
const LOVED_GIFTS = {
	"bluebell": {"name": "蓝风铃花", "affection": 80, "reply": "这是蓝风铃花！你怎么知道我最喜欢这个…好开心！❤️❤️❤️"},
	"diamond": {"name": "钻石", "affection": 60, "reply": "这么贵重的礼物…你太用心了 ✨"},
	"cake": {"name": "草莓蛋糕", "affection": 50, "reply": "哇，是我最喜欢的草莓蛋糕！你怎么知道的！🍰💕"},
	"gift_box": {"name": "廖芳的礼物盒", "affection": 80, "reply": "这、这是给我的礼物盒吗？！我太开心了！里面是你亲手放的吗？💝💝💝"},
}
const LIKED_GIFTS = {
	"bluebell_seed": {"name": "蓝风铃花种子", "affection": 40, "reply": "种子！我们一起种吧～🌱"},
	"flower_pink": {"name": "粉玫瑰", "affection": 30, "reply": "好漂亮的花～谢谢你 🌸"},
	"flower_yellow": {"name": "向日葵", "affection": 25, "reply": "好阳光的花，和你一样 🌻"},
	"flower_blue": {"name": "蓝玫瑰", "affection": 30, "reply": "蓝色的玫瑰！好少见啊～💙"},
	"milk": {"name": "牛奶", "affection": 15, "reply": "好新鲜的牛奶，农场产的果然不一样 🥛"},
	"egg": {"name": "鸡蛋", "affection": 15, "reply": "圆滚滚的鸡蛋，好可爱～"},
	"tomato": {"name": "番茄", "affection": 15, "reply": "番茄？嗯…你种的肯定好吃 🍅"},
	"wheat": {"name": "小麦", "affection": 10, "reply": "金灿灿的麦穗，闻起来有阳光的味道～"},
	"gold_ore": {"name": "金矿", "affection": 20, "reply": "金光闪闪的…留着做首饰不错！"},
	"fish_common": {"name": "普通鱼", "affection": 10, "reply": "哇你还会钓鱼呀！好厉害～🐟"},
	"coal": {"name": "煤炭", "affection": 5, "reply": "炭火…让我想起我们一起烤火的夜晚 🔥"},
}
const BASE_AFFECTION = 5

func _ready():
	add_to_group("npcs")
	_pick_new_target()
	_update_sprite()
	if not Affection.affections.has(NPC_ID):
		Affection.affections[NPC_ID] = 0

func get_npc_id() -> String:
	return NPC_ID

func _physics_process(delta):
	match state:
		State.IDLE:
			wait_timer -= delta
			if wait_timer <= 0:
				_pick_new_target()
		State.WALKING:
			walk_timer -= delta
			var dir_vec = (walk_target - global_position)
			if dir_vec.length() > 5:
				velocity = dir_vec.normalized() * SPEED
				move_and_slide()
				if abs(velocity.x) > abs(velocity.y):
					direction = "left" if velocity.x < 0 else "right"
				else:
					direction = "up" if velocity.y < 0 else "down"
				anim_counter += 1
				if anim_counter > 10:
					anim_counter = 0
					anim_frame = (anim_frame + 1) % 4
			else:
				state = State.IDLE
				wait_timer = randf_range(MIN_WAIT_TIME, MAX_WAIT_TIME)
				anim_frame = 0
			if walk_timer <= 0:
				state = State.IDLE
				wait_timer = randf_range(MIN_WAIT_TIME, MAX_WAIT_TIME)
				anim_frame = 0
			_update_sprite()

func _pick_new_target():
	var x = randf_range(FARM_BOUNDS.position.x, FARM_BOUNDS.position.x + FARM_BOUNDS.size.x)
	var y = randf_range(FARM_BOUNDS.position.y, FARM_BOUNDS.position.y + FARM_BOUNDS.size.y)
	walk_target = Vector2(x, y)
	walk_timer = randf_range(MIN_WALK_TIME, MAX_WALK_TIME)
	state = State.WALKING
	_update_sprite()

func _update_sprite():
	if not PixelArtist or not PixelArtist.has_method("generate_liaofang_sprite"):
		return
	$Sprite2D.texture = PixelArtist.generate_liaofang_sprite(direction, anim_frame)

func interact():
	if state == State.INTERACTING:
		return
	state = State.INTERACTING
	var gift = _find_gift_in_inventory()
	if gift.id != "":
		_display_gift_dialogue(gift)
	else:
		_display_dialogue()

static func _find_gift_in_inventory() -> Dictionary:
	for gift_id in LOVED_GIFTS:
		if Inventory.has_item(gift_id):
			return {"id": gift_id, "category": "loved", "data": LOVED_GIFTS[gift_id]}
	for gift_id in LIKED_GIFTS:
		if Inventory.has_item(gift_id):
			return {"id": gift_id, "category": "liked", "data": LIKED_GIFTS[gift_id]}
	for item_id in Inventory.inventory.keys():
		var info = Inventory.get_item_info(item_id)
		if info.get("type", "") in ["crop", "flower", "food", "mineral", "fish"]:
			if not LOVED_GIFTS.has(item_id) and not LIKED_GIFTS.has(item_id):
				return {"id": item_id, "category": "neutral", "data": {
					"name": info.get("name", item_id), "affection": 5,
					"reply": "这是什么呀～嗯…虽然不是最想要的，但你的心意我收到啦！"
				}}
	return {"id": "", "category": "none", "data": {}}

func _display_gift_dialogue(gift: Dictionary):
	var gift_name = gift.data.name
	var gift_affection = gift.data.affection
	Inventory.remove_item(gift.id, 1)
	var dialogues = [
		["💕 廖芳", "咦，你手里拿着什么？是给我的吗？😊"],
		["💕 廖芳", "哇，是 " + gift_name + ("！❤️" if gift.category == "loved" else "！")],
		["💕 廖芳", gift.data.reply],
		["💕 廖芳", "❤️ 好感度 +" + str(gift_affection) + " ❤️"],
	]
	var dm = get_node("/root/DialogueManager")
	dm.show_dialogue(dialogues, NPC_ID, gift_affection)
	
	# 任务：第一次对话（如果还没触发）
	if Engine.has_singleton("QuestManager"):
		get_node("/root/QuestManager").set_flag(0)

func _display_dialogue():
	var hour = DayTime.get_hour()
	var heart_level = Affection.get_heart_level(NPC_ID)
	
	# 检查好感度事件链
	var event_dialogue = _check_heart_events(heart_level)
	if event_dialogue.size() > 0:
		var dm = get_node("/root/DialogueManager")
		# 奖励物品在 _give_heart_event_rewards 中发放
		_give_heart_event_rewards(heart_level)
		dm.show_dialogue(event_dialogue, NPC_ID, 10)
		return
	
	var dialogues = []
	var intimacy = ""
	if heart_level >= 8: intimacy = "（她看着你的眼神特别温柔）"
	elif heart_level >= 4: intimacy = "（她笑得很开心）"
	elif heart_level >= 2: intimacy = "（她的语气很亲切）"
	
	if hour >= 6 and hour < 9:
		dialogues = [
			["💕 廖芳", "早上好呀～你来得真早！"],
			["💕 廖芳", "我刚给花浇了水，你看，蓝风铃花开得可好了 🌸"],
			["💕 廖芳", "…今天要不要一起在农场走走？" + intimacy],
		]
	elif hour >= 9 and hour < 12:
		dialogues = [
			["💕 廖芳", "阳光真好呀，我想去花海写生～"],
			["💕 廖芳", "你要一起来吗？我可以画你！🎨" + intimacy],
		]
	elif hour >= 12 and hour < 14:
		dialogues = [
			["💕 廖芳", "午饭时间到了～你吃了没？"],
			["💕 廖芳", "我带了便当，分你一半吧！🍱" + intimacy],
		]
	elif hour >= 14 and hour < 18:
		dialogues = [
			["💕 廖芳", "下午的农场好安静，风吹过来都是花香～"],
			["💕 廖芳", "你觉得这里还缺点什么？我想一起布置得更好看" + intimacy],
		]
	elif hour >= 18 and hour < 20:
		dialogues = [
			["💕 廖芳", "夕阳好美…和你一起看就更好看了 🌇"],
			["💕 廖芳", "今天开心吗？我可是超级开心的哦！" + intimacy],
		]
	elif hour >= 20 or hour < 6:
		dialogues = [
			["💕 廖芳", "天都黑了…你要赶紧休息哦"],
			["💕 廖芳", "明天见～做个好梦，梦里也要有我哦 🌙💕" + intimacy],
		]
	var dm = get_node("/root/DialogueManager")
	dm.show_dialogue(dialogues, NPC_ID, BASE_AFFECTION)
	
	# 任务：第一次对话
	if Engine.has_singleton("QuestManager"):
		get_node("/root/QuestManager").set_flag(0)

func _on_interact_area_area_entered(area):
	var p = area.get_parent()
	if p and p.is_in_group("player") and has_node("InteractHint"):
		$InteractHint.visible = true

func _on_interact_area_area_exited(area):
	var p = area.get_parent()
	if p and p.is_in_group("player") and has_node("InteractHint"):
		$InteractHint.visible = false

func end_interaction():
	state = State.IDLE
	wait_timer = randf_range(MIN_WAIT_TIME, MAX_WAIT_TIME)

# ══════════════════════════════
# ❤️ 好感度事件链
# ══════════════════════════════
func _check_heart_events(heart: int) -> Array:
	if AudioManager: AudioManager.play_sfx(AudioManager.Sfx.HEART, global_position)
	# 每个级别只触发一次
	var ev = Affection.triggered_events.get(NPC_ID, [])
	
	# 2❤ — 相识
	if heart >= 2 and not ev.has(2):
		Affection.triggered_events[NPC_ID].append(2)
		QuestManager.set_flag(2)
		return [
			["💕 廖芳", "诶，你最近总是来找我呢……"],
			["💕 廖芳", "其实我每天最期待的就是看到你啦！"],
			["💕 廖芳", "我们算…朋友了吧？"],
			["💕 廖芳", "太好了！嘿嘿，那以后多来陪我哦～"],
			["🎁 奖励", "好感事件「相识」达成！获得 蓝风铃花种子 x3！"],
		]
	# 4❤ — 陪伴
	if heart >= 4 and not ev.has(4):
		Affection.triggered_events[NPC_ID].append(4)
		QuestManager.set_flag(4)
		return [
			["💕 廖芳", "今天工作累了吧？我给你泡了杯茶 ☕"],
			["💕 廖芳", "虽然只是农场里采的薄荷叶，但我觉得很香！"],
			["💕 廖芳", "你知道吗，我以前一个人在城里的时候，从来没想过会有这样的生活。"],
			["💕 廖芳", "……但和你一起在农场，感觉每一天都好充实。"],
			["🎁 奖励", "好感事件「陪伴」达成！获得 草莓蛋糕 x1！"],
		]
	# 6❤ — 信任
	if heart >= 6 and not ev.has(6):
		Affection.triggered_events[NPC_ID].append(6)
		QuestManager.set_flag(6)
		return [
			["💕 廖芳", "最近我一直在想一件事……"],
			["💕 廖芳", "我们认识也有一阵子了，我总觉得你特别可靠。"],
			["💕 廖芳", "其实…我小的时候，最向往的就是这种田园生活。"],
			["💕 廖芳", "而你是唯一一个陪我实现这个梦想的人。"],
			["💕 廖芳", "所以…谢谢。真的。"],
			["🎁 奖励", "好感事件「信任」达成！获得 钻石 x1！"],
		]
	# 8❤ — 约定
	if heart >= 8 and not ev.has(8):
		Affection.triggered_events[NPC_ID].append(8)
		QuestManager.set_flag(8)
		return [
			["💕 廖芳", "你…你来一下，我有话跟你说。"],
			["💕 廖芳", "最近我晚上总是睡不着。"],
			["💕 廖芳", "不是因为别的，是因为……我一直在想你的事。"],
			["💕 廖芳", "你能不能答应我，不管发生什么事，都不要离开这个农场？"],
			["💕 廖芳", "因为如果你走了，这里就不再是「我们的」家了……"],
			["💕 廖芳", "所以约定好了哦！拉钩！🤝"],
			["🎁 奖励", "好感事件「约定」达成！获得 金锭 x2！"],
		]
	# 10❤ — 告白（保留，条件最难）
	if heart >= 10 and not ev.has(10):
		Affection.triggered_events[NPC_ID].append(10)
		QuestManager.set_flag(10)
		return [
			["💕 廖芳", "……你来了。"],
			["💕 廖芳", "我一直想告诉你一件事，在我遇见你之前，我从没觉得生活有这么多颜色。"],
			["💕 廖芳", "无论是清晨的第一缕阳光，还是傍晚的夕阳，都因为有你分享而变得更美。"],
			["💕 廖芳", "所以，我想说的是……"],
			["💕 廖芳", "我喜欢你。从心底里喜欢你。"],
			["💕 廖芳", "你愿意和我一直一起，在这个小镇，经营我们的农场，到很老很老吗？"],
			["🎁 奖励", "好感事件「告白」达成！获得 廖芳的礼物盒 x3！"],
		]
	return []

func _give_heart_event_rewards(heart: int):
	match heart:
		2:
			Inventory.add_item("bluebell_seed", 3)
			QuestManager.set_flag(2)
		4:
			Inventory.add_item("cake", 1)
			QuestManager.set_flag(4)
		6:
			Inventory.add_item("diamond", 1)
			QuestManager.set_flag(6)
		8:
			Inventory.add_item("gold_ingot", 2)
			QuestManager.set_flag(8)
		10:
			Inventory.add_item("gift_box", 3)
			QuestManager.set_flag(10)
