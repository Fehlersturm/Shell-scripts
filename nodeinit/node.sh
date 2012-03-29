#!/bin/bash

numforks=8 #number of forks

start()
{
for i in `seq 1 $numforks`
do
su - www-data -s /bin/bash -c "screen -dmS node$i path/to/startnode.sh $i"
done
}

stop()
{
for i in `seq 1 $numforks`
do
kill $(su - www-data -s /bin/bash -c "screen -ls" | grep node$i | cut -d "." -f 1)
done
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

