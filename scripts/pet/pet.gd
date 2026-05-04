# Pet - 宠物跟宠系统
extends CharacterBody2D

enum PetType { DOG, CAT }

@export var pet_type: PetType = PetType.DOG:
	set(v):
		pet_type = v
		_update_sprite()

var pet_name: String = "小狗"
var is_following: bool = true
var follow_speed: float = 60.0
var follow_distance: float = 40.0
var stop_distance: float = 20.0
var affection: int = 0
var max_affection: int = 100

var _target: Node = null
var _idle_timer: float = 0.0
var _idle_dir: Vector2 = Vector2.ZERO

signal pet_interacted(pet_name: String, affection: int)

func _ready():
	add_to_group("pets")
	call_deferred("_update_sprite")
	pet_interacted.connect(_on_pet_interacted)

func _update_sprite():
	for c in get_children():
		if c is Sprite2D:
			c.queue_free()
	var tex = PixelArtist.generate_pet_sprite(pet_type)
	if tex:
		var spr = Sprite2D.new()
		spr.texture = tex
		spr.scale = Vector2(1.5, 1.5)
		spr.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		spr.centered = true
		spr.z_index = 1
		add_child(spr)

func set_target(node: Node):
	_target = node

func _physics_process(delta: float):
	if not is_following or not _target or not is_instance_valid(_target):
		_idle_wander(delta)
		return
	var dist = global_position.distance_to(_target.global_position)
	if dist > stop_distance:
		var dir = (_target.global_position - global_position).normalized()
		velocity = dir * follow_speed
		move_and_slide()
		_idle_timer = 0.0
	else:
		_idle_wander(delta)

func _idle_wander(delta: float):
	_idle_timer -= delta
	if _idle_timer <= 0:
		_idle_dir = Vector2(randf_range(-1, 1), randf_range(-1, 1)).normalized()
		_idle_timer = randf_range(1.0, 3.0)
	velocity = _idle_dir * 20.0
	move_and_slide()

func interact():
	affection = mini(max_affection, affection + 5)
	pet_interacted.emit(pet_name, affection)

func _on_pet_interacted(name: String, aff: int):
	var dm = get_node_or_null("/root/DialogueManager")
	if dm and dm.has_method("show_text"):
		var msg = name + "摇了摇尾巴！好感+" + str(aff)
		if aff >= max_affection:
			msg = name + "亲昵地蹭了蹭你！"
		dm.show_text(msg)

func get_save_data() -> Dictionary:
	return {"pet_type": pet_type, "pet_name": pet_name, "affection": affection, "is_following": is_following}

func load_from_data(data: Dictionary):
	if data.has("pet_type"): pet_type = data.pet_type
	if data.has("pet_name"): pet_name = data.pet_name
	if data.has("affection"): affection = data.affection
	if data.has("is_following"): is_following = data.is_following
	_update_sprite()