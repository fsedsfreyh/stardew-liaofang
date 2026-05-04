import os, sys, re
sys.stdout.reconfigure(encoding="utf-8")

proj = r"D:\龙虾\projects\stardew-liaofang"
backup = r"C:\Users\Administrator\Desktop\星露乡物语\stardew-liaofang"

# 读取当前 farm_scene.gd
with open(os.path.join(proj, "scripts", "farm", "farm_scene.gd"), "r", encoding="utf-8") as f:
    current = f.read()

# 读取备份版
with open(os.path.join(backup, "scripts", "farm", "farm_scene.gd"), "r", encoding="utf-8") as f:
    backup_content = f.read()

# 提取备份版的所有函数
all_backup_funcs = {}
for m in re.finditer(r'(^func \w+\([^)]*\).*?\n(?:\t.*\n?)*)', backup_content, re.MULTILINE):
    name = m.group(1).split("(")[0].replace("func ", "")
    all_backup_funcs[name] = m.group(1)

# 提取当前版的所有函数  
current_funcs = {}
for m in re.finditer(r'(^func \w+\([^)]*\).*?\n(?:\t.*\n?)*)', current, re.MULTILINE):
    name = m.group(1).split("(")[0].replace("func ", "")
    current_funcs[name] = m.group(1)

print(f"备份版函数: {len(all_backup_funcs)}")
print(f"当前版函数: {len(current_funcs)}")

# 找出缺失的函数（当前没有但备份里有）
missing = []
for name in all_backup_funcs:
    if name not in current_funcs:
        missing.append(name)

print(f"当前版缺失的函数(来自备份):")
for name in sorted(missing):
    print(f"  func {name}")

# 找出当前版有自己的但备份里没有的
extra = []
for name in current_funcs:
    if name not in all_backup_funcs:
        extra.append(name)

if extra:
    print(f"当前版独有的函数(不在备份中):")
    for name in extra:
        print(f"  func {name}")

if not missing:
    print("✅ 当前版函数与备份版一致")
    # 检查精确内容差异
    for name in all_backup_funcs:
        if name in current_funcs:
            if all_backup_funcs[name] != current_funcs[name]:
                print(f"⚠️  func {name} 内容不同（可能是安全连接修复）")
