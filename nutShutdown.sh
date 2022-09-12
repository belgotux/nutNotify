#!/bin/bash
# Auteur : Belgotux
# Site : www.monlinux.net
# Licence : GPLV3 
# Version : 1.0
# Date : 08/04/2012

# Variables
logfile=/var/log/nutNotify/nutNotify.log  #logfile for nutNotify
flagfile=/var/log/nutNotify/nutShutdown.flag

#add to log
function addLog {
	if [ "$logfile" == "" ] ; then
		echo "Can't write to log !" 1>&2
		return 1
	else
		echo "$(date +'%a %d %H:%M:%S') $1" >> $logfile
		return $?
	fi
}


addLog "poweroff $HOSTNAME"
date +'%s' > $flagfile
shutdown -h +0

exit 0
