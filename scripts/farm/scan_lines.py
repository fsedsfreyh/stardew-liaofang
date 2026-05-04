#!/usr/bin/env python3
"""Scan farm_scene.gd for corrupted lines caused by UTF-8 BOM damage."""

import sys

fpath = r"D:\龙虾\projects\stardew-liaofang\scripts\farm\farm_scene.gd"

with open(fpath, 'r', encoding='utf-8') as f:
    lines = f.readlines()

# Write output to file to avoid console encoding issues
outpath = r"D:\龙虾\projects\stardew-liaofang\scripts\farm\scan_report.txt"
out = open(outpath, 'w', encoding='utf-8')

problem_lines = []

for i, line in enumerate(lines):
    line_num = i + 1
    stripped = line.rstrip('\n').rstrip('\r')
    
    # Count double quotes
    q_count = stripped.count('"')
    q_odd = (q_count % 2 == 1) and q_count > 0
    
    # Special: check for 铡 (U+94E1) which might be from '?' -> '"' mangling
    garbled_chars = []
    for j, c in enumerate(stripped):
        code = ord(c)
        # Non-ASCII, non-BMP, or suspicious
        if code > 0x4E00 and code < 0x9FFF:
            pass  # Normal CJK
        elif code >= 0xD800 and code <= 0xDFFF:
            garbled_chars.append(f"U+{code:04X}(surrogate)")
        elif code >= 0xFFF0 and code <= 0xFFFF:
            if code == 0xFFFD:
                garbled_chars.append("U+FFFD")
        elif code >= 0xE000 and code <= 0xF8FF:
            pass  # Private use area
    
    # Check for specific garbled chars
    text_check = stripped
    # Characters that indicate corruption
    bad_indicators = []
    # Check for emoji corruption pattern (surrogates)
    for c in stripped:
        if ord(c) >= 0xD800 and ord(c) <= 0xDFFF:
            bad_indicators.append(f"surrogate(0x{ord(c):04X})")
    
    problems = []
    if q_odd:
        problems.append(f"ODD_QUOTES({q_count})")
    if bad_indicators:
        problems.append(f"EMOJI_GARBLED({','.join(bad_indicators)})")
    
    # Check for lines that are comments with Chinese ending in "
    # This is the "?" -> '"' corruption pattern
    if '#' in stripped:
        comment_start = stripped.index('#')
        comment_text = stripped[comment_start:]
        # If comment has Chinese chars followed by " that doesn't look right
        # Like: # 体力�"  or # 好感度"
        import re
        # Find pattern: Chinese char followed by " that isn't a string opener
        matches = re.findall(r'[\u4e00-\u9fff]\"', comment_text)
        if matches:
            problems.append(f"CHINESE_QUOTE({','.join(matches)})")
    
    if problems:
        problem_lines.append((line_num, q_count, problems, stripped))

out.write(f"Total lines: {len(lines)}\n")
out.write(f"Problem lines found: {len(problem_lines)}\n\n")

for line_num, q_count, problems, text in problem_lines:
    out.write(f"=== Line {line_num} (quotes={q_count}) [{', '.join(problems)}] ===\n")
    # Show hex dump of problematic chars
    for j, c in enumerate(text):
        if ord(c) > 127:
            out.write(f"  pos={j} char={c!r} U+{ord(c):04X}\n")
    out.write(f"TEXT: {text}\n\n")

out.close()
print(f"Report written to {outpath}")
