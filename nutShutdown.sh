#!/bin/bash
# Auteur : Belgotux
# Site : www.monlinux.net
# Licence : GPLV3 
# Version : 1.1
# Date : 08/04/2012
# Update : 04/01/2023

# variables
configFile=/usr/local/etc/nutNotify.conf

source "$configFile"
source "$(dirname $0)/nutNotifyFct.sh"


addLog "poweroff $HOSTNAME"
date +'%s' > $flagfile
shutdown -h +0

exit 0
