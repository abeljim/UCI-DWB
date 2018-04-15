#!/bin/bash
# get the image from the raspberry pi into a zip in path specified by calling argument
# zip name will be the hour:minute_month-date_rpi3_im.gz
# $1 is path to output file(/home/kd/image_file) and $2 is the path to device as a whole (/dev/sdx)
# reference: https://raspberrypi.stackexchange.com/questions/311/how-do-i-backup-my-raspberry-pi
source ./utils.sh
set -e 
set -o pipefail
set -o nounset
block_size=64K # generally recommended

#-------------------------------------------------------------------

# check arguments to see if they are actually folder and file descriptor to sd card
if [ ! -d $1 ] || [ ! -b $2 ]; then
print_error "Given directory is not valid\n"
exit 1

else
print_message "Copying image from SD card"

sudo dd if=$2 bs=${block_size} | gzip > $1/"$(date +'%H:%M_%m-%d')_rpi3_im.gz" # copy then compress
print_message "SD card copied!"
exit 0
fi