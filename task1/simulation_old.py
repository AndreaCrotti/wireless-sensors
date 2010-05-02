#!/usr/bin/env python

import sys
import time
import random
from TOSSIM import *

# NUM_NODES = 2

t = Tossim([])
r = t.radio()

# Setting up the debugging channels
# we could make use of decorators for this for example
# We could also use some StringIO objects to encapsulate writing on pseudo files
t.addChannel("BlinkC", sys.stdout)
t.addChannel("Boot", sys.stdout)

# creating the list of nodes we're working with
# nodes = [t.getNode(x) for x in range(NUM_NODES)]

# loading the topology
# TODO: Does it make sense to open the file instead of generating directly the topology here?
# for line in open("topo.txt"):
#     vals = line.split()
#     vals = (int(vals[0]), int(vals[1]), float(vals[2]))
#     r.add(*vals)

r.add(1, 2, -54.0)
r.add(2, 1, -54.0)

# adding the noise track to each of them and creating the noisemodel
# for line in open("noise.txt"):
#     val = int(line.strip())
#     for n in nodes:
#         n.addNoiseTraceReading(val)

# for n in nodes:
#     n.createNoiseModel()

noise = open("noise.txt", "r")
lines = noise.readlines()
for line in lines:
  str = line.strip()
  if (str != ""):
    val = int(str)
    for i in range(1, 4):
      t.getNode(i).addNoiseTraceReading(val)

for i in range(1, 4):
  print "Creating noise model for ",i;
  t.getNode(i).createNoiseModel()

# booting all nodes at same time
# for n in nodes:
#     n.bootAtTime(100001)

t.getNode(1).bootAtTime(100001);
t.getNode(2).bootAtTime(800008);

# after booting we have to run to the next events to see what happens
for i in range(10000):
    t.runNextEvent()

