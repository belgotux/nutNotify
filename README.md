# nutNotify
Script to be notified by your UPS with differents notifications :
- mail
- Telegram
- Pushbullet
- Pushover
- SMS

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


## Link
See this article for more informations (in french) : https://www.monlinux.net/2018/03/nut-ups-notifications-mails-et-arret/
