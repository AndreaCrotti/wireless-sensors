#!/usr/bin/env python

"""
Generates a network of nodes
with the size given in input and the connection level from 0 to 9
"""

import random
from sys import argv, exit

NUM = int(argv[1])
CONN = int(argv[2])
DB_RANGE = (-60, -50)

if (NUM < 0 or CONN < 0 or CONN > 9):
    print "check your arguments"
    exit(1)

for x in range(1, NUM+1):
    for y in range(x+1, NUM+1):
        if random.random() * CONN > 1:
            val = random.randrange(*DB_RANGE)
            print "%d %d %f" % (x, y, val)
            print "%d %d %f" % (y, x, val + random.randrange(3))
