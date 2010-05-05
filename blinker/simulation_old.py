#! /usr/bin/python
from TOSSIM import *
import sys
import random

### Simulation settings ###
# Number of nodes 
NUM_NODES = 100
# Simulation runtime in seconds
RUNTIME = 200

t = Tossim([])
r = t.radio()
f = open("topo.txt", "r")

lines = f.readlines()
for line in lines:
  s = line.split()
  if (len(s) > 0):
    r.add(int(s[0]), int(s[1]), float(s[2]))

t.addChannel("BlinkC", sys.stdout)
t.addChannel("Boot", sys.stdout)

noise = open("noise.txt", "r")
lines = noise.readlines()
for line in lines:
  str = line.strip()
  if (str != ""):
    val = int(str)
    for i in range(0, NUM_NODES):
      t.getNode(i).addNoiseTraceReading(val)

for i in range(0, NUM_NODES):
  # print "Creating noise model for ",i;
  t.getNode(i).createNoiseModel()

for i in range(0, NUM_NODES):
    t.getNode(i).bootAtTime(random.randint(100001, 900009))

# t.getNode(0).bootAtTime(100001);
# t.getNode(1).bootAtTime(800008);
# t.getNode(2).bootAtTime(1800009);


t.runNextEvent()
time = t.time()
while(time + RUNTIME * 10000000000 > t.time()):
    t.runNextEvent()
