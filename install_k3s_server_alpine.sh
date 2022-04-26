#!/bin/sh

wget -q https://get.k3s.io -O install.sh
chmod +x install.sh 
sudo cp install.sh /root/
sudo su
INSTALL_K3S_EXEC="server --token this-is-a-test-token-$(date +%F) --write-kubeconfig-mode 644" ./install.sh

#tail -f /var/log/messages 
tail -f /var/log/k3s.log

#watch kubectl get node,pod,pvc -A -o wide
