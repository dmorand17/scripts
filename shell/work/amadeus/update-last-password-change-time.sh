#!/usr/bin/env bash

# Exit if error
set -e

newdate=$(date --utc +%FT%TZ)

echo "Updating last-password-change-time to $newdate"

# -b handle as binary to preserve line endings
sed -i -r -b "s/<last-password-change-time>(.*)<\/last-password-change-time>/<last-password-change-time>${newdate}<\/last-password-change-time>/" ./resources/portal-exports/test-users.c6x.xml