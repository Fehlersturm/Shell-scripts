#!/bin/bash
#this can be used as mentainance option. all servers download this. and execute it once.
#THis is no working part of the sysmaint package. Its just a example shellscript 
loglevel=1 # 1 = error 2 = all

err() { #simple error logging exc: exitstatus additional information to log
if (( $loglevel == 1 ));
then
        if (( $1 > 0 ))
                then
                echo ------------- >> logtemp
                echo ERROR:$@ >> logtemp
                cat logvtemp >> logtemp
        fi
else
        echo ------------- >> logtemp
        echo $@ >> logtemp
        cat logvtemp >> logtemp
fi
echo -e ". \n ---------------------------------" >> /var/log/sysmaint
date >> /var/log/sysmaint
cat logtemp >> /var/log/sysmaint
return $1
}

srestart() { #restarts /etc/init.d/$1 sample call: service ?[serious/simple ${FUNCNAME[0]}]
/etc/init.d/$1 restart > logvtemp
err $? ${FUNCNAME[0]} $1 $@
if [[ $2 == "serious" ]]
then
	killal $1 > logvtemp
	err $? ${FUNCNAME[0]} $1 "->tried to kill" $@
	/etc/init.d/$1 start > logvtemp
	err $? ${FUNCNAME[0]} $1 "->tried to start. giving up" $@
else
restart $1
fi
}

echo OH IT WORKED SO HARD
