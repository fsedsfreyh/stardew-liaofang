extends Node2D

func _ready():
	var rect = ColorRect.new()
	rect.color = Color.GREEN
	rect.size = Vector2(1280, 720)
	add_child(rect)
	
	var rect2 = ColorRect.new()
	rect2.color = Color(0.83, 0.69, 0.35)
	rect2.size = Vector2(500, 100)
	rect2.position = Vector2(390, 100)
	add_child(rect2)
