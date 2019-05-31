#!/bin/bash

cd "/home/steam/.config/SCP Secret Laboratory"
# https://stackoverflow.com/questions/1593051/how-to-programmatically-determine-the-current-checked-out-git-branch
branch_name="$(git symbolic-ref HEAD 2>/dev/null)" ||
branch_name="(unnamed branch)"     # detached HEAD
branch_name=${branch_name##refs/heads/}

if [ ! -s SteamIdBans.txt ]
then
	echo "[ERROR] [ERROR] [ERROR] SteamIdBans.txt was emptied out!"
	cp -fR ../SteamIdBans.txt.bak ./SteamIdBans.txt
fi

if [ ! -s IpBans.txt ]
then
	echo "[ERROR] [ERROR] [ERROR] IpBans.txt was emptied out!"
	cp -fR ../IpBans.txt.bak ./IpBans.txt
fi

if [ ! -s ReservedSlots.txt ]
then
	echo "[ERROR] [ERROR] [ERROR] ReservedSlots.txt was emptied out!"
	cp -fR ../ReservedSlots.txt.bak ./ReservedSlots.txt
fi

cp SteamIdBans.txt ../SteamIdBans.txt.bak
cp IpBans.txt ../IpBans.txt.bak
cp ReservedSlots.txt ../ReservedSlots.txt.bak

if [[ $branch_name != "master" ]]
then
	
	echo "[STEP 1] Adding files on $branch_name"
	bans=false
	slots=false
	message=
	if git commit --no-edit | grep -q "SteamIdBans.txt"
	then
		echo "[STEP 2] SteamIdBans.txt will be staged for commit"
		bans=true
	fi
	if git commit --no-edit | grep -q "IpBans.txt"
	then
		echo "[STEP 2] IpBans.txt will be staged for commit"
		bans=true
	fi
	
	if git commit --no-edit | grep -q "ReservedSlots.txt"
	then
		echo "[STEP 2] ReservedSlots.txt will be staged for commit"
		slots=true
	fi
	
	if [[ $bans = true && $slots = true ]]
	then
		message="Add/remove bans and update reserved slots"
	elif [[ $bans = true ]]
	then
		message="Add/remove bans"
	elif [[ $slots = true ]]
	then
		message="Update reserved slots"
	else
		echo "[STEP 3-4] Merge local master branch with origin/master"
		cwd="$PWD"
		cd ../SCPSLConfig
		git checkout master
		git pull --all
		git merge --no-edit origin/$branch_name
		git push
		cd "$cwd"
		
		echo "[STEP 5] No files to commit: fetch origin and pull all branches"
		git fetch origin master:master
		git pull --all
		echo "[STEP 6] No files to commit, merge with master"
		git merge --no-edit origin/master
		exit 0
	fi
	#echo "[STEP 3] Adding files SteamIdBans.txt, IpBans.txt, and/or Reserved Slots.txt"
	git add SteamIdBans.txt IpBans.txt ReservedSlots.txt
	echo "[STEP 3] Committing bans/slots with message $message"
	git commit -m "$message"
	if [[ $? -ne 0 ]]
	then
		echo "exiting"
		exit 2
	fi
	git push
	
	echo "[STEP 4] Merge local master branch with origin/master"
	cwd="$PWD"
	cd ../SCPSLConfig
	git checkout master
	git pull --all
	git merge --no-edit origin/$branch_name
	git push
	cd "$cwd"
	
	echo "[STEP 5] Pulling Git after push"
	git fetch origin master:master
	git pull --all
	echo "[STEP 6] Merging with the master branch"
	git merge --no-edit origin/master
else
	echo "Cannot make commits on branch $branch_name"
fi
