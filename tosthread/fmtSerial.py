#!/usr/bin/env python

import sys
#####################################################################
# dests: 0000, seqno: 00, instr: 01111011   (from node 00, to FFFF) #
#####################################################################

fromHex = lambda x: int(x, 16)
# get info from the starting string

while True: 
    line = sys.stdin.readline() 
    if not(line): 
        break 

    hexas = map(fromHex, line.split(' '))
    print hexas
