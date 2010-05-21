#!/usr/bin/env python
import sys
import time
import random

from TOSSIM import *
from SerialMsg import *

RUNTIME = 200
NUM_NODES = 16

sim = Tossim([])
mac = sim.mac()
radio = sim.radio()
sf = SerialForwarder(9001)
throttle = Throttle(sim, 10)

# Setting up the debugging channels
# we could make use of decorators for this for example
# We could also use some StringIO objects to encapsulate writing on pseudo files
sim.addChannel("Serial", sys.stdout)
sim.addChannel("Boot", sys.stdout)
sim.addChannel("Radio", sys.stdout)
sim.addChannel("Routing", sys.stdout)
sim.addChannel("Rel", sys.stdout)
sim.addChannel("Sensor", sys.stdout)


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

sf.process();
throttle.initialize();

time = sim.time()
while(time + RUNTIME * 10000000000 > sim.time()):
    sim.runNextEvent()
    throttle.checkThrottle()
    sf.process()

throttle.printStatistics()
