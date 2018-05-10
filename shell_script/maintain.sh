#!/bin/bash
# used for daily maintainance
# NEED TO BE EXECUTED WITH THE SOURCE COMMAND

#time for the computer to reboot, based on food court inactive hour
reboot_time="23:45"
project_name="UCI-DWB"

env_var_storage_file="/home/pi/env_storage.txt"
source ${env_var_storage_file}
non_root_user_dir="/home/pi"
source ${non_root_user_dir}/utils.sh
#--------------------------------------------------------------
log "INFO" "MAINTAIN" "Starting Maintainance"

check_bin_role
mode=$?
display_file="/home/pi/.xinitrc"
sed -i "s/export MODE=.*/export MODE=${mode}/g" ${display_file}

# MAINTAINANCE CODE
git -C ${non_root_user_dir}/${project_name}/ checkout release # change branch to receive update from release
sudo ufw enable # enable firewall if not enabled
sudo ifconfig wlan0 up # turn on network
sleep 11 # give wlan0 time to wake up

sudo service ntp restart >> /dev/null
sudo apt-get update >> /dev/null
sudo apt-get dist-upgrade -y >> /dev/null 
sudo timedatectl set-timezone US/Pacific >> /dev/null

# software update
if ! git -C ${non_root_user_dir}/${project_name}/ fetch ; then 
    log "ERROR" "UPDATE" "Failed To Fetch"
    if [ "${TOTAL_FAILURE}" -gt 5 ]; then
    log "ERROR" "UPDATE" "Failed updating more than 5 times"
    exit 1 # exit and leave the screen blank so people can contact the team instead of infinite reboot
    fi
    TOTAL_FAILURE=$((TOTAL_FAILURE+1))
    sed -i "s|TOTAL_FAILURE=.*$||g" ${env_var_storage_file}
    echo "TOTAL_FAILURE=${TOTAL_FAILURE}" >> ${env_var_storage_file}
    reboot
fi
# only pull and rerun stuffs if there is update
if [ $(git -C ${non_root_user_dir}/${project_name}/ rev-list  --count origin/release...release) -gt 0 ]; then
log "INFO" "UPDATE" "Found Upates"
if git -C ${non_root_user_dir}/${project_name}/ pull ; then
log "INFO" "UPDATE" "Finished Applying Update"
reboot
else
log "ERROR" "UPDATE" "Error updating"
if [ "${TOTAL_FAILURE}" -gt 5 ]; then
    log "ERROR" "UPDATE" "Failed updating more than 5 times"
    exit 1 # exit and leave the screen blank so people can contact the team instead of infinite reboot
fi
TOTAL_FAILURE=$((TOTAL_FAILURE+1))
sed -i "s|TOTAL_FAILURE=.*$||g" ${env_var_storage_file}
echo "TOTAL_FAILURE=${TOTAL_FAILURE}" >> ${env_var_storage_file}
reboot
fi
fi

sudo ifconfig wlan0 down
touch ${env_var_storage_file} #store env storage for rc.local
sed -i "s|TOTAL_FAILURE=.*$||g" ${env_var_storage_file}
echo "TOTAL_FAILURE=0" >> ${env_var_storage_file}
log "INFO" "MAINTAIN" "Finish Maintainance"
shutdown -r ${reboot_time} # schedule reboot everyday when the food court is not active

# run scale code and start display
make -C ${non_root_user_dir}/${project_name}/scale
./${non_root_user_dir}/${project_name}/scale/scale_main.out ${mode} &
sleep 1
xinit &
exit 0
