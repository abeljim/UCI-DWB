#!/bin/bash
# used for daily maintainance


#time for the computer to reboot, based on food court inactive hour
REBOOT_TIME="24:00" 

shutdown -r ${REBOOT_TIME}

# for future maintainance stuffs
# git -C ~/UCI-Digital-Waste-Bin/ pull

#MAINTAINANCE CODE
sudo ufw enable
sudo ifconfig wlan0 up
sudo service ntp restart
sudo apt-get update
sudo apt-get dist-upgrade -y 
sudo timedatectl set-timezone US/Pacific
sudo ifconfig wlan0 down