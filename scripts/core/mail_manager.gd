# MailManager — 每日邮件系统
extends Node

signal mail_received(mail_id: String)
signal mail_deleted(mail_id: String)
signal unread_changed(count: int)

const MAIL_LIBRARY = {
	"welcome_day1": {
		"title": "🏡 欢迎来到星露乡！",
		"sender": "廖芳 💕",
		"text": "亲爱的 {player_name}：\n\n欢迎来到星露乡！我是廖芳，以后就是你的邻居啦～\n这封信随信附上一些种子，希望能帮你开垦这片农场。\n\n我在农场旁边的小屋里等你，有空记得来找我聊天哦！\n\n—— 廖芳 💕\n\n附赠：蓝风铃花种子 ×3、番茄种子 ×2",
		"day": 1,
		"attachments": {
			"bluebell_seed": 3,
			"tomato_seed": 2,
		},
	},
	"liaofang_2heart": {
		"title": "🌸 廖芳的悄悄话",
		"sender": "廖芳 💕",
		"text": "嗨 {player_name}：\n\n你知道吗？和你一起在农场度过的每一天，我都觉得很开心。\n你种的花开了，我也跟着高兴。\n\n送给你一朵我摘的野花，放在窗台上吧～\n\n—— 想要和你一起看日落的 廖芳 💕",
		"day": 2,
		"condition": {"affection_liaofang": 200},
		"attachments": {
			"flower_blue": 1,
		},
	},
	"harvest_week": {
		"title": "🌾 农场大丰收通知",
		"sender": "星露乡农场协会 🏆",
		"text": "尊敬的 {player_name}：\n\n恭喜你在星露乡农场辛勤劳作了一周！\n协会特此表彰你的努力，送上一些肥料和金矿，\n祝你的农场越办越好！\n\n—— 星露乡农场协会\n\n附赠：金矿 ×2、优质肥料 ×3",
		"day": 7,
		"attachments": {
			"gold_ore": 2,
			"coal": 3,
		},
	},
	"friend_letter": {
		"title": "📝 来自远方的信",
		"sender": "老朋友 阿杰 ✉️",
		"text": "{player_name}！\n\n听说你在星露乡种地种得风生水起？\n我在城里可羡慕你了！这里每天除了上班就是睡觉，连个种花的地方都没有。\n\n随信附上一些城里带回来的好东西，\n有空给我回信啊！\n\n—— 你的老朋友 阿杰\n\n附赠：钻石 ×1、草莓蛋糕 ×1",
		"day": 14,
		"attachments": {
			"diamond": 1,
			"cake": 1,
		},
	},
	"anniversary": {
		"title": "💞 相遇一个月纪念",
		"sender": "廖芳 💕",
		"text": "致我最亲爱的 {player_name}：\n\n今天是我们在星露乡相遇的第30天。\n回想起第一天你笨拙地拿锄头的样子，我觉得又好笑又可爱。\n\n这30天里，我们看过了日出日落、种过了花花草草、\n一起经历了风风雨雨。谢谢你，让我的每一天都充满阳光。\n\n我爱你 🌹\n\n—— 永远是你的 廖芳 💕\n\n附赠：蓝风铃花 ×10、钻石 ×3",
		"day": 30,
		"attachments": {
			"bluebell": 10,
			"diamond": 3,
		},
	},
	# 🔔 好感度事件信件
	"gift_guide": {
		"title": "🎁 小镇送礼指南",
		"sender": "Bill 🧔",
		"text": "嘿 {player_name}！\n\n我是 Bill，小镇杂货店老板。听说你想和那个叫廖芳的姑娘搞好关系？\n这里给你透个底——她最爱蓝风铃花和草莓蛋糕，\n送对了东西好感涨得飞快！\n\n对了，我家店里就有卖种子和蛋糕，欢迎光临！\n\n—— Bill\n\n附赠：蓝风铃花种子 ×5",
		"day": 2,
		"attachments": {
			"bluebell_seed": 5,
		},
	},
	"heart4_mail": {
		"title": "💌 一封来自廖芳的信",
		"sender": "廖芳 💕",
		"text": "{player_name}：\n\n今天我在农场旁边的小山坡上坐了很久。\n看着你在地里忙碌的样子，我突然觉得很幸福。\n\n有些话当面说有点害羞…所以就写信告诉你吧：\n有你在这里，真好。\n\n—— 廖芳 💕\n\n附赠：蓝风铃花 ×3",
		"condition": {"affection_liaofang": 400},
		"attachments": {
			"bluebell": 3,
		},
	},
	"heart6_mail": {
		"title": "🌙 深夜的信",
		"sender": "廖芳 💕",
		"text": "致 {player_name}：\n\n现在是深夜，农场很安静，只有蟋蟀在叫。\n我睡不着，总想着你白天对我笑的样子。\n\n我能感觉到，我们之间的关系好像不太一样了……\n是比朋友更亲密的那种，对吗？\n\n—— 心里很乱的 廖芳 💕",
		"condition": {"affection_liaofang": 600},
	},
	"heart8_mail": {
		"title": "💍 一个重要的约定",
		"sender": "廖芳 💕",
		"text": "{player_name}：\n\n你愿意和我一起守护这片农场吗？\n不是作为邻居，也不是朋友…\n而是一起生活、一起变老的那种。\n\n如果你愿意，明天来小屋找我吧。\n我等你。\n\n—— 永远等你的 廖芳 💕\n\n附赠：野花束 ×1、金色玫瑰 ×1",
		"condition": {"affection_liaofang": 800},
		"attachments": {
			"bluebell": 5,
			"diamond": 1,
		},
	},
	"heart10_mail": {
		"title": "💖 最珍贵的礼物",
		"sender": "廖芳 💕",
		"text": "给我最爱的 {player_name}：\n\n谢谢你选择了和我在一起。\n我会用每一天来证明，你的选择是对的。\n\n这枚蓝风铃胸针是我亲手做的，\n里面有我们第一次见面时我摘的那朵花的花瓣。\n\n我爱你。永远。\n\n—— 你的 廖芳 💕\n\n附赠：蓝风铃花 ×10、草莓蛋糕 ×2、钻石 ×2",
		"condition": {"affection_liaofang": 1000},
		"attachments": {
			"bluebell": 10,
			"cake": 2,
			"diamond": 2,
		},
	},
	"mining_tips": {
		"title": "⛏️ 矿洞生存手册",
		"sender": "星露乡矿物协会",
		"text": "{player_name}：\n\n欢迎成为矿工！这里有一些小贴士：\n\n1. 矿洞每层都会生成新的怪物和矿石\n2. 用鼠标左键攻击，击退史莱姆\n3. 找到楼梯按 E 进入更深层\n4. 越深层的怪物越强，但掉落也越好\n\n祝你好运！别死在里面了 :)\n\n—— 星露乡矿物协会\n\n附赠：煤炭 ×5",
		"condition": {"affection_liaofang": 0, "max_affection": 200},
		"attachments": {
			"coal": 5,
		},
	},
}

var mail_list: Array = []  # [{id, title, sender, text, day, attachments, read}]
var received_ids: Array = []

func _ready():
	if DayTime.current_day > 1:
		_load_mail()

func check_for_new_mail():
	var current_day = DayTime.current_day
	var season = DayTime.current_season
	var year = DayTime.current_year
	
	for mid in MAIL_LIBRARY:
		if mid in received_ids:
			continue
		
		var mail = MAIL_LIBRARY[mid].duplicate(true)
		
		# 按条件判断
		var should_send = false
		
		if mail.has("day"):
			should_send = current_day >= mail["day"]
		
		if mail.has("condition"):
			var cond = mail["condition"]
			if cond.has("affection_liaofang"):
				var affection = Affection.get_affection("liaofang")
				var min_aff = cond["affection_liaofang"]
				var max_aff = cond.get("max_affection", 9999)
				if affection < min_aff or affection > max_aff:
					should_send = false
		
		if should_send:
			_receive_mail(mid)

func _receive_mail(mid: String):
	var mail = MAIL_LIBRARY[mid].duplicate(true)
	var text = mail["text"].replace("{player_name}", Global.player_name)
	mail["text"] = text
	mail["id"] = mid
	mail["read"] = false
	
	mail_list.append(mail)
	received_ids.append(mid)
	
	# 附件自动加入背包
	if mail.has("attachments"):
		for item_id in mail["attachments"]:
			var count = mail["attachments"][item_id]
			Inventory.add_item(item_id, count)
	
	mail_received.emit(mid)

func has_unread() -> bool:
	for mail in mail_list:
		if not mail.get("read", true):
			return true
	return false

func get_unread_count() -> int:
	var count = 0
	for mail in mail_list:
		if not mail.get("read", true):
			count += 1
	return count

func mark_as_read(mail_id: String):
	for mail in mail_list:
		if mail["id"] == mail_id:
			mail["read"] = true
			unread_changed.emit(get_unread_count())
			return

func mark_all_read():
	for mail in mail_list:
		mail["read"] = true
	unread_changed.emit(0)

func delete_mail(mail_id: String):
	var idx = -1
	for i in range(mail_list.size()):
		if mail_list[i]["id"] == mail_id:
			idx = i
			break
	if idx >= 0:
		mail_list.remove_at(idx)
		mail_deleted.emit(mail_id)

func get_mail_list() -> Array:
	return mail_list.duplicate()

func _load_mail():
	pass  # 保存系统负责恢复

func save_data() -> Dictionary:
	var slim_list = []
	for mail in mail_list:
		slim_list.append({
			"id": mail["id"],
			"read": mail.get("read", false),
			"day": mail.get("day", 1),
			"title": mail.get("title", ""),
			"sender": mail.get("sender", ""),
			"text": mail.get("text", ""),
			"attachments": mail.get("attachments", {}),
		})
	return {
		"mail_list": slim_list,
		"received_ids": received_ids.duplicate(),
	}

func load_data(data: Dictionary):
	mail_list = data.get("mail_list", []).duplicate()
	received_ids = data.get("received_ids", []).duplicate()
