#!/bin/bash
# used for prepping the internet, user and things like that for installation
source ./env_var.sh
source ../utils.sh
#-------------------------------------------------------------------------------
check_subshell_run
if [ ${USER} != pi ]; then
print_error "You need to be user named pi to install"
fi
print_message "Configuring wifi"
echo "network={" | sudo tee --append /etc/wpa_supplicant/wpa_supplicant.conf
echo "  ssid=\"UCInet Mobile Access\"" | sudo tee --append /etc/wpa_supplicant/wpa_supplicant.conf
echo "  key_mgmt=NONE" | sudo tee --append /etc/wpa_supplicant/wpa_supplicant.conf 
echo "}" | sudo tee --append /etc/wpa_supplicant/wpa_supplicant.conf
wpa_cli -i wlan0 reconfigure
sleep 5

sudo sed -i 's|pi ALL=(ALL) NOPASSWD: ALL|pi ALL=(ALL) ALL|g' /etc/sudoers.d/010_pi-nopasswd
print_message "Please enter new password for pi"
empty_input_buffer   
passwd
print_message "Starting setup"
git clone https://github.com/khoitd1997/OS_Setup.git ${HOME}/

# change keyboard layout to make sure the rest of installation is correct
sudo sed -i '/XKBLAYOUT/d' /etc/default/keyboard
echo XKBLAYOUT=\"us\" | sudo tee -a /etc/default/keyboard