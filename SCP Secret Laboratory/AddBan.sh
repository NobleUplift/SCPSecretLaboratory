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
elif [[ "$1" == *";"* ]]
then
	echo "Name cannot contain semicolons."
	exit
fi
name=$1

if [[ -z $2 && -z $3 ]]
then
	echo "Steam ID or IP address must be provided."
	exit
fi

if [[ ! -z "$2" ]]
then
	if [[ $2 -le 70000000000000000 || $2 -ge 80000000000000000 ]]
	then
		echo "Invalid Steam ID provided."
		exit
	fi
fi
steamid=$2

if [[ ! -z "$3" ]]
then
	temp=$3
	temp=${temp//::ffff:/}
	IFS='.' read -r -a ipoctets <<< "$temp"
	if [ "${#ipoctets[@]}" -ne 4 ]
	then
		echo "[ERROR] IP addresses must have 4 octets."
		exit
	fi
	
	for octet in "${ipoctets[@]}"
	do
		if ! [[ $octet =~ ^[0-9]+$ ]]
		then
			echo "[ERROR] IP Octet $octet is not a number."
			exit
		fi
		
		if [[ $octet -lt 0 || $octet -gt 255 ]]
		then
			echo "[ERROR] IP octet $octet is not a valid octet."
			exit
		fi
	done
fi
ipaddress=$3

if [[ -n "$ipaddress" && "${ipaddress:0:7}" != "::ffff:" ]]
then
	ipaddress=::ffff:${ipaddress}
fi

if [ -z "$4" ]
then
	echo "[ERROR] Duration must be provided."
	exit
fi
duration=$4

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
	duration=26280000
	;;
*)
	echo "[ERROR] Duration must be one of: 1m|5m|15m|30m|1h|3h|5h|8h|12h|1d|3d|7d|14d|30d|100d|1y|5y|50y"
	exit 1
esac

if [ -z "$5" ]
then
	echo "[ERROR] Banning admin must be provided."
	exit
elif [[ $5 == *";"* ]]
then
	echo "[ERROR] Admin cannot contain semicolons."
	exit
fi
admin=${5:-ADMIN}

if [ -z "$6" ]
then
	echo "[ERROR] Reason must be provided."
	exit
elif [[ "$6" == *";"* ]]
then
	echo "[ERROR] Reason cannot contain semicolons."
	exit
fi
reason=${6:-}

now=`date +%s`
start=$(($now * 10000000))
start=$(($start + 621355968000000000))
end=$(($now + $duration * 60))
end=$(($end * 10000000))
end=$(($end + 621355968000000000))

if [ -n "$steamid" ]
then
	ban=true
	while IFS=";" read -r csv_name csv_id csv_end csv_reason csv_admin csv_start
	do
		if [ "$steamid" = "$csv_id" ]
		then
			echo "[BAN FAILED] $name with Steam ID $steamid has already been banned. Please remove this ban before adding a ban: "
			echo "$csv_name;$csv_id;$csv_end;$csv_reason;$csv_admin;$csv_start"
			#exit
			ban=false
		fi
	done < config/global/UserIdBans.txt
	
	if $ban
	then
		echo "Adding ban to config/global/UserIdBans.txt..."
		echo "$name;${steamid}@steam;$end;$reason;$admin;$start"
		echo "$name;${steamid}@steam;$end;$reason;$admin;$start" >> config/global/UserIdBans.txt
	fi
fi

if [ -n "$ipaddress" ]
then
	ban=true
	while IFS=";" read -r csv_name csv_id csv_end csv_reason csv_admin csv_start
	do
		if [ "$ipaddress" = "$csv_id" ]
		then
			echo "[BAN FAILED] $name with IP address ${csv_id:7} has already been banned. You do not need to ban this IP address."
			echo "$csv_name;$csv_id;$csv_end;$csv_reason;$csv_admin;$csv_start"
			#exit
			ban=false
		fi
	done < config/global/IpBans.txt
	
	if $ban
	then
		echo "Adding ban to config/global/IpBans.txt..."
		echo "$name;$ipaddress;$end;$reason;$admin;$start"
		echo "$name;$ipaddress;$end;$reason;$admin;$start" >> config/global/IpBans.txt
	fi
fi
