#!/bin/sh

set -e

if [ -z $DEVICE ]; then
  DEVICE="tun0"
fi

case "$1" in
  'ls-configs' | 'ls')
    cd /etc/wireguard
    /scripts/ls-configs.sh
    exit 0
    ;;
  'add-client' | 'add')
    if [ ! -z $2 ]; then
      cd /etc/wireguard
      /scripts/add-client.sh $2
      exit 0
    fi
    cd /etc/wireguard
    /scripts/add-client.sh
    exit 0
    ;;
  'rm-client' | 'rm')
    if [ -z $2 ]; then
      echo "Usage: rm-client <client id>"
      exit 1
    fi
    cd /etc/wireguard
    /scripts/rm-client.sh $2
    exit 0
    ;;
  'show-client' | 'show')
    if [ -z $2 ]; then
      echo "Usage: show-client <client id>"
      exit 1
    fi
    cd /etc/wireguard
    /scripts/show-client.sh $2
    exit 0
    ;;
  'init')
    if [ "$2" == "--no-forward" ]; then
      export DISABLE_FORWARD_ALL_TRAFFIC="yes"
    fi
    if [ ! -f "/etc/wireguard/$DEVICE.conf" ]; then
      cd /etc/wireguard
      /scripts/create-config.sh
      exit 0
    else
      echo "Existing config found: Run command 'purge' first."
      exit 1
    fi
    ;;
  'purge')
    cd /etc/wireguard
    rm -rf hosts.d 2>/dev/null
    rm *.conf 2>/dev/null
    echo "Removed all configuration files"
    exit 0
    ;;
  'help')
    echo "Usage: <Command> [<Arguments>]"
    echo
    echo "Where Command is one of:"
    echo
    echo "ls      List server and clients sorted by creation date"
    echo "add     Add new client"
    echo "        If optional PUBLIC key is provided, a new client with given public key will be registered."
    echo "rm      Remove client by ID"
    echo "show    Show client config with qrcode"
    echo "init    Initialize service by creating config files"
    echo "        Option '--no-forward' will disable forwarding"
    echo "purge   Remove server config and all client configs"
    echo "help    Show this help message"
    echo
    ;;
  *)
    if [ ! -f "/etc/wireguard/$DEVICE.conf" ]; then
      cd /etc/wireguard
      /scripts/create-config.sh
    fi
    echo "Starting wg-quick on $DEVICE"
    cd /etc/wireguard
    /scripts/hosts.sh
    cd -
    touch "${WG_LOG_FILE}"
    wg-quick up $DEVICE
    dnsmasq -D --hostsdir=/etc/wireguard/hosts.d
    echo "done!"
    tail -f "${WG_LOG_FILE}"
    ;;
esac
