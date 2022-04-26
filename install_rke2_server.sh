#!/bin/sh
# source this file!
apt update
apt install -y net-tools jq tree

install -d /etc/rancher/rke2
install -m 0644 /dev/null /etc/rancher/rke2/config.yaml
export RKE2_CONFIG_FILE="/etc/rancher/rke2/config.yaml"
export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/snap/bin:/var/lib/rancher/rke2/bin"
export RKE2_TOKEN="this-is-a-test-token-$(date +%F)"
export ADDR="$(ip -j a | jq -r '.[].addr_info[0] | select(.label == "eth0") | .local')"

cat << EOF > /etc/rancher/rke2/config.yaml
write-kubeconfig-mode: 644
token: "$RKE_TOKEN"
debug: true
EOF

cat << EOF > /etc/rancher/rke2/envrc
export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/snap/bin:/var/lib/rancher/rke2/bin"
export RKE2_CONFIG_FILE="/etc/rancher/rke2/config.yaml"
export RKE2_TOKEN="this-is-a-test-token-$(date +%F)"
export KUBECONFIG=/etc/rancher/rke2/rke2.yaml
alias k='kubectl'
alias gm='watch -n 5 kubectl get node,all -A -o wide'
EOF

. /etc/rancher/rke2/envrc

curl -sfL https://get.rke2.io | sh -

systemctl enable --now rke2-server.service && \
watch -n 5 kubectl get node,all -A -o wide

#journalctl -feu rke2-server
#watch -n 5 tree -a -L 2 /var/lib/rancher/rke2
#watch -n 5 tree -a /etc/rancher/rke2
