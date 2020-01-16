#!/bin/env python3
"""mergemutes
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

[merge "mergemutes"]
        name = Merge reserved mutes in SCP:SL.
        driver = python3 ./mergemutes.py %O %A %B %L

Or define it in .gitconfig and run the following command:

git config --local include.path ../.gitconfig

Then make sure to define it in your .gitattributes file like so:

Reserved\ mutes.txt merge=mergemutes

This tells git to use the 'mergemutes' merge driver.

"""
import sys, csv

print('[DRIVER] Merge driver has been activated. Merging mutes...')

# The arguments from git are the names of temporary files that
# hold the contents of the different versions of the log.txt
# file.

ancestor_mutes = {}
current_mutes = {}
branch_mutes = {}

# The version of the file from the common ancestor of the two branches.
# This constitutes the 'base' version of the file.
with open(sys.argv[1], 'r', encoding='utf-8') as csvfile:
    mutes = csv.reader(csvfile, delimiter='@', quotechar='"')
    for row in mutes:
        if len(row) == 1:
            ancestor_mutes[ row[0] ] = row
        elif len(row) == 2:
            ancestor_mutes[ row[1] ] = row

# The version of the file at the HEAD of the current branch.
# The result of the merge should be left in this file by overwriting it.
with open(sys.argv[2], 'r', encoding='utf-8') as csvfile:
    mutes = csv.reader(csvfile, delimiter='@', quotechar='"')
    for row in mutes:
        if len(row) == 1:
            current_mutes[ row[0] ] = row
        elif len(row) == 2:
            current_mutes[ row[1] ] = row

# The version of the file at the HEAD of the other branch.
with open(sys.argv[3], 'r', encoding='utf-8') as csvfile:
    mutes = csv.reader(csvfile, delimiter='@', quotechar='"')
    for row in mutes:
        if len(row) == 1:
            branch_mutes[ row[0] ] = row
        elif len(row) == 2:
            branch_mutes[ row[1] ] = row

def compare_row(a, b):
    if len(a) > len(b):
        return 1
    elif len(a) < len(b):
        return -1
    else:
        for i in range(len(a)):
            if a[i] > b[i]:
                return 1
            elif a[i] < b[i]:
                return -1
    return 0

combined_mutes = {}
for key in list(ancestor_mutes.keys()):
    if key not in current_mutes or key not in branch_mutes:
        ancestor_mutes.pop(key, None)
        current_mutes.pop(key, None)
        branch_mutes.pop(key, None)
        continue
    ancestor_current = compare_row(ancestor_mutes[key], current_mutes[key])
    ancestor_branch = compare_row(ancestor_mutes[key], branch_mutes[key])
    if ancestor_current == 0 and ancestor_branch != 0:
        combined_mutes[key] = branch_mutes[key]
    elif ancestor_current != 0 and ancestor_branch == 0:
        combined_mutes[key] = current_mutes[key]
    elif ancestor_current == 0 and ancestor_branch == 0:
        combined_mutes[key] = ancestor_mutes[key]
    else:
        combined_mutes[key] = current_mutes[key]
    ancestor_mutes.pop(key, None)
    current_mutes.pop(key, None)
    branch_mutes.pop(key, None)

for key in current_mutes:
    combined_mutes[key] = current_mutes[key]

combined_mutes = sorted(combined_mutes, key=lambda mute: mute[0])

#print("")
#print("This is the content of the new Reserved mutes.txt file:")
#for key in combined_mutes:
#    print(';'.join(combined_mutes[key]))
with open(sys.argv[2], 'w') as csvfile:
    csvwriter = csv.writer(csvfile, delimiter=',', quoting=csv.QUOTE_MINIMAL, lineterminator="\n")
    for key in combined_mutes:
        csvwriter.writerow(combined_mutes[key])

# Exit with zero status if the merge went cleanly, non-zero otherwise.
sys.exit(0)

