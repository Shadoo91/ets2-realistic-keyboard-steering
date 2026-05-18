#!/bin/bash
# ==============================================================================
# ETS2 Realistic Keyboard Steering (RKS) - Linux & Steam Deck Launcher
# Developer: Shadoo91
# Version: 1.10 (ETS2 Edition)
# ==============================================================================

RKS_VERSION="1.10"
PRESET_FILE="rks_preset_controls.sii"

clear
echo -e "\e[36m================================================================================\e[0m"
echo -e "\e[36m   ETS2 Realistic Keyboard Steering (RKS) ~ Linux Launcher v${RKS_VERSION}\e[0m"
echo -e "\e[36m================================================================================\e[0m"
echo

# 1. Universelle Suchpfade für ALLE Linux-Systeme (Native, Flatpak & Proton-Emulation)
ETS2_DIR_NATIVE="$HOME/.local/share/Euro Truck Simulator 2"
ETS2_DIR_FLATPAK="$HOME/.var/app/com.valvesoftware.Steam/.local/share/Euro Truck Simulator 2"
ETS2_DIR_PROTON="$HOME/.steam/debian-installation/steamapps/compatdata/227300/pfx/drive_c/users/steamuser/Documents/Euro Truck Simulator 2"

USERDATA_NATIVE="$HOME/.local/share/Steam/userdata"
USERDATA_DEBIAN="$HOME/.steam/debian-installation/userdata"
USERDATA_FLATPAK="$HOME/.var/app/com.valvesoftware.Steam/.steam/steam/userdata"
USERDATA_STEAMDECK="$HOME/.steam/steam/userdata"

declare -a PROFILES_PATHS

# Lokale Standard-Verzeichnisse scannen
[ -d "$ETS2_DIR_NATIVE/profiles" ] && PROFILES_PATHS+=("$ETS2_DIR_NATIVE/profiles")
[ -d "$ETS2_DIR_NATIVE/steam_profiles" ] && PROFILES_PATHS+=("$ETS2_DIR_NATIVE/steam_profiles")
[ -d "$ETS2_DIR_FLATPAK/profiles" ] && PROFILES_PATHS+=("$ETS2_DIR_FLATPAK/profiles")
[ -d "$ETS2_DIR_FLATPAK/steam_profiles" ] && PROFILES_PATHS+=("$ETS2_DIR_FLATPAK/steam_profiles")
[ -d "$ETS2_DIR_PROTON/profiles" ] && PROFILES_PATHS+=("$ETS2_DIR_PROTON/profiles")
[ -d "$ETS2_DIR_PROTON/steam_profiles" ] && PROFILES_PATHS+=("$ETS2_DIR_PROTON/steam_profiles")

# Globale Steam Cloud Userdata-Ordner scannen (AppID 227300 für ETS2)
for udir in "$USERDATA_NATIVE" "$USERDATA_DEBIAN" "$USERDATA_FLATPAK" "$USERDATA_STEAMDECK"; do
    if [ -d "$udir" ]; then
        for iddir in "$udir"/*; do
            if [ -d "$iddir/227300/remote/profiles" ]; then
                PROFILES_PATHS+=("$iddir/227300/remote/profiles")
            fi
        done
    fi
done

# Einzigartige Pfade filtern
declare -a TARGET_DIRS
for p in "${PROFILES_PATHS[@]}"; do
    if [[ ! " ${TARGET_DIRS[@]} " =~ " ${p} " ]] && [ -d "$p" ]; then
        TARGET_DIRS+=("$p")
    fi
done

if [ ${#TARGET_DIRS[@]} -eq 0 ]; then
    echo -e "\e[31m[ERROR] No Euro Truck Simulator 2 profile directories found!\e[0m"
    exit 1
fi

# 2. Gefundene controls.sii auflisten
declare -a CONTROLS_FILES
declare -a FOLDER_NAMES
file_idx=1

echo -e "\e[33mDetected ETS2 Profiles:\e[0m"
echo "--------------------------------------------------------------------------------"

for tdir in "${TARGET_DIRS[@]}"; do
    while IFS= read -r -d '' file; do
        folder_name=$(basename "$(dirname "$file")")
        bak_status="[Backup: No ]"
        [ -f "${file}.bak" ] && bak_status="[Backup: Yes]"
        
        CONTROLS_FILES+=("$file")
        FOLDER_NAMES+=("$folder_name")
        
        printf " [\e[36m%d\e[0m] Profile: %-25s | %s\n" "$file_idx" "$folder_name" "$bak_status"
        ((file_idx++))
    done < <(find "$tdir" -name "controls.sii" -print0 2>/dev/null)
done

if [ ${#CONTROLS_FILES[@]} -eq 0 ]; then
    echo -e "\e[33m[INFO] No active 'controls.sii' configuration files found.\e[0m"
    exit 0
fi

echo "--------------------------------------------------------------------------------"
echo -e "\e[33m [A] Patch ALL profiles  |  [R] Restore Backups  |  [E] Exit\e[0m"
echo "--------------------------------------------------------------------------------"
echo

read -p "Select an option: " selection
selection=$(echo "$selection" | tr '[:lower:]' '[:upper:]')

[ "$selection" == "E" ] && exit 0

# ==========================================
# SEKTION: BACKUP WIEDERHERSTELLUNG [R]
# ==========================================
if [ "$selection" == "R" ]; then
    echo
    read -p "Restore ALL backups [A] or select a specific Profile Number? (A/Number): " roll_sel
    roll_sel=$(echo "$roll_sel" | tr '[:lower:]' '[:upper:]')
    
    declare -a rollback_indices
    if [ "$roll_sel" == "A" ]; then
        rollback_indices=("${!CONTROLS_FILES[@]}")
    elif [[ "$roll_sel" =~ ^[0-9]+$ ]] && [ "$roll_sel" -le "${#CONTROLS_FILES[@]}" ] && [ "$roll_sel" -gt 0 ]; then
        rollback_indices+=($((roll_sel-1)))
    else
        echo -e "\e[31m[ERROR] Invalid profile selection!\e[0m"; exit 1
    fi

    echo -e "\e[36mRestoring files...\e[0m"
    for idx in "${rollback_indices[@]}"; do
        cfile="${CONTROLS_FILES[$idx]}"
        fname="${FOLDER_NAMES[$idx]}"
        if [ -f "${cfile}.bak" ]; then
            chmod 644 "$cfile" 2>/dev/null
            cp -f "${cfile}.bak" "$cfile"
            rm -f "${cfile}.bak"
            echo -e "  -> \e[32mRestored:\e[0m $fname"
        else
            echo -e "  -> \e[33mNo backup available for:\e[0m $fname"
        fi
    done
    exit 0
fi

# Auswahl für das Patchen verarbeiten
declare -a patch_files
if [ "$selection" == "A" ]; then
    patch_files=("${CONTROLS_FILES[@]}")
else
    if [[ "$selection" =~ ^[0-9]+$ ]] && [ "$selection" -le "${#CONTROLS_FILES[@]}" ] && [ "$selection" -gt 0 ]; then
        p_idx=$((selection-1))
        patch_files+=("${CONTROLS_FILES[$p_idx]}")
    else
        echo -e "\e[31m[ERROR] Invalid selection!\e[0m"; exit 1
    fi
fi

if [ ! -f "$PRESET_FILE" ]; then
    echo -e "\e[31m[ERROR] Critical preset file '$PRESET_FILE' missing in current directory!\e[0m"
    exit 1
fi

# ==========================================
# SEKTION: INJEKTOR STARTEN
# ==========================================
for cfile in "${patch_files[@]}"; do
    fname=$(basename "$(dirname "$cfile")")
    echo -e "Processing profile: \e[33m$fname\e[0m"
    
    chmod 644 "$cfile" 2>/dev/null
    [ ! -f "${cfile}.bak" ] && cp "$cfile" "${cfile}.bak"
    
    final_file="${cfile}.tmp"
    
    # Korrekte awk-Syntax: Das ^ gehört IN die Schrägstriche /^[[:space:]]*.../
    awk '
    BEGIN { skip=0 }
    /^[[:space:]]*config_lines\[330\]:/ { skip=1 }
    { if (!skip) print $0 }
    /^[[:space:]]*config_lines\[341\]:/ { skip=0 }
    ' "$cfile" | tr -d '\r' > "$final_file"
    
    # PRÜFUNG: Wenn die Datei durch awk verändert wurde, existierten die Zeilen!
    if ! cmp -s "$cfile" "$final_file"; then
        mv -f "$final_file" "$cfile"
        cat "$PRESET_FILE" >> "$cfile"
        echo -e "  -> \e[32mSuccess:\e[0m RKS Matrix v${RKS_VERSION} successfully injected into existing profile!"
    else
        # FALLBACK: Wenn cmp keinen Unterschied sieht, fehlten die RKS-Zeilen im Profil komplett.
        rm -f "$final_file"
        echo -e "  -> \e[33m[WARNING]\e[0m Target lines 330-341 not found in your controls.sii."
        
        echo
        echo -e "     \e[31m!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!\e[0m"
        echo -e "     \e[33mWARNING: Installing the preset will reset your custom in-game keybinds \e[0m"
        echo -e "              \e[33mand sensitivity settings to default RKS values!\e[0m"
        echo -e "              \e[32mYour original settings are SAFELY backed up in 'controls.sii.bak'.\e[0m"
        echo -e "     \e[31m!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!\e[0m"
        echo
        
        read -p "     Do you want to overwrite 'controls.sii' with the RKS Preset? (Y/N): " confirm
        confirm=$(echo "$confirm" | tr '[:lower:]' '[:upper:]')
        
        if [ "$confirm" == "Y" ]; then
            cp -f "$PRESET_FILE" "$cfile"
            echo -e "  -> \e[32mSuccess:\e[0m Default RKS Preset applied successfully!"
        else
            echo -e "  -> \e[33mPatching skipped by user.\e[0m"
        fi
    fi
done

echo
read -p "All operations completed. Press Enter to exit..."
