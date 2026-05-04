import os, sys, re, ctypes, ctypes.wintypes, time, subprocess
sys.stdout.reconfigure(encoding="utf-8")
from PIL import ImageGrab

proj = r"D:\龙虾\projects\stardew-liaofang"
godot = r"C:\Program Files\Godot_v4.6.2\Godot_v4.6.2-stable_win64.exe"

# 备份 project.godot
pg_path = os.path.join(proj, "project.godot")
with open(pg_path, "r", encoding="utf-8") as f:
    original_pg = f.read()

# 改为 farm_scene.tscn 作为主场景
farm_pg = original_pg.replace(
    'run/main_scene="res://scenes/core/main_menu.tscn"',
    'run/main_scene="res://scenes/farm/farm_scene.tscn"'
)
with open(pg_path, "w", encoding="utf-8") as f:
    f.write(farm_pg)

# 清缓存
cache = os.path.join(proj, ".godot")
for _ in range(3):
    try:
        subprocess.run(["cmd", "/c", "rmdir", "/s", "/q", cache], capture_output=True, timeout=5, shell=True)
        break
    except: time.sleep(0.5)

# 编译
result = subprocess.run([godot, "--rendering-driver", "opengl3", "--path", proj, "--quit"],
                       capture_output=True, text=True, timeout=30)
if result.returncode != 0:
    print("Compile FAIL")
    for l in result.stderr.split("\n") + result.stdout.split("\n"):
        if "ERROR" in l or "error" in l or "Parse" in l:
            print(f"  {l.strip()}")
    # 恢复project.godot
    with open(pg_path, "w", encoding="utf-8") as f:
        f.write(original_pg)
    sys.exit(1)
print("Compile OK ✅")

# 启动
subprocess.run(["powershell", "-Command", 
    f'Start-Process "{godot}" -ArgumentList "--rendering-driver opengl3 --path `"{proj}`""'],
    capture_output=True, timeout=5)
time.sleep(20)

# 截图
user32 = ctypes.windll.user32
EWP = ctypes.WINFUNCTYPE(ctypes.c_bool, ctypes.c_long, ctypes.c_long)
hwnd = None
def cb(hwnd_, lp):
    global hwnd
    if user32.IsWindowVisible(hwnd_):
        buf = ctypes.create_unicode_buffer(256)
        n = user32.GetWindowTextW(hwnd_, buf, 256)
        if n > 0 and "DEBUG" in buf.value and "Godot" not in buf.value:
            hwnd = hwnd_
user32.EnumWindows(EWP(cb), 0)

if hwnd:
    r = ctypes.wintypes.RECT()
    user32.GetWindowRect(hwnd, ctypes.byref(r))
    full = ImageGrab.grab()
    img = full.crop((r.left, r.top, r.right, r.bottom))
    w, h = img.size
    px = img.load()
    
    green = sum(1 for _ in range(30000) if (lambda r_,g_,b_: g_ > r_*1.3 and g_ > b_*1.2)
               (*px[(int((w-1)*__import__("random").random()), int((h-1)*__import__("random").random()))][:3]))
    print(f"Farm scene direct: green={green/30000:.1%}")
    
    cx = w // 2
    for y in range(0, h, 40):
        r_,g_,b_ = px[cx, min(y, h-1)][:3]
        print(f"  y={y:3d}: ({r_:3d},{g_:3d},{b_:3d})")
    
    if green > 50:
        print("\n✅ FARM SCENE RENDERS DIRECTLY!")
    else:
        print("\n❌ FARM SCENE does NOT render directly")
    
    full.save(r"C:\Users\Administrator\Desktop\farm_direct_test.png")
else:
    print("No window found")

# 恢复 project.godot
with open(pg_path, "w", encoding="utf-8") as f:
    f.write(original_pg)
print("project.godot restored")
