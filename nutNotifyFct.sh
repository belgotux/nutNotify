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
	
	echo "$textMail" | mail -s "$subjectMail" -r "$FROM" "$MAILTO"
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
	#replace default mesg
	if [ "$1" != "" ] ; then
		subjectPushBullet=$1
	fi
	if [ "$2" != "" ] ; then
		textPushBullet=$2
	fi
	
	#var verification
	if [ "$pushbulletProviderApi" == "" ] || [ "$pushbulletAccessToken" == "" ] ; then
		echo "Can't sen push notification without complete variables for PushBullet" 1>&2
		addLog "Can't sen push notification without complete variables for PushBullet"
		return 1
	fi
	
	tempfile=$(mktemp --suffix '.nutNotifyPushBullet')
	curl -s -o "$tempfile" --header "Access-Token: $pushbulletAccessToken" --header 'Content-Type: application/json' --request POST --data-binary "{\"type\":\"note\",\"title\":\"$HOSTNAME - $subjectPushBullet\",\"body\":\"$textPushBullet\"}" "$pushbulletProviderApi"
	returnCurl=$?
	if [ $returnCurl -ne 0 ] ; then cat $tempfile ; fi
	rm $tempfile
	return $?
}

#send push notification with Telegram
# $1 message
# $2 title
# $3 emoji
function sendTelegram {
	#replace default mesg
	if  [ "$2" != "" ] && [ "$3" != "" ]  ; then
		local textTelegram=$(echo -e "$3 $HOSTNAME $3 $2\n$1")
	elif [ "$2" != "" ] ; then
		local textTelegram=$(echo -e "$HOSTNAME - $2 \n$1")
	else
		local textTelegram="$3$HOSTNAME : $1"
	fi
	#var verification
	if [ "$telegramProviderApi" == "" ] || [ "$telegramAccessToken" == "" ] ; then
		echo "Can't send notification without complete variables for Telegram" 1>&2
		addLog "Can't send notification without complete variables for Telegram"
		return 1
	fi
	
	tempfile=$(mktemp --suffix '.telegram-notification')
	curl -s -o "$tempfile" --data "chat_id=${telegramChatID}" --data "text=${textTelegram}" "${telegramProviderApi}/bot${telegramAccessToken}/sendMessage"
	returnCurl=$?
	if [ $returnCurl -ne 0 ] ; then cat $tempfile ; fi
	rm $tempfile
	return $returnCurl
}