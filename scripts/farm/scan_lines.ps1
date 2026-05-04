$lines = Get-Content "D:\龙虾\projects\stardew-liaofang\scripts\farm\farm_scene.gd"
for($i=0; $i -lt $lines.Length; $i++){
    $line = $lines[$i]
    # Count quotes
    $q = 0
    foreach($c in $line.ToCharArray()){ if($c -eq '"'){ $q++ } }
    $is_odd = $q % 2 -eq 1
    
    $has_problem = $false
    # Check for odd quotes
    if($is_odd -and $q -gt 0){ $has_problem = $true }
    
    # Check for garbled emoji characters
    if($line -match '馃'){ $has_problem = $true }
    if($line -match '鉂'){ $has_problem = $true }
    if($line -match '蝯'){ $has_problem = $true }
    
    # Check for garbled Chinese in strings (unlikely pattern)
    if($line -match '#.*"[,\s\)\]]'){ $has_problem = $true }
    
    if($has_problem){
        Write-Host "=== Line $($i+1) (quotes=$q) ==="
        Write-Host "$line"
    }
}
