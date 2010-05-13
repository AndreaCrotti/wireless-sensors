#!/usr/bin/env python

"""
python script to test if some
of the algorithms are working as expected
"""

def getIdFromBM(bitmask):
    counter = 0
    bitmask >>= 1
    while (bitmask != 0):
        bitmask >>= 1
        counter += 1

    return counter

for x in range(10):
    print "%d = %s -> %d" % (x, str(bin(x)), getIdFromBM(x))
