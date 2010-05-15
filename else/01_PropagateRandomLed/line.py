#!/usr/bin/python

# @author oscar.dustmann@rwth-aachen.de
#
# A simple test-scenario.

from TOSSIM import *
from random import *
import sys

t = Tossim([])
#t.addChannel("LedsC",sys.stdout)
t.addChannel("PrlC",sys.stdout)
t.addChannel("PrlC_l",sys.stdout)

nodes = 200
ndb = -1.0

### link setup
r = t.radio()
for i in range(0,nodes-1):
  print "link " + str(i) + " <-> " + str(i+1)
  r.add(i,i+1,ndb)
  r.add(i+1,i,ndb)


### noise
noise = open("meyer-short.txt", "r")
lines = noise.readlines()
for line in lines:
  s = line.strip()
  if (s != ""):
    val = int(s)
    for i in range(0, nodes):
      m = t.getNode(i)
      m.addNoiseTraceReading(val)


### boot the nodes
for i in range(0,nodes):
  n = t.getNode(i)
  n.createNoiseModel();
  n.bootAtTime(i*100)

## run the code
for i in range(0,10000000):
  t.runNextEvent()

#while (m0.isOn() == 0):
#  t.runNextEvent()
#while (m0.isOn() == 1):
#  t.runNextEvent()
