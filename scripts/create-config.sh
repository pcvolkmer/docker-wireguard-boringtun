#!/bin/bash

# Remove leftover config files
rm *.conf 2>/dev/null
rm *-client_*.png 2>/dev/null

while [[ -z $DEVICE ]]; do
  echo -n "Device (eg tun0):  "
  read DEVICE
done
echo " - Writing config to file $DEVICE.conf"

while [[ -z $SERVER_HOST ]]; do
  echo -n "Endpoint hostname: "
  read SERVER_HOST
done
echo " - Using endpoint hostname $SERVER_HOST"

if [[ -z $SERVER_PORT ]]; then
  echo -n "Endpoint port:     "
  read SERVER_PORT
fi
echo " - Using port $SERVER_PORT"

if [[ -z $NETWORK ]]; then
  echo -n "Network (/24):     "
  read NETWORK
fi
echo " - Using network $NETWORK/24"
NETWORK=$(echo -n $NETWORK | sed -r "s/\.[0-9]+$//")

while [[ -z $CLIENTS ]]; do
  echo -n "Number of clients: "
  read CLIENTS
done
echo " - Generating $CLIENTS client configs and client QR codes"

SERVER_SEC_KEY=$(wg genkey)
SERVER_PUB_KEY=$(echo $SERVER_SEC_KEY | wg pubkey)

declare -a CLIENT_SEC_KEYS
declare -a CLIENT_PUB_KEYS

# Generate client keys
for (( i=1; i<=$CLIENTS; i++ )); do
  CLIENT_SEC_KEY=$(wg genkey)
  CLIENT_PUB_KEY=$(echo $CLIENT_SEC_KEY | wg pubkey)

  CLIENT_SEC_KEYS[$i]=$CLIENT_SEC_KEY
  CLIENT_PUB_KEYS[$i]=$CLIENT_PUB_KEY
done

cat <<EOF >> $DEVICE.conf
##############
# SERVER
##############

[Interface]
Address = $NETWORK.1/24
ListenPort = $SERVER_PORT
PrivateKey = $SERVER_SEC_KEY

PostUp   = iptables -A FORWARD -i $DEVICE -j ACCEPT; iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
PostDown = iptables -D FORWARD -i $DEVICE -j ACCEPT; iptables -t nat -D POSTROUTING -o eth0 -j MASQUERADE

EOF

# Print out client peers
for (( i=1; i<=$CLIENTS; i++ )); do
cat << EOF >> $DEVICE.conf
# Client $i
[Peer]
PublicKey = ${CLIENT_PUB_KEYS[$i]}
AllowedIPs = $NETWORK.$(($i+10))/32

EOF
done

# Print out client configs

for (( i=1; i<=$CLIENTS; i++ )); do
cat <<EOF >> $DEVICE-client_$i.conf
##############
# CLIENT $i
##############

[Interface]
Address = $NETWORK.$(($i+10))/24
ListenPort = $SERVER_PORT
PrivateKey = ${CLIENT_SEC_KEYS[$i]}

[Peer]
PublicKey = $SERVER_PUB_KEY
AllowedIPs = 0.0.0.0/0, ::/0
Endpoint = $SERVER_HOST:$SERVER_PORT
EOF
done

# Create QR-codes for clients
if [ ! -z "$(which qrencode 2>/dev/null)" ]; then
  for (( i=1; i<=$CLIENTS; i++ )); do
    qrencode -t png -o "$DEVICE-client_$i.png" < $DEVICE-client_$i.conf
  done
fi
