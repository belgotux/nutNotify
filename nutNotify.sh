#!/bin/bash
# Auteur : Belgotux
# Site : www.monlinux.net
# Licence : GPLV3
# Version : 2.0
# Date : 01/03/18
# Update : 04/01/23
# changelog
# v1.0 use mail and SMS
# v1.1 use pushbullet and somes reviews
# v1.2 add telegram support
# v2.0 modify mail function to use mail daemon + split function file

## Notes : 
## edit logrotate if needed
## the nut user must access to the logfile below

if [ $# != 1 ] ; then
	echo "Error : only one argument needed" 1>&2
	exit 1
fi

# statics variables - don't change it
argument=$(echo "$1" | awk '{printf $1}')
ups=$(echo "$1" | awk '{printf $2}' | awk -F "[@:]" '{print $1}')
server=$(echo "$1" | awk '{printf $2}' | awk -F "[@:]" '{print $2}')
powerdownflag=$(sed -ne 's#^ *POWERDOWNFLAG *\(.*\)$#\1#p' /etc/nut/upsmon.conf)

# Variables
configFile=/usr/local/etc/nutNotify.conf

if [ ! -e "$(dirname $0)/nutNotifyFct.sh" ] ; then
	echo "Functions script $(dirname $0)/nutNotifyFct.sh doesn't exist" 1>&2
	exit 1
fi
source "$(dirname $0)/nutNotifyFct.sh"

if [ -e "$configFile" ] ; then
	source "$configFile"
elif [ -e "$(dirname $0)/nutNotify.conf" ] ; then
	source "$(dirname $0)/nutNotify.conf"
else
	echo "File $configFile doesn't exist" 1>&2
	exit 1
fi

if [ ! -x $curlBin ] ; then
	echo "No curl fount at $curlBin ! Install it!" 1>&2
	exit 1
fi

if [ ! -x $mailBin ] ; then
	echo "No mail command found at $mailBin, you need to install bsd-mailx!" 1>&2
	exit 1
fi

case "$argument" in
ONLINE)
	text="UPS $ups is now online at $(date +'%H:%M:%S')"
	writeLog
	conditionalNotification $argument "$text" ""
;;

ONBATT)
	text="Powercut at $(date +'%H:%M:%S')! UPS $ups run on battery!"
	writeLog
	emoji=$(echo -e "\xE2\x9A\xA0")
	conditionalNotification $argument "$text" "$emoji"
;;

LOWBATT)
	# note : notify get when /sbin/upsdrvctl shutdown executed
	text="Low level battery at $(date +'%H:%M:%S') UPS $ups... Shutdown imminent !"
	writeLog
	emoji=$(echo -e "\xF0\x9F\x94\xA5")
	conditionalNotification $argument "$text" "$emoji"
;;

FSD)
	# note : for slave only
	text="Force shutdown slave server $server at $(date +'%H:%M:%S') !"
	writeLog
	emoji=$(echo -e "\xE2\x9A\xA0")
	conditionalNotification $argument "$text" "$emoji"
;;

SHUTDOWN)
	# note : executed on the master only
	text="Shutdown master serveur $server at $(date +'%H:%M:%S') !"
	writeLog
	emoji=$(echo -e "\xF0\x9F\x94\xA5")
	conditionalNotification $argument "$text" "$emoji"
;;

COMMOK|COMMBAD|REPLBATT|NOCOMM)
	writeLog
	conditionalNotification $argument "$text" ""
;;

SERVERONLINE)
	# note : log not for nutNotify but was call when server is poweroff after a failure
		# add this to init nut script or make a new one
	if [ -f $powerdownflag ] ; then
		# add your script here to wakeup other servers etc
		text="Serveur $server online at $(date +'%H:%M:%S') !"
		rm -f $powerdownflag && \
		writeLog
		conditionalNotification $argument "$text" ""
	fi
;;

*)
# nothing
	echo "Error : this argument is not managed" 1>&2
	addLog "bad argument"
;;
esac

# Possible values for type:

#   ONLINE - UPS is back online
#   ONBATT - UPS is on battery
#   LOWBATT - UPS is on battery and has a low battery (is  critical)
#   FSD  -  UPS  is  being  shutdown by the master (FSD = "ForcedShutdown")
#   COMMOK - Communications established with the UPS
#   COMMBAD - Communications lost to the UPS
#   SHUTDOWN - The system is being shutdown
#   REPLBATT - The UPS battery is bad and needs to be replaced
#   NOCOMM - A UPS is unavailable (can't be contacted  for  monitoring)


exit 0
