#!/usr/bin/python

# @author oscar.dustmann@rwth-aachen.de
#
# A simple test-scenario.

from TOSSIM import *
from random import *
import sys

t = Tossim([])
t.addChannel("LedsC",sys.stdout)
#t.addChannel("PrlC",sys.stdout)
#t.addChannel("PrlC_l",sys.stdout)

nodes = 20
ndb = -1.0

### link setup
r = t.radio()
for i in range(0,4):
  for j in range(0,3):
    x = 4*i+j
    y = x+1
    z = x+4
    print "link " + str(x) + " <-> " + str(y)
    r.add(x,y,ndb)
    r.add(y,x,ndb)
    print "link " + str(x) + " <-> " + str(z)
    r.add(x,z,ndb)
    r.add(z,x,ndb)
print "link 18 <-> 19"
r.add(18,19,ndb)
r.add(19,18,ndb)
print "link 15 <-> 19"
r.add(15,19,ndb)
r.add(19,15,ndb)



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
for i in range(0,100000):
  t.runNextEvent()

#while (m0.isOn() == 0):
#  t.runNextEvent()
#while (m0.isOn() == 1):
#  t.runNextEvent()
