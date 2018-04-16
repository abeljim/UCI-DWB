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
STARTUP_FILE="/home/${NON_ROOT_USER}/.bashrc"

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
sed -i "s|^export MODE=.*$|export MODE=${new_mode}|g" ${STARTUP_FILE}
exec ${STARTUP_FILE} # stop executing this script and relaunch bashrc to update env var MODE
fi

# MAINTAINANCE CODE
git checkout release # change branch to receive update from release
sudo ufw enable # enable firewall if not enabled
sudo ifconfig wlan0 up # turn on network
sleep 20 # give wlan0 time to wake up

sudo service ntp restart >> /dev/null
sudo apt-get update >> /dev/null
sudo apt-get dist-upgrade -y >> /dev/null 
sudo timedatectl set-timezone US/Pacific >> /dev/null

# software update
if ! git -C ${NON_ROOT_USER_DIR}/${project_name}/ fetch > /dev/null 2>&1; then 
    log "ERROR" "UPDATE" "Failed To Fetch"
    reboot
fi
# only pull and rerun stuffs if there is update
if [ $(git rev-list  --count origin/release...release) > 0 ]; then
log "INFO" "UPDATE" "Found Upates"
if git -C ${NON_ROOT_USER_DIR}/${project_name}/ pull > /dev/null 2>&1 ; then
log "INFO" "UPDATE" "Finished Applying Update"
exec ${STARTUP_FILE}
else
log "ERROR" "UPDATE" "Error updating"
fi
fi

sudo ifconfig wlan0 down
log "INFO" "MAINTAIN" "Finish Maintainance"
su - ${NON_ROOT_USER} # change to non-root user for the rest of the day
shutdown -r ${reboot_time}

exit 0
