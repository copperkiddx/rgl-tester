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

console="NES" # Supported consoles: ATARI2600|GAMEBOY|GBA|Genesis|NeoGeo|NES|SMS|SNES|TGFX16
core_games_folder="/media/fat/games/$console"
config_folder="/media/fat/Scripts/.rgl"
hide_rom_name_on_launch="0"
launch_delay="0"

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
        ping -c 1 8.8.8.8 &>/dev/null; [ "$?" != "0" ] && printf "No internet connection, please try again\n\n" && exit 126
        printf "Installing dependencies (MiSTer_Batch_Control)...\n\n"
        mkdir /media/fat/Scripts/.mister_batch_control
        wget -qP /media/fat/Scripts/.mister_batch_control "https://github.com/pocomane/MiSTer_Batch_Control/releases/download/untagged-533dda82c9fd24faa6f1/mbc"
        if md5sum --status -c <(echo ea32cf0d76812a9994b27365437393f2 /media/fat/Scripts/.mister_batch_control/mbc)
        then
            printf "MiSTer_Batch_Control successfully installed to /media/fat/Scripts/.mister_batch_control/mbc\n\n"
        else
            printf "ERROR: md5sum for MiSTer_Batch_Control binary is bad, exiting\n\n"
            exit 1
        fi
    fi
}

scanRoms () {
    # find all rom files and print them to a file
    find "$core_games_folder" -iregex '.*\.\(nes\|fds\)$' -exec ls > "rom_path_$console.txt" {} \;
    # if rom_path_$console.txt is empty, no ROMS were found so exit
    if [[ -z $(grep '[^[:space:]]' rom_path_$console.txt) ]]
    then
        printf "ERROR: No $console ROMS found at $core_games_folder, exiting...\n\n"
        exit 1
    else
        # generate line count and export to rom_count_$console.txt
        cat "rom_path_$console.txt" | sed '/^\s*$/d' | wc -l > "rom_count_$console.txt"
        total_roms="`cat rom_count_$console.txt`"
        printf "Scan complete - ROMS found: $total_roms\n\n"
        # create scanned_$console.txt file to stop from scanning again
        touch "scanned_$console.txt"
    fi
}

loadRandomRom () {
    total_roms="`cat rom_count_$console.txt`"
    random_number="$(( $RANDOM % $total_roms + 1 ))"
    random_rom_path="`sed -n "$random_number"p rom_path_$console.txt`"
    random_rom_filename="`echo "${random_rom_path##*/}"`"
    random_rom_extension="`echo "${random_rom_filename##*.}"`"
    if [[ $hide_rom_name_on_launch == "1" ]]
    then
        printf "Now loading...\n\n$random_number / $total_roms: ???\n\n"
    else
        printf "Now loading...\n\n$random_number / $total_roms: $random_rom_filename\n\n"
    fi
    sleep "$launch_delay"
    # load random ROM
    if [[ $random_rom_extension == "fds" ]]
    then
        /media/fat/Scripts/.mister_batch_control/mbc load_rom "NES.FDS" "$random_rom_path"
    else
        /media/fat/Scripts/.mister_batch_control/mbc load_rom "$console" "$random_rom_path"
    fi
}

getFolderSize () {
    games_folder_size="`du -s --exclude='*.[Rr][Oo][Mm]' --exclude='*.md' --exclude='*.txt' --exclude='.DS_Store' --exclude='._.DS_Store' --exclude=/media/fat/games/$console/Palettes /media/fat/games/$console | awk '{print $1}'`"
    echo $games_folder_size > "$games_folder_size_console.txt"
}

rescanRoms () {
    current_games_folder_size="`du -s --exclude='*.[Rr][Oo][Mm]' --exclude='*.md' --exclude='*.txt' --exclude='.DS_Store' --exclude='._.DS_Store' --exclude=/media/fat/games/$console/Palettes /media/fat/games/$console | awk '{print $1}'`"
    previous_games_folder_size="`cat $games_folder_size_console.txt`"
    if [ "$current_games_folder_size" -ne "$previous_games_folder_size" ]
    then
        printf "** FILE CHANGE DETECTED - Please be patient while all ROMS are re-scanned **\n\n"
        scanRoms
        getFolderSize
fi
}

#=========   END FUNCTIONS   =========

#=========   BEGIN SCRIPT   =========

printf "Random Game Launcher ($console)\n\n"

checkDependencies

if [[ -f "scanned_$console.txt" ]]
then
    rescanRoms
    loadRandomRom
else
    printf "** INITIAL SCAN - Please be patient while all ROMS are scanned **\n\n"
    scanRoms
    getFolderSize
    loadRandomRom
fi

exit 0

#=========   END SCRIPT   =========

---------------------------------------------------------

TO-DO

- Make this line not dependent on NES file extensions:
find "$core_games_folder" -iregex '.*\.\(nes\|fds\)$' -exec ls > "rom_path_$console.txt" {} \;

- Script that curls actual script
wget -L "https://raw.githubusercontent.com/copperkiddx/rgl-tester/main/random_game_launcher.sh"

- Create README.md

- Faster way to get a list of rom locations? Tree? Maybe du is faster
du -c -- **/*.nes **/*.fds | tail -n 1

- Check script at https://www.shellcheck.net/

- Interactive menu to select any core?

- Create official github before launch

- find filesize of only specific rom extensions

cd /media/fat/games/$console; shopt -s extglob; du -sc -- **/*.nes **/*.fds | tail -n 1 | awk '{print $1}'