#!/bin/sh

set -e

if [ -z $DEVICE ]; then
  DEVICE="tun0"
fi

if [ ! -f "/etc/wireguard/$DEVICE.conf" ]; then
  cd /etc/wireguard
  /scripts/create-config.sh
  exit 0
fi

case "$1" in
  'add-client')
    cd /etc/wireguard
    /scripts/add-client.sh
    exit 0
    ;;
  'rm-client')
    if [ -z $2 ]; then
      echo "Usage: rm-client <client id>"
      exit 1
    fi
    cd /etc/wireguard
    /scripts/rm-client.sh $2
    exit 0
    ;;
  *)
    echo "Starting wg-quick on $DEVICE"
    touch "${WG_LOG_FILE}"
    wg-quick up $DEVICE
    echo "done!"
    tail -f "${WG_LOG_FILE}"
    ;;
esac
