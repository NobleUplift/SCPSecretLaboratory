#!/bin/bash

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

if [ -z "$3" ]
then
	echo "Duration must be provided."
	exit
fi
duration=$3

admin=${4:-ADMIN}

reason=${5:-}

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


now=`date +%s`
start=$(($now * 10000000))
start=$(($start + 621355968000000000))
end=$(($now + $duration))
end=$(($end * 10000000))
end=$(($end + 621355968000000000))

echo "Adding ban to SteamIdBans.txt..."
echo "$name;$steamid;$end;$reason;$admin;$start"
cp SteamIdBans.txt SteamIdBans.txt.bak
echo "$name;$steamid;$end;$reason;$admin;$start" >> SteamIdBans.txt

