#!/bin/bash
# used for daily maintainance
# pin state ref: https://raspberrypi.stackexchange.com/questions/51479/gpio-pin-states-on-powerup

YELLOW='\033[38;5;226m' #for error
GREEN='\033[38;5;154m' #for general messages
RESET='\033[0m' #for resetting the color

# pins if pulled high, indicate the correspoding bin types
COMPOST_PIN=22
RECYCLE_PIN=24
LANDFILL_PIN=10
GPIO_DIR="/sys/class/gpio/"

#time for the computer to reboot, based on food court inactive hour
REBOOT_TIME="24:00" 
PROJECT_NAME="UCI-DWB"

#--------------------------------------------------------------

# this section will check which mode this bin is operating in based on jumper position
# prep pins for reading
echo ${COMPOST_PIN} > ${GPIO_DIR}/export
echo ${RECYCLE_PIN} > ${GPIO_DIR}/export
echo ${LANDFILL_PIN} > ${GPIO_DIR}/export

echo "in" > ${GPIO_DIR}/gpio${COMPOST_PIN}/direction
echo "in" > ${GPIO_DIR}/gpio${RECYCLE_PIN}/direction
echo "in" > ${GPIO_DIR}/gpio${LANDFILL_PIN}/direction

if [ $(cat ${GPIO_DIR}/gpio${COMPOST_PIN}/value) = 1 ] && [ $(cat ${GPIO_DIR}/gpio${RECYCLE_PIN}/value) = 0 ] && [ $(cat ${GPIO_DIR}/gpio${LANDFILL_PIN}/value) = 0 ]
then 
    NEW_MODE=COMPOST
elif [ $(cat ${GPIO_DIR}/gpio${COMPOST_PIN}/value) = 0 ] && [ $(cat ${GPIO_DIR}/gpio${RECYCLE_PIN}/value) = 1 ] && [ $(cat ${GPIO_DIR}/gpio${LANDFILL_PIN}/value) = 0 ]
then 
    NEW_MODE=RECYCLE
elif [ $(cat ${GPIO_DIR}/gpio${COMPOST_PIN}/value) = 0 ] && [ $(cat ${GPIO_DIR}/gpio${RECYCLE_PIN}/value) = 0 ] && [ $(cat ${GPIO_DIR}/gpio${LANDFILL_PIN}/value) = 1 ]
then 
    NEW_MODE=LANDFILL
fi

# only launch the script again if the mode is different from last time
if [ ${NEW_MODE} != ${MODE} ]; then
sed -i "s|^export MODE=.*$|export MODE=${NEW_MODE}|g" ~/.bashrc
source ~/.bashrc
fi

# MAINTAINANCE CODE
git checkout release # change branch to receive update from release
sudo ufw enable # enable firewall if not enabled
sudo ifconfig wlan0 up # turn on network
sleep 20 # give wlan0 time to wake up

sudo service ntp restart 
sudo apt-get update
sudo apt-get dist-upgrade -y 
sudo timedatectl set-timezone US/Pacific 

# software update
git -C ~/${PROJECT_NAME}/ fetch
# only pull and rerun stuffs if there is update
if [ $(git rev-list  --count origin/release...release) > 0 ]; then
git -C ~/${PROJECT_NAME}/ pull 
source ~/.bashrc
fi

sudo ifconfig wlan0 down
shutdown -r ${REBOOT_TIME}

exit 0