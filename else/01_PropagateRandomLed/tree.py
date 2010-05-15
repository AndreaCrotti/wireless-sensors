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
run = 10000000
ndb = -1.0

### link setup
r = t.radio()
for i in range(0,nodes-1):
  a = i*2+1
  b = a+1
  if (a < nodes):
    print "link " + str(i) + " <-> " + str(a)
    r.add(i,a,ndb)
    r.add(a,i,ndb)
  if (b < nodes):
    print "link " + str(i) + " <-> " + str(b)
    r.add(i,b,ndb)
    r.add(b,i,ndb)



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
for i in range(0,run):
  t.runNextEvent()

#while (m0.isOn() == 0):
#  t.runNextEvent()
#while (m0.isOn() == 1):
#  t.runNextEvent()
