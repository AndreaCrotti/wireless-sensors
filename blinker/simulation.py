#!/usr/bin/env python
import sys
import time
import random
from TOSSIM import Tossim

RUNTIME = 200
NUM_NODES = 100

sim = Tossim([])
radio = sim.radio()

# Setting up the debugging channels
# we could make use of decorators for this for example
# We could also use some StringIO objects to encapsulate writing on pseudo files
sim.addChannel("BlinkC", sys.stdout)
sim.addChannel("Boot", sys.stdout)

# creating the list of nodes we're working with
nodes = [sim.getNode(x) for x in range(NUM_NODES)]

# loading the topology file
for line in open("topo.txt"):
    vals = line.split()
    vals = (int(vals[0]), int(vals[1]), float(vals[2]))
    radio.add(*vals)

for line in open("noise.txt"):
    val = int(line.strip())
    for n in nodes:
        n.addNoiseTraceReading(val)

for n in nodes:
    n.createNoiseModel()

# apparently booting with fixed times could cause some problems
for n in nodes:
    n.bootAtTime(random.randint(100001, 900009))

# FIXME: why this double runNextEvent is necesary?
sim.runNextEvent()
time = sim.time()
while(time + RUNTIME * 10000000000 > sim.time()):
    sim.runNextEvent()
