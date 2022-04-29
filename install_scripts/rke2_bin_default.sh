#!/bin/sh
# this script assumes you are root!

install -d /etc/rancher/rke2/install/core
install -d /var/lib/rancher/rke2/agent/images/

install -m 0644 /dev/null /etc/rancher/rke2/config.yaml

cat << EOF > /etc/rancher/rke2/envrc
export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/snap/bin:/var/lib/rancher/rke2/bin"
export RKE2_CONFIG_FILE="/etc/rancher/rke2/config.yaml"
export RKE2_TOKEN="this-is-a-test-token-$(date +%F)"
export KUBECONFIG=/etc/rancher/rke2/rke2.yaml
export MY_PRIVATE_IP="$(ip -j a | jq -r '.[].addr_info[0] | select(.label == "eth0") | .local')"
alias k='kubectl'
alias gm='watch -n 5 kubectl get node,all -A -o wide'
alias j='journalctl -feu k3s'
alias trke='tree -a -L 5 -I "bin" /var/lib/rancher'
alias trkee='tree -a /etc/rancher'
EOF

. /etc/rancher/rke2/envrc

# initial node
cat << EOF > /etc/rancher/rke2/config.yaml
write-kubeconfig-mode: 644
token: "$RKE2_TOKEN"
debug: true
EOF

# subsequent nodes need IP from initial node
#echo 'server: "https://<internal/private ip>:9345"' >> /etc/rancher/rke2/config.yaml


if [ ! -f "~/.profile" ]; then touch ~/.profile; fi
echo '. /etc/rancher/rke2/envrc' >> ~/.profile

wget -q https://github.com/rancher/rke2/releases/latest/download/rke2-images.linux-amd64.tar.gz
wget -q https://github.com/rancher/rke2/releases/latest/download/rke2.linux-amd64.tar.gz

mv rke2-images.linux-amd64.tar.gz /etc/rancher/rke2/install/
mv rke2.linux-amd64.tar.gz        /etc/rancher/rke2/install/

gzip -d /etc/rancher/rke2/install/rke2-images.linux-amd64.tar.gz
mv /etc/rancher/rke2/install/rke2-images.linux-amd64.tar /var/lib/rancher/rke2/agent/images/

tar xzf /etc/rancher/rke2/install/rke2.linux-amd64.tar.gz -C /etc/rancher/rke2/install/core
mv /etc/rancher/rke2/install/core/bin /var/lib/rancher/rke2/bin
ln -sf /var/lib/rancher/rke2/bin/rke2 /var/lib/rancher/rke2/bin/kubectl
mv /etc/rancher/rke2/install/core/share /var/lib/rancher/rke2/share

echo 'run this to start the server "rke2 server &"'
