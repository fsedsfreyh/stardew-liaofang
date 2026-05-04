# QuestManager — 任务/成就系统
extends Node

signal quest_updated(quest_id: String)
signal quest_completed(quest_id: String)
signal achievement_unlocked(achievement_id: String)

# 任务状态
enum QuestState { LOCKED, ACTIVE, COMPLETED }
enum QuestFlag { NONE, TALKED_TO_LIAOFANG, PLANTED_SEED, HARVESTED_CROP, WATERED_TILE, TILLED_TILE, VISITED_TOWN }

const QUESTS = {
	"welcome": {
		"name": "欢迎来到星露乡",
		"desc": "与廖芳说一次话",
		"giver": "系统",
		"unlock": [],
		"require_flag": QuestFlag.TALKED_TO_LIAOFANG,
		"reward_gold": 100,
		"reward_affection": 20,
		"dialogue_complete": [
			["🎉 任务完成", "你与廖芳聊了一次天，她对你露出了微笑。"],
			["💕 廖芳", "今天过得怎么样？我在农场等你～"],
			["🧑 系统", "你获得了 100G！与廖芳的好感度+20。"],
		],
	},
	"first_plant": {
		"name": "播种希望",
		"desc": "种下第一颗种子（左键选中种子工具，点击耕地）",
		"giver": "系统",
		"unlock": ["welcome"],
		"require_flag": QuestFlag.PLANTED_SEED,
		"reward_gold": 150,
		"reward_affection": 0,
		"dialogue_complete": [
			["🎉 任务完成", "种子已经埋进土里了，剩下的就交给时间和耐心。"],
			["🧑 系统", "获得了 150G！记得每天浇水。"],
		],
	},
	"first_harvest": {
		"name": "收获时节",
		"desc": "收获一朵成熟的蓝风铃花（等待作物成熟后点击）",
		"giver": "系统",
		"unlock": ["first_plant"],
		"require_flag": QuestFlag.HARVESTED_CROP,
		"reward_gold": 300,
		"reward_affection": 30,
		"dialogue_complete": [
			["🎉 任务完成", "你的第一朵花！蓝风铃在阳光下格外美丽。"],
			["💕 廖芳", "哇，这是你种的花吗？好漂亮！送给我好不好？"],
			["🧑 系统", "获得了 300G。廖芳好感度+30。"],
		],
	},
	"town_visit": {
		"name": "探索小镇",
		"desc": "走到农场左下角出口，前往鹈鹕小镇",
		"giver": "系统",
		"unlock": ["first_plant"],
		"require_flag": QuestFlag.VISITED_TOWN,
		"reward_gold": 200,
		"reward_affection": 0,
		"dialogue_complete": [
			["🎉 任务完成", "你来到了鹈鹕小镇。这里比农场热闹多了。"],
			["Bill 🧔", "新面孔！欢迎欢迎，有空来我店里坐坐。"],
			["🧑 系统", "获得了 200G。在镇上可以找 Bill 买东西。"],
		],
	},
}

var quest_states: Dictionary = {}  # quest_id → QuestState
var completed_quests: Array = []
var completed_flags: Array = []  # QuestFlag values

# 进度提示文本显示在 HUD 上
var current_quest_hint: String = ""
var _hint_timer: float = 0.0

func _ready():
	for qid in QUESTS:
		if QUESTS[qid]["unlock"].is_empty():
			quest_states[qid] = QuestState.ACTIVE
		else:
			quest_states[qid] = QuestState.LOCKED
	_update_hint()

func set_flag(flag: int):
	if flag in completed_flags:
		return
	completed_flags.append(flag)
	_check_quests()

func has_flag(flag: int) -> bool:
	return flag in completed_flags

func _check_quests():
	for qid in QUESTS:
		if quest_states.get(qid, QuestState.LOCKED) != QuestState.ACTIVE:
			continue
		var q = QUESTS[qid]
		if has_flag(q["require_flag"]):
			_complete_quest(qid)

func _complete_quest(qid: String):
	quest_states[qid] = QuestState.COMPLETED
	completed_quests.append(qid)
	
	var q = QUESTS[qid]
	
	# 奖励
	if q["reward_gold"] > 0:
		Inventory.add_gold(q["reward_gold"])
	if q["reward_affection"] > 0:
		var dm = get_node_or_null("/root/DialogueManager")
		if dm:
			Affection.add_affection("liaofang", q["reward_affection"])
	
	# 解锁后续任务
	for other_qid in QUESTS:
		var other = QUESTS[other_qid]
		if quest_states.get(other_qid, QuestState.LOCKED) == QuestState.LOCKED:
			var all_unlocked = true
			for need in other["unlock"]:
				if need not in completed_quests:
					all_unlocked = false
					break
			if all_unlocked:
				quest_states[other_qid] = QuestState.ACTIVE
	
	quest_completed.emit(qid)
	_update_hint()
	
	# 显示完成任务弹窗
	_show_quest_complete_popup(qid)

func get_active_quests() -> Array:
	var active = []
	for qid in QUESTS:
		if quest_states.get(qid, QuestState.LOCKED) == QuestState.ACTIVE:
			active.append(qid)
	return active

func get_quest_info(qid: String) -> Dictionary:
	return QUESTS.get(qid, {})

func get_quest_state(qid: String) -> int:
	return quest_states.get(qid, QuestState.LOCKED)

func is_quest_completed(qid: String) -> bool:
	return quest_states.get(qid, QuestState.LOCKED) == QuestState.COMPLETED

func _update_hint():
	var active = get_active_quests()
	if active.is_empty():
		current_quest_hint = ""
		return
	
	var first = active[0]
	var q = QUESTS[first]
	current_quest_hint = "📋 %s：%s" % [q["name"], q["desc"]]

func get_hint() -> String:
	return current_quest_hint

func _show_quest_complete_popup(qid: String):
	var q = QUESTS[qid]
	var dialogue = q.get("dialogue_complete", [])
	if dialogue.is_empty():
		return
	var dm = get_node_or_null("/root/DialogueManager")
	if dm:
		dm.show_dialogue(dialogue, "system", 0)
