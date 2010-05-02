#! /usr/bin/python
from TOSSIM import *
import sys
import random


t = Tossim([])
r = t.radio()
f = open("topo.txt", "r")

NUM_NODES = 20

lines = f.readlines()
for line in lines:
  s = line.split()
  if (len(s) > 0):
    r.add(int(s[0]), int(s[1]), float(s[2]))

# r.add(0, 1, -54.0)
# r.add(1, 0, -54.0)
# r.add(0, 2, -54.0)
# r.add(2, 0, -54.0)
# r.add(2, 1, -54.0)
# r.add(1, 2, -54.0)

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
  print "Creating noise model for ",i;
  t.getNode(i).createNoiseModel()

for i in range(0, NUM_NODES):
    t.getNode(i).bootAtTime(random.randint(100001, 900009))

# t.getNode(0).bootAtTime(100001);
# t.getNode(1).bootAtTime(800008);
# t.getNode(2).bootAtTime(1800009);

for i in range(0, 100000):
  t.runNextEvent()
