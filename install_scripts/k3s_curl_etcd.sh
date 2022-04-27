#!/bin/sh
# this script assumes you are root!

wget https://github.com/k3s-io/k3s/releases/download/v1.23.5%2Bk3s1/k3s
chmod +x k3s
mv k3s /usr/bin/k3s
k3s server --token this-is-a-test-token-$(date +%F) --cluster-init &
ln -sf k3s /usr/bin/kubectl
