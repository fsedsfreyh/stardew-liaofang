# MailUI — 邮件阅读面板
extends Control

var mail_items: Array = []
var _init_done: bool = false

@onready var mail_list = $MailList
@onready var content_panel = $ContentPanel
@onready var title_label = $ContentPanel/TitleLabel
@onready var sender_label = $ContentPanel/SenderLabel
@onready var text_label = $ContentPanel/TextLabel
@onready var close_btn = $CloseBtn

func _ready():
	mail_list.item_selected.connect(_on_mail_selected)
	close_btn.pressed.connect(_close)
	_init_done = true
	hide()

func open():
	mail_items = MailManager.get_mail_list()
	show()
	_refresh_list()
	
	# 如果有新邮件，自动选择第一封
	if mail_items.size() > 0:
		mail_list.select(0)
		_on_mail_selected(0)

func _refresh_list():
	mail_list.clear()
	for i in range(mail_items.size()):
		var mail = mail_items[i]
		var prefix = "📫 " if not mail["read"] else "📬 "
		mail_list.add_item(prefix + mail["title"])

func _on_mail_selected(index: int):
	if index < 0 or index >= mail_items.size():
		return
	var mail = mail_items[index]
	title_label.text = mail["title"]
	sender_label.text = "发件人：%s" % mail["sender"]
	text_label.text = mail["text"]
	
	# 标记已读
	MailManager.mark_as_read(mail["id"])
	_refresh_list()

func _close():
	hide()
