#!/bin/bash
# used for setting up display and scale
source ./env_var.sh
source ../utils.sh
set -o xtrace
#---------------------------------------------------------------

print_message "Beginning Display Configuration"

# make sure we don't write same setting to the  display file too many times by blanking it
# before installing
if [ -e "${display_file}" ]; then 
truncate -s 0 ${display_file}
else
touch ${display_file}
fi

#-----------------------------------------------------------------
# DISPLAY FILE AND CHROMIUM CONFIG
# disable screen blanking
echo "xset s off" |  tee --append ${display_file}
echo "xset -dpms" |  tee --append ${display_file}
echo "xset s noblank" |  tee --append ${display_file}

echo "point-rpi" | tee --append ${display_file} # move mouse to convenient position
echo "unclutter -idle 0.001 -root &" | tee --append ${display_file} # hide mouse pointer

echo "export MODE=${MODE}" | tee --append ${display_file} # set env var MODE to compost by default
touch /home/pi/env_storage.txt
echo "TOTAL_FAILURE=0" >> /home/pi/env_storage.txt # create fie to store env variable


# add running html file to display file
echo "chromium-browser --noerrdialogs --kiosk --incognito --allow-file-access-from-files ${non_root_home}/${project_name}/\${MODE}/index.html " | tee --append ${display_file}
print_message "please start the xserver on another console(Alt + F2) using xinit command and then quit out of that shell with Ctrl+Alt+F1, then press enter"
empty_input_buffer
read xserverDone
sed -i 's/\"exited_cleanly\": true//' ${non_root_home}/.config/chromium/Default/Preferences # disable chromium message about unclean shutdown
# replace chromium pref file, TODO: change this to sed in the future
cp -f ${non_root_home}/UCI-DWB/Preferences_Chromium ${non_root_home}/.config/chromium/Default/Preferences 

#---------------------------------------------------------
# CONFIGURE STARTUP SCRIPTS
# run maintain script at startup, everything else run after maintain, move to regular folder to avoid branch changing

sudo sed -i 's|1:2345:respawn:/sbin/getty 115200 tty1|#1:2345:respawn:/sbin/getty 115200 tty1|g' /etc/inittab
echo "1:2345:respawn:/bin/login -f pi tty1 </dev/tty1 >/dev/tty1 2>&1" | sudo tee --append /etc/inittab
# echo "git -C ${non_root_home}/${project_name}/ checkout ${devBranch}" | tee --append ${display_file} # change to release branch at startup
cp -f ${non_root_home}/${project_name}/shell_script/maintain.sh ${non_root_home}/
cp -f ${non_root_home}/${project_name}/shell_script/utils.sh ${non_root_home}/
sudo sed -i 's/exit 0//' ${startup_file}
echo "${non_root_home}/maintain.sh" | sudo tee --append ${startup_file}
echo "exit 0" | sudo tee --append ${startup_file}



#--------------------------------------------------------------
# configure boot config file
# set 720p to the pi, source for the settings: https://elinux.org/RPiconfig#Video_mode_options 
sudo sed -i 's/.*hdmi_mode=.*//' ${boot_config_file} # wipe old settings first
sudo sed -i 's/.*hdmi_group=.*//' ${boot_config_file}
echo "hdmi_mode=4" | sudo tee --append ${boot_config_file} # change to new mode
echo "hdmi_group=1" | sudo tee --append ${boot_config_file}

# enable full screen 
sudo sed -i 's/.*disable_overscan=.*//' ${boot_config_file}
echo "disable_overscan=1" | sudo tee --append ${boot_config_file}

#---------------------------------------------------------------
# CONFIGURE SCALE
# create symlink for the scale, the number seems to be same for every scale
echo "ACTION==\"add\",SUBSYSTEM==\"tty\", ATTRS{idVendor}==\"0403\", ATTRS{idProduct}==\"6001\", SYMLINK+=\"SCALE\"" | sudo tee --append /etc/udev/rules.d/99-com.rules
echo "xinit" >> /home/pi/.bashrc # turn on screen when user login
# autologin to pi by default
sudo sed -i 's|ExecStart=-/sbin/agetty --noclear %I $TERM| ExecStart=-/sbin/agetty --noclear -a pi %I $TERM |g' /lib/systemd/system/getty@.service