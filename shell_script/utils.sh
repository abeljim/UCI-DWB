#!/bin/bash
# carrying utilities for scripts like error reporting

red='\33[38;5;0196m'
cyan='\033[38;5;087m' #for marking the being of a new sections
yellow='\033[38;5;226m' #for error
green='\033[38;5;154m' #for general messages
reset='\033[0m' #for resetting the color

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
    touch ./maintainance.log
    printf '%-20s %-7s %-15s %-s\n' "$(date --iso-8601=date) $(date +'%H:%M:%S')" "${1}" "\"[${2}]\"" "${3}" >> ./maintainance.log
    return 0
}

# discard everything in stdin so far works with multi line garbage
empty_input_buffer()
{
    read -d '' -t 0.1 -n 100000 unused
    return 0
}

