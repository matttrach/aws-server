#!/bin/sh
# this script assumes you are root!

cat << EOF > /root/envrc
# env vars here
EOF

. /root/envrc

if [ ! -f "~/.profile" ]; then touch ~/.profile; fi
echo '. /root/envrc' >> ~/.profile

# don't be thrown, this script basically does nothing... just a placeholder
