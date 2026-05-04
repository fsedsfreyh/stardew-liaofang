# dialogue_manager.gd - 非阻塞对话管理器（星露谷风格 UI）
# 为什么非阻塞：玩家打开对话框时，UI 仍然可操作
# 为什么用信号：解耦对话逻辑与场景逻辑

extends Control

enum State { IDLE, OPENING, ACTIVE, CLOSING }

const CHAR_DELAY: float = 0.035
const FAST_CHAR_DELAY: float = 0.008
const CLOSE_DELAY: float = 0.3
const BLINK_SPEED: float = 1.5  # 继续提示闪烁速度

@export var box_position: Vector2 = Vector2(60, 460)
@export var box_size: Vector2 = Vector2(1280, 260)

var state: State = State.IDLE
var current_lines: Array[String] = []
var current_index: int = 0
var char_index: int = 0
var type_timer: float = 0.0
var is_fast: bool = false
var locked_player: Node = null
var _blink_timer: float = 0.0
var _npc_name: String = ""

signal dialogue_started(npc_name: String)
signal dialogue_finished()
signal dialogue_line_shown(index: int, total: int)

# UI 节点
var _bg: Panel = null
var _border: Panel = null
var _portrait_bg: Panel = null
var _portrait: TextureRect = null
var _name_bg: Panel = null
var _name_label: Label = null
var _text_label: Label = null
var _continue_hint: Label = null
var _audio: AudioStreamPlayer = null

# 配色（星露谷风格：米色/棕色/暖白）
const COL_BG := Color("#f5e6c8")           # 对话框背景：暖米色
const COL_BORDER := Color("#8a6a4a")       # 边框：深棕
const COL_NAME_BG := Color("#c4a47a")      # 名字标签背景
const COL_TEXT := Color("#3a2a1a")         # 文字：深褐
const COL_NAME := Color("#2a1a0a")         # 名字：近黑
const COL_HINT := Color("#6a5a4a")         # 提示文字

func _ready() -> void:
	visible = false
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_build_ui()
	_setup_audio()

func _build_ui() -> void:
	# 外边框（比背景大 4px，形成双层边框效果）
	_border = Panel.new()
	_border.position = box_position - Vector2(4, 4)
	_border.size = box_size + Vector2(8, 8)
	_border.add_theme_stylebox_override("panel", _make_border_style())
	add_child(_border)
	
	# 背景面板
	_bg = Panel.new()
	_bg.position = box_position
	_bg.size = box_size
	_bg.add_theme_stylebox_override("panel", _make_bg_style())
	add_child(_bg)
	
	# 头像背景框（带边框的矩形）
	_portrait_bg = Panel.new()
	_portrait_bg.position = Vector2(box_position.x + 16, box_position.y + 16)
	_portrait_bg.size = Vector2(80, 80)
	_portrait_bg.add_theme_stylebox_override("panel", _make_portrait_style())
	add_child(_portrait_bg)
	
	# 头像
	_portrait = TextureRect.new()
	_portrait.position = _portrait_bg.position + Vector2(4, 4)
	_portrait.size = _portrait_bg.size - Vector2(8, 8)
	_portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_portrait.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	add_child(_portrait)
	
	# 名字标签背景
	_name_bg = Panel.new()
	_name_bg.position = Vector2(box_position.x + 112, box_position.y + 16)
	_name_bg.size = Vector2(160, 28)
	_name_bg.add_theme_stylebox_override("panel", _make_name_style())
	add_child(_name_bg)
	
	# 名字标签
	_name_label = Label.new()
	_name_label.position = _name_bg.position + Vector2(8, 2)
	_name_label.size = Vector2(144, 24)
	_name_label.add_theme_font_size_override("font_size", 16)
	_name_label.add_theme_color_override("font_color", COL_NAME)
	add_child(_name_label)
	
	# 对话文本
	_text_label = Label.new()
	_text_label.position = Vector2(box_position.x + 112, box_position.y + 56)
	_text_label.size = Vector2(box_size.x - 140, box_size.y - 80)
	_text_label.add_theme_font_size_override("font_size", 16)
	_text_label.add_theme_color_override("font_color", COL_TEXT)
	_text_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_text_label.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	add_child(_text_label)
	
	# 继续提示（右下角）
	_continue_hint = Label.new()
	_continue_hint.position = Vector2(
		box_position.x + box_size.x - 130,
		box_position.y + box_size.y - 30
	)
	_continue_hint.size = Vector2(120, 24)
	_continue_hint.add_theme_font_size_override("font_size", 13)
	_continue_hint.add_theme_color_override("font_color", COL_HINT)
	_continue_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_continue_hint.text = "按 E 继续 ▼"
	add_child(_continue_hint)

func _make_border_style() -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = COL_BORDER
	sb.corner_radius_top_left = 12
	sb.corner_radius_top_right = 12
	sb.corner_radius_bottom_left = 12
	sb.corner_radius_bottom_right = 12
	return sb

func _make_bg_style() -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = COL_BG
	sb.corner_radius_top_left = 10
	sb.corner_radius_top_right = 10
	sb.corner_radius_bottom_left = 10
	sb.corner_radius_bottom_right = 10
	return sb

func _make_portrait_style() -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color("#e8d8b8")
	sb.border_color = COL_BORDER
	sb.border_width_left = 2
	sb.border_width_top = 2
	sb.border_width_right = 2
	sb.border_width_bottom = 2
	return sb

func _make_name_style() -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = COL_NAME_BG
	sb.corner_radius_top_left = 6
	sb.corner_radius_top_right = 6
	sb.corner_radius_bottom_left = 6
	sb.corner_radius_bottom_right = 6
	return sb

# ─── 音效 ─────────────────────────────────────────
func _setup_audio() -> void:
	_audio = AudioStreamPlayer.new()
	_audio.volume_db = -14.0
	add_child(_audio)
	
	# 生成一个短促的 beep 音效（8-bit mono，避免复杂度）
	var sample_rate := 22050
	var duration := 0.02
	var frames := int(sample_rate * duration)
	var data := PackedByteArray()
	data.resize(frames)  # 8-bit mono，每帧1字节
	
	for i in range(frames):
		var t := float(i) / sample_rate
		# 方波 A5 (880Hz)
		var sample: int = 127 + int(sin(t * 880.0 * TAU) * 60.0)
		sample = clampi(sample, 0, 255)
		data.encode_u8(i, sample)
	
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_8_BITS
	wav.stereo = false
	wav.mix_rate = sample_rate
	wav.data = data
	_audio.stream = wav

func _play_type_sound() -> void:
	if _audio and _audio.stream:
		_audio.play()

# ─── 公开 API ─────────────────────────────────────
func start_dialogue(text: String, npc_name: String = "", portrait: Texture2D = null) -> void:
	if state != State.IDLE:
		return
	
	var player := get_tree().get_first_node_in_group("player")
	if player and player.has_method("set_movement"):
		locked_player = player
		player.set_movement(false)
	
	current_lines = text.split("\n")
	current_index = 0
	char_index = 0
	type_timer = 0.0
	is_fast = false
	state = State.OPENING
	visible = true
	_npc_name = npc_name
	
	_name_label.text = npc_name
	if portrait:
		_portrait.texture = portrait
	else:
		_portrait.texture = null
	
	_continue_hint.visible = false
	_continue_hint.modulate = Color(1, 1, 1, 1)
	dialogue_started.emit(npc_name)
	_show_line(0)

func is_active() -> bool:
	return state in [State.OPENING, State.ACTIVE]

# ─── 逐字显示 ─────────────────────────────────────
func _process(delta: float) -> void:
	if state == State.IDLE:
		return
	
	# 继续提示闪烁
	if state == State.ACTIVE and _is_line_complete():
		_blink_timer += delta * BLINK_SPEED
		_continue_hint.modulate.a = 0.5 + 0.5 * sin(_blink_timer * TAU)
		_continue_hint.visible = true
	else:
		_continue_hint.visible = false
	
	# 检测加速
	is_fast = Input.is_action_pressed("player_interact") or Input.is_action_pressed("ui_accept")
	
	if state == State.OPENING or state == State.ACTIVE:
		type_timer += delta
		var delay := FAST_CHAR_DELAY if is_fast else CHAR_DELAY
		while type_timer >= delay:
			type_timer -= delay
			if char_index < len(current_lines[current_index]):
				char_index += 1
				_update_text_display()
				# 每隔 3 个字符播放一次音效（避免太吵）
				if char_index % 3 == 0 and not is_fast:
					_play_type_sound()
	
	# 继续按键
	if state == State.ACTIVE and _is_line_complete():
		if Input.is_action_just_pressed("player_interact") or Input.is_action_just_pressed("ui_accept"):
			_next_line()

func _update_text_display() -> void:
	if current_index < len(current_lines):
		var full_text := current_lines[current_index]
		_text_label.text = full_text.left(char_index)
		dialogue_line_shown.emit(current_index, len(current_lines))

func _is_line_complete() -> bool:
	return current_index < len(current_lines) and char_index >= len(current_lines[current_index])

func _show_line(index: int) -> void:
	if index >= len(current_lines):
		_close_dialogue()
		return
	
	current_index = index
	char_index = 0
	type_timer = 0.0
	_text_label.text = ""
	state = State.ACTIVE

func _next_line() -> void:
	current_index += 1
	_show_line(current_index)

func _close_dialogue() -> void:
	state = State.CLOSING
	visible = false
	
	if locked_player:
		var p := locked_player
		locked_player = null
		get_tree().create_timer(CLOSE_DELAY).timeout.connect(func():
			if is_instance_valid(p) and p.has_method("set_movement"):
				p.set_movement(true)
		)
	
	dialogue_finished.emit()
	state = State.IDLE
