#!/usr/bin/env python3
"""Verify the fix was applied correctly."""
fpath = r"D:\龙虾\projects\stardew-liaofang\scripts\farm\farm_scene.gd"

with open(fpath, 'r', encoding='utf-8') as f:
    lines = f.readlines()

outpath = r"D:\龙虾\projects\stardew-liaofang\scripts\farm\verify_report.txt"
with open(outpath, 'w', encoding='utf-8') as out:
    out.write(f"Total lines: {len(lines)}\n\n")
    
    # Check odd quotes
    has_issues = False
    for i, line in enumerate(lines):
        q = line.count('"')
        if q % 2 == 1 and q > 0:
            out.write(f"Line {i+1}: ODD QUOTES ({q}) -> {line.rstrip()}\n")
            has_issues = True
    
    if not has_issues:
        out.write("No odd-quote issues found!\n")
    
    out.write("\n")
    
    # Check for known bad chars
    bad_chars = ['馃', '鉂', '蝯', '寤栬', '鍐']
    found_any = False
    for bad in bad_chars:
        for i, line in enumerate(lines):
            if bad in line:
                out.write(f"Line {i+1}: still has '{bad}' -> {line.rstrip()[:120]}\n")
                for j, c in enumerate(line):
                    if ord(c) > 127:
                        out.write(f"  pos {j}: U+{ord(c):04X} '{c}'\n")
                found_any = True
    
    if not found_any:
        out.write("No known bad characters found!\n")
    
    # Show fixed lines
    out.write("\n=== Fixed content around problem areas ===\n")
    for i, line in enumerate(lines):
        line_num = i + 1
        stripped = line.rstrip()
        if line_num in [89, 92, 95, 114, 162, 441, 448, 558, 561, 566, 
                        575, 577, 579, 581, 738, 761, 762, 767, 779, 
                        781, 792, 806, 840, 951, 961]:
            out.write(f"Line {line_num}: {stripped}\n")

print(f"Report written to {outpath}")
