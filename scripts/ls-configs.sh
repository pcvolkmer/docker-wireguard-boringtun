#!/bin/bash

if [ ! -f "$DEVICE.conf" ]; then
  echo "No configuration: Use command 'init' to create configuration files"
  exit 1
fi

echo "Configurations - sorted by creation date"
echo
echo "Server"
echo -n "PublicKey: "
cat "$DEVICE.conf" | grep "PrivateKey =" | sed "s/PrivateKey = // " | wg pubkey
cat "$DEVICE.conf" | grep -e "# Client" -e "PublicKey =" -e "# <-" | grep -a "" | sed "s/# //" | sed "s/ = /: / " | sed "s/<- //" | sed "s/\(.*\)\([0-9]\{4\}\)/Created:   \1\2\n/"
