import os, sys, subprocess, ctypes, ctypes.wintypes, time, re
sys.stdout.reconfigure(encoding="utf-8")
from PIL import ImageGrab

proj = r"D:\龙虾\projects\stardew-liaofang"
godot = r"C:\Program Files\Godot_v4.6.2\Godot_v4.6.2-stable_win64.exe"
backup_dir = r"C:\Users\Administrator\Desktop\星露乡物语\stardew-liaofang"

# 读取备份
backup_path = os.path.join(backup_dir, "scripts", "farm", "farm_scene.gd")
with open(backup_path, "r", encoding="utf-8") as f:
    backup = f.read()

# 读取当前 farm_scene.gd
farm_path = os.path.join(proj, "scripts", "farm", "farm_scene.gd")
with open(farm_path, "r", encoding="utf-8") as f:
    current = f.read()

# 读取 main_menu.gd 看有没有需要保留的改动
mm_path = os.path.join(proj, "scripts", "core", "main_menu.gd")
with open(mm_path, "r", encoding="utf-8") as f:
    mm = f.read()

print(f"Backup: {len(backup)} chars, {backup.count(chr(10))} lines")
print(f"Current: {len(current)} chars, {current.count(chr(10))} lines")

# 从备份复制整个脚本内容，但做少量必要修复：
# 1. 去掉 emoji 字符（只保留中文和 ASCII）
# 2. 确保 _setup_connections 用安全连接方式
# 3. 确保 main_menu.gd 的 _on_new_game 指向正确的场景

# 复制整个备份
script = backup

# 修复1: _setup_connections 加 is_connected 保护
old_conn = """func _setup_connections():
	farm.tile_changed.connect(_on_farm_tile_changed)
	farm.crop_harvested.connect(_on_crop_harvested)
	DayTime.time_changed.connect(_on_time_changed)
	InventoryManager.inventory_changed.connect(_on_inventory_changed)"""

new_conn = """func _setup_connections():
	if not farm: return
	if not farm.tile_changed.is_connected(_on_farm_tile_changed):
		farm.tile_changed.connect(_on_farm_tile_changed)
	if not farm.crop_harvested.is_connected(_on_crop_harvested):
		farm.crop_harvested.connect(_on_crop_harvested)
	if DayTime and not DayTime.time_changed.is_connected(_on_time_changed):
		DayTime.time_changed.connect(_on_time_changed)
	if InventoryManager and not InventoryManager.inventory_changed.is_connected(_on_inventory_changed):
		InventoryManager.inventory_changed.connect(_on_inventory_changed)"""

script = script.replace(old_conn, new_conn)

# 修复2: main_menu.gd 去掉 _delayed_start 调用（已经做了，确认）
# 检查 main_menu.gd 是否还有 _delayed_start 调用
if "call_deferred(\"_delayed_start\")" in mm:
    print("WARNING: main_menu.gd still has _delayed_start call!")
else:
    print("OK: main_menu.gd no _delayed_start")

# 修复3: 确认 _on_new_game 使用正确的场景路径
if 'change_scene_to_file("res://scenes/farm/farm_scene.tscn")' not in script:
    # 从 main_menu.gd 找 _on_new_game
    mm_match = re.search(r'func _on_new_game\(\):(.*?)(?=\nfunc)', mm, re.DOTALL)
    if mm_match:
        print(f"main_menu _on_new_game: {mm_match.group(1)[:100]}...")

# 写回
with open(farm_path, "w", encoding="utf-8") as f:
    f.write(script)

print(f"\nWritten: {len(script)} chars, {script.count(chr(10))} lines")

# 编译
os.system("taskkill /F /IM Godot_v4* 2>nul")
time.sleep(2)
cache = os.path.join(proj, ".godot")
for _ in range(3):
    try:
        subprocess.run(["cmd", "/c", "rmdir", "/s", "/q", cache], capture_output=True, timeout=5, shell=True)
        break
    except: time.sleep(0.5)

result = subprocess.run([godot, "--rendering-driver", "opengl3", "--path", proj, "--quit"],
                       capture_output=True, text=True, timeout=30)
if result.returncode == 0:
    print("Compile OK")
else:
    errors = [l for l in result.stderr.split("\n") if "ERROR" in l or "error" in l or "Parse" in l]
    print(f"Compile FAIL ({result.returncode})")
    for e in errors[:10]:
        print(f"  {e.strip()}")
    sys.exit(1)

# 启动
subprocess.run(["powershell", "-Command", 
    f'Start-Process "{godot}" -ArgumentList "--rendering-driver opengl3 --path `"{proj}`""'],
    capture_output=True, timeout=5)
time.sleep(20)

# 截图检测
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
    w, h = r.right - r.left, r.bottom - r.top
    img = ImageGrab.grab(bbox=(r.left, r.top, r.right, r.bottom))
    px = img.load()
    
    gold = 0; green = 0; brown = 0
    for _ in range(20000):
        x = int((w-1) * __import__("random").random())
        y = int((h-1) * __import__("random").random())
        r_,g_,b_ = px[x, y][:3]
        if r_ > 150 and g_ > 100 and b_ < 100: gold += 1
        elif g_ > r_*1.3 and g_ > b_*1.2: green += 1
        elif r_ < 60 and g_ < 40 and b_ < 25: brown += 1
    
    print(f"\ngold={gold/20000:.1%} green={green/20000:.1%} brown={brown/20000:.1%}")
    cx = w // 2
    for y in range(0, h, 40):
        r_,g_,b_ = px[cx, min(y, h-1)][:3]
        print(f"  y={y:3d}: ({r_:3d},{g_:3d},{b_:3d})")
    
    if gold > 20:
        # 主菜单 -> 点击进入
        print("\n= 点击开始新农场 =")
        btn_x = r.left + 8 + 8 + 490 + 110
        btn_y = r.top + 23 + 7 + 340 + 24
        user32.SetCursorPos(btn_x, btn_y)
        time.sleep(0.3)
        user32.mouse_event(0x0002, 0, 0, 0, 0)
        time.sleep(0.05)
        user32.mouse_event(0x0004, 0, 0, 0, 0)
        time.sleep(5)
        
        img2 = ImageGrab.grab(bbox=(r.left, r.top, r.right, r.bottom))
        px2 = img2.load()
        g2 = sum(1 for _ in range(20000) 
                if (lambda r_,g_,b_: g_ > r_*1.3 and g_ > b_*1.2)
                (*px2[int((w-1)*__import__("random").random()), int((h-1)*__import__("random").random())][:3]))
        print(f"After click: green={g2/20000:.1%}")
        
        if g2 > 100:
            px = px2
            print("IN FARM SCENE!")
            
            # 测试快捷键
            print("\n= 测试 I (背包) =")
            user32.keybd_event(0x49, 0, 0, 0); time.sleep(0.05)
            user32.keybd_event(0x49, 0, 2, 0); time.sleep(1.5)
            img_i = ImageGrab.grab(bbox=(r.left, r.top, r.right, r.bottom))
            pxi = img_i.load()
            print(f"  Center after I: {pxi[w//2, h//2][:3]}")
            
            user32.keybd_event(0x49, 0, 0, 0); time.sleep(0.05)
            user32.keybd_event(0x49, 0, 2, 0); time.sleep(0.5)
            
            print("= 测试 K (烹饪) =")
            user32.keybd_event(0x4B, 0, 0, 0); time.sleep(0.05)
            user32.keybd_event(0x4B, 0, 2, 0); time.sleep(1.5)
            img_k = ImageGrab.grab(bbox=(r.left, r.top, r.right, r.bottom))
            print(f"  Center after K: {img_k.getpixel((w//2, h//2))[:3]}")
            
            user32.keybd_event(0x1B, 0, 0, 0); time.sleep(0.05)
            user32.keybd_event(0x1B, 0, 2, 0); time.sleep(0.5)
            
            print("= 测试 S (技能) =")
            user32.keybd_event(0x53, 0, 0, 0); time.sleep(0.05)
            user32.keybd_event(0x53, 0, 2, 0); time.sleep(1.5)
            img_s = ImageGrab.grab(bbox=(r.left, r.top, r.right, r.bottom))
            print(f"  Center after S: {img_s.getpixel((w//2, h//2))[:3]}")
        else:
            print("Did not enter farm")
    
    output_path = r"C:\Users\Administrator\Desktop\game_check.png"
    img.save(output_path)
    print(f"\nScreenshot saved")
else:
    print("No window found")
