#!/bin/bash
# carrying utilities for scripts like error reporting

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
    >&2 printf "${yellow}\n${1}${reset}"
    return 0
}

# announce which section of scripts are we on
print_section()
{
    printf "${cyan}\n${1}${reset}"
    return 0
}

# will log the time and error type
log () 
{
    touch ./log_file.log
    
    return 0
}