#!/usr/bin/env python
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
CHANNELS = ["Serial", "Boot", "Radio", "Routing", "Rel", "Sensor"]

class Simulation(object):
    """Simulation class"""
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
        while(time + RUNTIME * 10000000000 > self.sim.time()):
            self.sim.runNextEvent()
            self.throttle.checkThrottle()
            self.sf.process()

        self.throttle.printStatistics()

    def make_topology(self, topo_file):
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
