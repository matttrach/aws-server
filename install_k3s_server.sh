#!/bin/sh

SUDO=""
S="--cluster-init"
if [ ! "$(whoami)" = "root" ]; then SUDO="sudo"; fi
if [ ! -z "$1" ]; then S="--server $1"; fi

CMD="$SUDO curl -sfL https://get.k3s.io | \
    INSTALL_K3S_EXEC=\"server $S --token this-is-a-test-token-$(date +%F) --write-kubeconfig-mode 644\" \
    sh -"
echo $CMD

#$SUDO timeout 300 watch kubectl get node,pod,pvc -A -o wide
