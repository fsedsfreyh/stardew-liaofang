import os, sys, subprocess, ctypes, ctypes.wintypes, time, re
sys.stdout.reconfigure(encoding="utf-8")
from PIL import ImageGrab

proj = r"D:\龙虾\projects\stardew-liaofang"
godot = r"C:\Program Files\Godot_v4.6.2\Godot_v4.6.2-stable_win64.exe"

print("=== 精确函数扫描 ===\n")

def scan_functions(filepath, expected_funcs):
    with open(filepath, "r", encoding="utf-8") as f:
        content = f.read()
    found = []
    missing = []
    for func in expected_funcs:
        # 匹配 func 函数名( 开头的行
        pattern = r"^func\s+" + re.escape(func) + r"\s*\("
        if re.search(pattern, content, re.MULTILINE):
            found.append(func)
        else:
            missing.append(func)
    return found, missing

# Farm Scene
farm_path = os.path.join(proj, "scripts", "farm", "farm_scene.gd")
f, m = scan_functions(farm_path, ["_generate_map", "_draw_tiles", "_setup_players_and_npcs", 
                                    "_setup_farm_core", "_setup_connections", "_setup_ui",
                                    "_setup_farm_exit", "_sync_all_crop_sprites",
                                    "_sync_all_state_overlays", "_on_farm_tile_changed",
                                    "_on_crop_harvested", "_start_guide", "_check_mail",
                                    "_on_time_changed", "_on_inventory_changed"])
print(f"farm_scene.gd: 找到 {len(f)}/15")
if m: print(f"  缺失: {m}")

# Main Menu
mm_path = os.path.join(proj, "scripts", "core", "main_menu.gd")
f, m = scan_functions(mm_path, ["_ready", "_deferred_init", "_generate_background", 
                                  "_draw", "_on_new_game", "_on_continue", 
                                  "_make_button", "_style", "_queue_draw"])
print(f"\nmain_menu.gd: 找到 {len(f)}/8")
if m: print(f"  缺失: {m}")

# Inventory
inv_path = os.path.join(proj, "scripts", "core", "inventory_manager.gd")
f, m = scan_functions(inv_path, ["add_item", "remove_item", "has_item", "use_item",
                                  "get_item_count", "_ready", "get_items_by_type"])
print(f"\ninventory_manager.gd: 找到 {len(f)}/7")
if m: print(f"  缺失: {m}")

# DayTime
dt_path = os.path.join(proj, "scripts", "core", "day_time.gd")
f, m = scan_functions(dt_path, ["set_time", "advance_time", "_on_time_tick", 
                                 "_ready", "get_time_string", "get_season_name"])
print(f"\nday_time.gd: 找到 {len(f)}/6")
if m: print(f"  缺失: {m}")

# Skill System
skill_path = os.path.join(proj, "scripts", "core", "skill_system.gd")
f, m = scan_functions(skill_path, ["add_exp", "get_level", "get_exp_for_next_level",
                                    "get_total_exp", "_ready"])
print(f"\nskill_system.gd: 找到 {len(f)}/5")
if m: print(f"  缺失: {m}")

# Audio Manager
audio_path = os.path.join(proj, "scripts", "core", "audio_manager.gd")
f, m = scan_functions(audio_path, ["play_sfx", "play_bgm", "on_scene_changed",
                                    "_ready", "stop_all"])
print(f"\naudio_manager.gd: 找到 {len(f)}/5")
if m: print(f"  缺失: {m}")

# 检查 Autoload
pg_path = os.path.join(proj, "project.godot")
with open(pg_path, "r", encoding="utf-8") as f:
    pg = f.read()
auto_section = re.search(r'\[autoload\](.*?)(?=\n\[)', pg, re.DOTALL)
if auto_section:
    autoloads = re.findall(r'^(\w+)="?\*?res://(.+)"?$', auto_section.group(1), re.MULTILINE)
    print(f"\n=== Autoload ({len(autoloads)}个) ===")
    for name, path in autoloads:
        local = os.path.join(proj, path)
        status = "✅" if os.path.exists(local) else "❌ NOT FOUND"
        print(f"  {status} {name} -> {path}")

# 现在启动游戏测试
print("\n=== 启动游戏 ===")
os.system("taskkill /F /IM Godot_v4* 2>nul")
time.sleep(2)

# 清缓存并启动
cache = os.path.join(proj, ".godot")
for _ in range(3):
    try:
        subprocess.run(["cmd", "/c", "rmdir", "/s", "/q", cache], capture_output=True, timeout=5, shell=True)
        break
    except: time.sleep(0.5)

# 不用 Popen，用 Start-Process
subprocess.run(["powershell", "-Command", 
    f'Start-Process "{godot}" -ArgumentList "--rendering-driver opengl3 --path `"{proj}`""'],
    capture_output=True, timeout=5)
time.sleep(20)

print("\n=== 游戏画面检测 ===")
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
    
    # 保存截图
    img.save(os.path.join(proj, "ss_check.png"))
    
    px = img.load()
    
    # 多区域采样
    gold = green = brown = gray = 0
    for _ in range(20000):
        x = int((w-1) * __import__("random").random())
        y = int((h-1) * __import__("random").random())
        r_,g_,b_ = px[x, y][:3]
        if r_ > 150 and g_ > 100 and b_ < 100: gold += 1
        elif g_ > r_*1.3 and g_ > b_*1.2: green += 1
        elif r_ < 60 and g_ < 40 and b_ < 25: brown += 1
        elif abs(r_-g_) < 10 and abs(g_-b_) < 10 and r_ > 20: gray += 1
    
    print(f"Window: {w}x{h}")
    print(f"gold={gold/20000:.1%} green={green/20000:.1%} brown={brown/20000:.1%} gray={gray/20000:.1%}")
    
    cx = w // 2
    print(f"\nCenter line:")
    for y in range(0, h, 40):
        r_,g_,b_ = px[cx, min(y, h-1)][:3]
        print(f"  y={y:3d}: ({r_:3d},{g_:3d},{b_:3d})")
    
    if brown > 50 and gold > 20:
        current = "MAIN_MENU"
    elif green > 50:
        current = "FARM_SCENE"
    else:
        current = "UNKNOWN/GRAY"
    
    print(f"\n当前屏幕状态: {current}")
    
    if current == "MAIN_MENU":
        # 点击"开始新农场"
        print("\n=== 点击开始新农场 ===")
        btn_x = r.left + 8 + 8 + 490 + 110
        btn_y = r.top + 23 + 7 + 340 + 24
        print(f"点击坐标: ({btn_x}, {btn_y})")
        user32.SetCursorPos(btn_x, btn_y)
        time.sleep(0.3)
        user32.mouse_event(0x0002, 0, 0, 0, 0)
        time.sleep(0.05)
        user32.mouse_event(0x0004, 0, 0, 0, 0)
        print("点击发送!")
        time.sleep(5)
        
        img2 = ImageGrab.grab(bbox=(r.left, r.top, r.right, r.bottom))
        px2 = img2.load()
        g2 = sum(1 for _ in range(20000) 
                if (lambda r_,g_,b_: g_ > r_*1.3 and g_ > b_*1.2)
                (*px2[int((w-1)*__import__("random").random()), int((h-1)*__import__("random").random())][:3]))
        print(f"点击后: green={g2/20000:.1%}")
        
        if g2 > 100:
            current = "FARM_SCENE"
            img = img2
            px = px2
            print("✅ 成功进入农场!")
        else:
            print("❌ 未能进入农场")
    
    if current == "FARM_SCENE":
        print("\n=== 农场场景测试 ===")
        # 按 I 打开背包
        print("按 I 键打开背包...")
        user32.keybd_event(0x49, 0, 0, 0)  # I down
        time.sleep(0.05)
        user32.keybd_event(0x49, 0, 2, 0)  # I up
        time.sleep(1.5)
        
        img_i = ImageGrab.grab(bbox=(r.left, r.top, r.right, r.bottom))
        px_i = img_i.load()
        # 检测背包UI (白色/灰色区域)
        cx = w // 2
        print(f"  背包中心: {px_i[cx, h//2][:3]}")
        
        # 关闭背包（再按I）
        user32.keybd_event(0x49, 0, 0, 0)
        time.sleep(0.05)
        user32.keybd_event(0x49, 0, 2, 0)
        time.sleep(0.5)
        
        # 按 S 测试技能面板
        print("按 S 键打开技能面板...")
        user32.keybd_event(0x53, 0, 0, 0)
        time.sleep(0.05)
        user32.keybd_event(0x53, 0, 2, 0)
        time.sleep(1)
        img_s = ImageGrab.grab(bbox=(r.left, r.top, r.right, r.bottom))
        px_s = img_s.load()
        center_px = px_s[w//2, h//2][:3]
        print(f"  技能面板中心: {center_px}")
        # 关闭
        user32.keybd_event(0x53, 0, 0, 0)
        time.sleep(0.05)
        user32.keybd_event(0x53, 0, 2, 0)
        time.sleep(0.5)
        
        # 按 M 测试迷你地图
        print("按 M 键打开迷你地图...")
        user32.keybd_event(0x4D, 0, 0, 0)
        time.sleep(0.05)
        user32.keybd_event(0x4D, 0, 2, 0)
        time.sleep(1)
        img_m = ImageGrab.grab(bbox=(r.left, r.top, r.right, r.bottom))
        px_m = img_m.load()
        print(f"  迷你地图中心: ({px_m[w//4, h//2][:3]})")  # 左半区看UI
        
        # 按 K 测试烹饪
        print("按 K 键打开烹饪...")
        user32.keybd_event(0x4B, 0, 0, 0)
        time.sleep(0.05)
        user32.keybd_event(0x4B, 0, 2, 0)
        time.sleep(1.5)
        img_k = ImageGrab.grab(bbox=(r.left, r.top, r.right, r.bottom))
        print(f"  烹饪中心: {img_k.getpixel((w//2, h//2))[:3]}")
        
        # 按 Esc 关闭
        user32.keybd_event(0x1B, 0, 0, 0)
        time.sleep(0.05)
        user32.keybd_event(0x1B, 0, 2, 0)
        time.sleep(0.5)
        
        # 按 WASD 移动
        print("测试 WASD 移动...")
        for key, name in [(0x57, "W"), (0x41, "A"), (0x53, "S"), (0x44, "D")]:
            user32.keybd_event(key, 0, 0, 0)
            time.sleep(0.3)
            user32.keybd_event(key, 0, 2, 0)
            time.sleep(0.1)
        print("  移动测试完成")

else:
    print("未找到游戏窗口")

print("\n=== 测试完成 ===")
