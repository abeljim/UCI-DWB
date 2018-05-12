#!/bin/bash
# used for cleaning up after install
source ./env_var.sh
source ../utils.sh

#-------------------------------------------------------------------------------

sudo apt autoremove -y
# change branch upstream source
git -C ${non_root_home}/${project_name}/ branch -u origin/release release

print_message "Setup done, the system will reboot in 5 seconds"
sleep 5
reboot
