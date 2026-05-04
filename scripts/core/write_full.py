# This script writes the complete pixel_artist.gd file
# Using Python to avoid tool truncation limits

import os

path = r'D:\龙虾\projects\stardew-liaofang\scripts\core\pixel_artist.gd'

content = r"""# PixelArtist — 像素素材生成器（星露谷物语完全复刻版）增强画质版
# 瓦片 16×16 → 2x → 32×32，角色 16×32 源 → 2x → 32×64
# 所有函数签名与原始版本完全兼容
extends Node

# ═══════════════════════════════════
# 🎨 调色板（增强版：4-5级渐变）
# ═══════════════════════════════════
const PALETTE = {
	g_dd = Color("#3a6624"), g_d = Color("#46732e"), g = Color("#5c8f3c"),
	g_l = Color("#6ca048"), g_ll = Color("#7cb854"), g_s = Color("#8fc868"),
	g_n = Color("#3d6624"), g_hl = Color("#90d070"),
	d_dd = Color("#604830"), d_d = Color("#78583c"), d = Color("#886846"),
	d_l = Color("#987854"), d_ll = Color("#a88862"),
	d_w = Color("#5a4a30"), d_hl = Color("#b89870"),
	w_dd = Color("#1a5080"), w_d = Color("#2a6090"), w = Color("#3870a0"),
	w_l = Color("#4880b0"), w_f = Color("#68a8d0"), w_w = Color("#5898c0"),
	w_g = Color("#88c0e0"), w_hl = Color("#a0d0f0"),
	wd = Color("#4a3020"), wl = Color("#5a3a2a"), wb = Color("#7a5a4a"),
	r = Color("#3a2010"), r_l = Color("#4a3020"), r_d = Color("#2a1810"),
	db = Color("#5a3a2a"), dd = Color("#3a2010"),
	p_dd = Color("#786848"), p_d = Color("#887858"), p = Color("#988868"),
	p_l = Color("#a89878"), p_s = Color("#a09070"), p_h = Color("#b8a888"),
	p_hl = Color("#c8b898"),
	f_pk = Color("#e86888"), f_rs = Color("#e088a0"), f_pe = Color("#e8a878"),
	f_y = Color("#e8c040"), f_yd = Color("#d0a830"), f_r = Color("#c46858"),
	f_b = Color("#6888c0"), f_bd = Color("#5070a8"), f_pu = Color("#9860c0"),
	f_o = Color("#e88808"), f_w = Color("#e0e0d8"), f_pk_l = Color("#f088a8"),
	s_d = Color("#d0a880"), s = Color("#e8c8a0"), s_s = Color("#d8b890"),
	s_l = Color("#f0d8b0"), s_ll = Color("#f8e8d0"), s_b = Color("#e8a090"),
	s_rs = Color("#f0b090"),
	h_brd = Color("#2a1a10"), h_br = Color("#3a2a1a"), h_brl = Color("#4a3a28"),
	h_bl = Color("#5a4a38"), h_bll = Color("#6a5a48"),
	h_bk = Color("#18180a"), h_bkl = Color("#282818"), h_bkg = Color("#383828"),
	h_kl = Color("#282818"), h_kll = Color("#383828"),
	h_yd = Color("#c09840"), h_yl = Color("#c8a850"), h_yll = Color("#d8b860"),
	h_a = Color("#683828"),
	e_d = Color("#18182c"), e_b = Color("#3878b0"), e_g = Color("#488838"),
	e_h = Color("#e8e8e8"), e_hl = Color("#ffffff"),
	pl_b = Color("#4888d0"), pl_s = Color("#3878b8"), pl_l = Color("#5898e0"),
	pl_ll = Color("#68a8f0"),
	je = Color("#385888"), je_s = Color("#284878"), je_l = Color("#4870a0"),
	l_pk = Color("#e86888"), l_ps = Color("#d05878"), l_pkl = Color("#f088a8"),
	l_sk = Color("#e06078"), l_sh = Color("#e8a878"),
	l_pk_l = Color("#f098b0"), l_sk_l = Color("#f07090"),
	fn = Color("#887044"), fnd = Color("#685030"), fnl = Color("#988054"),
	fn_hl = Color("#a89060"),
	tk = Color("#583828"), tkd = Color("#382818"), tkl = Color("#684838"),
	tk_l = Color("#785848"),
	lf_dd = Color("#185818"), lf_d = Color("#286828"), lf = Color("#387830"),
	lf_l = Color("#488840"), lf_ll = Color("#589850"), lf_s = Color("#68a860"),
	lf_hl = Color("#78c060"),
	gt = Color("#d0a858"), gb = Color("#d8c040"), gs = Color("#e8d060"),
	gt_d = Color("#b88840"),
	hr = Color("#e82850"), hr_l = Color("#f04868"),
	st = Color("#e8c830"),
	h_rd = Color("#683020"), h_r = Color("#884030"), h_rl = Color("#a05040"),
	h_gn = Color("#386828"), h_gnl = Color("#488838"),
	h_pu = Color("#483868"), h_pul = Color("#584878"),
	sk_d = Color("#b85068"), sk_s = Color("#c85870"),
	gry_d = Color("#606060"), gry = Color("#808080"), gry_l = Color("#a0a0a0"),
	gry_ll = Color("#c0c0c0"), wh = Color("#f0f0f0"),
	ch_d = Color("#2a2a2a"), ch = Color("#3a3a3a"), ch_l = Color("#4a4a4a"),
	stl = Color("#c0c0c0"), stl_d = Color("#909090"), stl_l = Color("#e0e0e0"),
	gold_bar = Color("#d8c040"), gold_bar_d = Color("#b8a030"),
	egg_shell = Color("#f0e8d0"), egg_wh = Color("#faf0e0"),
	blush = Color(0.8, 0.3, 0.35, 0.4),
}

static func create(w: int, h: int) -> Image:
	var img = Image.create(w, h, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	return img

static func r(img: Image, x: int, y: int, w: int, h: int, c: Color):
	for py in range(y, y + h):
		for px in range(x, x + w):
			if px >= 0 and px < img.get_width() and py >= 0 and py < img.get_height():
				img.set_pixel(px, py, c)

static func p(img: Image, x: int, y: int, c: Color):
	if x >= 0 and x < img.get_width() and y >= 0 and y < img.get_height():
		img.set_pixel(x, y, c)

static func circ(img: Image, cx: int, cy: int, r: int, c: Color):
	for y in range(-r, r + 1):
		for x in range(-r, r + 1):
			if x*x + y*y <= r*r:
				p(img, cx + x, cy + y, c)

static func fcirc(img: Image, cx: int, cy: int, r: int, c: Color):
	for y in range(-r, r + 1):
		for x in range(-r, r + 1):
			if x*x + y*y <= r*r:
				p(img, cx + x, cy + y, c)

static func to_tex(img: Image) -> ImageTexture:
	return ImageTexture.create_from_image(img)

static func _darker(c: Color, f: float = 0.25) -> Color:
	return Color(c.r * (1.0 - f), c.g * (1.0 - f), c.b * (1.0 - f), c.a)

static func _lighter(c: Color, f: float = 0.25) -> Color:
	return Color(c.r + (1.0 - c.r) * f, c.g + (1.0 - c.g) * f, c.b + (1.0 - c.b) * f, c.a)

static func _hline(img: Image, x1: int, x2: int, y: int, c: Color):
	for x in range(min(x1, x2), max(x1, x2) + 1):
		p(img, x, y, c)

static func _vline(img: Image, x: int, y1: int, y2: int, c: Color):
	for y in range(min(y1, y2), max(y1, y2) + 1):
		p(img, x, y, c)

static func _line(img: Image, x1: int, y1: int, x2: int, y2: int, c: Color):
	var dx = abs(x2 - x1)
	var dy = -abs(y2 - y1)
	var sx = 1 if x1 < x2 else -1
	var sy = 1 if y1 < y2 else -1
	var err = dx + dy
	var cx = x1
	var cy = y1
	while true:
		p(img, cx, cy, c)
		if cx == x2 and cy == y2:
			break
		var e2 = 2 * err
		if e2 >= dy:
			err += dy
			cx += sx
		if e2 <= dx:
			err += dx
			cy += sy

# ═══════════════════════════════════
# 🏞️ 瓦片（16×16 → 2x upscale to 32×32）
# ═══════════════════════════════════

static func generate_tile(type: String, v: int = 0) -> ImageTexture:
	var src = create(16, 16)
	match type:
		"grass": _tg(src, v)
		"dirt": _td(src, v)
		"water": _tw(src, v)
		"path": _tp(src, v)
		"flower_bed": _tf(src, v)
		"fence": _tfn(src)
		"house_wall": _twall(src)
		"house_roof": _troof(src)
		"door": _tdoor(src)
		"tree": _tt(src, v)
	return _upscale2x(src, 32, 32)

# ─── Grass Tile ────────────────────
static func _tg(img: Image, v: int):
	r(img, 0, 0, 16, 16, PALETTE.g)
	var seed = v * 7 + 3
	for i in range(30):
		var px = (i * 9 + seed * 11) % 14 + 1
		var py = (i * 11 + seed * 7) % 14 + 1
		var c = PALETTE.g_n if (i + v) % 4 == 0 else (PALETTE.g_d if (i + v) % 3 == 0 else PALETTE.g_dd)
		p(img, px, py, c)
		if i % 3 == 0:
			p(img, px + 1, py, c)
	for i in range(10):
		var gx = 1 + (i * 7 + v * 3) % 14
		var gy = 8 + (i * 5 + v * 7) % 6
		var gc_arr = [PALETTE.g_s, PALETTE.g_l, PALETTE.g_ll, PALETTE.g_hl, PALETTE.g_s, PALETTE.g_l, PALETTE.g_ll, PALETTE.g_s, PALETTE.g_l, PALETTE.g_hl]
		p(img, gx, gy, gc_arr[i])
		p(img, gx, gy - 1, gc_arr[i])
		if i % 2 == 0:
			p(img, gx + 1, gy - 1, gc_arr[i])
		if i % 3 == 1:
			p(img, gx, gy - 2, gc_arr[i])
	if v % 2 == 0:
		var fx1 = (v * 3) % 14 + 1
		var fy1 = (v * 7) % 14 + 1
		p(img, fx1, fy1, PALETTE.f_pk)
		p(img, fx1 + 1, fy1, PALETTE.f_pk_l)
		p(img, fx1, fy1 - 1, PALETTE.f_pk_l)
	if v % 3 == 0:
		var fx2 = (v * 5 + 7) % 14 + 1
		var fy2 = (v * 11 + 3) % 14 + 1
		p(img, fx2, fy2, PALETTE.f_y)
		p(img, fx2 - 1, fy2, PALETTE.f_yd)
	if v % 5 == 0:
		var fx3 = (v * 13 + 2) % 14 + 1
		var fy3 = (v * 3 + 9) % 14 + 1
		p(img, fx3, fy3, PALETTE.f_w)
		p(img, fx3 + 1, fy3 + 1, PALETTE.f_w)

# ─── Tilled Dirt Tile ──────────────
static func _td(img: Image, v: int):
	r(img, 0, 0, 16, 16, PALETTE.d_dd)
	var seed = v * 7 + 13
	for i in range(14):
		var cx = (i * 9 + seed) % 14 + 1
		var cy = (i * 11 + seed * 2) % 14 + 1
		var c_arr = [PALETTE.d, PALETTE.d_l, PALETTE.d, PALETTE.d_ll, PALETTE.d_l, PALETTE.d, PALETTE.d_l, PALETTE.d_ll, PALETTE.d, PALETTE.d_l, PALETTE.d, PALETTE.d_ll, PALETTE.d_l, PALETTE.d]
		p(img, cx, cy, c_arr[i])
		if i % 2 == 0:
			p(img, cx + 1, cy, c_arr[i])
		if i % 4 == 0:
			p(img, cx, cy + 1, c_arr[i])
	for i in range(6):
		var px = (i * 13 + seed * 3) % 14 + 1
		var py = (i * 17 + seed * 5) % 14 + 1
		var pc = PALETTE.d_w if i % 2 == 0 else PALETTE.d_hl
		p(img, px, py, pc)
		p(img, px + 1, py, pc)
	for i in range(3):
		var sx = (i * 19 + seed * 7) % 14 + 1
		var sy = (i * 23 + seed * 11) % 14 + 1
		p(img, sx, sy, PALETTE.p_h)
		p(img, sx + 1, sy, PALETTE.p_h)
	r(img, 0, 15, 16, 1, _darker(PALETTE.d_dd, 0.2))
	r(img, 15, 0, 1, 16, _darker(PALETTE.d_dd, 0.2))
	for x in range(0, 16, 1):
		p(img, x, 14, _darker(PALETTE.d_dd, 0.08))
		p(img, x, 15, _darker(PALETTE.d_dd, 0.25))
	if v % 2 == 0:
		var rx = 2 + (v * 3) % 12
		var ry = 3 + (v * 5) % 10
		r(img, rx, ry, 1, 5, PALETTE.d_w)
		r(img, rx + 1, ry + 2, 1, 3, PALETTE.d_w)
	else:
		var rx = 7 + (v * 7) % 7
		var ry = 2 + (v * 9) % 10
		r(img, rx, ry, 1, 4, PALETTE.d_w)
		r(img, rx - 1, ry + 1, 1, 2, PALETTE.d_w)

# ─── Path Tile ─────────────────────
static func _tp(img: Image, v: int):
	r(img, 0, 0, 16, 16, PALETTE.p_dd)
	var stones = [
		[1,1,5,4],[7,1,7,3],[3,5,5,5],[10,5,5,3],
		[1,10,5,4],[7,10,7,3],[12,9,3,5],[4,14,8,2],
		[1,14,3,2],[14,1,2,3],[10,0,4,2],[0,5,3,3],
		[2,5,2,2],[13,6,2,3]
	]
	for s in stones:
		var col_arr = [PALETTE.p, PALETTE.p_l, PALETTE.p_s, PALETTE.p, PALETTE.p_h, PALETTE.p_l]
		var col = col_arr[(s[0] + s[1] + v) % col_arr.size()]
		r(img, s[0], s[1], s[2], s[3], col)
		p(img, s[0] + 1, s[1] + 1, PALETTE.p_hl)
		p(img, s[0], s[1], _lighter(col, 0.1))
	for i in range(8):
		var gx = (i * 9 + v * 5) % 14
		var gy = (i * 13 + v * 3) % 14
		var c = PALETTE.d_w if (i + v) % 3 == 0 else (PALETTE.p_dd if i % 2 == 0 else PALETTE.p_hl)
		r(img, gx, gy, 2, 1, c)
		if i % 2 == 0:
			r(img, gx, gy + 1, 1, 2, c)
		if i % 3 == 0:
			r(img, gx + 2, gy, 1, 2, c)
	for i in range(4):
		var mx = (i * 17 + v * 3) % 14 + 1
		var my = (i * 19 + v * 7) % 14 + 1
		p(img, mx, my, PALETTE.g_n)
		if i % 2 == 0:
			p(img, mx + 1, my, PALETTE.g_d)

# ─── Water Tile ────────────────────
static func _tw(img: Image, v: int):
	r(img, 0, 0, 16, 16, PALETTE.w_dd)
	for y in range(16):
		var t = float(y) / 15.0
		var c = Color(
			PALETTE.w_dd.r + (PALETTE.w_d.r - PALETTE.w_dd.r) * t,
			PALETTE.w_dd.g + (PALETTE.w_d.g - PALETTE.w_dd.g) * t,
			PALETTE.w_dd.b + (PALETTE.w_d.b - PALETTE.w_dd.b) * t, 1.0
		)
		for x in range(16):
			var dx = (x + v) % 4
			var mod = 0.02 if dx < 2 else -0.02
			p(img, x, y, Color(c.r + mod, c.g + mod, c.b + mod, 1.0))
	var wave_rows = [3, 6, 9, 12, 14]
	var wave_cols = [PALETTE.w, PALETTE.w_l, PALETTE.w_f, PALETTE.w_hl, PALETTE.w_l]
	for wi in range(wave_rows.size()):
		var wy = wave_rows[wi] + (v % 2) * (wi % 2)
		var wc = wave_cols[wi]
		for x in range(0, 16, 3):
			var xoff = (v + wi * 2) % 3
			r(img, x + xoff, wy, 2, 1, wc)
			if wi >= 3:
				p(img, x + xoff + 1, wy + 1, _darker(wc, 0.3))
	var sparkle = Color(1, 1, 1, 0.5)
	var sparkle_b = Color(1, 1, 1, 0.35)
	var spos = [[2,2],[14,4],[5,12],[13,10],[8,1],[3,9],[10,14],[1,7]]
	for i in range(6):
		var idx = (v + i * 5) % spos.size()
		var sx = spos[idx][0] + (v % 2)
		var sy = spos[idx][1] + (v % 3)
		p(img, sx, sy, sparkle)
		p(img, sx + 1, sy, sparkle_b)
		if i % 2 == 0:
			p(img, sx, sy + 1, sparkle_b)
	for x in range(0, 16, 1):
		p(img, x, 14, _darker(PALETTE.w_dd, 0.1))
		p(img, x, 15, _darker(PALETTE.w_dd, 0.25))

# ─── Flower Bed Tile ───────────────
static func _tf(img: Image, v: int):
	r(img, 0, 0, 16, 16, PALETTE.g)
	for i in range(20):
		var px = (i * 9 + v * 7) % 14 + 1
		var py = (i * 11 + v * 3) % 14 + 1
		p(img, px, py, PALETTE.g_n if i % 3 == 0 else PALETTE.g_d)
	for i in range(6):
		var gx = 1 + (i * 7 + v * 3) % 14
		var gy = 8 + (i * 5) % 6
		p(img, gx, gy, PALETTE.g_s)
		p(img, gx, gy - 1, PALETTE.g_hl)
	var fc = [PALETTE.f_pk, PALETTE.f_rs, PALETTE.f_y, PALETTE.f_pe, PALETTE.f_b, PALETTE.f_pu, PALETTE.f_o, PALETTE.f_r, PALETTE.f_w]
	var positions = [[3,3],[11,3],[3,11],[11,11],[7,7],[1,7],[15,7],[7,1],[7,15]]
	var used = 5 + (v % 4)
	for i in range(used):
		var idx = (v + i * 3) % positions.size()
		var px = positions[idx][0]
		var py = positions[idx][1]
		var col = fc[(v + i) % fc.size()]
		p(img, px, py, col)
		p(img, px + 1, py, col)
		p(img, px, py + 1, col)
		p(img, px + 1, py + 1, col)
		p(img, px, py, PALETTE.f_y)
		p(img, px + 1, py + 1, _lighter(col, 0.2))

# ─── Fence ─────────────────────────
static func _tfn(img: Image):
	r(img, 0, 0, 16, 16, PALETTE.fnd)
	r(img, 0, 5, 16, 2, PALETTE.fnd)
	r(img, 0, 5, 16, 1, PALETTE.fnl)
	r(img, 0, 12, 16, 2, PALETTE.fnd)
	r(img, 0, 12, 16, 1, PALETTE.fnl)
	for y in range(1, 16, 4):
		_hline(img, 2, 14, y, _darker(PALETTE.fnd, 0.15))
	r(img, 3, 0, 3, 16, PALETTE.fnd)
	r(img, 11, 0, 3, 16, PALETTE.fnd)
	_vline(img, 4, 2, 14, _darker(PALETTE.fnd, 0.1))
	_vline(img, 12, 2, 14, _darker(PALETTE.fnd, 0.1))
	circ(img, 4, 6, 1, PALETTE.gt_d)
	p(img, 4, 6, PALETTE.gt)
	p(img, 12, 6, PALETTE.gt)
	p(img, 4, 13, PALETTE.gt)
	p(img, 12, 13, PALETTE.gt)
	p(img, 4, 5, PALETTE.gs)
	p(img, 12, 5, PALETTE.gs)
	p(img, 4, 12, PALETTE.gs)
	p(img, 12, 12, PALETTE.gs)
	_vline(img, 0, 0, 15, _darker(PALETTE.fnd, 0.3))
	_hline(img, 0, 15, 0, _darker(PALETTE.fnd, 0.3))
	r(img, 0, 15, 16, 1, _darker(PALETTE.fnd, 0.2))

# ─── House Wall ─────────────────────
static func _twall(img: Image):
	r(img, 0, 0, 16, 16, PALETTE.wl)
	r(img, 0, 0, 16, 2, PALETTE.wb)
	r(img, 15, 0, 1, 16, PALETTE.wb)
	for y in range(3, 16, 4):
		r(img, 0, y, 16, 1, PALETTE.wd)
	for y in range(0, 16, 4):
		for x in range(3, 16, 8):
			p(img, x, y + 3, PALETTE.wd)
	for y in range(2, 16, 4):
		for x in range(7, 16, 8):
			p(img, x, y + 3, PALETTE.wd)
	for i in range(4):
		var bx = (i * 7 + 2) % 14
		var by = (i * 5 + 3) % 12
		r(img, bx, by, 3, 2, PALETTE.db)
	r(img, 0, 15, 16, 1, _darker(PALETTE.wl, 0.2))

# ─── House Roof ─────────────────────
static func _troof(img: Image):
	r(img, 0, 0, 16, 16, PALETTE.r_d)
	r(img, 0, 0, 16, 2, PALETTE.r)
	_hline(img, 0, 15, 0, PALETTE.r_l)
	for y in range(3, 16, 3):
		r(img, 0, y, 16, 1, PALETTE.r)
		for x in range(0, 16, 6):
			p(img, x + 2, y, PALETTE.r_l)

# ─── Door ───────────────────────────
static func _tdoor(img: Image):
	r(img, 0, 0, 16, 16, PALETTE.db)
	r(img, 2, 1, 12, 14, PALETTE.dd)
	r(img, 3, 2, 10, 12, PALETTE.db)
	_vline(img, 5, 3, 13, PALETTE.dd)
	_vline(img, 11, 3, 13, PALETTE.dd)
	circ(img, 13, 8, 2, PALETTE.gt_d)
	fcirc(img, 13, 8, 1, PALETTE.gb)
	p(img, 13, 8, PALETTE.gs)
	p(img, 13, 7, PALETTE.gt)

# ─── Tree ───────────────────────────
static func _tt(img: Image, v: int):
	r(img, 6, 10, 4, 6, PALETTE.tk)
	r(img, 6, 8, 4, 3, PALETTE.tkd)
	r(img, 5, 14, 6, 2, PALETTE.tkl)
	_vline(img, 7, 10, 15, _darker(PALETTE.tk, 0.1))
	_vline(img, 9, 11, 14, PALETTE.tk_l)
	fcirc(img, 8, 5, 7, PALETTE.lf_dd)
	fcirc(img, 6, 2, 6, PALETTE.lf_d)
	fcirc(img, 10, 3, 6, PALETTE.lf)
	fcirc(img, 7, 4, 5, PALETTE.lf_l)
	fcirc(img, 9, 1, 5, PALETTE.lf_ll)
	fcirc(img, 8, 0, 4, PALETTE.lf_s)
	fcirc(img, 5, 1, 4, PALETTE.lf_hl)
	fcirc(img, 11, 1, 4, PALETTE.lf_hl)
	p(img, 5, 2, PALETTE.g_ll)
	p(img, 12, 2, PALETTE.g_ll)
	p(img, 7, 0, PALETTE.lf_s)
	p(img, 10, 0, PALETTE.lf_s)
	p(img, 4, 3, PALETTE.lf_hl)
	p(img, 13, 3, PALETTE.lf_hl)
	p(img, 6, 0, PALETTE.g_hl)
	p(img, 11, 0, PALETTE.g_hl)
	p(img, 3, 8, _darker(PALETTE.lf_dd, 0.3))
	p(img, 13, 8, _darker(PALETTE.lf_dd, 0.3))
	p(img, 4, 9, _darker(PALETTE.lf_dd, 0.3))
	p(img, 12, 9, _darker(PALETTE.lf_dd, 0.3))
"""

print(f"Tile section length: {len(content)}")

# Now the character sprites section
player_section = r"""
# ═══════════════════════════════════
# 👤 角色（16×32 → 2x → 32×64）
# ═══════════════════════════════════

static func generate_player_sprite(dir: String = "down", frame: int = 0) -> ImageTexture:
	var src = create(16, 32)
	var lo = 0
	if frame == 1: lo = 1
	elif frame == 3: lo = -1

	var outline = _darker(PALETTE.pl_b, 0.3)
	r(src, 4, 16, 1, 9, outline)
	r(src, 12, 16, 1, 9, outline)

	if frame == 0 or frame == 2:
		r(src, 6, 25, 2, 5, PALETTE.je)
		r(src, 9, 25, 2, 5, PALETTE.je)
		p(src, 6, 25, PALETTE.je_s)
		p(src, 8, 25, PALETTE.je_s)
		p(src, 11, 25, PALETTE.je_s)
		_vline(src, 7, 26, 29, PALETTE.je_l)
		_vline(src, 10, 26, 29, PALETTE.je_l)
		r(src, 5, 30, 3, 2, PALETTE.h_a)
		r(src, 9, 30, 3, 2, PALETTE.h_a)
		r(src, 5, 31, 3, 1, _darker(PALETTE.h_a, 0.2))
		r(src, 9, 31, 3, 1, _darker(PALETTE.h_a, 0.2))
		p(src, 5, 30, _lighter(PALETTE.h_a, 0.15))
		p(src, 9, 30, _lighter(PALETTE.h_a, 0.15))
	else:
		r(src, 6 + lo, 25, 2, 5, PALETTE.je)
		r(src, 9 - lo, 25, 2, 5, PALETTE.je)
		_vline(src, 7 + lo, 26, 29, PALETTE.je_l)
		_vline(src, 10 - lo, 26, 29, PALETTE.je_l)
		r(src, 5 + lo, 30, 3, 2, PALETTE.h_a)
		r(src, 9 - lo, 30, 3, 2, PALETTE.h_a)
		r(src, 5 + lo, 31, 3, 1, _darker(PALETTE.h_a, 0.2))
		r(src, 9 - lo, 31, 3, 1, _darker(PALETTE.h_a, 0.2))

	r(src, 5, 15, 7, 10, PALETTE.pl