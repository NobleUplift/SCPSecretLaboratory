#!/bin/bash
epoch_ticks=621355968000000000
ticks_per_second=10000000
date_string=""

ticksToDateString() {
	ticks_since_epoch=$(($1 - $epoch_ticks))
	seconds_since_epoch=$(($ticks_since_epoch / $ticks_per_second))
	date_string=`date -d @$seconds_since_epoch "+%Y-%m-%d %H:%M:%S"`
}

for file in SteamIdBans.txt IpBans.txt
do
	echo Name,Steam Profile,Start Time,End Time,Admin,Reason
	while read ban
	do
		name=$(echo $ban | cut -d';' -f1)
		name=${name/,/\\,}
		idip=$(echo $ban | cut -d';' -f2)
		end_time=$(echo $ban | cut -d';' -f3)
		ticksToDateString ${end_time:-0}
		end_time=$date_string
		reason=$(echo $ban | cut -d';' -f4)
		admin=$(echo $ban | cut -d';' -f5)
		start_time=$(echo $ban | cut -d';' -f6)
		ticksToDateString ${start_time:-0}
		start_time=$date_string
		if [ "$file" = "SteamIdBans.txt" ]
		then
			idip=http://steamcommunity.com/profiles/$idip
		fi
		echo $name,$idip,$start_time,$end_time,$admin,$reason
	done <$file
	echo ""
done

