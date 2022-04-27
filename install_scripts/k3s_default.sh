#!/bin/sh
# this script assumes you are root!

curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC="server --token this-is-a-test-token-$(date +%F)" sh -
