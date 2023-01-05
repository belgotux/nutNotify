#!/bin/bash

# variables
configFile=/usr/local/etc/nutNotify.conf

source "$configFile"
source "$(dirname $0)/nutNotifyFct.sh"

if [ ! -e "$configFile" ] ; then
	echo "File $configFile doesn't exist" 1>&2
	exit 1
fi

function aide() {
	echo "$0 [mail|pushbullet|telegram]"
}

# verify method
if [ $# == 0 ] ; then
	if [ ! -x $mailBin ] ; then
		echo "No mail command found at $mailBin, you need to install bsd-mailx!" 1>&2
		exit 1
	fi
	notifynut_method=mail
elif [ $# == 1 ] ; then
	if [ "$1" == "mail" ] && [ ! -e $mailBin ] ; then
		echo "Error $BIN_MAIL not found" 1>&2 && exit 1
	elif [ "$1" == "pushbullet" ] && [ ! -x $curlBin ] && [ "$pushbulletAccessToken" != "" ] ; then
		echo "Error pushbullet not configured" 1>&2 && echo "Error telegram not configured" > $logfile && exit 1
	elif [ "$1" == "telegram" ] && [ ! -x $curlBin ] && [ "$telegramAccessToken" != "" ] && [ "$telegramChatID" != "" ] ; then
		echo "Error telegram not configured" 1>&2 && echo "Error telegram not configured" > $logfile && exit 1
	elif [ "$1" == "mail" ] || [ "$1" == "pushbullet" ] || [ "$1" == "telegram" ] ; then
		notifynut_method="$1"
	else
		aide
	fi
else
	echo "Error the method $1 is not supported"
fi



text="$(date '+%d/%m/%y %H:%M:%S') $HOSTNAME booting\n Downtime $(date -d @$(( $(date +'%s') - $(cat $flagfile))) -u +%H:%M:%S)"

if [ -e $flagfile ] ; then
	case "$notifynut_method" in
	mail)
    sendMail "$subjectMail" "$text" ;;
	pushbullet)
		sleep 30; sendPushBullet "$pushbulletSubject" "$text" ;;
	telegram)
		sleep30; sendTelegram "$text" "$telegramSubject" ;;
	esac
    rm $flagfile
fi

exit 0