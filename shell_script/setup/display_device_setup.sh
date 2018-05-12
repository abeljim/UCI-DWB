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

echo "export MODE=${MODE}" | tee --append ${display_file} # set env var MODE to compost by default
# echo "git -C ${non_root_home}/${project_name}/ checkout ${devBranch}" | tee --append ${display_file} # change to release branch at startup
touch /home/pi/env_storage.txt
echo "TOTAL_FAILURE=0" >> /home/pi/env_storage.txt # create fie to store env variable
# # autologin to root by default
# sudo sed -i 's|ExecStart=-/sbin/agetty --noclear %I $TERM| ExecStart=-/sbin/agetty --noclear -a root %I $TERM |g' /lib/systemd/system/getty@.service

# run this maintain script at startup, everything else run after maintain, move to regular folder to avoid branch changing
cp -f ${non_root_home}/${project_name}/shell_script/maintain.sh ${non_root_home}/
cp -f ${non_root_home}/${project_name}/shell_script/utils.sh ${non_root_home}/
sudo sed -i 's/exit 0//' ${startup_file}
echo "${non_root_home}/maintain.sh" | sudo tee --append ${startup_file}
echo "exit 0" | sudo tee --append ${startup_file}
# add running html file to display file
echo "chromium-browser --noerrdialogs --kiosk --incognito --allow-file-access-from-files ${non_root_home}/${project_name}/'${MODE}'/index.html &" | tee --append ${display_file}
print_message "please start the xserver on another console(Alt + F2) then quit using xinit command, then press enter"
empty_input_buffer
read xserverDone

# replace chromium pref file, TODO: change this to sed in the future
cp -f ${non_root_home}/UCI-DWB/Preferences_Chromium ${non_root_home}/.config/chromium/Default/Preferences 

# disable screen blanking
echo "xset s off" |  tee --append ${display_file}
echo "xset -dpms" |  tee --append ${display_file}
echo "xset s noblank" |  tee --append ${display_file}

sed -i 's/\"exited_cleanly\": true//' ${non_root_home}/.config/chromium/Default/Preferences # disable chromium message about unclean shutdown

echo "point-rpi" | tee --append ${display_file} # move mouse to convenient position
echo "unclutter -idle 0.001 -root" | tee --append ${display_file} # hide mouse pointer

# create symlink for the scale, the number seems to be same for every scale
echo "ACTION==\"add\",SUBSYSTEM==\"tty\", ATTRS{idVendor}==\"0403\", ATTRS{idProduct}==\"6001\", SYMLINK+=\"SCALE\"" | sudo tee --append /etc/udev/rules.d/99-com.rules



# set 720p to the pi, source for the settings: https://elinux.org/RPiconfig#Video_mode_options 
sudo sed -i 's/.*hdmi_mode=.*//' ${boot_config_file} # wipe old settings first
sudo sed -i 's/.*hdmi_group=.*//' ${boot_config_file}
echo "hdmi_mode=4" | sudo tee --append ${boot_config_file} # change to new mode
echo "hdmi_group=1" | sudo tee --append ${boot_config_file}

# enable full screen 
sudo sed -i 's/.*disable_overscan=.*//' ${boot_config_file}
echo "disable_overscan=1" | sudo tee --append ${boot_config_file}

