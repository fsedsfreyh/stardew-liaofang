#!/usr/bin/env python3
"""Final verification of the fixed file."""
fpath = r"D:\龙虾\projects\stardew-liaofang\scripts\farm\farm_scene.gd"

with open(fpath, 'r', encoding='utf-8') as f:
    lines = f.readlines()

report = []
report.append(f"=== VERIFICATION REPORT ===")
report.append(f"Total lines: {len(lines)}")
report.append("")

# 1. Check odd quotes
odd_quote_lines = []
for i, line in enumerate(lines):
    q = line.count('"')
    if q % 2 == 1 and q > 0:
        odd_quote_lines.append((i+1, q, line.rstrip()))
        report.append(f"ODD QUOTE: Line {i+1} ({q} quotes): {line.rstrip()}")

if not odd_quote_lines:
    report.append("PASS: No odd-quote issues found!")
report.append("")

# 2. Check specific problem lines
problem_line_nums = [89, 92, 95, 114, 162, 441, 448, 558, 561, 566,
                     575, 577, 579, 581, 738, 759, 760, 761, 762, 765,
                     767, 768, 769, 779, 781, 792, 806, 840, 873, 907,
                     910, 951, 961]

report.append("=== Fixed lines ===")
for ln in problem_line_nums:
    if ln <= len(lines):
        report.append(f"Line {ln}: {lines[ln-1].rstrip()}")
report.append("")

# 3. Check GUIDE_STEPS
report.append("=== GUIDE_STEPS (lines 24-30) ===")
for i in range(23, min(31, len(lines))):
    report.append(f"Line {i+1}: {lines[i].rstrip()[:200]}")

# 4. Check for any remaining corrupted chars
bad_patterns = [
    ('U+9983 馃', '馃'),
    ('U+9242 鉂', '鉂'),
    ('U+5BE4 寤', '寤'),
    ('U+6FB6 澶', '澶'),  # Might be valid
]
report.append("")
report.append("=== Remaining corruption scan ===")
remaining = 0
for i, line in enumerate(lines):
    for label, char in bad_patterns:
        if char in line:
            report.append(f"Line {i+1}: contains {label}")
            remaining += 1

if remaining == 0:
    report.append("No remaining corruption found!")
report.append("")

# 5. BOM check
with open(fpath, 'rb') as f:
    header = f.read(3)
if header == b'\xef\xbb\xbf':
    report.append("WARNING: File has UTF-8 BOM!")
else:
    report.append("PASS: File is UTF-8 without BOM")

# Write report
outpath = r"D:\龙虾\projects\stardew-liaofang\scripts\farm\final_report.txt"
with open(outpath, 'w', encoding='utf-8') as f:
    for r in report:
        f.write(r + '\n')

print(f"Report saved to {outpath}")
