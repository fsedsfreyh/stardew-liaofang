import os
proj = r"D:\龙虾\projects\stardew-liaofang"

pg_content = """; Engine configuration file.
; It's best edited using the editor UI and not directly,
; since the parameters that go here are not all obvious.
;
; Format:
;   [section] ; section goes between []
;   param=value ; assign values to parameters

config_version=5

[application]

run/main_scene="res://scenes/core/main_menu.tscn"
config/features=PackedStringArray("4.6")

[autoload]

SkillSystem="*res://scripts/core/skill_system.gd"
AudioManager="*res://scripts/core/audio_manager.gd"
PixelArtist="*res://scripts/core/pixel_artist.gd"
Global="*res://autoloads/global.gd"
DayTime="*res://scripts/core/day_time.gd"
Affection="*res://scripts/core/affection_system.gd"
Inventory="*res://scripts/core/inventory_manager.gd"
SaveManager="*res://scripts/core/save_manager.gd"
DialogueManager="*res://scenes/ui/dialogue_ui.tscn"
QuestManager="*res://scripts/core/quest_manager.gd"
HouseUpgrade="*res://scripts/core/house_upgrade.gd"
MailManager="*res://scripts/core/mail_manager.gd"
AchievementUI="*res://scenes/ui/achievement_ui.tscn"
FestivalManager="*res://scripts/core/festival_manager.gd"

[display]

window/size/viewport_width=1280
window/size/viewport_height=720

[rendering]

textures/canvas_textures/default_texture_filter=1
renderer/rendering_method="gl_compatibility"

[filesystem]

import/blender/enabled=false
"""

pg_path = os.path.join(proj, "project.godot")
with open(pg_path, "w", encoding="utf-8") as f:
    f.write(pg_content)

# Verify no BOM
with open(pg_path, "rb") as f:
    fb = f.read(3)
    print(f"First 3 bytes: {[b for b in fb]}")
    if fb == b"\xef\xbb\xbf":
        print("HAS BOM!")
    else:
        print("NO BOM - clean")
    
    text = f.read().decode("utf-8")
    if "main_menu" in text:
        print("main_scene correctly points to main_menu")
    else:
        print("WRONG main_scene!")
