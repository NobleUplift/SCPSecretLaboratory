#!/bin/env python
"""mergeslots



"""
import sys, csv

# The arguments from git are the names of temporary files that
# hold the contents of the different versions of the log.txt
# file.

ancestor_slots = {}
current_slots = {}
branch_slots = {}

# The version of the file from the common ancestor of the two branches.
# This constitutes the 'base' version of the file.
#ancestor = open(sys.argv[1],'r').readlines()
with open(sys.argv[1], 'r', encoding='utf-8') as csvfile:
    slots = csv.reader(csvfile, delimiter=';', quotechar='"')
    for row in slots:
        if len(row) == 1:
            ancestor_slots[ row[0] ] = row
        else
            ancestor_slots[ row[1] ] = row

# The version of the file at the HEAD of the current branch.
# The result of the merge should be left in this file by overwriting it.
#current = open(sys.argv[2],'r').readlines()
with open(sys.argv[2], 'r', encoding='utf-8') as csvfile:
    slots = csv.reader(csvfile, delimiter=';', quotechar='"')
    for row in slots:
        if len(row) == 1:
            ancestor_slots[ row[0] ] = row
        else
            ancestor_slots[ row[1] ] = row

# The version of the file at the HEAD of the other branch.
#other = open(sys.argv[3],'r').readlines()
with open(sys.argv[3], 'r', encoding='utf-8') as csvfile:
    slots = csv.reader(csvfile, delimiter=';', quotechar='"')
    for row in slots:
        if len(row) == 1:
            ancestor_slots[ row[0] ] = row
        else
            ancestor_slots[ row[1] ] = row

# The merge algorithm is as follows:
# Append any text that was added to the beginning of the file in the
# other branch to the beginning of the current branch's copy of the file.
# If the other branch contains changes other than adding text at the
# beginning of the file then fail.
combined_slots = {**current_slots, **branch_slots}
combined_slots = sorted(combined_slots, key=lambda ban: int(ban[5]))

print("The following text will be appended to the top of the file:")
for key in combined_slots:
    print(';'.join(combined_slots[key]))
#print ''.join()
#f = open(sys.argv[2],'w')
with open(sys.argv[2], 'w') as csvfile:
    csvwriter = csv.writer(csvfile, delimiter=';', quoting=csv.QUOTE_MINIMAL)
    for key in combined_slots:
        csvwriter.writerow(combined_slots[key])
    #csvwriter.writerows(combined_slots)
#f.writelines(ancestor_to_other)
#f.writelines(current)
#f.close()

# Exit with zero status if the merge went cleanly, non-zero otherwise.
sys.exit(0)

