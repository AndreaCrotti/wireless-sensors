#!/usr/bin/env python

import sys
import time
from TOSSIM import *

NUM_NODES = 20

t = Tossim([])
r = t.radio()

# Setting up the debugging channels
# we could make use of decorators for this for example
# We could also use some StringIO objects to encapsulate writing on pseudo files
t.addChannel("Boot", sys.stdout)
t.addChannel("BlinkC", sys.stdout)

# loading the topology
# TODO: Does it make sense to open the file instead of generating directly the topology here?
for line in open("topo.txt"):
    vals = line.split()
    vals = (int(vals[0]), int(vals[1]), float(vals[2]))
    r.add(*vals)

# creating the list of nodes we're working with
nodes = [t.getNode(x) for x in range(NUM_NODES)]

# adding the noise track to each of them and creating the noisemodel
for line in open("noise.txt"):
    val = int(line.strip())
    for n in nodes:
        n.addNoiseTraceReading(val)

for n in nodes:
    n.createNoiseModel()

# booting all nodes at same time
for n in nodes:
    n.bootAtTime(100)

# after booting we have to run to the next events to see what happens
for i in range(100):
    t.runNextEvent()
