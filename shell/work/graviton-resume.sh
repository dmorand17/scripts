#!/bin/bash

set -e

# Script parameters
# parameter 1 - environment - directory of solution to resume

solution=$1

######################## MAIN ########################
if [[ $# -ne 1 ]]
then
    echo "There are not enough parameters."
    
	echo "Must provide the remote solution directory (ie: rgrav/solution_ohop_username"
	echo "  Example: graviton-resume.sh 'rgrav/solution_ohop_username'"
	
    exit 1
fi

echo "Resuming $solution solution"

ssh graviton-jump-host -- "cd ~/$solution; graviton resume -p ec2"