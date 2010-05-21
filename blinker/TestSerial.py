# A simple TOSSIM driver for the TestSerial application that utilizes 
# TOSSIM Live extensions.
#
import sys
import time

from TOSSIM import *
from SerialMsg import *

t = Tossim([])
m = t.mac()
r = t.radio()
sf = SerialForwarder(9001)
throttle = Throttle(t, 10)

t.addChannel("Serial", sys.stdout);
t.addChannel("SerialC", sys.stdout);

for i in range(0, 2):
  m = t.getNode(i);
  m.bootAtTime((31 + t.ticksPerSecond() / 10) * i + 1);

sf.process();
throttle.initialize();

for i in range(0, 60):
# while True:
  throttle.checkThrottle();
  t.runNextEvent();
  sf.process();

msg = SerialMsg()
# msg.set_counter(7);

serialpkt = t.newSerialPacket();
serialpkt.setData(msg.data)
serialpkt.setType(msg.get_amType())
serialpkt.setDestination(0)
serialpkt.deliver(0, t.time() + 3)

pkt = t.newPacket()
pkt.setData(msg.data)
pkt.setType(msg.get_amType())
pkt.setDestination(0)
pkt.deliver(0, t.time() + 10)

# for i in range(0, 20):
while True:
  throttle.checkThrottle()
  t.runNextEvent()
  sf.process()

throttle.printStatistics()

