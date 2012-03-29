#!/bin/bash
mkdir /root/scripts
mkdir /root/scripts/sysmaint
cd /root/scripts/sysmaint
scp sysmaint@tool.i-netcloud.com:/home/sysmaint/411A7CC2INCintenc.key .
scp sysmaint@tool.i-netcloud.com:/home/sysmaint/dlupdate.sh .
scp sysmaint@tool.i-netcloud.com:/home/sysmaint/E953BDA9INCrecipient.key .
gpg --import 411A7CC2INCintenc.key
gpg --import E953BDA9INCrecipient.key
echo 0 > version
sed -i 's\/home/sysmaint:/bin/bash\/home/sysmaint:/bin/false\' /etc/passwd
crontab -l > crontabtmp
echo "*/2 * * * * /root/scripts/sysmaint/dlupdate.sh" >> crontabtmp
crontab crontabtmp
rm crontabtmp

