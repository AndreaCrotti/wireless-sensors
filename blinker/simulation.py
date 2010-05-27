#!/usr/bin/env python

"""
TODO: instead of just printing to debug can I get and parse the output from the program?
TODO: check what is the minimal number of events to run to be sure we trigger everything
TODO: use different subclasses instead

Usage:
Run normally "python simulation.py", wait that the motes are booted and then, pressing C-c it will ask interactively to build a packet and will send it over the serial channel
ow the instructions

We can also inspect variables while we run the program.
If this script doesn't work make sure you have
$TOSROOT/support/sdk/python/ in your PYTHONPATH variable

We can also do some sort of unit testing using variables.
"""

import sys
import time
import subprocess
import random
import readline
import rlcompleter

from colorize import colors

from TOSSIM import *
from SerialMsg import *
from tinyos.tossim.TossimApp import *

from gen_network import bin_tree, rand_graph

RUNTIME = 2
NUM_NODES = 16
SERIAL_PORT = 9001

# channels used for debug messages
# TODO: give different colors to the various debug messages

CHANNELS = ("Serial", "Boot", "Radio", "Routing", "Rel", "Sensor")

def get_decorated_file(f, prefix, color): 
    proc = subprocess.Popen(['python', 'colorize.py', prefix, color], 
                            bufsize=0, 
                            stdin=subprocess.PIPE, 
                            stdout=f) 
    return proc.stdin 
        
class Simulation(object):
    def __init__(self, num_nodes, port, channels):
        self.app = NescApp()
        self.vars = self.app.variables.variables()
        self.num_nodes = num_nodes
        # I pass the variables to the simulator 
        self.sim = Tossim(self.vars)
        self.nodes = [self.sim.getNode(x) for x in range(self.num_nodes)]
        self.mac = self.sim.mac()
        self.radio = self.sim.radio()
        self.sf = SerialForwarder(port)
        self.throttle = Throttle(self.sim, 10)
        self.seqno = 0
        # at the moment is only used to store and show the topology informations
        self.topology = {}
        # this is used to inspect our code
        # self.interactive_output = get_decorated_file(sys.stdout, "", "green")

        cols = colors.keys()
        idx = 0
        # adding all the channels
        for c in channels:
            # 1. one color for each channel
            # 2. print the name of the channel before it
            # ch = Channel(c, sys.stdout, 0)
            # self.sim.addChannel(c, ch)
            ch = get_decorated_file(sys.stdout, c, cols[idx])
            self.sim.addChannel(c, ch)
            # we should not have so many but just in case
            idx = (idx + 1) % len(cols)

    def start(self):
        "Starts the simulation"
        for n in self.nodes:
            n.bootAtTime(random.randint(100001, 900009))
            
        self.sf.process()
        self.throttle.initialize()

        # just run enough events to make sure we boot all the motes before starting
        time = self.sim.time()
        while(time + RUNTIME * 10000000000 > self.sim.time()):
            self.throttle.checkThrottle()
            self.sim.runNextEvent()
            # processing what it's got from it
            self.sf.process()

        self.throttle.printStatistics()
        self.cycle()

    def cycle(self):
        "Loop at infinite runnign all the events in the queue"
        print "start cycling, use C-c to send data interactively"
        # self.interactive_output.write("start cycling, use C-c to send data interactively\n")
        while True:
            try:
                self.throttle.checkThrottle()
                self.sim.runNextEvent()
                # processing what it's got from it
                self.sf.process()
            except KeyboardInterrupt:
                # with the first interrupt we go in interactive mode, the second quits the program
                try:
                    self.interactive()
                    print "\nrestarting the cycle, running other events...\n"
                    continue
                except KeyboardInterrupt:
                    sys.exit()
        
    def make_topology(self, topo_file):
        "Creates the topology from the given file"
        for line in open(topo_file):
            vals = line.split()
            vals = (int(vals[0]), int(vals[1]), float(vals[2]))
            self.add_connection(*vals)

    def make_rand_graph(self):
        "Creates a random graph"
        for vals in rand_graph(NUM_NODES, 5):
            self.add_connection(*vals)

    def make_bin_tree(self, len):
        "Creates a binary tree structure for the topology"
        for vals in bin_tree(len):
            self.add_connection(*vals)

    def get_max_node(self):
        "Look into the keys and automatically flat the list with two max"
        return max(max(couple) for couple in self.topology)

    def setup_noise(self, noise_file):
        for line in open(noise_file):
            val = int(line.strip())
            for n in self.nodes:
                n.addNoiseTraceReading(val)

        for n in self.nodes:
            n.createNoiseModel()
    
    def add_connection(self, n1, n2, distance):
        "Add to the radio channel a connection between the two nodes"
        # check if the nodes are present at all
        if self.radio.connected(n1, n2):
            print "already present, modifying the distance then"
            self.radio.remove(n1, n2)
            
        self.radio.add(n1, n2, distance)
        # self.radio.add(n2, n1, distance)
        self.topology[(n1,n2)] = distance
        # self.topology[(n2,n1)] = distance

    def remove_connection(self, n1, n2):
        if self.radio.connected(n1, n2):
            self.radio.remove(n1, n2)
            del self.topology[(n1, n2)]
            if self.topology.has_key([n2, n1]):
                # now it's done in a symmetric way
                del self.topology[(n2, n1)]
        else:
            print "not present in the topology"

    def interactive(self):
        # FIXME: the order of printing now is not respected though, concurrency stuff
        get_decorated_file(sys.stdout, "", "green").write("entering interactive session, another C-c to quit the program\n")
        # print "entering interactive session, another C-c to quit the program"
        choice = input("\n\n1)topology management\n2)packet creation\n3)variable inspection\n\n")
        if choice == 1:
            self.manipulate_topology()
        if choice == 2:
            self.send_packet()
        if choice == 3:
            self.inspect_variable()

    def inspect_variable(self):
        "Ask for a variable to inspect and returns it"
        readline.parse_and_bind("tab: complete")
        mote = input("which mote you want to inspect?\n")
        # see if this is actually correct
        c = rlcompleter.Completer(dict(zip(self.vars, self.vars)))
        readline.set_completer(c.complete)
        var = raw_input("which variable do you want to inspect\n")
        print "mote %d:var %s = %s" % (mote, var, self.nodes[mote].getVariable(var).getData())
            
    def manipulate_topology(self):
        choice = input("1)see topology\n2)add one connection\n3)remove one connection\n")
        if choice == 1:
            for x in self.topology:
                print "(%d -> %d) (%f)" % (x[0], x[1], self.topology[x])

        if choice == 2:
            n1, n2, dist = input("first node\n"), input("second node\n"), float(input("distance\n"))
            self.add_connection(n1, n2, dist)

        if choice == 3:
            nodes = raw_input("what are the nodes to remove (symmetrically) write X Y?\n")
            n1, n2 = map(int, nodes.split(" "))
            self.remove_connection(n1, n2)

    def send_packet(self):
        "Creates and send a new serial packet"
        msg = MyPacket()
        msg.make_packet()
        serialpkt = self.sim.newSerialPacket();
        serialpkt.setData(msg.get_data())
        serialpkt.setType(msg.am_type)
        serialpkt.setDestination(0)
        serialpkt.deliver(0, self.sim.time() + 3)

        for i in range(20):
            self.throttle.checkThrottle()
            self.sim.runNextEvent()
            # processing what it's got from it
            self.sf.process()

        print "sended packet:\n%s" % str(msg)
        self.seqno += 1

    def automated_test(self):
        "launch some tests automatically to test all the features"
        # test all the possible things with some easy stuff
        pass

class MyPacket(object):
    def __init__(self):
        self.msg = SerialMsg()
        # that's because we're always in mote 0 here
        self.msg.set_sender(0)
        self.am_type = self.msg.get_amType()
    
    def __str__(self):
        return "dest: %d\ntype: %d\ninstr: %d\n" % (self.msg.get_dests(), self.msg.get_type(), self.msg.get_instr())

    def get_data(self):
        return self.msg.data

    def make_packet(self):
        dest = input("Insert destination (as a bitmask)\n")
        self.msg.set_dests(dest)
        typ = input("1)led\n2)sensing request\n3)sensing data\n")
        self.msg.set_type(typ)

        if typ == 1:
            mask = input("insert led mask\n")
            self.msg.set_instr(mask)
        elif typ == 2:
            sens = input("1)light\n2)infrared\n3)humidity\n4)temperature\n")
            self.msg.set_instr(sens)
        
        else:
            self.make_packet()
            # you could also create a real data package maybe?

sim = Simulation(NUM_NODES, SERIAL_PORT, CHANNELS)
topo_file = "topo.txt"

if len(sys.argv) == 2:
    topo_file = sys.argv[1]
    
# TODO: only creates the number of nodes present our file
sim.make_topology(topo_file)
sim.setup_noise("noise.txt")
sim.start()
