#!/bin/bash
scpsl=. # $(dirname "$(readlink -f "$0")")

if [ -n "$1" ]
then
	server=$1
else
	server="*"
fi

if [ -z "$server" ]
then
	echo "No server provided."
	exit
fi

# https://logbuffer.wordpress.com/2010/09/23/bash-scripting-preserve-whitespaces-in-variables/
delimiter=": "
IFS=
for dir in $scpsl/$server
do
	echo $dir
	if [ ! -d "$dir" ]
	then
		continue
	fi
	
	if [ "$dir" = "global" ]
	then
		continue
	fi
	
	unset custom
	declare -A custom
	
	lastkey=""
	echo "Loading custom configuration settings $dir/config_custom.txt..."
	while read -r line
	do
		if [ "$line" = "" ]
		then
			continue
		fi
		
		#echo Last Key: $lastkey
		#echo Line delimiter: "${line/$delimiter}"
		#echo Line: $line
		# https://askubuntu.com/questions/299710/how-to-determine-if-a-string-is-a-substring-of-another-in-bash
		if [ "${line/$delimiter}" = "$line" ]
		then
			if grep -q ":$" <<< "$line"
			then
				id="$( cut -d ':' -f 1 <<< "$line" )"
				custom[$id]=
				lastkey=$id
			elif grep -q "^ - " <<< "$line"
			then
				#echo VALUE EQUALS LINE
				#value="$( cut -d '-' -f 2- <<< "$line" | xargs )"
				value=$line
				if [ -z ${custom[$id]} ]
				then
					custom[$id]=$value
					#echo FORCE SET ${custom[$id]}\\r\\n
				else
					custom[$id]=${custom[$id]}${value}\\r\\n
					#echo APPEND TO ${custom[$id]}
				fi
			else
				continue
			fi
		else
			# https://unix.stackexchange.com/questions/53310/splitting-string-by-the-first-occurrence-of-a-delimiter
			id="$( cut -d ':' -f 1 <<< "$line" )"
			value="$( cut -d ':' -f 2- <<< "$line" )"
			custom[$id]="$value"
			lastkey=$id
		fi
	done < "$dir/config_custom.txt"
	
	echo "Resulting custom dictionary: "
	echo ${!custom[@]}
	echo ${custom[@]}
	
	if [ ${#custom[@]} -eq 0 ]
	then
		echo "Could not parse $dir/config_custom.txt!"
		continue
	fi
	
	conf=config_gameplay.txt
	echo "Populating $dir/$conf..."
	cp /dev/null "$dir/$conf"
	arraykey=none
	lastkey=
	cat "$scpsl/config_global.txt" | while read -r line
	do
		#echo $line
		#echo ${line/$delimiter}
		# Remove the delimiter from the line
		# If it still matches, there is no delimiter so add it anyway
		if [ "${line/$delimiter}" = "$line" ]
		then
			id="$( cut -d ':' -f 1 <<< "$line" )"
			if grep -q ":$" <<< "$line" # [ -n "${custom[$id]}" ] && 
			then
				#echo "SETTING ARRAYKEY AND LASTKEY TO $id"
				arraykey=$id
				lastkey=$id
				echo -ne "$line\r\n" >> "$dir/$conf"
				echo -ne "${custom[$id]}\r\n" >> "$dir/$conf"
			elif grep -q "^ - " <<< "$line" # [ "$arraykey" = "$lastkey" ] &&
			then
				continue
			else
				echo -ne "$line\r\n" >> "$dir/$conf"
				lastkey=$line
			fi
		else
			id="$( cut -d ':' -f 1 <<< "$line" )"
			#echo $id
			value="$( cut -d ':' -f 2- <<< "$line" )"
			#echo $value
			
			if [ -n "${custom[$id]}" ]
			then
				echo -ne "${id}:${custom[$id]}\r\n" >> "$dir/$conf"
			else
				if [ "$value" = " " ]
				then
					continue
				fi
				echo -ne "$line\r\n" >> "$dir/$conf"
			fi
			lastkey=$id
		fi
	done
done

unset IFS
