#!/usr/bin/env python3
"""Fix remaining corrupted comment lines using raw byte offsets."""
fpath = r"D:\龙虾\projects\stardew-liaofang\scripts\farm\farm_scene.gd"

with open(fpath, 'rb') as f:
    data = bytearray(f.read())

# Each fix: (old_bytes, new_bytes)
# These are the UTF-8 bytes of the corrupted text
fixes = []

# 1. Line 19: first occurrence of 鏂版墜寮曞 with PUA
# Find position 19's corruption 
# Let's find by searching for the specific byte pattern for line 19
# The line 19 text starts with: 0a 23 20 e9 8f 82...
# Let's just find by looking for the PUA bytes

# Actually, let me take a smarter approach - fix by known line offsets
lines = data.split(b'\n')

fix_map = {
    # Line 19 (0-indexed): # 新手引导
    18: b'# 新手引导',
    # Line 682 (0-indexed): # 新手引导 
    681: b'# 新手引导',
    # Line 718 (0-indexed): # 邮件系统
    717: b'# 邮件系统',
    # Line 803 (0-indexed): # 钓鱼点（池塘边）
    802: b'\t# 钓鱼点（池塘边）',
    # Line 820 (0-indexed): # 浮标提示
    819: b'\t# 浮标提示',
    # Line 987 (0-indexed): # 持续下落循环
    986: b'\t# 持续下落循环',
}

for idx, new_line in fix_map.items():
    if idx < len(lines):
        old_line = lines[idx]
        if old_line != new_line:
            print("Line %d: %s -> %s" % (idx+1, old_line[:60], new_line[:60]))
            lines[idx] = new_line

# Reassemble
result = b'\n'.join(lines)

# Write back
with open(fpath, 'wb') as f:
    f.write(result)

print("\nDone.")
