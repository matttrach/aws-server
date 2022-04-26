#!/bin/sh

SUDO=""
S="--cluster-init"
if [ ! "$(whoami)" = "root" ]; then SUDO="sudo"; fi
if [ ! -z "$1" ]; then S="--server $1"; fi
$SUDO wget https://github.com/k3s-io/k3s/releases/download/v1.23.5%2Bk3s1/k3s
$SUDO chmod +x k3s
$SUDO mv k3s /usr/bin/k3s
$SUDO k3s server --token this-is-a-test-token-$(date +%F) $S &
$SUDO ln -sf k3s /usr/bin/kubectl

$SUDO timeout 300 watch kubectl get node,pod,pvc -A -o wide
