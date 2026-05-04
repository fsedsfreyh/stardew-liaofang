# FishAlbumUI — 鱼图鉴
extends CanvasLayer

const FISH_LIST = [
	{"id": "fish_common", "name": "鲫鱼", "desc": "最常见的河鱼，啥池塘都有"},
	{"id": "carp", "name": "鲤鱼", "desc": "红褐色的中型鱼，有点力气"},
	{"id": "salmon", "name": "三文鱼", "desc": "橙红色的肉，鲜美！"},
	{"id": "goldfish", "name": "金鱼", "desc": "金灿灿的观赏鱼，值不少钱"},
	{"id": "legendary", "name": "传说之鱼", "desc": "传说中的鱼…根本没人钓到过！"},
]

var is_open: bool = false

@onready var list = $FishList
@onready var close_btn = $CloseBtn
@onready var info_label = $InfoLabel

func _ready():
	close_btn.pressed.connect(_close)
	hide()

func open():
	_refresh()
	show()
	is_open = true

func _refresh():
	list.clear()
	var caught_count = 0
	for f in FISH_LIST:
		var count = Inventory.get_item_count(f.id)
		var is_caught = count > 0
		if is_caught:
			caught_count += 1
		var status = "🐟" if is_caught else "❓"
		var name_text = f.name if is_caught else "???"
		var desc_text = f.desc if is_caught else "还没见过这种鱼…"
		var text = "%s %s\n  %s  (背包: %d)" % [status, name_text, desc_text, count]
		list.add_item(text, null)
	
	info_label.text = "🎣 图鉴进度: %d/%d" % [caught_count, FISH_LIST.size()]

func _close():
	hide()
	is_open = false

func _input(event):
	if not is_open: return
	if event.is_action_pressed("player_interact") or (event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE and not event.echo):
		_close()
