#!/usr/bin/env python

"""
Generates a network of nodes in which the nodes are part of a fully connected grid.
As input parameters, the heigth and the width of the grid have to be given.
"""

import random
from sys import argv, exit


WIDTH = int(argv[1])
HEIGTH = int(argv[2])
DB_RANGE = (-60, -50)

if (WIDTH <= 0 or HEIGTH <= 0):
    print "One of the arguments is smaller than zero or not specified!"
    exit(1)

"""
The nodes numbers increase from left to right and from up to down in the grid.
"""

for x in range(0, WIDTH):
    for y in range(0, HEIGTH):
        # Connect the node with it's grid neighbors
        own = y * WIDTH + x
        # left:
        if(x >= 1):
            val =  random.randrange(*DB_RANGE)
            other = y * WIDTH + x - 1
            print "%d %d %f" % (own, other, val)
        # up:
        if(y >= 1):
            val =  random.randrange(*DB_RANGE)
            other = (y -1) * WIDTH + x
            print "%d %d %f" % (own, other, val)
        # right:
        if(x < WIDTH - 1):
            val =  random.randrange(*DB_RANGE)
            other = y * WIDTH + x + 1
            print "%d %d %f" % (own, other, val)
        # down:
        if(y < HEIGTH - 1):
            val =  random.randrange(*DB_RANGE)
            other = (y + 1) * WIDTH + x
            print "%d %d %f" % (own, other, val)
