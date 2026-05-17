#!/bin/bash
# ==============================================================================
# ETS2 Realistic Keyboard Steering (RKS) - Linux & Steam Deck Launcher
# Developer: Shadoo91
# Version: 1.0 (ETS2 Edition)
# ==============================================================================

GAME_NAME="Euro Truck Simulator 2"
GAME_SHORT="ETS2"
STEAM_APP_ID="227300"
RKS_VERSION="1.0"

# ANSI Color Codes
CYAN='\033[0;36m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
GRAY='\033[0;37m'
NC='\033[0m' # No Color

show_header() {
    clear
    echo -e "${CYAN}=====================================================================${NC}"
    echo -e "${GREEN}    $GAME_SHORT REALISTIC KEYBOARD STEERING (RKS) LINUX LAUNCHER v$RKS_VERSION${NC}"
    echo -e "${GRAY}    Created by: Shadoo91${NC}"
    echo -e "${CYAN}=====================================================================${NC}"
    echo ""
}

get_profile_name() {
    local hex=$1
    echo "$hex" | xxd -r -p 2>/dev/null || echo "$hex"
}

get_ets2_paths() {
    PATHS=()
    
    # 1. Native Linux Local Path
    LOCAL_PATH="$HOME/.local/share/$GAME_NAME/profiles"
    if [ -d "$LOCAL_PATH" ]; then
        PATHS+=("Local:$LOCAL_PATH")
    fi
    
    # 2. Steam Cloud / Proton Path (Most important for Steam Deck)
    # Scanning common Steam installation directories
    STEAM_DIRS=(
        "$HOME/.steam/steam/userdata"
        "$HOME/.local/share/Steam/userdata"
        "$HOME/.var/app/com.valvesoftware.Steam/.steam/steam/userdata"
    )
    
    for s_dir in "${STEAM_DIRS[@]}"; do
        if [ -d "$s_dir" ]; then
            for user_id in "$s_dir"/*; do
                if [ -d "$user_id/$STEAM_APP_ID/remote/profiles" ]; then
                    PATHS+=("SteamCloud:$user_id/$STEAM_APP_ID/remote/profiles")
                fi
            done
        fi
    done
}

invoke_patch() {
    get_ets2_paths
    if [ ${#PATHS[@]} -eq 0 ]; then
        echo -e "${RED}[-] No $GAME_NAME profile directories found!${NC}"
        echo -e "${YELLOW}    Please ensure the game has been launched at least once.${NC}"
        read -p $'\nPress Enter to return to the main menu...'
        return
    }

    PRESET_FILE="./rks_preset_controls.sii"
    if [ ! -f "$PRESET_FILE" ]; then
        echo -e "${RED}[-] Critical Error: 'rks_preset_controls.sii' not found in the same directory!${NC}"
        read -p $'\nPress Enter to return to the main menu...'
        return
    }

    echo -e "${CYAN}[+] Scanning for profiles...${NC}"
    patched_count=0

    for target in "${PATHS[@]}"; do
        IFS=':' read -r type path <<< "$target"
        
        for prof_dir in "$path"/*; do
            if [ -d "$prof_dir" ]; then
                control_file="$prof_dir/controls.sii"
                if [ -f "$control_file" ]; then
                    folder_name=$(basename "$prof_dir")
                    readable_name=$(get_profile_name "$folder_name")
                    echo -e "${GRAY}-> Processing profile: $readable_name ($type)${NC}"
                    
                    # Create backup if it doesn't exist
                    backup_file="$control_file.bak"
                    if [ ! -f "$backup_file" ]; then
                        cp "$control_file" "$backup_file"
                        echo -e "   ${GREEN}[+] Backup created: controls.sii.bak${NC}"
                    fi
                    
                    # Clean existing RKS matrix lines and prepare for injection
                    # Temporary files for processing
                    tmp_file=$(mktemp)
                    
                    # Filter out old RKS or default lines
                    awk '
                        /mix dsteerleft/ {skip=1; next}
                        skip && /mix backward/ {skip=0; next}
                        !skip {print}
                    ' "$control_file" > "$tmp_file"
                    
                    # Inject new RKS preset before 'mix forward'
                    final_file=$(mktemp)
                    injected=0
                    while IFS= read -r line || [ -n "$line" ]; do
                        if [[ "$line" =~ "mix forward" ]] && [ $injected -eq 0 ]; then
                            cat "$PRESET_FILE" >> "$final_file"
                            injected=1
                        fi
                        echo "$line" >> "$final_file"
                    done < "$tmp_file"
                    
                    cp "$final_file" "$control_file"
                    rm "$tmp_file" "$final_file"
                    
                    ((patched_count++))
                    echo -e "   ${GREEN}[+] RKS control matrix successfully injected!${NC}"
                fi
            fi
        done
    done

    echo -e "\n${GREEN}[+] Done! $patched_count profiles have been successfully updated to RKS.${NC}"
    read -p $'\nPress Enter to return to the main menu...'
}

invoke_restore() {
    get_ets2_paths
    if [ ${#PATHS[@]} -eq 0 ]; then
        echo -e "${RED}[-] No directories found to restore.${NC}"
        read -p $'\nPress Enter...'
        return
    fi

    restored_count=0
    for target in "${PATHS[@]}"; do
        IFS=':' read -r type path <<< "$target"
        
        for prof_dir in "$path"/*; do
            if [ -d "$prof_dir" ]; then
                control_file="$prof_dir/controls.sii"
                backup_file="$control_file.bak"
                
                if [ -f "$backup_file" ]; then
                    folder_name=$(basename "$prof_dir")
                    readable_name=$(get_profile_name "$folder_name")
                    echo -e "${GRAY}-> Restoring profile: $readable_name${NC}"
                    
                    cp "$backup_file" "$control_file"
                    rm "$backup_file"
                    ((restored_count++))
                    echo -e "   ${GREEN}[+] Backup successfully restored.${NC}"
                fi
            fi
        done
    done

    echo -e "\n${GREEN}[+] Done! $restored_count profiles have been reverted to their original state.${NC}"
    read -p $'\nPress Enter to return to the main menu...'
}

# --- MAIN MENU LOOP ---
while true; do
    show_header
    echo -e "${YELLOW}Please select an option:${NC}"
    echo -e " [A] Inject RKS steering into ALL ETS2 profiles (Patch)"
    echo -e " [R] Restore backups (Uninstall RKS / Rollback)"
    echo -e " [E] Exit"
    echo ""
    read -p "Selection: " choice
    choice=$(echo "$choice" | tr '[:lower:]' '[:upper:]')

    case "$choice" in
        A) invoke_patch ;;
        R) invoke_restore ;;
        E) 
            echo -e "\n${CYAN}Goodbye! Have a safe journey.${NC}"
            break 
            ;;
    esac
done
