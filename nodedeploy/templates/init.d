#!/bin/bash
if [[ "www-data" == "$(whoami)" ]]
then
    servicename=$( basename $0 ) 
        start()
        {
                screen -dmS $servicename /home/node/start-$servicename.sh
        }

        stop()
        {
                kill $(screen -ls | grep $servicename | cut -d "." -f 1)
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
        esac

else
    	servicename=$( basename $0 )
      	[[ -e /tmp/redis.sock ]] && chmod 777 /tmp/redis.sock
        chmod a+rw $(tty)
        su - www-data -s /bin/bash -c "/etc/init.d/$servicename $1"
        chmod 0720 $(tty);
fi

