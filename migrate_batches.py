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

back_funcs = {}
for fname in ["_generate_map", "_draw_tiles", "_setup_farm_core", "_setup_connections",
              "_sync_all_crop_sprites", "_sync_all_state_overlays",
              "_on_farm_tile_changed", "_on_crop_harvested",
              "_setup_players_and_npcs", "_setup_farm_exit", "_setup_ui",
              "_start_guide", "_check_mail"]:
    back_funcs[fname] = extract_func(backup, fname)

header_match = re.match(r'(extends Node2D.*?)(?=\nfunc\s)', backup, re.DOTALL)
var_decls = header_match.group(1) if header_match else "extends Node2D"

# 要逐个测试的批次
batches = [
    # Batch 1: 核心功能 + 信号（base确认OK）
    ("1-core+signals", ["_setup_connections", "_sync_all_crop_sprites", "_sync_all_state_overlays",
                        "_on_farm_tile_changed", "_on_crop_harvested"]),
    # Batch 2: 玩家/NPC
    ("2-players", ["_setup_players_and_npcs"]),
    # Batch 3: 退出
    ("3-exit", ["_setup_farm_exit"]),
    # Batch 4: UI层
    ("4-ui", ["_setup_ui"]),
    # Batch 5: 引导+邮件
    ("5-guide", ["_start_guide", "_check_mail"]),
]

for batch_name, funcs_to_add in batches:
    # 重新构建脚本
    script = var_decls + "\n\n"
    script += "func _ready():\n\tcall_deferred(\"_deferred_init\")\n\n"
    script += "func _deferred_init():\n\t_generate_map()\n\t_setup_farm_core()\n"
    for f in funcs_to_add:
        script += f"\t_{f}()\n" if f.startswith("setup") or f.startswith("sync") else f"\t{f}()\n"
    script += "\n"
    # 所有函数定义
    script += back_funcs["_generate_map"] + "\n"
    script += back_funcs["_draw_tiles"] + "\n"
    script += back_funcs["_setup_farm_core"] + "\n"
    for f in funcs_to_add:
        script += back_funcs[f] + "\n"
    # 占位
    script += "func _on_inventory_changed():\n\tpass\n\n"
    
    # 编译
    with open(farm_path, "w", encoding="utf-8") as f:
        f.write(script)
    
    result = subprocess.run([godot, "--rendering-driver", "opengl3", "--path", proj, "--quit"],
                           capture_output=True, text=True, timeout=30)
    if result.returncode != 0:
        errors = [l for l in result.stderr.split("\n") if "error" in l.lower() or "parse" in l.lower()]
        print(f"\n{batch_name}: COMPILE FAIL!")
        for e in errors[:3]: print(f"  {e.strip()}")
        continue
    
    # 启动 + 截图
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
        p = os.path.join(proj, f"ss_{batch_name}.png")
        img.save(p)
        px = img.load()
        g = sum(1 for _ in range(30000) 
                if (lambda r_,g_,b_: g_ > r_*1.3 and g_ > b_*1.2)
                (*px[int((w-1)*__import__("random").random()), int((h-1)*__import__("random").random())][:3]))
        print(f"\n{batch_name}: green={g/30000:.1%} ({w}x{h})")
    else:
        print(f"\n{batch_name}: No window")
    
    os.system(f"taskkill /F /PID {proc.pid} 2>nul")
    os.system("taskkill /F /IM Godot_v4* 2>nul")
    time.sleep(2)
