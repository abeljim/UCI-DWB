#!/bin/bash
# call the script with the thing to flash
# WILL FLASH TO ANY SD CARD CURRENT ON SYSTEM 
# $1 is the path of the zip image file 
# ref: https://elinux.org/RPi_Easy_SD_Card_Setup 
# ref: https://raspberrypi.stackexchange.com/questions/311/how-do-i-backup-my-raspberry-pi 
# note that there is no need to format the card before flashing it with this script
source ./utils.sh

set -e 
set -o pipefail
set -o nounset
block_size=64K # generally recommended
#----------------------------------------------------------------------

if ! gzip -t $1; then
print_error "Zip file not valid\n"
exit 1
else 
print_message "Beginning copying to sd card"
SD_LIST="$(ls /dev/ | grep -G "mmcblk[0123456789]$")" # find all sd card on system

if [ -z SD_LIST ]; then 
print_error "No SD card in system\n"
exit 1
fi

# start copy process if there is at least one SD card in system
for sd_card in ${SD_LIST}; do
print_message "Copying to ${sd_card}\n"
gzip -dc $1 | dd of=/dev/${sd_card} bs=${block_size}
done

print_message "Done copying to all sd card\n"
exit 0
fi