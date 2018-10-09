#!/bin/env python3
"""mergebans
Copyright (c) 2018, Patrick Seiter
All rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are met:
    * Redistributions of source code must retain the above copyright
      notice, this list of conditions and the following disclaimer.
    * Redistributions in binary form must reproduce the above copyright
      notice, this list of conditions and the following disclaimer in the
      documentation and/or other materials provided with the distribution.
    * Neither the name of the organization nor the
      names of its contributors may be used to endorse or promote products
      derived from this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
DISCLAIMED. IN NO EVENT SHALL PATRICK SEITER BE LIABLE FOR ANY
DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
(INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

This is a custom merge driver for git. You can either define
it in .git/config like this:

[merge "mergebans"]
        name = Merge SteamID and IP bans in SCP:SL.
        driver = python3 ./mergebans.py %O %A %B %L

Or define it in .gitconfig and run the following command:

git config --local include.path ../.gitconfig

Then make sure to define it in your .gitattributes file like so:

SteamIdBans.txt merge=mergebans
IpBans.txt merge=mergebans

This tells git to use the 'mergebans' merge driver.

"""
import sys, csv, time

TICKS_OFFSET = 621355968000000000
MICROSECOND_TENTH = 10000000

# The arguments from git are the names of temporary files that
# hold the contents of the different versions of the log.txt
# file.

ancestor_bans = {}
current_bans = {}
branch_bans = {}

# The version of the file from the common ancestor of the two branches.
# This constitutes the 'base' version of the file.
with open(sys.argv[1], 'r', encoding='utf-8-sig') as csvfile:
    bans = csv.reader(csvfile, delimiter=';', quotechar='"')
    for row in bans:
        row[0] = row[0].replace("\ufeff", "")
        ancestor_bans[ row[1] ] = row # ';'.join([row[1], row[2], row[5]])

# The version of the file at the HEAD of the current branch.
# The result of the merge should be left in this file by overwriting it.
with open(sys.argv[2], 'r', encoding='utf-8-sig') as csvfile:
    bans = csv.reader(csvfile, delimiter=';', quotechar='"')
    for row in bans:
        if len(row) != 6:
            print('WARNING! Non-standard row detected in ban file: ' + ';'.join(row))
            continue
            #sys.exit(1)
        row[0] = row[0].replace("\ufeff", "")
        current_bans[ row[1] ] = row # ';'.join([row[1], row[2], row[5]])

# The version of the file at the HEAD of the other branch.
with open(sys.argv[3], 'r', encoding='utf-8-sig') as csvfile:
    bans = csv.reader(csvfile, delimiter=';', quotechar='"')
    for row in bans:
        if len(row) != 6:
            print('WARNING! Non-standard row detected in ban file: ' + ';'.join(row))
            continue
            #sys.exit(2)
        row[0] = row[0].replace("\ufeff", "")
        branch_bans[ row[1] ] = row # ';'.join([row[1], row[2], row[5]])

combined_bans = current_bans.copy()
now = time.time()

def compare_row(a, b):
    if len(a) > len(b):
        return 1
    elif len(a) < len(b):
        return -1
    else:
        for i in range(0, len(a) - 1):
            if a[i] > b[i]:
                return 1
            elif a[i] < b[i]:
                return -1
    return 0

for key in branch_bans:
    if key in current_bans:
        if key in ancestor_bans:
            #
            # If the key exists in all three branches, determine if the row
            # is a duplicate of the current, the branch, or they are both the same
            #
            ancestor_current = compare_row(ancestor_bans[key], current_bans[key])
            ancestor_branch = compare_row(ancestor_bans[key], branch_bans[key])
            if ancestor_current == 0 and ancestor_branch != 0:
                combined_bans[key] = branch_bans[key]
                continue
            elif ancestor_current != 0 and ancestor_branch == 0:
                combined_bans[key] = current_bans[key]
                continue
            elif ancestor_current == 0 and ancestor_branch == 0:
                combined_bans[key] = current_bans[key]
                continue
        #
        # If key exists in branch bans, current bans, and not ancestor bans
        # the ban exists on multiple servers but has not been synced
        #
        branch_diff = int(branch_bans[key][2]) - int(branch_bans[key][5])
        #branch_reason = branch_bans[key][3]
        #branch_admin = branch_bans[key][4]
        current_diff = int(current_bans[key][2]) - int(current_bans[key][5])
        #current_reason = current_bans[key][3]
        #current_admin = current_bans[key][4]
        if branch_diff < current_diff:
            combined_bans[key] = current_bans[key]
            #if current_admin == 'ADMIN':
            #    combined_bans[key][4] = branch_admin
            #elif branch_admin == 'ADMIN':
            #    combined_bans[key][4] = current_admin
            #if branch_admin != current_admin:
            #    combined_bans[key][4] = current_admin + ',' + branch_admin
        elif current_diff > branch_diff:
            combined_bans[key] = branch_bans[key]
            #if current_admin == 'ADMIN':
            #    combined_bans[key][4] = branch_admin
            #elif branch_admin == 'ADMIN':
            #    combined_bans[key][4] = current_admin
            #if branch_admin != current_admin:
            #    combined_bans[key][4] = current_admin + ',' + branch_admin
    else:
        #
        # If the key is in the new branch, but not the current branch,
        # then it is a new ban
        #
        combined_bans[key] = branch_bans[key]

ticks_now = TICKS_OFFSET + (now * MICROSECOND_TENTH)
for key in list(combined_bans.keys()):
    if int(combined_bans[key][2]) < ticks_now:
        combined_bans.pop(key, None)

combined_bans = list(combined_bans.values())
combined_bans = sorted(combined_bans, key=lambda ban: int(ban[5]))

print("")
print("This is the content of the ban file:")
for value in combined_bans:
    print(u";".join(value))

with open(sys.argv[2], 'w', encoding='utf-8-sig') as csvfile:
    #counter = 0
    csvwriter = csv.writer(csvfile, delimiter=';', quoting=csv.QUOTE_MINIMAL, lineterminator="\r\n")
    for value in combined_bans:
        #if counter == 0:
        #    value[0] = 
        csvwriter.writerow(value)
        #counter++

# Exit with zero status if the merge went cleanly, non-zero otherwise.
sys.exit(0)

