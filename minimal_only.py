import os, sys, re, subprocess, ctypes, ctypes.wintypes, time
sys.stdout.reconfigure(encoding="utf-8")
from PIL import ImageGrab

proj = r"D:\龙虾\projects\stardew-liaofang"
godot = r"C:\Program Files\Godot_v4.6.2\Godot_v4.6.2-stable_win64.exe"

# 创建极简测试
test_gd = """extends Node2D

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
"""

test_tscn = """[gd_scene format=3]

[node name="Test" type="Node2D"]
script = ExtResource("1")

[ext_resource type="Script" path="res://minimal_test.gd" id="1"]
"""

with open(os.path.join(proj, "minimal_test.gd"), "w", encoding="utf-8") as f:
    f.write(test_gd)
with open(os.path.join(proj, "minimal_test.tscn"), "w", encoding="utf-8") as f:
    f.write(test_tscn)

# Backup and switch project.godot
pg_path = os.path.join(proj, "project.godot")
with open(pg_path, "r", encoding="utf-8") as f:
    pg = f.read()
pg_backup = pg

pg = pg.replace('run/main_scene="res://scenes/core/main_menu.tscn"',
                'run/main_scene="res://minimal_test.tscn"')
with open(pg_path, "w", encoding="utf-8") as f:
    f.write(pg)

# Clean cache and start
cache = os.path.join(proj, ".godot")
for _ in range(3):
    try:
        subprocess.run(["cmd", "/c", "rmdir", "/s", "/q", cache], capture_output=True, timeout=5, shell=True)
        break
    except: time.sleep(0.5)

subprocess.run(["powershell", "-Command", "Get-Process Godot* | Stop-Process -Force"], capture_output=True, timeout=5)
time.sleep(2)
subprocess.run(["powershell", "-Command", 
    f'Start-Process "{godot}" -ArgumentList "--rendering-driver opengl3 --path `"{proj}`""'],
    capture_output=True, timeout=5)
time.sleep(15)

# Screenshot
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
    
    green = sum(1 for _ in range(20000) if (lambda r_,g_,b_: g_ > r_*1.3 and g_ > b_*1.2)
               (*px[__import__("random").randint(0,w-1), __import__("random").randint(0,h-1)][:3]))
    gold = sum(1 for _ in range(20000) if (lambda r_,g_,b_: r_ > 150 and g_ > 100 and b_ < 100)
               (*px[__import__("random").randint(0,w-1), __import__("random").randint(0,h-1)][:3]))
    
    print(f"green={green/20000:.1%} gold={gold/20000:.1%}")
    cx = w // 2
    for y in range(0, h, 40):
        r_,g_,b_ = px[cx, min(y, h-1)][:3]
        print(f"  y={y:3d}: ({r_:3d},{g_:3d},{b_:3d})")
    
    if green > 0.01 or gold > 0.01:
        print("\n✅ MINIMAL TEST RENDERS!")
    else:
        print("\n❌ MINIMAL TEST DOES NOT RENDER - core Godot issue!")
else:
    print("No window found")

# Restore project.godot
with open(pg_path, "w", encoding="utf-8") as f:
    f.write(pg_backup)
print("project.godot restored")
