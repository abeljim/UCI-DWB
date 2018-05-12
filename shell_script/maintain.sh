#!/bin/bash
# used for daily maintainance
# NEED TO BE EXECUTED WITH THE SOURCE COMMAND

#time for the computer to reboot, based on food court inactive hour
reboot_time="23:45"
project_name="UCI-DWB"

env_var_storage_file="/home/pi/env_storage.txt"
display_file="/home/pi/.xinitrc"
source ${env_var_storage_file}
non_root_user_dir="/home/pi"
devBrand=iss9
mode=""

log()
{
    touch /home/pi/maintainance.log
    printf '%-20s %-7s %-15s %-s\n' "$(date --iso-8601=date) $(date +'%H:%M:%S')" "${1}" "\"[${2}]\"" "${3}" >> /home/pi/maintainance.log
    return 0
}
# pin state ref: https://raspberrypi.stackexchange.com/questions/51479/gpio-pin-states-on-powerup
# pin graph ref:
# https://www.jameco.com/Jameco/workshop/circuitnotes/raspberry-pi-circuit-note.html

#--------------------------------------------------------------
log "INFO" "MAINTAIN" "Starting Maintainance"

# pins if pulled high, indicate the correspoding bin types
compost_pin=22
recycle_pin=24
landfill_pin=10
gpio_dir="/sys/class/gpio"

# pin setup these may failed if the pin is already setup
echo ${compost_pin} > ${gpio_dir}/export
sleep 1
echo ${recycle_pin} > ${gpio_dir}/export
sleep 1
echo ${landfill_pin} > ${gpio_dir}/export
sleep 1
echo "in" > ${gpio_dir}/gpio${compost_pin}/direction
sleep 1
echo "in" > ${gpio_dir}/gpio${recycle_pin}/direction
sleep 1
echo "in" > ${gpio_dir}/gpio${landfill_pin}/direction
sleep 1

if [ $(cat ${gpio_dir}/gpio${compost_pin}/value) = 1 ] && [ $(cat ${gpio_dir}/gpio${recycle_pin}/value) = 0 ] && [ $(cat ${gpio_dir}/gpio${landfill_pin}/value) = 0 ]
then
    mode=compost
elif [ $(cat ${gpio_dir}/gpio${compost_pin}/value) = 0 ] && [ $(cat ${gpio_dir}/gpio${recycle_pin}/value) = 1 ] && [ $(cat ${gpio_dir}/gpio${landfill_pin}/value) = 0 ]
then
    mode=recycle
elif [ $(cat ${gpio_dir}/gpio${compost_pin}/value) = 0 ] && [ $(cat ${gpio_dir}/gpio${recycle_pin}/value) = 0 ] && [ $(cat ${gpio_dir}/gpio${landfill_pin}/value) = 1 ]
then
    mode=landfill
else
    log "ERROR" "GPIO" "Unknown Pin State"
    sleep 5
    reboot 
fi

sed -i "s/export MODE=.*/export MODE=${mode}/g" ${display_file}

# MAINTAINANCE CODE
git -C ${non_root_user_dir}/${project_name}/ checkout ${devBrand} # change branch to receive update from ${devBrand}
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
if [ $(git -C ${non_root_user_dir}/${project_name}/ rev-list  --count origin/${devBrand}...${devBrand}) -gt 0 ]; then
log "INFO" "UPDATE" "Found Upates"
if git -C ${non_root_user_dir}/${project_name}/ pull ; then
log "INFO" "UPDATE" "Finished Applying Update"
# reboot
else
log "ERROR" "UPDATE" "Error updating"
if [ "${TOTAL_FAILURE}" -gt 5 ]; then
    log "ERROR" "UPDATE" "Failed updating more than 5 times"
    exit 1 # exit and leave the screen blank so people can contact the team instead of infinite reboot
fi
TOTAL_FAILURE=$((TOTAL_FAILURE+1))
sed -i "s|TOTAL_FAILURE=.*$||g" ${env_var_storage_file}
echo "TOTAL_FAILURE=${TOTAL_FAILURE}" >> ${env_var_storage_file}
# reboot
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
${non_root_user_dir}/${project_name}/scale/scale_main.out ${mode} &
sleep 1
