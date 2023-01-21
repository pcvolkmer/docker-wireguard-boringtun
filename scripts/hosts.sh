#!/bin/bash

# Prepare and cleanup hosts file
mkdir hosts.d 2>/dev/null
echo -n "" > hosts.d/wg

NETWORK=$(cat $DEVICE.conf | grep Address | sed 's/Address = //g; s/\.[0-9\/]*,.*$//g')
NETWORK6=$(cat $DEVICE.conf | grep Address | sed 's/Address = //g; s/^.*, //g; s/\:[0-9a-f\/]*$//g')

# Print hosts file
echo "# IPv4 clients" >> hosts.d/wg
echo "$NETWORK.1    $DEVICE-server" >> hosts.d/wg
for i in {1..240}; do
  if [ -f "$DEVICE-client_$i.conf" ]; then
    echo "$NETWORK.$(($i+10))    $DEVICE-client$i" >> hosts.d/wg
  fi
done
echo "# IPv6 clients" >> hosts.d/wg
echo "$NETWORK6:1    $DEVICE-server" >> hosts.d/wg
for i in {1..240}; do
  if [ -f "$DEVICE-client_$i.conf" ]; then
    echo "$NETWORK6:$(printf "%x" $(($i+10)))    $DEVICE-client$i" >> hosts.d/wg
  fi
done