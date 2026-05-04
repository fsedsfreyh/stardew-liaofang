extends Node
## TileManager - loads LPC spritesheets as ImageTexture
## Falls back to PixelArtist code gen if spritesheets unavailable

const TILE_SIZE = 16

var _tile_textures: Dictionary = {}
var _loaded := false

func _ready():
	_load_textures()

func _load_textures():
	var dirs = ["res://assets/tilesets", "res://assets/submission_daneeklu/tilesets"]
	for dir_path in dirs:
		var dir = DirAccess.open(dir_path)
		if dir == null:
			continue
		dir.list_dir_begin()
		var fname = dir.get_next()
		while fname != "":
			if fname.ends_with(".png"):
				var tex = _load_png(dir_path.path_join(fname))
				if tex:
					var name = fname.replace(".png", "")
					_tile_textures[name] = tex
			fname = dir.get_next()
		dir.list_dir_end()
	
	if _tile_textures.size() > 0:
		_loaded = true

func _load_png(path: String) -> Texture2D:
	var img = Image.new()
	var err = img.load(path)
	if err == OK:
		var tex = ImageTexture.create_from_image(img)
		return tex
	return null

func get_tile_texture(tile_type: String, variant: int = 0) -> Texture2D:
	var sheet_name = _get_sheet_name(tile_type)
	if sheet_name in _tile_textures:
		var sheet = _tile_textures[sheet_name]
		if sheet is AtlasTexture:
			return sheet
		# Slice the spritesheet to get a single tile
		var atlas = _slice_tile(sheet, tile_type, variant)
		if atlas:
			return atlas
	return null

func _get_sheet_name(tile_type: String) -> String:
	match tile_type:
		"grass", "dirt", "water", "path", "sand":
			return "farming_fishing"
		"tomato", "corn", "pumpkin", "sunflower", "bluebell", "cactus":
			return "plants"
		"fence", "fence_h", "fence_v":
			return "fence"
		"fence_alt":
			return "fence_alt"
		"plowed_1", "plowed_2":
			return "plowed_soil"
		"reed":
			return "reed"
		"sandwater":
			return "sandwater"
		"tall_grass":
			return "tallgrass"
		"wheat":
			return "wheat"
		_:
			return "tallgrass"

func _slice_tile(sheet: Texture2D, tile_type: String, variant: int) -> AtlasTexture:
	var cols = int(sheet.get_width() / TILE_SIZE)
	var tile_id = _get_tile_id(tile_type, variant)
	var col = tile_id % cols
	var row = int(tile_id / cols)
	
	var atlas = AtlasTexture.new()
	atlas.atlas = sheet
	atlas.region = Rect2(col * TILE_SIZE, row * TILE_SIZE, TILE_SIZE, TILE_SIZE)
	return atlas

func _get_tile_id(tile_type: String, variant: int) -> int:
	match tile_type:
		"grass": return variant % 4
		"dirt": return 1
		"water": return 20
		"path": return 10
		"sand": return 5
		"tall_grass": return variant % 6
		"fence", "fence_h": return 0
		"fence_v": return 1
		"reed": return 0
		"tomato": return 0
		"corn": return 1
		"pumpkin": return 2
		"sunflower": return 3
		"bluebell": return 4
		"cactus": return 5
		"wheat": return 0
		"plowed_1": return 0
		"plowed_2": return 1
		_: return 0
