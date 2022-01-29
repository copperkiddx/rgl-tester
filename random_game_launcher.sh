#!/bin/bash

# Random Game Launcher v1.0 (Non-interactive version)
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
# https://github.com/copperkiddx/random_game_launcher

#=========   USER OPTIONS   =========

fat_or_usb0="fat"
hide_rom_name_on_launch="1"

#=========   END USER OPTIONS   =========

#=========   FUNCTIONS   =========

checkDependencies () {
    # if config folder doesn't exist, create it
    [ ! -d "$config_folder" ] && mkdir "$config_folder"
    # cd into config folder
    cd $config_folder
    if [[ ! -f "/media/fat/Scripts/.mister_batch_control/mbc" ]]
    then
        # Test internet
        clear
        ping -c 1 8.8.8.8 &>/dev/null; [ "$?" != "0" ] && clear && printf "No internet connection, please try again\n\n" && exit 126
        printf "Installing dependencies (MiSTer_Batch_Control)..."
        mkdir /media/fat/Scripts/.mister_batch_control
        wget -qP /media/fat/Scripts/.mister_batch_control "https://github.com/pocomane/MiSTer_Batch_Control/releases/download/untagged-533dda82c9fd24faa6f1/mbc"
        sleep 1
        if md5sum --status -c <(echo ea32cf0d76812a9994b27365437393f2 /media/fat/Scripts/.mister_batch_control/mbc)
        then
            clear
            printf "MiSTer_Batch_Control successfully installed to /media/fat/Scripts/.mister_batch_control/mbc"
            sleep 2
        else
            clear
            printf "ERROR: md5sum for MiSTer_Batch_Control binary is bad, exiting"
        fi
    fi
}

getFolderSize () {
    games_folder_size="`du -s --exclude='*.[Rr][Oo][Mm]' --exclude='*.md' --exclude='*.txt' --exclude='.DS_Store' --exclude='._.DS_Store' --exclude=/media/fat/games/$console/Palettes /media/fat/games/$console | awk '{print $1}'`"
    echo $games_folder_size > "$games_folder_size_console.txt"
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
    else # do an elif here if another alternate core is needed
        /media/fat/Scripts/.mister_batch_control/mbc load_rom "$console" "$random_rom_path"
    fi
}

rescanRoms () {
    current_games_folder_size="`du -s --exclude='*.[Rr][Oo][Mm]' --exclude='*.md' --exclude='*.txt' --exclude='.DS_Store' --exclude='._.DS_Store' --exclude=/media/fat/games/$console/Palettes /media/fat/games/$console | awk '{print $1}'`"
    previous_games_folder_size="`cat $games_folder_size_console.txt`"
    if [ "$current_games_folder_size" -ne "$previous_games_folder_size" ]
    then
        clear
        printf "** FILE CHANGE DETECTED - Please be patient while all ROMS are re-scanned **"
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
        else
            copperkiddx="awesome"
        fi

    # if rom_path_$console.txt is empty, no ROMS were found so exit
    if [[ -z $(grep '[^[:space:]]' rom_path_$console.txt) ]]
    then
        clear
        printf "ERROR: No $console ROMS found at $core_games_folder, exiting...\n\n"
        exit 1
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

# Create menu

DIALOG_CANCEL=1
DIALOG_ESC=255
HEIGHT=0
WIDTH=0

display_result() {
  dialog --title "$1" \
    --no-collapse \
    --msgbox "$result" 0 0
}

while true; do
  exec 3>&1
  selection=$(dialog \
    --backtitle "System Information" \
    --title "Random Game Launcher" \
    --clear \
    --cancel-label "Exit" \
    --menu "Please select:" $HEIGHT $WIDTH 4 \
    "1" "NES" \
    "2" "SNES" \
    2>&1 1>&3)
  exit_status=$?
  exec 3>&-
  case $exit_status in
    $DIALOG_CANCEL)
      clear
      echo "Program terminated."
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

# Set variables

core_games_folder="/media/$fat_or_usb0/games/$console"
config_folder="/media/fat/Scripts/.rgl"

# run checkDependencies function
checkDependencies

# run main functions
if [[ -f "scanned_$console.txt" ]]
then
    rescanRoms
    loadRandomRom
else
    clear
    printf "** INITIAL SCAN - Please be patient while all $console ROMS are scanned **"
    sleep 2
    scanRoms
    getFolderSize
    loadRandomRom
fi

exit 0

#=========   END MAIN PROGRAM   =========

---------------------------------------------------------

TO-DO

- Script that curls actual script
wget -L "https://raw.githubusercontent.com/copperkiddx/rgl-tester/main/random_game_launcher.sh"

- Create README.md

- Faster way to get a list of rom locations? Tree? Maybe du is faster
du -c -- **/*.nes **/*.fds | tail -n 1

- Check script at https://www.shellcheck.net/

- Create official github before launch

- find filesize of only specific rom extensions

cd /media/fat/games/$console; shopt -s extglob; du -sc -- **/*.nes **/*.fds | tail -n 1 | awk '{print $1}'