#!/bin/bash

# Remove leftover config files
rm *.conf 2>/dev/null
rm *-client_*.png 2>/dev/null

echo "Create configuration files"

if [[ -z $DEVICE ]]; then
  DEVICE="tun0"
fi
echo " - Writing server config to file $DEVICE.conf"

if [[ -z $SERVER_HOST ]]; then
  echo " ERROR: No server hostname!"
  exit 1
fi
echo " - Using endpoint hostname $SERVER_HOST"

if [[ -z $SERVER_PORT ]]; then
  echo " ERROR: No server port!"
  exit 1
fi
echo " - Using port $SERVER_PORT"

if [[ -z $NETWORK ]]; then
  NETWORK="192.168.42.0"
else
  NETWORK=$(echo -n $NETWORK | sed -r "s/\.[0-9]+$//")
fi
echo " - Using v4 network $NETWORK.0/24"

if [[ -z $NETWORK6 ]]; then
  NETWORK6="fd42:$(hexdump -n 6 -e '2/1 "%02x" 1 ":"' /dev/random)"
else
  NETWORK6=$(echo -n $NETWORK6 | sed -r "s/\:[0-9a-f]*$//")
  if [[ "$(echo $NETWORK6 | sed -e 's/.*\(\:\:\).*/\1/')" == "::" ]]; then
    echo " ERROR: invalid v6 network $NETWORK6. Network must not contain '::'."
    exit 1
  fi
fi
echo " - Using v6 network $NETWORK6:/64"

if [[ -z $MTU ]]; then
  echo " - Using default MTU"
else
  echo " - Using MTU: $MTU"
fi

if [ "$DISABLE_FORWARD_ALL_TRAFFIC" != "true" ] && [ "$DISABLE_FORWARD_ALL_TRAFFIC" != "yes" ]; then
  echo " - Forward all traffic"
else
  echo " - Do not forward all traffic"
fi

if [[ -z $CLIENTS ]]; then
  CLIENTS=0
fi

if (( $CLIENTS > 240 )); then
  CLIENTS=240
fi
echo " - Generating $CLIENTS client configs"

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
Address = $NETWORK.1/24, $NETWORK6:1/64
ListenPort = $SERVER_PORT
PrivateKey = $SERVER_SEC_KEY
EOF

if [ $MTU ]; then
echo "MTU = $MTU" >> $DEVICE.conf
fi

if [ "$DISABLE_FORWARD_ALL_TRAFFIC" != "true" ] && [ "$DISABLE_FORWARD_ALL_TRAFFIC" != "yes" ]; then
cat <<EOF >> $DEVICE.conf

PostUp   = iptables -A FORWARD -i $DEVICE -j ACCEPT; iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
PostDown = iptables -D FORWARD -i $DEVICE -j ACCEPT; iptables -t nat -D POSTROUTING -o eth0 -j MASQUERADE
EOF
fi

cat <<EOF >> $DEVICE.conf
# <- $(date)
EOF

# Print out client peers
for (( i=1; i<=$CLIENTS; i++ )); do
cat << EOF >> $DEVICE.conf
# Client $i
[Peer]
PublicKey = ${CLIENT_PUB_KEYS[$i]}
AllowedIPs = $NETWORK.$(($i+10))/32, $NETWORK6:$(printf "%x" $(($i+10)))/128
# <- $(date)
EOF
done

# Print out client configs
for (( i=1; i<=$CLIENTS; i++ )); do
cat <<EOF >> $DEVICE-client_$i.conf
##############
# CLIENT $i
#
# <- $(date)
##############
[Interface]
Address = $NETWORK.$(($i+10))/24, $NETWORK6:$(printf "%x" $(($i+10)))/64
ListenPort = $SERVER_PORT
PrivateKey = ${CLIENT_SEC_KEYS[$i]}
DNS = $NETWORK.1
EOF

if [ $MTU ]; then
echo "MTU = $MTU" >> $DEVICE-client_$i.conf
fi

cat <<EOF >> $DEVICE-client_$i.conf

[Peer]
PublicKey = $SERVER_PUB_KEY
AllowedIPs = 0.0.0.0/0, ::/0
Endpoint = $SERVER_HOST:$SERVER_PORT
EOF

done

# Create dnsmasq hosts file
/scripts/hosts.sh $NETWORK $NETWORK6
