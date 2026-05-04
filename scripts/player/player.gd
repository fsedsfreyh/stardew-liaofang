# player.gd - 玩家控制器
# 为什么自己构建：避免 AMD 灰屏 bug（Instantiate scenes 导致全灰）
# 为什么用静态类型：GDScript 2.0 支持，编译器能捕获类型错误
# 设计原则：单一职责，每个函数不超过 30 行

extends CharacterBody2D

# ─── 常量 ─────────────────────────────────────────
const WALK_SPEED: float = 80.0
const RUN_SPEED: float = 140.0
const MAX_STAMINA: int = 270
const TILE_SIZE: float = 48.0  # 32 * 1.5 ZOOM
const SPRITE_SCALE: float = 5.0  # 角色显示放大倍数

# ─── 导出（可编辑器调整） ─────────────────────────
@export var character_id: String = "player"

# ─── 状态变量 ─────────────────────────────────────
var direction: Vector2 = Vector2.DOWN  # 面朝方向
var facing: String = "down":            # 方向字符串 ["up","down","left","right"]
	set(v):
		if facing != v:
			facing = v
			anim_frame = 0
var anim_frame: int = 0                  # 动画帧 [0,1,2,3]
var anim_timer: float = 0.0              # 帧切换计时器
var is_moving: bool = false
var can_move: bool = true                # 对话/事件时锁定
var is_running: bool = false
var stamina: int = MAX_STAMINA:
	set(v):
		stamina = clampi(v, 0, MAX_STAMINA)
		stamina_changed.emit(stamina, MAX_STAMINA)
var _regen_counter: int = 0

# ─── 信号 ─────────────────────────────────────────
signal stamina_changed(current: int, max_st: int)
signal interacted(target: Node)
signal tool_used(tool_type: String, pos: Vector2)

# ─── 初始化 ───────────────────────────────────────
func _ready() -> void:
	add_to_group("player")
	_static_inline_setup()

func _static_inline_setup() -> void:
	"""内联构建可见/物理组件"""
	_sync_sprite()

# ─── 主循环 ───────────────────────────────────────
func _physics_process(delta: float) -> void:
	if not can_move:
		_play_idle()
		return
	
	var input_dir := Vector2(
		Input.get_axis("player_left", "player_right"),
		Input.get_axis("player_up", "player_down")
	)
	
	is_moving = input_dir != Vector2.ZERO
	is_running = Input.is_action_pressed("player_run") and is_moving
	
	if is_moving:
		velocity = input_dir.normalized() * (RUN_SPEED if is_running else WALK_SPEED)
		
		# 更新面朝方向
		if abs(input_dir.x) > abs(input_dir.y):
			facing = "left" if input_dir.x < 0 else "right"
		else:
			facing = "up" if input_dir.y < 0 else "down"
		
		# 动画帧切换
		anim_timer += delta
		if anim_timer > 0.12:
			anim_timer = 0.0
			anim_frame = (anim_frame + 1) % 4
	else:
		velocity = Vector2.ZERO
		anim_frame = 0
	
	move_and_slide()
	_sync_sprite()

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("player_interact"):
		_on_interact()
	if event.is_action_pressed("player_use_tool"):
		use_tool()
	if event.is_action_pressed("player_run"):
		is_running = true
	if event.is_action_pressed("player_inventory"):
		_toggle_inventory()
	if event.is_action_released("player_run"):
		is_running = false

# ─── 精灵同步 ─────────────────────────────────────
func _sync_sprite() -> void:
	"""根据 facing + anim_frame 更新纹理和朝向"""
	var sprite := get_node_or_null("Sprite2D") as Sprite2D
	if not sprite:
		return
	
	var variant: int = 0
	if is_moving:
		variant = 1 if anim_frame % 2 == 0 else 2
	
	# 根据方向选择纹理
	var tex_id: String = "player"
	match facing:
		"up":    tex_id = "player_back"
		"down":  tex_id = "player"
		"left":  tex_id = "player_left"
		"right": tex_id = "player_right"
	
	var tex := PixelArtist.generate(tex_id, variant)
	if tex:
		sprite.texture = tex
		sprite.scale = Vector2(SPRITE_SCALE, SPRITE_SCALE)
		# 左/右方向由纹理本身处理翻转，不需要 scale.x = -1

func _play_idle() -> void:
	"""不可移动时保持站立帧"""
	var sprite := get_node_or_null("Sprite2D") as Sprite2D
	if not sprite:
		return
	
	var tex_id: String = "player"
	match facing:
		"up":    tex_id = "player_back"
		"down":  tex_id = "player"
		"left":  tex_id = "player_left"
		"right": tex_id = "player_right"
	
	sprite.texture = PixelArtist.generate(tex_id, 0)
	if sprite.texture:
		sprite.scale = Vector2(SPRITE_SCALE, SPRITE_SCALE)
		velocity = Vector2.ZERO

# ─── 交互 ─────────────────────────────────────────
func _on_interact() -> void:
	"""按 E 时检测前方可交互对象"""
	var area := get_node_or_null("InteractArea") as Area2D
	if not area:
		return
	
	for other in area.get_overlapping_areas():
		var target := other.get_parent()
		if target and target.has_method("interact"):
			interacted.emit(target)
			target.interact()
			return

# ─── 工具系统 ─────────────────────────────────────
func use_tool() -> void:
	"""使用当前选中的工具"""
	if ToolManager and ToolManager.can_use:
		ToolManager.use(self)

# ─── 物品栏开关 ───────────────────────────────────
func _toggle_inventory() -> void:
	"""打开/关闭物品栏"""
	var inv := get_tree().current_scene.get_node_or_null("HUD/InventoryBar")
	if inv and inv.has_method("toggle"):
		inv.toggle()

# ─── 体力系统 ─────────────────────────────────────
func consume_stamina(amount: int) -> bool:
	"""消耗体力，不够返回 false"""
	if stamina < amount:
		return false
	stamina -= amount
	return true

func restore_stamina(amount: int) -> void:
	stamina += amount

func is_tired() -> bool:
	return stamina <= 0

func regen_tick() -> void:
	"""每 tick 恢复逻辑（由场景计时器调用）"""
	if stamina >= MAX_STAMINA:
		_regen_counter = 0
		return
	_regen_counter += 1
	if _regen_counter >= 10:
		_regen_counter = 0
		stamina = mini(stamina + 2, MAX_STAMINA)
