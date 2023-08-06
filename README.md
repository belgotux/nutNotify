# nutNotify
Script to be notified by your UPS with differents notifications :
- mail
- Telegram
- Pushbullet
- Pushover
- SMS
- Discord

## Install
- Copy git
- Copy file `nutNotify.conf.txt` to `/usr/local/etc/nutNotify.conf` and edit it
- Copy `nutNotifyFct.sh nutNotifyBoot.sh nutNotify.sh nutShutdown.sh` to `/usr/local/bin`
- Copy `systemd-notify` to `/lib/systemd/system/nut-notify-boot.service`
- systemctl reload daemon and enable `nut-notify-boot`
- Create folder `/var/log/nutNotify` with nut rights
- Copy logrotate file to `/etc/logrotate.d`

```
git clone https://github.com/belgotux/nutNotify.git
cd nutNotify
cp nutNotify.conf.txt /usr/local/etc/nutNotify.conf
vim /usr/local/etc/nutNotify.conf
cp nutNotifyFct.sh nutNotifyBoot.sh nutNotify.sh nutShutdown.sh /usr/local/bin
cp systemd-notify /lib/systemd/system/nut-notify-boot.service
systemctl daemon-reload
systemctl enable nut-notify-boot.service
mkdir /var/log/nutNotify
chown nut:nut /var/log/nutNotify
cp nutNotify.logrotate /etc/logrotate.d
```
Activate nutNotify by editing `upsmon.conf` and replace "NOTIFYCMD" with `/usr/local/bin/nutNotify.sh`. 

## Link
Here an article (in french) in my website about [the notification of Nut by Telegram Pushbullet or Pushover](https://www.monlinux.net/2023/02/nut-notifications-push-telegram-pushbullet-pushover-pour-ups/)

You can see a howto to [setup your nut configuration to monitore your UPS from scratch (in french)](https://www.monlinux.net/2018/03/nut-ups-notifications-mails-et-arret/)
