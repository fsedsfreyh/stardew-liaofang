param(
    [string]$file = "D:\龙虾\projects\stardew-liaofang\scripts\farm\farm_scene.gd"
)

$enc = [System.Text.UTF8Encoding]::new($false)
$content = [System.IO.File]::ReadAllText($file, $enc)

# Fix 1: Missing "var town_exit = Area2D.new()" before line 786
$content = $content.Replace(
    "`t# 左下出口→小镇`n`town_exit.name = ""TownExit""",
    "`t# 左下出口→小镇`n`tvar town_exit = Area2D.new()`n`town_exit.name = ""TownExit"""
)

# Fix 2: Missing "var forest_exit = Area2D.new()" before line 797
$content = $content.Replace(
    "`t# 右上出口→森林`n`forest_exit.name = ""ForestExit""",
    "`t# 右上出口→森林`n`tvar forest_exit = Area2D.new()`n`forest_exit.name = ""ForestExit"""
)

# Fix 3: Missing "var fish_game" before _on_fishing_spot_entered
# The fish_game is used in _on_fishing_spot_entered(). We need to add a var declaration.
# Better approach: declare it at the top of _on_fishing_spot_entered
$oldFish = "`t# 弹出钓鱼小游戏`n`tif not fish_game:"
$newFish = "`tvar fish_game = null`n`t# 弹出钓鱼小游戏`n`tif not fish_game:"
if ($content.Contains($oldFish)) {
    $content = $content.Replace($oldFish, $newFish)
} else {
    Write-Host "WARNING: fish_game pattern not found!"
}

# Fix 4: The for c in weather_layer.get_children() was consumed by # 清除旧粒子
$oldWeather = "`t# 清除旧粒子`n`t`tc.queue_free()"
$newWeather = "`t# 清除旧粒子`n`tfor c in weather_layer.get_children():`n`t`tc.queue_free()"
if ($content.Contains($oldWeather)) {
    $content = $content.Replace($oldWeather, $newWeather)
} else {
    Write-Host "WARNING: weather cleanup pattern not found!"
}

# Fix 5: Missing "func _refresh_inv_panel():" before inv panel refresh code
$oldInv = "# 物品侧边栏 & 晨间简报`n`tvar items = []"
$newInv = "func _refresh_inv_panel():`n# 物品侧边栏`n`tvar items = []"
if ($content.Contains($oldInv)) {
    $content = $content.Replace($oldInv, $newInv)
} else {
    Write-Host "WARNING: _refresh_inv_panel pattern not found! Checking raw content..."
}

Write-Host "Writing fixed file..."
[System.IO.File]::WriteAllBytes($file, [System.Text.Encoding]::GetBytes($enc).GetBytes($content))
Write-Host "Done!"
