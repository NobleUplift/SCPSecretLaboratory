#!/bin/bash

# https://askubuntu.com/questions/62492/how-can-i-change-the-date-modified-created-of-a-file

find ServerLogs/Round* -print | while read filename
do
	if [ "$filename" = "ServerLogs" ]
	then
		continue
	fi
	
	echo $filename
	round=`echo "$filename" | cut -d'.' -f1`
	time=`echo $round | cut -d' ' -f2`
	hour=`echo $time | cut -d'-' -f1`
	minute=`echo $time | cut -d'-' -f2`

	date=`echo $round | cut -d' ' -f3`
	day=`echo $date | cut -d'-' -f1`
	month=`echo $date | cut -d'-' -f2`
	year=`echo $date | cut -d'-' -f3`

	#  +"%H-%M %d-%m-%Y"
	filedate=`date -R -d"$year-$month-$day $hour:$minute"`
	if [ $? -ne 0 ]
	then
		exit
	fi
	touch -m -d "$filedate" "$filename"
done

find ServerLogs/7*/Round* -print | while read filename
do
	echo $filename
	round=`basename "$filename"`
	round=${round%.*}
	#echo "Round: $round"
	#round=`echo $filename | cut -d'.' -f1`
	date=`echo $round | cut -d' ' -f2`
	time=`echo $round | cut -d' ' -f3`
	#echo "Date: $date"
	#echo "Time: $time"
        hour=`echo $time | cut -d'.' -f1`
        minute=`echo $time | cut -d'.' -f2`
	second=`echo $time | cut -d'.' -f3`

	filedate=`date -R -d"$date $hour:$minute:$second"`
	echo $filedate
	touch -m -d "$filedate" "$filename"
done

