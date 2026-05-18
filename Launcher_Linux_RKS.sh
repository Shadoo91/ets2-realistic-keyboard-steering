#!/bin/bash

# ===================================================================================
#   ETS2 Realistic-Keyboard-Steering (RKS) (Turbo-Mode) ~ by Shadoo91
#   [BASH PROFILE INJECTOR - WITH SAFETY FALLBACK PRESET & ROLLBACK INFO]
# ===================================================================================

cd "$(dirname "$0")"

clear
echo -e "\e[36m====================================================================================\e[0m"
echo -e "\e[36m   ETS2 Realistic-Keyboard-Steering (RKS) ~ Profile Manager (Linux)\e[0m"
echo -e "\e[36m====================================================================================\e[0m"
echo

PresetFile="./rks_preset_controls.sii"

# 1. Suchpfade für Profile definieren (Lokal, Flatpak und Steam Cloud userdata)
Ets2DocPath="$HOME/.steam/steam/steamapps/compatdata/227300/pfx/drive_c/users/steamuser/Documents/Euro Truck Simulator 2"
Ets2FlatpakPath="$HOME/.var/app/com.valvesoftware.Steam/.steam/steam/steamapps/compatdata/227300/pfx/drive_c/users/steamuser/Documents/Euro Truck Simulator 2"

declare -a SearchPaths
[ -d "$Ets2DocPath/profiles" ] && SearchPaths+=("$Ets2DocPath/profiles")
[ -d "$Ets2DocPath/steam_profiles" ] && SearchPaths+=("$Ets2DocPath/steam_profiles")
[ -d "$Ets2FlatpakPath/profiles" ] && SearchPaths+=("$Ets2FlatpakPath/profiles")
[ -d "$Ets2FlatpakPath/steam_profiles" ] && SearchPaths+=("$Ets2FlatpakPath/steam_profiles")

# Lokale Steam Userdata (Cloud) Pfade durchsuchen (AppID 227300 für ETS2)
SteamPaths=("$HOME/.steam/steam/userdata" "$HOME/.var/app/com.valvesoftware.Steam/.steam/steam/userdata")
for SPath in "${SteamPaths[@]}"; do
    if [ -d "$SPath" ]; then
        for UserDir in "$SPath"/*; do
            if [ -d "$UserDir/227300/remote/profiles" ]; then
                SearchPaths+=("$UserDir/227300/remote/profiles")
            fi
        done
    fi
done

# Einzigartige, existierende Pfade filtern
declare -a TargetPaths
for Path in "${SearchPaths[@]}"; do
    if [[ ! " ${TargetPaths[@]} " =~ " ${Path} " ]] && [ -d "$Path" ]; then
        TargetPaths+=("$Path")
    fi
done

if [ ${#TargetPaths[@]} -eq 0 ]; then
    echo -e "\e[31m[ERROR] No Euro Truck Simulator 2 profile directories found!\e[0m"
    read -p "Press Enter to exit..."
    exit 1
fi

# 2. Alle controls.sii Dateien finden und auflisten
declare -a ControlFiles
declare -a ControlTypes
declare -a ControlFolders
Index=1

echo -e "\e[33mDetected ETS2 Profiles:\e[0m"
echo "------------------------------------------------------------------------------------"

for TPath in "${TargetPaths[@]}"; do
    while IFS= read -r -d '' FILE; do
        Folder=$(basename "$(dirname "$FILE")")
        Type="Local"
        [[ "$FILE" =~ "steam_profiles" ]] && Type="Steam Copy"
        [[ "$FILE" =~ "userdata" ]] && Type="Steam Cloud"
        
        BakStatus="[Backup: No ]"
        [ -f "${FILE}.bak" ] && BakStatus="[Backup: Yes]"
        
        ControlFiles+=("$FILE")
        ControlTypes+=("$Type")
        ControlFolders+=("$Folder")
        
        printf " [\e[36m%d\e[0m] Folder: %-20s | Type: %-12s | %s\n" "$Index" "$Folder" "$Type" "$BakStatus"
        ((Index++))
    done < <(find "$TPath" -name "controls.sii" -print0 2>/dev/null)
done

if [ ${#ControlFiles[@]} -eq 0 ]; then
    echo -e "\e[33m[INFO] No 'controls.sii' files found!\e[0m"
    read -p "Press Enter to exit..."
    exit 0
fi

echo "------------------------------------------------------------------------------------"
echo -e "\e[33m [A] Patch ALL profiles  |  [R] Restore backups  |  [E] Exit\e[0m"
echo "------------------------------------------------------------------------------------"
echo

read -p "Please select an option: " Selection
Selection=$(echo "$Selection" | tr '[:lower:]' '[:upper:]')

[ "$Selection" == "E" ] && exit 0

# ==========================================
# REITER: ROLLBACK SYSTEM [R]
# ==========================================
if [ "$Selection" == "R" ]; then
    echo
    read -p "Restore ALL backups [A] or select a specific Profile Number? (A/Number): " RollbackSel
    RollbackSel=$(echo "$RollbackSel" | tr '[:lower:]' '[:upper:]')
    
    declare -a FilesToRollback
    if [ "$RollbackSel" == "A" ]; then
        FilesToRollback=("${!ControlFiles[@]}")
    elif [[ "$RollbackSel" =~ ^[0-9]+$ ]] && [ "$RollbackSel" -le "${#ControlFiles[@]}" ] && [ "$RollbackSel" -gt 0 ]; then
        FilesToRollback+=($((RollbackSel-1)))
    else
        echo -e "\e[31m[ERROR] Invalid selection!\e[0m"; exit 1
    fi

    echo -e "\e[36mStarting Rollback System...\e[0m"
    for i in "${FilesToRollback[@]}"; do
        FILE="${ControlFiles[$i]}"
        Folder="${ControlFolders[$i]}"
        if [ -f "${FILE}.bak" ]; then
            chmod 644 "$FILE" 2>/dev/null
            cp -f "${FILE}.bak" "$FILE"
            rm -f "${FILE}.bak"
            echo -e "  -> \e[32mRestored:\e[0m $Folder"
        else
            echo -e "  -> \e[33mNo backup found for:\e[0m $Folder"
        fi
    done
    read -p "Rollback finished. Press Enter to exit..."
    exit 0
fi

# Auswahl für das Patchen auswerten
declare -a FilesToPatch
if [ "$Selection" == "A" ]; then
    FilesToPatch=("${ControlFiles[@]}")
else
    if [[ "$Selection" =~ ^[0-9]+$ ]] && [ "$Selection" -le "${#ControlFiles[@]}" ] && [ "$Selection" -gt 0 ]; then
        Idx=$((Selection-1))
        FilesToPatch+=("${ControlFiles[$Idx]}")
    else
        echo -e "\e[31m[ERROR] Invalid selection!\e[0m"; exit 1
    fi
fi

# ==========================================
# REITER: INJEKTOR STARTEN
# ==========================================
for FILE in "${FilesToPatch[@]}"; do
    Folder=$(basename "$(dirname "$FILE")" )
    echo -e "Processing: \e[33m$Folder\e[0m"
    
    chmod 644 "$FILE"
    [ ! -f "${FILE}.bak" ] && cp "$FILE" "${FILE}.bak"
    
    TEMP_FILE="${FILE}.tmp"
    
    # Sauberes Ersetzen über Perl (Exakt dein funktionierendes Prinzip!)
    perl -pe '
        s/(config_lines\[\d+\]:\s+)"mix dsteerleft .*"/$1"mix dsteerleft \`keyboard.a?0\`"/i;
        s/(config_lines\[\d+\]:\s+)"mix dsteerright .*"/$1"mix dsteerright \`keyboard.d?0\`"/i;
        s/(config_lines\[\d+\]:\s+)"mix dsteering .*"/$1"mix dsteering \`(keyboard.a?0 - keyboard.d?0) * (0.40 + (keyboard.space?0 * 0.50)) * (1.00 + (keyboard.s?0 * keyboard.lalt?0 * 0.60))\`"/i;
        s/(config_lines\[\d+\]:\s+)"mix steering .*"/$1"mix steering \`dsteering * (1.00 - c_steer_func)\`"/i;
        s/(config_lines\[\d+\]:\s+)"mix msteering .*"/$1"mix msteering \`-mouse.rel_position.x?0 * c_msens\`"/i;
        s/(config_lines\[\d+\]:\s+)"mix mpedals .*"/$1"mix mpedals \`-mouse.rel_position.y?0 * c_msens\`"/i;
        s/(config_lines\[\d+\]:\s+)"mix dforward .*"/$1"mix dforward \`0\`"/i;
        s/(config_lines\[\d+\]:\s+)"mix dbackward .*"/$1"mix dbackward \`0\`"/i;
        s/(config_lines\[\d+\]:\s+)"mix aforward .*"/$1"mix aforward \`((keyboard.w?0 * 0.35) + (keyboard.lalt?0 * 0.55)) * (! keyboard.s?0)\`"/i;
        s/(config_lines\[\d+\]:\s+)"mix abackward .*"/$1"mix abackward \`keyboard.s?0 * (0.10 + (keyboard.space?0 * 0.35) + (keyboard.lalt?0 * 0.90))\`"/i;
        s/(config_lines\[\d+\]:\s+)"mix forward .*"/$1"mix forward \`aforward\`"/i;
        s/(config_lines\[\d+\]:\s+)"mix backward .*"/$1"mix backward \`abackward\`"/i;
    ' "$FILE" > "$TEMP_FILE"
    
    # Überprüfen, ob Modifikationen vorgenommen wurden
    if ! cmp -s "$FILE" "$TEMP_FILE"; then
        mv -f "$TEMP_FILE" "$FILE"
        echo -e "  -> \e[32mSuccess:\e[0m RKS formulas injected!"
    else
        rm -f "$TEMP_FILE"
        echo -e "  -> \e[33m[WARNING]\e[0m Target lines not found. File might be corrupted."
        
        # INTERAKTIVER FALLBACK & WARNBLOCK
        if [ -f "$PresetFile" ]; then
            echo
            echo -e "     \e[31m!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!\e[0m"
            echo -e "     \e[33mWARNING: Installing the preset will reset your custom in-game keybinds \e[0m"
            echo -e "              \e[33mand sensitivity settings to default RKS values!\e[0m"
            echo -e "              \e[32mYour original settings are SAFELY backed up in '\''controls.sii.bak'\''.\e[0m"
            echo -e "     \e[31m!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!\e[0m"
            echo
            
            read -p "     Do you want to overwrite 'controls.sii' with the RKS Preset? (Y/N): " Confirm
            Confirm=$(echo "$Confirm" | tr '[:lower:]' '[:upper:]')
            
            if [ "$Confirm" == "Y" ]; then
                cp -f "$PresetFile" "$FILE"
                echo -e "  -> \e[32mSuccess:\e[0m Default RKS Preset applied successfully!"
            else
                echo -e "  -> \e[33mPatching skipped by user.\e[0m"
            fi
        fi
    fi
done

echo
read -p "All operations completed. Press Enter to exit..."
