#!/bin/bash

# Random Game Launcher v1.0
# (Non-interactive single console version)
# by copperkiddx

#=========   USER OPTIONS   =========

console="NES" # Options are NES|SNES|Genesis, etc.
core_games_folder="/media/fat/games/$console"
config_folder="/media/fat/Scripts/.rgl"
hide_rom_name_on_launch="0"
launch_delay="2"

#=========   END USER OPTIONS   =========

#=========   FUNCTIONS   =========

firstRun () {
    printf "** FIRST RUN ($console): Please be patient while all roms are scanned **\n\n"
    # find all rom files and print them to a file
    find "$core_games_folder" -iregex '.*\.\(nes\|fds\|nsf\)$' -exec ls > "rom_path_$console.txt" {} \;
    # if rom_path_$console.txt is empty, no roms were found so exit
    if [[ -z $(grep '[^[:space:]]' rom_path_$console.txt) ]]
    then
        printf "ERROR: No $console roms found at $core_games_folder, exiting...\n\n"
        exit 1
    else
        # generate line count and export to rom_count_$console.txt
        cat "rom_path_$console.txt" | sed '/^\s*$/d' | wc -l > "rom_count_$console.txt"
        total_roms="`cat rom_count_$console.txt`"
        printf "Scan complete - $console ROMS found: $total_roms\n\n"
        # create scanned_$console.txt file to stop from scanning again
        touch "scanned_$console.txt"
    fi
}

loadRandomRom () {
    total_roms="`cat rom_count_$console.txt`"
    random_number="$(( $RANDOM % $total_roms + 1 ))"
    random_rom_path="`sed -n "$random_number"p rom_path_$console.txt`"
    random_rom_filename="`echo "${random_rom_path##*/}"`"
    if [[ $hide_rom_name_on_launch == "1" ]]
    then
        printf "Now loading...\n\n$random_number / $total_roms: ???\n\n"
    else
        printf "Now loading...\n\n$random_number / $total_roms: $random_rom_filename\n\n"
    fi
    sleep "$launch_delay"
    # load random ROM
    /media/fat/Scripts/mbc load_rom "$console" "$random_rom_path"
}

#=========   END FUNCTIONS   =========

#=========   BEGIN SCRIPT   =========

printf "Random Game Launcher ($console)\n\n"

# if config folder doesn't exist, create it
[ ! -d "$config_folder" ] && mkdir "$config_folder"

# cd into config folder
cd $config_folder

if [[ ! -f "/media/fat/Scripts/mbc" ]]
then
    # Test internet
    ping -c 1 8.8.8.8 &>/dev/null; [ "$?" != "0" ] && printf "No internet connection, please try again\n\n" && exit 126
    printf "Installing dependencies (MiSTer_Batch_Control by the amazing Pocomane)...\n\n"
    wget -P /media/fat/Scripts "https://github.com/pocomane/MiSTer_Batch_Control/releases/download/untagged-533dda82c9fd24faa6f1/mbc"
    if md5sum --status -c <(echo ea32cf0d76812a9994b27365437393f2 /media/fat/Scripts/mbc)
    then
        printf "mbc succesfully installed to /media/fat/Scripts\n\n"
    else
        printf "ERROR: md5sum for MiSTer_Batch_Control binary is bad, exiting\n\n"
        exit 1
    fi
fi

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

Faster way to get a list of rom locations? Tree?

---------------------------------------------------------

Diff rom counts for rom list update?

# if rom_count.txt exists, cat it to set variable (for use with rescanning roms later on)
# if nes.txt exists
#   count lines
#   if lines != $(cat rom_count.txt), then rescan
# else
#   # find all rom files and print them to a file
# [ -f rom_count.txt ] && rom_count="`cat rom_count.txt`"

---------------------------------------------------------

Check script at https://www.shellcheck.net/

---------------------------------------------------------

Interactive menu?

---------------------------------------------------------

# show which game it's playing ($random_number)
sed -n 11982p /media/fat/.rgl/nes.txt

hi 