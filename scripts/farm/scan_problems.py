#!/usr/bin/env python3
"""Scan for remaining corrupted lines."""
fpath = r"D:\龙虾\projects\stardew-liaofang\scripts\farm\farm_scene.gd"

with open(fpath, 'r', encoding='utf-8') as f:
    lines = f.readlines()

out = open(r"D:\龙虾\projects\stardew-liaofang\scripts\farm\problem_scan.txt", 'w', encoding='utf-8')

# Check ALL lines for odd quotes
out.write("=== Odd quotes ===\n")
for i, line in enumerate(lines):
    ln = i + 1
    s = line.rstrip()
    q = s.count('"')
    if q % 2 == 1 and q > 0:
        out.write("Line %d: ODD QUOTE (%d) -> %s\n" % (ln, q, s))

# Known mangled chars from BOM corruption
mangled_chars = set("鏂扮殑涓€澶╋紒瀛妭鑹茶皟瑕嗙洊灞浣撳姏鏉寮瑰嚭閽撻奔久鎴鍐滃満烘彛宸︿笅鈫掑皬闀充笂．鏋鐭挎礊堟凡瑙ｉ攣鐗╁搧渚ц竟鏍鏅ㄩ棿绠鎶寤栬姵ョ▼锛啘鏃皵鏁堟煇濂芥劅搴铔嬶紓楦¤垗у崼涔板叆埜闆ぉ鎻愮ず氬�笉鑳藉晢瀹㈣€曚綔馃鉂\ue6e7\ue602\ue044\ue048\ue5df")

out.write("\n=== Mangling check ===\n")
for i, line in enumerate(lines):
    found = []
    seen = set()
    for c in line:
        if c in mangled_chars and c not in seen:
            found.append(repr(c)[1:-1])
            seen.add(c)
    if found:
        out.write("Line %d: found %s\n  -> %s\n" % (i+1, found, line.rstrip()[:120]))

out.close()
print("Done")
