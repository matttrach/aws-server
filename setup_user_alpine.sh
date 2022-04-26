#!/bin/sh

SUDO=""
if [ ! "$(whoami)" = "root" ]; then SUDO="sudo"; fi
USER="$1"
$SUDO addgroup $USER
$SUDO adduser -g "Matt Trachier" -s "/bin/sh" -G "$USER" -D $USER
$SUDO addgroup $USER wheel
$SUDO install -d -m 0700 /home/$USER/.ssh
$SUDO cp .ssh/authorized_keys /home/$USER/.ssh
$SUDO chown -R $USER:$USER /home/$USER
$SUDO passwd $USER -d '' -u
$SUDO openrc -s sshd restart
