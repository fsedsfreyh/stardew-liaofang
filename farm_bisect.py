"""
用法: python farm_bisect.py [backup_dir]
二分法定位 farm_scene.gd 中导致全灰的函数
"""

import os, sys, subprocess, ctypes, ctypes.wintypes, time, re, textwrap, traceback
sys.stdout.reconfigure(encoding="utf-8")
from PIL import ImageGrab

proj = r"D:\龙虾\projects\stardew-liaofang"
godot = r"C:\Program Files\Godot_v4.6.2\Godot_v4.6.2-stable_win64.exe"

def run_powershell(cmd):
    """Run PowerShell command and return output"""
    result = subprocess.run(["powershell", "-Command", cmd],
                           capture_output=True, text=True, timeout=30)
    return result.stdout, result.stderr

def take_screenshot(output_path=None):
    """Take screenshot of the game window, return color analysis"""
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
    
    if not hwnd[0]:
        return None, None
    
    r = ctypes.wintypes.RECT()
    user32.GetWindowRect(hwnd[0], ctypes.byref(r))
    w, h = r.right - r.left, r.bottom - r.top
    
    try:
        full = ImageGrab.grab()
        img = full.crop((r.left, r.top, r.right, r.bottom))
    except:
        return None, None
    
    if img.size[0] < 10 or img.size[1] < 10:
        return None, None
    
    if output_path:
        try:
            img.save(output_path)
        except:
            pass
    
    px = img.load()
    w, h = img.size
    
    # Color analysis
    green = 0; gold = 0; brown = 0
    for _ in range(20000):
        x = __import__("random").randint(0, w-1)
        y = __import__("random").randint(0, h-1)
        r_, g_, b_ = px[x, y][:3]
        if g_ > r_ * 1.3 and g_ > b_ * 1.2:
            green += 1
        elif r_ > 150 and g_ > 100 and b_ < 100:
            gold += 1
        elif r_ < 60 and g_ < 40 and b_ < 25:
            brown += 1
    
    center_line = []
    cx = w // 2
    for y in range(0, h, 40):
        center_line.append(px[cx, min(y, h-1)][:3])
    
    return {
        "w": w, "h": h,
        "green": green/20000,
        "gold": gold/20000,
        "brown": brown/20000,
        "center_line": center_line
    }, img


# Read current farm_scene.gd - this is the "86 function" version
with open(os.path.join(proj, "scripts", "farm", "farm_scene.gd"), "r", encoding="utf-8") as f:
    current = f.read()

# ---- Backup & restore functions ----
backup_dir = r"C:\Users\Administrator\Desktop\星露乡物语\stardew-liaofang"
backup_farm = os.path.join(backup_dir, "scripts", "farm", "farm_scene.gd")

# Read backup
with open(backup_farm, "r", encoding="utf-8") as f:
    backup_content = f.read()

# Extract all funcs from backup
all_funcs = {}
for m in re.finditer(r'(^func \w+\([^)]*\).*?\n(?:\t.*\n?)*)', backup_content, re.MULTILINE):
    name = m.group(1).split("(")[0].replace("func ", "")
    all_funcs[name] = m.group(1)

print(f"Backup has {len(all_funcs)} functions")

# The minimal set that should render (from earlier ACP session)
MINIMAL = [
    "_ready", "_deferred_init",
    "_generate_map", "_draw_tiles",
    "_setup_collision", "_replace_tile",
    "_setup_players_and_npcs",
    "_setup_farm_core",
    "_setup_ui",
    "_setup_connections",
    "_setup_farm_exit", "_setup_fishing_spot",
    "_on_fishing_spot_entered", "_on_town_exit_entered",
    "_on_forest_exit_entered",
    "_setup_mine_exit", "_on_mine_exit_entered",
    "_sync_all_crop_sprites", "_sync_all_state_overlays",
    "_update_crop_sprite", "_remove_crop_sprite",
    "_update_state_overlay", "_remove_state_overlay",
    "_on_time_changed", "_on_farm_tile_changed", "_on_crop_harvested",
    "_seasonal_distractions", "_update_greenhouse_overlay",
    "_show_floating_text", "_remove_named_child",
    "_start_guide", "_check_mail",
    "_update_stamina_display", "_update_affection_display",
    "_update_liaofang_presence", "_update_weather_effects",
    "_refresh_quest_hint", "_produce_animal_goods",
    "_show_notice",
    "_select_tool", "_update_tool_highlight",
    "_input", "_unhandled_input",
    "_use_tool", "_trigger_tool_cooldown",
    "_use_hoe", "_use_watering_can", "_use_seed",
    "_harvest", "_spawn_harvest_particles",
    "_toggle_crafting", "_toggle_cooking",
    "_toggle_achievement", "_toggle_fish_album",
    "_on_morning_briefing", "_close_briefing",
    "_check_festival", "_execute_festival",
    "_spawn_rain", "_rain_loop",
    "_spawn_snow", "_snow_loop",
    "_show_daily_report", "_show_daily_costs",
    "_show_insufficient_gold_warning",
    "_refresh_inv_panel",
    "_world_to_tile", "_tile_top_left", "_tile_center",
    "_get_tile_texture", "_get_available_seed",
    "_try_consume_stamina",
    "_show_guide_step", "_advance_guide",
    "_skip_guide", "_hide_guide",
    "_open_mail",
    "is_walkable"
]

# Check which exist in backup
for f in MINIMAL:
    if f not in all_funcs:
        print(f"MISSING from backup: {f}")

# Build test script with just MINIMAL + header
h_match = re.match(r'(extends Node2D.*?)(?=\nfunc )', current, re.DOTALL)
header = h_match.group(1) if h_match else "extends Node2D"

# Build safe connections
script = header + "\n\n"
for name in MINIMAL:
    if name in all_funcs:
        fn = all_funcs[name]
        # Add is_connected safety
        fn = fn.replace(
            "farm.tile_changed.connect(_on_farm_tile_changed)",
            "if not farm.tile_changed.is_connected(_on_farm_tile_changed):\n\t\tfarm.tile_changed.connect(_on_farm_tile_changed)"
        )
        script += fn + "\n"
    else:
        print(f"WARNING: {name} not in backup, adding stub")
        script += f"func {name}():\n\tpass\n\n"

# Write it
farm_path = os.path.join(proj, "scripts", "farm", "farm_scene.gd")
with open(farm_path, "w", encoding="utf-8") as f:
    f.write(script)

print(f"\nWritten {script.count(chr(10))} lines, {len(MINIMAL)} funcs")

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
    print(f"\nCOMPILE FAIL ({result.returncode})")
    for l in result.stderr.split("\n") + result.stdout.split("\n"):
        if "ERROR" in l or "Parse" in l:
            print(f"  {l.strip()}")
    sys.exit(1)
print("Compile OK")

# Switch project.godot to farm_scene
pg_path = os.path.join(proj, "project.godot")
with open(pg_path, "r", encoding="utf-8") as f:
    pg = f.read()

pg_backup = pg

# Write farm as main_scene
pg = pg.replace(
    'run/main_scene="res://scenes/core/main_menu.tscn"',
    'run/main_scene="res://scenes/farm/farm_scene.tscn"'
)
with open(pg_path, "w", encoding="utf-8") as f:
    f.write(pg)

# KILL existing
subprocess.run(["powershell", "-Command", "Get-Process Godot* | Stop-Process -Force"], 
               capture_output=True, timeout=5)
time.sleep(2)

# Start fresh
subprocess.run(["powershell", "-Command", 
    f'Start-Process "{godot}" -ArgumentList "--rendering-driver opengl3 --path `"{proj}`""'],
    capture_output=True, timeout=5)
time.sleep(20)

# Screenshot  
data, img = take_screenshot(r"C:\Users\Administrator\Desktop\bisect_test.png")

if data is None:
    print("\nNo window found")
else:
    print(f"\nWindow: {data['w']}x{data['h']}")
    print(f"green={data['green']:.1%} gold={data['gold']:.1%} brown={data['brown']:.1%}")
    for i, c in enumerate(data['center_line']):
        print(f"  y={i*40:3d}: {c}")
    
    if data['green'] > 0.005:
        print("\n✅ GRASS RENDERED! Now testing features...")
    else:
        print(f"\n❌ No grass (green={data['green']:.6f})")

# Restore project.godot
with open(pg_path, "w", encoding="utf-8") as f:
    f.write(pg_backup)
print("\nproject.godot restored to main_menu")
