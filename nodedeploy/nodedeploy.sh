#!/bin/bash
######CONFIG######
GITROOT="https://github.com/inetcompany/"
WORKDIR=$(echo $0|rev|cut -d "/" -f 2-|rev)

servicename=$1

#functions

funread(){ 
	if [[ "$2" == "nostring" ]] 
	then
		read -p "$1: " $1
	else
		read -p "$1: " userip
		export "$1"="\"$userip\""  
	fi 
}

#prerequisites

prereq_aptitude-packages()
{
	shift
	aptitude -y install $@
}

prereq_redis()
{
	aptitude -y install redis-server
	/etc/init.d/redis-server stop
	cp $WORKDIR/templates/redis.conf /etc/redis/.
	/etc/init.d/redis-server start
}


prereq_create-local-yaml-static()
{
	shift
	while [[ $1 != "" ]]
	do
		export "$1"="\"$2\""
		shift 2
	done
}

prereq_create-local-yaml()
{
	cd config
	shift
	for i in $@
	do
		funread $i
	done
	OIFS=$IFS
	IFS="
	"
	for i in $(cat default.yaml)
	do [[ "$(echo $i | cut -d ":" -f 1)" == "Extensions" ]] && break
		if [[ $(echo $i | grep -ce "^  ") -gt 0 ]]
		then
			varn=$(echo $i | cut -d ":" -f 1 | cut -c 3-)
			realname=$currentcat
			realname+="_"
			realname+=$varn
			eval cont=\$$realname
			if [[ "$cont" != "" ]]
			then
				if [[ $currentcatwritten != 1 ]]
				then
					echo "$currentcat:" >> local.yaml
					currentcatwritten=1
				fi
			echo "  $varn: $cont" >> local.yaml
			fi
		else
			varn=$(echo $i | cut -d ":" -f 1)
			currentcat=$varn
			currentcatwritten=0
		fi
	done
	IFS=$OIFS
	cd ..
}



####install some stuff we need anyway####
apt-get -y install aptitude
aptitude update
aptitude -y install language-pack-en-base
dpkg-reconfigure locales
update-locale LC_ALL=en_US.UTF-8
aptitude -y install python-software-properties
add-apt-repository -y ppa:chris-lea/node.js
aptitude update
aptitude -y install pwgen git nodejs screen

####prepare user + enviroment####
adduser --disabled-password --gecos "" node
cd /home/node
mkdir git
cd git
git clone $GITROOT$servicename
cd $servicename

###parse prerequisites file
while read line; do 
    prereq_$(echo $line | cut -d " " -f 1) $line || echo "prerequisite $line not defined please look into it manually"
done < prerequisites

chown node -R /home/node

#Create log dir
mkdir /var/log/node
chmod 731 /var/log/node
chown node /var/log/node
#####install all the scripts: init.d  logrotate  start
cp $WORKDIR/templates/init.d /etc/init.d/$servicename
chmod +x echo $0|rev|cut -d "/" -f 2-|rev
update-rc.d $servicename defaults
cat $WORKDIR/templates/logrotate | sed "s#REPLACESERVICENAME#$servicename#g" > /etc/logrotate.d/$servicename
cat $WORKDIR/templates/start | sed "s#REPLACESERVICENAME#$servicename#g" > /home/node/start-$servicename


