#!/usr/bin/env python
import sys
import time
import random

from TOSSIM import *
from SerialMsg import *
from tinyos.message import MoteIF

from BlinkMsg import BlinkMsg

RUNTIME = 200
NUM_NODES = 16
SERIAL_PORT = 9001

# channels used for debug messages
# TODO: give different colors to the various debug messages
CHANNELS = ("Serial", "Boot", "Radio", "Routing", "Rel", "Sensor")

# add another class for more direct input sending
class Communicator(object):
    """ Sending messages directly to the motes """
    def __init__(self, port):
        self.mif = MoteIF.MoteIF()
        addr = "sf@localhost:%s" % port
        self.mif.addSource(addr)
        # the self argument is referring to the listener class
        # simply a class that implements the receive function
        self.mif.addListener(self, BlinkMsg)
        self.seq_no = 0

        mif.sendMsg(self, dest, addr, amType, group, msg)

    def receive(self, src, msg):
        print "Received message from %s: %s" % (str(msg), str(src))

    def send_led_mask(self, dest, mask):
        # Where is the actual sending command done?
        message = BlinkMsg()
        message.set_dests(dest)
        message.set_type(1)
        message.set_instr(mask)
        message.set_seqno(self.seq_no)

        print "sended message with mask %d and dest %d with seq %d\n" % (mask, dest, self.seq_no)
        ## check out from 
        # self.mif.sendMsg(dest, adddr)
        self.seq_no += 1

class Simulation(object):
    def __init__(self, num_nodes, port, channels):
        self.num_nodes = num_nodes
        self.sim = Tossim([])
        self.nodes = [self.sim.getNode(x) for x in range(self.num_nodes)]
        self.mac = self.sim.mac()
        self.radio = self.sim.radio()
        self.sf = SerialForwarder(port)
        self.throttle = Throttle(self.sim, 10)

        for c in channels:
            self.sim.addChannel(c, sys.stdout)

    def start(self):
        "Starts the simulation"
        for n in self.nodes:
            n.bootAtTime(random.randint(100001, 900009))
        self.sf.process()
        self.throttle.initialize()

        # we can divide things even more here
        time = self.sim.time()
        # TODO: setup more granularity in output
        # Use a try/catch to stop and resume the debugging process
        # while(time + RUNTIME * 10000000000 > self.sim.time()):
        while True:
            self.sim.runNextEvent()
            self.throttle.checkThrottle()
            self.sf.process()

        self.throttle.printStatistics()

    def make_topology(self, topo_file):
        # every time it should be resetted so we can change te topology on the fly
        # maybe a deepcopy is necessary or something like that?
        for line in open(topo_file):
            vals = line.split()
            vals = (int(vals[0]), int(vals[1]), float(vals[2]))
            self.radio.add(*vals)

    def setup_noise(self, noise_file):
        for line in open(noise_file):
            val = int(line.strip())
            for n in self.nodes:
                n.addNoiseTraceReading(val)

        for n in self.nodes:
            n.createNoiseModel()


sim = Simulation(NUM_NODES, SERIAL_PORT, CHANNELS)
sim.make_topology("topo.txt")
sim.setup_noise("noise.txt")
sim.start()
