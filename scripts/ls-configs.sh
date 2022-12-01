#!/bin/bash

echo "Configurations - sorted by creation date"
echo
echo "Server"
cat "$DEVICE.conf" | grep -e "# Client" -e "# <-" | grep -a "#" | sed "s/# //" | sed "s/<- //" | sed "s/\(.*\)\([0-9]\{4\}\)/Created: \1\2\n/"
