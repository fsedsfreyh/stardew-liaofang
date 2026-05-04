import ctypes, subprocess, sys
from ctypes import wintypes

u = ctypes.windll.user32
r = subprocess.run(["tasklist", "/FO", "CSV"], capture_output=True, text=False)
text = r.stdout.decode("gbk", errors="replace")
pid = None
for line in text.splitlines():
    if "Godot_v4" in line:
        parts = line.split(",")
        if len(parts) >= 2:
            raw = parts[1].strip()
            raw = raw.replace('"', "").strip()
            pid = int(raw)
            break

if not pid:
    print("No Godot process found")
    sys.exit(1)

found = []
def cb(h, p):
    buf = ctypes.create_unicode_buffer(256)
    u.GetWindowTextW(h, buf, 256)
    t = buf.value
    pid2 = ctypes.c_ulong()
    u.GetWindowThreadProcessId(h, ctypes.byref(pid2))
    if pid2.value == pid:
        rect = wintypes.RECT()
        u.GetWindowRect(h, ctypes.byref(rect))
        w = rect.right - rect.left
        h2 = rect.bottom - rect.top
        found.append((h, t, w, h2, bool(u.IsWindowVisible(h))))
    return True

proc = ctypes.WINFUNCTYPE(ctypes.c_bool, ctypes.c_int, ctypes.c_int)
u.EnumWindows(proc(cb), 0)

for h, t, w, h2, vis in found:
    if w > 100 and vis:
        print(f"Window: {h} ({w}x{h2}) visible={vis}")
        u.SetWindowPos(h, -1, 200, 100, 1280, 720, 0x0040)
        u.ShowWindow(h, 9)
        u.SetForegroundWindow(h)
        print("Window restored to 1280x720 at (200,100)")
        break