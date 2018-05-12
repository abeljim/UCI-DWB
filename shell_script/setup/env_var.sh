#!/bin/bash
# contain environment variable used for setup

# list of necessary software
software=" xserver-xorg xinit ufw ntp gcc chromium-browser unclutter git "

project_name="UCI-DWB"
non_root_home="/home/pi"
startup_file="/etc/rc.local" # location of file that would be run when user logins
display_file="/home/pi/.xinitrc"
boot_config_file="/boot/config.txt"
MODE="compost" # later become env variable to determine which mode this pi is running on
devBranch="iss19"
source ../utils.sh

set -e 
set -o pipefail
set -o nounset