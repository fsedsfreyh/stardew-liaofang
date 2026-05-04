#!/usr/bin/env python3
"""Scan for private-use area characters (PUA) in the file - these are corruption remnants."""
fpath = r"D:\龙虾\projects\stardew-liaofang\scripts\farm\farm_scene.gd"

with open(fpath, 'r', encoding='utf-8') as f:
    content = f.read()
    lines = content.split('\n')

out = open(r"D:\龙虾\projects\stardew-liaofang\scripts\farm\pua_report.txt", 'w', encoding='utf-8')

for i, line in enumerate(lines):
    for j, c in enumerate(line):
        cp = ord(c)
        if 0xE000 <= cp <= 0xF8FF:
            out.write("Line %d, pos %d: PUA U+%04X\n  Full line: %s\n\n" % (i+1, j, cp, line[:120]))

out.close()
print("Done")
