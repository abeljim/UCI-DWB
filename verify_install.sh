#!/bin/bash
# used for verifying the image, will calculate the sha256sum of the 
# tar of the entire dir and compare it with a file

#-------------------------------------------------------
tar -c ${HOME}/UCI-DWB/!(sha256sum.txt|.*) | sha256sum -c ${HOME}/UCI-DWB/sha256sum.txt
if [[ $? == 0 ]]; then
# do stuffs if sha matches
echo "Integrity check succeeded"
else
#do stuffs if sha failed
echo "Integrity check failed"
fi 