#!/bin/bash
# used for daily maintainance

#time for the computer to reboot, based on food court inactive hour
REBOOT_TIME="24:00" 
PROJECT_NAME="UCI-DWB"

shutdown -r ${REBOOT_TIME}

# MAINTAINANCE CODE
sudo ufw enable # enable firewall if not enabled
sudo ifconfig wlan0 up # turn on network
sleep 20 # give wlan0 time to wake up

sudo service ntp restart 
sudo apt-get update
sudo apt-get dist-upgrade -y 
sudo timedatectl set-timezone US/Pacific 

# software update
git -C ~/${PROJECT_NAME}/ pull 

sudo ifconfig wlan0 down

exit 0