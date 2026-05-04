# FishGame — 钓鱼小游戏（按住空格瞄准浮动鱼标）
extends Control

signal fish_caught(fish_id: String, count: int)

enum State { IDLE, PLAYING, SUCCESS, FAIL }

var state: int = State.IDLE

# 鱼标
var fish_y: float = 0.5
var fish_speed: float = 0.0
var fish_dir: float = 1.0

# 玩家游标
var cursor_y: float = 0.5
var cursor_vel: float = 0.0
const CURSOR_UP_SPEED: float = 1.5
const CURSOR_DOWN_SPEED: float = 1.0
const CURSOR_BOUNCE: float = 0.3

# 目标区域
var target_center: float = 0.5
var target_half: float = 0.12

# 鱼种
const FISH_TABLE = {
	"fish_common": { "name": "鲫鱼", "min_diff": 0.0, "max_diff": 0.4, "color": Color("#a0c0d0") },
	"carp": { "name": "鲤鱼", "min_diff": 0.3, "max_diff": 0.65, "color": Color("#c08040") },
	"salmon": { "name": "三文鱼", "min_diff": 0.5, "max_diff": 0.8, "color": Color("#e07050") },
	"goldfish": { "name": "金鱼", "min_diff": 0.7, "max_diff": 0.92, "color": Color("#ffd700") },
	"legendary": { "name": "传说之鱼", "min_diff": 0.9, "max_diff": 1.0, "color": Color("#ff40ff") },
}

var current_fish_id: String = "fish_common"
var _difficulty: float = 0.0
var _fish_name: String = "鲫鱼"

var _hold_seconds: float = 0.0
const HOLD_REQUIRED: float = 0.6
var _timer: float = 0.0

@onready var title_label: Label = $TitleLabel
@onready var target_zone: ColorRect = $TargetZone
@onready var fish_bar: ColorRect = $FishBar
@onready var player_bar: ColorRect = $PlayerBar
@onready var hit_bar: ColorRect = $HitBar
@onready var retry_btn: Button = $RetryBtn
@onready var close_btn: Button = $CloseBtn
@onready var info_label: Label = $InfoLabel

func _ready():
	hide()
	retry_btn.pressed.connect(_on_retry)
	retry_btn.hide()
	close_btn.pressed.connect(_close)

func open():
	target_zone.color = Color(0, 0.8, 0, 0.3)
	hit_bar.modulate = Color(1, 1, 0, 0.3)
	state = State.PLAYING
	show()
	_reset()

func _reset():
	fish_y = 0.5
	fish_speed = 0.0
	fish_dir = 1.0
	cursor_y = 0.5
	cursor_vel = 0.0
	_hold_seconds = 0.0
	_timer = 0.0
	
	_difficulty = randf()
	var candidates = []
	for fid in FISH_TABLE:
		var f = FISH_TABLE[fid]
		if _difficulty >= f.min_diff and _difficulty <= f.max_diff:
			candidates.append(fid)
	current_fish_id = candidates[randi() % candidates.size()] if candidates.size() > 0 else "fish_common"
	var fish_info = FISH_TABLE[current_fish_id]
	_fish_name = fish_info["name"]
	
	target_center = randf_range(0.25, 0.75)
	target_half = 0.08 + (1.0 - _difficulty) * 0.10
	
	fish_speed = 0.5 + _difficulty * 0.6
	
	title_label.text = "🎣 目标：%s" % _fish_name
	retry_btn.hide()
	info_label.text = "按住空格/左键向上，松手下沉"

func _process(delta):
	if state != State.PLAYING:
		return
	_timer += delta
	
	# 鱼上下摆动
	fish_y += fish_dir * fish_speed * delta
	if fish_y > 0.9:
		fish_y = 0.9; fish_dir = -1.0
	elif fish_y < 0.1:
		fish_y = 0.1; fish_dir = 1.0
	fish_y += randf_range(-_difficulty * 0.04, _difficulty * 0.04) * delta * 3.0
	fish_y = clampf(fish_y, 0.05, 0.95)
	
	# 玩家游标
	var space_held = Input.is_key_pressed(KEY_SPACE) or Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)
	if space_held:
		cursor_vel -= CURSOR_UP_SPEED * delta
	else:
		cursor_vel += CURSOR_DOWN_SPEED * delta
	cursor_vel = clampf(cursor_vel, -2.0, 2.0)
	cursor_y += cursor_vel * delta
	
	# 边界反弹
	if cursor_y < 0.01:
		cursor_y = 0.01; cursor_vel = abs(cursor_vel) * CURSOR_BOUNCE
	elif cursor_y > 0.99:
		cursor_y = 0.99; cursor_vel = -abs(cursor_vel) * CURSOR_BOUNCE
	
	# 视觉更新
	var bh = fish_bar.size.y
	fish_bar.position = Vector2(fish_bar.position.x, 50 + fish_y * (340 - 50 - 8))
	player_bar.position = Vector2(player_bar.position.x, 50 + cursor_y * (340 - 50 - 8))
	target_zone.position = Vector2(target_zone.position.x, 50 + (target_center - target_half) * (340 - 50 - 8))
	target_zone.size = Vector2(target_zone.size.x, target_half * 2.0 * (340 - 50 - 8))
	
	# 判定
	var dist = abs(cursor_y - fish_y)
	if dist < target_half:
		_hold_seconds += delta
		hit_bar.color = Color(0, 1, 0, 0.4 + sin(_timer * 10) * 0.2)
		hit_bar.position = Vector2(hit_bar.position.x, 50 + cursor_y * (340 - 50 - 8))
		if _hold_seconds >= HOLD_REQUIRED:
			_on_catch()
	else:
		_hold_seconds = maxf(0, _hold_seconds - delta * 0.5)
		if dist < 0.1:
			hit_bar.color = Color(1, 1, 0, 0.2)
		else:
			hit_bar.color = Color(1, 0, 0, 0.1)
		hit_bar.position = Vector2(hit_bar.position.x, 50 + cursor_y * (340 - 50 - 8))

func _on_catch():
	state = State.SUCCESS
	Inventory.add_item(current_fish_id, 1)
	title_label.text = "✅ 钓到 %s ！" % _fish_name
	retry_btn.text = "继续钓鱼"
	retry_btn.show()
	info_label.text = ""
	fish_caught.emit(current_fish_id, 1)

func _on_retry():
	_reset()
	retry_btn.hide()
	state = State.PLAYING

func _close():
	hide()
	state = State.IDLE

func _input(event):
	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_ESCAPE: _close()
