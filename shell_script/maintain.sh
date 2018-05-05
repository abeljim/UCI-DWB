#!/bin/bash
# used for daily maintainance
# pin state ref: https://raspberrypi.stackexchange.com/questions/51479/gpio-pin-states-on-powerup

# pins if pulled high, indicate the correspoding bin types
compost_pin=22
recycle_pin=24
landfill_pin=10
gpio_dir="/sys/class/gpio/"

#time for the computer to reboot, based on food court inactive hour
reboot_time="24:00"
project_name="UCI-DWB"

source ./utils.sh
startup_file="/home/${NON_ROOT_USER}/.bashrc" # NON_ROOT_USER set during initial installation
chmod u+x startup_file
non_root_user_dir="/home/${NON_ROOT_USER}"
#--------------------------------------------------------------
log "INFO" "MAINTAIN" "Starting Maintainance"

# this section will check which mode this bin is operating in based on jumper position
# prep pins for reading
echo ${compost_pin} > ${gpio_dir}/export
echo ${recycle_pin} > ${gpio_dir}/export
echo ${landfill_pin} > ${gpio_dir}/export

echo "in" > ${gpio_dir}/gpio${compost_pin}/direction
echo "in" > ${gpio_dir}/gpio${recycle_pin}/direction
echo "in" > ${gpio_dir}/gpio${landfill_pin}/direction

if [ $(cat ${gpio_dir}/gpio${compost_pin}/value) = 1 ] && [ $(cat ${gpio_dir}/gpio${recycle_pin}/value) = 0 ] && [ $(cat ${gpio_dir}/gpio${landfill_pin}/value) = 0 ]
then
    new_mode=COMPOST
elif [ $(cat ${gpio_dir}/gpio${compost_pin}/value) = 0 ] && [ $(cat ${gpio_dir}/gpio${recycle_pin}/value) = 1 ] && [ $(cat ${gpio_dir}/gpio${landfill_pin}/value) = 0 ]
then
    new_mode=RECYCLE
elif [ $(cat ${gpio_dir}/gpio${compost_pin}/value) = 0 ] && [ $(cat ${gpio_dir}/gpio${recycle_pin}/value) = 0 ] && [ $(cat ${gpio_dir}/gpio${landfill_pin}/value) = 1 ]
then
    new_mode=LANDFILL
else
    log "ERROR" "GPIO" "Unknown Pin State"
    sleep 5
    reboot 
fi

# only launch the script again if the mode is different from last time
if [ "${new_mode}" != "${MODE}" ]; then
sed -i "s|^export MODE=.*$|export MODE=${new_mode}|g" ${startup_file}
exec ${startup_file} # stop executing this script and relaunch bashrc to update env var MODE
fi

# MAINTAINANCE CODE
git -C ${non_root_user_dir}/${project_name}/ checkout release # change branch to receive update from release
sudo ufw enable # enable firewall if not enabled
sudo ifconfig wlan0 up # turn on network
sleep 20 # give wlan0 time to wake up

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
    sed -i "s|^export TOTAL_FAILURE=.*$|export TOTAL_FAILURE=${TOTAL_FAILURE}|g" ${startup_file}
    reboot
fi
# only pull and rerun stuffs if there is update
if [ $(git -C ${non_root_user_dir}/${project_name}/ rev-list  --count origin/release...release) -gt 0 ]; then
log "INFO" "UPDATE" "Found Upates"
if git -C ${non_root_user_dir}/${project_name}/ pull ; then
log "INFO" "UPDATE" "Finished Applying Update"
exec ${startup_file}
else
log "ERROR" "UPDATE" "Error updating"
if [ "${TOTAL_FAILURE}" -gt 5 ]; then
    log "ERROR" "UPDATE" "Failed updating more than 5 times"
    exit 1 # exit and leave the screen blank so people can contact the team instead of infinite reboot
fi
TOTAL_FAILURE=$((TOTAL_FAILURE+1))
sed -i "s|^export TOTAL_FAILURE=.*$|export TOTAL_FAILURE=${TOTAL_FAILURE}|g" ${startup_file}
reboot

fi
fi

sudo ifconfig wlan0 down
sed -i "s|^export TOTAL_FAILURE=.*$|export TOTAL_FAILURE=0|g" ${startup_file} # reset total failures to 0
log "INFO" "MAINTAIN" "Finish Maintainance"
su - ${NON_ROOT_USER} # change to non-root user for the rest of the day
shutdown -r ${reboot_time}

exit 0
