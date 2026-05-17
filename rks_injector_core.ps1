# ==============================================================================
# ETS2 Realistic Keyboard Steering (RKS) - Injector Core
# Developer: Shadoo91
# Version: 1.0 (ETS2 Edition)
# ==============================================================================

$Global:RKS_VERSION = "1.0"
$Global:GAME_NAME = "Euro Truck Simulator 2"
$Global:GAME_SHORT = "ETS2"
$Global:STEAM_APP_ID = "227300" # Official ETS2 App ID

# Save default console colors
$oldRaw = $Host.UI.RawUI
$oldBackground = $oldRaw.BackgroundColor
$oldForeground = $oldRaw.ForegroundColor

function Show-WelcomeHeader {
    Clear-Host
    Write-Host "=====================================================================" -ForegroundColor Cyan
    Write-Host "    $Global:GAME_SHORT REALISTIC KEYBOARD STEERING (RKS) INJECTOR v$Global:RKS_VERSION    " -ForegroundColor Green -BackgroundColor Black
    Write-Host "    Created by: Shadoo91                                             " -ForegroundColor DarkGray
    Write-Host "=====================================================================" -ForegroundColor Cyan
    Write-Host ""
}

function Get-Ets2Paths {
    $Paths = @()
    
    # 1. Check default Documents path
    $DocPath = [System.IO.Path]::Combine([Environment]::GetFolderPath("MyDocuments"), $Global:GAME_NAME)
    if (Test-Path -Path $DocPath) {
        $Paths += ,[pscustomobject]@{ Type = "Local"; Path = [System.IO.Path]::Combine($DocPath, "profiles") }
    }
    
    # 2. Locate Steam Cloud path via Registry
    $SteamReg = Get-ItemProperty -Path "HKCU:\Software\Valve\Steam" -ErrorAction SilentlyContinue
    if ($SteamReg -and $SteamReg.SteamPath) {
        $SteamPath = $SteamReg.SteamPath
        $UserdataDir = [System.IO.Path]::Combine($SteamPath, "userdata")
        
        if (Test-Path -Path $UserdataDir) {
            Get-ChildItem -Path $UserdataDir -Directory | ForEach-Object {
                $Ets2CloudPath = [System.IO.Path]::Combine($_.FullName, $Global:STEAM_APP_ID, "remote", "profiles")
                if (Test-Path -Path $Ets2CloudPath) {
                    $Paths += ,[pscustomobject]@{ Type = "SteamCloud"; Path = $Ets2CloudPath }
                }
            }
        }
    }
    
    return $Paths
}

function Get-ProfileName ($HexFolder) {
    try {
        $Bytes = @()
        for ($i = 0; $i -lt $HexFolder.Length; $i += 2) {
            $Bytes += [Convert]::ToByte($HexFolder.Substring($i, 2), 16)
        }
        return [System.Text.Encoding]::UTF8.GetString($Bytes)
    } catch {
        return $HexFolder
    }
}

function Invoke-PatchProfiles {
    $TargetPaths = Get-Ets2Paths
    if ($TargetPaths.Count -eq 0) {
        Write-Host "[-] No $Global:GAME_NAME profile directories found!" -ForegroundColor Red
        Write-Host "    Please ensure the game has been launched at least once." -ForegroundColor Yellow
        Read-Host "`nPress Enter to return to the main menu..."
        return
    }

    $PresetFile = [System.IO.Path]::Combine($PSScriptRoot, "rks_preset_controls.sii")
    if (-not (Test-Path -Path $PresetFile)) {
        Write-Host "[-] Critical Error: 'rks_preset_controls.sii' not found in the same directory!" -ForegroundColor Red
        Read-Host "`nPress Enter to return to the main menu..."
        return
    }
    $PresetLines = Get-Content -Path $PresetFile

    Write-Host "[+] Scanning for profiles..." -ForegroundColor Cyan
    $PatchedCount = 0

    foreach ($Target in $TargetPaths) {
        $Profiles = Get-ChildItem -Path $Target.Path -Directory
        foreach ($Prof in $Profiles) {
            $ControlFile = [System.IO.Path]::Combine($Prof.FullName, "controls.sii")
            if (Test-Path -Path $ControlFile) {
                $ReadableName = Get-ProfileName -HexFolder $Prof.Name
                Write-Host "-> Processing profile: $ReadableName ($($Target.Type))" -ForegroundColor Gray
                
                # Create a safety backup if it doesn't exist yet
                $BackupFile = $ControlFile + ".bak"
                if (-not (Test-Path -Path $BackupFile)) {
                    Copy-Item -Path $ControlFile -Destination $BackupFile -Force
                    Write-Host "   [+] Backup created: controls.sii.bak" -ForegroundColor DarkGreen
                }

                # Patching process for the 12 RKS matrix lines
                $FileLines = Get-Content -Path $ControlFile
                $NewLines = @()
                $SkipMode = $false

                # Clean existing RKS blocks or replace default lines
                foreach ($Line in $FileLines) {
                    if ($Line -match "mix dsteerleft") { $SkipMode = $true; continue }
                    if ($SkipMode -and $Line -match "mix backward") { $SkipMode = $false; continue }
                    if ($SkipMode) { continue }
                    $NewLines += $Line
                }

                # Inject RKS configuration (usually before the 'mix forward' line)
                $FinalLines = @()
                $Injected = $false
                foreach ($Line in $NewLines) {
                    if ($Line -match "mix forward" -and -not $Injected) {
                        foreach ($PLine in $PresetLines) { $FinalLines += $PLine }
                        $Injected = $true
                    }
                    $FinalLines += $Line
                }

                Set-Content -Path $ControlFile -Value $FinalLines -Force
                $PatchedCount++
                Write-Host "   [+] RKS control matrix successfully injected!" -ForegroundColor Green
            }
        }
    }

    Write-Host "`n[+] Done! $PatchedCount profiles have been successfully updated to RKS." -ForegroundColor Green
    Read-Host "`nPress Enter to return to the main menu..."
}

function Invoke-RestoreProfiles {
    $TargetPaths = Get-Ets2Paths
    if ($TargetPaths.Count -eq 0) {
        Write-Host "[-] No directories found to restore." -ForegroundColor Red
        Read-Host "`nPress Enter..."
        return
    }

    $RestoredCount = 0
    foreach ($Target in $TargetPaths) {
        $Profiles = Get-ChildItem -Path $Target.Path -Directory
        foreach ($Prof in $Profiles) {
            $ControlFile = [System.IO.Path]::Combine($Prof.FullName, "controls.sii")
            $BackupFile = $ControlFile + ".bak"
            
            if (Test-Path -Path $BackupFile) {
                $ReadableName = Get-ProfileName -HexFolder $Prof.Name
                Write-Host "-> Restoring profile: $ReadableName" -ForegroundColor Gray
                Copy-Item -Path $BackupFile -Destination $ControlFile -Force
                Remove-Item -Path $BackupFile -Force
                $RestoredCount++
                Write-Host "   [+] Backup successfully restored." -ForegroundColor Green
            }
        }
    }

    Write-Host "`n[+] Done! $RestoredCount profiles have been reverted to their original state." -ForegroundColor Green
    Read-Host "`nPress Enter to return to the main menu..."
}

# --- MAIN MENU LOOP ---
do {
    Show-WelcomeHeader
    Write-Host "Please select an option:" -ForegroundColor Yellow
    Write-Host " [A] Inject RKS steering into ALL ETS2 profiles (Patch)" -ForegroundColor White
    Write-Host " [R] Restore backups (Uninstall RKS / Rollback)" -ForegroundColor White
    Write-Host " [E] Exit" -ForegroundColor White
    Write-Host ""
    $Choice = (Read-Host "Selection").ToUpper()

    switch ($Choice) {
        "A" { Invoke-PatchProfiles }
        "R" { Invoke-RestoreProfiles }
        "E" { Write-Host "`nGoodbye! Have a safe journey." -ForegroundColor Cyan }
    }
} while ($Choice -ne "E")

# Reset console colors
$raw = $Host.UI.RawUI
$raw.BackgroundColor = $oldBackground
$raw.ForegroundColor = $oldForeground
Clear-Host
