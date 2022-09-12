#!/bin/bash
# Auteur : Belgotux
# Site : www.monlinux.net
# Licence : GPLV3
# Version : 1.1
# Date : 01/03/18
# changelog
# v1.0 use mail and SMS
# v1.1 use pushbullet and somes reviews

## Notes : 
## edit logrotate if needed
## the nut user must access to the logfile below

if [ $# != 1 ] ; then
	echo "Error : only one argument needed" 1>&2
	exit 1
fi

if [ ! -x $curlBin ] ; then
	echo "No curl fount at $curlBin ! Install it!" 1>&2
	exit 1
fi

# statics variables - don't change it
argument=$(echo "$1" | awk '{printf $1}')
ups=$(echo "$1" | awk '{printf $2}' | awk -F "[@:]" '{print $1}')
server=$(echo "$1" | awk '{printf $2}' | awk -F "[@:]" '{print $2}')
powerdownflag=$(sed -ne 's#^ *POWERDOWNFLAG *\(.*\)$#\1#p' /etc/nut/upsmon.conf)

# Variables
logfile=/var/log/nutNotify.log											# logfile for nutNotify
curlBin="/usr/bin/curl"
configFile=/usr/local/bin/nutNotify.conf

if [ ! -e "$configFile" ] ; then
	echo "File $configFile doesn't exist" 1>&2
	exit 1
fi

source "$configFile"

# add to log
function addLog {
	if [ "$logfile" == "" ] ; then
		echo "Can't write to log !" 1>&2
		return 1
	else
		echo "$(date +'%a %d %H:%M:%S') $1" >> $logfile
		return $?
	fi
}

function writeLog {
	addLog  "$HOSTNAME : UPS $ups state $argument"
	return $?
}

# send mail
# $1 subjectMail (optional) - default $subjectMail
# $2 text/HTML body message - default $textMail
function sendMail {
	# replace default mesg
	if [ "$1" != "" ] ; then
		subjectMail=$1
	fi
	if [ "$2" != "" ] ; then
		textMail=$2
	fi
	
	# var verification
	if [ "$FROM" == "" ] || [ "$MAILTO" == "" ] || [ "$subjectMail" == "" ] || [ "$textMail" == "" ] ; then
		echo "Can't send mail without complete variables" 1>&2
		addLog "Can't send mail without complete variables"
		return 1
	fi
	
	(
	echo "From: $FROM"
	echo "To: $MAILTO"
	echo "MIME-Version: 1.0"
	echo "Content-Type: multipart/mixed;"
	echo " boundary=\"PAA08673.1018277622/$dom\""
	echo "Subject: $subjectMail"
	echo ""
	echo "This is a MIME-encapsulated message"
	echo ""
	echo "--PAA08673.1018277622/$dom"
	echo "Content-Type: text/html"
	echo ""
	
	echo "$textMail"
	
	echo "--PAA08673.1018277622/$dom"

	) | sendmail -t
	return $?
}

# send sms
# $1 text body message - default $textSms
function sendSms {
	# replace default mesg
	if [ "$1" != "" ] ; then
		textSms=$1
	fi
	
	# var verification
	if [ "$providerSms" == "" ] || [ "$usernameSms" == "" ] || [ "$passwordSms" == "" ] || [ "$fromSms" == "" ] || [ "$toSms" == "" ] || [ "$textSms" == "" ] ; then
		echo "Can't send SMS without complete variables" 1>&2
		addLog "Can't send mail without complete variables"
		return 1
	fi
	
	textSms=$(echo $textSms | sed -e 's/ /%20/g' | iconv -t iso-8859-1)

	url="https://www.$providerSms/myaccount/sendsms.php?username=$usernameSms&password=$passwordSms&from=$fromSms&to=$toSms&text=$textSms"
	tempfile=$(tempfile -p 'nutNotifySms-')
	curl -s -o $tempfile $url
	result=$(cat $tempfile | grep '<result>' | awk -F "[<>]" '{print $3}')
	description=$(cat $tempfile | grep '<description>' | awk -F "[<>]" '{print $3}')
	if [ "$result" == 1 ] ; then
		addLog "sendSMS : success"
		return 0
	else
		echo "sendSMS : fail - $description" 1>&2
		addLog "sendSMS : fail - $description"
		return 1	
	fi
	rm $tempfile
	
}

# send push notification with pushbullet
# see https://www.pushbullet.com
# $1 title
# $2 text body - default $textPushBullet
function sendPushBullet {
	# replace default mesg
	if [ "$1" != "" ] ; then
		subjectPushBullet=$1
	fi
	if [ "$2" != "" ] ; then
		textPushBullet=$2
	fi
	
	# var verification
	if [ "$providerApi" == "" ] || [ "$accessToken" == "" ] ; then
		echo "Can't sen push notification without complete variables for PushBullet" 1>&2
		addLog "Can't sen push notification without complete variables for PushBullet"
		return 1
	fi
	
	tempfile=$(tempfile -p 'nutNotifyPushBullet-')
	curl -s -o $tempfile --header "Access-Token: $accessToken" --header 'Content-Type: application/json' --request POST --data-binary "{\"type\":\"note\",\"title\":\"$subjectPushBullet\",\"body\":\"$textPushBullet\"}" "$providerApi"
	# TODO check return
	rm $tempfile
}

case "$argument" in
ONLINE)
	text="UPS $ups is now online at $(date +'%H:%M:%S')"
	writeLog
	sendMail "$subjectMail" "$text"
	sendPushBullet "$subjectPushBullet" "$text"
;;

ONBATT)
	text="Powercut at $(date +'%H:%M:%S')! UPS $ups run on battery!"
	writeLog
	sendMail "$subjectMail" "$text"
	sendPushBullet "$subjectPushBullet" "$text"
#	sendSms "$text"
;;

LOWBATT)
	# note : notify get when /sbin/upsdrvctl shutdown executed
	text="Low level battery at $(date +'%H:%M:%S') UPS $ups... Shutdown imminent !"
	writeLog
	sendMail "$subjectMail" "$text"
	sendPushBullet "$subjectPushBullet" "$text"
#	sendSms "$text"
;;

FSD)
	# note : for slave only
	text="Force shutdown slave server $server at $(date +'%H:%M:%S') !"
	writeLog
	sendMail "$subjectMail" "$text"
	sendPushBullet "$subjectPushBullet" "$text"
#	sendSms "$text"
;;

SHUTDOWN)
	# note : executed on the master only
	text="Shutdown master serveur $server at $(date +'%H:%M:%S') !"
	writeLog
	sendMail "$subjectMail" "$text"
	sendPushBullet "$subjectPushBullet" "$text"
#	sendSms "$text"
;;

COMMOK|COMMBAD|REPLBATT|NOCOMM)
	writeLog
	sendMail
	sendPushBullet
	# sendSms
;;

SERVERONLINE)
	# note : log not for nutNotify but was call when server is poweroff after a failure
		# add this to init nut script or make a new one
	if [ -f $powerdownflag ] ; then
		# add your script here to wakeup other servers etc
		text="Serveur $server online at $(date +'%H:%M:%S') !"
		rm -f $powerdownflag && \
		writeLog && \
		sendMail "$subjectMail" "$text"
		sendPushBullet "$subjectPushBullet" "$text"
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
