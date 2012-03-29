#!/bin/bash
#All checks need to write their results to: ./tmplog
#heading messages are echoed 
#exit a meaningfull errorcode i.e. x>0 if a check fails
INSTALLATIONPATH=/root/scripts/sysm2/ # where to install
checks="diskusage updates ramusage smartstatus raidstatus rootkits" # functions to call when doing a daily check, report everything
errors="diskusage checkservices ramusage" # every 4 houers only report errors
errorsseldom="smartstatus raidstatus rootkits" # every 5 minutes only report errors
mailaddr="skarufue@localhost" #where we should mail stuff we find
services="nginx" #meaningful string which determines if a service is running when grep ing ps aux output
harddisks="/dev/sda5" #Harddisks for witch you want smartstatus (can also be raid arrays)
raids="/dev/md0" #Raid arrays
maxrepeat=2 #report errors this often then ignore until they are fixed
rm sendmail
hostname=$(cat /etc/hostname) 

if [[ $EUID -ne 0 ]]
then
   	echo "This script must be run as root" 1>&2
   	exit 1
fi

echo -e "\n ###### \n #$hostname reports on $(date)  \n ###### \n" >> sendmail

diskusage() {
	local i
	local return
	df -Ph >> tmplog

	for i in $(df -Ph)
	do

		if [[ $(echo $i | grep -c %) > 0 ]]
		then
			echo $i

			if [[ $(echo $i | sed 's/%//') -gt 95 ]] # 95 is the percentage at which we warn
			then
				return=$(( $return + 1 ))
			fi
		fi
	done
	exit $return
}

droppedpackages() {
	echo "coming soon"
}

raidstatus() {
local i 
	local return=0

	for i in $raids
	do
		mdadm --detail $i >> tmplog
		return=$(( $return + $? ))
	done
	exit $return
}

smartstatus() {
	local i 
	local return=0

	for i in $harddisks
	do
		smartctl -H -l selftest $i >> tmplog
		return=$(( $return + $? ))
		smartctl --smart=on --offlineauto=on --saveauto=on $i
	done
	exit $return
}

ramusage() {
	local return=0
	local i
	free -m >> tmplog
	swap=$(free -m | grep Swap:)
	local -a result

	for i in $(seq 2 60)
	do
		chk=$(echo $swap | cut -d " " -f $i)
		[[ $chk -gt 0 ]] && result[$((${#result[*]}+1))]=$chk
	done

	if [[ ${result[3]} -gt 0 ]]
	then
		[[ $(( ${result[1]} / ${result[3]} )) -gt 7 ]] && return=1 && echo "!!!!swap is very full this is baaaad news" 
	fi 
	exit $return
}

checkservices() {
	local i
	local return=0
	ps aux > tmplog

	for i in $services
	do

		if [[ $(ps aux | grep -c $i) -lt 2 ]]
		then
			echo "$i not running "
			return=$(( $return + 1 ))
		fi
	done
	exit $return
}

rootkits() {
	chkrootkit > tmplog
	exit $?
}

updates() {
	aptitude search ~U > tmplog
	exit 0
}



caller(){
	#echo $@
	#echo "calling $1"
	return=$($1 2>&1) # call $1 write all output into $return
	local retval=$? # save $1s exitcode to $retval
	#echo $retval
	#cat tmplog

	if [[ $(wc -l tmplog | cut -d " " -f 1) -gt 1 ]] #only do something if we have anything in the tmplog
	then

		if [[ "$2" == "errors" ]]
		then

			if  [[ $retval != 0 ]]
			then
				erroccur=$(cat ignore | grep $i | cut -d " " -f 2) 	#how often has this error occured previously

				if [[ $erroccur -lt $maxrepeat ]]			#dont do shit if we are aboth maxrepeat
				then                           				#generate content for mail
					echo -e "\n #### \n #$1 reported a error: $return \n #### \n" >> sendmail 
					cat tmplog >> sendmail 

				else
					echo !!!!IGNORING $i
				fi
				cat ignore | grep -v $1 > ignoretmp			#increase counter of erroroccurance
				echo $1 $(( $erroccur + 1 )) >> ignoretmp		
				mv ignoretmp ignore

			else
				cat ignore | grep -v $1 > ignoretmp			#everythings working. reset erroroccurence counter
				echo $1 0 >> ignoretmp
				mv ignoretmp ignore
			fi

		elif [[ "$2" == "checks" ]]						#we just be checking. write everything into the mail
		then
			#echo "doing ma thing on $i"
			echo -e "\n #### \n #$1 $return\n #### \n" >> sendmail
			cat tmplog >> sendmail
			accumulatederr=$(( $accumulatederr + $retval ))			
			#cat tmplog
		fi
	fi

	rm tmplog 									#remove the tmplog. for the next function
}


iterator () { #iterate over function names. hand them to caller
	local i

	for i in $1
	do
		caller $i $2
	done 
}

cronsetup() { #un/install cronjobs
crontab -l > tmpcron

if [[ "$1" == "install" ]]
then

	if [[ $(cat tmpcron | grep -c "$INSTALLATIONPATH/sysm2.sh") -lt 1 ]]
	then
		echo "*/5 * * * * $INSTALLATIONPATH/sysm2.sh errors" >> tmpcron
		echo "22 */4 * * * $INSTALLATIONPATH/sysm2.sh errorsseldom" >> tmpcron
		echo "2 5 */1 * * $INSTALLATIONPATH/sysm2.sh checks" >> tmpcron
		crontab tmpcron && echo "crojobs installed sucessfully" || echo "crojob installation failed"
	else
		echo "cronjobs seem to be already installed. please check roots crontab"
	fi

elif [[ "$1" == "uninstall" ]]
then
	cat tmpcron | grep -v "$INSTALLATIONPATH/sysm2.sh" > ttmpcron
	mv ttmpcron tmpcron
	crontab tmpcron && echo "cronjobs removed" || echo "failed to remove cronjobs"
fi
rm tmpcron
}

mailer() { #iterate over mailaddresses and send
	local m
        for m in $mailaddr
        do
                mail -s "$1" $m < sendmail
        done

}

if [[ "$1" == "errors" ]]  #check for CMD parameters and run stuff, these where just 2 options earlier. should be rewritten to a case conditional.
then
	iterator "$errors" errors

	if [[ $(wc -l sendmail | cut -d " " -f 1) -gt 6 ]]
	then
			mailer "Error on $hostname" 
	fi

elif [[ "$1" == "errorsseldom" ]]
then
        iterator "$errorsseldom" errors

        if [[ $(wc -l sendmail | cut -d " " -f 1) -gt 6 ]]
        then
                        mailer "Error on $hostname" 
        fi

elif [[ "$1" == "checks" ]]
then
	iterator "$checks" checks
	mailer "Report from $hostname. Total errorcode is: $accumulatederr" 

elif [[ "$1" == "install" ]]
then
	aptitude install smartmontools chkrootkit 
	sourcepwd=$PWD/$0
	cd /

	for i in $(echo "$INSTALLATIONPATH" | sed 's/\// /g')
	do
		mkdir $i
		cd $i
	done
	echo "created destination dir"
	touch ignore
	touch sendmail
	touch tmplog
	cp $sourcepwd $INSTALLATIONPATH
	echo "copied everything"
	chown root:root $INSTALLATIONPATH/$0
	chmod 700 $INSTALLATIONPATH/$0
	echo "set good permissions"
	cronsetup install

elif [[ "$1" == "uninstall" ]]
then
	cronsetup uninstall
	echo you need to remove $INSTALLATIONPATH manually if you want to get rid of all files related to sysm2.sh

else
 	echo "Syntax is: errors, checks, errorsseldom, install, uninstall"
fi

