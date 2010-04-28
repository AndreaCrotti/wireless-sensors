#!/usr/bin/env python

import sys
import time
from TOSSIM import *

NUM_NODES = 20

nodes = [t.getNode(x) for x in range(NUM_NODES)]

# node with ID0 sends command
t = Tossim([])
n = t.getNode(32)
n.bootAtTime(100)

t.addChannel("Boot", sys.stdout)
t.addChannel("BlinkC", sys.stdout)

for i in range(1000):
    t.runNextEvent()


noise = open("meyer-heavy.txt", "r")
lines = noise.readlines()
for line in lines:
    str = line.strip()
    if (str != ""):
        val = int(str)
        for i in range(0, 7):
            t.getNode(i).addNoiseTraceReading(val)

for i in range(0, 7):
    t.getNode(i).createNoiseModel()
