#!/bin/bash

# Random Game Launcher v1.0
# by copperkiddx <copperkiddx@gmail.com>

# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.

# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.

# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

# You can download the latest version of this tool from:
# https://github.com/copperkiddx/MiSTer-console-random-game-launcher

#=========   USER OPTIONS   =========

fat_or_usb0="fat" # Location of your ROMS - microSD (fat) or hard drive (usb0)
hide_rom_name_on_launch="0" # 0 to show game name upon launch OR 1 to display "???" instead of game name

#=========   END USER OPTIONS   =========

#=========   FUNCTIONS   =========

checkDependencies () {
    [ ! -d "$config_folder" ] && mkdir "$config_folder" # If config folder doesn't exist, create it
    cd $config_folder
    
    if [[ ! -f "/media/fat/Scripts/.mister_batch_control/mbc" ]] # If mbc does not exist, download it
    then
        clear
        ping -c 1 8.8.8.8 &>/dev/null; [ "$?" != "0" ] && clear && printf "ERROR: Missing dependencies (Internet connection required). Please try again\n\n" && exit 126 # Test internet
        printf "Missing dependencies (MiSTer_Batch_Control): Installing from Github..."
        mkdir /media/fat/Scripts/.mister_batch_control
        wget -qP /media/fat/Scripts/.mister_batch_control "https://github.com/pocomane/MiSTer_Batch_Control/releases/download/untagged-533dda82c9fd24faa6f1/mbc"
        sleep 1
        if md5sum --status -c <(echo ea32cf0d76812a9994b27365437393f2 /media/fat/Scripts/.mister_batch_control/mbc) # Check md5sum with exact mbc file
        then
            clear
            printf "SUCCESS! Installed to \"/media/fat/Scripts/.mister_batch_control\""
            sleep 2
        else
            clear
            printf "ERROR: md5sum for MiSTer_Batch_Control binary is bad, exiting\n\n"
            exit 126
        fi
    fi
}

getFolderSize () { # Find total disk space used by console-specific ROMS only (used for rescanning purposes)
    if [ $console == "NES" ]; then
        games_folder_size="`cd /media/fat/games/$console; du -c --max-depth=999 -- *.nes *.fds **/*.nes **/*.fds 2>/dev/null | awk '$2 == "total" {total += $1} END {print total}'`"
    elif [ $console == "SNES" ]; then
        games_folder_size="`cd /media/fat/games/$console; du -c --max-depth=999 -- *.sfc *.smc **/*.sfc **/*.smc 2>/dev/null | awk '$2 == "total" {total += $1} END {print total}'`"
    fi

    echo $games_folder_size > "games_folder_size_$console.txt"
}

launchMenu () {
    DIALOG_CANCEL=1
    DIALOG_ESC=255
    HEIGHT=0
    WIDTH=0

    while true; do
        exec 3>&1
        selection=$(dialog \
            --backtitle "Random Game Launcher" \
            --clear \
            --cancel-label "Exit" \
            --menu "Select a console:" $HEIGHT $WIDTH 4 \
            "1" "NES" \
            "2" "SNES" \
             2>&1 1>&3)
        exit_status=$?
        exec 3>&-

        case $exit_status in
            $DIALOG_CANCEL)
                clear
                echo "Program terminated"
                echo
                exit
                ;;
            $DIALOG_ESC)
                clear
                echo "Program aborted" >&2
                echo
                exit 1
                ;;
        esac

        case $selection in
            1 )
                console="NES"
                break
                ;;
            2 )
                console="SNES"
                break
                ;;
        esac
    done
}

loadRandomRom () {
    total_roms="`cat rom_count_$console.txt`"
    random_number="$(( $RANDOM % $total_roms + 1 ))"
    random_rom_path="`sed -n "$random_number"p rom_path_$console.txt`"
    random_rom_filename="`echo "${random_rom_path##*/}"`"
    random_rom_extension="`echo "${random_rom_filename##*.}"`"

    if [ $hide_rom_name_on_launch -eq 1 ]; then random_rom_filename="???"; fi
    clear
    printf "Now loading...\n\n$random_number / $total_roms: $random_rom_filename"
    sleep 2

    # load random ROM
    if [[ $random_rom_extension == "fds" ]]
    then
        /media/fat/Scripts/.mister_batch_control/mbc load_rom "NES.FDS" "$random_rom_path"
    else # TODO - do an elif here if another alternate core is needed besides FDS
        # https://raw.githubusercontent.com/pocomane/MiSTer_Batch_Control/master/mbc.c
        /media/fat/Scripts/.mister_batch_control/mbc load_rom "$console" "$random_rom_path"
    fi
}

rescanRoms () {
    if [ $console == "NES" ]; then
        current_games_folder_size="`cd /media/fat/games/$console; du -c --max-depth=999 -- *.nes *.fds **/*.nes **/*.fds 2>/dev/null | awk '$2 == "total" {total += $1} END {print total}'`"
    elif [ $console == "SNES" ]; then
        current_games_folder_size="`cd /media/fat/games/$console; du -c --max-depth=999 -- *.sfc *.smc **/*.sfc **/*.smc 2>/dev/null | awk '$2 == "total" {total += $1} END {print total}'`"
    fi

    previous_games_folder_size="`cat games_folder_size_$console.txt`"

    if [ "$current_games_folder_size" -ne "$previous_games_folder_size" ]
    then
        clear
        printf "** FILE CHANGE DETECTED - Please be patient while $console ROMS are re-scanned **"
        sleep 2
        scanRoms
        getFolderSize
    fi
}

scanRoms () {
    # find all rom files and print them to a file
        if [ $console == "NES" ]; then
            find "$core_games_folder" -iregex '.*\.\(nes\|fds\)$' -exec ls > "rom_path_$console.txt" {} \;
        elif [ $console == "SNES" ]; then
            find "$core_games_folder" -iregex '.*\.\(sfc\|smc\)$' -exec ls > "rom_path_$console.txt" {} \;
        fi

    # if rom_path_$console.txt is empty, no ROMS were found, so exit
    if [[ -z $(grep '[^[:space:]]' rom_path_$console.txt) ]]
    then
        clear
        printf "ERROR: No $console ROMS found at $core_games_folder, exiting\n\n"
        exit 126
    else
        # generate line count and export to rom_count_$console.txt
        cat "rom_path_$console.txt" | sed '/^\s*$/d' | wc -l > "rom_count_$console.txt"
        total_roms="`cat rom_count_$console.txt`"
        clear
        printf "Scan complete - ROMS found: $total_roms\n\n"
        sleep 1
        # create scanned_$console.txt file to stop from scanning again
        touch "scanned_$console.txt"
    fi
}

#=========   END FUNCTIONS   =========

#=========   BEGIN MAIN PROGRAM   =========

# Set variables
core_games_folder="/media/$fat_or_usb0/games/$console"
config_folder="/media/fat/Scripts/.rgl"

# Install dependencies
checkDependencies

# Launch menu
launchMenu

# If the console has already been scanned, check for new roms, then load game, Otherwise, run an initial scan and then load a random game
if [[ -f "scanned_$console.txt" ]]
then
    rescanRoms
    loadRandomRom
else
    clear
    printf "** INITIAL SCAN - Please be patient while $console ROMS are scanned **"
    sleep 1
    scanRoms
    getFolderSize
    loadRandomRom
fi

exit 0

#=========   END MAIN PROGRAM   =========

---------------------------------------------------------

TO-DO

- Add supported consoles
GAMEBOY
GBA
Genesis
NeoGeo
SMS
TGFX16

- Add ALL option

- Script that curls actual script
wget -L "https://raw.githubusercontent.com/copperkiddx/rgl-tester/main/random_game_launcher.sh"

- Create README.md

- Check script at https://www.shellcheck.net/

- Create official github before launch