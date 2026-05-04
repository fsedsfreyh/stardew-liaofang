import os, sys, subprocess, ctypes, ctypes.wintypes, time
sys.stdout.reconfigure(encoding="utf-8")
from PIL import ImageGrab

proj = r"D:\龙虾\projects\stardew-liaofang"
godot = r"C:\Program Files\Godot_v4.6.2\Godot_v4.6.2-stable_win64.exe"

# 修复 main_menu.tscn
tscn_path = os.path.join(proj, "scenes", "core", "main_menu.tscn")
with open(tscn_path, "r", encoding="utf-8") as f:
    tscn = f.read()

# 如果 anchors_preset = 0 不存在就加回去
if 'anchors_preset' not in tscn:
    tscn = tscn.replace(
        '[node name="MainMenu" type="Control"]',
        '[node name="MainMenu" type="Control"]\nanchors_preset = 0'
    )
    with open(tscn_path, "w", encoding="utf-8") as f:
        f.write(tscn)
    print("Added anchors_preset = 0")
else:
    print("anchors_preset already present")

# 也恢复 main_menu.gd 的 _draw 里用 size.x
mm_path = os.path.join(proj, "scripts", "core", "main_menu.gd")
with open(mm_path, "r", encoding="utf-8") as f:
    mm = f.read()

# 我上次改成了固定 640，改回 size.x
mm = mm.replace(
    'func _draw():\n\tvar cx = 640.0',
    'func _draw():\n\tvar cx = size.x / 2.0'
)
with open(mm_path, "w", encoding="utf-8") as f:
    f.write(mm)

print("Restored size.x/2.0 in _draw")

# 重启游戏
os.system("taskkill /F /IM Godot_v4* 2>nul")
time.sleep(2)
cache = os.path.join(proj, ".godot")
for _ in range(3):
    try:
        subprocess.run(["cmd", "/c", "rmdir", "/s", "/q", cache], capture_output=True, timeout=5, shell=True)
        break
    except: time.sleep(0.5)

proc = subprocess.Popen([godot, "--rendering-driver", "opengl3", "--path", proj],
                       creationflags=subprocess.DETACHED_PROCESS)
time.sleep(18)

# 截图
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
    img.save(r"C:\Users\Administrator\Desktop\test_fixed.png")
    px = img.load()
    
    gold = 0; green = 0; brown = 0
    for _ in range(20000):
        x = int((w-1) * __import__("random").random())
        y = int((h-1) * __import__("random").random())
        r_,g_,b_ = px[x, y][:3]
        if r_ > 150 and g_ > 100 and b_ < 100: gold += 1
        elif g_ > r_*1.3 and g_ > b_*1.2: green += 1
        elif r_ < 60 and g_ < 40 and b_ < 25: brown += 1
    
    print(f"gold={gold/20000:.1%} green={green/20000:.1%} brown={brown/20000:.1%}")
    cx = w // 2
    for y in range(0, h, 40):
        r_,g_,b_ = px[cx, min(y, h-1)][:3]
        print(f"  y={y:3d}: ({r_:3d},{g_:3d},{b_:3d})")
else:
    print("No window found")

print("\nWindow PID:", proc.pid)
print("Screenshot saved to desktop: test_fixed.png")
