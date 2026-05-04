@tool
extends EditorScript
func _run():
	var s = ResourceLoader.load("res://scenes/farm/farm_scene.tscn")
	print("Loaded: ", s)
	print("Error: ", ResourceLoader.has_cached("res://scenes/farm/farm_scene.tscn"))