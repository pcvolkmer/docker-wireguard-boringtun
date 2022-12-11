#!/bin/bash

if [ ! -f "$DEVICE-client_$1.conf" ]; then
  echo "No client $1"
  exit 1
fi

cat "$DEVICE-client_$1.conf"

echo
echo

# Create QR-codes for clients
if [ ! -z "$(which qrencode 2>/dev/null)" ]; then
  cat "$DEVICE-client_$1.conf" | sed '/^#/d '| qrencode -t utf8
fi