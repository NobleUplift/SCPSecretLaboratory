#!/bin/bash

cd "/home/steam/.config/SCP Secret Laboratory"
# https://stackoverflow.com/questions/1593051/how-to-programmatically-determine-the-current-checked-out-git-branch
branch_name="$(git symbolic-ref HEAD 2>/dev/null)" ||
branch_name="(unnamed branch)"     # detached HEAD
branch_name=${branch_name##refs/heads/}

if [[ $branch_name != "master" ]]
then
	echo "Adding files on $branch_name"
	bans=false
	slots=false
	message=
	git add SteamIdBans.txt IpBans.txt
	if [[ $? -eq 0 ]]
	then
		bans=true
	fi
	git add Reserved\ Slots.txt
	if [[ $? -eq 0 ]]
	then
		slots=true
	fi
	
	if [[ $bans -eq true && slots -eq true ]]
	then
		message="Add/remove bans and update reserved slots"
	elif [[ $bans -eq true ]]
	then
		message="Add/remove bans"
	elif [[ $slots -eq true ]]
	then
		message="Update reserved slots"
	else
		echo "No files to commit"
		exit 1
	fi
	git commit -m "$message"
	git push
	git merge  --no-edit origin/master
else
	echo "Cannot make commits on branch $branch_name"
fi
