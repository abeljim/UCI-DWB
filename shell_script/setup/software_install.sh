#!/bin/bash
# used for installing necessary software
source ./env_var.sh
source ../utils.sh

#-------------------------------------------------------------------------------

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