#!/bin/bash

SERVER_PUB_KEY=$(cat $DEVICE.conf | grep PrivateKey | sed 's/PrivateKey = //g' | wg pubkey)
NETWORK=$(cat $DEVICE.conf | grep Address | sed 's/Address = //g; s/\.[0-9\/]*,.*$//g')
NETWORK6=$(cat $DEVICE.conf | grep Address | sed 's/Address = //g; s/^.*, //g; s/\:[0-9a-f\/]*$//g')

for i in {1..240}; do
  if [ ! -f "$DEVICE-client_$i.conf" ]; then
    CLIENT_ID=$i
    break
  fi
done

if [ -z $CLIENT_ID ]; then
  echo "Adding a new client not possible: No IP address available"
  exit 1
fi

if [ -z $1 ]; then
  CLIENT_SEC_KEY=$(wg genkey)
  CLIENT_PUB_KEY=$(echo $CLIENT_SEC_KEY | wg pubkey)
else
  # Check if public key is already used
  clients=($(cat $DEVICE.conf | grep "# Client" | sed "s/# Client \([0-9]*\)$/\1/"))
  keys=($(cat $DEVICE.conf | grep "PublicKey = " | sed "s/PublicKey = \(.*\)$/\1/"))
  for i in "${!keys[@]}"; do
    if [[ "$1" = "${keys[$i]}" ]]; then
      echo "Key '$1' already used in 'Client ${clients[$i]}'"
      exit 1
    fi
  done
  CLIENT_SEC_KEY="<place secret key here>"
  CLIENT_PUB_KEY=$1
fi

# Add peer config
cat << EOF >> $DEVICE.conf
# Client $CLIENT_ID
[Peer]
PublicKey = ${CLIENT_PUB_KEY}
AllowedIPs = $NETWORK.$(($CLIENT_ID+10))/32, $NETWORK6:$(printf "%x" $(($CLIENT_ID+10)))/128
# <- $(date)
EOF

# Print out client configs
cat <<EOF > $DEVICE-client_$CLIENT_ID.conf
##############
# CLIENT $CLIENT_ID
#
# <- $(date)
##############

[Interface]
Address = $NETWORK.$(($CLIENT_ID+10))/24, $NETWORK6:$(printf "%x" $(($CLIENT_ID+10)))/64
ListenPort = $SERVER_PORT
PrivateKey = ${CLIENT_SEC_KEY}
DNS = $NETWORK.1
EOF

if [ $MTU ]; then
echo "MTU = $MTU" >> $DEVICE-client_$CLIENT_ID.conf
fi

cat <<EOF >> $DEVICE-client_$CLIENT_ID.conf

[Peer]
PublicKey = $SERVER_PUB_KEY
AllowedIPs = 0.0.0.0/0, ::/0
Endpoint = $SERVER_HOST:$SERVER_PORT
EOF

# Update dnsmasq hosts file
/scripts/hosts.sh

if [ -z $1 ]; then
  echo "Added Client # $CLIENT_ID"
else
  echo "Added Client # $CLIENT_ID with existing public key"
fi
