#!/bin/bash
# get the image from the raspberry pi into a zip in path specified by calling argument
# zip name will be the hour:minute_month-date_rpi3_im.gz
# $1 is path to output file(/home/kd/image_file) and $2 is the path to device as a whole (/dev/sdx)
# reference: https://raspberrypi.stackexchange.com/questions/311/how-do-i-backup-my-raspberry-pi
YELLOW='\033[38;5;226m' #for error
GREEN='\033[38;5;154m' #for general messages
RESET='\033[0m' #for resetting the color
set -e
#-------------------------------------------------------------------

# check arguments to see if they are actually folder and file descriptor to sd card
if [ ! -d $1 ] || [ ! -f $2 ]; then
printf "${YELLOW}\nGiven directory is not valid\n${RESET}"
exit 1

else
printf "${GREEN}\nCopying image from SD card${RESET}"

sudo dd if=$2 | gzip > $1/"$(date +'%H:%M_%m-%d')_rpi3_im.gz" # copy then compress
printf "${GREEN}\nSD card copied!${RESET}"
exit 0
fi