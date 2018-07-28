#!/bin/bash
# used for generating the hash for the release and store it in a file

#---------------------------------------------------
tar -c ${HOME}/UCI-DWB/!(sha256sum.txt|.*) | sha256sum | tee sha256sum.txt