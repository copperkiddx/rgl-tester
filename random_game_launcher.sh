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
        printf "Installing dependencies (MiSTer_Batch_Control by the amazing Pocomane)...\n\n"
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

firstRun () {
    printf "** INITIAL SCAN ($console): Please be patient while all ROMS are scanned **\n\n"
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

#=========   END FUNCTIONS   =========

#=========   BEGIN SCRIPT   =========

printf "Random Game Launcher ($console)\n\n"

checkDependencies

if [[ -f "scanned_$console.txt" ]]
then
    loadRandomRom
else
    firstRun
    loadRandomRom
fi

exit 0

#=========   END SCRIPT   =========

---------------------------------------------------------

TO-DO

- Script that curls actual script
wget -L "https://raw.githubusercontent.com/copperkiddx/rgl-tester/main/random_game_launcher.sh"

- Check games folder size with du and diff to rescan core

- README

- Faster way to get a list of rom locations? Tree?

- Diff rom counts for rom list update?

# if rom_count.txt exists, cat it to set variable (for use with rescanning ROMS later on)
# if nes.txt exists
#   count lines
#   if lines != $(cat rom_count.txt), then rescan
# else
#   # find all rom files and print them to a file
# [ -f rom_count.txt ] && rom_count="`cat rom_count.txt`"

- Check script at https://www.shellcheck.net/

- Interactive menu to select any core?

- Create official github before launch
- hi