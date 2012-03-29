#!/bin/bash
cd /root/autoban/banned
if [[ $( wc -l current/yesterday | cut -d " " -f 1) -gt 0 ]]
then
mv current/yesterday archive/$(date | sed 's/[: ]/_/g')
touch current/yesterday
fi

mv current/today current/yesterday
touch current/today
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
