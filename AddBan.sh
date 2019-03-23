#!/bin/bash

#
# Assign each parameter to a variable
#
if [ $# -eq 0 ]
then
	echo "AddBan.sh <Name> <SteamID> <IPAddress> <Duration> <Admin> <Reason>"
	exit
fi

if [ -z "$1" ]
then
	echo "Name must be provided."
	exit
fi
name=$1

if [ -z "$2" ]
then
	echo "Steam ID must be provided."
	exit
fi
steamid=$2

if [[ -v $3 ]]
then
	echo "IP address must be provided or set to an empty string."
	exit
fi
ipaddress=$3

if [ -z "$4" ]
then
	echo "Duration must be provided."
	exit
fi
duration=$4

if [ -z "$5" ]
then
	echo "Banning admin must be provided."
	exit
fi
admin=${5:-ADMIN}

if [ -z "$6" ]
then
	echo "Reason must be provided."
	exit
fi
reason=${6:-}

#
# Validation
#
if [[ $name == *";"* ]]
then
	echo "Name cannot contain semicolons."
	exit
fi

if [[ $steamid -le 76561197960265728 || $steamid -ge 80000000000000000 ]]
then
	echo "Invalid Steam ID provided."
	exit
fi

IFS='.' read -r -a ipoctets <<< "$ipaddress"
for octet in "${ipoctets[@]}"
do
	if ! [[ $octet =~ ^[0-9]+$ ]]
	then
		echo "IP Octet $octet is not a number."
		exit
	fi
	
	if [[ $octet -lt 0 || $octet -gt 255 ]]
	then
		echo "IP octet $octet is not a valid octet."
		exit
	fi
done

if [[ -n "$ipaddress" && "${ipaddress:0:7}" != "::ffff:" ]]
then
	ipaddress=::ffff:${ipaddress}
fi

case $duration in
1m)
	duration=1
	;;
5m)
	duration=5
	;;
15m)
	duration=15
	;;
30m)
	duration=30
	;;
1h)
	duration=60
	;;
3h)
	duration=180
	;;
5h)
	duration=300
	;;
8h)
	duration=480
	;;
12h)
	duration=720
	;;
1d)
	duration=1440
	;;
3d)
	duration=4320
	;;
7d)
	duration=10080
	;;
14d)
	duration=20160
	;;
30d)
	duration=43200
	;;
100d)
	duration=144000
	;;
1y)
	duration=525600
	;;
5y)
	duration=2628000
	;;
50y)
	duration=1576800000
	;;
*)
	echo "Duration must be one of: 1m|5m|15m|30m|1h|3h|5h|8h|12h|1d|3d|7d|14d|30d|100d|1y|5y|50y"
	exit 1
esac

if [[ $admin == *";"* ]]
then
	echo "Admin cannot contain semicolons."
	exit
fi

if [[ $reason == *";"* ]]
then
	echo "Reason cannot contain semicolons."
	exit
fi

now=`date +%s`
start=$(($now * 10000000))
start=$(($start + 621355968000000000))
end=$(($now + $duration * 60))
end=$(($end * 10000000))
end=$(($end + 621355968000000000))

echo "Adding ban to SteamIdBans.txt..."
echo "$name;$steamid;$end;$reason;$admin;$start"
echo "$name;$steamid;$end;$reason;$admin;$start" >> SteamIdBans.txt

if [ -n "$ipaddress" ]
then
	echo "Adding ban to IpBans.txt..."
	echo "$name;$ipaddress;$end;$reason;$admin;$start"
	echo "$name;$ipaddress;$end;$reason;$admin;$start" >> IpBans.txt
fi
