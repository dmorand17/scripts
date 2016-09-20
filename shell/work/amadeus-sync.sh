#!/bin/bash

# This script will pull/push updates to the remote graviton-jump-host
# Expects 

solution_name=$1
sub_dir=solutions

# Bash script to sync files
rsync -avzh --delete --filter=':- .gitignore' graviton-jump-host:~/solutions/solution_hbc/ ./solution_hbc

# 
rsync -rz --exclude='.git*' --filter=':- .gitignore' --rsync-path="mkdir -p ~/$sub_dir && rsync" . graviton-jump-host:$sub_dir/$solution_name

######################## FUNCTIONS ########################

sync_to_jump_host() {
  echo Syncing to jump host...
  rsync -rz --exclude='.git*' --filter=':- .gitignore' --rsync-path="mkdir -p ~/$sub_dir && rsync" . graviton-jump-host:$sub_dir/$solution_name
  rsync -rz --delete --exclude='.git*' files/ graviton-jump-host:$sub_dir/$solution_name/files/
}

sync_to_home() {
  rsync -rz --delete --exclude='.git*' graviton-jump-host:$sub_dir/$solution_name/files/ files/ 2>/dev/null &

  run_ticker $! "Syncing files to home..."
  printf "\rSyncing files to home... Done\n"

  download_from_host Puppetfile.lock
  download_from_host Gemfile.lock

  download_logs
}

download_logs() {
  download_from_host graviton.log
  download_from_host agent-logs
}

download_from_host() {
  file=$1
  text="Downloading $file..."

  # Delete the local file(s) so that we have something to measure success against
  rm -rf $file

  # Tarball must have something in it to be valid; choose the Puppetfile
  ssh graviton-jump-host "cd $sub_dir/$solution_name; if [ ! -e $file ]; then FILE=Puppetfile; else FILE=$file; fi; tar --transform 's/$sub_dir\/$solution_name\///g' -cj \$FILE" | tar -xjf - 2>/dev/null &

  run_ticker $! "$text"

  # Can't easily get the child process exit code from the ssh command, so base success on
  # whether the file is present.
  if [ ! -e $file ]; then
    printf "\r$text Failed (this is ok, it probably doesn't exist on the jump host)\n"
  else
    printf "\r$text Done\n"
  fi
}

run_ticker() {
  pid=$1 # Process Id of the previous running command
  text=$2
  spin='-\|/'
  i=0
  while kill -0 $pid 2>/dev/null
  do
    i=$(( (i+1) %4 ))
    printf "\r$text ${spin:$i:1}"
    sleep .1
  done
}


######################## MAIN ########################
if [[ $# -ne 1 ]]
then
    echo "There are not enough parameters."
    
	echo "Must provide a solution (ie: directory)"
	echo "  Example: amadeus-sync.sh solution_ohop"
	
    exit 1
fi

if [ ! -f 'solution_definition.yaml' ] ; then
  echo Please run script from your graviton solution directory
  exit 1
fi
