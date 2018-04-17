#!/bin/bash
# script file used for setting up rpi for digital wastebin

# list of necessary software
software=" server-xorg xinit ufw ntp gcc chromium-browser unclutter git "

version="final"
project_name="UCI-DWB"
startup_file="${HOME}/.bashrc" # location of file that would be run when user logins
display_file="${HOME}/.xinitrc"
boot_config_file="/boot/config.txt"
MODE="compost" # later become env variable to determine which mode this pi is running on

source ./utils.h

set -e 
set -o pipefail
set -o nounset

#-------------------------------------------------------------------------------
if [ ${USER} = pi ] || [ ${USER} = root ]; then
  print_error "Please don't use pi or root for install, create another account first\n"
  exit 1
fi

print_message "Starting setup"

# change keyboard layout to make sure the rest of installation is correct
sudo sed -i '/XKBLAYOUT/d' /etc/default/keyboard
echo XKBLAYOUT=\"us\" | sudo tee -a /etc/default/keyboard

#change password from default
empty_input_buffer   
print_message "Please enter new password"
passwd
sudo passwd -l root # lock root account

print_message "Beginning Software Install"
# update and install the necessary software
sudo apt-get update
sudo apt-get dist-upgrade -y 
sudo apt-get update
sudo apt-get install ${software} -y

# enable firewall
sudo ufw enable 
sudo ufw status

# set the correct timezone to California
sudo timedatectl set-timezone US/Pacific

# disable bluetooth after reboot and rotate the display
echo "dtoverlay=pi3-disable-bt" | sudo tee --append ${boot_config_file}
echo "display_rotate=3" | sudo tee --append ${boot_config_file}

# make sure we don't write same setting to the  display file too many times
if [ -e "${display_file}" ]; then 
truncate -s 0 ${display_file}
else
touch ${display_file}
fi

echo "export MODE=COMPOST" | tee --append ${startup_file} # set env var MODE to compost by default
echo "export NON_ROOT_USER=${USER}" | tee --append ${startup_file} # set env var MODE to compost by default
# autologin
sudo sed -i 's|ExecStart=-/sbin/agetty --noclear %I $TERM| ExecStart=-/sbin/agetty --noclear -a root %I $TERM |g' /lib/systemd/system/getty@.service

#-------------------------------------------------------------------------------

print_message "Beginning Display Configuration"

# run this maintain script at startup, everything else run after maintain
echo "${HOME}/${project_name}/shell_script/maintain.sh &" | tee --append ${startup_file}

# replace chromium pref file, TODO: change this to sed in the future
cp -f ${HOME}/UCI-DWB/Preferences_Chromium ${HOME}/.config/chromium/Default/Preferences 

# disable screen blanking
echo "xset s off" |  tee --append ${display_file}
echo "xset -dpms" |  tee --append ${display_file}
echo "xset s noblank" |  tee --append ${display_file}

sed -i 's/\"exited_cleanly\": true/' ${HOME}/.config/chromium/Default/Preferences # disable chromium message about unclean shutdown

echo "point-rpi" | tee --append ${display_file} # move mouse to convenient position
echo "unclutter -idle 0.001 -root" | tee --append ${display_file} # hide mouse pointer

# create symlink for the scale, the number seems to be same for every scale
echo "ACTION==\"add\",SUBSYSTEM==\"tty\", ATTRS{idVendor}==\"0403\", ATTRS{idProduct}==\"6001\", SYMLINK+=\"SCALE\"" | sudo tee --append /etc/udev/rules.d/99-com.rules

# add running html file to display file
echo "chromium-browser --noerrdialogs --kiosk --incognito --allow-file-access-from-files ${HOME}/${project_name}/${MODE}/index.html &" | tee --append ${display_file}

echo "xinit" | tee --append ${startup_file} # start x server at login

# set 720p to the pi, source for the settings: https://elinux.org/RPiconfig#Video_mode_options 
sudo sed -i 's/.*hdmi_mode=.*//' ${boot_config_file} # wipe old settings first
sudo sed -i 's/.*hdmi_group=.*//' ${boot_config_file}
echo "hdmi_mode=4" | sudo tee --append ${boot_config_file} # change to new mode
echo "hdmi_group=1" | sudo tee --append ${boot_config_file}

# enable full screen 
sudo sed -i 's/.*disable_overscan=.*//' ${boot_config_file}
echo "disable_overscan=1" | sudo tee --append ${boot_config_file}

sudo apt autoremove -y
# change branch upstream source
git -C ${HOME}/${project_name}/ branch --set-upstream-to release origin/release 

print_message "Setup done, the system will reboot in 5 seconds"
sleep 5
reboot