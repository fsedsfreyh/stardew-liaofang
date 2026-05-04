import os, re, sys, subprocess, ctypes, ctypes.wintypes, time
sys.stdout.reconfigure(encoding="utf-8")
from PIL import ImageGrab

proj = r"D:\龙虾\projects\stardew-liaofang"
backup = r"C:\Users\Administrator\Desktop\星露乡物语\stardew-liaofang"
godot = r"C:\Program Files\Godot_v4.6.2\Godot_v4.6.2-stable_win64.exe"

# 读取文件
with open(os.path.join(proj, "scripts", "farm", "farm_scene.gd"), "r", encoding="utf-8") as f:
    current = f.read()

with open(os.path.join(backup, "scripts", "farm", "farm_scene.gd"), "r", encoding="utf-8") as f:
    backup_content = f.read()

# 提取备份版的所有函数
all_backup_funcs = {}
for m in re.finditer(r'(^func \w+\([^)]*\).*?\n(?:\t.*\n?)*)', backup_content, re.MULTILINE):
    name = m.group(1).split("(")[0].replace("func ", "")
    all_backup_funcs[name] = m.group(1)

# 提取当前版
current_func_names = set()
for m in re.finditer(r'^func \w+\(', current, re.MULTILINE):
    current_func_names.add(m.group(0).split("(")[0].replace("func ", ""))

# 需要添加的函数列表（按合理顺序）
needed = ["_world_to_tile", "_tile_top_left", "_tile_center", 
          "_get_tile_texture", "_get_available_seed", "_try_consume_stamina",
          "_show_guide_step", "_advance_guide", "_skip_guide", "_hide_guide",
          "_open_mail", "is_walkable"]

# 找到当前脚本的最后一个函数
last_func_match = list(re.finditer(r'(^func \w+\([^)]*\).*?\n(?:\t.*\n?)*)', current, re.MULTILINE))[-1]
insert_pos = last_func_match.end()

# 构建被添加的代码块
add_code = ""
for name in needed:
    if name in all_backup_funcs and name not in current_func_names:
        add_code += "\n" + all_backup_funcs[name]
        print(f"  添加: func {name}")
    else:
        print(f"  ⚠️ 跳过: {name}")

# 在最后一个函数后面插入
script = current[:insert_pos] + add_code + current[insert_pos:]

print(f"\n写入前: {len(current)} chars, {current.count(chr(10))} lines")
print(f"写入后: {len(script)} chars, {script.count(chr(10))} lines")

with open(os.path.join(proj, "scripts", "farm", "farm_scene.gd"), "w", encoding="utf-8") as f:
    f.write(script)

print("\n✅ 写入完成")

# 编译验证
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
    errors = [l for l in result.stderr.split("\n") + result.stdout.split("\n") if "ERROR" in l or "error" in l or "Parse" in l]
    print(f"Compile FAIL ({result.returncode})")
    for e in errors[:15]:
        print(f"  {e.strip()}")
    sys.exit(1)

# 启动游戏测试
subprocess.run(["powershell", "-Command", 
    f'Start-Process "{godot}" -ArgumentList "--rendering-driver opengl3 --path `"{proj}`""'],
    capture_output=True, timeout=5)
time.sleep(18)

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
    
    # 先截全屏再裁剪（避免PIL截图区域问题）
    full = ImageGrab.grab()
    img = full.crop((r.left, r.top, r.right, r.bottom))
    px = img.load()
    
    # 颜色分析
    gold = sum(1 for _ in range(20000) if (lambda r_,g_,b_: r_ > 150 and g_ > 100 and b_ < 100)
               (*px[int((w-1)*__import__('random').random()), int((h-1)*__import__('random').random())][:3]))
    brown = sum(1 for _ in range(20000) if (lambda r_,g_,b_: r_ < 60 and g_ < 40 and b_ < 25)
               (*px[int((w-1)*__import__('random').random()), int((h-1)*__import__('random').random())][:3]))
    
    print(f"\ngold={gold/20000:.1%} brown={brown/20000:.1%}")
    cx = w // 2
    for y in range(0, h, 40):
        r_,g_,b_ = px[cx, min(y, h-1)][:3]
        print(f"  y={y:3d}: ({r_:3d},{g_:3d},{b_:3d})")
    
    img.save("C:\\Users\\Administrator\\Desktop\\full_check_final.png")
    print("\n截图已保存到桌面")
else:
    print("未找到游戏窗口")
