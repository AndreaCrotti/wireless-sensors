#!/usr/bin/env python

import sys

while True:
    try:
        line = sys.stdin.readline() 
        if not(line): 
            break 

        print "now led is %d" % int(line.split(' ')[-1], 16)
    except KeyboardInterrupt:
        sys.exit(0)
