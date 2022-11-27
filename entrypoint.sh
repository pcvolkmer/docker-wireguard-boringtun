#!/bin/sh

set -e

if [ -z $DEVICE ]; then
  DEVICE="tun0"
fi

if [ ! -f "/etc/wireguard/$DEVICE.conf" ]; then
  cd /etc/wireguard
  /create-config.sh
  exit 0
fi

echo "Starting wg-quick on $DEVICE"
touch "${WG_LOG_FILE}"
wg-quick up $DEVICE
echo "done!"

tail -f "${WG_LOG_FILE}"
