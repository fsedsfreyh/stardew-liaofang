# 星露乡物语 一键启动
$godot = "C:\Program Files\Godot_v4.6.2\Godot_v4.6.2-stable_win64.exe"
$proj = "D:\龙虾\projects\stardew-liaofang"

Get-Process -Name Godot_v4* -ErrorAction SilentlyContinue | ForEach-Object {
    Write-Host "Killing PID $($_.Id)..."
    $_.Kill()
}
Start-Sleep 2

Write-Host "Starting Godot 4.6.2 + OpenGL3..."
Start-Process -NoNewWindow -FilePath $godot -ArgumentList "--path", $proj, "--rendering-driver", "opengl3"
Start-Sleep 10

Write-Host "Restoring window..."
D:\autociaw\AutoClaw\resources\python\python.exe D:\龙虾\projects\stardew-liaofang\restore_window.py

Write-Host ""
Write-Host "============================================"
Write-Host "  星露乡物语 - Stardew Liaofang"
Write-Host "  Running on OpenGL3 (AMD Vulkan fix)"
Write-Host "============================================"
Write-Host "Controls: WASD=Move E=Interact F=UseItem"
Write-Host "          B=Shop C=Craft V=Achieve J=Fish"
Write-Host "============================================"