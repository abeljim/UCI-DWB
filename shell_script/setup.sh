#!/bin/bash
# script file used for setting up rpi for digital wastebin

# list of necessary software
SOFTWARE=" server-xorg xinit ufw ntp gcc chromium-browser unclutter "

VERSION="final"
PROJECT_NAME="UCI-DWB"
STARTUP_FILE="~/.bashrc" # location of file that would be run when user logins
DISPLAY_FILE="~/.xinitrc"
BOOT_CONFIG_FILE="/boot/config.txt"
MODE="compost"

CYAN='\033[38;5;087m' #for marking the being of a new sections
YELLOW='\033[38;5;226m' #for error
GREEN='\033[38;5;154m' #for general messages
RESET='\033[0m' #for resetting the color
set -e 

#-------------------------------------------------------------------------------
printf "\n{GREEN}Starting setup${RESET}"

# change keyboard layout to make sure the rest of installation is correct
sudo sed -i '/XKBLAYOUT/d' /etc/default/keyboard
echo XKBLAYOUT=\"us\" | sudo tee -a /etc/default/keyboard

#change password from default
read -t 0.1 100000 unused # discard everything in stdin so far
read -p  
echo "\n{GREEN}Please enter new password${RESET}"
passwd
sudo passwd -l root # lock root account

printf "\n{GREEN}Beginning Software Install${RESET}"
# update and install the necessary software
sudo apt-get update
sudo apt-get dist-upgrade -y 
sudo apt-get update
sudo apt-get install ${SOFTWARE} -y

# enable firewall
sudo ufw enable 
sudo ufw status

# set the correct timezone to California
sudo timedatectl set-timezone US/Pacific

# disable bluetooth after reboot and rotate the display
echo "dtoverlay=pi3-disable-bt" | sudo tee --append ${BOOT_CONFIG_FILE}
echo "display_rotate=3" | sudo tee --append ${BOOT_CONFIG_FILE}

# make sure we don't write same setting to the  display file too many times
if [ -e "${DISPLAY_FILE}" ]; then 
truncate -s 0 ${DISPLAY_FILE}
else
touch ${DISPLAY_FILE}
fi

#-------------------------------------------------------------------------------

printf "\n{GREEN}Beginning Display Configuration${RESET}"

# run this maintain script at startup, everything else run after maintain
echo "${HOME}/${PROJECT_NAME}/shell_script/maintain.sh &" | tee --append ${STARTUP_FILE}

# replace chromium pref file, TODO: change this to sed in the future
cp -f ~/UCI-DWB/Preferences_Chromium ${HOME}/.config/chromium/Default/Preferences 

# disable screen blanking
echo "xset s off" |  tee --append ${DISPLAY_FILE}
echo "xset -dpms" |  tee --append ${DISPLAY_FILE}
echo "xset s noblank" |  tee --append ${DISPLAY_FILE}

sed -i 's/\"exited_cleanly\": true/' ${HOME}/.config/chromium/Default/Preferences # disable chromium message about unclean shutdown

echo "point-rpi" | tee --append ${DISPLAY_FILE} # move mouse to convenient position
echo "unclutter -idle 0.001 -root" | tee --append ${DISPLAY_FILE} # hide mouse pointer

# create symlink for the scale, the number seems to be same for every scale
echo "ACTION==\"add\",SUBSYSTEM==\"tty\", ATTRS{idVendor}==\"0403\", ATTRS{idProduct}==\"6001\", SYMLINK+=\"SCALE\"" | sudo tee --append /etc/udev/rules.d/99-com.rules

# add running html file to display file
echo "chromium-browser --noerrdialogs --kiosk --incognito --allow-file-access-from-files ${HOME}/${PROJECT_NAME}/${MODE}/index.html &" | tee --append ${DISPLAY_FILE}

echo "xinit" | tee --append ${STARTUP_FILE} # start x server at login

sudo apt autoremove -y
# change branch upstream source
git -C ~/${PROJECT_NAME}/ branch --set-upstream-to release origin/release 

printf "\n{GREEN}Setup done, the system will reboot in 5 seconds${RESET}"
sleep 5
reboot