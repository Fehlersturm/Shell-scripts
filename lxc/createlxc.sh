#/bin/bash
source config
ftdip=$(echo $network | cut -d "." -f 1-3)
cd $workingdir
if [[ $(cat ips) == "" ]]
then
	echo $ftdip.$(($startingip - 1 )) > ips
fi
showcont()
{
        echo "Unknown Container. Defined containers are:"
        cat ips | cut -d " " -f 2
}

exists()
{
	echo $(cat ips | grep -c $1)
}
newipaddr()
{
	local lastdigit=0
	local workdigit=$startingip
	while [[ $lastdigit -eq 0 ]]
	do
		if [[ $(cat ips | grep -c "$ftdip.$workdigit") -eq 0 ]]
		then
			lastdigit=$workdigit
		fi
		workdigit=$(($workdigit + 1 ))
	done
	echo $ftdip.$lastdigit
}

create ()
{
ipaddr=$(newipaddr)

[ -e $1-network.conf ] || cat network.conf | sed "s/BRIDGEREPLACE/$virbr/" > $1-network.conf
[[ $2 == "special" ]] && vi $1-network.conf
lxc-create -n $1 -t ubuntu -f $1-network.conf
if [[ $? -eq 0 ]]
then
	[ -e $1-interfaces ] || cat interfaces | sed "s/IPADDRREPLACE/$ipaddr/" | sed "s/GATEWAYREPLACE/$gwip/" > $1-interfaces
	[[ $2 == "special" ]] && vi $1-interfaces
	cat $1-interfaces > /var/lib/lxc/$1/rootfs/etc/network/interfaces
	echo "$ipaddr $1" >> ips
	chroot /var/lib/lxc/$1/rootfs passwd
	lxc-start -n $1 -d
	echo "IP of new container is: $ipaddr"
else
	echo "couldnt create lxc container"
fi
}

portforward()
{
if [[ $(exists $1) -gt 0 ]]
then
	lxcname=$1
	shift
	ipaddr=$(cat ips | grep $lxcname | cut -d " " -f 1)
	for i in $@ 
	do
		iptables -t nat -A lxc-NAT -i $gwif -p tcp -m tcp --dport $i -j DNAT --to-destination $ipaddr:$i #$lxcname
		echo "iptables -t nat -A lxc-NAT -i $gwif -p tcp -m tcp --dport $i -j DNAT --to-destination $ipaddr:$i #$lxcname" >> iptables
	done
else
	showcont
fi
} 

uportfw()
{
local i
if [[ $(exists $1) -gt 0 ]]
then
        lxcname=$1
        shift
        ipaddr=$(cat ips | grep $lxcname | cut -d " " -f 1)
        for i in $@
        do
		cat iptables | grep -ve "^iptables.*ort $i -j.*ion $ipaddr:$i .lxcname$" > iptablestmp
		mv iptablestmp iptables 	
		chmod +x iptables
        done
	./iptables
else
        showcont
fi
}


show()
{
if [[ "$1" == "" ]]
then
	showcont
else
	if [[ $(exists $1) -gt 0 ]]
	then
		echo "Information for $1:"
		lxc-info -n $1
		echo "IP:	 $(cat ips | grep $1 | cut -d " " -f 1)"
		echo "Forwarded Ports:"
		cat iptables | grep $1 | cut -c 60- | cut -d "-" -f 1 
	else
		showcont
	fi
fi
}

destroy()
{
if [[ $(exists $1) -gt 0 ]]
then
	lxc-destroy -n $1 -f
	cat iptables | grep -v $1 >> iptablestemp
	mv iptablestemp iptables
	chmod +x iptables
	cat ips | grep -v $1 >> ipstemp
	mv ipstemp ips
	./iptables
	rm $1-network.conf
	rm $1-interfaces
else
        showcont
fi
}

recreate()
{
if [[ $(exists $1) -gt 0 ]]
then
	lxc-destroy -n $1 -f
	lxc-create -n $1 -t ubuntu -f $1-network.config
	cat $1-interfaces > /var/lib/lxc/$1/rootfs/etc/network/interfaces
        chroot /var/lib/lxc/$1/rootfs passwd
        lxc-start -n $1 -d
else
        showcont
fi
}

help()
{
echo -e "create [name] [special]\n portforward [name] [ports]\n show [name] \n destroy [name] \n recreate [name] \n socket [socketname] [name] [name]{ [name]... \n help\n"
}

socket()
{
local i
local j
local k
local error=0
socketn=$1
shift
        rm sortn
        for j in $@; do echo $i > sortn; done
        for i in $(sort -bdf sortn); do names="$names $i"; done
        dirname=$(echo $names | sed 's/ //g')$socketn

for i in $@
do
	if [[$(exists $i) -lt 1]] 
	then
		echo "container $i doesnt exist"
		error=$(($error + 1))
	else
		if [[ -e /var/lib/lxc/$i/rootfs/tmp/$dirname ]]
		then
			echo "Socket $dirname already exists in $i"
			error=$(($error + 1))
		fi
	fi
done

if [[ $error -eq 0 ]]
then
	mkdir $workingdir/sockets/$dirname

	for k in $names
	do
		mount --bind $workingdir/sockets/$dirname  /var/lib/lxc/$k/rootfs/tmp/$dirname
		echo "mount --bind $workingdir/sockets/$dirname  /var/lib/lxc/$k/rootfs/tmp/$dirname" >> mountpersistance
	done
else
        showcont
fi
}

usocket()
{
socketn=$1
shift
for j in $@; do echo $i > sortn; done
for i in $(sort -bdf sortn); do names="$names $i"; done
dirname=$(echo $names | sed 's/ //g')$socketn
## TODO!!!!!

}

option=$1
shift
case "$option" in
        create)
                create $@
        ;;
        portfw)
		portforward $@		
        ;;
        uportfw)
                uportfw $@
        ;;
	socket)
		socket $@
	;;
	show)
		show $1
	;;
	destroy)
		destroy $1
	;;
	recreate)
		recreate $1
	;;
        help)
        	help
	;;
	*)
		echo "unknown option: $option"
		help
	;;
esac
