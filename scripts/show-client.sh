#!/bin/bash

cat "$DEVICE-client_$1.conf"

echo
echo

# Create QR-codes for clients
if [ ! -z "$(which qrencode 2>/dev/null)" ]; then
  qrencode -t utf8 < "$DEVICE-client_$1.conf"
fi