# palette_demo.gd - 像素精灵验证输出
# 为什么单独做验证：确保像素质量可人工审查，不需要外部截图工具
# 输出方式：写入文件 _palette_demo_output.txt 到项目根目录
# 再配合 push_error 在控制台输出

extends Node

const OUTPUT_PATH := "res://_palette_demo_output.txt"

static func run() -> void:
	"""生成角色精灵并打印+写入像素网格文字图"""
	var lines: Array[String] = []
	lines.append("==================================================")
	lines.append(" 像素精灵验证 - 2x 放大文字图")
	lines.append("==================================================")
	
	for pair in [
		["player (正面站)", PixelArtist.generate("player", 0)],
		["player (左步)",   PixelArtist.generate("player", 1)],
		["player (右步)",   PixelArtist.generate("player", 2)],
		["liaofang (正面)", PixelArtist.generate("liaofang", 0)],
		["liaofang (左步)", PixelArtist.generate("liaofang", 1)],
		["liaofang (右步)", PixelArtist.generate("liaofang", 2)],
	]:
		lines.append("")
		lines.append("--- " + pair[0] + " ---")
		_print_grid(pair[1], lines)
	
	lines.append("")
	lines.append("==================================================")
	lines.append(" 审核项目")
	lines.append("==================================================")
	lines.append("[ ] 轮廓线是 #2a2018 褐色, 不是纯黑")
	lines.append("[ ] 头发 #18181a 深灰, 非纯黑")
	lines.append("[ ] 皮肤三层明度: 亮 #f0d8b0 / 中 #e0c0a0 / 暗 #c8a880")
	lines.append("[ ] 眼睛 2x2 + 左上角高光")
	lines.append("[ ] 腮红单像素 #e8a090")
	lines.append("[ ] 嘴巴配色 #c05048")
	lines.append("[ ] 角色比例 16x32")
	lines.append("[ ] 无纯黑无纯白")
	
	# 打印到控制台
	for line in lines:
		print(line)
	
	# 写入文件
	var file := FileAccess.open(OUTPUT_PATH, FileAccess.WRITE)
	if file:
		for line in lines:
			file.store_line(line)
		file.close()
		print("Done: " + OUTPUT_PATH)

static func _print_grid(tex: ImageTexture, lines: Array[String]) -> void:
	"""将 ImageTexture 按 2x 放大转为文字图"""
	var img := tex.get_image()
	if not img:
		lines.append("[ERR] no texture")
		return
	
	for y in range(32):
		var row := ""
		var skip := true
		for x in range(16):
			var c := img.get_pixel(x, y)
			if c.a < 0.5:
				row += "  "
			else:
				skip = false
				if c.r > 0.85 and c.g > 0.7:
					row += ".."
				elif c.r > 0.4 and c.g < 0.6:
					row += "%%"
				elif c.r < 0.3:
					row += "##"
				else:
					row += "()"
		if not skip:
			lines.append(row)
	
	lines.append("")
	lines.append("图例: ##=深色(头发/轮廓) %%=蓝色/中色 ..=浅色(皮肤/粉色)")
