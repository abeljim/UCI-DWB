#!/bin/bash
# call the script with the thing to flash
# WILL FLASH TO ANY SD CARD CURRENT ON SYSTEM 
# $1 is the path of the zip image file, should be in .gz format or .tar.gz
# ref: https://elinux.org/RPi_Easy_SD_Card_Setup 
# ref: https://raspberrypi.stackexchange.com/questions/311/how-do-i-backup-my-raspberry-pi 
# note that there is no need to format the card before flashing it with this script
source ./utils.sh

block_size=64K # generally recommended
#----------------------------------------------------------------------

print_message "Checking input files"
if ! gzip -t $1; then
print_error "Zip file not valid\n"
exit 1
else
print_message "Zip file is valid"

# find all sd card on connected on system
# criteria is based on their partition having FAT32 type
SD_LIST="$(ls /dev/ | grep -G "mmcblk[0123456789]$")"
SD_LIST="${SD_LIST} $(sudo fdisk -l | grep FAT32 | sed -E 's|/dev/sd(.)(.*)|/dev/sd\1|g')" 
if [ ${SD_LIST} = " " ] ; then 
print_error "No SD card in system\n"
exit 1
fi

print_message "ALL SD CARD WILL BE OVERWRITTEN, make sure they have at least one FAT partition, all drives with FAT wil be wiped " 
print_message "List of Drives to be overwritten:"
for sd_card in "${SD_LIST}"; do
echo ${sd_card} 
done
print_message "Please press any key to confirm writing"
empty_input_buffer
read confirmation
print_message "Beginning copying to sd card"

# start copy process if there is at least one SD card in system
for sd_card in ${SD_LIST}; do
print_message "Copying to ${sd_card}\n"
gzip -dc $1 | sudo dd of=${sd_card} bs=${block_size}

done

print_message "Done copying to all sd card\n"
exit 0
fi