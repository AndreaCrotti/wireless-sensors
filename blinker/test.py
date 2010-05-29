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


# when doing automated testing the DEBUG output should be ignored completely
# Test
# 1. leds setting
# 2. data sensing
# For
# 1. different topologies
# 2. random values
# more...


