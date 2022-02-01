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

fat_or_usb0="fat" # Location of your ROMS: Use "fat" for microSD or "usb0" for hard drive
hide_rom_name_on_launch="0" # Use "0" to display the game name upon launch OR "1" to display "???" instead of the game name

#=========   END USER OPTIONS   =========

#=========   FUNCTIONS   =========

checkDependencies () {
    config_folder="/media/fat/Scripts/.rgl"
    [ ! -d "$config_folder" ] && mkdir "$config_folder" # If config folder doesn't exist, create it
    cd $config_folder
    
    if [[ ! -f "/media/fat/Scripts/.mister_batch_control/mbc" ]] # If mbc does not exist, download it
    then
        clear
        ping -c 1 8.8.8.8 &>/dev/null; [ "$?" != "0" ] && clear && printf "ERROR: No internet connection - Missing dependencies cannot be installed. Please try again\n\n" && exit 126 # Test internet
        printf "Installing missing dependencies from Github (mbc)..."
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

getFolderSize () { # Find total disk space used by console-specific ROMS only (used for re-scanning purposes)
    if [ $console == "NES" ]; then
        games_folder_size="`cd /media/fat/games/$console; du -c --max-depth=999 -- *.nes *.fds **/*.nes **/*.fds 2>/dev/null | awk '$2 == "total" {total += $1} END {print total}'`"
    elif [ $console == "SNES" ]; then
        games_folder_size="`cd /media/fat/games/$console; du -c --max-depth=999 -- *.sfc *.smc **/*.sfc **/*.smc 2>/dev/null | awk '$2 == "total" {total += $1} END {print total}'`"
    elif [ $console == "Genesis" ]; then
        games_folder_size="`cd /media/fat/games/$console; du -c --max-depth=999 -- *.bin *.gen *.md **/*.bin **/*.gen **/*.md 2>/dev/null | awk '$2 == "total" {total += $1} END {print total}'`"
    elif [ $console == "GBA" ]; then
        games_folder_size="`cd /media/fat/games/$console; du -c --max-depth=999 -- *.gba **/*.gba 2>/dev/null | awk '$2 == "total" {total += $1} END {print total}'`"
    elif [ $console == "GAMEBOY" ]; then
        games_folder_size="`cd /media/fat/games/$console; du -c --max-depth=999 -- *.gb *.gbc **/*.gb **/*.gbc 2>/dev/null | awk '$2 == "total" {total += $1} END {print total}'`"
    elif [ $console == "SMS" ]; then
        games_folder_size="`cd /media/fat/games/$console; du -c --max-depth=999 -- *.sms **/*.sms 2>/dev/null | awk '$2 == "total" {total += $1} END {print total}'`"
    elif [ $console == "TGFX16" ]; then
        games_folder_size="`cd /media/fat/games/$console; du -c --max-depth=999 -- *.pce **/*.pce 2>/dev/null | awk '$2 == "total" {total += $1} END {print total}'`"
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
            "3" "Genesis" \
            "4" "GBA" \
            "5" "GAMEBOY" \
            "6" "Master System" \
            "7" "TurboGrafx-16" \
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
            3 )
                console="Genesis"
                break
                ;;
            4 )
                console="GBA"
                break
                ;;
            5 )
                console="GAMEBOY"
                break
                ;;
            6 )
                console="SMS"
                break
                ;;
            7 )
                console="TGFX16"
                break
                ;;
        esac
    done
}

loadRandomRom () {
    total_roms="`cat rom_count_$console.txt`"
    random_number="$(( $RANDOM % $total_roms + 1 ))"
    random_rom_path="`sed -n "$random_number"p rom_paths_$console.txt`"
    random_rom_filename="`echo "${random_rom_path##*/}"`"
    random_rom_extension="`echo "${random_rom_filename##*.}"`"

    if [ $hide_rom_name_on_launch -eq 1 ]; then random_rom_filename="???"; fi
    clear
    printf "Now loading...\n\n$random_number / $total_roms: $random_rom_filename\n\n"
    sleep 2

    # load random ROM # https://raw.githubusercontent.com/pocomane/MiSTer_Batch_Control/master/mbc.c
    if [[ $random_rom_extension == "fds" ]]; then
        /media/fat/Scripts/.mister_batch_control/mbc load_rom "NES.FDS" "$random_rom_path"
    elif [[ $random_rom_extension == "gen" ]]; then
        /media/fat/Scripts/.mister_batch_control/mbc load_rom "GENESIS" "$random_rom_path"
    elif [[ $random_rom_extension == "md" ]]; then
        /media/fat/Scripts/.mister_batch_control/mbc load_rom "MEGADRIVE" "$random_rom_path"
    elif [[ $random_rom_extension == "bin" ]]; then
        /media/fat/Scripts/.mister_batch_control/mbc load_rom "MEGADRIVE.BIN" "$random_rom_path"
    elif [[ $random_rom_extension == "gbc" ]]; then
        /media/fat/Scripts/.mister_batch_control/mbc load_rom "GAMEBOY.COL" "$random_rom_path"
    else
        /media/fat/Scripts/.mister_batch_control/mbc load_rom "$console" "$random_rom_path"
    fi
}

rescanRoms () {
    if [ $console == "NES" ]; then
        current_games_folder_size="`cd /media/fat/games/$console; du -c --max-depth=999 -- *.nes *.fds **/*.nes **/*.fds 2>/dev/null | awk '$2 == "total" {total += $1} END {print total}'`"
    elif [ $console == "SNES" ]; then
        current_games_folder_size="`cd /media/fat/games/$console; du -c --max-depth=999 -- *.sfc *.smc **/*.sfc **/*.smc 2>/dev/null | awk '$2 == "total" {total += $1} END {print total}'`"
    elif [ $console == "Genesis" ]; then
        current_games_folder_size="`cd /media/fat/games/$console; du -c --max-depth=999 -- *.bin *.gen *.md **/*.bin **/*.gen **/*.md 2>/dev/null | awk '$2 == "total" {total += $1} END {print total}'`"
    elif [ $console == "GBA" ]; then
        current_games_folder_size="`cd /media/fat/games/$console; du -c --max-depth=999 -- *.gba **/*.gba 2>/dev/null | awk '$2 == "total" {total += $1} END {print total}'`"
    elif [ $console == "GAMEBOY" ]; then
        current_games_folder_size="`cd /media/fat/games/$console; du -c --max-depth=999 -- *.gb *.gbc **/*.gb **/*.gbc 2>/dev/null | awk '$2 == "total" {total += $1} END {print total}'`"
    elif [ $console == "SMS" ]; then
        current_games_folder_size="`cd /media/fat/games/$console; du -c --max-depth=999 -- *.sms **/*.sms 2>/dev/null | awk '$2 == "total" {total += $1} END {print total}'`"
    elif [ $console == "TGFX16" ]; then
        current_games_folder_size="`cd /media/fat/games/$console; du -c --max-depth=999 -- *.pce **/*.pce 2>/dev/null | awk '$2 == "total" {total += $1} END {print total}'`"
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
            find "$core_games_folder" -iregex '.*\.\(nes\|fds\)$' ! -name '*[Rr][Ee][Aa][Dd][Mm][Ee]*' -exec ls > "rom_paths_$console.txt" {} \;
        elif [ $console == "SNES" ]; then
            find "$core_games_folder" -iregex '.*\.\(sfc\|smc\)$' ! -name '*[Rr][Ee][Aa][Dd][Mm][Ee]*' -exec ls > "rom_paths_$console.txt" {} \;
        elif [ $console == "Genesis" ]; then
            find "$core_games_folder" -iregex '.*\.\(bin\|gen\|md\)$' ! -name '*[Rr][Ee][Aa][Dd][Mm][Ee]*' -exec ls > "rom_paths_$console.txt" {} \;
        elif [ $console == "GBA" ]; then
            find "$core_games_folder" -iregex '.*\.\(gba\)$' ! -name '*[Rr][Ee][Aa][Dd][Mm][Ee]*' -exec ls > "rom_paths_$console.txt" {} \;
        elif [ $console == "GAMEBOY" ]; then
            find "$core_games_folder" -iregex '.*\.\(gb\|gbc\)$' ! -name '*[Rr][Ee][Aa][Dd][Mm][Ee]*' -exec ls > "rom_paths_$console.txt" {} \;
        elif [ $console == "SMS" ]; then
            find "$core_games_folder" -iregex '.*\.\(sms\)$' ! -name '*[Rr][Ee][Aa][Dd][Mm][Ee]*' -exec ls > "rom_paths_$console.txt" {} \;
        elif [ $console == "TGFX16" ]; then
            find "$core_games_folder" -iregex '.*\.\(pce\)$' ! -name '*[Rr][Ee][Aa][Dd][Mm][Ee]*' -exec ls > "rom_paths_$console.txt" {} \;
        fi

    # if rom_paths_$console.txt is empty, no ROMS were found, so exit
    if [[ -z $(grep '[^[:space:]]' rom_paths_$console.txt) ]]
    then
        clear
        printf "ERROR: No $console ROMS found at $core_games_folder, exiting\n\n"
        exit 126
    else
        # generate line count and export to rom_count_$console.txt
        cat "rom_paths_$console.txt" | sed '/^\s*$/d' | wc -l > "rom_count_$console.txt"
        total_roms="`cat rom_count_$console.txt`"
        clear
        printf "Scan complete - ROMS found: $total_roms\n\n"
        sleep 1
        # create scanned_$console file to stop from scanning again
        touch "scanned_$console"
    fi
}

#=========   END FUNCTIONS   =========

#=========   BEGIN MAIN PROGRAM   =========

# Install dependencies
checkDependencies

# Launch menu
launchMenu

# Set console game folder path variable
core_games_folder="/media/$fat_or_usb0/games/$console"

# If the console has already been scanned, check for new roms, then load game, Otherwise, run an initial scan and then load a random game
if [[ -f "scanned_$console" ]]
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

clear

exit

#=========   END MAIN PROGRAM   =========

---------------------------------------------------------

TO-DO

- Add "ALL" option

- Script that curls actual script
wget -L "https://raw.githubusercontent.com/copperkiddx/rgl-tester/main/random_game_launcher.sh"

- Create README.md

- Check script at https://www.shellcheck.net/

- Create official github before launch

- Fix link in line 20

- Rename script?

README

- You must be connected to the internet the first time you run this script to download a dependency
- If you wish to run it offline after that, download the script from here and place it in your /media/fat/Scripts folder. But please note, you will not get the latest script updates this way.
- Be sure to set fat or usb0 in the user options before you use the script! The default is microsd (fat) but some people use usb0

1983 NES
1986 SMS
1987 TGFX16
1988 Genesis
1989 GAMEBOY
1990 SNES
2001 GBA