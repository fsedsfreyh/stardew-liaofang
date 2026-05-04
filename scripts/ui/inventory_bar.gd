# inventory_bar.gd - 热键物品栏
# 为什么是 bar 而不是全屏背包：战斗中/农活时快速切换工具
# 为什么用 @export 引用：避免硬编码路径
# 为什么支持键盘+鼠标：交互优先原则

extends Control

# ─── 常量 ─────────────────────────────────────────
const SLOT_COUNT: int = 9
const SLOT_SIZE: int = 52
const PADDING: int = 4
const TOOLTIP_DELAY: float = 0.8

# ─── 导出 ─────────────────────────────────────────
@export var slot_scene: PackedScene  # 可选，不用则代码生成

# ─── 状态 ─────────────────────────────────────────
var is_open: bool = true               # 默认显示
var selected_index: int = 0            # 当前选中格 [0-8]
var slots: Array[SlotWidget] = []      # 所有格子对象
var hover_index: int = -1              # 鼠标悬停格 [-1=无]

# ─── 信号 ─────────────────────────────────────────
signal slot_selected(index: int)
signal slot_used(index: int, item_id: String)

# ─── 子节点类型定义 ───────────────────────────────
class SlotWidget:
	var panel: Panel
	var icon: TextureRect
	var count: Label
	var hotkey: Label
	var index: int
	
	func _init(idx: int) -> void:
		index = idx

# ─── 初始化 ───────────────────────────────────────
func _ready() -> void:
	position = Vector2(0, 648)  # 底部居中：720 - 52 - 20
	size = Vector2(1280, 72)
	_build_slots()
	_select_slot(0)

func _build_slots() -> void:
	"""创建 9 个物品格子"""
	var start_x := (1280 - (SLOT_COUNT * (SLOT_SIZE + PADDING) - PADDING)) / 2
	
	for i in range(SLOT_COUNT):
		var slot := SlotWidget.new(i)
		
		# 面板
		var p := Panel.new()
		p.position = Vector2(start_x + i * (SLOT_SIZE + PADDING), 4)
		p.size = Vector2(SLOT_SIZE, SLOT_SIZE)
		p.add_theme_stylebox_override("panel", _make_slot_style(false, i == selected_index))
		p.mouse_entered.connect(_on_slot_hover.bind(i))
		p.mouse_exited.connect(_on_slot_unhover.bind(i))
		p.gui_input.connect(_on_slot_gui_input.bind(i))
		add_child(p)
		slot.panel = p
		
		# Icon
		var icon := TextureRect.new()
		icon.position = Vector2(6, 6)
		icon.size = Vector2(40, 40)
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		icon.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
		p.add_child(icon)
		slot.icon = icon
		
		# 数量标签
		var cnt := Label.new()
		cnt.position = Vector2(4, 34)
		cnt.size = Vector2(44, 14)
		cnt.add_theme_font_size_override("font_size", 10)
		cnt.add_theme_color_override("font_color", Color.WHITE)
		cnt.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.5))
		cnt.add_theme_constant_override("shadow_offset_x", 1)
		cnt.add_theme_constant_override("shadow_offset_y", 1)
		cnt.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		p.add_child(cnt)
		slot.count = cnt
		
		# 快捷键标签
		var key := Label.new()
		key.position = Vector2(2, 2)
		key.size = Vector2(20, 14)
		key.add_theme_font_size_override("font_size", 9)
		key.add_theme_color_override("font_color", Color(0.8, 0.8, 0.7, 0.6))
		key.text = str(i + 1)
		p.add_child(key)
		slot.hotkey = key
		
		slots.append(slot)

func _make_slot_style(is_hover: bool, is_selected: bool) -> StyleBoxFlat:
	"""根据状态返回格子风格"""
	var sb := StyleBoxFlat.new()
	sb.corner_radius_top_left = 4
	sb.corner_radius_top_right = 4
	sb.corner_radius_bottom_left = 4
	sb.corner_radius_bottom_right = 4
	if is_selected:
		sb.bg_color = Color(0.3, 0.5, 0.3, 0.7)  # 绿色选中
		sb.border_width_left = 2
		sb.border_width_right = 2
		sb.border_width_top = 2
		sb.border_width_bottom = 2
		sb.border_color = Color("#88c888")
	elif is_hover:
		sb.bg_color = Color(0.25, 0.25, 0.2, 0.6)
		sb.border_width_left = 1
		sb.border_width_right = 1
		sb.border_width_top = 1
		sb.border_width_bottom = 1
		sb.border_color = Color("#a0a090")
	else:
		sb.bg_color = Color(0.15, 0.12, 0.08, 0.55)
		sb.border_width_left = 1
		sb.border_width_right = 1
		sb.border_width_top = 1
		sb.border_width_bottom = 1
		sb.border_color = Color("#605050")
	return sb

# ─── 输入处理 ─────────────────────────────────────
func _input(event: InputEvent) -> void:
	# 键盘 1-9 选择格子
	if event is InputEventKey and event.pressed and not event.echo:
		for i in range(SLOT_COUNT):
			var keycode := KEY_1 + i
			if event.keycode == keycode:
				_select_slot(i)
				return

func _select_slot(index: int) -> void:
	"""选中格子"""
	if index < 0 or index >= SLOT_COUNT:
		return
	
	# 取消旧选中
	if selected_index >= 0 and selected_index < len(slots):
		slots[selected_index].panel.add_theme_stylebox_override("panel",
			_make_slot_style(selected_index == hover_index, false))
	
	selected_index = index
	slots[index].panel.add_theme_stylebox_override("panel",
		_make_slot_style(index == hover_index, true))
	
	slot_selected.emit(index)

# ─── 鼠标交互 ─────────────────────────────────────
func _on_slot_hover(index: int) -> void:
	hover_index = index
	_update_slot_style(index)

func _on_slot_unhover(index: int) -> void:
	hover_index = -1
	_update_slot_style(index)

func _on_slot_gui_input(event: InputEvent, index: int) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_select_slot(index)

func _update_slot_style(index: int) -> void:
	if index < 0 or index >= len(slots):
		return
	var is_sel := index == selected_index
	slots[index].panel.add_theme_stylebox_override("panel",
		_make_slot_style(index == hover_index, is_sel))

# ─── 物品数据同步 ─────────────────────────────────
func sync_with_inventory() -> void:
	"""从 Inventory autoload 同步物品显示"""
	if not Engine.has_singleton("Inventory"):
		return
	
	for i in range(SLOT_COUNT):
		_apply_slot(i)

func _apply_slot(index: int) -> void:
	"""更新单个格子的显示"""
	if index >= len(slots):
		return
	var slot := slots[index]
	var inv := get_node("/root/Inventory")  # autoload
	if not inv:
		return
	
	# 获取该格子的物品
	var items := inv.inventory if "inventory" in inv else {}
	var keys := items.keys()
	if index < keys.size():
		var item_id := keys[index] as String
		var qty := items[item_id] as int
		var db := inv.get_item_db() if inv.has_method("get_item_db") else {}
		var info := db.get(item_id, {})
		var tex: Texture2D = info.get("icon", null) if info is Dictionary else null
		
		if tex:
			slot.icon.texture = tex
		else:
			slot.icon.texture = null
		
		if qty > 1:
			slot.count.text = str(qty)
			slot.count.visible = true
		else:
			slot.count.visible = false
	else:
		slot.icon.texture = null
		slot.count.visible = false

func toggle() -> void:
	"""开关物品栏可见性"""
	is_open = not is_open
	visible = is_open
