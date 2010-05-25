#!/usr/bin/env python

"""
TODO: instead of just printing to debug can I get and parse the output from the program?
"""

import sys
import time
import random

from TOSSIM import *
from SerialMsg import *

RUNTIME = 200
NUM_NODES = 16
SERIAL_PORT = 9001

# channels used for debug messages
# TODO: give different colors to the various debug messages
CHANNELS = ("Serial", "Boot", "Radio", "Routing", "Rel", "Sensor")

class Simulation(object):
    def __init__(self, num_nodes, port, channels):
        self.num_nodes = num_nodes
        self.sim = Tossim([])
        self.nodes = [self.sim.getNode(x) for x in range(self.num_nodes)]
        self.mac = self.sim.mac()
        self.radio = self.sim.radio()
        self.sf = SerialForwarder(port)
        self.throttle = Throttle(self.sim, 10)
        self.seqno = 0

        # adding all the channels
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
        while True:
        # while(time + RUNTIME * 10000000000 > self.sim.time()):
            self.sim.runNextEvent()
            self.throttle.checkThrottle()
            # processing what it's got from it
            self.sf.process()

        self.throttle.printStatistics()

    def make_topology(self, topo_file):
        # TODO: every time it should be resetted so we can change te topology on the fly
        # not so easy apparently
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
# TODO: use some arguments to limit the time used
sim.start()
