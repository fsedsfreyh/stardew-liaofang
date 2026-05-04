# GenerateIcon - 运行一次生成 icon.png
# 在 Godot 编辑器中运行即可
extends Node

func _ready():
	var img = PixelArtist.create(64, 64)
	
	# 绘制简单图标 - 爱心 + 星星
	var cx = 32
	var cy = 32
	
	# 爱心
	var heart_pixels = [
		[0,0,0,0,1,1,0,0,0,0,1,1,0,0,0,0],
		[0,0,1,1,1,1,1,0,0,1,1,1,1,1,0,0],
		[0,1,1,1,1,1,1,1,0,1,1,1,1,1,1,1,0],
		[0,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,0],
		[0,0,1,1,1,1,1,1,1,1,1,1,1,1,1,0,0],
		[0,0,0,1,1,1,1,1,1,1,1,1,1,0,0,0],
		[0,0,0,0,1,1,1,1,1,1,1,0,0,0,0],
		[0,0,0,0,0,1,1,1,1,0,0,0,0,0],
		[0,0,0,0,0,0,1,0,0,0,0,0,0],
	]
	
	var hx = cx - 8
	var hy = cy - 4
	for y in range(len(heart_pixels)):
		for x in range(len(heart_pixels[y])):
			if heart_pixels[y][x] == 1:
				# 放大2倍
				for dy in range(2):
					for dx in range(2):
						var px = (hx + x) * 2 + dx
						var py = (hy + y) * 2 + dy
						if px >= 0 and px < 64 and py >= 0 and py < 64:
							img.set_pixel(px, py, Color("#ff6b8a"))
	
	# 星星
	var star_pixels = [
		[0,0,0,0,0,1,0,0,0,0,0],
		[0,0,0,0,1,1,1,0,0,0,0],
		[0,0,0,1,0,1,0,1,0,0,0],
		[0,0,1,0,0,1,0,0,1,0,0],
		[0,1,1,1,1,1,1,1,1,1,0],
		[0,0,1,0,0,0,0,0,1,0,0],
		[0,0,0,1,0,0,0,1,0,0,0],
		[0,0,0,0,1,0,1,0,0,0,0],
		[0,0,0,0,0,1,0,0,0,0,0],
	]
	
	var sx = cx - 12
	var sy = cy - 12
	for y in range(len(star_pixels)):
		for x in range(len(star_pixels[y])):
			if star_pixels[y][x] == 1:
				for dy in range(2):
					for dx in range(2):
						var px = (sx + x) * 2 + dx
						var py = (sy + y) * 2 + dy
						if px >= 0 and px < 64 and py >= 0 and py < 64:
							img.set_pixel(px, py, Color("#d4af5a"))
	
	img.save_png("res://icon.png")
	print("图标已生成: icon.png")
	get_tree().quit()
