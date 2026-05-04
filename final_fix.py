import os, sys, re, subprocess, ctypes, ctypes.wintypes, time
sys.stdout.reconfigure(encoding="utf-8")
from PIL import ImageGrab

proj = r"D:\龙虾\projects\stardew-liaofang"
godot = r"C:\Program Files\Godot_v4.6.2\Godot_v4.6.2-stable_win64.exe"
backup = r"C:\Users\Administrator\Desktop\星露乡物语\stardew-liaofang\scripts\farm\farm_scene.gd"

# 1. 从备份构建完整 farm_scene.gd
with open(backup, "r", encoding="utf-8") as f:
    backup_content = f.read()

# 提取备份所有函数
all_funcs = {}
for m in re.finditer(r'(^func \w+\([^)]*\).*?\n(?:\t.*\n?)*)', backup_content, re.MULTILINE):
    name = m.group(1).split("(")[0].replace("func ", "")
    all_funcs[name] = m.group(1)

print(f"备份函数数: {len(all_funcs)}")

# 添加缺失的核心辅助函数（如果备份没有）
extras = {
    "_world_to_tile": "func _world_to_tile(world_pos: Vector2) -> Vector2i:\n\treturn Vector2i(int(world_pos.x / (TILE_SIZE * ZOOM)), int(world_pos.y / (TILE_SIZE * ZOOM)))\n",
    "_tile_top_left": "func _tile_top_left(tile_pos: Vector2i) -> Vector2:\n\treturn Vector2(tile_pos.x * TILE_SIZE * ZOOM, tile_pos.y * TILE_SIZE * ZOOM)\n",
    "_tile_center": "func _tile_center(tile_pos: Vector2i) -> Vector2:\n\treturn Vector2(tile_pos.x * TILE_SIZE * ZOOM + TILE_SIZE * ZOOM / 2.0, tile_pos.y * TILE_SIZE * ZOOM + TILE_SIZE * ZOOM / 2.0)\n",
    "_remove_named_child": "func _remove_named_child(name: String):\n\tfor child in get_children():\n\t\tif child.name == name:\n\t\t\tchild.queue_free()\n\t\t\treturn\n",
    "is_walkable": "func is_walkable(global_pos: Vector2) -> bool:\n\tvar tp = _world_to_tile(global_pos)\n\tif tp.x < 0 or tp.x >= MAP_W or tp.y < 0 or tp.y >= MAP_H:\n\t\treturn false\n\treturn map_data[tp.y][tp.x] == 0 or map_data[tp.y][tp.x] == 7 or map_data[tp.y][tp.x] == 6\n"
}

# 构建脚本
h_match = re.match(r'(extends Node2D.*?)(?=\nfunc )', backup_content, re.DOTALL)
header = h_match.group(1) if h_match else "extends Node2D"

script = header + "\n\n"
all_func_names = list(all_funcs.keys())

for name in all_func_names:
    fn = all_funcs[name]
    # 加安全信号连接
    fn = fn.replace(
        "farm.tile_changed.connect(_on_farm_tile_changed)",
        "if not farm.tile_changed.is_connected(_on_farm_tile_changed):\n\t\tfarm.tile_changed.connect(_on_farm_tile_changed)"
    )
    fn = fn.replace(
        "farm.crop_harvested.connect(_on_crop_harvested)",
        "if not farm.crop_harvested.is_connected(_on_crop_harvested):\n\t\tfarm.crop_harvested.connect(_on_crop_harvested)"
    )
    
    # InventoryManager => Inventory 的兼容
    fn = fn.replace("InventoryManager.", "Inventory.")
    fn = fn.replace("Inventory.inventory_changed", "Inventory.inventory_changed")
    
    script += fn + "\n"

# 加缺失辅助函数
for name, code in extras.items():
    if name not in all_funcs:
        script += "\n" + code

# 确保 _setup_connections 安全
script = script.replace(
    "DayTime.time_changed.connect(_on_time_changed)",
    "if DayTime and not DayTime.time_changed.is_connected(_on_time_changed):\n\t\tDayTime.time_changed.connect(_on_time_changed)"
)
script = script.replace(
    "Inventory.inventory_changed.connect(_update_affection_display)",
    "if Inventory and not Inventory.inventory_changed.is_connected(_update_affection_display):\n\t\tInventory.inventory_changed.connect(_update_affection_display)"
)

# 写回
with open(os.path.join(proj, "scripts", "farm", "farm_scene.gd"), "w", encoding="utf-8") as f:
    f.write(script)
print(f"写入: {script.count(chr(10))} 行")

# 2. 确保 project.godot 无 BOM 正确
pg_content = """; Engine configuration file.
; It's best edited using the editor UI and not directly,
; since the parameters that go here are not all obvious.
;
; Format:
;   [section] ; section goes between []
;   param=value ; assign values to parameters

config_version=5

[application]

run/main_scene="res://scenes/core/main_menu.tscn"
config/features=PackedStringArray("4.6")

[autoload]

SkillSystem="*res://scripts/core/skill_system.gd"
AudioManager="*res://scripts/core/audio_manager.gd"
PixelArtist="*res://scripts/core/pixel_artist.gd"
Global="*res://autoloads/global.gd"
DayTime="*res://scripts/core/day_time.gd"
Affection="*res://scripts/core/affection_system.gd"
Inventory="*res://scripts/core/inventory_manager.gd"
SaveManager="*res://scripts/core/save_manager.gd"
DialogueManager="*res://scenes/ui/dialogue_ui.tscn"
QuestManager="*res://scripts/core/quest_manager.gd"
HouseUpgrade="*res://scripts/core/house_upgrade.gd"
MailManager="*res://scripts/core/mail_manager.gd"
AchievementUI="*res://scenes/ui/achievement_ui.tscn"
FestivalManager="*res://scripts/core/festival_manager.gd"

[display]

window/size/viewport_width=1280
window/size/viewport_height=720

[rendering]

textures/canvas_textures/default_texture_filter=1
renderer/rendering_method="gl_compatibility"

[filesystem]

import/blender/enabled=false
"""

with open(os.path.join(proj, "project.godot"), "w", encoding="utf-8") as f:
    f.write(pg_content)
print("project.godot 已写入 (无BOM)")

# 3. 编译
cache = os.path.join(proj, ".godot")
for _ in range(3):
    try:
        subprocess.run(["cmd", "/c", "rmdir", "/s", "/q", cache], capture_output=True, timeout=5, shell=True)
        break
    except: time.sleep(0.5)

result = subprocess.run([godot, "--rendering-driver", "opengl3", "--path", proj, "--quit"],
                       capture_output=True, text=True, timeout=30)
if result.returncode == 0:
    print("Compile OK ✅")
else:
    print(f"Compile FAIL ({result.returncode})")
    for l in result.stderr.split("\n") + result.stdout.split("\n"):
        if "ERROR" in l or "Parse" in l:
            print(f"  {l.strip()}")
    sys.exit(1)

# 4. 启动
subprocess.run(["powershell", "-Command", "Get-Process Godot* | Stop-Process -Force"], capture_output=True, timeout=5)
time.sleep(2)
subprocess.run(["powershell", "-Command", 
    f'Start-Process "{godot}" -ArgumentList "--rendering-driver opengl3 --path `"{proj}`""'],
    capture_output=True, timeout=5)
time.sleep(20)

# 5. 截图
user32 = ctypes.windll.user32
EWP = ctypes.WINFUNCTYPE(ctypes.c_bool, ctypes.c_long, ctypes.c_long)
hwnd = [None]
def cb(hwnd_, lp):
    if user32.IsWindowVisible(hwnd_):
        buf = ctypes.create_unicode_buffer(256)
        n = user32.GetWindowTextW(hwnd_, buf, 256)
        if n > 0 and "DEBUG" in buf.value and "Godot" not in buf.value:
            hwnd[0] = hwnd_
user32.EnumWindows(EWP(cb), 0)

if hwnd[0]:
    r = ctypes.wintypes.RECT()
    user32.GetWindowRect(hwnd[0], ctypes.byref(r))
    full = ImageGrab.grab()
    img = full.crop((r.left, r.top, r.right, r.bottom))
    w, h = img.size
    px = img.load()
    
    gold = sum(1 for _ in range(20000) if (lambda r_,g_,b_: r_ > 150 and g_ > 100 and b_ < 100)
               (*px[__import__("random").randint(0,w-1), __import__("random").randint(0,h-1)][:3]))
    brown = sum(1 for _ in range(20000) if (lambda r_,g_,b_: r_ < 60 and g_ < 40 and b_ < 25)
               (*px[__import__("random").randint(0,w-1), __import__("random").randint(0,h-1)][:3]))
    
    print(f"\ngold={gold/20000:.1%} brown={brown/20000:.1%}")
    cx = w // 2
    for y in range(0, h, 40):
        r_,g_,b_ = px[cx, min(y, h-1)][:3]
        print(f"  y={y:3d}: ({r_:3d},{g_:3d},{b_:3d})")
    
    if gold > 0.01:
        print("\n✅ MAIN MENU UP!")
        
        # 点击进入农场
        print("\nClicking Start New Farm...")
        user32.SetCursorPos(r.left + w//2, r.top + 400)
        time.sleep(0.2)
        user32.mouse_event(0x0002, 0, 0, 0, 0)
        time.sleep(0.05)
        user32.mouse_event(0x0004, 0, 0, 0, 0)
        time.sleep(6)
        
        img2 = ImageGrab.grab().crop((r.left, r.top, r.right, r.bottom))
        px2 = img2.load()
        g = sum(1 for _ in range(20000) if (lambda r_,g_,b_: g_ > r_*1.3 and g_ > b_*1.2)
               (*px2[__import__("random").randint(0,w-1), __import__("random").randint(0,h-1)][:3]))
        print(f"Farm: green={g/20000:.1%}")
        
        if g > 0.005:
            print("✅ IN FARM SCENE!")
            for y in range(0, h, 40):
                r_,g_,b_ = px2[w//2, min(y, h-1)][:3]
                print(f"  y={y:3d}: ({r_:3d},{g_:3d},{b_:3d})")
        else:
            print("Not in farm - checking state")
            for y in range(0, h, 40):
                r_,g_,b_ = px2[w//2, min(y, h-1)][:3]
                print(f"  y={y:3d}: ({r_:3d},{g_:3d},{b_:3d})")
    
    img.save(r"C:\Users\Administrator\Desktop\final_test.png")
else:
    print("No window found")
