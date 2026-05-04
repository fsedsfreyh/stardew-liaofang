#!/usr/bin/env python3
"""Fix UTF-8 BOM corruption in farm_scene.gd - comprehensive version."""

fpath = r"D:\龙虾\projects\stardew-liaofang\scripts\farm\farm_scene.gd"

with open(fpath, 'r', encoding='utf-8') as f:
    lines = f.readlines()

result = []
fixes = []

# Map: line_num -> new_line_content (without trailing CRLF)
LINE_FIXES = {
    # Line 89: gold_label.text emoji
    89: '\tgold_label.text = "💰 " + str(Inventory.gold) + " G"',
    # Line 92: gold_label.text same
    92: '\t\tgold_label.text = "💰 " + str(Inventory.gold) + " G"',
    # Line 95: comment about stamina bar
    95: '\t# 体力条\tvar st_bar_bg = Panel.new()',
    # Line 162: mail button emoji
    162: '\tmail_btn.text = "📬"',
    # Line 448: affection display string
    448: '\taff_label.text = "❤" + str(hearts) + " 好感度"',
    # Line 558: daily report comment  
    558: '\t# 每 日 20:00 日报',
    # Line 561: liaofang schedule comment
    561: '\t# 廖芳日程：12:00-18:00 在农场\t_update_liaofang_presence(hour)',
    # Line 566: season overlay comment
    566: '\t# 季节色调覆盖层\tvar overlay = get_node_or_null("SeasonOverlay")',
    # Line 575: spring
    575: '\t\t0: # 春 - 淡粉',
    # Line 577: summer
    577: '\t\t1: # 夏 - 淡金',
    # Line 579: autumn
    579: '\t\t2: # 秋 - 淡橙',
    # Line 581: winter
    581: '\t\t3: # 冬 - 淡蓝/白\t\t\toverlay.color = Color(0.9, 0.95, 1.0, 0.06)',
    # Line 738: comment before _refresh_inv_panel
    738: '# 物品侧边栏 & 晨间简报',
    # Line 761: briefing title
    761: '\ttitle.text = "📋 第%d天 · %s季" % [day, season_names[season]]',
    # Line 762: briefing body
    762: '\tbody.text = "今天天气：%s\\n\\n" % w_names[weather]',
    # Line 767: body text with hearts
    767: '\tbody.text += "💰 廖芳好感：%d❤️\\n" % heart',
    # Line 768: weather hint for rain
    768: '\tif weather == 2: body.text += "\\n🌧️ 雨天提示：作物今天自动浇水！"',
    # Line 769: weather hint for snow
    769: '\telif weather == 3: body.text += "\\n❄️ 雪天提示：今天不能耕作！"',
    # Line 779: farm exit comment
    779: '# 农场出口 → 小镇',
    # Line 781: town exit comment
    781: '\t# 左下出口→小镇',
    # Line 792: forest exit comment
    792: '\t# 右上出口→森林',
    # Line 806: mine exit comment
    806: '\t# 右上矿洞出口（如果已解锁）',
    # Line 840: fish game popup comment
    840: '\t# 弹出钓鱼小游戏',
    # Line 873: mine lock text
    873: '\t\tlock.text = "⛏ 城北矿洞（需在商店购买入场券）"',
    # Line 907: chicken produce notice
    907: '\t\t_show_notice("🐔 鸡舍产出 2 个鸡蛋！")',
    # Line 910: cow produce notice
    910: '\t\t_show_notice("🐄 牛栏产出 2 瓶牛奶！")',
    # Line 951: weather effects header
    951: '# 🌤️ 天气效果',
    # Line 961: clear particles comment
    961: '\t# 清除旧粒子',
    # Line 759: season_names array - fix corrupted Chinese
    759: '\tvar season_names = ["春", "夏", "秋", "冬"]',
    # Line 760: weather_names array - fix emoji corruption
    760: '\tvar w_names = ["☀️ 晴", "🌤️ 阴", "🌧️ 雨", "❄️ 雪"]',
    # Line 765: unread mail hint
    765: '\t\tif unread > 0: body.text += "📬 你有 %d 封未读邮件！\\n" % unread',
    # Line 114: stamina label (already fine but verify)
    114: '\tst_label.text = "体力: 100/100"',
    # Line 441: stamina format string
    441: '\tst_label.text = "体力: %d/%d" % [st, max_st]',
    # Line 726: mail button text
    726: '\t\tbtn.text = "📬" if unread == 0 else "📬 [%d]" % unread',
}

print(f"Applying fixes to {len(LINE_FIXES)} lines...")

for i, line in enumerate(lines):
    line_num = i + 1
    if line_num in LINE_FIXES:
        old_text = line.rstrip('\r\n')
        new_text = LINE_FIXES[line_num]
        if old_text != new_text:
            fix_info = f"Line {line_num}:\n  OLD: {old_text[80:] if len(old_text)>80 else old_text}\n  NEW: {new_text[80:] if len(new_text)>80 else new_text}\n"
            fixes.append(fix_info)
        result.append(new_text + ('\r\n' if line.endswith('\r\n') else '\n'))
    else:
        result.append(line)

# Write fixed file
with open(fpath, 'w', encoding='utf-8', newline='\r\n') as f:
    f.writelines(result)

print(f"Applied {len(fixes)} fixes:")
for f in fixes:
    print(f)

# Verify
with open(fpath, 'r', encoding='utf-8') as f:
    verify_lines = f.readlines()

remaining_issues = []
for i, line in enumerate(verify_lines):
    q = line.count('"')
    if q % 2 == 1 and q > 0:
        remaining_issues.append(f"Line {i+1}: odd quotes ({q}) -> {line.rstrip()[:100]}")

if remaining_issues:
    print("\nRemaining odd-quote issues:")
    for r in remaining_issues:
        print(f"  {r}")

# Also check for GUIDE_STEPS (lines 24-30)
print("\n=== GUIDE_STEPS content ===")
for i in range(23, 31):
    if i < len(verify_lines):
        print(f"  Line {i+1}: {verify_lines[i].rstrip()}")

print("\nDone! Fixed file written.")
