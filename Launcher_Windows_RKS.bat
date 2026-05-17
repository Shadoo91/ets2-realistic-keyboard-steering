# ===================================================================================
#   ETS2 Realistic-Keyboard-Steering (RKS) (v1.10) ~ by Shadoo91
#   [POWERSHELL PROFILE INJECTOR - FULL INDEPENDENT CORE]
# ===================================================================================

Clear-Host
Write-Host "====================================================================================" -ForegroundColor Cyan
Write-Host "   ETS2 Realistic-Keyboard-Steering (RKS) ~ Profile Manager (v1.10)" -ForegroundColor Cyan
Write-Host "====================================================================================" -ForegroundColor Cyan
Write-Host ""

$PresetFile = "./rks_preset_controls.sii"

# 1. Suchpfade für Profile definieren (Lokal, Flatpak und Steam Cloud userdata)
$Ets2DocPath = "$env:USERPROFILE\Documents\Euro Truck Simulator 2"
$Ets2CloudPaths = @(
    "$env:PROGRAMFILES(X86)\Steam\userdata",
    "$env:PROGRAMFILES\Steam\userdata"
)

$SearchPaths = [System.Collections.Generic.List[string]]::new()

if (Test-Path "$Ets2DocPath\profiles") { $SearchPaths.Add("$Ets2DocPath\profiles") }
if (Test-Path "$Ets2DocPath\steam_profiles") { $SearchPaths.Add("$Ets2DocPath\steam_profiles") }

# Steam Userdata (Cloud) Pfade durchsuchen
foreach ($SteamPath in $Ets2CloudPaths) {
    if (Test-Path $SteamPath) {
        Get-ChildItem -Path $SteamPath -Directory | ForEach-Object {
            $Ets2CloudDir = Join-Path $_.FullName "227300\remote\profiles"
            if (Test-Path $Ets2CloudDir) { $SearchPaths.Add($Ets2CloudDir) }
        }
    }
}

# Einzigartige, existierende Pfade filtern
$TargetPaths = $SearchPaths | Select-Object -Unique | Where-Object { Test-Path $_ }

if ($TargetPaths.Count -eq 0) {
    Write-Host "[ERROR] No Euro Truck Simulator 2 profile directories found!" -ForegroundColor Red
    Read-Host "Press Enter to exit..."
    exit
}

# 2. Alle controls.sii Dateien finden und auflisten
$ControlFiles = [System.Collections.Generic.List[string]] =::new()
$ControlTypes = [System.Collections.Generic.List[string]]::new()
$ControlFolders = [System.Collections.Generic.List[string]]::new()
$Index = 1

Write-Host "Detected ETS2 Profiles:" -ForegroundColor Yellow
Write-Host "------------------------------------------------------------------------------------"

foreach ($TPath in $TargetPaths) {
    Get-ChildItem -Path $TPath -Filter "controls.sii" -Recurse | ForEach-Object {
        $Folder = $_.Directory.Name
        $Type = "Local"
        if ($_.FullName -match "steam_profiles") { $Type = "Steam Copy" }
        if ($_.FullName -match "userdata") { $Type = "Steam Cloud" }
        
        $BakStatus = "[Backup: No ]"
        if (Test-Path "$($_.FullName).bak") { $BakStatus = "[Backup: Yes]" }
        
        $ControlFiles.Add($_.FullName)
        $ControlTypes.Add($Type)
        $ControlFolders.Add($Folder)
        
        Write-Host " [$Index] Folder: $Folder | Type: $Type | $BakStatus" -ForegroundColor Cyan
        $Index++
    }
}

if ($ControlFiles.Count -eq 0) {
    Write-Host "[INFO] No 'controls.sii' files found!" -ForegroundColor Yellow
    Read-Host "Press Enter to exit..."
    exit
}

Write-Host "------------------------------------------------------------------------------------"
Write-Host " [A] Patch ALL profiles  |  [R] Restore backups  |  [E] Exit" -ForegroundColor Yellow
Write-Host "------------------------------------------------------------------------------------"
Write-Host ""

$Selection = (Read-Host "Please select an option").ToUpper()

if ($Selection -eq "E") { exit }

# ==========================================
# REITER: ROLLBACK SYSTEM [R]
# ==========================================
if ($Selection -eq "R") {
    Write-Host ""
    $RollbackSel = (Read-Host "Restore ALL backups [A] or select a specific Profile Number? (A/Number)").ToUpper()
    
    $FilesToRollback = [System.Collections.Generic.List[int]]::new()
    if ($RollbackSel -eq "A") {
        for ($i = 0; $i -lt $ControlFiles.Count; $i++) { $FilesToRollback.Add($i) }
    } elseif ($RollbackSel -match "^\d+$" -and [int]$RollbackSel -le $ControlFiles.Count -and [int]$RollbackSel -gt 0) {
        $FilesToRollback.Add([int]$RollbackSel - 1)
    } else {
        Write-Host "[ERROR] Invalid selection!" -ForegroundColor Red
        exit
    }

    Write-Host "Starting Rollback System..." -ForegroundColor Cyan
    foreach ($i in $FilesToRollback) {
        $FILE = $ControlFiles[$i]
        $Folder = $ControlFolders[$i]
        if (Test-Path "$FILE.bak") {
            Set-ItemProperty -Path $FILE -Name IsReadOnly -Value $false -ErrorAction SilentlyContinue
            Copy-Item -Path "$FILE.bak" -Destination $FILE -Force
            Remove-Item -Path "$FILE.bak" -Force
            Write-Host "  -> Restored: $Folder" -ForegroundColor Green
        } else {
            Write-Host "  -> No backup found for: $Folder" -ForegroundColor Yellow
        }
    }
    Read-Host "Rollback finished. Press Enter to exit..."
    exit
}

# Auswahl für das Patchen auswerten
$FilesToPatch = [System.Collections.Generic.List[string]]::new()
if ($Selection -eq "A") {
    foreach ($f in $ControlFiles) { $FilesToPatch.Add($f) }
} else {
    if ($Selection -match "^\d+$" -and [int]$Selection -le $ControlFiles.Count -and [int]$Selection -gt 0) {
        $FilesToPatch.Add($ControlFiles[[int]$Selection - 1])
    } else {
        Write-Host "[ERROR] Invalid selection!" -ForegroundColor Red
        exit
    }
}

# ==========================================
# REITER: INJEKTOR STARTEN & GEZIELTES PATCHEN
# ==========================================
$B = [char]96  # Backtick-Konstante für SCS-Formel-Strings

$CustomFormulas = @{
    ' mix dsteerleft'  = " mix dsteerleft ${B} keyboard.a?0${B}"
    ' mix dsteerright' = " mix dsteerright ${B} keyboard.d?0${B}"
    ' mix dsteering'   = " mix dsteering ${B}(keyboard.a?0 - keyboard.d?0) * (0.40 + (keyboard.space?0 * 0.50)) * (1.00 + (keyboard.s?0 * keyboard.lalt?0 * 0.60))${B}"
    ' mix steering'    = " mix steering ${B} dsteering * (1.0 - c_steer_func)${B}"
    ' mix msteering'   = " mix msteering ${B}-mouse.rel_position.x?0 * c_msens${B}"
    ' mix mpedals'     = " mix mpedals ${B}-mouse.rel_position.y?0 * c_msens${B}"
    ' mix dforward'    = " mix dforward ${B} 0${B}"
    ' mix dbackward'   = " mix dbackward ${B} 0${B}"
    ' mix aforward'    = " mix aforward ${B}((keyboard.w?0 * 0.35) + (keyboard.lalt?0 * 0.55)) * (! keyboard.s?0)${B}"
    ' mix abackward'   = " mix abackward ${B} keyboard.s?0 * (0.10 + (keyboard.space?0 * 0.50) + (keyboard.lalt?0 * 0.90))${B}"
    ' mix forward'     = " mix forward ${B} aforward${B}"
    ' mix backward'    = " mix backward ${B} abackward${B}"
}

foreach ($FILE in $FilesToPatch) {
    $Folder = (Split-Path (Split-Path $FILE -Parent) -Leaf)
    Write-Host "Processing: $Folder" -ForegroundColor Yellow
    
    Set-ItemProperty -Path $FILE -Name IsReadOnly -Value $false -ErrorAction SilentlyContinue
    if (-not (Test-Path "$FILE.bak")) { Copy-Item -Path $FILE -Destination "$FILE.bak" }
    
    $Content = Get-Content -Path $FILE -Raw
    $Modified = $false
    
    foreach ($Key in $CustomFormulas.Keys) {
        # Dieser Regex sucht penibel nach dem exakten SCS-Zeilen-Muster inklusive der Gänsefüßchen
        # und ersetzt NUR den Inhalt sauber, OHNE zusätzliche Gänsefüßchen einzuschleusen!
        $Pattern = '(?i)(config_lines\[\d+\]:\s+)"' + [regex]::Escape($Key) + '\s+.*?"'
        $NewValue = '$1"' + $CustomFormulas[$Key] + '"'
        
        if ($Content -match $Pattern) {
            $NewContent = $Content -replace $Pattern, $NewValue
            if ($Content -ne $NewContent) {
                $Content = $NewContent
                $Modified = $true
            }
        }
    }
    
    if ($Modified) {
        $Content | Set-Content -Path $FILE -NoNewline
        Write-Host "  -> Success: RKS formulas injected!" -ForegroundColor Green
    } else {
        Write-Host "  -> [WARNING] Target lines not found or already up to date." -ForegroundColor Yellow
        
        # INTERAKTIVER FALLBACK-BLOCK
        if (Test-Path $PresetFile) {
            Write-Host ""
            Write-Host "     !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!" -ForegroundColor Red
            Write-Host "     WARNING: Installing the preset will reset your custom in-game keybinds " -ForegroundColor Yellow
            Write-Host "              and sensitivity settings to default RKS values!" -ForegroundColor Yellow
            Write-Host "              Your original settings are SAFELY backed up in 'controls.sii.bak'." -ForegroundColor Green
            Write-Host "     !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!" -ForegroundColor Red
            Write-Host ""
            $Confirm = (Read-Host "     Do you want to overwrite 'controls.sii' with the RKS Preset? (Y/N)").ToUpper()
            if ($Confirm -eq "Y") {
                Copy-Item -Path $PresetFile -Destination $FILE -Force
                Write-Host "  -> Success: Default RKS Preset applied successfully!" -ForegroundColor Green
            } else {
                Write-Host "  -> Patching skipped by user." -ForegroundColor Yellow
            }
        }
    }
}

Write-Host ""
Read-Host "All operations completed. Press Enter to exit..."
