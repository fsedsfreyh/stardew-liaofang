# AffectionSystem 好感度全局系统
extends Node

signal affection_changed(npc_id: String, new_affection: int, heart_level: int)
signal heart_event_unlocked(npc_id: String, heart_level: int)

const MAX_AFFECTION = 1000   # 10❤ = 1000点
const HEART_PER_LEVEL = 100  # 每❤ = 100点

# 所有NPC好感度 {npc_id: affection_points}
var affections: Dictionary = {}

# 已触发的好感事件 {npc_id: [2, 4, 6, 8, 10]}
var triggered_events: Dictionary = {}

func _ready():
	# 初始化所有NPC
	var npc_list = ["player", "liaofang", "tom", "lily", "mary", "bob", "bill",
					"jack", "erin", "merlin", "karen", "anna", "david",
					"xiaoji", "xiaomei", "mark", "linda", "george", "harvey", "ella", "ben"]
	for npc_id in npc_list:
		if not affections.has(npc_id):
			affections[npc_id] = 0
		if not triggered_events.has(npc_id):
			triggered_events[npc_id] = []

func add_affection(npc_id: String, amount: int):
	if not affections.has(npc_id):
		affections[npc_id] = 0
	
	var old_heart = get_heart_level(npc_id)
	affections[npc_id] = clampi(affections[npc_id] + amount, 0, MAX_AFFECTION)
	var new_heart = get_heart_level(npc_id)
	
	affection_changed.emit(npc_id, affections[npc_id], new_heart)
	
	# 检查是否触发新好感事件
	if new_heart > old_heart and new_heart % 2 == 0 and new_heart <= 10:
		if not triggered_events[npc_id].has(new_heart):
			triggered_events[npc_id].append(new_heart)
			heart_event_unlocked.emit(npc_id, new_heart)

func get_affection(npc_id: String) -> int:
	return affections.get(npc_id, 0)

func get_heart_level(npc_id: String) -> int:
	return affections.get(npc_id, 0) / HEART_PER_LEVEL

func get_heart_display(npc_id: String) -> String:
	var hearts = get_heart_level(npc_id)
	var filled = ""
	var empty = ""
	for i in range(min(hearts, 10)):
		filled += "♥" 
	for i in range(10 - min(hearts, 10)):
		empty += "♡"
	return filled + empty

func has_unlocked_event(npc_id: String, heart: int) -> bool:
	return triggered_events.get(npc_id, []).has(heart)
