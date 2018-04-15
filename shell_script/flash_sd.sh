#!/bin/bash
# call the script with the thing to flash
# WILL FLASH TO ANY SD CARD CURRENT ON SYSTEM 
# $1 is the path of the zip image file 
# ref: https://elinux.org/RPi_Easy_SD_Card_Setup 
# ref: https://raspberrypi.stackexchange.com/questions/311/how-do-i-backup-my-raspberry-pi 
YELLOW='\033[38;5;226m' #for error
GREEN='\033[38;5;154m' #for general messages
RESET='\033[0m' #for resetting the color
set -e
#----------------------------------------------------------------------

if ! gzip -t $1; then
printf "\n{YELLOW}Zip file not valid\n${RESET}"
exit 1
else 
printf "\n{GREEN}Beginning copying to sd card${RESET}"
SD_LIST="$(ls /dev/ | grep -G "mmcblk[0123456789]$")" # find all sd card on system

if [ -z SD_LIST ]; then 
printf "\n{YELLOW}No SD card in system\n${RESET}"
exit 1
fi

# start copy process if there is at least one SD card in system
for sd_card in ${SD_LIST}; do
printf "\n{GREEN}Copying to ${sd_card}${RESET}\n"
gzip -dc $1 | dd of=/dev/${sd_card}
done

printf "\n{GREEN}Done copying to all sd card\n${RESET}"
exit 0
fi