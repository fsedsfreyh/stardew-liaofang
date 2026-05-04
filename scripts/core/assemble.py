#!/usr/bin/env python3
"""Assemble the complete pixel_artist.gd from parts"""

PARTS = [
    # Part 0: Header, helpers, tile functions
    "parts/000_header.tmp",
    "parts/001_tiles.tmp",
    "parts/002_player.tmp",
    "parts/003_liaofang.tmp",
    "parts/004_crop.tmp",
    "parts/005_items.tmp",
    "parts/006_pet_npc.tmp",
]

if __name__ == "__main__":
    out_path = r"D:\龙虾\projects\stardew-liaofang\scripts\core\pixel_artist.gd"
    with open(out_path, "w", encoding="utf-8") as out:
        out.write("# PixelArtist — 像素素材生成器（星露谷物语完全复刻版）增强画质版\n")
        out.write("# 瓦片 16×16 → 2x → 32×32，角色 16×32 源 → 2x → 32×64\n")
        out.write("# 所有函数签名与原始版本完全兼容（原版函数全部保留）\n")
        out.write("extends Node\n\n")
        # Rest is in parts
        for p in PARTS:
            import os
            fpath = os.path.join(os.path.dirname(__file__), p)
            if os.path.exists(fpath):
                with open(fpath, "r", encoding="utf-8") as f:
                    out.write(f.read())
                out.write("\n")
            else:
                print(f"Warning: {p} not found")
    print(f"Written {out_path}")
    print(f"Size: {os.path.getsize(out_path)} bytes")
