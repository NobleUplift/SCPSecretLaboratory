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
	if git commit | grep -q "SteamIdBans.txt"
	then
		#echo "SteamIdBans.txt will be staged for commit"
		bans=true
	fi
	if git commit | grep -q "IpBans.txt"
	then
		#echo "IpBans.txt will be staged for commit"
		bans=true
	fi
	
	if git commit | grep -q "Reserved Slots.txt"
	then
		#echo "Reserved Slots.txt will be staged for commit"
		slots=true
	fi
	
	if [[ $bans = true && $slots = true ]]
	then
		message="Add/remove bans and update reserved slots"
		#echo "COMMIT MESSAGE $message"
	elif [[ $bans = true ]]
	then
		message="Add/remove bans"
		#echo "COMMIT MESSAGE $message"
	elif [[ $slots = true ]]
	then
		message="Update reserved slots"
		#echo "COMMIT MESSAGE $message"
	else
		#echo "No files to commit, pull all branches"
		git pull --all
		echo "No files to commit, merge with master"
		git merge --no-edit origin/master
		exit 0
	fi
	#echo "Adding files SteamIdBans.txt, IpBans.txt, and/or Reserved Slots.txt"
	git add SteamIdBans.txt IpBans.txt Reserved\ Slots.txt
	#echo "Committing bans/slots with message $message"
	git commit -m "$message"
	if [[ $? -ne 0 ]]
	then
		echo "exiting"
		exit 2
	fi
	git push
	#echo "Pulling Git after push"
	git pull --all
	#echo "Merging with the master branch"
	git merge --no-edit origin/master
else
	echo "Cannot make commits on branch $branch_name"
fi
