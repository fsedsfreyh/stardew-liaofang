path = r'D:\龙虾\projects\stardew-liaofang\scripts\core\pixel_artist.gd'
with open(path, 'r', encoding='utf-8') as f:
    content = f.read()
print("Last 100 chars:")
print(repr(content[-100:]))
print(f"\nTotal chars: {len(content)}")
print(f"Total lines: {content.count(chr(10))}")
