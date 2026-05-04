# pixel_artist.gd — 像素精灵纯代码生成器
# 为什么要用代码画？确保零外部资源依赖，编辑器打开就能跑，不需要导入任何 PNG
# 所有调色板参照星露谷物语规范：暖色系、低饱和度、3 层明度、1px 褐色轮廓线

extends Node

# ─── 星露谷规范调色板 ─────────────────────────────
# 轮廓线（所有外部描绘）：暖褐色 #2a2018（不是纯黑 #000000！）
const OUTLINE := Color("#2a2018")

const PALETTE := {
	# 皮肤
	"skin_light": Color("#f0d8b0"),
	"skin_mid":   Color("#e0c0a0"),
	"skin_dark":  Color("#c8a880"),
	# 头发
	"hair_main":  Color("#18181a"),
	"hair_highlight": Color("#282820"),
	"hair_shadow": Color("#0c0c0e"),
	# 眼睛
	"eye_white":  Color("#203050"),
	"eye_highlight": Color("#f8f8f8"),
	# 腮红
	"blush":      Color("#e8a090"),
	# 蓝色衬衫（玩家）
	"shirt_light": Color("#5898d0"),
	"shirt_mid":   Color("#4888d0"),
	"shirt_dark":  Color("#3868b0"),
	"shirt_highlight": Color("#68a8e0"),
	# 裤子
	"pants_light": Color("#4888a0"),
	"pants_mid":   Color("#385888"),
	"pants_dark":  Color("#284870"),
	# 鞋子
	"shoes":      Color("#3a2a1a"),
	"shoes_light": Color("#4a3a2a"),
	# 廖芳的粉色上衣
	"pink_light":  Color("#f0a0b0"),
	"pink_mid":    Color("#e08090"),
	"pink_dark":   Color("#c06070"),
	"pink_highlight": Color("#f8b8c0"),
	# 廖芳裙子
	"skirt_light": Color("#e0d0a0"),
	"skirt_mid":   Color("#d0b890"),
	"skirt_dark":  Color("#b09870"),
	# 通用
	"mouth":      Color("#c05048"),
	# 工具
	"hoe_wood":   Color("#8a6a4a"),
	"hoe_metal":  Color("#7a8a9a"),
	"water":      Color("#4890c8"),
	"can_body":   Color("#a0a0a0"),
}


# ─── 工具函数 ─────────────────────────────────────

static func set_px(img: Image, x: int, y: int, color: Color) -> void:
	"""设置像素，边界检查"""
	var w := img.get_width()
	var h := img.get_height()
	if x < 0 or x >= w or y < 0 or y >= h:
		return
	img.set_pixel(x, y, color)

static func fill_rect(img: Image, rx: int, ry: int, rw: int, rh: int, color: Color) -> void:
	"""填充矩形区域"""
	var w := img.get_width()
	var h := img.get_height()
	for dx in range(rw):
		var px := rx + dx
		if px < 0 or px >= w:
			continue
		for dy in range(rh):
			var py := ry + dy
			if py < 0 or py >= h:
				continue
			img.set_pixel(px, py, color)

static func _to_texture(img: Image) -> ImageTexture:
	return ImageTexture.create_from_image(img)


# ─── 公共入口 ─────────────────────────────────────

# 缓存：texture_id + "_" + variant → ImageTexture
static var _tex_cache: Dictionary = {}

static func generate(texture_id: String, variant: int = 0) -> ImageTexture:
	var cache_key := texture_id + str(variant)
	if cache_key in _tex_cache:
		return _tex_cache[cache_key]
	
	var tex: ImageTexture
	match texture_id:
		"player":       tex = _gen_player(variant)
		"liaofang":     tex = _gen_liaofang(variant)
		"pet":          tex = _gen_pet(variant)
		"player_back":  tex = _gen_player_back(variant)
		"player_left":  tex = _gen_player_side(variant, true)
		"player_right": tex = _gen_player_side(variant, false)
		"hoe":          tex = _gen_tool("hoe")
		"watering_can": tex = _gen_tool("watering_can")
		_:              tex = _gen_player(variant)
	
	_tex_cache[cache_key] = tex
	return tex


# ═══════════════════════════════════════════════════
# 主角正面（16x32 像素）— 升级版：更多细节
# ═══════════════════════════════════════════════════

static func _gen_player(variant: int) -> ImageTexture:
	"""主角正面：蓝色衬衫 + 深蓝裤子
	variant: 0=站, 1=左步, 2=右步"""
	var img := Image.create(16, 32, false, Image.FORMAT_RGBA8)
	img.fill(Color.TRANSPARENT)
	
	# ── 头发（增加层次：主色+高光+阴影） ──
	# 主发块
	fill_rect(img, 5, 0, 6, 3, PALETTE["hair_main"])
	fill_rect(img, 4, 1, 8, 5, PALETTE["hair_main"])
	# 高光（顶部中间）
	fill_rect(img, 6, 1, 4, 2, PALETTE["hair_highlight"])
	# 刘海（中间分缝）
	fill_rect(img, 5, 3, 2, 1, PALETTE["hair_main"])
	fill_rect(img, 9, 3, 2, 1, PALETTE["hair_main"])
	set_px(img, 7, 3, PALETTE["hair_highlight"])
	# 鬓角（耳朵位置）
	set_px(img, 3, 5, PALETTE["hair_main"])
	set_px(img, 12, 5, PALETTE["hair_main"])
	
	# ── 脸 ──
	fill_rect(img, 5, 4, 6, 6, PALETTE["skin_light"])
	fill_rect(img, 4, 5, 8, 5, PALETTE["skin_light"])
	# 耳朵
	set_px(img, 3, 7, PALETTE["skin_mid"])
	set_px(img, 12, 7, PALETTE["skin_mid"])
	
	# ── 眼睛（2x2 + 左上角高光） ──
	set_px(img, 6, 6, PALETTE["eye_highlight"])
	set_px(img, 7, 6, PALETTE["eye_white"])
	set_px(img, 6, 7, PALETTE["eye_white"])
	set_px(img, 7, 7, PALETTE["eye_white"])
	set_px(img, 9, 6, PALETTE["eye_highlight"])
	set_px(img, 10, 6, PALETTE["eye_white"])
	set_px(img, 9, 7, PALETTE["eye_white"])
	set_px(img, 10, 7, PALETTE["eye_white"])
	# 眉毛
	set_px(img, 6, 5, PALETTE["hair_main"])
	set_px(img, 7, 5, PALETTE["hair_main"])
	set_px(img, 9, 5, PALETTE["hair_main"])
	set_px(img, 10, 5, PALETTE["hair_main"])
	
	# ── 腮红 ──
	set_px(img, 4, 8, PALETTE["blush"])
	set_px(img, 11, 8, PALETTE["blush"])
	
	# ── 鼻子（1px 阴影） ──
	set_px(img, 7, 8, PALETTE["skin_dark"])
	set_px(img, 8, 8, PALETTE["skin_dark"])
	
	# ── 嘴巴（微笑） ──
	set_px(img, 7, 9, PALETTE["mouth"])
	set_px(img, 8, 10, PALETTE["mouth"])
	set_px(img, 9, 9, PALETTE["mouth"])
	
	# ── 脖子 ──
	fill_rect(img, 6, 10, 4, 1, PALETTE["skin_dark"])
	
	# ── 身体（蓝色衬衫） ──
	fill_rect(img, 5, 11, 6, 7, PALETTE["shirt_mid"])
	# 领口 V 形
	set_px(img, 6, 11, PALETTE["skin_dark"])
	set_px(img, 9, 11, PALETTE["skin_dark"])
	# 衬衫褶皱/阴影
	set_px(img, 5, 13, PALETTE["shirt_dark"])
	set_px(img, 10, 13, PALETTE["shirt_dark"])
	set_px(img, 6, 15, PALETTE["shirt_dark"])
	set_px(img, 9, 15, PALETTE["shirt_dark"])
	# 纽扣
	set_px(img, 7, 13, PALETTE["shirt_highlight"])
	set_px(img, 8, 14, PALETTE["shirt_highlight"])
	
	# ── 手臂 ──
	fill_rect(img, 3, 12, 2, 5, PALETTE["skin_light"])
	fill_rect(img, 11, 12, 2, 5, PALETTE["skin_light"])
	# 袖子
	set_px(img, 3, 11, PALETTE["shirt_mid"])
	set_px(img, 4, 11, PALETTE["shirt_dark"])
	set_px(img, 11, 11, PALETTE["shirt_mid"])
	set_px(img, 12, 11, PALETTE["shirt_dark"])
	# 手
	set_px(img, 3, 17, PALETTE["skin_dark"])
	set_px(img, 12, 17, PALETTE["skin_dark"])
	
	# ── 裤子（根据步态变化） ──
	match variant:
		0:  # 站立
			fill_rect(img, 5, 18, 6, 7, PALETTE["pants_mid"])
			fill_rect(img, 4, 19, 8, 6, PALETTE["pants_mid"])
			# 裤缝
			set_px(img, 6, 20, PALETTE["pants_dark"])
			set_px(img, 9, 20, PALETTE["pants_dark"])
			# 腰带区
			fill_rect(img, 5, 18, 6, 1, PALETTE["pants_dark"])
		1:  # 左步
			fill_rect(img, 5, 18, 6, 7, PALETTE["pants_mid"])
			fill_rect(img, 3, 19, 5, 6, PALETTE["pants_mid"])
			fill_rect(img, 9, 19, 4, 6, PALETTE["pants_dark"])
			set_px(img, 6, 24, PALETTE["pants_mid"])
			set_px(img, 7, 24, PALETTE["pants_mid"])
			# 左膝盖高光
			set_px(img, 4, 21, PALETTE["pants_light"])
		2:  # 右步
			fill_rect(img, 5, 18, 6, 7, PALETTE["pants_mid"])
			fill_rect(img, 3, 19, 4, 6, PALETTE["pants_dark"])
			fill_rect(img, 8, 19, 5, 6, PALETTE["pants_mid"])
			set_px(img, 6, 24, PALETTE["pants_mid"])
			set_px(img, 7, 24, PALETTE["pants_mid"])
			# 右膝盖高光
			set_px(img, 10, 21, PALETTE["pants_light"])
	
	# ── 鞋子 ──
	fill_rect(img, 4, 25, 3, 2, PALETTE["shoes"])
	fill_rect(img, 9, 25, 3, 2, PALETTE["shoes"])
	# 鞋带高光
	set_px(img, 5, 25, PALETTE["shoes_light"])
	set_px(img, 10, 25, PALETTE["shoes_light"])
	
	# ── 轮廓线 ──
	_draw_outline_front(img)
	
	return _to_texture(img)


static func _draw_outline_front(img: Image) -> void:
	"""主角正面轮廓"""
	# 头顶
	set_px(img, 5, 0, OUTLINE); set_px(img, 6, 0, OUTLINE); set_px(img, 7, 0, OUTLINE)
	set_px(img, 8, 0, OUTLINE); set_px(img, 9, 0, OUTLINE); set_px(img, 10, 0, OUTLINE)
	# 两侧头发
	set_px(img, 4, 1, OUTLINE); set_px(img, 11, 1, OUTLINE)
	set_px(img, 3, 2, OUTLINE); set_px(img, 12, 2, OUTLINE)
	set_px(img, 3, 3, OUTLINE); set_px(img, 12, 3, OUTLINE)
	set_px(img, 3, 4, OUTLINE); set_px(img, 12, 4, OUTLINE)
	set_px(img, 3, 5, OUTLINE); set_px(img, 12, 5, OUTLINE)
	set_px(img, 3, 6, OUTLINE); set_px(img, 12, 6, OUTLINE)
	set_px(img, 3, 7, OUTLINE); set_px(img, 12, 7, OUTLINE)
	set_px(img, 3, 8, OUTLINE); set_px(img, 12, 8, OUTLINE)
	set_px(img, 3, 9, OUTLINE); set_px(img, 12, 9, OUTLINE)
	# 下巴两侧
	set_px(img, 4, 10, OUTLINE); set_px(img, 11, 10, OUTLINE)
	# 肩膀
	set_px(img, 2, 11, OUTLINE); set_px(img, 13, 11, OUTLINE)
	# 手臂外侧
	set_px(img, 2, 12, OUTLINE); set_px(img, 13, 12, OUTLINE)
	set_px(img, 2, 13, OUTLINE); set_px(img, 13, 13, OUTLINE)
	set_px(img, 2, 14, OUTLINE); set_px(img, 13, 14, OUTLINE)
	set_px(img, 2, 15, OUTLINE); set_px(img, 13, 15, OUTLINE)
	set_px(img, 2, 16, OUTLINE); set_px(img, 13, 16, OUTLINE)
	# 裤腿外侧
	set_px(img, 3, 17, OUTLINE); set_px(img, 12, 17, OUTLINE)
	set_px(img, 3, 18, OUTLINE); set_px(img, 12, 18, OUTLINE)
	set_px(img, 3, 19, OUTLINE); set_px(img, 12, 19, OUTLINE)
	set_px(img, 3, 20, OUTLINE); set_px(img, 12, 20, OUTLINE)
	set_px(img, 3, 21, OUTLINE); set_px(img, 12, 21, OUTLINE)
	set_px(img, 3, 22, OUTLINE); set_px(img, 12, 22, OUTLINE)
	# 鞋子底部
	set_px(img, 4, 24, OUTLINE); set_px(img, 5, 24, OUTLINE); set_px(img, 6, 24, OUTLINE)
	set_px(img, 9, 24, OUTLINE); set_px(img, 10, 24, OUTLINE); set_px(img, 11, 24, OUTLINE)


# ═══════════════════════════════════════════════════
# 主角背面（16x32 像素）
# ═══════════════════════════════════════════════════

static func _gen_player_back(variant: int) -> ImageTexture:
	"""主角背面：只能看到头发、背部、裤子、鞋子"""
	var img := Image.create(16, 32, false, Image.FORMAT_RGBA8)
	img.fill(Color.TRANSPARENT)
	
	# ── 头发（背面：更饱满，看不到脸） ──
	fill_rect(img, 5, 0, 6, 4, PALETTE["hair_main"])
	fill_rect(img, 4, 1, 8, 5, PALETTE["hair_main"])
	fill_rect(img, 3, 3, 2, 4, PALETTE["hair_main"])
	fill_rect(img, 11, 3, 2, 4, PALETTE["hair_main"])
	# 高光
	fill_rect(img, 6, 1, 4, 2, PALETTE["hair_highlight"])
	# 发尾
	set_px(img, 3, 7, PALETTE["hair_main"])
	set_px(img, 12, 7, PALETTE["hair_main"])
	
	# ── 脖子 ──
	fill_rect(img, 6, 8, 4, 1, PALETTE["skin_dark"])
	
	# ── 背部（衬衫背面） ──
	fill_rect(img, 5, 9, 6, 8, PALETTE["shirt_mid"])
	# 背部褶皱
	set_px(img, 6, 11, PALETTE["shirt_dark"])
	set_px(img, 9, 12, PALETTE["shirt_dark"])
	set_px(img, 7, 14, PALETTE["shirt_highlight"])
	
	# ── 手臂（背面：只露出手臂外侧） ──
	fill_rect(img, 3, 10, 2, 5, PALETTE["shirt_mid"])
	fill_rect(img, 11, 10, 2, 5, PALETTE["shirt_mid"])
	# 袖口
	set_px(img, 3, 15, PALETTE["skin_dark"])
	set_px(img, 12, 15, PALETTE["skin_dark"])
	
	# ── 裤子 ──
	match variant:
		0:
			fill_rect(img, 5, 17, 6, 8, PALETTE["pants_mid"])
			fill_rect(img, 4, 18, 8, 7, PALETTE["pants_mid"])
			# 后口袋
			set_px(img, 5, 19, PALETTE["pants_dark"])
			set_px(img, 10, 19, PALETTE["pants_dark"])
		1:
			fill_rect(img, 5, 17, 6, 8, PALETTE["pants_mid"])
			fill_rect(img, 3, 18, 5, 7, PALETTE["pants_mid"])
			fill_rect(img, 9, 18, 4, 7, PALETTE["pants_dark"])
		2:
			fill_rect(img, 5, 17, 6, 8, PALETTE["pants_mid"])
			fill_rect(img, 3, 18, 4, 7, PALETTE["pants_dark"])
			fill_rect(img, 8, 18, 5, 7, PALETTE["pants_mid"])
	
	# ── 鞋子 ──
	fill_rect(img, 4, 25, 3, 2, PALETTE["shoes"])
	fill_rect(img, 9, 25, 3, 2, PALETTE["shoes"])
	
	# ── 轮廓 ──
	_draw_outline_back(img)
	return _to_texture(img)


static func _draw_outline_back(img: Image) -> void:
	set_px(img, 5, 0, OUTLINE); set_px(img, 6, 0, OUTLINE); set_px(img, 7, 0, OUTLINE)
	set_px(img, 8, 0, OUTLINE); set_px(img, 9, 0, OUTLINE); set_px(img, 10, 0, OUTLINE)
	set_px(img, 4, 1, OUTLINE); set_px(img, 11, 1, OUTLINE)
	set_px(img, 3, 2, OUTLINE); set_px(img, 12, 2, OUTLINE)
	set_px(img, 3, 3, OUTLINE); set_px(img, 12, 3, OUTLINE)
	set_px(img, 2, 4, OUTLINE); set_px(img, 13, 4, OUTLINE)
	set_px(img, 2, 5, OUTLINE); set_px(img, 13, 5, OUTLINE)
	set_px(img, 2, 6, OUTLINE); set_px(img, 13, 6, OUTLINE)
	set_px(img, 2, 7, OUTLINE); set_px(img, 13, 7, OUTLINE)
	set_px(img, 3, 8, OUTLINE); set_px(img, 12, 8, OUTLINE)
	set_px(img, 4, 9, OUTLINE); set_px(img, 11, 9, OUTLINE)
	set_px(img, 2, 10, OUTLINE); set_px(img, 13, 10, OUTLINE)
	set_px(img, 2, 11, OUTLINE); set_px(img, 13, 11, OUTLINE)
	set_px(img, 2, 12, OUTLINE); set_px(img, 13, 12, OUTLINE)
	set_px(img, 2, 13, OUTLINE); set_px(img, 13, 13, OUTLINE)
	set_px(img, 2, 14, OUTLINE); set_px(img, 13, 14, OUTLINE)
	set_px(img, 3, 15, OUTLINE); set_px(img, 12, 15, OUTLINE)
	set_px(img, 3, 16, OUTLINE); set_px(img, 12, 16, OUTLINE)
	set_px(img, 3, 17, OUTLINE); set_px(img, 12, 17, OUTLINE)
	set_px(img, 3, 18, OUTLINE); set_px(img, 12, 18, OUTLINE)
	set_px(img, 3, 19, OUTLINE); set_px(img, 12, 19, OUTLINE)
	set_px(img, 3, 20, OUTLINE); set_px(img, 12, 20, OUTLINE)
	set_px(img, 3, 21, OUTLINE); set_px(img, 12, 21, OUTLINE)
	set_px(img, 3, 22, OUTLINE); set_px(img, 12, 22, OUTLINE)
	set_px(img, 4, 24, OUTLINE); set_px(img, 5, 24, OUTLINE); set_px(img, 6, 24, OUTLINE)
	set_px(img, 9, 24, OUTLINE); set_px(img, 10, 24, OUTLINE); set_px(img, 11, 24, OUTLINE)


# ═══════════════════════════════════════════════════
# 主角侧面（16x32 像素）
# ═══════════════════════════════════════════════════

static func _gen_player_side(variant: int, is_left: bool) -> ImageTexture:
	"""主角侧面：左/右
	variant: 0=站, 1=走"""
	var img := Image.create(16, 32, false, Image.FORMAT_RGBA8)
	img.fill(Color.TRANSPARENT)
	
	# 水平翻转处理（画左面，右面 = 水平翻转）
	var flip := not is_left
	
	# ── 头发 ──
	fill_rect(img, 6, 0, 5, 3, PALETTE["hair_main"])
	fill_rect(img, 5, 1, 7, 5, PALETTE["hair_main"])
	fill_rect(img, 7, 1, 3, 2, PALETTE["hair_highlight"])
	# 侧面鬓角
	set_px(img, 5, 4, PALETTE["hair_main"])
	set_px(img, 5, 5, PALETTE["hair_main"])
	set_px(img, 5, 6, PALETTE["hair_main"])
	
	# ── 脸（侧脸） ──
	fill_rect(img, 6, 4, 5, 6, PALETTE["skin_light"])
	fill_rect(img, 5, 5, 6, 5, PALETTE["skin_light"])
	# 侧脸轮廓阴影
	set_px(img, 5, 7, PALETTE["skin_dark"])
	set_px(img, 5, 8, PALETTE["skin_dark"])
	
	# ── 眼睛（侧面：单只眼，2x2） ──
	set_px(img, 8, 6, PALETTE["eye_highlight"])
	set_px(img, 9, 6, PALETTE["eye_white"])
	set_px(img, 8, 7, PALETTE["eye_white"])
	set_px(img, 9, 7, PALETTE["eye_white"])
	# 眉毛
	set_px(img, 8, 5, PALETTE["hair_main"])
	set_px(img, 9, 5, PALETTE["hair_main"])
	
	# ── 嘴巴 ──
	set_px(img, 7, 9, PALETTE["mouth"])
	
	# ── 身体（侧面） ──
	fill_rect(img, 6, 10, 5, 8, PALETTE["shirt_mid"])
	# 衬衫褶皱
	set_px(img, 7, 12, PALETTE["shirt_dark"])
	set_px(img, 8, 14, PALETTE["shirt_dark"])
	
	# ── 手臂（侧面：一只手臂可见） ──
	fill_rect(img, 4, 11, 2, 6, PALETTE["skin_light"])
	# 袖子
	set_px(img, 4, 10, PALETTE["shirt_dark"])
	set_px(img, 5, 10, PALETTE["shirt_mid"])
	# 手
	set_px(img, 4, 17, PALETTE["skin_dark"])
	
	# ── 裤子 ──
	match variant:
		0:
			fill_rect(img, 6, 18, 5, 8, PALETTE["pants_mid"])
			# 裤缝
			set_px(img, 7, 20, PALETTE["pants_dark"])
			set_px(img, 7, 22, PALETTE["pants_dark"])
		1:
			fill_rect(img, 6, 18, 5, 8, PALETTE["pants_mid"])
			# 走路时的弯曲
			set_px(img, 5, 21, PALETTE["pants_dark"])
			set_px(img, 8, 23, PALETTE["pants_light"])
	
	# ── 鞋子 ──
	fill_rect(img, 6, 26, 3, 2, PALETTE["shoes"])
	set_px(img, 7, 26, PALETTE["shoes_light"])
	
	# ── 轮廓 ──
	_draw_outline_side(img)
	
	if flip:
		img.flip_x()
	
	return _to_texture(img)


static func _draw_outline_side(img: Image) -> void:
	set_px(img, 6, 0, OUTLINE); set_px(img, 7, 0, OUTLINE); set_px(img, 8, 0, OUTLINE); set_px(img, 9, 0, OUTLINE); set_px(img, 10, 0, OUTLINE)
	set_px(img, 5, 1, OUTLINE); set_px(img, 11, 1, OUTLINE)
	set_px(img, 4, 2, OUTLINE); set_px(img, 11, 2, OUTLINE)
	set_px(img, 4, 3, OUTLINE); set_px(img, 11, 3, OUTLINE)
	set_px(img, 4, 4, OUTLINE); set_px(img, 11, 4, OUTLINE)
	set_px(img, 4, 5, OUTLINE); set_px(img, 10, 5, OUTLINE)
	set_px(img, 4, 6, OUTLINE); set_px(img, 10, 6, OUTLINE)
	set_px(img, 4, 7, OUTLINE); set_px(img, 10, 7, OUTLINE)
	set_px(img, 4, 8, OUTLINE); set_px(img, 10, 8, OUTLINE)
	set_px(img, 5, 9, OUTLINE); set_px(img, 9, 9, OUTLINE)
	set_px(img, 3, 10, OUTLINE); set_px(img, 10, 10, OUTLINE)
	set_px(img, 3, 11, OUTLINE); set_px(img, 10, 11, OUTLINE)
	set_px(img, 3, 12, OUTLINE); set_px(img, 10, 12, OUTLINE)
	set_px(img, 3, 13, OUTLINE); set_px(img, 10, 13, OUTLINE)
	set_px(img, 3, 14, OUTLINE); set_px(img, 10, 14, OUTLINE)
	set_px(img, 3, 15, OUTLINE); set_px(img, 10, 15, OUTLINE)
	set_px(img, 4, 16, OUTLINE); set_px(img, 10, 16, OUTLINE)
	set_px(img, 5, 17, OUTLINE); set_px(img, 10, 17, OUTLINE)
	set_px(img, 5, 18, OUTLINE); set_px(img, 10, 18, OUTLINE)
	set_px(img, 5, 19, OUTLINE); set_px(img, 10, 19, OUTLINE)
	set_px(img, 5, 20, OUTLINE); set_px(img, 10, 20, OUTLINE)
	set_px(img, 5, 21, OUTLINE); set_px(img, 10, 21, OUTLINE)
	set_px(img, 5, 22, OUTLINE); set_px(img, 10, 22, OUTLINE)
	set_px(img, 6, 25, OUTLINE); set_px(img, 7, 25, OUTLINE); set_px(img, 8, 25, OUTLINE)


# ═══════════════════════════════════════════════════
# 廖芳绘制（16x32 像素）— 升级版
# ═══════════════════════════════════════════════════

static func _gen_liaofang(variant: int) -> ImageTexture:
	"""廖芳正面：粉色上衣 + 米色裙子"""
	var img := Image.create(16, 32, false, Image.FORMAT_RGBA8)
	img.fill(Color.TRANSPARENT)
	
	# ── 头发 ──
	fill_rect(img, 4, 0, 8, 3, PALETTE["hair_main"])
	fill_rect(img, 3, 1, 10, 5, PALETTE["hair_main"])
	fill_rect(img, 5, 1, 6, 2, PALETTE["hair_highlight"])
	# 长发
	fill_rect(img, 2, 4, 2, 6, PALETTE["hair_main"])
	fill_rect(img, 12, 4, 2, 6, PALETTE["hair_main"])
	# 刘海
	fill_rect(img, 5, 3, 3, 1, PALETTE["hair_main"])
	fill_rect(img, 8, 3, 2, 1, PALETTE["hair_main"])
	
	# ── 脸 ──
	fill_rect(img, 4, 4, 8, 6, PALETTE["skin_light"])
	fill_rect(img, 3, 6, 10, 4, PALETTE["skin_light"])
	
	# ── 眼睛 ──
	set_px(img, 5, 7, PALETTE["eye_highlight"])
	set_px(img, 6, 7, PALETTE["eye_white"])
	set_px(img, 5, 8, PALETTE["eye_white"])
	set_px(img, 6, 8, PALETTE["eye_white"])
	set_px(img, 9, 7, PALETTE["eye_highlight"])
	set_px(img, 10, 7, PALETTE["eye_white"])
	set_px(img, 9, 8, PALETTE["eye_white"])
	set_px(img, 10, 8, PALETTE["eye_white"])
	# 眉毛
	set_px(img, 5, 6, PALETTE["hair_main"])
	set_px(img, 6, 6, PALETTE["hair_main"])
	set_px(img, 9, 6, PALETTE["hair_main"])
	set_px(img, 10, 6, PALETTE["hair_main"])
	
	# ── 腮红 ──
	set_px(img, 3, 9, PALETTE["blush"])
	set_px(img, 12, 9, PALETTE["blush"])
	
	# ── 嘴巴 ──
	set_px(img, 7, 10, PALETTE["mouth"])
	set_px(img, 8, 11, PALETTE["mouth"])
	
	# ── 身体（粉色上衣） ──
	fill_rect(img, 4, 11, 8, 6, PALETTE["pink_mid"])
	# 领口
	set_px(img, 3, 11, PALETTE["pink_dark"])
	set_px(img, 12, 11, PALETTE["pink_dark"])
	set_px(img, 7, 11, PALETTE["skin_dark"])
	set_px(img, 8, 11, PALETTE["skin_dark"])
	# 褶皱
	set_px(img, 5, 13, PALETTE["pink_dark"])
	set_px(img, 10, 14, PALETTE["pink_dark"])
	# 纽扣
	set_px(img, 7, 13, PALETTE["pink_highlight"])
	set_px(img, 8, 15, PALETTE["pink_highlight"])
	
	# ── 手臂 ──
	fill_rect(img, 2, 12, 2, 5, PALETTE["skin_light"])
	fill_rect(img, 12, 12, 2, 5, PALETTE["skin_light"])
	# 袖子
	set_px(img, 2, 11, PALETTE["pink_mid"])
	set_px(img, 3, 11, PALETTE["pink_dark"])
	set_px(img, 12, 11, PALETTE["pink_mid"])
	set_px(img, 13, 11, PALETTE["pink_dark"])
	
	# ── 裙子 ──
	match variant:
		0:
			fill_rect(img, 4, 17, 8, 8, PALETTE["skirt_mid"])
			set_px(img, 3, 18, PALETTE["skirt_light"])
			set_px(img, 12, 18, PALETTE["skirt_light"])
			set_px(img, 3, 21, PALETTE["skirt_light"])
			set_px(img, 12, 21, PALETTE["skirt_light"])
			# 裙摆褶皱
			set_px(img, 6, 19, PALETTE["skirt_dark"])
			set_px(img, 9, 20, PALETTE["skirt_dark"])
		1:
			fill_rect(img, 4, 17, 8, 8, PALETTE["skirt_mid"])
			set_px(img, 3, 18, PALETTE["skirt_light"])
			set_px(img, 12, 18, PALETTE["skirt_light"])
			set_px(img, 7, 22, PALETTE["skirt_dark"])
		2:
			fill_rect(img, 4, 17, 8, 8, PALETTE["skirt_mid"])
			set_px(img, 3, 18, PALETTE["skirt_light"])
			set_px(img, 12, 18, PALETTE["skirt_light"])
			set_px(img, 8, 22, PALETTE["skirt_dark"])
	
	# ── 鞋子 ──
	fill_rect(img, 4, 25, 3, 2, PALETTE["shoes"])
	fill_rect(img, 9, 25, 3, 2, PALETTE["shoes"])
	set_px(img, 5, 25, PALETTE["shoes_light"])
	set_px(img, 10, 25, PALETTE["shoes_light"])
	
	# ── 轮廓 ──
	_draw_outline_liaofang(img)
	return _to_texture(img)


static func _draw_outline_liaofang(img: Image) -> void:
	set_px(img, 3, 0, OUTLINE); set_px(img, 12, 0, OUTLINE)
	set_px(img, 2, 1, OUTLINE); set_px(img, 13, 1, OUTLINE)
	set_px(img, 2, 2, OUTLINE); set_px(img, 13, 2, OUTLINE)
	set_px(img, 2, 3, OUTLINE); set_px(img, 13, 3, OUTLINE)
	set_px(img, 1, 4, OUTLINE); set_px(img, 14, 4, OUTLINE)
	set_px(img, 1, 5, OUTLINE); set_px(img, 14, 5, OUTLINE)
	set_px(img, 1, 6, OUTLINE); set_px(img, 14, 6, OUTLINE)
	set_px(img, 1, 7, OUTLINE); set_px(img, 14, 7, OUTLINE)
	set_px(img, 1, 8, OUTLINE); set_px(img, 14, 8, OUTLINE)
	set_px(img, 1, 9, OUTLINE); set_px(img, 14, 9, OUTLINE)
	set_px(img, 3, 10, OUTLINE); set_px(img, 12, 10, OUTLINE)
	set_px(img, 1, 11, OUTLINE); set_px(img, 14, 11, OUTLINE)
	set_px(img, 1, 12, OUTLINE); set_px(img, 14, 12, OUTLINE)
	set_px(img, 1, 13, OUTLINE); set_px(img, 14, 13, OUTLINE)
	set_px(img, 1, 14, OUTLINE); set_px(img, 14, 14, OUTLINE)
	set_px(img, 1, 15, OUTLINE); set_px(img, 14, 15, OUTLINE)
	set_px(img, 3, 25, OUTLINE); set_px(img, 12, 25, OUTLINE)
	set_px(img, 4, 26, OUTLINE); set_px(img, 11, 26, OUTLINE)


# ═══════════════════════════════════════════════════
# 宠物绘制（16x16 像素）
# ═══════════════════════════════════════════════════

static func _gen_pet(variant: int) -> ImageTexture:
	"""小猫 sprite"""
	var img := Image.create(16, 16, false, Image.FORMAT_RGBA8)
	img.fill(Color.TRANSPARENT)
	
	# 身体
	fill_rect(img, 4, 6, 8, 5, Color("#e89050"))
	# 头部
	fill_rect(img, 5, 3, 6, 4, Color("#e89050"))
	# 耳朵
	set_px(img, 5, 2, Color("#e89050"))
	set_px(img, 10, 2, Color("#e89050"))
	set_px(img, 5, 1, Color("#d08040"))
	set_px(img, 10, 1, Color("#d08040"))
	# 眼睛
	set_px(img, 6, 5, Color("#f8f8f8"))
	set_px(img, 9, 5, Color("#f8f8f8"))
	# 鼻子
	set_px(img, 7, 6, Color("#f0a0a0"))
	set_px(img, 8, 6, Color("#f0a0a0"))
	# 尾巴
	set_px(img, 11, 4, Color("#e89050"))
	set_px(img, 12, 3, Color("#e89050"))
	# 腿
	set_px(img, 5, 11, Color("#d08040"))
	set_px(img, 10, 11, Color("#d08040"))
	
	# 轮廓
	set_px(img, 4, 3, OUTLINE); set_px(img, 11, 3, OUTLINE)
	set_px(img, 4, 2, OUTLINE); set_px(img, 11, 2, OUTLINE)
	
	return _to_texture(img)


# ═══════════════════════════════════════════════════
# 工具图标（16x16 像素）
# ═══════════════════════════════════════════════════

static func _gen_tool(tool_type: String) -> ImageTexture:
	var img := Image.create(16, 16, false, Image.FORMAT_RGBA8)
	img.fill(Color.TRANSPARENT)
	
	match tool_type:
		"hoe":
			# 木柄
			fill_rect(img, 7, 2, 2, 8, PALETTE["hoe_wood"])
			# 金属头
			fill_rect(img, 5, 10, 6, 3, PALETTE["hoe_metal"])
			set_px(img, 4, 11, PALETTE["hoe_metal"])
			set_px(img, 11, 11, PALETTE["hoe_metal"])
			# 轮廓
			for y in range(2, 10):
				set_px(img, 6, y, OUTLINE); set_px(img, 9, y, OUTLINE)
			for x in range(4, 12):
				set_px(img, x, 10, OUTLINE); set_px(img, x, 13, OUTLINE)
			set_px(img, 3, 11, OUTLINE); set_px(img, 12, 11, OUTLINE)
		
		"watering_can":
			# 壶身
			fill_rect(img, 4, 6, 8, 6, PALETTE["can_body"])
			# 壶嘴
			fill_rect(img, 10, 4, 4, 2, PALETTE["can_body"])
			# 把手
			set_px(img, 3, 7, PALETTE["can_body"])
			set_px(img, 3, 8, PALETTE["can_body"])
			set_px(img, 3, 9, PALETTE["can_body"])
			# 水
			set_px(img, 13, 5, PALETTE["water"])
			set_px(img, 14, 5, PALETTE["water"])
			# 轮廓
			for x in range(4, 12):
				set_px(img, x, 6, OUTLINE); set_px(img, x, 12, OUTLINE)
			for y in range(6, 12):
				set_px(img, 3, y, OUTLINE); set_px(img, 11, y, OUTLINE)
			set_px(img, 2, 7, OUTLINE); set_px(img, 2, 9, OUTLINE)
			set_px(img, 12, 4, OUTLINE); set_px(img, 13, 4, OUTLINE)
			set_px(img, 12, 5, OUTLINE)
	
	return _to_texture(img)


# ═══════════════════════════════════════════════════
# 旧 API 兼容函数
# ═══════════════════════════════════════════════════

static func generate_player_sprite(direction: String, frame: int) -> ImageTexture:
	match direction:
		"up":    return generate("player_back", frame)
		"down":  return generate("player", frame)
		"left":  return generate("player_left", frame)
		"right": return generate("player_right", frame)
	return generate("player", frame)

static func create(tile_type, variant: int = 0):
	if typeof(tile_type) == TYPE_STRING:
		return generate(tile_type, variant)
	elif typeof(tile_type) == TYPE_INT:
		var w := tile_type as int
		var h := variant
		var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
		img.fill(Color.TRANSPARENT)
		for x in range(w):
			img.set_pixel(x, 0, OUTLINE)
			img.set_pixel(x, h-1, OUTLINE)
		for y in range(h):
			img.set_pixel(0, y, OUTLINE)
			img.set_pixel(w-1, y, OUTLINE)
		return ImageTexture.create_from_image(img)
	return generate("player", 0)

static func generate_tile(type: String, variant: int = 0) -> ImageTexture:
	return generate(type, variant)

static func p(img: Image, x: int, y: int, c: Color) -> void:
	if x >= 0 and x < img.get_width() and y >= 0 and y < img.get_height():
		img.set_pixel(x, y, c)

static func r(img: Image, x: int, y: int, w: int, h: int, c: Color) -> void:
	for py in range(y, y + h):
		for px in range(x, x + w):
			if px >= 0 and px < img.get_width() and py >= 0 and py < img.get_height():
				img.set_pixel(px, py, c)

static func to_tex(img: Image) -> ImageTexture:
	return ImageTexture.create_from_image(img)

static func generate_pet_sprite(frame: int = 0) -> ImageTexture:
	return generate("pet", frame)

static func generate_liaofang_sprite(direction: String, frame: int) -> ImageTexture:
	return generate("liaofang", frame)

static func generate_crop_sprite(stage: int, crop_type: String) -> ImageTexture:
	var img := Image.create(16, 16, false, Image.FORMAT_RGBA8)
	img.fill(Color.TRANSPARENT)
	var c := Color("#58a040") if stage > 2 else Color("#80c060") if stage > 0 else Color("#90d870")
	r(img, 2, 10 - stage, 12, 2 + stage * 2, c)
	return to_tex(img)

static func generate_item_icon(item_id: String) -> ImageTexture:
	var img := Image.create(16, 16, false, Image.FORMAT_RGBA8)
	img.fill(Color.TRANSPARENT)
	r(img, 1, 1, 14, 14, Color("#886846"))
	return to_tex(img)

static func generate_npc_sprite(npc_id: String, direction: String, frame: int) -> ImageTexture:
	if npc_id == "liaofang":
		return generate("liaofang", frame)
	return generate("player", frame)
