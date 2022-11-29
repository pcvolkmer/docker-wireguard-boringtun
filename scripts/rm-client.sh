#!/bin/bash

CONFIG=$(cat "$DEVICE.conf" | sed "/^\# Client $1/{N;N;N;N;d}")

echo "$CONFIG" > "$DEVICE.conf"

rm "$DEVICE-client_$1.conf" 2>/dev/null
rm "$DEVICE-client_$1.png" 2>/dev/null

echo "Client # $1 removed"