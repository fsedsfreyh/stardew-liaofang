import os, sys, re, subprocess, ctypes, ctypes.wintypes, time
sys.stdout.reconfigure(encoding="utf-8")
from PIL import ImageGrab

proj = r"D:\龙虾\projects\stardew-liaofang"
godot = r"C:\Program Files\Godot_v4.6.2\Godot_v4.6.2-stable_win64.exe"

# Read backup for raw content
backup = r"C:\Users\Administrator\Desktop\星露乡物语\stardew-liaofang\scripts\farm\farm_scene.gd"
with open(backup, "r", encoding="utf-8") as f:
    backup_content = f.read()

# Extract ALL functions from backup
all_funcs = {}
for m in re.finditer(r'(^func \w+\([^)]*\).*?\n(?:\t.*\n?)*)', backup_content, re.MULTILINE):
    name = m.group(1).split("(")[0].replace("func ", "")
    all_funcs[name] = m.group(1)

# Extreme minimal - ONLY map generation + tile drawing
# No NPCs, no farm core, no UI, no connections, no exits
MIN_CORE = [
    "_ready", "_deferred_init",
    "_generate_map", "_draw_tiles", "_setup_collision", "_replace_tile",
]

# Build script
script = "extends Node2D\n\n"
for name in MIN_CORE:
    if name in all_funcs:
        fn = all_funcs[name]
        # Simplify _deferred_init to ONLY generate_map
        if name == "_deferred_init":
            fn = "func _deferred_init():\n\t_generate_map()\n"
        script += fn + "\n"
    else:
        script += f"func {name}():\n\tpass\n\n"

farm_path = os.path.join(proj, "scripts", "farm", "farm_scene.gd")
with open(farm_path, "w", encoding="utf-8") as f:
    f.write(script)

print(f"MIN_CORE: {script.count(chr(10))} lines")

# Compile
cache = os.path.join(proj, ".godot")
for _ in range(3):
    try:
        subprocess.run(["cmd", "/c", "rmdir", "/s", "/q", cache], capture_output=True, timeout=5, shell=True)
        break
    except: time.sleep(0.5)

result = subprocess.run([godot, "--rendering-driver", "opengl3", "--path", proj, "--quit"],
                       capture_output=True, text=True, timeout=30)
if result.returncode != 0:
    print(f"COMPILE FAIL ({result.returncode})")
    sys.exit(1)
print("Compile OK")

# Switch project.godot to farm_scene
pg_path = os.path.join(proj, "project.godot")
with open(pg_path, "r", encoding="utf-8") as f:
    pg = f.read()
pg_backup = pg
pg = pg.replace('run/main_scene="res://scenes/core/main_menu.tscn"',
                'run/main_scene="res://scenes/farm/farm_scene.tscn"')
with open(pg_path, "w", encoding="utf-8") as f:
    f.write(pg)

# Kill + restart
subprocess.run(["powershell", "-Command", "Get-Process Godot* | Stop-Process -Force"], capture_output=True, timeout=5)
time.sleep(2)
subprocess.run(["powershell", "-Command", 
    f'Start-Process "{godot}" -ArgumentList "--rendering-driver opengl3 --path `"{proj}`""'],
    capture_output=True, timeout=5)
time.sleep(20)

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
    print(f"Window: {w}x{h}")
    
    px = img.load()
    green = sum(1 for _ in range(20000) if (lambda r_,g_,b_: g_ > r_*1.3 and g_ > b_*1.2)
               (*px[__import__("random").randint(0,w-1), __import__("random").randint(0,h-1)][:3]))
    print(f"green={green/20000:.1%}")
    cx = w // 2
    for y in range(0, h, 40):
        r_,g_,b_ = px[cx, min(y, h-1)][:3]
        print(f"  y={y:3d}: ({r_:3d},{g_:3d},{b_:3d})")
    
    if green > 50:
        print("\n✅ MIN_CORE renders green!")
    else:
        print(f"\n❌ MIN_CORE no green = {green}/{20000}")
else:
    print("No window found")

# Restore
with open(pg_path, "w", encoding="utf-8") as f:
    f.write(pg_backup)
