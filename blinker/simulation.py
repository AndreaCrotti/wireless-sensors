#!/usr/bin/env python

"""
TODO: instead of just printing to debug can I get and parse the output from the program?
TODO: check what is the minimal number of events to run to be sure we trigger everything
TODO: check problems with multiple destinations
TODO: catch exceptions when getting input from string

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
from packet import *

from TOSSIM import *
from tinyos.tossim.TossimApp import *
from tinyos.message import MoteIF

from gen_network import bin_tree, rand_graph

RUNTIME = 2

MAX_NODES = 16
MAXEVENTS = 1000
SERIAL_PORT = 9001

# channels used for debug messages
# TODO: give different colors to the various debug messages

# CHANNELS = ("Serial", "Boot", "Radio", "Routing", "Rel", "Sensor")
CHANNELS = ("Serial", "Boot", "Radio", "Routing", "Rel", "Sensor")

def print_var_table(vars):
    from re import match
    print "\nvariable list\n"
    for v in vars:
        if match(r"Blink.*|Easy.*|Rulti.*", v):
            print v
    print "\n"

def get_decorated_file(f, prefix, color):
    proc = subprocess.Popen(['python', 'colorize.py', prefix, color],
                            bufsize=0,
                            stdin=subprocess.PIPE,
                            stdout=f)
    return proc.stdin

class RadioNetwork(object):
    "Manage the network topology"
    def __init__(self, radio, symmetric=True):
        self.symmetric = symmetric
        self.radio = radio
        self.topology = set()

    def __len__(self):
        return len(self.topology)

    def __str__(self):
        return "\n".join("%d - %d" % (x[0], x[1]) for x in list(self.topology))

    def add_connection(self, node1, node2, link=-56.0):
        "Add a connection between two nodes"
        if self.symmetric:
            self.radio.add(node2, node1, link)
            self.topology.add((node2, node1))

        self.topology.add((node1, node2))
        self.radio.add(node1, node2, link)

    def remove_connection(self, node1, node2):
        if self.symmetric:
            self.radio.remove(node2, node1)
            self.topology.remove((node2, node1))

        self.topology.remove((node1, node2))
        self.radio.remove(node1, node1)

# add to the local variables also the variables in the 
class Simulation(object):
    def __init__(self, port, channels):
        self.app = NescApp()
        # only take the variable names without
        self.vars = self.app.variables.variables()
        # I pass the variables to the simulator
        self.sim = Tossim(self.vars)
        self.nodes = {}
        # the serial forwarder stuff is needed only by the java interaface
        # or the listen.py script
        self.sf = SerialForwarder(port)
        self.throttle = Throttle(self.sim, 10)
        self.seqno = 0
        # operations on the topology and the radio channel
        self.topology = RadioNetwork(self.sim.radio())

        # cols = colors.keys()
        # idx = 0
        # adding all the channels
        for c in channels:
            self.sim.addChannel(c, sys.stdout)

            # 1. one color for each channel
            # 2. print the name of the channel before it
            # ch = get_decorated_file(sys.stdout, c, cols[idx])
            # self.sim.addChannel(c, ch)
            # # we should not have so many but just in case
            # idx = (idx + 1) % len(cols)

    def add_node(self, idx):
        # otherwise add to the dictionary the correct node
        if not(idx in self.nodes):
            # FIXME: check that they're all added correctly
            if len(self.nodes) == MAX_NODES:
                print "Not possible to add more nodes, reached limit"

            else:
                self.nodes[idx] = self.sim.getNode(idx)

    # TODO: we should then implement the removal as well
    # making sure we always keep a minimal set of nodes

    def start(self, batch=False):
        "Starts the simulation"
        for n in self.nodes.values():
            n.bootAtTime(random.randint(100001, 900009))

        self.sf.process()
        self.throttle.initialize()

        # just run enough events to make sure we boot all the motes before starting
        self.run_some_events()
        if not(batch):
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
        for vals in rand_graph(MAX_NODES, 5):
            self.add_connection(*vals)

    def make_bin_tree(self, len):
        "Creates a binary tree structure for the topology"
        for vals in bin_tree(len):
            self.add_connection(*vals)
        print self.topology

    def count_events_needed(self, packet, var, value):
        "Send a packet and try to see how many steps are needed to fulfill it"
        from itertools import count
        self.send_packet(packet)
        for i in count():
            if i > MAXEVENTS:
                return False

            if self.check_vars_all_nodes(var, value):
                return i

            # run one more event
            self.throttle.checkThrottle()
            self.sim.runNextEvent()
            # processing what it's got from it
            self.sf.process()

    def setup_noise(self, noise_file):
        for line in open(noise_file):
            val = int(line.strip())
            for n in self.nodes.values():
                n.addNoiseTraceReading(val)

        for n in self.nodes.values():
            n.createNoiseModel()

    def add_connection(self, n1, n2, distance):
        "Add to the radio channel a connection between the two nodes"
        self.add_node(n1)
        self.add_node(n2)
        self.topology.add_connection(n1, n2, distance)

    def remove_connection(self, n1, n2):
        self.topology.remove_connection(n1, n2)

    def interactive(self):
        # FIXME: the order of printing now is not respected though, concurrency stuff
        # get_decorated_file(sys.stdout, "", "green").write("entering interactive session, another C-c to quit the program\n")
        print "entering interactive session, another C-c to quit the program"
        choice = input("\n\n1)topology management\n2)packet creation\n3)variable inspection\n4)inspect mote\n5)Running tests\n\n")
        if choice == 1:
            self.manipulate_topology()
        if choice == 2:
            self.send_packet(make_packet())
        if choice == 3:
            self.inspect_variable()
        if choice == 4:
            self.inspect_mote()
        if choice == 5:
            node_list = sorted(self.nodes.keys())
            print "sending turn on to all nodes"
            self.send_packet(turn_leds_all_nodes(node_list))
            self.run_some_events()
            if not(self.check_vars_nodes(node_list, "BlinkC.ledMask", 7)):
                print "Not all motes got the right value"

            print "sending sensing info to a random node"
            self.send_packet(sens_random_node(node_list))

    def run_some_events(self):
        "Run some of the events"
        # TODO: pass some arguments to make sure they're enough
        time = self.sim.time()
        while(time + RUNTIME * 10000000000 > self.sim.time()):
            self.throttle.checkThrottle()
            self.sim.runNextEvent()
            # processing what it's got from it
            self.sf.process()

        self.throttle.printStatistics()

    def check_vars_all_nodes(self, var, value):
        return self.check_vars_nodes(sorted(self.nodes.keys()), var, value)

    def check_vars_nodes(self, nodes, var, value):
        "Check that all the variables of nodes have that value"
        for n in nodes:
            val = self.get_variable(n, var)
            print "node %d = %d" % (n, val)
            if val != value:
                return False

        return True

    def inspect_variable(self):
        "Ask for a variable to inspect and returns it"
        readline.parse_and_bind("tab: complete")
        mote = input("which mote you want to inspect?\n")
        print_var_table(self.vars)
        # see if this is actually correct
        c = rlcompleter.Completer(dict(zip(self.vars, self.vars)))
        readline.set_completer(c.complete)
        var = raw_input("which variable do you want to inspect?\n")
        print "mote %d:var %s = %s" % (mote, var, self.get_variable(mote, var))

    def inspect_mote(self):
        mote = input("which mote you want to inspect?\n")
        self.print_mote_vars(mote)

    def get_variable(self, mote, var):
        return self.nodes[mote].getVariable(var).getData()

    def filter_variable(self, mod = "Easy|Blink|Rulti"):
        for v in self.vars:
            if re.match(mod, v):
                yield v

    def print_mote_vars(self, mote):
        for v in self.filter_variable():
            print self.get_variable(mote, v)

    def manipulate_topology(self):
        choice = input("1)see topology\n2)add one connection\n3)remove one connection\n")
        if choice == 1:
            print self.topology

        if choice == 2:
            n1, n2, dist = input("first node\n"), input("second node\n"), float(input("distance\n"))
            self.add_connection(n1, n2, dist)
            print "added link from %s to %s" % (n1, n2)

        if choice == 3:
            nodes = raw_input("what are the nodes to remove (symmetrically) write X Y?\n")
            n1, n2 = map(int, nodes.split(" "))
            self.remove_connection(n1, n2)
            print "removed link from %s to %s" % (n1, n2)

    def send_packet(self, msg):
        "Takes a BlinkMsg already generated and sends it via serial"
        serialpkt = self.sim.newSerialPacket();
        serialpkt.setData(msg.get_data())
        serialpkt.setType(msg.am_type)
        # TODO: this 0 is ok to be 
        serialpkt.setDestination(0)
        serialpkt.deliver(0, self.sim.time() + 3)

        for i in range(20):
            self.throttle.checkThrottle()
            self.sim.runNextEvent()
            # processing what it's got from it
            self.sf.process()

        print "sended packet:\n%s" % str(msg)
        self.seqno += 1


if __name__ == '__main__':
    sim = Simulation(SERIAL_PORT, CHANNELS)
    topo_file = "topo.txt"

    if len(sys.argv) == 2:
        topo_file = sys.argv[1]
    
    # TODO: only creates the number of nodes present our file
    sim.make_topology(topo_file)
    sim.setup_noise("noise.txt")
    sim.start()
