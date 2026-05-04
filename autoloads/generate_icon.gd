# Generate icon for the project
extends Node

func _ready():
	# Create a simple 64x64 icon
	var img = Image.create(64, 64, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	
	# Bluebell flower icon for the logo
	# Petals
	for x in 4:
		for y in 4:
			if (x + y) % 3 != 1:
				var px = 24 + x * 4
				var py = 14 + y * 4
				for dx in 4:
					for dy in 4:
						img.set_pixel(px + dx, py + dy, Color("#6a8ac0"))
	
	# Center yellow
	for dx in 6:
		for dy in 6:
			img.set_pixel(28 + dx, 24 + dy, Color("#ffd700"))
	
	# Stem
	for y in 16:
		img.set_pixel(30, 34 + y, Color("#4a7c3f"))
		img.set_pixel(31, 34 + y, Color("#4a7c3f"))
		img.set_pixel(29, 34 + y, Color("#3a6c2f"))
	
	# Ground
	for x in 16:
		for y in 3:
			img.set_pixel(24 + x, 52 + y, Color("#7a6244"))
	
	img.save_png("res://icon.png")
	print("Icon generated and saved!")
	queue_free()