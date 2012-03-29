#!/bin/bash
SAVELOCATION=/usr/local/etc/iptablessave

start(){
echo start
for i in `seq 200 -1 0`
do      olne=$lne
        lne="`cat $SAVELOCATION | tail -n $i | head -n 1`"
        if [[ "$lne" != "$olne" ]]
        then echo iptables $olne; fi
done
}

save(){
iptables -S > $SAVELOCATION
iptables -t nat -S >> $SAVELOCATION
}

stop(){
#Just flush the tables and call it a stop
iptables -F INPUT
iptables -F FORWARD
iptables -F OUTPUT
}



case "$1" in
        start)
                start
        ;;
        stop)
                stop
        ;;
        restart)
                stop
                start

        ;;
        save)
                save
        ;;
esac

