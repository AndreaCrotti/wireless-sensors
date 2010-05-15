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

def updateLedMask(ledmask, led):
    return ledmask & (~led >> 3) ^ led

for x in range(10):
    print "%d = %s -> %d" % (x, str(bin(x)), getIdFromBM(x))

ledmask = 5
for x in (2**x for x in range(3)):
    print "setting led %s on ledmask %s getting -> %s" % (str(bin(x)), str(bin(ledmask)), str(bin(updateLedMask(ledmask, x))))
