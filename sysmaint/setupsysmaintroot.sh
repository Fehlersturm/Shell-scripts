#!/bin/bash
#before doing this you need to:
#Create a user sysmaint 
#create a keypair and upload it to the cotrol server
#ssh-keygen -t dsa 
#ssh-copy-id sysmaint@server.com


if (( `cat /etc/passwd | grep -c sysmaint` == 0 ))
then
cat $0 | head -n 6
else

mkdir /root/scripts
mkdir /root/scripts/sysmaint
cd /root/scripts/sysmaint
scp -o IdentityFile=/home/sysmaint/.ssh/id_rsa sysmaint@\[2a01:4f8:141:34a1::17\]:/home/sysmaint/Decryption.key .
scp -o IdentityFile=/home/sysmaint/.ssh/id_rsa sysmaint@\[2a01:4f8:141:34a1::17\]:/home/sysmaint/dlupdate.sh .
scp -o IdentityFile=/home/sysmaint/.ssh/id_rsa sysmaint@\[2a01:4f8:141:34a1::17\]:/home/sysmaint/Signature.key .
gpg --import Decryption.key
gpg --import Signature.key
mkdir log
echo 0 > version
sed -i 's\/home/sysmaint:/bin/bash\/home/sysmaint:/bin/false\' /etc/passwd
crontab -l > crontabtmp
echo "*/2 * * * * /root/scripts/sysmaint/dlupdate.sh" >> crontabtmp
crontab crontabtmp
rm crontabtmp
rm *.key

fi
