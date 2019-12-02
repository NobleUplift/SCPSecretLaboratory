#!/bin/bash

cd "/home/steam/.config/SCP Secret Laboratory/config/global"
# https://stackoverflow.com/questions/1593051/how-to-programmatically-determine-the-current-checked-out-git-branch
branch_name="$(git symbolic-ref HEAD 2>/dev/null)" ||
branch_name="(unnamed branch)"     # detached HEAD
branch_name=${branch_name##refs/heads/}

# Let's hope that SCP:SL is no longer retarded and stops wiping the ban file
#
#if [[ ! -s UserIdBans.txt ]]
#then
#	now=`date +'%Y-%m-%d %H:%M:%S'`
#	echo "[$now] [ERROR] UserIdBans.txt was emptied out!"
#	cp -fR ../UserIdBans.txt.bak ./UserIdBans.txt
#fi
#
#if [[ ! -s IpBans.txt ]]
#then
#	now=`date +'%Y-%m-%d %H:%M:%S'`
#	echo "[$now] [ERROR] IpBans.txt was emptied out!"
#	cp -fR ../IpBans.txt.bak ./IpBans.txt
#fi
#
#if [[ ! -s UserIDReservedSlots.txt ]]
#then
#	now=`date +'%Y-%m-%d %H:%M:%S'`
#	echo "[$now] [ERROR] UserIDReservedSlots.txt was emptied out!"
#	cp -fR ../UserIDReservedSlots.txt.bak ./UserIDReservedSlots.txt
#fi
#
#cp UserIdBans.txt ../UserIdBans.txt.bak
#cp IpBans.txt ../IpBans.txt.bak
#cp UserIDReservedSlots.txt ../UserIDReservedSlots.txt.bak

if [[ "$branch_name" != "master" ]]
then
	now=`date +'%Y-%m-%d %H:%M:%S'`
	echo "[$now] [STEP 1] Adding files on $branch_name"
	bans=false
	mutes=false
	slots=false
	message=
	if git commit --no-edit | grep -q "UserIdBans.txt"
	then
		now=`date +'%Y-%m-%d %H:%M:%S'`
		echo "[$now] [STEP 2] UserIdBans.txt will be staged for commit"
		bans=true
	fi
	
	if git commit --no-edit | grep -q "IpBans.txt"
	then
		now=`date +'%Y-%m-%d %H:%M:%S'`
		echo "[$now] [STEP 2] IpBans.txt will be staged for commit"
		bans=true
	fi
	
	if git commit --no-edit | grep -q "UserIDReservedSlots.txt"
	then
		now=`date +'%Y-%m-%d %H:%M:%S'`
		echo "[$now] [STEP 2] UserIDReservedSlots.txt will be staged for commit"
		slots=true
	fi
	
	if git commit --no-edit | grep -q "mutes.txt"
	then
		now=`date +'%Y-%m-%d %H:%M:%S'`
		echo "[$now] [STEP 2] mutes.txt will be staged for commit"
		mutes=true
	fi
	
	if [[ $bans = true ]]
	then
		message="Add/remove bans"
		if [[ $mutes = true && $slots = true ]]
		then
			message="$message, add/remove mutes, and add/remove reserved slots"
		elif [[ $mutes = true && $slots = false ]]
		then
			message="$message and add/remove mutes"
		elif [[ $mutes = false && $slots = true ]]
		then
			message="$message and add/remove reserved slots"
		fi
	elif [[ $mutes = true ]]
	then
		message="Add/remove mutes"
		if [[ $slots = true ]]
		then
			message="$message and add/remove reserved slots"
		fi
	elif [[ $slots = true ]]
	then
		message="Add/remove reserved slots"
	else
		now=`date +'%Y-%m-%d %H:%M:%S'`
		echo "[$now] [STEP 3-4] Merge local master branch with origin/master"
		cwd="$PWD"
		cd "/home/steam/.config/SCPSLConfig"
		#git checkout master
		git reset --hard HEAD
		git pull --all
		git merge --no-edit origin/$branch_name
		git push
		cd "$cwd"
		
		echo "[$now] [STEP 5] No files to commit: fetch origin and pull all branches"
		git fetch origin master:master
		git pull --all
		echo "[$now] [STEP 6] No files to commit, merge with master"
		git merge --no-edit origin/master
		exit 0
	fi
	
	now=`date +'%Y-%m-%d %H:%M:%S'`
	#echo "[$now] [STEP 3] Adding files UserIdBans.txt, IpBans.txt, and/or UserIDReservedSlots.txt"
	git add UserIdBans.txt IpBans.txt UserIDReservedSlots.txt mutes.txt
	echo "[$now] [STEP 3] Committing bans/slots with message $message"
	git commit -m "$message"
	if [[ $? -ne 0 ]]
	then
		echo "exiting"
		exit 2
	fi
	git push
	
	now=`date +'%Y-%m-%d %H:%M:%S'`
	echo "[$now] [STEP 4] Merge local master branch with origin/master"
	cwd="$PWD"
	cd "/home/steam/.config/SCPSLConfig"
	git checkout master
	git pull --all
	git merge --no-edit origin/$branch_name
	git push
	cd "$cwd"
	
	now=`date +'%Y-%m-%d %H:%M:%S'`
	echo "[$now] [STEP 5] Pulling Git after push"
	git fetch origin master:master
	git pull --all
	now=`date +'%Y-%m-%d %H:%M:%S'`
	echo "[$now] [STEP 6] Merging with the master branch"
	git merge --no-edit origin/master
else
	echo "Cannot make commits on branch $branch_name"
fi
