extends Control

func _ready():
	size = Vector2(1280, 720)
	var lbl = Label.new()
	lbl.text = "TEST SCENE LOADED!"
	lbl.position = Vector2(400, 300)
	lbl.size = Vector2(400, 50)
	lbl.add_theme_font_size_override("font_size", 24)
	lbl.add_theme_color_override("font_color", Color.RED)
	add_child(lbl)
	
	var r = ColorRect.new()
	r.color = Color(0, 1, 0)
	r.position = Vector2(100, 100)
	r.size = Vector2(50, 50)
	add_child(r)