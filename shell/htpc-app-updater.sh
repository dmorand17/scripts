#!/bin/bash

cur_dir=$(pwd)

echo "Current directory: $cur_dir"

git_repositories=("/opt/CouchPotatoServer" "/opt/plexpy" "/home/dougie/github_scripts" "/home/dougie/.dotfiles")

for i in ${git_repositories[@]}; do
    echo "Updating $i"
    cd $i
    git pull origin master
    echo
done

echo "Finished"
cd $cur_dir