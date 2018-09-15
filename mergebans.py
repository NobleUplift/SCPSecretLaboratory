#!/bin/env python
"""mergelog

This is a custom merge driver for git. It should be called from git
with a stanza in .git.config like this:

    [merge "mergelog"]
        name = A custom merge driver for my log.txt file.
        driver = ~/scripts/mergelog %O %A %B %L
        recursive = binary

To make git use the custom merge driver you also need to put this in
.git/info/attributes:

   log.txt merge=mergelog

This tells git to use the 'mergelog' merge driver to merge files called log.txt.

"""
import sys, difflib, csv

class DiffError(Exception):
    def __init__(self,value):
        self.value = value
    def __str__(self):
        return repr(self.value)

# The arguments from git are the names of temporary files that
# hold the contents of the different versions of the log.txt
# file.

ancestorbans = []
currentbans = []
branchbans = []

# The version of the file from the common ancestor of the two branches.
# This constitutes the 'base' version of the file.
#ancestor = open(sys.argv[1],'r').readlines()
with open(sys.argv[1], 'r') as csvfile:
    bans = csv.reader(csvfile, delimiter=';', quotechar='"')
        for row in bans:
            ancestorbans[ ';'.join(row[1], row[2], row[5]) ] = row;

# The version of the file at the HEAD of the current branch.
# The result of the merge should be left in this file by overwriting it.
#current = open(sys.argv[2],'r').readlines()
with open(sys.argv[2], 'r') as csvfile:
    bans = csv.reader(csvfile, delimiter=';', quotechar='"')
        for row in bans:
            currentbans[ ';'.join(row[1], row[2], row[5]) ] = row;

# The version of the file at the HEAD of the other branch.
#other = open(sys.argv[3],'r').readlines()
with open(sys.argv[3], 'r') as csvfile:
    bans = csv.reader(csvfile, delimiter=';', quotechar='"')
        for row in bans:
            branchbans[ ';'.join(row[1], row[2], row[5]) ] = row;

# The merge algorithm is as follows:
# Append any text that was added to the beginning of the file in the
# other branch to the beginning of the current branch's copy of the file.
# If the other branch contains changes other than adding text at the
# beginning of the file then fail.
try:
    combined_bans = currentbans + branchbans
    sorted(combined_bans, key=lambda ban: ban[5])
except DiffError, d:
    iprint ''.join(difflib.unified_diff(ancestor,other))
    sys.exit(1)

print "The following text will be appended to the top of the file:"
print ''.join(ancestor_to_other)
f = open(sys.argv[2],'w')
csvwriter = csv.writer(csvfile, delimiter=';', quoting=csv.QUOTE_MINIMAL)
csvwriter.writerows(combined_bans)
#f.writelines(ancestor_to_other)
#f.writelines(current)
f.close()

# Exit with zero status if the merge went cleanly, non-zero otherwise.
sys.exit(0)

