# ===================================================================================
#   ATS Realistic-Keyboard-Steering (RKS) (Turbo-Mode) ~ by Shadoo91
#   [POWERSHELL PROFILE INJECTOR - PURE TEXT MODE - 100% BIT-ACCURATE]
# ===================================================================================

if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Start-Process powershell -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    Exit
}

Clear-Host
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition
$PresetFile = Join-Path $ScriptDir "rks_preset_controls.sii"

Write-Host "====================================================================================" -ForegroundColor Cyan
Write-Host "   ATS Realistic-Keyboard-Steering (RKS) ~ Profile Manager" -ForegroundColor Cyan
Write-Host "====================================================================================" -ForegroundColor Cyan
Write-Host ""

$AtsDocPath = [System.IO.Path]::Combine([Environment]::GetFolderPath("MyDocuments"), "American Truck Simulator")
$SearchPaths = @(
    [System.IO.Path]::Combine($AtsDocPath, "profiles"),
    [System.IO.Path]::Combine($AtsDocPath, "steam_profiles")
)

$SteamPath = (Get-ItemProperty -Path "HKLM:\SOFTWARE\WOW6432Node\Valve\Steam" -Name "InstallPath" -ErrorAction SilentlyContinue).InstallPath
if ($SteamPath -and (Test-Path $SteamPath)) {
    $UserdataPath = [System.IO.Path]::Combine($SteamPath, "userdata")
    if (Test-Path $UserdataPath) {
        foreach ($UserDir in (Get-ChildItem -Path $UserdataPath -Directory)) {
            $AtsCloudPath = [System.IO.Path]::Combine($UserDir.FullName, "270880", "remote", "profiles")
            if (Test-Path $AtsCloudPath) { $SearchPaths += $AtsCloudPath }
        }
    }
}

$TargetPaths = $SearchPaths | Select-Object -Unique | Where-Object { Test-Path $_ }

if ($TargetPaths.Count -eq 0) {
    Write-Host "[ERROR] No American Truck Simulator profile directories found!" -ForegroundColor Red
    Read-Host "Press Enter to exit..."
    Exit
}

$ControlFiles = @()
foreach ($Dir in $TargetPaths) {
    foreach ($F in (Get-ChildItem -Path $Dir -Filter "controls.sii" -Recurse -ErrorAction SilentlyContinue)) {
        $Type = "Local"; if ($F.FullName -match "steam_profiles") { $Type = "Steam Copy" } elseif ($F.FullName -match "userdata") { $Type = "Steam Cloud" }
        $ControlFiles += [PSCustomObject]@{ Index = 0; Path = $F.FullName; Folder = $F.Directory.Name; Type = $Type; FileInfo = $F; HasBackup = (Test-Path ($F.FullName + ".bak")) }
    }
}

if ($ControlFiles.Count -eq 0) {
    Write-Host "[INFO] No 'controls.sii' files found!" -ForegroundColor Yellow
    Read-Host "Press Enter to exit..."
    Exit
}

for ($i = 0; $i -lt $ControlFiles.Count; $i++) { $ControlFiles[$i].Index = $i + 1 }

Write-Host "Detected ATS Profiles:" -ForegroundColor Yellow
Write-Host "------------------------------------------------------------------------------------"
foreach ($CF in $ControlFiles) {
    $BakStatus = if ($CF.HasBackup) { "[Backup: Yes]" } else { "[Backup: No ]" }
    Write-Host " [$($CF.Index)] " -NoNewline -ForegroundColor Cyan
    Write-Host "Folder: $($CF.Folder,-20) | Type: $($CF.Type,-12) | $BakStatus" -ForegroundColor White
}
Write-Host "------------------------------------------------------------------------------------"
Write-Host " [A] Patch ALL profiles  |  [R] Restore backups  |  [E] Exit" -ForegroundColor Yellow
Write-Host "------------------------------------------------------------------------------------"
Write-Host ""

$Selection = (Read-Host "Please select an option").Trim().ToUpper()
if ($Selection -eq "E") { Exit }

# INTERAKTIVES BACKUP-ROLLBACK SYSTEM
if ($Selection -eq "R") {
    Write-Host ""
    $RollbackSel = (Read-Host "Restore ALL backups [A] or select a specific Profile Number? (A/Number)").Trim().ToUpper()
    
    $FilesToRollback = @()
    if ($RollbackSel -eq "A") {
        $FilesToRollback = $ControlFiles
    } else {
        $SelectedRIdx = 0
        if ([int]::TryParse($RollbackSel, [ref]$SelectedRIdx) -and $SelectedRIdx -le $ControlFiles.Count -and $SelectedRIdx -gt 0) {
            $FilesToRollback = @($ControlFiles[$SelectedRIdx - 1])
        } else {
            Write-Host "[ERROR] Invalid selection!" -ForegroundColor Red
            Read-Host "Press Enter to exit..."
            Exit
        }
    }

    Write-Host ""
    Write-Host "Starting Rollback System..." -ForegroundColor Cyan
    foreach ($CF in $FilesToRollback) {
        $BackupPath = $CF.Path + ".bak"
        if (Test-Path $BackupPath) {
            if ($CF.FileInfo.IsReadOnly) { $CF.FileInfo.IsReadOnly = $false }
            Copy-Item -Path $BackupPath -Destination $CF.Path -Force
            Remove-Item -Path $BackupPath -Force
            Write-Host "  -> Restored: $($CF.Folder)" -ForegroundColor Green
        } else {
            Write-Host "  -> No backup found for: $($CF.Folder)" -ForegroundColor DarkYellow
        }
    }
    Read-Host "Rollback completed. Press Enter to exit..."
    Exit
}

$FilesToPatch = @()
if ($Selection -eq "A") { $FilesToPatch = $ControlFiles }
else {
    $SelectedIdx = 0
    if ([int]::TryParse($Selection, [ref]$SelectedIdx) -and $SelectedIdx -le $ControlFiles.Count -and $SelectedIdx -gt 0) {
        $FilesToPatch = @($ControlFiles[$SelectedIdx - 1])
    }
}

if ($FilesToPatch.Count -eq 0) { Write-Host "[ERROR] Invalid selection!" -ForegroundColor Red; Exit }

# REIN-TEXT-MATRIX (NATIVE STRINGS)
$B = [char]96
$CustomFormulas = @{
    'mix dsteerleft'  = "mix dsteerleft ${B}keyboard.a?0${B}"
    'mix dsteerright' = "mix dsteerright ${B}keyboard.d?0${B}"
    'mix dsteering'   = "mix dsteering ${B}(keyboard.a?0 - keyboard.d?0) * (0.40 + (keyboard.space?0 * 0.50) + (keyboard.s?0 * keyboard.lalt?0 * 0.20))${B}"
    'mix steering'    = "mix steering ${B}dsteering * (1.0 - c_steer_func)${B}"
    'mix msteering'   = "mix msteering ${B}-mouse.rel_position.x?0 * c_msens${B}"
    'mix mpedals'     = "mix mpedals ${B}-mouse.rel_position.y?0 * c_msens${B}"
    'mix dforward'    = "mix dforward ${B}0${B}"
    'mix dbackward'   = "mix dbackward ${B}0${B}"
    'mix aforward'    = "mix aforward ${B}((keyboard.w?0 * 0.35) + (keyboard.lalt?0 * 0.55)) * (! keyboard.s?0)${B}"
    'mix abackward'   = "mix abackward ${B}keyboard.s?0 * (0.10 + (keyboard.lalt?0 * 0.50) + (keyboard.space?0 * 0.90))${B}"
    'mix forward'     = "mix forward ${B}aforward${B}"
    'mix backward'    = "mix backward ${B}abackward${B}"
}

foreach ($CF in $FilesToPatch) {
    $File = $CF.FileInfo
    Write-Host "Processing: $($CF.Folder) [$($CF.Type)]" -ForegroundColor Yellow
    if ($File.IsReadOnly) { $File.IsReadOnly = $false }
    
    $BackupPath = $File.FullName + ".bak"
    if (-not (Test-Path $BackupPath)) { 
        Copy-Item -Path $File.FullName -Destination $BackupPath -Force 
        Write-Host "  -> Backup created: controls.sii.bak" -ForegroundColor Green
    }
    
    # Datei zeilenweise einlesen
    $Lines = [System.IO.File]::ReadAllLines($File.FullName, [System.Text.Encoding]::UTF8)
    $NewLines = @()
    $ModifiedCount = 0
    
    foreach ($Line in $Lines) {
        $Matched = $false
        foreach ($Key in $CustomFormulas.Keys) {
            # FLEXIBLE SUCHE: Ignoriert Anstriche und Leerzeichen vor dem mix-Befehl
            if ($Line -match "\b$Key\b") {
                if ($Line -match '^(\s*config_lines\[\d+\]:\s*)') {
                    $Prefix = $Matches[1]
                    $NewLines += "${Prefix}`"$($CustomFormulas[$Key])`""
                    $ModifiedCount++
                    $Matched = $true
                    break
                }
            }
        }
        if (-not $Matched) {
            $NewLines += $Line
        }
    }
    
    # Pruefen, ob die Zeilen erfolgreich injiziert wurden
    if ($ModifiedCount -ge 6) {
        [System.IO.File]::WriteAllLines($File.FullName, $NewLines, [System.Text.Encoding]::UTF8)
        Write-Host "  -> Success: RKS formulas injected!" -ForegroundColor Green
    } else {
        # WARNBLOCK & PRESET-FALLBACK WENN INJEKTION FEHLSCHLÄGT
        Write-Host "  -> [WARNING] Target lines not found. File might be corrupted." -ForegroundColor DarkYellow
        if (Test-Path $PresetFile) {
            Write-Host ""
            Write-Host "     !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!" -ForegroundColor Red
            Write-Host "     WARNING: Installing the preset will reset your custom in-game keybinds " -ForegroundColor Yellow
            Write-Host "              and sensitivity settings to default RKS values!" -ForegroundColor Yellow
            Write-Host "              Your original settings are SAFELY backed up in 'controls.sii.bak'." -ForegroundColor Green
            Write-Host "              You will need to manually reconfigure your basic controls in-game." -ForegroundColor Yellow
            Write-Host "     !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!" -ForegroundColor Red
            Write-Host ""
            $Choice = Read-Host "     Do you still want to overwrite with the clean RKS Default Preset? (Y/N)"
            if ($Choice.Trim().ToUpper() -eq "Y") {
                Copy-Item -Path $PresetFile -Destination $File.FullName -Force
                Write-Host "     -> Success: Overwritten with clean RKS Preset!" -ForegroundColor Green
                Write-Host ""
                Write-Host "     ------------------------------------------------------------------------" -ForegroundColor Cyan
                Write-Host "     HOW TO RESTORE YOUR ORIGINAL SETTINGS LATER:" -ForegroundColor Yellow
                Write-Host "     Option 1 (Automatic): Restart this tool and press [R] in the main menu." -ForegroundColor White
                Write-Host "     Option 2 (Manual): Go to your profile folder:" -ForegroundColor White
                Write-Host "                        $($File.DirectoryName)" -ForegroundColor Gray
                Write-Host "                        Delete 'controls.sii' and rename 'controls.sii.bak'" -ForegroundColor White
                Write-Host "                        back to 'controls.sii'." -ForegroundColor White
                Write-Host "     ------------------------------------------------------------------------" -ForegroundColor Cyan
                Write-Host ""
            } else { Write-Host "     -> Skipped preset installation." -ForegroundColor Gray }
        } else { Write-Host "     -> Fallback preset file 'rks_preset_controls.sii' not found in script folder!" -ForegroundColor Red }
    }
    Write-Host "------------------------------------------------------------------------------------"
}

Read-Host "Process finished. Press Enter to exit..."
