#!/bin/bash

scpsl=.
start_regex='^([0-9]{4}\-[0-9]{2}\-[0-9]{2} [0-9]{2}:[0-9]{2}:[0-9]{2}\.[0-9]{3} -[0-9]{2}:[0-9]{2}) \| ([a-zA-Z0-9 ]+) \| ([a-zA-Z0-9 ]+) \| ([0-9]{17})@steam authenticated from endpoint ([0-9:.-]+)\. Auth token serial number: (.*)$'
stop_regex='^([0-9]{4}-[0-9]{2}-[0-9]{2} [0-9]{2}:[0-9]{2}:[0-9]{2}\.[0-9]{3} -[0-9]{2}:[0-9]{2}) \| ([a-zA-Z0-9 ]+) \| ([a-zA-Z0-9 ]+) \| (.*) ([0-9]{17})@steam disconnected from IP address ([0-9:.-]+). Last class: (.*) \(.*\)$'

echo "" > ServerStatistics.log

for dir in $scpsl/ServerLogs/*
do
	if [ ! -d $dir ]
	then
		continue
	fi
	server=$(basename $dir)
	server=scp$((server - 7776))
	echo "Statistics for server $dir..."
	echo "Creating file $dir/../${server}_server_statistics.csv"
	echo "Creating file $dir/../${server}_player_statistics.csv"
	echo "date,amount,uniques" | tee $dir/../${server}_server_statistics.csv
	echo "date,id,amount" | tee $dir/../${server}_player_statistics.csv

	unset dates
	unset dates_total_players
	unset dates_unique_players
	declare -a dates
	declare -A dates_total_players
	declare -A dates_unique_players
	echo $dir

	first_date=$(ls $dir | head -n 1 | cut -d' ' -f2)
	echo "Generating statistics from date: $first_date"

	last_date=$(date +%Y-%m-%d)
	last_date=$(date +%Y-%m-%d -d "$last_date - 1 day")

	date=$first_date
	files_per_date=$(ls -1 $dir/Round*${date}* | wc -l)
	echo "FILES PER DATE: $files_per_date"
	while [ "$date" != "$last_date" ]
	do
		dates+=($date)
		if [ -z ${dates_total_players[$date]} ]
		then
			dates_total_players[$date]=0
		fi
		if ! ls $dir/Round*${date}*.txt > /dev/null 2>&1
		then
			echo "No files found for pattern $dir/Round*${date}*.txt"
			date=$(date +%Y-%m-%d -d "$date + 1 day")
			continue
		fi
		echo "$date "
		
		unset dates_player_per_day
		declare -A dates_player_per_day
		
		for file in $dir/Round*${date}*.txt
		do
			unset start_date_player_per_day
			declare -A start_date_player_per_day
			#unset end_date_player_per_day
			#declare -A end_date_player_per_day
		
			echo -ne .
			lastline=
			while read line
			do
				#if [[ $line =~ $regex ]]
				#then
				#	steamid=/"${BASH_REMATCH[4]}"
				#	if [ -z ${dates_player_per_day[$steamid]} ]
				#	then
				#		dates_player_per_day[$steamid]=0
				#	fi
				#	(( dates_total_players[$date]++ ))
				#	(( dates_player_per_day[$steamid]++ ))
				#	echo -ne "#"
				#fi
				
				if [[ $line =~ $start_regex ]]
				then
					(( dates_total_players[$date]++ ))
					steamid=/"${BASH_REMATCH[4]}"
					start_date_player_per_day[$steamid]=$(date -d "${BASH_REMATCH[1]}" +%s)
					if [ -z "${dates_player_per_day[$steamid]}" ]
					then
						dates_player_per_day[$steamid]="0"
					fi
					#echo "[FOUND START DATE] Found connection for Steam ID $steamid - ${start_date_player_per_day[$steamid]}" | tee -a ServerStatistics.log
					echo -ne "{"
				elif [[ $line =~ $stop_regex ]]
				then
					steamid=/"${BASH_REMATCH[5]}"
					
					if [ -z "${start_date_player_per_day[$steamid]}" ]
					then
						echo ""
						echo "[NO START DATE] No connection found for Steam ID $steamid in file $file" | tee -a ServerStatistics.log
						grep ${steamid/\//} "$file" >> ServerStatistics.log
						continue
					fi
					
					start_date=${start_date_player_per_day[$steamid]}
					end_date=$(date -d "${BASH_REMATCH[1]}" +%s)
					date_difference=$(expr "$end_date" - "$start_date")
					date_minutes_per_player=${dates_player_per_day[$steamid]}
					
					#echo "[MINUTES] Running expression $date_minutes_per_player + $date_difference" | tee -a ServerStatistics.log
					dates_player_per_day[$steamid]=$(expr "$date_minutes_per_player" + "$date_difference")
					unset start_date_player_per_day[$steamid]
					#echo "[SUCCESS] Successfully added $date_difference to Steam ID $steamid" | tee -a ServerStatistics.log
					echo -ne "}"
				fi
				lastline=$line
			done<"$file"
			
			for id in ${!start_date_player_per_day[@]}
			do
				echo ""
				echo "[NO DISCONNECT] Missing disconnect for connection $id - ${start_date_player_per_day[$id]} in file $file" | tee -a ServerStatistics.log
				echo "grep ${id/\//} '$file'" | tee -a ServerStatistics.log
				grep ${id/\//} "$file" >> ServerStatistics.log
			done
		done
		echo ""

		for id in ${!dates_player_per_day[@]}
		do
			echo ${date},${id},${dates_player_per_day[$id]} | tee -a $dir/../${server}_player_statistics.csv
		done
		dates_unique_players[$date]=${#dates_player_per_day[@]}

		echo -ne "\n"
		date=$(date +%Y-%m-%d -d "$date + 1 day")
	done
	for date in ${dates[@]}
	do
		echo ${date},${dates_total_players[$date]},${dates_unique_players[$date]} | tee -a $dir/../${server}_server_statistics.csv
	done
done
