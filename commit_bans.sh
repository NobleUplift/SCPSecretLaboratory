#!/bin/bash

# https://stackoverflow.com/questions/1593051/how-to-programmatically-determine-the-current-checked-out-git-branch
branch_name="$(git symbolic-ref HEAD 2>/dev/null)" ||
branch_name="(unnamed branch)"     # detached HEAD
branch_name=${branch_name##refs/heads/}

if [[ $branch_name != "master" ]]
then
	echo "Adding files on $branch_name"
	git add SteamIdBans.txt IpBans.txt
	git commit -m "Add/remove bans"
	git push
else
	echo "Cannot make commits on branch $branch_name"
fi
