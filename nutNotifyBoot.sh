#!/bin/bash
# Variables
logfile=/var/log/nutNotify/nutNotify.log
flagfile=/var/log/nutNotify/nutShutdown.flag
BIN_MAIL=/usr/bin/mail
BIN_PUSHBULLET=/usr/local/bin/pushbullet.sh

MAILTO=root

function aide() {
	echo "$0 [mail|pushbullet]"
}

# add to log
function addLog() {
	if [ "$logfile" == "" ] ; then
		echo "Can't write to log !" 1>&2
		return 1
	else
		echo "$(date +'%a %d %H:%M:%S') $1" >> $logfile
		return $?
	fi
}

if [ $# == 0 ] ; then
	if [ ! -e $BIN_MAIL ] ; then
		echo "Error $BIN_MAIL not found" 1>&2 && exit 1
	fi
	notifynut_method=mail
elif [ $# == 1 ] ; then
	if [ "$1" == "mail" ] && [ ! -e $BIN_MAIL ] ; then
		echo "Error $BIN_MAIL not found" 1>&2 && exit 1
	elif [ "$1" == "pushbullet" ] && [ ! -e $BIN_PUSHBULLET ] ; then
		echo "Error $BIN_PUSHBULLET not found" 1>&2 && exit 1
	elif [ "$1" == "mail" ] || [ "$1" == "pushbullet" ] ; then
		notifynut_method="$1"
	else
		aide
	fi
else
	echo "Error the method $1 is not supported"
fi





if [ -e $flagfile ] ; then
	case "$notifynut_method" in
	mail)
    	echo -e "$(date '+%d/%m/%y %H:%M:%S') $HOSTNAME booting\n Downtime $(date -d @$(( $(date +'%s') - $(cat $flagfile))) -u +%H:%M:%S)" | mail -s "booting $HOSTNAME" $MAILTO ;;
	pushbullet)
		$BIN_PUSHBULLET "booting $HOSTNAME" "$(date '+%d/%m/%y %H:%M:%S') $HOSTNAME booting - Downtime $(date -d @$(( $(date +'%s') - $(cat $flagfile))) -u +%H:%M:%S)" ;;
	esac
    rm $flagfile
fi

exit 0