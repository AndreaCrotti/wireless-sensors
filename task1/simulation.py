#!/usr/bin/env python

import sys
import time
import random
from TOSSIM import *

RUNTIME = 200
NUM_NODES = 100

t = Tossim([])
r = t.radio()

# Setting up the debugging channels
# we could make use of decorators for this for example
# We could also use some StringIO objects to encapsulate writing on pseudo files
t.addChannel("BlinkC", sys.stdout)
t.addChannel("Boot", sys.stdout)

# creating the list of nodes we're working with
nodes = [t.getNode(x) for x in range(NUM_NODES)]

# loading the topology
# TODO: Does it make sense to open the file instead of generating directly the topology here?
for line in open("topo.txt"):
    vals = line.split()
    vals = (int(vals[0]), int(vals[1]), float(vals[2]))
    r.add(*vals)

for line in open("noise.txt"):
    val = int(line.strip())
    for n in nodes:
        n.addNoiseTraceReading(val)

for n in nodes:
    n.createNoiseModel()

for n in nodes:
    n.bootAtTime(random.randint(100001, 900009))

t.runNextEvent()
time = t.time()
while(time + RUNTIME * 10000000000 > t.time()):
    t.runNextEvent()
