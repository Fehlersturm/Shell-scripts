#!/bin/bash
ignore="never ban line containing sis"
containerf()
{
cat /var/log/apache2/access.log | grep -v $ignore | tail -n 4000 > /root/autoban/ramdisk/bancache
sessrand=$(echo $RANDOM | cut -c 1)
rm /root/autoban/ramdisk/tobanned
#for i in $(cat /root/autoban/ramdisk/bancache | grep '"-" "-"' | cut -d " " -f 1)
#do
#	echo $i >> /root/autoban/ramdisk/tobanned
#
#	if [[ $(grep -c $i /root/autoban/ramdisk/tobanned ) == 1 ]]
#	then
#		echo "$i suspicious:  am guessing HOIC"
#		echo $i >> /root/autoban/ramdisk/bannedi
#	fi
#done

timeelap=$(( $(cat /root/autoban/ramdisk/bancache | tail -n 1 | cut -d " " -f 4 | cut -d ":" -f 3 | sed 's/0*//') - $(cat /root/autoban/ramdisk/bancache | head -n 1 | cut -d " " -f 4 | cut -d ":" -f 3 | sed 's/0*//') ))

if [[ $timelap -lt 5 ]]
then
	cat /root/autoban/ramdisk/bancache | cut -d " " -f 1 > /root/autoban/ramdisk/connips

	while [[ $( wc -l /root/autoban/ramdisk/connips | cut -d " " -f 1) -gt 100 ]]
	do
		sip=$(cat /root/autoban/ramdisk/connips | head -n 1)
		if [[ $(grep -c $sip /root/autoban/ramdisk/connips) -gt 220 ]]
		then
			echo "$sip suspicious: flood" 
			echo $sip >> /root/autoban/ramdisk/bannedi
		fi
		cat /root/autoban/ramdisk/connips | grep -v $sip > /root/autoban/ramdisk/connipstmp 
		mv /root/autoban/ramdisk/connipstmp /root/autoban/ramdisk/connips
	done
fi

bancount=0
echo -e "\n"

for j in $(cat /root/autoban/ramdisk/bannedi)
do
if [[ $(grep -c $j /root/autoban/banned/current/today) == 0 ]]
then
	echo "banning $j"
 	echo $j >> /root/autoban/banned/current/today
	bancount=$(( $bancount + 1 ))
fi
done

rm /root/autoban/ramdisk/bannedi
echo "banned: $bancount new ips"
if [[ $bancount -gt 0 ]]
then
#here you need to reload the Iptables rules somehow. If you have your own tables for these bans this can be as simple asÖ:
#iptables -F -t yourtable
#cd current
#for i in `ls`
#do
#for j in `cat $i`
#do
#iptables -t yourtable -s $j DROP
#done
#done

fi

if [[ $(( $bancount * 10 )) -gt 230 ]]
then
sleepmod=230
else
sleepmod=$(( $bancount * 10 ))
fi
sleeptime=$(( 240 - $sleepmod ))
echo sleeping for $sleeptime
sleep $sleeptime
}

callf()
{
containerf
sleep $sessrand
callf
}
callf
