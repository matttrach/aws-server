#!/bin/sh
# this script assumes you are root!

install -d /etc/rancher/rke2
install -m 0644 /dev/null /etc/rancher/rke2/config.yaml

cat << EOF > /etc/rancher/rke2/envrc
export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/snap/bin:/var/lib/rancher/rke2/bin"
export TOKEN="this-is-a-test-token-$(date +%F)"
alias k='kubectl'
alias gm='watch -n 5 kubectl get node,all -A -o wide'
alias j='journalctl -feu k3s'
alias trke='tree -a -L 5 -I "bin" /var/lib/rancher'
alias trkee='tree -a /etc/rancher'
EOF

. /etc/rancher/rke2/envrc

if [ ! -f "~/.profile" ]; then touch ~/.profile; fi
echo '. /etc/rancher/rke2/envrc' >> ~/.profile

wget https://github.com/k3s-io/k3s/releases/latest/download/k3s
chmod +x k3s
mv k3s /usr/bin/k3s
ln -sf k3s /usr/bin/kubectl
k3s server --token $TOKEN &
