#!/usr/bin/env bash
epoch_ticks=621355968000000000
ticks_per_second=10000000
date_string=""

ticksToDateString() {
	if [[ -z $1 ]]
	then
		date_string=INVALID
		return 1
	fi
	ticks_since_epoch=$(($1 - $epoch_ticks))
	seconds_since_epoch=$(($ticks_since_epoch / $ticks_per_second))
	if [[ $seconds_since_epoch -gt 2147483647 ]] && uname -m | grep -qv _64
	then
		date_string=PERMANENT
		return 50
	fi
	date_string=`date -d @$seconds_since_epoch "+%Y-%m-%d %H:%M:%S"`
}

separator=","
for file in config/global/UserIdBans.txt config/global/IpBans.txt
do
	newfile=${file//.txt/.csv}
	rm -f $newfile
	touch $newfile
	echo Name,Steam Profile,Start Time,End Time,Admin,Reason | tee -a $newfile
	while IFS= read -r ban || [[ $ban ]]
	do
		ban=${ban%$'\r'}
		IFS=';' read -ra row <<< "$ban"
		#name=$(echo $ban | cut -d';' -f1)
		#name=${name/,/\\,}
		#idip=$(echo $ban | cut -d';' -f2)
		#end_time=$(echo $ban | cut -d';' -f3)
		#ticksToDateString $end_time
		#end_time=$date_string
		#reason=$(echo $ban | cut -d';' -f4)
		#admin=$(echo $ban | cut -d';' -f5)
		#start_time=$(echo $ban | cut -d';' -f6)
		#ticksToDateString $start_time
		#start_time=$date_string
		row[0]=${row[0]//,/\\,}
		if [ "$file" = "config/global/UserIdBans.txt" ]
		then
			row[1]=http://steamcommunity.com/profiles/${row[1]}
		fi
		ticksToDateString ${row[2]}
		row[2]=$date_string
		ticksToDateString ${row[5]}
		row[5]=$date_string
		echo ${row[0]}$separator${row[1]}$separator${row[5]}$separator${row[2]}$separator${row[4]}$separator${row[3]} | tee -a $newfile
	done<"$file"
	echo ""
done

