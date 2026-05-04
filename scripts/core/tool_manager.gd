# tool_manager.gd — 工具系统管理器
extends Node

enum ToolType { NONE, HOE, WATERING_CAN, SEED, SWORD, PICKAXE, AXE, FISHING_ROD }

const TOOL_COOLDOWN: float = 0.2
const HOE_STAMINA_COST: int = 4
const WATER_STAMINA_COST: int = 3

var current_tool: int = ToolType.HOE
var cooldown_timer: float = 0.0
var can_use: bool = true

signal tool_switched(tool_type: int)
signal tool_used(tool_type: int, tile_pos: Vector2i)
signal tool_cooldown_started(duration: float)
signal tool_cooldown_ended()

func _process(delta: float) -> void:
	if not can_use:
		cooldown_timer -= delta
		if cooldown_timer <= 0.0:
			can_use = true
			tool_cooldown_ended.emit()

func use(player: Node2D) -> void:
	"""使用当前工具"""
	if not can_use or current_tool == ToolType.NONE:
		return
	
	# 计算目标 tile 坐标（玩家前方一格）
	var tile_pos: Vector2i = _get_tile_in_front(player)
	
	match current_tool:
		ToolType.HOE:
			if _can_afford(player, HOE_STAMINA_COST):
				_consume_stamina(player, HOE_STAMINA_COST)
				if CropManager:
					CropManager.till_soil(tile_pos)
				tool_used.emit(current_tool, tile_pos)
		ToolType.WATERING_CAN:
			if _can_afford(player, WATER_STAMINA_COST):
				_consume_stamina(player, WATER_STAMINA_COST)
				if CropManager:
					CropManager.water_soil(tile_pos)
				tool_used.emit(current_tool, tile_pos)
		_:
			tool_used.emit(current_tool, tile_pos)
	
	can_use = false
	cooldown_timer = TOOL_COOLDOWN
	tool_cooldown_started.emit(TOOL_COOLDOWN)

func switch_to(tool_type: int) -> void:
	if tool_type >= ToolType.NONE and tool_type <= ToolType.FISHING_ROD:
		current_tool = tool_type
		tool_switched.emit(tool_type)

func _get_tile_in_front(player: Node2D) -> Vector2i:
	"""根据玩家朝向计算前方 1 格的 tile 坐标"""
	if not player:
		return Vector2i.ZERO
	var pfacing := ""
	if player.has_method("get_facing"):
		# 新版 player.gd 有 facing 变量，但不是方法
		pass
	# 直接访问 facing 属性
	var facing := "down"
	if "facing" in player:
		facing = player.facing
	
	var tile_size: float = 48.0  # 32 * 1.5 ZOOM
	var offset: Vector2 = Vector2.ZERO
	match facing:
		"up":    offset = Vector2(0, -tile_size)
		"down":  offset = Vector2(0, tile_size)
		"left":  offset = Vector2(-tile_size, 0)
		"right": offset = Vector2(tile_size, 0)
	
	var world_pos := player.global_position + offset
	return Vector2i(int(world_pos.x / tile_size), int(world_pos.y / tile_size))

func _can_afford(player: Node2D, cost: int) -> bool:
	return player.has_method("consume_stamina") and player.consume_stamina(cost)

func _consume_stamina(player: Node2D, cost: int) -> void:
	if player.has_method("consume_stamina"):
		player.consume_stamina(cost)
