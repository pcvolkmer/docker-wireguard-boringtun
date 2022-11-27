#!/bin/bash

SERVER_PUB_KEY=$(cat $DEVICE.conf | grep PrivateKey | sed 's/PrivateKey = //g' | wg pubkey)
NETWORK=$(cat $DEVICE.conf | grep Address | sed 's/Address = //g; s/\.[0-9\/]*$//g')

CLIENT_ID=$(($(ls $DEVICE-client_*.conf | grep ".conf" | tail -1 | sed "s/$DEVICE-client_//g; s/\.conf$//g")+1))

CLIENT_SEC_KEY=$(wg genkey)
CLIENT_PUB_KEY=$(echo $CLIENT_SEC_KEY | wg pubkey)

# Add peer config
cat << EOF >> $DEVICE.conf
# Client $CLIENT_ID
[Peer]
PublicKey = ${CLIENT_PUB_KEY}
AllowedIPs = $NETWORK.$(($CLIENT_ID+10))/32

EOF

# Print out client configs
cat <<EOF > $DEVICE-client_$CLIENT_ID.conf
##############
# CLIENT $CLIENT_ID
##############

[Interface]
Address = $NETWORK.$(($CLIENT_ID+10))/24
ListenPort = $SERVER_PORT
PrivateKey = ${CLIENT_SEC_KEY}

[Peer]
PublicKey = $SERVER_PUB_KEY
AllowedIPs = 0.0.0.0/0, ::/0
Endpoint = $SERVER_HOST:$SERVER_PORT
EOF

# Create QR-codes for clients
if [ ! -z "$(which qrencode 2>/dev/null)" ]; then
  qrencode -t png -o "$DEVICE-client_$CLIENT_ID.png" < $DEVICE-client_$CLIENT_ID.conf
fi

echo "Added Client # $CLIENT_ID"