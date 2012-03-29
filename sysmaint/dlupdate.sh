#!/bin/bash
loglevel=1 # 1 = error 2 = all
logdir=./log
workdir=/root/scripts/sysmaint
updateserver=\[2a01:4f8:200:3000::17\] #CHANGE ME
sysmaint_user=sysmaint

cd $workdir
rm logtemp
touch logtemp

err() {
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
echo -e ". \n ---------------------------------" >> $logdir/sysmaint
date >> $logdir/sysmaint
cat logtemp >> $logdir/sysmaint
return $1
}


updatever() {
scp -o IdentityFile=/home/$sysmaint_user/.ssh/id_rsa $sysmaint_user@$updateserver:/home/$sysmaint_user/new_sysmaint.sh.gpg . > logvtemp
err $? ${FUNCNAME[0]} "couldnt download new version" $@ || return $?
gpg -d new_sysmaint.sh.gpg > new_sysmaint.sh
err $? ${FUNCNAME[0]} "couldnt decode new version, !!!maybe someone is beeing nasty" $@ || return $?
if [[ $? = 0 ]]
then
        mv new_sysmaint.sh sysmaint.sh
        mv newversion version
	chmod +x sysmaint.sh
	./sysmaint.sh
fi
}

checkver() {
scp -o IdentityFile=/home/$sysmaint_user/.ssh/id_rsa $sysmaint_user@$updateserver:/home/$sysmaint_user/newversion . > logvtemp
err $? ${FUNCNAME[0]} $1 $@ "couldnt get new version information" || return $?
if (( `cat newversion` > `cat version` )); then updatever; fi
}


checkver

