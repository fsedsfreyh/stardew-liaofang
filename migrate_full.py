import os, sys, re, subprocess, ctypes, ctypes.wintypes, time
sys.stdout.reconfigure(encoding="utf-8")
from PIL import ImageGrab

proj = r"D:\龙虾\projects\stardew-liaofang"
godot = r"C:\Program Files\Godot_v4.6.2\Godot_v4.6.2-stable_win64.exe"
backup_dir = r"C:\Users\Administrator\Desktop\星露乡物语\stardew-liaofang"

backup_path = os.path.join(backup_dir, "scripts", "farm", "farm_scene.gd")
with open(backup_path, "r", encoding="utf-8") as f:
    backup = f.read()

def extract_func(content, fname):
    pattern = re.compile(r"(func\s+" + re.escape(fname) + r"\s*\([^)]*\):\n(?:\t.*\n?)*)")
    m = pattern.search(content)
    return m.group(1) if m else ""

farm_path = os.path.join(proj, "scripts", "farm", "farm_scene.gd")

# 提取所有需要的函数
all_funcs = ["_generate_map", "_draw_tiles", "_setup_farm_core", "_setup_connections",
             "_sync_all_crop_sprites", "_sync_all_state_overlays",
             "_on_farm_tile_changed", "_on_crop_harvested",
             "_setup_players_and_npcs", "_setup_farm_exit", "_setup_ui",
             "_start_guide", "_check_mail"]

funcs = {f: extract_func(backup, f) for f in all_funcs}

header_match = re.match(r'(extends Node2D.*?)(?=\nfunc\s)', backup, re.DOTALL)
var_decls = header_match.group(1) if header_match else "extends Node2D"

# 安全版 _setup_connections（去掉重复信号连接）
safe_connections = """func _setup_connections():
	if not farm: return
	if not farm.tile_changed.is_connected(_on_farm_tile_changed):
		farm.tile_changed.connect(_on_farm_tile_changed)
	if not farm.crop_harvested.is_connected(_on_crop_harvested):
		farm.crop_harvested.connect(_on_crop_harvested)
	if DayTime and not DayTime.time_changed.is_connected(_on_time_changed):
		DayTime.time_changed.connect(_on_time_changed)
	if InventoryManager and not InventoryManager.inventory_changed.is_connected(_on_inventory_changed):
		InventoryManager.inventory_changed.connect(_on_inventory_changed)
"""

# 完整 _deferred_init
deferred_init = """func _deferred_init():
	_generate_map()
	_setup_players_and_npcs()
	_setup_farm_core()
	_setup_ui()
	_setup_connections()
	_sync_all_crop_sprites()
	_sync_all_state_overlays()
	_setup_farm_exit()
	
	if Global.player_pos != Vector2.ZERO:
		for child in $Entities.get_children():
			if child is CharacterBody2D and child.has_method("set_movement"):
				child.global_position = Global.player_pos
	
	if DayTime.current_day == 1 and DayTime.current_season == 0:
		call_deferred("_start_guide")
	call_deferred("_check_mail")
"""

# 构建完整脚本
script = var_decls + "\n\n"
script += "func _ready():\n\tcall_deferred(\"_deferred_init\")\n\n"
script += deferred_init + "\n"
script += funcs["_generate_map"] + "\n"
script += funcs["_draw_tiles"] + "\n"
script += funcs["_setup_players_and_npcs"] + "\n"
script += funcs["_setup_farm_core"] + "\n"
script += funcs["_setup_ui"] + "\n"
script += safe_connections + "\n"
script += funcs["_sync_all_crop_sprites"] + "\n"
script += funcs["_sync_all_state_overlays"] + "\n"
script += funcs["_setup_farm_exit"] + "\n"
script += funcs["_on_farm_tile_changed"] + "\n"
script += funcs["_on_crop_harvested"] + "\n"
script += funcs["_start_guide"] + "\n"
script += funcs["_check_mail"] + "\n"

# 补充缺失的函数
extra = """func _on_time_changed():
	pass

func _on_inventory_changed():
	pass
"""
script += extra

with open(farm_path, "w", encoding="utf-8") as f:
    f.write(script)
print(f"Full script: {len(script)} chars")

# 编译
result = subprocess.run([godot, "--rendering-driver", "opengl3", "--path", proj, "--quit"],
                       capture_output=True, text=True, timeout=30)
if result.returncode != 0:
    errors = [l for l in result.stderr.split("\n") if "error" in l.lower() or "parse" in l.lower()]
    print("FAIL:", errors[:5])
    sys.exit(1)
print("Compile OK")

# 运行 + 截图
proc = subprocess.Popen([godot, "--rendering-driver", "opengl3", "--path", proj],
                       creationflags=subprocess.DETACHED_PROCESS)
time.sleep(16)

user32 = ctypes.windll.user32
EWP = ctypes.WINFUNCTYPE(ctypes.c_bool, ctypes.c_long, ctypes.c_long)
GetWindowTextW = user32.GetWindowTextW
hwnd = None
def cb(hwnd_, lp):
    global hwnd
    if user32.IsWindowVisible(hwnd_):
        buf = ctypes.create_unicode_buffer(256)
        n = GetWindowTextW(hwnd_, buf, 256)
        if n > 0 and "DEBUG" in buf.value and "Godot" not in buf.value:
            hwnd = hwnd_
user32.EnumWindows(EWP(cb), 0)

if hwnd:
    r = ctypes.wintypes.RECT()
    user32.GetWindowRect(hwnd, ctypes.byref(r))
    w, h = r.right - r.left, r.bottom - r.top
    img = ImageGrab.grab(bbox=(r.left, r.top, r.right, r.bottom))
    img.save(os.path.join(proj, "ss_full.png"))
    img.save(r"C:\Users\Administrator\Desktop\farm_full.png")
    px = img.load()
    g = sum(1 for _ in range(30000) 
            if (lambda r_,g_,b_: g_ > r_*1.3 and g_ > b_*1.2)
            (*px[int((w-1)*__import__("random").random()), int((h-1)*__import__("random").random())][:3]))
    print(f"Full: green={g/30000:.1%} ({w}x{h})")
    cx = w // 2
    for y in range(0, h, 60):
        r_,g_,b_ = px[cx, min(y, h-1)][:3]
        print(f"  y={y}: ({r_},{g_},{b_})")
else:
    print("No window")
