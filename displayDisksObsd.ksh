#!/bin/ksh

# Intellectual property information START
# 
# Copyright (c) 2021 Ivan Bityutskiy 
# 
# Permission to use, copy, modify, and distribute this software for any
# purpose with or without fee is hereby granted, provided that the above
# copyright notice and this permission notice appear in all copies.
# 
# THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
# WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
# MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
# ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
# WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
# ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
# OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
# 
# Intellectual property information END

# Description START
#
# The script displays information about
# available disk devices on OpenBSD system.
# The script is written for OpenBSD's pdksh.
#
# Description END

# Shell settings START
set -o noglob
# Shell settings END

# Declare variables START
# Getting total count of disk devices
integer diskCount=$(sysctl hw.diskcount | cut -d '=' -f 2)
# Setting conunter for array iteration
integer counter=2
# Getting output from dmesg
typeset dmesgOut="$(dmesg | grep '[fchws]d[[:digit:]]')"
# Setting labels for the script's output
typeset fdLabel='\033[1mFDD devices:\033[0m'
typeset cdLabel='\033[1mCD/DVD devices:\033[0m'
typeset wdLabel='\033[1mIDE devices:\033[0m'
typeset sdLabel='\033[1mSCSI & RAID devices:\033[0m'
# Setting variable to contain the file system's location
typeset specialFile=''
# Getting disk names from sysctl into array
set -A arrDisks -- $(sysctl hw.disknames |
  awk 'BEGIN {
               RS = ","
             }
             {
               sub("^.*=", "", $0)
               sub(":.*$", "", $0)
               print $0
             }')
# Setting array to contain script's output
set -A arrResult -- "\n\033[1mList of disk devices on \033[34m$(uname -n)\033[0m" \
  "    Total number of disk devices: \033[34m${diskCount}\033[0m"
# Declare variables END

# BEGINNING OF SCRIPT
# Formatting dmesg information and writing
# it into array containing script's output
for item in "${arrDisks[@]}"
  do
    itemName="$(print -- "$dmesgOut" |
      # Examle input string:
      # "wd0 at pciide1 channel 1 drive 0: <SAMSUNG HD501LJ>"
      # Comparing input string against pattern "wd0.*<"
      # displaying 2nd field: "SAMSUNG HD501LJ"
      awk -v "diskFile=$item" -F '[<>]' '$0 ~ diskFile".*<" { fileName = $2 }

        # Comparing input string against pattern "root on wd0"
        # Matching pattern "root on " and calculating the position of "wd0a"
        # Adding ":ROOT" to the output
        # Adding special filename "wd0a" to the output
        # Example output: "SAMSUNG HD501LJ:ROOTwd0a"
        $0 ~ "root on "diskFile {
          match($0, "root on ")
          spDev = substr($0, (RSTART + RLENGTH), 4)
          fileName = fileName":ROOT"spDev
        }

        # Example output: "SAMSUNG HD501LJ:ROOTwd0a:SWAPwd0b"
        $0 ~ "swap on "diskFile {
          match($0, "swap on ")
          spDev = substr($0, (RSTART + RLENGTH), 4)
          fileName = fileName":SWAP"spDev
        }

        # Example output: "SAMSUNG HD501LJ:ROOTwd0a:SWAPwd0b:DUMPwd0b"
        $0 ~ "dump on "diskFile {
          match($0, "dump on ")
          spDev = substr($0, (RSTART + RLENGTH), 4)
          fileName = fileName":DUMP"spDev
        }
        END {
          print fileName
        }')"
    # If it is the first time a certain drive type
    # is being displayed, print the label
    if [[ "$item" == 'fd'* &&  'A'"$fdLabel" != 'A' ]]
    then
      arrResult[counter++]="$fdLabel"
      fdLabel=''
    fi
    
    if [[ "$item" == 'cd'* &&  'A'"$cdLabel" != 'A' ]]
    then
      arrResult[counter++]="$cdLabel"
      cdLabel=''
    fi
    
    if [[ "$item" == [hw]'d'* &&  'A'"$wdLabel" != 'A' ]]
    then
      arrResult[counter++]="$wdLabel"
      wdLabel=''
    fi

    if [[ "$item" == s'd'* &&  'A'"$sdLabel" != 'A' ]]
    then
      arrResult[counter++]="$sdLabel"
      sdLabel=''
    fi
    # Populate the array containing script's output
    # Example $itemName: "SAMSUNG HD501LJ:ROOTwd0a:SWAPwd0b:DUMPwd0b"
    # Storing cleared value of $itemName in the array
    arrResult[counter++]="    ${itemName%%:*}"
    # Storing special device name in the array
    arrResult[counter++]="        Special device: \033[34m$item\033[0m"
    # If $itemName contains ':ROOT', then extracting information
    # about root location and printing it in color
    if [[ "$itemName" == *':ROOT'* ]]
    then
      specialFile="${itemName#*:ROOT}"
      specialFile="${specialFile%%:*}"
      arrResult[counter++]="        \033[31mroot\033[0m on \033[34m$specialFile\033[0m"
    fi
    # If $itemName contains ':SWAP', then extracting information
    # about swap location and printing it in color
    if [[ "$itemName" == *':SWAP'* ]]
    then
      specialFile="${itemName#*:SWAP}"
      specialFile="${specialFile%%:*}"
      arrResult[counter++]="        \033[34mswap\033[0m on \033[34m$specialFile\033[0m"
    fi
    # If $itemName contains ':DUMP', then extracting information
    # about dump location and printing it in color
    if [[ "$itemName" == *':DUMP'* ]]
    then
      specialFile="${itemName#*:DUMP}"
      specialFile="${specialFile%%:*}"
      arrResult[counter++]="        \033[32mdump\033[0m on \033[34m$specialFile\033[0m"
    fi
done
# Adding new line at the end
arrResult[counter++]=""

# Printing the output to error stream
for result in "${arrResult[@]}"
do
  print -u2 -- "$result"
done

# Shell settings START
set +o noglob
# Shell settings END

# END OF SCRIPT

