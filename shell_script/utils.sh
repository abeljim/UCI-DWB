#!/bin/bash
# carrying utilities for scripts like error reporting

red='\33[38;5;0196m'
cyan='\033[38;5;087m' #for marking the being of a new sections
yellow='\033[38;5;226m' #for error
green='\033[38;5;154m' #for general messages
reset='\033[0m' #for resetting the color

#-------------------------------------------------------------
# print general messages
print_message()
{
    printf "${green}\n${1}${reset}"
    return 0
}

# error messaging
print_error()
{
    >&2 printf "${red}\n${1}${reset}"
    return 0
}

# announce which section of scripts are we on
print_section()
{
    printf "${cyan}\n${1}${reset}"
    return 0
}

# will log the time and error type
# log file format is date followed by, code section, followed by defailted description
# for log highlighting: https://marketplace.visualstudio.com/items?itemName=emilast.LogFileHighlighter
# $1 is type of log, $2 is which section of code, $3 is what happens
# type of log for this project should usually just be error
# for now only log error
log ()
{
    touch /home/pi/maintainance.log
    printf '%-20s %-7s %-15s %-s\n' "$(date --iso-8601=date) $(date +'%H:%M:%S')" "${1}" "\"[${2}]\"" "${3}" >> /home/pi/maintainance.log
    return 0
}

# discard everything in stdin so far works with multi line garbage
empty_input_buffer()
{
    read -d '' -t 0.1 -n 100000 unused || true # make sure this doesn't raise errors
    return 0
}

# pin state ref: https://raspberrypi.stackexchange.com/questions/51479/gpio-pin-states-on-powerup
# pin graph ref:
# https://www.jameco.com/Jameco/workshop/circuitnotes/raspberry-pi-circuit-note.html
check_bin_role()
{

# pins if pulled high, indicate the correspoding bin types
compost_pin=22
recycle_pin=24
landfill_pin=10
gpio_dir="/sys/class/gpio"

# pin setup these may failed if the pin is already setup
echo ${compost_pin} > ${gpio_dir}/export
echo ${recycle_pin} > ${gpio_dir}/export
echo ${landfill_pin} > ${gpio_dir}/export
echo "in" > ${gpio_dir}/gpio${compost_pin}/direction
echo "in" > ${gpio_dir}/gpio${recycle_pin}/direction
echo "in" > ${gpio_dir}/gpio${landfill_pin}/direction

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
return ${mode}
}

# check if script is being run in subshell or not
# aka if command being run source script.sh or ./script.sh
check_subshell_run()
{
script_name=$( basename ${0#-} ) #- needed if sourced no path
this_script=$( basename ${BASH_SOURCE} )
if [[ ${script_name} = ${this_script} ]] ; then
    echo "Please run with source command instead of ./"
    exit 1
else
    echo "Script is being sourced, continuing" 

fi 
}
